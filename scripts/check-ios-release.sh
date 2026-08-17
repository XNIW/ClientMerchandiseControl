#!/usr/bin/env bash
set -euo pipefail

cmc_ios_release_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_ios_release_root="$(git -C "${cmc_ios_release_script_dir}" rev-parse --show-toplevel)"
cmc_ios_release_app=''
cmc_ios_release_archive=''
cmc_ios_release_source_only=false
cmc_ios_release_require_upload=false

cmc_ios_release_fail() {
  printf 'IOS_RELEASE_BLOCKED: %s\n' "$1" >&2
  exit 1
}

cmc_ios_release_usage() {
  printf '%s\n' \
    'Usage: scripts/check-ios-release.sh --source-only' \
    '   or: scripts/check-ios-release.sh --app <Runner.app> [--archive <Runner.xcarchive>] [--require-upload-ready]'
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --app)
      shift
      [[ "$#" -gt 0 ]] || cmc_ios_release_fail 'APP_PATH_MISSING'
      cmc_ios_release_app="$1"
      ;;
    --archive)
      shift
      [[ "$#" -gt 0 ]] || cmc_ios_release_fail 'ARCHIVE_PATH_MISSING'
      cmc_ios_release_archive="$1"
      ;;
    --source-only)
      cmc_ios_release_source_only=true
      ;;
    --require-upload-ready)
      cmc_ios_release_require_upload=true
      ;;
    --help)
      cmc_ios_release_usage
      exit 0
      ;;
    *)
      cmc_ios_release_fail 'UNSUPPORTED_ARGUMENT'
      ;;
  esac
  shift
done

cmc_ios_release_info="${cmc_ios_release_root}/ios/Runner/Info.plist"
cmc_ios_release_privacy="${cmc_ios_release_root}/ios/Runner/PrivacyInfo.xcprivacy"
cmc_ios_release_xcode="${cmc_ios_release_root}/ios/Runner.xcodeproj/project.pbxproj"
cmc_ios_release_scheme="${cmc_ios_release_root}/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme"
cmc_ios_release_config="${cmc_ios_release_root}/config/app_config.production.release.json"
cmc_ios_release_xcconfig="${cmc_ios_release_root}/ios/Flutter/Release.xcconfig"
cmc_ios_release_security="${cmc_ios_release_root}/scripts/check-client-security.sh"

for cmc_ios_release_file in \
  "${cmc_ios_release_info}" \
  "${cmc_ios_release_privacy}" \
  "${cmc_ios_release_xcode}" \
  "${cmc_ios_release_scheme}" \
  "${cmc_ios_release_config}" \
  "${cmc_ios_release_xcconfig}" \
  "${cmc_ios_release_security}"; do
  [[ -r "${cmc_ios_release_file}" ]] || \
    cmc_ios_release_fail 'RELEASE_SOURCE_MISSING'
done

for cmc_ios_release_command in \
  codesign dart dwarfdump file find lipo openssl otool perl plutil python3 shasum; do
  command -v "${cmc_ios_release_command}" >/dev/null 2>&1 || \
    cmc_ios_release_fail 'ARTIFACT_TOOLING_MISSING'
done
[[ -x /usr/libexec/PlistBuddy ]] || \
  cmc_ios_release_fail 'PLIST_TOOLING_MISSING'

cmc_ios_release_require_literal() {
  local cmc_ios_release_file="$1"
  local cmc_ios_release_literal="$2"
  local cmc_ios_release_code="$3"
  grep -Fq -- "${cmc_ios_release_literal}" "${cmc_ios_release_file}" || \
    cmc_ios_release_fail "${cmc_ios_release_code}"
}

cmc_ios_release_require_literal \
  "${cmc_ios_release_config}" '"APP_ENV": "production"' \
  'PRODUCTION_ENV_MISSING'
cmc_ios_release_require_literal \
  "${cmc_ios_release_config}" '"GOOGLE_AUTH_ENABLED": "false"' \
  'OAUTH_NOT_FAIL_CLOSED'
cmc_ios_release_require_literal \
  "${cmc_ios_release_config}" '"DELIVERY_MAPS_ENABLED": "false"' \
  'MAPS_NOT_FAIL_CLOSED'
cmc_ios_release_require_literal \
  "${cmc_ios_release_config}" '"DELIVERY_MAPS_NATIVE_CONFIGURED": "false"' \
  'MAPS_NATIVE_NOT_FAIL_CLOSED'
cmc_ios_release_require_literal \
  "${cmc_ios_release_xcconfig}" 'IOS_GOOGLE_MAPS_API_KEY=NOT_CONFIGURED' \
  'MAPS_NATIVE_SENTINEL_MISSING'
cmc_ios_release_require_literal \
  "${cmc_ios_release_xcode}" 'PRODUCT_BUNDLE_IDENTIFIER = com.xniw.clientmerchandisecontrol;' \
  'BUNDLE_IDENTIFIER_MISMATCH'
cmc_ios_release_require_literal \
  "${cmc_ios_release_xcode}" 'DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";' \
  'DSYM_CONFIGURATION_MISSING'
cmc_ios_release_require_literal \
  "${cmc_ios_release_scheme}" 'buildForArchiving = "YES"' \
  'ARCHIVE_SCHEME_DISABLED'
cmc_ios_release_require_literal \
  "${cmc_ios_release_scheme}" 'buildConfiguration = "Release"' \
  'ARCHIVE_NOT_RELEASE'

