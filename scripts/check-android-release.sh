#!/usr/bin/env bash
set -euo pipefail

cmc_android_release_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_android_release_root="$(git -C "${cmc_android_release_script_dir}" rev-parse --show-toplevel)"
cmc_android_release_aab=''
cmc_android_release_apk=''
cmc_android_release_source_only=false
cmc_android_release_require_upload=false

cmc_android_release_fail() {
  printf 'ANDROID_RELEASE_BLOCKED: %s\n' "$1" >&2
  exit 1
}

cmc_android_release_usage() {
  printf '%s\n' \
    'Usage: scripts/check-android-release.sh --source-only' \
    '   or: scripts/check-android-release.sh --aab <path> --apk <path> [--require-upload-ready]'
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --aab)
      shift
      [[ "$#" -gt 0 ]] || cmc_android_release_fail 'AAB_PATH_MISSING'
      cmc_android_release_aab="$1"
      ;;
    --apk)
      shift
      [[ "$#" -gt 0 ]] || cmc_android_release_fail 'APK_PATH_MISSING'
      cmc_android_release_apk="$1"
      ;;
    --source-only)
      cmc_android_release_source_only=true
      ;;
    --require-upload-ready)
      cmc_android_release_require_upload=true
      ;;
    --help)
      cmc_android_release_usage
      exit 0
      ;;
    *)
      cmc_android_release_fail 'UNSUPPORTED_ARGUMENT'
      ;;
  esac
  shift
done

cmc_android_release_gradle="${cmc_android_release_root}/android/app/build.gradle.kts"
cmc_android_release_manifest="${cmc_android_release_root}/android/app/src/release/AndroidManifest.xml"
cmc_android_release_network="${cmc_android_release_root}/android/app/src/release/res/xml/network_security_config.xml"
cmc_android_release_config="${cmc_android_release_root}/config/app_config.production.release.json"
cmc_android_release_key_properties="${cmc_android_release_root}/android/key.properties"
cmc_android_release_bundle_manifest_tool="${cmc_android_release_root}/tool/check_android_bundle_manifest.dart"
cmc_android_release_play_credentials_tool="${cmc_android_release_root}/tool/check_android_play_credentials.dart"

for cmc_android_release_file in \
  "${cmc_android_release_gradle}" \
  "${cmc_android_release_manifest}" \
  "${cmc_android_release_network}" \
  "${cmc_android_release_config}" \
  "${cmc_android_release_bundle_manifest_tool}" \
  "${cmc_android_release_play_credentials_tool}"; do
  [[ -r "${cmc_android_release_file}" ]] || \
    cmc_android_release_fail 'RELEASE_SOURCE_MISSING'
done

cmc_android_release_require_literal() {
  local cmc_android_release_file="$1"
  local cmc_android_release_literal="$2"
  local cmc_android_release_code="$3"
  grep -Fq -- "${cmc_android_release_literal}" "${cmc_android_release_file}" || \
    cmc_android_release_fail "${cmc_android_release_code}"
}

cmc_android_release_require_literal \
  "${cmc_android_release_gradle}" 'isMinifyEnabled = true' 'R8_DISABLED'
cmc_android_release_require_literal \
  "${cmc_android_release_gradle}" 'isShrinkResources = true' 'RESOURCE_SHRINK_DISABLED'
cmc_android_release_require_literal \
  "${cmc_android_release_gradle}" 'proguard-android-optimize.txt' 'R8_OPTIMIZE_CONFIG_MISSING'
cmc_android_release_require_literal \
  "${cmc_android_release_gradle}" 'releaseSigningValues.none' 'PARTIAL_SIGNING_GUARD_MISSING'
cmc_android_release_require_literal \
  "${cmc_android_release_manifest}" 'android:usesCleartextTraffic="false"' 'CLEARTEXT_NOT_DISABLED'
cmc_android_release_require_literal \
  "${cmc_android_release_manifest}" 'android:networkSecurityConfig="@xml/network_security_config"' 'NETWORK_POLICY_MISSING'
