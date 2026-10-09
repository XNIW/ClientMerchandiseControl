#!/usr/bin/env bash
set -euo pipefail
# Catture di componenti produzione con fixture, mai E2E backend autenticato.
cmc_visual_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${cmc_visual_script_dir}/resolve-flutter.sh"
[[ $# -eq 1 && "$1" == '--ios' || $# -eq 2 && "$1" == '--device' ]] || {
  printf 'USAGE: test-task054-visual.sh --ios | --device OWNED_DEVICE_ID\n' >&2
  exit 2
}
CMC_TASK054_SCRIPTS_DIR="${cmc_visual_script_dir}" python3 - "$@" <<'PYCODE'
import importlib.util
import json
import os
import re
from pathlib import Path
import signal
import subprocess
import sys

device = None
owns_device = sys.argv[1] == '--ios'
cleanup_spec = importlib.util.spec_from_file_location('cmc_owned_cleanup',
    Path(os.environ['CMC_TASK054_SCRIPTS_DIR']) / 'run-task054-android-visual.py')
cleanup_module = importlib.util.module_from_spec(cleanup_spec)
cleanup_spec.loader.exec_module(cleanup_module)


def stop_command(process):
    global cleanup_failed
    try:
        # Python OS drena i propri tool group con TERM5/KILL5, probe2/reap1:
        # questa grace20 preserva il suo KILL e il receipt finale.
        cleanup_module.stop_owned_process(process, term_grace=20)
    except BaseException as error:
        if getattr(error, 'owned_cleanup_quiescent', None) is None:
            # Il primo segnale può interrompere anche prima di entrare nel
            # helper; conserva il primario e drena comunque il PGID proprio.
            error = cleanup_module.finish_owned_cleanup_after_error(
                process, error, term_grace=20)
        if not getattr(error, 'owned_cleanup_quiescent', False):
            cleanup_failed = True
            print(f"FAIL: cleanup visual command {type(error).__name__}", flush=True)
        if isinstance(error, (SystemExit, KeyboardInterrupt)):
            raise error


def run(command, timeout):
    global cleanup_failed
    process = subprocess.Popen(command, start_new_session=True)
    primary_failure = None
    try:
        code = process.wait(timeout=timeout)
        if code:
            primary_failure = SystemExit(code if code > 0 else 128 - code)
    except subprocess.TimeoutExpired:
        print(f"FAIL: verifica visuale timeout dopo {timeout}s", flush=True)
        primary_failure = SystemExit(124)
    except BaseException as error:
        primary_failure = error
    finally:
        try:
            stop_command(process)
        except BaseException as error:
            if getattr(error, 'owned_cleanup_quiescent', None) is None:
                error = cleanup_module.finish_owned_cleanup_after_error(
                    process, error, term_grace=20)
                if not error.owned_cleanup_quiescent:
                    # L'ingresso nel wrapper è ancora dentro il lifecycle own.
                    cleanup_failed = True
            if primary_failure is None:
                primary_failure = error
    if primary_failure is not None:
        raise primary_failure
    if cleanup_failed:
        raise SystemExit(1)


def interrupted(signum, _frame):
    signal.signal(signal.SIGTERM, signal.SIG_IGN)
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    raise SystemExit(128 + signum)


signal.signal(signal.SIGTERM, interrupted)
signal.signal(signal.SIGINT, interrupted)
primary_failure = None
cleanup_failed = False
try:
    if owns_device:
        developer = os.environ.get('DEVELOPER_DIR') or subprocess.check_output(
            ['xcode-select', '-p'], text=True, timeout=15).strip()
        simulator = developer + '/Applications/Simulator.app'
        if not os.path.isdir(simulator):
            raise SystemExit('BLOCKED: Simulator.app non disponibile nella toolchain selezionata')
        runtimes = json.loads(subprocess.check_output(
            ['xcrun', 'simctl', 'list', 'runtimes', '--json'], timeout=30))['runtimes']
        available = [r for r in runtimes if r.get('isAvailable') and
                     r['identifier'].startswith('com.apple.CoreSimulator.SimRuntime.iOS-26-')]
        if not available:
            raise SystemExit('BLOCKED: manca runtime iOS26 compatibile')
        runtime = sorted(available, key=lambda r: tuple(map(int, r['version'].split('.'))))[-1]
        device = subprocess.check_output(['xcrun', 'simctl', 'create', 'CMC-Task054-Visual',
            'com.apple.CoreSimulator.SimDeviceType.iPhone-17', runtime['identifier']],
            text=True, timeout=30).strip()
        run(['xcrun', 'simctl', 'boot', device], 60)
        run(['open', '-a', simulator, '--args', '-CurrentDeviceUDID', device], 60)
        run(['xcrun', 'simctl', 'bootstatus', device, '-b'], 300)
    else:
        device = sys.argv[2]
    if owns_device:
        os.environ['CMC_OS_FRAME_PLATFORM'] = 'ios'
        os.environ['CMC_OS_FRAME_DEVICE'] = device
    os_capture = bool(os.environ.get('CMC_OS_FRAME_PLATFORM') and
                      os.environ.get('CMC_OS_FRAME_DEVICE'))
    if (bool(os.environ.get('CMC_OS_FRAME_PLATFORM')) !=
            bool(os.environ.get('CMC_OS_FRAME_DEVICE')) or
            os_capture and (os.environ['CMC_OS_FRAME_PLATFORM'] not in ('android', 'ios') or
                            os.environ['CMC_OS_FRAME_DEVICE'] != device)):
        print('FAIL: contesto OS frame non corrisponde al device esplicito', flush=True)
        raise SystemExit(2)
    selection = os.environ.get('CMC_TASK054_VISUAL_SELECTION', 'full')
    if selection == 'full':
        run(['flutter', 'drive', '--no-pub', '--driver=test_driver/task054_visual.dart',
             '--target=integration_test/task054_visual_flow_test.dart', '-d', device,
             '--dart-define=CMC_VISUAL_CAPTURE=true',
             '--dart-define=CMC_OS_FRAME_CAPTURE=' + str(os_capture).lower()], 900)
    elif selection in ('review', 'review-after-inbox'):
        # Selezione nativa ufficiale Flutter: nessuno skip o cambio della fixture.
        names = ['recensione submit busy failure retry edit conserva commento']
        if selection == 'review-after-inbox':
            names = ['inbox non lette parziale raggiunge pagina2 e deduplica',
                     'inbox offline conserva cache e auth scaduta la elimina'] + names
        command = ['flutter', 'test', '--no-pub',
                   'integration_test/task054_next_integration_surfaces_test.dart', '-d', device]
        if selection == 'review':
            command += ['--plain-name', names[0]]
        else:
            command += ['--name', '^(?:' + '|'.join(re.escape(name) for name in names) + ')$']
        run(command, 900)
    else:
        raise SystemExit('FAIL: selezione visuale diagnostica non riconosciuta')
except BaseException as error:
    primary_failure = error
finally:
    if owns_device and device:
        for action in ('shutdown', 'delete'):
            try:
                result = subprocess.run(['xcrun', 'simctl', action, device],
                                        timeout=30, check=False)
                if result.returncode:
                    cleanup_failed = True
                    print(f"FAIL: cleanup {action} exit{result.returncode}", flush=True)
            except (OSError, subprocess.TimeoutExpired) as error:
                cleanup_failed = True
                print(f"FAIL: cleanup {action} {type(error).__name__}", flush=True)
if primary_failure is not None:
    raise primary_failure
if cleanup_failed:
    raise SystemExit(1)
PYCODE
