#!/usr/bin/env python3
"""Regressioni dei confini evidence guest cart, senza SDK, emulatori o app.

Da eseguire soltanto dopo l'integrazione della proposta nel checkout autorizzato.
Non sostituisce il gate seed/stop/recover nativo.
"""
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


def module(name, filename):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(filename))
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


A = module('guest_cart_android_under_test', 'run-guest-cart-restart-android.py')
I = module('guest_cart_ios_under_test', 'run-guest-cart-restart-ios.py')
RUN_ID = 'f0540000-0000-4000-8000-000000000002'


def receipt(phase='seed', process_id=12, seed_pid=12):
    return {
        'apiVersion': 'guest-cart-native-evidence.v1', 'phase': phase,
        'runId': RUN_ID, 'processId': process_id, 'seedProcessId': seed_pid,
        'shopSlug': 'cmc-cart-' + RUN_ID,
        'nativeWriteRead': 'PASS' if phase == 'seed' else 'NOT_RUN',
        'processRestartRead': 'PASS' if phase == 'recover' else 'NOT_RUN',
        'cartUiRestored': 'PASS' if phase == 'recover' else 'NOT_RUN',
        'cleanup': 'PASS' if phase == 'recover' else 'NOT_RUN', 'backend': 'NOT_RUN',
    }


class GuestCartReceiptTest(unittest.TestCase):
    def test_seed_cannot_be_replayed_as_recover_or_reuse_seed_pid(self):
        with self.assertRaises(A.Failure):
            A.validate_receipt(receipt(), 'recover', RUN_ID, 13, 12)
        with self.assertRaises(A.Failure):
            A.validate_receipt(receipt('recover', 12), 'recover', RUN_ID, 12, 12)

    def test_wrong_owner_scope_run_or_missing_ui_cleanup_cannot_claim_restart(self):
        for key, value in [('runId', 'stale'), ('shopSlug', 'cmc-cart-foreign'),
                ('processId', 12), ('seedProcessId', 99), ('backend', 'PASS'),
                ('cartUiRestored', 'NOT_RUN'), ('cleanup', 'NOT_RUN')]:
            with self.subTest(key=key):
                data = receipt('recover', 13)
                data[key] = value
                with self.assertRaises(A.Failure):
                    A.validate_receipt(data, 'recover', RUN_ID, 13, 12)

    def test_sanitized_fixture_failure_never_becomes_success(self):
        data = {'apiVersion': 'guest-cart-native-evidence.v1', 'phase': 'seed',
            'runId': RUN_ID, 'processId': 12, 'status': 'FAIL', 'errorType': 'assertion'}
        with self.assertRaises(A.Failure):
            A.validate_receipt(data, 'seed', RUN_ID, 12, 12)

    def test_path_cannot_escape_run_or_select_an_unrecognized_phase(self):
        for run, phase in [('../foreign', 'seed'), (RUN_ID, '../recover'), (RUN_ID, 'other')]:
            with self.subTest(run=run, phase=phase), self.assertRaises(A.Failure):
                A.receipt_relative_path(run, phase)

    def test_android_cart_failure_preserves_existing_address_receipt(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            address = root / 'build/task054/address-journal-receipt.json'
            address.parent.mkdir(parents=True)
            address.write_text('preserve address evidence')
            runner = A.GuestCartRunner(root)
            with patch.object(runner, 'execute', side_effect=A.Failure('cart-seed', 7, 'fixture')), \
                 patch.object(runner, 'cleanup'):
                self.assertEqual(runner.run(), 7)
            self.assertEqual(address.read_text(), 'preserve address evidence')
            data = json.loads(runner.runner_receipt.read_text())
            self.assertEqual(data['restart'], 'NOT_RUN')
            self.assertEqual(data['exit_code'], 7)
            self.assertNotEqual(data['evidence_level'], 'native_android_fixture')

    def test_one_apk_install_and_native_stop_without_vm_or_flutter_drive(self):
        for fail_seed in (False, True):
            with self.subTest(fail_seed=fail_seed), tempfile.TemporaryDirectory() as directory:
                runner = A.GuestCartRunner(directory)
                runner.serial, runner.run_id = 'emulator-owned', RUN_ID
                apk = Path(directory) / 'build/app/outputs/flutter-apk/app-debug.apk'
                apk.parent.mkdir(parents=True)
                apk.write_bytes(b'synthetic cart apk')
                identity = {'uid': 10123, 'apk_sha256': hashlib.sha256(apk.read_bytes()).hexdigest()}
                calls = []
                def read(phase, *args):
                    calls.append(('receipt', phase))
                    if fail_seed and phase == 'seed':
                        raise A.Failure('cart-seed', 7, 'fixture')
                with patch.object(runner, 'prepare_device', return_value=Path('/owned/adb')), \
                     patch.object(runner, 'command', side_effect=lambda args, *a, **k:
                         calls.append(('command', args)) or (0, '')), \
                     patch.object(runner, 'device', side_effect=lambda args, *a, **k:
                         calls.append(('device', args)) or (0, '')), \
                     patch.object(runner, 'identity', return_value=identity), \
                     patch.object(runner, 'launch', side_effect=[12, 13]), \
                     patch.object(runner, 'read_fixture', side_effect=read), \
                     patch.object(runner, 'stop_seed', side_effect=lambda pid: calls.append(('stop', pid))), \
                     patch.object(runner, 'service_uri', side_effect=AssertionError('VM forbidden')):
                    if fail_seed:
                        with self.assertRaises(A.Failure):
                            runner.execute()
                    else:
                        runner.execute()
                self.assertEqual(len([c for kind, c in calls if kind == 'command'
                    and c[:2] == ['flutter', 'build']]), 1)
                self.assertEqual(len([c for kind, c in calls if kind == 'device' and c[0] == 'install']), 1)
                self.assertFalse(any(c[:2] == ['flutter', 'drive'] for kind, c in calls if kind == 'command'))
                self.assertFalse(any('uninstall' in c or 'clear' in c for kind, c in calls if kind == 'device'))
                sequence = [c for c in calls if c[0] in ('receipt', 'stop')]
                self.assertEqual(sequence, [('receipt', 'seed')] if fail_seed else
                    [('receipt', 'seed'), ('stop', 12), ('receipt', 'recover')])

    def test_ios_cart_output_and_unaccepted_receipt_preserve_address_artifacts(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            address = root / 'build/task054/ios-address-journal/runner.json'
            address.parent.mkdir(parents=True)
            address.write_text('preserve address evidence')
            runner = I.IosGuestCartRunner(root, root / 'owner.json')
            runner.output.mkdir(parents=True)
            runner.data = root / 'owned-data'
            runner.data.mkdir()
            runner.run_id = RUN_ID
            path = runner.data / 'Library/Application Support' / A.receipt_relative_path(RUN_ID, 'recover')
            path.parent.mkdir(parents=True)
            path.write_text(json.dumps(receipt()))
            with patch.object(runner, 'attest_pid'), self.assertRaises(I.CART.Failure):
                runner.read_fixture('recover', 13, 12)
            self.assertEqual(address.read_text(), 'preserve address evidence')
            self.assertEqual(runner.results, {})
            self.assertFalse((runner.output / 'recover.json').exists())


if __name__ == '__main__':
    unittest.main()
