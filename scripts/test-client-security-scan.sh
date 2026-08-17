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
cmc_fixture_real_git="$(command -v git)"

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

cmc_fixture_token_body='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
cmc_fixture_supabase_prefix='sb_'
cmc_fixture_supabase_value="${cmc_fixture_supabase_prefix}secret_${cmc_fixture_token_body}"
cmc_fixture_google_prefix='GOC'
cmc_fixture_google_value="${cmc_fixture_google_prefix}SPX-${cmc_fixture_token_body}"
cmc_fixture_maps_prefix='AI'
cmc_fixture_maps_value="${cmc_fixture_maps_prefix}za${cmc_fixture_token_body}AAA"
cmc_fixture_overlap_prefix='gh'
cmc_fixture_overlap_value="${cmc_fixture_maps_prefix}za${cmc_fixture_overlap_prefix}p_${cmc_fixture_token_body%?}"
cmc_fixture_maps_sdk_prefix='X-Ios-Bundle-Identifier'
cmc_fixture_maps_sdk_quota='DeductQuota'
cmc_fixture_maps_sdk_platform='unknown_ios'
cmc_fixture_maps_sdk_service='mapsmobilesdks-pa.googleapis.com'
cmc_fixture_maps_sdk_places='places.googleapis.com'
cmc_fixture_jwt_header='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
cmc_fixture_jwt_payload='eyJyb2xlIjoic2VydmljZV9yb2xlIn0'
cmc_fixture_jwt_value="${cmc_fixture_jwt_header}.${cmc_fixture_jwt_payload}.${cmc_fixture_token_body}"
cmc_fixture_customer_jwt_payload='eyJyb2xlIjoiYXV0aGVudGljYXRlZCJ9'
cmc_fixture_customer_jwt_value="${cmc_fixture_jwt_header}.${cmc_fixture_customer_jwt_payload}.${cmc_fixture_token_body}"
cmc_fixture_unknown_jwt_payload='eyJyb2xlIjoiZWRpdG9yIn0'
cmc_fixture_unknown_jwt_value="${cmc_fixture_jwt_header}.${cmc_fixture_unknown_jwt_payload}.${cmc_fixture_token_body}"
cmc_fixture_invalid_jwt_payload='bm90LWpzb24'
cmc_fixture_invalid_jwt_value="${cmc_fixture_jwt_header}.${cmc_fixture_invalid_jwt_payload}.${cmc_fixture_token_body}"
cmc_fixture_missing_role_jwt_payload='eyJzdWIiOiJjdXN0b21lciJ9'
cmc_fixture_missing_role_jwt_value="${cmc_fixture_jwt_header}.${cmc_fixture_missing_role_jwt_payload}.${cmc_fixture_token_body}"
cmc_fixture_duplicate_role_jwt_payload='eyJyb2xlIjoiYW5vbiIsInJvbGUiOiJhdXRoZW50aWNhdGVkIn0'
cmc_fixture_duplicate_role_jwt_value="${cmc_fixture_jwt_header}.${cmc_fixture_duplicate_role_jwt_payload}.${cmc_fixture_token_body}"
cmc_fixture_escaped_role_jwt_payload='eyJcdTAwNzJvbGUiOiJhdXRoZW50aWNhdGVkIiwicm9sZSI6ImFub24ifQ'
cmc_fixture_escaped_role_jwt_value="${cmc_fixture_jwt_header}.${cmc_fixture_escaped_role_jwt_payload}.${cmc_fixture_token_body}"
cmc_fixture_nul_jwt_payload='eyJyb2xlIjoiYW4Ab24ifQ'
cmc_fixture_nul_jwt_value="${cmc_fixture_jwt_header}.${cmc_fixture_nul_jwt_payload}.${cmc_fixture_token_body}"
cmc_fixture_anon_jwt_payload='eyJyb2xlIjoiYW5vbiJ9'
cmc_fixture_anon_jwt_value="${cmc_fixture_jwt_header}.${cmc_fixture_anon_jwt_payload}.${cmc_fixture_token_body}"
cmc_fixture_pem_fence='-----'
cmc_fixture_private_key_label='PRIVATE KEY'
cmc_fixture_rsa_key_label='RSA PRIVATE KEY'
cmc_fixture_ec_key_label='EC PRIVATE KEY'
cmc_fixture_encrypted_key_label='ENCRYPTED PRIVATE KEY'
cmc_fixture_dsa_key_label='DSA PRIVATE KEY'

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

