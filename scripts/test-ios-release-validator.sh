#!/usr/bin/env bash
set -euo pipefail

cmc_ios_test_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_ios_test_root="$(git -C "${cmc_ios_test_script_dir}" rev-parse --show-toplevel)"
cmc_ios_test_validator="${cmc_ios_test_root}/scripts/check-ios-release.sh"
cmc_ios_test_archive=''

if [[ "${1:-}" == '--archive' && -n "${2:-}" && "$#" -eq 2 ]]; then
  cmc_ios_test_archive="$2"
else
  printf 'Usage: scripts/test-ios-release-validator.sh --archive <Runner.xcarchive>\n' >&2
  exit 1
fi

cmc_ios_test_source_app="${cmc_ios_test_archive}/Products/Applications/Runner.app"
cmc_ios_test_source_info="${cmc_ios_test_archive}/Info.plist"
cmc_ios_test_source_dsym="${cmc_ios_test_archive}/dSYMs/Runner.app.dSYM/Contents/Resources/DWARF/Runner"
[[ -d "${cmc_ios_test_source_app}" && -f "${cmc_ios_test_source_info}" && \
  -f "${cmc_ios_test_source_dsym}" ]] || {
  printf 'Fixture archive iOS non leggibile.\n' >&2
  exit 1
}

cmc_ios_test_tmp_parent="${TMPDIR:-/tmp}"
cmc_ios_test_tmp_parent="${cmc_ios_test_tmp_parent%/}"
cmc_ios_test_tmp_root="$(mktemp -d "${cmc_ios_test_tmp_parent}/cmc-ios-validator.XXXXXX")"
cmc_ios_test_cleanup() {
  case "${cmc_ios_test_tmp_root}" in
    "${cmc_ios_test_tmp_parent}"/cmc-ios-validator.*)
      rm -rf -- "${cmc_ios_test_tmp_root}"
      ;;
    *)
      printf 'Cleanup fixture iOS rifiutato.\n' >&2
      ;;
  esac
}
trap cmc_ios_test_cleanup EXIT

cmc_ios_test_fixture_archive="${cmc_ios_test_tmp_root}/Runner.xcarchive"
cmc_ios_test_fixture_app="${cmc_ios_test_fixture_archive}/Products/Applications/Runner.app"
cmc_ios_test_fixture_dsym="${cmc_ios_test_fixture_archive}/dSYMs/Runner.app.dSYM/Contents/Resources/DWARF"
mkdir -p "$(dirname -- "${cmc_ios_test_fixture_app}")" "${cmc_ios_test_fixture_dsym}"
cp -R "${cmc_ios_test_source_app}" "${cmc_ios_test_fixture_app}"
cp "${cmc_ios_test_source_info}" "${cmc_ios_test_fixture_archive}/Info.plist"
cp "${cmc_ios_test_source_dsym}" "${cmc_ios_test_fixture_dsym}/Runner"

cmc_ios_test_total=0
cmc_ios_test_passed=0

cmc_ios_test_expect_failure() {
  local cmc_ios_test_name="$1"
  local cmc_ios_test_expected="$2"
  shift 2
  local cmc_ios_test_log="${cmc_ios_test_tmp_root}/${cmc_ios_test_name}.log"
  cmc_ios_test_total=$((cmc_ios_test_total + 1))

  if "$@" >"${cmc_ios_test_log}" 2>&1; then
    printf 'Fixture iOS %s doveva fallire.\n' "${cmc_ios_test_name}" >&2
    exit 1
  fi
  grep -Fq -- "IOS_RELEASE_BLOCKED: ${cmc_ios_test_expected}" \
    "${cmc_ios_test_log}" || {
    printf 'Fixture iOS %s fallita per ragione inattesa.\n' \
      "${cmc_ios_test_name}" >&2
    grep -E '^IOS_RELEASE_BLOCKED: [A-Z0-9_]+$' \
      "${cmc_ios_test_log}" >&2 || true
    exit 1
  }
  cmc_ios_test_passed=$((cmc_ios_test_passed + 1))
}

cmc_ios_test_baseline_output="$(bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}")"
cmc_ios_test_expected_runtime_sha="$(
  shasum -a 256 \
    "${cmc_ios_test_fixture_app}/Frameworks/App.framework/App" | awk '{print $1}'
)"
cmc_ios_test_expected_native_sha="$(
  shasum -a 256 "${cmc_ios_test_fixture_app}/Runner" | awk '{print $1}'
)"
grep -Fxq \
  "IOS_RELEASE_EXECUTABLE_SHA256=${cmc_ios_test_expected_runtime_sha}" \
  <<<"${cmc_ios_test_baseline_output}" || {
  printf 'Fixture iOS: hash runtime non legato ad App.framework/App.\n' >&2
  exit 1
}
grep -Fxq \
  "IOS_RELEASE_NATIVE_WRAPPER_SHA256=${cmc_ios_test_expected_native_sha}" \
  <<<"${cmc_ios_test_baseline_output}" || {
  printf 'Fixture iOS: hash wrapper nativo non verificabile.\n' >&2
  exit 1
}

