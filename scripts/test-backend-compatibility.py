#!/usr/bin/env python3
"""Regressioni fail-closed del preflight senza rete o dati cliente."""
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import zipfile
from unittest import mock
import contextlib
import io
import os
import subprocess

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
                         'migrations': sorted({r['migration'].split('_')[0] for r in self.manifest['rpcs']} | {r['version'] for r in self.manifest.get('required_migrations', [])}),
                         'indexes': copy.deepcopy(self.manifest.get('indexes', []))}

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

    def test_non_rpc_migration_and_index_are_required(self):
        self.manifest['required_migrations'] = [{'version': '20260928200000', 'sha256': 'a' * 64}]
        self.manifest['indexes'] = [{'schema': 'public', 'name': 'fixture_index', 'definition': 'CREATE UNIQUE INDEX fixture_index ON public.fixture(id)', 'unique': True, 'valid': True}]
        self.snapshot['migrations'] = [v for v in self.snapshot['migrations'] if v != '20260928200000']
        self.snapshot['indexes'] = copy.deepcopy(self.manifest['indexes'])
        self.assertIn('missing_migration:20260928200000', gate.schema_errors(self.manifest, self.snapshot))
        self.snapshot['migrations'].append('20260928200000')
        self.assertEqual(gate.schema_errors(self.manifest, self.snapshot), [])
        for delta in [{'definition': 'old unfiltered index'}, {'unique': False}, {'valid': False}]:
            broken = copy.deepcopy(self.snapshot)
            broken['indexes'][0].update(delta)
            self.assertIn('incompatible_index:fixture_index', gate.schema_errors(self.manifest, broken))
        self.snapshot['indexes'] = []
        self.assertIn('missing_index:fixture_index', gate.schema_errors(self.manifest, self.snapshot))

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