cmc_fixture_expect_rejection_with_path() {
  local cmc_fixture_path="$1"
  local cmc_fixture_path_prefix="$2"
  shift 2
  cmc_fixture_total=$((cmc_fixture_total + 1))
  if CMC_FIXTURE_REAL_GIT="${cmc_fixture_real_git}" \
    PATH="${cmc_fixture_path_prefix}:${PATH}" \
    CMC_SECURITY_REPO_ROOT="${cmc_fixture_path}" \
    bash "${cmc_fixture_validator}" "$@" >/dev/null 2>&1; then
    printf 'Fixture security negativa accettata: %s\n' \
      "${cmc_fixture_path##*/}" >&2
  else
    cmc_fixture_rejected=$((cmc_fixture_rejected + 1))
  fi
}

bash "${cmc_fixture_validator}"

cmc_fixture_git_failure="$(cmc_fixture_prepare git-enumerator-failure)"
cmc_fixture_git_failure_bin="${cmc_fixture_git_failure}/tool-shim"
mkdir -p "${cmc_fixture_git_failure_bin}"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'if [[ "$*" == *"ls-files --stage -z"* ]]; then' \
  "  printf '100644 0000000000000000000000000000000000000000 0\\tlib/main.dart\\0'" \
  '  exit 77' \
  'fi' \
  'exec "${CMC_FIXTURE_REAL_GIT}" "$@"' \
  >"${cmc_fixture_git_failure_bin}/git"
chmod 700 "${cmc_fixture_git_failure_bin}/git"
cmc_fixture_expect_rejection_with_path \
  "${cmc_fixture_git_failure}" \
  "${cmc_fixture_git_failure_bin}"

cmc_fixture_secret="$(cmc_fixture_prepare secret-shaped)"
printf '%s\n' \
  "const credential = '${cmc_fixture_supabase_value}';" \
  >"${cmc_fixture_secret}/lib/main.dart"
git -C "${cmc_fixture_secret}" add lib/main.dart
cmc_fixture_expect_rejection "${cmc_fixture_secret}"

cmc_fixture_scanner_script="$(
  cmc_fixture_prepare scanner-script-secret
)"
mkdir -p "${cmc_fixture_scanner_script}/scripts"
printf '%s\n' "${cmc_fixture_supabase_value}" \
  >"${cmc_fixture_scanner_script}/scripts/check-client-security.sh"
git -C "${cmc_fixture_scanner_script}" add -- \
  scripts/check-client-security.sh
cmc_fixture_expect_rejection "${cmc_fixture_scanner_script}"

cmc_fixture_test_script="$(
  cmc_fixture_prepare scanner-test-script-secret
)"
mkdir -p "${cmc_fixture_test_script}/scripts"
printf '%s\n' "${cmc_fixture_supabase_value}" \
  >"${cmc_fixture_test_script}/scripts/test-client-security-scan.sh"
git -C "${cmc_fixture_test_script}" add -- \
  scripts/test-client-security-scan.sh
cmc_fixture_expect_rejection "${cmc_fixture_test_script}"

cmc_fixture_masked_index_secret="$(
  cmc_fixture_prepare masked-index-secret
)"
mkdir -p "${cmc_fixture_masked_index_secret}/scripts"
printf '%s\n' "${cmc_fixture_supabase_value}" \
  >"${cmc_fixture_masked_index_secret}/scripts/check-client-security.sh"
git -C "${cmc_fixture_masked_index_secret}" add -- \
  scripts/check-client-security.sh
printf 'safe fixture\n' \
  >"${cmc_fixture_masked_index_secret}/scripts/check-client-security.sh"
cmc_fixture_expect_rejection "${cmc_fixture_masked_index_secret}"

cmc_fixture_worktree_symlink="$(
  cmc_fixture_prepare worktree-symlink-secret
)"
ln -s 'safe-fixture' \
  "${cmc_fixture_worktree_symlink}/lib/oauth-worktree-link"
git -C "${cmc_fixture_worktree_symlink}" add -- \
  lib/oauth-worktree-link
rm "${cmc_fixture_worktree_symlink}/lib/oauth-worktree-link"
ln -s "${cmc_fixture_google_value}" \
  "${cmc_fixture_worktree_symlink}/lib/oauth-worktree-link"
cmc_fixture_expect_rejection "${cmc_fixture_worktree_symlink}"

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
  "const credential = '${cmc_fixture_google_value}';" \
  >"${cmc_fixture_google_secret}/lib/main.dart"
git -C "${cmc_fixture_google_secret}" add lib/main.dart
cmc_fixture_expect_rejection "${cmc_fixture_google_secret}"

