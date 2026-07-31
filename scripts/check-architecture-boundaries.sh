#!/usr/bin/env bash
set -euo pipefail

cmc_arch_repo_root="$(git rev-parse --show-toplevel)"
cmc_arch_master="${cmc_arch_repo_root}/docs/MASTER-PLAN.md"
cmc_arch_adr009="${cmc_arch_repo_root}/docs/DECISIONS/ADR-009-parallel-catalog-authentication-workstreams.md"
cmc_arch_adr010="${cmc_arch_repo_root}/docs/DECISIONS/ADR-010-storefront-contract-ownership.md"
cmc_arch_contract="${cmc_arch_repo_root}/docs/ARCHITECTURE/STOREFRONT-INTEGRATION-CONTRACT.md"
cmc_arch_ownership="${cmc_arch_repo_root}/docs/ARCHITECTURE/CROSS-REPO-OWNERSHIP.md"
cmc_arch_quality="${cmc_arch_repo_root}/docs/QUALITY-GATES.md"
cmc_arch_system="${cmc_arch_repo_root}/docs/ARCHITECTURE/SYSTEM-CONTEXT.md"
cmc_arch_mobile="${cmc_arch_repo_root}/docs/ARCHITECTURE/MOBILE-ARCHITECTURE.md"
cmc_arch_violation_count=0

cmc_arch_require_literal() {
  local cmc_arch_file="$1"
  local cmc_arch_literal="$2"
  local cmc_arch_label="$3"

  if ! grep -Fq -- "${cmc_arch_literal}" "${cmc_arch_file}"; then
    printf 'Boundary architetturale assente: %s (%s)\n' \
      "${cmc_arch_label}" "${cmc_arch_file}" >&2
    cmc_arch_violation_count=$((cmc_arch_violation_count + 1))
  fi
}

cmc_arch_forbid_literal() {
  local cmc_arch_file="$1"
  local cmc_arch_literal="$2"
  local cmc_arch_label="$3"

  if grep -Fq -- "${cmc_arch_literal}" "${cmc_arch_file}"; then
    printf 'Boundary architetturale vietato: %s (%s)\n' \
      "${cmc_arch_label}" "${cmc_arch_file}" >&2
    cmc_arch_violation_count=$((cmc_arch_violation_count + 1))
  fi
}

cmc_arch_require_count() {
  local cmc_arch_file="$1"
  local cmc_arch_literal="$2"
  local cmc_arch_expected_count="$3"
  local cmc_arch_label="$4"
  local cmc_arch_actual_count

  cmc_arch_actual_count="$(
    grep -Fc -- "${cmc_arch_literal}" "${cmc_arch_file}" || true
  )"

  if [[ "${cmc_arch_actual_count}" -ne "${cmc_arch_expected_count}" ]]; then
    printf 'Cardinalità boundary errata: %s (%s)\n' \
      "${cmc_arch_label}" "${cmc_arch_file}" >&2
    cmc_arch_violation_count=$((cmc_arch_violation_count + 1))
  fi
}

cmc_arch_table_cell() {
  local cmc_arch_file="$1"
  local cmc_arch_task="$2"
  local cmc_arch_column="$3"

  awk -F '|' \
    -v cmc_arch_task="${cmc_arch_task}" \
    -v cmc_arch_column="${cmc_arch_column}" '
      function trim(value) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        return value
      }
      {
        task = trim($2)
        gsub(/`/, "", task)
        if (task == cmc_arch_task) {
          value = trim($cmc_arch_column)
          gsub(/`/, "", value)
          print value
          exit
        }
      }
    ' "${cmc_arch_file}"
}

cmc_arch_normalize_dependencies() {
  printf '%s' "$1" | tr -d '[:space:]`'
}

cmc_arch_require_literal \
  "${cmc_arch_contract}" \
  "| Business decision owner | ruoli business autorizzati definiti per dominio |" \
  "decision owner distinto dal control plane"
cmc_arch_require_literal \
  "${cmc_arch_contract}" \
  "| Control plane | Admin Console |" \
  "control plane esplicito"
cmc_arch_require_literal \
  "${cmc_arch_contract}" \
  "| Writer/enforcer | Admin server writer; Supabase runtime/enforcement |" \
  "writer/enforcer esplicito"
cmc_arch_forbid_literal \
  "${cmc_arch_contract}" \
  "| Business decision owner | Admin Console |" \
  "Admin Console non è il decision owner business"
cmc_arch_require_literal \
  "${cmc_arch_ownership}" \
  "Admin Console è il control plane: rende operative decisioni assunte dai ruoli business" \
  "tassonomia decision owner/control plane"
cmc_arch_require_literal \
  "${cmc_arch_ownership}" \
  "layer logico e artifact server machine-readable possono avere owner distinti" \
  "contract ownership esplicita per layer"
cmc_arch_require_literal \
  "${cmc_arch_adr010}" \
  "| Business decision owner | ruoli business autorizzati definiti per dominio |" \
  "authority business ADR-010"
