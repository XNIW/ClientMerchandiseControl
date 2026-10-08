#!/usr/bin/env python3
"""Unit runner: failure chiusa e singolo APK. Nessuna prova runtime Android."""
import hashlib
import importlib.util
import json
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('journal_runner',
    Path(__file__).with_name('run-address-journal-android.py'))
M = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(M)
RUN_ID = 'f0540000-0000-4000-8000-000000000002'


def evidence(phase='seed', pid=12, seed=12):
    return {'apiVersion': 'address-journal-native-evidence.v2', 'phase': phase,
        'runId': RUN_ID, 'processId': pid, 'seedProcessId': seed,
        'nativeWriteRead': 'PASS' if phase == 'seed' else 'NOT_RUN',
        'processRestartRead': 'PASS' if phase == 'recover' else 'NOT_RUN',
        'cleanup': 'PASS' if phase == 'recover' else 'NOT_RUN', 'backend': 'NOT_RUN'}


class JournalRunnerTest(unittest.TestCase):
    def test_only_matching_seed_and_recover_receipts_are_accepted(self):
        for phase, pid in [('seed', 12), ('recover', 13)]:
            self.assertEqual(M.validate_receipt(evidence(phase, pid), phase,
                RUN_ID, pid, 12), evidence(phase, pid))

    def test_replay_missing_cleanup_wrong_pid_or_backend_claim_fail_closed(self):
        for key, value in [('phase', 'seed'), ('processId', 12), ('seedProcessId', 99),
                ('runId', 'stale'), ('cleanup', 'NOT_RUN'), ('backend', 'PASS'),
                ('apiVersion', 'unknown'), ('processRestartRead', 'NOT_RUN')]:
            with self.subTest(key=key):
                data = evidence('recover', 13)
                data[key] = value
                with self.assertRaises(M.Failure):
                    M.validate_receipt(data, 'recover', RUN_ID, 13, 12)
        with self.assertRaises(M.Failure):
            M.validate_receipt(evidence('recover', 12), 'recover', RUN_ID, 12, 12)

    def execute_fixture(self, *, pid_reuse=False, changed_identity=False, seed_error=False):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        runner = M.AddressJournalRunner(directory.name)
        runner.serial = 'emulator-5554'
        runner.run_id = RUN_ID
        apk = Path(directory.name) / 'build/app/outputs/flutter-apk/app-debug.apk'
        apk.parent.mkdir(parents=True)
        apk.write_bytes(b'owned synthetic apk')
        identity = {'uid': 10123, 'apk_sha256': hashlib.sha256(apk.read_bytes()).hexdigest()}
        identities = [identity, dict(identity, uid=10124) if changed_identity else identity, identity]
        calls = []

        def device(args, *_args, **_kwargs):
            calls.append(('device', args))
            return (0, '')

        def drive(phase, *_args):
            calls.append(('drive', phase))
            if seed_error and phase == 'seed':
                raise M.Failure('seed', 7, 'fixture')

        with patch.object(runner, 'prepare_device', return_value=Path('/owned/adb')), \
             patch.object(runner, 'command', side_effect=lambda args, *_args, **_kwargs:
                 calls.append(('command', args)) or (0, '')), \
             patch.object(runner, 'device', side_effect=device), \
             patch.object(runner, 'identity', side_effect=identities), \
             patch.object(runner, 'launch', side_effect=[12, 12 if pid_reuse else 13]), \
             patch.object(runner, 'drive', side_effect=drive), \
             patch.object(runner, 'stop_seed', side_effect=lambda pid: calls.append(('stop', pid))):
            try:
                runner.execute()
                failure = None
            except M.Failure as error:
                failure = error
        return calls, failure

    def test_one_build_and_install_then_two_processes_with_force_stop_between(self):
        calls, failure = self.execute_fixture()
        self.assertIsNone(failure)
        self.assertEqual(len([c for kind, c in calls if kind == 'command' and c[:2] == ['flutter', 'build']]), 1)
        self.assertEqual(len([c for kind, c in calls if kind == 'device' and c[0] == 'install']), 1)
        self.assertEqual([c for c in calls if c[0] in ('drive', 'stop')],
            [('drive', 'seed'), ('stop', 12), ('drive', 'recover')])
        self.assertFalse(any('uninstall' in c or 'clear' in c for kind, c in calls if kind == 'device'))

    def test_pid_reuse_rejects_restart_without_running_recover(self):
        calls, failure = self.execute_fixture(pid_reuse=True)
        self.assertIsNotNone(failure)
        self.assertNotIn(('drive', 'recover'), calls)

    def test_changed_uid_rejects_restart_before_second_launch(self):
        calls, failure = self.execute_fixture(changed_identity=True)
        self.assertIsNotNone(failure)
        self.assertNotIn(('drive', 'recover'), calls)

    def test_seed_failure_stops_dependent_restart(self):
        calls, failure = self.execute_fixture(seed_error=True)
        self.assertEqual(failure.code, 7)
        self.assertNotIn(('stop', 12), calls)
        self.assertNotIn(('drive', 'recover'), calls)

    def test_force_stop_requires_absent_proc_and_empty_package_pid(self):
        runner = M.AddressJournalRunner('/owned')
        runner.adb, runner.serial = '/owned/adb', 'emulator-5554'
        with patch.object(runner, 'device', side_effect=[(0, ''), (0, '12')]), \
             patch.object(runner, 'wait_ready') as wait:
            with self.assertRaises(M.Failure):
                runner.stop_seed(12)
        self.assertEqual(wait.call_args.args[2][-4:], ['test', '!', '-e', '/proc/12'])
        self.assertNotIn('seed_terminated', runner.results)

    def test_driver_attaches_existing_app_without_install_or_launch(self):
        with tempfile.TemporaryDirectory() as directory:
            runner = M.AddressJournalRunner(directory)
            runner.run_id, runner.serial = RUN_ID, 'emulator-5554'
            runner.output.mkdir(parents=True)
            (runner.output / 'seed.json').write_text(json.dumps(evidence()))
            with patch.object(runner, 'service_uri', return_value='http://127.0.0.1:1234/fixture=/'), \
                 patch.object(runner, 'command', return_value=(0, '')) as command, \
                 patch.object(runner, 'device', return_value=(0, '12')):
                runner.drive('seed', 12, 12)
            args = command.call_args.args[0]
            self.assertIn('--use-existing-app=http://127.0.0.1:1234/fixture=/', args)
            self.assertIn('--keep-app-running', args)
            self.assertNotIn('--use-application-binary', args)
            self.assertFalse(command.call_args.kwargs['check'])

    def test_failed_driver_never_accepts_stale_receipt(self):
        with tempfile.TemporaryDirectory() as directory:
            runner = M.AddressJournalRunner(directory)
            runner.output.mkdir(parents=True)
            (runner.output / 'seed.json').write_text(json.dumps(evidence()))
            with patch.object(runner, 'service_uri', return_value='http://127.0.0.1:1234/fixture=/'), \
                 patch.object(runner, 'command', return_value=(7, 'private vm log')):
                with self.assertRaises(M.Failure) as failure:
                    runner.drive('seed', 12, 12)
            self.assertEqual(failure.exception.code, 7)
            self.assertEqual(runner.results, {})

    def test_cleanup_removes_only_owned_forwards_and_still_cleans_avd_after_error(self):
        runner = M.AddressJournalRunner('/owned')
        runner.forwards = {'1234'}
        with patch.object(runner, 'device', side_effect=M.Failure('forward', 7, 'fixture')) as device, \
             patch.object(M.OWNED.AndroidVisualRunner, 'cleanup') as cleanup:
            with self.assertRaises(M.Failure):
                runner.cleanup()
        device.assert_called_once_with(['forward', '--remove', 'tcp:1234'])
        cleanup.assert_called_once()
        self.assertTrue(runner.cleanup_failed)

    def test_primary_exit_is_preserved_when_cleanup_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            runner = M.AddressJournalRunner(directory)
            with patch.object(runner, 'execute', side_effect=M.Failure('seed', 7, 'fixture')), \
                 patch.object(runner, 'cleanup', side_effect=M.Failure('cleanup', 9, 'fixture')):
                self.assertEqual(runner.run(), 7)
            receipt = json.loads((Path(directory) / 'build/task054/address-journal-receipt.json').read_text())
            self.assertEqual(receipt['exit_code'], 7)
            self.assertNotEqual(receipt['restart'], 'PASS')

    def test_real_driver_signal_exit_matches_receipt_despite_cleanup_failure(self):
        for signum in (signal.SIGTERM, signal.SIGKILL):
            with self.subTest(signum=signum), tempfile.TemporaryDirectory() as directory:
                script = f'''
import importlib.util
from pathlib import Path
import sys
from unittest.mock import patch
spec = importlib.util.spec_from_file_location('journal_signal', {str(SPEC.origin)!r})
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
runner = module.AddressJournalRunner({directory!r})
runner.serial = 'emulator-owned-test'
command = runner.command
def signalled_driver(*args, **kwargs):
    return command([sys.executable, '-c',
        'import os, signal; os.kill(os.getpid(), {int(signum)})'], 3, check=False)
with patch.object(runner, 'service_uri', return_value='http://127.0.0.1:1234/fixture=/'), \\
     patch.object(runner, 'command', side_effect=signalled_driver), \\
     patch.object(runner, 'execute', side_effect=lambda: runner.drive('seed', 12, 12)), \\
     patch.object(runner, 'cleanup', side_effect=module.Failure('cleanup', 9, 'fixture')):
    sys.exit(runner.run())
'''
                process = subprocess.run([sys.executable, '-c', script], capture_output=True,
                    text=True, timeout=10, check=False)
                expected = 128 + int(signum)
                self.assertEqual(process.returncode, expected, process.stderr)
                receipt = json.loads((Path(directory) /
                    'build/task054/address-journal-receipt.json').read_text())
                self.assertEqual(receipt['exit_code'], process.returncode)
                self.assertNotEqual(receipt['restart'], 'PASS')

    def test_visual_runner_still_prepares_before_capture_and_requires_137(self):
        with tempfile.TemporaryDirectory() as directory:
            runner = M.OWNED.AndroidVisualRunner(directory)
            visual = Path(directory) / 'visual'
            visual.mkdir()
            for number in range(137):
                (visual / f'{number}.png').touch()
            runner.environment['CMC_VISUAL_OUTPUT_DIR'] = str(visual)
            runner.serial = 'emulator-5554'
            sequence = []
            with patch.object(runner, 'prepare_device', side_effect=lambda:
                    sequence.append('prepare') or Path('/owned/adb')), \
                 patch.object(runner, 'command', side_effect=lambda *_args, **_kwargs:
                    sequence.append('capture') or (0, '')):
                runner.execute()
            self.assertEqual(sequence, ['prepare', 'capture'])
            self.assertEqual(runner.capture_count, 137)


if __name__ == '__main__':
    unittest.main()
