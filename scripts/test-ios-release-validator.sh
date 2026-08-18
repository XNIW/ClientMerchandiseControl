#!/usr/bin/env bash
set -euo pipefail

cmc_ios_test_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_ios_test_root="$(git -C "${cmc_ios_test_script_dir}" rev-parse --show-toplevel)"
cmc_ios_test_validator="${cmc_ios_test_root}/scripts/check-ios-release.sh"
cmc_ios_test_attestor="${cmc_ios_test_root}/scripts/create-ios-reference-attestation.sh"
cmc_ios_test_archive=''
cmc_ios_test_reference_app=''
cmc_ios_test_reference_attestation=''

if [[ "${1:-}" == '--archive' && -n "${2:-}" && \
  "${3:-}" == '--reference-app' && -n "${4:-}" && \
  "${5:-}" == '--reference-attestation' && -n "${6:-}" && \
  "$#" -eq 6 ]]; then
  cmc_ios_test_archive="$2"
  cmc_ios_test_reference_app="$4"
  cmc_ios_test_reference_attestation="$6"
else
  printf 'Usage: scripts/test-ios-release-validator.sh --archive <Runner.xcarchive> --reference-app <Runner.app> --reference-attestation <sha256-list>\n' >&2
  exit 1
fi

cmc_ios_test_validate() {
  bash "${cmc_ios_test_validator}" "$@" \
    --reference-app "${cmc_ios_test_reference_app}" \
    --reference-attestation "${cmc_ios_test_reference_attestation}"
}

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
cmc_ios_test_reference_restore=''
cmc_ios_test_reference_backup=''
cmc_ios_test_cleanup() {
  if [[ -n "${cmc_ios_test_reference_restore}" && \
    -f "${cmc_ios_test_reference_backup}" ]]; then
    cp "${cmc_ios_test_reference_backup}" \
      "${cmc_ios_test_reference_restore}" || true
  fi
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

cmc_ios_test_expect_attestor_failure() {
  local cmc_ios_test_name="$1"
  local cmc_ios_test_expected="$2"
  shift 2
  local cmc_ios_test_log="${cmc_ios_test_tmp_root}/${cmc_ios_test_name}.log"
  cmc_ios_test_total=$((cmc_ios_test_total + 1))

  if "$@" >"${cmc_ios_test_log}" 2>&1; then
    printf 'Fixture attestor iOS %s doveva fallire.\n' \
      "${cmc_ios_test_name}" >&2
    exit 1
  fi
  grep -Fxq -- \
    "IOS_REFERENCE_ATTESTATION_BLOCKED: ${cmc_ios_test_expected}" \
    "${cmc_ios_test_log}" || {
    printf 'Fixture attestor iOS %s fallita per ragione inattesa.\n' \
      "${cmc_ios_test_name}" >&2
    grep -E '^IOS_REFERENCE_ATTESTATION_BLOCKED: [A-Z0-9_]+$' \
      "${cmc_ios_test_log}" >&2 || true
    exit 1
  }
  cmc_ios_test_passed=$((cmc_ios_test_passed + 1))
}

cmc_ios_test_flip_byte() {
  perl -e '
    use strict;
    use warnings;
    my ($path, $offset) = @ARGV;
    open my $handle, "+<", $path or die "open\n";
    binmode $handle;
    seek $handle, $offset, 0 or die "seek\n";
    read($handle, my $byte, 1) == 1 or die "read\n";
    seek $handle, $offset, 0 or die "seek\n";
    print {$handle} chr(ord($byte) ^ 0x01) or die "write\n";
    close $handle or die "close\n";
  ' "$1" "$2"
}

cmc_ios_test_baseline_output="$(cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}")"
cmc_ios_test_expect_failure reference-attestation-missing \
  REFERENCE_ATTESTATION_ARGUMENT_CONFLICT \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}" \
  --reference-app "${cmc_ios_test_reference_app}"
cmc_ios_test_expect_failure reference-attestation-malformed \
  REFERENCE_ATTESTATION_INVALID \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}" \
  --reference-app "${cmc_ios_test_reference_app}" \
  --reference-attestation 'invalid'
cmc_ios_test_expect_failure reference-attestation-trailing-delimiter \
  REFERENCE_ATTESTATION_INVALID \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}" \
  --reference-app "${cmc_ios_test_reference_app}" \
  --reference-attestation "${cmc_ios_test_reference_attestation},"
