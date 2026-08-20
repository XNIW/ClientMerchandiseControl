#!/usr/bin/env bash
set -euo pipefail

cmc_ios_test_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_ios_test_root="$(git -C "${cmc_ios_test_script_dir}" rev-parse --show-toplevel)"
cmc_ios_test_validator="${cmc_ios_test_root}/scripts/check-ios-release.sh"
cmc_ios_test_attestor="${cmc_ios_test_root}/scripts/create-ios-reference-attestation.sh"
cmc_ios_test_plist_canonicalizer="${cmc_ios_test_root}/scripts/canonicalize-ios-bundle-plist.py"
cmc_ios_test_tree_attestor="${cmc_ios_test_root}/scripts/attest-ios-app-tree.py"
cmc_ios_test_real_python3="$(command -v python3)"
cmc_ios_test_archive=''
cmc_ios_test_reference_app=''
cmc_ios_test_reference_attestation=''
cmc_ios_test_current_seal=''

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
  cmc_ios_test_prepare_seal
  bash "${cmc_ios_test_validator}" "$@" \
    --sealed-app-output "${cmc_ios_test_current_seal}" \
    --reference-app "${cmc_ios_test_reference_app}" \
    --reference-attestation "${cmc_ios_test_reference_attestation}"
}

cmc_ios_test_validate_bounded() {
  cmc_ios_test_prepare_seal
  python3 - "${cmc_ios_test_validator}" \
    "${cmc_ios_test_reference_app}" \
    "${cmc_ios_test_reference_attestation}" \
    "${cmc_ios_test_current_seal}" "$@" <<'PY'
import subprocess
import sys

validator, reference_app, reference_attestation, sealed_output, *arguments = sys.argv[1:]
command = [
    "bash",
    validator,
    *arguments,
    "--sealed-app-output",
    sealed_output,
    "--reference-app",
    reference_app,
    "--reference-attestation",
    reference_attestation,
]
try:
    result = subprocess.run(command, capture_output=True, timeout=60)
except subprocess.TimeoutExpired:
    print("Fixture iOS: validator non bounded.", file=sys.stderr)
    raise SystemExit(124)
sys.stdout.buffer.write(result.stdout)
sys.stderr.buffer.write(result.stderr)
raise SystemExit(result.returncode)
PY
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
cmc_ios_test_tmp_parent="$(cd -- "${cmc_ios_test_tmp_parent}" && pwd -P)"
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

cmc_ios_test_seal_root="${cmc_ios_test_tmp_root}/sealed"
mkdir -p "${cmc_ios_test_seal_root}"
cmc_ios_test_prepare_seal() {
  cmc_ios_test_seal_case="$(
    mktemp -d "${cmc_ios_test_seal_root}/candidate.XXXXXX"
  )"
  cmc_ios_test_current_seal="${cmc_ios_test_seal_case}/Runner.app.zip"
}

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
  if [[ "$(grep -Ec '^IOS_RELEASE_BLOCKED:' \
    "${cmc_ios_test_log}")" -ne 1 ]] || \
    ! grep -Fxq -- "IOS_RELEASE_BLOCKED: ${cmc_ios_test_expected}" \
      "${cmc_ios_test_log}"; then
    printf 'Fixture iOS %s fallita per ragione inattesa.\n' \
      "${cmc_ios_test_name}" >&2
    grep -E '^IOS_RELEASE_BLOCKED: [A-Z0-9_]+$' \
      "${cmc_ios_test_log}" >&2 || true
    exit 1
  fi
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
  if [[ "$(grep -Ec '^IOS_REFERENCE_ATTESTATION_BLOCKED:' \
    "${cmc_ios_test_log}")" -ne 1 ]] || \
    ! grep -Fxq -- \
      "IOS_REFERENCE_ATTESTATION_BLOCKED: ${cmc_ios_test_expected}" \
      "${cmc_ios_test_log}"; then
    printf 'Fixture attestor iOS %s fallita per ragione inattesa.\n' \
      "${cmc_ios_test_name}" >&2
    grep -E '^IOS_REFERENCE_ATTESTATION_BLOCKED: [A-Z0-9_]+$' \
      "${cmc_ios_test_log}" >&2 || true
    exit 1
  fi
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

cmc_ios_test_replace_uuid() {
  perl -e '
    use strict;
    use warnings;
    my $path = shift;
    open my $handle, "+<:raw", $path or exit 1;
    my $file_size = -s $handle;
    read($handle, my $prefix, 8) == 8 or exit 1;
    my $slice_offset = 0;
    if (substr($prefix, 0, 4) eq "\xca\xfe\xba\xbe") {
      my (undef, $count) = unpack("NN", $prefix);
      $count == 1 or exit 1;
      read($handle, my $architecture, 20) == 20 or exit 1;
      my (undef, undef, $offset, $size, undef) =
        unpack("NNNNN", $architecture);
      $offset + $size == $file_size or exit 1;
      $slice_offset = $offset;
    } elsif (substr($prefix, 0, 4) ne "\xcf\xfa\xed\xfe") {
      exit 1;
    }
    seek($handle, $slice_offset, 0) or exit 1;
    read($handle, my $header, 32) == 32 or exit 1;
    my ($magic, $commands, $commands_size) =
      unpack("Vx12VV", $header);
    $magic == 0xfeedfacf or exit 1;
    my $offset = $slice_offset + 32;
    my $end = $offset + $commands_size;
    my $uuid_count = 0;
    for (1 .. $commands) {
      seek($handle, $offset, 0) or exit 1;
      read($handle, my $command_header, 8) == 8 or exit 1;
      my ($command, $size) = unpack("VV", $command_header);
      $size >= 8 && $offset + $size <= $end or exit 1;
      if ($command == 0x1b) {
        $size == 24 or exit 1;
        seek($handle, $offset + 8, 0) or exit 1;
        print {$handle} "\xa5" x 16 or exit 1;
        $uuid_count += 1;
      }
      $offset += $size;
    }
    $offset == $end && $uuid_count == 1 or exit 1;
    close $handle or exit 1;
  ' "$1"
}

cmc_ios_test_fake_reason_suffix() {
  printf 'IOS_RELEASE_BLOCKED: FRAMEWORK_ARCHITECTURE_INVALID_SUFFIX\n' >&2
  return 1
}

cmc_ios_test_fake_reason_duplicate() {
  printf 'IOS_RELEASE_BLOCKED: FRAMEWORK_ARCHITECTURE_INVALID\n' >&2
  printf 'IOS_RELEASE_BLOCKED: EMBEDDED_COMPONENT_DIGEST_MISMATCH\n' >&2
  return 1
}

cmc_ios_test_fake_attestor_reason_duplicate() {
  printf 'IOS_REFERENCE_ATTESTATION_BLOCKED: REFERENCE_MACHO_ARCHITECTURE_INVALID\n' >&2
  printf 'IOS_REFERENCE_ATTESTATION_BLOCKED: REFERENCE_COMPONENT_SET_INVALID\n' >&2
  return 1
}

cmc_ios_test_fake_reason_malformed_duplicate() {
  printf 'IOS_RELEASE_BLOCKED: FRAMEWORK_ARCHITECTURE_INVALID\n' >&2
  printf 'IOS_RELEASE_BLOCKED: EMBEDDED_COMPONENT_DIGEST_MISMATCH \r\n' >&2
  return 1
}

cmc_ios_test_fake_attestor_reason_malformed_duplicate() {
  printf 'IOS_REFERENCE_ATTESTATION_BLOCKED: REFERENCE_MACHO_ARCHITECTURE_INVALID\n' >&2
  printf 'IOS_REFERENCE_ATTESTATION_BLOCKED: REFERENCE_COMPONENT_SET_INVALID \r\n' >&2
  return 1
}

cmc_ios_test_total=$((cmc_ios_test_total + 1))
if (
  cmc_ios_test_expect_failure reason-suffix-rejected \
    FRAMEWORK_ARCHITECTURE_INVALID \
    cmc_ios_test_fake_reason_suffix
) >/dev/null 2>&1; then
  printf 'Fixture iOS ha accettato una reason con suffisso.\n' >&2
  exit 1
fi
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))
cmc_ios_test_total=$((cmc_ios_test_total + 1))
if (
  cmc_ios_test_expect_failure reason-malformed-duplicate-rejected \
    FRAMEWORK_ARCHITECTURE_INVALID \
    cmc_ios_test_fake_reason_malformed_duplicate
) >/dev/null 2>&1; then
  printf 'Fixture iOS ha accettato reason malformate multiple.\n' >&2
  exit 1
fi
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))
cmc_ios_test_total=$((cmc_ios_test_total + 1))
if (
  cmc_ios_test_expect_failure reason-duplicate-rejected \
    FRAMEWORK_ARCHITECTURE_INVALID \
    cmc_ios_test_fake_reason_duplicate
) >/dev/null 2>&1; then
  printf 'Fixture iOS ha accettato reason multiple.\n' >&2
  exit 1
fi
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))
cmc_ios_test_total=$((cmc_ios_test_total + 1))
if (
  cmc_ios_test_expect_attestor_failure attestor-reason-duplicate-rejected \
    REFERENCE_MACHO_ARCHITECTURE_INVALID \
    cmc_ios_test_fake_attestor_reason_duplicate
) >/dev/null 2>&1; then
  printf 'Fixture attestor iOS ha accettato reason multiple.\n' >&2
  exit 1
fi
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))
cmc_ios_test_total=$((cmc_ios_test_total + 1))
if (
  cmc_ios_test_expect_attestor_failure \
    attestor-reason-malformed-duplicate-rejected \
    REFERENCE_MACHO_ARCHITECTURE_INVALID \
    cmc_ios_test_fake_attestor_reason_malformed_duplicate
) >/dev/null 2>&1; then
  printf 'Fixture attestor iOS ha accettato reason malformate multiple.\n' >&2
  exit 1
