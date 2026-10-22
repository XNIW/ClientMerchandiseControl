#!/usr/bin/env python3
"""Cold profile host tests: SDK commands fully mocked, filesystem synthetic."""
import contextlib
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import plistlib
import re
import signal
import subprocess
import tempfile
import unittest
from types import SimpleNamespace
from unittest.mock import patch

ROOT = Path(__file__).parent
SPEC = importlib.util.spec_from_file_location('canonical_cold_profile', ROOT / 'run-ios-preflight-measured.py')
M = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(M)
DEVICE = '11111111-1111-4111-8111-111111111111'
RUNTIME = 'com.apple.CoreSimulator.SimRuntime.iOS-26-5'
DEVELOPER = '/Applications/Xcode_26.6.app/Contents/Developer'


class Fixture:
    def __init__(self, directory, failure=None, cleanup_failure=False):
        self.output = Path(directory) / 'cold'
        self.devices = Path(directory) / 'Devices'
        self.calls = []
        self.exists = False
        self.booted = False
        self.failure = failure
        self.failure_code = 124
        self.cleanup_type_error = False
        self.cleanup_failure = cleanup_failure
        self.xcode = 'Xcode 26.6\nBuild version 17F113'
        self.sdk = '26.5'
        self.catalog = {'runtimes': [{'identifier': RUNTIME, 'version': '26.5',
            'buildversion': 'synthetic26F', 'isAvailable': True,
            'privateMetadata': 'private-fixture-do-not-publish'}]}
        self.environment = dict(zip(M.IOS.OWNER_CONTEXT, ('123', '1', 'cold', 'a' * 40)))
        self.environment.update(DEVELOPER_DIR=DEVELOPER, ImageOS='macos26',
                                ImageVersion='20260907.0351.1')

    def command(self, owner, args, timeout, capture=False):
        self.calls.append((args, timeout))
        if args == ['xcodebuild', '-version']:
            return self.xcode
        if args == ['xcrun', '--sdk', 'iphonesimulator', '--show-sdk-version']:
            return self.sdk
        assert args[:2] == ['xcrun', 'simctl'], args
        action = args[2]
        if action == self.failure:
            raise M.IOS.Failure(self.failure_code, 'synthetic timeout')
        if args == ['xcrun', 'simctl', 'list', 'runtimes', '--json']:
            if self.failure == 'runtimes':
                raise M.IOS.Failure(124, 'synthetic runtime timeout')
            return json.dumps(self.catalog)
        if action == 'create':
            self.exists = True
            file = self.devices / DEVICE / 'device.plist'
            file.parent.mkdir(parents=True)
            file.write_bytes(plistlib.dumps({'UDID': DEVICE, 'name': owner.record['name'],
                'runtime': RUNTIME, 'deviceType': M.IOS.OWNED_DEVICE_TYPE, 'state': 3}))
            return DEVICE
        if args == ['xcrun', 'simctl', 'list', 'devices', '--json']:
            rows = [{'udid': DEVICE, 'name': owner.record['name'],
                     'isAvailable': True, 'state': 'Booted' if self.booted else 'Shutdown'}] if self.exists else []
            return json.dumps({'devices': {RUNTIME: rows}})
        if action == 'boot':
            self.booted = True
        elif action == 'spawn':
            assert args == ['xcrun', 'simctl', 'spawn', DEVICE, 'launchctl', 'list'], args
            return 'private-launchctl-fixture-do-not-publish'
        elif action == 'shutdown':
            self.booted = False
        elif action == 'delete':
            if self.cleanup_type_error:
                raise TypeError('synthetic cleanup malformed response')
            if self.cleanup_failure:
                raise M.IOS.Failure(7, 'synthetic cleanup failure')
            self.exists = False
        return ''

    def execute(self):
        actual_read = M.IOS.owned_descriptor_observation
        def command(owner, args, timeout, capture=False):
            return self.command(owner, args, timeout, capture)
        with patch.object(M.IOS.IosOwnedRunner, 'command', command), \
             patch.object(M.Path, 'is_dir', return_value=True), \
             patch.object(M.signal, 'signal'), \
             patch.dict(os.environ, self.environment, clear=True), \
             patch.object(M.IOS, 'owned_descriptor_observation',
                side_effect=lambda record: actual_read(record, self.devices)), \
             contextlib.redirect_stdout(io.StringIO()):
            return M.main(['--profile', 'canonical', '--output', str(self.output)])

    def result(self):
        return json.loads((self.output / 'result.json').read_text())


