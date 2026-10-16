#!/usr/bin/env python3
"""Cold profile host tests: SDK commands fully mocked, filesystem synthetic."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import plistlib
import re
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
        self.xcode = 'Xcode 26.6\nBuild version synthetic'
        self.sdk = '26.6'
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
            self.assertEqual(result['toolchain']['simulator_sdk'], '26.6')
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
        for invalid in ('developer', 'xcode', 'sdk'):
            with self.subTest(invalid=invalid), tempfile.TemporaryDirectory() as directory:
                fixture = Fixture(directory)
                if invalid == 'developer':
                    fixture.environment['DEVELOPER_DIR'] = '/Applications/Xcode_26.5.app/Contents/Developer'
                elif invalid == 'xcode':
                    fixture.xcode = 'Xcode 26.5'
                else:
                    fixture.sdk = '26.5'
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


if __name__ == '__main__':
    unittest.main()
