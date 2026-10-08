#!/usr/bin/env python3
"""Esperimento hosted: CLI, inventory, create, boot, inventory e cleanup propri."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import signal


def module(name, filename):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(filename))
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


IOS = module('ios_preflight_owner', 'run-task054-ios-owned.py')
TRACE = module('ios_preflight_trace', 'trace-ios-owned-process.py')


class UuidInventoryOwner(IOS.IosOwnedRunner):
    """Ipotesi isolata: filtro UUID documentato dalla CLI hosted installata."""
    def __init__(self, receipt=None):
        super().__init__(receipt)
        self.scoped_query_verified = False

    def command(self, arguments, timeout, capture=False):
        device = self.record.get('device') if self.record else None
        inventory = arguments == ['xcrun', 'simctl', 'list', 'devices', '--json']
        if not inventory or not device:
            return super().command(arguments, timeout, capture=capture)
        if not IOS.UUID.fullmatch(device):
            raise IOS.Failure(2, 'UUID proprio invalido prima della query scoped')
        output = super().command(arguments + [device], timeout, capture=capture)
        payload = json.loads(output)
        devices = payload.get('devices')
        if not isinstance(devices, dict) or any(not isinstance(rows, list)
                for rows in devices.values()):
            raise IOS.Failure(2, 'shape inventory scoped invalida')
        entries = [entry for rows in devices.values() for entry in rows]
        if any(not isinstance(entry, dict) or
               str(entry.get('udid', '')).lower() != device.lower() for entry in entries):
            raise IOS.Failure(2, 'filtro UUID non rispettato dalla CLI installata')
        if not entries and not self.scoped_query_verified:
            if self.phase != 'cleanup':
                raise IOS.Failure(2, 'filtro UUID non verificato sul simulatore appena creato')
            # Un filtro mai provato non attesta assenza. Cleanup usa in questo
            # solo caso l'inventory canonico, poi verifica nome/runtime propri.
            return super().command(arguments, timeout, capture=capture)
        if entries:
            self.scoped_query_verified = True
        # I controlli canonici di unicità/runtime/name/availability/state restano
        # nel device_record/check_device ereditato; assenza è ancora un readback.
        return output


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    parser.add_argument('--keep-ready', action='store_true')
    parser.add_argument('--inventory-scope', choices=('global', 'uuid'), default='global')
    options = parser.parse_args(argv)
    output = Path(options.output)
    output.mkdir(parents=True, exist_ok=False)
    runner_type = UuidInventoryOwner if options.inventory_scope == 'uuid' else IOS.IosOwnedRunner
    owner = runner_type(output / 'owner.json')
    result = {'schemaVersion': 1, 'scope': 'owned_hosted_simulator_preflight',
              'app': 'NOT_RUN', 'preflight': 'NOT_RUN', 'cleanup': 'NOT_RUN',
              'inventory_scope': options.inventory_scope}
    primary = 0
    handlers = {signum: signal.getsignal(signum) for signum in (signal.SIGTERM, signal.SIGINT)}
    for signum in (signal.SIGTERM, signal.SIGINT):
        signal.signal(signum, owner.interrupted)
    try:
        with TRACE.trace_processes(output / 'processes.jsonl') as emit:
            try:
                revision = owner.command(['git', 'rev-parse', 'HEAD'], 15, capture=True)
                result['revision'] = revision.strip()
                help_main = owner.command(['xcrun', 'simctl', 'help'], 30, capture=True)
                # Questa CLI scrive l'help di list su stderr (run37836564977).
                # Exec statico conserva il PGID proprio e il wrapper canonico.
                help_list = owner.command(['/bin/sh', '-c',
                    'exec xcrun simctl help list 2>&1'], 30, capture=True)
                (output / 'simctl-help.txt').write_text(help_main + '\n' + help_list)
                result['cli'] = {'help_sha256': hashlib.sha256(
                    (help_main + '\n' + help_list).encode()).hexdigest(),
                    'device_set_option': '--set' in help_main,
                    'list_search_term': 'search term' in help_list.lower(),
                    'help_list_channels': 'stdout_and_stderr',
                    'policy': options.inventory_scope + '_inventory_experiment'}
                if options.inventory_scope == 'uuid' and not result['cli']['list_search_term']:
                    raise IOS.Failure(2, 'CLI non dichiara il filtro inventory richiesto')
                inventory = json.loads(owner.command(
                    ['xcrun', 'simctl', 'list', 'devices', '--json'], 30, capture=True))
                if not isinstance(inventory.get('devices'), dict):
                    raise IOS.Failure(2, 'inventory iniziale invalido')
                result['initial_inventory'] = 'PASS'
                emit('preflight-prepare-start')
                owner.prepare()
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
