#!/usr/bin/env python3
"""Regressioni della misura: solo processi Python propri, nessun simulatore."""
import importlib.util
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch


SPEC = importlib.util.spec_from_file_location('measured_ios_process',
    Path(__file__).with_name('trace-ios-owned-process.py'))
TRACE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(TRACE)
PREFLIGHT_SPEC = importlib.util.spec_from_file_location('measured_ios_preflight',
    Path(__file__).with_name('run-ios-preflight-measured.py'))
PREFLIGHT = importlib.util.module_from_spec(PREFLIGHT_SPEC)
PREFLIGHT_SPEC.loader.exec_module(PREFLIGHT)


class ProcessTraceTest(unittest.TestCase):
    def rows(self, path):
        rows = [json.loads(line) for line in path.read_text().splitlines()]
        self.assertEqual([row['sequence'] for row in rows], list(range(1, len(rows) + 1)))
        self.assertEqual(sorted(row['monotonic_ns'] for row in rows),
                         [row['monotonic_ns'] for row in rows])
        return rows

    def test_success_has_complete_valid_output_and_reap_without_payload_or_argv(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'trace.jsonl'
            with TRACE.trace_processes(path):
                result = subprocess.run([sys.executable, '-c',
                    'print("{\\\"SECRET_SENTINEL\\\": 1}")'], start_new_session=True,
                    capture_output=True, text=True, timeout=2, check=True)
            self.assertEqual(result.returncode, 0)
            rows = self.rows(path)
            ending = [row for row in rows if row['event'] == 'communicate-end'][-1]
            self.assertTrue(ending['output_complete'])
            self.assertEqual(ending['stdout']['json'], 'valid')
            self.assertTrue(any(row.get('reaped') for row in rows))
            self.assertNotIn('SECRET_SENTINEL', path.read_text())
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)

    def test_live_timeout_is_distinct_and_group_signals_and_reap_are_measured(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'trace.jsonl'
            with TRACE.trace_processes(path):
                process = subprocess.Popen([sys.executable, '-c',
                    'import time;time.sleep(10)'], start_new_session=True,
                    stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                try:
                    with self.assertRaises(subprocess.TimeoutExpired):
                        process.communicate(timeout=.1)
                finally:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.communicate(timeout=2)
            rows = self.rows(path)
            timeout = [row for row in rows if row['event'] == 'communicate-timeout'][0]
            self.assertEqual(timeout['leader_state'], 'alive')
            self.assertEqual(timeout['inherited_pipe'], 'not_demonstrated')
            self.assertFalse(timeout['output_complete'])
            self.assertTrue(any(row['event'] == 'group-signal-end' and
                                row['signal'] == signal.SIGKILL for row in rows))
            self.assertIsNotNone(process.returncode)

    def test_exited_leader_with_inherited_pipe_is_distinct_from_live_process(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'trace.jsonl'
            child = 'import time;time.sleep(.5)'
            leader = f'import subprocess,sys;subprocess.Popen([sys.executable,"-c",{child!r}])'
            with TRACE.trace_processes(path):
                process = subprocess.Popen([sys.executable, '-c', leader],
                    start_new_session=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                try:
                    with self.assertRaises(subprocess.TimeoutExpired):
                        process.communicate(timeout=.15)
                finally:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.communicate(timeout=2)
            rows = self.rows(path)
            timeout = [row for row in rows if row['event'] == 'communicate-timeout'][0]
            self.assertEqual(timeout['leader_state'], 'terminated')
            self.assertEqual(timeout['inherited_pipe'], 'possible')
            self.assertTrue(timeout['observer_poll_may_reap'])
            waits = [row for row in rows if row['event'] == 'communicate-start']
            self.assertEqual([row['timeout_seconds'] for row in waits], [.15, 2])
            self.assertIsNotNone(process.returncode)

    def test_trace_is_exclusive_and_restores_global_functions_after_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'trace.jsonl'
            original_popen, original_killpg = subprocess.Popen, os.killpg
            with self.assertRaisesRegex(RuntimeError, 'injected'):
                with TRACE.trace_processes(path):
                    raise RuntimeError('injected')
            self.assertIs(subprocess.Popen, original_popen)
            self.assertIs(os.killpg, original_killpg)
            with self.assertRaises(FileExistsError):
                with TRACE.trace_processes(path):
                    self.fail('existing trace cannot be overwritten')

    def test_output_metadata_never_exposes_invalid_or_partial_content(self):
        value = TRACE.output_metadata(b'SECRET_SENTINEL{')
        self.assertEqual(value['json'], 'invalid')
        self.assertEqual(value['bytes'], 16)
        self.assertNotIn('SECRET_SENTINEL', json.dumps(value))

    def test_ps_metadata_retains_only_owned_group_states_and_strict_shape(self):
        result = TRACE.owned_ps_metadata('111 Z\n111 ZN\n222 S\n333 R\n', {111, 222, 444})
        self.assertEqual(result, {'ps_shape': 'valid', 'owned_groups': [
            {'pgid': 111, 'states': ['Z', 'ZN'], 'state': 'zombie_only'},
            {'pgid': 222, 'states': ['S'], 'state': 'live'},
            {'pgid': 444, 'states': [], 'state': 'absent'}]})
        self.assertNotIn('333', json.dumps(result))
        self.assertEqual(TRACE.owned_ps_metadata('111 Z SECRET_SENTINEL', {111}),
                         {'ps_shape': 'invalid', 'owned_groups': []})


class PreflightLifecycleTest(unittest.TestCase):
    def exercise(self, directory, *, failure=None, cleanup=True, keep=False):
        owner = Mock(record=None, owns_receipt=False)
        owner.command.side_effect = lambda arguments, *_args, **_kwargs: (
            'a' * 40 if arguments[0] == 'git' else
            'usage: simctl --set <path>' if arguments[-1] == 'help' else
            'list devices [<search term>]' if arguments[-1] == 'list' else
            '{"devices":{}}')

        def prepare():
            owner.record, owner.owns_receipt = {'device': 'owned'}, True
            if failure is not None:
                raise failure
            return 'owned'

        owner.prepare.side_effect = prepare
        owner.cleanup.return_value = cleanup
        output = Path(directory) / 'output'
        arguments = ['--output', str(output)] + (['--keep-ready'] if keep else [])
        with patch.object(PREFLIGHT.IOS, 'IosOwnedRunner', return_value=owner):
            code = PREFLIGHT.main(arguments)
        return code, owner, json.loads((output / 'result.json').read_text())

    def test_preflight_pass_requires_terminal_cleanup(self):
        with tempfile.TemporaryDirectory() as directory:
            code, owner, result = self.exercise(directory)
            self.assertEqual(code, 0)
            self.assertEqual(result['preflight'], 'PASS')
            self.assertEqual(result['cleanup'], 'PASS')
            owner.cleanup.assert_called_once_with()
            self.assertTrue(result['cli']['device_set_option'])
            self.assertTrue(result['cli']['list_search_term'])

    def test_cleanup_failure_preserves_negative_result(self):
        with tempfile.TemporaryDirectory() as directory:
            code, _, result = self.exercise(directory, cleanup=False)
            self.assertEqual(code, 1)
            self.assertEqual(result['cleanup'], 'FAIL')

    def test_primary_timeout_kept_and_cleanup_not_skipped_by_keep_ready(self):
        with tempfile.TemporaryDirectory() as directory:
            code, owner, result = self.exercise(directory,
                failure=PREFLIGHT.IOS.Failure(124, 'timeout'), cleanup=False, keep=True)
            self.assertEqual(code, 124)
            self.assertEqual(result['preflight'], 'FAIL')
            self.assertEqual(result['cleanup'], 'FAIL')
            owner.cleanup.assert_called_once_with()

    def test_keep_ready_defers_cleanup_only_after_pass(self):
        with tempfile.TemporaryDirectory() as directory:
            code, owner, result = self.exercise(directory, keep=True)
            self.assertEqual(code, 0)
            self.assertEqual(result['cleanup'], 'NOT_RUN')
            self.assertEqual(result['cleanup_reason'], 'owned_workflow_finally_after_native_steps')
            owner.cleanup.assert_not_called()


if __name__ == '__main__':
    unittest.main()
