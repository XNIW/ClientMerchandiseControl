#!/usr/bin/env bash
set -euo pipefail

cmc_security_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_security_default_root="$(git -C "${cmc_security_script_dir}" rev-parse --show-toplevel)"
cmc_security_repo_root="${CMC_SECURITY_REPO_ROOT:-${cmc_security_default_root}}"
cmc_security_violation_count=0
cmc_security_tracked_count=0

if ! git -C "${cmc_security_repo_root}" rev-parse --is-inside-work-tree \
  >/dev/null 2>&1; then
  printf 'Security scan non eseguibile: repository Git non valido.\n' >&2
  exit 1
fi

cmc_security_secret_pattern='(AKIA[0-9A-Z]{16}|github_pat_[0-9A-Za-z_]{20,}|gh[pousr]_[0-9A-Za-z]{30,}|sk-(proj|live|prod)-[0-9A-Za-z_-]{20,}|sk_(live|prod)_[0-9A-Za-z]{20,}|sb_secret_[0-9A-Za-z]{24,}|AIza[0-9A-Za-z_-]{30,}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----)'

while IFS= read -r cmc_security_path; do
  if [[ ! -f "${cmc_security_repo_root}/${cmc_security_path}" ]]; then
    continue
  fi
  cmc_security_tracked_count=$((cmc_security_tracked_count + 1))

  case "${cmc_security_path}" in
    config/*.local.json | \
      .env | .env.* | \
      build/* | */build/* | \
      coverage/* | */coverage/* | \
      *.jks | *.keystore | *.p8 | *.p12 | *.pfx | *.mobileprovision | \
      android/key.properties | \
      android/app/google-services.json | \
      ios/Runner/GoogleService-Info.plist)
      case "${cmc_security_path}" in
        .env.example | .env.*.example)
          ;;
        *)
          printf '%s: path locale, credenziale o artifact non ammesso in Git.\n' \
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

  if LC_ALL=C grep -IEq -- "${cmc_security_secret_pattern}" \
    "${cmc_security_repo_root}/${cmc_security_path}"; then
    printf '%s: valore secret-shaped rilevato; contenuto non stampato.\n' \
      "${cmc_security_path}" >&2
    cmc_security_violation_count=$((cmc_security_violation_count + 1))
  fi
done < <(git -C "${cmc_security_repo_root}" ls-files)

if [[ "${cmc_security_tracked_count}" -eq 0 ]]; then
  printf 'Security scan non eseguibile: nessun file tracciato.\n' >&2
  exit 1
fi

if [[ "${cmc_security_violation_count}" -ne 0 ]]; then
  printf 'Security scan client fallito: %d violazione/i; nessun valore esposto.\n' \
    "${cmc_security_violation_count}" >&2
  exit 1
fi

printf 'Security scan client: %d file tracciati, zero secret/config/artifact vietati.\n' \
  "${cmc_security_tracked_count}"
