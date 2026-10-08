#!/usr/bin/env python3
"""Regressioni del runner iOS: nessuna build o risorsa Simulator."""
import importlib.util
import json
import signal
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch

SPEC = importlib.util.spec_from_file_location('journal_ios',
    Path(__file__).with_name('run-address-journal-ios.py'))
M = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(M)


class IosJournalTest(unittest.TestCase):
    def runner(self, directory):
        runner = M.IosJournalRunner(directory, Path(directory) / 'owner.json')
        runner.serial = '11111111-1111-4111-8111-111111111111'
        runner.executable = Path(directory) / 'Runner.app/Runner'
        return runner

    def test_owner_rejects_wrong_context_before_any_device_operation(self):
        runner = self.runner('/fixture')
        with patch.object(runner.owner, 'load', side_effect=M.IOS.Failure(2, 'context')), \
             patch.object(runner.owner, 'check_device') as device:
            with self.assertRaises(M.IOS.Failure):
                runner.check_owner()
        device.assert_not_called()

    def test_owner_rejects_unready_previously_cleaned_or_failed_processes(self):
        for change in ({'ready': False}, {'cleanup': 'PASS'}, {'processCleanupFailed': True}):
            runner = self.runner('/fixture')
            runner.owner.record = {'device': runner.serial, 'ready': True, 'cleanup': 'NOT_RUN', **change}
            with patch.object(runner.owner, 'load'), patch.object(runner.owner, 'check_device') as device:
                with self.assertRaises(M.Failure):
                    runner.check_owner()
            device.assert_not_called()

    def test_no_terminate_when_pid_executable_is_not_the_owned_app(self):
        runner = self.runner('/fixture')
        with patch.object(runner, 'check_owner'), \
             patch.object(runner, 'command', return_value=(0, '/foreign/Runner')), \
             patch.object(runner, 'simctl') as simctl:
            with self.assertRaises(M.Failure):
                runner.stop_seed(123)
        simctl.assert_not_called()

    def test_terminate_requires_owned_device_and_checks_seed_is_gone(self):
        runner = self.runner('/fixture')
        sequence = []
        with patch.object(runner, 'check_owner', side_effect=lambda: sequence.append('owner')), \
             patch.object(runner, 'attest_pid', side_effect=lambda pid: sequence.append(('pid', pid))), \
             patch.object(runner, 'simctl', side_effect=lambda args: sequence.append(args)), \
             patch.object(runner, 'command', return_value=(1, '')):
            runner.stop_seed(123)
        self.assertEqual(sequence, ['owner', ('pid', 123),
            ['terminate', runner.serial, M.ANDROID.PACKAGE]])
        self.assertEqual(runner.results['seed_terminated'], 'PASS')

    def test_terminate_timeout_does_not_claim_seed_gone(self):
        runner = self.runner('/fixture')
        with patch.object(runner, 'check_owner'), patch.object(runner, 'attest_pid'), \
             patch.object(runner, 'simctl'), patch.object(M.time, 'monotonic', side_effect=[0, 11]):
            with self.assertRaises(M.Failure) as failure:
                runner.stop_seed(123)
        self.assertEqual(failure.exception.code, 124)
        self.assertNotIn('seed_terminated', runner.results)

    def test_vm_uri_timeout_is_bounded_and_never_disables_auth(self):
        runner = self.runner('/fixture')
        with patch.object(M.time, 'monotonic', side_effect=[0, 31]):
            with self.assertRaises(M.Failure) as failure:
                runner.service_uri(123, [])
        self.assertEqual(failure.exception.code, 124)

    def test_vm_uri_is_read_from_private_phase_log_only(self):
        with tempfile.TemporaryDirectory() as directory:
            runner = self.runner(directory)
            path = Path(directory) / 'seed.stderr'
            path.write_text('The Dart VM service is listening on http://127.0.0.1:1234/fixture=/\n')
            stdout = Path(directory) / 'seed.stdout'
            stdout.touch()
            with patch.object(runner, 'attest_pid') as attest:
                uri = runner.service_uri(123, [stdout, path])
            self.assertEqual(uri, 'http://127.0.0.1:1234/fixture=/')
            attest.assert_called_once_with(123)

    def test_ambiguous_vm_uris_fail(self):
        with tempfile.TemporaryDirectory() as directory:
            runner = self.runner(directory)
            path = Path(directory) / 'stderr'
            path.write_text('http://127.0.0.1:1234/a=/\nhttp://127.0.0.1:1235/b=/')
            stdout = Path(directory) / 'stdout'
            stdout.touch()
            with patch.object(runner, 'attest_pid'), self.assertRaises(M.Failure):
                runner.service_uri(123, [stdout, path])

    def test_launch_limits_app_to_owned_udid_and_private_logs(self):
        with tempfile.TemporaryDirectory() as directory:
            runner = self.runner(directory)
            runner.private = Path(directory)
            with patch.object(runner, 'check_owner'), patch.object(runner, 'attest_pid'), \
                 patch.object(runner, 'simctl', return_value=(0, M.ANDROID.PACKAGE + ': 123')) as simctl:
                pid, logs = runner.launch('seed')
            self.assertEqual(pid, 123)
            args = simctl.call_args.args[0]
            self.assertEqual(args[3:5], [runner.serial, M.ANDROID.PACKAGE])
            self.assertNotIn('--disable-service-auth-codes', args)
            for path in logs:
                self.assertEqual(path.stat().st_mode & 0o777, 0o600)

    def execute_fixture(self, *, changed_identity=False, reused_pid=False, seed_fail=False):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        runner = self.runner(directory.name)
        identity = {'bundle_sha256': 'digest', 'binary_sha256': 'binary', 'containers_sha256': 'containers'}
        identities = [identity, dict(identity, containers_sha256='changed') if changed_identity else identity, identity]
        calls = []
        def drive(phase, *args):
            calls.append(('drive', phase))
            if phase == 'seed' and seed_fail:
                raise M.Failure('seed', 7, 'fixture')
        def command(args, *rest, **kwargs):
            calls.append(('command', args))
            return (0, '{}' if args[0] == 'plutil' else 'a' * 40)
        with patch.object(runner, 'check_owner'), patch.object(runner, 'command', side_effect=command), \
             patch.object(runner, 'simctl', side_effect=lambda args, *rest, **kwargs:
                 calls.append(('simctl', args)) or (1 if args[0] == 'get_app_container' else 0, '')), \
             patch.object(runner, 'identity', side_effect=identities), \
             patch.object(M, 'bundle_digest', return_value='digest'), \
             patch.object(runner, 'launch', side_effect=[(123, []), (123 if reused_pid else 456, [])]), \
             patch.object(runner, 'drive', side_effect=drive), \
             patch.object(runner, 'stop_seed', side_effect=lambda pid: calls.append(('stop', pid))):
            try:
                runner.execute()
                failure = None
            except M.Failure as error:
                failure = error
            finally:
                if runner.private:
                    M.shutil.rmtree(runner.private)
        return calls, failure

    def test_one_build_install_then_two_processes_without_clear(self):
        calls, failure = self.execute_fixture()
        self.assertIsNone(failure)
        self.assertEqual(len([c for k, c in calls if k == 'command' and c[:2] == ['flutter', 'build']]), 1)
        self.assertEqual(len([c for k, c in calls if k == 'simctl' and c[0] == 'install']), 1)
        self.assertEqual([c for c in calls if c[0] in ('drive', 'stop')],
            [('drive', 'seed'), ('stop', 123), ('drive', 'recover')])
        self.assertFalse(any('erase' in c or 'uninstall' in c for k, c in calls if k == 'simctl'))

    def test_changed_container_reused_pid_and_failed_seed_block_recover(self):
        for option in ('changed_identity', 'reused_pid', 'seed_fail'):
            with self.subTest(option=option):
                calls, failure = self.execute_fixture(**{option: True})
                self.assertIsNotNone(failure)
                self.assertNotIn(('drive', 'recover'), calls)

    def test_signal_driver_exit_is_normalized_before_receipt_read(self):
        for code, expected in [(-9, 137), (-15, 143), (7, 7)]:
            runner = self.runner('/fixture')
            with patch.object(runner, 'service_uri', return_value='http://127.0.0.1:1234/a=/'), \
                 patch.object(runner, 'log_metadata'), \
                 patch.object(runner, 'command', return_value=(code, 'private vm output')):
                with self.assertRaises(M.Failure) as failure:
                    runner.drive('seed', 123, 123, [])
            self.assertEqual(failure.exception.code, expected)
            self.assertEqual(runner.results, {})

    def test_preexisting_output_is_never_modified(self):
        with tempfile.TemporaryDirectory() as directory:
            runner = self.runner(directory)
            runner.output.mkdir(parents=True)
            marker = runner.output / 'foreign.json'
            marker.write_text('preserve')
            with patch.object(runner, 'check_owner'), patch.object(runner, 'command', return_value=(0, 'a' * 40)):
                self.assertEqual(runner.run(), 2)
            self.assertEqual(list(runner.output.iterdir()), [marker])
            self.assertEqual(marker.read_text(), 'preserve')

    def test_primary_failure_survives_private_log_cleanup_failure_and_persists_process_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            runner = self.runner(directory)
            runner.output.mkdir(parents=True)
            runner.owns_output = True
            runner.private = Path(directory) / 'private'
            runner.private.mkdir()
            runner.cleanup_failed = True
            runner.owner.record = {}
            with patch.object(runner, 'execute', side_effect=M.Failure('seed', 7, 'fixture')), \
                 patch.object(M.shutil, 'rmtree', side_effect=OSError), \
                 patch.object(runner.owner, 'persist') as persist:
                self.assertEqual(runner.run(), 7)
            persist.assert_called_once()
            receipt = json.loads((runner.output / 'runner.json').read_text())
            self.assertEqual(receipt['private_log_cleanup'], 'FAIL')
            self.assertEqual(receipt['process_cleanup'], 'FAIL')
            self.assertEqual(receipt['simulator_cleanup'], 'NOT_RUN')
            self.assertNotEqual(receipt['restart'], 'PASS')

    def test_incomplete_execution_cannot_claim_pass(self):
        with tempfile.TemporaryDirectory() as directory:
            runner = self.runner(directory)
            with patch.object(runner, 'execute'):
                self.assertEqual(runner.run(), 1)

    def test_bundle_digest_detects_content_change(self):
        with tempfile.TemporaryDirectory() as directory:
            bundle = Path(directory)
            file = bundle / 'Runner'
            file.write_bytes(b'before')
            before = M.bundle_digest(bundle)
            file.write_bytes(b'after')
            self.assertNotEqual(M.bundle_digest(bundle), before)

    def test_inventory_failure_never_authorizes_install(self):
        for code in (137, 143, 2):
            with self.subTest(code=code), tempfile.TemporaryDirectory() as directory:
                runner = self.runner(directory)
                def inventory(args, *rest, **kwargs):
                    self.assertEqual(args[0], 'listapps')
                    raise M.Failure('inventory', code, 'fixture')
                with patch.object(runner, 'check_owner'), \
                     patch.object(runner, 'command', return_value=(0, 'a' * 40)), \
                     patch.object(runner, 'simctl', side_effect=inventory) as simctl:
                    self.assertEqual(runner.run(), code)
                self.assertEqual(simctl.call_count, 1)

    def test_invalid_or_present_inventory_never_authorizes_install(self):
        for inventory in ('[]', 'invalid', json.dumps({M.ANDROID.PACKAGE: {}})):
            with self.subTest(inventory=inventory), tempfile.TemporaryDirectory() as directory:
                runner = self.runner(directory)
                with patch.object(runner, 'check_owner'), \
                     patch.object(runner, 'command', side_effect=[(0, 'a' * 40), (0, ''), (0, inventory)]), \
                     patch.object(runner, 'simctl', return_value=(0, 'plist')) as simctl:
                    self.assertNotEqual(runner.run(), 0)
                self.assertEqual([call.args[0][0] for call in simctl.call_args_list], ['listapps'])

    def test_owner_inventory_signal_uses_the_same_robust_command_cleanup(self):
        runner = self.runner('/fixture')
        child = Mock(pid=54321, returncode=0)
        child.communicate.return_value = ('{}', None)
        handlers = {sig: signal.getsignal(sig) for sig in (signal.SIGTERM, signal.SIGINT)}
        cleanup_calls = []
        def interrupted_cleanup(process, *args, **kwargs):
            cleanup_calls.append(process.pid)
            if len(cleanup_calls) == 1:
                M.ANDROID.OWNED.interrupted(signal.SIGTERM, None)
            process._cmc_owned_group_drained = True
        try:
            with patch.object(M.ANDROID.OWNED.subprocess, 'Popen', return_value=child), \
                 patch.object(M.ANDROID.OWNED, 'stop_owned_process', side_effect=interrupted_cleanup), \
                 patch.object(M.ANDROID.OWNED, '_stop_owned_group', side_effect=interrupted_cleanup):
                with self.assertRaises(M.Failure) as failure:
                    runner.owner.command(['owned-fixture'], 1, capture=True)
            self.assertEqual(failure.exception.code, 143)
            self.assertEqual(cleanup_calls, [54321, 54321])
            self.assertTrue(child._cmc_owned_group_drained)
        finally:
            for sig, handler in handlers.items():
                signal.signal(sig, handler)

    def test_diagnostics_never_publish_vm_uri_or_raw_stderr(self):
        with tempfile.TemporaryDirectory() as directory:
            runner = self.runner(directory)
            runner.current_probe = 'seed'
            stdout, stderr = [Path(directory) / name for name in ('stdout', 'stderr')]
            stdout.write_text('http://127.0.0.1:1234/private-token=/')
            stderr.write_text('Unhandled Exception: PlatformException private-payload')
            runner.log_metadata([stdout, stderr])
            encoded = json.dumps(runner.diagnostics)
            self.assertNotIn('private-token', encoded)
            self.assertNotIn('private-payload', encoded)
            self.assertEqual(runner.diagnostics['seed']['vm_uri'], 'found')
            self.assertEqual(runner.diagnostics['seed']['crash_cause'], 'NOT_CONFIRMED')

    def test_unreadable_diagnostics_and_cleanup_failure_preserve_driver_exit(self):
        for code, expected in [(7, 7), (-9, 137), (-15, 143)]:
            with self.subTest(code=code), tempfile.TemporaryDirectory() as directory:
                runner = self.runner(directory)
                runner.output.mkdir(parents=True)
                runner.owns_output = True
                runner.private = Path(directory) / 'private'
                runner.private.mkdir()
                with patch.object(runner, 'service_uri', return_value='http://127.0.0.1:1234/a=/'), \
                     patch.object(runner, 'command', return_value=(code, 'private output')), \
                     patch.object(runner, 'log_metadata', side_effect=OSError), \
                     patch.object(runner, 'execute', side_effect=lambda: runner.drive('seed', 123, 123, [])), \
                     patch.object(M.shutil, 'rmtree', side_effect=OSError):
                    self.assertEqual(runner.run(), expected)
                receipt = json.loads((runner.output / 'runner.json').read_text())
                self.assertEqual(receipt['exit_code'], expected)
                self.assertEqual(receipt['diagnostics']['seed']['log_metadata'], 'unavailable')
                self.assertEqual(receipt['private_log_cleanup'], 'FAIL')


if __name__ == '__main__':
    unittest.main()
