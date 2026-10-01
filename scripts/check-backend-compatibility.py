#!/usr/bin/env python3
"""Contratto consumer e preflight SQL readonly; nessuna credenziale nei risultati."""

import argparse
from datetime import datetime, timezone
import time
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / 'docs/contracts/client-backend-rpc-manifest.json'
RPC = re.compile(r"['\"]((?:customer|storefront)_[a-z0-9_]+_v\d+)['\"]")
FIELDS = ('identity_arguments', 'arguments', 'result', 'security_definer',
          'anon_execute', 'authenticated_execute', 'settings', 'definition_md5')


def source_errors(manifest, root=ROOT):
    observed = {}
    for path in (root / 'lib').rglob('*.dart'):
        relative = path.relative_to(root).as_posix()
        source = path.read_text()
        for match in RPC.finditer(source):
            name = match[1]
            if (relative == 'lib/features/delivery_context/data/shared_preferences_delivery_context_cache.dart'
                    and name == 'customer_delivery_context_v1'
                    and source[:match.start()].endswith('static const _prefix = ')):
                continue
            observed.setdefault(name, set()).add(relative)
    expected = {rpc['name']: set(rpc['sources']) for rpc in manifest['rpcs']}
    errors = []
    if len(expected) != len(manifest['rpcs']):
        errors.append('duplicate_manifest_rpc')
    for source, digest in manifest['consumer_sources'].items():
        path = root / source
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            errors.append(f'consumer_revision_requires_contract_review:{source}')
    for name in sorted(observed.keys() | expected.keys()):
        if observed.get(name) != expected.get(name):
            errors.append(f'source_drift:{name}')
    return errors


def query(manifest):
    # I nomi provengono solo dal manifest versionato, mai da input SQL libero.
    names = []
    for rpc in manifest['rpcs']:
        if rpc['schema'] != 'public' or not re.fullmatch(r'[a-z][a-z0-9_]+', rpc['name']):
            raise ValueError('invalid_manifest_identifier')
        names.append("'" + rpc['name'] + "'")
    index_names = []
    for index in manifest.get('indexes', []):
        if index.get('schema') != 'public' or not re.fullmatch(r'[a-z][a-z0-9_]+', index.get('name', '')):
            raise ValueError('invalid_manifest_index')
        index_names.append("'" + index['name'] + "'")
    index_filter = ','.join(index_names) or "NULL"
    return """BEGIN READ ONLY;
SET LOCAL statement_timeout='10s';
SELECT json_build_object('observed_at', clock_timestamp(), 'rpcs', COALESCE((SELECT json_agg(r ORDER BY name) FROM (
 SELECT n.nspname AS schema, p.proname AS name,
 pg_get_function_identity_arguments(p.oid) AS identity_arguments,
 pg_get_function_arguments(p.oid) AS arguments,
 pg_get_function_result(p.oid) AS result, p.prosecdef AS security_definer,
 p.proconfig AS settings, md5(pg_get_functiondef(p.oid)) AS definition_md5,
 has_function_privilege('anon',p.oid,'EXECUTE') AS anon_execute,
 has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_execute
 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='public' AND p.proname IN (""" + ','.join(names) + """)) r),'[]'),
  'indexes', COALESCE((SELECT json_agg(x ORDER BY name) FROM (
 SELECT n.nspname AS schema, c.relname AS name, pg_get_indexdef(c.oid) AS definition,
 i.indisunique AS unique, i.indisvalid AS valid
 FROM pg_index i JOIN pg_class c ON c.oid=i.indexrelid
 JOIN pg_namespace n ON n.oid=c.relnamespace
 WHERE n.nspname='public' AND c.relname IN (""" + index_filter + """)) x),'[]'),
 'migrations', COALESCE((SELECT json_agg(version ORDER BY version)
 FROM supabase_migrations.schema_migrations),'[]'));
ROLLBACK;
"""


def schema_errors(manifest, snapshot):
    if not isinstance(snapshot, dict) or not isinstance(snapshot.get('rpcs'), list):
        return ['invalid_snapshot']
    if any(not isinstance(rpc, dict) for rpc in snapshot['rpcs']):
        return ['invalid_snapshot']
    errors = []
    for expected in manifest['rpcs']:
        candidates = [r for r in snapshot['rpcs'] if r.get('schema') == expected['schema']
                      and r.get('name') == expected['name']]
        name = expected['name']
        if not candidates:
            errors.append(f'missing_rpc:{name}')
            continue
        if len(candidates) != 1:
            errors.append(f'ambiguous_overload:{name}')
            continue
        for field in FIELDS:
            if candidates[0].get(field) != expected[field]:
                errors.append(f'incompatible_{field}:{name}')
    versions = snapshot.get('migrations')
    if not isinstance(versions, list):
        errors.append('missing_migration_history')
    else:
        for version in sorted({r['migration'].split('_')[0] for r in manifest['rpcs']} |
                              {r['version'] for r in manifest.get('required_migrations', [])}):
            if version not in versions:
                errors.append(f'missing_migration:{version}')
    indexes = snapshot.get('indexes', [])
    if not isinstance(indexes, list) or any(not isinstance(i, dict) for i in indexes):
        errors.append('invalid_index_snapshot')
    else:
        for expected in manifest.get('indexes', []):
            observed = [i for i in indexes if i.get('schema') == expected['schema'] and i.get('name') == expected['name']]
            if not observed:
                errors.append('missing_index:' + expected['name'])
            elif len(observed) != 1 or observed[0] != expected:
                errors.append('incompatible_index:' + expected['name'])
    return errors


