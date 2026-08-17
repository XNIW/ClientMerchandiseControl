#!/usr/bin/env bash
set -euo pipefail

cmc_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_fixture_root="$(mktemp -d)"
trap 'rm -rf -- "${cmc_fixture_root}"' EXIT

mkdir -p \
  "${cmc_fixture_root}/scripts" \
  "${cmc_fixture_root}/lib/app/design_system" \
  "${cmc_fixture_root}/lib/features/example/presentation"
cp "${cmc_script_dir}/check-user-facing-localization.sh" \
  "${cmc_fixture_root}/scripts/check-user-facing-localization.sh"

printf '%s\n' \
  "Widget buildLocalized(String label) => Text(label);" \
  "Widget buildComposed(String label) => Text('\${label}: 2');" \
  > "${cmc_fixture_root}/lib/features/example/presentation/pass.dart"

bash "${cmc_fixture_root}/scripts/check-user-facing-localization.sh" \
  | grep -F 'LOCALIZATION_SCAN_PASS' >/dev/null

printf '%s\n' \
  "Widget buildBroken() => const Text(" \
  "  'Hardcoded customer copy'," \
  ");" \
  "Widget buildTooltip() => const Tooltip(" \
  "  message: 'Hardcoded tooltip'," \
  "  child: SizedBox()," \
  ");" \
  > "${cmc_fixture_root}/lib/features/example/presentation/fail.dart"

set +e
cmc_output="$(
  bash "${cmc_fixture_root}/scripts/check-user-facing-localization.sh" 2>&1
)"
cmc_status=$?
set -e

if [[ ${cmc_status} -ne 1 ]] || \
  ! grep -F 'LOCALIZATION_SCAN_FAIL' <<<"${cmc_output}" >/dev/null || \
  ! grep -F 'Hardcoded customer copy' <<<"${cmc_output}" >/dev/null || \
  ! grep -F 'Hardcoded tooltip' <<<"${cmc_output}" >/dev/null; then
  printf 'LOCALIZATION_SCAN_FIXTURE_FAIL (exit=%s)\n%s\n' \
    "${cmc_status}" "${cmc_output}" >&2
  exit 1
fi

printf '%s\n' 'LOCALIZATION_SCAN_FIXTURES_PASS: 2/2.'
