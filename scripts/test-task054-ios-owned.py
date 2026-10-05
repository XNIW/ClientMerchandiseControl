#!/usr/bin/env python3
"""Regressioni lifecycle/processi: nessun boot, build o dispositivo reale."""
import importlib.util
import contextlib
import io
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import Mock, patch

SPEC = importlib.util.spec_from_file_location('ios_owned',
    Path(__file__).with_name('run-task054-ios-owned.py'))
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)
DEVICE = '11111111-1111-4111-8111-111111111111'
FOREIGN = '22222222-2222-4222-8222-222222222222'
RUNTIME = 'com.apple.CoreSimulator.SimRuntime.iOS-26-1'


class Fixture:
    def __init__(self, directory, fail=None, signal_at_create=None, unknown_create=False):
        self.path = Path(directory) / 'owned.json'
        self.calls = []
        self.fail = fail
        self.signal_at_create = signal_at_create
        self.unknown_create = unknown_create
        self.exists = False
        self.booted = False
        self.runner = None
        self.record_before_boot = None
        self.owner_environment = {key: os.environ[key] for key in MODULE.OWNER_CONTEXT
                                  if key in os.environ}

    def command(self, runner, arguments, timeout, capture=False):
        self.runner = runner
        self.calls.append((arguments, timeout))
        action = arguments[2] if arguments[0] == 'xcrun' else arguments[0]
        if action == 'create':
            if self.signal_at_create:
                runner.interrupted(self.signal_at_create, None)
            if self.unknown_create:
                raise MODULE.Failure(124, 'timeout create')
            self.exists = True
            return DEVICE
        if action == 'boot':
            self.record_before_boot = json.loads(self.path.read_text())
            if self.fail == 'boot':
                raise MODULE.Failure(7, 'mock boot')
            self.booted = True
        if action == 'delete':
            self.exists = False
        if action == self.fail:
            raise MODULE.Failure(7, 'mock failure')
        if action == 'list' and 'runtimes' in arguments:
            return json.dumps({'runtimes': [
                {'isAvailable': True, 'identifier': RUNTIME, 'version': '26.1'},
                {'isAvailable': True, 'identifier': 'iOS-27-0', 'version': '27.0'}]})
        if action == 'list' and 'devices' in arguments:
            entries = [{'udid': FOREIGN, 'name': 'Unrelated', 'state': 'Booted',
                        'isAvailable': True}]
            if self.exists:
                entries.append({'udid': DEVICE, 'name': runner.record['name'],
                                'state': 'Booted' if self.booted else 'Shutdown',
                                'isAvailable': True})
            return json.dumps({'devices': {RUNTIME: entries}})
        return '/fake/Developer' if arguments[0] == 'xcode-select' else ''

    def execute(self, action, github_output=None):
        def command(runner, *args, **kwargs):
            return self.command(runner, *args, **kwargs)
        args = [action, '--receipt', str(self.path)]
        if action == 'smoke':
            args += ['--device', DEVICE]
        if github_output:
            args += ['--github-output', str(github_output)]
        with patch.object(MODULE.IosOwnedRunner, 'command', command), \
             patch.object(MODULE.Path, 'is_dir', return_value=True), \
             patch.object(MODULE.signal, 'signal'), \
             patch.dict(os.environ, self.owner_environment, clear=True):
            return MODULE.main(args)


