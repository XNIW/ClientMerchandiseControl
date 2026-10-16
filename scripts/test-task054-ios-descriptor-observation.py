#!/usr/bin/env python3
"""Bounded file/FD/privacy/entrypoint tests; schema actual/native NOT_RUN."""
import importlib.util
import json
import os
from pathlib import Path
import plistlib
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('descriptor_owner_boundaries',
    Path(__file__).with_name('test-task054-ios-owned.py'))
BASE = importlib.util.module_from_spec(spec)
spec.loader.exec_module(BASE)
M = BASE.MODULE
SECRET = 'do-not-emit-any-value-private-fixture'


def record():
    nonce = 'a' * 32
    return {'device': BASE.DEVICE, 'name': M.PREFIX + nonce, 'nonce': nonce,
            'creationStarted': True, 'bootstatusCompleted': True,
            'cleanup': 'NOT_RUN', 'processCleanupFailed': False,
            'runtime': BASE.RUNTIME,
            'ownerContext': {key: os.environ.get(key) for key in M.OWNER_CONTEXT}}


def descriptor(directory, data=None):
    base = Path(directory) / 'Devices'
    device = base / BASE.DEVICE
    device.mkdir(parents=True)
    path = device / 'device.plist'
    data = data if data is not None else {
        'UDID': BASE.DEVICE, 'name': record()['name'], 'runtime': BASE.RUNTIME,
        'deviceType': 'com.apple.CoreSimulator.SimDeviceType.iPhone-17',
        'state': 3, 'privateMetadata': SECRET,
    }
    path.write_bytes(plistlib.dumps(data))
    return base, path


