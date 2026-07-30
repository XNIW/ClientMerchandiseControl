#!/usr/bin/env bash
set -euo pipefail

cmc_expected_flutter_version="3.44.8"
cmc_expected_flutter_revision="058e0af2c2b57e369d905a03ac9748b0ebf543c6"
cmc_flutter_executable=""

if [[ -n "${FLUTTER_ROOT:-}" ]]; then
  cmc_flutter_executable="${FLUTTER_ROOT%/}/bin/flutter"
  if [[ ! -x "${cmc_flutter_executable}" ]]; then
    printf 'FLUTTER_ROOT non contiene un eseguibile Flutter valido: %s\n' \
      "${cmc_flutter_executable}" >&2
    return 127 2>/dev/null || exit 127
  fi
elif command -v flutter >/dev/null 2>&1; then
  cmc_flutter_executable="$(command -v flutter)"
else
  cmc_fallback_root="${HOME}/develop/flutter"
  cmc_flutter_executable="${cmc_fallback_root}/bin/flutter"
  if [[ ! -x "${cmc_flutter_executable}" ]]; then
    printf 'Flutter non trovato in FLUTTER_ROOT, PATH o %s.\n' \
      "${cmc_fallback_root}" >&2
    return 127 2>/dev/null || exit 127
  fi
fi

cmc_flutter_metadata="$("${cmc_flutter_executable}" --version --machine)"
cmc_actual_flutter_version="$(
  printf '%s\n' "${cmc_flutter_metadata}" |
    sed -nE 's/^[[:space:]]*"frameworkVersion":[[:space:]]*"([^"]+)".*/\1/p'
)"
cmc_actual_flutter_revision="$(
  printf '%s\n' "${cmc_flutter_metadata}" |
    sed -nE 's/^[[:space:]]*"frameworkRevision":[[:space:]]*"([^"]+)".*/\1/p'
)"
cmc_resolved_flutter_root="$(
  printf '%s\n' "${cmc_flutter_metadata}" |
    sed -nE 's/^[[:space:]]*"flutterRoot":[[:space:]]*"([^"]+)".*/\1/p'
)"

if [[ -z "${cmc_actual_flutter_version}" ||
  -z "${cmc_actual_flutter_revision}" ||
  -z "${cmc_resolved_flutter_root}" ]]; then
  printf 'Impossibile leggere versione, revisione o root di Flutter.\n' >&2
  return 1 2>/dev/null || exit 1
fi

if [[ "${cmc_actual_flutter_version}" != "${cmc_expected_flutter_version}" ]]; then
  printf 'Versione Flutter non ammessa: attesa %s, trovata %s.\n' \
    "${cmc_expected_flutter_version}" "${cmc_actual_flutter_version}" >&2
  return 1 2>/dev/null || exit 1
fi

if [[ "${cmc_actual_flutter_revision}" != "${cmc_expected_flutter_revision}" ]]; then
  printf 'Revisione Flutter non ammessa: attesa %s, trovata %s.\n' \
    "${cmc_expected_flutter_revision}" "${cmc_actual_flutter_revision}" >&2
  return 1 2>/dev/null || exit 1
fi

export FLUTTER_ROOT="${cmc_resolved_flutter_root}"
export PATH="${FLUTTER_ROOT}/bin:${PATH}"

printf 'Flutter %s (%s) verificato.\n' \
  "${cmc_actual_flutter_version}" "${cmc_actual_flutter_revision}"