cmc_fixture_service_role="$(cmc_fixture_prepare legacy-service-role-jwt)"
printf '%s\n' \
  "const credential = '${cmc_fixture_jwt_value}';" \
  >"${cmc_fixture_service_role}/lib/main.dart"
git -C "${cmc_fixture_service_role}" add lib/main.dart
cmc_fixture_expect_rejection "${cmc_fixture_service_role}"

cmc_fixture_decode_failure_bin="${cmc_fixture_service_role}/decode-shim"
mkdir -p "${cmc_fixture_decode_failure_bin}"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'exit 77' \
  >"${cmc_fixture_decode_failure_bin}/openssl"
chmod 700 "${cmc_fixture_decode_failure_bin}/openssl"
cmc_fixture_expect_rejection_with_path \
  "${cmc_fixture_service_role}" \
  "${cmc_fixture_decode_failure_bin}"

cmc_fixture_customer_source="$(
  cmc_fixture_prepare customer-jwt-source
)"
printf '%s\n' \
  "const credential = '${cmc_fixture_customer_jwt_value}';" \
  >"${cmc_fixture_customer_source}/lib/main.dart"
git -C "${cmc_fixture_customer_source}" add lib/main.dart
cmc_fixture_expect_rejection "${cmc_fixture_customer_source}"

cmc_fixture_customer_index="$(
  cmc_fixture_prepare customer-jwt-index
)"
printf '%s\n' \
  "const credential = '${cmc_fixture_customer_jwt_value}';" \
  >"${cmc_fixture_customer_index}/lib/main.dart"
git -C "${cmc_fixture_customer_index}" add lib/main.dart
printf 'void main() {}\n' >"${cmc_fixture_customer_index}/lib/main.dart"
cmc_fixture_expect_rejection "${cmc_fixture_customer_index}"

cmc_fixture_customer_worktree="$(
  cmc_fixture_prepare customer-jwt-worktree
)"
printf '%s\n' \
  "const credential = '${cmc_fixture_customer_jwt_value}';" \
  >"${cmc_fixture_customer_worktree}/lib/main.dart"
cmc_fixture_expect_rejection "${cmc_fixture_customer_worktree}"

cmc_fixture_customer_artifact="$(
  cmc_fixture_prepare customer-jwt-artifact
)"
mkdir -p "${cmc_fixture_customer_artifact}/artifact"
printf '%s\n' \
  "${cmc_fixture_customer_jwt_value}" \
  >"${cmc_fixture_customer_artifact}/artifact/bundle.bin"
cmc_fixture_expect_rejection \
  "${cmc_fixture_customer_artifact}" \
  --artifact "${cmc_fixture_customer_artifact}/artifact"

cmc_fixture_unknown_role="$(
  cmc_fixture_prepare unknown-role-jwt
)"
printf '%s\n' \
  "const credential = '${cmc_fixture_unknown_jwt_value}';" \
  >"${cmc_fixture_unknown_role}/lib/main.dart"
git -C "${cmc_fixture_unknown_role}" add lib/main.dart
cmc_fixture_expect_rejection "${cmc_fixture_unknown_role}"

cmc_fixture_invalid_payload="$(
  cmc_fixture_prepare invalid-json-jwt
)"
printf '%s\n' \
  "const credential = '${cmc_fixture_invalid_jwt_value}';" \
  >"${cmc_fixture_invalid_payload}/lib/main.dart"
git -C "${cmc_fixture_invalid_payload}" add lib/main.dart
cmc_fixture_expect_rejection "${cmc_fixture_invalid_payload}"

cmc_fixture_missing_role="$(
  cmc_fixture_prepare missing-role-jwt
)"
printf '%s\n' \
  "const credential = '${cmc_fixture_missing_role_jwt_value}';" \
  >"${cmc_fixture_missing_role}/lib/main.dart"
git -C "${cmc_fixture_missing_role}" add lib/main.dart
cmc_fixture_expect_rejection "${cmc_fixture_missing_role}"

cmc_fixture_duplicate_role="$(
  cmc_fixture_prepare duplicate-role-jwt
)"
printf '%s\n' \
  "const credential = '${cmc_fixture_duplicate_role_jwt_value}';" \
  >"${cmc_fixture_duplicate_role}/lib/main.dart"
git -C "${cmc_fixture_duplicate_role}" add lib/main.dart
cmc_fixture_expect_rejection "${cmc_fixture_duplicate_role}"

cmc_fixture_escaped_role="$(
  cmc_fixture_prepare escaped-role-jwt
)"
printf '%s\n' \
  "const credential = '${cmc_fixture_escaped_role_jwt_value}';" \
  >"${cmc_fixture_escaped_role}/lib/main.dart"
