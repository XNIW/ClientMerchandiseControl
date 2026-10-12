#!/usr/bin/env python3
"""Qualificazione descriptor/spawn: filesystem host reale, simctl soltanto mock."""
import importlib.util
import json
import os
from pathlib import Path
import plistlib
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('descriptor_qualification_base',
    Path(__file__).with_name('test-task054-ios-owned.py'))
BASE = importlib.util.module_from_spec(spec)
spec.loader.exec_module(BASE)
M = BASE.MODULE


class DescriptorFixture(BASE.Fixture):
    def __init__(self, directory):
        super().__init__(directory)
        self.devices_root = Path(directory) / 'Devices'
        self.descriptor = self.devices_root / BASE.DEVICE / 'device.plist'
        self.owner_environment = dict(zip(M.OWNER_CONTEXT,
            ('12345', '1', 'ios-guest-cart', 'a' * 40)))
        self.fields = {}
        self.spawn_failure = None
        self.spawn_callback = None
        self.cold_after_bootstatus = False
        self.observations = 0

    def write_descriptor(self, runner, atomic=False):
        payload = {'UDID': BASE.DEVICE, 'name': runner.record['name'],
                   'runtime': BASE.RUNTIME, 'deviceType': M.OWNED_DEVICE_TYPE,
                   'state': 3, 'lastBootedAt': 'synthetic'}
        payload.update(self.fields)
        self.descriptor.parent.mkdir(parents=True, exist_ok=True)
        target = self.descriptor.with_name('replace.plist') if atomic else self.descriptor
        target.write_bytes(plistlib.dumps(payload))
        if atomic:
            os.replace(target, self.descriptor)

    def command(self, runner, arguments, timeout, capture=False):
        if arguments[:3] == ['xcrun', 'simctl', 'spawn']:
            self.runner = runner
            self.calls.append((arguments, timeout))
            if arguments != ['xcrun', 'simctl', 'spawn', BASE.DEVICE, '/usr/bin/true']:
                raise AssertionError('Spawn fuori dal solo UUID/true proprio.')
            if not self.booted:
                raise M.Failure(1, 'spawn normale richiede Booted')
            if self.spawn_failure:
                raise self.spawn_failure
            if self.spawn_callback:
                self.spawn_callback(runner)
            return ''
        if (arguments[:4] == ['xcrun', 'simctl', 'list', 'devices'] and
                self.booted and runner.phase != 'cleanup'):
            self.calls.append((arguments, timeout))
            raise M.Failure(124, 'inventory postboot storico bloccato')
        output = super().command(runner, arguments, timeout, capture)
        if arguments[:3] == ['xcrun', 'simctl', 'create']:
            self.write_descriptor(runner)
        if arguments[:3] == ['xcrun', 'simctl', 'bootstatus'] and self.cold_after_bootstatus:
            self.booted = False
        return output

    def execute(self, action='prepare', method=M.OWNED_DESCRIPTOR, observe=False,
                github_output=None, observation_effect=None, clock=None):
        args = [action, '--receipt', str(self.path)]
        if action == 'prepare':
            args += ['--headless', '--readiness-attestation', method]
            if observe:
                args += ['--observe-owned-descriptor']
        elif action == 'smoke':
            args += ['--device', BASE.DEVICE]
        if github_output:
            args += ['--github-output', str(github_output)]
        actual_read = M.owned_descriptor_observation

        def observe_owned(record):
            self.observations += 1
            if observation_effect:
                return observation_effect(record, actual_read)
            return actual_read(record, self.devices_root)

        def command(runner, *items, **kwargs):
            return self.command(runner, *items, **kwargs)

        with patch.object(M.IosOwnedRunner, 'command', command), \
             patch.object(M.signal, 'signal'), \
             patch.dict(os.environ, self.owner_environment, clear=True), \
             patch.object(M, 'owned_descriptor_observation', side_effect=observe_owned):
            if clock:
                with patch.object(M.time, 'monotonic', side_effect=clock):
                    return M.main(args)
            return M.main(args)

    def saved(self):
        return json.loads(self.path.read_text())

    def spawns(self):
        return [(args, timeout) for args, timeout in self.calls
                if args[:3] == ['xcrun', 'simctl', 'spawn']]


