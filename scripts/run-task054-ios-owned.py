#!/usr/bin/env python3
"""Un simulatore iOS proprio, riusabile fra smoke e visual in step separati."""
import argparse
import json
import os
from pathlib import Path
import re
import signal
import stat
import subprocess
import tempfile
import time
import uuid

UUID = re.compile(r'^[0-9A-Fa-f]{8}(?:-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12}$')
PREFIX = 'CMC-Task054-Owned-'
OWNER_CONTEXT = ('GITHUB_RUN_ID', 'GITHUB_RUN_ATTEMPT', 'GITHUB_JOB', 'GITHUB_SHA')
SMOKE = ['flutter', 'test', 'integration_test/app_shell_smoke_test.dart',
         '--no-pub', '--reporter', 'expanded', '--verbose']


class Failure(Exception):
    def __init__(self, code, reason, output=''):
        super().__init__(reason)
        self.code, self.output = code, output


def process_diagnostic(operation, error=None, **metadata):
    # Mai str(error), cmd, stdout, stderr o nomi/argomenti di processi altrui.
    detail = dict(operation=operation, **metadata)
    if error is not None:
        detail['errorType'] = type(error).__name__
        if isinstance(error, subprocess.TimeoutExpired):
            detail['timeoutSeconds'] = error.timeout
        elif isinstance(error, OSError):
            detail['errno'] = error.errno
        elif isinstance(error, Failure):
            detail['failureCode'] = error.code
    print('DIAGNOSTIC: ' + json.dumps(detail, sort_keys=True), flush=True)


def group_has_live_members(group):
    # Solo metadati pgid/stato, mai argomenti o dati applicativi.
    try:
        result = subprocess.run(['ps', '-axo', 'pgid=,stat='], capture_output=True,
                                text=True, timeout=2, check=False)
    except (OSError, subprocess.TimeoutExpired) as error:
        process_diagnostic('psProbe', error, ownedPgid=group)
        raise
    if result.returncode:
        process_diagnostic('psProbe', ownedPgid=group, reason='exitStatus',
                           exitCode=result.returncode, rowCount=len(result.stdout.splitlines()))
        raise Failure(1, 'process-group probe fallita')
    alive = False
    rows = result.stdout.splitlines()
    for line in rows:
        fields = line.split()
        if len(fields) != 2 or not fields[0].isdigit():
            process_diagnostic('psProbe', ownedPgid=group, reason='shape',
                               rowCount=len(rows), fieldCount=len(fields),
                               numericPgid=bool(fields and fields[0].isdigit()))
            raise Failure(1, 'process-group probe non verificabile')
        if int(fields[0]) == group and not fields[1].startswith('Z'):
            alive = True
    return alive


def stop_owned_process(process):
    """Il leader terminato non dimostra che i discendenti siano terminati."""
    probe_error = None
    for sig in (signal.SIGTERM, signal.SIGKILL):
        try:
            os.killpg(process.pid, sig)
        except ProcessLookupError:
            pass
        deadline = time.monotonic() + 5
        while True:
            try:
                if not group_has_live_members(process.pid):
                    process.wait(timeout=2)
                    if probe_error:
                        raise probe_error
                    return
            except (OSError, subprocess.TimeoutExpired, Failure) as error:
                probe_error = error
                break  # Il KILL del solo gruppo proprio viene comunque tentato.
            if time.monotonic() >= deadline:
                break
            time.sleep(0.05)
    if probe_error:
        raise probe_error
    process_diagnostic('ownedGroupVerification', ownedPgid=process.pid,
                       reason='liveMembersAfterKill')
    raise Failure(1, 'process-group proprio ancora attivo dopo cleanup bounded')


