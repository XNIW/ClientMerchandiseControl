#!/usr/bin/env python3
"""Guest cart: un APK, due processi Android e ricevute native senza VM Service.

Riusa soltanto lifecycle/identity/stop del runner address. Le ricevute del
journal indirizzi non vengono lette o scritte. Solo AVD proprio e dati sintetici.
"""
import importlib.util
import json
from pathlib import Path
import re
import signal
import sys
import uuid


def module(name, filename):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(filename))
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


ADDRESS = module('cmc_guest_cart_android_owner', 'run-address-journal-android.py')
Failure = ADDRESS.Failure
PACKAGE = ADDRESS.PACKAGE
TARGET = 'integration_test/guest_cart_native_restart_test.dart'
RUN_DEFINE = 'CMC_GUEST_CART_RUN_ID'
PHASE_TIMEOUT = 150
MAX_RECEIPT_BYTES = 8192


def receipt_relative_path(run_id, phase):
    if not re.fullmatch(r'[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}', run_id):
        raise Failure('cart-receipt-path', 2, 'run UUID non valido')
    if phase not in ('seed', 'recover'):
        raise Failure('cart-receipt-path', 2, 'fase non valida')
    return f'task054-guest-cart-{run_id}/{phase}.json'


def validate_receipt(data, phase, run_id, process_id, seed_pid):
    receipt_relative_path(run_id, phase)
    if not isinstance(data, dict):
        raise Failure('cart-' + phase, 1, 'ricevuta non oggetto')
    if data.get('status') == 'FAIL':
        expected_keys = {'apiVersion', 'phase', 'runId', 'processId', 'status', 'errorType'}
        if (set(data) != expected_keys or data.get('apiVersion') != 'guest-cart-native-evidence.v1'
                or data.get('phase') != phase or data.get('runId') != run_id
                or data.get('processId') != process_id
                or data.get('errorType') not in ('assertion', 'filesystem', 'unexpected')):
            raise Failure('cart-' + phase, 1, 'ricevuta failure non conforme')
        raise Failure('cart-' + phase, 1, 'fixture nativa segnala failure sanitizzata')
    expected = {
        'apiVersion': 'guest-cart-native-evidence.v1',
        'phase': phase,
        'runId': run_id,
        'processId': process_id,
        'seedProcessId': seed_pid,
        'shopSlug': 'cmc-cart-' + run_id,
        'nativeWriteRead': 'PASS' if phase == 'seed' else 'NOT_RUN',
        'processRestartRead': 'PASS' if phase == 'recover' else 'NOT_RUN',
        'cartUiRestored': 'PASS' if phase == 'recover' else 'NOT_RUN',
        'cleanup': 'PASS' if phase == 'recover' else 'NOT_RUN',
        'backend': 'NOT_RUN',
    }
    if data != expected or (phase == 'recover' and process_id == seed_pid):
        raise Failure('cart-' + phase, 1, 'ricevuta non conforme a fase, run o PID attesi')
    return data


def write_exclusive(path, data):
    with path.open('x', encoding='utf-8') as stream:
        stream.write(json.dumps(data, indent=2) + '\n')