cp "${cmc_ios_test_source_info}" \
  "${cmc_ios_test_tmp_root}/Archive-Info.plist.original"
/usr/libexec/PlistBuddy -c \
  'Set :ApplicationProperties:ApplicationPath Applications/Evil.app' \
  "${cmc_ios_test_fixture_archive}/Info.plist"
cmc_ios_test_expect_failure archive-application-path \
  ARCHIVE_APPLICATION_PATH_MISMATCH \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_tmp_root}/Archive-Info.plist.original" \
  "${cmc_ios_test_fixture_archive}/Info.plist"

cp -R "${cmc_ios_test_fixture_app}" \
  "${cmc_ios_test_fixture_archive}/Products/Applications/Extra.app"
cmc_ios_test_expect_failure archive-application-set \
  ARCHIVE_APPLICATION_SET_INVALID \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
rm -rf -- "${cmc_ios_test_fixture_archive}/Products/Applications/Extra.app"

ln -s "${cmc_ios_test_tmp_root}/external-extra.app" \
  "${cmc_ios_test_fixture_archive}/Products/Applications/Extra.app"
cmc_ios_test_expect_failure archive-application-symlink \
  ARCHIVE_APPLICATION_SET_INVALID \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
rm "${cmc_ios_test_fixture_archive}/Products/Applications/Extra.app"

cmc_ios_test_external_app="${cmc_ios_test_tmp_root}/External.app"
cp -R "${cmc_ios_test_fixture_app}" "${cmc_ios_test_external_app}"
cmc_ios_test_expect_failure archive-binding APP_ARCHIVE_BUNDLE_MISMATCH \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_external_app}" \
  --archive "${cmc_ios_test_fixture_archive}"

cmc_ios_test_app_info="${cmc_ios_test_fixture_app}/Info.plist"
cp "${cmc_ios_test_app_info}" "${cmc_ios_test_tmp_root}/Info.plist.original"
/usr/libexec/PlistBuddy -c \
  'Add :CFBundleURLTypes:0:CFBundleURLSchemes:1 string com.xniw.clientmerchandisecontrol.dev' \
  "${cmc_ios_test_app_info}"
cmc_ios_test_expect_failure extra-url-scheme DEEPLINK_SCHEME_SET_INVALID \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_tmp_root}/Info.plist.original" "${cmc_ios_test_app_info}"

/usr/libexec/PlistBuddy -c \
  'Set :CFBundleExecutable ../../outside-runner' "${cmc_ios_test_app_info}"
cmc_ios_test_expect_failure executable-traversal APP_EXECUTABLE_NAME_INVALID \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_tmp_root}/Info.plist.original" "${cmc_ios_test_app_info}"

cmc_ios_test_required_privacy="${cmc_ios_test_fixture_app}/app_links_app_links.bundle/PrivacyInfo.xcprivacy"
mv "${cmc_ios_test_required_privacy}" \
  "${cmc_ios_test_tmp_root}/app-links.PrivacyInfo.xcprivacy"
mkdir -p "${cmc_ios_test_fixture_app}/privacy-decoy.bundle"
cp "${cmc_ios_test_fixture_app}/PrivacyInfo.xcprivacy" \
  "${cmc_ios_test_fixture_app}/privacy-decoy.bundle/PrivacyInfo.xcprivacy"
cmc_ios_test_expect_failure privacy-decoy DEPENDENCY_PRIVACY_MANIFEST_MISSING \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
mv "${cmc_ios_test_tmp_root}/app-links.PrivacyInfo.xcprivacy" \
  "${cmc_ios_test_required_privacy}"
rm -rf -- "${cmc_ios_test_fixture_app}/privacy-decoy.bundle"

cp "${cmc_ios_test_required_privacy}" \
  "${cmc_ios_test_tmp_root}/app-links.valid.xcprivacy"
printf 'not a plist\n' >"${cmc_ios_test_required_privacy}"
cmc_ios_test_expect_failure privacy-malformed \
  DEPENDENCY_PRIVACY_MANIFEST_INVALID \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_tmp_root}/app-links.valid.xcprivacy" \
  "${cmc_ios_test_required_privacy}"