cmc_ios_test_expect_failure reference-attestation-newline \
  REFERENCE_ATTESTATION_INVALID \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}" \
  --reference-app "${cmc_ios_test_reference_app}" \
  --reference-attestation \
  "${cmc_ios_test_reference_attestation}"$'\n'"${cmc_ios_test_reference_attestation}"
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
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_tmp_root}/Archive-Info.plist.original" \
  "${cmc_ios_test_fixture_archive}/Info.plist"

cp -R "${cmc_ios_test_fixture_app}" \
  "${cmc_ios_test_fixture_archive}/Products/Applications/Extra.app"
cmc_ios_test_expect_failure archive-application-set \
  ARCHIVE_APPLICATION_SET_INVALID \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
rm -rf -- "${cmc_ios_test_fixture_archive}/Products/Applications/Extra.app"

ln -s "${cmc_ios_test_tmp_root}/external-extra.app" \
  "${cmc_ios_test_fixture_archive}/Products/Applications/Extra.app"
cmc_ios_test_expect_failure archive-application-symlink \
  ARCHIVE_APPLICATION_SET_INVALID \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
rm "${cmc_ios_test_fixture_archive}/Products/Applications/Extra.app"

cmc_ios_test_external_app="${cmc_ios_test_tmp_root}/External.app"
cp -R "${cmc_ios_test_fixture_app}" "${cmc_ios_test_external_app}"
cmc_ios_test_expect_failure archive-binding APP_ARCHIVE_BUNDLE_MISMATCH \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_external_app}" \
  --archive "${cmc_ios_test_fixture_archive}"

cmc_ios_test_app_info="${cmc_ios_test_fixture_app}/Info.plist"
cp "${cmc_ios_test_app_info}" "${cmc_ios_test_tmp_root}/Info.plist.original"
/usr/libexec/PlistBuddy -c \
  'Add :CFBundleURLTypes:0:CFBundleURLSchemes:1 string com.xniw.clientmerchandisecontrol.dev' \
  "${cmc_ios_test_app_info}"
cmc_ios_test_expect_failure extra-url-scheme DEEPLINK_SCHEME_SET_INVALID \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_tmp_root}/Info.plist.original" "${cmc_ios_test_app_info}"

/usr/libexec/PlistBuddy -c \
  'Set :CFBundleExecutable ../../outside-runner' "${cmc_ios_test_app_info}"
cmc_ios_test_expect_failure executable-traversal APP_EXECUTABLE_NAME_INVALID \
  cmc_ios_test_validate \
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
  cmc_ios_test_validate \
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
  cmc_ios_test_validate \
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
  cmc_ios_test_validate \
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
  cmc_ios_test_validate \
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
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_tmp_root}/app-links.valid.xcprivacy" \
  "${cmc_ios_test_required_privacy}"

plutil -replace NSPrivacyAccessedAPITypes -json \
  '[{"NSPrivacyAccessedAPIType":"NSPrivacyAccessedAPICategoryUserDefaults","NSPrivacyAccessedAPITypeReasons":["85F4.1"]}]' \
  "${cmc_ios_test_required_privacy}"
cmc_ios_test_expect_failure privacy-reason-category-mismatch \
  DEPENDENCY_PRIVACY_MANIFEST_INVALID \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_tmp_root}/app-links.valid.xcprivacy" \
  "${cmc_ios_test_required_privacy}"

cmc_ios_test_maps_privacy="${cmc_ios_test_fixture_app}/google_maps_flutter_ios_privacy.bundle/PrivacyInfo.xcprivacy"
cp "${cmc_ios_test_maps_privacy}" \
  "${cmc_ios_test_tmp_root}/google-maps.valid.xcprivacy"
cp "${cmc_ios_test_required_privacy}" "${cmc_ios_test_maps_privacy}"
cmc_ios_test_expect_failure privacy-sdk-content-mismatch \
  DEPENDENCY_PRIVACY_MANIFEST_CONTENT_MISMATCH \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_tmp_root}/google-maps.valid.xcprivacy" \
  "${cmc_ios_test_maps_privacy}"

cmc_ios_test_extra_framework="${cmc_ios_test_fixture_app}/Frameworks/Extra.framework"
cp -R "${cmc_ios_test_fixture_app}/Frameworks/App.framework" \
  "${cmc_ios_test_extra_framework}"
cmc_ios_test_expect_failure privacy-extra-framework-without-manifest \
  EMBEDDED_FRAMEWORK_SET_INVALID \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
rm -rf -- "${cmc_ios_test_extra_framework}"

