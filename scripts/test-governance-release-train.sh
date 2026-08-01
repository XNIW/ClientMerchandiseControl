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
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-006" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-010" \
    "${cmc_target}/docs/TASKS"
  cp "${cmc_test_repo_root}/README.md" "${cmc_target}/README.md"
  cp "${cmc_test_repo_root}/docs/MASTER-PLAN.md" "${cmc_target}/docs/MASTER-PLAN.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-005-storefront-schema-rls-migration-ownership.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-005/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-005/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-006-storefront-catalog-projection.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-006/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-006/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-010-storefront-catalog-query-contract.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-010/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-010/README.md"

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

cmc_case="$(cmc_fixture valid)"
cmc_expect_pass valid "${cmc_case}"

cmc_case="$(cmc_fixture duplicate-active)"
sed -i.bak \
  's/| TASK-007 | Admin Console: pubblicazione e gestione visibilità prodotti | TODO |/| TASK-007 | Admin Console: pubblicazione e gestione visibilità prodotti | ACTIVE |/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_expect_fail duplicate-active "${cmc_case}"

cmc_case="$(cmc_fixture wrong-active)"
sed -i.bak \
  's/| TASK-010 | Catalog query contract, search, pagination, fixtures e contract test | ACTIVE |/| TASK-010 | Catalog query contract, search, pagination, fixtures e contract test | TODO |/; s/| TASK-007 | Admin Console: pubblicazione e gestione visibilità prodotti | TODO |/| TASK-007 | Admin Console: pubblicazione e gestione visibilità prodotti | ACTIVE |/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_expect_fail wrong-active "${cmc_case}"

cmc_case="$(cmc_fixture premature-done)"
sed -i.bak \
  's/| TASK-007 | Admin Console: pubblicazione e gestione visibilità prodotti | TODO |/| TASK-007 | Admin Console: pubblicazione e gestione visibilità prodotti | DONE |/' \
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
cmc_expect_pass validated-pending "${cmc_case}"

cmc_case="$(cmc_fixture validated-file-missing)"
mv \
  "${cmc_case}/docs/TASKS/TASK-005-storefront-schema-rls-migration-ownership.md" \
  "${cmc_case}/TASK-005-missing.md"
cmc_expect_fail validated-file-missing "${cmc_case}"

printf 'Governance release train: 8/8 fixture PASS.\n'