printf '<?xml version="1.0" encoding="UTF-8"?>\n' \
  '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
  '<plist version="1.0"><dict/></plist>\n' \
  >"${cmc_ios_test_required_privacy}"
cmc_ios_test_expect_failure privacy-empty-schema \
  DEPENDENCY_PRIVACY_MANIFEST_INVALID \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_tmp_root}/app-links.valid.xcprivacy" \
  "${cmc_ios_test_required_privacy}"

plutil -replace NSPrivacyAccessedAPITypes -json '[{}]' \
  "${cmc_ios_test_required_privacy}"
plutil -replace NSPrivacyCollectedDataTypes -json '[{}]' \
  "${cmc_ios_test_required_privacy}"
cmc_ios_test_expect_failure privacy-incomplete-nested-schema \
  DEPENDENCY_PRIVACY_MANIFEST_INVALID \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_tmp_root}/app-links.valid.xcprivacy" \
  "${cmc_ios_test_required_privacy}"

plutil -replace NSPrivacyAccessedAPITypes -json \
  '[{"NSPrivacyAccessedAPIType":"NSPrivacyAccessedAPICategoryTotallyFake","NSPrivacyAccessedAPITypeReasons":["ZZZZ.999"]}]' \
  "${cmc_ios_test_required_privacy}"
plutil -replace NSPrivacyCollectedDataTypes -json \
  '[{"NSPrivacyCollectedDataType":"NSPrivacyCollectedDataTypeTotallyFake","NSPrivacyCollectedDataTypeLinked":false,"NSPrivacyCollectedDataTypePurposes":["NSPrivacyCollectedDataTypePurposeTotallyFake"],"NSPrivacyCollectedDataTypeTracking":false}]' \
  "${cmc_ios_test_required_privacy}"
cmc_ios_test_expect_failure privacy-unknown-enums \
  DEPENDENCY_PRIVACY_MANIFEST_INVALID \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_tmp_root}/app-links.valid.xcprivacy" \
  "${cmc_ios_test_required_privacy}"

plutil -replace NSPrivacyAccessedAPITypes -json \
  '[{"NSPrivacyAccessedAPIType":"NSPrivacyAccessedAPICategoryUserDefaults","NSPrivacyAccessedAPITypeReasons":["85F4.1"]}]' \
  "${cmc_ios_test_required_privacy}"
cmc_ios_test_expect_failure privacy-reason-category-mismatch \
  DEPENDENCY_PRIVACY_MANIFEST_INVALID \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_tmp_root}/app-links.valid.xcprivacy" \
  "${cmc_ios_test_required_privacy}"

cmc_ios_test_entitlements="${cmc_ios_test_tmp_root}/entitlements.plist"
cp "${cmc_ios_test_root}/ios/Runner/PrivacyInfo.xcprivacy" \
  "${cmc_ios_test_entitlements}"
/usr/libexec/PlistBuddy -c 'Delete :NSPrivacyTracking' \
  "${cmc_ios_test_entitlements}"
/usr/libexec/PlistBuddy -c 'Delete :NSPrivacyTrackingDomains' \
  "${cmc_ios_test_entitlements}"
/usr/libexec/PlistBuddy -c 'Delete :NSPrivacyCollectedDataTypes' \
  "${cmc_ios_test_entitlements}"
/usr/libexec/PlistBuddy -c 'Delete :NSPrivacyAccessedAPITypes' \
  "${cmc_ios_test_entitlements}"
/usr/libexec/PlistBuddy -c 'Add :get-task-allow bool false' \
  "${cmc_ios_test_entitlements}"
codesign --force --deep --sign - --entitlements "${cmc_ios_test_entitlements}" \
  "${cmc_ios_test_fixture_app}" >/dev/null 2>&1
bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}" >/dev/null
cmc_ios_test_profile_plist="${cmc_ios_test_tmp_root}/profile.plist"
cp "${cmc_ios_test_entitlements}" "${cmc_ios_test_profile_plist}"
/usr/libexec/PlistBuddy -c 'Add :TeamIdentifier array' \
  "${cmc_ios_test_profile_plist}"
/usr/libexec/PlistBuddy -c 'Add :TeamIdentifier:0 string FIXTURE123' \
  "${cmc_ios_test_profile_plist}"
/usr/libexec/PlistBuddy -c 'Add :Entitlements dict' \
  "${cmc_ios_test_profile_plist}"
/usr/libexec/PlistBuddy -c 'Add :Entitlements:get-task-allow bool false' \
  "${cmc_ios_test_profile_plist}"
