#!/usr/bin/env python3
"""Journal Keychain: stesso bundle, due processi su Simulator proprio già pronto.

Riusa ownership iOS e trasporto/cleanup dei processi esistenti. Nessuna risorsa
viene creata qui: prepare/cleanup del simulatore restano step dedicati del job.
"""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import signal
import tempfile
import time
import uuid


def module(name, filename):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(filename))
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


ANDROID = module('journal_android_contract', 'run-address-journal-android.py')
IOS = module('journal_ios_owner', 'run-task054-ios-owned.py')
Failure = ANDROID.Failure


def bundle_digest(bundle):
    digest = hashlib.sha256()
    for path in sorted(bundle.rglob('*')):
        relative = path.relative_to(bundle).as_posix().encode()
        if path.is_symlink():
            value = b'link:' + os.readlink(path).encode()
        elif path.is_file():
            value = hashlib.sha256(path.read_bytes()).digest()
        else:
            continue
        digest.update(relative + b'\0' + value + b'\0')
    return digest.hexdigest()


class IosJournalRunner(ANDROID.OWNED.AndroidVisualRunner):
    # La base fornisce esclusivamente command() e cleanup dei PGID propri;
    # execute/cleanup Android non sono mai chiamati.
    def __init__(self, repository, owner_receipt):
        super().__init__(repository)
        self.owner = IOS.IosOwnedRunner(owner_receipt)
        # Anche l'inventory owner deve usare lo stesso handler/cleanup dei PGID.
        # Prepare e cleanup Simulator esterni conservano il proprio lifecycle.
        self.owner.command = self.owner_command
        self.output = self.repository / 'build/task054/ios-address-journal'
        self.run_id = str(uuid.uuid4())
        self.private = None
        self.owns_output = False
        self.private_cleanup_failed = False
        self.results = {}
        self.app = None
        self.data = None
        self.executable = None
        self.diagnostics = {}
        self.current_probe = None

    def owner_command(self, arguments, timeout, capture=False):
        return self.command(arguments, timeout, capture=True)[1]

    def check_owner(self):
        self.owner.load()
        record = self.owner.record
        if not record.get('ready') or record.get('cleanup') != 'NOT_RUN' or record.get('processCleanupFailed'):
            raise Failure(self.phase, 2, 'receipt iOS non pronta')
        self.serial = record['device']
        self.owner.check_device(self.serial, ready=True, owned=True)

    def simctl(self, arguments, timeout=30, *, check=True):
        return self.command(['xcrun', 'simctl'] + arguments, timeout, check=check)

    def identity(self):
        _, app = self.simctl(['get_app_container', self.serial, ANDROID.PACKAGE, 'app'])
        _, data = self.simctl(['get_app_container', self.serial, ANDROID.PACKAGE, 'data'])
        app, data = Path(app).resolve(), Path(data).resolve()
        for container in (app, data):
            if not container.is_dir() or self.serial.lower() not in [p.lower() for p in container.parts]:
                raise Failure(self.phase, 1, 'container non appartenente al simulatore proprio')
        info = plistlib.loads((app / 'Info.plist').read_bytes())
        executable = info.get('CFBundleExecutable', '')
        if info.get('CFBundleIdentifier') != ANDROID.PACKAGE or not re.fullmatch(r'[A-Za-z0-9_-]+', executable):
            raise Failure(self.phase, 1, 'bundle installato non valido')
        binary = app / executable
        if not binary.is_file():
            raise Failure(self.phase, 1, 'binario installato assente')
        self.app, self.data, self.executable = app, data, binary
        return {'bundle_sha256': bundle_digest(app),
                'binary_sha256': hashlib.sha256(binary.read_bytes()).hexdigest(),
                'containers_sha256': hashlib.sha256(f'{app}\0{data}'.encode()).hexdigest()}

    def attest_pid(self, process_id):
        code, executable = self.command(['ps', '-p', str(process_id), '-o', 'comm='], 5, check=False)
        matches = code == 0 and bool(executable.strip()) and Path(executable.strip()).resolve() == self.executable
        probe = self.diagnostics.setdefault(self.current_probe or 'unscoped', {})
        probe.update(process_id=process_id, process_state='alive' if code == 0 else 'absent' if code == 1 else 'unknown',
                     executable_matches=matches)
        if not matches:
            raise Failure(self.phase, 1, 'PID non associato al binario installato proprio')

    def launch(self, phase):
        self.check_owner()
        self.current_probe = phase
        self.phase = 'journal-' + phase + '-launch'
        stdout, stderr = [self.private / f'{phase}.{stream}' for stream in ('stdout', 'stderr')]
        for path in (stdout, stderr):
            path.touch(mode=0o600, exist_ok=False)
        _, launched = self.simctl(['launch', '--stdout=' + str(stdout), '--stderr=' + str(stderr),
            self.serial, ANDROID.PACKAGE, '--enable-dart-profiling',
            '--enable-checked-mode', '--verify-entry-points', '--disable-vm-service-publication'])
        match = re.fullmatch(re.escape(ANDROID.PACKAGE) + r': ([1-9][0-9]*)', launched)
        if match is None:
            raise Failure(self.phase, 1, 'launch non restituisce il PID atteso')
        process_id = int(match.group(1))
        self.attest_pid(process_id)
        return process_id, (stdout, stderr)

    def log_metadata(self, logs):
        payloads = []
        sizes = []
        for path in logs:
            sizes.append(path.stat().st_size)
            with path.open('rb') as stream:
                payloads.append(stream.read(256 * 1024))
        text = b'\n'.join(payloads).decode(errors='replace')
        uris = set(re.findall(r'http://127\.0\.0\.1:[0-9]+/[A-Za-z0-9_=-]*/', text))
        probe = self.diagnostics.setdefault(self.current_probe or 'unscoped', {})
        probe.update(stdout_bytes=sizes[0], stderr_bytes=sizes[1],
            vm_uri='found' if len(uris) == 1 else 'ambiguous' if uris else 'not_found',
            stderr_markers=[marker for marker in ('PlatformException', 'MissingPluginException',
                'Unhandled Exception', 'EXC_BAD_ACCESS', 'SIGABRT', 'SIGSEGV') if marker in text],
            crash_cause='NOT_CONFIRMED')
        return uris

    def service_uri(self, process_id, logs):
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            uris = self.log_metadata(logs)
            self.attest_pid(process_id)
            if len(uris) == 1:
                return uris.pop()
            if len(uris) > 1:
                raise Failure(self.phase, 1, 'URI VM ambigua')
            time.sleep(0.1)
        raise Failure(self.phase, 124, 'URI VM propria non disponibile entro 30s')

    def drive(self, phase, process_id, seed_pid, logs):
        self.phase = 'journal-' + phase
        uri = self.service_uri(process_id, logs)
        receipt = self.output / (phase + '.json')
        self.environment['CMC_ADDRESS_JOURNAL_RECEIPT'] = str(receipt)
        # command non stampa argv; check=False evita log della VM anche in failure.
        code, _ = self.command(['flutter', 'drive', '--no-pub', '--use-existing-app=' + uri,
            '--keep-app-running', '-d', self.serial, '--driver=test_driver/address_creation_journal.dart',
            '--target=' + ANDROID.TARGET], 150, check=False)
        if code:
            try:
                self.log_metadata(logs)
            except OSError:
                self.diagnostics.setdefault(phase, {})['log_metadata'] = 'unavailable'
            raise Failure(self.phase, code if code > 0 else 128 - code, 'driver journal fallito')
        data = json.loads(receipt.read_text())
        self.results[phase] = ANDROID.validate_receipt(data, phase, self.run_id, process_id, seed_pid)
        self.attest_pid(process_id)

    def stop_seed(self, process_id):
        self.phase = 'journal-seed-terminate'
        self.check_owner()
        self.attest_pid(process_id)
        # Comando documentato limitato a bundle + UDID attestati, mai kill PID grezzo.
        self.simctl(['terminate', self.serial, ANDROID.PACKAGE])
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            code, state = self.command(['ps', '-p', str(process_id), '-o', 'stat='], 5, check=False)
            if code == 1 and not state or code == 0 and state.startswith('Z'):
                self.results['seed_terminated'] = 'PASS'
                return
            if code not in (0, 1):
                raise Failure(self.phase, 1, 'stato PID non verificabile')
            time.sleep(0.1)
        raise Failure(self.phase, 124, 'processo seed ancora attivo')

    def execute(self):
        self.check_owner()
        _, self.revision = self.command(['git', 'rev-parse', 'HEAD'], 15)
        if not re.fullmatch(r'[0-9a-f]{40}', self.revision):
            raise Failure(self.phase, 2, 'revision non verificabile')
        if self.output.exists():
            raise Failure(self.phase, 2, 'output già presente; nessuna sovrascrittura')
        self.output.mkdir(parents=True)
        self.owns_output = True
        self.private = Path(tempfile.mkdtemp(prefix='cmc-ios-journal-', dir=self.environment.get('RUNNER_TEMP')))
        self.phase = 'journal-build'
        self.command(['flutter', 'build', 'ios', '--simulator', '--debug', '--no-pub',
            '--target=' + ANDROID.TARGET, '--dart-define=ADDRESS_JOURNAL_RUN_ID=' + self.run_id], 600)
        app = self.repository / 'build/ios/iphonesimulator/Runner.app'
        self.phase = 'journal-install-once'
        _, inventory = self.simctl(['listapps', self.serial])
        _, converted = self.command(['plutil', '-convert', 'json', '-o', '-', '--', '-'],
            15, input_text=inventory)
        apps = json.loads(converted)
        if not isinstance(apps, dict):
            raise Failure(self.phase, 1, 'inventario app non valido')
        if ANDROID.PACKAGE in apps:
            raise Failure(self.phase, 1, 'package già presente; nessuna reinstallazione')
        self.simctl(['install', self.serial, str(app)], 60)
        identity = self.identity()
        if identity['bundle_sha256'] != bundle_digest(app):
            raise Failure(self.phase, 1, 'bundle installato diverso dalla build')
        self.results['app_identity'] = identity
        seed, logs = self.launch('seed')
        self.drive('seed', seed, seed, logs)
        self.stop_seed(seed)
        if self.identity() != identity:
            raise Failure(self.phase, 1, 'bundle/container variati dopo terminate')
        recover, logs = self.launch('recover')
        if recover == seed:
            raise Failure(self.phase, 1, 'PID riutilizzato; restart non attestabile')
        self.drive('recover', recover, seed, logs)
        if self.identity() != identity:
            raise Failure(self.phase, 1, 'bundle/container variati durante recover')
        self.results['same_bundle_and_containers'] = 'PASS'
        self.phase = 'journal-complete'

    def run(self):
        code, failed_phase, failure_reason = 0, None, None
        try:
            self.execute()
        except (Failure, IOS.Failure, OSError, ValueError, KeyError) as error:
            code = error.code if isinstance(error, (Failure, IOS.Failure)) else 1
            failed_phase = self.phase
            failure_reason = str(error) if isinstance(error, (Failure, IOS.Failure)) else type(error).__name__
            print(f'FAIL: {self.phase} {type(error).__name__}', flush=True)
        finally:
            try:
                if self.private is not None:
                    for phase in ('seed', 'recover'):
                        logs = [self.private / f'{phase}.{stream}' for stream in ('stdout', 'stderr')]
                        if all(path.is_file() for path in logs):
                            self.current_probe = phase
                            self.log_metadata(logs)
            except OSError:
                self.diagnostics['log_metadata'] = 'unavailable'
            try:
                if self.private is not None:
                    shutil.rmtree(self.private)
            except OSError:
                self.private_cleanup_failed = True
            if (self.cleanup_failed or self.owner.process_cleanup_failed) and self.owner.record is not None:
                self.owner.process_cleanup_failed = True
                try:
                    self.owner.persist()
                except OSError:
                    self.cleanup_failed = True
        code = code or (1 if self.cleanup_failed or self.owner.process_cleanup_failed or self.private_cleanup_failed else 0)
        if not code and self.results.get('same_bundle_and_containers') != 'PASS':
            code, failed_phase = 1, 'journal-incomplete'
        # Ownership Simulator resta al workflow, che esegue cleanup anche in FAIL.
        if self.owns_output:
            receipt = self.output / 'runner.json'
            if receipt.exists():
                return code or 1
            receipt.write_text(json.dumps({'schemaVersion': 1, 'revision': self.revision,
                'evidence_level': 'native_ios_simulator_fixture', 'run_id': self.run_id,
                'exit_code': code, 'failed_phase': failed_phase, 'backend': 'NOT_RUN',
                'failure_reason': failure_reason, 'diagnostics': self.diagnostics,
                'restart': 'PASS' if not code else 'FAIL' if 'seed' in self.results else 'NOT_RUN',
                'private_log_cleanup': 'FAIL' if self.private_cleanup_failed else 'PASS',
                'process_cleanup': 'FAIL' if self.cleanup_failed or self.owner.process_cleanup_failed else 'PASS',
                'simulator_cleanup': 'NOT_RUN', 'simulator_cleanup_reason': 'separate_owned_cleanup_receipt',
                'termination': 'simctl_terminate', 'results': self.results}, indent=2) + '\n')
        return code


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--owner-receipt', required=True)
    options = parser.parse_args()
    signal.signal(signal.SIGTERM, ANDROID.OWNED.interrupted)
    signal.signal(signal.SIGINT, ANDROID.OWNED.interrupted)
    raise SystemExit(IosJournalRunner(Path(__file__).resolve().parent.parent, options.owner_receipt).run())
