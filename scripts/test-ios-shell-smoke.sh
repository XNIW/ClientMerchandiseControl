#!/usr/bin/env bash
set -euo pipefail
# Runner macOS26/Xcode26, target prodotto14.0 invariato. Simulatore creato dalla run.
cmc_runtime="$(xcrun simctl list runtimes --json | python3 -c 'import json,sys; r=[r for r in json.load(sys.stdin)["runtimes"] if r.get("isAvailable") and r["identifier"].startswith("com.apple.CoreSimulator.SimRuntime.iOS-26-")]; assert r, "Missing supported iOS26 runtime"; print(sorted(r,key=lambda r: tuple(map(int,r["version"].split("."))))[-1]["identifier"])')"
cmc_device="$(xcrun simctl create CMC-Task054 com.apple.CoreSimulator.SimDeviceType.iPhone-17 "$cmc_runtime")"
# Un processo Flutter bloccato deve fallire prima del timeout del job, lasciando
# visibile l'ultimo comando install/launch/discovery. Si termina solo il suo gruppo.
python3 - "$cmc_device" <<'PY'
import os
import signal
import subprocess
import sys

device = sys.argv[1]


def run(command, timeout):
    print("+ " + " ".join(command), flush=True)
    process = subprocess.Popen(command, start_new_session=True)
    try:
        code = process.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        print(f"FAIL: timeout dopo {timeout}s", flush=True)
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            pass
        # Il leader può essere già uscito mentre un figlio ignora SIGTERM.
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait()
        raise SystemExit(124)
    if code:
        raise SystemExit(code)


try:
    developer = os.environ.get("DEVELOPER_DIR") or subprocess.check_output(
        ["xcode-select", "-p"], text=True, timeout=15
    ).strip()
    run(["xcrun", "simctl", "boot", device], 60)
    run(["open", "-a", f"{developer}/Applications/Simulator.app",
         "--args", "-CurrentDeviceUDID", device], 60)
    run(["xcrun", "simctl", "bootstatus", device, "-b"], 300)
    run(["flutter", "test", "integration_test/app_shell_smoke_test.dart",
         "-d", device, "--no-pub", "--reporter", "expanded", "--verbose"], 900)
finally:
    # Stato tecnico, senza esportare dati applicativi o argomenti dei processi.
    for command in (["xcrun", "simctl", "list", "devices", "booted"],
                    ["ps", "-axo", "pid,ppid,stat,comm"],
                    ["xcrun", "simctl", "shutdown", device],
                    ["xcrun", "simctl", "delete", device]):
        try:
            subprocess.run(command, timeout=30, check=False)
        except subprocess.TimeoutExpired:
            print("Diagnostica/cleanup non concluso: " + command[0], flush=True)
PY
