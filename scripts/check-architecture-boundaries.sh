#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${CMC_ARCH_REPO_ROOT:-}" ]]; then
  cmc_arch_repo_root="${CMC_ARCH_REPO_ROOT}"
else
  cmc_arch_repo_root="$(git rev-parse --show-toplevel)"
fi
cmc_arch_master="${cmc_arch_repo_root}/docs/MASTER-PLAN.md"
cmc_arch_adr008="${cmc_arch_repo_root}/docs/DECISIONS/ADR-008-semantic-design-system.md"
cmc_arch_adr009="${cmc_arch_repo_root}/docs/DECISIONS/ADR-009-parallel-catalog-authentication-workstreams.md"
cmc_arch_adr010="${cmc_arch_repo_root}/docs/DECISIONS/ADR-010-storefront-contract-ownership.md"
cmc_arch_contract="${cmc_arch_repo_root}/docs/ARCHITECTURE/STOREFRONT-INTEGRATION-CONTRACT.md"
cmc_arch_ownership="${cmc_arch_repo_root}/docs/ARCHITECTURE/CROSS-REPO-OWNERSHIP.md"
cmc_arch_data_boundary="${cmc_arch_repo_root}/docs/ARCHITECTURE/STOREFRONT-DATA-BOUNDARY.md"
cmc_arch_quality="${cmc_arch_repo_root}/docs/QUALITY-GATES.md"
cmc_arch_system="${cmc_arch_repo_root}/docs/ARCHITECTURE/SYSTEM-CONTEXT.md"
cmc_arch_mobile="${cmc_arch_repo_root}/docs/ARCHITECTURE/MOBILE-ARCHITECTURE.md"
cmc_arch_auth="${cmc_arch_repo_root}/docs/ARCHITECTURE/AUTH-BOUNDARY.md"
cmc_arch_task002="${cmc_arch_repo_root}/docs/TASKS/TASK-002-product-scope-branding-design-system.md"
cmc_arch_app_config="${cmc_arch_repo_root}/lib/core/config/app_config.dart"
cmc_arch_storefront_repository="${cmc_arch_repo_root}/lib/features/storefront/data/supabase_storefront_repository.dart"
cmc_arch_storefront_provider="${cmc_arch_repo_root}/lib/features/storefront/application/storefront_providers.dart"
cmc_arch_storefront_sources="${cmc_arch_repo_root}/lib/features/storefront"
cmc_arch_home_sources="${cmc_arch_repo_root}/lib/features/home"
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

cmc_arch_unique_table_cell() {
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
      BEGIN {
        found = 0
      }
      {
        task = trim($2)
        gsub(/`/, "", task)
        if (task == cmc_arch_task) {
          value = trim($cmc_arch_column)
          gsub(/`/, "", value)
          print value
          found++
        }
      }
      END {
        if (found != 1) {
          exit 1
        }
      }
    ' "${cmc_arch_file}"
}

cmc_arch_marker_table_cell() {
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
      BEGIN {
        in_table = 0
        found = 0
      }
      $0 == "<!-- CMC-WORKSTREAM-DEPENDENCIES:BEGIN -->" {
        in_table = 1
        next
      }
      $0 == "<!-- CMC-WORKSTREAM-DEPENDENCIES:END -->" {
        in_table = 0
        next
      }
      in_table {
        task = trim($2)
        gsub(/`/, "", task)
        if (task == cmc_arch_task) {
          value = trim($cmc_arch_column)
          gsub(/`/, "", value)
          print value
          found++
        }
      }
      END {
        if (found != 1) {
          exit 1
        }
      }
    ' "${cmc_arch_file}"
}

cmc_arch_normalize_dependencies() {
  printf '%s' "$1" |
    tr ',' '\n' |
    sed 's/[[:space:]`]//g; /^$/d' |
    LC_ALL=C sort -u |
    tr '\n' ',' |
    sed 's/,$//'
}