cmc_ios_release_validate_url_types() {
  local cmc_ios_release_plist="$1"

  plutil -extract CFBundleURLTypes json -o - \
    "${cmc_ios_release_plist}" 2>/dev/null | perl -MJSON::PP -e '
      use strict;
      use warnings;
      local $/;
      my $decoded = eval { JSON::PP->new->utf8->decode(<STDIN>) };
      exit 1 if $@ || ref($decoded) ne "ARRAY" || @$decoded != 1;
      my $entry = $decoded->[0];
      exit 1 if ref($entry) ne "HASH";
      my %expected = map { $_ => 1 }
        qw(CFBundleTypeRole CFBundleURLName CFBundleURLSchemes);
      exit 1 if grep { !$expected{$_} } keys %$entry;
      exit 1 if keys(%$entry) != keys(%expected);
      exit 1 if ($entry->{CFBundleTypeRole} // "") ne "Editor";
      exit 1 if ($entry->{CFBundleURLName} // "") ne
        "com.xniw.clientmerchandisecontrol.storefront";
      my $schemes = $entry->{CFBundleURLSchemes};
      exit 1 if ref($schemes) ne "ARRAY" || @$schemes != 1;
      exit 1 if $schemes->[0] ne "com.xniw.clientmerchandisecontrol";
      exit 0;
    ' || cmc_ios_release_fail 'DEEPLINK_SCHEME_SET_INVALID'
}

cmc_ios_release_validate_privacy_manifest() {
  local cmc_ios_release_manifest="$1"

  plutil -convert json -o - "${cmc_ios_release_manifest}" 2>/dev/null | \
    perl -MJSON::PP -e '
      use strict;
      use warnings;
      local $/;
      my $decoded = eval { JSON::PP->new->utf8->decode(<STDIN>) };
      exit 1 if $@ || ref($decoded) ne "HASH";
      my %expected = map { $_ => 1 } qw(
        NSPrivacyAccessedAPITypes
        NSPrivacyCollectedDataTypes
        NSPrivacyTracking
        NSPrivacyTrackingDomains
      );
      exit 1 if keys(%$decoded) != keys(%expected);
      exit 1 if grep { !$expected{$_} } keys %$decoded;
      exit 1 if ref($decoded->{NSPrivacyAccessedAPITypes}) ne "ARRAY";
      exit 1 if ref($decoded->{NSPrivacyCollectedDataTypes}) ne "ARRAY";
      exit 1 if ref($decoded->{NSPrivacyTrackingDomains}) ne "ARRAY";
      exit 1 if !JSON::PP::is_bool($decoded->{NSPrivacyTracking}) ||
        $decoded->{NSPrivacyTracking};
      exit 1 if @{$decoded->{NSPrivacyTrackingDomains}};

      my %accessed_reasons = (
        NSPrivacyAccessedAPICategoryDiskSpace => { "85F4.1" => 1 },
        NSPrivacyAccessedAPICategoryFileTimestamp => {
          "0A2A.1" => 1,
          "C617.1" => 1,
        },
        NSPrivacyAccessedAPICategorySystemBootTime => { "35F9.1" => 1 },
        NSPrivacyAccessedAPICategoryUserDefaults => { "1C8F.1" => 1 },
      );
      my %seen_accessed_types;
      for my $entry (@{$decoded->{NSPrivacyAccessedAPITypes}}) {
        exit 1 if ref($entry) ne "HASH";
        my %entry_expected = map { $_ => 1 } qw(
          NSPrivacyAccessedAPIType
          NSPrivacyAccessedAPITypeReasons
        );
        exit 1 if keys(%$entry) != keys(%entry_expected);
        exit 1 if grep { !$entry_expected{$_} } keys %$entry;
        my $type = $entry->{NSPrivacyAccessedAPIType};
        exit 1 if ref($type) || !exists $accessed_reasons{$type};
        exit 1 if $seen_accessed_types{$type}++;
        my $reasons = $entry->{NSPrivacyAccessedAPITypeReasons};
        exit 1 if ref($reasons) ne "ARRAY" || !@$reasons;
        my %seen_reasons;
        for my $reason (@$reasons) {
          exit 1 if ref($reason) ||
            !$accessed_reasons{$type}->{$reason};
          exit 1 if $seen_reasons{$reason}++;
        }
      }

      my %allowed_collected_types = map { $_ => 1 } qw(
        NSPrivacyCollectedDataTypeCrashData
        NSPrivacyCollectedDataTypeDeviceID
        NSPrivacyCollectedDataTypeEmailAddress
        NSPrivacyCollectedDataTypeName
        NSPrivacyCollectedDataTypeOtherUserContent
        NSPrivacyCollectedDataTypePaymentInfo
        NSPrivacyCollectedDataTypePerformanceData
        NSPrivacyCollectedDataTypePhysicalAddress
        NSPrivacyCollectedDataTypeProductInteraction
        NSPrivacyCollectedDataTypePurchaseHistory
        NSPrivacyCollectedDataTypeSearchHistory
        NSPrivacyCollectedDataTypeUserID
      );
      my %allowed_collected_purposes = map { $_ => 1 } qw(
        NSPrivacyCollectedDataTypePurposeAnalytics
        NSPrivacyCollectedDataTypePurposeAppFunctionality
      );
      my %seen_collected_types;
      for my $entry (@{$decoded->{NSPrivacyCollectedDataTypes}}) {
        exit 1 if ref($entry) ne "HASH";
        my %entry_expected = map { $_ => 1 } qw(
          NSPrivacyCollectedDataType
          NSPrivacyCollectedDataTypeLinked
          NSPrivacyCollectedDataTypePurposes
          NSPrivacyCollectedDataTypeTracking
        );
        exit 1 if keys(%$entry) != keys(%entry_expected);
        exit 1 if grep { !$entry_expected{$_} } keys %$entry;
        my $type = $entry->{NSPrivacyCollectedDataType};
        exit 1 if ref($type) || !$allowed_collected_types{$type};
        exit 1 if $seen_collected_types{$type}++;
        exit 1 if !JSON::PP::is_bool(
          $entry->{NSPrivacyCollectedDataTypeLinked}
        );
        exit 1 if !JSON::PP::is_bool(
          $entry->{NSPrivacyCollectedDataTypeTracking}
        ) || $entry->{NSPrivacyCollectedDataTypeTracking};
        my $purposes = $entry->{NSPrivacyCollectedDataTypePurposes};
        exit 1 if ref($purposes) ne "ARRAY" || !@$purposes;
        my %seen_purposes;
        for my $purpose (@$purposes) {
          exit 1 if ref($purpose) || !$allowed_collected_purposes{$purpose};
          exit 1 if $seen_purposes{$purpose}++;
        }
      }
      exit 0;
    '
}

if grep -Eq 'SUPABASE_|AUTH_REDIRECT_URI|STOREFRONT_SHOP_SLUG' \
  "${cmc_ios_release_config}"; then
  cmc_ios_release_fail 'PRODUCTION_TEMPLATE_CONTAINS_EXTERNAL_VALUE'
fi
if find "${cmc_ios_release_root}/ios/Runner" -maxdepth 1 \
  -type f -name '*.entitlements' -print -quit | grep -q .; then
  cmc_ios_release_entitlement_source=PRESENT
else
  cmc_ios_release_entitlement_source=ABSENT
fi

cmc_ios_release_source_bundle="$(
  /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' \
    "${cmc_ios_release_info}" 2>/dev/null || true
)"
# Info.plist usa la variabile build; il valore finale è verificato nell'artifact.
[[ "${cmc_ios_release_source_bundle// /}" == '$(PRODUCT_BUNDLE_IDENTIFIER)' ]] || \
  cmc_ios_release_fail 'SOURCE_BUNDLE_IDENTIFIER_NOT_BUILD_BOUND'
[[ "$(/usr/libexec/PlistBuddy -c 'Print :FlutterDeepLinkingEnabled' \
  "${cmc_ios_release_info}")" == false ]] || \
  cmc_ios_release_fail 'UNREVIEWED_FLUTTER_DEEPLINKING_ENABLED'
cmc_ios_release_validate_url_types "${cmc_ios_release_info}"
plutil -lint "${cmc_ios_release_info}" "${cmc_ios_release_privacy}" >/dev/null || \
  cmc_ios_release_fail 'PLIST_INVALID'

if [[ "${cmc_ios_release_source_only}" == true ]]; then
  if [[ -n "${cmc_ios_release_app}" || -n "${cmc_ios_release_archive}" || \
    "${cmc_ios_release_require_upload}" == true ]]; then
    cmc_ios_release_fail 'SOURCE_ONLY_ARGUMENT_CONFLICT'
  fi
  printf 'IOS_RELEASE_SOURCE_READY_UNSIGNED\n'
  printf 'IOS_PUSH_ACTIVATION_BLOCKED: REVIEWED_ENTITLEMENT_AND_APNS_REQUIRED\n'
  printf 'IOS_UNIVERSAL_LINKS_ACTIVATION_BLOCKED: OWNED_DOMAIN_AND_ASSOCIATION_FILE_REQUIRED\n'
  printf 'IOS_MAPS_ACTIVATION_BLOCKED: RESTRICTED_KEY_BILLING_AND_OWNER_SWITCH_REQUIRED\n'
  exit 0
fi

[[ -n "${cmc_ios_release_app}" && -d "${cmc_ios_release_app}" ]] || \
  cmc_ios_release_fail 'APP_NOT_READABLE'
case "${cmc_ios_release_app}" in
  *.app) ;;
  *) cmc_ios_release_fail 'APP_EXTENSION_INVALID' ;;
