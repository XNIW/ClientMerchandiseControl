#!/usr/bin/env python3
"""Esperimento hosted: CLI, inventory, create, boot, inventory e cleanup propri."""
import argparse
import hashlib
import importlib.util
import json
import os
import re
from pathlib import Path
import signal


def module(name, filename):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(filename))
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


IOS = module('ios_preflight_owner', 'run-task054-ios-owned.py')
TRACE = module('ios_preflight_trace', 'trace-ios-owned-process.py')


def canonical_cold_preflight(output):
    """Ricetta minima osservabile; nessuna app, warm-up o query aggiuntiva."""
    output = Path(output)
    output.mkdir(mode=0o700, parents=True, exist_ok=False)
    owner = IOS.IosOwnedRunner(output / 'owner.json')
    result = {'schemaVersion': 1, 'scope': 'canonical_cold_owned_preflight',
              'app': 'NOT_RUN', 'preflight': 'NOT_RUN', 'cleanup': 'NOT_RUN',
              'catalog': {'commandCount': 0, 'result': 'NOT_RUN'}}
    original_command = owner.command

    def observe_command(arguments, timeout, capture=False):
        catalog = arguments == ['xcrun', 'simctl', 'list', 'runtimes', '--json']
        if catalog:
            result['catalog']['commandCount'] += 1
            result['catalog']['result'] = 'FAIL'
        value = original_command(arguments, timeout, capture=capture)
        if catalog:
            observation = result['catalog']
            observation.update(bytes=len(value.encode()),
                               sha256=hashlib.sha256(value.encode()).hexdigest())
            try:
                payload = json.loads(value)
                rows = payload.get('runtimes') if isinstance(payload, dict) else None
                observation.update(jsonRootType=type(payload).__name__,
                                   runtimesType=type(rows).__name__)
                if isinstance(rows, list):
                    observation['rowCount'] = len(rows)
                    selected = []
                    for row in rows:
                        if not isinstance(row, dict):
                            continue
                        identifier = row.get('identifier')
                        if not isinstance(identifier, str) or not re.fullmatch(
                                r'com\.apple\.CoreSimulator\.SimRuntime\.iOS-26-[0-9]+(?:-[0-9]+)?',
                                identifier):
                            continue
                        item = {'identifier': identifier}
                        for key in ('version', 'buildversion', 'isAvailable'):
                            value_field = row.get(key)
                            item[key + 'Type'] = type(value_field).__name__
                            if (key == 'isAvailable' and type(value_field) is bool or
                                    key != 'isAvailable' and isinstance(value_field, str) and
                                    re.fullmatch(r'[A-Za-z0-9._-]{1,80}', value_field)):
                                item[key] = value_field
                        selected.append(item)
                    observation['ios26'] = selected[:32]
                observation['jsonValid'] = True
                observation['result'] = 'PASS' if isinstance(rows, list) else 'FAIL'
            except (ValueError, TypeError):
                observation['jsonValid'] = False
            # Osservazione soltanto: il parser/selector canonico riceve gli
            # stessi byte e resta responsabile di accettare o fallire.
        return value

    owner.command = observe_command
    handlers = {sig: signal.getsignal(sig) for sig in (signal.SIGTERM, signal.SIGINT)}
    for sig in handlers:
        signal.signal(sig, owner.interrupted)
    primary = 0
    try:
        with TRACE.trace_processes(output / 'processes.jsonl') as emit:
            try:
                developer = '/Applications/Xcode_26.6.app/Contents/Developer'
                result['toolchain'] = {'image_os': os.environ.get('ImageOS'),
                    'image_version': os.environ.get('ImageVersion'),
                    'developer_dir': os.environ.get('DEVELOPER_DIR')}
                if os.environ.get('DEVELOPER_DIR') != developer or not Path(developer).is_dir():
                    raise IOS.Failure(2, 'Xcode26.6 richiesto non presente/selezionato')
                version = owner.command(['xcodebuild', '-version'], 30, capture=True).strip()
                sdk = owner.command(['xcrun', '--sdk', 'iphonesimulator', '--show-sdk-version'],
                                    30, capture=True).strip()
                result['toolchain'].update(xcode_version=version[:256], simulator_sdk=sdk[:80])
                # Xcode26.6 usa SDKsim26.5 sulla superficie attestata; il
                # runtime viene selezionato separatamente dal catalogo.
                if version.splitlines()[:1] != ['Xcode 26.6'] or sdk != '26.5':
                    raise IOS.Failure(2, 'Superficie richiede Xcode26.6/SDKsim26.5')
                emit('canonical-cold-prepare-start')
                owner.prepare(headless=True, readiness_attestation=IOS.OWNED_DESCRIPTOR)
                result['preflight'] = 'PASS'
                emit('canonical-cold-prepare-end', result='PASS')
            except (IOS.Failure, OSError, ValueError, KeyError, TypeError, AttributeError) as error:
                primary = error.code if isinstance(error, IOS.Failure) else 2
                result.update(preflight='FAIL', error_type=type(error).__name__)
                emit('canonical-cold-error', error_type=type(error).__name__, exit_code=primary)
            finally:
                if owner.record is not None:
                    result['selectedRuntime'] = owner.record.get('runtime')
                    result['selectedRuntimeVersion'] = owner.record.get('runtimeVersion')
                    result['bootstatusCompleted'] = owner.record.get('bootstatusCompleted') is True
                if owner.owns_receipt:
                    for sig in handlers:
                        signal.signal(sig, signal.SIG_IGN)
                    try:
                        result['cleanup'] = 'PASS' if owner.cleanup() else 'FAIL'
                    except (IOS.Failure, OSError, ValueError, KeyError, TypeError, AttributeError) as error:
                        result.update(cleanup='FAIL', cleanup_error_type=type(error).__name__)
                    if result['cleanup'] != 'PASS':
                        primary = primary or 1
                else:
                    result['cleanup_reason'] = 'no_owned_receipt_or_device_created'
                result['processCleanupFailed'] = bool(owner.process_cleanup_failed or
                    owner.record is not None and owner.record.get('processCleanupFailed'))
                if result['processCleanupFailed']:
                    primary = primary or 1
                result['exit_code'] = primary
                with os.fdopen(os.open(output / 'result.json',
                        os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), 'w') as saved:
                    saved.write(json.dumps(result, indent=2) + '\n')
    finally:
        for sig, handler in handlers.items():
            signal.signal(sig, handler)
    return primary


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    parser.add_argument('--keep-ready', action='store_true')
    parser.add_argument('--profile', choices=('historical', 'canonical'), default='historical')
    options = parser.parse_args(argv)
    if options.profile == 'canonical':
        if options.keep_ready:
            parser.error('canonical preflight vieta keep-ready e non esegue app')
        return canonical_cold_preflight(options.output)
    output = Path(options.output)
    output.mkdir(parents=True, exist_ok=False)
    owner = IOS.IosOwnedRunner(output / 'owner.json')
    result = {'schemaVersion': 1, 'scope': 'owned_hosted_simulator_preflight',
              'app': 'NOT_RUN', 'preflight': 'NOT_RUN', 'cleanup': 'NOT_RUN'}
    primary = 0
    handlers = {signum: signal.getsignal(signum) for signum in (signal.SIGTERM, signal.SIGINT)}
    for signum in (signal.SIGTERM, signal.SIGINT):
        signal.signal(signum, owner.interrupted)
    try:
        with TRACE.trace_processes(output / 'processes.jsonl') as emit:
            try:
                revision = owner.command(['git', 'rev-parse', 'HEAD'], 15, capture=True)
                result['revision'] = revision.strip()
                developer = '/Applications/Xcode_26.5.app/Contents/Developer'
                result['toolchain'] = {
                    'image_os': os.environ.get('ImageOS'),
                    'image_version': os.environ.get('ImageVersion'),
                    'available_xcodes': sorted(str(path) for path in
                        Path('/Applications').glob('Xcode*.app')),
                    'developer_dir': os.environ.get('DEVELOPER_DIR'),
                }
                if os.environ.get('DEVELOPER_DIR') != developer or not Path(developer).is_dir():
                    raise IOS.Failure(2, 'Xcode26.5 richiesto non presente/selezionato')
                version = owner.command(['xcodebuild', '-version'], 30, capture=True).strip()
                sdk = owner.command(['xcrun', '--sdk', 'iphonesimulator', '--show-sdk-version'],
                                    30, capture=True).strip()
                result['toolchain'].update(xcode_version=version, simulator_sdk=sdk)
                print(json.dumps({'toolchain': result['toolchain']}), flush=True)
                if version.splitlines()[:1] != ['Xcode 26.5'] or sdk != '26.5':
                    raise IOS.Failure(2, 'Xcode/SDK non coincide con ipotesi26.5')
                help_main = owner.command(['xcrun', 'simctl', 'help'], 30, capture=True)
                help_list = owner.command(['xcrun', 'simctl', 'help', 'list'], 30, capture=True)
                (output / 'simctl-help.txt').write_text(help_main + '\n' + help_list)
                result['cli'] = {'help_sha256': hashlib.sha256(
                    (help_main + '\n' + help_list).encode()).hexdigest(),
                    'device_set_option': '--set' in help_main,
                    'list_search_term': 'search term' in help_list.lower(),
                    'policy': 'baseline_inventory_unchanged_pending_installed_cli_evidence'}
                inventory = json.loads(owner.command(
                    ['xcrun', 'simctl', 'list', 'devices', '--json'], 30, capture=True))
                if not isinstance(inventory.get('devices'), dict):
                    raise IOS.Failure(2, 'inventory iniziale invalido')
                result['initial_inventory'] = 'PASS'
                emit('preflight-prepare-start')
                owner.prepare()
                if owner.record['runtime'] != 'com.apple.CoreSimulator.SimRuntime.iOS-26-5':
                    raise IOS.Failure(2, 'runtime diverso dalla baseline iOS26.5')
                result['preflight'] = 'PASS'
                emit('preflight-prepare-end', result='PASS')
            except (IOS.Failure, OSError, ValueError, KeyError) as error:
                primary = error.code if isinstance(error, IOS.Failure) else 1
                result.update(preflight='FAIL', error_type=type(error).__name__, exit_code=primary)
                emit('preflight-error', error_type=type(error).__name__, exit_code=primary)
            finally:
                if owner.record is not None and owner.owns_receipt and (
                        primary or not options.keep_ready):
                    for signum in (signal.SIGTERM, signal.SIGINT):
                        signal.signal(signum, signal.SIG_IGN)
                    try:
                        result['cleanup'] = 'PASS' if owner.cleanup() else 'FAIL'
                    except (IOS.Failure, OSError, ValueError, KeyError) as error:
                        result.update(cleanup='FAIL', cleanup_error_type=type(error).__name__)
                    if result['cleanup'] != 'PASS':
                        primary = primary or 1
                elif options.keep_ready and not primary:
                    result['cleanup_reason'] = 'owned_workflow_finally_after_native_steps'
                else:
                    result['cleanup_reason'] = 'no_owned_receipt_or_device_created'
            result['exit_code'] = primary
            (output / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    finally:
        for signum, handler in handlers.items():
            signal.signal(signum, handler)
    return primary


if __name__ == '__main__':
    raise SystemExit(main())