git -C "${cmc_fixture_escaped_role}" add lib/main.dart
cmc_fixture_expect_rejection "${cmc_fixture_escaped_role}"

cmc_fixture_nul_payload="$(
  cmc_fixture_prepare nul-payload-jwt
)"
printf '%s\n' \
  "const credential = '${cmc_fixture_nul_jwt_value}';" \
  >"${cmc_fixture_nul_payload}/lib/main.dart"
git -C "${cmc_fixture_nul_payload}" add lib/main.dart
cmc_fixture_expect_rejection "${cmc_fixture_nul_payload}"

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
  "${cmc_fixture_google_value}" \
  >"${cmc_fixture_bundle}/artifact/bundle.bin"
cmc_fixture_expect_rejection \
  "${cmc_fixture_bundle}" \
  --artifact "${cmc_fixture_bundle}/artifact"

cmc_fixture_aab_secret="$(cmc_fixture_prepare aab-deflated-secret)"
mkdir -p \
  "${cmc_fixture_aab_secret}/artifact/input/base/assets/flutter_assets"
printf '%s\n' \
  "${cmc_fixture_google_value}" \
  >"${cmc_fixture_aab_secret}/artifact/input/base/assets/flutter_assets/config.bin"
(
  cd "${cmc_fixture_aab_secret}/artifact/input"
  zip -q -9 -r ../candidate.aab .
)
cmc_fixture_expect_rejection \
  "${cmc_fixture_aab_secret}" \
  --artifact "${cmc_fixture_aab_secret}/artifact/candidate.aab"

cmc_fixture_aab_renamed="$(cmc_fixture_prepare aab-renamed-deflated-secret)"
mkdir -p \
  "${cmc_fixture_aab_renamed}/artifact/input/base/assets/flutter_assets"
printf '%s\n' \
  "${cmc_fixture_google_value}" \
  >"${cmc_fixture_aab_renamed}/artifact/input/base/assets/flutter_assets/config.bin"
(
  cd "${cmc_fixture_aab_renamed}/artifact/input"
  zip -q -9 -r ../candidate.bundle .
)
cmc_fixture_expect_rejection \
  "${cmc_fixture_aab_renamed}" \
  --artifact "${cmc_fixture_aab_renamed}/artifact/candidate.bundle"
cp \
  "${cmc_fixture_aab_renamed}/artifact/candidate.bundle" \
  "${cmc_fixture_aab_renamed}/artifact/candidate.AAB"
cmc_fixture_expect_rejection \
  "${cmc_fixture_aab_renamed}" \
  --artifact "${cmc_fixture_aab_renamed}/artifact/candidate.AAB"
cp \
  "${cmc_fixture_aab_renamed}/artifact/candidate.bundle" \
  "${cmc_fixture_aab_renamed}/artifact/candidate"
cmc_fixture_expect_rejection \
  "${cmc_fixture_aab_renamed}" \
  --artifact "${cmc_fixture_aab_renamed}/artifact/candidate"

cmc_fixture_aab_secret_name="$(cmc_fixture_prepare aab-secret-entry-name)"
mkdir -p \
  "${cmc_fixture_aab_secret_name}/artifact/input/base/assets/${cmc_fixture_google_value}"
printf '%s\n' \
  'public fixture payload' \
  >"${cmc_fixture_aab_secret_name}/artifact/input/base/assets/${cmc_fixture_google_value}/payload.bin"
(
  cd "${cmc_fixture_aab_secret_name}/artifact/input"
  zip -q -9 -r ../candidate.aab .
)
cmc_fixture_expect_rejection \
  "${cmc_fixture_aab_secret_name}" \
  --artifact "${cmc_fixture_aab_secret_name}/artifact/candidate.aab"

cmc_fixture_aab_secret_comment="$(cmc_fixture_prepare aab-secret-comment)"
mkdir -p \
  "${cmc_fixture_aab_secret_comment}/artifact/input/base/assets/flutter_assets"
printf '%s\n' \
  'public fixture payload' \
  >"${cmc_fixture_aab_secret_comment}/artifact/input/base/assets/flutter_assets/config.bin"
(
  cd "${cmc_fixture_aab_secret_comment}/artifact/input"
  zip -q -9 -r ../candidate.aab .
  printf '%s\n' "${cmc_fixture_google_value}" | zip -q -z ../candidate.aab
)
cmc_fixture_expect_rejection \
  "${cmc_fixture_aab_secret_comment}" \
  --artifact "${cmc_fixture_aab_secret_comment}/artifact/candidate.aab"