cmc_android_release_require_literal \
  "${cmc_android_release_network}" 'cleartextTrafficPermitted="false"' 'NETWORK_POLICY_ALLOWS_CLEARTEXT'
cmc_android_release_require_literal \
  "${cmc_android_release_config}" '"APP_ENV": "production"' 'PRODUCTION_ENV_MISSING'
cmc_android_release_require_literal \
  "${cmc_android_release_config}" '"GOOGLE_AUTH_ENABLED": "false"' 'OAUTH_NOT_FAIL_CLOSED'
cmc_android_release_require_literal \
  "${cmc_android_release_config}" '"DELIVERY_MAPS_ENABLED": "false"' 'MAPS_NOT_FAIL_CLOSED'
cmc_android_release_require_literal \
  "${cmc_android_release_config}" '"DELIVERY_MAPS_NATIVE_CONFIGURED": "false"' 'MAPS_NATIVE_NOT_FAIL_CLOSED'

if grep -Fq 'signingConfigs.getByName("debug")' "${cmc_android_release_gradle}"; then
  cmc_android_release_fail 'DEBUG_SIGNING_CONFIGURED_FOR_RELEASE'
fi
if grep -Eq 'SUPABASE_|AUTH_REDIRECT_URI|STOREFRONT_SHOP_SLUG' \
  "${cmc_android_release_config}"; then
  cmc_android_release_fail 'PRODUCTION_TEMPLATE_CONTAINS_EXTERNAL_VALUE'
fi
if grep -Fq 'src="user"' "${cmc_android_release_network}"; then
  cmc_android_release_fail 'USER_CA_TRUSTED_IN_RELEASE'
fi

