#!/usr/bin/env python3
import base64
import importlib.util
from pathlib import Path
import unittest
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
    def test_duplicate_and_corrupt_defines(self):
        for value in ['???', encoded({'GOOGLE_AUTH_ENABLED':'true'}) + ',' + encoded({'GOOGLE_AUTH_ENABLED':'false'})]:
            with self.assertRaises(ValueError): binding.entitlements(value)
if __name__ == '__main__': unittest.main()