fi
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

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
cmc_ios_test_baseline_seal_sha="$(
  sed -nE 's/^IOS_RELEASE_SEALED_APP_SHA256=([0-9a-f]{64})$/\1/p' \
    <<<"${cmc_ios_test_baseline_output}"
)"
[[ "${cmc_ios_test_baseline_seal_sha}" =~ ^[0-9a-f]{64}$ ]] || {
  printf 'Fixture iOS: payload sealed non legato al digest emesso.\n' >&2
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

cmc_ios_test_runner_objc_stubs_offset="$(
  otool -l "${cmc_ios_test_runner_binary}" | awk '
    $1 == "sectname" && $2 == "__objc_stubs" { in_stubs = 1; next }
    in_stubs && $1 == "offset" { print $2; exit }
  '
)"
[[ "${cmc_ios_test_runner_objc_stubs_offset}" =~ ^[0-9]+$ ]] || {
  printf 'Fixture iOS: offset __objc_stubs non leggibile.\n' >&2
  exit 1
}
# I due output Xcode ammessi differiscono solo per la scelta completa fra due
# slot GOT equivalenti di _objc_msgSend. Una mutazione parziale degli stub deve
# continuare a fallire l'exact-content gate.
cmc_ios_test_flip_byte "${cmc_ios_test_runner_binary}" \
  "$((cmc_ios_test_runner_objc_stubs_offset + 13))"
cmc_ios_test_expect_failure runner-objc-stub-content-digest \
  EMBEDDED_COMPONENT_DIGEST_MISMATCH \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_source_app}/Runner" "${cmc_ios_test_runner_binary}"

cmc_ios_test_objective_binary="${cmc_ios_test_fixture_app}/Frameworks/objective_c.framework/objective_c"
cmc_ios_test_replace_uuid "${cmc_ios_test_objective_binary}"
cmc_ios_test_total=$((cmc_ios_test_total + 1))
cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}" >/dev/null || {
  printf 'Fixture iOS ha rifiutato LC_UUID non semantico.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))
cp "${cmc_ios_test_source_app}/Frameworks/objective_c.framework/objective_c" \
  "${cmc_ios_test_objective_binary}"

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
  --reference-attestation "${cmc_ios_test_fat_attestation}" \
  --sealed-app-output "${cmc_ios_test_seal_root}/framework-fat.zip"
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

cmc_ios_test_bundle_info="${cmc_ios_test_fixture_app}/app_links_app_links.bundle/Info.plist"
cmc_ios_test_bundle_machine_build="$({
  /usr/libexec/PlistBuddy -c 'Print :BuildMachineOSBuild' \
    "${cmc_ios_test_bundle_info}" 2>/dev/null || true
})"
[[ -n "${cmc_ios_test_bundle_machine_build}" ]] || {
  printf 'Fixture iOS: BuildMachineOSBuild non leggibile.\n' >&2
  exit 1
}
/usr/libexec/PlistBuddy -c \
  'Set :BuildMachineOSBuild CMC_HOST_VARIANCE_FIXTURE' \
  "${cmc_ios_test_bundle_info}"
cmc_ios_test_total=$((cmc_ios_test_total + 1))
cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}" >/dev/null || {
  printf 'Fixture iOS ha legato il bundle al build number del macOS host.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))
/usr/libexec/PlistBuddy -c \
  "Set :BuildMachineOSBuild ${cmc_ios_test_bundle_machine_build}" \
  "${cmc_ios_test_bundle_info}"

/usr/libexec/PlistBuddy -c 'Add :CMCUnexpectedMetadata string tamper' \
  "${cmc_ios_test_bundle_info}"
cmc_ios_test_expect_failure bundle-plist-semantic-digest \
  EMBEDDED_BUNDLE_DIGEST_MISMATCH \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
/usr/libexec/PlistBuddy -c 'Delete :CMCUnexpectedMetadata' \
  "${cmc_ios_test_bundle_info}"

/usr/libexec/PlistBuddy -c \
  'Set :CFBundleIdentifier com.xniw.invalid-bundle-fixture' \
  "${cmc_ios_test_bundle_info}"
cmc_ios_test_expect_failure bundle-plist-identity-combined \
  BUNDLE_IDENTITY_INVALID \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
/usr/libexec/PlistBuddy -c \
  'Set :CFBundleIdentifier app-links-7.2.1.app-links.resources' \
  "${cmc_ios_test_bundle_info}"

cmc_ios_test_python_hook="${cmc_ios_test_tmp_root}/python-hook"
mkdir -p "${cmc_ios_test_python_hook}"
cat >"${cmc_ios_test_python_hook}/python3" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$#" -eq 5 && \
  "$1" == "${CMC_IOS_TEST_TREE_ATTESTOR}" && \
  "$2" == '--publish-seal' ]]; then
  cmc_ios_test_hook_output="$("${CMC_IOS_TEST_REAL_PYTHON3}" "$@")"
  "${CMC_IOS_TEST_REAL_PYTHON3}" - "$5" \
    "${CMC_IOS_TEST_HOOK_SENTINEL}" <<'PY'
import os
import sys

payload, sentinel = sys.argv[1:]
os.chmod(payload, 0o644)
with open(payload, "r+b") as target:
    target.seek(64)
    current = target.read(1)
    target.seek(64)
    target.write(bytes([current[0] ^ 1]))
with open(sentinel, "wb") as target:
    target.write(b"hook-ran")
PY
  printf '%s\n' "${cmc_ios_test_hook_output}"
  exit 0
fi
exec "${CMC_IOS_TEST_REAL_PYTHON3}" "$@"
SH
chmod u+x "${cmc_ios_test_python_hook}/python3"
cmc_ios_test_postfinal_seal="${cmc_ios_test_seal_root}/postfinal-bound.zip"
cmc_ios_test_postfinal_log="${cmc_ios_test_tmp_root}/postfinal-bound.log"
cmc_ios_test_postfinal_sentinel="${cmc_ios_test_tmp_root}/postfinal-hook-ran"
cmc_ios_test_total=$((cmc_ios_test_total + 1))
if env \
  PATH="${cmc_ios_test_python_hook}:${PATH}" \
  CMC_IOS_TEST_TREE_ATTESTOR="${cmc_ios_test_tree_attestor}" \
  CMC_IOS_TEST_HOOK_SENTINEL="${cmc_ios_test_postfinal_sentinel}" \
  CMC_IOS_TEST_REAL_PYTHON3="${cmc_ios_test_real_python3}" \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}" \
  --reference-app "${cmc_ios_test_reference_app}" \
  --reference-attestation "${cmc_ios_test_reference_attestation}" \
  --sealed-app-output "${cmc_ios_test_postfinal_seal}" \
  >"${cmc_ios_test_postfinal_log}" 2>&1; then
  printf 'Fixture iOS: payload sealed sostituito dopo publish accettato.\n' >&2
  exit 1
fi
[[ -f "${cmc_ios_test_postfinal_sentinel}" && \
  "$(grep -Ec '^IOS_RELEASE_BLOCKED: SEALED_APP_VERIFICATION_FAILED$' \
    "${cmc_ios_test_postfinal_log}")" -eq 1 ]] || {
  printf 'Fixture iOS: post-publish tamper non respinto esattamente.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_snapshot_aba_archive="${cmc_ios_test_tmp_root}/snapshot-aba.xcarchive"
cp -R "${cmc_ios_test_fixture_archive}" "${cmc_ios_test_snapshot_aba_archive}"
cmc_ios_test_snapshot_aba_app="${cmc_ios_test_snapshot_aba_archive}/Products/Applications/Runner.app"
printf 'unsafe-retained\n' \
  >"${cmc_ios_test_snapshot_aba_app}/snapshot-aba-payload.txt"
cmc_ios_test_snapshot_aba_hook="${cmc_ios_test_tmp_root}/snapshot-aba-hook"
mkdir -p "${cmc_ios_test_snapshot_aba_hook}"
cat >"${cmc_ios_test_snapshot_aba_hook}/python3" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$#" -eq 5 && \
  "$1" == "${CMC_IOS_TEST_TREE_ATTESTOR}" && \
  "$2" == '--seal-snapshot' ]]; then
  cmc_ios_test_hook_output="$("${CMC_IOS_TEST_REAL_PYTHON3}" "$@")"
  mv "$5" "${CMC_IOS_TEST_SNAPSHOT_UNSAFE}"
  cp -R "${CMC_IOS_TEST_SNAPSHOT_SAFE}" "$5"
  printf '%s\n' "${cmc_ios_test_hook_output}"
  exit 0
fi
exec "${CMC_IOS_TEST_REAL_PYTHON3}" "$@"
SH
chmod u+x "${cmc_ios_test_snapshot_aba_hook}/python3"
cmc_ios_test_snapshot_aba_seal="${cmc_ios_test_seal_root}/snapshot-aba.zip"
cmc_ios_test_snapshot_aba_log="${cmc_ios_test_tmp_root}/snapshot-aba.log"
cmc_ios_test_total=$((cmc_ios_test_total + 1))
if env \
  PATH="${cmc_ios_test_snapshot_aba_hook}:${PATH}" \
  CMC_IOS_TEST_TREE_ATTESTOR="${cmc_ios_test_tree_attestor}" \
  CMC_IOS_TEST_REAL_PYTHON3="${cmc_ios_test_real_python3}" \
  CMC_IOS_TEST_SNAPSHOT_SAFE="${cmc_ios_test_fixture_app}" \
  CMC_IOS_TEST_SNAPSHOT_UNSAFE="${cmc_ios_test_tmp_root}/unsafe-held.app" \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_snapshot_aba_app}" \
  --archive "${cmc_ios_test_snapshot_aba_archive}" \
  --reference-app "${cmc_ios_test_reference_app}" \
  --reference-attestation "${cmc_ios_test_reference_attestation}" \
  --sealed-app-output "${cmc_ios_test_snapshot_aba_seal}" \
  >"${cmc_ios_test_snapshot_aba_log}" 2>&1; then
  printf 'Fixture iOS: snapshot ABA accettata dal validator.\n' >&2
  exit 1
