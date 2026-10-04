#!/usr/bin/env python3
"""Processi/SDK simulati: verifica ownership e failure, senza build o emulatori."""
import importlib.util
import json
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import Mock, patch


SCRIPT = Path(__file__).with_name('run-task054-android-visual.py')
SPEC = importlib.util.spec_from_file_location('android_visual_runner', SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class AndroidVisualRunnerTest(unittest.TestCase):
    def test_real_descendant_ignoring_term_is_stopped_after_leader_exit(self):
        with tempfile.TemporaryDirectory() as directory:
            pid_file = Path(directory) / 'child.pid'
            child_source = (
                'import os, signal, time; from pathlib import Path; '
                'signal.signal(signal.SIGTERM, signal.SIG_IGN); '
                f'Path({str(pid_file)!r}).write_text(str(os.getpid())); time.sleep(60)')
            leader_source = (
                'import subprocess, sys, time; '
                f'subprocess.Popen([sys.executable, "-c", {child_source!r}]); time.sleep(60)')
            leader = subprocess.Popen([sys.executable, '-c', leader_source],
                start_new_session=True, stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            child_pid = None
            try:
                deadline = time.monotonic() + 3
                while not pid_file.exists() and time.monotonic() < deadline:
                    time.sleep(0.01)
                self.assertTrue(pid_file.exists(), 'child readiness bounded')
                child_pid = int(pid_file.read_text())
                MODULE.stop_owned_process(leader)
                status = subprocess.run(['ps', '-p', str(child_pid), '-o', 'stat='],
                    capture_output=True, text=True, timeout=2, check=False).stdout.strip()
                self.assertTrue(not status or status.startswith('Z'),
                    f'discendente proprio ancora vivo: {status}')
                self.assertEqual(leader.returncode, -signal.SIGTERM)
            finally:
                try:
                    MODULE.os.killpg(leader.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                leader.wait(timeout=5)
                if child_pid is not None:
                    deadline = time.monotonic() + 2
                    while time.monotonic() < deadline:
                        status = subprocess.run(['ps', '-p', str(child_pid), '-o', 'stat='],
                            capture_output=True, text=True, timeout=2, check=False).stdout.strip()
                        if not status or status.startswith('Z'):
                            break
                        time.sleep(0.01)
                    self.assertTrue(not status or status.startswith('Z'), 'cleanup test bounded')

    def execute(self, failure=None, cleanup_failure=False, foreign=False,
                early_exit=False, wrong_api=False, capture_count=103):
        calls = []
        environments = []
        emulator = Mock(pid=12345)
        emulator.poll.return_value = 19 if early_exit else None
        emulator.wait.return_value = 0
        with tempfile.TemporaryDirectory() as directory:
            runner = MODULE.AndroidVisualRunner(directory)
            runner.environment = {'ANDROID_HOME': '/fake/sdk', 'RUNNER_TEMP': directory}
            owned_paths = []

            def process(arguments, **kwargs):
                calls.append(arguments)
                environments.append(kwargs['env'].copy())
                self.assertTrue(kwargs['start_new_session'])
                if '-avd' in arguments:
                    return emulator
                child = Mock(pid=54321, returncode=0)
                phase = runner.phase
                child.returncode = 7 if phase == failure else 0
                if phase == 'avd-create' and not child.returncode:
                    path = Path(arguments[arguments.index('-p') + 1])
                    path.mkdir()
                    owned_paths.append(runner.owned_directory)
                if phase == 'avd-delete' and cleanup_failure:
                    child.returncode = 11
                output = ''
                if arguments[0] == 'git':
                    output = 'a' * 40
                elif 'get-state' in arguments:
                    output = 'device'
                elif arguments[-3:] == ['emu', 'avd', 'name']:
                    output = ('foreign-avd' if foreign else runner.avd_name) + '\nOK'
                elif arguments[-1] == 'sys.boot_completed':
                    output = '1'
                elif arguments[-3:] == ['pm', 'path', 'android']:
                    output = 'package:/system/framework/framework-res.apk'
                elif arguments[-1] == 'ro.build.version.sdk':
                    output = '34' if wrong_api else '35'
                elif arguments[-1] == 'ro.product.cpu.abi':
                    output = 'x86_64'
                elif arguments[0] == 'bash' and not child.returncode:
                    captures = Path(kwargs['env']['CMC_VISUAL_OUTPUT_DIR'])
                    captures.mkdir(parents=True)
                    for index in range(capture_count):
                        (captures / f'fake-{index}.png').write_bytes(b'fake')
                child.communicate.return_value = (output, None)
                return child

            with patch.object(MODULE.platform, 'system', return_value='Linux'), \
                 patch.object(MODULE.platform, 'machine', return_value='x86_64'), \
                 patch.object(MODULE.os, 'access', return_value=True), \
                 patch.object(MODULE.socket, 'socket') as socket_type, \
                 patch.object(MODULE, 'owned_group_has_live_members', return_value=False), \
                 patch.object(MODULE.subprocess, 'Popen', side_effect=process), \
                 patch.object(MODULE.os, 'killpg') as kill:
                code = runner.run()
                receipt = json.loads((Path(directory) /
                    'build/task054/android-visual-receipt.json').read_text())
                self.assertTrue(all(not path.exists() for path in owned_paths))
                self.assertEqual(code, receipt['exit_code'])
                self.assertEqual(receipt['evidence_level'], 'native_android_fixture')
                killed = kill.call_args_list
        return code, calls, environments, killed, receipt, runner

    def test_success_checks_readiness_identity_platform_and_owns_cleanup(self):
        code, calls, environments, killed, receipt, runner = self.execute()
        self.assertEqual(code, 0)
        self.assertEqual(receipt['cleanup'], 'PASS')
        self.assertEqual(receipt['revision'], 'a' * 40)
        self.assertEqual(receipt['capture_count'], 103)
        drive = next(args for args in calls if args[0] == 'bash')
        self.assertEqual(drive, ['bash', 'scripts/test-task054-visual.sh',
            '--device', runner.serial])
        self.assertEqual(runner.serial, 'emulator-5554')
        self.assertEqual(killed[0].args, (12345, signal.SIGTERM))
        delete = calls[-1]
        self.assertEqual(delete[-4:], ['delete', 'avd', '-n', runner.avd_name])
        self.assertEqual(environments[-1]['ANDROID_AVD_HOME'],
            str(runner.owned_directory / 'avd'))
        self.assertNotIn('HOME', environments[-1])
        self.assertFalse(any('kill-server' in args or 'kill' in args for args in calls))

    def test_capture_failure_and_cleanup_failure_preserve_primary_code(self):
        code, calls, _, _, receipt, _ = self.execute(
            failure='native-fixture-capture', cleanup_failure=True)
        self.assertEqual(code, 7)
        self.assertEqual(receipt['cleanup'], 'FAIL')
        self.assertEqual(receipt['failed_phase'], 'native-fixture-capture')
        self.assertIn('delete', calls[-1])

    def test_cleanup_failure_fails_successful_capture(self):
        code, _, _, _, receipt, _ = self.execute(cleanup_failure=True)
        self.assertEqual(code, 1)
        self.assertEqual(receipt['cleanup'], 'FAIL')

    def test_sdk_failure_never_launches_emulator_or_fixture(self):
        code, calls, _, killed, receipt, runner = self.execute(failure='sdk-install')
        self.assertEqual(code, 7)
        self.assertEqual(receipt['failed_phase'], 'sdk-install')
        self.assertEqual(len(calls), 2)
        self.assertEqual(killed, [])
        self.assertFalse(runner.owned_directory.exists())

    def test_foreign_identity_is_never_used_or_stopped_via_adb(self):
        code, calls, _, killed, receipt, _ = self.execute(foreign=True)
        self.assertEqual(code, 2)
        self.assertEqual(receipt['failed_phase'], 'device-identity')
        self.assertFalse(any('shell' in args or args[0] == 'bash' for args in calls))
        self.assertTrue(all(call.args[0] == 12345 for call in killed))

    def test_early_emulator_exit_stops_dependent_phases(self):
        code, calls, _, _, receipt, _ = self.execute(early_exit=True)
        self.assertEqual(code, 19)
        self.assertEqual(receipt['failed_phase'], 'adb-online')
        self.assertFalse(any('get-state' in args or args[0] == 'bash' for args in calls))

    def test_wrong_device_api_fails_before_capture(self):
        code, calls, _, _, receipt, _ = self.execute(wrong_api=True)
        self.assertEqual(code, 2)
        self.assertEqual(receipt['failed_phase'], 'device-platform')
        self.assertFalse(any(args[0] == 'bash' for args in calls))

    def test_partial_capture_is_not_promoted_to_success(self):
        code, _, _, _, receipt, _ = self.execute(capture_count=102)
        self.assertEqual(code, 1)
        self.assertEqual(receipt['failed_phase'], 'capture-completeness')
        self.assertEqual(receipt['capture_count'], 102)

    def test_readiness_polls_then_runs_only_once_when_ready(self):
        runner = MODULE.AndroidVisualRunner('/fake')
        runner.emulator = Mock()
        runner.emulator.poll.return_value = None
        with patch.object(runner, 'command', side_effect=[(1, 'offline'), (0, 'device')]) as command, \
             patch.object(MODULE.time, 'sleep'):
            runner.wait_ready('adb-online', 60, ['adb', '-s', 'owned', 'get-state'],
                lambda output: output == 'device')
        self.assertEqual(command.call_count, 2)
        self.assertTrue(all(0 < call.args[1] <= 10 for call in command.call_args_list))

    def test_readiness_deadline_is_bounded_and_reports_124(self):
        runner = MODULE.AndroidVisualRunner('/fake')
        runner.emulator = Mock()
        runner.emulator.poll.return_value = None
        ticks = iter(range(100))
        with patch.object(runner, 'command', return_value=(1, 'offline')) as command, \
             patch.object(MODULE.time, 'monotonic', side_effect=lambda: next(ticks)), \
             patch.object(MODULE.time, 'sleep'), self.assertRaises(MODULE.Failure) as failure:
            runner.wait_ready('adb-online', 4, ['adb', '-s', 'owned', 'get-state'],
                lambda output: output == 'device')
        self.assertEqual(failure.exception.code, 124)
        self.assertEqual(command.call_count, 1)

    def test_command_timeout_kills_only_its_group_and_preserves_124(self):
        runner = MODULE.AndroidVisualRunner('/fake')
        child = Mock(pid=54321)
        child.communicate.side_effect = subprocess.TimeoutExpired('fake', 3)
        child.wait.return_value = 0
        with patch.object(MODULE.subprocess, 'Popen', return_value=child), \
             patch.object(MODULE.os, 'killpg') as kill, \
             patch.object(MODULE, 'owned_group_has_live_members', side_effect=[True, False]), \
             patch.object(MODULE.time, 'monotonic', side_effect=[0, 6, 6]), \
             self.assertRaises(MODULE.Failure) as failure:
            runner.command(['fake'], 3)
        self.assertEqual(failure.exception.code, 124)
        self.assertEqual([call.args for call in kill.call_args_list],
            [(54321, signal.SIGTERM), (54321, signal.SIGKILL)])

    def test_interrupt_is_translated_and_owned_child_is_stopped(self):
        runner = MODULE.AndroidVisualRunner('/fake')
        child = Mock(pid=54321)
        child.communicate.side_effect = MODULE.Failure('signal', 143, 'interrotto')
        with patch.object(MODULE.subprocess, 'Popen', return_value=child), \
             patch.object(MODULE, 'owned_group_has_live_members', return_value=False), \
             patch.object(MODULE.os, 'killpg') as kill, \
             self.assertRaises(MODULE.Failure) as failure:
            runner.command(['fake'], None, capture=False)
        self.assertEqual(failure.exception.code, 143)
        kill.assert_called_once_with(54321, signal.SIGTERM)

    def test_cleanup_error_cannot_mask_command_timeout(self):
        runner = MODULE.AndroidVisualRunner('/fake')
        child = Mock(pid=54321)
        child.communicate.side_effect = subprocess.TimeoutExpired('fake', 3)
        with patch.object(MODULE.subprocess, 'Popen', return_value=child), \
             patch.object(MODULE, 'stop_owned_process', side_effect=OSError('mock')), \
             self.assertRaises(MODULE.Failure) as failure:
            runner.command(['fake'], 3)
        self.assertEqual(failure.exception.code, 124)
        self.assertTrue(runner.cleanup_failed)

    def test_zombie_only_group_is_quiescent_and_foreign_members_are_ignored(self):
        snapshot = Mock(returncode=0, stdout='54321 Z\n11111 S\n')
        with patch.object(MODULE.subprocess, 'run', return_value=snapshot):
            self.assertFalse(MODULE.owned_group_has_live_members(54321))

    def test_live_descendant_is_detected_even_with_zombie_leader(self):
        snapshot = Mock(returncode=0, stdout='54321 Z\n54321 S\n')
        with patch.object(MODULE.subprocess, 'run', return_value=snapshot):
            self.assertTrue(MODULE.owned_group_has_live_members(54321))

    def test_invalid_group_snapshot_fails_closed(self):
        snapshot = Mock(returncode=0, stdout='unverifiable\n')
        with patch.object(MODULE.subprocess, 'run', return_value=snapshot), \
             self.assertRaises(MODULE.Failure):
            MODULE.owned_group_has_live_members(54321)

    def test_kill_cannot_claim_success_with_remaining_live_group(self):
        child = Mock(pid=54321)
        with patch.object(MODULE.os, 'killpg') as kill, \
             patch.object(MODULE, 'owned_group_has_live_members', return_value=True), \
             patch.object(MODULE.time, 'monotonic', side_effect=[0, 6, 6, 12]), \
             self.assertRaises(MODULE.Failure):
            MODULE.stop_owned_process(child)
        self.assertEqual([call.args for call in kill.call_args_list],
            [(54321, signal.SIGTERM), (54321, signal.SIGKILL)])
        child.wait.assert_not_called()

    def test_kvm_unavailable_stops_before_mutating_resources(self):
        with tempfile.TemporaryDirectory() as directory:
            runner = MODULE.AndroidVisualRunner(directory)
            with patch.object(MODULE.platform, 'system', return_value='Linux'), \
                 patch.object(MODULE.platform, 'machine', return_value='x86_64'), \
                 patch.object(MODULE.os, 'access', return_value=False), \
                 patch.object(MODULE.subprocess, 'Popen') as process:
                self.assertEqual(runner.run(), 2)
            process.assert_not_called()
            self.assertIsNone(runner.owned_directory)


if __name__ == '__main__':
    unittest.main()
