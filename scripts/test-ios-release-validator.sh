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
PY
for cmc_ios_test_malicious_name in \
  traversal symlink compressed duplicate encrypted too-many; do
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