class ConnectionTransportTest(unittest.TestCase):
    def setUp(self):
        self.project = 'abcdefghijklmnopqrst'
        self.config = {'APP_ENV': 'staging', 'SUPABASE_URL': f'https://{self.project}.supabase.co'}
        self.endpoint = {
            'schema_version': 1, 'environment': 'staging', 'project_ref': self.project,
            'connection_type': 'session-pooler', 'host': 'aws-7-eu-west-1.pooler.supabase.com',
            'port': 5432, 'database': 'postgres',
            'username': f'supabase_read_only_user.{self.project}', 'sslmode': 'verify-full',
            'source': {'kind': 'supabase-dashboard-connect',
                       'url': f'https://supabase.com/dashboard/project/{self.project}'},
        }
        self.identity = {'current_user': 'supabase_read_only_user',
                         'session_user': 'supabase_read_only_user', 'database': 'postgres',
                         'transaction_read_only': 'on', 'superuser': False,
                         'create_role': False, 'create_db': False, 'replication': False}

    def test_direct_connection_pins_readonly_role_and_options(self):
        connection = gate.target_connection('readonly', self.config)
        self.assertIn('user=supabase_read_only_user', connection)
        self.assertIn("options='-c default_transaction_read_only=on'", connection)

    def test_session_pooler_uses_resolved_cluster_and_custom_role(self):
        connection = gate.target_connection('readonly', self.config, 'session-pooler', self.endpoint)
        self.assertIn('host=aws-7-eu-west-1.pooler.supabase.com', connection)
        self.assertIn(f'user=supabase_read_only_user.{self.project}', connection)
        self.assertIn("hostaddr='' port=5432 dbname=postgres sslmode=verify-full", connection)
        self.assertNotIn(f'host=db.{self.project}', connection)

    def test_pooler_reference_cannot_change_project_environment_role_or_tls(self):
        for key, value in [('project_ref', 'b' * 20), ('environment', 'production'),
                           ('username', 'postgres.' + self.project),
                           ('username', 'supabase_read_only_user.' + 'b' * 20),
                           ('sslmode', 'require'), ('database', 'other'), ('port', 6543),
                           ('connection_type', 'transaction-pooler'), ('schema_version', 2), ('schema_version', True),
                           ('host', 'aws-7-eu-west-1.pooler.supabase.com.attacker.invalid'),
                           ('host', 'aws-7-eu-west-1.pooler.supabase.com,other'),
                           ('host', 'db.' + self.project + '.supabase.co'),
                           ('host', "aws-7-eu-west-1.pooler.supabase.com user=postgres")]:
            with self.subTest(key=key, value=value):
                endpoint = dict(self.endpoint, **{key: value})
                with self.assertRaises(ValueError):
                    gate.target_connection('readonly', self.config, 'session-pooler', endpoint)

    def test_source_must_refer_to_authoritative_project_and_no_extra_fields(self):
        for source in [None, {'kind': 'region-guess', 'url': self.endpoint['source']['url']},
                       {'kind': 'supabase-dashboard-connect', 'url': self.endpoint['source']['url'] + 'x'},
                       {'kind': 'supabase-management-api', 'url': 'https://attacker.invalid/'},
                       dict(self.endpoint['source'], password='do-not-print')]:
            with self.subTest(source=source), self.assertRaises(ValueError):
                gate.target_connection('readonly', self.config, 'session-pooler', dict(self.endpoint, source=source))
        with self.assertRaises(ValueError):
            gate.target_connection('readonly', self.config, 'session-pooler', dict(self.endpoint, password='do-not-print'))
        endpoint = dict(self.endpoint, source={'kind': 'supabase-management-api',
                        'url': f'https://api.supabase.com/v1/projects/{self.project}/config/database/pooler'})
        self.assertIn('port=5432', gate.target_connection('readonly', self.config, 'session-pooler', endpoint))

    def test_no_implicit_fallback_or_ignored_endpoint(self):
        for mode, endpoint in [('session-pooler', None), ('transaction-pooler', self.endpoint),
                               ('direct', self.endpoint)]:
            with self.subTest(mode=mode), self.assertRaises(ValueError):
                gate.target_connection('readonly', self.config, mode, endpoint)
        for environment in ['', 'test', 'development']:
            with self.subTest(environment=environment), self.assertRaises(ValueError):
                gate.target_connection('readonly', dict(self.config, APP_ENV=environment))

    def test_connection_identity_rejects_role_changes_and_non_readonly_transaction(self):
        self.assertEqual(gate.connection_errors({'connection_identity': self.identity}), [])
        for key, value in [('current_user', 'postgres'), ('session_user', 'postgres'),
                           ('database', 'other'), ('transaction_read_only', 'off'),
                           ('superuser', True), ('create_role', True), ('create_db', True),
                           ('replication', True), ('superuser', None)]:
            with self.subTest(key=key):
                self.assertTrue(gate.connection_errors({'connection_identity': dict(self.identity, **{key: value})}))
        for snapshot in [{}, None, {'connection_identity': []}]:
            self.assertTrue(gate.connection_errors(snapshot))

    def test_connection_only_query_is_independent_of_missing_schema(self):
        sql = gate.query(json.loads(gate.MANIFEST.read_text()), connection_only=True)
        self.assertTrue(sql.startswith('BEGIN READ ONLY;'))
        self.assertTrue(sql.rstrip().endswith('ROLLBACK;'))
        self.assertIn('session_user', sql)
        self.assertIn('transaction_read_only', sql)
        self.assertNotIn('supabase_migrations', sql)
        self.assertNotIn('pg_proc', sql)
        self.assertNotIn('public.', sql)

    def test_connection_receipt_cannot_claim_full_schema(self):
        from datetime import datetime, timezone
        now = datetime.now(timezone.utc)
        snapshot = {'observed_at': now.isoformat(), 'connection_identity': self.identity}
        manifest = gate.MANIFEST.read_bytes()
        config = json.dumps(self.config).encode()
        receipt = gate.live_receipt(manifest, config, snapshot, 'a' * 40, now, now, 10, [],
                                    'session-pooler', self.endpoint, connection_only=True)
        self.assertEqual(receipt['scope'], 'live_connection_identity')
        self.assertEqual(receipt['schema_result'], 'NOT_RUN')
        self.assertEqual(receipt['connection']['type'], 'session-pooler')
        self.assertEqual(receipt['connection']['host'], self.endpoint['host'])
        self.assertEqual(receipt['connection']['username'], self.endpoint['username'])
        self.assertEqual(receipt['connection_identity'], self.identity)
        self.assertFalse(receipt['reusable_for_upload'])
        self.assertEqual(len(receipt['endpoint_metadata_sha256']), 64)
        self.assertTrue(gate.schema_errors(json.loads(manifest), dict(snapshot, rpcs=[])))

    def run_main(self, mode, snapshot=None, psql_failure=None, extra_args=(), from_environment=False):
        from datetime import datetime, timezone
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            config = root / 'config.json'
            endpoint = root / 'endpoint.json'
            receipt = root / 'receipt.json'
            config.write_text(json.dumps(self.config))
            endpoint.write_text(json.dumps(self.endpoint))
            receipt.write_text('{}')
            receipt.chmod(0o644)
            argv = ['gate', mode, '--service', 'readonly', '--app-config', str(config),
                    '--receipt', str(receipt), *extra_args]
            environment_transport = {}
            if from_environment:
                environment_transport = {'CMC_BACKEND_CONNECTION_TYPE': 'session-pooler',
                                         'CMC_BACKEND_ENDPOINT_METADATA': str(endpoint)}
            else:
                argv += ['--connection-type', 'session-pooler', '--endpoint-metadata', str(endpoint)]

            def run_psql(command, **kwargs):
                self.assertEqual(command[:-1], ['psql', '-X', '-w', '-Atq', '-v', 'ON_ERROR_STOP=1'])
                self.assertEqual(kwargs['timeout'], 30)
                self.assertIn('sslmode=verify-full', command[-1])
                self.assertIn('gssencmode=disable', command[-1])
                self.assertIn('user=' + self.endpoint['username'], command[-1])
                self.assertIn('host=' + self.endpoint['host'], command[-1])
                self.assertIn("hostaddr='' port=5432", command[-1])
                self.assertIn("options='-c default_transaction_read_only=on'", command[-1])
                self.assertEqual(kwargs['env']['PGOPTIONS'], '-c default_transaction_read_only=on')
                self.assertTrue(kwargs['input'].startswith('BEGIN READ ONLY;'))
                payload = dict(snapshot or {}, observed_at=datetime.now(timezone.utc).isoformat())
                return subprocess.CompletedProcess(command, 2 if psql_failure else 0,
                                                   json.dumps(payload), psql_failure or '')

            stream = io.StringIO()
            with mock.patch.object(gate.sys, 'argv', argv), \
                 mock.patch.object(gate.subprocess, 'run', side_effect=run_psql) as run, \
                 mock.patch.object(gate.subprocess, 'check_output', side_effect=['a' * 40, '']), \
                 mock.patch.dict(os.environ, {'PGHOST': 'attacker.invalid', 'PGHOSTADDR': '127.0.0.1',
                                             'PGPORT': '6543', 'PGUSER': 'postgres', 'PGDATABASE': 'other',
                                             'PGSSLMODE': 'disable', 'PGOPTIONS': '-c role=postgres',
                                             **environment_transport}), \
                 contextlib.redirect_stdout(stream):
                exit_code = gate.main()
            return exit_code, stream.getvalue(), json.loads(receipt.read_text()), receipt.stat().st_mode & 0o777, run.call_count

    def test_preapply_identity_pass_does_not_claim_schema_or_apply_authorization(self):
        result, output, receipt, permissions, calls = self.run_main('--connection-only', {'connection_identity': self.identity})
        self.assertEqual((result, permissions, calls), (0, 0o600, 1))
        self.assertIn('schema=NOT_RUN apply_authorization=NOT_RUN', output)
        self.assertNotIn('BACKEND_COMPATIBILITY PASS', output)
        self.assertEqual(receipt['connection_result'], 'PASS')
        self.assertEqual(receipt['schema_result'], 'NOT_RUN')

    def test_live_schema_still_requires_all_rpc_migrations_and_indexes(self):
        manifest = json.loads(gate.MANIFEST.read_text())
        snapshot = {'connection_identity': self.identity, 'rpcs': manifest['rpcs'],
                    'indexes': manifest['indexes'],
                    'migrations': sorted({r['migration'].split('_')[0] for r in manifest['rpcs']} |
                                         {r['version'] for r in manifest.get('required_migrations', [])})}
        result, _, receipt, _, _ = self.run_main('--live', snapshot)
        self.assertEqual(result, 0)
        self.assertEqual(receipt['schema_result'], 'PASS')
        snapshot['rpcs'] = snapshot['rpcs'][:32]
        result, _, receipt, _, _ = self.run_main('--live', snapshot)
        self.assertEqual(result, 1)
        self.assertEqual(receipt['connection_result'], 'PASS')
        self.assertEqual(receipt['schema_result'], 'FAIL')
        self.assertEqual(len([e for e in receipt['errors'] if e.startswith('missing_rpc:')]), 25)

    def test_identity_mismatch_fails_even_with_preapply_mode(self):
        result, _, receipt, _, _ = self.run_main('--connection-only', {'connection_identity': dict(self.identity, current_user='postgres')})
        self.assertEqual(result, 1)
        self.assertEqual(receipt['connection_result'], 'FAIL')
        self.assertEqual(receipt['schema_result'], 'NOT_RUN')

    def test_transport_failure_is_not_mislabeled_as_schema_incompatibility(self):
        for message, stage in [('SSL error: certificate verify failed secret-value', 'tls_handshake'),
                               ('password authentication failed secret-value', 'authentication'),
                               ('could not connect secret-value', 'connection_or_query')]:
            with self.subTest(stage=stage):
                result, output, _, _, calls = self.run_main('--connection-only', psql_failure=message)
                self.assertEqual((result, calls), (2, 1))
                self.assertIn('attempted=true stage=' + stage, output)
                self.assertIn('schema=NOT_RUN', output)
                self.assertNotIn('secret-value', output)

    def test_invalid_pooler_reference_is_rejected_before_psql(self):
        self.endpoint['port'] = 6543
        result, _, _, _, calls = self.run_main('--connection-only')
        self.assertEqual((result, calls), (2, 0))

    def test_release_callers_can_explicitly_select_transport_by_environment(self):
        result, _, receipt, _, calls = self.run_main('--connection-only', {'connection_identity': self.identity}, from_environment=True)
        self.assertEqual((result, calls), (0, 1))
        self.assertEqual(receipt['connection']['type'], 'session-pooler')

    def test_source_gate_is_not_blocked_by_live_transport_environment(self):
        stream = io.StringIO()
        with mock.patch.object(gate.sys, 'argv', ['gate', '--source-only']), \
             mock.patch.dict(os.environ, {'CMC_BACKEND_CONNECTION_TYPE': 'session-pooler',
                                         'CMC_BACKEND_ENDPOINT_METADATA': '/no-such-live-reference.json'}), \
             mock.patch.object(gate.subprocess, 'run') as run, contextlib.redirect_stdout(stream):
            self.assertEqual(gate.main(), 0)
            self.assertFalse(run.called)


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
