#!/usr/bin/env bash
set -euo pipefail

cmc_fixture_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_fixture_repo_root="$(git -C "${cmc_fixture_script_dir}" rev-parse --show-toplevel)"
cmc_fixture_validator="${cmc_fixture_script_dir}/check-architecture-boundaries.sh"
cmc_fixture_tmp_parent="${TMPDIR:-/tmp}"
cmc_fixture_tmp_parent="${cmc_fixture_tmp_parent%/}"
cmc_fixture_root="$(
  mktemp -d "${cmc_fixture_tmp_parent}/cmc-arch-fixtures.XXXXXX"
)"
cmc_fixture_total=0
cmc_fixture_rejected=0

cmc_fixture_cleanup() {
  case "${cmc_fixture_root}" in
    "${cmc_fixture_tmp_parent}"/cmc-arch-fixtures.*)
      rm -rf -- "${cmc_fixture_root}"
      ;;
    *)
      printf 'Cleanup fixture rifiutato per path inatteso.\n' >&2
      ;;
  esac
}

trap cmc_fixture_cleanup EXIT

cmc_fixture_prepare() {
  local cmc_fixture_name="$1"
  local cmc_fixture_path="${cmc_fixture_root}/${cmc_fixture_name}"

  mkdir -p "${cmc_fixture_path}/docs/TASKS" \
    "${cmc_fixture_path}/lib/core" \
    "${cmc_fixture_path}/lib/features"
  cp -R "${cmc_fixture_repo_root}/docs/ARCHITECTURE" \
    "${cmc_fixture_path}/docs/"
  cp -R "${cmc_fixture_repo_root}/docs/DECISIONS" \
    "${cmc_fixture_path}/docs/"
  cp "${cmc_fixture_repo_root}/docs/MASTER-PLAN.md" \
    "${cmc_fixture_path}/docs/MASTER-PLAN.md"
  cp "${cmc_fixture_repo_root}/docs/QUALITY-GATES.md" \
    "${cmc_fixture_path}/docs/QUALITY-GATES.md"
  cp \
    "${cmc_fixture_repo_root}/docs/TASKS/TASK-002-product-scope-branding-design-system.md" \
    "${cmc_fixture_path}/docs/TASKS/TASK-002-product-scope-branding-design-system.md"
  cp -R "${cmc_fixture_repo_root}/lib/core/config" \
    "${cmc_fixture_path}/lib/core/"
  cp -R "${cmc_fixture_repo_root}/lib/features/storefront" \
    "${cmc_fixture_path}/lib/features/"
  cp -R "${cmc_fixture_repo_root}/lib/features/home" \
    "${cmc_fixture_path}/lib/features/"

  printf '%s\n' "${cmc_fixture_path}"
}

cmc_fixture_replace_literal() {
  local cmc_fixture_file="$1"
  local cmc_fixture_old="$2"
  local cmc_fixture_new="$3"
  local cmc_fixture_output="${cmc_fixture_file}.tmp"

  if ! grep -Fq -- "${cmc_fixture_old}" "${cmc_fixture_file}"; then
    printf 'Fixture non preparabile: literal sorgente assente.\n' >&2
    exit 1
  fi

  sed "s#${cmc_fixture_old}#${cmc_fixture_new}#" \
    "${cmc_fixture_file}" >"${cmc_fixture_output}"
  if cmp -s "${cmc_fixture_file}" "${cmc_fixture_output}"; then
    printf 'Fixture non preparabile: mutazione inefficace.\n' >&2
    exit 1
  fi
  mv "${cmc_fixture_output}" "${cmc_fixture_file}"
}

cmc_fixture_expect_rejection() {
  local cmc_fixture_path="$1"

  cmc_fixture_total=$((cmc_fixture_total + 1))
  if CMC_ARCH_REPO_ROOT="${cmc_fixture_path}" \
    bash "${cmc_fixture_validator}" >/dev/null 2>&1; then
    printf 'Fixture negativa accettata inaspettatamente: %s\n' \
      "${cmc_fixture_path##*/}" >&2
  else
    cmc_fixture_rejected=$((cmc_fixture_rejected + 1))
  fi
}

