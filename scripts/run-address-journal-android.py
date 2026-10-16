#!/usr/bin/env python3
"""Un APK, due processi Android: verifica journal cifrato dopo force-stop.

Solo AVD Linux/KVM proprio e dati sintetici. Nessun backend o device condiviso.
Il lifecycle AVD e i gruppi di processi riusano il runner visuale collaudato.
"""
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import signal
import sys
import uuid
from urllib.parse import urlsplit

_SPEC = importlib.util.spec_from_file_location('cmc_android_owned',
    Path(__file__).with_name('run-task054-android-visual.py'))
OWNED = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(OWNED)
Failure = OWNED.Failure
PACKAGE = 'com.xniw.clientmerchandisecontrol'
TARGET = 'integration_test/address_creation_journal_native_test.dart'


def validate_receipt(data, phase, run_id, process_id, seed_pid):
    expected = {
        'apiVersion': 'address-journal-native-evidence.v2', 'phase': phase,
        'runId': run_id, 'processId': process_id, 'seedProcessId': seed_pid,
        'nativeWriteRead': 'PASS' if phase == 'seed' else 'NOT_RUN',
        'processRestartRead': 'PASS' if phase == 'recover' else 'NOT_RUN',
        'cleanup': 'PASS' if phase == 'recover' else 'NOT_RUN',
        'backend': 'NOT_RUN',
    }
    if data != expected or (phase == 'recover' and process_id == seed_pid):
        raise Failure('receipt-validation', 1, 'ricevuta non conforme al processo e fase attesi')
    return data


