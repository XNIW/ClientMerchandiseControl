#!/usr/bin/env bash
set -euo pipefail

cmc_security_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_security_default_root="$(git -C "${cmc_security_script_dir}" rev-parse --show-toplevel)"
cmc_security_repo_root="${CMC_SECURITY_REPO_ROOT:-${cmc_security_default_root}}"
cmc_security_violation_count=0
cmc_security_tracked_count=0
cmc_security_artifact_file_count=0
cmc_security_artifacts=()

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --artifact)
      shift
      if [[ "$#" -eq 0 ]]; then
        printf 'Security scan: valore mancante per --artifact.\n' >&2
        exit 1
      fi
      cmc_security_artifacts+=("$1")
      ;;
    *)
      printf 'Security scan: argomento non supportato.\n' >&2
      exit 1
      ;;
  esac
  shift
done

if ! git -C "${cmc_security_repo_root}" rev-parse --is-inside-work-tree \
  >/dev/null 2>&1; then
  printf 'Security scan non eseguibile: repository Git non valido.\n' >&2
  exit 1
fi

cmc_security_secret_value_pattern='(AKIA[0-9A-Z]{16}|github_pat_[0-9A-Za-z_]{20,}|gh[pousr]_[0-9A-Za-z]{30,}|sk-(proj|live|prod)-[0-9A-Za-z_-]{20,}|sk_(live|prod)_[0-9A-Za-z]{20,}|sb_secret_[0-9A-Za-z]{24,}|AIza[0-9A-Za-z_-]{30,}|GOCSPX-[0-9A-Za-z_-]{20,})'
cmc_security_source_secret_pattern="(${cmc_security_secret_value_pattern}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----)"
cmc_security_jwt_pattern='eyJ[0-9A-Za-z_-]{8,}\.[0-9A-Za-z_-]{8,}\.[0-9A-Za-z_-]{8,}'

cmc_security_contains_service_role_jwt() {
  local cmc_security_file="$1"
  local cmc_security_token
  local cmc_security_payload
  local cmc_security_padding

  while IFS= read -r cmc_security_token; do
    cmc_security_payload="${cmc_security_token#*.}"
    cmc_security_payload="${cmc_security_payload%%.*}"
    case "$((${#cmc_security_payload} % 4))" in
      0) cmc_security_padding='' ;;
      2) cmc_security_padding='==' ;;
      3) cmc_security_padding='=' ;;
      *) continue ;;
    esac
    if printf '%s' "${cmc_security_payload}${cmc_security_padding}" \
      | tr '_-' '/+' \
      | openssl base64 -d -A 2>/dev/null \
      | LC_ALL=C grep -Eq \
        '"role"[[:space:]]*:[[:space:]]*"service_role"'; then
      return 0
    fi
  done < <(
    LC_ALL=C grep -aEo -- "${cmc_security_jwt_pattern}" \
      "${cmc_security_file}" 2>/dev/null || true
  )
  return 1
}

cmc_security_file_has_prohibited_value() {
  local cmc_security_file="$1"
  local cmc_security_pattern="$2"
  if LC_ALL=C grep -aEq -- "${cmc_security_pattern}" \
    "${cmc_security_file}"; then
    return 0
  fi
  cmc_security_contains_service_role_jwt "${cmc_security_file}"
}

while IFS= read -r -d '' cmc_security_path; do
  if [[ ! -f "${cmc_security_repo_root}/${cmc_security_path}" ]]; then
    continue
  fi
  cmc_security_tracked_count=$((cmc_security_tracked_count + 1))

  case "${cmc_security_path}" in
    config/*.local.json | */config/*.local.json | \
      .env | .env.* | */.env | */.env.* | \
      build/* | */build/* | \
      coverage/* | */coverage/* | \
      *.jks | *.keystore | *.p8 | *.p12 | *.pfx | *.mobileprovision | \
      android/key.properties | \
      android/app/google-services.json | \
      ios/Runner/GoogleService-Info.plist)
      case "${cmc_security_path}" in
        .env.example | .env.*.example | \
          */.env.example | */.env.*.example)
          ;;
        *)
          printf '%q: path locale, credenziale o artifact non ammesso in Git.\n' \
            "${cmc_security_path}" >&2
          cmc_security_violation_count=$((cmc_security_violation_count + 1))
          ;;
      esac
      ;;
  esac

  case "${cmc_security_path}" in
    scripts/check-client-security.sh | scripts/test-client-security-scan.sh)
      continue
      ;;
  esac

  if cmc_security_file_has_prohibited_value \
    "${cmc_security_repo_root}/${cmc_security_path}" \
    "${cmc_security_source_secret_pattern}"; then
    printf '%q: valore secret-shaped rilevato; contenuto non stampato.\n' \
      "${cmc_security_path}" >&2
    cmc_security_violation_count=$((cmc_security_violation_count + 1))
  fi
