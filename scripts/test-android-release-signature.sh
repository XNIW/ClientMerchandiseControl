#!/usr/bin/env bash
set -euo pipefail

cmc_signature_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_signature_tmp_parent="${TMPDIR:-/tmp}"
cmc_signature_tmp_parent="${cmc_signature_tmp_parent%/}"
cmc_signature_aab=''
cmc_signature_apk=''

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --aab)
      shift
      [[ "$#" -gt 0 ]] || exit 1
      cmc_signature_aab="$1"
      ;;
    --apk)
      shift
      [[ "$#" -gt 0 ]] || exit 1
      cmc_signature_apk="$1"
      ;;
    *)
      printf 'Android signature fixture: argomento non supportato.\n' >&2
      exit 1
      ;;
  esac
  shift
done

[[ -r "${cmc_signature_aab}" && -r "${cmc_signature_apk}" ]] || {
  printf 'Android signature fixture: AAB/APK non leggibili.\n' >&2
  exit 1
}

for cmc_signature_command in cp jarsigner keytool unzip zip; do
  command -v "${cmc_signature_command}" >/dev/null 2>&1 || {
    printf 'Android signature fixture: tooling assente.\n' >&2
    exit 1
  }
done

cmc_signature_apksigner="$(command -v apksigner 2>/dev/null || true)"
if [[ -z "${cmc_signature_apksigner}" ]]; then
  for cmc_signature_sdk_root in \
    "${ANDROID_HOME:-}" \
    "${ANDROID_SDK_ROOT:-}"; do
    [[ -n "${cmc_signature_sdk_root}" ]] || continue
    cmc_signature_apksigner="$(
      find "${cmc_signature_sdk_root}/build-tools" \
        -mindepth 2 -maxdepth 2 -type f -name apksigner -perm -111 \
        2>/dev/null | LC_ALL=C sort | tail -n 1
    )"
    [[ -n "${cmc_signature_apksigner}" ]] && break
  done
fi
[[ -x "${cmc_signature_apksigner}" ]] || {
  printf 'Android signature fixture: apksigner assente.\n' >&2
  exit 1
}

cmc_signature_tmp_root="$(
  mktemp -d "${cmc_signature_tmp_parent}/cmc-android-signature.XXXXXX"
)"
cmc_signature_cleanup() {
  case "${cmc_signature_tmp_root}" in
    "${cmc_signature_tmp_parent}"/cmc-android-signature.*)
      rm -rf -- "${cmc_signature_tmp_root}"
      ;;
    *)
      printf 'Android signature fixture: cleanup rifiutato.\n' >&2
      ;;
  esac
}
trap cmc_signature_cleanup EXIT

cmc_signature_candidate_aab="${cmc_signature_tmp_root}/candidate.aab"
cmc_signature_candidate_apk="${cmc_signature_tmp_root}/candidate.apk"
cmc_signature_keystore="${cmc_signature_tmp_root}/fixture.p12"
cp "${cmc_signature_aab}" "${cmc_signature_candidate_aab}"
cp "${cmc_signature_apk}" "${cmc_signature_candidate_apk}"

keytool -genkeypair -noprompt \
  -keystore "${cmc_signature_keystore}" \
  -storetype PKCS12 \
  -storepass fixturepass \
  -keypass fixturepass \
  -alias fixture \
  -keyalg RSA \
  -keysize 2048 \
  -validity 2 \
  -dname 'CN=TASK039 Test Fixture,OU=Release Validation,O=Local Test,L=Santiago,C=CL' \
  >/dev/null 2>&1
jarsigner -J-Duser.language=en \
  -keystore "${cmc_signature_keystore}" \
  -storepass fixturepass \
  -keypass fixturepass \
  "${cmc_signature_candidate_aab}" fixture \
  >/dev/null 2>&1
"${cmc_signature_apksigner}" sign \
  --ks "${cmc_signature_keystore}" \
  --ks-pass pass:fixturepass \
  --key-pass pass:fixturepass \
  --ks-key-alias fixture \
  --v1-signing-enabled false \
  --v2-signing-enabled true \
  --v3-signing-enabled false \
  --v4-signing-enabled false \
  "${cmc_signature_candidate_apk}" \
  >/dev/null 2>&1

cmc_signature_apk_verification="$(
  "${cmc_signature_apksigner}" verify --verbose \
    "${cmc_signature_candidate_apk}" 2>/dev/null
)"
grep -Fq 'Verified using v1 scheme (JAR signing): false' \
  <<<"${cmc_signature_apk_verification}"
grep -Fq 'Verified using v2 scheme (APK Signature Scheme v2): true' \
  <<<"${cmc_signature_apk_verification}"

