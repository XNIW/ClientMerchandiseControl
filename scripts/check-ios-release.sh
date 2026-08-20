#!/usr/bin/env bash
set -euo pipefail

cmc_ios_release_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_ios_release_root="$(git -C "${cmc_ios_release_script_dir}" rev-parse --show-toplevel)"
cmc_ios_release_app=''
cmc_ios_release_archive=''
cmc_ios_release_reference_app=''
cmc_ios_release_reference_attestation=''
cmc_ios_release_source_only=false
cmc_ios_release_require_upload=false

cmc_ios_release_fail() {
  printf 'IOS_RELEASE_BLOCKED: %s\n' "$1" >&2
  exit 1
}

cmc_ios_release_usage() {
  printf '%s\n' \
    'Usage: scripts/check-ios-release.sh --source-only' \
    '   or: scripts/check-ios-release.sh --app <Runner.app> [--archive <Runner.xcarchive>] [--reference-app <Runner.app> --reference-attestation <sha256-list>] [--require-upload-ready]'
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
    --reference-app)
      shift
      [[ "$#" -gt 0 ]] || cmc_ios_release_fail 'REFERENCE_APP_PATH_MISSING'
      cmc_ios_release_reference_app="$1"
      ;;
    --reference-attestation)
      shift
      [[ "$#" -gt 0 ]] || \
        cmc_ios_release_fail 'REFERENCE_ATTESTATION_MISSING'
      cmc_ios_release_reference_attestation="$1"
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
cmc_ios_release_uuid_normalizer="${cmc_ios_release_root}/scripts/normalize-ios-macho-uuid.pl"

for cmc_ios_release_file in \
  "${cmc_ios_release_info}" \
  "${cmc_ios_release_privacy}" \
  "${cmc_ios_release_xcode}" \
  "${cmc_ios_release_scheme}" \
  "${cmc_ios_release_config}" \
  "${cmc_ios_release_xcconfig}" \
  "${cmc_ios_release_security}" \
  "${cmc_ios_release_uuid_normalizer}"; do
  [[ -r "${cmc_ios_release_file}" ]] || \
    cmc_ios_release_fail 'RELEASE_SOURCE_MISSING'
done

for cmc_ios_release_command in \
  codesign dart dwarfdump file find lipo openssl otool perl plutil python3 shasum xcrun; do
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
    -n "${cmc_ios_release_reference_app}" || \
    -n "${cmc_ios_release_reference_attestation}" || \
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

if [[ -n "${cmc_ios_release_reference_app}" || \
  -n "${cmc_ios_release_reference_attestation}" ]]; then
  [[ -n "${cmc_ios_release_reference_app}" && \
    -n "${cmc_ios_release_reference_attestation}" ]] || \
    cmc_ios_release_fail 'REFERENCE_ATTESTATION_ARGUMENT_CONFLICT'
  [[ "${cmc_ios_release_reference_attestation}" =~ \
    ^[0-9a-f]{64}(,[0-9a-f]{64}){3}$ ]] || \
    cmc_ios_release_fail 'REFERENCE_ATTESTATION_INVALID'
  IFS=',' read -r -a cmc_ios_release_reference_digests \
    <<<"${cmc_ios_release_reference_attestation}"
  [[ "${#cmc_ios_release_reference_digests[@]}" -eq 4 ]] || \
    cmc_ios_release_fail 'REFERENCE_ATTESTATION_INVALID'
  for cmc_ios_release_reference_expected_digest in \
    "${cmc_ios_release_reference_digests[@]}"; do
    [[ "${cmc_ios_release_reference_expected_digest}" =~ \
      ^[0-9a-f]{64}$ ]] || \
      cmc_ios_release_fail 'REFERENCE_ATTESTATION_INVALID'
  done
fi

