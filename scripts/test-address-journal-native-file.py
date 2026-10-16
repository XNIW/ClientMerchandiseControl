#!/usr/bin/env python3
"""Confini del trasporto file; nessun SDK, emulatore o Keychain reale."""
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


A = module('address_file_android_test', 'run-address-journal-file-android.py')
I = module('address_file_ios_test', 'run-address-journal-file-ios.py')
RUN_ID = 'f0540000-0000-4000-8000-000000000002'


def receipt(phase='seed', process_id=12, seed_pid=12):
    return {'apiVersion': 'address-journal-native-evidence.v2', 'phase': phase,
        'runId': RUN_ID, 'processId': process_id, 'seedProcessId': seed_pid,
        'nativeWriteRead': 'PASS' if phase == 'seed' else 'NOT_RUN',
        'processRestartRead': 'PASS' if phase == 'recover' else 'NOT_RUN',
        'cleanup': 'PASS' if phase == 'recover' else 'NOT_RUN', 'backend': 'NOT_RUN'}


class NativeAddressFileTest(unittest.TestCase):
    def test_same_exact_contract_for_native_seed_and_recover(self):
        for phase, current in [('seed', 12), ('recover', 13)]:
            self.assertEqual(A.validate_native_receipt(receipt(phase, current),
                phase, RUN_ID, current, 12), receipt(phase, current))

    def test_wrong_run_pid_phase_cleanup_or_backend_fails_closed(self):
        for key, value in [('runId', 'stale'), ('phase', 'seed'), ('processId', 12),
                ('seedProcessId', 99), ('cleanup', 'NOT_RUN'), ('backend', 'PASS')]:
            with self.subTest(key=key):
                data = receipt('recover', 13)
                data[key] = value
                with self.assertRaises(A.Failure):
                    A.validate_native_receipt(data, 'recover', RUN_ID, 13, 12)
        with self.assertRaises(A.Failure):
            A.validate_native_receipt(receipt('recover', 12), 'recover', RUN_ID, 12, 12)

    def test_terminal_posttest_failure_cannot_be_accepted(self):
        data = {'apiVersion': 'address-journal-native-evidence.v2', 'phase': 'seed',
            'runId': RUN_ID, 'processId': 12, 'status': 'FAIL', 'errorType': 'assertion'}
        with self.assertRaises(A.Failure):
            A.validate_native_receipt(data, 'seed', RUN_ID, 12, 12)

    def test_android_reads_terminal_json_only_and_attests_same_pid(self):
        with tempfile.TemporaryDirectory() as directory:
            runner = A.AddressJournalFileRunner(directory)
            runner.run_id, runner.serial = RUN_ID, 'emulator-owned'
            runner.adb = Path('/owned/adb')
            runner.output.mkdir(parents=True)
            def wait(phase, timeout, arguments, predicate):
                self.assertEqual(timeout, 150)
                self.assertEqual(arguments[3:7], ['shell', 'run-as', A.ADDRESS.PACKAGE, 'cat'])
                self.assertFalse(predicate('{"apiVersion":'))
                self.assertEqual(runner.results, {})
                self.assertTrue(predicate(json.dumps(receipt())))
            with patch.object(runner, 'wait_ready', side_effect=wait), \
                 patch.object(runner, 'device', return_value=(0, '12')), \
                 patch.object(runner, 'service_uri', side_effect=AssertionError('VM forbidden')):
                runner.drive('seed', 12, 12)
            self.assertEqual(runner.results['seed'], receipt())
            self.assertEqual(json.loads((runner.output / 'seed.json').read_text()), receipt())

    def test_android_pid_change_and_preexisting_output_are_not_accepted(self):
        for changed_pid in (True, False):
            with self.subTest(changed_pid=changed_pid), tempfile.TemporaryDirectory() as directory:
                runner = A.AddressJournalFileRunner(directory)
                runner.run_id, runner.serial = RUN_ID, 'emulator-owned'
                runner.adb = Path('/owned/adb')
                runner.output.mkdir(parents=True)
                target = runner.output / 'seed.json'
                target.write_text('preserve prior evidence')
                def wait(phase, timeout, arguments, predicate):
                    self.assertTrue(predicate(json.dumps(receipt())))
                with patch.object(runner, 'wait_ready', side_effect=wait), \
                     patch.object(runner, 'device', return_value=(0, '13' if changed_pid else '12')):
                    with self.assertRaises(A.Failure if changed_pid else FileExistsError):
                        runner.drive('seed', 12, 12)
                self.assertNotIn('seed', runner.results)
                self.assertEqual(target.read_text(), 'preserve prior evidence')

    def test_ios_failure_class_is_normalized_before_base_run_receipt_cleanup(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            runner = I.IosAddressJournalFileRunner(root, root / 'owner.json')
            runner.run_id = RUN_ID
            runner.data = root / 'owned-data'
            path = runner.data / 'Library/Application Support' / A.receipt_relative_path(RUN_ID, 'seed')
            path.parent.mkdir(parents=True)
            path.write_text(json.dumps({'apiVersion': 'address-journal-native-evidence.v2',
                'phase': 'seed', 'runId': RUN_ID, 'processId': 12,
                'status': 'FAIL', 'errorType': 'assertion'}))
            with patch.object(runner, 'attest_pid'), \
                 patch.object(runner, 'service_uri', side_effect=AssertionError('VM forbidden')):
                with self.assertRaises(I.ADDRESS.Failure) as error:
                    runner.drive('seed', 12, 12, [])
            self.assertEqual(error.exception.code, 1)
            self.assertEqual(runner.results, {})

    def test_ios_symlink_cannot_read_foreign_receipt(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            runner = I.IosAddressJournalFileRunner(root, root / 'owner.json')
            runner.run_id, runner.data = RUN_ID, root / 'owned-data'
            path = runner.data / 'Library/Application Support' / A.receipt_relative_path(RUN_ID, 'seed')
            path.parent.mkdir(parents=True)
            foreign = root / 'foreign.json'
            foreign.write_text(json.dumps(receipt()))
            path.symlink_to(foreign)
            with patch.object(runner, 'attest_pid'), self.assertRaises(I.ADDRESS.Failure):
                runner.drive('seed', 12, 12, [])
            self.assertEqual(runner.results, {})
            self.assertFalse((runner.output / 'seed.json').exists())

    def failure_artifact(self, error_type, **changes):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            runner = I.IosAddressJournalFileRunner(root, root / 'owner.json')
            runner.run_id, runner.data = RUN_ID, root / 'owned-data'
            runner.revision = 'd195602bddf3b23c04530f32ae6ddf06fdd39c15'
            source = runner.data / 'Library/Application Support' / A.receipt_relative_path(RUN_ID, 'seed')
            source.parent.mkdir(parents=True)
            data = {'apiVersion': 'address-journal-native-evidence.v2', 'phase': 'seed',
                    'runId': RUN_ID, 'processId': 12, 'status': 'FAIL', 'errorType': error_type}
            data.update(changes)
            source.write_text(json.dumps(data))

            def execute():
                runner.output.mkdir(parents=True)
                runner.owns_output = True
                runner.drive('seed', 12, 12, [])

            with patch.object(runner, 'execute', side_effect=execute), \
                 patch.object(runner, 'attest_pid') as attest, \
                 patch.object(runner, 'command', side_effect=AssertionError('native command forbidden')):
                code = runner.run()
            artifact_text = (runner.output / 'runner.json').read_text()
            artifact = json.loads(artifact_text)
            self.assertEqual(code, 1)
            self.assertEqual(artifact['exit_code'], 1)
            self.assertEqual(artifact['failed_phase'], 'journal-seed')
            self.assertEqual(artifact['restart'], 'NOT_RUN')
            self.assertEqual(artifact['backend'], 'NOT_RUN')
            self.assertNotIn('seed', artifact['results'])
            self.assertFalse((runner.output / 'seed.json').exists())
            attest.assert_called_once_with(12)
            return artifact, artifact_text

    def test_ios_native_failure_safe_enum_survives_into_runner_artifact(self):
        for category in ('assertion', 'filesystem', 'unexpected'):
            with self.subTest(category=category):
                artifact, text = self.failure_artifact(category)
                self.assertEqual(artifact['diagnostics'].get('seed', {}).get(
                    'native_terminal_error_type'), category)
                self.assertIn('fixture nativa segnala failure sanitizzata', artifact['failure_reason'])
                self.assertNotIn('PASS', artifact['results'].values())

    def test_ios_unknown_or_unqualified_failure_never_exports_enum_or_raw_data(self):
        for category, changes in (
                ('SECRET_RAW_MESSAGE', {}), ('assertion', {'rawMessage': 'SECRET_RAW_MESSAGE'}),
                ('filesystem', {'runId': 'foreign'}), ('unexpected', {'processId': 99})):
            with self.subTest(category=category, changes=changes):
                artifact, text = self.failure_artifact(category, **changes)
                self.assertNotIn('native_terminal_error_type', artifact['diagnostics'].get('seed', {}))
                self.assertNotIn('SECRET_RAW_MESSAGE', text)
                self.assertIn('ricevuta failure non conforme', artifact['failure_reason'])

    def test_native_validator_failure_exposes_only_validated_enum_on_original_failure(self):
        for category in ('assertion', 'filesystem', 'unexpected'):
            data = {'apiVersion': 'address-journal-native-evidence.v2', 'phase': 'seed',
                    'runId': RUN_ID, 'processId': 12, 'status': 'FAIL', 'errorType': category}
            with self.assertRaises(A.Failure) as raised:
                A.validate_native_receipt(data, 'seed', RUN_ID, 12, 12)
            self.assertIs(type(raised.exception), A.Failure)
            self.assertEqual(raised.exception.code, 1)
            self.assertEqual(getattr(raised.exception, 'native_error_type', None), category)
            self.assertEqual(str(raised.exception), 'journal-seed: fixture nativa segnala failure sanitizzata')

    def test_paths_cannot_escape_run_scope(self):
        for run, phase in [('../other', 'seed'), (RUN_ID, '../recover'), (RUN_ID, 'other')]:
            with self.subTest(run=run, phase=phase), self.assertRaises(A.Failure):
                A.receipt_relative_path(run, phase)


if __name__ == '__main__':
    unittest.main()