class AddressJournalRunner(OWNED.AndroidVisualRunner):
    def __init__(self, repository):
        super().__init__(repository)
        self.run_id = str(uuid.uuid4())
        self.avd_name = 'cmc-address-journal-' + uuid.uuid4().hex
        self.output = self.repository / 'build/task054/address-journal'
        self.adb = None
        self.forwards = set()
        self.results = {}

    def prepare_output(self):
        if (self.repository / 'build/task054/address-journal-receipt.json').exists():
            raise Failure(self.phase, 2, 'ricevuta runner già presente; nessuna sovrascrittura')
        if self.output.exists() and any(self.output.iterdir()):
            raise Failure(self.phase, 2, 'directory journal non vuota; nessuna cancellazione')
        self.output.mkdir(parents=True, exist_ok=True)

    def device(self, arguments, timeout=15, *, check=True):
        return self.command([str(self.adb), '-s', self.serial] + arguments,
            timeout, check=check)

    def identity(self):
        _, packages = self.device(['shell', 'cmd', 'package', 'list', 'packages', '-U', PACKAGE])
        match = re.fullmatch(r'package:' + re.escape(PACKAGE) + r' uid:([0-9]+)', packages)
        if match is None:
            raise Failure(self.phase, 1, 'UID applicazione non verificabile')
        _, path = self.device(['shell', 'pm', 'path', PACKAGE])
        if not re.fullmatch(r'package:/data/app/[A-Za-z0-9_./=+~-]+/base\.apk', path):
            raise Failure(self.phase, 1, 'APK installato non univoco')
        apk_path = path.removeprefix('package:')
        _, checksum = self.device(['shell', 'sha256sum', apk_path])
        digest = checksum.split()[0] if checksum else ''
        if not re.fullmatch(r'[0-9a-f]{64}', digest):
            raise Failure(self.phase, 1, 'hash APK installato non verificabile')
        return {'uid': int(match.group(1)), 'apk_sha256': digest}

    def launch(self):
        self.device(['shell', 'am', 'start', '-W', '-n', PACKAGE + '/.MainActivity',
            '-a', 'android.intent.action.MAIN', '-c', 'android.intent.category.LAUNCHER',
            '--ez', 'enable-dart-profiling', 'true', '--ez', 'enable-checked-mode', 'true',
            '--ez', 'verify-entry-points', 'true'])
        target = [str(self.adb), '-s', self.serial]
        self.wait_ready('journal-process-start', 20,
            target + ['shell', 'pidof', PACKAGE],
            lambda value: re.fullmatch(r'[1-9][0-9]*', value) is not None)
        _, process = self.device(['shell', 'pidof', PACKAGE])
        if not re.fullmatch(r'[1-9][0-9]*', process):
            raise Failure(self.phase, 1, 'PID app non univoco')
        return int(process)

    def service_uri(self, process_id):
        found = []

        def service_ready(output):
            uris = re.findall(r'http://127\.0\.0\.1:[0-9]+/[A-Za-z0-9_=-]*/', output)
            if len(set(uris)) == 1:
                found[:] = uris[:1]
                return True
            return False

        # Logcat limitato al processo fixture. URI VM effimera mai salvata nei log.
        self.wait_ready('journal-vm-ready', 30,
            [str(self.adb), '-s', self.serial, 'logcat', '-d', '--pid', str(process_id),
             '-s', 'flutter:I'], service_ready)
        parsed = urlsplit(found[0])
        _, forwarded = self.device(['forward', 'tcp:0', f'tcp:{parsed.port}'])
        if not re.fullmatch(r'[1-9][0-9]{0,4}', forwarded) or int(forwarded) > 65535:
            raise Failure(self.phase, 1, 'forward VM non verificabile')
        self.forwards.add(forwarded)
        return f'http://127.0.0.1:{forwarded}{parsed.path}'

    def drive(self, phase, process_id, seed_pid):
        uri = self.service_uri(process_id)
        self.phase = 'journal-' + phase
        path = self.output / (phase + '.json')
        self.environment['CMC_ADDRESS_JOURNAL_RECEIPT'] = str(path)
        # use-existing-app evita i percorsi install/reinstall e avvio automatico.
        # Output non pubblicato: potrebbe contenere l'URI effimera della VM.
        code, _ = self.command(['flutter', 'drive', '--no-pub',
            '--use-existing-app=' + uri, '--keep-app-running', '-d', self.serial,
            '--driver=test_driver/address_creation_journal.dart', '--target=' + TARGET],
            150, check=False)
        if code:
            exit_code = code if code > 0 else 128 - code
            raise Failure(self.phase, exit_code,
                'driver fixture fallito; output sensibile non pubblicato')
        if not path.is_file():
            raise Failure(self.phase, 1, 'ricevuta fixture assente')
        data = json.loads(path.read_text())
        self.results[phase] = validate_receipt(data, phase, self.run_id, process_id, seed_pid)
        _, current = self.device(['shell', 'pidof', PACKAGE])
        if current != str(process_id):
            raise Failure(self.phase, 1, 'processo fixture cambiato durante il test')

    def stop_seed(self, seed_pid):
        self.phase = 'journal-seed-force-stop'
        self.device(['shell', 'am', 'force-stop', PACKAGE])
        self.wait_ready('journal-seed-absent', 10,
            [str(self.adb), '-s', self.serial, 'shell', 'test', '!', '-e', f'/proc/{seed_pid}'],
            lambda output: output == '')
        code, remaining = self.device(['shell', 'pidof', PACKAGE], check=False)
        if code not in (0, 1) or remaining:
            raise Failure(self.phase, 1, 'processo app ancora presente dopo force-stop')
        self.results['seed_terminated'] = 'PASS'

    def execute(self):
        self.adb = self.prepare_device()
        self.phase = 'journal-build'
        self.command(['flutter', 'build', 'apk', '--debug', '--no-pub',
            '--target=' + TARGET, '--dart-define=ADDRESS_JOURNAL_RUN_ID=' + self.run_id], 600)
        apk = self.repository / 'build/app/outputs/flutter-apk/app-debug.apk'
        digest = hashlib.sha256(apk.read_bytes()).hexdigest()
        self.phase = 'journal-install-once'
        _, prior = self.device(['shell', 'pm', 'path', PACKAGE], check=False)
        if prior:
            raise Failure(self.phase, 1, 'AVD proprio contiene già il package; nessuna sovrascrittura')
        self.device(['install', str(apk)], 60)
        identity = self.identity()
        if identity['apk_sha256'] != digest:
            raise Failure(self.phase, 1, 'APK installato diverso dalla build')
        self.results['app_identity'] = identity
        seed_pid = self.launch()
        self.drive('seed', seed_pid, seed_pid)
        self.stop_seed(seed_pid)
        if self.identity() != identity:
            raise Failure(self.phase, 1, 'identità app variata dopo force-stop')
        recover_pid = self.launch()
        if recover_pid == seed_pid:
            raise Failure(self.phase, 1, 'PID riutilizzato: restart non attestabile')
        self.drive('recover', recover_pid, seed_pid)
        if self.identity() != identity:
            raise Failure(self.phase, 1, 'identità app variata durante recover')
        self.results['same_apk_and_uid'] = 'PASS'
        self.phase = 'journal-complete'

    def cleanup(self):
        # Si rimuovono soltanto i port-forward creati da questa istanza.
        deferred = None
        for port in list(self.forwards):
            try:
                self.device(['forward', '--remove', 'tcp:' + port])
                self.forwards.remove(port)
            except BaseException as error:
                self.cleanup_failed = True
                deferred = deferred or error
        try:
            super().cleanup()
        finally:
            if deferred is not None:
                raise deferred

    def run(self):
        code = 0
        failed_phase = None
        try:
            self.execute()
        except (Failure, OSError, ValueError) as error:
            code = error.code if isinstance(error, Failure) else 1
            failed_phase = self.phase
            print(f'FAIL: {self.phase} {type(error).__name__}', flush=True)
        finally:
            try:
                self.cleanup()
            except (Failure, OSError) as error:
                if not code:
                    code = error.code if isinstance(error, Failure) else 1
                    failed_phase = self.phase
        code = code or (1 if self.cleanup_failed else 0)
        # Un output preesistente non viene sovrascritto neppure nel preflight.
        receipt = self.repository / 'build/task054/address-journal-receipt.json'
        receipt.parent.mkdir(parents=True, exist_ok=True)
        if receipt.exists():
            print('FAIL: ricevuta runner preesistente; nessuna sovrascrittura', flush=True)
            return code or 1
        receipt.write_text(json.dumps({'schemaVersion': 1, 'revision': self.revision,
            'evidence_level': 'native_android_fixture', 'run_id': self.run_id,
            'api': 35, 'abi': 'x86_64', 'exit_code': code, 'failed_phase': failed_phase,
            'restart': ('PASS' if not code and self.results.get('same_apk_and_uid') == 'PASS'
                        else 'FAIL' if 'seed' in self.results else 'NOT_RUN'),
            'cleanup': 'FAIL' if self.cleanup_failed else 'PASS',
            'backend': 'NOT_RUN', 'results': self.results}, indent=2) + '\n')
        return code


if __name__ == '__main__':
    signal.signal(signal.SIGTERM, OWNED.interrupted)
    signal.signal(signal.SIGINT, OWNED.interrupted)
    sys.exit(AddressJournalRunner(Path(__file__).resolve().parent.parent).run())
