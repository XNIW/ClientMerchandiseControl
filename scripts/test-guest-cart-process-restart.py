#!/usr/bin/env python3
"""Regressioni dei confini evidence guest cart, senza SDK, emulatori o app.

Da eseguire soltanto dopo l'integrazione della proposta nel checkout autorizzato.
Non sostituisce il gate seed/stop/recover nativo.
"""
import hashlib
import importlib.util
import contextlib
import io
import json
import os
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


class GuestPrepareTraceRetentionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = (Path(__file__).parent.parent /
            '.github/workflows/task054-guest-cart-restart.yml').read_text()
        block = cls.workflow.split('      - name: Retain bounded passive prepare trace\n', 1)[1]
        cls.guard = block.split("          python3 - <<'PY'\n", 1)[1].split('          PY\n', 1)[0]
        cls.guard = '\n'.join(line[10:] for line in cls.guard.splitlines())
        cls.namespace = {'__name__': 'guest_trace_retention_under_test'}
        exec(compile(cls.guard, '<guest trace retention>', 'exec'), cls.namespace)

    def payload(self, events=1):
        return b''.join((json.dumps({'sequence': number, 'monotonic_ns': number,
            'elapsed_ns': number, 'event': 'trace-start'}) + '\n').encode()
            for number in range(1, events + 1))

    def execute(self, directory, outcome='success', data=None, setup=None):
        root = Path(directory)
        source = root / 'build/task054/ios-guest-cart-owned-receipt.processes.jsonl'
        source.parent.mkdir(parents=True, exist_ok=True)
        if data is not None:
            source.write_bytes(data)
            source.chmod(0o600)
        if setup:
            setup(source)
        outputs = root / 'github-output'
        if not outputs.exists():
            outputs.write_text('preserved_output=1\n')
        original_cwd = Path.cwd()
        try:
            os.chdir(root)
            with patch.dict(os.environ, {'CMC_PREPARE_OUTCOME': outcome,
                    'GITHUB_OUTPUT': str(outputs)}, clear=True), \
                 contextlib.redirect_stdout(io.StringIO()) as console:
                code = self.namespace['retain']()
        finally:
            os.chdir(original_cwd)
        admitted = source.parent / 'ios-guest-cart-prepare-trace'
        result = json.loads((admitted / 'result.json').read_text()) \
            if (admitted / 'result.json').is_file() else None
        values = dict(line.split('=', 1) for line in outputs.read_text().splitlines()) \
            if outputs.is_file() else {}
        return code, result, values, source, admitted, console.getvalue()

    def test_private_exclusive_copy_and_only_fixed_admitted_output_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            data = self.payload()
            code, result, outputs, source, admitted, _ = self.execute(directory, data=data)
            self.assertEqual(code, 0)
            self.assertEqual(result['status'], 'PASS')
            self.assertEqual(result['sha256'], hashlib.sha256(data).hexdigest())
            self.assertEqual(source.read_bytes(), data)
            self.assertEqual((admitted / 'processes.jsonl').read_bytes(), data)
            self.assertEqual(admitted.stat().st_mode & 0o777, 0o700)
            self.assertTrue(all(path.stat().st_mode & 0o777 == 0o600 for path in admitted.iterdir()))
            self.assertEqual(outputs, {'preserved_output': '1',
                'result_ready': 'true', 'trace_ready': 'true'})

    def test_byte_and_event_limits_are_inclusive_and_plus_one_fails_closed(self):
        byte_limit = self.payload().rstrip(b'\n')
        byte_limit += b' ' * (2097152 - len(byte_limit) - 1) + b'\n'
        for payload, accepted in ((byte_limit, True), (byte_limit + b'\n', False),
                                  (self.payload(2048), True), (self.payload(2049), False)):
            with self.subTest(bytes=len(payload), accepted=accepted), tempfile.TemporaryDirectory() as directory:
                code, result, outputs, source, admitted, _ = self.execute(directory, data=payload)
                self.assertEqual(code, 0 if accepted else 2)
                self.assertEqual(result['status'], 'PASS' if accepted else 'FAIL')
                self.assertEqual(source.read_bytes(), payload)
                self.assertEqual('trace_ready' in outputs, accepted)
                self.assertEqual((admitted / 'processes.jsonl').exists(), accepted)

    def test_missing_empty_malformed_partial_or_wrong_shape_is_not_exported(self):
        for payload in (None, b'', b'SECRET_PAYLOAD', self.payload().rstrip(b'\n'),
                        b'[]\n', b'{"sequence":1}\n'):
            with self.subTest(payload=payload), tempfile.TemporaryDirectory() as directory:
                code, result, outputs, _, admitted, console = self.execute(directory, data=payload)
                self.assertEqual(code, 2)
                self.assertEqual(result['status'], 'FAIL')
                self.assertNotIn('trace_ready', outputs)
                self.assertFalse((admitted / 'processes.jsonl').exists())
                self.assertNotIn('SECRET', json.dumps(result) + console)

    def test_symlink_nonregular_or_public_trace_is_never_admitted(self):
        for kind in ('symlink', 'directory', 'fifo', 'public'):
            with self.subTest(kind=kind), tempfile.TemporaryDirectory() as directory:
                def setup(source):
                    if kind == 'symlink':
                        target = source.parent / 'private-target'
                        target.write_bytes(self.payload())
                        source.symlink_to(target)
                    elif kind == 'directory':
                        source.mkdir()
                    elif kind == 'fifo':
                        os.mkfifo(source, 0o600)
                    else:
                        source.write_bytes(self.payload())
                        source.chmod(0o644)
                code, result, outputs, _, admitted, _ = self.execute(directory, setup=setup)
                self.assertEqual(code, 2)
                self.assertEqual(result['status'], 'FAIL')
                self.assertNotIn('trace_ready', outputs)
                self.assertFalse((admitted / 'processes.jsonl').exists())

    def test_preexisting_destination_is_preserved_without_exporting_stale_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            def setup(source):
                admitted = source.parent / 'ios-guest-cart-prepare-trace'
                admitted.mkdir()
                (admitted / 'processes.jsonl').write_text('preserve existing evidence')
            code, _, outputs, _, admitted, _ = self.execute(directory, data=self.payload(), setup=setup)
            self.assertEqual(code, 2)
            self.assertEqual(outputs, {'preserved_output': '1'})
            self.assertEqual((admitted / 'processes.jsonl').read_text(), 'preserve existing evidence')

    def test_skipped_prepare_is_not_run_and_unknown_outcome_never_echoes_input(self):
        for outcome in ('skipped', '', 'SECRET_OUTCOME'):
            with self.subTest(outcome=outcome), tempfile.TemporaryDirectory() as directory:
                code, result, outputs, _, admitted, console = self.execute(directory, outcome=outcome)
                self.assertEqual(code, 2 if outcome == 'SECRET_OUTCOME' else 0)
                self.assertIsNone(result)
                self.assertFalse(admitted.exists())
                self.assertEqual(outputs, {'preserved_output': '1'})
                self.assertNotIn('SECRET', console)

    def test_prepare_failure_keeps_its_own_outcome_and_bounded_trace_or_guard_failure(self):
        for data, accepted in ((self.payload(), True), (b'SECRET_PAYLOAD', False)):
            with self.subTest(accepted=accepted), tempfile.TemporaryDirectory() as directory:
                code, result, outputs, _, _, _ = self.execute(directory, outcome='failure', data=data)
                self.assertEqual(code, 0 if accepted else 2)
                self.assertEqual(result['prepareOutcome'], 'failure')
                self.assertEqual(result['status'], 'PASS' if accepted else 'FAIL')
                self.assertEqual('trace_ready' in outputs, accepted)

    def test_copy_or_result_output_failure_cannot_publish_unqualified_trace(self):
        actual_open = os.open
        for target in ('processes.jsonl', 'result.json'):
            with self.subTest(target=target), tempfile.TemporaryDirectory() as directory:
                def deny(name, flags, mode=0o777, **kwargs):
                    if Path(name).name == target and flags & os.O_CREAT:
                        raise PermissionError(1, 'SECRET_WRITE')
                    return actual_open(name, flags, mode, **kwargs)
                with patch.object(os, 'open', side_effect=deny):
                    code, result, outputs, source, _, console = self.execute(directory, data=self.payload())
                self.assertEqual(code, 2)
                self.assertNotIn('trace_ready', outputs)
                self.assertEqual(source.read_bytes(), self.payload())
                self.assertNotIn('SECRET', console + json.dumps(result))

    def test_partial_or_failed_github_output_never_exports_partial_paths(self):
        actual_open = open
        for kind in ('partial', 'directory'):
            with self.subTest(kind=kind), tempfile.TemporaryDirectory() as directory:
                target = Path(directory) / 'github-output'
                if kind == 'directory':
                    target.mkdir()
                class PartialOutput:
                    def __enter__(self):
                        self.stream = actual_open(target, 'a')
                        return self
                    def write(self, _):
                        self.stream.write('result_ready=tru')
                        raise OSError('SECRET_OUTPUT_WRITE')
                    def __exit__(self, *args):
                        self.stream.close()
                def opened(path, mode='r', *args, **kwargs):
                    if kind == 'partial' and Path(path) == target and mode == 'a':
                        return PartialOutput()
                    return actual_open(path, mode, *args, **kwargs)
                with patch('builtins.open', side_effect=opened):
                    code, _, outputs, _, _, console = self.execute(directory, data=self.payload())
                self.assertEqual(code, 2)
                self.assertNotEqual(outputs.get('result_ready'), 'true')
                self.assertNotEqual(outputs.get('trace_ready'), 'true')
                self.assertNotIn('SECRET', console)

    def test_workflow_keeps_original_prepare_primary_and_fail_closed_guest_routing(self):
        android, ios = self.workflow.split('  ios-guest-cart:\n', 1)
        self.assertNotIn('--trace-processes', android)
        self.assertEqual(ios.count('--trace-processes'), 1)
        self.assertNotIn('--observe-', ios)
        self.assertNotIn('continue-on-error', ios)
        self.assertNotIn('|| true', ios)
        prepare = ios.split('      - name: Prepare a new owned Simulator headless\n', 1)[1].split('      - name:', 1)[0]
        self.assertIn('id: owned_prepare', prepare)
        self.assertIn('--headless', prepare)
        self.assertIn('--readiness-attestation owned-descriptor-launchd --trace-processes', prepare)
        self.assertNotIn('set +e', prepare)
        self.assertNotIn('exit ', prepare)
        guard = ios.split('      - name: Retain bounded passive prepare trace\n', 1)[1].split('      - name:', 1)[0]
        self.assertIn('if: always()', guard)
        guest = ios.split('      - name: Seed terminate and restore guest cart without VM transport\n', 1)[1].split('      - name:', 1)[0]
        self.assertNotIn('if:', guest)
        cleanup = ios.split('      - name: Clean up the owned guest cart Simulator\n', 1)[1].split('      - name:', 1)[0]
        self.assertIn('if: always()', cleanup)
        upload = ios.split('          path: |\n', 1)[1].split('          if-no-files-found:', 1)[0]
        self.assertEqual(upload.splitlines(), [
            '            build/task054/ios-guest-cart-restart/*.json',
            '            build/task054/ios-guest-cart-owned-receipt.json',
            "            ${{ steps.prepare_trace.outputs.result_ready == 'true' && 'build/task054/ios-guest-cart-prepare-trace/result.json' || '' }}",
            "            ${{ steps.prepare_trace.outputs.trace_ready == 'true' && 'build/task054/ios-guest-cart-prepare-trace/processes.jsonl' || '' }}"])
        self.assertNotIn('owned-receipt.processes.jsonl', upload)
        self.assertIn('retention-days: 7', ios)


if __name__ == '__main__':
    unittest.main()
