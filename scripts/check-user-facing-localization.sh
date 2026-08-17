#!/usr/bin/env bash
set -euo pipefail

cmc_repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${cmc_repo_root}"

cmc_ui_roots=(
  lib/app/design_system
  lib/features
)

cmc_patterns=(
  "\\bText\\s*\\(\\s*(?:const\\s+)?(?:r)?(?:\"[^\"$\\n]+\"|'[^'$\\n]+')"
  "\\bTextSpan\\s*\\([^)]*\\btext\\s*:\\s*(?:const\\s+)?(?:r)?(?:\"[^\"$\\n]+\"|'[^'$\\n]+')"
  "\\b(?:message|title|label|tooltip|semanticsLabel|semanticLabel|labelText|hintText|helperText|errorText|barrierLabel)\\s*:\\s*(?:const\\s+)?(?:r)?(?:\"[^\"$\\n]+\"|'[^'$\\n]+')"
)

cmc_violations=""
for cmc_pattern in "${cmc_patterns[@]}"; do
  set +e
  cmc_matches="$(
    rg --pcre2 --multiline --line-number --glob '*.dart' \
      --glob '!**/*.g.dart' --glob '!**/generated/**' \
      "${cmc_pattern}" "${cmc_ui_roots[@]}" 2>&1
  )"
  cmc_status=$?
  set -e

  if [[ ${cmc_status} -eq 0 ]]; then
    cmc_violations+="${cmc_matches}"$'\n'
  elif [[ ${cmc_status} -ne 1 ]]; then
    printf 'LOCALIZATION_SCAN_ERROR: rg exited with %s\n%s\n' \
      "${cmc_status}" "${cmc_matches}" >&2
    exit 2
  fi
done

if [[ -n "${cmc_violations}" ]]; then
  printf '%s\n' 'LOCALIZATION_SCAN_FAIL: direct user-facing string literals detected.' >&2
  printf '%s' "${cmc_violations}" >&2
  exit 1
fi

printf '%s\n' 'LOCALIZATION_SCAN_PASS: no direct user-facing string literals detected.'
