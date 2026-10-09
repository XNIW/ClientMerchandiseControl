#!/usr/bin/env python3
"""Regressioni host del binding AAB: nessuna build o firma nativa."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
import zipfile

spec = importlib.util.spec_from_file_location(
    'runtime_binding', Path(__file__).with_name('check-android-runtime-binding.py'))
binding = importlib.util.module_from_spec(spec)
spec.loader.exec_module(binding)


class RuntimeBindingTest(unittest.TestCase):
    def test_production_and_test_markers_are_separate(self):
        fingerprint = 'a' * 64
        for test_mode, prefix in ((False, 'CMC_RELEASE_CONFIG_ATTESTATION_V1:'),
                                  (True, 'CMC_TEST_CONFIG_ATTESTATION_V1:')):
            with self.subTest(test=test_mode), tempfile.TemporaryDirectory() as temporary:
                path = Path(temporary) / 'fixture.aab'
                self.write(path, [prefix + fingerprint] * 3)
                self.assertTrue(binding.verify(path, fingerprint, test=test_mode))
                self.assertFalse(binding.verify(path, fingerprint, test=not test_mode))

    def test_each_abi_rejects_wrong_missing_duplicate_or_opposite_marker(self):
        fingerprint = 'a' * 64
        for test_mode, prefix, opposite in (
            (False, 'CMC_RELEASE_CONFIG_ATTESTATION_V1:', 'CMC_TEST_CONFIG_ATTESTATION_V1:'),
            (True, 'CMC_TEST_CONFIG_ATTESTATION_V1:', 'CMC_RELEASE_CONFIG_ATTESTATION_V1:'),
        ):
            marker = prefix + fingerprint
            for abi in range(3):
                for altered in ('', prefix + 'b' * 64, marker + marker,
                                marker + opposite + fingerprint):
                    with self.subTest(test=test_mode, abi=abi, altered=altered), tempfile.TemporaryDirectory() as temporary:
                        path = Path(temporary) / 'fixture.aab'
                        payloads = [marker] * 3
                        payloads[abi] = altered
                        self.write(path, payloads)
                        self.assertFalse(binding.verify(path, fingerprint, test=test_mode))

    @staticmethod
    def write(path, payloads):
        with zipfile.ZipFile(path, 'w') as archive:
            for abi, payload in zip(binding.ABIS, payloads):
                archive.writestr('base/lib/' + abi + '/libapp.so', payload.encode('ascii'))


if __name__ == '__main__':
    unittest.main()
