#!/usr/bin/env python3
"""Regressioni della misura: solo processi Python propri, nessun simulatore."""
import contextlib
import importlib.util
import io
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


class ReadinessObservationTest(unittest.TestCase):
    DEVICE = '12345678-1234-1234-1234-123456789ABC'
    CONTEXT = {'GITHUB_RUN_ID': '1', 'GITHUB_RUN_ATTEMPT': '1',
               'GITHUB_JOB': 'ios-build', 'GITHUB_SHA': 'a' * 40}

    def record(self):
        return dict(device=self.DEVICE, nonce='b' * 32, name='CMC-Task054-Owned-' + 'b' * 32,
                    readinessMethod='owned-descriptor-launchd',
                    deviceType='com.apple.CoreSimulator.SimDeviceType.iPhone-17',
                    runtime='com.apple.CoreSimulator.SimRuntime.iOS-26-5', creationStarted=True,
                    bootstatusCompleted=True, cleanup='NOT_RUN', ownerContext=self.CONTEXT)

    def observer(self):
        result = object.__new__(TRACE.ReadinessObservation)
        result.process = Mock(pid=123, returncode=None)
        result.device, result.timeout = self.DEVICE, 30
        result.stop = Mock(is_set=Mock(return_value=False), wait=Mock(return_value=False))
        result.emit = Mock()
        result.capture = Mock()
        result.failure = result.cleanup_error = None
        result.started = TRACE.datetime.datetime(2026, 10, 16, tzinfo=TRACE.datetime.timezone.utc)
        return result

    def test_ownership_is_exact_and_fails_closed_without_probe(self):
        args = ['xcrun', 'simctl', 'spawn', self.DEVICE, 'launchctl', 'list']
        with patch.dict(os.environ, self.CONTEXT):
            self.assertEqual(TRACE.readiness_owner(self.record(), args), self.DEVICE)
            for change in ({'device': 'not-uuid'}, {'bootstatusCompleted': False},
                           {'ownerContext': {}}, {'cleanup': 'PASS'}, {'nonce': 'private'},
                           {'processCleanupFailed': True}, {'creationStarted': False},
                           {'readinessMethod': 'inventory'}, {'name': 'foreign'}):
                with self.subTest(change=change):
                    record = self.record()
                    record.update(change)
                    self.assertIsNone(TRACE.readiness_owner(record, args))
            self.assertIsNone(TRACE.readiness_owner(self.record(), args[:-1] + ['getenv']))
            self.assertIsNone(TRACE.readiness_owner(self.record(), args + ['foreign']))

    def test_state_accepts_only_numeric_own_pid_parent_group_uid(self):
        observer = self.observer()
        good = f'123 {os.getpid()} 123 {os.geteuid()} S Fri Oct 16 00:00:00 2026\n'.encode()
        observer.capture.return_value = ({'status': 'PASS'}, good, b'')
        _, state = observer.state()
        self.assertEqual(state['pid'], 123)
        self.assertEqual(observer.capture.call_args.args[0][:4], ['/bin/ps', '-p', '123', '-o'])
        for bad in (good.replace(b'123 ', b'124 ', 1), b'123 1 123 501 S private-path',
                    good.replace(b' S ', b' SECRET_PATH '), good + b'124 foreign process'):
            observer.capture.return_value = ({'status': 'PASS'}, bad, b'')
            self.assertIsNone(observer.state()[1])

    def test_stack_drops_paths_binary_images_arguments_unknown_images_and_wrong_pid(self):
        raw = (b'Process: simctl [123]\nPath: /Users/SECRET_PATH/simctl\n'
               b'Command: SECRET_TOKEN\nCall graph:\n'
               b'    + 100 mach_msg2_trap (in libsystem_kernel.dylib) + 8 [0x123]\n'
               b'    ! 100 -[SimDevice spawn:] (in CoreSimulator) + 9\n'
               b'    ! 100 SECRET_TOKEN (in CustomerData) + 9\n'
               b'    ! 100 /Users/SECRET_PATH (in CoreSimulator) + 9\n'
               b'Binary Images:\n    /Users/SECRET_PATH\n')
        result = TRACE.ReadinessObservation.frames(raw, 123)
        self.assertTrue(result['qualified'])
        self.assertEqual(len(result['frames']), 2)
        self.assertNotIn('SECRET', json.dumps(result))
        self.assertFalse(TRACE.ReadinessObservation.frames(raw, 124)['qualified'])

    def test_core_logs_filter_uuid_subsystem_and_keep_only_safe_metadata(self):
        selected = {'eventMessage': self.DEVICE + ' spawn timeout /Users/SECRET_PATH TOKEN',
                    'subsystem': 'com.apple.CoreSimulator.SimDevice', 'category': 'SECRET_CATEGORY',
                    'processImagePath': '/Users/SECRET_PATH', 'messageType': 'Error',
                    'timestamp': '2026-10-16 00:00:01+0000'}
        foreign = dict(selected, eventMessage='FOREIGN uuid SECRET_TOKEN')
        wrong = dict(selected, subsystem='com.apple.CoreSimulatorMalicious')
        raw = b'\n'.join(json.dumps(value).encode() for value in (selected, foreign, wrong, []))
        result = TRACE.ReadinessObservation.logs(raw, self.DEVICE)
        self.assertEqual(len(result['rows']), 1)
        self.assertEqual(result['rejected'], 3)
        self.assertEqual(result['rows'][0]['tokens'], ['spawn', 'timeout'])
        self.assertNotIn('SECRET', json.dumps(result))
        self.assertLessEqual(len(TRACE.ReadinessObservation.logs(
            b'\n'.join(json.dumps(selected).encode() for _ in range(100)), self.DEVICE)['rows']), 64)

    def test_fast_return_or_short_budget_has_no_observing_command(self):
        for short in (True, False):
            observer = self.observer()
            observer.timeout = 23 if short else 30
            observer.stop.wait.return_value = True
            observer.run()
            observer.capture.assert_not_called()
            self.assertIsNone(observer.failure)

    def test_one_sample_and_uuid_filtered_window_with_unchanged_timeout(self):
        observer = self.observer()
        state = {'startIdentitySha256': 'c' * 64}
        observer.state = Mock(return_value=({'status': 'PASS'}, state))
        observer.capture.side_effect = [({'status': 'PASS'}, b'Process: simctl [123]\n', b''),
                                       ({'status': 'PASS'}, b'', b'')]
        observer.run()
        self.assertEqual(observer.timeout, 30)
        observer.stop.wait.assert_called_once_with(10)
        self.assertEqual(observer.state.call_count, 2)
        sample, logs = [call.args for call in observer.capture.call_args_list]
        self.assertEqual(sample, (['/usr/bin/sample', '123', '1', '10', '-file', '/dev/stdout'], 3))
        self.assertEqual(logs[0][:4], ['/usr/bin/log', 'show', '--style', 'ndjson'])
        self.assertIn(self.DEVICE, logs[0][5])
        self.assertIn('subsystem BEGINSWITH', logs[0][5])
        self.assertIn('--start', logs[0])
        self.assertIn('--end', logs[0])
        self.assertEqual(logs[1], 3)
        self.assertIsNone(observer.failure)

    def test_identity_change_discards_stack_and_stops_before_logs(self):
        observer = self.observer()
        observer.state = Mock(side_effect=[({'status': 'PASS'}, {'startIdentitySha256': 'a'}),
                                           ({'status': 'PASS'}, {'startIdentitySha256': 'b'})])
        observer.capture.return_value = ({'status': 'PASS'}, b'Process: simctl [123]\n', b'')
        observer.run()
        self.assertEqual(observer.capture.call_count, 1)
        stack = [c.kwargs for c in observer.emit.call_args_list if c.args[0] == 'readiness-owned-stack'][0]
        self.assertFalse(stack['identityStable'])
        self.assertFalse(stack['sample']['qualified'])

    def test_permission_refusal_has_no_retry_or_alternate_stack_tool(self):
        observer = self.observer()
        observer.state = Mock(return_value=({'status': 'PASS'}, {'startIdentitySha256': 'a'}))
        observer.capture.side_effect = [({'status': 'BLOCKED', 'permissionRefused': True}, b'', b''),
                                       ({'status': 'BLOCKED', 'permissionRefused': True}, b'', b'')]
        observer.run()
        self.assertEqual(observer.capture.call_count, 1)
        self.assertEqual([c.args[0][0] for c in observer.capture.call_args_list],
                         ['/usr/bin/sample'])
        self.assertFalse(any('sudo' in str(c) for c in observer.capture.call_args_list))

    def test_close_cancel_joins_and_unresolved_cleanup_is_an_error(self):
        observer = self.observer()
        observer.thread = Mock(is_alive=Mock(return_value=False))
        observer.close()
        observer.stop.set.assert_called_once_with()
        observer.thread.join.assert_called_once_with(timeout=2.5)
        observer.thread.is_alive.return_value = True
        with self.assertRaises(OSError):
            observer.close()
        observer.thread.is_alive.return_value = False
        observer.cleanup_error = OSError('synthetic cleanup')
        with self.assertRaises(OSError):
            observer.close()

    def test_capture_cap_terminates_only_own_group_and_reaps(self):
        observer = self.observer()
        # Restore the real bounded reader, while every OS/process call is mock.
        observer.capture = TRACE.ReadinessObservation.capture.__get__(observer)
        child = Mock(pid=321, returncode=0, stdout=Mock(), stderr=Mock(), poll=Mock(return_value=None))
        probe = Mock(pid=322, returncode=1, stdout=Mock())
        probe.communicate.return_value = (b'', None)
        observer.popen = Mock(side_effect=[child, probe])
        selector = Mock()
        selector.get_map.return_value = {1: 'present'}
        selector.select.return_value = [(Mock(fileobj=child.stdout, data=bytearray()), None)]
        with patch.object(TRACE.selectors, 'DefaultSelector') as factory, \
             patch.object(TRACE.os, 'read', return_value=b'x' * (observer.CAP + 1)), \
             patch.object(TRACE.os, 'killpg') as kill:
            factory.return_value.__enter__.return_value = selector
            meta, output, errors = observer.capture(['/usr/bin/sample', '123'], 3)
        self.assertEqual(meta['reason'], 'byteCap')
        self.assertLessEqual(len(output) + len(errors), observer.CAP)
        self.assertEqual([call.args[0] for call in kill.call_args_list], [321, 321])
        self.assertEqual([call.kwargs['timeout'] for call in child.wait.call_args_list], [.25, .5])
        self.assertEqual(observer.popen.call_args_list[1].args[0],
                         ['/bin/ps', '-g', '321', '-o', 'pgid=,stat='])
        self.assertTrue(child.stdout.close.called)
        self.assertTrue(child.stderr.close.called)

    def test_capture_recognizes_sample_permission_phrase_without_exposing_it(self):
        observer = self.observer()
        observer.capture = TRACE.ReadinessObservation.capture.__get__(observer)
        child = Mock(pid=321, returncode=1, stdout=Mock(), stderr=Mock())
        probe = Mock(pid=322, returncode=1, stdout=Mock(), stderr=Mock())
        probe.communicate.return_value = (b'', b'')
        observer.popen = Mock(side_effect=[child, probe])
        output = bytearray()
        key = Mock(fileobj=child.stdout, data=output)
        selector = Mock()
        selector.get_map.side_effect = [{1: key}, {1: key}, {}]
        selector.register.side_effect = lambda file, _events, data: (
            setattr(key, 'data', data) if file is child.stdout else None)
        selector.select.return_value = [(key, None)]
        phrase = b'You do not have permission to sample process 123'
        with patch.object(TRACE.selectors, 'DefaultSelector') as factory, \
             patch.object(TRACE.os, 'read', side_effect=[phrase, b'']), \
             patch.object(TRACE.os, 'killpg'):
            factory.return_value.__enter__.return_value = selector
            meta, _, _ = observer.capture(['/usr/bin/sample', '123'], 3)
        self.assertEqual(meta['status'], 'BLOCKED')
        self.assertTrue(meta['permissionRefused'])
        self.assertNotIn('permission to sample', json.dumps(meta))

    def test_capture_cancel_before_spawn_never_starts_a_process(self):
        observer = self.observer()
        observer.capture = TRACE.ReadinessObservation.capture.__get__(observer)
        observer.stop.is_set.return_value = True
        observer.popen = Mock()
        meta, _, _ = observer.capture(['/usr/bin/sample', '123'], 3)
        self.assertEqual(meta['reason'], 'gateCompleted')
        observer.popen.assert_not_called()

    def test_cli_rejects_opt_in_outside_descriptor_before_any_command(self):
        with patch.object(PREFLIGHT.IOS.subprocess, 'Popen') as popen, \
             patch('sys.stderr'):
            with self.assertRaises(SystemExit) as raised:
                PREFLIGHT.IOS.main(['prepare', '--receipt', '/unused', '--observe-readiness'])
            self.assertEqual(raised.exception.code, 2)
            popen.assert_not_called()

    def test_cli_opt_in_uses_same_prepare_and_restores_trace_after_failure(self):
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, self.CONTEXT):
            receipt = Path(directory) / 'owned.json'
            owner = Mock(record=None, owns_receipt=False)
            owner.prepare.side_effect = PREFLIGHT.IOS.Failure(124, 'synthetic gate timeout')
            original = subprocess.Popen
            with patch.object(PREFLIGHT.IOS, 'IosOwnedRunner', return_value=owner):
                self.assertEqual(PREFLIGHT.IOS.main(['prepare', '--receipt', str(receipt),
                    '--readiness-attestation', 'owned-descriptor-launchd', '--observe-readiness']), 124)
            owner.prepare.assert_called_once_with(headless=False,
                readiness_attestation='owned-descriptor-launchd', observe_descriptor=False)
            self.assertIs(subprocess.Popen, original)
            self.assertTrue(receipt.with_suffix('.readiness.jsonl').is_file())

    def test_owner_timeout_primary_124_survives_observer_cleanup_failure_durably(self):
        with tempfile.TemporaryDirectory() as directory:
            owner = PREFLIGHT.IOS.IosOwnedRunner(Path(directory) / 'owned.json')
            owner.record = self.record()
            owner.persist(exclusive=True)
            with patch.object(TRACE, 'readiness_owner', return_value=self.DEVICE), \
                 patch.object(TRACE, 'ReadinessObservation', autospec=True) as observation, \
                 patch.object(PREFLIGHT.IOS, 'group_has_live_members', return_value=False):
                observation.return_value.close.side_effect = OSError('synthetic observer reap')
                with TRACE.trace_processes(Path(directory) / 'trace.jsonl',
                        readiness_record=lambda: owner.record,
                        readiness_cleanup_failed=lambda: setattr(owner, 'process_cleanup_failed', True)):
                    with self.assertRaises(PREFLIGHT.IOS.Failure) as raised:
                        owner.command([sys.executable, '-c', 'import time; time.sleep(1)'], .01, capture=True)
                self.assertEqual(raised.exception.code, 124)
                # Il processo Python fixture e reaped; chiudere la PIPE che
                # communicate ha lasciato aperta al timeout prima del testend.
                observed_process = observation.call_args.args[0]
                if observed_process.stdout is not None:
                    observed_process.stdout.close()
                self.assertTrue(owner.process_cleanup_failed)
                with patch.object(owner, 'cleanup_device', return_value='PASS'):
                    self.assertFalse(owner.cleanup())
            receipt = json.loads(owner.receipt.read_text())
            self.assertTrue(receipt['processCleanupFailed'])
            self.assertEqual(receipt['cleanup'], 'FAIL')
            self.assertEqual(receipt['cleanupAttempts'][-1]['resourceCleanup'], 'PASS')
            rows = [json.loads(line) for line in (Path(directory) / 'trace.jsonl').read_text().splitlines()]
            failed = [row for row in rows if row['event'] == 'readiness-observation-cleanup']
            self.assertEqual(len(failed), 1)
            self.assertEqual(failed[0]['status'], 'FAIL')
            self.assertTrue(failed[0]['primary_preserved'])

    def test_owner_success_cannot_hide_observer_cleanup_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            owner = PREFLIGHT.IOS.IosOwnedRunner()
            with patch.object(TRACE, 'readiness_owner', return_value=self.DEVICE), \
                 patch.object(TRACE, 'ReadinessObservation', autospec=True) as observation, \
                 patch.object(PREFLIGHT.IOS, 'group_has_live_members', return_value=False):
                observation.return_value.close.side_effect = OSError('synthetic observer reap')
                with TRACE.trace_processes(Path(directory) / 'trace.jsonl',
                        readiness_record=lambda: self.record(),
                        readiness_cleanup_failed=lambda: setattr(owner, 'process_cleanup_failed', True)):
                    with self.assertRaises(OSError):
                        owner.command([sys.executable, '-c', 'pass'], 1, capture=True)
                self.assertTrue(owner.process_cleanup_failed)

    def test_capture_eof_before_exit_allows_natural_exit_before_group_teardown(self):
        observer = self.observer()
        observer.capture = TRACE.ReadinessObservation.capture.__get__(observer)
        child = Mock(pid=321, returncode=None, stdout=Mock(), stderr=Mock())
        probe = Mock(pid=322, returncode=1, stdout=Mock(), stderr=Mock())
        probe.communicate.return_value = (b'', b'')
        observer.popen = Mock(side_effect=[child, probe])
        order = []

        def wait(**_kwargs):
            order.append('wait')
            child.returncode = 0
            return 0

        def kill(group, signum):
            order.append(('kill', group, signum))
            if child.returncode is None:
                child.returncode = -signum

        child.wait.side_effect = wait
        child.poll.side_effect = lambda: child.returncode
        selector = Mock(get_map=Mock(return_value={}))
        with patch.object(TRACE.selectors, 'DefaultSelector') as factory, \
             patch.object(TRACE.os, 'killpg', side_effect=kill):
            factory.return_value.__enter__.return_value = selector
            meta, _, _ = observer.capture(['/usr/bin/sample', '123'], 3)
        self.assertEqual(meta['status'], 'PASS')
        self.assertEqual(meta['exitCode'], 0)
        self.assertEqual(order[0], 'wait')
        self.assertNotIn(('kill', 321, signal.SIGTERM), order)
        # Il gruppo dei discendenti rimane terminato e verificato, anche su0.
        self.assertIn(('kill', 321, signal.SIGKILL), order)
        self.assertEqual(observer.popen.call_args_list[1].args[0],
                         ['/bin/ps', '-g', '321', '-o', 'pgid=,stat='])

    def test_every_nonpass_sample_stops_without_afterstate_logs_or_retry(self):
        for detail in ({'permissionRefused': True}, {'permissionRefused': False},
                       {'reason': 'byteCap'}, {'reason': 'observerBudget'}):
            observer = self.observer()
            observer.state = Mock(return_value=({'status': 'PASS'}, {'startIdentitySha256': 'a'}))
            observer.capture.return_value = (dict(status='BLOCKED', **detail),
                b'You do not have permission to sample process 123', b'')
            observer.run()
            observer.state.assert_called_once_with()
            observer.capture.assert_called_once()
            self.assertFalse(any(c.args[0] == 'readiness-owned-coresimulator'
                                 for c in observer.emit.call_args_list))

    def trace_write_fault(self, *, prepare_code, owned=True,
                          trace_flags=('--observe-readiness',), fault_index=0):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        receipt = Path(directory.name) / 'owned.json'
        owner = PREFLIGHT.IOS.IosOwnedRunner(receipt)
        real_fdopen, trace_fds = os.fdopen, []
        fdopen_count = 0

        @contextlib.contextmanager
        def fdopen(fd, *args, **kwargs):
            nonlocal fdopen_count
            index, fdopen_count = fdopen_count, fdopen_count + 1
            with real_fdopen(fd, *args, **kwargs) as stream:
                if index == fault_index:
                    trace_fds.append(fd)
                    yield Mock(write=Mock(side_effect=OSError('SECRET_TRACE_PAYLOAD')))
                else:
                    yield stream

        def prepare(**_kwargs):
            if owned:
                owner.record = self.record()
                owner.persist(exclusive=True)
            if prepare_code:
                raise PREFLIGHT.IOS.Failure(prepare_code, 'synthetic prepare failure')
            return self.DEVICE

        output = io.StringIO()
        with patch.object(PREFLIGHT.IOS, 'IosOwnedRunner', return_value=owner), \
             patch.object(owner, 'prepare', side_effect=prepare) as prepared, \
             patch.object(owner, 'cleanup_device', return_value='PASS') as cleanup, \
             patch.object(os, 'fdopen', side_effect=fdopen), patch('sys.stdout', output):
            code = PREFLIGHT.IOS.main(['prepare', '--receipt', str(receipt),
                '--readiness-attestation', 'owned-descriptor-launchd', *trace_flags])
        self.assertEqual(prepared.call_count, 1)
        self.assertEqual(len(trace_fds), 1)
        with self.assertRaises(OSError):
            os.fstat(trace_fds[0])
        self.assertNotIn('SECRET_TRACE_PAYLOAD', output.getvalue())
        return code, owner, cleanup, output.getvalue()

    def test_cli_trace_exit_write_failure_keeps_primary_124_owned_or_unowned(self):
        for owned in (False, True):
            with self.subTest(owned=owned):
                code, owner, cleanup, output = self.trace_write_fault(prepare_code=124, owned=owned)
                self.assertEqual(code, 124)
                self.assertIn('FAIL: evidence trace (OSError)', output)
                self.assertEqual(cleanup.call_count, 1 if owned else 0)
                if owned:
                    receipt = json.loads(owner.receipt.read_text())
                    self.assertEqual(receipt['cleanup'], 'PASS')
                    self.assertEqual(receipt['readinessTraceEvidence'], {
                        'result': 'FAIL', 'errorType': 'OSError', 'phase': 'exit'})

    def test_cli_trace_exit_failure_after_prepare_pass_fails_and_cleans_owned(self):
        code, owner, cleanup, output = self.trace_write_fault(prepare_code=0)
        self.assertNotEqual(code, 0)
        cleanup.assert_called_once_with()
        receipt = json.loads(owner.receipt.read_text())
        self.assertEqual(receipt['cleanup'], 'PASS')
        self.assertEqual(receipt['readinessTraceEvidence']['result'], 'FAIL')
        self.assertEqual(receipt['readinessTraceEvidence']['phase'], 'exit')
        self.assertIn('FAIL: evidence trace (OSError)', output)

    def test_cli_trace_enter_failure_never_prepares_or_cleans_unowned(self):
        with tempfile.TemporaryDirectory() as directory:
            receipt = Path(directory) / 'owned.json'
            occupied = receipt.with_suffix('.readiness.jsonl')
            occupied.write_text('retained trace')
            owner = PREFLIGHT.IOS.IosOwnedRunner(receipt)
            original_popen = subprocess.Popen
            with patch.object(PREFLIGHT.IOS, 'IosOwnedRunner', return_value=owner), \
                 patch.object(owner, 'prepare') as prepared, \
                 patch.object(owner, 'cleanup') as cleanup, patch('sys.stdout'):
                code = PREFLIGHT.IOS.main(['prepare', '--receipt', str(receipt),
                    '--readiness-attestation', 'owned-descriptor-launchd', '--observe-readiness'])
            self.assertNotEqual(code, 0)
            prepared.assert_not_called()
            cleanup.assert_not_called()
            self.assertIs(subprocess.Popen, original_popen)
            self.assertEqual(occupied.read_text(), 'retained trace')
            self.assertFalse(receipt.exists())

    def test_opt_in_never_changes_call_timeout_and_observer_is_one_shot(self):
        owner = self.record()
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, self.CONTEXT), \
             patch.object(TRACE, 'ReadinessObservation', autospec=True) as observation:
            # Pure Python child; argv/context are synthetic, no simctl execution.
            with patch.object(TRACE, 'readiness_owner', return_value=self.DEVICE), \
                 TRACE.trace_processes(Path(directory) / 'trace.jsonl', readiness_record=lambda: owner):
                for _ in range(2):
                    child = subprocess.Popen([sys.executable, '-c', 'pass'], start_new_session=True)
                    child.communicate(timeout=1)
            observation.assert_called_once()
            self.assertEqual(observation.call_args.args[2], 1)
            observation.return_value.close.assert_called_once_with()
            rows = [json.loads(line) for line in (Path(directory) / 'trace.jsonl').read_text().splitlines()]
            self.assertTrue(all(row['timeout_seconds'] == 1 for row in rows
                                if row['event'] == 'communicate-start'))