class OwnedDescriptorLaunchdTest(unittest.TestCase):
    def assert_not_ready(self, fixture, cleanup='PASS'):
        saved = fixture.saved()
        self.assertFalse(saved.get('ready', False))
        self.assertNotIn('readinessAttestation', saved)
        self.assertNotIn('descriptorReadback', saved)
        self.assertEqual(saved['cleanup'], cleanup)

    def test_prepare_qualifies_fresh_descriptor_and_only_owned_normal_spawn(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = DescriptorFixture(directory)
            export = Path(directory) / 'github-output'
            self.assertEqual(fixture.execute(github_output=export), 0)
            saved = fixture.saved()
            self.assertTrue(saved['ready'])
            self.assertEqual(saved['readinessAttestation']['kind'], M.DESCRIPTOR_KIND)
            self.assertEqual(saved['descriptorReadback']['before']['fields']['UDID']['value'], BASE.DEVICE)
            self.assertEqual(fixture.observations, 2)
            self.assertEqual(len(fixture.spawns()), 1)
            self.assertLessEqual(fixture.spawns()[0][1], 30)
            self.assertEqual(export.read_text(), 'device_id=' + BASE.DEVICE + '\n')
            self.assertEqual(fixture.record_before_boot['deviceType'], M.OWNED_DEVICE_TYPE)
            self.assertFalse(any(BASE.FOREIGN in args for args, _ in fixture.calls))

    def test_state_numeric_or_absent_never_replaces_spawn(self):
        for state in (0, 3, 999):
            with self.subTest(state=state), tempfile.TemporaryDirectory() as directory:
                fixture = DescriptorFixture(directory)
                fixture.fields['state'] = state
                self.assertEqual(fixture.execute(), 0)
                self.assertEqual(len(fixture.spawns()), 1)

    def test_cold_normal_spawn_fails_even_when_descriptor_has_state3(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = DescriptorFixture(directory)
            fixture.cold_after_bootstatus = True
            self.assertEqual(fixture.execute(), 1)
            self.assertEqual(fixture.observations, 1)
            self.assert_not_ready(fixture)

    def test_mismatch_and_wrong_type_before_spawn_reject_each_identity_field(self):
        for key in ('UDID', 'name', 'runtime', 'deviceType'):
            for value in ('foreign-value', ['nested']):
                with self.subTest(key=key, value=value), tempfile.TemporaryDirectory() as directory:
                    fixture = DescriptorFixture(directory)
                    fixture.fields[key] = value
                    self.assertEqual(fixture.execute(), 2)
                    self.assertEqual(fixture.spawns(), [])
                    self.assert_not_ready(fixture)

    def test_atomic_same_identity_rewrite_between_reads_is_qualified(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = DescriptorFixture(directory)
            before_inode = []
            def rewrite(runner):
                before_inode.append(fixture.descriptor.stat().st_ino)
                fixture.fields['lastBootedAt'] = 'new-synthetic-value'
                fixture.write_descriptor(runner, atomic=True)
            fixture.spawn_callback = rewrite
            self.assertEqual(fixture.execute(), 0)
            self.assertNotEqual(before_inode[0], fixture.descriptor.stat().st_ino)
            proof = fixture.saved()['readinessAttestation']
            self.assertNotEqual(proof['descriptorBeforeSha256'], proof['descriptorAfterSha256'])

    def test_rename_or_runtime_change_during_spawn_rejects_final_readback(self):
        for key in ('name', 'runtime', 'UDID', 'deviceType'):
            with self.subTest(key=key), tempfile.TemporaryDirectory() as directory:
                fixture = DescriptorFixture(directory)
                def replace(runner):
                    fixture.fields[key] = 'foreign-replacement'
                    fixture.write_descriptor(runner, atomic=True)
                fixture.spawn_callback = replace
                self.assertEqual(fixture.execute(), 2)
                self.assertEqual(fixture.observations, 2)
                self.assert_not_ready(fixture)

    def test_context_change_during_spawn_rejects_completion(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = DescriptorFixture(directory)
            fixture.spawn_callback = lambda runner: os.environ.__setitem__('GITHUB_SHA', 'b' * 40)
            self.assertEqual(fixture.execute(), 2)
            self.assert_not_ready(fixture)

    def test_spawn_failure_or_timeout_never_publishes_proof(self):
        for code in (7, 124):
            with self.subTest(code=code), tempfile.TemporaryDirectory() as directory:
                fixture = DescriptorFixture(directory)
                fixture.spawn_failure = M.Failure(code, 'synthetic spawn failure')
                self.assertEqual(fixture.execute(), code)
                self.assertEqual(fixture.observations, 1)
                self.assert_not_ready(fixture)

    def test_total_budget_includes_descriptor_and_does_not_reset_for_spawn(self):
        for clock, expected_spawns in (([100, 100, 131], 0), ([100, 100, 110, 131], 1)):
            with self.subTest(clock=clock), tempfile.TemporaryDirectory() as directory:
                fixture = DescriptorFixture(directory)
                self.assertEqual(fixture.execute(clock=clock), 124)
                self.assertEqual(len(fixture.spawns()), expected_spawns)
                if expected_spawns:
                    self.assertEqual(fixture.spawns()[0][1], 20)
                self.assert_not_ready(fixture)

    def test_failed_optional_observation_has_no_qualification_fallback(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = DescriptorFixture(directory)
            def failed(record, actual_read):
                raise M.Failure(2, 'synthetic observation failure')
            self.assertEqual(fixture.execute(observe=True, observation_effect=failed), 2)
            self.assertEqual(fixture.observations, 1)
            self.assertEqual(fixture.spawns(), [])
            self.assertEqual(fixture.saved()['ownedDescriptorObservation']['descriptorRead'], 'FAIL')
            self.assert_not_ready(fixture)

    def test_recheck_reads_fresh_and_invalidates_cached_proof_on_mismatch(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = DescriptorFixture(directory)
            self.assertEqual(fixture.execute(), 0)
            fixture.fields['runtime'] = 'foreign-replacement'
            fixture.write_descriptor(fixture.runner, atomic=True)
            fixture.calls.clear()
            self.assertEqual(fixture.execute(action='smoke'), 2)
            self.assertFalse(any(args[:2] == ['flutter', 'test'] for args, _ in fixture.calls))
            self.assert_not_ready(fixture, cleanup='NOT_RUN')

    def test_receipt_wrong_kind_missing_or_altered_readback_fails_load(self):
        for mutation in ('kind', 'readback', 'field', 'boolean', 'bytes'):
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory() as directory:
                fixture = DescriptorFixture(directory)
                self.assertEqual(fixture.execute(), 0)
                saved = fixture.saved()
                if mutation == 'kind':
                    saved['readinessAttestation']['kind'] = M.READINESS_KIND
                elif mutation == 'readback':
                    saved.pop('descriptorReadback')
                elif mutation == 'field':
                    saved['descriptorReadback']['before']['fields']['name']['value'] = 'foreign'
                elif mutation == 'boolean':
                    saved['readinessAttestation']['spawnStandalone'] = 0
                else:
                    saved['descriptorReadback']['before']['fileBytes'] = True
                fixture.path.write_text(json.dumps(saved))
                runner = M.IosOwnedRunner(fixture.path)
                with patch.dict(os.environ, fixture.owner_environment, clear=True):
                    with self.assertRaises(M.Failure):
                        runner.load()

    def test_foreign_uuid_cleanup_or_incomplete_context_never_read_or_spawn(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = DescriptorFixture(directory)
            self.assertEqual(fixture.execute(), 0)
            saved = fixture.saved()
            for case in ('foreign', 'cleanup', 'context', 'bootstatus'):
                with self.subTest(case=case):
                    runner = M.IosOwnedRunner(fixture.path)
                    runner.record = dict(saved)
                    device = BASE.DEVICE
                    environment = fixture.owner_environment.copy()
                    if case == 'foreign':
                        device = BASE.FOREIGN
                    elif case == 'cleanup':
                        runner.record['cleanup'] = 'PASS'
                    elif case == 'context':
                        environment['GITHUB_JOB'] = ''
                        runner.record['ownerContext'] = environment.copy()
                    else:
                        runner.record['bootstatusCompleted'] = False
                    with patch.dict(os.environ, environment, clear=True), \
                         patch.object(M, 'owned_descriptor_observation') as observe, \
                         patch.object(runner, 'command') as command:
                        with self.assertRaises(M.Failure):
                            runner.check_device(device, ready=True, owned=True)
                        observe.assert_not_called()
                        command.assert_not_called()

    def test_old_environment_negative_is_preserved(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = DescriptorFixture(directory)
            # Questa fixture permette solo true; la vecchia modalità viene
            # controllata anche dalla suite environment dedicata, immutata.
            actual_command = fixture.command
            def env_command(runner, arguments, timeout, capture=False):
                if arguments[:3] == ['xcrun', 'simctl', 'spawn']:
                    fixture.calls.append((arguments, timeout))
                    self.assertEqual(arguments[3], BASE.DEVICE)
                    self.assertEqual(arguments[4:6], ['launchctl', 'getenv'])
                    return ''
                return actual_command(runner, arguments, timeout, capture)
            fixture.command = env_command
            self.assertEqual(fixture.execute(method=M.OWNED_ENVIRONMENT), 2)
            self.assert_not_ready(fixture)


if __name__ == '__main__':
    unittest.main()
