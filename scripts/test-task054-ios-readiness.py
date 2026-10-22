#!/usr/bin/env python3
"""Gate host del nuovo readback per-owned-UDID; nessun SDK/dispositivo reale."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('ios_owned_inventory_boundaries',
    Path(__file__).with_name('test-task054-ios-owned.py'))
BASE = importlib.util.module_from_spec(spec)
spec.loader.exec_module(BASE)
M = BASE.MODULE
trace_spec = importlib.util.spec_from_file_location('ios_passive_process_trace',
    Path(__file__).with_name('trace-ios-owned-process.py'))
TRACE = importlib.util.module_from_spec(trace_spec)
trace_spec.loader.exec_module(TRACE)


class EnvironmentFixture(BASE.Fixture):
    def __init__(self, directory):
        super().__init__(directory)
        self.environment_values = {}
        self.environment_failure = None
        self.global_owner_changed = False

    def command(self, runner, arguments, timeout, capture=False):
        if arguments[:3] == ['xcrun', 'simctl', 'spawn']:
            self.runner = runner
            self.calls.append((arguments, timeout))
            if arguments[3] != BASE.DEVICE or arguments[4:6] != ['launchctl', 'getenv']:
                raise AssertionError('Comando non limitato al launchd del device proprio.')
            if not self.booted:
                raise M.Failure(1, 'process spawn device non Booted')
            variable = arguments[6]
            if variable == self.environment_failure:
                raise M.Failure(124, 'timeout readback per-device')
            values = {'SIMULATOR_UDID': BASE.DEVICE,
                      'SIMULATOR_DEVICE_NAME': runner.record['name'],
                      'SIMULATOR_RUNTIME_VERSION': '26.1'}
            values.update(self.environment_values)
            return values[variable] + '\n'
        # Causa storica riprodotta nel vero entrypoint: la nuova strategia non
        # invoca l'inventory globale dopo bootstatus. Cleanup conserva quel gate.
        if arguments[:4] == ['xcrun', 'simctl', 'list', 'devices'] and \
                self.booted and runner.phase != 'cleanup':
            self.calls.append((arguments, timeout))
            raise M.Failure(124, 'postboot inventory globale bloccata')
        result = super().command(runner, arguments, timeout, capture)
        if self.global_owner_changed and arguments[:4] == ['xcrun', 'simctl', 'list', 'devices']:
            data = json.loads(result)
            for entries in data['devices'].values():
                for entry in entries:
                    if entry['udid'] == BASE.DEVICE:
                        entry['name'] = 'Unrelated-replacement'
            return json.dumps(data)
        return result

    def execute(self, action, github_output=None, strategy=M.OWNED_ENVIRONMENT):
        args = [action, '--receipt', str(self.path)]
        if action == 'prepare':
            args += ['--headless', '--readiness-attestation', strategy]
        if github_output:
            args += ['--github-output', str(github_output)]
        def command(runner, *items, **kwargs):
            return self.command(runner, *items, **kwargs)
        with patch.object(M.IosOwnedRunner, 'command', command), \
             patch.object(M.signal, 'signal'), \
             patch.dict(os.environ, self.owner_environment, clear=True):
            return M.main(args)


class OwnedEnvironmentReadinessTest(unittest.TestCase):
    def test_legacy_global_postboot_failure_is_preserved_without_ready_or_export(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = EnvironmentFixture(directory)
            output = Path(directory) / 'github-output'
            self.assertEqual(fixture.execute('prepare', output, strategy='inventory'), 124)
            record = json.loads(fixture.path.read_text())
            self.assertFalse(record.get('ready', False))
            self.assertNotIn('readinessAttestation', record)
            self.assertFalse(output.exists())
            self.assertEqual(record['cleanup'], 'PASS')
            self.assertFalse(any(c[:3] == ['xcrun', 'simctl', 'spawn'] for c, _ in fixture.calls))

    def test_opt_in_owns_before_boot_and_attests_exact_environment_with_original_budget(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = EnvironmentFixture(directory)
            output = Path(directory) / 'github-output'
            self.assertEqual(fixture.execute('prepare', output), 0)
            record = json.loads(fixture.path.read_text())
            self.assertEqual(fixture.record_before_boot['device'], BASE.DEVICE)
            self.assertFalse(fixture.record_before_boot.get('ready', False))
            self.assertTrue(record['bootstatusCompleted'])
            self.assertTrue(record['ready'])
            self.assertEqual(record['runtime'], BASE.RUNTIME)
            self.assertEqual(record['runtimeVersion'], '26.1')
            self.assertEqual(record['readinessAttestation']['kind'], M.READINESS_KIND)
            self.assertEqual(record['readinessAttestation']['globalPostBootInventory'], 'NOT_RUN')
            self.assertEqual(fixture.path.stat().st_mode & 0o777, 0o600)
            self.assertEqual(output.read_text(), 'device_id=' + BASE.DEVICE + '\n')
            env = [(c, t) for c, t in fixture.calls if c[:3] == ['xcrun', 'simctl', 'spawn']]
            self.assertEqual([c[-1] for c, _ in env],
                ['SIMULATOR_UDID', 'SIMULATOR_DEVICE_NAME', 'SIMULATOR_RUNTIME_VERSION'])
            self.assertTrue(all(c[3] == BASE.DEVICE and 0 < t <= 30 for c, t in env))
            self.assertIn((['xcrun', 'simctl', 'bootstatus', BASE.DEVICE, '-b'], 300), fixture.calls)
            self.assertFalse(any(c[0] == 'open' or BASE.FOREIGN in c for c, _ in fixture.calls))

    def test_wrong_udid_name_runtime_or_absent_value_fails_closed_and_preserves_primary(self):
        for key, value in [('SIMULATOR_UDID', BASE.FOREIGN),
                ('SIMULATOR_DEVICE_NAME', 'Unrelated'),
                ('SIMULATOR_RUNTIME_VERSION', '26.2'), ('SIMULATOR_UDID', '')]:
            with self.subTest(variable=key), tempfile.TemporaryDirectory() as directory:
                fixture = EnvironmentFixture(directory)
                fixture.environment_values[key] = value
                output = Path(directory) / 'github-output'
                self.assertEqual(fixture.execute('prepare', output), 2)
                record = json.loads(fixture.path.read_text())
                self.assertFalse(record.get('ready', False))
                self.assertFalse(output.exists())
                self.assertNotIn('readinessAttestation', record)
                self.assertEqual(record['cleanup'], 'PASS')
                self.assertTrue(all(BASE.FOREIGN not in c for c, _ in fixture.calls))

    def test_bootstatus_failure_prevents_environment_query_and_ready(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = EnvironmentFixture(directory)
            fixture.fail = 'bootstatus'
            self.assertEqual(fixture.execute('prepare'), 7)
            record = json.loads(fixture.path.read_text())
            self.assertFalse(record.get('ready', False))
            self.assertFalse(record.get('bootstatusCompleted', False))
            self.assertNotIn('readinessAttestation', record)
            self.assertFalse(any(c[:3] == ['xcrun', 'simctl', 'spawn'] for c, _ in fixture.calls))
            self.assertEqual(record['cleanup'], 'PASS')

    def test_timeout_does_not_fallback_to_global_inventory_or_publish_ready(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = EnvironmentFixture(directory)
            fixture.environment_failure = 'SIMULATOR_DEVICE_NAME'
            self.assertEqual(fixture.execute('prepare'), 124)
            record = json.loads(fixture.path.read_text())
            self.assertFalse(record.get('ready', False))
            self.assertNotIn('readinessAttestation', record)
            self.assertEqual(record['cleanup'], 'PASS')
            self.assertFalse(any(c[-1] == 'SIMULATOR_RUNTIME_VERSION' for c, _ in fixture.calls))

    def test_reloaded_same_owner_revalidates_without_accepting_foreign_device(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = EnvironmentFixture(directory)
            self.assertEqual(fixture.execute('prepare'), 0)
            runner = M.IosOwnedRunner(fixture.path)
            runner.command = lambda *a, **k: fixture.command(runner, *a, **k)
            with patch.dict(os.environ, fixture.owner_environment, clear=True):
                runner.load()
                before = len(fixture.calls)
                with self.assertRaises(M.Failure):
                    runner.check_device(BASE.FOREIGN, ready=True, owned=True)
                self.assertEqual(len(fixture.calls), before)
                self.assertTrue(runner.check_device(BASE.DEVICE, ready=True, owned=True))
                self.assertEqual(len(fixture.calls) - before, 3)
                fixture.environment_values['SIMULATOR_RUNTIME_VERSION'] = '26.2'
                with self.assertRaises(M.Failure):
                    runner.check_device(BASE.DEVICE, ready=True, owned=True)

    def test_missing_terminal_attestation_or_other_owner_cannot_reuse_ready_receipt(self):
        for mutate in ('attestation', 'owner'):
            with self.subTest(mutate=mutate), tempfile.TemporaryDirectory() as directory:
                fixture = EnvironmentFixture(directory)
                self.assertEqual(fixture.execute('prepare'), 0)
                record = json.loads(fixture.path.read_text())
                if mutate == 'attestation':
                    record.pop('readinessAttestation')
                else:
                    record['ownerContext']['GITHUB_JOB'] = 'another-job'
                fixture.path.write_text(json.dumps(record))
                runner = M.IosOwnedRunner(fixture.path)
                with patch.dict(os.environ, fixture.owner_environment, clear=True), \
                     self.assertRaises(M.Failure):
                    runner.load()

    def test_three_readbacks_share_thirty_second_budget(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = EnvironmentFixture(directory)
            self.assertEqual(fixture.execute('prepare'), 0)
            runner = M.IosOwnedRunner(fixture.path)
            runner.command = lambda *a, **k: fixture.command(runner, *a, **k)
            with patch.dict(os.environ, fixture.owner_environment, clear=True):
                runner.load()
            before = len(fixture.calls)
            with patch.object(M.time, 'monotonic', side_effect=[100, 100, 108, 130]), \
                 self.assertRaises(M.Failure) as failure:
                runner.check_device(BASE.DEVICE, ready=True, owned=True)
            self.assertEqual(failure.exception.code, 124)
            queried = fixture.calls[before:]
            self.assertEqual([c[-1] for c, _ in queried],
                ['SIMULATOR_UDID', 'SIMULATOR_DEVICE_NAME'])
            self.assertEqual([t for _, t in queried], [30, 22])

    def test_cleanup_retains_global_identity_gate_and_never_mutates_changed_owner(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = EnvironmentFixture(directory)
            self.assertEqual(fixture.execute('prepare'), 0)
            fixture.global_owner_changed = True
            before = len(fixture.calls)
            self.assertEqual(fixture.execute('cleanup'), 1)
            record = json.loads(fixture.path.read_text())
            self.assertEqual(record['cleanup'], 'FAIL')
            self.assertFalse(any(c[:3] in [['xcrun', 'simctl', 'shutdown'],
                ['xcrun', 'simctl', 'delete']] for c, _ in fixture.calls[before:]))


class PassiveProcessTraceTest(unittest.TestCase):
    def execute(self, fixture, passive=True, timeout=False, broken_sink=False):
        args = ['prepare', '--receipt', str(fixture.path), '--headless']
        if passive:
            args.append('--trace-processes')

        def command(runner, arguments, *items, **kwargs):
            if timeout and arguments[:3] == ['xcrun', 'simctl', 'bootstatus']:
                fixture.calls.append((arguments, items[0]))
                raise M.Failure(124, 'synthetic original timeout')
            return fixture.command(runner, arguments, *items, **kwargs)

        original_stream = TRACE.exclusive_trace_stream
        original_trace = TRACE.trace_processes
        self.trace_calls = []

        def trace_context(*args, **kwargs):
            self.trace_calls.append((args, kwargs))
            return original_trace(*args, **kwargs)

        @contextlib.contextmanager
        def failing_stream(path):
            with original_stream(path) as stream:
                class Writer:
                    def write(self, value):
                        raise OSError('PRIVATE_PERSISTENCE_ERROR')
                yield Writer()

        fake_spec = SimpleNamespace(loader=SimpleNamespace(exec_module=lambda module: None))
        with contextlib.ExitStack() as stack:
            stack.enter_context(patch.object(M.IosOwnedRunner, 'command', command))
            stack.enter_context(patch.object(M.signal, 'signal'))
            stack.enter_context(patch.dict(os.environ, fixture.owner_environment, clear=True))
            stack.enter_context(patch.object(M.uuid, 'uuid4', return_value=SimpleNamespace(hex='a' * 32)))
            stack.enter_context(patch.object(M.importlib.util, 'spec_from_file_location', return_value=fake_spec))
            stack.enter_context(patch.object(M.importlib.util, 'module_from_spec', return_value=TRACE))
            stack.enter_context(patch.object(TRACE, 'ReadinessObservation', side_effect=AssertionError('observer forbidden')))
            stack.enter_context(patch.object(TRACE, 'BootstatusObservation', side_effect=AssertionError('observer forbidden')))
            stack.enter_context(patch.object(TRACE, 'trace_processes', trace_context))
            if broken_sink:
                stack.enter_context(patch.object(TRACE, 'exclusive_trace_stream', failing_stream))
            # Un flag assente nella baseline deve dare un RED di comportamento,
            # non un errore di setup della suite.
            try:
                with contextlib.redirect_stderr(io.StringIO()):
                    return M.main(args)
            except SystemExit as error:
                return error.code

    def test_passive_main_preserves_commands_budgets_and_never_constructs_observer(self):
        with tempfile.TemporaryDirectory() as first, tempfile.TemporaryDirectory() as second:
            legacy, passive = BASE.Fixture(first), BASE.Fixture(second)
            self.assertEqual(self.execute(legacy, passive=False), 0)
            self.assertEqual(self.execute(passive), 0)
            self.assertEqual(len(self.trace_calls), 1)
            self.assertTrue(all(self.trace_calls[0][1].get(key) is None for key in (
                'readiness_record', 'bootstatus_record', 'readiness_cleanup_failed', 'bootstatus_destination')))
            self.assertEqual(passive.calls, legacy.calls)
            self.assertIn((['xcrun', 'simctl', 'bootstatus', BASE.DEVICE, '-b'], 300), passive.calls)
            destination = passive.path.with_suffix('.processes.jsonl')
            self.assertTrue(destination.is_file())
            self.assertEqual(destination.stat().st_mode & 0o777, 0o600)
            rows = [json.loads(row) for row in destination.read_text().splitlines()]
            self.assertEqual([row['event'] for row in rows], ['trace-start', 'trace-end'])
            record = json.loads(passive.path.read_text())
            self.assertNotIn('bootstatusObservationOwnership', record)
            self.assertNotIn('readinessTraceEvidence', record)
            self.assertNotIn('bootstatusTraceEvidence', record)

    def test_existing_passive_trace_is_preserved_before_any_native_command(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = BASE.Fixture(directory)
            destination = fixture.path.with_suffix('.processes.jsonl')
            destination.write_text('preserved existing evidence')
            self.assertEqual(self.execute(fixture), 2)
            self.assertEqual(destination.read_text(), 'preserved existing evidence')
            self.assertEqual(fixture.calls, [])
            self.assertFalse(fixture.path.exists())

    def test_passive_persistence_failure_preserves_primary124_and_owned_cleanup(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = BASE.Fixture(directory)
            original_popen = subprocess.Popen
            self.assertEqual(self.execute(fixture, timeout=True, broken_sink=True), 124)
            record = json.loads(fixture.path.read_text())
            self.assertEqual(record['cleanup'], 'PASS')
            self.assertFalse(record.get('ready', False))
            self.assertEqual(record.get('processTraceEvidence'),
                {'result': 'FAIL', 'errorType': 'OSError', 'phase': 'exit'})
            self.assertNotIn('PRIVATE_', fixture.path.read_text())
            self.assertIn((['xcrun', 'simctl', 'delete', BASE.DEVICE], 30), fixture.calls)
            self.assertIs(subprocess.Popen, original_popen)

    def test_passive_persistence_failure_after_prepare_pass_cannot_publish_pass(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = BASE.Fixture(directory)
            self.assertEqual(self.execute(fixture, broken_sink=True), 2)
            self.assertTrue(fixture.path.is_file(), 'prepare deve essere attraversato prima del failure trace')
            record = json.loads(fixture.path.read_text())
            self.assertEqual(record['cleanup'], 'PASS')
            self.assertEqual(record.get('processTraceEvidence', {}).get('result'), 'FAIL')
            self.assertFalse(fixture.exists)

    def measured(self, directory, exit_at_poll=None, spawn_error=False, clock=None):
        calls = []

        class ExistingPopen:
            def __init__(self, arguments, *args, **kwargs):
                calls.append(('spawn', arguments, args, kwargs))
                if clock is not None:
                    clock[0] += 50
                if spawn_error:
                    raise OSError('PRIVATE_SPAWN_ERROR')
                self.pid = 7301
                self.returncode = None
                self.stdin = None
                self.stdout = SimpleNamespace(closed=False)
                self.stderr = None

            def communicate(self, *args, **kwargs):
                calls.append(('communicate', args, kwargs))
                raise subprocess.TimeoutExpired('PRIVATE_ARGV', kwargs['timeout'],
                    output='PRIVATE_STDOUT', stderr='PRIVATE_STDERR')

            def poll(self):
                calls.append(('poll',))
                self.returncode = exit_at_poll
                return self.returncode

        destination = Path(directory) / 'processes.jsonl'
        arguments = ['xcrun', 'simctl', 'spawn', BASE.DEVICE, 'launchctl', 'list']
        original_popen = subprocess.Popen
        def getpgid(process_id):
            if clock is not None:
                clock[0] += 70
            return process_id

        with contextlib.ExitStack() as stack:
            stack.enter_context(patch.object(TRACE.subprocess, 'Popen', ExistingPopen))
            stack.enter_context(patch.object(TRACE.os, 'getpgid', side_effect=getpgid))
            stack.enter_context(patch.object(TRACE.subprocess, 'run', side_effect=AssertionError('extra subprocess forbidden')))
            stack.enter_context(patch.object(TRACE, 'ReadinessObservation', side_effect=AssertionError('observer forbidden')))
            stack.enter_context(patch.object(TRACE, 'BootstatusObservation', side_effect=AssertionError('observer forbidden')))
            if clock is not None:
                stack.enter_context(patch.object(TRACE.time, 'monotonic_ns', side_effect=lambda: clock[0]))
            with TRACE.trace_processes(destination):
                if spawn_error:
                    with self.assertRaises(OSError):
                        subprocess.Popen(arguments, start_new_session=True, stdout=subprocess.PIPE)
                else:
                    process = subprocess.Popen(arguments, start_new_session=True, stdout=subprocess.PIPE)
                    with self.assertRaises(subprocess.TimeoutExpired):
                        process.communicate(timeout=25.75)
            self.assertIs(subprocess.Popen, ExistingPopen)
        self.assertIs(subprocess.Popen, original_popen)
        rows = [json.loads(row) for row in destination.read_text().splitlines()]
        text = destination.read_text()
        self.assertNotIn(BASE.DEVICE, text)
        self.assertNotIn('PRIVATE_', text)
        self.assertEqual(sum(row[0] == 'spawn' for row in calls), 1)
        return rows, calls

    def test_timeout_distinguishes_live_host_leader_without_extra_process_or_poll(self):
        with tempfile.TemporaryDirectory() as directory:
            rows, calls = self.measured(directory)
            timeout = next(row for row in rows if row['event'] == 'communicate-timeout')
            self.assertEqual(timeout['leader_state'], 'alive')
            self.assertIsNone(timeout['returncode_before_poll'])
            self.assertIsNone(timeout['returncode_after_poll'])
            self.assertEqual(timeout.get('pipe_state_before_poll'),
                {'stdin': 'not_exposed', 'stdout': 'open', 'stderr': 'not_exposed'})
            self.assertEqual(timeout.get('pipe_state_after_poll'), timeout['pipe_state_before_poll'])
            self.assertEqual(timeout.get('pid_scope'), 'host_subprocess_leader')
            self.assertEqual(timeout['operation'], 'simctl-spawn')
            self.assertIs(timeout.get('guest_pid_observed'), False)
            self.assertEqual(timeout['timeout_seconds'], 25.75)
            self.assertTrue(timeout['observer_poll_may_reap'])
            self.assertEqual(calls[1:], [('communicate', (), {'timeout': 25.75}), ('poll',)])

    def test_exited_host_leader_with_open_stream_is_only_possible_inherited_pipe(self):
        with tempfile.TemporaryDirectory() as directory:
            rows, calls = self.measured(directory, exit_at_poll=0)
            timeout = next(row for row in rows if row['event'] == 'communicate-timeout')
            self.assertEqual(timeout['leader_state'], 'terminated')
            self.assertEqual(timeout['returncode_after_poll'], 0)
            self.assertEqual(timeout['inherited_pipe'], 'possible')
            self.assertEqual(timeout.get('pipe_state_after_poll', {}).get('stdout'), 'open')
            self.assertEqual(timeout.get('host_command'), 'xcrun-simctl')
            self.assertFalse(timeout['output_complete'])
            self.assertEqual(timeout['stdout']['bytes'], len('PRIVATE_STDOUT'))
            self.assertEqual(sum(call[0] == 'poll' for call in calls), 1)

    def test_spawn_cost_has_endpoints_around_same_popen_for_success_or_error(self):
        for spawn_error in (False, True):
            with self.subTest(spawn_error=spawn_error), tempfile.TemporaryDirectory() as directory:
                rows, calls = self.measured(directory, spawn_error=spawn_error, clock=[0])
                end = next(row for row in rows if row['event'] == (
                    'spawn-error' if spawn_error else 'spawn-end'))
                self.assertIn('popen_started_ns', end)
                self.assertIn('popen_completed_ns', end)
                self.assertGreaterEqual(end['popen_completed_ns'], end['popen_started_ns'])
                self.assertEqual(end.get('popen_duration_ns'),
                    end['popen_completed_ns'] - end['popen_started_ns'])
                self.assertEqual(end['popen_duration_ns'], 50)
                self.assertEqual(end['duration_ns'], 50 if spawn_error else 120)
                self.assertEqual(len(calls), 1 if spawn_error else 3)

    def test_journal_workflow_selects_passive_only_and_preserves_always_jsonl_upload(self):
        workflow = Path(__file__).resolve().parent.parent / '.github/workflows/ci.yml'
        journal = workflow.read_text().split('  ios-address-journal:\n', 1)[1]
        self.assertEqual(journal.count('--trace-processes'), 1)
        self.assertNotIn('--observe-readiness', journal)
        self.assertNotIn('--observe-bootstatus', journal)
        self.assertIn('build/task054/ios-journal-owned-receipt.processes.jsonl', journal)
        upload = journal.split('- name: Save iOS journal restart receipts', 1)[1]
        self.assertIn('if: always()', upload)


if __name__ == '__main__':
    unittest.main()
