#!/usr/bin/env bash
set -euo pipefail

cmc_fixture_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_fixture_validator="${cmc_fixture_script_dir}/check-client-security.sh"
cmc_fixture_tmp_parent="${TMPDIR:-/tmp}"
cmc_fixture_tmp_parent="${cmc_fixture_tmp_parent%/}"
cmc_fixture_root="$(
  mktemp -d "${cmc_fixture_tmp_parent}/cmc-security-fixtures.XXXXXX"
)"
cmc_fixture_total=0
cmc_fixture_rejected=0

cmc_fixture_cleanup() {
  case "${cmc_fixture_root}" in
    "${cmc_fixture_tmp_parent}"/cmc-security-fixtures.*)
      rm -rf -- "${cmc_fixture_root}"
      ;;
    *)
      printf 'Cleanup fixture security rifiutato per path inatteso.\n' >&2
      ;;
  esac
}

trap cmc_fixture_cleanup EXIT

cmc_fixture_prepare() {
  local cmc_fixture_name="$1"
  local cmc_fixture_path="${cmc_fixture_root}/${cmc_fixture_name}"
  mkdir -p "${cmc_fixture_path}/lib"
  git -C "${cmc_fixture_path}" init -q
  printf 'void main() {}\n' >"${cmc_fixture_path}/lib/main.dart"
  git -C "${cmc_fixture_path}" add lib/main.dart
  printf '%s\n' "${cmc_fixture_path}"
}

cmc_fixture_expect_rejection() {
  local cmc_fixture_path="$1"
  cmc_fixture_total=$((cmc_fixture_total + 1))
  if CMC_SECURITY_REPO_ROOT="${cmc_fixture_path}" \
    bash "${cmc_fixture_validator}" >/dev/null 2>&1; then
    printf 'Fixture security negativa accettata: %s\n' \
      "${cmc_fixture_path##*/}" >&2
  else
    cmc_fixture_rejected=$((cmc_fixture_rejected + 1))
  fi
}

bash "${cmc_fixture_validator}"

cmc_fixture_secret="$(cmc_fixture_prepare secret-shaped)"
printf '%s\n' \
  "const credential = 'sb_secret_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';" \
  >"${cmc_fixture_secret}/lib/main.dart"
git -C "${cmc_fixture_secret}" add lib/main.dart
cmc_fixture_expect_rejection "${cmc_fixture_secret}"

cmc_fixture_config="$(cmc_fixture_prepare tracked-local-config)"
mkdir -p "${cmc_fixture_config}/config"
printf '{}\n' >"${cmc_fixture_config}/config/staging.local.json"
git -C "${cmc_fixture_config}" add -f config/staging.local.json
cmc_fixture_expect_rejection "${cmc_fixture_config}"

cmc_fixture_artifact="$(cmc_fixture_prepare tracked-artifact)"
mkdir -p "${cmc_fixture_artifact}/coverage"
printf 'fixture\n' >"${cmc_fixture_artifact}/coverage/lcov.info"
git -C "${cmc_fixture_artifact}" add -f coverage/lcov.info
cmc_fixture_expect_rejection "${cmc_fixture_artifact}"

if [[ "${cmc_fixture_rejected}" -ne "${cmc_fixture_total}" ]]; then
  printf 'Fixture security respinte: %d/%d.\n' \
    "${cmc_fixture_rejected}" "${cmc_fixture_total}" >&2
  exit 1
fi

printf 'Fixture security negative respinte: %d/%d.\n' \
  "${cmc_fixture_rejected}" "${cmc_fixture_total}"