cmc_signature_fingerprint="$(
  keytool -J-Duser.language=en -printcert -jarfile \
    "${cmc_signature_candidate_aab}" 2>/dev/null | \
    awk -F': ' '/SHA256:/ { print $2; exit }'
)"
[[ -n "${cmc_signature_fingerprint}" ]]
cmc_signature_email='release-fixture@owned-project.iam.gserviceaccount.com'
cmc_signature_project='owned-project'
cmc_signature_credential="${cmc_signature_tmp_root}/service-account.json"
cmc_signature_private_begin='-----BEGIN '
cmc_signature_private_end='-----END '
printf '{"type":"service_account","project_id":"%s","private_key_id":"fixture_key_01","private_key":"%sPRIVATE KEY-----\\nsynthetic-test-material\\n%sPRIVATE KEY-----\\n","client_email":"%s","token_uri":"https://oauth2.googleapis.com/token"}\n' \
  "${cmc_signature_project}" \
  "${cmc_signature_private_begin}" \
  "${cmc_signature_private_end}" \
  "${cmc_signature_email}" \
  >"${cmc_signature_credential}"

if PLAY_INTERNAL_UPLOAD_AUTHORIZED=true \
  PLAY_SERVICE_ACCOUNT_JSON_PATH=/dev/null \
  PLAY_SERVICE_ACCOUNT_EXPECTED_EMAIL="${cmc_signature_email}" \
  PLAY_SERVICE_ACCOUNT_EXPECTED_PROJECT_ID="${cmc_signature_project}" \
  ANDROID_SIGNING_CERT_SHA256="${cmc_signature_fingerprint}" \
  bash "${cmc_signature_script_dir}/check-android-release.sh" \
    --aab "${cmc_signature_candidate_aab}" \
    --apk "${cmc_signature_candidate_apk}" \
    --require-upload-ready \
    >"${cmc_signature_tmp_root}/device-path.log" 2>&1; then
  printf 'Android signature fixture: /dev/null accettato.\n' >&2
  exit 1
fi
grep -Fq 'PLAY_SERVICE_ACCOUNT_MISSING' \
  "${cmc_signature_tmp_root}/device-path.log"

if PLAY_INTERNAL_UPLOAD_AUTHORIZED=true \
  PLAY_SERVICE_ACCOUNT_JSON_PATH="${cmc_signature_credential}" \
  PLAY_SERVICE_ACCOUNT_EXPECTED_EMAIL='other@owned-project.iam.gserviceaccount.com' \
  PLAY_SERVICE_ACCOUNT_EXPECTED_PROJECT_ID="${cmc_signature_project}" \
  ANDROID_SIGNING_CERT_SHA256="${cmc_signature_fingerprint}" \
  bash "${cmc_signature_script_dir}/check-android-release.sh" \
    --aab "${cmc_signature_candidate_aab}" \
    --apk "${cmc_signature_candidate_apk}" \
    --require-upload-ready \
    >"${cmc_signature_tmp_root}/wrong-account.log" 2>&1; then
  printf 'Android signature fixture: account diverso accettato.\n' >&2
  exit 1
fi
grep -Fq 'PLAY_SERVICE_ACCOUNT_INVALID' \
  "${cmc_signature_tmp_root}/wrong-account.log"

if PLAY_INTERNAL_UPLOAD_AUTHORIZED=true \
  PLAY_SERVICE_ACCOUNT_JSON_PATH="${cmc_signature_credential}" \
  PLAY_SERVICE_ACCOUNT_EXPECTED_EMAIL="${cmc_signature_email}" \
  PLAY_SERVICE_ACCOUNT_EXPECTED_PROJECT_ID='other-owned-project' \
  ANDROID_SIGNING_CERT_SHA256="${cmc_signature_fingerprint}" \
  bash "${cmc_signature_script_dir}/check-android-release.sh" \
    --aab "${cmc_signature_candidate_aab}" \
    --apk "${cmc_signature_candidate_apk}" \
    --require-upload-ready \
    >"${cmc_signature_tmp_root}/wrong-project.log" 2>&1; then
  printf 'Android signature fixture: progetto diverso accettato.\n' >&2
  exit 1
fi
grep -Fq 'PLAY_SERVICE_ACCOUNT_INVALID' \
  "${cmc_signature_tmp_root}/wrong-project.log"

cmc_signature_renamed_aab="${cmc_signature_tmp_root}/candidate.bundle"
cp "${cmc_signature_candidate_aab}" "${cmc_signature_renamed_aab}"
if bash "${cmc_signature_script_dir}/check-android-release.sh" \
  --aab "${cmc_signature_renamed_aab}" \
  --apk "${cmc_signature_candidate_apk}" \
  >"${cmc_signature_tmp_root}/renamed-aab.log" 2>&1; then
  printf 'Android signature fixture: estensione AAB non canonica accettata.\n' >&2
  exit 1
fi
grep -Fq 'AAB_EXTENSION_INVALID' \
  "${cmc_signature_tmp_root}/renamed-aab.log"