if [[ -n "${cmc_ios_release_reference_app}" ]]; then
  [[ -d "${cmc_ios_release_reference_app}" && \
    ! -L "${cmc_ios_release_reference_app}" ]] || \
    cmc_ios_release_fail 'REFERENCE_APP_NOT_READABLE'
  case "${cmc_ios_release_reference_app}" in
    *.app) ;;
    *) cmc_ios_release_fail 'REFERENCE_APP_EXTENSION_INVALID' ;;
  esac
  cmc_ios_release_reference_app_canonical="$(
    cd -- "${cmc_ios_release_reference_app}" && pwd -P
  )"
  cmc_ios_release_expected_reference_app="${cmc_ios_release_root}/build/ios/iphoneos/Runner.app"
  [[ -d "${cmc_ios_release_expected_reference_app}" ]] || \
    cmc_ios_release_fail 'REFERENCE_APP_NOT_READABLE'
  cmc_ios_release_expected_reference_app="$(
    cd -- "${cmc_ios_release_expected_reference_app}" && pwd -P
  )"
  cmc_ios_release_app_canonical="$(cd -- "${cmc_ios_release_app}" && pwd -P)"
  [[ "${cmc_ios_release_reference_app_canonical}" == \
      "${cmc_ios_release_expected_reference_app}" && \
    "${cmc_ios_release_reference_app_canonical}" != \
      "${cmc_ios_release_app_canonical}" ]] || \
    cmc_ios_release_fail 'REFERENCE_APP_PATH_INVALID'
fi

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
cmc_ios_release_expected_frameworks=(
  'Frameworks/App.framework'
  'Frameworks/Flutter.framework'
  'Frameworks/objective_c.framework'
  'Frameworks/sqlite3.framework'
)
cmc_ios_release_expected_framework_executables=(
  'App'
  'Flutter'
  'objective_c'
  'sqlite3'
)
cmc_ios_release_expected_framework_identifiers=(
  'io.flutter.flutter.app'
  'io.flutter.flutter'
  'io.flutter.flutter.native-assets.objective-c'
  'io.flutter.flutter.native-assets.sqlite3'
)
cmc_ios_release_expected_framework_install_names=(
  '@rpath/App.framework/App'
  '@rpath/Flutter.framework/Flutter'
  '@rpath/objective_c.framework/objective_c'
  '@rpath/sqlite3.framework/sqlite3'
)
cmc_ios_release_expected_framework_symbols=(
  ''
  ''
  '_DOBJC_initializeApi'
  '_sqlite3_open'
)
cmc_ios_release_expected_macho_paths=(
  'Runner'
  'Frameworks/App.framework/App'
  'Frameworks/Flutter.framework/Flutter'
  'Frameworks/objective_c.framework/objective_c'
  'Frameworks/sqlite3.framework/sqlite3'
)
# Digest dell'intero Mach-O canonicalizzato: la copia viene firmata ad hoc e la
# firma rimossa, così header, load command, sezioni e __LINKEDIT restano legati.
# Runner normalizza LC_UUID, che Xcode rigenera tra build equivalenti; la
# relazione UUID Runner/dSYM resta verificata separatamente dall'archive.
# Xcode 26.6 può inoltre scegliere uno dei due slot GOT equivalenti per
# `_objc_msgSend`: entrambi gli artifact completi verificati restano ammessi
# come exact digest, senza escludere dal digest alcuna sezione eseguibile.
# Anche objective_c normalizza il solo LC_UUID: il native asset conserva
# sezioni identiche ma rigenera quel metadato fra clean build equivalenti.
cmc_ios_release_expected_macho_digests=(
  'dea7dc176e6ddd65afd5be5ba8946171bd71b4ad59e96c5c25ce93e368aa0c40 9ddf9cea0d563fa7e8c86b2768f7e291f932958787c4b48dd5c73b2bf2129702'
  '847be0c00445269c63b4c1b3c475da7164a2257dad6bb0ffb99888af7c61dde7'
  'd1756c1031e3a0661f80dee4f6341b7c678021e571bf7026e1e1a1d61dac6868'
  # objective_c conserva l'exact-content completo dopo la sola
  # canonicalizzazione dell'LC_UUID nondeterministico.
  'aff4fc764ce7a78c4bec19dd499741967e17cdb7c008986facde88f37ce333c7'
  'e4f81ee4a9dc0cbdbc7ce78b8a7f0a76b4412ef6d53b6750656f0a123bdfb52b'
)
cmc_ios_release_expected_bundles=(
  'GoogleMapsResources.bundle'
  'GoogleMapsResources.bundle/GoogleMaps.bundle'
  'GoogleMapsResources.bundle/GoogleMaps.bundle/GMSCoreResources.bundle'
  'app_links_app_links.bundle'
  'flutter_secure_storage_darwin_flutter_secure_storage_darwin.bundle'
  'google_maps_flutter_ios_privacy.bundle'
  'share_plus_share_plus.bundle'
  'shared_preferences_foundation_shared_preferences_foundation.bundle'
  'url_launcher_ios_url_launcher_ios.bundle'
)
cmc_ios_release_expected_bundle_identifiers=(
  'org.cocoapods.GoogleMapsResources'
  'com.google.GoogleMaps'
  'com.google.Maps.GMSCoreResources'
  'app-links-7.2.1.app-links.resources'
  'flutter-secure-storage-darwin-0.3.2.flutter-secure-storage-darwin.resources'
  'org.cocoapods.google-maps-flutter-ios-privacy'
  'share-plus-13.2.1.share-plus.resources'
  'shared-preferences-foundation-2.5.6.shared-preferences-foundation.resources'
  'url-launcher-ios-6.4.1.url-launcher-ios.resources'
)
cmc_ios_release_expected_bundle_digests=(
  '25b5d8f6ca51382499bd3a7514ac40d46d7dca4e5d7cf8199d3047e14cc7c1e7'
  'c68287a3eef73d8803e899188399338b3b9ca25e9cb5f058e7e1fe69917520c7'
  '9690a463594a7339456e1b947b5b5127d528725045a654984d770c6d0b1de593'
  '3c21eed078875cd2e08e9e21e74625a5d8186b4a3a4dac52e755ccbf3318dff6'
  '977af56dd55f489cde8a515811a87f231a41841d85c5bed6b0a1856c12a00592'
  '5925a2133ba8501fb2bd9202615b9f0d3d4ed4820bb9c45c86bef0642f4bb244'
  '126170f9e2bd63a6feb1872a44b34b3b3ef2d8aa76e40bb6f826ebbe66fd7152'
  '3748616f9170148c93cec63927f9afd8d206255993c42712ba31f6a60426f6dc'
  'fd0c7e7cc49944829772e38e1cccc8e658ac00955e0c64190f9c3b64dfa6075f'
)

