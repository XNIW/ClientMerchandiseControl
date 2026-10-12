#!/usr/bin/env python3
"""Gate host del nuovo readback per-owned-UDID; nessun SDK/dispositivo reale."""
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('ios_owned_inventory_boundaries',
    Path(__file__).with_name('test-task054-ios-owned.py'))
BASE = importlib.util.module_from_spec(spec)
spec.loader.exec_module(BASE)
M = BASE.MODULE


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


if __name__ == '__main__':
    unittest.main()
