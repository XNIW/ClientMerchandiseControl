#!/usr/bin/env python3
"""Esperimento hosted: CLI, inventory, create, boot, inventory e cleanup propri."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import signal
import stat
import uuid


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


class DedicatedSetOwner(IOS.IosOwnedRunner):
    """Ultima ipotesi CLI headless: un set esclusivo, mai esportato ai nativi."""
    def __init__(self, receipt):
        super().__init__(receipt)
        self.device_set = self.receipt.parent / 'device-set'
        self.device_set.mkdir(mode=0o700, exist_ok=False)
        metadata = self.device_set.lstat()
        self.set_identity = {'uid': metadata.st_uid, 'device': metadata.st_dev,
                             'inode': metadata.st_ino}
        self.set_cleanup = 'NOT_RUN'
        self.validate_set()
        with os.fdopen(os.open(self.receipt.parent / 'device-set-owner.json',
                os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), 'w') as stream:
            json.dump({'schemaVersion': 1, 'path': str(self.device_set),
                       'identity': self.set_identity, 'nativeTransport': 'BLOCKED'}, stream)

    def validate_set(self):
        metadata = self.device_set.lstat()
        identity = {'uid': metadata.st_uid, 'device': metadata.st_dev,
                    'inode': metadata.st_ino}
        if not stat.S_ISDIR(metadata.st_mode) or metadata.st_uid != os.geteuid() or \
                metadata.st_mode & 0o077 or identity != self.set_identity:
            raise IOS.Failure(2, 'device set proprio sostituito/non privato: nessuna mutazione')

    def command(self, arguments, timeout, capture=False):
        if arguments[:2] == ['xcrun', 'simctl']:
            self.validate_set()
            arguments = arguments[:2] + ['--set', str(self.device_set)] + arguments[2:]
        elif arguments == ['/bin/sh', '-c', 'exec xcrun simctl help list 2>&1']:
            self.validate_set()
            arguments = ['/bin/sh', '-c', 'exec xcrun simctl --set "$1" help list 2>&1',
                         'simctl-list-help', str(self.device_set)]
        output = super().command(arguments, timeout, capture=capture)
        if arguments[4:7] == ['list', 'devices', '--json']:
            payload = json.loads(output)
            devices = payload.get('devices')
            if not isinstance(devices, dict) or any(not isinstance(rows, list)
                    for rows in devices.values()):
                raise IOS.Failure(2, 'shape inventory del set invalida')
            entries = [entry for rows in devices.values() for entry in rows]
            device = self.record.get('device') if self.record else None
            if any(not isinstance(entry, dict) or not device or
                    str(entry.get('udid', '')).lower() != device.lower() for entry in entries):
                raise IOS.Failure(2, 'inventory del set contiene identità non propria')
        return output

    def prepare(self):
        # Stessa ricetta/budget/receipt del runner canonico, con GUI esplicitamente
        # NOT_RUN. Nessun default-set open e nessuna pretesa di app readiness.
        self.record = {'schemaVersion': 1, 'nonce': uuid.uuid4().hex, 'device': None,
                       'creationStarted': False, 'cleanup': 'NOT_RUN',
                       'deviceSetIdentity': self.set_identity, 'gui': 'NOT_RUN',
                       'nativeTransport': 'BLOCKED'}
        self.record['ownerContext'] = {key: os.environ.get(key) for key in IOS.OWNER_CONTEXT}
        self.record['name'] = IOS.PREFIX + self.record['nonce']
        self.persist(exclusive=True)
        payload = json.loads(self.command(['xcrun', 'simctl', 'list', 'runtimes', '--json'],
                                         30, capture=True))
        available = [runtime for runtime in payload['runtimes']
                     if runtime.get('isAvailable') and runtime['identifier'].startswith(
                         'com.apple.CoreSimulator.SimRuntime.iOS-26-')]
        if not available:
            raise IOS.Failure(2, 'runtime iOS26 compatibile assente')
        runtime = max(available, key=lambda row: tuple(map(int, row['version'].split('.'))))
        self.record['runtime'] = runtime['identifier']
        self.record['creationStarted'] = True
        self.persist()
        self.phase = 'create'
        creation_failure, device = None, ''
        try:
            device = self.command(['xcrun', 'simctl', 'create', self.record['name'],
                'com.apple.CoreSimulator.SimDeviceType.iPhone-17', self.record['runtime']],
                30, capture=True).strip()
        except IOS.Failure as error:
            creation_failure, device = error, error.output.strip()
        self.phase = 'prepare'
        if IOS.UUID.fullmatch(device):
            self.record['device'] = device
            self.persist()
        if self.pending_signal:
            raise IOS.Failure(128 + self.pending_signal, 'interrotto durante create')
        if creation_failure:
            raise creation_failure
        if not self.record['device']:
            raise IOS.Failure(2, 'create non ha restituito un UUID verificabile')
        if not self.check_device(device, owned=True):
            raise IOS.Failure(2, 'simulatore appena creato assente nel set proprio')
        self.command(['xcrun', 'simctl', 'boot', device], 60)
        self.command(['xcrun', 'simctl', 'bootstatus', device, '-b'], 300)
        self.check_device(device, ready=True, owned=True)
        self.record['ready'] = True  # Solo CLI, vincolo nativeTransport resta BLOCKED.
        self.persist()
        return device

    def cleanup(self):
        self.set_cleanup = 'FAIL'
        result = super().cleanup() if self.record is not None else not self.process_cleanup_failed
        if not result:
            self.set_cleanup = 'BLOCKED'
            return False
        # Nessuna rimozione directory se una prova di processo/risorsa è fallita.
        payload = json.loads(self.command(['xcrun', 'simctl', 'list', 'devices', '--json'],
                                         30, capture=True))
        if any(payload['devices'].values()):
            raise IOS.Failure(2, 'device set non vuoto dopo cleanup')
        self.validate_set()
        shutil.rmtree(self.device_set)
        self.set_cleanup = 'PASS'
        return True


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    parser.add_argument('--keep-ready', action='store_true')
    parser.add_argument('--inventory-scope', choices=('global', 'uuid', 'device-set'),
                        default='global')
    options = parser.parse_args(argv)
    if options.inventory_scope == 'device-set' and options.keep_ready:
        parser.error('device-set è solo diagnostica CLI: trasporto native non verificato')
    output = Path(options.output)
    output.mkdir(mode=0o700, parents=True, exist_ok=False)
    runner_type = {'uuid': UuidInventoryOwner, 'device-set': DedicatedSetOwner}.get(
        options.inventory_scope, IOS.IosOwnedRunner)
    owner = runner_type(output / 'owner.json')
    result = {'schemaVersion': 1, 'scope': 'owned_hosted_simulator_preflight',
              'app': 'NOT_RUN', 'preflight': 'NOT_RUN', 'cleanup': 'NOT_RUN',
              'inventory_scope': options.inventory_scope}
    if options.inventory_scope == 'device-set':
        result.update(preflight_surface='CLI_only', gui='NOT_RUN', native_transport='BLOCKED',
                      device_set_identity=owner.set_identity)
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
                if options.inventory_scope == 'device-set' and not result['cli']['device_set_option']:
                    raise IOS.Failure(2, 'CLI non dichiara il device set richiesto')
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
                if (isinstance(owner, DedicatedSetOwner) or
                        owner.record is not None and owner.owns_receipt) and (
                        primary or not options.keep_ready):
                    for signum in (signal.SIGTERM, signal.SIGINT):
                        signal.signal(signum, signal.SIG_IGN)
                    try:
                        result['cleanup'] = 'PASS' if owner.cleanup() else 'FAIL'
                    except (IOS.Failure, OSError, ValueError, KeyError) as error:
                        result.update(cleanup='FAIL', cleanup_error_type=type(error).__name__)
                    if isinstance(owner, DedicatedSetOwner):
                        result['device_set_cleanup'] = owner.set_cleanup
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