openssl req -x509 -newkey rsa:2048 -nodes \
  -subj '/CN=CMC iOS validator fixture' \
  -keyout "${cmc_ios_test_tmp_root}/profile.key" \
  -out "${cmc_ios_test_tmp_root}/profile.crt" \
  -days 1 >/dev/null 2>&1
openssl cms -sign -binary -nodetach \
  -in "${cmc_ios_test_profile_plist}" \
  -signer "${cmc_ios_test_tmp_root}/profile.crt" \
  -inkey "${cmc_ios_test_tmp_root}/profile.key" \
  -outform DER \
  -out "${cmc_ios_test_fixture_app}/embedded.mobileprovision" \
  >/dev/null 2>&1
codesign --force --deep --sign - --entitlements "${cmc_ios_test_entitlements}" \
  "${cmc_ios_test_fixture_app}" >/dev/null 2>&1
bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}" >/dev/null
cmc_ios_test_secret="GOCSPX-$(printf 'A%.0s' {1..32})"
/usr/libexec/PlistBuddy -c \
  "Add :FixtureNote string ${cmc_ios_test_secret}" \
  "${cmc_ios_test_profile_plist}"
openssl cms -sign -binary -nodetach \
  -in "${cmc_ios_test_profile_plist}" \
  -signer "${cmc_ios_test_tmp_root}/profile.crt" \
  -inkey "${cmc_ios_test_tmp_root}/profile.key" \
  -outform DER \
  -out "${cmc_ios_test_fixture_app}/embedded.mobileprovision" \
  >/dev/null 2>&1
codesign --force --deep --sign - --entitlements "${cmc_ios_test_entitlements}" \
  "${cmc_ios_test_fixture_app}" >/dev/null 2>&1
cmc_ios_test_expect_failure decoded-profile-secret \
  PROVISIONING_PROFILE_SECURITY_SCAN_FAILED \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
rm "${cmc_ios_test_fixture_app}/embedded.mobileprovision"
codesign --force --deep --sign - --entitlements "${cmc_ios_test_entitlements}" \
  "${cmc_ios_test_fixture_app}" >/dev/null 2>&1
/usr/libexec/PlistBuddy -c 'Add :aps-environment string development' \
  "${cmc_ios_test_entitlements}"
codesign --force --deep --sign - --entitlements "${cmc_ios_test_entitlements}" \
  "${cmc_ios_test_fixture_app}" >/dev/null 2>&1
cmc_ios_test_expect_failure unexpected-entitlement SIGNED_ENTITLEMENT_SET_INVALID \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
/usr/libexec/PlistBuddy -c 'Delete :aps-environment' \
  "${cmc_ios_test_entitlements}"
codesign --force --deep --sign - --entitlements "${cmc_ios_test_entitlements}" \
  "${cmc_ios_test_fixture_app}" >/dev/null 2>&1
cmc_ios_test_signature_offset="$(
  otool -l "${cmc_ios_test_fixture_app}/Runner" | awk '
    $1 == "cmd" && $2 == "LC_CODE_SIGNATURE" { found = 1; next }
    found && $1 == "dataoff" { print $2; exit }
  '
)"
[[ "${cmc_ios_test_signature_offset}" =~ ^[0-9]+$ ]] || {
  printf 'Fixture signature offset non leggibile.\n' >&2
  exit 1
}
perl -e '
  use strict;
  use warnings;
  my ($path, $offset) = @ARGV;
  open my $handle, "+<", $path or die "open\n";
  binmode $handle;
  seek $handle, $offset, 0 or die "seek\n";
  read($handle, my $byte, 1) == 1 or die "read\n";
  seek $handle, $offset, 0 or die "seek\n";
  print {$handle} chr(ord($byte) ^ 0xff) or die "write\n";
  close $handle or die "close\n";
' "${cmc_ios_test_fixture_app}/Runner" "${cmc_ios_test_signature_offset}"
cmc_ios_test_expect_failure corrupt-signature-superblob ARTIFACT_SIGNATURE_INVALID \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp -R "${cmc_ios_test_source_app}/." "${cmc_ios_test_fixture_app}/"
codesign --force --deep --sign - --entitlements "${cmc_ios_test_entitlements}" \
  "${cmc_ios_test_fixture_app}" >/dev/null 2>&1
printf 'tamper after signing\n' >>"${cmc_ios_test_fixture_app}/Assets.car"
cmc_ios_test_expect_failure invalid-signature ARTIFACT_SIGNATURE_INVALID \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"

printf 'iOS release validator fixtures: %d/%d PASS.\n' \
  "${cmc_ios_test_passed}" "${cmc_ios_test_total}"
