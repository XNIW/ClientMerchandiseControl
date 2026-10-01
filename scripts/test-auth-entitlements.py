#!/usr/bin/env python3
import base64
import importlib.util
from pathlib import Path
import unittest
import os
import subprocess
import sys
import tempfile
import plistlib
spec = importlib.util.spec_from_file_location('binding', Path(__file__).with_name('prepare-auth-entitlements.py'))
binding = importlib.util.module_from_spec(spec)
spec.loader.exec_module(binding)
def encoded(values):
    return ','.join(base64.b64encode(f'{k}={v}'.encode()).decode() for k,v in values.items())
class BindingTests(unittest.TestCase):
    def test_off_no_associated_domains(self):
        self.assertEqual(binding.entitlements(''), {})
    def test_exact_staging_host(self):
        values = {'APP_ENV':'staging', 'GOOGLE_AUTH_ENABLED':'true', 'AUTH_CALLBACK_VERIFIED_HOST':'login.example.org', 'AUTH_REDIRECT_URI':'https://login.example.org/auth-callback/'}
        self.assertEqual(binding.entitlements(encoded(values)), {'com.apple.developer.associated-domains':['applinks:login.example.org']})
        for delta in [{'APP_ENV':'production'}, {'AUTH_CALLBACK_VERIFIED_HOST':'*.example.org'}, {'AUTH_REDIRECT_URI':'https://other.example.org/auth-callback/'}, {'AUTH_CALLBACK_VERIFIED_HOST':'a.invalid'}, {'AUTH_CALLBACK_VERIFIED_HOST':''}]:
            with self.subTest(delta=delta), self.assertRaises(ValueError): binding.entitlements(encoded(values | delta))
    def test_build_check_rejects_missing_stale_or_invalid_generated_file(self):
        script = Path(__file__).with_name('prepare-auth-entitlements.py')
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'AuthCallback.entitlements'
            env = dict(os.environ, SCRIPT_OUTPUT_FILE_0=str(path), DART_DEFINES='')
            def run(*args):
                return subprocess.run([sys.executable, str(script), *args], env=env, capture_output=True).returncode
            self.assertNotEqual(run('--check'), 0)
            self.assertEqual(run(), 0)
            self.assertEqual(run('--check'), 0)
            path.write_bytes(plistlib.dumps({'com.apple.developer.associated-domains': ['applinks:stale.invalid']}))
            self.assertNotEqual(run('--check'), 0)
            env['DART_DEFINES'] = 'malformed!'
            self.assertNotEqual(run(), 0)
            self.assertFalse(path.exists())

    def test_duplicate_and_corrupt_defines(self):
        for value in ['???', encoded({'GOOGLE_AUTH_ENABLED':'true'}) + ',' + encoded({'GOOGLE_AUTH_ENABLED':'false'})]:
            with self.assertRaises(ValueError): binding.entitlements(value)
if __name__ == '__main__': unittest.main()