class IosOwnedRunner:
    def __init__(self, receipt=None):
        self.receipt = Path(receipt) if receipt else None
        self.record = None
        self.owns_receipt = False
        self.phase = 'initial'
        self.pending_signal = None
        self.process_cleanup_signal = None
        self.process_cleanup_failed = False
        self.observed_device_state = None

    def interrupted(self, signum, _frame):
        if self.phase == 'process_cleanup':
            if self.process_cleanup_signal is None:
                self.process_cleanup_signal = signum
            return  # Quiescenza bounded prima di riproporre il primo segnale.
        if self.phase == 'create':
            # Create bounded30: acquisire UUID prima di reagire consente cleanup
            # quando TERM arriva tra la creazione e la risposta del provider.
            if self.pending_signal is None:
                self.pending_signal = signum
            return
        raise Failure(128 + signum, 'interrotto')

    def command(self, arguments, timeout, capture=False):
        print('+ ' + ' '.join(arguments), flush=True)
        process = subprocess.Popen(arguments, start_new_session=True,
                                   stdout=subprocess.PIPE if capture else None,
                                   text=True)
        primary, output = None, ''
        try:
            output, _ = process.communicate(timeout=timeout)
            output = output or ''
            if process.returncode:
                primary = Failure(process.returncode if process.returncode > 0
                                  else 128 - process.returncode,
                                  'comando fallito', output)
        except subprocess.TimeoutExpired as error:
            captured = error.output or ''
            output = captured.decode() if isinstance(captured, bytes) else captured
            primary = Failure(124, f'timeout dopo {timeout}s', output)
        except BaseException as error:
            primary = error
        finally:
            previous_phase = self.phase
            self.phase = 'process_cleanup'
            self.process_cleanup_signal = None
            try:
                must_stop = primary is not None
                if not must_stop:
                    try:
                        must_stop = group_has_live_members(process.pid)
                    except (OSError, subprocess.TimeoutExpired, Failure) as error:
                        process_diagnostic('commandProbe', error, ownedPgid=process.pid)
                        self.process_cleanup_failed = True
                        must_stop = True
                        primary = Failure(1, 'probe processi non verificata', output)
                try:
                    # Anche successo del leader con figli rimasti va verificato.
                    if must_stop:
                        stop_owned_process(process)
                except (OSError, subprocess.TimeoutExpired, Failure) as error:
                    process_diagnostic('commandCleanup', error, ownedPgid=process.pid)
                    self.process_cleanup_failed = True
                    print('FAIL: cleanup del gruppo proprio non verificato', flush=True)
                    if primary is None:
                        primary = Failure(1, 'cleanup processi fallito', output)
            finally:
                self.phase = previous_phase
            if primary is None and self.process_cleanup_signal is not None:
                primary = Failure(128 + self.process_cleanup_signal,
                                  'interrotto durante cleanup processi', output)
        if primary is not None:
            raise primary
        return output

    def persist(self, exclusive=False):
        self.record['processCleanupFailed'] = bool(
            self.process_cleanup_failed or self.record.get('processCleanupFailed'))
        encoded = json.dumps(self.record, indent=2) + '\n'
        if exclusive:
            with os.fdopen(os.open(self.receipt, os.O_WRONLY | os.O_CREAT | os.O_EXCL,
                                   0o600), 'w') as output:
                output.write(encoded)
            self.owns_receipt = True
            return
        with tempfile.NamedTemporaryFile(mode='w', dir=self.receipt.parent,
                                         delete=False) as output:
            temporary = Path(output.name)
            output.write(encoded)
        try:
            os.replace(temporary, self.receipt)
        finally:
            temporary.unlink(missing_ok=True)

    def device_record(self, device):
        payload = json.loads(self.command(
            ['xcrun', 'simctl', 'list', 'devices', '--json'], 30, capture=True))
        found = [(entry, runtime) for runtime, entries in payload['devices'].items()
                 for entry in entries if entry.get('udid', '').lower() == device.lower()]
        if len(found) > 1:
            raise Failure(2, 'identità simulatore ambigua')
        return found[0] if found else (None, None)

    def check_device(self, device, ready=False, owned=False):
        if not UUID.fullmatch(device):
            raise Failure(2, 'UUID simulatore invalido')
        entry, runtime = self.device_record(device)
        self.observed_device_state = entry.get('state') if entry else None
        if entry is None:
            if ready:
                raise Failure(2, 'simulatore richiesto assente')
            return False
        if owned and (entry.get('name') != self.record['name'] or
                      runtime != self.record['runtime']):
            raise Failure(2, 'ownership simulatore non coincide: nessuna mutazione')
        if ready and (not entry.get('isAvailable') or entry.get('state') != 'Booted'):
            raise Failure(2, 'simulatore richiesto non Booted/disponibile')
        return True

    def prepare(self):
        self.record = {'schemaVersion': 1, 'nonce': uuid.uuid4().hex,
                       'device': None, 'creationStarted': False, 'cleanup': 'NOT_RUN'}
        self.record['ownerContext'] = {key: os.environ.get(key) for key in OWNER_CONTEXT}
        self.record['name'] = PREFIX + self.record['nonce']
        self.persist(exclusive=True)  # Nessuna creazione se la receipt esiste.
        developer = os.environ.get('DEVELOPER_DIR') or self.command(
            ['xcode-select', '-p'], 15, capture=True).strip()
        simulator = developer + '/Applications/Simulator.app'
        if not Path(simulator).is_dir():
            raise Failure(2, 'Simulator.app assente nella toolchain selezionata')
        payload = json.loads(self.command(['xcrun', 'simctl', 'list', 'runtimes',
                                          '--json'], 30, capture=True))
        available = [runtime for runtime in payload['runtimes']
                     if runtime.get('isAvailable') and runtime['identifier'].startswith(
                         'com.apple.CoreSimulator.SimRuntime.iOS-26-')]
        if not available:
            raise Failure(2, 'runtime iOS26 compatibile assente')
        runtime = max(available, key=lambda row: tuple(map(int, row['version'].split('.'))))
        self.record['runtime'] = runtime['identifier']
        self.record['creationStarted'] = True
        self.persist()
        self.phase = 'create'
        creation_failure, device = None, ''
        try:
            device = self.command(['xcrun', 'simctl', 'create', self.record['name'],
                                  'com.apple.CoreSimulator.SimDeviceType.iPhone-17',
                                  self.record['runtime']], 30, capture=True).strip()
        except Failure as error:
            creation_failure, device = error, error.output.strip()
        self.phase = 'prepare'
        if UUID.fullmatch(device):
            self.record['device'] = device
            self.persist()  # Ownership durevole prima di boot/open.
        if self.pending_signal:
            raise Failure(128 + self.pending_signal, 'interrotto durante create')
        if creation_failure:
            raise creation_failure
        if not self.record['device']:
            raise Failure(2, 'create non ha restituito un UUID verificabile')
        self.check_device(device, owned=True)
        self.command(['xcrun', 'simctl', 'boot', device], 60)
        self.command(['open', '-a', simulator, '--args', '-CurrentDeviceUDID', device], 60)
        self.command(['xcrun', 'simctl', 'bootstatus', device, '-b'], 300)
        self.check_device(device, ready=True, owned=True)
        self.record['ready'] = True
        self.persist()
        return device

    def load(self):
        metadata = self.receipt.lstat()
        if not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != os.geteuid() or \
                metadata.st_mode & 0o077:
            raise Failure(2, 'receipt ownership non privata/regolare')
        record = json.loads(self.receipt.read_text())
        if record.get('schemaVersion') != 1 or not re.fullmatch(
                r'[0-9a-f]{32}', record.get('nonce', '')) or \
                record.get('name') != PREFIX + record['nonce']:
            raise Failure(2, 'receipt ownership invalida')
        if record.get('ownerContext') != {key: os.environ.get(key) for key in OWNER_CONTEXT}:
            raise Failure(2, 'receipt di altra run/job/revisione: nessuna mutazione')
        self.record = record

    def cleanup(self):
        self.phase = 'cleanup'
        if not self.owns_receipt:
            self.load()
        # Solo receipt acquisita con O_EXCL o appena validata da load().
        attempts = self.record.setdefault('cleanupAttempts', [])
        if not isinstance(attempts, list):
            raise Failure(2, 'receipt tentativi cleanup invalida')
        incomplete = any(attempt.get('result') == 'NOT_RUN' for attempt in attempts)
        process_failed = bool(self.process_cleanup_failed or self.record.get('processCleanupFailed'))
        failed = process_failed or self.record.get('cleanup') == 'FAIL'
        attempt = {'attempt': len(attempts) + 1, 'result': 'NOT_RUN',
                   'resourceCleanup': 'NOT_RUN', 'processCleanupFailed': process_failed}
        attempts.append(attempt)
        if failed:
            self.record['cleanup'] = 'FAIL'
        self.persist()  # Flag durevole prima di inventory/readback che possono sollevare.
        primary = None
        try:
            resource_result = self.cleanup_device()
        except (Failure, OSError, ValueError, KeyError) as error:
            primary, resource_result = error, 'FAIL'
            attempt['errorType'] = type(error).__name__
        process_failed = bool(self.process_cleanup_failed or self.record.get('processCleanupFailed'))
        failed = failed or process_failed or resource_result == 'FAIL'
        self.record['cleanup'] = 'FAIL' if failed else 'BLOCKED' if incomplete else resource_result
        attempt.update(result=self.record['cleanup'], resourceCleanup=resource_result,
                       processCleanupFailed=process_failed)
        try:
            self.persist()
        except (OSError, ValueError, KeyError) as error:
            print(f'FAIL: persistenza cleanup ({type(error).__name__})', flush=True)
            if primary is None:
                primary = error
        if primary is not None:
            raise primary
        return self.record['cleanup'] == 'PASS'

    def cleanup_device(self):
        device = self.record.get('device')
        if not device:
            return 'BLOCKED' if self.record.get('creationStarted') else 'PASS'
        # Identità diversa impedisce sia shutdown sia delete.
        if not self.check_device(device, owned=True):
            return 'PASS'
        failed = False
        actions = ('delete',) if self.observed_device_state == 'Shutdown' else ('shutdown', 'delete')
        for action in actions:
            try:
                self.command(['xcrun', 'simctl', action, device], 30)
            except (OSError, Failure) as error:
                failed = True
                print(f'FAIL: cleanup {action} {type(error).__name__}', flush=True)
        if self.check_device(device, owned=True):
            failed = True
        return 'FAIL' if failed else 'PASS'

    def smoke(self, device):
        self.phase = 'smoke'
        primary = None
        try:
            if self.receipt is None:
                raise Failure(2, 'smoke --device richiede la receipt privata della run')
            if self.record is None:
                self.load()
            if not UUID.fullmatch(device) or device.lower() != str(
                    self.record.get('device')).lower():
                raise Failure(2, 'UUID smoke non coincide con la receipt: nessuna mutazione')
            if not self.record.get('ready') or self.record.get('cleanup') != 'NOT_RUN' or \
                    self.record.get('processCleanupFailed'):
                raise Failure(2, 'receipt smoke non pronta o cleanup precedente fallito')
            self.check_device(device, ready=True, owned=True)
            self.command(SMOKE + ['-d', device], 900)
        except (Failure, OSError, ValueError, KeyError) as error:
            primary = error
        finally:
            if self.record is not None and self.process_cleanup_failed:
                try:
                    self.persist()
                except (OSError, ValueError, KeyError) as error:
                    print(f'FAIL: persistenza cleanup processi ({type(error).__name__})', flush=True)
                    if primary is None:
                        primary = Failure(2, 'receipt cleanup processi non aggiornata')
        if primary is not None:
            raise primary


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    subcommands = parser.add_subparsers(dest='action', required=True)
    prepare = subcommands.add_parser('prepare')
    prepare.add_argument('--receipt', required=True)
    prepare.add_argument('--github-output')
    cleanup = subcommands.add_parser('cleanup')
    cleanup.add_argument('--receipt', required=True)
    smoke = subcommands.add_parser('smoke')
    smoke.add_argument('--device')
    smoke.add_argument('--receipt', default=os.environ.get('CMC_IOS_OWNED_RECEIPT'))
    options = parser.parse_args(argv)
    standalone = options.action == 'smoke' and options.device is None
    receipt = getattr(options, 'receipt', None)
    if standalone:
        receipt = Path(tempfile.mkdtemp(prefix='cmc-ios-owned-')) / 'receipt.json'
    runner = IosOwnedRunner(receipt)
    for signum in (signal.SIGTERM, signal.SIGINT):
        signal.signal(signum, runner.interrupted)
    primary = 0
    must_cleanup = options.action == 'cleanup'
    try:
        if options.action == 'prepare' or standalone:
            device = runner.prepare()
            if options.action == 'prepare' and options.github_output:
                with open(options.github_output, 'a') as output:
                    output.write('device_id=' + device + '\n')
            if options.action == 'prepare':
                print('READY: simulatore proprio preparato per smoke e visual', flush=True)
        if options.action == 'smoke':
            runner.smoke(device if standalone else options.device)
    except (Failure, OSError, ValueError, KeyError) as error:
        primary = error.code if isinstance(error, Failure) else 2
        print(f'FAIL: {error}', flush=True)
        must_cleanup = must_cleanup or runner.owns_receipt
    finally:
        must_cleanup = must_cleanup or (standalone and runner.owns_receipt)
        if must_cleanup:
            # Non interrompere il cleanup proprio per un secondo TERM/INT.
            for signum in (signal.SIGTERM, signal.SIGINT):
                signal.signal(signum, signal.SIG_IGN)
            try:
                if not runner.cleanup() and primary == 0:
                    primary = 1
            except (Failure, OSError, ValueError, KeyError) as error:
                print(f'FAIL: cleanup non verificato ({type(error).__name__})', flush=True)
                if primary == 0:
                    primary = 1
    return primary


if __name__ == '__main__':
    raise SystemExit(main())