class OwnedDescriptorObservationTest(unittest.TestCase):
    def test_only_owned_descriptor_captured_without_readiness_or_private_values(self):
        with tempfile.TemporaryDirectory() as directory:
            base, path = descriptor(directory)
            result = M.owned_descriptor_observation(record(), base)
            self.assertEqual(result['descriptorRead'], 'PASS')
            self.assertEqual(result['readiness'], 'NOT_RUN')
            self.assertEqual(result['nativeApp'], 'NOT_RUN')
            self.assertTrue(result['fileIdentityStable'])
            self.assertEqual(result['fileBytes'], path.stat().st_size)
            self.assertTrue(result['fields']['UDID']['matchesExpected'])
            self.assertTrue(result['fields']['name']['matchesExpected'])
            self.assertTrue(result['fields']['runtime']['matchesExpected'])
            self.assertEqual(result['fields']['state']['value'], 3)
            self.assertNotIn(SECRET, json.dumps(result))
            self.assertNotIn('privateMetadata', result['fields'])
            self.assertNotIn(str(base), json.dumps(result))

    def test_symlink_file_device_and_base_are_rejected(self):
        for level in ('file', 'device', 'base'):
            with self.subTest(level=level), tempfile.TemporaryDirectory() as directory:
                base, path = descriptor(directory)
                if level == 'file':
                    target = path.with_name('foreign.plist')
                    path.rename(target)
                    path.symlink_to(target)
                elif level == 'device':
                    original = path.parent
                    target = base / 'foreign'
                    original.rename(target)
                    original.symlink_to(target, target_is_directory=True)
                else:
                    target = base.with_name('ForeignDevices')
                    base.rename(target)
                    base.symlink_to(target, target_is_directory=True)
                with self.assertRaises(M.Failure):
                    M.owned_descriptor_observation(record(), base)

    def test_oversize_malformed_and_nonobject_descriptor_cannot_be_capture_pass(self):
        for bad in (b'x' * 65537, b'not-a-plist', b'<?xml version="1.0"?><plist><dict>', plistlib.dumps([1])):
            with self.subTest(bytes=len(bad)), tempfile.TemporaryDirectory() as directory:
                base, path = descriptor(directory)
                path.write_bytes(bad)
                with self.assertRaises((M.Failure, ValueError)):
                    M.owned_descriptor_observation(record(), base)

    def test_owner_nonce_boot_and_context_rejected_before_open(self):
        mutations = [('nonce', 'bad'), ('bootstatusCompleted', False),
                     ('creationStarted', False),
                     ('cleanup', 'PASS')]
        with tempfile.TemporaryDirectory() as directory:
            base, _ = descriptor(directory)
            for key, value in mutations:
                with self.subTest(key=key), patch.object(M.os, 'open',
                        side_effect=AssertionError('Should not open a descriptor')):
                    data = record()
                    data[key] = value
                    with self.assertRaises((M.Failure, FileNotFoundError)):
                        M.owned_descriptor_observation(data, base)
            data = record()
            data['ownerContext']['GITHUB_JOB'] = 'foreign-job'
            with patch.object(M.os, 'open', side_effect=AssertionError('Should not open')):
                with self.assertRaises(M.Failure):
                    M.owned_descriptor_observation(data, base)

    def test_missing_claimed_uuid_never_opens_a_descriptor_file(self):
        with tempfile.TemporaryDirectory() as directory:
            base, _ = descriptor(directory)
            data = record()
            data['device'] = BASE.FOREIGN
            real_open = os.open
            with patch.object(M.os, 'open', wraps=real_open) as opened:
                with self.assertRaises(FileNotFoundError):
                    M.owned_descriptor_observation(data, base)
            self.assertEqual(opened.call_count, 1)
            self.assertEqual(opened.call_args.args[0], base)

    def test_other_file_owner_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            base, _ = descriptor(directory)
            wrong_uid = os.geteuid() + 1
            with patch.object(M.os, 'geteuid', return_value=wrong_uid):
                with self.assertRaises(M.Failure):
                    M.owned_descriptor_observation(record(), base)

    def test_replacement_during_read_is_rejected_and_fd_closed(self):
        with tempfile.TemporaryDirectory() as directory:
            base, path = descriptor(directory)
            real_read = os.read
            opened = []
            def read(fd, count):
                opened.append(fd)
                value = real_read(fd, count)
                replacement = path.with_name('replacement.plist')
                replacement.write_bytes(path.read_bytes())
                os.replace(replacement, path)
                return value
            with patch.object(M.os, 'read', side_effect=read):
                with self.assertRaises(M.Failure):
                    M.owned_descriptor_observation(record(), base)
            self.assertEqual(len(opened), 1)
            with self.assertRaises(OSError):
                os.fstat(opened[0])

    def test_fifo_replacement_between_stat_and_open_is_nonblocking_and_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            base, path = descriptor(directory)
            real_open = os.open
            opened = []

            def open_owned(path_arg, flags, *args, **kwargs):
                if path_arg == 'device.plist':
                    path.unlink()
                    os.mkfifo(path)
                    # Questa precondizione evita che il negativo sorgente blocchi
                    # la suite; una regressione indipendente controlla il budget.
                    self.assertTrue(flags & os.O_NONBLOCK)
                fd = real_open(path_arg, flags, *args, **kwargs)
                opened.append(fd)
                return fd

            with patch.object(M.os, 'open', side_effect=open_owned):
                with self.assertRaises(M.Failure):
                    M.owned_descriptor_observation(record(), base)
            self.assertEqual(len(opened), 3)
            for fd in opened:
                with self.assertRaises(OSError):
                    os.fstat(fd)

    def test_arbitrary_nested_field_values_not_emitted_and_mismatches_not_accepted(self):
        with tempfile.TemporaryDirectory() as directory:
            data = {'UDID': BASE.FOREIGN, 'name': SECRET, 'runtime': SECRET,
                    'deviceType': {'value': SECRET}, 'state': {'value': SECRET}}
            base, _ = descriptor(directory, data)
            result = M.owned_descriptor_observation(record(), base)
            self.assertNotIn(SECRET, json.dumps(result))
            self.assertFalse(result['fields']['UDID']['matchesExpected'])
            self.assertFalse(result['fields']['name']['matchesExpected'])
            self.assertFalse(result['fields']['runtime']['matchesExpected'])
            self.assertEqual(result['readiness'], 'NOT_RUN')

    def test_entrypoint_observation_retained_through_original_environment_failure_and_cleanup(self):
        for success in (True, False):
            with self.subTest(observation=success), tempfile.TemporaryDirectory() as directory:
                fixture = BASE.Fixture(directory)
                args = ['prepare', '--receipt', str(fixture.path), '--headless',
                        '--readiness-attestation', M.OWNED_ENVIRONMENT,
                        '--observe-owned-descriptor']
                capsule = {'kind': 'owned-device-descriptor-observation.v1',
                           'descriptorRead': 'PASS', 'readiness': 'NOT_RUN',
                           'nativeApp': 'NOT_RUN', 'fields': {}}
                def command(runner, *a, **k):
                    return fixture.command(runner, *a, **k)
                effect = None if success else M.Failure(2, 'synthetic descriptor failure')
                with patch.object(M.IosOwnedRunner, 'command', command), \
                     patch.object(M.signal, 'signal'), \
                     patch.dict(os.environ, fixture.owner_environment, clear=True), \
                     patch.object(M, 'owned_descriptor_observation', return_value=capsule,
                                  side_effect=effect) as observe:
                    # Le variabili launchd restano vuote nella fixture: stesso
                    # negativo readiness, nessun fallback dopo l'osservazione.
                    self.assertEqual(M.main(args), 2)
                    self.assertEqual(observe.call_count, 1)
                saved = json.loads(fixture.path.read_text())
                self.assertEqual(saved['ownedDescriptorObservation']['descriptorRead'],
                                 'PASS' if success else 'FAIL')
                self.assertEqual(saved['ownedDescriptorObservation']['readiness'], 'NOT_RUN')
                self.assertFalse(saved.get('ready', False))
                self.assertNotIn('readinessAttestation', saved)
                self.assertEqual(saved['cleanup'], 'PASS')
                self.assertFalse(any(BASE.FOREIGN in c for c, _ in fixture.calls))


    def test_xml_parse_failure_is_sanitized_and_original_failure_still_cleans_uuid(self):
        with tempfile.TemporaryDirectory() as directory:
            base, path = descriptor(directory)
            path.write_bytes(b'<?xml version="1.0"?><plist><dict>')
            fixture = BASE.Fixture(directory)
            args = ['prepare', '--receipt', str(fixture.path), '--headless',
                    '--readiness-attestation', M.OWNED_ENVIRONMENT,
                    '--observe-owned-descriptor']
            actual_read = M.owned_descriptor_observation
            def command(runner, *a, **k):
                return fixture.command(runner, *a, **k)
            with patch.object(M.IosOwnedRunner, 'command', command), \
                 patch.object(M.signal, 'signal'), \
                 patch.dict(os.environ, fixture.owner_environment, clear=True), \
                 patch.object(M, 'owned_descriptor_observation',
                              side_effect=lambda rec: actual_read(rec, base)):
                self.assertEqual(M.main(args), 2)
            saved = json.loads(fixture.path.read_text())
            self.assertEqual(saved['ownedDescriptorObservation']['descriptorRead'], 'FAIL')
            self.assertEqual(saved['ownedDescriptorObservation']['errorType'], 'Failure')
            self.assertEqual(saved['cleanup'], 'PASS')
            self.assertFalse(fixture.exists)
            self.assertFalse(saved.get('ready', False))

    def test_inventory_observe_flag_reads_after_actual_bootstatus(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = BASE.Fixture(directory)
            args = ['prepare', '--receipt', str(fixture.path), '--headless',
                    '--observe-owned-descriptor']
            def command(runner, *a, **k):
                return fixture.command(runner, *a, **k)
            def observe(rec):
                self.assertTrue(rec['bootstatusCompleted'])
                return {'descriptorRead': 'PASS', 'readiness': 'NOT_RUN'}
            with patch.object(M.IosOwnedRunner, 'command', command), \
                 patch.object(M.signal, 'signal'), \
                 patch.dict(os.environ, fixture.owner_environment, clear=True), \
                 patch.object(M, 'owned_descriptor_observation', side_effect=observe) as reader:
                self.assertEqual(M.main(args), 0)
                self.assertEqual(reader.call_count, 1)
            saved = json.loads(fixture.path.read_text())
            self.assertEqual(saved['ownedDescriptorObservation']['descriptorRead'], 'PASS')
            self.assertTrue(saved['ready'])
            self.assertNotIn('readinessAttestation', saved)

    def test_signal_during_observation_is_preserved_and_prevents_ready_probe(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = BASE.Fixture(directory)
            args = ['prepare', '--receipt', str(fixture.path), '--headless',
                    '--readiness-attestation', M.OWNED_ENVIRONMENT,
                    '--observe-owned-descriptor']
            def command(runner, *a, **k):
                return fixture.command(runner, *a, **k)
            with patch.object(M.IosOwnedRunner, 'command', command), \
                 patch.object(M.signal, 'signal'), \
                 patch.dict(os.environ, fixture.owner_environment, clear=True), \
                 patch.object(M, 'owned_descriptor_observation',
                              side_effect=M.Failure(143, 'interrupted')):
                self.assertEqual(M.main(args), 143)
            saved = json.loads(fixture.path.read_text())
            self.assertEqual(saved['cleanup'], 'PASS')
            self.assertFalse(saved.get('ready', False))
            self.assertFalse(any(c[:3] == ['xcrun', 'simctl', 'spawn'] for c, _ in fixture.calls))


if __name__ == '__main__':
    unittest.main()