cmc_signature_partial_aab="${cmc_signature_tmp_root}/partial.aab"
cmc_signature_unsigned_entry="${cmc_signature_tmp_root}/unsigned-after-signing.txt"
cp "${cmc_signature_candidate_aab}" "${cmc_signature_partial_aab}"
printf 'public regression fixture\n' >"${cmc_signature_unsigned_entry}"
zip -q -j "${cmc_signature_partial_aab}" "${cmc_signature_unsigned_entry}"
if PLAY_INTERNAL_UPLOAD_AUTHORIZED=true \
  PLAY_SERVICE_ACCOUNT_JSON_PATH="${cmc_signature_credential}" \
  PLAY_SERVICE_ACCOUNT_EXPECTED_EMAIL="${cmc_signature_email}" \
  PLAY_SERVICE_ACCOUNT_EXPECTED_PROJECT_ID="${cmc_signature_project}" \
  ANDROID_SIGNING_CERT_SHA256="${cmc_signature_fingerprint}" \
  bash "${cmc_signature_script_dir}/check-android-release.sh" \
    --aab "${cmc_signature_partial_aab}" \
    --apk "${cmc_signature_candidate_apk}" \
    --require-upload-ready \
    >"${cmc_signature_tmp_root}/partial-signature.log" 2>&1; then
  printf 'Android signature fixture: entry AAB non firmata accettata.\n' >&2
  exit 1
fi
grep -Fq 'AAB_SIGNATURE_VERIFICATION_FAILED' \
  "${cmc_signature_tmp_root}/partial-signature.log"

cmc_signature_second_keystore="${cmc_signature_tmp_root}/fixture-second.p12"
cmc_signature_multiple_aab="${cmc_signature_tmp_root}/multiple-signers.aab"
cp "${cmc_signature_candidate_aab}" "${cmc_signature_multiple_aab}"
keytool -genkeypair -noprompt \
  -keystore "${cmc_signature_second_keystore}" \
  -storetype PKCS12 \
  -storepass fixturepass \
  -keypass fixturepass \
  -alias fixturesecond \
  -keyalg RSA \
  -keysize 2048 \
  -validity 2 \
  -dname 'CN=TASK039 Second Fixture,OU=Release Validation,O=Local Test,L=Santiago,C=CL' \
  >/dev/null 2>&1
jarsigner -J-Duser.language=en \
  -keystore "${cmc_signature_second_keystore}" \
  -storepass fixturepass \
  -keypass fixturepass \
  "${cmc_signature_multiple_aab}" fixturesecond \
  >/dev/null 2>&1
if PLAY_INTERNAL_UPLOAD_AUTHORIZED=true \
  PLAY_SERVICE_ACCOUNT_JSON_PATH="${cmc_signature_credential}" \
  PLAY_SERVICE_ACCOUNT_EXPECTED_EMAIL="${cmc_signature_email}" \
  PLAY_SERVICE_ACCOUNT_EXPECTED_PROJECT_ID="${cmc_signature_project}" \
  ANDROID_SIGNING_CERT_SHA256="${cmc_signature_fingerprint}" \
  bash "${cmc_signature_script_dir}/check-android-release.sh" \
    --aab "${cmc_signature_multiple_aab}" \
    --apk "${cmc_signature_candidate_apk}" \
    --require-upload-ready \
    >"${cmc_signature_tmp_root}/multiple-signers.log" 2>&1; then
  printf 'Android signature fixture: AAB multi-signer accettato.\n' >&2
  exit 1
fi
grep -Fq 'AAB_SIGNER_SET_INVALID' \
  "${cmc_signature_tmp_root}/multiple-signers.log"

cmc_signature_validator_output="$(
  PLAY_INTERNAL_UPLOAD_AUTHORIZED=true \
  PLAY_SERVICE_ACCOUNT_JSON_PATH="${cmc_signature_credential}" \
  PLAY_SERVICE_ACCOUNT_EXPECTED_EMAIL="${cmc_signature_email}" \
  PLAY_SERVICE_ACCOUNT_EXPECTED_PROJECT_ID="${cmc_signature_project}" \
  ANDROID_SIGNING_CERT_SHA256="${cmc_signature_fingerprint}" \
    bash "${cmc_signature_script_dir}/check-android-release.sh" \
    --aab "${cmc_signature_candidate_aab}" \
    --apk "${cmc_signature_candidate_apk}" \
    --require-upload-ready
)"
grep -Fq 'ANDROID_RELEASE_SIGNING=SIGNED' \
  <<<"${cmc_signature_validator_output}"
grep -Fq 'ANDROID_INTERNAL_UPLOAD_INPUTS_VALIDATED' \
  <<<"${cmc_signature_validator_output}"

printf 'Android release signature fixture: APK v2-only e input Play validati.\n'