fi
[[ "$(grep -Ec '^IOS_RELEASE_BLOCKED: ARTIFACT_SNAPSHOT_UNREADABLE$' \
    "${cmc_ios_test_snapshot_aba_log}")" -eq 1 && \
  "$(grep -Ec '^IOS_(RELEASE_CANDIDATE_VALID|TESTFLIGHT_UPLOAD_INPUTS_VALIDATED)$' \
    "${cmc_ios_test_snapshot_aba_log}")" -eq 0 ]] || {
  printf 'Fixture iOS: snapshot ABA non respinta esattamente.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_guard_proxy="${cmc_ios_test_tmp_root}/guard-proxy"
mkdir -p "${cmc_ios_test_guard_proxy}"
cat >"${cmc_ios_test_guard_proxy}/python3" <<'PY'
#!/usr/bin/python3
import os
import shutil
import subprocess
import sys

real_python = os.environ["CMC_IOS_TEST_REAL_PYTHON3"]
tree_attestor = os.environ["CMC_IOS_TEST_TREE_ATTESTOR"]
mode = os.environ.get("CMC_IOS_TEST_GUARD_PROXY_MODE", "")
if (
    len(sys.argv) == 4
    and sys.argv[1] == tree_attestor
    and sys.argv[2] == "--create-temp-directory"
    and mode == "tmp-identity-capture"
):
    result = subprocess.run(
        [real_python, *sys.argv[1:]],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode == 0:
        record = result.stdout.decode("utf-8").strip()
        temporary_root, _ = record.split("\t", 1)
        held = os.environ["CMC_IOS_TEST_CLEANUP_HELD"]
        os.rename(temporary_root, held)
        os.mkdir(temporary_root, 0o700)
        with open(os.path.join(temporary_root, "preserved.txt"), "wb") as target:
            target.write(b"victim")
        with open(
            os.environ["CMC_IOS_TEST_CLEANUP_PATH_FILE"],
            "w",
            encoding="utf-8",
        ) as target:
            target.write(temporary_root)
    sys.stdout.buffer.write(result.stdout)
    sys.stderr.buffer.write(result.stderr)
    raise SystemExit(result.returncode)
if (
    len(sys.argv) == 6
    and sys.argv[1] == tree_attestor
    and sys.argv[2] == "--publish-seal"
    and mode == "tmp-cleanup-aba"
):
    result = subprocess.run(
        [real_python, *sys.argv[1:]],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode == 0:
        temporary_root = os.path.dirname(sys.argv[3])
        held = os.environ["CMC_IOS_TEST_CLEANUP_HELD"]
        os.rename(temporary_root, held)
        os.mkdir(temporary_root, 0o700)
        with open(os.path.join(temporary_root, "preserved.txt"), "wb") as target:
            target.write(b"victim")
        with open(
            os.environ["CMC_IOS_TEST_CLEANUP_PATH_FILE"],
            "w",
            encoding="utf-8",
        ) as target:
            target.write(temporary_root)
    sys.stdout.buffer.write(result.stdout)
    sys.stderr.buffer.write(result.stderr)
    raise SystemExit(result.returncode)
if (
    len(sys.argv) == 5
    and sys.argv[1] == tree_attestor
    and sys.argv[2] == "--guard"
    and mode in ("parent-aba", "ancestor-aba", "mode-aba")
):
    process = subprocess.Popen(
        [real_python, *sys.argv[1:]],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    assert process.stdin is not None
    assert process.stdout is not None
    assert process.stderr is not None
    ready = process.stdout.readline()
    if ready != b"IOS_ARTIFACT_GUARD_READY\n":
        process.kill()
        process.wait()
        raise SystemExit(1)
    snapshot = sys.argv[3]
    held = ""
    decoy = ""
    executable = ""
    original_mode = 0
    if mode == "parent-aba":
        parent = os.path.dirname(snapshot)
        held = f"{parent}.held-{os.getpid()}"
        decoy = f"{parent}.decoy-{os.getpid()}"
        os.rename(parent, held)
        os.mkdir(parent, 0o700)
        shutil.copytree(
            os.environ["CMC_IOS_TEST_GUARD_SAFE_APP"],
            os.path.join(parent, "Runner.app"),
        )
    elif mode == "ancestor-aba":
        ancestor = os.environ["CMC_IOS_TEST_GUARD_ANCESTOR"]
        temporary_root = os.path.dirname(snapshot)
        relative_root = os.path.relpath(temporary_root, ancestor)
        if relative_root.startswith("..") or "/" in relative_root:
            process.kill()
            process.wait()
            raise SystemExit(1)
        held = f"{ancestor}.held-{os.getpid()}"
        decoy = f"{ancestor}.decoy-{os.getpid()}"
        os.rename(ancestor, held)
        os.mkdir(ancestor, 0o700)
        os.mkdir(os.path.join(ancestor, relative_root), 0o700)
        shutil.copytree(
            os.environ["CMC_IOS_TEST_GUARD_SAFE_APP"],
            os.path.join(ancestor, relative_root, "Runner.app"),
        )
    elif mode == "mode-aba":
        executable = os.path.join(snapshot, "Runner")
        original_mode = os.stat(executable, follow_symlinks=False).st_mode & 0o7777
        os.chmod(executable, original_mode | 0o100)
    else:
        process.kill()
        process.wait()
        raise SystemExit(1)
    sys.stdout.buffer.write(ready)
    sys.stdout.buffer.flush()
    command = sys.stdin.buffer.readline()
    if mode in ("parent-aba", "ancestor-aba"):
        swapped = (
            os.path.dirname(snapshot)
            if mode == "parent-aba"
            else os.environ["CMC_IOS_TEST_GUARD_ANCESTOR"]
        )
        os.rename(swapped, decoy)
        os.rename(held, swapped)
    else:
        os.chmod(executable, original_mode)
    process.stdin.write(command)
    process.stdin.flush()
    stdout, stderr = process.communicate(timeout=10)
    sys.stdout.buffer.write(stdout)
    sys.stderr.buffer.write(stderr)
    if decoy:
        shutil.rmtree(decoy)
    raise SystemExit(process.returncode)
os.execv(real_python, [real_python, *sys.argv[1:]])
PY
chmod u+x "${cmc_ios_test_guard_proxy}/python3"

cmc_ios_test_parent_aba_archive="${cmc_ios_test_tmp_root}/parent-aba.xcarchive"
cp -R "${cmc_ios_test_fixture_archive}" "${cmc_ios_test_parent_aba_archive}"
cmc_ios_test_parent_aba_app="${cmc_ios_test_parent_aba_archive}/Products/Applications/Runner.app"
printf 'unsafe-parent-retained\n' \
  >"${cmc_ios_test_parent_aba_app}/parent-aba-payload.txt"
cmc_ios_test_parent_aba_seal="${cmc_ios_test_seal_root}/parent-aba.zip"
cmc_ios_test_parent_aba_log="${cmc_ios_test_tmp_root}/parent-aba.log"
cmc_ios_test_total=$((cmc_ios_test_total + 1))
if env \
  PATH="${cmc_ios_test_guard_proxy}:${PATH}" \
  CMC_IOS_TEST_TREE_ATTESTOR="${cmc_ios_test_tree_attestor}" \
  CMC_IOS_TEST_REAL_PYTHON3="${cmc_ios_test_real_python3}" \
  CMC_IOS_TEST_GUARD_PROXY_MODE='parent-aba' \
  CMC_IOS_TEST_GUARD_SAFE_APP="${cmc_ios_test_fixture_app}" \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_parent_aba_app}" \
  --archive "${cmc_ios_test_parent_aba_archive}" \
  --reference-app "${cmc_ios_test_reference_app}" \
  --reference-attestation "${cmc_ios_test_reference_attestation}" \
  --sealed-app-output "${cmc_ios_test_parent_aba_seal}" \
  >"${cmc_ios_test_parent_aba_log}" 2>&1; then
  printf 'Fixture iOS: parent ABA accettata dal validator.\n' >&2
  exit 1
fi
[[ "$(grep -Ec '^IOS_RELEASE_BLOCKED: ARTIFACT_CHANGED_DURING_VALIDATION$' \
    "${cmc_ios_test_parent_aba_log}")" -eq 1 && \
  "$(grep -Ec '^IOS_(RELEASE_CANDIDATE_VALID|TESTFLIGHT_UPLOAD_INPUTS_VALIDATED)$' \
    "${cmc_ios_test_parent_aba_log}")" -eq 0 ]] || {
  printf 'Fixture iOS: parent ABA non respinta esattamente.\n' >&2
  grep -E '^IOS_RELEASE_BLOCKED: [A-Z0-9_]+$' \
    "${cmc_ios_test_parent_aba_log}" >&2 || true
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_ancestor_guard_root="${cmc_ios_test_tmp_root}/ancestor-guard"
mkdir -p "${cmc_ios_test_ancestor_guard_root}"
cmc_ios_test_ancestor_guard_archive="${cmc_ios_test_tmp_root}/ancestor-guard.xcarchive"
cp -R "${cmc_ios_test_fixture_archive}" "${cmc_ios_test_ancestor_guard_archive}"
cmc_ios_test_ancestor_guard_app="${cmc_ios_test_ancestor_guard_archive}/Products/Applications/Runner.app"
printf 'unsafe-ancestor-retained\n' \
  >"${cmc_ios_test_ancestor_guard_app}/ancestor-guard-payload.txt"
cmc_ios_test_ancestor_guard_seal="${cmc_ios_test_seal_root}/ancestor-guard.zip"
cmc_ios_test_ancestor_guard_log="${cmc_ios_test_tmp_root}/ancestor-guard.log"
cmc_ios_test_total=$((cmc_ios_test_total + 1))
if env \
  TMPDIR="${cmc_ios_test_ancestor_guard_root}" \
  PATH="${cmc_ios_test_guard_proxy}:${PATH}" \
  CMC_IOS_TEST_TREE_ATTESTOR="${cmc_ios_test_tree_attestor}" \
  CMC_IOS_TEST_REAL_PYTHON3="${cmc_ios_test_real_python3}" \
  CMC_IOS_TEST_GUARD_PROXY_MODE='ancestor-aba' \
  CMC_IOS_TEST_GUARD_ANCESTOR="${cmc_ios_test_ancestor_guard_root}" \
  CMC_IOS_TEST_GUARD_SAFE_APP="${cmc_ios_test_fixture_app}" \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_ancestor_guard_app}" \
  --archive "${cmc_ios_test_ancestor_guard_archive}" \
  --reference-app "${cmc_ios_test_reference_app}" \
  --reference-attestation "${cmc_ios_test_reference_attestation}" \
  --sealed-app-output "${cmc_ios_test_ancestor_guard_seal}" \
  >"${cmc_ios_test_ancestor_guard_log}" 2>&1; then
  printf 'Fixture iOS: ancestor ABA accettata dal validator.\n' >&2
  exit 1
fi
[[ "$(grep -Ec '^IOS_RELEASE_BLOCKED: ARTIFACT_CHANGED_DURING_VALIDATION$' \
    "${cmc_ios_test_ancestor_guard_log}")" -eq 1 && \
  "$(grep -Ec '^IOS_(RELEASE_CANDIDATE_VALID|TESTFLIGHT_UPLOAD_INPUTS_VALIDATED)$' \
    "${cmc_ios_test_ancestor_guard_log}")" -eq 0 ]] || {
  printf 'Fixture iOS: ancestor ABA non respinta esattamente.\n' >&2
  grep -E '^IOS_RELEASE_BLOCKED: [A-Z0-9_]+$' \
    "${cmc_ios_test_ancestor_guard_log}" >&2 || true
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_mode_aba_archive="${cmc_ios_test_tmp_root}/mode-aba.xcarchive"
cp -R "${cmc_ios_test_fixture_archive}" "${cmc_ios_test_mode_aba_archive}"
cmc_ios_test_mode_aba_app="${cmc_ios_test_mode_aba_archive}/Products/Applications/Runner.app"
chmod 0644 "${cmc_ios_test_mode_aba_app}/Runner"
cmc_ios_test_mode_aba_seal="${cmc_ios_test_seal_root}/mode-aba.zip"
cmc_ios_test_mode_aba_log="${cmc_ios_test_tmp_root}/mode-aba.log"
cmc_ios_test_total=$((cmc_ios_test_total + 1))
if env \
  PATH="${cmc_ios_test_guard_proxy}:${PATH}" \
  CMC_IOS_TEST_TREE_ATTESTOR="${cmc_ios_test_tree_attestor}" \
  CMC_IOS_TEST_REAL_PYTHON3="${cmc_ios_test_real_python3}" \
  CMC_IOS_TEST_GUARD_PROXY_MODE='mode-aba' \
  CMC_IOS_TEST_GUARD_SAFE_APP="${cmc_ios_test_fixture_app}" \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_mode_aba_app}" \
  --archive "${cmc_ios_test_mode_aba_archive}" \
  --reference-app "${cmc_ios_test_reference_app}" \
  --reference-attestation "${cmc_ios_test_reference_attestation}" \
  --sealed-app-output "${cmc_ios_test_mode_aba_seal}" \
  >"${cmc_ios_test_mode_aba_log}" 2>&1; then
  printf 'Fixture iOS: mode ABA accettata dal validator.\n' >&2
  exit 1
fi
[[ "$(grep -Ec '^IOS_RELEASE_BLOCKED: ARTIFACT_CHANGED_DURING_VALIDATION$' \
    "${cmc_ios_test_mode_aba_log}")" -eq 1 && \
  "$(grep -Ec '^IOS_(RELEASE_CANDIDATE_VALID|TESTFLIGHT_UPLOAD_INPUTS_VALIDATED)$' \
    "${cmc_ios_test_mode_aba_log}")" -eq 0 ]] || {
  printf 'Fixture iOS: mode ABA non respinta esattamente.\n' >&2
  grep -E '^IOS_RELEASE_BLOCKED: [A-Z0-9_]+$' \
    "${cmc_ios_test_mode_aba_log}" >&2 || true
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_cleanup_aba_seal="${cmc_ios_test_seal_root}/tmp-cleanup-aba.zip"
cmc_ios_test_cleanup_aba_log="${cmc_ios_test_tmp_root}/tmp-cleanup-aba.log"
cmc_ios_test_cleanup_aba_held="${cmc_ios_test_tmp_root}/tmp-cleanup-held"
cmc_ios_test_cleanup_aba_path_file="${cmc_ios_test_tmp_root}/tmp-cleanup-path"
cmc_ios_test_total=$((cmc_ios_test_total + 1))
if env \
  PATH="${cmc_ios_test_guard_proxy}:${PATH}" \
  CMC_IOS_TEST_TREE_ATTESTOR="${cmc_ios_test_tree_attestor}" \
  CMC_IOS_TEST_REAL_PYTHON3="${cmc_ios_test_real_python3}" \
  CMC_IOS_TEST_GUARD_PROXY_MODE='tmp-cleanup-aba' \
  CMC_IOS_TEST_CLEANUP_HELD="${cmc_ios_test_cleanup_aba_held}" \
  CMC_IOS_TEST_CLEANUP_PATH_FILE="${cmc_ios_test_cleanup_aba_path_file}" \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}" \
  --reference-app "${cmc_ios_test_reference_app}" \
  --reference-attestation "${cmc_ios_test_reference_attestation}" \
  --sealed-app-output "${cmc_ios_test_cleanup_aba_seal}" \
  >"${cmc_ios_test_cleanup_aba_log}" 2>&1; then
  printf 'Fixture iOS: temp-root cleanup ABA accettata.\n' >&2
  exit 1
fi
cmc_ios_test_cleanup_aba_victim="$(cat "${cmc_ios_test_cleanup_aba_path_file}")"
[[ "$(grep -Ec '^IOS_RELEASE_BLOCKED: TEMP_CLEANUP_REFUSED$' \
    "${cmc_ios_test_cleanup_aba_log}")" -eq 1 && \
  "$(grep -Ec '^IOS_(RELEASE_CANDIDATE_VALID|TESTFLIGHT_UPLOAD_INPUTS_VALIDATED)$' \
    "${cmc_ios_test_cleanup_aba_log}")" -eq 0 && \
  -f "${cmc_ios_test_cleanup_aba_victim}/preserved.txt" && \
  -d "${cmc_ios_test_cleanup_aba_held}" ]] || {
  printf 'Fixture iOS: temp-root cleanup non identity-bound.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_identity_capture_seal="${cmc_ios_test_seal_root}/tmp-identity-capture.zip"
cmc_ios_test_identity_capture_log="${cmc_ios_test_tmp_root}/tmp-identity-capture.log"
cmc_ios_test_identity_capture_held="${cmc_ios_test_tmp_root}/tmp-identity-held"
cmc_ios_test_identity_capture_path_file="${cmc_ios_test_tmp_root}/tmp-identity-path"
cmc_ios_test_total=$((cmc_ios_test_total + 1))
if env \
  PATH="${cmc_ios_test_guard_proxy}:${PATH}" \
  CMC_IOS_TEST_TREE_ATTESTOR="${cmc_ios_test_tree_attestor}" \
  CMC_IOS_TEST_REAL_PYTHON3="${cmc_ios_test_real_python3}" \
  CMC_IOS_TEST_GUARD_PROXY_MODE='tmp-identity-capture' \
  CMC_IOS_TEST_CLEANUP_HELD="${cmc_ios_test_identity_capture_held}" \
  CMC_IOS_TEST_CLEANUP_PATH_FILE="${cmc_ios_test_identity_capture_path_file}" \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}" \
  --reference-app "${cmc_ios_test_reference_app}" \
  --reference-attestation "${cmc_ios_test_reference_attestation}" \
  --sealed-app-output "${cmc_ios_test_identity_capture_seal}" \
  >"${cmc_ios_test_identity_capture_log}" 2>&1; then
  printf 'Fixture iOS: pre-identity temp-root swap accettato.\n' >&2
  exit 1
fi
cmc_ios_test_identity_capture_victim="$(
  cat "${cmc_ios_test_identity_capture_path_file}"
)"
[[ "$(grep -Ec '^IOS_RELEASE_BLOCKED: TEMP_CLEANUP_REFUSED$' \
    "${cmc_ios_test_identity_capture_log}")" -eq 1 && \
  "$(grep -Ec '^IOS_(RELEASE_CANDIDATE_VALID|TESTFLIGHT_UPLOAD_INPUTS_VALIDATED)$' \
    "${cmc_ios_test_identity_capture_log}")" -eq 0 && \
  -f "${cmc_ios_test_identity_capture_victim}/preserved.txt" && \
  -d "${cmc_ios_test_identity_capture_held}" ]] || {
  printf 'Fixture iOS: temp-root identity non acquisita atomicamente.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_ancestor_root="${cmc_ios_test_tmp_root}/ancestor-race"
cmc_ios_test_ancestor_bad="${cmc_ios_test_ancestor_root}/bad"
mkdir -p "${cmc_ios_test_ancestor_root}" "${cmc_ios_test_ancestor_bad}"
cp -R "${cmc_ios_test_fixture_app}" \
  "${cmc_ios_test_ancestor_bad}/Runner.app"
printf 'injected\n' \
  >"${cmc_ios_test_ancestor_bad}/Runner.app/ancestor-race-payload.txt"
ln -s "$(dirname -- "${cmc_ios_test_fixture_app}")" \
  "${cmc_ios_test_ancestor_root}/current"
cmc_ios_test_ancestor_hook="${cmc_ios_test_tmp_root}/ancestor-python-hook"
mkdir -p "${cmc_ios_test_ancestor_hook}"
cat >"${cmc_ios_test_ancestor_hook}/python3" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$#" -eq 5 && \
  "$1" == "${CMC_IOS_TEST_TREE_ATTESTOR}" && \
  "$2" == '--seal-snapshot' ]]; then
  cmc_ios_test_hook_output="$("${CMC_IOS_TEST_REAL_PYTHON3}" "$@")"
  "${CMC_IOS_TEST_REAL_PYTHON3}" - \
    "${CMC_IOS_TEST_ANCESTOR_LINK}" \
    "${CMC_IOS_TEST_ANCESTOR_BAD}" <<'PY'
import os
import sys

link, target = sys.argv[1:]
temporary = f"{link}.next"
os.symlink(target, temporary)
os.replace(temporary, link)
PY
  printf '%s\n' "${cmc_ios_test_hook_output}"
  exit 0
fi
exec "${CMC_IOS_TEST_REAL_PYTHON3}" "$@"
SH
chmod u+x "${cmc_ios_test_ancestor_hook}/python3"
cmc_ios_test_ancestor_seal="${cmc_ios_test_seal_root}/ancestor-bound.zip"
cmc_ios_test_ancestor_log="${cmc_ios_test_tmp_root}/ancestor-bound.log"
cmc_ios_test_total=$((cmc_ios_test_total + 1))
env \
  PATH="${cmc_ios_test_ancestor_hook}:${PATH}" \
  CMC_IOS_TEST_TREE_ATTESTOR="${cmc_ios_test_tree_attestor}" \
  CMC_IOS_TEST_REAL_PYTHON3="${cmc_ios_test_real_python3}" \
  CMC_IOS_TEST_ANCESTOR_LINK="${cmc_ios_test_ancestor_root}/current" \
  CMC_IOS_TEST_ANCESTOR_BAD="${cmc_ios_test_ancestor_bad}" \
  bash "${cmc_ios_test_validator}" \
  --app "${cmc_ios_test_ancestor_root}/current/Runner.app" \
  --archive "${cmc_ios_test_fixture_archive}" \
  --reference-app "${cmc_ios_test_reference_app}" \
  --reference-attestation "${cmc_ios_test_reference_attestation}" \
  --sealed-app-output "${cmc_ios_test_ancestor_seal}" \
  >"${cmc_ios_test_ancestor_log}" 2>&1 || {
  printf 'Fixture iOS: ancestor swap ha invalidato lo snapshot pinned.\n' >&2
  exit 1
}
cmc_ios_test_ancestor_sha="$(
  sed -nE 's/^IOS_RELEASE_SEALED_APP_SHA256=([0-9a-f]{64})$/\1/p' \
    "${cmc_ios_test_ancestor_log}"
)"
[[ "${cmc_ios_test_ancestor_sha}" =~ ^[0-9a-f]{64}$ && \
  -f "${cmc_ios_test_ancestor_root}/current/Runner.app/ancestor-race-payload.txt" ]] || {
  printf 'Fixture iOS: ancestor swap non eseguito o seal assente.\n' >&2
  exit 1
}
cmc_ios_test_ancestor_extracted="${cmc_ios_test_tmp_root}/AncestorBound.app"
"${cmc_ios_test_real_python3}" "${cmc_ios_test_tree_attestor}" \
  --extract "${cmc_ios_test_ancestor_seal}" \
  "${cmc_ios_test_ancestor_sha}" \
  "${cmc_ios_test_ancestor_extracted}" >/dev/null || {
  printf 'Fixture iOS: seal ancestor-bound non estraibile.\n' >&2
  exit 1
}
[[ ! -e "${cmc_ios_test_ancestor_extracted}/ancestor-race-payload.txt" ]] || {
  printf 'Fixture iOS: payload ancestor incluso nel seal validato.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_total=$((cmc_ios_test_total + 1))
"${cmc_ios_test_real_python3}" - \
  "${cmc_ios_test_tree_attestor}" \
  "${cmc_ios_test_tmp_root}" <<'PY' || {
import importlib.util
import os
import sys

script, root = sys.argv[1:]
spec = importlib.util.spec_from_file_location("cmc_ios_tree", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

source = f"{root}/cleanup-late-hardlink-source"
external = f"{root}/cleanup-late-hardlink-preserved"
os.mkdir(source)
with open(f"{source}/payload", "wb") as target:
    target.write(b"preserved-late-link")
directory = os.open(source, os.O_RDONLY | os.O_DIRECTORY)
real_quarantine = module._quarantine_bound_entry
injected = False

def late_link(parent, name, expected):
    global injected
    quarantine = real_quarantine(parent, name, expected)
    if not injected and name == "payload" and parent == directory:
        injected = True
        os.link(quarantine, external, src_dir_fd=parent)
    return quarantine

module._quarantine_bound_entry = late_link
failed = False
try:
    module._clear_directory(directory)
except OSError:
    failed = True
finally:
    module._quarantine_bound_entry = real_quarantine
    os.close(directory)
with open(external, "rb") as target:
    payload = target.read()
if not injected or not failed or payload != b"preserved-late-link":
    raise SystemExit(1)
PY
  printf 'Fixture iOS: late hardlink cleanup non fail-closed.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_total=$((cmc_ios_test_total + 1))
"${cmc_ios_test_real_python3}" - \
  "${cmc_ios_test_tree_attestor}" \
  "${cmc_ios_test_tmp_root}" <<'PY' || {
import importlib.util
import os
import sys

script, root = sys.argv[1:]
spec = importlib.util.spec_from_file_location("cmc_ios_tree", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

source = f"{root}/cleanup-hardlink-source"
external = f"{root}/cleanup-hardlink-preserved"
os.mkdir(source)
with open(external, "wb") as target:
    target.write(b"preserved")
os.link(external, f"{source}/linked")
directory = os.open(source, os.O_RDONLY | os.O_DIRECTORY)
failed = False
try:
    module._clear_directory(directory)
except OSError:
    failed = True
finally:
    os.close(directory)
with open(external, "rb") as target:
    payload = target.read()
if not failed or payload != b"preserved":
    raise SystemExit(1)
PY
  printf 'Fixture iOS: cleanup ha alterato un hardlink esterno.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_total=$((cmc_ios_test_total + 1))
"${cmc_ios_test_real_python3}" - \
  "${cmc_ios_test_tree_attestor}" \
  "${cmc_ios_test_tmp_root}" <<'PY' || {
import importlib.util
import multiprocessing
import os
import stat
import sys
import threading

script, root = sys.argv[1:]
spec = importlib.util.spec_from_file_location("cmc_ios_tree", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

parent_path = f"{root}/retention-lock-bound"
os.mkdir(parent_path)
real_flock = module.fcntl.flock
observed_directory_lock = False

def inspect_flock(descriptor, operation):
    global observed_directory_lock
    if not stat.S_ISDIR(os.fstat(descriptor).st_mode):
        raise AssertionError("replaceable pathname lock used")
    observed_directory_lock = True
    return real_flock(descriptor, operation)

module.fcntl.flock = inspect_flock
original_limit = module.MAX_RETAINED_TEMP_ROOTS
module.MAX_RETAINED_TEMP_ROOTS = 1
failed = False
try:
    module.create_temp_directory(parent_path)
    try:
        module.create_temp_directory(parent_path)
    except OSError:
        failed = True
finally:
    module.MAX_RETAINED_TEMP_ROOTS = original_limit
    module.fcntl.flock = real_flock
roots = [
    name
    for name in os.listdir(parent_path)
    if name.startswith("cmc-ios-release.")
]
if not observed_directory_lock or not failed or len(roots) != 1:
    raise SystemExit(1)

race_parent = f"{root}/retention-lock-aba"
os.mkdir(race_parent)
legacy_lock = f"{race_parent}/.cmc-ios-release.lock"
with open(legacy_lock, "wb") as target:
    target.write(b"legacy")
context = multiprocessing.get_context("fork")
start = context.Event()
results = context.Queue()

def create_once():
    start.wait()
    try:
        module.create_temp_directory(race_parent)
    except (OSError, ValueError):
        results.put(False)
    else:
        results.put(True)

stop = threading.Event()

def churn_legacy_lock():
    while not stop.is_set():
        try:
            os.unlink(legacy_lock)
        except FileNotFoundError:
            pass
        descriptor = os.open(
            legacy_lock,
            os.O_RDWR | os.O_CREAT | os.O_TRUNC,
            0o600,
        )
        os.close(descriptor)

module.MAX_RETAINED_TEMP_ROOTS = 1
workers = [context.Process(target=create_once) for _ in range(2)]
churn = threading.Thread(target=churn_legacy_lock)
churn.start()
for worker in workers:
    worker.start()
start.set()
for worker in workers:
    worker.join(10)
stop.set()
churn.join(10)
module.MAX_RETAINED_TEMP_ROOTS = original_limit
outcomes = [results.get(timeout=2) for _ in workers]
race_roots = [
    name
    for name in os.listdir(race_parent)
    if name.startswith("cmc-ios-release.")
]
if (
    any(worker.exitcode != 0 for worker in workers)
    or outcomes.count(True) != 1
    or len(race_roots) != 1
):
    raise SystemExit(1)
PY
  printf 'Fixture iOS: lock directory/cap non identity-bound.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_total=$((cmc_ios_test_total + 1))
"${cmc_ios_test_real_python3}" - \
  "${cmc_ios_test_tree_attestor}" \
  "${cmc_ios_test_tmp_root}" <<'PY' || {
import importlib.util
import os
import sys

script, root = sys.argv[1:]
spec = importlib.util.spec_from_file_location("cmc_ios_tree", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

def exercise(kind):
    source = f"{root}/retained-name-{kind}"
    os.mkdir(source)
    target = f"{source}/target"
    if kind == "file":
        with open(target, "wb") as handle:
            handle.write(b"original")
    else:
        os.mkdir(target)
        with open(f"{target}/original", "wb") as handle:
            handle.write(b"original")
    directory = os.open(source, os.O_RDONLY | os.O_DIRECTORY)
    real_quarantine = module._quarantine_bound_entry
    swapped = False
    replacement = ""

    def swap_after_quarantine(parent, name, expected):
        nonlocal swapped, replacement
        quarantine = real_quarantine(parent, name, expected)
        if not swapped and name == "target" and parent == directory:
            swapped = True
            os.rename(
                quarantine,
                f"{quarantine}-held",
                src_dir_fd=parent,
                dst_dir_fd=parent,
            )
            replacement = f"{source}/{quarantine}"
            if kind == "file":
                with open(replacement, "wb") as handle:
                    handle.write(b"replacement")
            else:
                os.mkdir(replacement)
                with open(f"{replacement}/replacement", "wb") as handle:
                    handle.write(b"replacement")
        return quarantine

    module._quarantine_bound_entry = swap_after_quarantine
    failed = False
    try:
        module._clear_directory(directory)
    except OSError:
        failed = True
    finally:
        module._quarantine_bound_entry = real_quarantine
        os.close(directory)
    if kind == "file":
        with open(replacement, "rb") as handle:
            preserved = handle.read() == b"replacement"
    else:
        with open(f"{replacement}/replacement", "rb") as handle:
            preserved = handle.read() == b"replacement"
    if not swapped or not failed or not preserved:
        raise SystemExit(1)

exercise("file")
exercise("directory")
PY
  printf 'Fixture iOS: retained-name ABA non rilevata.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_total=$((cmc_ios_test_total + 1))
"${cmc_ios_test_real_python3}" - \
  "${cmc_ios_test_tree_attestor}" \
  "${cmc_ios_test_tmp_root}" <<'PY' || {
import importlib.util
import os
import sys

script, root = sys.argv[1:]
spec = importlib.util.spec_from_file_location("cmc_ios_tree", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

for suffix in ("tab\tparent", "newline\nparent"):
    parent = f"{root}/{suffix}"
    os.mkdir(parent)
    failed = False
    try:
        module.create_temp_directory(parent)
    except ValueError:
        failed = True
    leaked = [
        name
        for name in os.listdir(parent)
        if name.startswith("cmc-ios-release.")
    ]
    if not failed or leaked:
        raise SystemExit(1)
PY
  printf 'Fixture iOS: parent record non valido crea root residue.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_total=$((cmc_ios_test_total + 1))
"${cmc_ios_test_real_python3}" - \
  "${cmc_ios_test_tree_attestor}" \
  "${cmc_ios_test_tmp_root}" <<'PY' || {
import importlib.util
import os
import sys

script, root = sys.argv[1:]
spec = importlib.util.spec_from_file_location("cmc_ios_tree", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

source = f"{root}/cleanup-child-source"
child = f"{source}/child"
detached = f"{source}/detached"
victim = f"{root}/cleanup-child-victim"
os.makedirs(child)
os.mkdir(victim)
with open(f"{child}/original", "wb") as target:
    target.write(b"original")
with open(f"{victim}/preserved", "wb") as target:
    target.write(b"victim")
directory = os.open(source, os.O_RDONLY | os.O_DIRECTORY)
real_open = module.os.open
swapped = False

def swapped_open(path, flags, mode=0o777, *, dir_fd=None):
    global swapped
    if (
        not swapped
        and path == "child"
        and dir_fd == directory
        and flags & os.O_DIRECTORY
    ):
        swapped = True
        os.rename(child, detached)
        os.rename(victim, child)
    return real_open(path, flags, mode, dir_fd=dir_fd)

module.os.open = swapped_open
failed = False
try:
    module._clear_directory(directory)
except OSError:
    failed = True
finally:
    module.os.open = real_open
    os.close(directory)
if not failed or not swapped or not os.path.isfile(f"{child}/preserved"):
    raise SystemExit(1)
PY
  printf 'Fixture iOS: cleanup child swap non identity-bound.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_total=$((cmc_ios_test_total + 1))
"${cmc_ios_test_real_python3}" - \
  "${cmc_ios_test_tree_attestor}" \
  "${cmc_ios_test_tmp_root}" <<'PY' || {
import importlib.util
import os
import sys

script, root = sys.argv[1:]
spec = importlib.util.spec_from_file_location("cmc_ios_tree", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

source = f"{root}/cleanup-terminal-source"
os.makedirs(f"{source}/child")
with open(f"{source}/child/file", "wb") as target:
    target.write(b"payload")
with open(f"{source}/regular", "wb") as target:
    target.write(b"payload")
directory = os.open(source, os.O_RDONLY | os.O_DIRECTORY)
real_rmdir = module.os.rmdir
real_unlink = module.os.unlink
calls = []

def forbidden_rmdir(*args, **kwargs):
    calls.append("rmdir")
    raise AssertionError("name-based rmdir reached")

def forbidden_unlink(*args, **kwargs):
    calls.append("unlink")
    raise AssertionError("name-based unlink reached")

module.os.rmdir = forbidden_rmdir
module.os.unlink = forbidden_unlink
try:
    module._clear_directory(directory)
finally:
    module.os.rmdir = real_rmdir
    module.os.unlink = real_unlink
    os.close(directory)
if calls:
    raise SystemExit(1)
for current_root, _, files in os.walk(source):
    for name in files:
        if os.path.getsize(os.path.join(current_root, name)) != 0:
            raise SystemExit(1)
PY
  printf 'Fixture iOS: cleanup usa ancora terminali unlink/rmdir name-based.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_total=$((cmc_ios_test_total + 1))
"${cmc_ios_test_real_python3}" - \
  "${cmc_ios_test_tree_attestor}" \
  "${cmc_ios_test_tmp_root}" <<'PY' || {
import importlib.util
import os
import sys

script, root = sys.argv[1:]
spec = importlib.util.spec_from_file_location("cmc_ios_tree", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

parent_path = f"{root}/retention-bound"
os.mkdir(parent_path)
for index in range(2):
    os.mkdir(f"{parent_path}/.cmc-cleanup-existing-{index}")
original_limit = module.MAX_RETAINED_TEMP_ROOTS
module.MAX_RETAINED_TEMP_ROOTS = 2
failed = False
try:
    module.create_temp_directory(parent_path)
except OSError:
    failed = True
finally:
    module.MAX_RETAINED_TEMP_ROOTS = original_limit
if not failed:
    raise SystemExit(1)
PY
  printf 'Fixture iOS: retention tombstone non bounded.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_component_root="${cmc_ios_test_tmp_root}/component-open"
mkdir -p "${cmc_ios_test_component_root}/real/Runner.app"
ln -s "${cmc_ios_test_component_root}/real" \
  "${cmc_ios_test_component_root}/linked"
cmc_ios_test_total=$((cmc_ios_test_total + 1))
if "${cmc_ios_test_real_python3}" "${cmc_ios_test_tree_attestor}" \
  "${cmc_ios_test_component_root}/linked/Runner.app" \
  >"${cmc_ios_test_component_root}/stdout" \
  2>"${cmc_ios_test_component_root}/stderr" || \
  [[ -s "${cmc_ios_test_component_root}/stdout" || \
    -s "${cmc_ios_test_component_root}/stderr" ]]; then
  printf 'Fixture iOS: ancestor symlink accettato dal component walk.\n' >&2
  exit 1
fi
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_tree_probe="${cmc_ios_test_tmp_root}/tree-probe"
mkdir -p "${cmc_ios_test_tree_probe}"
cmc_ios_test_tree_before="$(
  "${cmc_ios_test_real_python3}" "${cmc_ios_test_tree_attestor}" \
    "${cmc_ios_test_tree_probe}"
)"
mkdir "${cmc_ios_test_tree_probe}/empty"
cmc_ios_test_tree_with_empty="$(
  "${cmc_ios_test_real_python3}" "${cmc_ios_test_tree_attestor}" \
    "${cmc_ios_test_tree_probe}"
)"
chmod 0777 "${cmc_ios_test_tree_probe}/empty"
cmc_ios_test_tree_with_mode="$(
  "${cmc_ios_test_real_python3}" "${cmc_ios_test_tree_attestor}" \
    "${cmc_ios_test_tree_probe}"
)"
cmc_ios_test_total=$((cmc_ios_test_total + 1))
[[ "${cmc_ios_test_tree_before}" != "${cmc_ios_test_tree_with_empty}" && \
  "${cmc_ios_test_tree_with_empty}" != "${cmc_ios_test_tree_with_mode}" ]] || {
  printf 'Fixture iOS: directory vuote o mode non legati al digest.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_total=$((cmc_ios_test_total + 1))
"${cmc_ios_test_real_python3}" - \
  "${cmc_ios_test_tree_attestor}" \
  "${cmc_ios_test_tmp_root}/guard-aba" <<'PY' || {
import os
import shutil
import subprocess
import sys

script, root = sys.argv[1:]
source = f"{root}/Runner.app"
benign = f"{root}/Benign.app"
held = f"{root}/Held.app"
decoy = f"{root}/Decoy.app"
os.makedirs(source)
with open(f"{source}/value", "wb") as target:
    target.write(b"original")
shutil.copytree(source, benign)
expected = subprocess.check_output([sys.executable, script, source], text=True).strip()
process = subprocess.Popen(
    [sys.executable, script, "--guard", source, expected],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
)
assert process.stdout is not None
if process.stdout.readline() != b"IOS_ARTIFACT_GUARD_READY\n":
    raise SystemExit(1)
os.rename(source, held)
os.rename(benign, source)
os.rename(source, decoy)
os.rename(held, source)
stdout, stderr = process.communicate(b"STOP\n", timeout=5)
if process.returncode == 0 or stdout or stderr:
    raise SystemExit(1)
PY
  printf 'Fixture iOS: guard snapshot non ha respinto ABA completo.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_deep_root="${cmc_ios_test_tmp_root}/deep-tree"
mkdir -p "${cmc_ios_test_deep_root}"
cmc_ios_test_deep_cursor="${cmc_ios_test_deep_root}"
for _ in {1..65}; do
  cmc_ios_test_deep_cursor="${cmc_ios_test_deep_cursor}/d"
  mkdir "${cmc_ios_test_deep_cursor}"
done
cmc_ios_test_deep_stdout="${cmc_ios_test_tmp_root}/deep.stdout"
cmc_ios_test_deep_stderr="${cmc_ios_test_tmp_root}/deep.stderr"
cmc_ios_test_deep_destination="${cmc_ios_test_tmp_root}/DeepSnapshot.app"
cmc_ios_test_total=$((cmc_ios_test_total + 1))
if "${cmc_ios_test_real_python3}" "${cmc_ios_test_tree_attestor}" \
  --snapshot "${cmc_ios_test_deep_root}" \
  "${cmc_ios_test_deep_destination}" >"${cmc_ios_test_deep_stdout}" \
  2>"${cmc_ios_test_deep_stderr}" || \
  [[ -s "${cmc_ios_test_deep_stdout}" || -s "${cmc_ios_test_deep_stderr}" || \
    -e "${cmc_ios_test_deep_destination}" || \
    -L "${cmc_ios_test_deep_destination}" ]]; then
  printf 'Fixture iOS: profondita tree non respinta in modo redatto.\n' >&2
  exit 1
fi
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_tampered_seal="${cmc_ios_test_seal_root}/tampered.zip"
cmc_ios_test_tampered_result="$(
  "${cmc_ios_test_real_python3}" "${cmc_ios_test_tree_attestor}" \
    --seal "${cmc_ios_test_fixture_app}" "${cmc_ios_test_tampered_seal}"
)"
cmc_ios_test_tampered_sha="${cmc_ios_test_tampered_result##*,}"
[[ "${cmc_ios_test_tampered_sha}" =~ ^[0-9a-f]{64}$ ]] || {
  printf 'Fixture iOS: payload per tamper test non sigillato.\n' >&2
  exit 1
}
chmod u+w "${cmc_ios_test_tampered_seal}"
cmc_ios_test_flip_byte "${cmc_ios_test_tampered_seal}" 64
cmc_ios_test_total=$((cmc_ios_test_total + 1))
if "${cmc_ios_test_real_python3}" "${cmc_ios_test_tree_attestor}" \
  --extract "${cmc_ios_test_tampered_seal}" \
  "${cmc_ios_test_tampered_sha}" \
  "${cmc_ios_test_tmp_root}/TamperedSeal.app" \
  >"${cmc_ios_test_tmp_root}/tampered-seal.stdout" \
  2>"${cmc_ios_test_tmp_root}/tampered-seal.stderr" || \
  [[ -s "${cmc_ios_test_tmp_root}/tampered-seal.stdout" || \
    -s "${cmc_ios_test_tmp_root}/tampered-seal.stderr" ]]; then
  printf 'Fixture iOS: payload sealed alterato non respinto.\n' >&2
  exit 1
fi
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_total=$((cmc_ios_test_total + 1))
"${cmc_ios_test_real_python3}" - \
  "${cmc_ios_test_tree_attestor}" \
  "${cmc_ios_test_tmp_root}/extract-aba" <<'PY' || {
import hashlib
import importlib.util
import os
import sys

script, root = sys.argv[1:]
spec = importlib.util.spec_from_file_location("cmc_ios_tree", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

source = f"{root}/source"
alternate = f"{root}/alternate"
payload = f"{root}/payload.zip"
alternate_payload = f"{root}/alternate.zip"
destination = f"{root}/Runner.app"
os.makedirs(source)
os.makedirs(alternate)
with open(f"{source}/large", "wb") as target:
    target.write(b"A" * 262144)
with open(f"{alternate}/large", "wb") as target:
    target.write(b"B" * 262144)
_, expected = module.seal(source, payload)
module.seal(alternate, alternate_payload)
os.chmod(payload, 0o644)
with open(payload, "rb") as target:
    original = target.read()
with open(alternate_payload, "rb") as target:
    replacement = target.read()
if len(original) != len(replacement) or len(original) < 196608:
    raise SystemExit(1)
identity = os.stat(payload)
real_read = module.os.read
reads = 0

def racing_read(descriptor, length):
    global reads
    chunk = real_read(descriptor, length)
    current = os.fstat(descriptor)
    if current.st_dev == identity.st_dev and current.st_ino == identity.st_ino and chunk:
        reads += 1
        if reads == 1:
            with open(payload, "r+b") as target:
                target.write(replacement)
                target.flush()
                os.fsync(target.fileno())
        elif reads == 2:
            with open(payload, "r+b") as target:
                target.write(original)
                target.flush()
                os.fsync(target.fileno())
    return chunk

module.os.read = racing_read
failed = False
try:
    module.extract(payload, expected, destination)
except (OSError, ValueError):
    failed = True
finally:
    module.os.read = real_read
with open(payload, "rb") as target:
    current_digest = hashlib.sha256(target.read()).hexdigest()
if not failed or reads < 2 or current_digest != expected or os.path.lexists(destination):
    raise SystemExit(1)
PY
  printf 'Fixture iOS: extract ABA non respinto o output parziale.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_malicious_seal_root="${cmc_ios_test_tmp_root}/malicious-seals"
mkdir -p "${cmc_ios_test_malicious_seal_root}"
"${cmc_ios_test_real_python3}" - "${cmc_ios_test_malicious_seal_root}" <<'PY'
import os
import stat
import struct
import sys
import warnings
import zipfile

root = sys.argv[1]

def directory_info():
    info = zipfile.ZipInfo("Runner.app/")
    info.create_system = 3
    info.external_attr = ((stat.S_IFDIR | 0o755) & 0xFFFF) << 16 | 0x10
    return info

with zipfile.ZipFile(f"{root}/traversal.zip", "w", zipfile.ZIP_STORED) as archive:
    archive.writestr(directory_info(), b"")
    archive.writestr("Runner.app/../../escape", b"escape")

with zipfile.ZipFile(f"{root}/symlink.zip", "w", zipfile.ZIP_STORED) as archive:
    archive.writestr(directory_info(), b"")
    info = zipfile.ZipInfo("Runner.app/evil")
    info.create_system = 3
    info.external_attr = ((stat.S_IFLNK | 0o777) & 0xFFFF) << 16
    archive.writestr(info, b"/private/tmp")

with zipfile.ZipFile(f"{root}/compressed.zip", "w", zipfile.ZIP_DEFLATED) as archive:
    archive.writestr(directory_info(), b"")
    archive.writestr("Runner.app/payload", b"payload")

with warnings.catch_warnings():
    warnings.simplefilter("ignore", UserWarning)
    with zipfile.ZipFile(f"{root}/duplicate.zip", "w", zipfile.ZIP_STORED) as archive:
        archive.writestr(directory_info(), b"")
        archive.writestr("Runner.app/payload", b"one")
        archive.writestr("Runner.app/payload", b"two")

with zipfile.ZipFile(f"{root}/encrypted.zip", "w", zipfile.ZIP_STORED) as archive:
    archive.writestr(directory_info(), b"")
    archive.writestr("Runner.app/payload", b"payload")
encrypted_path = f"{root}/encrypted.zip"
with open(encrypted_path, "rb") as source:
    encrypted = bytearray(source.read())
cursor = 0
while True:
    cursor = encrypted.find(b"PK\x03\x04", cursor)
    if cursor < 0:
        break
    flags = struct.unpack_from("<H", encrypted, cursor + 6)[0] | 0x1
    struct.pack_into("<H", encrypted, cursor + 6, flags)
    cursor += 4
cursor = 0
while True:
    cursor = encrypted.find(b"PK\x01\x02", cursor)
    if cursor < 0:
        break
    flags = struct.unpack_from("<H", encrypted, cursor + 8)[0] | 0x1
    struct.pack_into("<H", encrypted, cursor + 8, flags)
    cursor += 4
with open(encrypted_path, "wb") as target:
    target.write(encrypted)

with zipfile.ZipFile(f"{root}/too-many.zip", "w", zipfile.ZIP_STORED) as archive:
    archive.writestr(directory_info(), b"")
    for index in range(4097):
        archive.writestr(f"Runner.app/e{index:04d}", b"")

forged_path = f"{root}/too-many-forged-count.zip"
with open(f"{root}/too-many.zip", "rb") as source:
    forged = bytearray(source.read())
eocd = forged.rfind(b"PK\x05\x06")
if eocd < 0:
    raise SystemExit(1)
struct.pack_into("<H", forged, eocd + 8, 1)
struct.pack_into("<H", forged, eocd + 10, 1)
with open(forged_path, "wb") as target:
    target.write(forged)
PY
for cmc_ios_test_malicious_name in \
  traversal symlink compressed duplicate encrypted too-many \
  too-many-forged-count; do
  cmc_ios_test_malicious_payload="${cmc_ios_test_malicious_seal_root}/${cmc_ios_test_malicious_name}.zip"
  cmc_ios_test_malicious_sha="$(
    shasum -a 256 "${cmc_ios_test_malicious_payload}" | awk '{print $1}'
  )"
  cmc_ios_test_malicious_stdout="${cmc_ios_test_malicious_seal_root}/${cmc_ios_test_malicious_name}.stdout"
  cmc_ios_test_malicious_stderr="${cmc_ios_test_malicious_seal_root}/${cmc_ios_test_malicious_name}.stderr"
  cmc_ios_test_malicious_destination="${cmc_ios_test_malicious_seal_root}/${cmc_ios_test_malicious_name}.app"
  cmc_ios_test_total=$((cmc_ios_test_total + 1))
  if "${cmc_ios_test_real_python3}" "${cmc_ios_test_tree_attestor}" \
    --extract "${cmc_ios_test_malicious_payload}" \
    "${cmc_ios_test_malicious_sha}" \
    "${cmc_ios_test_malicious_destination}" \
    >"${cmc_ios_test_malicious_stdout}" \
    2>"${cmc_ios_test_malicious_stderr}" || \
    [[ -s "${cmc_ios_test_malicious_stdout}" || \
      -s "${cmc_ios_test_malicious_stderr}" ]]; then
    printf 'Fixture iOS: seal malevolo %s non respinto.\n' \
      "${cmc_ios_test_malicious_name}" >&2
    exit 1
  fi
  [[ ! -e "${cmc_ios_test_malicious_destination}" && \
    ! -L "${cmc_ios_test_malicious_destination}" ]] || {
    printf 'Fixture iOS: extract fallito %s ha lasciato output parziale.\n' \
      "${cmc_ios_test_malicious_name}" >&2
    exit 1
  }
  cmc_ios_test_passed=$((cmc_ios_test_passed + 1))
done

cmc_ios_test_total=$((cmc_ios_test_total + 1))
"${cmc_ios_test_real_python3}" - \
  "${cmc_ios_test_tree_attestor}" \
  "${cmc_ios_test_malicious_seal_root}" <<'PY' || {
import hashlib
import importlib.util
import os
import stat
import sys

script, root = sys.argv[1:]
spec = importlib.util.spec_from_file_location("cmc_ios_tree", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

source = f"{root}/mode-source"
payload = f"{root}/mode-race.zip"
destination = f"{root}/mode-race.app"
external = f"{root}/external"
os.makedirs(f"{source}/victim")
os.mkdir(external, 0o755)
with open(f"{source}/victim/value", "wb") as target:
    target.write(b"payload")
_, expected = module.seal(source, payload)

real_open = module.os.open
opens = 0

def guarded_open(path, flags, mode=0o777, *, dir_fd=None):
    global opens
    if path == "victim" and dir_fd is not None and flags & os.O_DIRECTORY:
        opens += 1
        if opens == 2:
            os.rename(
                f"{destination}/victim",
                f"{destination}/detached",
            )
            os.symlink(external, f"{destination}/victim")
    return real_open(path, flags, mode, dir_fd=dir_fd)

module.os.open = guarded_open
failed = False
try:
    module.extract(payload, expected, destination)
except (OSError, ValueError):
    failed = True
finally:
    module.os.open = real_open
if not failed or stat.S_IMODE(os.stat(external).st_mode) != 0o755:
    raise SystemExit(1)
if os.path.lexists(destination):
    raise SystemExit(1)
PY
  printf 'Fixture iOS: extract race ha seguito symlink o lasciato output.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_total=$((cmc_ios_test_total + 1))
"${cmc_ios_test_real_python3}" - \
  "${cmc_ios_test_tree_attestor}" \
  "${cmc_ios_test_malicious_seal_root}" <<'PY' || {
import importlib.util
import os
import sys

script, root = sys.argv[1:]
spec = importlib.util.spec_from_file_location("cmc_ios_tree", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

name = "cleanup-depth.app"
destination = f"{root}/{name}"
os.mkdir(destination)
cursor = destination
for _ in range(70):
    cursor = f"{cursor}/d"
    os.mkdir(cursor)
parent = os.open(root, os.O_RDONLY | os.O_DIRECTORY)
directory = os.open(name, os.O_RDONLY | os.O_DIRECTORY, dir_fd=parent)
try:
    metadata = os.stat(name, dir_fd=parent, follow_symlinks=False)
    module._cleanup_created_directory(
        parent,
        name,
        (metadata.st_dev, metadata.st_ino),
        directory,
    )
finally:
    os.close(directory)
    os.close(parent)
if os.path.lexists(destination):
    raise SystemExit(1)
PY
  printf 'Fixture iOS: cleanup profondo non converge.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_total=$((cmc_ios_test_total + 1))
"${cmc_ios_test_real_python3}" - \
  "${cmc_ios_test_tree_attestor}" \
  "${cmc_ios_test_malicious_seal_root}" <<'PY' || {
import importlib.util
import os
import sys

script, root = sys.argv[1:]
spec = importlib.util.spec_from_file_location("cmc_ios_tree", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

collision = ".cmc-cleanup-collision"
os.mkdir(f"{root}/{collision}")
with open(f"{root}/{collision}/preserved", "wb") as target:
    target.write(b"collision")
tokens = iter(("collision", "unique", "entry"))
real_token_hex = module.secrets.token_hex
module.secrets.token_hex = lambda _: next(tokens)
name = "cleanup-collision.app"
os.mkdir(f"{root}/{name}")
with open(f"{root}/{name}/partial", "wb") as target:
    target.write(b"partial")
parent = os.open(root, os.O_RDONLY | os.O_DIRECTORY)
directory = os.open(name, os.O_RDONLY | os.O_DIRECTORY, dir_fd=parent)
try:
    metadata = os.fstat(directory)
    module._cleanup_created_directory(
        parent,
        name,
        (metadata.st_dev, metadata.st_ino),
        directory,
    )
finally:
    module.secrets.token_hex = real_token_hex
    os.close(directory)
    os.close(parent)
if os.path.lexists(f"{root}/{name}"):
    raise SystemExit(1)
if not os.path.isfile(f"{root}/{collision}/preserved"):
    raise SystemExit(1)
retained_file = f"{root}/.cmc-cleanup-unique/.cmc-cleanup-entry"
if not os.path.isfile(retained_file) or os.path.getsize(retained_file) != 0:
    raise SystemExit(1)

name = "cleanup-swap.app"
victim = "cleanup-victim"
os.mkdir(f"{root}/{name}")
with open(f"{root}/{name}/partial", "wb") as target:
    target.write(b"partial")
os.mkdir(f"{root}/{victim}")
with open(f"{root}/{victim}/preserved", "wb") as target:
    target.write(b"victim")
parent = os.open(root, os.O_RDONLY | os.O_DIRECTORY)
directory = os.open(name, os.O_RDONLY | os.O_DIRECTORY, dir_fd=parent)
real_rename = module._rename_exclusive
detached = f"{root}/{name}.detached"
swapped = False

def swapped_rename(source_directory, source, destination_directory, destination):
    global swapped
    if not swapped and source == name and destination.startswith(".cmc-cleanup-"):
        swapped = True
        os.rename(f"{root}/{name}", detached)
        os.rename(f"{root}/{victim}", f"{root}/{name}")
    return real_rename(
        source_directory,
        source,
        destination_directory,
        destination,
    )

module._rename_exclusive = swapped_rename
failed = False
try:
    metadata = os.fstat(directory)
    module._cleanup_created_directory(
        parent,
        name,
        (metadata.st_dev, metadata.st_ino),
        directory,
    )
except OSError:
    failed = True
finally:
    module._rename_exclusive = real_rename
    os.close(directory)
    os.close(parent)
if not failed or not swapped:
    raise SystemExit(1)
if not os.path.isfile(f"{root}/{name}/preserved"):
    raise SystemExit(1)
if not os.path.isfile(f"{detached}/partial"):
    raise SystemExit(1)
PY
  printf 'Fixture iOS: cleanup collision/swap non inode-bound.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))

cmc_ios_test_bundle_info_backup="${cmc_ios_test_tmp_root}/bundle-info.plist.original"
cp "${cmc_ios_test_bundle_info}" "${cmc_ios_test_bundle_info_backup}"

rm -f "${cmc_ios_test_bundle_info}"
mkfifo "${cmc_ios_test_bundle_info}"
cmc_ios_test_total=$((cmc_ios_test_total + 1))
python3 - "${cmc_ios_test_plist_canonicalizer}" \
  "${cmc_ios_test_bundle_info}" <<'PY' || {
import subprocess
import sys

canonicalizer, path = sys.argv[1:]
try:
    result = subprocess.run(
        [sys.executable, canonicalizer, "--digest", path],
        capture_output=True,
        timeout=1,
    )
except subprocess.TimeoutExpired:
    print("Fixture iOS: FIFO canonicalizer non bounded.", file=sys.stderr)
    raise SystemExit(1)
if result.returncode == 0 or result.stdout or result.stderr:
    print("Fixture iOS: FIFO accettato o non redatto.", file=sys.stderr)
    raise SystemExit(1)
PY
  printf 'Fixture iOS: FIFO canonicalizer non respinto in modo bounded.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))
cmc_ios_test_expect_failure bundle-plist-fifo-bound \
  ARTIFACT_SNAPSHOT_UNREADABLE \
  cmc_ios_test_validate_bounded \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
rm -f "${cmc_ios_test_bundle_info}"
cp "${cmc_ios_test_bundle_info_backup}" "${cmc_ios_test_bundle_info}"

python3 - "${cmc_ios_test_bundle_info}" <<'PY'
import sys

levels = 28
declarations = ['<!ENTITY cmc0 "A">']
for index in range(1, levels + 1):
    declarations.append(
        f'<!ENTITY cmc{index} "&cmc{index - 1};&cmc{index - 1};">'
    )
declaration_text = "\n".join(declarations)
payload = f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist [
{declaration_text}
]>
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>&cmc{levels};</string>
<key>CFBundlePackageType</key><string>BNDL</string>
</dict></plist>
'''
with open(sys.argv[1], "wb") as target:
    target.write(payload.encode("utf-8"))
PY
cmc_ios_test_total=$((cmc_ios_test_total + 1))
python3 - "${cmc_ios_test_plist_canonicalizer}" \
  "${cmc_ios_test_bundle_info}" <<'PY' || {
import subprocess
import sys

canonicalizer, path = sys.argv[1:]
try:
    result = subprocess.run(
        [sys.executable, canonicalizer, "--digest", path],
        capture_output=True,
        timeout=1,
    )
except subprocess.TimeoutExpired:
    print("Fixture iOS: entity XML non bounded.", file=sys.stderr)
    raise SystemExit(1)
if result.returncode == 0 or result.stdout or result.stderr:
    print("Fixture iOS: entity XML accettata o non redatta.", file=sys.stderr)
    raise SystemExit(1)
PY
  printf 'Fixture iOS: entity XML non respinta in modo bounded.\n' >&2
  exit 1
}
cmc_ios_test_passed=$((cmc_ios_test_passed + 1))
cp "${cmc_ios_test_bundle_info_backup}" "${cmc_ios_test_bundle_info}"

python3 - "${cmc_ios_test_bundle_info}" <<'PY'
import plistlib
import sys

path = sys.argv[1]
with open(path, "rb") as source:
    payload = plistlib.load(source)
payload["CMCOversizedFixture"] = "x" * 1_048_576
with open(path, "wb") as target:
    plistlib.dump(payload, target, fmt=plistlib.FMT_XML, sort_keys=True)
PY
[[ "$(/usr/bin/stat -f '%z' "${cmc_ios_test_bundle_info}")" -gt 1048576 ]] || {
  printf 'Fixture iOS: Info.plist oversized non costruito.\n' >&2
  exit 1
}
cmc_ios_test_expect_failure bundle-plist-size-bound \
  EMBEDDED_BUNDLE_DIGEST_UNREADABLE \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_bundle_info_backup}" "${cmc_ios_test_bundle_info}"

python3 - "${cmc_ios_test_bundle_info}" <<'PY'
import plistlib
import sys

shared = "A" * 16384
payload = {
    "BuildMachineOSBuild": "25G76",
    "CFBundleIdentifier": "app-links-7.2.1.app-links.resources",
    "CFBundlePackageType": "BNDL",
}
for index in range(3000):
    payload[f"CMC{index:04d}"] = shared
with open(sys.argv[1], "wb") as target:
    plistlib.dump(payload, target, fmt=plistlib.FMT_BINARY, sort_keys=True)
PY
[[ "$(/usr/bin/stat -f '%z' "${cmc_ios_test_bundle_info}")" -lt 1048576 ]] || {
  printf 'Fixture iOS: binary plist shared-reference fuori bound.\n' >&2
  exit 1
}
cmc_ios_test_expect_failure bundle-plist-shared-reference-bounded \
  EMBEDDED_BUNDLE_DIGEST_MISMATCH \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_bundle_info_backup}" "${cmc_ios_test_bundle_info}"

python3 - "${cmc_ios_test_bundle_info}" <<'PY'
import plistlib
import sys

payload = {
    "BuildMachineOSBuild": "25G76",
    "CFBundleIdentifier": "app-links-7.2.1.app-links.resources",
    "CFBundlePackageType": "BNDL",
}
for index in range(20000):
    payload[f"CMC{index:05d}"] = index
with open(sys.argv[1], "wb") as target:
    plistlib.dump(payload, target, fmt=plistlib.FMT_BINARY, sort_keys=True)
PY
[[ "$(/usr/bin/stat -f '%z' "${cmc_ios_test_bundle_info}")" -lt 1048576 ]] || {
  printf 'Fixture iOS: binary plist object-count fuori input bound.\n' >&2
  exit 1
}
cmc_ios_test_expect_failure bundle-plist-object-count-bound \
  EMBEDDED_BUNDLE_DIGEST_UNREADABLE \
  cmc_ios_test_validate \
  --app "${cmc_ios_test_fixture_app}" \
  --archive "${cmc_ios_test_fixture_archive}"
cp "${cmc_ios_test_bundle_info_backup}" "${cmc_ios_test_bundle_info}"

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
