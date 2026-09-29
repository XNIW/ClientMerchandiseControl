#!/usr/bin/env python3
"""Regressioni fail-closed del preflight senza rete o dati cliente."""
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

spec = importlib.util.spec_from_file_location('compatibility', Path(__file__).with_name('check-backend-compatibility.py'))
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


binding_spec = importlib.util.spec_from_file_location('binding', Path(__file__).with_name('check-android-runtime-binding.py'))
binding = importlib.util.module_from_spec(binding_spec)
binding_spec.loader.exec_module(binding)


class CompatibilityTest(unittest.TestCase):
    def setUp(self):
        self.manifest = json.loads(gate.MANIFEST.read_text())
        self.snapshot = {'rpcs': copy.deepcopy(self.manifest['rpcs']),
                         'migrations': sorted({r['migration'].split('_')[0] for r in self.manifest['rpcs']})}

    def test_live_receipt_binds_target_revision_config_and_freshness(self):
        from datetime import datetime, timezone, timedelta
        now = datetime.now(timezone.utc)
        snapshot = dict(self.snapshot, observed_at=now.isoformat())
        manifest = json.dumps(self.manifest).encode()
        config = json.dumps({'APP_ENV': 'staging', 'SUPABASE_URL': 'https://abcdefghijklmnopqrst.supabase.co', 'SUPABASE_PUBLISHABLE_KEY': 'do-not-print-this-value'}).encode()
        receipt = gate.live_receipt(manifest, config, snapshot, 'a' * 40, now, now, 12, [])
        self.assertEqual(receipt['scope'], 'live_schema')
        self.assertFalse(receipt['reusable_for_upload'])
        self.assertNotIn('do-not-print', json.dumps(receipt))
        self.assertEqual(receipt['client_commit'], 'a' * 40)
        changed = gate.live_receipt(manifest, config.replace(b'abcdefghijklmnopqrst', b'bcdefghijklmnopqrstu'), snapshot, 'b' * 40, now, now, 12, ['missing_rpc:fixture'])
        self.assertNotEqual(receipt['config_sha256'], changed['config_sha256'])
        self.assertNotEqual(receipt['project_ref'], changed['project_ref'])
        self.assertEqual(changed['result'], 'FAIL')
        for stale in [dict(snapshot, observed_at=(now - timedelta(minutes=1)).isoformat()), self.snapshot]:
            with self.assertRaises((ValueError, KeyError)):
                gate.live_receipt(manifest, config, stale, 'a' * 40, now, now, 12, [])
        with self.assertRaises(ValueError):
            gate.live_receipt(manifest, config, snapshot, 'a' * 40, now, now, 30001, [])

    def test_complete_schema(self):
        self.assertEqual(gate.schema_errors(self.manifest, self.snapshot), [])
        self.assertEqual(gate.source_errors(self.manifest), [])

    def test_missing_checkout_v2_does_not_fall_back_to_v1(self):
        self.snapshot['rpcs'] = [r for r in self.snapshot['rpcs'] if r['name'] != 'customer_checkout_quote_create_v2']
        self.assertIn('missing_rpc:customer_checkout_quote_create_v2', gate.schema_errors(self.manifest, self.snapshot))

    def test_overload_cannot_mask_missing_signature(self):
        self.snapshot['rpcs'].append(copy.deepcopy(self.snapshot['rpcs'][0]))
        self.assertTrue(any(e.startswith('ambiguous_overload:') for e in gate.schema_errors(self.manifest, self.snapshot)))

    def test_each_boundary_field_is_verified(self):
        for field in gate.FIELDS:
            with self.subTest(field=field):
                broken = copy.deepcopy(self.snapshot)
                broken['rpcs'][0][field] = 'wrong'
                self.assertTrue(any(e.startswith('incompatible_' + field + ':') for e in gate.schema_errors(self.manifest, broken)))

    def test_schema_without_migration_receipt_is_not_compatible(self):
        self.snapshot['migrations'].remove('20260823023037')
        self.assertIn('missing_migration:20260823023037', gate.schema_errors(self.manifest, self.snapshot))

    def test_parameter_change_requires_new_contract_review(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for source in self.manifest['consumer_sources']:
                path = root / source
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes((gate.ROOT / source).read_bytes())
            source = self.manifest['rpcs'][0]['sources'][0]
            path = root / source
            path.write_text(path.read_text().replace('p_address_id', 'p_wrong_address'))
            self.assertIn('consumer_revision_requires_contract_review:' + source, gate.source_errors(self.manifest, root))

    def test_query_is_read_only_and_does_not_invoke_business_rpc(self):
        sql = gate.query(self.manifest)
        self.assertTrue(sql.startswith('BEGIN READ ONLY;'))
        self.assertTrue(sql.rstrip().endswith('ROLLBACK;'))
        self.assertNotIn('select public.', sql.lower())

    def test_incomplete_or_malformed_snapshot_fails(self):
        for value in [None, [], {}, {'rpcs': []}]:
            self.assertTrue(gate.schema_errors(self.manifest, value))

    def test_live_target_is_bound_to_artifact_and_verified_tls(self):
        connection = gate.target_connection('readonly', {'APP_ENV': 'staging',
            'SUPABASE_URL': 'https://abcdefghijklmnopqrst.supabase.co'})
        self.assertIn('host=db.abcdefghijklmnopqrst.supabase.co', connection)
        self.assertIn("hostaddr=''", connection)
        self.assertIn('sslmode=verify-full', connection)
        for url in ['', 'http://abcdefghijklmnopqrst.supabase.co',
                    'https://abcdefghijklmnopqrst.supabase.co@attacker.invalid',
                    'https://abcdefghijklmnopqrst.supabase.co/other']:
            with self.assertRaises(ValueError):
                gate.target_connection('readonly', {'APP_ENV': 'staging', 'SUPABASE_URL': url})


class AndroidBindingTest(unittest.TestCase):
    def test_each_abi_must_match_exactly_once(self):
        digest = 'a' * 64
        marker = binding.MARKER + digest.encode('ascii')
        for alteration in ('valid', 'missing', 'mismatch', 'duplicate', 'no_marker'):
            with self.subTest(alteration=alteration), tempfile.TemporaryDirectory() as temp:
                path = Path(temp) / 'candidate.aab'
                with zipfile.ZipFile(path, 'w') as archive:
                    for abi in binding.ABIS:
                        if abi == 'x86_64' and alteration == 'missing':
                            continue
                        payload = marker
                        if abi == 'x86_64':
                            if alteration == 'mismatch':
                                payload = binding.MARKER + b'b' * 64
                            elif alteration == 'duplicate':
                                payload = marker + marker
                            elif alteration == 'no_marker':
                                payload = b'no runtime attestation'
                        archive.writestr('base/lib/' + abi + '/libapp.so', payload)
                self.assertEqual(binding.verify(path, digest), alteration == 'valid')

    def test_invalid_archive_or_digest_fails_closed(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / 'candidate.aab'
            path.write_bytes(b'not an archive')
            self.assertFalse(binding.verify(path, 'a' * 64))
            self.assertFalse(binding.verify(path, 'invalid'))


if __name__ == '__main__':
    unittest.main()
