#!/usr/bin/env bash
set -euo pipefail
# Runner macOS26/Xcode26, target prodotto14.0 invariato. Simulatore creato dalla run.
cmc_runtime="$(xcrun simctl list runtimes --json | python3 -c 'import json,sys; r=[r for r in json.load(sys.stdin)["runtimes"] if r.get("isAvailable") and r["identifier"].startswith("com.apple.CoreSimulator.SimRuntime.iOS-26-")]; assert r, "Missing supported iOS26 runtime"; print(sorted(r,key=lambda r: tuple(map(int,r["version"].split("."))))[-1]["identifier"])')"
cmc_device="$(xcrun simctl create CMC-Task054 com.apple.CoreSimulator.SimDeviceType.iPhone-17 "$cmc_runtime")"
trap 'xcrun simctl shutdown "$cmc_device" || true; xcrun simctl delete "$cmc_device"' EXIT
xcrun simctl boot "$cmc_device"
xcrun simctl bootstatus "$cmc_device" -b
flutter test integration_test/app_shell_smoke_test.dart -d "$cmc_device" --reporter expanded
