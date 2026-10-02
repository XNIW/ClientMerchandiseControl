#!/usr/bin/env python3
"""Regressioni del runner con processi simulati: nessun device viene controllato."""
import json
from pathlib import Path
import subprocess
import unittest
from unittest.mock import Mock, patch

SOURCE = (Path(__file__).parent / 'test-task054-visual.sh').read_text().split("<<'PYCODE'\n", 1)[1].rsplit('\nPYCODE', 1)[0]


class VisualRunnerTest(unittest.TestCase):
    def execute(self, primary=0, shutdown_error=None, delete_error=None,
                drive_timeout=False, owned=True):
        actions = []
        processes = []

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

        with patch('sys.argv', ['runner', '--ios'] if owned else ['runner', '--device', 'foreign-device']), \
             patch('os.environ', {}), patch('os.path.isdir', return_value=True), \
             patch('subprocess.check_output', side_effect=output), \
             patch('subprocess.Popen', side_effect=process), \
             patch('subprocess.run', side_effect=cleanup), patch('os.killpg'):
            try:
                exec(compile(SOURCE, 'test-task054-visual.sh', 'exec'), {})
                code = 0
            except SystemExit as error:
                code = error.code
        return code, actions, processes

    def test_success_cleanup(self):
        code, actions, _ = self.execute()
        self.assertEqual(code, 0)
        self.assertEqual(actions, ['shutdown', 'delete'])

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
        code, actions, _ = self.execute(primary=7, owned=False)
        self.assertEqual(code, 7)
        self.assertEqual(actions, [])


if __name__ == '__main__':
    unittest.main()
