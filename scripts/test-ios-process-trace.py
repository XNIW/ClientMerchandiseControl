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
            'list devices [<search term>]' if arguments[0] == '/bin/sh' else
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

    def test_installed_cli_help_on_stderr_is_not_misclassified_as_unsupported(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fake = root / 'xcrun'
            fake.write_text('#!/bin/sh\n'
                'if [ "$2" = help ] && [ "$3" = list ]; then\n'
                '  printf "Usage: list devices [<search term>|available]\\n" >&2\n'
                'elif [ "$2" = help ]; then\n'
                '  printf "usage: simctl --set <path>\\n"\n'
                'else\n'
                '  printf \'{"devices":{}}\\n\'\n'
                'fi\n')
            fake.chmod(0o755)
            with patch.dict(os.environ, {'PATH': str(root) + os.pathsep + os.environ['PATH']}), \
                 patch.object(PREFLIGHT.IOS.IosOwnedRunner, 'prepare',
                    side_effect=PREFLIGHT.IOS.Failure(124, 'test stops before any device')):
                code = PREFLIGHT.main(['--output', str(root / 'result')])
            self.assertEqual(code, 124)
            result = json.loads((root / 'result/result.json').read_text())
            self.assertTrue(result['cli']['list_search_term'])


class ScopedInventoryTest(unittest.TestCase):
    device = '12345678-1234-1234-1234-123456789ABC'
    runtime = 'com.apple.CoreSimulator.SimRuntime.iOS-26-5'

    def owner(self):
        owner = PREFLIGHT.UuidInventoryOwner()
        owner.record = {'device': self.device, 'name': 'owned', 'runtime': self.runtime}
        return owner

    def test_scoped_inventory_retains_exact_ownership_state_and_budget(self):
        owner = self.owner()
        entry = {'udid': self.device, 'name': 'owned', 'state': 'Booted', 'isAvailable': True}
        with patch.object(PREFLIGHT.IOS.IosOwnedRunner, 'command',
                return_value=json.dumps({'devices': {self.runtime: [entry]}})) as command:
            self.assertTrue(owner.check_device(self.device, ready=True, owned=True))
        command.assert_called_once_with(['xcrun', 'simctl', 'list', 'devices', '--json',
            self.device], 30, capture=True)

    def test_empty_unproved_filter_cannot_authorize_boot_or_false_absence(self):
        owner = self.owner()
        owner.phase = 'prepare'
        with patch.object(PREFLIGHT.IOS.IosOwnedRunner, 'command',
                return_value=json.dumps({'devices': {}})), \
             self.assertRaises(PREFLIGHT.IOS.Failure):
            owner.check_device(self.device, owned=True)

    def test_scope_cannot_hide_foreign_entries_or_mismatched_identity(self):
        for change in ({'udid': 'foreign'}, {'name': 'foreign'}, {'state': 'Shutdown'},
                       {'isAvailable': False}):
            entry = {'udid': self.device, 'name': 'owned', 'state': 'Booted', 'isAvailable': True}
            entry.update(change)
            with self.subTest(change=change), patch.object(PREFLIGHT.IOS.IosOwnedRunner,
                    'command', return_value=json.dumps({'devices': {self.runtime: [entry]}})), \
                 self.assertRaises(PREFLIGHT.IOS.Failure):
                self.owner().check_device(self.device, ready=True, owned=True)

    def test_scope_keeps_duplicate_runtime_and_cleanup_absence_guards(self):
        entry = {'udid': self.device, 'name': 'owned', 'state': 'Booted', 'isAvailable': True}
        for payload in ({'devices': {self.runtime: [entry, entry]}},
                        {'devices': {'foreign-runtime': [entry]}}):
            with self.subTest(payload=payload), patch.object(PREFLIGHT.IOS.IosOwnedRunner,
                    'command', return_value=json.dumps(payload)), \
                 self.assertRaises(PREFLIGHT.IOS.Failure):
                self.owner().check_device(self.device, ready=True, owned=True)
        with patch.object(PREFLIGHT.IOS.IosOwnedRunner, 'command',
                return_value=json.dumps({'devices': {}})):
            owner = self.owner()
            owner.phase = 'cleanup'
            self.assertFalse(owner.check_device(self.device, owned=True))

    def test_cleanup_unproved_filter_uses_global_identity_readback(self):
        owner = self.owner()
        owner.phase = 'cleanup'
        entry = {'udid': self.device, 'name': 'owned', 'state': 'Shutdown', 'isAvailable': True}
        with patch.object(PREFLIGHT.IOS.IosOwnedRunner, 'command', side_effect=[
                json.dumps({'devices': {}}),
                json.dumps({'devices': {self.runtime: [entry]}})]) as command:
            self.assertTrue(owner.check_device(self.device, owned=True))
        self.assertEqual(command.call_args_list[-1].args,
                         (['xcrun', 'simctl', 'list', 'devices', '--json'], 30))

    def test_cleanup_proved_filter_does_not_require_global_inventory(self):
        owner = self.owner()
        owner.scoped_query_verified = True
        owner.phase = 'cleanup'
        with patch.object(PREFLIGHT.IOS.IosOwnedRunner, 'command',
                return_value=json.dumps({'devices': {}})) as command:
            self.assertFalse(owner.check_device(self.device, owned=True))
        command.assert_called_once_with(['xcrun', 'simctl', 'list', 'devices', '--json',
            self.device], 30, capture=True)


class DedicatedSetTest(unittest.TestCase):
    device = ScopedInventoryTest.device
    runtime = ScopedInventoryTest.runtime

    def test_set_operation_is_labeled_without_recording_private_path(self):
        self.assertEqual(TRACE.operation(['xcrun', 'simctl', '--set',
            '/PRIVATE_SENTINEL', 'list', 'devices', '--json']), 'simctl-list')

    def test_each_simctl_uses_the_same_private_identity_and_original_budget(self):
        with tempfile.TemporaryDirectory() as directory:
            owner = PREFLIGHT.DedicatedSetOwner(Path(directory) / 'owner.json')
            with patch.object(PREFLIGHT.IOS.IosOwnedRunner, 'command',
                    return_value='{"devices":{}}') as command:
                owner.command(['xcrun', 'simctl', 'list', 'devices', '--json'],
                              30, capture=True)
            command.assert_called_once_with(['xcrun', 'simctl', '--set',
                str(owner.device_set), 'list', 'devices', '--json'], 30, capture=True)
            self.assertEqual(owner.device_set.stat().st_mode & 0o777, 0o700)
            self.assertEqual((Path(directory) / 'device-set-owner.json').stat().st_mode &
                             0o777, 0o600)

    def test_replaced_or_public_set_cannot_authorize_any_command(self):
        for substitution in ('directory', 'symlink', 'mode'):
            with self.subTest(substitution=substitution), tempfile.TemporaryDirectory() as directory:
                owner = PREFLIGHT.DedicatedSetOwner(Path(directory) / 'owner.json')
                if substitution == 'mode':
                    owner.device_set.chmod(0o755)
                else:
                    original = owner.device_set.with_name('original')
                    owner.device_set.rename(original)
                    if substitution == 'directory':
                        owner.device_set.mkdir(mode=0o700)
                    else:
                        owner.device_set.symlink_to(original, target_is_directory=True)
                with patch.object(PREFLIGHT.IOS.IosOwnedRunner, 'command') as command, \
                     self.assertRaises(PREFLIGHT.IOS.Failure):
                    owner.command(['xcrun', 'simctl', 'boot', self.device], 60)
                command.assert_not_called()

    def test_initial_foreign_device_and_wrong_owned_identity_fail_closed(self):
        with tempfile.TemporaryDirectory() as directory:
            owner = PREFLIGHT.DedicatedSetOwner(Path(directory) / 'owner.json')
            entry = {'udid': self.device, 'name': 'foreign', 'state': 'Booted',
                     'isAvailable': True}
            payload = json.dumps({'devices': {self.runtime: [entry]}})
            with patch.object(PREFLIGHT.IOS.IosOwnedRunner, 'command', return_value=payload), \
                 self.assertRaises(PREFLIGHT.IOS.Failure):
                owner.command(['xcrun', 'simctl', 'list', 'devices', '--json'], 30, capture=True)
            owner.record = {'device': self.device, 'name': 'owned', 'runtime': self.runtime}
            with patch.object(PREFLIGHT.IOS.IosOwnedRunner, 'command', return_value=payload), \
                 self.assertRaises(PREFLIGHT.IOS.Failure):
                owner.check_device(self.device, ready=True, owned=True)

    def test_headless_recipe_and_cleanup_do_not_use_default_set_or_gui(self):
        with tempfile.TemporaryDirectory() as directory:
            owner = PREFLIGHT.DedicatedSetOwner(Path(directory) / 'owner.json')
            state = {'created': False, 'booted': False, 'deleted': False}
            calls = []

            def command(arguments, timeout, capture=False):
                calls.append((arguments, timeout, capture))
                self.assertEqual(arguments[:4], ['xcrun', 'simctl', '--set',
                                                str(owner.device_set)])
                action = arguments[4]
                if action == 'list' and arguments[5] == 'runtimes':
                    return json.dumps({'runtimes': [{'isAvailable': True, 'version': '26.5',
                                                    'identifier': self.runtime}]})
                if action == 'create':
                    state['created'] = True
                    return self.device
                if action == 'boot':
                    state['booted'] = True
                if action == 'delete':
                    state['deleted'] = True
                if action == 'list':
                    entries = [] if not state['created'] or state['deleted'] else [{
                        'udid': self.device, 'name': owner.record['name'], 'isAvailable': True,
                        'state': 'Booted' if state['booted'] else 'Shutdown'}]
                    return json.dumps({'devices': {self.runtime: entries}})
                return ''

            with patch.object(PREFLIGHT.IOS.IosOwnedRunner, 'command', side_effect=command):
                self.assertEqual(owner.prepare(), self.device)
                self.assertTrue(owner.cleanup())
            budgets = {arguments[4]: timeout for arguments, timeout, _ in calls}
            self.assertEqual(budgets, {'list': 30, 'create': 30, 'boot': 60,
                                      'bootstatus': 300, 'shutdown': 30, 'delete': 30})
            self.assertFalse(owner.device_set.exists())
            self.assertEqual(owner.set_cleanup, 'PASS')

    def test_failed_process_cleanup_preserves_private_set_and_negative_receipt(self):
        with tempfile.TemporaryDirectory() as directory:
            owner = PREFLIGHT.DedicatedSetOwner(Path(directory) / 'owner.json')
            owner.record = {'device': self.device}
            owner.owns_receipt = True
            with patch.object(PREFLIGHT.IOS.IosOwnedRunner, 'cleanup', return_value=False):
                self.assertFalse(owner.cleanup())
            self.assertTrue(owner.device_set.exists())
            self.assertEqual(owner.set_cleanup, 'BLOCKED')

    def test_process_failure_before_device_receipt_cannot_become_cleanup_pass(self):
        with tempfile.TemporaryDirectory() as directory:
            owner = PREFLIGHT.DedicatedSetOwner(Path(directory) / 'owner.json')
            owner.process_cleanup_failed = True
            with patch.object(PREFLIGHT.IOS.IosOwnedRunner, 'command',
                    return_value='{"devices":{}}') as command:
                self.assertFalse(owner.cleanup())
            command.assert_not_called()
            self.assertTrue(owner.device_set.exists())
            self.assertEqual(owner.set_cleanup, 'BLOCKED')

    def test_failed_attempted_empty_readback_is_fail_and_keeps_set(self):
        with tempfile.TemporaryDirectory() as directory:
            owner = PREFLIGHT.DedicatedSetOwner(Path(directory) / 'owner.json')
            with patch.object(PREFLIGHT.IOS.IosOwnedRunner, 'command',
                    side_effect=PREFLIGHT.IOS.Failure(124, 'timeout')), \
                 self.assertRaises(PREFLIGHT.IOS.Failure):
                owner.cleanup()
            self.assertTrue(owner.device_set.exists())
            self.assertEqual(owner.set_cleanup, 'FAIL')

    def test_set_cannot_be_exported_to_unverified_native_transport(self):
        with tempfile.TemporaryDirectory() as directory, self.assertRaises(SystemExit) as exit:
            PREFLIGHT.main(['--output', str(Path(directory) / 'output'),
                            '--inventory-scope', 'device-set', '--keep-ready'])
        self.assertEqual(exit.exception.code, 2)


if __name__ == '__main__':
    unittest.main()