cmc_ios_test_extra_framework="${cmc_ios_test_fixture_app}/Frameworks/Extra.FRAMEWORK"
cp -R "${cmc_ios_test_fixture_app}/Frameworks/App.framework" \
  "${cmc_ios_test_extra_framework}"
cmc_ios_test_expect_failure privacy-extra-framework-case \
  EMBEDDED_FRAMEWORK_SET_INVALID \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
rm -rf -- "${cmc_ios_test_extra_framework}"

mkdir -p "${cmc_ios_test_fixture_app}/PlugIns"
cp -R "${cmc_ios_test_fixture_app}/Frameworks/App.framework" \
  "${cmc_ios_test_fixture_app}/PlugIns/Extra.framework"
cmc_ios_test_expect_failure privacy-extra-framework-nested \
  EMBEDDED_FRAMEWORK_SET_INVALID \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
rm -rf -- "${cmc_ios_test_fixture_app}/PlugIns"

cp "${cmc_ios_test_fixture_app}/Frameworks/App.framework/App" \
  "${cmc_ios_test_fixture_app}/Frameworks/Extra.dylib"
cmc_ios_test_expect_failure privacy-extra-dylib EMBEDDED_DYLIB_SET_INVALID \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
rm "${cmc_ios_test_fixture_app}/Frameworks/Extra.dylib"

cp "${cmc_ios_test_fixture_app}/Frameworks/App.framework/App" \
  "${cmc_ios_test_fixture_app}/Frameworks/App.framework/EmbeddedPayload"
cmc_ios_test_expect_failure extensionless-macho EMBEDDED_MACHO_SET_INVALID \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
rm "${cmc_ios_test_fixture_app}/Frameworks/App.framework/EmbeddedPayload"

cmc_ios_test_runner_binary="${cmc_ios_test_fixture_app}/Runner"
perl -e '
  use strict;
  use warnings;
  my ($path, $mask, $operation) = @ARGV;
  open my $handle, "+<", $path or die "open\n";
  binmode $handle;
  seek $handle, 24, 0 or die "seek\n";
  read($handle, my $bytes, 4) == 4 or die "read\n";
  my $flags = unpack "V", $bytes;
  my $mask_value = hex $mask;
  $flags = $operation eq "clear"
    ? $flags & ~$mask_value
    : $flags | $mask_value;
  seek $handle, 24, 0 or die "seek\n";
  print {$handle} pack("V", $flags) or die "write\n";
  close $handle or die "close\n";
' "${cmc_ios_test_runner_binary}" 0x00200000 clear
cmc_ios_test_expect_failure macho-header-pie-disabled \
  EMBEDDED_COMPONENT_DIGEST_MISMATCH \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_source_app}/Runner" "${cmc_ios_test_runner_binary}"

perl -e '
  use strict;
  use warnings;
  my ($path, $mask, $operation) = @ARGV;
  open my $handle, "+<", $path or die "open\n";
  binmode $handle;
  seek $handle, 24, 0 or die "seek\n";
  read($handle, my $bytes, 4) == 4 or die "read\n";
  my $flags = unpack "V", $bytes;
  my $mask_value = hex $mask;
  $flags = $operation eq "clear"
    ? $flags & ~$mask_value
    : $flags | $mask_value;
  seek $handle, 24, 0 or die "seek\n";
  print {$handle} pack("V", $flags) or die "write\n";
  close $handle or die "close\n";
' "${cmc_ios_test_runner_binary}" 0x00020000 set
cmc_ios_test_expect_failure macho-header-stack-executable \
  EMBEDDED_COMPONENT_DIGEST_MISMATCH \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_source_app}/Runner" "${cmc_ios_test_runner_binary}"

cmc_ios_test_objective_binary="${cmc_ios_test_fixture_app}/Frameworks/objective_c.framework/objective_c"
perl -e '
  use strict;
  use warnings;
  local $/;
  my ($path, $before, $after) = @ARGV;
  length($before) == length($after) or die "length\n";
  open my $input, "<", $path or die "open-read\n";
  binmode $input;
  my $contents = <$input>;
  close $input or die "close-read\n";
  my $first = index($contents, $before);
  $first >= 0 or die "missing\n";
  index($contents, $before, $first + 1) < 0 or die "duplicate\n";
  substr($contents, $first, length($before), $after);
  open my $output, ">", $path or die "open-write\n";
  binmode $output;
  print {$output} $contents or die "write\n";
  close $output or die "close-write\n";
' "${cmc_ios_test_objective_binary}" \
  '/usr/lib/libSystem.B.dylib' '/usr/lib/libSystfm.B.dylib'
