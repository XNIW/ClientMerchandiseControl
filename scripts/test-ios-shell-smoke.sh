#!/usr/bin/env bash
set -euo pipefail
# Smoke autonomo; --device prende in prestito il simulatore della run senza boot/delete.
cmc_smoke_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
[[ $# -eq 0 || $# -eq 2 && "$1" == '--device' || $# -eq 4 && "$1" == '--device' && "$3" == '--receipt' ]] || {
  printf 'USAGE: test-ios-shell-smoke.sh [--device OWNED_IOS_UUID [--receipt PATH]]\n' >&2
  exit 2
}
exec python3 "${cmc_smoke_script_dir}/run-task054-ios-owned.py" smoke "$@"
