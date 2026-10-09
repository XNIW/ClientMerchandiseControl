#!/usr/bin/env python3
"""Regressioni host: nessun certificato o profilo reale letto."""
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location(
    'ios_callback', Path(__file__).with_name('check-ios-test-callback.py'))
callback = importlib.util.module_from_spec(spec)
spec.loader.exec_module(callback)


class TestCallback(unittest.TestCase):
    def test_exact_app_domain_accepts_exact_or_capability_profile_grant(self):
        expected = ['applinks:auth.client.example.com']
        for grant in (expected, ['*'], '*'):
            with self.subTest(grant=grant):
                self.assertTrue(callback.verify(
                    {callback.KEY: expected}, {'Entitlements': {callback.KEY: grant}},
                    'auth.client.example.com'))

    def test_signed_app_never_accepts_wildcard_other_or_multiple_domain(self):
        for domains in (None, [], '*', ['*'], ['applinks:*'],
                        ['applinks:other.client.example.com'],
                        ['applinks:auth.client.example.com', 'applinks:other.client.example.com']):
            with self.subTest(domains=domains):
                self.assertFalse(callback.verify(
                    {callback.KEY: domains}, {'Entitlements': {callback.KEY: ['*']}},
                    'auth.client.example.com'))

    def test_profile_rejects_absent_empty_wrong_type_partial_wildcard_or_other_service(self):
        expected = ['applinks:auth.client.example.com']
        for grant in (None, [], True, ['applinks:*'],
                      ['webcredentials:auth.client.example.com'],
                      ['applinks:other.client.example.com'], expected + ['*']):
            with self.subTest(grant=grant):
                self.assertFalse(callback.verify(
                    {callback.KEY: expected}, {'Entitlements': {callback.KEY: grant}},
                    'auth.client.example.com'))


if __name__ == '__main__':
    unittest.main()