cmc_arch_has_task012_data_backed_record() {
  local cmc_arch_file="$1"

  awk '
    function trim(value) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      return value
    }
    function flush_record() {
      normalized = tolower(record)
      table_task = ""
      if (record ~ /^\|/) {
        split(record, table_cells, "|")
        table_task = tolower(trim(table_cells[2]))
        gsub(/`/, "", table_task)
      }
      if (index(normalized, "data-backed")) {
        if (record ~ /^\|/ &&
            table_task ~ /^task-[0-9][0-9][0-9]$/) {
          if (table_task == "task-012") {
            violation = 1
          }
        } else if (index(normalized, "task-012")) {
          violation = 1
        }
      }
      record = ""
    }
    BEGIN {
      record = ""
      violation = 0
    }
    /^[[:space:]]*$/ {
      flush_record()
      next
    }
    /^\|/ {
      flush_record()
      record = $0
      flush_record()
      next
    }
    /^#{1,6}[[:space:]]/ {
      flush_record()
      next
    }
    /^[-*][[:space:]]/ {
      flush_record()
      record = $0
      next
    }
    {
      if (record == "") {
        record = $0
      } else {
        record = record " " $0
      }
    }
    END {
      flush_record()
      if (violation) {
        exit 1
      }
    }
  ' "${cmc_arch_file}"
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
cmc_arch_require_count \
  "${cmc_arch_contract}" \
  "| Business decision owner |" \
  1 \
  "un solo record tassonomico business decision owner nel contratto"
cmc_arch_require_count \
  "${cmc_arch_contract}" \
  "| Control plane |" \
  1 \
  "un solo record tassonomico control plane nel contratto"
cmc_arch_require_count \
  "${cmc_arch_contract}" \
  "| Writer/enforcer |" \
  1 \
  "un solo record tassonomico writer/enforcer nel contratto"
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
cmc_arch_require_count \
  "${cmc_arch_adr010}" \
  "| Business decision owner |" \
  1 \
  "un solo record tassonomico business decision owner in ADR-010"
cmc_arch_require_count \
  "${cmc_arch_adr010}" \
  "| Control plane |" \
  1 \
  "un solo record tassonomico control plane in ADR-010"
cmc_arch_require_count \
  "${cmc_arch_adr010}" \
  "| Writer/enforcer |" \
  1 \
  "un solo record tassonomico writer/enforcer in ADR-010"
cmc_arch_forbid_literal \
  "${cmc_arch_system}" \
  "Admin è il decision owner del control plane" \
  "un sistema non sostituisce il business decision owner"
cmc_arch_require_literal \
  "${cmc_arch_system}" \
  "I ruoli business autorizzati sono i decision owner dei rispettivi domini e usano Admin" \
  "decision owner business nel system context"
cmc_arch_require_literal \
  "${cmc_arch_system}" \
  "Console come control plane. Il repository Admin è l'authority versionata per migrations," \
  "control plane distinto nel system context"
cmc_arch_require_literal \
  "${cmc_arch_data_boundary}" \
  "| Verità | Contenuto | Business decision owner | Writer/enforcer | Consumer pubblico |" \
  "tassonomia owner/writer nel data boundary"

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
cmc_arch_require_literal \
  "${cmc_arch_auth}" \
  '`detectSessionInUri:false`' \
  "observer SDK Auth disabilitato"
cmc_arch_require_literal \
  "${cmc_arch_auth}" \
  "SharedPreferences contiene soltanto il marker booleano di installazione e due tombstone" \
  "token e verifier fuori da SharedPreferences, marker non sensibili ammessi"
cmc_arch_require_literal \
  "${cmc_arch_auth}" \
  "Ogni purge scrive per primo un journal file di" \
  "journal persistente documentato nel boundary Auth"
cmc_arch_require_literal \
  "${cmc_arch_mobile}" \
  "Se tutti e tre i canali persistenti e il delete falliscono insieme" \
  "tre canali cleanup documentati nella mobile architecture"
cmc_arch_require_literal \
  "${cmc_arch_auth}" \
  "Una sessione valida prova soltanto l'identità Supabase." \
  "session identity distinta da authorization"
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

cmc_arch_task012_sources=(
  "${cmc_arch_repo_root}"/docs/ARCHITECTURE/*.md
  "${cmc_arch_repo_root}"/docs/DECISIONS/*.md
  "${cmc_arch_master}"
  "${cmc_arch_task002}"
)

for cmc_arch_task012_source in "${cmc_arch_task012_sources[@]}"; do
  if ! cmc_arch_has_task012_data_backed_record "${cmc_arch_task012_source}"; then
    printf 'Scope TASK-012 contraddittorio in un record normativo (%s)\n' \
      "${cmc_arch_task012_source}" >&2
    cmc_arch_violation_count=$((cmc_arch_violation_count + 1))
  fi
done

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
    decision_owner = tolower(trim($4))
    if (decision_owner ~ /admin console/ ||
        decision_owner ~ /admin server/ ||
        decision_owner ~ /admin\/server/ ||
        decision_owner ~ /supabase/ ||
        decision_owner ~ /control plane/) {
      invalid = 1
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
  $0 == "| Verità | Contenuto | Business decision owner | Writer/enforcer | Consumer pubblico |" {
    in_matrix = 1
    next
  }
  in_matrix && /^\|---/ {
    next
  }
  in_matrix && /^\|/ {
    if (NF != 7) {
      invalid = 1
      next
    }
    truth = trim($2)
    if (truth == "" || seen[truth]++) {
      invalid = 1
    }
    for (column = 3; column <= 6; column++) {
      if (trim($column) == "") {
        invalid = 1
      }
    }
    decision_owner = tolower(trim($4))
    if (decision_owner ~ /admin console/ ||
        decision_owner ~ /admin server/ ||
        decision_owner ~ /admin\/server/ ||
        decision_owner ~ /supabase/ ||
        decision_owner ~ /control plane/) {
      invalid = 1
    }
    row_count++
    next
  }
  in_matrix {
    in_matrix = 0
  }
  END {
    if (row_count != 4 || invalid) {
      exit 1
    }
  }
' "${cmc_arch_data_boundary}"; then
  printf 'Matrice dei livelli di verità incompleta, duplicata o ambigua (%s)\n' \
    "${cmc_arch_data_boundary}" >&2
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

cmc_arch_require_count \
  "${cmc_arch_app_config}" \
  "const String.fromEnvironment('STOREFRONT_SHOP_SLUG')" \
  1 \
  "un solo input compile-time Storefront shop slug"
cmc_arch_require_count \
  "${cmc_arch_storefront_repository}" \
  "function: 'storefront_home_v1'" \
  1 \
  "un solo RPC Home v1 allowlisted nel repository"
cmc_arch_require_count \
  "${cmc_arch_storefront_repository}" \
  "function: 'storefront_categories_v1'" \
  1 \
  "un solo RPC Categories v1 allowlisted nel repository"
cmc_arch_require_count \
  "${cmc_arch_storefront_repository}" \
  "function: 'storefront_catalog_v1'" \
  1 \
  "un solo RPC Catalog v1 allowlisted nel repository"
cmc_arch_require_count \
  "${cmc_arch_storefront_repository}" \
  "function: 'storefront_search_v1'" \
  1 \
  "un solo RPC Search v1 allowlisted nel repository"
cmc_arch_require_count \
  "${cmc_arch_storefront_repository}" \
  "function: 'storefront_product_detail_v1'" \
  1 \
  "un solo RPC Product Detail v1 allowlisted nel repository"
cmc_arch_require_count \
  "${cmc_arch_storefront_provider}" \
  ".rpc(function, params: parameters)" \
  1 \
  "un solo adapter Supabase RPC confinato"

if grep -REn --include='*.dart' '\.from[[:space:]]*\(' \
  "${cmc_arch_storefront_sources}" "${cmc_arch_home_sources}" >/dev/null; then
  printf 'Boundary Storefront violato: query diretta a tabella/view.\n' >&2
  cmc_arch_violation_count=$((cmc_arch_violation_count + 1))
fi
if grep -REn --include='*.dart' '\.storage([.]|\b)' \
  "${cmc_arch_storefront_sources}" "${cmc_arch_home_sources}" >/dev/null; then
  printf 'Boundary Storefront violato: accesso Storage diretto.\n' >&2
  cmc_arch_violation_count=$((cmc_arch_violation_count + 1))
fi
if grep -REn --include='*.dart' '\.rpc[[:space:]]*\(' \
  "${cmc_arch_storefront_sources}" "${cmc_arch_home_sources}" |
  grep -Fv -- "${cmc_arch_storefront_provider}:" >/dev/null; then
  printf 'Boundary Storefront violato: RPC fuori dall adapter allowlisted.\n' >&2
  cmc_arch_violation_count=$((cmc_arch_violation_count + 1))
fi

if ! awk -F '|' '
  function trim(value) {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
    return value
  }
  BEGIN {
    in_table = 0
    row_count = 0
    invalid = 0
  }
  $0 == "<!-- CMC-WORKSTREAM-DEPENDENCIES:BEGIN -->" {
    in_table = 1
    next
  }
  $0 == "<!-- CMC-WORKSTREAM-DEPENDENCIES:END -->" {
    in_table = 0
    next
  }
  in_table && $0 == "| Task | Dipendenze dirette |" {
    next
  }
  in_table && /^\|---/ {
    next
  }
  in_table && /^\|[[:space:]]*TASK-[0-9][0-9][0-9][[:space:]]*\|/ {
    if (NF != 4) {
      invalid = 1
      next
    }
    task = trim($2)
    gsub(/`/, "", task)
    dependencies = trim($3)
    gsub(/`/, "", dependencies)
    if (seen[task]++ || dependencies == "") {
      invalid = 1
    }
    if (task !~ /^TASK-(005|006|007|008|009|010|011|012|020|021|022)$/) {
      invalid = 1
    }
    dependency_count = split(dependencies, dependency_list, ",")
    for (dependency_index = 1;
         dependency_index <= dependency_count;
         dependency_index++) {
      dependency = trim(dependency_list[dependency_index])
      if (dependency !~ /^TASK-[0-9][0-9][0-9]$/) {
        invalid = 1
      }
    }
    row_count++
    next
  }
  in_table && /^\|/ {
    invalid = 1
  }
  END {
    if (in_table || row_count != 11 || invalid) {
      exit 1
    }
  }
' "${cmc_arch_adr009}"; then
  printf 'Tabella DAG ADR-009 fuori marker, duplicata o non valida (%s)\n' \
    "${cmc_arch_adr009}" >&2
  cmc_arch_violation_count=$((cmc_arch_violation_count + 1))
fi

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
  cmc_arch_master_dependencies=""
  cmc_arch_adr_dependencies=""
  cmc_arch_row_error=0

  if ! cmc_arch_master_dependencies="$(
    cmc_arch_unique_table_cell "${cmc_arch_master}" "${cmc_arch_task}" 5
  )"; then
    cmc_arch_row_error=1
  fi
  if ! cmc_arch_adr_dependencies="$(
    cmc_arch_marker_table_cell "${cmc_arch_adr009}" "${cmc_arch_task}" 3
  )"; then
    cmc_arch_row_error=1
  fi

  cmc_arch_master_normalized="$(
    cmc_arch_normalize_dependencies "${cmc_arch_master_dependencies}"
  )"
  cmc_arch_adr_normalized="$(
    cmc_arch_normalize_dependencies "${cmc_arch_adr_dependencies}"
  )"

  if [[ "${cmc_arch_row_error}" -ne 0 ||
    -z "${cmc_arch_master_normalized}" ||
    -z "${cmc_arch_adr_normalized}" ||
    "${cmc_arch_master_normalized}" != "${cmc_arch_adr_normalized}" ]]; then
    printf 'DAG ADR/Master incoerente o non univoco per %s\n' \
      "${cmc_arch_task}" >&2
    cmc_arch_violation_count=$((cmc_arch_violation_count + 1))
  fi
done

if [[ "${cmc_arch_violation_count}" -ne 0 ]]; then
  printf 'Controllo boundary architetturali fallito: %d violazione/i.\n' \
    "${cmc_arch_violation_count}" >&2
  exit 1
fi

printf 'Boundary architetturali coerenti: ownership, TASK-012, Auth, DAG e RPC Storefront Home/Categories/Catalog/Search/Detail verificati.\n'
