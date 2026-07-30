#!/usr/bin/env bash
set -euo pipefail

cmc_workflow_count=0
cmc_violation_count=0
cmc_uses_pattern='uses:[[:space:]]*([^[:space:]#]+)'
cmc_sha_pattern='^[0-9a-fA-F]{40}$'

while IFS= read -r cmc_workflow; do
  cmc_workflow_count=$((cmc_workflow_count + 1))
  cmc_line_number=0

  while IFS= read -r cmc_line || [[ -n "${cmc_line}" ]]; do
    cmc_line_number=$((cmc_line_number + 1))

    if [[ "${cmc_line}" =~ ${cmc_uses_pattern} ]]; then
      cmc_action_ref="${BASH_REMATCH[1]}"
      cmc_action_ref="${cmc_action_ref#\"}"
      cmc_action_ref="${cmc_action_ref%\"}"
      cmc_action_ref="${cmc_action_ref#\'}"
      cmc_action_ref="${cmc_action_ref%\'}"

      if [[ "${cmc_action_ref}" == ./* ]]; then
        continue
      fi

      cmc_action_pin="${cmc_action_ref##*@}"
      if [[ "${cmc_action_ref}" != *@* ||
        ! "${cmc_action_pin}" =~ ${cmc_sha_pattern} ]]; then
        printf '%s:%d: action non fissata a uno SHA completo: %s\n' \
          "${cmc_workflow}" "${cmc_line_number}" "${cmc_action_ref}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      fi
    fi
  done <"${cmc_workflow}"

  if grep -Eq \
    "^[[:space:]]*cache:[[:space:]]*(['\"]?true['\"]?)[[:space:]]*(#.*)?$" \
    "${cmc_workflow}"; then
    printf '%s: cache action-provided non ammessa: può introdurre action annidate mutabili.\n' \
      "${cmc_workflow}" >&2
    cmc_violation_count=$((cmc_violation_count + 1))
  fi
done < <(
  find .github/workflows -type f \
    \( -name '*.yml' -o -name '*.yaml' \) -print | LC_ALL=C sort
)

if [[ "${cmc_workflow_count}" -eq 0 ]]; then
  printf 'Nessun workflow GitHub Actions trovato.\n' >&2
  exit 1
fi

if [[ "${cmc_violation_count}" -ne 0 ]]; then
  printf 'Controllo action pin fallito: %d violazione/i.\n' \
    "${cmc_violation_count}" >&2
  exit 1
fi

printf 'Action pin verificati in %d workflow.\n' "${cmc_workflow_count}"