esac

cmc_ios_release_app_info="${cmc_ios_release_app}/Info.plist"
cmc_ios_release_app_privacy="${cmc_ios_release_app}/PrivacyInfo.xcprivacy"
[[ -r "${cmc_ios_release_app_info}" && -r "${cmc_ios_release_app_privacy}" ]] || \
  cmc_ios_release_fail 'APP_METADATA_MISSING'
cmc_ios_release_executable_name="$(
  /usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' \
    "${cmc_ios_release_app_info}" 2>/dev/null || true
)"
[[ "${cmc_ios_release_executable_name}" == 'Runner' ]] || \
  cmc_ios_release_fail 'APP_EXECUTABLE_NAME_INVALID'
cmc_ios_release_executable="${cmc_ios_release_app}/${cmc_ios_release_executable_name}"
[[ -n "${cmc_ios_release_executable_name}" && \
  -x "${cmc_ios_release_executable}" ]] || \
  cmc_ios_release_fail 'APP_EXECUTABLE_MISSING'
file "${cmc_ios_release_executable}" | grep -Fq 'Mach-O' || \
  cmc_ios_release_fail 'APP_EXECUTABLE_NOT_MACHO'

cmc_ios_release_bundle="$(
  /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' \
    "${cmc_ios_release_app_info}" 2>/dev/null || true
)"
cmc_ios_release_version="$(
  /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
    "${cmc_ios_release_app_info}" 2>/dev/null || true
)"
cmc_ios_release_build="$(
  /usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' \
    "${cmc_ios_release_app_info}" 2>/dev/null || true
)"
[[ "${cmc_ios_release_bundle// /}" == \
  'com.xniw.clientmerchandisecontrol' ]] || \
  cmc_ios_release_fail 'ARTIFACT_BUNDLE_IDENTIFIER_MISMATCH'
[[ "${cmc_ios_release_version// /}" == '0.1.0' ]] || \
  cmc_ios_release_fail 'ARTIFACT_VERSION_MISMATCH'
[[ "${cmc_ios_release_build// /}" == '1' ]] || \
  cmc_ios_release_fail 'ARTIFACT_BUILD_MISMATCH'
[[ "$(/usr/libexec/PlistBuddy -c 'Print :MinimumOSVersion' \
  "${cmc_ios_release_app_info}" 2>/dev/null || true)" == '14.0' ]] || \
  cmc_ios_release_fail 'ARTIFACT_DEPLOYMENT_TARGET_MISMATCH'
[[ "$(/usr/libexec/PlistBuddy -c 'Print :DTPlatformName' \
  "${cmc_ios_release_app_info}" 2>/dev/null || true)" == 'iphoneos' ]] || \
  cmc_ios_release_fail 'ARTIFACT_PLATFORM_MISMATCH'