cmc_arch_require_literal \
  "${cmc_arch_adr010}" \
  "| Control plane | Admin Console |" \
  "control plane ADR-010"
cmc_arch_require_literal \
  "${cmc_arch_adr010}" \
  "| Writer/enforcer | Admin server writer; Supabase runtime/enforcement |" \
  "writer/enforcer ADR-010"
cmc_arch_forbid_literal \
  "${cmc_arch_system}" \
  "Admin è il decision owner del control plane" \
  "un sistema non sostituisce il business decision owner"

cmc_arch_forbid_literal \
  "${cmc_arch_quality}" \
  "un solo decision owner, writer," \
  "cardinalità uno sui ruoli cooperativi"
cmc_arch_require_literal \
  "${cmc_arch_quality}" \
  "decision owner business non ambigui; elenca separatamente i writer, projector e" \
  "gate ownership compatibile con set autorizzati"

cmc_arch_forbid_literal \
  "${cmc_arch_system}" \
  "shell cliente data-backed" \
  "TASK-012 non possiede UI commerciali data-backed"
cmc_arch_forbid_literal \
  "${cmc_arch_mobile}" \
  "TASK-012 per shell cliente data-backed" \
  "TASK-012 non possiede UI commerciali data-backed"
cmc_arch_require_literal \
  "${cmc_arch_system}" \
  "| shell cliente guest/data-safe, stati readiness e baseline accessibile | TASK-012 |" \
  "scope TASK-012 nel system context"
cmc_arch_require_literal \
  "${cmc_arch_mobile}" \
  "TASK-012 per shell cliente guest/data-safe, stati readiness e baseline accessibile;" \
  "scope TASK-012 nella mobile architecture"

if ! awk -F '|' '
  function trim(value) {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
    return value
  }
  BEGIN {
    in_matrix = 0
    row_count = 0
    invalid = 0
  }
  $0 == "| Dominio | Domain owner | Business decision owner | Writer autorizzati | Projector | Consumer | Contract owner | Change owner |" {
    in_matrix = 1
    next
  }
  in_matrix && /^\|---/ {
    next
  }
  in_matrix && /^\|/ {
    if (NF != 10) {
      invalid = 1
      next
    }
    domain = trim($2)
    if (domain == "" || seen[domain]++) {
      invalid = 1
    }
    for (column = 3; column <= 9; column++) {
      if (trim($column) == "") {
        invalid = 1
      }
    }
    row_count++
    next
  }
  in_matrix {
    in_matrix = 0
  }
  END {
    if (row_count != 10 || invalid) {
      exit 1
    }
  }
' "${cmc_arch_ownership}"; then
  printf 'Matrice ownership incompleta, duplicata o ambigua (%s)\n' \
    "${cmc_arch_ownership}" >&2
  cmc_arch_violation_count=$((cmc_arch_violation_count + 1))
fi

cmc_arch_require_count \
  "${cmc_arch_adr009}" \
  "<!-- CMC-WORKSTREAM-DEPENDENCIES:BEGIN -->" \
  1 \
  "marker iniziale DAG"
cmc_arch_require_count \
  "${cmc_arch_adr009}" \
  "<!-- CMC-WORKSTREAM-DEPENDENCIES:END -->" \
  1 \
  "marker finale DAG"

cmc_arch_tasks=(
  TASK-005
  TASK-006
  TASK-007
  TASK-008
  TASK-009
  TASK-010
  TASK-011
  TASK-012
  TASK-020
  TASK-021
  TASK-022
)

for cmc_arch_task in "${cmc_arch_tasks[@]}"; do
  cmc_arch_master_dependencies="$(
    cmc_arch_table_cell "${cmc_arch_master}" "${cmc_arch_task}" 5
  )"
  cmc_arch_adr_dependencies="$(
    cmc_arch_table_cell "${cmc_arch_adr009}" "${cmc_arch_task}" 3
  )"

  cmc_arch_master_normalized="$(
    cmc_arch_normalize_dependencies "${cmc_arch_master_dependencies}"
  )"
  cmc_arch_adr_normalized="$(
    cmc_arch_normalize_dependencies "${cmc_arch_adr_dependencies}"
  )"

  if [[ -z "${cmc_arch_master_normalized}" ||
    -z "${cmc_arch_adr_normalized}" ||
    "${cmc_arch_master_normalized}" != "${cmc_arch_adr_normalized}" ]]; then
    printf 'DAG ADR/Master incoerente per %s: Master=%q ADR=%q\n' \
      "${cmc_arch_task}" \
      "${cmc_arch_master_dependencies}" \
      "${cmc_arch_adr_dependencies}" >&2
    cmc_arch_violation_count=$((cmc_arch_violation_count + 1))
  fi
done

if [[ "${cmc_arch_violation_count}" -ne 0 ]]; then
  printf 'Controllo boundary architetturali fallito: %d violazione/i.\n' \
    "${cmc_arch_violation_count}" >&2
  exit 1
fi

printf 'Boundary architetturali coerenti: ownership, TASK-012 e 11 edge DAG verificati.\n'