cmc_ios_release_require_exact_component_set() {
  local cmc_ios_release_component_root="$1"
  local cmc_ios_release_component_pattern="$2"
  local cmc_ios_release_component_error="$3"
  shift 3
  local cmc_ios_release_expected_components=("$@")
  local cmc_ios_release_component
  local cmc_ios_release_component_count=0

  while IFS= read -r -d '' cmc_ios_release_component; do
    cmc_ios_release_component_count=$((cmc_ios_release_component_count + 1))
  done < <(find "${cmc_ios_release_component_root}" \
    -mindepth 1 -iname "${cmc_ios_release_component_pattern}" \
    -print0)
  [[ "${cmc_ios_release_component_count}" -eq \
    "${#cmc_ios_release_expected_components[@]}" ]] || \
    cmc_ios_release_fail "${cmc_ios_release_component_error}"
  for cmc_ios_release_component in \
    "${cmc_ios_release_expected_components[@]}"; do
    [[ -d "${cmc_ios_release_component_root}/${cmc_ios_release_component}" && \
      ! -L "${cmc_ios_release_component_root}/${cmc_ios_release_component}" ]] || \
      cmc_ios_release_fail "${cmc_ios_release_component_error}"
  done
}

cmc_ios_release_macho_canonical_digest() {
  local cmc_ios_release_macho="$1"
  local cmc_ios_release_macho_label="$2"
  local cmc_ios_release_normalize_uuid="${3:-false}"
  local cmc_ios_release_macho_copy="${cmc_ios_release_tmp_root}/macho-${cmc_ios_release_macho_label}"

  cp "${cmc_ios_release_macho}" "${cmc_ios_release_macho_copy}" || return 1
  chmod u+w "${cmc_ios_release_macho_copy}" || return 1
  codesign --remove-signature "${cmc_ios_release_macho_copy}" \
    >/dev/null 2>&1 || true
  codesign --force --sign - "${cmc_ios_release_macho_copy}" \
    >/dev/null 2>&1 || return 1
  codesign --remove-signature "${cmc_ios_release_macho_copy}" \
    >/dev/null 2>&1 || return 1
  if [[ "${cmc_ios_release_normalize_uuid}" == true ]]; then
    perl "${cmc_ios_release_uuid_normalizer}" \
      "${cmc_ios_release_macho_copy}" || return 1
  fi
  shasum -a 256 "${cmc_ios_release_macho_copy}" | awk '{print $1}'
}

