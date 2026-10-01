#!/usr/bin/env bash
set -euo pipefail
# Catture di componenti produzione con fixture, mai E2E backend autenticato.
cmc_visual_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${cmc_visual_script_dir}/resolve-flutter.sh"
[[ $# -eq 1 && "$1" == '--ios' || $# -eq 2 && "$1" == '--device' ]] || {
  printf 'USAGE: test-task054-visual.sh --ios | --device OWNED_DEVICE_ID\n' >&2
  exit 2
}
python3 - "$@" <<'PYCODE'
import json
import os
import signal
import subprocess
import sys

device = None
owns_device = sys.argv[1] == '--ios'


def run(command, timeout):
    process = subprocess.Popen(command, start_new_session=True)
    try:
        code = process.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        print(f"FAIL: verifica visuale timeout dopo {timeout}s", flush=True)
        for sig in (signal.SIGTERM, signal.SIGKILL):
            try:
                os.killpg(process.pid, sig)
            except ProcessLookupError:
                pass
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                pass
        process.wait()
        raise SystemExit(124)
    if code:
        raise SystemExit(code)


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
    run(['flutter', 'drive', '--no-pub', '--driver=test_driver/task054_visual.dart',
         '--target=integration_test/task054_visual_flow_test.dart', '-d', device,
         '--dart-define=CMC_VISUAL_CAPTURE=true'], 900)
finally:
    if owns_device and device:
        for action in ('shutdown', 'delete'):
            subprocess.run(['xcrun', 'simctl', action, device], timeout=30, check=False)
PYCODE