cmc_fixture_aab_entry_comment="$(cmc_fixture_prepare aab-secret-entry-comment)"
mkdir -p \
  "${cmc_fixture_aab_entry_comment}/artifact/input/base/assets/flutter_assets"
printf '%s\n' \
  'public fixture payload' \
  >"${cmc_fixture_aab_entry_comment}/artifact/input/base/assets/flutter_assets/config.bin"
(
  cd "${cmc_fixture_aab_entry_comment}/artifact/input"
  printf '%s\n' "${cmc_fixture_google_value}" | \
    zip -q -9 -c ../candidate.aab \
      base/assets/flutter_assets/config.bin
)
cmc_fixture_expect_rejection \
  "${cmc_fixture_aab_entry_comment}" \
  --artifact "${cmc_fixture_aab_entry_comment}/artifact/candidate.aab"

cmc_fixture_aab_expansion="$(cmc_fixture_prepare aab-expansion-bound)"
mkdir -p \
  "${cmc_fixture_aab_expansion}/artifact/input/base/assets/flutter_assets"
dd if=/dev/zero \
  of="${cmc_fixture_aab_expansion}/artifact/input/base/assets/flutter_assets/zeros.bin" \
  bs=1048576 count=2 2>/dev/null
(
  cd "${cmc_fixture_aab_expansion}/artifact/input"
  zip -q -9 -r ../candidate.aab .
)
cmc_fixture_expect_rejection \
  "${cmc_fixture_aab_expansion}" \
  --artifact "${cmc_fixture_aab_expansion}/artifact/candidate.aab"

cmc_fixture_aab_forged_size="$(cmc_fixture_prepare aab-forged-size-bound)"
mkdir -p "${cmc_fixture_aab_forged_size}/artifact/input"
dd if=/dev/zero \
  of="${cmc_fixture_aab_forged_size}/artifact/input/payload.bin" \
  bs=1048576 count=16 2>/dev/null
(
  cd "${cmc_fixture_aab_forged_size}/artifact/input"
  zip -q -9 ../candidate.aab payload.bin
)
perl -0777 -pi -e '
  my $declared = 2000000;
  my $local = index($_, "PK\x03\x04");
  my $central = index($_, "PK\x01\x02");
  die "fixture ZIP signature missing\n" if $local < 0 || $central < 0;
  substr($_, $local + 22, 4) = pack("V", $declared);
  substr($_, $central + 24, 4) = pack("V", $declared);
' "${cmc_fixture_aab_forged_size}/artifact/candidate.aab"
cmc_fixture_expect_rejection \
  "${cmc_fixture_aab_forged_size}" \
  --artifact "${cmc_fixture_aab_forged_size}/artifact/candidate.aab"

cmc_fixture_aab_entry_bound="$(cmc_fixture_prepare aab-entry-count-bound)"
mkdir -p "${cmc_fixture_aab_entry_bound}/artifact/input/entries"
for ((cmc_fixture_entry_index = 0; cmc_fixture_entry_index < 2049; cmc_fixture_entry_index++)); do
  : >"${cmc_fixture_aab_entry_bound}/artifact/input/entries/entry-${cmc_fixture_entry_index}"
done
(
  cd "${cmc_fixture_aab_entry_bound}/artifact/input"
  zip -q -9 -r ../candidate.aab .
)
cmc_fixture_expect_rejection \
  "${cmc_fixture_aab_entry_bound}" \
  --artifact "${cmc_fixture_aab_entry_bound}/artifact/candidate.aab"

cmc_fixture_aab_public="$(cmc_fixture_prepare aab-deflated-public)"
mkdir -p \
  "${cmc_fixture_aab_public}/artifact/input/base/assets/flutter_assets"
printf '%s\n' \
  'release fixture without privileged configuration' \
  >"${cmc_fixture_aab_public}/artifact/input/base/assets/flutter_assets/config.bin"
(
  cd "${cmc_fixture_aab_public}/artifact/input"
  zip -q -9 -r ../candidate.aab .
)
cmc_fixture_expect_acceptance \
  "${cmc_fixture_aab_public}" \
  --artifact "${cmc_fixture_aab_public}/artifact/candidate.aab"

cmc_fixture_maps_near_miss="$(
  cmc_fixture_prepare bundle-maps-sdk-near-miss
)"
mkdir -p "${cmc_fixture_maps_near_miss}/artifact"
printf '%s\0%s\0%s\0%s\0%s\n' \
  "${cmc_fixture_maps_sdk_prefix}" \
  "${cmc_fixture_maps_sdk_quota}" \
  "${cmc_fixture_maps_value}" \
  "${cmc_fixture_maps_sdk_platform}" \
  'example.invalid' \
  >"${cmc_fixture_maps_near_miss}/artifact/bundle.bin"