cmc_ios_release_bundle_tree_digest() {
  local cmc_ios_release_tree_root="$1"
  local cmc_ios_release_tree_file
  local cmc_ios_release_tree_file_digest
  local cmc_ios_release_tree_relative

  find "${cmc_ios_release_tree_root}" -type f \
    ! -path '*/_CodeSignature/*' -print0 | LC_ALL=C sort -z | \
    while IFS= read -r -d '' cmc_ios_release_tree_file; do
      cmc_ios_release_tree_relative="${cmc_ios_release_tree_file#"${cmc_ios_release_tree_root}"/}"
      if [[ "${cmc_ios_release_tree_relative##*/}" == 'Info.plist' ]]; then
        # Xcode inserisce il build number del macOS host nei resource bundle.
        # Quel solo campo varia fra macchine a parita' di toolchain e input;
        # ogni altra chiave plist e ogni altra risorsa restano nel digest.
        cmc_ios_release_tree_file_digest="$(
          plutil -convert json -o - "${cmc_ios_release_tree_file}" 2>/dev/null | \
            perl -MJSON::PP -e '
              use strict;
              use warnings;
              local $/;
              my $decoded = eval { JSON::PP->new->utf8->decode(<STDIN>) };
              exit 1 if $@ || ref($decoded) ne "HASH";
              delete $decoded->{BuildMachineOSBuild};
              print JSON::PP->new->canonical->encode($decoded);
            ' | shasum -a 256 | awk '{print $1}'
        )" || return 1
      else
        cmc_ios_release_tree_file_digest="$(
          shasum -a 256 "${cmc_ios_release_tree_file}" | awk '{print $1}'
        )" || return 1
      fi
      [[ "${cmc_ios_release_tree_file_digest}" =~ ^[0-9a-f]{64}$ ]] || \
        return 1
      printf '%s\0' "${cmc_ios_release_tree_relative}"
      printf '%s\0' "${cmc_ios_release_tree_file_digest}"
    done | shasum -a 256 | awk '{print $1}'
}

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

cmc_ios_release_require_exact_component_set \
  "${cmc_ios_release_app}" '*.framework' \
  'EMBEDDED_FRAMEWORK_SET_INVALID' \
  "${cmc_ios_release_expected_frameworks[@]}"
cmc_ios_release_require_exact_component_set \
  "${cmc_ios_release_app}" '*.bundle' \
  'EMBEDDED_BUNDLE_SET_INVALID' \
  "${cmc_ios_release_expected_bundles[@]}"
[[ "$(find "${cmc_ios_release_app}" -iname '*.dylib' -print | \
  wc -l | tr -d '[:space:]')" -eq 0 ]] || \
  cmc_ios_release_fail 'EMBEDDED_DYLIB_SET_INVALID'
[[ "$(find "${cmc_ios_release_app}/Frameworks" -mindepth 1 -maxdepth 1 \
  -print | wc -l | tr -d '[:space:]')" -eq \
  "${#cmc_ios_release_expected_frameworks[@]}" ]] || \
  cmc_ios_release_fail 'EMBEDDED_FRAMEWORK_SET_INVALID'
if find "${cmc_ios_release_app}" -type l -print -quit | grep -q .; then
  cmc_ios_release_fail 'ARTIFACT_SYMLINK_SET_INVALID'
fi
if [[ -n "${cmc_ios_release_reference_app}" ]]; then
  cmc_ios_release_require_exact_component_set \
    "${cmc_ios_release_reference_app}" '*.framework' \
    'REFERENCE_FRAMEWORK_SET_INVALID' \
    "${cmc_ios_release_expected_frameworks[@]}"
  [[ "$(find "${cmc_ios_release_reference_app}" -iname '*.dylib' -print | \
    wc -l | tr -d '[:space:]')" -eq 0 ]] || \
    cmc_ios_release_fail 'REFERENCE_DYLIB_SET_INVALID'
  if find "${cmc_ios_release_reference_app}" -type l -print -quit | grep -q .; then
    cmc_ios_release_fail 'REFERENCE_SYMLINK_SET_INVALID'
  fi
fi

cmc_ios_release_macho_count=0
while IFS= read -r -d '' cmc_ios_release_candidate; do
  if file "${cmc_ios_release_candidate}" | grep -Fq 'Mach-O'; then
    cmc_ios_release_candidate_relative="${cmc_ios_release_candidate#"${cmc_ios_release_app}"/}"
    cmc_ios_release_macho_expected=false
    for cmc_ios_release_expected_macho in \
      "${cmc_ios_release_expected_macho_paths[@]}"; do
      if [[ "${cmc_ios_release_candidate_relative}" == \
        "${cmc_ios_release_expected_macho}" ]]; then
        cmc_ios_release_macho_expected=true
        break
      fi
    done
    [[ "${cmc_ios_release_macho_expected}" == true ]] || \
      cmc_ios_release_fail 'EMBEDDED_MACHO_SET_INVALID'
    cmc_ios_release_macho_count=$((cmc_ios_release_macho_count + 1))
  fi