class CanonicalColdTest(unittest.TestCase):
    def test_26_6_toolchain_accepts_actual_26_5_runtime_and_preserves_recipe(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            self.assertEqual(fixture.execute(), 0)
            result = fixture.result()
            owner = json.loads((fixture.output / 'owner.json').read_text())
            self.assertEqual(result['app'], 'NOT_RUN')
            self.assertEqual(result['preflight'], 'PASS')
            self.assertEqual(result['selectedRuntimeVersion'], '26.5')
            self.assertEqual(result['toolchain']['simulator_sdk'], '26.5')
            self.assertEqual(result['toolchain']['xcode_version'], 'Xcode 26.6\nBuild version 17F113')
            self.assertEqual(result['catalog']['commandCount'], 1)
            self.assertEqual(result['catalog']['runtimesType'], 'list')
            self.assertEqual(result['cleanup'], 'PASS')
            self.assertEqual(owner['launchMode'], 'headless')
            self.assertEqual(owner['readinessMethod'], M.IOS.OWNED_DESCRIPTOR)
            self.assertEqual(owner['readinessAttestation']['kind'], 'owned-descriptor-launchd.v2')
            commands = [args for args, _ in fixture.calls]
            inventory = ['xcrun', 'simctl', 'list', 'runtimes', '--json']
            self.assertEqual(commands.count(inventory), 1)
            self.assertEqual(commands[2], inventory)
            self.assertFalse(any('help' in args or args[0] in ('flutter', 'open') for args in commands))
            create = next(i for i, args in enumerate(commands) if args[:3] == ['xcrun', 'simctl', 'create'])
            first_devices = commands.index(['xcrun', 'simctl', 'list', 'devices', '--json'])
            self.assertGreater(first_devices, create)
            self.assertIn((['xcrun', 'simctl', 'bootstatus', DEVICE, '-b'], 300), fixture.calls)
            self.assertIn((inventory, 30), fixture.calls)
            self.assertNotIn('private-fixture', json.dumps(result))
            self.assertNotIn('private-launchctl', json.dumps(result))
            events = [json.loads(line) for line in (fixture.output / 'processes.jsonl').read_text().splitlines()]
            self.assertTrue(events)

    def test_runtime_inventory_timeout_stops_before_create_and_cleanup_passes(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory, failure='runtimes')
            self.assertEqual(fixture.execute(), 124)
            self.assertEqual(fixture.result()['cleanup'], 'PASS')
            self.assertEqual(fixture.result()['catalog']['result'], 'FAIL')
            self.assertFalse(any(args[:3] == ['xcrun', 'simctl', 'create'] for args, _ in fixture.calls))
            owner = json.loads((fixture.output / 'owner.json').read_text())
            self.assertFalse(owner['creationStarted'])
            self.assertIsNone(owner['device'])

    def test_bootstatus_timeout_keeps_primary_and_cleans_only_owned_device(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory, failure='bootstatus')
            self.assertEqual(fixture.execute(), 124)
            result = fixture.result()
            self.assertEqual(result['cleanup'], 'PASS')
            self.assertFalse(result['bootstatusCompleted'])
            self.assertEqual(result['selectedRuntimeVersion'], '26.5')
            self.assertFalse(any(args[:3] == ['xcrun', 'simctl', 'spawn'] for args, _ in fixture.calls))
            for args, _ in fixture.calls:
                if args[:3] in (['xcrun', 'simctl', 'shutdown'], ['xcrun', 'simctl', 'delete']):
                    self.assertEqual(args[3], DEVICE)

    def test_primary_124_is_not_replaced_by_cleanup_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory, failure='bootstatus', cleanup_failure=True)
            self.assertEqual(fixture.execute(), 124)
            self.assertEqual(fixture.result()['cleanup'], 'FAIL')
            self.assertEqual(fixture.result()['exit_code'], 124)

    def test_signal_failure_primary_is_preserved_with_cleanup_type_error(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory, failure='bootstatus')
            fixture.failure_code = 143
            fixture.cleanup_type_error = True
            self.assertEqual(fixture.execute(), 143)
            self.assertEqual(fixture.result()['cleanup'], 'FAIL')
            self.assertEqual(fixture.result()['cleanup_error_type'], 'TypeError')
            self.assertEqual(fixture.result()['exit_code'], 143)

    def test_wrong_toolchain_fails_closed_before_simctl(self):
        for invalid in ('developer', 'xcode', 'sdk26.4', 'sdk26.6'):
            with self.subTest(invalid=invalid), tempfile.TemporaryDirectory() as directory:
                fixture = Fixture(directory)
                if invalid == 'developer':
                    fixture.environment['DEVELOPER_DIR'] = '/Applications/Xcode_26.5.app/Contents/Developer'
                elif invalid == 'xcode':
                    fixture.xcode = 'Xcode 26.5'
                elif invalid == 'sdk26.4':
                    fixture.sdk = '26.4'
                else:
                    fixture.sdk = '26.6'
                self.assertEqual(fixture.execute(), 2)
                self.assertEqual(fixture.result()['preflight'], 'FAIL')
                self.assertFalse(any(args[:2] == ['xcrun', 'simctl'] for args, _ in fixture.calls))
                self.assertFalse((fixture.output / 'owner.json').exists())

    def test_bad_catalog_shape_is_observed_without_an_extra_query(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Fixture(directory)
            fixture.catalog = {'runtimes': {'bad': 'shape'}}
            self.assertEqual(fixture.execute(), 2)
            self.assertEqual(fixture.result()['catalog']['commandCount'], 1)
            self.assertEqual(fixture.result()['catalog']['runtimesType'], 'dict')
            self.assertEqual(fixture.result()['preflight'], 'FAIL')
            self.assertEqual(fixture.result()['cleanup'], 'PASS')

    def test_canonical_rejects_keep_ready_before_creating_output(self):
        with tempfile.TemporaryDirectory() as directory, contextlib.redirect_stderr(io.StringIO()):
            output = Path(directory) / 'unused'
            with self.assertRaises(SystemExit) as caught:
                M.main(['--profile', 'canonical', '--keep-ready', '--output', str(output)])
            self.assertEqual(caught.exception.code, 2)
            self.assertFalse(output.exists())

    def test_workflow_canonical_is_preflight_only_and_has_no_native_or_flutter_steps(self):
        workflow_file = ROOT.parent / '.github/workflows/task054-ios-measured.yml'
        if not workflow_file.is_file():
            workflow_file = ROOT / 'task054-ios-measured.yml'
        workflow = workflow_file.read_text()
        job_condition = re.search(r'^    if: (.+)$', workflow, re.M).group(1)
        def evaluate(expression, mode):
            return eval(expression.replace('&&', ' and ').replace('||', ' or '),
                {'__builtins__': {}}, {'inputs': SimpleNamespace(surface='canonical', mode=mode)})
        self.assertTrue(evaluate(job_condition, 'preflight'))
        self.assertTrue(evaluate(job_condition, 'runtime-query'))
        for mode in ('native', 'review', 'matrix', 'journal'):
            self.assertFalse(evaluate(job_condition, mode))
        for block in re.split(r'^      - name:', workflow, flags=re.M)[1:]:
            title = block.splitlines()[0]
            if title.strip() == 'Cold canonical owned preflight without Flutter or app':
                continue
            if title.strip() in ('Minimal owned preflight', 'Prepare alternative installed iOS surface headless', 'Set up Flutter', 'Validate Flutter toolchain and dependencies') or 'app' in title or 'Simulator' in title and 'cold' not in title.lower():
                conditional = re.search(r'^        if: (.+)$', block, re.M)
                if conditional and 'always()' not in conditional.group(1):
                    self.assertFalse(evaluate(conditional.group(1), 'preflight'), title)


class RuntimeQueryTest(unittest.TestCase):
    QUERY = ['xcrun', 'simctl', 'list', 'runtimes', '--json']

    def execute(self, output, failure=None, trace_failure=False, trace_content=None):
        self.calls, self.signals = [], []
        payload = '{"runtimes": [], "SECRET_CATALOG": "PRIVATE_PATH"}'
        current = self

        class FakePopen:
            def __init__(self, arguments, **kwargs):
                current.calls.append(('spawn', arguments, kwargs))
                self.pid, self.returncode = 321, None
                self.stdin = self.stderr = None
                self.stdout = io.StringIO(payload)

            def communicate(self, timeout=None):
                current.calls.append(('communicate', timeout))
                if failure in ('timeout', 'cleanup'):
                    raise subprocess.TimeoutExpired('SECRET_ARGV', timeout,
                                                    output=b'SECRET_PARTIAL{')
                if failure == 'signal':
                    raise M.IOS.Failure(143, 'SECRET_SIGNAL')
                self.returncode = 7 if failure == 'exit' else 0
                self.stdout.close()
                return payload, None

            def poll(self):
                current.calls.append(('poll',))
                return self.returncode

            def wait(self, timeout=None):
                current.calls.append(('wait', timeout))
                self.returncode = -15
                return self.returncode

        original_trace = M.TRACE.trace_processes

        @contextlib.contextmanager
        def measured(path):
            if trace_failure == 'enter':
                raise OSError('SECRET_TRACE_ENTER')
            with original_trace(path) as emit:
                yield emit
            if trace_content is not None:
                Path(path).write_bytes(trace_content)
            if trace_failure:
                raise OSError('SECRET_TRACE_FAILURE')

        def killpg(group, sig):
            self.signals.append((group, sig))
            if failure == 'cleanup' and sig == signal.SIGKILL:
                raise PermissionError(1, 'SECRET_EPERM')

        handlers = {sig: M.signal.getsignal(sig) for sig in (signal.SIGINT, signal.SIGTERM)}
        with patch.object(subprocess, 'Popen', FakePopen), \
             patch.object(M.IOS, 'group_has_live_members',
                side_effect=PermissionError(1, 'SECRET_PROBE') if failure == 'cleanup' else None,
                return_value=False), \
             patch.object(os, 'getpgid', return_value=321), \
             patch.object(os, 'killpg', side_effect=killpg), \
             patch.object(M.TRACE, 'trace_processes', measured), \
             patch.object(M.Path, 'is_dir', return_value=True), \
             patch.dict(os.environ, {'DEVELOPER_DIR': DEVELOPER}, clear=True), \
             patch.object(M.IOS.IosOwnedRunner, 'prepare', side_effect=AssertionError('prepare')), \
             patch.object(M.IOS.IosOwnedRunner, 'cleanup', side_effect=AssertionError('cleanup')), \
             contextlib.redirect_stdout(io.StringIO()):
            original_popen, original_killpg = subprocess.Popen, os.killpg
            code = M.main(['--profile', 'runtime-query', '--output', str(output)])
            self.assertIs(subprocess.Popen, original_popen)
            self.assertIs(os.killpg, original_killpg)
        for sig, handler in handlers.items():
            self.assertIs(M.signal.getsignal(sig), handler)
        result_path = output / 'result.json'
        return code, json.loads(result_path.read_text()) if result_path.exists() else None

    def test_success_stops_after_one_query_and_retains_only_private_metadata(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / 'query'
            code, result = self.execute(output)
            self.assertEqual(code, 0)
            self.assertEqual(result['query'], 'PASS')
            self.assertEqual(result['commandCount'], 1)
            self.assertEqual(result['trace'], 'PASS')
            self.assertEqual(result['traceRetention'], 'PASS')
            self.assertTrue(result['stdoutComplete'])
            self.assertEqual(result['stdout']['json'], 'valid')
            self.assertEqual(result['resourceCleanup'], 'NOT_RUN')
            self.assertFalse(result['resourceCreated'])
            self.assertEqual(result['stderr'], 'inherited_not_captured')
            self.assertEqual(sorted(p.name for p in output.iterdir()),
                             ['processes.jsonl', 'result.json'])
            self.assertEqual(output.stat().st_mode & 0o777, 0o700)
            for path in output.iterdir():
                self.assertEqual(path.stat().st_mode & 0o777, 0o600)
                self.assertNotIn('SECRET', path.read_text())
                self.assertNotIn('PRIVATE_PATH', path.read_text())
            self.assertLessEqual((output / 'result.json').stat().st_size, 4096)
            self.assertEqual([entry for entry in self.calls if entry[0] == 'spawn'],
                [('spawn', self.QUERY, {'start_new_session': True,
                  'stdout': subprocess.PIPE, 'text': True})])
            self.assertEqual([entry for entry in self.calls if entry[0] == 'communicate'],
                             [('communicate', 30)])
            self.assertEqual(self.signals, [])

    def test_timeout_preserves_124_partial_hash_stop_wait_and_unknown_eof(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / 'query'
            code, result = self.execute(output, failure='timeout')
            self.assertEqual(code, 124)
            self.assertEqual(result['query'], 'FAIL')
            self.assertIsNone(result['stdoutComplete'])
            self.assertEqual(result['stdout']['sha256'],
                             hashlib.sha256(b'SECRET_PARTIAL{').hexdigest())
            self.assertEqual(self.signals, [(321, signal.SIGTERM)])
            self.assertIn(('wait', 2), self.calls)
            rows = [json.loads(line) for line in (output / 'processes.jsonl').read_text().splitlines()]
            timeout = next(row for row in rows if row['event'] == 'communicate-timeout')
            self.assertEqual(timeout['timeout_seconds'], 30)
            self.assertTrue(timeout['observer_poll_may_reap'])
            self.assertFalse(timeout['output_complete'])
            self.assertTrue(any(row.get('reaped') for row in rows))
            self.assertNotIn('SECRET', (output / 'processes.jsonl').read_text())
            self.assertEqual(sum(entry[0] == 'spawn' for entry in self.calls), 1)
            self.assertEqual(sum(entry[0] == 'communicate' for entry in self.calls), 1)

    def test_nonzero_signal_and_cleanup_error_keep_primary_and_do_not_retry(self):
        for failure, expected in (('exit', 7), ('signal', 143), ('cleanup', 124)):
            with self.subTest(failure=failure), tempfile.TemporaryDirectory() as directory:
                output = Path(directory) / 'query'
                code, result = self.execute(output, failure=failure)
                self.assertEqual(code, expected)
                self.assertEqual(result['exit_code'], expected)
                self.assertEqual(result['query'], 'FAIL')
                self.assertEqual(result['processCleanupFailed'], failure == 'cleanup')
                self.assertEqual(sum(entry[0] == 'spawn' for entry in self.calls), 1)
                self.assertEqual(sum(entry[0] == 'communicate' for entry in self.calls), 1)
                self.assertNotIn('SECRET', (output / 'result.json').read_text())
                if failure == 'cleanup':
                    self.assertEqual(self.signals, [(321, signal.SIGTERM), (321, signal.SIGKILL)])

    def test_trace_exit_failure_keeps_query_primary_or_marks_incomplete_diagnostic(self):
        for failure, expected in ((None, 2), ('timeout', 124)):
            with self.subTest(failure=failure), tempfile.TemporaryDirectory() as directory:
                code, result = self.execute(Path(directory) / 'query', failure=failure,
                                            trace_failure=True)
                self.assertEqual(code, expected)
                self.assertEqual(result['trace'], 'FAIL')
                self.assertEqual(result['query'], 'PASS' if failure is None else 'FAIL')

    def test_trace_enter_failure_does_not_run_query(self):
        with tempfile.TemporaryDirectory() as directory:
            code, result = self.execute(Path(directory) / 'query', trace_failure='enter')
            self.assertEqual(code, 2)
            self.assertEqual(result['commandCount'], 0)
            self.assertEqual(result['query'], 'NOT_RUN')
            self.assertEqual(result['trace'], 'FAIL')
            self.assertEqual(self.calls, [])

    def test_result_write_failure_preserves_primary(self):
        actual_open = os.open
        def deny_result(path, flags, mode=0o777):
            if Path(path).name == 'result.json':
                raise PermissionError(1, 'SECRET_RESULT_WRITE')
            return actual_open(path, flags, mode)
        for failure, expected in ((None, 2), ('timeout', 124)):
            with self.subTest(failure=failure), tempfile.TemporaryDirectory() as directory, \
                 patch.object(os, 'open', side_effect=deny_result):
                output = Path(directory) / 'query'
                code, result = self.execute(output, failure=failure)
                self.assertEqual(code, expected)
                self.assertIsNone(result)
                self.assertFalse((output / 'result.json').exists())

    def test_trace_write_failure_preserves_primary(self):
        @contextlib.contextmanager
        def broken_stream(path):
            class Stream:
                def write(self, _):
                    raise OSError('SECRET_TRACE_WRITE')
            yield Stream()
        for failure, expected in ((None, 2), ('timeout', 124)):
            with self.subTest(failure=failure), tempfile.TemporaryDirectory() as directory, \
                 patch.object(M.TRACE, 'exclusive_trace_stream', broken_stream):
                code, result = self.execute(Path(directory) / 'query', failure=failure)
                self.assertEqual(code, expected)
                self.assertEqual(result['trace'], 'FAIL')
                self.assertEqual(result['query'], 'PASS' if failure is None else 'FAIL')

    def test_trace_retention_read_failure_preserves_primary(self):
        actual_open = Path.open
        def deny_trace(path, mode='r', *args, **kwargs):
            if path.name == 'processes-pending.local' and mode == 'rb':
                raise OSError('SECRET_TRACE_READ')
            return actual_open(path, mode, *args, **kwargs)
        with tempfile.TemporaryDirectory() as directory, patch.object(Path, 'open', deny_trace):
            code, result = self.execute(Path(directory) / 'query', failure='timeout')
            self.assertEqual(code, 124)
            self.assertEqual(result['traceRetention'], 'FAIL')

    def test_trace_retention_caps_preserve_local_file_and_primary(self):
        for content in (b'x' * 2097153, b'{}\n' * 2049):
            with self.subTest(size=len(content)), tempfile.TemporaryDirectory() as directory:
                output = Path(directory) / 'query'
                code, result = self.execute(output, failure='timeout', trace_content=content)
                self.assertEqual(code, 124)
                self.assertEqual(result['traceRetention'], 'FAIL')
                self.assertFalse((output / 'processes.jsonl').exists())
                self.assertEqual((output / 'processes-retention-blocked.local').read_bytes(), content)

    def test_existing_output_keep_ready_and_wrong_surface_never_invoke_query(self):
        with tempfile.TemporaryDirectory() as directory, \
             patch.object(M.IOS.IosOwnedRunner, 'command') as command, \
             contextlib.redirect_stderr(io.StringIO()):
            existing = Path(directory) / 'existing'
            existing.mkdir()
            sentinel = existing / 'result.json'
            sentinel.write_text('preserve')
            with self.assertRaises(FileExistsError):
                M.main(['--profile', 'runtime-query', '--output', str(existing)])
            self.assertEqual(sentinel.read_text(), 'preserve')
            unused = Path(directory) / 'unused'
            with self.assertRaises(SystemExit) as caught:
                M.main(['--profile', 'runtime-query', '--keep-ready', '--output', str(unused)])
            self.assertEqual(caught.exception.code, 2)
            self.assertFalse(unused.exists())
            with patch.dict(os.environ, {'DEVELOPER_DIR': 'SECRET_WRONG_SURFACE'}, clear=True):
                self.assertEqual(M.main(['--profile', 'runtime-query', '--output', str(unused)]), 2)
            result = json.loads((unused / 'result.json').read_text())
            self.assertEqual(result['commandCount'], 0)
            self.assertEqual(result['query'], 'NOT_RUN')
            self.assertEqual(result['trace'], 'NOT_RUN')
            self.assertNotIn('SECRET', json.dumps(result))
            command.assert_not_called()

    def test_workflow_routes_exact_steps_and_preserves_all_legacy_combinations(self):
        workflow = (ROOT.parent / '.github/workflows/task054-ios-measured.yml').read_text()
        blocks = re.split(r'^      - name:', workflow, flags=re.M)[1:]
        conditions = {block.splitlines()[0].strip():
            re.search(r'^        if: (.+)$', block, re.M) for block in blocks}
        job = re.search(r'^    if: (.+)$', workflow, re.M).group(1)
        def evaluate(expression, mode, surface):
            return eval(expression.replace('&&', ' and ').replace('||', ' or '),
                {'__builtins__': {}}, {'inputs': SimpleNamespace(surface=surface, mode=mode),
                                      'always': lambda: True})
        base = {'Checkout exact candidate', 'Validate measured transport',
                'Save measurements and native receipts', 'Create separate iOS PNG previews',
                'Save separate iOS PNG previews'}
        for mode in ('preflight', 'native', 'review', 'matrix', 'journal', 'runtime-query'):
            for surface in ('historical', 'compatible', 'canonical'):
                with self.subTest(mode=mode, surface=surface):
                    actual = {title for title, match in conditions.items() if
                        match is None or evaluate(match.group(1), mode, surface)} if evaluate(
                            job, mode, surface) else set()
                    expected = set(base)
                    if mode == 'runtime-query':
                        expected = {'Checkout exact candidate', 'Observe one canonical HOST runtime query',
                                    'Save HOST query metadata only'} if surface == 'canonical' else set()
                    elif surface == 'canonical':
                        expected = expected | {'Cold canonical owned preflight without Flutter or app'} \
                            if mode == 'preflight' else set()
                    else:
                        expected.add('Minimal owned preflight' if surface == 'historical' else
                                     'Prepare alternative installed iOS surface headless')
                        if surface == 'compatible' or mode != 'preflight':
                            expected.add('Final owned cleanup')
                        if mode != 'preflight':
                            expected.update(('Set up Flutter', 'Validate Flutter toolchain and dependencies'))
                        if mode in ('native', 'review'):
                            expected.update(('Critical review alone on the same owned Simulator',
                                             'Review after the two preceding inbox cases'))
                            if surface == 'compatible':
                                expected.update(('Build compatible iOS Simulator app before critical review',
                                    'Validate compatible iOS bundle security',
                                    'Smoke compatible app before critical review'))
                        if mode in ('native', 'journal'):
                            expected.add('Existing journal runner on the same owned Simulator')
                        if mode in ('native', 'matrix'):
                            expected.update(('Build normal iOS Simulator app for matrix',
                                'Validate normal iOS bundle security', 'Smoke normal app before matrix',
                                'Capture full fixture matrix after smoke'))
                    self.assertEqual(actual, expected)
        upload = next(block for block in blocks if block.startswith(' Save HOST query metadata only\n'))
        paths = re.search(r'          path: \|\n(.*?)          retention-days:', upload, re.S).group(1)
        self.assertEqual(paths.split(), ['build/task054/ios-runtime-query/result.json',
                                       'build/task054/ios-runtime-query/processes.jsonl'])
        self.assertIn('retention-days: 7', upload)


if __name__ == '__main__':
    unittest.main()