cmc_fixture_expect_rejection \
  "${cmc_fixture_maps_near_miss}" \
  --artifact "${cmc_fixture_maps_near_miss}/artifact"

cmc_fixture_maps_mixed="$(cmc_fixture_prepare bundle-maps-sdk-mixed-secret)"
mkdir -p "${cmc_fixture_maps_mixed}/artifact"
printf '%s\0%s\0%s\0%s\0%s\0%s\n%s\n' \
  "${cmc_fixture_maps_sdk_prefix}" \
  "${cmc_fixture_maps_sdk_quota}" \
  "${cmc_fixture_maps_value}" \
  "${cmc_fixture_maps_sdk_platform}" \
  "${cmc_fixture_maps_sdk_service}" \
  "${cmc_fixture_maps_sdk_places}" \
  "${cmc_fixture_google_value}" \
  >"${cmc_fixture_maps_mixed}/artifact/bundle.bin"
cmc_fixture_expect_rejection \
  "${cmc_fixture_maps_mixed}" \
  --artifact "${cmc_fixture_maps_mixed}/artifact"

cmc_fixture_maps_overlap="$(cmc_fixture_prepare bundle-maps-sdk-overlap-secret)"
mkdir -p "${cmc_fixture_maps_overlap}/artifact"
printf '%s\0%s\0%s\0%s\0%s\0%s\n' \
  "${cmc_fixture_maps_sdk_prefix}" \
  "${cmc_fixture_maps_sdk_quota}" \
  "${cmc_fixture_overlap_value}" \
  "${cmc_fixture_maps_sdk_platform}" \
  "${cmc_fixture_maps_sdk_service}" \
  "${cmc_fixture_maps_sdk_places}" \
  >"${cmc_fixture_maps_overlap}/artifact/bundle.bin"
cmc_fixture_expect_rejection \
  "${cmc_fixture_maps_overlap}" \
  --artifact "${cmc_fixture_maps_overlap}/artifact"

cmc_fixture_pem_bundle="$(cmc_fixture_prepare bundle-private-key)"
mkdir -p "${cmc_fixture_pem_bundle}/artifact"
printf '%s\n' \
  "${cmc_fixture_pem_fence}BEGIN ${cmc_fixture_private_key_label}${cmc_fixture_pem_fence}" \
  'QUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFB' \
  "${cmc_fixture_pem_fence}END ${cmc_fixture_private_key_label}${cmc_fixture_pem_fence}" \
  >"${cmc_fixture_pem_bundle}/artifact/bundle.bin"
cmc_fixture_expect_rejection \
  "${cmc_fixture_pem_bundle}" \
  --artifact "${cmc_fixture_pem_bundle}/artifact"

cmc_fixture_short_pem_tail="$(cmc_fixture_prepare bundle-private-key-short-tail)"
mkdir -p "${cmc_fixture_short_pem_tail}/artifact"
printf '%s\n' \
  "${cmc_fixture_pem_fence}BEGIN ${cmc_fixture_rsa_key_label}${cmc_fixture_pem_fence}" \
  'QUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFB' \
  'QUFBQUFBQUFB' \
  "${cmc_fixture_pem_fence}END ${cmc_fixture_rsa_key_label}${cmc_fixture_pem_fence}" \
  >"${cmc_fixture_short_pem_tail}/artifact/bundle.bin"
cmc_fixture_expect_rejection \
  "${cmc_fixture_short_pem_tail}" \
  --artifact "${cmc_fixture_short_pem_tail}/artifact"

cmc_fixture_spaced_pem="$(
  cmc_fixture_prepare bundle-private-key-whitespace
)"
mkdir -p "${cmc_fixture_spaced_pem}/artifact"
openssl genpkey \
  -algorithm RSA \
  -pkeyopt rsa_keygen_bits:1024 \
  -out "${cmc_fixture_spaced_pem}/artifact/canonical.pem" \
  >/dev/null 2>&1
perl -pe \
  'if (/-----BEGIN/) { s/$/ \t/; }
   elsif (/-----END/) { s/$/\t /; }
   else { s/^/ \t/; s/$/\t /; }' \
  "${cmc_fixture_spaced_pem}/artifact/canonical.pem" \
  >"${cmc_fixture_spaced_pem}/artifact/bundle.bin"
openssl pkey \
  -in "${cmc_fixture_spaced_pem}/artifact/bundle.bin" \
  -noout \
  >/dev/null 2>&1