[[ "$(lipo -archs "${cmc_ios_release_executable}")" == 'arm64' ]] || \
  cmc_ios_release_fail 'ARTIFACT_ARCHITECTURE_MISMATCH'
cmp -s "${cmc_ios_release_privacy}" "${cmc_ios_release_app_privacy}" || \
  cmc_ios_release_fail 'APP_PRIVACY_MANIFEST_MISMATCH'

cmc_ios_release_artifact_maps="$(
  /usr/libexec/PlistBuddy -c 'Print :GoogleMapsAPIKey' \
    "${cmc_ios_release_app_info}" 2>/dev/null || true
)"
[[ "${cmc_ios_release_artifact_maps// /}" == 'NOT_CONFIGURED' ]] || \
  cmc_ios_release_fail 'MAPS_ARTIFACT_NOT_FAIL_CLOSED'
cmc_ios_release_validate_url_types "${cmc_ios_release_app_info}"
cmc_ios_release_privacy_paths=(
  'PrivacyInfo.xcprivacy'
  'Frameworks/Flutter.framework/PrivacyInfo.xcprivacy'
  'app_links_app_links.bundle/PrivacyInfo.xcprivacy'
  'flutter_secure_storage_darwin_flutter_secure_storage_darwin.bundle/PrivacyInfo.xcprivacy'
  'google_maps_flutter_ios_privacy.bundle/PrivacyInfo.xcprivacy'
  'share_plus_share_plus.bundle/PrivacyInfo.xcprivacy'
  'shared_preferences_foundation_shared_preferences_foundation.bundle/PrivacyInfo.xcprivacy'
  'url_launcher_ios_url_launcher_ios.bundle/PrivacyInfo.xcprivacy'
)
cmc_ios_release_privacy_sha256=(
  '3528adeddf0b68a86a885a1f361b1e8e4c4c2002f03b1490bba3fa0c6b0ae7c2'
  '30e7356e5a4601a790ff13801eb5c16a361a7efed258ba0b7912976a072ba0c6'
  '3b49c699d80484e28adc8dcd4edc6febc3e232a7d9bab57459dfadac2d80033d'
  '3b49c699d80484e28adc8dcd4edc6febc3e232a7d9bab57459dfadac2d80033d'
  '53f5cef36626b46c5490cdb9af8ab42c3c67778b21267e899ca6d494118ffb18'
  '3b49c699d80484e28adc8dcd4edc6febc3e232a7d9bab57459dfadac2d80033d'
  '333d51ec3d7daca74fe6a61bfb18074708bed233b4d5d0f3a1ad161e96d85b1c'
  '3b49c699d80484e28adc8dcd4edc6febc3e232a7d9bab57459dfadac2d80033d'
)
for cmc_ios_release_privacy_index in \
  "${!cmc_ios_release_privacy_paths[@]}"; do
  cmc_ios_release_privacy_relative="${cmc_ios_release_privacy_paths[cmc_ios_release_privacy_index]}"
  cmc_ios_release_privacy_file="${cmc_ios_release_app}/${cmc_ios_release_privacy_relative}"
  [[ -f "${cmc_ios_release_app}/${cmc_ios_release_privacy_relative}" ]] || \
    cmc_ios_release_fail 'DEPENDENCY_PRIVACY_MANIFEST_MISSING'
  plutil -lint \
    "${cmc_ios_release_privacy_file}" \
    >/dev/null 2>&1 || \
    cmc_ios_release_fail 'DEPENDENCY_PRIVACY_MANIFEST_INVALID'
  cmc_ios_release_validate_privacy_manifest \
    "${cmc_ios_release_privacy_file}" || \
    cmc_ios_release_fail 'DEPENDENCY_PRIVACY_MANIFEST_INVALID'
  cmc_ios_release_privacy_digest="$(
    plutil -convert json -o - "${cmc_ios_release_privacy_file}" 2>/dev/null | \
      perl -MJSON::PP -e '
        use strict;
        use warnings;
        local $/;
        my $decoded = eval { JSON::PP->new->utf8->decode(<STDIN>) };
        exit 1 if $@;
        print JSON::PP->new->canonical->encode($decoded);
      ' | shasum -a 256
  )" || cmc_ios_release_fail 'DEPENDENCY_PRIVACY_MANIFEST_INVALID'
  cmc_ios_release_privacy_digest="${cmc_ios_release_privacy_digest%% *}"
  [[ "${cmc_ios_release_privacy_digest}" == \
    "${cmc_ios_release_privacy_sha256[cmc_ios_release_privacy_index]}" ]] || \
    cmc_ios_release_fail 'DEPENDENCY_PRIVACY_MANIFEST_CONTENT_MISMATCH'
done
[[ "$(find "${cmc_ios_release_app}" -name PrivacyInfo.xcprivacy -type f | \
  wc -l | tr -d '[:space:]')" -eq "${#cmc_ios_release_privacy_paths[@]}" ]] || \
  cmc_ios_release_fail 'DEPENDENCY_PRIVACY_MANIFEST_SET_INVALID'