done < <(find "${cmc_ios_release_app}" -type f -print0)
[[ "${cmc_ios_release_macho_count}" -eq \
  "${#cmc_ios_release_expected_macho_paths[@]}" ]] || \
  cmc_ios_release_fail 'EMBEDDED_MACHO_SET_INVALID'
for cmc_ios_release_macho_index in \
  "${!cmc_ios_release_expected_macho_paths[@]}"; do
  cmc_ios_release_macho_file="${cmc_ios_release_app}/${cmc_ios_release_expected_macho_paths[cmc_ios_release_macho_index]}"
  [[ -f "${cmc_ios_release_macho_file}" && \
    ! -L "${cmc_ios_release_macho_file}" ]] || \
    cmc_ios_release_fail 'EMBEDDED_MACHO_SET_INVALID'
  if [[ "${cmc_ios_release_macho_index}" -gt 0 ]]; then
    [[ "$(lipo -archs "${cmc_ios_release_macho_file}" 2>/dev/null)" == \
      'arm64' ]] || cmc_ios_release_fail 'FRAMEWORK_ARCHITECTURE_INVALID'
  fi
  cmc_ios_release_normalize_uuid=false
  if [[ "${cmc_ios_release_macho_index}" -eq 0 || \
    "${cmc_ios_release_macho_index}" -eq 3 ]]; then
    cmc_ios_release_normalize_uuid=true
  fi
  cmc_ios_release_macho_digest="$(
    cmc_ios_release_macho_canonical_digest \
      "${cmc_ios_release_macho_file}" "${cmc_ios_release_macho_index}" \
      "${cmc_ios_release_normalize_uuid}"
  )" || cmc_ios_release_fail 'EMBEDDED_COMPONENT_DIGEST_UNREADABLE'
  if [[ -n "${cmc_ios_release_reference_app}" ]]; then
    cmc_ios_release_reference_macho="${cmc_ios_release_reference_app}/${cmc_ios_release_expected_macho_paths[cmc_ios_release_macho_index]}"
    [[ -f "${cmc_ios_release_reference_macho}" && \
      ! -L "${cmc_ios_release_reference_macho}" ]] || \
      cmc_ios_release_fail 'REFERENCE_MACHO_SET_INVALID'
    file "${cmc_ios_release_reference_macho}" | grep -Fq 'Mach-O' || \
      cmc_ios_release_fail 'REFERENCE_MACHO_SET_INVALID'
    if [[ "${cmc_ios_release_macho_index}" -ne 0 ]]; then
      cmc_ios_release_reference_digest="$(
        cmc_ios_release_macho_canonical_digest \
          "${cmc_ios_release_reference_macho}" \
          "reference-${cmc_ios_release_macho_index}" \
          "${cmc_ios_release_normalize_uuid}"
      )" || cmc_ios_release_fail 'REFERENCE_COMPONENT_DIGEST_UNREADABLE'
      cmc_ios_release_reference_expected_digest="${cmc_ios_release_reference_digests[cmc_ios_release_macho_index - 1]}"
      [[ "${cmc_ios_release_reference_digest}" == \
        "${cmc_ios_release_reference_expected_digest}" ]] || \
        cmc_ios_release_fail 'REFERENCE_ATTESTATION_MISMATCH'
      [[ "${cmc_ios_release_macho_digest}" == \
        "${cmc_ios_release_reference_expected_digest}" ]] || \
        cmc_ios_release_fail 'EMBEDDED_COMPONENT_DIGEST_MISMATCH'
    else
      [[ " ${cmc_ios_release_expected_macho_digests[0]} " == \
        *" ${cmc_ios_release_macho_digest} "* ]] || \
        cmc_ios_release_fail 'EMBEDDED_COMPONENT_DIGEST_MISMATCH'
    fi
  else
    [[ " ${cmc_ios_release_expected_macho_digests[cmc_ios_release_macho_index]} " == \
      *" ${cmc_ios_release_macho_digest} "* ]] || \
      cmc_ios_release_fail 'EMBEDDED_COMPONENT_DIGEST_MISMATCH'
  fi
done

