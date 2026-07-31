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
cmc_fixture_positive_total=0
cmc_fixture_accepted=0

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
  shift
  cmc_fixture_total=$((cmc_fixture_total + 1))
  if CMC_SECURITY_REPO_ROOT="${cmc_fixture_path}" \
    bash "${cmc_fixture_validator}" "$@" >/dev/null 2>&1; then
    printf 'Fixture security negativa accettata: %s\n' \
      "${cmc_fixture_path##*/}" >&2
  else
    cmc_fixture_rejected=$((cmc_fixture_rejected + 1))
  fi
}

cmc_fixture_expect_acceptance() {
  local cmc_fixture_path="$1"
  shift
  cmc_fixture_positive_total=$((cmc_fixture_positive_total + 1))
  if CMC_SECURITY_REPO_ROOT="${cmc_fixture_path}" \
    bash "${cmc_fixture_validator}" "$@" >/dev/null 2>&1; then
    cmc_fixture_accepted=$((cmc_fixture_accepted + 1))
  else
    printf 'Fixture security positiva respinta: %s\n' \
      "${cmc_fixture_path##*/}" >&2
    CMC_SECURITY_REPO_ROOT="${cmc_fixture_path}" \
      bash "${cmc_fixture_validator}" "$@" >&2 || true
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

cmc_fixture_google_secret="$(cmc_fixture_prepare google-oauth-secret)"
printf '%s\n' \
  "const credential = 'GOCSPX-AAAAAAAAAAAAAAAAAAAAAAAAAAAA';" \
  >"${cmc_fixture_google_secret}/lib/main.dart"
git -C "${cmc_fixture_google_secret}" add lib/main.dart
cmc_fixture_expect_rejection "${cmc_fixture_google_secret}"

cmc_fixture_service_role="$(cmc_fixture_prepare legacy-service-role-jwt)"
printf '%s\n' \
  "const credential = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIn0.AAAAAAAAAAAAAAAAAAAA';" \
  >"${cmc_fixture_service_role}/lib/main.dart"
git -C "${cmc_fixture_service_role}" add lib/main.dart
cmc_fixture_expect_rejection "${cmc_fixture_service_role}"

cmc_fixture_nested_config="$(cmc_fixture_prepare nested-local-config)"
mkdir -p "${cmc_fixture_nested_config}/nested/config"
printf '{}\n' \
  >"${cmc_fixture_nested_config}/nested/config/staging.local.json"
git -C "${cmc_fixture_nested_config}" add nested/config/staging.local.json
cmc_fixture_expect_rejection "${cmc_fixture_nested_config}"

cmc_fixture_nested_env="$(cmc_fixture_prepare nested-env)"
mkdir -p "${cmc_fixture_nested_env}/nested"
printf 'FIXTURE=true\n' >"${cmc_fixture_nested_env}/nested/.env.staging"
git -C "${cmc_fixture_nested_env}" add -f nested/.env.staging
cmc_fixture_expect_rejection "${cmc_fixture_nested_env}"

cmc_fixture_newline="$(cmc_fixture_prepare newline-path)"
mkdir -p "${cmc_fixture_newline}/nested/config"
cmc_fixture_newline_relative=$'nested/config/break\nline.local.json'
printf '{}\n' >"${cmc_fixture_newline}/${cmc_fixture_newline_relative}"
git -C "${cmc_fixture_newline}" add -- "${cmc_fixture_newline_relative}"
cmc_fixture_expect_rejection "${cmc_fixture_newline}"

cmc_fixture_bundle="$(cmc_fixture_prepare bundle-secret)"
mkdir -p "${cmc_fixture_bundle}/artifact"
printf '%s\n' \
  "GOCSPX-BBBBBBBBBBBBBBBBBBBBBBBBBBBB" \
  >"${cmc_fixture_bundle}/artifact/bundle.bin"
cmc_fixture_expect_rejection \
  "${cmc_fixture_bundle}" \
  --artifact "${cmc_fixture_bundle}/artifact"

cmc_fixture_pem_bundle="$(cmc_fixture_prepare bundle-private-key)"
mkdir -p "${cmc_fixture_pem_bundle}/artifact"
printf '%s\n' \
  '-----BEGIN PRIVATE KEY-----' \
  'QUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFB' \
  '-----END PRIVATE KEY-----' \
  >"${cmc_fixture_pem_bundle}/artifact/bundle.bin"
cmc_fixture_expect_rejection \
  "${cmc_fixture_pem_bundle}" \
  --artifact "${cmc_fixture_pem_bundle}/artifact"

cmc_fixture_encrypted_pem="$(cmc_fixture_prepare bundle-encrypted-private-key)"
mkdir -p "${cmc_fixture_encrypted_pem}/artifact"
printf '%s\n' \
  '-----BEGIN ENCRYPTED PRIVATE KEY-----' \
  'QkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJC' \
  '-----END ENCRYPTED PRIVATE KEY-----' \
  >"${cmc_fixture_encrypted_pem}/artifact/bundle.bin"
cmc_fixture_expect_rejection \
  "${cmc_fixture_encrypted_pem}" \
  --artifact "${cmc_fixture_encrypted_pem}/artifact"

cmc_fixture_dsa_pem="$(cmc_fixture_prepare bundle-dsa-private-key)"
mkdir -p "${cmc_fixture_dsa_pem}/artifact"
printf '%s\n' \
  '-----BEGIN DSA PRIVATE KEY-----' \
  'Q0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0ND' \
  '-----END DSA PRIVATE KEY-----' \
  >"${cmc_fixture_dsa_pem}/artifact/bundle.bin"
cmc_fixture_expect_rejection \
  "${cmc_fixture_dsa_pem}" \
  --artifact "${cmc_fixture_dsa_pem}/artifact"

cmc_fixture_sensitive_bundle="$(cmc_fixture_prepare bundle-sensitive-path)"
mkdir -p "${cmc_fixture_sensitive_bundle}/artifact"
printf 'synthetic fixture\n' \
  >"${cmc_fixture_sensitive_bundle}/artifact/client.p12"
cmc_fixture_expect_rejection \
  "${cmc_fixture_sensitive_bundle}" \
  --artifact "${cmc_fixture_sensitive_bundle}/artifact"

cmc_fixture_upper_cert="$(cmc_fixture_prepare bundle-uppercase-certificate)"
mkdir -p "${cmc_fixture_upper_cert}/artifact"
printf 'synthetic fixture\n' \
  >"${cmc_fixture_upper_cert}/artifact/client.CER"
cmc_fixture_expect_rejection \
  "${cmc_fixture_upper_cert}" \
  --artifact "${cmc_fixture_upper_cert}/artifact"

cmc_fixture_unreadable_bundle="$(cmc_fixture_prepare bundle-unreadable)"
mkdir -p "${cmc_fixture_unreadable_bundle}/artifact"
printf 'synthetic fixture\n' \
  >"${cmc_fixture_unreadable_bundle}/artifact/unreadable.bin"
chmod 000 "${cmc_fixture_unreadable_bundle}/artifact/unreadable.bin"
cmc_fixture_expect_rejection \
  "${cmc_fixture_unreadable_bundle}" \
  --artifact "${cmc_fixture_unreadable_bundle}/artifact"
chmod 600 "${cmc_fixture_unreadable_bundle}/artifact/unreadable.bin"

cmc_fixture_symlink="$(cmc_fixture_prepare tracked-symlink-secret)"
ln -s \
  'GOCSPX-CCCCCCCCCCCCCCCCCCCCCCCCCCCC' \
  "${cmc_fixture_symlink}/lib/oauth-link"
git -C "${cmc_fixture_symlink}" add lib/oauth-link
cmc_fixture_expect_rejection "${cmc_fixture_symlink}"

cmc_fixture_publishable="$(cmc_fixture_prepare publishable-artifact)"
mkdir -p "${cmc_fixture_publishable}/artifact"
printf '%s\n' \
  'sb_publishable_fixture_public_value' \
  >"${cmc_fixture_publishable}/artifact/bundle.bin"
cmc_fixture_expect_acceptance \
  "${cmc_fixture_publishable}" \
  --artifact "${cmc_fixture_publishable}/artifact"

if [[ "${cmc_fixture_rejected}" -ne "${cmc_fixture_total}" ]]; then
  printf 'Fixture security respinte: %d/%d.\n' \
    "${cmc_fixture_rejected}" "${cmc_fixture_total}" >&2
  exit 1
fi

if [[ "${cmc_fixture_accepted}" -ne "${cmc_fixture_positive_total}" ]]; then
  printf 'Fixture security positive accettate: %d/%d.\n' \
    "${cmc_fixture_accepted}" "${cmc_fixture_positive_total}" >&2
  exit 1
fi

printf 'Fixture security negative respinte: %d/%d.\n' \
  "${cmc_fixture_rejected}" "${cmc_fixture_total}"
printf 'Fixture security positive accettate: %d/%d.\n' \
  "${cmc_fixture_accepted}" "${cmc_fixture_positive_total}"