cmc_ios_release_framework_count=0
while IFS= read -r -d '' cmc_ios_release_framework; do
  cmc_ios_release_framework_count=$((cmc_ios_release_framework_count + 1))
  cmc_ios_release_framework_info="${cmc_ios_release_framework}/Info.plist"
  [[ -r "${cmc_ios_release_framework_info}" ]] || \
    cmc_ios_release_fail 'FRAMEWORK_INFO_MISSING'
  cmc_ios_release_framework_executable_name="$(
    /usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' \
      "${cmc_ios_release_framework_info}" 2>/dev/null || true
  )"
  [[ -n "${cmc_ios_release_framework_executable_name}" && \
    "${cmc_ios_release_framework_executable_name}" != '.' && \
    "${cmc_ios_release_framework_executable_name}" != '..' && \
    "${cmc_ios_release_framework_executable_name}" != */* ]] || \
    cmc_ios_release_fail 'FRAMEWORK_EXECUTABLE_NAME_INVALID'
  cmc_ios_release_framework_executable="${cmc_ios_release_framework}/${cmc_ios_release_framework_executable_name}"
  [[ -n "${cmc_ios_release_framework_executable_name}" && \
    -r "${cmc_ios_release_framework_executable}" ]] || \
    cmc_ios_release_fail 'FRAMEWORK_EXECUTABLE_MISSING'
  file "${cmc_ios_release_framework_executable}" | grep -Fq 'Mach-O' || \
    cmc_ios_release_fail 'FRAMEWORK_EXECUTABLE_NOT_MACHO'
  lipo -archs "${cmc_ios_release_framework_executable}" | \
    tr ' ' '\n' | grep -Fxq arm64 || \
    cmc_ios_release_fail 'FRAMEWORK_ARM64_MISSING'
done < <(find "${cmc_ios_release_app}/Frameworks" \
  -mindepth 1 -maxdepth 1 -type d -name '*.framework' -print0)
[[ "${cmc_ios_release_framework_count}" -ge 3 ]] || \
  cmc_ios_release_fail 'EMBEDDED_FRAMEWORK_SET_INCOMPLETE'
cmc_ios_release_runtime_executable="${cmc_ios_release_app}/Frameworks/App.framework/App"
[[ -f "${cmc_ios_release_runtime_executable}" && \
  ! -L "${cmc_ios_release_runtime_executable}" ]] || \
  cmc_ios_release_fail 'RUNTIME_EXECUTABLE_INVALID'
file "${cmc_ios_release_runtime_executable}" | grep -Fq 'Mach-O' || \
  cmc_ios_release_fail 'RUNTIME_EXECUTABLE_INVALID'
[[ "$(lipo -archs "${cmc_ios_release_runtime_executable}")" == 'arm64' ]] || \
  cmc_ios_release_fail 'RUNTIME_ARCHITECTURE_INVALID'

cmc_ios_release_signature_commands="$(
  otool -l "${cmc_ios_release_executable}" | \
    awk '$1 == "cmd" && $2 == "LC_CODE_SIGNATURE" { count++ } END { print count + 0 }'
)" || cmc_ios_release_fail 'SIGNATURE_METADATA_UNREADABLE'
[[ "${cmc_ios_release_signature_commands}" =~ ^[0-9]+$ && \
  "${cmc_ios_release_signature_commands}" -le 1 ]] || \
  cmc_ios_release_fail 'SIGNATURE_METADATA_INVALID'
if [[ "${cmc_ios_release_signature_commands}" -eq 1 || \
  -e "${cmc_ios_release_app}/_CodeSignature" ]]; then
  codesign --display "${cmc_ios_release_app}" >/dev/null 2>&1 || \
    cmc_ios_release_fail 'ARTIFACT_SIGNATURE_INVALID'
  codesign --verify --deep --strict "${cmc_ios_release_app}" \
    >/dev/null 2>&1 || cmc_ios_release_fail 'ARTIFACT_SIGNATURE_INVALID'
  cmc_ios_release_signing_state='SIGNED'
else
  if codesign --display "${cmc_ios_release_app}" >/dev/null 2>&1; then
    cmc_ios_release_fail 'SIGNATURE_METADATA_INVALID'
  fi
  cmc_ios_release_signing_state='UNSIGNED'
fi

cmc_ios_release_tmp_parent="${TMPDIR:-/tmp}"
cmc_ios_release_tmp_parent="${cmc_ios_release_tmp_parent%/}"
cmc_ios_release_tmp_root="$(
  mktemp -d "${cmc_ios_release_tmp_parent}/cmc-ios-release.XXXXXX"
)"
cmc_ios_release_cleanup() {
  case "${cmc_ios_release_tmp_root}" in
    "${cmc_ios_release_tmp_parent}"/cmc-ios-release.*)
      rm -rf -- "${cmc_ios_release_tmp_root}"
      ;;
    *)
      printf 'IOS_RELEASE_BLOCKED: TEMP_CLEANUP_REFUSED\n' >&2
      ;;
  esac
}
trap cmc_ios_release_cleanup EXIT

if [[ "${cmc_ios_release_signing_state}" == SIGNED ]]; then
  cmc_ios_release_entitlements="${cmc_ios_release_tmp_root}/entitlements.plist"
  codesign --display --xml \
    --entitlements "${cmc_ios_release_entitlements}" \
    "${cmc_ios_release_app}" >/dev/null 2>&1 || \
    cmc_ios_release_fail 'SIGNED_ENTITLEMENTS_UNREADABLE'
  [[ -s "${cmc_ios_release_entitlements}" ]] || \
    cmc_ios_release_fail 'SIGNED_ENTITLEMENTS_MISSING'
  plutil -lint "${cmc_ios_release_entitlements}" >/dev/null || \
    cmc_ios_release_fail 'SIGNED_ENTITLEMENTS_INVALID'
  plutil -convert json -o - "${cmc_ios_release_entitlements}" | \
    perl -MJSON::PP -e '
      use strict;
      use warnings;
      local $/;
      my $decoded = eval { JSON::PP->new->utf8->decode(<STDIN>) };
      exit 1 if $@ || ref($decoded) ne "HASH";
      my %allowed = map { $_ => 1 } (
        "application-identifier",
        "com.apple.developer.team-identifier",
        "keychain-access-groups",
        "get-task-allow",
        "beta-reports-active",
      );
      exit 1 if grep { !$allowed{$_} } keys %$decoded;
      exit 0;
    ' || cmc_ios_release_fail 'SIGNED_ENTITLEMENT_SET_INVALID'
  if [[ "$(/usr/libexec/PlistBuddy -c 'Print :get-task-allow' \
    "${cmc_ios_release_entitlements}" 2>/dev/null || true)" == true ]]; then
    cmc_ios_release_fail 'DEBUG_ENTITLEMENT_PRESENT'
  fi
fi

if [[ -n "${cmc_ios_release_archive}" ]]; then
  [[ -d "${cmc_ios_release_archive}" ]] || \
    cmc_ios_release_fail 'ARCHIVE_NOT_READABLE'
  case "${cmc_ios_release_archive}" in
    *.xcarchive) ;;
    *) cmc_ios_release_fail 'ARCHIVE_EXTENSION_INVALID' ;;
  esac
  cmc_ios_release_archive_info="${cmc_ios_release_archive}/Info.plist"
  cmc_ios_release_archive_applications="${cmc_ios_release_archive}/Products/Applications"
  cmc_ios_release_archive_app="${cmc_ios_release_archive}/Products/Applications/Runner.app"
  cmc_ios_release_archive_dsym="${cmc_ios_release_archive}/dSYMs/Runner.app.dSYM/Contents/Resources/DWARF/Runner"
  [[ -r "${cmc_ios_release_archive_info}" && \
    -d "${cmc_ios_release_archive_applications}" && \
    ! -L "${cmc_ios_release_archive_applications}" && \
    -d "${cmc_ios_release_archive_app}" && \
    ! -L "${cmc_ios_release_archive_app}" && \
    -r "${cmc_ios_release_archive_dsym}" ]] || \
    cmc_ios_release_fail 'ARCHIVE_CONTENT_MISSING'
  [[ "$(/usr/libexec/PlistBuddy -c \
    'Print :ApplicationProperties:ApplicationPath' \
    "${cmc_ios_release_archive_info}" 2>/dev/null || true)" == \
    'Applications/Runner.app' ]] || \
    cmc_ios_release_fail 'ARCHIVE_APPLICATION_PATH_MISMATCH'
  cmc_ios_release_archive_app_count=0
  while IFS= read -r -d '' cmc_ios_release_archive_app_entry; do
    cmc_ios_release_archive_app_count=$((cmc_ios_release_archive_app_count + 1))
    [[ "${cmc_ios_release_archive_app_entry}" == \
      "${cmc_ios_release_archive_app}" ]] || \
      cmc_ios_release_fail 'ARCHIVE_APPLICATION_SET_INVALID'
  done < <(find "${cmc_ios_release_archive_applications}" \
    -mindepth 1 -maxdepth 1 -name '*.app' -print0)
  [[ "${cmc_ios_release_archive_app_count}" -eq 1 ]] || \
    cmc_ios_release_fail 'ARCHIVE_APPLICATION_SET_INVALID'
  [[ "$(/usr/libexec/PlistBuddy -c \
    'Print :ApplicationProperties:CFBundleIdentifier' \
    "${cmc_ios_release_archive_info}")" == \
    'com.xniw.clientmerchandisecontrol' ]] || \
    cmc_ios_release_fail 'ARCHIVE_BUNDLE_IDENTIFIER_MISMATCH'
  [[ "$(/usr/libexec/PlistBuddy -c \
    'Print :ApplicationProperties:CFBundleShortVersionString' \
    "${cmc_ios_release_archive_info}")" == '0.1.0' ]] || \
    cmc_ios_release_fail 'ARCHIVE_VERSION_MISMATCH'
  [[ "$(/usr/libexec/PlistBuddy -c \
    'Print :ApplicationProperties:CFBundleVersion' \
    "${cmc_ios_release_archive_info}")" == '1' ]] || \
    cmc_ios_release_fail 'ARCHIVE_BUILD_MISMATCH'
  cmc_ios_release_app_canonical="$(cd -- "${cmc_ios_release_app}" && pwd -P)"
  cmc_ios_release_archive_app_canonical="$(
    cd -- "${cmc_ios_release_archive_app}" && pwd -P
  )"
  [[ "${cmc_ios_release_app_canonical}" == \
    "${cmc_ios_release_archive_app_canonical}" ]] || \
    cmc_ios_release_fail 'APP_ARCHIVE_BUNDLE_MISMATCH'
  cmc_ios_release_binary_uuid="$(
    dwarfdump --uuid "${cmc_ios_release_archive_app}/Runner" | \
      awk 'NR == 1 { print $2 }'
  )"
  cmc_ios_release_dsym_uuid="$(
    dwarfdump --uuid "${cmc_ios_release_archive_dsym}" | \
      awk 'NR == 1 { print $2 }'
  )"
  [[ -n "${cmc_ios_release_binary_uuid}" && \
    "${cmc_ios_release_binary_uuid}" == "${cmc_ios_release_dsym_uuid}" ]] || \
    cmc_ios_release_fail 'ARCHIVE_DSYM_UUID_MISMATCH'
fi

cmc_ios_release_profile=''
if [[ -e "${cmc_ios_release_app}/embedded.mobileprovision" ]]; then
  [[ "${cmc_ios_release_signing_state}" == SIGNED ]] || \
    cmc_ios_release_fail 'UNSIGNED_APP_CONTAINS_PROVISIONING_PROFILE'
  [[ -f "${cmc_ios_release_app}/embedded.mobileprovision" && \
    ! -L "${cmc_ios_release_app}/embedded.mobileprovision" ]] || \
    cmc_ios_release_fail 'PROVISIONING_PROFILE_INVALID'
  command -v security >/dev/null 2>&1 || \
    cmc_ios_release_fail 'APPLE_SECURITY_TOOL_MISSING'
  cmc_ios_release_profile="${cmc_ios_release_tmp_root}/profile.plist"
  security cms -D -i "${cmc_ios_release_app}/embedded.mobileprovision" \
    >"${cmc_ios_release_profile}" 2>/dev/null || \
    cmc_ios_release_fail 'PROVISIONING_PROFILE_UNREADABLE'
  plutil -lint "${cmc_ios_release_profile}" >/dev/null || \
    cmc_ios_release_fail 'PROVISIONING_PROFILE_INVALID'
  if /usr/libexec/PlistBuddy -c 'Print :ProvisionedDevices' \
    "${cmc_ios_release_profile}" >/dev/null 2>&1 || \
    /usr/libexec/PlistBuddy -c 'Print :ProvisionsAllDevices' \
      "${cmc_ios_release_profile}" >/dev/null 2>&1; then
    cmc_ios_release_fail 'APP_STORE_PROVISIONING_PROFILE_REQUIRED'
  fi
  bash "${cmc_ios_release_security}" \
    --artifact "${cmc_ios_release_profile}" || \
    cmc_ios_release_fail 'PROVISIONING_PROFILE_SECURITY_SCAN_FAILED'
  bash "${cmc_ios_release_security}" \
    --allow-ios-embedded-profile --artifact "${cmc_ios_release_app}" || \
    cmc_ios_release_fail 'ARTIFACT_SECURITY_SCAN_FAILED'
else
  bash "${cmc_ios_release_security}" --artifact "${cmc_ios_release_app}" || \
    cmc_ios_release_fail 'ARTIFACT_SECURITY_SCAN_FAILED'
fi

cmc_ios_release_sha="$(
  shasum -a 256 "${cmc_ios_release_runtime_executable}" | awk '{print $1}'
)"
[[ "${cmc_ios_release_sha}" =~ ^[0-9a-f]{64}$ ]] || \
  cmc_ios_release_fail 'ARTIFACT_HASH_UNREADABLE'
cmc_ios_release_native_sha="$(
  shasum -a 256 "${cmc_ios_release_executable}" | awk '{print $1}'
)"
[[ "${cmc_ios_release_native_sha}" =~ ^[0-9a-f]{64}$ ]] || \
  cmc_ios_release_fail 'ARTIFACT_HASH_UNREADABLE'

if [[ "${cmc_ios_release_require_upload}" == true ]]; then
  [[ -n "${cmc_ios_release_archive}" ]] || \
    cmc_ios_release_fail 'TESTFLIGHT_REQUIRES_ARCHIVE'
  [[ "${cmc_ios_release_signing_state}" == SIGNED ]] || \
    cmc_ios_release_fail 'TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE'
  [[ -r "${cmc_ios_release_app}/embedded.mobileprovision" ]] || \
    cmc_ios_release_fail 'TESTFLIGHT_PROVISIONING_PROFILE_MISSING'
  [[ -n "${IOS_RELEASE_RUNTIME_CONFIG_PATH:-}" && \
    -f "${IOS_RELEASE_RUNTIME_CONFIG_PATH}" && \
    ! -L "${IOS_RELEASE_RUNTIME_CONFIG_PATH}" ]] || \
    cmc_ios_release_fail 'TESTFLIGHT_RUNTIME_CONFIG_MISSING'
  cmc_ios_release_runtime_fingerprint="$(
    dart run "${cmc_ios_release_root}/tool/check_ios_runtime_config.dart" \
      --config "${IOS_RELEASE_RUNTIME_CONFIG_PATH}"
  )" || cmc_ios_release_fail 'TESTFLIGHT_RUNTIME_CONFIG_INVALID'
  [[ "${cmc_ios_release_runtime_fingerprint}" =~ ^[0-9a-f]{64}$ ]] || \
    cmc_ios_release_fail 'TESTFLIGHT_RUNTIME_CONFIG_INVALID'
  cmc_ios_release_runtime_marker="CMC_RELEASE_CONFIG_ATTESTATION_V1:${cmc_ios_release_runtime_fingerprint}"
  perl -e '
    use strict;
    use warnings;
    my ($path, $expected) = @ARGV;
    open my $handle, "<", $path or exit 2;
    binmode $handle;
    local $/;
    my $content = <$handle>;
    close $handle or exit 2;
    my @markers =
      $content =~ /(CMC_RELEASE_CONFIG_ATTESTATION_V1:[0-9a-f]{64})/g;
    exit(@markers == 1 && $markers[0] eq $expected ? 0 : 1);
  ' "${cmc_ios_release_runtime_executable}" \
    "${cmc_ios_release_runtime_marker}" || \
    cmc_ios_release_fail 'TESTFLIGHT_RUNTIME_CONFIG_NOT_ARTIFACT_BOUND'
  [[ "${IOS_TESTFLIGHT_UPLOAD_AUTHORIZED:-}" == true ]] || \
    cmc_ios_release_fail 'TESTFLIGHT_AUTHORIZATION_MISSING'
  [[ "${IOS_EXPECTED_TEAM_ID:-}" =~ ^[A-Z0-9]{10}$ ]] || \
    cmc_ios_release_fail 'EXPECTED_TEAM_ID_MISSING'
  [[ "${IOS_EXPECTED_SIGNING_CERT_SHA256:-}" =~ ^[0-9A-Fa-f]{64}$ ]] || \
    cmc_ios_release_fail 'EXPECTED_SIGNING_FINGERPRINT_MISSING'
  command -v security >/dev/null 2>&1 || \
    cmc_ios_release_fail 'APPLE_SECURITY_TOOL_MISSING'
  cmc_ios_release_certificate_prefix="${cmc_ios_release_tmp_root}/certificate"
  codesign -d --extract-certificates "${cmc_ios_release_certificate_prefix}" \
    "${cmc_ios_release_app}" >/dev/null 2>&1 || \
    cmc_ios_release_fail 'SIGNING_CERTIFICATE_UNREADABLE'
  [[ -r "${cmc_ios_release_certificate_prefix}0" ]] || \
    cmc_ios_release_fail 'SIGNING_CERTIFICATE_UNREADABLE'
  cmc_ios_release_certificate_subject="$(
    openssl x509 -inform DER \
      -in "${cmc_ios_release_certificate_prefix}0" \
      -noout -subject 2>/dev/null
  )" || cmc_ios_release_fail 'SIGNING_CERTIFICATE_UNREADABLE'
  grep -Eq 'Apple Distribution:|iPhone Distribution:' \
    <<<"${cmc_ios_release_certificate_subject}" || \
    cmc_ios_release_fail 'APPLE_DISTRIBUTION_CERTIFICATE_REQUIRED'
  cmc_ios_release_certificate_fingerprint="$(
    openssl x509 -inform DER \
      -in "${cmc_ios_release_certificate_prefix}0" \
      -noout -fingerprint -sha256 2>/dev/null | \
      awk -F= 'NF == 2 { print $2 }' | \
      tr -d '[:space:]:' | tr '[:upper:]' '[:lower:]'
  )"
  [[ "${cmc_ios_release_certificate_fingerprint}" =~ ^[0-9a-f]{64}$ ]] || \
    cmc_ios_release_fail 'SIGNING_FINGERPRINT_UNREADABLE'
  [[ "${cmc_ios_release_certificate_fingerprint}" == \
    "$(tr '[:upper:]' '[:lower:]' \
      <<<"${IOS_EXPECTED_SIGNING_CERT_SHA256}")" ]] || \
    cmc_ios_release_fail 'SIGNING_FINGERPRINT_MISMATCH'
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :TeamIdentifier:0' \
    "${cmc_ios_release_profile}" 2>/dev/null || true)" == \
    "${IOS_EXPECTED_TEAM_ID}" ]] || \
    cmc_ios_release_fail 'PROVISIONING_TEAM_MISMATCH'
  [[ "$(/usr/libexec/PlistBuddy -c \
    'Print :Entitlements:application-identifier' \
    "${cmc_ios_release_profile}" 2>/dev/null || true)" == \
    "${IOS_EXPECTED_TEAM_ID}.com.xniw.clientmerchandisecontrol" ]] || \
    cmc_ios_release_fail 'PROVISIONING_APPLICATION_IDENTIFIER_MISMATCH'
  [[ "$(/usr/libexec/PlistBuddy -c \
    'Print :Entitlements:com.apple.developer.team-identifier' \
    "${cmc_ios_release_profile}" 2>/dev/null || true)" == \
    "${IOS_EXPECTED_TEAM_ID}" ]] || \
    cmc_ios_release_fail 'PROVISIONING_ENTITLEMENT_TEAM_MISMATCH'
  if [[ "$(/usr/libexec/PlistBuddy -c \
    'Print :Entitlements:get-task-allow' \
    "${cmc_ios_release_profile}" 2>/dev/null || true)" == true ]]; then
    cmc_ios_release_fail 'DEVELOPMENT_PROVISIONING_PROFILE_REJECTED'
  fi
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :application-identifier' \
    "${cmc_ios_release_entitlements}" 2>/dev/null || true)" == \
    "${IOS_EXPECTED_TEAM_ID}.com.xniw.clientmerchandisecontrol" ]] || \
    cmc_ios_release_fail 'SIGNED_APPLICATION_IDENTIFIER_MISMATCH'
  [[ "$(/usr/libexec/PlistBuddy -c \
    'Print :com.apple.developer.team-identifier' \
    "${cmc_ios_release_entitlements}" 2>/dev/null || true)" == \
    "${IOS_EXPECTED_TEAM_ID}" ]] || \
    cmc_ios_release_fail 'SIGNED_TEAM_IDENTIFIER_MISMATCH'
  cmc_ios_release_keychain_groups="$(
    plutil -extract keychain-access-groups json -o - \
      "${cmc_ios_release_entitlements}" 2>/dev/null | tr -d '[:space:]'
  )" || cmc_ios_release_fail 'SIGNED_KEYCHAIN_GROUP_MISSING'
  if [[ "${cmc_ios_release_keychain_groups}" != \
      "[\"${IOS_EXPECTED_TEAM_ID}.*\"]" && \
    "${cmc_ios_release_keychain_groups}" != \
      "[\"${IOS_EXPECTED_TEAM_ID}.com.xniw.clientmerchandisecontrol\"]" ]]; then
    cmc_ios_release_fail 'SIGNED_KEYCHAIN_GROUP_MISMATCH'
  fi
  [[ "${APP_STORE_CONNECT_KEY_ID:-}" =~ ^[A-Z0-9]{10}$ ]] || \
    cmc_ios_release_fail 'APP_STORE_CONNECT_KEY_ID_MISSING'
  [[ "${APP_STORE_CONNECT_ISSUER_ID:-}" =~ \
    ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]] || \
    cmc_ios_release_fail 'APP_STORE_CONNECT_ISSUER_ID_MISSING'
  [[ -n "${APP_STORE_CONNECT_API_KEY_PATH:-}" && \
    -r "${APP_STORE_CONNECT_API_KEY_PATH}" ]] || \
    cmc_ios_release_fail 'APP_STORE_CONNECT_API_KEY_MISSING'
  openssl pkey -in "${APP_STORE_CONNECT_API_KEY_PATH}" -noout \
    >/dev/null 2>&1 || \
    cmc_ios_release_fail 'APP_STORE_CONNECT_API_KEY_INVALID'
  printf 'IOS_TESTFLIGHT_UPLOAD_INPUTS_VALIDATED\n'
fi

printf 'IOS_RELEASE_CANDIDATE_VALID\n'
printf 'IOS_RELEASE_SIGNING=%s\n' "${cmc_ios_release_signing_state}"
printf 'IOS_RELEASE_EXECUTABLE_SHA256=%s\n' "${cmc_ios_release_sha}"
printf 'IOS_RELEASE_NATIVE_WRAPPER_SHA256=%s\n' "${cmc_ios_release_native_sha}"
if [[ "${cmc_ios_release_entitlement_source}" == ABSENT ]]; then
  printf 'IOS_PUSH_ACTIVATION_BLOCKED: REVIEWED_ENTITLEMENT_AND_APNS_REQUIRED\n'
  printf 'IOS_UNIVERSAL_LINKS_ACTIVATION_BLOCKED: OWNED_DOMAIN_AND_ASSOCIATION_FILE_REQUIRED\n'
fi
printf 'IOS_MAPS_ACTIVATION_BLOCKED: RESTRICTED_KEY_BILLING_AND_OWNER_SWITCH_REQUIRED\n'
