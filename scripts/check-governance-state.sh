#!/usr/bin/env bash
set -euo pipefail

cmc_repo_root="$(git rev-parse --show-toplevel)"
cmc_master_plan="${cmc_repo_root}/docs/MASTER-PLAN.md"
cmc_readme="${cmc_repo_root}/README.md"
cmc_violation_count=0

cmc_field() {
  local cmc_file="$1"
  local cmc_label="$2"

  sed -n "s/^- \\*\\*${cmc_label}\\*\\*: //p" "${cmc_file}" |
    head -n 1 |
    tr -d '`'
}

cmc_compare() {
  local cmc_label="$1"
  local cmc_expected="$2"
  local cmc_actual="$3"
  local cmc_source="$4"

  if [[ -z "${cmc_expected}" || -z "${cmc_actual}" ||
    "${cmc_expected}" != "${cmc_actual}" ]]; then
    printf '%s incoerente: Master Plan=%q, %s=%q\n' \
      "${cmc_label}" "${cmc_expected}" "${cmc_source}" "${cmc_actual}" >&2
    cmc_violation_count=$((cmc_violation_count + 1))
  fi
}

cmc_active_task="$(cmc_field "${cmc_master_plan}" "Task attivo")"
cmc_task_status="$(cmc_field "${cmc_master_plan}" "Stato task")"
cmc_phase="$(cmc_field "${cmc_master_plan}" "Fase")"
cmc_indicator="$(cmc_field "${cmc_master_plan}" "Indicatore")"

cmc_compare \
  "Task attivo" \
  "${cmc_active_task}" \
  "$(cmc_field "${cmc_readme}" "Task attivo")" \
  "README"
cmc_compare \
  "Stato task" \
  "${cmc_task_status}" \
  "$(cmc_field "${cmc_readme}" "Stato task")" \
  "README"
cmc_compare \
  "Fase" \
  "${cmc_phase}" \
  "$(cmc_field "${cmc_readme}" "Fase")" \
  "README"
cmc_compare \
  "Indicatore" \
  "${cmc_indicator}" \
  "$(cmc_field "${cmc_readme}" "Indicatore")" \
  "README"

cmc_active_task_normalized="$(
  printf '%s' "${cmc_active_task}" | tr '[:upper:]' '[:lower:]'
)"

if [[ "${cmc_active_task_normalized}" != "nessuno" ]]; then
  cmc_task_relative="$(cmc_field "${cmc_master_plan}" "File task")"
  cmc_task_file="${cmc_repo_root}/${cmc_task_relative}"

  if [[ ! -f "${cmc_task_file}" ]]; then
    printf 'File task attivo assente: %s\n' "${cmc_task_relative}" >&2
    cmc_violation_count=$((cmc_violation_count + 1))
  else
    cmc_compare \
      "Stato task" \
      "${cmc_task_status}" \
      "$(cmc_field "${cmc_task_file}" "Stato")" \
      "task attivo"
    cmc_compare \
      "Fase" \
      "${cmc_phase}" \
      "$(cmc_field "${cmc_task_file}" "Fase")" \
      "task attivo"
    cmc_compare \
      "Indicatore/Handoff" \
      "${cmc_indicator}" \
      "$(cmc_field "${cmc_task_file}" "Handoff")" \
      "task attivo"

    cmc_evidence_relative="$(cmc_field "${cmc_task_file}" "Evidence directory")"
    cmc_evidence_readme="${cmc_repo_root}/${cmc_evidence_relative%/}/README.md"

    if [[ ! -f "${cmc_evidence_readme}" ]]; then
      printf 'README evidence assente: %s\n' "${cmc_evidence_readme}" >&2
      cmc_violation_count=$((cmc_violation_count + 1))
    else
      cmc_snapshot="$(
        sed -n '/^Snapshot di handoff:$/{
          n
          s/^`//
          s/`\.$//
          p
          q
        }' "${cmc_evidence_readme}"
      )"
      cmc_expected_snapshot="${cmc_task_status} / ${cmc_phase} / ${cmc_indicator}"

      if [[ "${cmc_snapshot}" != "${cmc_expected_snapshot}" ]]; then
        printf 'Snapshot evidence incoerente: atteso=%q, ricevuto=%q\n' \
          "${cmc_expected_snapshot}" "${cmc_snapshot}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      fi
    fi
  fi
fi

if [[ "${cmc_violation_count}" -ne 0 ]]; then
  printf 'Controllo governance fallito: %d violazione/i.\n' \
    "${cmc_violation_count}" >&2
  exit 1
fi

printf 'Governance coerente: %s / %s / %s / %s.\n' \
  "${cmc_active_task}" "${cmc_task_status}" "${cmc_phase}" "${cmc_indicator}"