cmc_android_release_property_present() {
  local cmc_android_release_key="$1"
  [[ -r "${cmc_android_release_key_properties}" ]] || return 1
  awk -F= -v key="${cmc_android_release_key}" '
    $1 == key {
      value = substr($0, index($0, "=") + 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if (length(value) > 0) found = 1
    }
    END { exit(found ? 0 : 1) }
  ' "${cmc_android_release_key_properties}"
}

cmc_android_release_store_file_from_properties() {
  awk -F= '
    $1 == "storeFile" {
      value = substr($0, index($0, "=") + 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if (length(value) > 0) print value
      exit
    }
  ' "${cmc_android_release_key_properties}"
}

cmc_android_release_signing_count=0
if [[ -n "${ANDROID_KEYSTORE_PATH:-}" ]] || \
  cmc_android_release_property_present storeFile; then
  cmc_android_release_signing_count=$((cmc_android_release_signing_count + 1))
fi
if [[ -n "${ANDROID_KEYSTORE_PASSWORD:-}" ]] || \
  cmc_android_release_property_present storePassword; then
  cmc_android_release_signing_count=$((cmc_android_release_signing_count + 1))
fi
if [[ -n "${ANDROID_KEY_ALIAS:-}" ]] || \
  cmc_android_release_property_present keyAlias; then
  cmc_android_release_signing_count=$((cmc_android_release_signing_count + 1))
fi
if [[ -n "${ANDROID_KEY_PASSWORD:-}" ]] || \
  cmc_android_release_property_present keyPassword; then
  cmc_android_release_signing_count=$((cmc_android_release_signing_count + 1))
fi

if [[ "${cmc_android_release_signing_count}" -ne 0 && \
  "${cmc_android_release_signing_count}" -ne 4 ]]; then
  cmc_android_release_fail 'SIGNING_CONFIGURATION_PARTIAL'
fi
if [[ "${cmc_android_release_signing_count}" -eq 4 ]]; then
  cmc_android_release_store_file="${ANDROID_KEYSTORE_PATH:-}"
  if [[ -z "${cmc_android_release_store_file}" ]]; then
    cmc_android_release_store_file="$(
      cmc_android_release_store_file_from_properties
    )"
  fi
  if [[ "${cmc_android_release_store_file}" != /* ]]; then
    cmc_android_release_store_file="${cmc_android_release_root}/android/${cmc_android_release_store_file}"
  fi
  [[ -r "${cmc_android_release_store_file}" ]] || \
    cmc_android_release_fail 'SIGNING_KEYSTORE_UNAVAILABLE'
fi

if [[ "${cmc_android_release_source_only}" == true ]]; then
  if [[ -n "${cmc_android_release_aab}" || -n "${cmc_android_release_apk}" || \
    "${cmc_android_release_require_upload}" == true ]]; then
    cmc_android_release_fail 'SOURCE_ONLY_ARGUMENT_CONFLICT'
  fi
  if [[ "${cmc_android_release_signing_count}" -eq 4 ]]; then
    printf 'ANDROID_RELEASE_SOURCE_READY_SIGNING_CONFIGURED\n'
  else
    printf 'ANDROID_RELEASE_SOURCE_READY_UNSIGNED\n'
  fi
  printf 'ANDROID_APP_LINK_BLOCKED: OWNED_HTTPS_DOMAIN_AND_ASSOCIATION_FILE_REQUIRED\n'
  exit 0
fi

[[ -n "${cmc_android_release_aab}" && -n "${cmc_android_release_apk}" ]] || \
  cmc_android_release_fail 'AAB_AND_APK_REQUIRED'
[[ -r "${cmc_android_release_aab}" && -r "${cmc_android_release_apk}" ]] || \
  cmc_android_release_fail 'ARTIFACT_NOT_READABLE'
case "${cmc_android_release_aab}" in
  *.aab) ;;
  *) cmc_android_release_fail 'AAB_EXTENSION_INVALID' ;;
esac
case "${cmc_android_release_apk}" in
  *.apk) ;;
  *) cmc_android_release_fail 'APK_EXTENSION_INVALID' ;;
esac

for cmc_android_release_command in dart unzip jarsigner keytool shasum; do
  command -v "${cmc_android_release_command}" >/dev/null 2>&1 || \
    cmc_android_release_fail 'ARTIFACT_TOOLING_MISSING'
done

cmc_android_release_resolve_sdk_command() {
  local cmc_android_release_command_name="$1"
  local cmc_android_release_relative_path="$2"
  local cmc_android_release_candidate=''
  local cmc_android_release_sdk_root=''
  local cmc_android_release_resolved=''

  cmc_android_release_resolved="$(
    command -v "${cmc_android_release_command_name}" 2>/dev/null || true
  )"
  if [[ -n "${cmc_android_release_resolved}" && \
    -x "${cmc_android_release_resolved}" && \
    "${cmc_android_release_resolved}" == */cmdline-tools/*/bin/* && \
    -d "${cmc_android_release_resolved%%/cmdline-tools/*}/build-tools" ]]; then
    printf '%s\n' "${cmc_android_release_resolved}"
    return 0
  fi

  for cmc_android_release_sdk_root in \
    "${ANDROID_HOME:-}" \
    "${ANDROID_SDK_ROOT:-}"; do
    [[ -n "${cmc_android_release_sdk_root}" ]] || continue
    cmc_android_release_candidate="${cmc_android_release_sdk_root}/${cmc_android_release_relative_path}"
    if [[ -x "${cmc_android_release_candidate}" ]]; then
      printf '%s\n' "${cmc_android_release_candidate}"
      return 0
    fi
  done
  return 1
}

cmc_android_release_resolve_apksigner() {
  local cmc_android_release_resolved=''
  local cmc_android_release_sdk_root=''
  local cmc_android_release_candidate=''

  cmc_android_release_resolved="$(command -v apksigner 2>/dev/null || true)"
  if [[ -n "${cmc_android_release_resolved}" && \
    -x "${cmc_android_release_resolved}" ]]; then
    printf '%s\n' "${cmc_android_release_resolved}"
    return 0
  fi
  for cmc_android_release_sdk_root in \
    "${ANDROID_HOME:-}" \
    "${ANDROID_SDK_ROOT:-}"; do
    [[ -n "${cmc_android_release_sdk_root}" ]] || continue
    cmc_android_release_candidate="$(
      find "${cmc_android_release_sdk_root}/build-tools" \
        -mindepth 2 -maxdepth 2 -type f -name apksigner -perm -111 \
        2>/dev/null | LC_ALL=C sort | tail -n 1
    )"
    if [[ -n "${cmc_android_release_candidate}" && \
      -x "${cmc_android_release_candidate}" ]]; then
      printf '%s\n' "${cmc_android_release_candidate}"
      return 0
    fi
  done
  return 1
}

cmc_android_release_apkanalyzer="$(
  cmc_android_release_resolve_sdk_command \
    apkanalyzer cmdline-tools/latest/bin/apkanalyzer
)" || cmc_android_release_fail 'APKANALYZER_MISSING'
cmc_android_release_apksigner="$(
  cmc_android_release_resolve_apksigner
)" || cmc_android_release_fail 'APKSIGNER_MISSING'

unzip -tqq "${cmc_android_release_aab}" || cmc_android_release_fail 'AAB_ZIP_INVALID'
unzip -tqq "${cmc_android_release_apk}" || cmc_android_release_fail 'APK_ZIP_INVALID'
cmc_android_release_aab_entries="$(unzip -Z1 "${cmc_android_release_aab}")"
grep -Fqx 'BUNDLE-METADATA/com.android.tools/r8.json' \
  <<<"${cmc_android_release_aab_entries}" || \
  cmc_android_release_fail 'R8_METADATA_MISSING'
grep -Fqx 'BUNDLE-METADATA/com.android.tools.build.obfuscation/proguard.map' \
  <<<"${cmc_android_release_aab_entries}" || \
  cmc_android_release_fail 'PROGUARD_MAP_MISSING'
cmc_android_release_r8="$(
  unzip -p "${cmc_android_release_aab}" BUNDLE-METADATA/com.android.tools/r8.json
)"
for cmc_android_release_r8_flag in \
  '"isObfuscationEnabled":true' \
  '"isOptimizationsEnabled":true' \
  '"isShrinkingEnabled":true' \
  '"isDebugModeEnabled":false' \
  '"isOptimizedShrinkingEnabled":true'; do
  grep -Fq -- "${cmc_android_release_r8_flag}" <<<"${cmc_android_release_r8}" || \
    cmc_android_release_fail 'R8_OR_RESOURCE_SHRINK_NOT_ACTIVE'
done

cmc_android_release_abis="$({
  printf '%s\n' "${cmc_android_release_aab_entries}" | \
    awk -F/ '/^base\/lib\// { print $3 }' | LC_ALL=C sort -u
} | paste -sd, -)"
[[ "${cmc_android_release_abis}" == 'arm64-v8a,armeabi-v7a,x86_64' ]] || \
  cmc_android_release_fail 'UNEXPECTED_ABI_SET'

cmc_android_release_tmp_parent="${TMPDIR:-/tmp}"
cmc_android_release_tmp_parent="${cmc_android_release_tmp_parent%/}"
cmc_android_release_tmp_root="$(
  mktemp -d "${cmc_android_release_tmp_parent}/cmc-android-release.XXXXXX"
)"
cmc_android_release_cleanup() {
  case "${cmc_android_release_tmp_root}" in
    "${cmc_android_release_tmp_parent}"/cmc-android-release.*)
      rm -rf -- "${cmc_android_release_tmp_root}"
      ;;
    *)
      printf 'ANDROID_RELEASE_BLOCKED: TEMP_CLEANUP_REFUSED\n' >&2
      ;;
  esac
}
trap cmc_android_release_cleanup EXIT

cmc_android_release_aab_manifest="${cmc_android_release_tmp_root}/AndroidManifest.xml"
if ! unzip -p "${cmc_android_release_aab}" \
  base/manifest/AndroidManifest.xml >"${cmc_android_release_aab_manifest}"; then
  cmc_android_release_fail 'AAB_MANIFEST_UNAVAILABLE'
fi
if ! dart --disable-dart-dev "${cmc_android_release_bundle_manifest_tool}" \
  --manifest "${cmc_android_release_aab_manifest}" >/dev/null; then
  cmc_android_release_fail 'AAB_MANIFEST_INVALID'
fi

for cmc_android_release_abi in arm64-v8a armeabi-v7a x86_64; do
  cmc_android_release_aab_lib_sha="$(
    unzip -p "${cmc_android_release_aab}" \
      "base/lib/${cmc_android_release_abi}/libapp.so" | \
      shasum -a 256 | awk '{print $1}'
  )"
  cmc_android_release_apk_lib_sha="$(
    unzip -p "${cmc_android_release_apk}" \
      "lib/${cmc_android_release_abi}/libapp.so" | \
      shasum -a 256 | awk '{print $1}'
  )"
  [[ -n "${cmc_android_release_aab_lib_sha}" && \
    "${cmc_android_release_aab_lib_sha}" == \
      "${cmc_android_release_apk_lib_sha}" ]] || \
    cmc_android_release_fail 'AAB_APK_PAYLOAD_MISMATCH'
done

cmc_android_release_package="$(
  "${cmc_android_release_apkanalyzer}" manifest application-id \
    "${cmc_android_release_apk}" 2>/dev/null
)"
cmc_android_release_version_name="$(
  "${cmc_android_release_apkanalyzer}" manifest version-name \
    "${cmc_android_release_apk}" 2>/dev/null
)"
cmc_android_release_version_code="$(
  "${cmc_android_release_apkanalyzer}" manifest version-code \
    "${cmc_android_release_apk}" 2>/dev/null
)"
cmc_android_release_debuggable="$(
  "${cmc_android_release_apkanalyzer}" manifest debuggable \
    "${cmc_android_release_apk}" 2>/dev/null
)"
cmc_android_release_compiled_manifest="$(
  "${cmc_android_release_apkanalyzer}" manifest print \
    "${cmc_android_release_apk}" 2>/dev/null
)"

[[ "${cmc_android_release_package}" == 'com.xniw.clientmerchandisecontrol' ]] || \
  cmc_android_release_fail 'APPLICATION_ID_MISMATCH'
[[ "${cmc_android_release_version_name}" == '0.1.0' ]] || \
  cmc_android_release_fail 'VERSION_NAME_MISMATCH'
[[ "${cmc_android_release_version_code}" == '1' ]] || \
  cmc_android_release_fail 'VERSION_CODE_MISMATCH'
[[ "${cmc_android_release_debuggable}" == 'false' ]] || \
  cmc_android_release_fail 'ARTIFACT_DEBUGGABLE'
grep -Fq 'android:usesCleartextTraffic="false"' \
  <<<"${cmc_android_release_compiled_manifest}" || \
  cmc_android_release_fail 'ARTIFACT_CLEARTEXT_NOT_DISABLED'
grep -Fq 'android:value="NOT_CONFIGURED"' \
  <<<"${cmc_android_release_compiled_manifest}" || \
  cmc_android_release_fail 'MAPS_FAIL_CLOSED_SENTINEL_MISSING'
grep -Fq 'android:scheme="com.xniw.clientmerchandisecontrol"' \
  <<<"${cmc_android_release_compiled_manifest}" || \
  cmc_android_release_fail 'DEEPLINK_SCHEME_MISSING'
grep -Fq 'android:permission="android.permission.DUMP"' \
  <<<"${cmc_android_release_compiled_manifest}" || \
  cmc_android_release_fail 'EXPORTED_PROFILE_RECEIVER_NOT_GUARDED'

cmc_android_release_aab_signature_output=''
cmc_android_release_aab_signature_status=0
if cmc_android_release_aab_signature_output="$(
  jarsigner -J-Duser.language=en -strict -verify -verbose -certs \
    "${cmc_android_release_aab}" 2>&1
)"; then
  :
else
  cmc_android_release_aab_signature_status="$?"
fi
if grep -Fq 'jar is unsigned.' <<<"${cmc_android_release_aab_signature_output}"; then
  cmc_android_release_aab_signature_state=UNSIGNED
elif { [[ "${cmc_android_release_aab_signature_status}" -eq 0 ]] || \
  [[ "${cmc_android_release_aab_signature_status}" -eq 4 ]]; } && \
  grep -Eq 'jar verified(, with signer errors)?\.' \
    <<<"${cmc_android_release_aab_signature_output}" && \
  ! grep -Eq \
    'unsigned entries|certificate has expired|certificate (is not|isn.t) yet valid|algorithm .* disabled|timestamp (has expired|is invalid)' \
    <<<"${cmc_android_release_aab_signature_output}"; then
  # `jarsigner -strict` usa il bit 16 per entry non firmate. Il solo codice 4
  # resta ammesso perché i certificati Android sono normalmente self-signed e
  # non concatenati a una CA pubblica; ogni altra severe warning fallisce chiusa.
  cmc_android_release_aab_signature_state=SIGNED
else
  cmc_android_release_fail 'AAB_SIGNATURE_VERIFICATION_FAILED'
fi

cmc_android_release_apk_signature_output=''
cmc_android_release_apk_signature_status=0
if cmc_android_release_apk_signature_output="$(
  "${cmc_android_release_apksigner}" verify --print-certs \
    "${cmc_android_release_apk}" 2>&1
)"; then
  cmc_android_release_apk_signature_state=SIGNED
else
  cmc_android_release_apk_signature_status="$?"
  if grep -Eq 'DOES NOT VERIFY|Missing META-INF/MANIFEST.MF|not signed' \
    <<<"${cmc_android_release_apk_signature_output}"; then
    cmc_android_release_apk_signature_state=UNSIGNED
  else
    cmc_android_release_fail 'APK_SIGNATURE_VERIFICATION_FAILED'
  fi
fi

[[ "${cmc_android_release_aab_signature_state}" == \
  "${cmc_android_release_apk_signature_state}" ]] || \
  cmc_android_release_fail 'AAB_APK_SIGNATURE_STATE_MISMATCH'
cmc_android_release_signature_state="${cmc_android_release_aab_signature_state}"
if [[ "${cmc_android_release_signing_count}" -eq 4 && \
  "${cmc_android_release_signature_state}" != SIGNED ]]; then
  cmc_android_release_fail 'SIGNING_CONFIGURED_BUT_ARTIFACT_UNSIGNED'
fi

cmc_android_release_aab_fingerprint=''
cmc_android_release_apk_fingerprint=''
if [[ "${cmc_android_release_signature_state}" == SIGNED ]]; then
  cmc_android_release_aab_signature_entries="$(
    printf '%s\n' "${cmc_android_release_aab_entries}" | \
      LC_ALL=C grep -E '^META-INF/[A-Za-z0-9_-]+\.(RSA|DSA|EC)$' || true
  )"
  cmc_android_release_aab_signature_entry_count="$(
    awk 'NF { count += 1 } END { print count + 0 }' \
      <<<"${cmc_android_release_aab_signature_entries}"
  )"
  [[ "${cmc_android_release_aab_signature_entry_count}" -eq 1 ]] || \
    cmc_android_release_fail 'AAB_SIGNER_SET_INVALID'
  cmc_android_release_aab_signature_block="${cmc_android_release_tmp_root}/aab-signature-block"
  if ! unzip -p "${cmc_android_release_aab}" \
    "${cmc_android_release_aab_signature_entries}" \
    >"${cmc_android_release_aab_signature_block}"; then
    cmc_android_release_fail 'AAB_CERTIFICATE_UNREADABLE'
  fi
  cmc_android_release_aab_certificate="$(
    keytool -J-Duser.language=en -printcert -file \
      "${cmc_android_release_aab_signature_block}" 2>/dev/null
  )" || cmc_android_release_fail 'AAB_CERTIFICATE_UNREADABLE'
  cmc_android_release_aab_fingerprint="$(
    awk -F': ' '/SHA256:/ { print $2 }' \
      <<<"${cmc_android_release_aab_certificate}" | \
      tr -d ':' | tr '[:upper:]' '[:lower:]' | LC_ALL=C sort -u
  )"
  cmc_android_release_apk_fingerprint="$(
    awk -F': ' '/Signer #1 certificate SHA-256 digest:/ { print $2 }' \
      <<<"${cmc_android_release_apk_signature_output}" | \
      LC_ALL=C sort -u
  )"
  [[ "${cmc_android_release_aab_fingerprint}" =~ ^[0-9a-f]{64}$ && \
    "${cmc_android_release_apk_fingerprint}" =~ ^[0-9a-f]{64}$ ]] || \
    cmc_android_release_fail 'SIGNING_FINGERPRINT_UNREADABLE'
  [[ "${cmc_android_release_aab_fingerprint}" == \
    "${cmc_android_release_apk_fingerprint}" ]] || \
    cmc_android_release_fail 'AAB_APK_SIGNER_MISMATCH'
fi

if [[ "${cmc_android_release_require_upload}" == true ]]; then
  [[ "${cmc_android_release_signature_state}" == SIGNED ]] || \
    cmc_android_release_fail 'PLAY_INTERNAL_REQUIRES_SIGNED_AAB'
  [[ "${PLAY_INTERNAL_UPLOAD_AUTHORIZED:-}" == true ]] || \
    cmc_android_release_fail 'PLAY_INTERNAL_AUTHORIZATION_MISSING'
  [[ -n "${PLAY_SERVICE_ACCOUNT_JSON_PATH:-}" && \
    -f "${PLAY_SERVICE_ACCOUNT_JSON_PATH}" && \
    -r "${PLAY_SERVICE_ACCOUNT_JSON_PATH}" ]] || \
    cmc_android_release_fail 'PLAY_SERVICE_ACCOUNT_MISSING'
  if ! dart --disable-dart-dev "${cmc_android_release_play_credentials_tool}" \
    --service-account "${PLAY_SERVICE_ACCOUNT_JSON_PATH}" \
    --expected-email "${PLAY_SERVICE_ACCOUNT_EXPECTED_EMAIL:-}" \
    --expected-project "${PLAY_SERVICE_ACCOUNT_EXPECTED_PROJECT_ID:-}" \
    --expected-fingerprint "${ANDROID_SIGNING_CERT_SHA256:-}" \
    --artifact-fingerprint "${cmc_android_release_aab_fingerprint}" \
    >/dev/null; then
    cmc_android_release_fail 'PLAY_SERVICE_ACCOUNT_INVALID'
  fi
fi

bash "${cmc_android_release_script_dir}/check-client-security.sh" \
  --artifact "${cmc_android_release_aab}" \
  --artifact "${cmc_android_release_apk}"

cmc_android_release_aab_sha="$(shasum -a 256 "${cmc_android_release_aab}" | awk '{print $1}')"
cmc_android_release_apk_sha="$(shasum -a 256 "${cmc_android_release_apk}" | awk '{print $1}')"
printf 'ANDROID_RELEASE_PACKAGE=%s\n' "${cmc_android_release_package}"
printf 'ANDROID_RELEASE_VERSION=%s+%s\n' \
  "${cmc_android_release_version_name}" "${cmc_android_release_version_code}"
printf 'ANDROID_RELEASE_ABIS=%s\n' "${cmc_android_release_abis}"
printf 'ANDROID_RELEASE_SIGNING=%s\n' "${cmc_android_release_signature_state}"
printf 'ANDROID_RELEASE_AAB_SHA256=%s\n' "${cmc_android_release_aab_sha}"
printf 'ANDROID_RELEASE_APK_SHA256=%s\n' "${cmc_android_release_apk_sha}"
printf 'ANDROID_APP_LINK_BLOCKED: OWNED_HTTPS_DOMAIN_AND_ASSOCIATION_FILE_REQUIRED\n'

if [[ "${cmc_android_release_require_upload}" == true ]]; then
  printf 'ANDROID_INTERNAL_UPLOAD_INPUTS_VALIDATED\n'
else
  if [[ "${cmc_android_release_signature_state}" == SIGNED ]]; then
    printf 'ANDROID_RELEASE_CANDIDATE_READY_SIGNED\n'
  else
    printf 'ANDROID_RELEASE_CANDIDATE_READY_UNSIGNED\n'
  fi
fi
