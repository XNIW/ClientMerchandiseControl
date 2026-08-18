#!/usr/bin/env bash
set -euo pipefail

cmc_ios_attest_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_ios_attest_root="$(git -C "${cmc_ios_attest_script_dir}" rev-parse --show-toplevel)"
cmc_ios_attest_app=''

cmc_ios_attest_fail() {
  printf 'IOS_REFERENCE_ATTESTATION_BLOCKED: %s\n' "$1" >&2
  exit 1
}

if [[ "${1:-}" == '--app' && -n "${2:-}" && "$#" -eq 2 ]]; then
  cmc_ios_attest_app="$2"
else
  cmc_ios_attest_fail 'ARGUMENT_SET_INVALID'
fi

[[ -d "${cmc_ios_attest_app}" && ! -L "${cmc_ios_attest_app}" ]] || \
  cmc_ios_attest_fail 'REFERENCE_APP_NOT_READABLE'
cmc_ios_attest_app_canonical="$(cd -- "${cmc_ios_attest_app}" && pwd -P)"
cmc_ios_attest_expected_app="${cmc_ios_attest_root}/build/ios/iphoneos/Runner.app"
[[ -d "${cmc_ios_attest_expected_app}" ]] || \
  cmc_ios_attest_fail 'REFERENCE_APP_NOT_READABLE'
cmc_ios_attest_expected_app="$(cd -- "${cmc_ios_attest_expected_app}" && pwd -P)"
[[ "${cmc_ios_attest_app_canonical}" == "${cmc_ios_attest_expected_app}" ]] || \
  cmc_ios_attest_fail 'REFERENCE_APP_PATH_INVALID'

cmc_ios_attest_tmp_parent="${TMPDIR:-/tmp}"
cmc_ios_attest_tmp_parent="${cmc_ios_attest_tmp_parent%/}"
cmc_ios_attest_tmp_root="$(mktemp -d "${cmc_ios_attest_tmp_parent}/cmc-ios-reference.XXXXXX")"
cmc_ios_attest_cleanup() {
  case "${cmc_ios_attest_tmp_root}" in
    "${cmc_ios_attest_tmp_parent}"/cmc-ios-reference.*)
      rm -rf -- "${cmc_ios_attest_tmp_root}"
      ;;
    *)
      printf 'Cleanup reference iOS rifiutato.\n' >&2
      ;;
  esac
}
trap cmc_ios_attest_cleanup EXIT

cmc_ios_attest_paths=(
  'Frameworks/App.framework/App'
  'Frameworks/Flutter.framework/Flutter'
  'Frameworks/objective_c.framework/objective_c'
  'Frameworks/sqlite3.framework/sqlite3'
)
cmc_ios_attest_digests=()

for cmc_ios_attest_index in "${!cmc_ios_attest_paths[@]}"; do
  cmc_ios_attest_source="${cmc_ios_attest_app}/${cmc_ios_attest_paths[cmc_ios_attest_index]}"
  [[ -f "${cmc_ios_attest_source}" && ! -L "${cmc_ios_attest_source}" ]] || \
    cmc_ios_attest_fail 'REFERENCE_MACHO_SET_INVALID'
  file "${cmc_ios_attest_source}" | grep -Fq 'Mach-O' || \
    cmc_ios_attest_fail 'REFERENCE_MACHO_SET_INVALID'
  [[ "$(lipo -archs "${cmc_ios_attest_source}" 2>/dev/null)" == 'arm64' ]] || \
    cmc_ios_attest_fail 'REFERENCE_MACHO_ARCHITECTURE_INVALID'
  cmc_ios_attest_copy="${cmc_ios_attest_tmp_root}/macho-${cmc_ios_attest_index}"
  cp "${cmc_ios_attest_source}" "${cmc_ios_attest_copy}" || \
    cmc_ios_attest_fail 'REFERENCE_COMPONENT_DIGEST_UNREADABLE'
  chmod u+w "${cmc_ios_attest_copy}" || \
    cmc_ios_attest_fail 'REFERENCE_COMPONENT_DIGEST_UNREADABLE'
  codesign --remove-signature "${cmc_ios_attest_copy}" \
    >/dev/null 2>&1 || true
  codesign --force --sign - "${cmc_ios_attest_copy}" \
    >/dev/null 2>&1 || \
    cmc_ios_attest_fail 'REFERENCE_COMPONENT_DIGEST_UNREADABLE'
  codesign --remove-signature "${cmc_ios_attest_copy}" \
    >/dev/null 2>&1 || \
    cmc_ios_attest_fail 'REFERENCE_COMPONENT_DIGEST_UNREADABLE'
  cmc_ios_attest_digest="$(
    shasum -a 256 "${cmc_ios_attest_copy}" | awk '{print $1}'
  )"
  [[ "${cmc_ios_attest_digest}" =~ ^[0-9a-f]{64}$ ]] || \
    cmc_ios_attest_fail 'REFERENCE_COMPONENT_DIGEST_UNREADABLE'
  cmc_ios_attest_digests+=("${cmc_ios_attest_digest}")
done

cmc_ios_attest_joined="$(
  IFS=','
  printf '%s' "${cmc_ios_attest_digests[*]}"
)"
printf 'IOS_REFERENCE_ATTESTATION=%s\n' "${cmc_ios_attest_joined}"