def target_connection(service, config):
    """Il target deriva dalla configurazione dell'artifact, non dal nome del service."""
    if not service or not re.fullmatch(r'[a-zA-Z0-9_-]{1,80}', service):
        raise ValueError('missing_service')
    if config.get('APP_ENV') not in ('staging', 'production'):
        raise ValueError('invalid_environment')
    match = re.fullmatch(r'https://([a-z]{20})\.supabase\.co', config.get('SUPABASE_URL', ''))
    if not match:
        raise ValueError('missing_validated_target')
    # hostaddr viene svuotato per impedire che il service rediriga la connessione.
    return f"service={service} host=db.{match[1]}.supabase.co hostaddr='' port=5432 dbname=postgres sslmode=verify-full"


def live_receipt(manifest_bytes, config_bytes, snapshot, revision, started, finished, duration_ms, errors):
    config = json.loads(config_bytes)
    target_connection('receipt', config)
    observed = datetime.fromisoformat(snapshot['observed_at'].replace('Z', '+00:00'))
    if observed.tzinfo is None or not (started.timestamp() - 5 <= observed.timestamp() <= finished.timestamp() + 5):
        raise ValueError('stale_live_response')
    if duration_ms < 0 or duration_ms > 30000 or (finished - started).total_seconds() > 35:
        raise ValueError('live_query_expired')
    if not re.fullmatch(r'[0-9a-f]{40}', revision):
        raise ValueError('missing_revision')
    return {
        'schema_version': 1, 'scope': 'live_schema', 'reusable_for_upload': False,
        'result': 'FAIL' if errors else 'PASS', 'client_commit': revision,
        'manifest_sha256': hashlib.sha256(manifest_bytes).hexdigest(),
        'config_sha256': hashlib.sha256(config_bytes).hexdigest(),
        'environment': config['APP_ENV'], 'project_ref': config['SUPABASE_URL'].split('//')[1].split('.')[0],
        'started_at_utc': started.isoformat(), 'checked_at_utc': finished.isoformat(),
        'server_observed_at': observed.isoformat(), 'duration_ms': duration_ms,
        'freshness_policy': 'query_per_invocation_max_30_seconds_no_receipt_reuse',
        'rpcs': len(json.loads(manifest_bytes)['rpcs']),
        'errors': errors,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--source-only', action='store_true')
    mode.add_argument('--emit-sql', action='store_true')
    mode.add_argument('--snapshot', type=Path)
    mode.add_argument('--live', action='store_true')
    parser.add_argument('--service', default=os.environ.get('CMC_BACKEND_PGSERVICE'))
    parser.add_argument('--app-config', type=Path)
    parser.add_argument('--receipt', type=Path, help='Output sanitizzato solo per query live; mai input di autorizzazione.')
    args = parser.parse_args()
    try:
        if args.receipt and not args.live:
            raise ValueError('receipt_requires_live')
        manifest_bytes = MANIFEST.read_bytes()
        manifest = json.loads(manifest_bytes)
        errors = source_errors(manifest)
        if errors:
            for error in errors:
                print('BACKEND_CONTRACT FAIL ' + error)
            return 1
        if args.emit_sql:
            print(query(manifest), end='')
            return 0
        if args.source_only:
            print(f'BACKEND_CONTRACT_SOURCE PASS rpcs={len(manifest["rpcs"])} runtime=NOT_RUN')
            return 0
        if args.live:
            if not args.service or args.app_config is None:
                print('BACKEND_COMPATIBILITY BLOCKED prerequisite=CMC_BACKEND_PGSERVICE_and_artifact_config')
                return 2
            config_bytes = args.app_config.read_bytes()
            connection = target_connection(args.service, json.loads(config_bytes))
            revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
            started = datetime.now(timezone.utc)
            monotonic_started = time.monotonic()
            env = dict(os.environ, PGCONNECT_TIMEOUT='10', PGOPTIONS='-c default_transaction_read_only=on')
            result = subprocess.run(['psql', '-X', '-w', '-Atq', '-v', 'ON_ERROR_STOP=1',
                                     connection], input=query(manifest),
                                    text=True, capture_output=True, env=env, timeout=30)
            if result.returncode:
                print('BACKEND_COMPATIBILITY BLOCKED prerequisite=authorized_readonly_database_connection')
                return 2
            finished = datetime.now(timezone.utc)
            duration_ms = round((time.monotonic() - monotonic_started) * 1000)
            snapshot = json.loads(result.stdout)
        else:
            snapshot = json.loads(args.snapshot.read_text())
        errors = schema_errors(manifest, snapshot)
        if args.live:
            receipt = live_receipt(manifest_bytes, config_bytes, snapshot, revision, started, finished, duration_ms, errors)
            receipt['source_dirty'] = bool(subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT, text=True).strip())
            receipt['consumer_sources'] = manifest['consumer_sources']
            receipt['client_sources_sha256'] = hashlib.sha256(b''.join(
                str(p.relative_to(ROOT)).encode() + b'\0' + p.read_bytes() + b'\0'
                for p in sorted((ROOT / 'lib').rglob('*.dart')))).hexdigest()
            if args.receipt:
                descriptor = os.open(args.receipt, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
                with os.fdopen(descriptor, 'w') as handle:
                    json.dump(receipt, handle, sort_keys=True, indent=2)
            print('BACKEND_LIVE_RECEIPT ' + json.dumps(receipt, sort_keys=True))
        for error in errors:
            print('BACKEND_COMPATIBILITY FAIL ' + error)
        if errors:
            return 1
        print('BACKEND_COMPATIBILITY PASS scope=' + ('live_schema' if args.live else 'snapshot_only'))
        print('BACKEND_BEHAVIOR NOT_RUN prerequisite=payload_and_owner_shop_E2E')
        return 0
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError):
        print('BACKEND_COMPATIBILITY BLOCKED prerequisite=valid_manifest_snapshot_or_connection')
        return 2


if __name__ == '__main__':
    sys.exit(main())