for cmc_ios_release_framework_index in \
  "${!cmc_ios_release_expected_frameworks[@]}"; do
  cmc_ios_release_framework_relative="${cmc_ios_release_expected_frameworks[cmc_ios_release_framework_index]}"
  cmc_ios_release_framework="${cmc_ios_release_app}/${cmc_ios_release_framework_relative}"
  cmc_ios_release_framework_info="${cmc_ios_release_framework}/Info.plist"
  [[ -r "${cmc_ios_release_framework_info}" ]] || \
    cmc_ios_release_fail 'FRAMEWORK_INFO_MISSING'
  cmc_ios_release_framework_executable_name="$(
    /usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' \
      "${cmc_ios_release_framework_info}" 2>/dev/null || true
  )"
  [[ "${cmc_ios_release_framework_executable_name}" == \
    "${cmc_ios_release_expected_framework_executables[cmc_ios_release_framework_index]}" ]] || \
    cmc_ios_release_fail 'FRAMEWORK_IDENTITY_INVALID'
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' \
    "${cmc_ios_release_framework_info}" 2>/dev/null || true)" == \
    "${cmc_ios_release_expected_framework_identifiers[cmc_ios_release_framework_index]}" ]] || \
    cmc_ios_release_fail 'FRAMEWORK_IDENTITY_INVALID'
  cmc_ios_release_framework_executable="${cmc_ios_release_framework}/${cmc_ios_release_framework_executable_name}"
  [[ -n "${cmc_ios_release_framework_executable_name}" && \
    -r "${cmc_ios_release_framework_executable}" ]] || \
    cmc_ios_release_fail 'FRAMEWORK_EXECUTABLE_MISSING'
  file "${cmc_ios_release_framework_executable}" | grep -Fq 'Mach-O' || \
    cmc_ios_release_fail 'FRAMEWORK_EXECUTABLE_NOT_MACHO'
  [[ "$(lipo -archs "${cmc_ios_release_framework_executable}" 2>/dev/null)" == \
    'arm64' ]] || \
    cmc_ios_release_fail 'FRAMEWORK_ARCHITECTURE_INVALID'
  cmc_ios_release_framework_install_name="$(
    otool -D "${cmc_ios_release_framework_executable}" 2>/dev/null | tail -n 1 | \
      tr -d '[:space:]'
  )"
  [[ "${cmc_ios_release_framework_install_name}" == \
    "${cmc_ios_release_expected_framework_install_names[cmc_ios_release_framework_index]}" ]] || \
    cmc_ios_release_fail 'FRAMEWORK_IDENTITY_INVALID'
  cmc_ios_release_framework_symbol="${cmc_ios_release_expected_framework_symbols[cmc_ios_release_framework_index]}"
  if [[ -n "${cmc_ios_release_framework_symbol}" ]]; then
    nm -gU "${cmc_ios_release_framework_executable}" 2>/dev/null | \
      awk '{print $NF}' | grep -Fxq "${cmc_ios_release_framework_symbol}" || \
      cmc_ios_release_fail 'FRAMEWORK_IDENTITY_INVALID'
  fi
done
for cmc_ios_release_bundle_index in \
  "${!cmc_ios_release_expected_bundles[@]}"; do
  cmc_ios_release_bundle="${cmc_ios_release_app}/${cmc_ios_release_expected_bundles[cmc_ios_release_bundle_index]}"
  cmc_ios_release_bundle_info="${cmc_ios_release_bundle}/Info.plist"
  [[ -r "${cmc_ios_release_bundle_info}" ]] || \
    cmc_ios_release_fail 'BUNDLE_IDENTITY_INVALID'
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' \
    "${cmc_ios_release_bundle_info}" 2>/dev/null || true)" == \
    "${cmc_ios_release_expected_bundle_identifiers[cmc_ios_release_bundle_index]}" ]] || \
    cmc_ios_release_fail 'BUNDLE_IDENTITY_INVALID'
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundlePackageType' \
    "${cmc_ios_release_bundle_info}" 2>/dev/null || true)" == 'BNDL' ]] || \
    cmc_ios_release_fail 'BUNDLE_IDENTITY_INVALID'
  cmc_ios_release_bundle_digest="$(
    cmc_ios_release_bundle_tree_digest "${cmc_ios_release_bundle}"
  )" || cmc_ios_release_fail 'EMBEDDED_BUNDLE_DIGEST_UNREADABLE'
  [[ "${cmc_ios_release_bundle_digest}" == \
    "${cmc_ios_release_expected_bundle_digests[cmc_ios_release_bundle_index]}" ]] || \
    cmc_ios_release_fail 'EMBEDDED_BUNDLE_DIGEST_MISMATCH'
done
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
