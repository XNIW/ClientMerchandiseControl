#!/usr/bin/env bash
set -euo pipefail

cmc_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_repo_root="$(cd -- "${cmc_script_dir}/.." && pwd)"

cd -- "${cmc_repo_root}"
dart run tool/check_release_metadata.dart
