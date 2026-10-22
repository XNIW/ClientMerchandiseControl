#!/usr/bin/env python3
"""Ordine, budget e APK immutabile della fixture; nessun SDK/device reale."""
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch


spec = importlib.util.spec_from_file_location('android_visual_prebuilt',
    Path(__file__).with_name('run-task054-android-visual.py'))
M = importlib.util.module_from_spec(spec)
spec.loader.exec_module(M)
SHELL = (Path(__file__).with_name('test-task054-visual.sh')).read_text().split(
    "<<'PYCODE'\n", 1)[1].rsplit('\nPYCODE', 1)[0]


class VisualPrebuiltTest(unittest.TestCase):
    def test_build_failure_does_not_allocate_emulator_or_run_drive(self):
        with tempfile.TemporaryDirectory() as directory:
            runner = M.AndroidVisualRunner(directory)
            with patch.object(runner, 'preflight_visual_host'), \
                 patch.object(runner, 'command', side_effect=M.Failure('build', 124, 'timeout')), \
                 patch.object(runner, 'prepare_device') as prepare:
                with self.assertRaises(M.Failure) as error:
                    runner.execute()
            self.assertEqual(error.exception.code, 124)
            prepare.assert_not_called()
            self.assertIsNone(runner.emulator)
            self.assertFalse(runner.build_before_emulator)

    def test_build_then_boot_then_prebuilt_drive_and_installed_apk_identity(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            runner = M.AndroidVisualRunner(root)
            runner.serial = 'emulator-owned'
            visual = root / 'visual'
            visual.mkdir()
            runner.environment['CMC_VISUAL_OUTPUT_DIR'] = str(visual)
            digest = hashlib.sha256(b'fixture apk').hexdigest()
            sequence = []
            def command(arguments, timeout, **kwargs):
                if arguments[:2] == ['bash', 'scripts/build-task054-android-visual.sh']:
                    self.assertEqual(timeout, 600)
                    self.assertIsNone(runner.emulator)
                    sequence.append('build')
                    source = root / 'build/app/outputs/flutter-apk/app-debug.apk'
                    source.parent.mkdir(parents=True)
                    source.write_bytes(b'fixture apk')
                    return (0, '')
                if arguments[:2] == ['bash', 'scripts/test-task054-visual.sh']:
                    sequence.append('drive')
                    self.assertEqual(runner.environment['CMC_TASK054_VISUAL_TIMEOUT_SECONDS'], '890')
                    self.assertEqual(runner.environment['CMC_TASK054_VISUAL_APK_SHA256'], digest)
                    for index in range(137):
                        (visual / f'{index}.png').touch()
                    return (0, '')
                if arguments[3:8] == ['shell', 'cmd', 'package', 'list', 'packages']:
                    return (0, 'package:com.xniw.clientmerchandisecontrol uid:10123')
                if arguments[3:6] == ['shell', 'pm', 'path']:
                    return (0, 'package:/data/app/owned/base.apk')
                if arguments[3:5] == ['shell', 'sha256sum']:
                    return (0, digest + '  /data/app/owned/base.apk')
                self.fail(f'Comando inatteso: {arguments}')
            def prepare():
                sequence.append('boot')
                self.assertEqual(runner.fixture_digest(), digest)
                return Path('/owned/adb')
            with patch.object(runner, 'preflight_visual_host'), \
                 patch.object(runner, 'command', side_effect=command), \
                 patch.object(runner, 'prepare_device', side_effect=prepare), \
                 patch.object(M.time, 'monotonic', side_effect=[0, 10]):
                runner.execute()
            self.assertEqual(sequence, ['build', 'boot', 'drive'])
            self.assertEqual(runner.capture_count, 137)
            self.assertEqual(runner.installed_fixture, {'uid': 10123, 'apk_sha256': digest})
            self.assertTrue(runner.build_before_emulator)

    def test_existing_fixture_is_preserved_before_build_and_device_allocation(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / 'build/task054/android-visual-fixture/app-debug.apk'
            target.parent.mkdir(parents=True)
            target.write_bytes(b'prior evidence')
            runner = M.AndroidVisualRunner(root)
            with patch.object(runner, 'preflight_visual_host'), \
                 patch.object(runner, 'command') as command, \
                 patch.object(runner, 'prepare_device') as prepare:
                with self.assertRaises(M.Failure):
                    runner.execute()
            command.assert_not_called()
            prepare.assert_not_called()
            self.assertEqual(target.read_bytes(), b'prior evidence')

    def test_mutated_frozen_or_installed_apk_cannot_qualify_fixture(self):
        for mutation in ('frozen', 'installed'):
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                runner = M.AndroidVisualRunner(root)
                runner.serial, runner.fixture_apk = 'emulator-owned', root / 'fixture.apk'
                runner.fixture_apk.write_bytes(b'changed' if mutation == 'frozen' else b'original')
                runner.fixture_apk_sha256 = hashlib.sha256(b'original').hexdigest()
                with patch.object(runner, 'command', side_effect=[
                        (0, 'package:com.xniw.clientmerchandisecontrol uid:10123'),
                        (0, 'package:/data/app/owned/base.apk'), (0, '0' * 64 + ' apk')]):
                    with self.assertRaises(M.Failure):
                        runner.attest_fixture_installed(Path('/owned/adb'))
                self.assertIsNone(runner.installed_fixture)

    def shell(self, root, environment, exit_code=0, timeout=False, on_complete=None):
        commands, waits = [], []
        cleanup = SimpleNamespace(stop_owned_process=lambda *args, **kwargs: None,
            finish_owned_cleanup_after_error=lambda child, error, **kwargs: error)
        def popen(arguments, **kwargs):
            commands.append(arguments)
            child = Mock(pid=12345)
            def wait(timeout):
                waits.append(timeout)
                if timeout_mode:
                    raise subprocess.TimeoutExpired(arguments, timeout)
                if on_complete is not None:
                    on_complete(arguments)
                return exit_code
            child.wait.side_effect = wait
            return child
        timeout_mode = timeout
        with patch('sys.argv', ['runner', '--device', 'emulator-owned']), \
             patch('os.environ', {'CMC_TASK054_SCRIPTS_DIR': str(Path(__file__).parent), **environment}), \
             patch('importlib.util.spec_from_file_location', return_value=Mock()), \
             patch('importlib.util.module_from_spec', return_value=cleanup), \
             patch('subprocess.Popen', side_effect=popen), \
             patch('pathlib.Path.cwd', return_value=root), patch('signal.signal'):
            try:
                exec(compile(SHELL, 'test-task054-visual.sh', 'exec'), {})
                code = 0
            except SystemExit as error:
                code = error.code
        return code, commands, waits

    def context(self, root):
        binary = root / 'build/task054/android-visual-fixture/app-debug.apk'
        binary.parent.mkdir(parents=True)
        binary.write_bytes(b'fixture')
        return {'CMC_OS_FRAME_PLATFORM': 'android', 'CMC_OS_FRAME_DEVICE': 'emulator-owned',
            'CMC_TASK054_VISUAL_APK': str(binary),
            'CMC_TASK054_VISUAL_APK_SHA256': hashlib.sha256(b'fixture').hexdigest(),
            'CMC_TASK054_VISUAL_TIMEOUT_SECONDS': '725'}

    def test_drive_receives_same_prebuilt_apk_os_defines_and_remaining_budget(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            environment = self.context(root)
            code, commands, waits = self.shell(root, environment)
            self.assertEqual(code, 0)
            self.assertEqual(waits, [725])
            self.assertEqual(len(commands), 1)
            self.assertIn('--use-application-binary=' +
                str(Path(environment['CMC_TASK054_VISUAL_APK']).resolve()), commands[0])
            self.assertIn('--keep-app-running', commands[0])
            self.assertIn('--dart-define=CMC_OS_FRAME_CAPTURE=true', commands[0])
            self.assertIn('--target=integration_test/task054_visual_flow_test.dart', commands[0])

    def test_default_drive_uninstalls_but_prebuilt_retains_package_for_attestation(self):
        # Primary pinned058 behavior: keep defaults true only for use-existing-app.
        # Simulate SDK completion, then the package read required by attestation.
        for prebuilt in (False, True):
            with self.subTest(prebuilt=prebuilt), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                environment = self.context(root) if prebuilt else {}
                installed = {'present': True}
                def sdk_complete(command):
                    if '--keep-app-running' in command:
                        keep = True
                    elif '--no-keep-app-running' in command:
                        keep = False
                    else:
                        keep = any(value.startswith('--use-existing-app=') for value in command)
                    if not keep:
                        installed['present'] = False
                code, commands, _ = self.shell(root, environment, on_complete=sdk_complete)
                self.assertEqual(code, 0)
                self.assertEqual(len(commands), 1)
                if prebuilt:
                    self.assertTrue(installed['present'], 'APK deve restare per la receipt post-drive')
                    self.assertIn('--keep-app-running', commands[0])
                else:
                    self.assertFalse(installed['present'], 'Controllo: il default SDK disinstalla')
                    self.assertNotIn('--keep-app-running', commands[0])

    def test_changed_digest_bad_context_or_budget_cannot_start_drive(self):
        for key, value in [('CMC_TASK054_VISUAL_APK_SHA256', '0' * 64),
                ('CMC_TASK054_VISUAL_TIMEOUT_SECONDS', '901'),
                ('CMC_TASK054_VISUAL_TIMEOUT_SECONDS', '0'),
                ('CMC_OS_FRAME_PLATFORM', 'ios'),
                ('CMC_TASK054_VISUAL_SELECTION', 'review')]:
            with self.subTest(key=key), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                environment = self.context(root)
                environment[key] = value
                code, commands, _ = self.shell(root, environment)
                self.assertNotEqual(code, 0)
                self.assertEqual(commands, [])

    def test_prebuilt_drive_preserves_primary_exit_and_timeout(self):
        for timeout, primary, expected in [(False, 7, 7), (True, 0, 124)]:
            with self.subTest(timeout=timeout), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                code, commands, waits = self.shell(root, self.context(root), primary, timeout)
                self.assertEqual(code, expected)
                self.assertEqual(waits, [725])
                self.assertEqual(len(commands), 1)


if __name__ == '__main__':
    unittest.main()
