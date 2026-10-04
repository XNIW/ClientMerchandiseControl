#!/usr/bin/env python3
"""Regressioni del runner con processi simulati: nessun device viene controllato."""
import json
from pathlib import Path
import signal
import subprocess
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

SOURCE = (Path(__file__).parent / 'test-task054-visual.sh').read_text().split("<<'PYCODE'\n", 1)[1].rsplit('\nPYCODE', 1)[0]


class VisualRunnerTest(unittest.TestCase):
    def execute(self, primary=0, shutdown_error=None, delete_error=None,
                drive_timeout=False, owned=True, drive_signal=None,
                process_cleanup_error=None, environment=None, external_device='foreign-device'):
        actions = []
        processes = []
        handlers = {}
        owned_stop = Mock(side_effect=process_cleanup_error)
        module = SimpleNamespace(stop_owned_process=owned_stop, Failure=RuntimeError)
        spec = Mock()

        def output(command, **kwargs):
            if command[0] == 'xcode-select':
                return '/mock/Developer\n'
            if command[2] == 'list':
                return json.dumps({'runtimes': [{'isAvailable': True,
                    'identifier': 'com.apple.CoreSimulator.SimRuntime.iOS-26-1',
                    'version': '26.1'}]}).encode()
            return 'owned-device\n'

        def process(command, **kwargs):
            child = Mock(pid=54321)
            is_drive = command[0] == 'flutter'
            child.wait.side_effect = ([subprocess.TimeoutExpired(command, 900), 0, 0, 0]
                                     if is_drive and drive_timeout else None)
            child.wait.return_value = primary if is_drive else 0
            if is_drive and drive_signal:
                attempts = []

                def interrupted_wait(**kwargs):
                    if not attempts:
                        attempts.append(True)
                        handlers[drive_signal](drive_signal, None)
                    return 0

                child.wait.side_effect = interrupted_wait
            processes.append(command)
            return child

        def cleanup(command, **kwargs):
            actions.append(command[2])
            self.assertEqual(command[-1], 'owned-device')
            self.assertEqual(kwargs['timeout'], 30)
            error = shutdown_error if command[2] == 'shutdown' else delete_error
            if error:
                raise error
            return Mock(returncode=0)

        with patch('sys.argv', ['runner', '--ios'] if owned else ['runner', '--device', external_device]), \
             patch('os.environ', {'CMC_TASK054_SCRIPTS_DIR': str(Path(__file__).parent),
                                 **(environment or {})}), \
             patch('os.path.isdir', return_value=True), \
             patch('importlib.util.spec_from_file_location', return_value=spec), \
             patch('importlib.util.module_from_spec', return_value=module), \
             patch('subprocess.check_output', side_effect=output), \
             patch('subprocess.Popen', side_effect=process), \
             patch('subprocess.run', side_effect=cleanup), patch('os.killpg') as kill, \
             patch('signal.signal', side_effect=lambda key, handler: handlers.update({key: handler})):
            try:
                exec(compile(SOURCE, 'test-task054-visual.sh', 'exec'), {})
                code = 0
            except SystemExit as error:
                code = error.code
            self.owned_stops = owned_stop.call_args_list
            self.terminated_groups = [call.args for call in kill.call_args_list]
        return code, actions, processes

    def test_success_cleanup(self):
        code, actions, processes = self.execute()
        self.assertEqual(code, 0)
        self.assertEqual(actions, ['shutdown', 'delete'])
        self.assertIn('--dart-define=CMC_OS_FRAME_CAPTURE=true', processes[-1])

    def test_primary_failure_preserved(self):
        code, actions, _ = self.execute(primary=7)
        self.assertEqual(code, 7)
        self.assertEqual(actions, ['shutdown', 'delete'])

    def test_shutdown_timeout_still_deletes(self):
        code, actions, _ = self.execute(shutdown_error=subprocess.TimeoutExpired('shutdown', 30))
        self.assertEqual(code, 1)
        self.assertEqual(actions, ['shutdown', 'delete'])

    def test_shutdown_oserror_still_deletes(self):
        code, actions, _ = self.execute(shutdown_error=OSError('mock'))
        self.assertEqual(code, 1)
        self.assertEqual(actions, ['shutdown', 'delete'])

    def test_cleanup_does_not_mask_primary_failure(self):
        code, actions, _ = self.execute(primary=7, shutdown_error=OSError('mock'))
        self.assertEqual(code, 7)
        self.assertEqual(actions, ['shutdown', 'delete'])

    def test_drive_timeout_preserves_124_and_cleans(self):
        code, actions, _ = self.execute(drive_timeout=True)
        self.assertEqual(code, 124)
        self.assertEqual(actions, ['shutdown', 'delete'])

    def test_delete_failure_fails_successful_run(self):
        code, actions, _ = self.execute(delete_error=OSError('mock'))
        self.assertEqual(code, 1)
        self.assertEqual(actions, ['shutdown', 'delete'])

    def test_external_device_is_never_cleaned(self):
        code, actions, processes = self.execute(primary=7, owned=False)
        self.assertEqual(code, 7)
        self.assertEqual(actions, [])
        self.assertIn('--dart-define=CMC_OS_FRAME_CAPTURE=false', processes[-1])

    def test_term_stops_owned_drive_group_then_shuts_down_and_deletes(self):
        code, actions, _ = self.execute(drive_signal=signal.SIGTERM)
        self.assertEqual(code, 143)
        self.assertEqual(actions, ['shutdown', 'delete'])
        self.assertEqual(len(self.owned_stops), 1)
        self.assertEqual(self.owned_stops[0].args[0].pid, 54321)
        self.assertEqual(self.owned_stops[0].kwargs, {'term_grace': 20})
        self.assertEqual(self.terminated_groups, [])

    def test_int_stops_drive_without_touching_external_device(self):
        code, actions, _ = self.execute(drive_signal=signal.SIGINT, owned=False)
        self.assertEqual(code, 130)
        self.assertEqual(actions, [])
        self.assertEqual(len(self.owned_stops), 1)
        self.assertEqual(self.owned_stops[0].args[0].pid, 54321)
        self.assertEqual(self.owned_stops[0].kwargs, {'term_grace': 20})
        self.assertEqual(self.terminated_groups, [])

    def test_signal_failure_survives_cleanup_failure(self):
        code, actions, _ = self.execute(drive_signal=signal.SIGTERM,
            shutdown_error=OSError('mock'))
        self.assertEqual(code, 143)
        self.assertEqual(actions, ['shutdown', 'delete'])

    def test_owned_group_cleanup_failure_preserves_timeout_and_device_cleanup(self):
        code, actions, _ = self.execute(drive_timeout=True,
            process_cleanup_error=RuntimeError('controlled'))
        self.assertEqual(code, 124)
        self.assertEqual(actions, ['shutdown', 'delete'])

    def test_explicit_owned_os_context_is_forwarded_without_device_cleanup(self):
        device = '12345678-1234-4234-8234-123456789abc'
        code, actions, processes = self.execute(owned=False, external_device=device,
            environment={'CMC_OS_FRAME_PLATFORM': 'ios', 'CMC_OS_FRAME_DEVICE': device})
        self.assertEqual(code, 0)
        self.assertEqual(actions, [])
        self.assertIn('--dart-define=CMC_OS_FRAME_CAPTURE=true', processes[-1])

    def test_wrong_or_partial_os_context_does_not_start_flutter(self):
        for context in ({'CMC_OS_FRAME_PLATFORM': 'ios'},
                        {'CMC_OS_FRAME_DEVICE': 'foreign-device'},
                        {'CMC_OS_FRAME_PLATFORM': 'ios', 'CMC_OS_FRAME_DEVICE': 'other-device'},
                        {'CMC_OS_FRAME_PLATFORM': 'unknown', 'CMC_OS_FRAME_DEVICE': 'foreign-device'}):
            code, actions, processes = self.execute(owned=False, environment=context)
            self.assertEqual(code, 2)
            self.assertEqual(actions, [])
            self.assertEqual(processes, [])


if __name__ == '__main__':
    unittest.main()
