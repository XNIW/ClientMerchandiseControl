#!/usr/bin/env bash
set -euo pipefail

cmc_test_repo_root="$(git rev-parse --show-toplevel)"
cmc_test_tmp="$(mktemp -d "${TMPDIR:-/tmp}/cmc-governance.XXXXXX")"
trap 'rm -rf "${cmc_test_tmp}"' EXIT

cmc_fixture() {
  local cmc_name="$1"
  local cmc_target="${cmc_test_tmp}/${cmc_name}"

  mkdir -p \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-005" \
    "${cmc_target}/docs/TASKS"
  cp "${cmc_test_repo_root}/README.md" "${cmc_target}/README.md"
  cp "${cmc_test_repo_root}/docs/MASTER-PLAN.md" "${cmc_target}/docs/MASTER-PLAN.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-005-storefront-schema-rls-migration-ownership.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-005/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-005/README.md"

  printf '%s\n' "${cmc_target}"
}

cmc_expect_pass() {
  local cmc_name="$1"
  local cmc_target="$2"

  if ! CMC_GOVERNANCE_REPO_ROOT="${cmc_target}" \
    bash "${cmc_test_repo_root}/scripts/check-governance-state.sh" >/dev/null; then
    printf 'Fixture %s doveva passare.\n' "${cmc_name}" >&2
    exit 1
  fi
}

cmc_expect_fail() {
  local cmc_name="$1"
  local cmc_target="$2"

  if CMC_GOVERNANCE_REPO_ROOT="${cmc_target}" \
    bash "${cmc_test_repo_root}/scripts/check-governance-state.sh" >/dev/null 2>&1; then
    printf 'Fixture %s doveva fallire.\n' "${cmc_name}" >&2
    exit 1
  fi
}

cmc_mark_task_005_validated() {
  local cmc_target="$1"

  for cmc_file in "${cmc_target}/docs/MASTER-PLAN.md" "${cmc_target}/README.md"; do
    sed -i.bak \
      -e 's/- \*\*Task attivo\*\*: TASK-005/- **Task attivo**: nessuno/' \
      -e 's#- \*\*File task\*\*: docs/TASKS/TASK-005-storefront-schema-rls-migration-ownership.md#- **File task**: non applicabile#' \
      -e 's/- \*\*Stato task\*\*: ACTIVE/- **Stato task**: non applicabile/' \
      -e 's/- \*\*Fase\*\*: EXECUTION/- **Fase**: non applicabile/' \
      -e 's/- \*\*Indicatore\*\*: CODEX_PLANNING_APPROVED_TO_EXECUTION/- **Indicatore**: STOREFRONT_V1_MILESTONE_CHECKPOINT_VALIDATED/' \
      "${cmc_file}"
    rm "${cmc_file}.bak"
  done
  sed -i.bak \
    's/| TASK-005 | Supabase Storefront schema, RLS, grants e migration ownership | ACTIVE |/| TASK-005 | Supabase Storefront schema, RLS, grants e migration ownership | VALIDATED_PENDING_INTEGRATED_REVIEW |/' \
    "${cmc_target}/docs/MASTER-PLAN.md"
  rm "${cmc_target}/docs/MASTER-PLAN.md.bak"
  sed -i.bak \
    's/- \*\*Stato\*\*: ACTIVE/- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW/' \
    "${cmc_target}/docs/TASKS/TASK-005-storefront-schema-rls-migration-ownership.md"
  rm "${cmc_target}/docs/TASKS/TASK-005-storefront-schema-rls-migration-ownership.md.bak"
}

cmc_case="$(cmc_fixture valid)"
cmc_expect_pass valid "${cmc_case}"

cmc_case="$(cmc_fixture duplicate-active)"
sed -i.bak \
  's/| TASK-006 | Storefront catalog projection e aggiornamento dal dominio operativo | TODO |/| TASK-006 | Storefront catalog projection e aggiornamento dal dominio operativo | ACTIVE |/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_expect_fail duplicate-active "${cmc_case}"

cmc_case="$(cmc_fixture wrong-active)"
sed -i.bak \
  's/| TASK-005 | Supabase Storefront schema, RLS, grants e migration ownership | ACTIVE |/| TASK-005 | Supabase Storefront schema, RLS, grants e migration ownership | TODO |/; s/| TASK-006 | Storefront catalog projection e aggiornamento dal dominio operativo | TODO |/| TASK-006 | Storefront catalog projection e aggiornamento dal dominio operativo | ACTIVE |/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_expect_fail wrong-active "${cmc_case}"

cmc_case="$(cmc_fixture premature-done)"
sed -i.bak \
  's/| TASK-006 | Storefront catalog projection e aggiornamento dal dominio operativo | TODO |/| TASK-006 | Storefront catalog projection e aggiornamento dal dominio operativo | DONE |/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_expect_fail premature-done "${cmc_case}"

cmc_case="$(cmc_fixture invalid-train-state)"
sed -i.bak 's/- \*\*Stato release train\*\*: EXECUTION/- **Stato release train**: UNKNOWN/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_expect_fail invalid-train-state "${cmc_case}"

cmc_case="$(cmc_fixture active-during-review)"
sed -i.bak \
  's/- \*\*Stato release train\*\*: EXECUTION/- **Stato release train**: INTEGRATED_REVIEW/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_expect_fail active-during-review "${cmc_case}"

cmc_case="$(cmc_fixture validated-pending)"
cmc_mark_task_005_validated "${cmc_case}"
cmc_expect_pass validated-pending "${cmc_case}"

cmc_case="$(cmc_fixture validated-file-missing)"
cmc_mark_task_005_validated "${cmc_case}"
mv \
  "${cmc_case}/docs/TASKS/TASK-005-storefront-schema-rls-migration-ownership.md" \
  "${cmc_case}/TASK-005-missing.md"
cmc_expect_fail validated-file-missing "${cmc_case}"

printf 'Governance release train: 8/8 fixture PASS.\n'
