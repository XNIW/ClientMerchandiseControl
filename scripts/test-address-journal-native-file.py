#!/usr/bin/env python3
"""Confini del trasporto file; nessun SDK, emulatore o Keychain reale."""
import importlib.util
import json
import re
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

    def failure_artifact(self, error_type, *, expected_phase='seed', **changes):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            runner = I.IosAddressJournalFileRunner(root, root / 'owner.json')
            runner.run_id, runner.data = RUN_ID, root / 'owned-data'
            runner.revision = 'd195602bddf3b23c04530f32ae6ddf06fdd39c15'
            current_pid = 12 if expected_phase == 'seed' else 13
            source = runner.data / 'Library/Application Support' / A.receipt_relative_path(RUN_ID, expected_phase)
            source.parent.mkdir(parents=True)
            data = {'apiVersion': 'address-journal-native-evidence.v2', 'phase': expected_phase,
                    'runId': RUN_ID, 'processId': current_pid, 'status': 'FAIL', 'errorType': error_type}
            data.update(changes)
            source.write_text(json.dumps(data))

            def execute():
                runner.output.mkdir(parents=True)
                runner.owns_output = True
                if expected_phase == 'recover':
                    runner.results['seed'] = receipt()
                    runner.results['seed_terminated'] = 'PASS'
                runner.drive(expected_phase, current_pid, 12, [])

            with patch.object(runner, 'execute', side_effect=execute), \
                 patch.object(runner, 'attest_pid') as attest, \
                 patch.object(runner, 'command', side_effect=AssertionError('native command forbidden')):
                code = runner.run()
            artifact_text = (runner.output / 'runner.json').read_text()
            artifact = json.loads(artifact_text)
            self.assertEqual(code, 1)
            self.assertEqual(artifact['exit_code'], 1)
            self.assertEqual(artifact['failed_phase'], 'journal-' + expected_phase)
            self.assertEqual(artifact['restart'], 'FAIL' if expected_phase == 'recover' else 'NOT_RUN')
            self.assertEqual(artifact['backend'], 'NOT_RUN')
            self.assertNotIn(expected_phase, artifact['results'])
            self.assertFalse((runner.output / (expected_phase + '.json')).exists())
            attest.assert_called_once_with(current_pid)
            return artifact, artifact_text

    def test_ios_native_failure_safe_enum_survives_into_runner_artifact(self):
        for category in ('assertion', 'filesystem', 'unexpected'):
            with self.subTest(category=category):
                artifact, text = self.failure_artifact(category)
                self.assertEqual(artifact['diagnostics'].get('seed', {}).get(
                    'native_terminal_error_type'), category)
                self.assertNotIn('native_terminal_failure_origin', artifact['diagnostics'].get('seed', {}))
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

    def test_ios_v3_failure_origin_survives_to_terminal_artifact_without_success(self):
        for phase in ('seed', 'recover'):
            for origin, category in (('body', 'assertion'), ('body', 'filesystem'),
                    ('body', 'unexpected'), ('terminal_gate', 'assertion')):
                with self.subTest(phase=phase, origin=origin, category=category):
                    artifact, text = self.failure_artifact(category, expected_phase=phase,
                        apiVersion='address-journal-native-evidence.v3', failureOrigin=origin)
                    diagnostics = artifact['diagnostics'].get(phase, {})
                    self.assertEqual(diagnostics.get('native_terminal_error_type'), category)
                    self.assertEqual(diagnostics.get('native_terminal_failure_origin'), origin)
                    self.assertIn('fixture nativa segnala failure sanitizzata', artifact['failure_reason'])
                    self.assertNotIn('same_bundle_and_containers', artifact['results'])

    def test_ios_invalid_v3_and_mixed_version_failures_export_no_metadata(self):
        cases = (
            ('assertion', {'apiVersion': 'address-journal-native-evidence.v3'}),
            ('assertion', {'failureOrigin': 'body'}),
            ('assertion', {'apiVersion': 'address-journal-native-evidence.v3',
                'failureOrigin': 'SECRET_RAW_MESSAGE'}),
            ('assertion', {'apiVersion': 'address-journal-native-evidence.v3',
                'failureOrigin': None}),
            ('assertion', {'apiVersion': 'address-journal-native-evidence.v3',
                'failureOrigin': ['body']}),
            ('filesystem', {'apiVersion': 'address-journal-native-evidence.v3',
                'failureOrigin': 'terminal_gate'}),
            ('unexpected', {'apiVersion': 'address-journal-native-evidence.v3',
                'failureOrigin': 'terminal_gate'}),
            ('SECRET_RAW_MESSAGE', {'apiVersion': 'address-journal-native-evidence.v3',
                'failureOrigin': 'body'}),
            ('assertion', {'apiVersion': 'address-journal-native-evidence.v3',
                'failureOrigin': 'body', 'rawMessage': 'SECRET_RAW_MESSAGE'}),
            ('assertion', {'apiVersion': 'address-journal-native-evidence.v3',
                'failureOrigin': 'body', 'runId': 'foreign'}),
            ('assertion', {'apiVersion': 'address-journal-native-evidence.v3',
                'failureOrigin': 'body', 'processId': 99}),
            ('assertion', {'apiVersion': 'address-journal-native-evidence.v3',
                'failureOrigin': 'body', 'phase': 'recover'}),
        )
        for category, changes in cases:
            with self.subTest(category=category, changes=changes):
                artifact, text = self.failure_artifact(category, **changes)
                diagnostics = artifact['diagnostics'].get('seed', {})
                self.assertNotIn('native_terminal_error_type', diagnostics)
                self.assertNotIn('native_terminal_failure_origin', diagnostics)
                self.assertNotIn('SECRET_RAW_MESSAGE', text)
                self.assertIn('ricevuta failure non conforme', artifact['failure_reason'])

    def test_native_v3_validated_failure_carries_origin_on_same_failure(self):
        for origin, category in (('body', 'assertion'), ('body', 'filesystem'),
                ('body', 'unexpected'), ('terminal_gate', 'assertion')):
            with self.subTest(origin=origin, category=category):
                data = {'apiVersion': 'address-journal-native-evidence.v3', 'phase': 'recover',
                    'runId': RUN_ID, 'processId': 13, 'status': 'FAIL',
                    'errorType': category, 'failureOrigin': origin}
                with self.assertRaises(A.Failure) as raised:
                    A.validate_native_receipt(data, 'recover', RUN_ID, 13, 12)
                self.assertIs(type(raised.exception), A.Failure)
                self.assertEqual(raised.exception.code, 1)
                self.assertEqual(getattr(raised.exception, 'native_error_type', None), category)
                self.assertEqual(getattr(raised.exception, 'native_failure_origin', None), origin)
                self.assertEqual(str(raised.exception), 'journal-recover: fixture nativa segnala failure sanitizzata')

    def test_success_contract_never_accepts_failure_origin_or_v3(self):
        for changes in ({'failureOrigin': 'body'},
                {'apiVersion': 'address-journal-native-evidence.v3'},
                {'apiVersion': 'address-journal-native-evidence.v3', 'failureOrigin': 'terminal_gate'}):
            with self.subTest(changes=changes), self.assertRaises(A.Failure):
                A.validate_native_receipt({**receipt(), **changes}, 'seed', RUN_ID, 12, 12)

    def checkpoint_failure(self, checkpoint, *, phase='recover', origin='body', category='assertion'):
        return {'apiVersion': 'address-journal-native-evidence.v4', 'phase': phase,
            'runId': RUN_ID, 'processId': 13 if phase == 'recover' else 12,
            'status': 'FAIL', 'errorType': category, 'failureOrigin': origin,
            'failureCheckpoint': checkpoint}

    def test_v4_recover_assertion_distinguishes_each_validated_checkpoint(self):
        for checkpoint in ('recover_marker', 'recover_process', 'restored_identity',
                'restored_payload', 'cleared_readback'):
            with self.subTest(checkpoint=checkpoint), self.assertRaises(A.Failure) as raised:
                A.validate_native_receipt(self.checkpoint_failure(checkpoint), 'recover', RUN_ID, 13, 12)
            self.assertEqual(raised.exception.code, 1)
            self.assertEqual(getattr(raised.exception, 'native_error_type', None), 'assertion')
            self.assertEqual(getattr(raised.exception, 'native_failure_origin', None), 'body')
            self.assertEqual(getattr(raised.exception, 'native_failure_checkpoint', None), checkpoint)
            self.assertIn('fixture nativa segnala failure sanitizzata', str(raised.exception))

    def test_v4_null_checkpoint_preserves_known_origin_without_inference(self):
        for phase in ('seed', 'recover'):
            for origin, category in (('body', 'assertion'), ('body', 'filesystem'),
                    ('body', 'unexpected'), ('terminal_gate', 'assertion')):
                with self.subTest(phase=phase, origin=origin, category=category), \
                     self.assertRaises(A.Failure) as raised:
                    A.validate_native_receipt(self.checkpoint_failure(None, phase=phase,
                        origin=origin, category=category), phase, RUN_ID,
                        13 if phase == 'recover' else 12, 12)
                self.assertEqual(getattr(raised.exception, 'native_error_type', None), category)
                self.assertEqual(getattr(raised.exception, 'native_failure_origin', None), origin)
                self.assertFalse(hasattr(raised.exception, 'native_failure_checkpoint'))

    def test_v4_nonnull_checkpoint_requires_body_recover_assertion(self):
        for checkpoint in ('recover_marker', 'recover_process', 'restored_identity',
                'restored_payload', 'cleared_readback'):
            for phase, origin, category in (('seed', 'body', 'assertion'),
                    ('recover', 'terminal_gate', 'assertion'), ('recover', 'body', 'filesystem'),
                    ('recover', 'body', 'unexpected')):
                with self.subTest(checkpoint=checkpoint, phase=phase, origin=origin, category=category), \
                     self.assertRaises(A.Failure) as raised:
                    A.validate_native_receipt(self.checkpoint_failure(checkpoint, phase=phase,
                        origin=origin, category=category), phase, RUN_ID,
                        13 if phase == 'recover' else 12, 12)
                self.assertFalse(hasattr(raised.exception, 'native_error_type'))
                self.assertFalse(hasattr(raised.exception, 'native_failure_origin'))
                self.assertFalse(hasattr(raised.exception, 'native_failure_checkpoint'))

    def test_v4_exact_schema_identity_and_checkpoint_allowlist_fail_closed(self):
        cases = (
            {'failureCheckpoint': 'SECRET_RAW_CHECKPOINT'}, {'failureCheckpoint': ['recover_marker']},
            {'failureCheckpoint': {'recover_marker': True}}, {'failureCheckpoint': 1},
            {'failureOrigin': None}, {'failureOrigin': 'SECRET_RAW_ORIGIN'},
            {'failureOrigin': ['body']}, {'failureOrigin': 'terminal_gate', 'errorType': 'filesystem',
                'failureCheckpoint': None}, {'errorType': 'SECRET_RAW_ERROR'},
            {'apiVersion': 'address-journal-native-evidence.v2'},
            {'apiVersion': 'address-journal-native-evidence.v3'},
            {'apiVersion': 'address-journal-native-evidence.v5'}, {'runId': 'foreign'},
            {'processId': 99}, {'phase': 'seed'}, {'rawMessage': 'SECRET_RAW_MESSAGE'},
            {'status': 'PASS'},
        )
        for changes in cases:
            data = {**self.checkpoint_failure('recover_marker'), **changes}
            with self.subTest(changes=changes), self.assertRaises(A.Failure) as raised:
                A.validate_native_receipt(data, 'recover', RUN_ID, 13, 12)
            for field in ('native_error_type', 'native_failure_origin', 'native_failure_checkpoint'):
                self.assertFalse(hasattr(raised.exception, field))
            self.assertNotIn('SECRET_RAW', str(raised.exception))
        for missing in ('failureCheckpoint', 'failureOrigin', 'errorType', 'status'):
            data = self.checkpoint_failure(None)
            del data[missing]
            with self.subTest(missing=missing), self.assertRaises(A.Failure) as raised:
                A.validate_native_receipt(data, 'recover', RUN_ID, 13, 12)
            self.assertFalse(hasattr(raised.exception, 'native_failure_checkpoint'))

    def test_v4_does_not_add_checkpoint_to_strict_legacy_failure_contracts(self):
        for version, origin in (('v2', None), ('v3', 'body')):
            data = {'apiVersion': 'address-journal-native-evidence.' + version, 'phase': 'recover',
                'runId': RUN_ID, 'processId': 13, 'status': 'FAIL', 'errorType': 'assertion'}
            if origin:
                data['failureOrigin'] = origin
            with self.subTest(version=version), self.assertRaises(A.Failure) as raised:
                A.validate_native_receipt(data, 'recover', RUN_ID, 13, 12)
            self.assertEqual(getattr(raised.exception, 'native_error_type', None), 'assertion')
            self.assertFalse(hasattr(raised.exception, 'native_failure_checkpoint'))
            for checkpoint in (None, 'recover_marker'):
                with self.subTest(version=version, checkpoint=checkpoint), self.assertRaises(A.Failure) as invalid:
                    A.validate_native_receipt({**data, 'failureCheckpoint': checkpoint}, 'recover', RUN_ID, 13, 12)
                self.assertFalse(hasattr(invalid.exception, 'native_error_type'))

    def test_success_v2_never_accepts_failure_checkpoint_or_v4(self):
        for changes in ({'failureCheckpoint': None}, {'failureCheckpoint': 'recover_marker'},
                {'apiVersion': 'address-journal-native-evidence.v4'},
                {'apiVersion': 'address-journal-native-evidence.v4', 'failureCheckpoint': None}):
            with self.subTest(changes=changes), self.assertRaises(A.Failure):
                A.validate_native_receipt({**receipt(), **changes}, 'seed', RUN_ID, 12, 12)

    def test_ios_v4_checkpoints_survive_only_as_validated_enums_and_failure(self):
        for checkpoint in ('recover_marker', 'recover_process', 'restored_identity',
                'restored_payload', 'cleared_readback'):
            with self.subTest(checkpoint=checkpoint):
                artifact, text = self.failure_artifact('assertion', expected_phase='recover',
                    apiVersion='address-journal-native-evidence.v4', failureOrigin='body',
                    failureCheckpoint=checkpoint)
                diagnostics = artifact['diagnostics'].get('recover', {})
                self.assertEqual(diagnostics.get('native_terminal_error_type'), 'assertion')
                self.assertEqual(diagnostics.get('native_terminal_failure_origin'), 'body')
                self.assertEqual(diagnostics.get('native_terminal_failure_checkpoint'), checkpoint)
                self.assertNotIn('same_bundle_and_containers', artifact['results'])
                self.assertEqual(artifact['restart'], 'FAIL')

    def test_ios_v4_null_checkpoint_does_not_imply_unobserved_check(self):
        for phase in ('seed', 'recover'):
            for origin, category in (('body', 'assertion'), ('body', 'filesystem'),
                    ('body', 'unexpected'), ('terminal_gate', 'assertion')):
                with self.subTest(phase=phase, origin=origin, category=category):
                    artifact, text = self.failure_artifact(category, expected_phase=phase,
                        apiVersion='address-journal-native-evidence.v4', failureOrigin=origin,
                        failureCheckpoint=None)
                    diagnostics = artifact['diagnostics'].get(phase, {})
                    self.assertEqual(diagnostics.get('native_terminal_error_type'), category)
                    self.assertEqual(diagnostics.get('native_terminal_failure_origin'), origin)
                    self.assertNotIn('native_terminal_failure_checkpoint', diagnostics)

    def test_ios_invalid_v4_checkpoint_exports_neither_metadata_nor_raw_value(self):
        cases = (
            ('assertion', 'recover', {'failureCheckpoint': 'SECRET_RAW_CHECKPOINT'}),
            ('assertion', 'recover', {'failureCheckpoint': ['recover_marker']}),
            ('assertion', 'recover', {'failureOrigin': 'terminal_gate'}),
            ('filesystem', 'recover', {}), ('unexpected', 'recover', {}),
            ('assertion', 'seed', {}), ('assertion', 'recover', {'runId': 'foreign'}),
            ('assertion', 'recover', {'processId': 99}),
            ('assertion', 'recover', {'phase': 'seed'}),
            ('assertion', 'recover', {'rawMessage': 'SECRET_RAW_MESSAGE'}),
            ('assertion', 'recover', {'apiVersion': 'address-journal-native-evidence.v3'}),
        )
        for category, phase, changes in cases:
            fields = {'apiVersion': 'address-journal-native-evidence.v4', 'failureOrigin': 'body',
                'failureCheckpoint': 'recover_marker', **changes}
            with self.subTest(category=category, phase=phase, changes=changes):
                artifact, text = self.failure_artifact(category, expected_phase=phase, **fields)
                diagnostics = artifact['diagnostics'].get(phase, {})
                for field in ('native_terminal_error_type', 'native_terminal_failure_origin',
                        'native_terminal_failure_checkpoint'):
                    self.assertNotIn(field, diagnostics)
                self.assertNotIn('SECRET_RAW', text)
                self.assertIn('ricevuta failure non conforme', artifact['failure_reason'])

    def fixture_source(self):
        return (Path(__file__).resolve().parent.parent / 'integration_test' /
            'address_creation_journal_native_test.dart').read_text(encoding='utf-8')

    def test_fixture_wraps_exactly_five_existing_recover_assertions(self):
        source = self.fixture_source()
        self.assertEqual(re.findall(r"publisher\.checkRecover\(\s*'([^']+)'", source),
            ['recover_marker', 'recover_process', 'restored_identity', 'restored_payload', 'cleared_readback'])
        expected = {
            'recover_marker': 'expect(marker, isNotNull);',
            'recover_process': "expect(pid, isNot(seedPid), reason: 'Serve un processo nativo nuovo.',);",
            'restored_identity': 'expect(restored?.id, runId);',
            'restored_payload': 'expect(restored?.matches(_draft(runId, seedPid)), isTrue);',
            'cleared_readback': 'expect(cleared, isNull);',
        }
        for checkpoint, assertion in expected.items():
            block = re.search(r"publisher\.checkRecover\(\s*'" + checkpoint +
                r"',\s*\(\)\s*\{(.*?)\}\s*\);", source, re.S)
            self.assertIsNotNone(block, checkpoint)
            self.assertEqual(re.sub(r'\s+', '', block.group(1)), re.sub(r'\s+', '', assertion))
        self.assertEqual(len(re.findall(r'\bexpect\(', source)), 8)
        self.assertLess(source.index("reason: 'Nessun journal precedente va riusato.'"),
            source.index('publisher.phase = phase;'))
        self.assertLess(source.index('publisher.phase = phase;'),
            source.index("publisher.checkRecover('recover_marker'"))

    def test_fixture_checkpoint_reset_and_read_boundary_prevent_false_attribution(self):
        source = self.fixture_source()
        helper = re.search(r'void checkRecover\(String checkpoint, void Function\(\) check\)\s*\{(.*?)\}', source, re.S)
        self.assertIsNotNone(helper)
        self.assertEqual(re.sub(r'\s+', '', helper.group(1)),
            "failureCheckpoint=phase=='recover'?checkpoint:null;check();failureCheckpoint=null;")
        self.assertNotIn('async', helper.group(0))
        self.assertLess(source.index('await journal.clear(_fixtureOwner);'),
            source.index('final cleared = await journal.read(_fixtureOwner);'))
        self.assertLess(source.index('final cleared = await journal.read(_fixtureOwner);'),
            source.index("publisher.checkRecover('cleared_readback'"))
        self.assertLess(source.index('final restored = await SecureAddressCreationJournal().read(_fixtureOwner);'),
            source.index("publisher.checkRecover('restored_identity'"))

    def test_fixture_v5_export_guards_error_type_and_phase_and_keeps_origin(self):
        compact = re.sub(r'\s+', '', self.fixture_source())
        self.assertIn("const_failureApiVersion='address-journal-native-evidence.v5';", compact)
        self.assertIn("finalcheckpoint=bodyErrorType=='assertion'&&phase=='recover'?failureCheckpoint:null;", compact)
        self.assertIn("'failureCheckpoint':checkpoint,", compact)
        self.assertIn("'failureOrigin':bodyErrorType==null?'terminal_gate':'body',", compact)
        self.assertIn("const_apiVersion='address-journal-native-evidence.v2';", compact)

    def mask_failure(self, mask, *, phase='recover', origin='terminal_gate', category='assertion', checkpoint=None):
        return {**self.checkpoint_failure(checkpoint, phase=phase, origin=origin, category=category),
            'apiVersion': 'address-journal-native-evidence.v5', 'terminalGateMask': mask}

    def test_v5_terminal_mask_distinguishes_sdk_false_from_missing_candidate(self):
        # Entrambi sono terminal_gate/assertion nel vecchio contratto v4.
        legacy = self.checkpoint_failure(None, origin='terminal_gate')
        with self.assertRaises(A.Failure) as old:
            A.validate_native_receipt(legacy, 'recover', RUN_ID, 13, 12)
        self.assertEqual(getattr(old.exception, 'native_failure_origin', None), 'terminal_gate')
        self.assertFalse(hasattr(old.exception, 'native_terminal_gate_mask'))
        observed = []
        for mask in (1, 32):
            with self.subTest(mask=mask), self.assertRaises(A.Failure) as raised:
                A.validate_native_receipt(self.mask_failure(mask), 'recover', RUN_ID, 13, 12)
            self.assertEqual(raised.exception.code, 1)
            self.assertEqual(getattr(raised.exception, 'native_error_type', None), 'assertion')
            self.assertEqual(getattr(raised.exception, 'native_failure_origin', None), 'terminal_gate')
            observed.append(getattr(raised.exception, 'native_terminal_gate_mask', None))
        self.assertEqual(observed, [1, 32])
        self.assertNotEqual(*observed)

    def test_v5_accepts_every_nonzero_mask_with_consistent_teardown_availability(self):
        accepted = 0
        for mask in range(1, 128):
            if mask & 64 and not mask & 8:
                continue
            accepted += 1
            with self.subTest(mask=mask), self.assertRaises(A.Failure) as raised:
                A.validate_native_receipt(self.mask_failure(mask), 'recover', RUN_ID, 13, 12)
            self.assertEqual(type(getattr(raised.exception, 'native_terminal_gate_mask', None)), int)
            self.assertEqual(raised.exception.native_terminal_gate_mask, mask)
            self.assertEqual(raised.exception.code, 1)
            self.assertFalse(hasattr(raised.exception, 'native_failure_checkpoint'))
        self.assertEqual(accepted, 95)

    def test_v5_teardown_mask_distinguishes_failing_and_unavailable(self):
        observed = []
        for mask in (8, 72):
            with self.subTest(mask=mask), self.assertRaises(A.Failure) as raised:
                A.validate_native_receipt(self.mask_failure(mask), 'recover', RUN_ID, 13, 12)
            observed.append(getattr(raised.exception, 'native_terminal_gate_mask', None))
        self.assertEqual(observed, [8, 72])
        self.assertNotEqual(*observed)

    def test_v5_body_requires_null_mask_and_preserves_v4_checkpoint_rules(self):
        for phase in ('seed', 'recover'):
            for category in ('assertion', 'filesystem', 'unexpected'):
                with self.subTest(phase=phase, category=category), self.assertRaises(A.Failure) as raised:
                    A.validate_native_receipt(self.mask_failure(None, phase=phase,
                        origin='body', category=category), phase, RUN_ID,
                        13 if phase == 'recover' else 12, 12)
                self.assertEqual(getattr(raised.exception, 'native_error_type', None), category)
                self.assertEqual(getattr(raised.exception, 'native_failure_origin', None), 'body')
                self.assertFalse(hasattr(raised.exception, 'native_terminal_gate_mask'))
        for checkpoint in ('recover_marker', 'recover_process', 'restored_identity',
                'restored_payload', 'cleared_readback'):
            with self.subTest(checkpoint=checkpoint), self.assertRaises(A.Failure) as raised:
                A.validate_native_receipt(self.mask_failure(None, origin='body', checkpoint=checkpoint),
                    'recover', RUN_ID, 13, 12)
            self.assertEqual(getattr(raised.exception, 'native_failure_checkpoint', None), checkpoint)
            self.assertFalse(hasattr(raised.exception, 'native_terminal_gate_mask'))

    def test_v5_mask_type_range_origin_category_and_checkpoint_fail_closed(self):
        cases = [self.mask_failure(value) for value in
            (None, 0, -1, 64, 65, 96, 128, True, False, 1.0, '1', [1], {'bit': 1})]
        cases += [self.mask_failure(1, origin='body', category=category)
            for category in ('assertion', 'filesystem', 'unexpected')]
        cases += [self.mask_failure(1, category=category) for category in ('filesystem', 'unexpected')]
        cases += [self.mask_failure(1, origin=origin) for origin in (None, 'SECRET_RAW_ORIGIN', ['terminal_gate'])]
        cases += [self.mask_failure(1, checkpoint=value) for value in ('recover_marker', 'SECRET_RAW_CHECKPOINT')]
        cases += [self.mask_failure(None, origin='body', phase='seed', checkpoint='restored_identity'),
            self.mask_failure(None, origin='body', category='filesystem', checkpoint='recover_marker')]
        for data in cases:
            expected_phase = data['phase']
            with self.subTest(data=data), self.assertRaises(A.Failure) as raised:
                A.validate_native_receipt(data, expected_phase, RUN_ID,
                    13 if expected_phase == 'recover' else 12, 12)
            for field in ('native_error_type', 'native_failure_origin', 'native_failure_checkpoint',
                    'native_terminal_gate_mask'):
                self.assertFalse(hasattr(raised.exception, field))
            self.assertNotIn('SECRET_RAW', str(raised.exception))

    def test_v5_exact_keys_version_and_native_identity_remain_required(self):
        for changes in ({'apiVersion': 'address-journal-native-evidence.v4'},
                {'apiVersion': 'address-journal-native-evidence.v6'}, {'phase': 'seed'},
                {'runId': 'foreign'}, {'processId': 99}, {'errorType': 'SECRET_RAW_ERROR'},
                {'rawMessage': 'SECRET_RAW_MESSAGE'}):
            with self.subTest(changes=changes), self.assertRaises(A.Failure) as raised:
                A.validate_native_receipt({**self.mask_failure(1), **changes}, 'recover', RUN_ID, 13, 12)
            self.assertFalse(hasattr(raised.exception, 'native_terminal_gate_mask'))
        for missing in ('terminalGateMask', 'failureCheckpoint', 'failureOrigin', 'errorType', 'status'):
            data = self.mask_failure(1)
            del data[missing]
            with self.subTest(missing=missing), self.assertRaises(A.Failure) as raised:
                A.validate_native_receipt(data, 'recover', RUN_ID, 13, 12)
            self.assertFalse(hasattr(raised.exception, 'native_terminal_gate_mask'))

    def test_legacy_v2_v3_v4_strict_failures_never_accept_or_infer_terminal_mask(self):
        for version in (2, 3, 4):
            data = {'apiVersion': 'address-journal-native-evidence.v' + str(version),
                'phase': 'recover', 'runId': RUN_ID, 'processId': 13, 'status': 'FAIL', 'errorType': 'assertion'}
            if version >= 3:
                data['failureOrigin'] = 'terminal_gate'
            if version == 4:
                data['failureCheckpoint'] = None
            with self.subTest(version=version), self.assertRaises(A.Failure) as old:
                A.validate_native_receipt(data, 'recover', RUN_ID, 13, 12)
            self.assertEqual(getattr(old.exception, 'native_error_type', None), 'assertion')
            self.assertFalse(hasattr(old.exception, 'native_terminal_gate_mask'))
            for mask in (None, 1):
                with self.subTest(version=version, mask=mask), self.assertRaises(A.Failure) as raised:
                    A.validate_native_receipt({**data, 'terminalGateMask': mask}, 'recover', RUN_ID, 13, 12)
                self.assertFalse(hasattr(raised.exception, 'native_error_type'))

    def test_success_v2_stays_exact_and_never_accepts_terminal_mask_or_v5(self):
        self.assertEqual(A.validate_native_receipt(receipt(), 'seed', RUN_ID, 12, 12), receipt())
        for changes in ({'terminalGateMask': None}, {'terminalGateMask': 1},
                {'apiVersion': 'address-journal-native-evidence.v5'},
                {'apiVersion': 'address-journal-native-evidence.v5', 'terminalGateMask': None}):
            with self.subTest(changes=changes), self.assertRaises(A.Failure):
                A.validate_native_receipt({**receipt(), **changes}, 'seed', RUN_ID, 12, 12)

    def test_ios_v5_terminal_mask_survives_into_failed_runner_without_recover_json(self):
        for mask in (1, 8, 32, 72, 127):
            with self.subTest(mask=mask):
                artifact, text = self.failure_artifact('assertion', expected_phase='recover',
                    apiVersion='address-journal-native-evidence.v5', failureOrigin='terminal_gate',
                    failureCheckpoint=None, terminalGateMask=mask)
                diagnostic = artifact['diagnostics']['recover']
                self.assertEqual(diagnostic.get('native_terminal_error_type'), 'assertion')
                self.assertEqual(diagnostic.get('native_terminal_failure_origin'), 'terminal_gate')
                self.assertEqual(diagnostic.get('native_terminal_gate_mask'), mask)
                self.assertNotIn('native_terminal_failure_checkpoint', diagnostic)
                self.assertEqual(artifact['restart'], 'FAIL')
                self.assertIn('fixture nativa segnala failure sanitizzata', artifact['failure_reason'])

    def test_ios_v5_body_null_mask_preserves_checkpoint_without_terminal_inference(self):
        for checkpoint in (None, 'restored_payload'):
            with self.subTest(checkpoint=checkpoint):
                artifact, text = self.failure_artifact('assertion', expected_phase='recover',
                    apiVersion='address-journal-native-evidence.v5', failureOrigin='body',
                    failureCheckpoint=checkpoint, terminalGateMask=None)
                diagnostic = artifact['diagnostics']['recover']
                self.assertEqual(diagnostic.get('native_terminal_failure_origin'), 'body')
                self.assertEqual(diagnostic.get('native_terminal_failure_checkpoint'), checkpoint)
                self.assertNotIn('native_terminal_gate_mask', diagnostic)

    def test_ios_invalid_v5_masks_export_no_diagnostics_or_raw_values(self):
        for changes in ({'terminalGateMask': 0}, {'terminalGateMask': 64}, {'terminalGateMask': 65},
                {'terminalGateMask': 96}, {'terminalGateMask': 128}, {'terminalGateMask': True},
                {'terminalGateMask': 1.0}, {'terminalGateMask': 'SECRET_RAW_MASK'},
                {'terminalGateMask': None}, {'failureOrigin': 'body'},
                {'failureCheckpoint': 'restored_identity'}, {'runId': 'foreign'},
                {'processId': 99}, {'apiVersion': 'address-journal-native-evidence.v4'},
                {'rawMessage': 'SECRET_RAW_MESSAGE'}):
            fields = {'apiVersion': 'address-journal-native-evidence.v5', 'failureOrigin': 'terminal_gate',
                'failureCheckpoint': None, 'terminalGateMask': 1, **changes}
            with self.subTest(changes=changes):
                artifact, text = self.failure_artifact('assertion', expected_phase='recover', **fields)
                diagnostic = artifact['diagnostics'].get('recover', {})
                for field in ('native_terminal_error_type', 'native_terminal_failure_origin',
                        'native_terminal_failure_checkpoint', 'native_terminal_gate_mask'):
                    self.assertNotIn(field, diagnostic)
                self.assertNotIn('SECRET_RAW', text)
                self.assertIn('ricevuta failure non conforme', artifact['failure_reason'])

    def test_fixture_terminal_mask_and_seven_predicates_share_single_snapshot(self):
        source = self.fixture_source()
        compact = re.sub(r'\s+', '', source)
        start = compact.index('finalteardownResult=Invoker.current?.liveTest.state.result.isFailing;')
        end = compact.index('finaltargetDirectory=directory;')
        snapshot = compact[start:end]
        for expected in ('finalteardownResult=Invoker.current?.liveTest.state.result.isFailing;',
                'finalteardownFailed=teardownResult??true;',
                'finalpostTestCompleted=binding.postTestCompleted;',
                'finalpostTestFailed=binding.postTestFailed;',
                'finalfailureMethodsEmpty=binding.failureMethodsDetails.isEmpty;',
                'finalcandidate=successCandidate;', 'finalbodyErrorType=errorType;'):
            self.assertEqual(snapshot.count(expected), 1)
        self.assertNotIn('await', snapshot)
        self.assertIn('finalterminalPassed=sdkPassed&&postTestCompleted&&!postTestFailed&&'
            '!teardownFailed&&failureMethodsEmpty&&bodyErrorType==null&&candidate!=null;', snapshot)
        self.assertIn('finalterminalGateMask=(sdkPassed?0:1)|(postTestCompleted?0:2)|'
            '(postTestFailed?4:0)|(teardownFailed?8:0)|(failureMethodsEmpty?0:16)|'
            '(candidate!=null?0:32)|(teardownResult==null?64:0);', snapshot)
        self.assertIn("'terminalGateMask':bodyErrorType==null?terminalGateMask:null,", compact)
        self.assertIn('finalresult=terminalPassed?candidate:', compact)

    def test_paths_cannot_escape_run_scope(self):
        for run, phase in [('../other', 'seed'), (RUN_ID, '../recover'), (RUN_ID, 'other')]:
            with self.subTest(run=run, phase=phase), self.assertRaises(A.Failure):
                A.receipt_relative_path(run, phase)


if __name__ == '__main__':
    unittest.main()