bash "${cmc_fixture_validator}"

cmc_fixture_owner_path="$(cmc_fixture_prepare invalid-business-owner)"
cmc_fixture_replace_literal \
  "${cmc_fixture_owner_path}/docs/ARCHITECTURE/STOREFRONT-DATA-BOUNDARY.md" \
  "Shop owner/manager o ruolo commerciale Admin autorizzato" \
  "Admin Console"
cmc_fixture_expect_rejection "${cmc_fixture_owner_path}"

cmc_fixture_task012_path="$(cmc_fixture_prepare invalid-task012-scope)"
cmc_fixture_replace_literal \
  "${cmc_fixture_task012_path}/docs/DECISIONS/ADR-008-semantic-design-system.md" \
  "guest/data-safe" \
  "data-backed"
cmc_fixture_expect_rejection "${cmc_fixture_task012_path}"

cmc_fixture_task002_path="$(cmc_fixture_prepare invalid-task002-decision)"
cmc_fixture_replace_literal \
  "${cmc_fixture_task002_path}/docs/TASKS/TASK-002-product-scope-branding-design-system.md" \
  "TASK-012 resta owner della shell guest/data-safe" \
  "TASK-012 resta owner della shell data-backed"
cmc_fixture_expect_rejection "${cmc_fixture_task002_path}"

cmc_fixture_dag_path="$(cmc_fixture_prepare duplicate-dag-row)"
cmc_fixture_dag_file="${cmc_fixture_dag_path}/docs/DECISIONS/ADR-009-parallel-catalog-authentication-workstreams.md"
if ! grep -Fq -- "| TASK-005 | TASK-003, TASK-004 |" "${cmc_fixture_dag_file}"; then
  printf 'Fixture DAG non preparabile: riga sorgente assente.\n' >&2
  exit 1
fi
awk '
  {
    print
  }
  $0 == "| TASK-005 | TASK-003, TASK-004 |" {
    print "| TASK-005 | TASK-004 |"
  }
' "${cmc_fixture_dag_file}" >"${cmc_fixture_dag_file}.tmp"
mv "${cmc_fixture_dag_file}.tmp" "${cmc_fixture_dag_file}"
cmc_fixture_expect_rejection "${cmc_fixture_dag_path}"

cmc_fixture_quality_path="$(cmc_fixture_prepare invalid-quality-cardinality)"
cmc_fixture_replace_literal \
  "${cmc_fixture_quality_path}/docs/QUALITY-GATES.md" \
  "decision owner business non ambigui; elenca separatamente i writer, projector e" \
  "un solo decision owner, writer, projector e"
cmc_fixture_expect_rejection "${cmc_fixture_quality_path}"

cmc_fixture_direct_table_path="$(cmc_fixture_prepare invalid-storefront-direct-table)"
cmc_fixture_replace_literal \
  "${cmc_fixture_direct_table_path}/lib/features/storefront/application/storefront_providers.dart" \
  "Supabase.instance.client.rpc(function, params: parameters)" \
  "Supabase.instance.client.from('inventory_products').select()"
cmc_fixture_expect_rejection "${cmc_fixture_direct_table_path}"

cmc_fixture_storage_path="$(cmc_fixture_prepare invalid-storefront-storage-access)"
cmc_fixture_replace_literal \
  "${cmc_fixture_storage_path}/lib/features/storefront/application/storefront_providers.dart" \
  "Supabase.instance.client.rpc(function, params: parameters)" \
  "Supabase.instance.client.storage.from('product-images').list()"
cmc_fixture_expect_rejection "${cmc_fixture_storage_path}"

if [[ "${cmc_fixture_rejected}" -ne "${cmc_fixture_total}" ]]; then
  printf 'Fixture negative respinte: %d/%d.\n' \
    "${cmc_fixture_rejected}" "${cmc_fixture_total}" >&2
  exit 1
fi

printf 'Fixture negative architetturali respinte: %d/%d.\n' \
  "${cmc_fixture_rejected}" "${cmc_fixture_total}"