class BootstatusObservationTest(unittest.TestCase):
    DEVICE = ReadinessObservationTest.DEVICE
    CONTEXT = ReadinessObservationTest.CONTEXT

    def record(self):
        record = ReadinessObservationTest.record(self)
        record.pop('bootstatusCompleted')
        record['runtimeVersion'] = '26.5'
        proof = {key: record[key] for key in (
            'device', 'name', 'nonce', 'runtime', 'deviceType', 'ownerContext')}
        proof.update(kind='owned-created-boot-command.v1', createExitCode=0,
                     inventoryIdentityMatched=True, bootCommandExitCode=0)
        record['bootstatusObservationOwnership'] = proof
        return record

    def observer(self):
        result = ReadinessObservationTest.observer(self)
        result.__class__ = TRACE.BootstatusObservation
        result.authorize = Mock(return_value=True)
        return result

    # Stesse primitive V3, con la nuova classe e autorizzazione bootstrap.
    test_byte_cap = ReadinessObservationTest.test_capture_cap_terminates_only_own_group_and_reaps
    test_eof = ReadinessObservationTest.test_capture_eof_before_exit_allows_natural_exit_before_group_teardown
    test_refusal = ReadinessObservationTest.test_every_nonpass_sample_stops_without_afterstate_logs_or_retry
    test_cleanup = ReadinessObservationTest.test_close_cancel_joins_and_unresolved_cleanup_is_an_error
    test_fast_return = ReadinessObservationTest.test_fast_return_or_short_budget_has_no_observing_command

    def test_boot_owner_requires_new_created_proof_and_current_context_before_any_probe(self):
        args = ['xcrun', 'simctl', 'bootstatus', self.DEVICE, '-b']
        with patch.dict(os.environ, self.CONTEXT):
            self.assertEqual(TRACE.bootstatus_owner(self.record(), args), self.DEVICE)
            for change in ({'creationStarted': False}, {'bootstatusCompleted': True},
                    {'ready': True}, {'ready': 0}, {'bootstatusCompleted': 0}, {'device': 'invalid'}, {'ownerContext': {}},
                    {'name': 'foreign'}, {'nonce': 'bad'}, {'cleanup': 'PASS'},
                    {'runtimeVersion': '26.6'}, {'runtime': 'foreign'},
                    {'deviceType': 'foreign'}, {'processCleanupFailed': True},
                    {'bootstatusObservationOwnership': {}},
                    {'bootstatusObservationOwnership': {'device': 'foreign'}}):
                with self.subTest(change=change):
                    record = self.record()
                    record.update(change)
                    self.assertIsNone(TRACE.bootstatus_owner(record, args))
            self.assertIsNone(TRACE.bootstatus_owner(self.record(), args[:-1]))
            self.assertIsNone(TRACE.bootstatus_owner(self.record(), args[:3] + ['foreign', '-b']))
            self.assertNotIn('bootstatusCompleted', self.record())

    def test_boot_guard_rechecked_before_each_probe_and_refuses_without_spawning(self):
        observer = self.observer()
        observer.capture = TRACE.BootstatusObservation.capture.__get__(observer)
        observer.authorize.side_effect = [True, False]
        with patch.object(TRACE.ReadinessObservation, 'capture', return_value=({'status': 'PASS'}, b'', b'')) as capture:
            self.assertEqual(observer.capture(['/bin/ps', '-p', '123'], 1)[0]['status'], 'PASS')
            self.assertEqual(observer.capture(['/usr/bin/sample', '123'], 3)[0]['reason'], 'ownershipChanged')
        capture.assert_called_once()
        self.assertEqual(observer.authorize.call_count, 2)

    def test_trigger_is_during_pending_300_not_after_timeout_or_completed_boot(self):
        observer = self.observer()
        observer.timeout = 300
        record = self.record()
        active = []

        def trigger(seconds):
            self.assertEqual(seconds, 100)
            self.assertIsNone(observer.process.returncode)
            self.assertFalse(observer.stop.is_set())
            self.assertNotIn('bootstatusCompleted', record)
            active.append('during-pending')
            return False

        observer.stop.wait.side_effect = trigger
        observer.state = Mock(return_value=({'status': 'PASS'}, {'startIdentitySha256': 'a'}))
        observer.capture.side_effect = [({'status': 'PASS'}, b'Process: simctl [123]\n', b''),
                                       ({'status': 'PASS'}, b'', b'')]
        observer.run()
        self.assertEqual(active, ['during-pending'])
        self.assertEqual(observer.timeout, 300)
        self.assertEqual(observer.capture.call_count, 2)
        self.assertNotIn('bootstatusCompleted', record)

    def test_dual_profiles_have_separate_jsonl_and_one_observer_each_no_nested_patch(self):
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, self.CONTEXT):
            ready, boot = Path(directory) / 'ready.jsonl', Path(directory) / 'boot.jsonl'
            def for_boot(record, args):
                return self.DEVICE if args[-1] == 'pass # boot' else None
            def for_ready(record, args):
                return self.DEVICE if args[-1] == 'pass # ready' else None
            with patch.object(TRACE, 'bootstatus_owner', side_effect=for_boot), \
                 patch.object(TRACE, 'readiness_owner', side_effect=for_ready), \
                 patch.object(TRACE, 'BootstatusObservation', autospec=True) as boot_observer, \
                 patch.object(TRACE, 'ReadinessObservation', autospec=True) as ready_observer:
                def observed(*args, **_kwargs):
                    args[3]('readiness-owned-stack', synthetic=True)
                    return Mock()
                boot_observer.side_effect = ready_observer.side_effect = observed
                with TRACE.trace_processes(ready, readiness_record=self.record,
                        bootstatus_record=self.record, bootstatus_destination=boot):
                    wrapper = subprocess.Popen
                    for kind, timeout in [('boot', 300), ('ready', 30), ('boot', 300), ('ready', 30)]:
                        child = subprocess.Popen([sys.executable, '-c', 'pass # ' + kind], start_new_session=True)
                        child.communicate(timeout=timeout)
                        self.assertIs(subprocess.Popen, wrapper)
                boot_observer.assert_called_once()
                ready_observer.assert_called_once()
                self.assertEqual(boot_observer.call_args.args[2], 300)
                self.assertEqual(ready_observer.call_args.args[2], 30)
            ready_rows = [json.loads(line) for line in ready.read_text().splitlines()]
            boot_rows = [json.loads(line) for line in boot.read_text().splitlines()]
            self.assertTrue(any(row['event'] == 'readiness-owned-stack' for row in ready_rows))
            self.assertTrue(any(row['event'] == 'bootstatus-owned-stack' for row in boot_rows))
            self.assertFalse(any(row['event'].startswith('bootstatus-') for row in ready_rows))
            self.assertFalse(any(row['event'].startswith('readiness-') for row in boot_rows))
            ready_pids = {row['pid'] for row in ready_rows if row['event'] == 'spawn-end'}
            boot_pids = {row['pid'] for row in boot_rows if row['event'] == 'spawn-end'}
            self.assertFalse(ready_pids & boot_pids)
            for rows in (ready_rows, boot_rows):
                self.assertEqual([row['sequence'] for row in rows], list(range(1, len(rows) + 1)))
            self.assertEqual(ready.stat().st_mode & 0o777, 0o600)
            self.assertEqual(boot.stat().st_mode & 0o777, 0o600)

    def test_boot_timeout300_preserved_as_124_when_observer_cleanup_fails(self):
        class Process:
            pid = 99001
            returncode = None
            stdout = stderr = None
            def __init__(self, *_args, **_kwargs):
                pass
            def communicate(self, *_args, **kwargs):
                raise subprocess.TimeoutExpired('owned synthetic bootstatus', kwargs['timeout'])
            def poll(self):
                return None
        with tempfile.TemporaryDirectory() as directory:
            owner = PREFLIGHT.IOS.IosOwnedRunner()
            with patch.object(TRACE.subprocess, 'Popen', Process), \
                 patch.object(TRACE.os, 'getpgid', return_value=99001), \
                 patch.object(TRACE, 'bootstatus_owner', return_value=self.DEVICE), \
                 patch.object(TRACE, 'BootstatusObservation', autospec=True) as observer, \
                 patch.object(PREFLIGHT.IOS, 'stop_owned_process'):
                observer.return_value.close.side_effect = OSError('synthetic observer cleanup')
                with TRACE.trace_processes(Path(directory) / 'boot.jsonl', bootstatus_record=self.record,
                        readiness_cleanup_failed=lambda: setattr(owner, 'process_cleanup_failed', True)):
                    with self.assertRaises(PREFLIGHT.IOS.Failure) as raised:
                        owner.command(['synthetic-bootstatus'], 300)
                self.assertEqual(raised.exception.code, 124)
                self.assertTrue(owner.process_cleanup_failed)
                observer.assert_called_once()
                self.assertEqual(observer.call_args.args[2], 300)
            rows = [json.loads(line) for line in (Path(directory) / 'boot.jsonl').read_text().splitlines()]
            timeout = next(row for row in rows if row['event'] == 'communicate-timeout')
            self.assertEqual(timeout['timeout_seconds'], 300)
            failure = next(row for row in rows if row['event'] == 'bootstatus-observation-cleanup')
            self.assertEqual(failure['status'], 'FAIL')
            self.assertTrue(failure['primary_preserved'])

    def test_boot_config_rejects_missing_secondary_or_same_trace_before_open(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'trace'
            for options in ({'readiness_record': self.record, 'bootstatus_record': self.record},
                            {'bootstatus_record': self.record, 'bootstatus_destination': path},
                            {'bootstatus_destination': path.with_suffix('.other')}):
                with self.subTest(options=options), self.assertRaises(ValueError):
                    with TRACE.trace_processes(path, **options):
                        self.fail('invalid config cannot enter')
                self.assertFalse(path.exists())

    def test_boot_cli_rejects_non_descriptor_before_prepare(self):
        with patch.object(PREFLIGHT.IOS.IosOwnedRunner, 'prepare') as prepare, patch('sys.stderr'):
            with self.assertRaises(SystemExit) as error:
                PREFLIGHT.IOS.main(['prepare', '--receipt', '/unused', '--observe-bootstatus'])
            self.assertEqual(error.exception.code, 2)
            prepare.assert_not_called()

    def test_cli_proof_is_durable_before_pending_boot_and_sdk_sequence_is_unchanged(self):
        spec = importlib.util.spec_from_file_location('boot_owner_fixture',
            Path(__file__).with_name('test-task054-ios-owned.py'))
        fixtures = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(fixtures)
        sequences = []
        for observed in (False, True):
            with tempfile.TemporaryDirectory() as directory:
                fixture = fixtures.Fixture(directory)
                seen = []

                def command(runner, arguments, timeout, capture=False):
                    if arguments[:3] == ['xcrun', 'simctl', 'bootstatus']:
                        fixture.calls.append((arguments, timeout))
                        record = json.loads(fixture.path.read_text())
                        self.assertNotIn('bootstatusCompleted', record)
                        if observed:
                            self.assertEqual(TRACE.bootstatus_owner(record, arguments), fixtures.DEVICE)
                            self.assertTrue(record['bootstatusObservationOwnership']['inventoryIdentityMatched'])
                        else:
                            self.assertNotIn('bootstatusObservationOwnership', record)
                        self.assertEqual(timeout, 300)
                        seen.append('pending owned bootstatus')
                        raise PREFLIGHT.IOS.Failure(124, 'synthetic bootstatus300 timeout')
                    return fixture.command(runner, arguments, timeout, capture)

                args = ['prepare', '--receipt', str(fixture.path),
                        '--readiness-attestation', 'owned-descriptor-launchd']
                if observed:
                    args += ['--observe-readiness', '--observe-bootstatus']
                with patch.object(PREFLIGHT.IOS.IosOwnedRunner, 'command', command), \
                     patch.object(PREFLIGHT.IOS.Path, 'is_dir', return_value=True), \
                     patch.object(PREFLIGHT.IOS.signal, 'signal'), \
                     patch.object(PREFLIGHT.IOS.uuid, 'uuid4', return_value=Mock(hex='b' * 32)), \
                     patch.dict(os.environ, self.CONTEXT):
                    code = PREFLIGHT.IOS.main(args)
                self.assertEqual(code, 124)
                self.assertEqual(seen, ['pending owned bootstatus'])
                saved = json.loads(fixture.path.read_text())
                self.assertEqual(saved['cleanup'], 'PASS')
                self.assertFalse(saved['processCleanupFailed'])
                self.assertNotIn('bootstatusCompleted', saved)
                sequences.append(fixture.calls)
        self.assertEqual(sequences[0], sequences[1])

    def test_missing_created_uuid_inventory_never_claims_match_or_authorizes_observer(self):
        spec = importlib.util.spec_from_file_location('boot_missing_owner_fixture',
            Path(__file__).with_name('test-task054-ios-owned.py'))
        fixtures = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(fixtures)
        sequences, observed_record = [], None
        for observed in (False, True):
            with tempfile.TemporaryDirectory() as directory:
                fixture = fixtures.Fixture(directory)
                before_bootstatus = []
                checked = []
                real_check = PREFLIGHT.IOS.IosOwnedRunner.check_device

                def check(runner, *args, **kwargs):
                    result = real_check(runner, *args, **kwargs)
                    if kwargs.get('owned') and not kwargs.get('ready'):
                        checked.append(result)
                    return result

                def command(runner, arguments, timeout, capture=False):
                    if arguments[:4] == ['xcrun', 'simctl', 'list', 'devices']:
                        fixture.calls.append((arguments, timeout))
                        return json.dumps({'devices': {fixtures.RUNTIME: []}})
                    if arguments[:3] == ['xcrun', 'simctl', 'bootstatus']:
                        fixture.calls.append((arguments, timeout))
                        before_bootstatus.append(json.loads(fixture.path.read_text()))
                        raise PREFLIGHT.IOS.Failure(124, 'synthetic bootstatus300 timeout')
                    return fixture.command(runner, arguments, timeout, capture)

                args = ['prepare', '--receipt', str(fixture.path),
                        '--readiness-attestation', 'owned-descriptor-launchd']
                if observed:
                    args += ['--observe-readiness', '--observe-bootstatus']
                with patch.object(PREFLIGHT.IOS.IosOwnedRunner, 'command', command), \
                     patch.object(PREFLIGHT.IOS.IosOwnedRunner, 'check_device', check), \
                     patch.object(PREFLIGHT.IOS.Path, 'is_dir', return_value=True), \
                     patch.object(PREFLIGHT.IOS.signal, 'signal'), \
                     patch.object(PREFLIGHT.IOS.uuid, 'uuid4', return_value=Mock(hex='b' * 32)), \
                     patch.dict(os.environ, self.CONTEXT):
                    code = PREFLIGHT.IOS.main(args)
                    self.assertEqual(code, 124)
                    self.assertTrue(checked)
                    self.assertIs(checked[0], False)  # helper reale, non ritorno mock
                    self.assertEqual(len(before_bootstatus), 1)
                    if observed:
                        observed_record = before_bootstatus[0]
                        self.assertIsNone(TRACE.bootstatus_owner(observed_record,
                            ['xcrun', 'simctl', 'bootstatus', fixtures.DEVICE, '-b']))
                saved = json.loads(fixture.path.read_text())
                self.assertNotIn('bootstatusCompleted', saved)
                self.assertEqual(saved['cleanup'], 'PASS')
                sequences.append(fixture.calls)
        self.assertEqual(sequences[0], sequences[1])
        self.assertNotIn('bootstatusObservationOwnership', observed_record)
        self.assertEqual(observed_record['bootstatusObservation'], {
            'result': 'NOT_RUN', 'reason': 'createdIdentityNotMatched'})

    def test_boot_second_sink_write_fault_preserves_primary_and_failure_scope(self):
        code, owner, cleanup, _ = ReadinessObservationTest.trace_write_fault(self,
            prepare_code=124, trace_flags=('--observe-readiness', '--observe-bootstatus'), fault_index=1)
        self.assertEqual(code, 124)
        cleanup.assert_called_once_with()
        receipt = json.loads(owner.receipt.read_text())
        self.assertEqual(receipt['bootstatusTraceEvidence']['result'], 'FAIL')
        self.assertNotIn('readinessTraceEvidence', receipt)

    def test_trace_fdopen_failure_closes_real_untransferred_fd(self):
        with tempfile.TemporaryDirectory() as directory:
            original_open = os.open
            descriptors = []
            def opened(*args, **kwargs):
                fd = original_open(*args, **kwargs)
                descriptors.append(fd)
                return fd
            with patch.object(TRACE.os, 'open', side_effect=opened), \
                 patch.object(TRACE.os, 'fdopen', side_effect=OSError('synthetic enter')):
                with self.assertRaises(OSError):
                    with TRACE.trace_processes(Path(directory) / 'boot.jsonl', bootstatus_record=self.record):
                        self.fail('enter cannot finish')
            self.assertEqual(len(descriptors), 1)
            with self.assertRaises(OSError):
                os.fstat(descriptors[0])

    def test_boot_second_trace_enter_failure_never_prepares_and_closes_first_fd(self):
        with tempfile.TemporaryDirectory() as directory:
            receipt = Path(directory) / 'owned.json'
            occupied = receipt.with_suffix('.bootstatus.jsonl')
            occupied.write_text('preserve boot evidence')
            with patch.object(PREFLIGHT.IOS.IosOwnedRunner, 'prepare') as prepare, patch('sys.stdout'):
                code = PREFLIGHT.IOS.main(['prepare', '--receipt', str(receipt),
                    '--readiness-attestation', 'owned-descriptor-launchd',
                    '--observe-readiness', '--observe-bootstatus'])
            self.assertNotEqual(code, 0)
            prepare.assert_not_called()
            self.assertEqual(occupied.read_text(), 'preserve boot evidence')
            self.assertFalse(receipt.exists())

class PreflightLifecycleTest(unittest.TestCase):
    def exercise(self, directory, *, failure=None, cleanup=True, keep=False,
                 developer="/Applications/Xcode_26.5.app/Contents/Developer",
                 present=True, version="Xcode 26.5\nBuild version TEST", sdk="26.5",
                 runtime="com.apple.CoreSimulator.SimRuntime.iOS-26-5"):
        owner = Mock(record=None, owns_receipt=False)
        owner.command.side_effect = lambda arguments, *_args, **_kwargs: (
            'a' * 40 if arguments[0] == 'git' else
            version if arguments[0] == 'xcodebuild' else
            sdk if arguments[-1] == '--show-sdk-version' else
            'usage: simctl --set <path>' if arguments[-1] == 'help' else
            'list devices [<search term>]' if arguments[-1] == 'list' else
            '{"devices":{}}')

        def prepare():
            owner.record, owner.owns_receipt = {'device': 'owned', 'runtime': runtime}, True
            if failure is not None:
                raise failure
            return 'owned'

        owner.prepare.side_effect = prepare
        owner.cleanup.return_value = cleanup
        output = Path(directory) / 'output'
        arguments = ['--output', str(output)] + (['--keep-ready'] if keep else [])
        with patch.object(PREFLIGHT.IOS, 'IosOwnedRunner', return_value=owner), \
             patch.dict(os.environ, {'DEVELOPER_DIR': developer}), \
             patch.object(PREFLIGHT.Path, 'is_dir', return_value=present), \
             patch.object(PREFLIGHT.Path, 'glob', return_value=[]):
            code = PREFLIGHT.main(arguments)
        return code, owner, json.loads((output / 'result.json').read_text())

    def test_missing_wrong_or_incompatible_toolchain_never_prepares(self):
        for change in ({'present': False}, {'developer': '/unrelated'},
                       {'version': 'Xcode 26.6'}, {'version': ''}, {'sdk': '26.6'}):
            with self.subTest(change=change), tempfile.TemporaryDirectory() as directory:
                code, owner, result = self.exercise(directory, **change)
                self.assertEqual(code, 2)
                self.assertEqual(result['preflight'], 'FAIL')
                owner.prepare.assert_not_called()
                owner.cleanup.assert_not_called()

    def test_wrong_runtime_cleans_and_does_not_keep_ready(self):
        with tempfile.TemporaryDirectory() as directory:
            code, owner, result = self.exercise(directory, keep=True,
                runtime='com.apple.CoreSimulator.SimRuntime.iOS-26-6')
            self.assertEqual(code, 2)
            self.assertEqual(result['preflight'], 'FAIL')
            owner.cleanup.assert_called_once_with()

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