done < <(git -C "${cmc_security_repo_root}" ls-files -z)

if [[ "${cmc_security_tracked_count}" -eq 0 ]]; then
  printf 'Security scan non eseguibile: nessun file tracciato.\n' >&2
  exit 1
fi

if [[ "${#cmc_security_artifacts[@]}" -gt 0 ]]; then
  cmc_security_tmp_parent="${TMPDIR:-/tmp}"
  cmc_security_tmp_parent="${cmc_security_tmp_parent%/}"
  cmc_security_tmp_root="$(
    mktemp -d "${cmc_security_tmp_parent}/cmc-client-artifacts.XXXXXX"
  )"
  cmc_security_cleanup_artifacts() {
    case "${cmc_security_tmp_root}" in
      "${cmc_security_tmp_parent}"/cmc-client-artifacts.*)
        rm -rf -- "${cmc_security_tmp_root}"
        ;;
      *)
        printf 'Cleanup artifact security rifiutato per path inatteso.\n' >&2
        ;;
    esac
  }
  trap cmc_security_cleanup_artifacts EXIT

  cmc_security_artifact_index=0
  for cmc_security_artifact in "${cmc_security_artifacts[@]}"; do
    if [[ ! -e "${cmc_security_artifact}" ]]; then
      printf 'Security scan artifact: target assente.\n' >&2
      exit 1
    fi
    cmc_security_artifact_index=$((cmc_security_artifact_index + 1))
    cmc_security_scan_root="${cmc_security_artifact}"
    case "${cmc_security_artifact}" in
      *.apk | *.zip)
        cmc_security_scan_root="${cmc_security_tmp_root}/${cmc_security_artifact_index}"
        mkdir -p "${cmc_security_scan_root}"
        if ! unzip -qq "${cmc_security_artifact}" \
          -d "${cmc_security_scan_root}"; then
          printf 'Security scan artifact: archivio non leggibile.\n' >&2
          exit 1
        fi
        ;;
    esac

    if [[ -f "${cmc_security_scan_root}" ]]; then
      cmc_security_artifact_files=("${cmc_security_scan_root}")
    else
      cmc_security_artifact_files=()
      while IFS= read -r -d '' cmc_security_artifact_file; do
        cmc_security_artifact_files+=("${cmc_security_artifact_file}")
      done < <(find "${cmc_security_scan_root}" -type f -print0)
    fi

    for cmc_security_artifact_file in \
      "${cmc_security_artifact_files[@]}"; do
      cmc_security_artifact_file_count=$((cmc_security_artifact_file_count + 1))
      if cmc_security_file_has_prohibited_value \
        "${cmc_security_artifact_file}" \
        "${cmc_security_secret_value_pattern}"; then
        printf 'Artifact client: valore secret-shaped rilevato; contenuto non stampato.\n' \
          >&2
        cmc_security_violation_count=$((cmc_security_violation_count + 1))
      fi
    done
  done

  if [[ "${cmc_security_artifact_file_count}" -eq 0 ]]; then
    printf 'Security scan artifact: nessun file verificabile.\n' >&2
    exit 1
  fi
fi

if [[ "${cmc_security_violation_count}" -ne 0 ]]; then
  printf 'Security scan client fallito: %d violazione/i; nessun valore esposto.\n' \
    "${cmc_security_violation_count}" >&2
  exit 1
fi

printf 'Security scan client: %d file tracciati, zero secret/config/artifact vietati.\n' \
  "${cmc_security_tracked_count}"
if [[ "${cmc_security_artifact_file_count}" -gt 0 ]]; then
  printf 'Security scan artifact: %d file, nessun secret privilegiato rilevato.\n' \
    "${cmc_security_artifact_file_count}"
fi