cmc_fixture_expect_rejection \
  "${cmc_fixture_spaced_pem}" \
  --artifact "${cmc_fixture_spaced_pem}/artifact/bundle.bin"

cmc_fixture_form_feed_pem="$(
  cmc_fixture_prepare bundle-private-key-form-feed-boundary
)"
mkdir -p "${cmc_fixture_form_feed_pem}/artifact"
perl -pe \
  'if (/-----BEGIN/) { s/$/\f/; }' \
  "${cmc_fixture_spaced_pem}/artifact/canonical.pem" \
  >"${cmc_fixture_form_feed_pem}/artifact/bundle.bin"
openssl pkey \
  -in "${cmc_fixture_form_feed_pem}/artifact/bundle.bin" \
  -noout \
  >/dev/null 2>&1
cmc_fixture_expect_rejection \
  "${cmc_fixture_form_feed_pem}" \
  --artifact "${cmc_fixture_form_feed_pem}/artifact/bundle.bin"

cmc_fixture_vertical_tab_pem="$(
  cmc_fixture_prepare bundle-private-key-vertical-tab-boundary
)"
mkdir -p "${cmc_fixture_vertical_tab_pem}/artifact"
perl -pe \
  'if (/-----BEGIN/) { s/$/\x0b/; }' \
  "${cmc_fixture_spaced_pem}/artifact/canonical.pem" \
  >"${cmc_fixture_vertical_tab_pem}/artifact/bundle.bin"
openssl pkey \
  -in "${cmc_fixture_vertical_tab_pem}/artifact/bundle.bin" \
  -noout \
  >/dev/null 2>&1
cmc_fixture_expect_rejection \
  "${cmc_fixture_vertical_tab_pem}" \
  --artifact "${cmc_fixture_vertical_tab_pem}/artifact/bundle.bin"

cmc_fixture_ascii_whitespace_pem="$(
  cmc_fixture_prepare bundle-private-key-ascii-whitespace
)"
mkdir -p "${cmc_fixture_ascii_whitespace_pem}/artifact"
perl -pe \
  'if (/-----BEGIN/) { s/$/ \t\f\x0b\r\r/; }
   elsif (/-----END/) { s/$/\r\r/; }
   else { s/^/ \t/; s/$/\f\x0b\r\r/; }' \
  "${cmc_fixture_spaced_pem}/artifact/canonical.pem" \
  >"${cmc_fixture_ascii_whitespace_pem}/artifact/bundle.bin"
openssl pkey \
  -in "${cmc_fixture_ascii_whitespace_pem}/artifact/bundle.bin" \
  -noout \
  >/dev/null 2>&1
cmc_fixture_expect_rejection \
  "${cmc_fixture_ascii_whitespace_pem}" \
  --artifact "${cmc_fixture_ascii_whitespace_pem}/artifact/bundle.bin"

cmc_fixture_single_column_pem="$(
  cmc_fixture_prepare bundle-private-key-single-column
)"
mkdir -p "${cmc_fixture_single_column_pem}/artifact"
openssl genpkey \
  -algorithm RSA \
  -pkeyopt rsa_keygen_bits:1024 \
  -out "${cmc_fixture_single_column_pem}/artifact/canonical.pem" \
  >/dev/null 2>&1