cmc_ios_test_expect_failure macho-load-command-digest \
  EMBEDDED_COMPONENT_DIGEST_MISMATCH \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_source_app}/Frameworks/objective_c.framework/objective_c" \
  "${cmc_ios_test_objective_binary}"

cmc_ios_test_objective_text_offset="$(
  otool -l "${cmc_ios_test_objective_binary}" | awk '
    $1 == "sectname" && $2 == "__text" { in_text = 1; next }
    in_text && $1 == "offset" { print $2; exit }
  '
)"
cmc_ios_test_objective_slice_offset="$(
  lipo -detailed_info "${cmc_ios_test_objective_binary}" | awk '
    $1 == "architecture" && $2 == "arm64" { in_arm64 = 1; next }
    in_arm64 && $1 == "offset" { print $2; exit }
  '
)"
cmc_ios_test_objective_slice_offset="${cmc_ios_test_objective_slice_offset:-0}"
[[ "${cmc_ios_test_objective_text_offset}" =~ ^[0-9]+$ ]] || {
  printf 'Fixture iOS: offset __text non leggibile.\n' >&2
  exit 1
}
[[ "${cmc_ios_test_objective_slice_offset}" =~ ^[0-9]+$ ]] || {
  printf 'Fixture iOS: offset slice arm64 non leggibile.\n' >&2
  exit 1
}
cmc_ios_test_objective_text_offset=$((
  cmc_ios_test_objective_slice_offset + cmc_ios_test_objective_text_offset
))
cmc_ios_test_flip_byte "${cmc_ios_test_objective_binary}" \
  "$((cmc_ios_test_objective_text_offset + 16))"
cmc_ios_test_expect_failure macho-content-digest \
  EMBEDDED_COMPONENT_DIGEST_MISMATCH \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_source_app}/Frameworks/objective_c.framework/objective_c" \
  "${cmc_ios_test_objective_binary}"

cmc_ios_test_reference_objective="${cmc_ios_test_reference_app}/Frameworks/objective_c.framework/objective_c"
cmc_ios_test_reference_backup="${cmc_ios_test_tmp_root}/objective-reference.original"
cmc_ios_test_reference_restore="${cmc_ios_test_reference_objective}"
cp "${cmc_ios_test_reference_objective}" \
  "${cmc_ios_test_reference_backup}"
cmc_ios_test_flip_byte "${cmc_ios_test_objective_binary}" \
  "$((cmc_ios_test_objective_text_offset + 16))"
cmc_ios_test_flip_byte "${cmc_ios_test_reference_objective}" \
  "$((cmc_ios_test_objective_text_offset + 16))"
cmc_ios_test_expect_failure paired-reference-content-tamper \
  REFERENCE_ATTESTATION_MISMATCH \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_source_app}/Frameworks/objective_c.framework/objective_c" \
  "${cmc_ios_test_objective_binary}"
cp "${cmc_ios_test_reference_backup}" \
  "${cmc_ios_test_reference_objective}"
cmc_ios_test_reference_restore=''

cmc_ios_test_objective_arm64="${cmc_ios_test_tmp_root}/objective-arm64"
cmc_ios_test_objective_x86="${cmc_ios_test_tmp_root}/objective-x86"
cmc_ios_test_objective_fat="${cmc_ios_test_tmp_root}/objective-fat"
lipo "${cmc_ios_test_objective_binary}" -thin arm64 \
  -output "${cmc_ios_test_objective_arm64}"
cp "${cmc_ios_test_objective_arm64}" "${cmc_ios_test_objective_x86}"
chmod u+w "${cmc_ios_test_objective_x86}"
perl -e '
  use strict;
  use warnings;
  my $path = shift;
  open my $handle, "+<:raw", $path or die "open\n";
  seek($handle, 4, 0) or die "seek\n";
  print {$handle} pack("V", 0x01000007), pack("V", 3) or die "write\n";
  close $handle or die "close\n";
' "${cmc_ios_test_objective_x86}"
lipo -create "${cmc_ios_test_objective_arm64}" \
  "${cmc_ios_test_objective_x86}" -output "${cmc_ios_test_objective_fat}"
cp "${cmc_ios_test_objective_fat}" "${cmc_ios_test_reference_objective}"
cmc_ios_test_expect_attestor_failure reference-fat-architecture \
  REFERENCE_MACHO_ARCHITECTURE_INVALID \
  bash "${cmc_ios_test_attestor}" \
  --app "${cmc_ios_test_reference_app}"