class GuestCartRunner(ADDRESS.AddressJournalRunner):
    def __init__(self, repository):
        super().__init__(repository)
        self.avd_name = 'cmc-guest-cart-' + uuid.uuid4().hex
        self.output = self.repository / 'build/task054/guest-cart-restart'
        self.runner_receipt = self.repository / 'build/task054/guest-cart-restart-receipt.json'

    def prepare_output(self):
        if self.runner_receipt.exists():
            raise Failure(self.phase, 2, 'ricevuta guest cart già presente; nessuna sovrascrittura')
        if self.output.exists():
            raise Failure(self.phase, 2, 'directory guest cart già presente; nessuna cancellazione')
        self.output.mkdir(parents=True)

    def read_fixture(self, phase, process_id, seed_pid):
        self.phase = 'cart-' + phase
        accepted = []
        relative = 'files/' + receipt_relative_path(self.run_id, phase)

        def accept(output):
            if len(output.encode('utf-8')) > MAX_RECEIPT_BYTES:
                raise Failure(self.phase, 1, 'ricevuta troppo grande')
            try:
                data = json.loads(output)
            except ValueError:
                # Nessun JSON parziale vale PASS: si attende il record completo.
                return False
            accepted.append(validate_receipt(data, phase, self.run_id, process_id, seed_pid))
            return True

        # run-as legge solo il sandbox debuggable del package proprio. Nessun
        # attach, forwarding, URI VM, reinstallazione o modificazione del file.
        self.wait_ready('cart-' + phase + '-receipt', PHASE_TIMEOUT,
            [str(self.adb), '-s', self.serial, 'shell', 'run-as', PACKAGE, 'cat', relative], accept)
        _, current = self.device(['shell', 'pidof', PACKAGE])
        if current != str(process_id):
            raise Failure(self.phase, 1, 'processo fixture cambiato durante la fase')
        self.results[phase] = accepted[0]
        write_exclusive(self.output / (phase + '.json'), accepted[0])

    def execute(self):
        self.adb = self.prepare_device()
        self.phase = 'cart-build'
        self.command(['flutter', 'build', 'apk', '--debug', '--no-pub',
            '--target=' + TARGET, '--dart-define=' + RUN_DEFINE + '=' + self.run_id], 600)
        apk = self.repository / 'build/app/outputs/flutter-apk/app-debug.apk'
        digest = ADDRESS.hashlib.sha256(apk.read_bytes()).hexdigest()
        self.phase = 'cart-install-once'
        _, prior = self.device(['shell', 'pm', 'path', PACKAGE], check=False)
        if prior:
            raise Failure(self.phase, 1, 'package già presente; nessuna sovrascrittura')
        self.device(['install', str(apk)], 60)
        identity = self.identity()
        if identity['apk_sha256'] != digest:
            raise Failure(self.phase, 1, 'APK installato diverso dalla build')
        self.results['app_identity'] = identity
        seed_pid = self.launch()
        self.read_fixture('seed', seed_pid, seed_pid)
        self.stop_seed(seed_pid)
        if self.identity() != identity:
            raise Failure(self.phase, 1, 'APK/UID variati dopo force-stop')
        recover_pid = self.launch()
        if recover_pid == seed_pid:
            raise Failure(self.phase, 1, 'PID riutilizzato; restart non attestabile')
        self.read_fixture('recover', recover_pid, seed_pid)
        if self.identity() != identity:
            raise Failure(self.phase, 1, 'APK/UID variati durante recover')
        self.results['same_apk_and_uid'] = 'PASS'
        self.phase = 'cart-complete'

    def run(self):
        code, failed_phase = 0, None
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
        if not code and self.results.get('same_apk_and_uid') != 'PASS':
            code, failed_phase = 1, 'cart-incomplete'
        self.runner_receipt.parent.mkdir(parents=True, exist_ok=True)
        try:
            write_exclusive(self.runner_receipt, {
                'schemaVersion': 1, 'revision': self.revision,
                'evidence_level': 'native_android_guest_cart_fixture',
                'run_id': self.run_id, 'transport': 'app_support_receipt_run_as',
                'api': 35, 'abi': 'x86_64', 'exit_code': code, 'failed_phase': failed_phase,
                'restart': 'PASS' if not code else 'FAIL' if 'seed' in self.results else 'NOT_RUN',
                'cleanup': 'FAIL' if self.cleanup_failed else 'PASS',
                'backend': 'NOT_RUN', 'results': self.results,
            })
        except FileExistsError:
            print('FAIL: ricevuta guest cart preesistente; nessuna sovrascrittura', flush=True)
            return code or 1
        return code


if __name__ == '__main__':
    signal.signal(signal.SIGTERM, ADDRESS.OWNED.interrupted)
    signal.signal(signal.SIGINT, ADDRESS.OWNED.interrupted)
    raise SystemExit(GuestCartRunner(Path(__file__).resolve().parent.parent).run())
