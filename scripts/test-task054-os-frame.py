#!/usr/bin/env python3
"""Regressioni del bridge OS con Popen simulati: nessun device viene controllato."""
from contextlib import redirect_stdout, redirect_stderr
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import signal
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location('cmc_os_frame',
    Path(__file__).with_name('capture-task054-os-frame.py'))
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)

REVISION = b'a' * 40 + b'\n'
PNG = MODULE.PNG_SIGNATURE + b'synthetic-frame-bytes'
PRIVATE = b'PRIVATE_OWNER_AND_TEXT_MUST_NEVER_BE_WRITTEN'
UUID = '12345678-1234-4234-8234-123456789abc'


class OSFrameTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix='cmc-os-frame-test-')
        self.root = Path(self.directory.name).resolve()
        self.adb = self.root / 'sdk/platform-tools/adb'
        self.adb.parent.mkdir(parents=True)
        self.adb.write_text('fake; never executed\n')
        self.adb.chmod(0o700)
        self.environment = {'ANDROID_HOME': str(self.root / 'sdk')}
        self.stdout = io.StringIO()
        self.stderr = io.StringIO()
        self.commands = []
        self.children = []
        self.cleanup = []

    def tearDown(self):
        self.directory.cleanup()

    def execute(self, platform='android', device=None, name='01-review-comment-focus',
                git=0, screen=0, probe=0, dump=None, frame=PNG,
                failure_phase=None, failure=None, cleanup_failure=None,
                environment=None, before_screen=None, cleanup_signal=None,
                revision=REVISION):
        capture = MODULE.OSFrameCapture(self.root, name, platform,
            device or ('emulator-5554' if platform == 'android' else UUID),
            self.environment if environment is None else environment)
        test = self

        class Child:
            def __init__(self, arguments, **kwargs):
                test.commands.append((arguments, kwargs))
                test.children.append(self)
                self.arguments = arguments
                self.pid = 8000 + len(test.children)
                self.phase = 'git' if arguments[0] == 'git' else (
                    'probe' if arguments[-1] == 'input_method' else 'screen')
                self.returncode = {'git': git, 'screen': screen, 'probe': probe}[self.phase]

            def communicate(self, **kwargs):
                expected_timeout = {'git': 5, 'screen': 10, 'probe': 5}[self.phase]
                test.assertEqual(kwargs, {'timeout': expected_timeout})
                if self.phase == failure_phase:
                    raise failure
                if self.phase == 'git':
                    return revision, None
                if self.phase == 'probe':
                    return (dump if dump is not None else
                            PRIVATE + b'\n  mInputShown=true mIsInputViewShown=true\n'), None
                if before_screen:
                    before_screen(capture)
                if platform == 'ios':
                    Path(self.arguments[-1]).write_bytes(frame)
                    return PRIVATE, None
                return frame, None

        def stop(child):
            self.cleanup.append(child)
            if child.phase == cleanup_signal:
                raise MODULE.Failure('signal', 143)
            if child.phase == cleanup_failure:
                raise MODULE._cleanup_module.Failure('cleanup-process', 1, 'private error')

        with patch.object(MODULE.subprocess, 'Popen', side_effect=Child), \
             patch.object(MODULE, 'stop_owned_process', side_effect=stop), \
             redirect_stdout(self.stdout), redirect_stderr(self.stderr):
            code = capture.run()
        self.assertNotIn(PRIVATE.decode(), self.stdout.getvalue() + self.stderr.getvalue())
        return code, capture

    def receipt(self, capture):
        contents = capture.receipt_path.read_text()
        self.assertNotIn(PRIVATE.decode(), contents)
        self.assertNotIn(capture.device, contents)
        self.assertNotIn(str(self.adb), contents)
        return json.loads(contents)

    def test_android_display_and_probe_use_only_explicit_serial(self):
        code, capture = self.execute()
        self.assertEqual(code, 0)
        self.assertEqual([c[0] for c in self.commands], [
            ['git', 'rev-parse', 'HEAD'],
            [str(self.adb), '-s', 'emulator-5554', 'exec-out', 'screencap', '-p'],
            [str(self.adb), '-s', 'emulator-5554', 'shell', 'dumpsys', 'input_method']])
        for _, kwargs in self.commands:
            self.assertEqual(kwargs['cwd'], self.root)
            self.assertTrue(kwargs['start_new_session'])
            self.assertFalse(kwargs['shell'])
            self.assertEqual(kwargs['stdin'], subprocess.DEVNULL)
            self.assertEqual(kwargs['stderr'], subprocess.DEVNULL)
            self.assertEqual(kwargs['stdout'], subprocess.PIPE)
        self.assertEqual(self.cleanup, self.children)
        result = self.receipt(capture)
        self.assertEqual(result['gitHead'], REVISION.strip().decode())
        self.assertEqual(result['source'], 'os_display')
        self.assertEqual(result['frame_status'], 'PASS')
        self.assertEqual(result['probe_status'], 'PASS')
        self.assertIs(result['mInputShown'], True)
        self.assertIs(result['mIsInputViewShown'], True)
        self.assertEqual(result['ime_acceptance'], 'NOT_RUN')
        self.assertEqual(result['frame_sha256'], hashlib.sha256(PNG).hexdigest())
        self.assertEqual(capture.image.read_bytes(), PNG)
        self.assertEqual(sorted(path.name for path in capture.output.iterdir()),
            [capture.name + '.json', capture.name + '.png'])

    def test_false_flags_are_observations_and_never_ime_acceptance(self):
        code, capture = self.execute(dump=b'mInputShown=false mIsInputViewShown=false')
        self.assertEqual(code, 0)
        result = self.receipt(capture)
        self.assertIs(result['mInputShown'], False)
        self.assertIs(result['mIsInputViewShown'], False)
        self.assertEqual(result['ime_acceptance'], 'NOT_RUN')

    def test_ios_screen_grammar_without_android_probe_or_inference(self):
        code, capture = self.execute(platform='ios', environment={})
        self.assertEqual(code, 0)
        arguments = self.commands[1][0]
        self.assertEqual(arguments[:-1],
            ['xcrun', 'simctl', 'io', UUID, 'screenshot', '--type=png'])
        self.assertTrue(Path(arguments[-1]).is_relative_to(capture.output))
        self.assertFalse(Path(arguments[-1]).exists())
        self.assertEqual(len(self.commands), 2)
        self.assertEqual(self.cleanup, self.children)
        result = self.receipt(capture)
        self.assertEqual(result['frame_status'], 'PASS')
        self.assertEqual(result['probe_status'], 'NOT_RUN')
        self.assertIsNone(result['mInputShown'])
        self.assertIsNone(result['mIsInputViewShown'])
        self.assertEqual(result['ime_acceptance'], 'NOT_RUN')

    def test_precise_adb_override_precedes_android_home(self):
        other = self.root / 'authorized-adb'
        other.write_text('fake; never executed\n')
        other.chmod(0o700)
        code, _ = self.execute(environment={'CMC_OS_FRAME_ADB': str(other),
            'ANDROID_HOME': '/not-used'})
        self.assertEqual(code, 0)
        self.assertEqual(self.commands[1][0][0], str(other))

    def test_ios_nonzero_screen_and_empty_png_have_failure_receipts(self):
        for label, options, expected_code in (
                ('exit', {'screen': 6}, 6), ('empty', {'frame': b''}, 1)):
            with self.subTest(label=label):
                code, capture = self.execute(platform='ios', name=f'{label}-focus',
                    environment={}, **options)
                self.assertEqual(code, expected_code)
                result = self.receipt(capture)
                self.assertEqual(result['frame_status'], 'FAIL')
                self.assertEqual(result['probe_status'], 'NOT_RUN')
                self.assertIsNone(result['mInputShown'])
                self.assertEqual(sorted(path.name for path in capture.output.iterdir()),
                    sorted(path.name for path in capture.output.glob('*.json')))

    def test_invalid_names_devices_and_tool_paths_have_no_process_actions(self):
        cases = [
            {'name': '../focus'}, {'name': 'review-focus/other'},
            {'name': 'review\nfocus'}, {'name': 'review-focused'},
            {'name': 'review-focus-' + 'a' * 100}, {'name': '-focus'},
            {'device': 'emulator-5555'}, {'device': 'emulator-5552'},
            {'device': 'emulator-5684'}, {'device': 'emulator-05554'},
            {'device': 'phone-5554'}, {'device': 'emulator-5554;bad'},
            {'platform': 'ios', 'device': 'booted'},
            {'platform': 'ios', 'device': UUID + '/bad'},
            {'platform': 'ios', 'device': '12345678123442348234123456789abc'},
            {'environment': {'CMC_OS_FRAME_ADB': 'relative/adb'}},
            {'environment': {'CMC_OS_FRAME_ADB': '/missing-adb'}},
            {'environment': {'ANDROID_HOME': 'relative/sdk'}},
            {'environment': {}},
        ]
        for arguments in cases:
            with self.subTest(arguments=arguments):
                code, capture = self.execute(**arguments)
                self.assertEqual(code, 2)
                self.assertEqual(self.commands, [])
                self.assertFalse(capture.output.exists())
                self.assertEqual(self.cleanup, [])

    def test_serial_upper_bound_and_focus_token_are_accepted(self):
        code, _ = self.execute(device='emulator-5682', name='focus')
        self.assertEqual(code, 0)

    def test_symlink_output_directory_does_not_touch_foreign_directory(self):
        foreign = self.root / 'foreign'
        foreign.mkdir()
        output = self.root / 'build/task054/os-visual'
        output.parent.mkdir(parents=True)
        output.symlink_to(foreign, target_is_directory=True)
        code, _ = self.execute()
        self.assertEqual(code, 2)
        self.assertEqual(self.commands, [])
        self.assertEqual(list(foreign.iterdir()), [])

    def test_existing_frame_receipt_and_broken_symlink_are_never_overwritten(self):
        for kind in ('png', 'json', 'symlink'):
            with self.subTest(kind=kind):
                output = self.root / 'build/task054/os-visual'
                output.mkdir(parents=True, exist_ok=True)
                name = f'{kind}-focus'
                path = output / (name + ('.json' if kind == 'json' else '.png'))
                if kind == 'symlink':
                    path.symlink_to(self.root / 'foreign-not-present')
                else:
                    path.write_bytes(b'foreign')
                code, _ = self.execute(name=name)
                self.assertEqual(code, 2)
                self.assertEqual(self.commands, [])
                if kind == 'symlink':
                    self.assertTrue(path.is_symlink())
                else:
                    self.assertEqual(path.read_bytes(), b'foreign')

    def test_racing_frame_creation_is_not_overwritten(self):
        def race(capture):
            capture.image.write_bytes(b'foreign')
        code, capture = self.execute(before_screen=race)
        self.assertEqual(code, 1)
        self.assertEqual(capture.image.read_bytes(), b'foreign')
        result = self.receipt(capture)
        self.assertEqual(result['frame_status'], 'FAIL')
        self.assertEqual(result['probe_status'], 'NOT_RUN')
        self.assertIsNone(result['frame_sha256'])

    def test_missing_invalid_and_duplicate_booleans_fail_without_raw_dump(self):
        cases = [
            (b'', None, None),
            (PRIVATE + b' mInputShown=true', True, None),
            (b'mInputShown=null mIsInputViewShown=true', None, True),
            (b'mInputShown=truex mIsInputViewShown=false', None, False),
            (b'mInputShown=true mInputShown=true mIsInputViewShown=true', None, True),
            (b'mInputShown=true mIsInputViewShown=true mIsInputViewShown=false', True, None),
            (b'not_mInputShown=true mIsInputViewShown=true', None, True),
        ]
        for index, (dump, first, second) in enumerate(cases):
            with self.subTest(index=index):
                code, capture = self.execute(name=f'{index}-focus', dump=dump)
                self.assertEqual(code, 1)
                result = self.receipt(capture)
                self.assertEqual(result['frame_status'], 'PASS')
                self.assertEqual(result['probe_status'], 'FAIL')
                self.assertIs(result['mInputShown'], first)
                self.assertIs(result['mIsInputViewShown'], second)
                self.assertEqual(result['ime_acceptance'], 'NOT_RUN')

    def test_screen_failure_preserves_exit_and_does_not_run_probe(self):
        code, capture = self.execute(screen=7)
        self.assertEqual(code, 7)
        self.assertFalse(capture.image.exists())
        self.assertEqual(len(self.commands), 2)
        result = self.receipt(capture)
        self.assertEqual(result['exit_code'], 7)
        self.assertEqual(result['failed_phase'], 'screen')
        self.assertEqual(result['frame_status'], 'FAIL')
        self.assertEqual(result['probe_status'], 'NOT_RUN')

    def test_probe_failure_preserves_valid_frame_and_exit(self):
        code, capture = self.execute(probe=9)
        self.assertEqual(code, 9)
        self.assertEqual(capture.image.read_bytes(), PNG)
        result = self.receipt(capture)
        self.assertEqual(result['frame_status'], 'PASS')
        self.assertEqual(result['probe_status'], 'FAIL')
        self.assertIsNone(result['mInputShown'])
        self.assertEqual(result['exit_code'], 9)

    def test_empty_or_non_png_frame_produces_failure_receipt(self):
        for index, frame in enumerate((b'', MODULE.PNG_SIGNATURE, PRIVATE)):
            with self.subTest(index=index):
                code, capture = self.execute(name=f'{index}-focus', frame=frame)
                self.assertEqual(code, 1)
                self.assertFalse(capture.image.exists())
                self.assertEqual(self.receipt(capture)['frame_status'], 'FAIL')

    def test_git_failure_prevents_os_actions_and_has_nullable_revision(self):
        code, capture = self.execute(git=11)
        self.assertEqual(code, 11)
        self.assertEqual(len(self.commands), 1)
        result = self.receipt(capture)
        self.assertIsNone(result['gitHead'])
        self.assertEqual(result['frame_status'], 'NOT_RUN')
        self.assertEqual(result['probe_status'], 'NOT_RUN')

    def test_invalid_git_revision_stops_before_device_commands(self):
        code, capture = self.execute(revision=PRIVATE)
        self.assertEqual(code, 1)
        self.assertEqual(len(self.commands), 1)
        result = self.receipt(capture)
        self.assertIsNone(result['gitHead'])
        self.assertEqual(result['failed_phase'], 'git')

    def test_unexpected_command_error_is_sanitized_and_receipted(self):
        code, capture = self.execute(failure_phase='screen',
            failure=RuntimeError(PRIVATE.decode()))
        self.assertEqual(code, 1)
        self.assertEqual(self.receipt(capture)['frame_status'], 'FAIL')
        self.assertEqual(self.cleanup, self.children)

    def test_timeouts_cleanup_each_own_child_and_keep_primary_124(self):
        for phase in ('git', 'screen', 'probe'):
            with self.subTest(phase=phase):
                start = len(self.children)
                code, capture = self.execute(name=f'{phase}-focus',
                    failure_phase=phase,
                    failure=subprocess.TimeoutExpired(PRIVATE.decode(), 5,
                        output=PRIVATE, stderr=PRIVATE), cleanup_failure=phase)
                self.assertEqual(code, 124)
                self.assertEqual(self.cleanup[start:], self.children[start:])
                result = self.receipt(capture)
                self.assertEqual(result['exit_code'], 124)
                self.assertEqual(result['cleanup_status'], 'FAIL')
                self.assertEqual(result['failed_phase'], phase)

    def test_nonzero_command_wins_over_cleanup_probe_failure(self):
        code, capture = self.execute(screen=7, cleanup_failure='screen')
        self.assertEqual(code, 7)
        result = self.receipt(capture)
        self.assertEqual(result['cleanup_status'], 'FAIL')
        self.assertEqual(result['failed_phase'], 'screen')

    def test_cleanup_failure_fails_an_otherwise_successful_capture(self):
        code, capture = self.execute(cleanup_failure='probe')
        self.assertEqual(code, 1)
        result = self.receipt(capture)
        self.assertEqual(result['frame_status'], 'PASS')
        self.assertEqual(result['probe_status'], 'FAIL')
        self.assertEqual(result['failed_phase'], 'cleanup')

    def test_cleanup_failure_after_git_prevents_os_actions(self):
        code, capture = self.execute(cleanup_failure='git')
        self.assertEqual(code, 1)
        self.assertEqual(len(self.commands), 1)
        result = self.receipt(capture)
        self.assertEqual(result['frame_status'], 'NOT_RUN')
        self.assertEqual(result['failed_phase'], 'cleanup')

    def test_signal_during_cleanup_is_preserved_and_no_probe_is_started(self):
        code, capture = self.execute(cleanup_signal='screen')
        self.assertEqual(code, 143)
        self.assertEqual(len(self.commands), 2)
        result = self.receipt(capture)
        self.assertEqual(result['failed_phase'], 'signal')
        self.assertEqual(result['cleanup_status'], 'FAIL')

    def test_sigterm_and_sigint_preserve_primary_and_cleanup_owned_group(self):
        for signum in (signal.SIGTERM, signal.SIGINT):
            with self.subTest(signum=signum):
                code, capture = self.execute(name=f'{signum}-focus',
                    failure_phase='screen', failure=MODULE.Failure('signal', 128 + signum),
                    cleanup_failure='screen')
                self.assertEqual(code, 128 + signum)
                result = self.receipt(capture)
                self.assertEqual(result['failed_phase'], 'signal')
                self.assertEqual(result['cleanup_status'], 'FAIL')
                self.assertEqual(self.cleanup, self.children)

    def test_signal_handler_ignores_repeated_signals_only_after_primary(self):
        with patch.object(MODULE.signal, 'signal') as register:
            with self.assertRaises(MODULE.Failure) as caught:
                MODULE.interrupted(signal.SIGTERM, None)
        self.assertEqual(caught.exception.code, 143)
        self.assertEqual(register.call_args_list[0].args,
            (signal.SIGTERM, signal.SIG_IGN))
        self.assertEqual(register.call_args_list[1].args,
            (signal.SIGINT, signal.SIG_IGN))

    def test_argument_parser_does_not_repeat_supplied_identity(self):
        with redirect_stderr(self.stderr), self.assertRaises(SystemExit) as caught:
            MODULE.main(['--device', PRIVATE.decode(), '--platform', 'unexpected'])
        self.assertEqual(caught.exception.code, 2)
        self.assertNotIn(PRIVATE.decode(), self.stderr.getvalue())


if __name__ == '__main__':
    unittest.main()