cp "${cmc_ios_test_objective_fat}" "${cmc_ios_test_objective_binary}"
cmc_ios_test_objective_fat_canonical="${cmc_ios_test_tmp_root}/objective-fat-canonical"
cp "${cmc_ios_test_objective_fat}" \
  "${cmc_ios_test_objective_fat_canonical}"
chmod u+w "${cmc_ios_test_objective_fat_canonical}"
codesign --remove-signature "${cmc_ios_test_objective_fat_canonical}" \
  >/dev/null 2>&1 || true
codesign --force --sign - "${cmc_ios_test_objective_fat_canonical}" \
  >/dev/null 2>&1
codesign --remove-signature "${cmc_ios_test_objective_fat_canonical}" \
  >/dev/null 2>&1
cmc_ios_test_objective_fat_digest="$(
  shasum -a 256 "${cmc_ios_test_objective_fat_canonical}" | awk '{print $1}'
)"
IFS=',' read -r -a cmc_ios_test_fat_digests \
  <<<"${cmc_ios_test_reference_attestation}"
cmc_ios_test_fat_digests[2]="${cmc_ios_test_objective_fat_digest}"
cmc_ios_test_fat_attestation="$(
  IFS=','
  printf '%s' "${cmc_ios_test_fat_digests[*]}"
)"
cmc_ios_test_expect_failure framework-fat-architecture \
  FRAMEWORK_ARCHITECTURE_INVALID \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}" \
  --reference-app "${cmc_ios_test_reference_app}" \
  --reference-attestation "${cmc_ios_test_fat_attestation}"
cp "${cmc_ios_test_source_app}/Frameworks/objective_c.framework/objective_c" \
  "${cmc_ios_test_objective_binary}"
cp "${cmc_ios_test_reference_backup}" \
  "${cmc_ios_test_reference_objective}"

rm -rf -- "${cmc_ios_test_fixture_app}/Frameworks/objective_c.framework"
cp -R "${cmc_ios_test_fixture_app}/Frameworks/sqlite3.framework" \
  "${cmc_ios_test_fixture_app}/Frameworks/objective_c.framework"
cmc_ios_test_expect_failure framework-content-replacement \
  EMBEDDED_MACHO_SET_INVALID \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
rm -rf -- "${cmc_ios_test_fixture_app}/Frameworks/objective_c.framework"
cp -R "${cmc_ios_test_source_app}/Frameworks/objective_c.framework" \
  "${cmc_ios_test_fixture_app}/Frameworks/objective_c.framework"

mv "${cmc_ios_test_fixture_app}/GoogleMapsResources.bundle" \
  "${cmc_ios_test_tmp_root}/GoogleMapsResources.bundle.original"
mkdir "${cmc_ios_test_fixture_app}/GoogleMapsResources.bundle"
cp "${cmc_ios_test_fixture_app}/app_links_app_links.bundle/Info.plist" \
  "${cmc_ios_test_fixture_app}/GoogleMapsResources.bundle/Info.plist"
cmc_ios_test_expect_failure bundle-content-replacement \
  EMBEDDED_BUNDLE_SET_INVALID \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
rm -rf -- "${cmc_ios_test_fixture_app}/GoogleMapsResources.bundle"
mv "${cmc_ios_test_tmp_root}/GoogleMapsResources.bundle.original" \
  "${cmc_ios_test_fixture_app}/GoogleMapsResources.bundle"

cmc_ios_test_bundle_tamper="${cmc_ios_test_fixture_app}/app_links_app_links.bundle/cmc-unexpected-resource.txt"
printf 'unexpected release resource\n' >"${cmc_ios_test_bundle_tamper}"
cmc_ios_test_expect_failure bundle-content-digest \
  EMBEDDED_BUNDLE_DIGEST_MISMATCH \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
rm "${cmc_ios_test_bundle_tamper}"

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
cmc_ios_test_validate \
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
cmc_ios_test_validate \
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
  cmc_ios_test_validate \
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
  cmc_ios_test_validate \
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
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp -R "${cmc_ios_test_source_app}/." "${cmc_ios_test_fixture_app}/"
codesign --force --deep --sign - --entitlements "${cmc_ios_test_entitlements}" \
  "${cmc_ios_test_fixture_app}" >/dev/null 2>&1
printf 'tamper after signing\n' >>"${cmc_ios_test_fixture_app}/Assets.car"
cmc_ios_test_expect_failure invalid-signature ARTIFACT_SIGNATURE_INVALID \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"

printf 'iOS release validator fixtures: %d/%d PASS.\n' \
  "${cmc_ios_test_passed}" "${cmc_ios_test_total}"