class IosOwnedTest(unittest.TestCase):
    def test_prepare_owns_once_persists_before_boot_and_exports_after_ready(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            output = Path(directory) / 'github-output'
            self.assertEqual(fixture.execute('prepare', output), 0)
            record = json.loads(fixture.path.read_text())
            self.assertEqual(record['device'], DEVICE)
            self.assertTrue(record['ready'])
            self.assertEqual(fixture.record_before_boot['device'], DEVICE)
            self.assertFalse(fixture.record_before_boot.get('ready', False))
            self.assertEqual(fixture.path.stat().st_mode & 0o777, 0o600)
            self.assertEqual(output.read_text(), 'device_id=' + DEVICE + '\n')
            self.assertEqual(sum('create' in c for c, _ in fixture.calls), 1)
            self.assertEqual(sum('bootstatus' in c for c, _ in fixture.calls), 1)
            self.assertIn((['xcrun', 'simctl', 'bootstatus', DEVICE, '-b'], 300), fixture.calls)
            self.assertFalse(any('shutdown' in c or 'delete' in c for c, _ in fixture.calls))

    def test_prepare_existing_receipt_cannot_mutate_or_cleanup_it(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            fixture.path.write_text('preserved unrelated state')
            self.assertEqual(fixture.execute('prepare'), 2)
            self.assertEqual(fixture.path.read_text(), 'preserved unrelated state')
            self.assertEqual(fixture.calls, [])

    def test_boot_failure_cleans_only_owned_device_and_preserves_primary(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory, fail='boot')
            self.assertEqual(fixture.execute('prepare'), 7)
            self.assertEqual(json.loads(fixture.path.read_text())['cleanup'], 'PASS')
            actions = [c for c, _ in fixture.calls if 'shutdown' in c or 'delete' in c]
            self.assertEqual(actions, [['xcrun', 'simctl', 'delete', DEVICE]])

    def test_output_failure_still_cleans_owned_creation(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            self.assertEqual(fixture.execute('prepare', Path(directory)/'missing'/'output'), 2)
            self.assertEqual(json.loads(fixture.path.read_text())['cleanup'], 'PASS')
            self.assertFalse(fixture.exists)

    def test_unknown_create_outcome_is_blocked_without_guessing_device(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory, unknown_create=True)
            self.assertEqual(fixture.execute('prepare'), 124)
            self.assertEqual(json.loads(fixture.path.read_text())['cleanup'], 'BLOCKED')
            self.assertFalse(any('delete' in c or 'shutdown' in c for c, _ in fixture.calls))

    def test_signal_during_create_records_returned_uuid_then_cleans(self):
        for signum in (signal.SIGTERM, signal.SIGINT):
            with self.subTest(signum=signum), tempfile.TemporaryDirectory() as directory:
                fixture = Fixture(directory, signal_at_create=signum)
                self.assertEqual(fixture.execute('prepare'), 128+signum)
                self.assertEqual(json.loads(fixture.path.read_text())['cleanup'], 'PASS')
                self.assertFalse(any('boot' in c for c, _ in fixture.calls))

    def test_cleanup_is_idempotent_only_after_absence_readback(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            self.assertEqual(fixture.execute('prepare'), 0)
            fixture.calls.clear()
            self.assertEqual(fixture.execute('cleanup'), 0)
            self.assertEqual(fixture.execute('cleanup'), 0)
            self.assertEqual(sum('delete' in c for c, _ in fixture.calls), 1)
            self.assertEqual(sum('shutdown' in c for c, _ in fixture.calls), 1)
            self.assertGreaterEqual(sum('list' in c for c, _ in fixture.calls), 3)

    def test_cleanup_without_receipt_is_failure_and_performs_no_command(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            self.assertEqual(fixture.execute('cleanup'), 1)
            self.assertEqual(fixture.calls, [])

    def test_cleanup_writable_or_symlink_receipt_is_rejected(self):
        for mode in ('public', 'symlink'):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as directory:
                fixture = Fixture(directory)
                self.assertEqual(fixture.execute('prepare'), 0)
                if mode == 'public':
                    fixture.path.chmod(0o644)
                else:
                    actual = fixture.path.with_name('actual.json')
                    fixture.path.rename(actual)
                    fixture.path.symlink_to(actual)
                fixture.calls.clear()
                self.assertEqual(fixture.execute('cleanup'), 1)
                self.assertEqual(fixture.calls, [])

    def test_receipt_from_another_run_cannot_cleanup_a_device(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            self.assertEqual(fixture.execute('prepare'), 0)
            record = json.loads(fixture.path.read_text())
            record['ownerContext']['GITHUB_RUN_ID'] = 'another-run'
            fixture.path.write_text(json.dumps(record))
            before = fixture.path.read_bytes()
            fixture.calls.clear()
            self.assertEqual(fixture.execute('cleanup'), 1)
            self.assertEqual(fixture.calls, [])
            self.assertEqual(fixture.path.read_bytes(), before)

    def test_cleanup_mismatched_name_or_runtime_never_mutates_device(self):
        contexts = ({}, {'GITHUB_RUN_ID': '123456789', 'GITHUB_RUN_ATTEMPT': '2',
                         'GITHUB_JOB': 'ios-build', 'GITHUB_SHA': '65487aee'})
        for context in contexts:
            for key in ('name', 'runtime'):
                with self.subTest(key=key, context=context), \
                     patch.dict(os.environ, context, clear=True), \
                     tempfile.TemporaryDirectory() as directory:
                    fixture = Fixture(directory)
                    self.assertEqual(fixture.execute('prepare'), 0)
                    runner = MODULE.IosOwnedRunner(fixture.path)
                    runner.load()
                    self.assertEqual(runner.record['ownerContext'],
                                     {name: context.get(name) for name in MODULE.OWNER_CONTEXT})
                    entry = {'udid': DEVICE, 'name': runner.record['name']}
                    runtime = runner.record['runtime']
                    if key == 'name': entry['name'] = 'Someone else'
                    else: runtime = 'foreign-runtime'
                    with patch.object(runner, 'device_record', return_value=(entry, runtime)), \
                         patch.object(runner, 'command') as command, \
                         self.assertRaises(MODULE.Failure) as failure:
                        runner.cleanup()
                    self.assertIn('ownership simulatore non coincide', str(failure.exception))
                    command.assert_not_called()

    def test_delete_failure_cannot_claim_cleanup_pass(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            self.assertEqual(fixture.execute('prepare'), 0)
            fixture.fail = 'delete'
            self.assertEqual(fixture.execute('cleanup'), 1)
            self.assertEqual(json.loads(fixture.path.read_text())['cleanup'], 'FAIL')

    def test_shutdown_failure_still_deletes_and_fails_cleanup(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            self.assertEqual(fixture.execute('prepare'), 0)
            fixture.fail = 'shutdown'
            self.assertEqual(fixture.execute('cleanup'), 1)
            self.assertFalse(fixture.exists)

    def test_already_shutdown_device_is_deleted_without_spurious_shutdown_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            self.assertEqual(fixture.execute('prepare'), 0)
            fixture.booted = False
            fixture.fail = 'shutdown'
            fixture.calls.clear()
            self.assertEqual(fixture.execute('cleanup'), 0)
            self.assertFalse(any('shutdown' in c for c, _ in fixture.calls))
            self.assertFalse(fixture.exists)

    def test_process_cleanup_failure_survives_successful_device_delete_and_reopen(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            self.assertEqual(fixture.execute('prepare'), 0)
            runner = fixture.runner
            runner.process_cleanup_failed = True
            with patch.object(runner, 'command',
                side_effect=lambda *args, **kwargs: fixture.command(runner, *args, **kwargs)):
                self.assertFalse(runner.cleanup())
            record = json.loads(fixture.path.read_text())
            self.assertEqual(record['cleanup'], 'FAIL')
            self.assertTrue(record['processCleanupFailed'])
            self.assertFalse(fixture.exists)
            self.assertEqual(fixture.execute('cleanup'), 1)
            self.assertEqual(json.loads(fixture.path.read_text())['cleanup'], 'FAIL')

    def test_prepare_timeout_and_inventory_failure_survive_next_cleanup_process(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            original = fixture.command
            state = {'bootTimedOut': False, 'initialCleanupFailed': False}
            def command(runner, arguments, timeout, capture=False):
                if arguments[:3] == ['xcrun', 'simctl', 'bootstatus']:
                    state['bootTimedOut'] = True
                    runner.process_cleanup_failed = True
                    raise MODULE.Failure(124, 'bootstatus primario')
                if arguments[:4] == ['xcrun', 'simctl', 'list', 'devices'] and \
                        state['bootTimedOut'] and not state['initialCleanupFailed']:
                    state['initialCleanupFailed'] = True
                    raise MODULE.Failure(124, 'inventory cleanup fallita')
                return original(runner, arguments, timeout, capture)
            fixture.command = command
            self.assertEqual(fixture.execute('prepare'), 124)
            initial = json.loads(fixture.path.read_text())
            self.assertTrue(initial['processCleanupFailed'])
            self.assertEqual(initial['cleanup'], 'FAIL')
            self.assertEqual(initial['cleanupAttempts'][0]['resourceCleanup'], 'FAIL')
            self.assertTrue(fixture.exists)
            self.assertEqual(fixture.execute('cleanup'), 1)
            final = json.loads(fixture.path.read_text())
            self.assertFalse(fixture.exists)
            self.assertTrue(final['processCleanupFailed'])
            self.assertEqual(final['cleanup'], 'FAIL')
            self.assertEqual([a['attempt'] for a in final['cleanupAttempts']], [1, 2])
            self.assertEqual([a['result'] for a in final['cleanupAttempts']], ['FAIL', 'FAIL'])
            self.assertEqual([a['resourceCleanup'] for a in final['cleanupAttempts']], ['FAIL', 'PASS'])

    def test_failed_cleanup_query_remains_failed_after_later_resource_success(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            self.assertEqual(fixture.execute('prepare'), 0)
            original = fixture.command
            def command(runner, arguments, timeout, capture=False):
                if arguments[:4] == ['xcrun', 'simctl', 'list', 'devices']:
                    raise MODULE.Failure(7, 'query cleanup fallita')
                return original(runner, arguments, timeout, capture)
            fixture.command = command
            fixture.calls.clear()
            self.assertEqual(fixture.execute('cleanup'), 1)
            self.assertEqual(fixture.calls, [])
            initial = json.loads(fixture.path.read_text())
            self.assertEqual(initial['cleanup'], 'FAIL')
            self.assertFalse(initial['processCleanupFailed'])
            fixture.command = original
            self.assertEqual(fixture.execute('cleanup'), 1)
            final = json.loads(fixture.path.read_text())
            self.assertFalse(fixture.exists)
            self.assertEqual(final['cleanup'], 'FAIL')
            self.assertFalse(final['processCleanupFailed'])
            self.assertEqual(final['cleanupAttempts'][1]['resourceCleanup'], 'PASS')

    def test_identity_failure_records_attempt_without_mutating_another_device(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            self.assertEqual(fixture.execute('prepare'), 0)
            runner = MODULE.IosOwnedRunner(fixture.path)
            entry = {'udid': DEVICE, 'name': 'Unrelated owner'}
            with patch.object(runner, 'device_record', return_value=(entry, RUNTIME)), \
                 patch.object(runner, 'command') as command, \
                 self.assertRaises(MODULE.Failure) as failure:
                runner.cleanup()
            self.assertIn('ownership simulatore non coincide', str(failure.exception))
            command.assert_not_called()
            initial = json.loads(fixture.path.read_text())
            self.assertEqual(initial['cleanup'], 'FAIL')
            self.assertEqual(initial['cleanupAttempts'][0]['resourceCleanup'], 'FAIL')
            self.assertEqual(fixture.execute('cleanup'), 1)
            self.assertFalse(fixture.exists)
            self.assertEqual(json.loads(fixture.path.read_text())['cleanupAttempts'][1]['resourceCleanup'], 'PASS')

    def test_final_receipt_write_failure_keeps_primary_query_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            self.assertEqual(fixture.execute('prepare'), 0)
            runner = MODULE.IosOwnedRunner(fixture.path)
            runner.load()
            persist = runner.persist
            writes = []
            def failing_final_write():
                writes.append(True)
                if len(writes) == 2:
                    raise OSError('scrittura fixture non disponibile')
                persist()
            with patch.object(runner, 'persist', side_effect=failing_final_write), \
                 patch.object(runner, 'check_device', side_effect=MODULE.Failure(7, 'query primaria')), \
                 self.assertRaises(MODULE.Failure) as failure:
                runner.cleanup()
            self.assertEqual(failure.exception.code, 7)
            self.assertEqual(str(failure.exception), 'query primaria')
            initial = json.loads(fixture.path.read_text())
            self.assertEqual(initial['cleanup'], 'NOT_RUN')
            self.assertEqual(initial['cleanupAttempts'][0]['result'], 'NOT_RUN')
            self.assertFalse(initial['processCleanupFailed'])
            # Nuovo processo: la risorsa rimossa non completa il tentativo storico.
            self.assertEqual(fixture.execute('cleanup'), 1)
            final = json.loads(fixture.path.read_text())
            self.assertFalse(fixture.exists)
            self.assertEqual(final['cleanup'], 'BLOCKED')
            self.assertFalse(final['processCleanupFailed'])
            self.assertEqual(final['cleanupAttempts'][0]['result'], 'NOT_RUN')
            self.assertEqual(final['cleanupAttempts'][1]['resourceCleanup'], 'PASS')
            self.assertEqual(final['cleanupAttempts'][1]['result'], 'BLOCKED')

    def test_borrowed_smoke_runs_exact_test_with_900_without_lifecycle_mutation(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            self.assertEqual(fixture.execute('prepare'), 0)
            fixture.calls.clear()
            self.assertEqual(fixture.execute('smoke'), 0)
            self.assertEqual(fixture.calls[-1], (MODULE.SMOKE+['-d', DEVICE], 900))
            self.assertFalse(any('boot' in c or 'delete' in c or 'shutdown' in c
                                 for c, _ in fixture.calls))
            self.assertEqual(json.loads(fixture.path.read_text())['cleanup'], 'NOT_RUN')

    def test_borrowed_not_booted_stops_before_flutter(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            self.assertEqual(fixture.execute('prepare'), 0)
            fixture.booted = False
            fixture.calls.clear()
            self.assertEqual(fixture.execute('smoke'), 2)
            self.assertFalse(any(c[0] == 'flutter' for c, _ in fixture.calls))

    def test_non_uuid_is_rejected_before_any_device_query(self):
        runner = MODULE.IosOwnedRunner()
        with patch.object(runner, 'command') as command, self.assertRaises(MODULE.Failure):
            runner.smoke('booted')
        command.assert_not_called()

    def test_booted_unrelated_device_is_not_accepted_as_borrowed_smoke_target(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            self.assertEqual(fixture.execute('prepare'), 0)
            runner = MODULE.IosOwnedRunner(fixture.path)
            with patch.object(runner, 'command') as command, self.assertRaises(MODULE.Failure):
                runner.smoke(FOREIGN)
            command.assert_not_called()

    def test_borrowed_smoke_requires_receipt_before_any_resource_command(self):
        runner = MODULE.IosOwnedRunner()
        with patch.object(runner, 'command') as command, self.assertRaises(MODULE.Failure):
            runner.smoke(DEVICE)
        command.assert_not_called()

    def test_borrowed_smoke_process_cleanup_failure_persists_primary_and_reopen_fail(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            self.assertEqual(fixture.execute('prepare'), 0)
            command_before_failure = fixture.command
            def command(runner, arguments, timeout, capture=False):
                if arguments[0] == 'flutter':
                    runner.process_cleanup_failed = True
                    raise MODULE.Failure(7, 'smoke primario')
                return command_before_failure(runner, arguments, timeout, capture)
            fixture.command = command
            fixture.calls.clear()
            self.assertEqual(fixture.execute('smoke'), 7)
            self.assertTrue(json.loads(fixture.path.read_text())['processCleanupFailed'])
            self.assertTrue(fixture.exists)  # Cleanup device resta nello step separato.
            self.assertFalse(any('delete' in c or 'shutdown' in c for c, _ in fixture.calls))
            self.assertEqual(fixture.execute('cleanup'), 1)
            self.assertFalse(fixture.exists)
            self.assertEqual(json.loads(fixture.path.read_text())['cleanup'], 'FAIL')

    def test_borrowed_smoke_rejects_receipt_from_another_owner_before_query(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            self.assertEqual(fixture.execute('prepare'), 0)
            record = json.loads(fixture.path.read_text())
            record['ownerContext']['GITHUB_RUN_ID'] = 'another-run'
            fixture.path.write_text(json.dumps(record))
            fixture.calls.clear()
            self.assertEqual(fixture.execute('smoke'), 2)
            self.assertEqual(fixture.calls, [])

    def test_probe_failure_after_normal_command_still_stops_only_owned_group(self):
        secret = 'FOREIGN_ARGUMENT_OR_SECRET_SENTINEL'
        cases = [(subprocess.TimeoutExpired(secret, 2, output=secret, stderr=secret),
                  {'errorType': 'TimeoutExpired', 'timeoutSeconds': 2}),
                 (OSError(5, secret, secret), {'errorType': 'OSError', 'errno': 5}),
                 (Mock(returncode=9, stdout=secret, stderr=secret),
                  {'reason': 'exitStatus', 'exitCode': 9, 'rowCount': 1}),
                 (Mock(returncode=0, stdout='54321 S\n'+secret+' args payload\n', stderr=secret),
                  {'reason': 'shape', 'rowCount': 2, 'fieldCount': 3, 'numericPgid': False})]
        for reply, expected in cases:
            with self.subTest(expected=expected):
                runner = MODULE.IosOwnedRunner()
                process = Mock(pid=54321, returncode=0)
                process.communicate.return_value = ('', None)
                result = {'side_effect': reply} if isinstance(reply, Exception) else {'return_value': reply}
                output = io.StringIO()
                with patch.object(MODULE.subprocess, 'Popen', return_value=process), \
                     patch.object(MODULE.subprocess, 'run', **result), \
                     patch.object(MODULE, 'stop_owned_process') as stop, \
                     contextlib.redirect_stdout(output), \
                     self.assertRaises(MODULE.Failure) as failure:
                    runner.command(['fake'], 900)
                self.assertEqual(failure.exception.code, 1)
                self.assertTrue(runner.process_cleanup_failed)
                stop.assert_called_once_with(process)
                events = [json.loads(line.removeprefix('DIAGNOSTIC: '))
                          for line in output.getvalue().splitlines() if line.startswith('DIAGNOSTIC: ')]
                self.assertEqual(events[0], dict(operation='psProbe', ownedPgid=54321, **expected))
                self.assertEqual(events[1]['operation'], 'commandProbe')
                self.assertNotIn(secret, output.getvalue())

    def test_timeout_keeps_124_if_process_cleanup_probe_fails(self):
        runner = MODULE.IosOwnedRunner()
        process = Mock(pid=54321)
        process.communicate.side_effect = subprocess.TimeoutExpired('fake', 900)
        output = io.StringIO()
        with patch.object(MODULE.subprocess, 'Popen', return_value=process), \
             patch.object(MODULE, 'stop_owned_process', side_effect=MODULE.Failure(1, 'SECRET_SENTINEL')), \
             contextlib.redirect_stdout(output), \
             self.assertRaises(MODULE.Failure) as failure:
            runner.command(['fake'], 900)
        self.assertEqual(failure.exception.code, 124)
        self.assertTrue(runner.process_cleanup_failed)
        events = [json.loads(line.removeprefix('DIAGNOSTIC: '))
                  for line in output.getvalue().splitlines() if line.startswith('DIAGNOSTIC: ')]
        self.assertEqual(events, [dict(operation='commandCleanup', ownedPgid=54321,
                                       errorType='Failure', failureCode=1)])
        self.assertNotIn('SECRET_SENTINEL', output.getvalue())

    def test_interrupt_keeps_primary_and_stops_only_owned_group(self):
        for signum in (signal.SIGTERM, signal.SIGINT):
            with self.subTest(signum=signum):
                runner = MODULE.IosOwnedRunner()
                process = Mock(pid=54321)
                process.communicate.side_effect = MODULE.Failure(128+signum, 'interrupted')
                with patch.object(MODULE.subprocess, 'Popen', return_value=process), \
                     patch.object(MODULE, 'stop_owned_process') as stop, \
                     self.assertRaises(MODULE.Failure) as failure:
                    runner.command(['fake'], 900)
                self.assertEqual(failure.exception.code, 128+signum)
                stop.assert_called_once_with(process)

    def test_probe_error_still_sends_kill_and_remains_failure(self):
        process = Mock(pid=54321)
        with patch.object(MODULE.os, 'killpg') as kill, \
             patch.object(MODULE, 'group_has_live_members', side_effect=MODULE.Failure(1, 'probe')), \
             self.assertRaises(MODULE.Failure):
            MODULE.stop_owned_process(process)
        self.assertEqual([c.args for c in kill.call_args_list],
                         [(54321, signal.SIGTERM), (54321, signal.SIGKILL)])

    def test_live_group_after_kill_is_not_pass(self):
        process = Mock(pid=54321)
        output = io.StringIO()
        with patch.object(MODULE.os, 'killpg'), \
             patch.object(MODULE, 'group_has_live_members', return_value=True), \
             patch.object(MODULE.time, 'monotonic', side_effect=[0,6,6,12]), \
             contextlib.redirect_stdout(output), \
             self.assertRaises(MODULE.Failure):
            MODULE.stop_owned_process(process)
        process.wait.assert_not_called()
        event = json.loads(output.getvalue().strip().removeprefix('DIAGNOSTIC: '))
        self.assertEqual(event, dict(operation='ownedGroupVerification', ownedPgid=54321,
                                    reason='liveMembersAfterKill'))

    def test_zombie_group_and_foreign_group_are_quiescent(self):
        result = Mock(returncode=0, stdout='54321 Z\n123 S\n')
        with patch.object(MODULE.subprocess, 'run', return_value=result):
            self.assertFalse(MODULE.group_has_live_members(54321))

    def test_shell_entrypoint_exec_routes_standalone_and_borrowed_arguments(self):
        script = Path(__file__).with_name('test-ios-shell-smoke.sh')
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            executable = directory/'python3'
            executable.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$CMC_TEST_SMOKE_ARGS"\n')
            executable.chmod(0o700)
            output = directory/'args'
            environment = dict(os.environ, PATH=str(directory)+os.pathsep+os.environ['PATH'],
                               CMC_TEST_SMOKE_ARGS=str(output))
            for arguments in ([], ['--device', DEVICE],
                              ['--device', DEVICE, '--receipt', str(directory/'receipt.json')]):
                result = subprocess.run(['bash',str(script)]+arguments,env=environment,
                                        capture_output=True,text=True,timeout=2)
                self.assertEqual(result.returncode,0,result.stderr)
                expected = [str(script.with_name('run-task054-ios-owned.py')), 'smoke']+arguments
                self.assertEqual(output.read_text().splitlines(),expected)
            output.unlink()
            result = subprocess.run(['bash',str(script),'--ios'],env=environment,
                                    capture_output=True,text=True,timeout=2)
            self.assertEqual(result.returncode,2)
            self.assertFalse(output.exists())

    def test_normal_command_exit_still_stops_real_orphan_descendant(self):
        with tempfile.TemporaryDirectory() as directory:
            ready=Path(directory)/'child.pid'
            child=('import os,signal,time; from pathlib import Path; '
                   'signal.signal(signal.SIGTERM, signal.SIG_IGN); '
                   f'Path({str(ready)!r}).write_text(str(os.getpid())); time.sleep(60)')
            leader=('import subprocess,sys,time; from pathlib import Path; '
                    f'subprocess.Popen([sys.executable,"-c",{child!r}]); '
                    f'p=Path({str(ready)!r}); '
                    'deadline=time.monotonic()+2\n'
                    'while not p.exists() and time.monotonic()<deadline: time.sleep(.01)\n')
            runner=MODULE.IosOwnedRunner()
            try:
                runner.command([sys.executable,'-c',leader],5)
                self.assertTrue(ready.exists())
                state=subprocess.run(['ps','-p',ready.read_text(),'-o','stat='],
                    capture_output=True,text=True,timeout=2).stdout.strip()
                self.assertTrue(not state or state.startswith('Z'),state)
                self.assertFalse(runner.process_cleanup_failed)
            finally:
                if ready.exists():
                    try: os.kill(int(ready.read_text()),signal.SIGKILL)
                    except ProcessLookupError: pass

    def test_real_leader_exit_does_not_leave_term_ignoring_child(self):
        with tempfile.TemporaryDirectory() as directory:
            ready = Path(directory)/'child.pid'
            child = ('import os,signal,time; from pathlib import Path; '
                     'signal.signal(signal.SIGTERM, signal.SIG_IGN); '
                     f'Path({str(ready)!r}).write_text(str(os.getpid())); time.sleep(60)')
            leader = ('import subprocess,sys,time; '
                      f'subprocess.Popen([sys.executable,"-c",{child!r}]); time.sleep(60)')
            process = subprocess.Popen([sys.executable,'-c',leader],start_new_session=True,
                stdin=subprocess.DEVNULL,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
            try:
                deadline=time.monotonic()+3
                while not ready.exists() and time.monotonic()<deadline: time.sleep(.01)
                self.assertTrue(ready.exists())
                MODULE.stop_owned_process(process)
                state=subprocess.run(['ps','-p',ready.read_text(),'-o','stat='],
                    capture_output=True,text=True,timeout=2).stdout.strip()
                self.assertTrue(not state or state.startswith('Z'),state)
            finally:
                try: os.killpg(process.pid,signal.SIGKILL)
                except ProcessLookupError: pass
                process.wait(timeout=2)

    def test_real_signal_during_term_wait_defers_repeats_until_owned_group_quiescent(self):
        for primary_code, first_signal in ((0, signal.SIGTERM), (0, signal.SIGINT),
                                           (7, signal.SIGTERM), (7, signal.SIGINT)):
            with self.subTest(primary_code=primary_code, first_signal=first_signal), \
                 tempfile.TemporaryDirectory() as directory:
                ready = Path(directory)/'child.pid'
                child = ('import os,signal,time; from pathlib import Path; '
                         'signal.signal(signal.SIGTERM, signal.SIG_IGN); '
                         f'Path({str(ready)!r}).write_text(str(os.getpid())); time.sleep(60)')
                leader = ('import subprocess,sys,time; from pathlib import Path; '
                          f'subprocess.Popen([sys.executable,"-c",{child!r}]); '
                          f'p=Path({str(ready)!r}); deadline=time.monotonic()+2\n'
                          'while not p.exists() and time.monotonic()<deadline: time.sleep(.01)\n'
                          f'raise SystemExit({primary_code})')
                runner = MODULE.IosOwnedRunner()
                previous = {sig: signal.getsignal(sig) for sig in (signal.SIGTERM, signal.SIGINT)}
                real_killpg = os.killpg
                def kill_and_interrupt(group, signum):
                    real_killpg(group, signum)
                    if signum == signal.SIGTERM:
                        os.kill(os.getpid(), first_signal)
                        repeated_signal = signal.SIGINT if first_signal == signal.SIGTERM else signal.SIGTERM
                        os.kill(os.getpid(), repeated_signal)
                try:
                    for sig in previous: signal.signal(sig, runner.interrupted)
                    with patch.object(MODULE.os, 'killpg', side_effect=kill_and_interrupt), \
                         self.assertRaises(MODULE.Failure) as failure:
                        runner.command([sys.executable, '-c', leader], 5)
                    self.assertEqual(failure.exception.code, primary_code or 128+first_signal)
                    self.assertEqual(runner.process_cleanup_signal, first_signal)
                    self.assertFalse(runner.process_cleanup_failed)
                    state = subprocess.run(['ps', '-p', ready.read_text(), '-o', 'stat='],
                        capture_output=True, text=True, timeout=2).stdout.strip()
                    self.assertTrue(not state or state.startswith('Z'), state)
                finally:
                    for sig, handler in previous.items(): signal.signal(sig, handler)
                    if ready.exists():
                        try: os.kill(int(ready.read_text()), signal.SIGKILL)
                        except ProcessLookupError: pass

    def test_real_command_timeout_and_signal_close_own_child_group(self):
        for reason in ('timeout','TERM','INT'):
            with self.subTest(reason=reason), tempfile.TemporaryDirectory() as directory:
                ready=Path(directory)/'child.pid'
                child=('import os,signal,time; from pathlib import Path; '
                       'signal.signal(signal.SIGTERM, signal.SIG_IGN); '
                       f'Path({str(ready)!r}).write_text(str(os.getpid())); time.sleep(60)')
                leader=('import subprocess,sys,time; '
                        f'subprocess.Popen([sys.executable,"-c",{child!r}]); time.sleep(60)')
                if reason!='timeout':
                    signum=signal.SIGTERM if reason=='TERM' else signal.SIGINT
                    leader=('import os,signal,subprocess,sys,time; '
                            f'subprocess.Popen([sys.executable,"-c",{child!r}]); '
                            f'time.sleep(.3); os.kill(os.getppid(),{int(signum)}); time.sleep(60)')
                runner=MODULE.IosOwnedRunner()
                previous={sig:signal.getsignal(sig) for sig in (signal.SIGTERM,signal.SIGINT)}
                try:
                    for sig in previous: signal.signal(sig,runner.interrupted)
                    with self.assertRaises(MODULE.Failure) as failure:
                        runner.command([sys.executable,'-c',leader],.5 if reason=='timeout' else 5)
                    self.assertEqual(failure.exception.code,124 if reason=='timeout' else 128+signum)
                    self.assertTrue(ready.exists())
                    state=subprocess.run(['ps','-p',ready.read_text(),'-o','stat='],
                        capture_output=True,text=True,timeout=2).stdout.strip()
                    self.assertTrue(not state or state.startswith('Z'),state)
                    self.assertFalse(runner.process_cleanup_failed)
                finally:
                    for sig,handler in previous.items(): signal.signal(sig,handler)
                    if ready.exists():
                        try: os.kill(int(ready.read_text()),signal.SIGKILL)
                        except ProcessLookupError: pass


if __name__ == '__main__':
    unittest.main()
