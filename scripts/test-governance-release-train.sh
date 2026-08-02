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
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-007" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-008" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-009" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-010" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-013" \
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
    "${cmc_test_repo_root}/docs/TASKS/TASK-007-admin-storefront-publications.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-007/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-007/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-008-admin-storefront-pricing-promotions.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-008/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-008/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-009-storefront-public-image-pipeline.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-009/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-009/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-010-storefront-catalog-query-contract.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-010/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-010/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-013-home-storefront-data-backed.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-013/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-013/README.md"

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
  's/| TASK-014 | Categorie e griglia catalogo con caricamento immagini | TODO |/| TASK-014 | Categorie e griglia catalogo con caricamento immagini | ACTIVE |/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_expect_fail duplicate-active "${cmc_case}"

cmc_case="$(cmc_fixture wrong-active)"
sed -i.bak \
  's/- \*\*Task attivo\*\*: TASK-013/- **Task attivo**: TASK-008/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_expect_fail wrong-active "${cmc_case}"

cmc_case="$(cmc_fixture premature-done)"
sed -i.bak \
  's/| TASK-013 | Home e prodotti\/promozioni in evidenza | ACTIVE |/| TASK-013 | Home e prodotti\/promozioni in evidenza | DONE |/' \
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