perl -0777 -e '
  use strict;
  use warnings;
  my ($begin, $end, $path) = @ARGV;
  open my $handle, "<", $path or exit 2;
  local $/;
  my $content = <$handle>;
  close $handle or exit 2;
  $content =~ /\Q$begin\E\r?\n(.*?)\Q$end\E/s or exit 2;
  my $payload = $1;
  $payload =~ s/\s//g;
  print "$begin\n", join("\n", split //, $payload), "\n$end\n";
' -- \
  "${cmc_fixture_pem_fence}BEGIN ${cmc_fixture_private_key_label}${cmc_fixture_pem_fence}" \
  "${cmc_fixture_pem_fence}END ${cmc_fixture_private_key_label}${cmc_fixture_pem_fence}" \
  "${cmc_fixture_single_column_pem}/artifact/canonical.pem" \
  >"${cmc_fixture_single_column_pem}/artifact/bundle.bin"
openssl pkey \
  -in "${cmc_fixture_single_column_pem}/artifact/bundle.bin" \
  -noout \
  >/dev/null 2>&1
cmc_fixture_expect_rejection \
  "${cmc_fixture_single_column_pem}" \
  --artifact "${cmc_fixture_single_column_pem}/artifact/bundle.bin"

cmc_fixture_encrypted_pem="$(cmc_fixture_prepare bundle-encrypted-private-key)"
mkdir -p "${cmc_fixture_encrypted_pem}/artifact"
printf '%s\n' \
  "${cmc_fixture_pem_fence}BEGIN ${cmc_fixture_encrypted_key_label}${cmc_fixture_pem_fence}" \
  'QkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJC' \
  "${cmc_fixture_pem_fence}END ${cmc_fixture_encrypted_key_label}${cmc_fixture_pem_fence}" \
  >"${cmc_fixture_encrypted_pem}/artifact/bundle.bin"
cmc_fixture_expect_rejection \
  "${cmc_fixture_encrypted_pem}" \
  --artifact "${cmc_fixture_encrypted_pem}/artifact"

cmc_fixture_dsa_pem="$(cmc_fixture_prepare bundle-dsa-private-key)"
mkdir -p "${cmc_fixture_dsa_pem}/artifact"
printf '%s\n' \
  "${cmc_fixture_pem_fence}BEGIN ${cmc_fixture_dsa_key_label}${cmc_fixture_pem_fence}" \
  'Q0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0ND' \
  "${cmc_fixture_pem_fence}END ${cmc_fixture_dsa_key_label}${cmc_fixture_pem_fence}" \
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
  "${cmc_fixture_google_value}" \
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

cmc_fixture_maps_sdk="$(cmc_fixture_prepare maps-sdk-public-identifier)"
mkdir -p "${cmc_fixture_maps_sdk}/artifact"
printf '%s\0%s\0%s\0%s\0%s\0%s\n' \
  "${cmc_fixture_maps_sdk_prefix}" \
  "${cmc_fixture_maps_sdk_quota}" \
  "${cmc_fixture_maps_value}" \
  "${cmc_fixture_maps_sdk_platform}" \
  "${cmc_fixture_maps_sdk_service}" \
  "${cmc_fixture_maps_sdk_places}" \
  >"${cmc_fixture_maps_sdk}/artifact/bundle.bin"
cmc_fixture_expect_acceptance \
  "${cmc_fixture_maps_sdk}" \
  --artifact "${cmc_fixture_maps_sdk}/artifact"

cmc_fixture_kernel_fences="$(cmc_fixture_prepare kernel-key-parser-constants)"
mkdir -p "${cmc_fixture_kernel_fences}/artifact"
printf "static const begin = '%sBEGIN %s%s'; static const end = '%sEND %s%s';\n" \
  "${cmc_fixture_pem_fence}" \
  "${cmc_fixture_private_key_label}" \
  "${cmc_fixture_pem_fence}" \
  "${cmc_fixture_pem_fence}" \
  "${cmc_fixture_private_key_label}" \
  "${cmc_fixture_pem_fence}" \
  >"${cmc_fixture_kernel_fences}/artifact/bundle.bin"
printf "static const beginEc = '%sBEGIN %s%s'; static const endEc = '%sEND %s%s';\n" \
  "${cmc_fixture_pem_fence}" \
  "${cmc_fixture_ec_key_label}" \
  "${cmc_fixture_pem_fence}" \
  "${cmc_fixture_pem_fence}" \
  "${cmc_fixture_ec_key_label}" \
  "${cmc_fixture_pem_fence}" \
  >>"${cmc_fixture_kernel_fences}/artifact/bundle.bin"
printf "static const beginRsa = '%sBEGIN %s%s'; static const endRsa = '%sEND %s%s';\n" \
  "${cmc_fixture_pem_fence}" \
  "${cmc_fixture_rsa_key_label}" \
  "${cmc_fixture_pem_fence}" \
  "${cmc_fixture_pem_fence}" \
  "${cmc_fixture_rsa_key_label}" \
  "${cmc_fixture_pem_fence}" \
  >>"${cmc_fixture_kernel_fences}/artifact/bundle.bin"
cmc_fixture_expect_acceptance \
  "${cmc_fixture_kernel_fences}" \
  --artifact "${cmc_fixture_kernel_fences}/artifact/bundle.bin"

cmc_fixture_anon_jwt="$(cmc_fixture_prepare legacy-anon-jwt)"
mkdir -p "${cmc_fixture_anon_jwt}/artifact"
printf '%s\n' \
  "${cmc_fixture_anon_jwt_value}" \
  >"${cmc_fixture_anon_jwt}/artifact/bundle.bin"
cmc_fixture_expect_acceptance \
  "${cmc_fixture_anon_jwt}" \
  --artifact "${cmc_fixture_anon_jwt}/artifact"

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
