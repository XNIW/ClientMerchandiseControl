#!/usr/bin/env python3
"""Guest cart: stesso bundle/container, due PID e ricevute native senza VM Service.

Simulator ownership e cleanup restano dello step esterno esistente. Nessuna
ricevuta address/Keychain viene modificata; nessuna app viene reinstallata.
"""
import argparse
import importlib.util
import json
from pathlib import Path
import shutil
import signal
import tempfile
import time


def module(name, filename):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(filename))
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


ADDRESS = module('cmc_guest_cart_ios_owner', 'run-address-journal-ios.py')
CART = module('cmc_guest_cart_receipt', 'run-guest-cart-restart-android.py')


class IosGuestCartRunner(ADDRESS.IosJournalRunner):
    def __init__(self, repository, owner_receipt):
        super().__init__(repository, owner_receipt)
        self.output = self.repository / 'build/task054/ios-guest-cart-restart'

    def read_fixture(self, phase, process_id, seed_pid):
        self.phase = 'cart-' + phase
        relative = CART.receipt_relative_path(self.run_id, phase)
        path = self.data / 'Library' / 'Application Support' / relative
        deadline = time.monotonic() + CART.PHASE_TIMEOUT
        while time.monotonic() < deadline:
            self.attest_pid(process_id)
            if path.is_file():
                if path.is_symlink() or self.data.resolve() not in path.resolve().parents:
                    raise ADDRESS.Failure(self.phase, 1, 'ricevuta fuori dal container proprio')
                if path.stat().st_size > CART.MAX_RECEIPT_BYTES:
                    raise ADDRESS.Failure(self.phase, 1, 'ricevuta troppo grande')
                try:
                    data = json.loads(path.read_text(encoding='utf-8'))
                except ValueError:
                    # Un file ancora incompleto non vale PASS.
                    data = None
                if data is not None:
                    accepted = CART.validate_receipt(data, phase, self.run_id, process_id, seed_pid)
                    self.attest_pid(process_id)
                    self.results[phase] = accepted
                    CART.write_exclusive(self.output / (phase + '.json'), accepted)
                    return
            time.sleep(min(0.25, max(0, deadline - time.monotonic())))
        raise ADDRESS.Failure(self.phase, 124, 'ricevuta guest cart non pubblicata entro150s')

    def execute(self):
        self.check_owner()
        _, self.revision = self.command(['git', 'rev-parse', 'HEAD'], 15)
        if not ADDRESS.re.fullmatch(r'[0-9a-f]{40}', self.revision):
            raise ADDRESS.Failure(self.phase, 2, 'revision non verificabile')
        if self.output.exists():
            raise ADDRESS.Failure(self.phase, 2, 'output guest cart già presente; nessuna sovrascrittura')
        self.output.mkdir(parents=True)
        self.owns_output = True
        self.private = Path(tempfile.mkdtemp(prefix='cmc-ios-guest-cart-',
            dir=self.environment.get('RUNNER_TEMP')))
        self.phase = 'cart-build'
        self.command(['flutter', 'build', 'ios', '--simulator', '--debug', '--no-pub',
            '--target=' + CART.TARGET, '--dart-define=' + CART.RUN_DEFINE + '=' + self.run_id], 600)
        app = self.repository / 'build/ios/iphonesimulator/Runner.app'
        self.phase = 'cart-install-once'
        _, inventory = self.simctl(['listapps', self.serial])
        _, converted = self.command(['plutil', '-convert', 'json', '-o', '-', '--', '-'],
            15, input_text=inventory)
        apps = json.loads(converted)
        if not isinstance(apps, dict) or CART.PACKAGE in apps:
            raise ADDRESS.Failure(self.phase, 1, 'inventory non valido o package già presente')
        self.simctl(['install', self.serial, str(app)], 60)
        identity = self.identity()
        if identity['bundle_sha256'] != ADDRESS.bundle_digest(app):
            raise ADDRESS.Failure(self.phase, 1, 'bundle installato diverso dalla build')
        self.results['app_identity'] = identity
        # launch riusa soltanto PID/executable e log privati del runner esistente;
        # URI/service_uri/drive non sono mai chiamati dal percorso guest cart.
        seed, _ = self.launch('seed')
        self.read_fixture('seed', seed, seed)
        self.stop_seed(seed)
        if self.identity() != identity:
            raise ADDRESS.Failure(self.phase, 1, 'bundle/container variati dopo terminate')
        recover, _ = self.launch('recover')
        if recover == seed:
            raise ADDRESS.Failure(self.phase, 1, 'PID riutilizzato; restart non attestabile')
        self.read_fixture('recover', recover, seed)
        if self.identity() != identity:
            raise ADDRESS.Failure(self.phase, 1, 'bundle/container variati durante recover')
        self.results['same_bundle_and_containers'] = 'PASS'
        self.phase = 'cart-complete'

    def run(self):
        code, failed_phase = 0, None
        known_failures = (ADDRESS.Failure, ADDRESS.IOS.Failure, CART.Failure)
        caught_errors = known_failures + (OSError, ValueError, KeyError)
        try:
            self.execute()
        except caught_errors as error:
            code = error.code if isinstance(error, known_failures) else 1
            failed_phase = self.phase
            print(f'FAIL: {self.phase} {type(error).__name__}', flush=True)
        finally:
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
        code = code or (1 if self.cleanup_failed or self.owner.process_cleanup_failed
                        or self.private_cleanup_failed else 0)
        if not code and self.results.get('same_bundle_and_containers') != 'PASS':
            code, failed_phase = 1, 'cart-incomplete'
        if self.owns_output:
            try:
                CART.write_exclusive(self.output / 'runner.json', {
                    'schemaVersion': 1, 'revision': self.revision,
                    'evidence_level': 'native_ios_guest_cart_fixture',
                    'run_id': self.run_id, 'transport': 'owned_app_support_file',
                    'exit_code': code, 'failed_phase': failed_phase,
                    'restart': 'PASS' if not code else 'FAIL' if 'seed' in self.results else 'NOT_RUN',
                    'private_log_cleanup': 'FAIL' if self.private_cleanup_failed else 'PASS',
                    'helper_process_cleanup': 'FAIL' if self.cleanup_failed or self.owner.process_cleanup_failed else 'PASS',
                    'app_process_cleanup': 'NOT_RUN',
                    'app_process_cleanup_reason': 'external_owned_simulator_cleanup_pending',
                    'simulator_cleanup': 'NOT_RUN',
                    'simulator_cleanup_reason': 'separate_owned_cleanup_receipt',
                    'seed_termination': 'simctl_terminate', 'backend': 'NOT_RUN',
                    'results': self.results,
                })
            except FileExistsError:
                return code or 1
        return code


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--owner-receipt', required=True)
    options = parser.parse_args()
    signal.signal(signal.SIGTERM, ADDRESS.ANDROID.OWNED.interrupted)
    signal.signal(signal.SIGINT, ADDRESS.ANDROID.OWNED.interrupted)
    raise SystemExit(IosGuestCartRunner(Path(__file__).resolve().parent.parent,
        options.owner_receipt).run())
