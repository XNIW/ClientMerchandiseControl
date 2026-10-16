"""Osservazioni read-only limitate al package della fixture e al suo AVD proprio.

Il dump post-driver non attesta l'hash al momento dell'evento né esclude eventi
persi/troncati. Nessun messaggio logcat grezzo viene persistito o stampato.
"""
import re
import time

PACKAGE = 'com.xniw.clientmerchandisecontrol'
TAGS = ('am_proc_start', 'am_proc_died', 'am_kill', 'am_create_activity',
        'am_destroy_activity', 'am_resume_activity', 'am_pause_activity',
        'wm_create_activity', 'wm_destroy_activity', 'wm_resume_activity',
        'wm_pause_activity', 'wm_on_create_called', 'wm_on_start_called',
        'wm_on_resume_called', 'wm_on_paused_called', 'wm_on_stop_called',
        'wm_on_destroy_called', 'wm_on_restart_called')
LINE = re.compile(r'^\s*([0-9]{9,13}\.[0-9]{1,9})\s+([0-9]+)\s+[0-9]+\s+I\s+([a-z_]+)\s*:\s*\[(.*)\]\s*$')


def lifecycle_rows(text):
    rows = []
    discarded = 0
    # Anche l'output di una sorgente inattesa resta limitato prima del parsing.
    for raw in text.splitlines()[:256]:
        if len(raw) > 8192:
            discarded += 1
            continue
        match = LINE.fullmatch(raw)
        if match is None or match[3] not in TAGS:
            discarded += 1
            continue
        fields = [value.strip() for value in match[4].split(',')]
        tag = match[3]
        own_process = (tag == 'am_proc_start' and len(fields) >= 4 and fields[3] == PACKAGE or
                       tag in ('am_proc_died', 'am_kill') and len(fields) >= 3 and fields[2] == PACKAGE)
        own_activity = any(value in (PACKAGE + '/.MainActivity',
            PACKAGE + '/' + PACKAGE + '.MainActivity', PACKAGE + '.MainActivity') for value in fields)
        if not own_process and not own_activity:
            discarded += 1
            continue
        pid = int(fields[1]) if own_process and fields[1].isdigit() else None
        if own_activity and tag.startswith('wm_on_'):
            pid = int(match[2])
        rows.append({'device_epoch_seconds': match[1], 'event': tag, 'pid': pid,
                     'own_activity': own_activity})
    return rows, discarded


def collect(runner, adb, deadline):
    receipt = {'status': 'NOT_RUN', 'package': PACKAGE,
        'expected_apk_sha256': runner.fixture_apk_sha256,
        'bounded_dump': True, 'max_dump_rows': 256,
        'installed_snapshot': None, 'identity_snapshot_status': 'NOT_RUN',
        'queries_started': 0, 'lifecycle': [],
        'limitation': 'post-driver snapshot; no hash-at-event or absence proof'}
    target = [str(adb), '-s', runner.serial]

    def query(arguments, *, absent_ok=False):
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError('original visual budget exhausted')
        receipt['queries_started'] += 1
        code, output = runner.command(target + arguments, min(3, remaining), check=False)
        if code and not (absent_ok and code == 1 and not output):
            raise RuntimeError('diagnostic adb query failed')
        return output

    try:
        package_filter = r'(^|[, ])' + re.escape(PACKAGE) + r'([,/\]]|\.MainActivity([,\] ]|$)|$)'
        output = query(['logcat', '-d', '-b', 'events', '-v', 'epoch', '-t', '256',
            '-e', package_filter] + [tag + ':I' for tag in TAGS] + ['*:S'])
        receipt['lifecycle'], receipt['discarded_rows'] = lifecycle_rows(output)
        receipt['dump_bytes_received'] = len(output.encode('utf-8'))
        receipt['dump_reached_row_cap'] = len(output.splitlines()) >= 256
        receipt['truncation_possible'] = True
        processes = query(['shell', 'pidof', PACKAGE], absent_ok=True)
        receipt['post_driver_package_pids'] = ([int(value) for value in processes.split()[:16]]
            if re.fullmatch(r'[0-9]+(?: [0-9]+){0,15}', processes) else [])
        installed = query(['shell', 'pm', 'path', PACKAGE])
        receipt['identity_snapshot_status'] = 'FAIL'
        if re.fullmatch(r'package:/data/app/[A-Za-z0-9_./=+~-]+/base\.apk', installed):
            checksum = query(['shell', 'sha256sum', installed.removeprefix('package:')])
            digest = checksum.split()[0] if checksum else ''
            if re.fullmatch(r'[0-9a-f]{64}', digest):
                receipt['installed_snapshot'] = {'apk_sha256': digest,
                    'matches_expected': digest == runner.fixture_apk_sha256}
                receipt['identity_snapshot_status'] = (
                    'PASS' if digest == runner.fixture_apk_sha256 else 'FAIL')
        receipt['host_snapshot_epoch_us'] = time.time_ns() // 1000
        receipt['status'] = 'PASS'
    except Exception as error:
        if getattr(error, 'phase', None) == 'signal':
            raise
        receipt.update(status='FAIL' if receipt['queries_started'] else 'NOT_RUN',
            error_type=type(error).__name__)
    return receipt
