#!/usr/bin/env python3
"""Parser, isolamento e budget diagnostico con sole fixture/mocks Python."""
import importlib.util
from pathlib import Path
from types import SimpleNamespace
import tempfile
import unittest
from unittest.mock import Mock, patch

SPEC = importlib.util.spec_from_file_location('startup_diagnostics',
    Path(__file__).with_name('task054-android-startup-diagnostics.py'))
M = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(M)
P = M.PACKAGE


def line(tag, fields, pid=1080):
    return f'1792119103.005548  {pid}  1090 I {tag}: [{fields}]'


class StartupDiagnosticsTest(unittest.TestCase):
    def test_process_start_and_death_match_own_exact_process(self):
        rows, discarded = M.lifecycle_rows('\n'.join([
            line('am_proc_start', f'0,2398,10123,{P},activity,{P}/.MainActivity'),
            line('am_proc_died', f'0,2398,{P},0,2'),
            line('am_proc_start', f'0,3456,10124,{P}.foreign,activity,x'),
            line('am_proc_died', f'0,777,{P}:foreign,0,2'),
        ]))
        self.assertEqual([row['pid'] for row in rows], [2398, 2398])
        self.assertEqual(discarded, 2)
        self.assertNotIn('10123', str(rows))

    def test_activity_system_pid_is_not_confused_with_app_pid(self):
        rows, _ = M.lifecycle_rows('\n'.join([
            line('wm_create_activity', f'0,23895,3,{P}/.MainActivity,x'),
            line('wm_on_destroy_called', f'23895,{P}/.MainActivity,SECRET', pid=2398),
        ]))
        self.assertIsNone(rows[0]['pid'])
        self.assertEqual(rows[1]['pid'], 2398)
        self.assertNotIn('SECRET', str(rows))
        self.assertNotIn('23895', str(rows))

    def test_foreign_activity_and_payload_are_discarded(self):
        rows, discarded = M.lifecycle_rows('\n'.join([
            line('wm_on_create_called', f'10,foreign/.Activity,{P}', pid=777),
            line('unapproved_tag', f'0,2398,{P}'),
            line('am_proc_died', f'0,1,{P}evil,0,2'),
        ]))
        self.assertEqual(rows, [])
        self.assertEqual(discarded, 3)

    def test_row_and_line_bounds(self):
        own = line('am_proc_died', f'0,2398,{P},0,2')
        rows, _ = M.lifecycle_rows('\n'.join([own] * 300))
        self.assertEqual(len(rows), 256)
        rows, discarded = M.lifecycle_rows(own + 'x' * 9000)
        self.assertEqual(rows, [])
        self.assertEqual(discarded, 1)

    def runner(self, checksum=None):
        return SimpleNamespace(serial='emulator-owned', fixture_apk_sha256='a' * 64,
            installed_fixture=None, command=Mock(side_effect=[
                (0, line('am_proc_died', f'0,2398,{P},0,2')),
                (0, '2401'),
                (0, 'package:/data/app/owned/base.apk'),
                (0, (checksum or 'a' * 64) + '  /data/app/owned/base.apk')]))

    def test_queries_own_serial_filtered_package_and_hash_without_raw_storage(self):
        runner = self.runner()
        with patch.object(M.time, 'monotonic', side_effect=[10, 11, 12, 13]):
            receipt = M.collect(runner, '/owned/adb', 15)
        self.assertEqual(receipt['status'], 'PASS')
        self.assertTrue(receipt['installed_snapshot']['matches_expected'])
        self.assertIsNone(runner.installed_fixture)
        calls = runner.command.call_args_list
        self.assertEqual(len(calls), 4)
        self.assertEqual(receipt['post_driver_package_pids'], [2401])
        self.assertTrue(all(call.args[0][:3] == ['/owned/adb', '-s', 'emulator-owned'] for call in calls))
        self.assertTrue(all(0 < call.args[1] <= 3 for call in calls))
        self.assertIn('-e', calls[0].args[0])
        self.assertIn('com\\.xniw\\.clientmerchandisecontrol', calls[0].args[0][calls[0].args[0].index('-e') + 1])
        self.assertNotIn('/data/app', str(receipt))

    def test_mismatched_hash_is_observation_not_acceptance_pass(self):
        runner = self.runner(checksum='b' * 64)
        with patch.object(M.time, 'monotonic', return_value=10):
            receipt = M.collect(runner, '/owned/adb', 15)
        self.assertFalse(receipt['installed_snapshot']['matches_expected'])
        self.assertIsNone(runner.installed_fixture)

    def test_original_budget_exhaustion_never_runs_adb(self):
        runner = self.runner()
        with patch.object(M.time, 'monotonic', return_value=15):
            receipt = M.collect(runner, '/owned/adb', 15)
        self.assertEqual(receipt['status'], 'NOT_RUN')
        self.assertEqual(receipt['error_type'], 'TimeoutError')
        runner.command.assert_not_called()

    def test_adb_timeout_failure_is_sanitized_and_not_raised_over_driver_failure(self):
        runner = self.runner()
        runner.command.side_effect = Exception('SECRET arbitrary output')
        with patch.object(M.time, 'monotonic', return_value=10):
            receipt = M.collect(runner, '/owned/adb', 15)
        self.assertEqual(receipt['status'], 'FAIL')
        self.assertNotIn('SECRET', str(receipt))

    def test_missing_or_split_install_path_is_never_used(self):
        runner = self.runner()
        runner.command.side_effect = [(0, ''), (0, ''), (0, 'package:/data/app/a/base.apk\npackage:/data/app/a/split.apk')]
        with patch.object(M.time, 'monotonic', return_value=10):
            receipt = M.collect(runner, '/owned/adb', 15)
        self.assertIsNone(receipt['installed_snapshot'])
        self.assertEqual(runner.command.call_count, 3)


    def test_full_activity_class_is_owned_and_name_is_not_persisted(self):
        rows, discarded = M.lifecycle_rows(line('wm_on_resume_called',
            f'2395,{P}.MainActivity,SECRET', pid=2398))
        self.assertEqual(discarded, 0)
        self.assertEqual(rows[0]['pid'], 2398)
        self.assertNotIn('SECRET', str(rows))

    def test_driver_primary_failure_survives_post_driver_diagnostic_failure(self):
        spec = importlib.util.spec_from_file_location('observed_runner',
            Path(__file__).with_name('run-task054-android-visual.py'))
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as directory:
            runner = module.AndroidVisualRunner(directory)
            runner.serial = 'emulator-owned'
            runner.fixture_apk_sha256 = 'a' * 64
            runner.environment.update(CMC_VISUAL_OUTPUT_DIR=directory,
                CMC_TASK054_VISUAL_TIMEOUT_SECONDS='900',
                CMC_TASK054_ANDROID_STARTUP_OBSERVER='true')
            primary = module.Failure('native-fixture-capture', 19, 'original driver failure')
            with patch.object(runner, 'preflight_visual_host'), \
                 patch.object(runner, 'build_fixture_binary'), \
                 patch.object(runner, 'prepare_device', return_value='/owned/adb'), \
                 patch.object(runner, 'command', side_effect=[primary, RuntimeError('SECRET')]), \
                 patch.object(module.time, 'monotonic', return_value=10):
                with self.assertRaises(module.Failure) as observed:
                    runner.execute()
            self.assertIs(observed.exception, primary)
            self.assertEqual(runner.startup_diagnostics['status'], 'FAIL')
            self.assertIsNone(runner.installed_fixture)
            self.assertNotIn('SECRET', str(runner.startup_diagnostics))


if __name__ == '__main__':
    unittest.main()
