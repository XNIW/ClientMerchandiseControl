#!/usr/bin/env bash
set -euo pipefail

cmc_test_repo_root="$(git rev-parse --show-toplevel)"
cmc_test_tmp="$(mktemp -d "${TMPDIR:-/tmp}/cmc-governance.XXXXXX")"
trap 'rm -rf "${cmc_test_tmp}"' EXIT
cmc_assertion_count=0
cmc_repository_task_status="$(
  sed -n 's/^- \*\*Stato task\*\*: //p' \
    "${cmc_test_repo_root}/docs/MASTER-PLAN.md" | head -n 1
)"
cmc_fixture_revision='HEAD'
if [[ "${cmc_repository_task_status}" == 'DONE' ]]; then
  cmc_closeout_transition="$(
    git log -1 --format='%H' -S'- **Stato task**: BLOCKED' -- \
      docs/MASTER-PLAN.md
  )"
  if [[ -z "${cmc_closeout_transition}" ]]; then
    printf 'Transizione closeout TASK-040 non trovata.\n' >&2
    exit 1
  fi
  cmc_fixture_revision="${cmc_closeout_transition}^"
fi
cmc_fixture_task_status="$(
  git show "${cmc_fixture_revision}:docs/MASTER-PLAN.md" | \
    sed -n 's/^- \*\*Stato task\*\*: //p' | head -n 1
)"

source "${cmc_test_repo_root}/scripts/lib/governance_path_policy.sh"
source "${cmc_test_repo_root}/scripts/lib/governance_review_role_policy.sh"

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
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-014" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-015" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-016" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-017" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-018" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-019" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-021" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-022" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-023" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-024" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-025" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-026" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-027" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-028" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-029" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-030" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-031" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-032" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-033" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-034" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-035" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-036" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-037" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-038" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-039" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-040" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-043" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-044" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-045" \
    "${cmc_target}/docs/TASKS" \
    "${cmc_target}/docs/releases"
  cp "${cmc_test_repo_root}/README.md" "${cmc_target}/README.md"
  cp "${cmc_test_repo_root}/docs/MASTER-PLAN.md" "${cmc_target}/docs/MASTER-PLAN.md"
  cp "${cmc_test_repo_root}/docs/AI_WORKLOG.md" \
    "${cmc_target}/docs/AI_WORKLOG.md"
  cp \
    "${cmc_test_repo_root}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md" \
    "${cmc_target}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
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
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-014-catalog-categories-grid.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-014/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-014/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-015-search-filters-sorting.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-015/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-015/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-016-product-detail-commercial-availability.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-016/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-016/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-017-offline-catalog-cache-refresh-invalidation.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-017/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-017/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-018-favorites-sharing-product-deep-links.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-018/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-018/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-019-catalog-performance-extended-dataset.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-019/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-019/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-021-customer-profile-addresses-privacy.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-021/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-021/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-022-customer-devices-push-consent.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-022/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-022/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-023-persistent-cart-price-revalidation.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-023/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-023/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-024-public-availability-stock-projection.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-024/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-024/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-025-reservation-hold-atomic-expiry.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-025/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-025/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-026-checkout-pickup-delivery.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-026/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-026/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-027-idempotent-order-price-snapshot.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-027/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-027/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-028-order-history-status-tracking.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-028/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-028/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-029-admin-order-queue-management.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-029/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-029/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-030-win7pos-handoff-fiscal-boundary.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-030/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-030/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-031-order-notifications.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-031/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-031/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-032-payment-provider-integration.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-032/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-032/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-033-security-hardening.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-033/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-033/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-034-resilience-concurrency-idempotency.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-034/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-034/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-035-observability-crash-analytics.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-035/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-035/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-036-accessibility-localization-device-matrix.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-036/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-036/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-037-performance-images-cache-load.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-037/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-037/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-038-store-assets-privacy-legal-release-metadata.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-038/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-038/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-039-android-internal-testing-release.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-039/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-039/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-040-ios-testflight-release.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-040/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-040/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-043-storefront-commerce-information-architecture-ux-refresh.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-043/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-043/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-044-delivery-tracking-contract-privacy-writer.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-044/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-044/README.md"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/TASK-045-client-live-map-integrated-acceptance-closeout.md" \
    "${cmc_target}/docs/TASKS/"
  cp \
    "${cmc_test_repo_root}/docs/TASKS/EVIDENCE/TASK-045/README.md" \
    "${cmc_target}/docs/TASKS/EVIDENCE/TASK-045/README.md"

  if [[ "${cmc_repository_task_status}" == 'DONE' ]]; then
    local cmc_governance_file=''
    for cmc_governance_file in \
      README.md \
      docs/MASTER-PLAN.md \
      docs/AI_WORKLOG.md \
      docs/TASKS/TASK-040-ios-testflight-release.md \
      docs/TASKS/EVIDENCE/TASK-040/README.md \
      docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md; do
      git show "${cmc_fixture_revision}:${cmc_governance_file}" \
        >"${cmc_target}/${cmc_governance_file}"
    done
    CMC_REMOTE_REVIEW='dfa81de942f4cc06dc0340096a17d94410943730' \
      CMC_CURRENT_REVIEW="$(git rev-parse HEAD)" \
      CMC_REMOTE_TECHNICAL='83e9d42ba51190617c91e3137786e6cd33fe7bd9' \
      CMC_CURRENT_TECHNICAL="$(
        git log -1 --format='%H' -- scripts/test-governance-release-train.sh
      )" \
      perl -pi -e '
        s/\Q$ENV{CMC_REMOTE_REVIEW}\E/$ENV{CMC_CURRENT_REVIEW}/g;
        s/\Q$ENV{CMC_REMOTE_TECHNICAL}\E/$ENV{CMC_CURRENT_TECHNICAL}/g;
        s/dfa81de/substr($ENV{CMC_CURRENT_REVIEW}, 0, 7)/ge;
        s/83e9d42/substr($ENV{CMC_CURRENT_TECHNICAL}, 0, 7)/ge;
      ' \
      "${cmc_target}/docs/MASTER-PLAN.md" \
      "${cmc_target}/docs/AI_WORKLOG.md" \
      "${cmc_target}/docs/TASKS/TASK-040-ios-testflight-release.md" \
      "${cmc_target}/docs/TASKS/EVIDENCE/TASK-040/README.md" \
      "${cmc_target}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
    if ! git cat-file -e \
      '30ccc4de09e7a1e85b3d96d5d217dd1affe414e9^{commit}' 2>/dev/null; then
      CMC_REMOTE_ARTIFACT='30ccc4de09e7a1e85b3d96d5d217dd1affe414e9' \
        CMC_LOCAL_ARTIFACT='dda9c1f8a4933267d625c72a8c20db834260811d' \
        perl -pi -e '
          s/\Q$ENV{CMC_REMOTE_ARTIFACT}\E/$ENV{CMC_LOCAL_ARTIFACT}/g;
          s/30ccc4d/dda9c1f/g;
        ' \
        "${cmc_target}/docs/TASKS/TASK-040-ios-testflight-release.md" \
        "${cmc_target}/docs/TASKS/EVIDENCE/TASK-040/README.md"
    fi
  fi

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
  cmc_assertion_count=$((cmc_assertion_count + 1))
}

cmc_expect_fail() {
  local cmc_name="$1"
  local cmc_target="$2"
  local cmc_expected="$3"
  local cmc_log="${cmc_target}/governance-negative.log"

  if CMC_GOVERNANCE_REPO_ROOT="${cmc_target}" \
    bash "${cmc_test_repo_root}/scripts/check-governance-state.sh" \
      >"${cmc_log}" 2>&1; then
    printf 'Fixture %s doveva fallire.\n' "${cmc_name}" >&2
    exit 1
  fi
  if ! grep -Fq -- "${cmc_expected}" "${cmc_log}"; then
    printf 'Fixture %s fallita per una ragione diversa da quella attesa.\n' \
      "${cmc_name}" >&2
    exit 1
  fi
  rm "${cmc_log}"
  cmc_assertion_count=$((cmc_assertion_count + 1))
}

cmc_expect_handoff_path() {
  local cmc_path="$1"
  local cmc_expected="$2"

  if cmc_governance_path_is_handoff_document "${cmc_path}"; then
    cmc_actual='allowed'
  else
    cmc_actual='denied'
  fi
  if [[ "${cmc_actual}" != "${cmc_expected}" ]]; then
    printf 'Path policy incoerente per %s: atteso=%s, ricevuto=%s.\n' \
      "${cmc_path}" "${cmc_expected}" "${cmc_actual}" >&2
    exit 1
  fi
  cmc_assertion_count=$((cmc_assertion_count + 1))
}

cmc_expect_post_sha_path_collection() {
  local cmc_repository="${cmc_test_tmp}/post-sha-paths"
  local cmc_output="${cmc_test_tmp}/post-sha-paths.bin"
  local cmc_base=''
  local cmc_path=''
  local cmc_count=0
  local cmc_source_seen=false
  local cmc_target_seen=false

  mkdir -p "${cmc_repository}/test_driver"
  git -C "${cmc_repository}" init -q
  git -C "${cmc_repository}" config user.email governance@example.invalid
  git -C "${cmc_repository}" config user.name 'Governance Fixture'
  printf '%s\n' 'rename sentinel' \
    >"${cmc_repository}/test_driver/task_040_probe.dart"
  git -C "${cmc_repository}" add test_driver/task_040_probe.dart
  git -C "${cmc_repository}" commit -qm base
  cmc_base="$(git -C "${cmc_repository}" rev-parse HEAD)"
  git -C "${cmc_repository}" mv \
    test_driver/task_040_probe.dart README.md
  git -C "${cmc_repository}" commit -qam rename

  cmc_governance_collect_post_sha_paths \
    "${cmc_repository}" "${cmc_base}" "${cmc_output}"
  while IFS= read -r -d '' cmc_path; do
    cmc_count=$((cmc_count + 1))
    [[ "${cmc_path}" == 'test_driver/task_040_probe.dart' ]] && \
      cmc_source_seen=true
    [[ "${cmc_path}" == 'README.md' ]] && cmc_target_seen=true
  done <"${cmc_output}"
  if [[ "${cmc_count}" -ne 2 || "${cmc_source_seen}" != true || \
    "${cmc_target_seen}" != true ]]; then
    printf 'Il collector post-SHA non ha conservato entrambi i path del rename.\n' >&2
    exit 1
  fi
  cmc_assertion_count=$((cmc_assertion_count + 1))

  if cmc_governance_collect_post_sha_paths \
    "${cmc_repository}" '1111111111111111111111111111111111111111' \
    "${cmc_output}" 2>/dev/null; then
    printf 'Il collector post-SHA doveva propagare il fallimento Git.\n' >&2
    exit 1
  fi
  cmc_assertion_count=$((cmc_assertion_count + 1))
}

cmc_expect_review_role_policy() {
  local cmc_phase="$1"
  local cmc_indicator="$2"
  local cmc_expected_role="$3"
  local cmc_expected_suffix="$4"
  local cmc_expected_label="$5"

  cmc_governance_set_review_role_policy "${cmc_phase}" "${cmc_indicator}"
  if [[ "${cmc_governance_expected_revision_role}" != \
      "${cmc_expected_role}" || \
    "${cmc_governance_expected_worklog_suffix}" != \
      "${cmc_expected_suffix}" || \
    "${cmc_governance_expected_worklog_revision_label}" != \
      "${cmc_expected_label}" ]]; then
    printf 'Role policy incoerente: fase=%s, indicatore=%s.\n' \
      "${cmc_phase}" "${cmc_indicator}" >&2
    exit 1
  fi
  cmc_assertion_count=$((cmc_assertion_count + 1))
}

cmc_expect_review_role_policy \
  REVIEW CODEX_REVIEW_BLOCKED \
  review re-review 'Exact HEAD'
cmc_expect_review_role_policy \
  REVIEW CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION \
  review re-review 'Exact HEAD'
cmc_expect_review_role_policy \
  REVIEW CODEX_EXECUTION_COMPLETE_TO_REVIEW \
  technical 'e handoff' 'Technical SHA'
cmc_expect_review_role_policy \
  REVIEW CODEX_FIX_COMPLETE_TO_RE_REVIEW \
  technical 'e handoff' 'Technical SHA'
cmc_expect_review_role_policy \
  REVIEW CODEX_FIX_BLOCKED_TO_RE_REVIEW \
  technical 'e handoff' 'Technical SHA'
cmc_expect_review_role_policy \
  FIX CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX \
  review re-review 'Exact HEAD'
cmc_expect_review_role_policy \
  REVIEW CODEX_REVIEW_UNKNOWN \
  '' '' ''

if [[ "${cmc_repository_task_status}" == 'DONE' ]]; then
  cmc_expect_pass final-idle-closeout "${cmc_test_repo_root}"
fi

cmc_case="$(cmc_fixture valid)"
cmc_expect_pass valid "${cmc_case}"

cmc_current_task_status="${cmc_fixture_task_status}"

cmc_case="$(cmc_fixture duplicate-active)"
sed -i.bak \
  's/| TASK-031 | Notifiche push e order status events | VALIDATED_PENDING_INTEGRATED_REVIEW |/| TASK-031 | Notifiche push e order status events | ACTIVE |/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_duplicate_active_expected='Un task corrente ACTIVE richiede esattamente una riga ACTIVE'
if [[ "${cmc_current_task_status}" == 'BLOCKED' ]]; then
  cmc_duplicate_active_expected='Un task corrente BLOCKED non può lasciare righe ACTIVE'
fi
cmc_expect_fail duplicate-active "${cmc_case}" \
  "${cmc_duplicate_active_expected}"

cmc_case="$(cmc_fixture wrong-active)"
sed -i.bak \
  's/- \*\*Task attivo\*\*: TASK-040/- **Task attivo**: TASK-008/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_expect_fail wrong-active "${cmc_case}" \
  "$([[ "${cmc_current_task_status}" == 'BLOCKED' ]] && \
    printf 'Task attivo incoerente' || \
    printf 'Task ACTIVE in roadmap incoerente')"

cmc_case="$(cmc_fixture premature-done)"
sed -i.bak \
  's/| TASK-045 | Client live map, integrated acceptance and closeout | DONE |/| TASK-045 | Client live map, integrated acceptance and closeout | ACTIVE |/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_expect_fail premature-done "${cmc_case}" \
  "${cmc_duplicate_active_expected}"

cmc_case="$(cmc_fixture invalid-train-state)"
sed -i.bak 's/- \*\*Release train\*\*: CLIENT_FINAL_PRODUCT_COMPLETION/- **Release train**: STOREFRONT_V1/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
sed -i.bak 's/- \*\*Stato release train\*\*: EXECUTION/- **Stato release train**: UNKNOWN/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_expect_fail invalid-train-state "${cmc_case}" \
  'Stato release train non valido'

cmc_case="$(cmc_fixture active-during-review)"
sed -i.bak \
  's/- \*\*Release train\*\*: CLIENT_FINAL_PRODUCT_COMPLETION/- **Release train**: STOREFRONT_V1/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
sed -i.bak \
  's/- \*\*Stato release train\*\*: EXECUTION/- **Stato release train**: INTEGRATED_REVIEW/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
sed -i.bak \
  's/| TASK-031 | Notifiche push e order status events | VALIDATED_PENDING_INTEGRATED_REVIEW |/| TASK-031 | Notifiche push e order status events | ACTIVE |/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_expect_fail active-during-review "${cmc_case}" \
  'Durante INTEGRATED_REVIEW nessun task può restare ACTIVE'

cmc_case="$(cmc_fixture active-header-without-active-row)"
if [[ "${cmc_current_task_status}" == 'BLOCKED' ]]; then
  sed -i.bak \
    's/- \*\*Stato task\*\*: BLOCKED/- **Stato task**: ACTIVE/' \
    "${cmc_case}/docs/MASTER-PLAN.md"
else
  sed -i.bak \
    's/| TASK-040 | iOS TestFlight release | ACTIVE |/| TASK-040 | iOS TestFlight release | TODO |/' \
    "${cmc_case}/docs/MASTER-PLAN.md"
fi
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_expect_fail active-header-without-active-row "${cmc_case}" \
  'Un task corrente ACTIVE richiede esattamente una riga ACTIVE'

for cmc_wrong_blocked_row_status in \
  TODO DONE VALIDATED_PENDING_INTEGRATED_REVIEW; do
  cmc_wrong_blocked_row_label="$(
    printf '%s' "${cmc_wrong_blocked_row_status}" | tr '[:upper:]_' '[:lower:]-'
  )"
  cmc_case="$(
    cmc_fixture \
      "blocked-header-with-${cmc_wrong_blocked_row_label}-row"
  )"
  if [[ "${cmc_current_task_status}" == 'BLOCKED' ]]; then
    CMC_WRONG_STATUS="${cmc_wrong_blocked_row_status}" \
      perl -0pi.bak -e '
        s/^(\| TASK-040 \| iOS TestFlight release \|) BLOCKED (\|)/
          $1 . " " . $ENV{CMC_WRONG_STATUS} . " " . $2/em
          or die "Master TASK-040 blocked row missing\n";
      ' "${cmc_case}/docs/MASTER-PLAN.md"
    rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
  else
    CMC_WRONG_STATUS="${cmc_wrong_blocked_row_status}" \
      perl -0pi.bak -e '
        s/^- \*\*Stato task\*\*: ACTIVE$/- **Stato task**: BLOCKED/m
          or die "Master task status missing\n";
        s/^(\| TASK-040 \| iOS TestFlight release \|) ACTIVE (\|)/
          $1 . " " . $ENV{CMC_WRONG_STATUS} . " " . $2/em
          or die "Master TASK-040 row missing\n";
      ' "${cmc_case}/docs/MASTER-PLAN.md"
    rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
    perl -0pi.bak -e '
      s/^- \*\*Stato task\*\*: ACTIVE$/- **Stato task**: BLOCKED/m
        or die "README task status missing\n";
      s/^(TASK-040 è l.unico task `)ACTIVE( \/ FIX`)/${1}BLOCKED$2/m
        or die "README summary missing\n";
    ' "${cmc_case}/README.md"
    rm "${cmc_case}/README.md.bak"
    perl -0pi.bak -e '
      s/^- \*\*Stato\*\*: ACTIVE$/- **Stato**: BLOCKED/m
        or die "task status missing\n";
    ' "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md"
    rm "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md.bak"
    perl -0pi.bak -e '
      s/^`ACTIVE \/ FIX \/ /`BLOCKED \/ FIX \/ /m
        or die "evidence state missing\n";
    ' "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
    rm "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md.bak"
    perl -0pi.bak -e '
      s/^(\| TASK-040 \|) ACTIVE \/ FIX (\|)/$1 BLOCKED \/ FIX $2/m
        or die "manifest TASK-040 state missing\n";
    ' "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
    rm \
      "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md.bak"
  fi
  cmc_expect_fail \
    "blocked-header-with-${cmc_wrong_blocked_row_label}-row" \
    "${cmc_case}" \
    'Stato task corrente nel backlog incoerente'
done

for cmc_indented_duplicate_width in 1 2 3; do
  cmc_case="$(
    cmc_fixture \
      "master-current-row-duplicate-indent-${cmc_indented_duplicate_width}"
  )"
  cmc_row="$(grep -E '^\| TASK-040 \|' "${cmc_case}/docs/MASTER-PLAN.md")"
  cmc_indent="$(printf '%*s' "${cmc_indented_duplicate_width}" '')"
  printf '\n%s%s\n' "${cmc_indent}" "${cmc_row}" \
    >>"${cmc_case}/docs/MASTER-PLAN.md"
  cmc_indented_duplicate_expected='Righe ACTIVE fuori dalla tabella canonica Backlog completo'
  if [[ "${cmc_current_task_status}" == 'BLOCKED' ]]; then
    cmc_indented_duplicate_expected='Riga task corrente nel backlog incoerente'
  fi
  cmc_expect_fail \
    "master-current-row-duplicate-indent-${cmc_indented_duplicate_width}" \
    "${cmc_case}" \
    "${cmc_indented_duplicate_expected}"
done

cmc_case="$(cmc_fixture validated-pending)"
cmc_expect_pass validated-pending "${cmc_case}"

cmc_case="$(cmc_fixture validated-file-missing)"
sed -i.bak \
  's/- \*\*Release train\*\*: CLIENT_FINAL_PRODUCT_COMPLETION/- **Release train**: STOREFRONT_V1/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
mv \
  "${cmc_case}/docs/TASKS/TASK-005-storefront-schema-rls-migration-ownership.md" \
  "${cmc_case}/TASK-005-missing.md"
cmc_expect_fail validated-file-missing "${cmc_case}" \
  'TASK-005 validato richiede esattamente un file task'

cmc_case="$(cmc_fixture stale-worklog-tail)"
cmc_current_indicator="$(
  sed -n 's/^- \*\*Indicatore\*\*: //p' \
    "${cmc_case}/docs/MASTER-PLAN.md" | head -n 1
)"
case "${cmc_current_indicator}" in
  CODEX_FIX_COMPLETE_TO_RE_REVIEW)
    cmc_stale_indicator='CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX'
    ;;
  *)
    cmc_stale_indicator='CODEX_FIX_COMPLETE_TO_RE_REVIEW'
    ;;
esac
printf '%s\n' \
  '' \
  '## 2026-08-17 — TASK-040 stale synthetic tail' \
  '' \
  "- **Handoff**: \`${cmc_stale_indicator}\`." \
  >>"${cmc_case}/docs/AI_WORKLOG.md"
cmc_expect_fail stale-worklog-tail "${cmc_case}" \
  'Worklog corrente incoerente con handoff'

cmc_case="$(cmc_fixture stale-manifest-status)"
perl -0pi.bak -e '
  s/(\| TASK-040 \| )[^|]+( \|)/${1}ACTIVE \/ STALE${2}/
    or die "TASK-040 manifest row missing\n";
' "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
rm "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md.bak"
cmc_expect_fail stale-manifest-status "${cmc_case}" \
  'Release manifest status incoerente'

cmc_case="$(cmc_fixture stale-manifest-revision)"
perl -0pi.bak -e '
  s/(\| TASK-040 \|[^|]*\| )[^|]+( \|)/${1}`1111111` stale${2}/
    or die "TASK-040 manifest row missing\n";
' "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
rm "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md.bak"
cmc_expect_fail stale-manifest-revision "${cmc_case}" \
  'Release manifest revision incoerente'

cmc_case="$(cmc_fixture stale-task-tail)"
cmc_current_indicator="$(
  sed -n 's/^- \*\*Indicatore\*\*: //p' \
    "${cmc_case}/docs/MASTER-PLAN.md" | head -n 1
)"
case "${cmc_current_indicator}" in
  CODEX_FIX_COMPLETE_TO_RE_REVIEW)
    cmc_stale_indicator='CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX'
    ;;
  *)
    cmc_stale_indicator='CODEX_FIX_COMPLETE_TO_RE_REVIEW'
    ;;
esac
printf '%s\n' \
  '' \
  '### Fix 99' \
  '' \
  '- exact technical SHA `1111111111111111111111111111111111111111`;' \
  "- \`${cmc_stale_indicator}\`." \
  >>"${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md"
cmc_expect_fail stale-task-tail "${cmc_case}" \
  'Task chronology contiene cicli Fix fuori dalla sezione canonica'

cmc_case="$(cmc_fixture stale-evidence-matrix)"
perl -0pi.bak -e '
  s/(^\| T-02 \|[^\n]*exact SHA `)[0-9a-f]{7,40}(`)/${1}1111111${2}/m
    or die "T-02 evidence row missing\n";
' "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
rm "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md.bak"
cmc_expect_fail stale-evidence-matrix "${cmc_case}" \
  'Matrice T-02 incoerente'

cmc_case="$(cmc_fixture stale-evidence-matrix-t03)"
perl -0pi.bak -e '
  s/(^\| T-03 \|[^\n]*fixture iOS )[0-9]+\/[0-9]+/${1}1\/1/m
    or die "T-03 evidence row missing\n";
' "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
rm "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md.bak"
cmc_expect_fail stale-evidence-matrix-t03 "${cmc_case}" \
  'Matrice T-03 incoerente'

cmc_case="$(cmc_fixture duplicate-active-manifest-row)"
cmc_manifest_row="$(
  grep -E '^\| TASK-040 \|' \
    "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
)"
printf '%s\n' "${cmc_manifest_row}" \
  >>"${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
cmc_expect_fail duplicate-active-manifest-row "${cmc_case}" \
  'Release manifest richiede esattamente una riga'

cmc_case="$(cmc_fixture manifest-fix-token-boundary)"
perl -0pi.bak -e '
  s{(\| TASK-040 \|[^\n]*\| Fix )([0-9]+)( [^\n]*\|)$}{$1.$2."0".$3}me
    or die "TASK-040 manifest gate missing\n";
' "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
rm "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md.bak"
cmc_expect_fail manifest-fix-token-boundary "${cmc_case}" \
  'Release manifest gate incoerente'

cmc_case="$(cmc_fixture evidence-t02-fail-status)"
perl -0pi.bak -e '
  s/^(\| T-02 \| )PASS( \|)/${1}FAIL${2}/m
    or die "T-02 evidence row missing\n";
' "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
rm "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md.bak"
cmc_expect_fail evidence-t02-fail-status "${cmc_case}" \
  'Matrice T-02 incoerente'

cmc_case="$(cmc_fixture evidence-t03-fail-status)"
perl -0pi.bak -e '
  s/^(\| T-03 \| )PASS( \|)/${1}FAIL${2}/m
    or die "T-03 evidence row missing\n";
' "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
rm "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md.bak"
cmc_expect_fail evidence-t03-fail-status "${cmc_case}" \
  'Matrice T-03 incoerente'

cmc_case="$(cmc_fixture duplicate-evidence-t02-row)"
printf '%s\n' \
  '|T-02|FAIL|clean release no-codesign e archive Xcode exact SHA `1111111`|' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail duplicate-evidence-t02-row "${cmc_case}" \
  'richiede esattamente una riga T-02'

cmc_case="$(cmc_fixture duplicate-evidence-t03-row)"
printf '%s\n' \
  '   | T-03 | FAIL | plist/privacy + fixture iOS 1/1 |' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail duplicate-evidence-t03-row "${cmc_case}" \
  'richiede esattamente una riga T-03'

cmc_case="$(cmc_fixture missing-fix-chronology)"
perl -0pi.bak -e '
  s/^### ((?:Re-review )?Fix [0-9]+)$/### Ciclo $1/gm
    or die "Fix headings missing\n";
' "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md"
rm "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md.bak"
cmc_expect_fail missing-fix-chronology "${cmc_case}" \
  'Task chronology priva di cicli Fix strutturati'

cmc_case="$(cmc_fixture html-comment-tail-decoy)"
perl -0pi.bak -e '
  s/(### Re-review Fix [0-9]+\n\n)- exact review SHA: `([0-9a-f]{40})`;/${1}- exact review SHA: `1111111111111111111111111111111111111111`;\n<!-- exact review SHA: `$2`; CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX -->/
    or die "review SHA line missing\n";
' "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md"
rm "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md.bak"
cmc_expect_fail html-comment-tail-decoy "${cmc_case}" \
  'Task chronology contiene commenti, fence o heading indentati non ammessi'

cmc_case="$(cmc_fixture out-of-order-fix-chronology)"
perl -0pi.bak -e '
  s/^### Fix 8$/### Fix 9/m or die "Fix 8 heading missing\n";
' "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md"
rm "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md.bak"
cmc_expect_fail out-of-order-fix-chronology "${cmc_case}" \
  'Task chronology fuori sequenza'

cmc_case="$(cmc_fixture manifest-revision-not-prefix)"
perl -0pi.bak -e '
  s/(\| TASK-040 \|[^\n]*\| `)([0-9a-f]{7})(` [^|]*\|)/$1.$2."deadbeef".$3/e
    or die "TASK-040 manifest revision missing\n";
' "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
rm "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md.bak"
cmc_expect_fail manifest-revision-not-prefix "${cmc_case}" \
  'Release manifest revision incoerente'

cmc_case="$(cmc_fixture stale-current-task-handoff)"
cmc_current_indicator="$(
  sed -n 's/^- \*\*Indicatore\*\*: //p' \
    "${cmc_case}/docs/MASTER-PLAN.md" | head -n 1
)"
case "${cmc_current_indicator}" in
  CODEX_FIX_COMPLETE_TO_RE_REVIEW)
    cmc_stale_indicator='CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX'
    ;;
  *)
    cmc_stale_indicator='CODEX_FIX_COMPLETE_TO_RE_REVIEW'
    ;;
esac
CMC_CURRENT_INDICATOR="${cmc_current_indicator}" \
  CMC_STALE_INDICATOR="${cmc_stale_indicator}" \
  perl -0pi.bak -e '
    my $current = quotemeta $ENV{CMC_CURRENT_INDICATOR};
    my $stale = $ENV{CMC_STALE_INDICATOR};
    s/`$current`\.\n\n## Chiusura/`$stale`.\n\n## Chiusura/
      or die "current task handoff missing\n";
  ' "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md"
rm "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md.bak"
cmc_expect_fail stale-current-task-handoff "${cmc_case}" \
  'Tail task incoerente con handoff'

cmc_case="$(cmc_fixture manifest-prose-row)"
perl -0pi.bak -e '
  s/^\| TASK-040 \|/prose | TASK-040 |/m
    or die "TASK-040 manifest row missing\n";
' "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
rm "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md.bak"
cmc_expect_fail manifest-prose-row "${cmc_case}" \
  'Release manifest richiede esattamente una riga'

cmc_case="$(cmc_fixture manifest-blockquote-row)"
perl -0pi.bak -e '
  s/^\| TASK-040 \|/> | TASK-040 |/m
    or die "TASK-040 manifest row missing\n";
' "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
rm "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md.bak"
cmc_expect_fail manifest-blockquote-row "${cmc_case}" \
  'Release manifest richiede esattamente una riga'

cmc_case="$(cmc_fixture manifest-code-block-row)"
perl -0pi.bak -e '
  s/^\| TASK-040 \|/    | TASK-040 |/m
    or die "TASK-040 manifest row missing\n";
' "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
rm "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md.bak"
cmc_expect_fail manifest-code-block-row "${cmc_case}" \
  'Release manifest richiede esattamente una riga'

cmc_case="$(cmc_fixture manifest-extra-column)"
perl -0pi.bak -e '
  s/^(\| TASK-040 \|[^\n]*) \|$/$1 | EXTRA |/m
    or die "TASK-040 manifest row missing\n";
' "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
rm "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md.bak"
cmc_expect_fail manifest-extra-column "${cmc_case}" \
  'Release manifest richiede esattamente una riga'

cmc_case="$(cmc_fixture evidence-prose-t02)"
perl -0pi.bak -e '
  s/^\| T-02 \|/prose | T-02 |/m or die "T-02 row missing\n";
' "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
rm "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md.bak"
cmc_expect_fail evidence-prose-t02 "${cmc_case}" \
  'richiede esattamente una riga T-02'

cmc_case="$(cmc_fixture evidence-blockquote-t03)"
perl -0pi.bak -e '
  s/^\| T-03 \|/> | T-03 |/m or die "T-03 row missing\n";
' "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
rm "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md.bak"
cmc_expect_fail evidence-blockquote-t03 "${cmc_case}" \
  'richiede esattamente una riga T-03'

cmc_case="$(cmc_fixture evidence-code-block-t02)"
perl -0pi.bak -e '
  s/^\| T-02 \|/    | T-02 |/m or die "T-02 row missing\n";
' "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
rm "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md.bak"
cmc_expect_fail evidence-code-block-t02 "${cmc_case}" \
  'richiede esattamente una riga T-02'

cmc_case="$(cmc_fixture evidence-extra-column-t02)"
perl -0pi.bak -e '
  s/^(\| T-02 \|[^\n]*) \|$/$1 | EXTRA |/m or die "T-02 row missing\n";
' "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
rm "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md.bak"
cmc_expect_fail evidence-extra-column-t02 "${cmc_case}" \
  'richiede esattamente una riga T-02'

cmc_case="$(cmc_fixture evidence-comment-decoy)"
printf '%s\n' '<!-- hidden evidence row decoy -->' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-comment-decoy "${cmc_case}" \
  'Evidence TASK-040 contiene commenti, fence o heading indentati non ammessi'

cmc_case="$(cmc_fixture evidence-partial-ios-coordinated)"
perl -0pi.bak -e '
  s/(validator iOS avversariale )([0-9]+)\/\2/${1}1\/$2/
    or die "current iOS gate count missing\n";
  s/(^\| T-03 \|[^\n]*fixture iOS )([0-9]+)\/\2/${1}1\/$2/m
    or die "T-03 count missing\n";
' "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
rm "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md.bak"
cmc_expect_fail evidence-partial-ios-coordinated "${cmc_case}" \
  'Matrice T-03 incoerente'

cmc_case="$(cmc_fixture task-code-fence)"
perl -0pi.bak -e '
  s/^## Fix$/## Fix\n```/m or die "Fix section missing\n";
  s/^## Chiusura$/```\n## Chiusura/m or die "Chiusura missing\n";
' "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md"
rm "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md.bak"
cmc_expect_fail task-code-fence "${cmc_case}" \
  'Task chronology contiene commenti, fence o heading indentati non ammessi'

cmc_case="$(cmc_fixture task-indented-heading)"
perl -0pi.bak -e '
  s/^(### (?:Re-review )?Fix [0-9]+)$/   $1/m
    or die "Fix heading missing\n";
' "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md"
rm "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md.bak"
cmc_expect_fail task-indented-heading "${cmc_case}" \
  'Task chronology contiene commenti, fence o heading indentati non ammessi'

cmc_case="$(cmc_fixture worklog-comment-decoy)"
printf '%s\n' '<!-- hidden worklog handoff decoy -->' \
  >>"${cmc_case}/docs/AI_WORKLOG.md"
cmc_expect_fail worklog-comment-decoy "${cmc_case}" \
  'Worklog contiene commenti, fence o heading indentati non ammessi'

cmc_case="$(cmc_fixture worklog-global-tail)"
printf '%s\n' '' '## 2026-08-17 — TASK-041 synthetic premature tail' \
  >>"${cmc_case}/docs/AI_WORKLOG.md"
cmc_expect_fail worklog-global-tail "${cmc_case}" \
  'Worklog corrente non è l ultimo heading globale'

cmc_case="$(cmc_fixture missing-worklog-sha)"
perl -0pi.bak -e '
  s/(.*^## [^\n]+ — TASK-040 Fix [^\n]+\n)(.*?)(^- \*\*(?:Technical SHA|Exact HEAD)\*\*: `[0-9a-f]{40}`\.\n)/$1$2/ms
    or die "current worklog SHA missing\n";
' "${cmc_case}/docs/AI_WORKLOG.md"
rm "${cmc_case}/docs/AI_WORKLOG.md.bak"
cmc_expect_fail missing-worklog-sha "${cmc_case}" \
  'Worklog corrente non correlato allo SHA task'

cmc_case="$(cmc_fixture mismatched-worklog-sha)"
perl -0pi.bak -e '
  s/(.*^## [^\n]+ — TASK-040 Fix [^\n]+\n.*?^- \*\*(?:Technical SHA|Exact HEAD)\*\*: `)[0-9a-f]{40}(`\.)/${1}a85d60774212f212d3ee8dd274db99af011925c8$2/ms
    or die "current worklog SHA missing\n";
' "${cmc_case}/docs/AI_WORKLOG.md"
rm "${cmc_case}/docs/AI_WORKLOG.md.bak"
cmc_expect_fail mismatched-worklog-sha "${cmc_case}" \
  'Worklog corrente non correlato allo SHA task'

cmc_case="$(cmc_fixture nonexistent-coordinated-sha)"
cmc_current_revision="$(
  sed -nE 's/^- exact (technical|review) SHA: `([0-9a-f]{40})`;$/\2/p' \
    "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md" | tail -n 1
)"
CMC_SOURCE_REVISION="${cmc_current_revision}" perl -0pi.bak -e '
  my $source = quotemeta $ENV{CMC_SOURCE_REVISION};
  s/$source/1111111111111111111111111111111111111111/g;
' "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md" \
  "${cmc_case}/docs/AI_WORKLOG.md"
rm "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md.bak" \
  "${cmc_case}/docs/AI_WORKLOG.md.bak"
perl -0pi.bak -e '
  s/(\| TASK-040 \|[^\n]*\| `)[0-9a-f]{7,40}(` [^|]*\|)/${1}1111111${2}/
    or die "manifest revision missing\n";
' "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
rm "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md.bak"
cmc_expect_fail nonexistent-coordinated-sha "${cmc_case}" \
  'Tail task revision inesistente o fuori lineage'

cmc_case="$(cmc_fixture rollback-current-fix-cycle)"
cmc_current_fix_number="$(
  sed -nE 's/^### (Re-review )?Fix ([0-9]+)$/\2/p' \
    "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md" | tail -n 1
)"
cmc_previous_fix_number=$((cmc_current_fix_number - 1))
CMC_CURRENT_FIX="${cmc_current_fix_number}" \
  CMC_PREVIOUS_FIX="${cmc_previous_fix_number}" \
  perl -0pi.bak -e '
    my $current = $ENV{CMC_CURRENT_FIX};
    my $previous = $ENV{CMC_PREVIOUS_FIX};
    s/(.*^### (?:Re-review )?Fix )$current$/${1}$previous/ms
      or die "last task Fix heading missing\n";
  ' "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md"
rm "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md.bak"
CMC_CURRENT_FIX="${cmc_current_fix_number}" \
  CMC_PREVIOUS_FIX="${cmc_previous_fix_number}" \
  perl -0pi.bak -e '
    my $current = $ENV{CMC_CURRENT_FIX};
    my $previous = $ENV{CMC_PREVIOUS_FIX};
    s/(\| TASK-040 \|[^\n]*\| Fix )$current([ :])/${1}$previous$2/
      or die "manifest Fix missing\n";
  ' "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
rm "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md.bak"
CMC_CURRENT_FIX="${cmc_current_fix_number}" \
  CMC_PREVIOUS_FIX="${cmc_previous_fix_number}" \
  perl -0pi.bak -e '
  my $current = $ENV{CMC_CURRENT_FIX};
  my $previous = $ENV{CMC_PREVIOUS_FIX};
  s/(^## Gate executor corrente — Fix )$current$/${1}$previous/m
    or die "current evidence Fix heading missing\n";
  s/(^\| T-07 \| NOT_RUN \| Fix )$current( handoff)/${1}$previous$2/m
    or die "T-07 current Fix missing\n";
' "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
rm "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md.bak"
CMC_CURRENT_FIX="${cmc_current_fix_number}" \
  CMC_PREVIOUS_FIX="${cmc_previous_fix_number}" \
  perl -0pi.bak -e '
    my $current = $ENV{CMC_CURRENT_FIX};
    my $previous = $ENV{CMC_PREVIOUS_FIX};
    s/(.*^## [^\n]+ — TASK-040 Fix )$current( (?:e handoff|re-review))$/${1}$previous$2/ms
      or die "current worklog Fix heading missing\n";
  ' "${cmc_case}/docs/AI_WORKLOG.md"
rm "${cmc_case}/docs/AI_WORKLOG.md.bak"
cmc_expect_fail rollback-current-fix-cycle "${cmc_case}" \
  'Ciclo Fix corrente non ancorato alla chronology Git'

cmc_case="$(cmc_fixture master-active-row-relocated)"
cmc_row="$(grep -E '^\| TASK-040 \|' "${cmc_case}/docs/MASTER-PLAN.md")"
cmc_relocated_row="${cmc_row}"
if [[ "${cmc_current_task_status}" == 'BLOCKED' ]]; then
  cmc_relocated_row="${cmc_relocated_row/ | BLOCKED |/ | ACTIVE |}"
fi
CMC_ROW="${cmc_row}" CMC_RELOCATED_ROW="${cmc_relocated_row}" \
  perl -0pi.bak -e '
  my $row = quotemeta $ENV{CMC_ROW};
  s/^$row\n//m or die "TASK-040 backlog row missing\n";
  $_ .= "\n$ENV{CMC_RELOCATED_ROW}\n";
' "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_expect_fail master-active-row-relocated "${cmc_case}" \
  'Righe ACTIVE fuori dalla tabella canonica Backlog completo'

cmc_case="$(cmc_fixture manifest-row-relocated)"
cmc_row="$(grep -E '^\| TASK-040 \|' \
  "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md")"
CMC_ROW="${cmc_row}" perl -0pi.bak -e '
  my $row = quotemeta $ENV{CMC_ROW};
  s/^$row\n//m or die "TASK-040 manifest row missing\n";
  $_ .= "\n$ENV{CMC_ROW}\n";
' "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
rm "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md.bak"
cmc_expect_fail manifest-row-relocated "${cmc_case}" \
  'Release manifest richiede esattamente una riga canonica'

cmc_case="$(cmc_fixture manifest-row-other-table)"
cmc_row="$(grep -E '^\| TASK-040 \|' \
  "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md")"
CMC_ROW="${cmc_row}" perl -0pi.bak -e '
  my $row = quotemeta $ENV{CMC_ROW};
  s/^$row\n//m or die "TASK-040 manifest row missing\n";
  $_ .= "\n## Tabella non autoritativa\n\n| Task | Stato | Client revision | Admin revision | PR/merge | Gate |\n|---|---|---|---|---|---|\n$ENV{CMC_ROW}\n";
' "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
rm "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md.bak"
cmc_expect_fail manifest-row-other-table "${cmc_case}" \
  'Release manifest richiede esattamente una riga canonica'

cmc_case="$(cmc_fixture evidence-rows-relocated)"
cmc_t02="$(grep -E '^\| T-02 \|' \
  "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md")"
cmc_t03="$(grep -E '^\| T-03 \|' \
  "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md")"
cmc_t07="$(grep -E '^\| T-07 \|' \
  "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md")"
CMC_T02="${cmc_t02}" CMC_T03="${cmc_t03}" CMC_T07="${cmc_t07}" \
  perl -0pi.bak -e '
    for my $name (qw(CMC_T02 CMC_T03 CMC_T07)) {
      my $row = quotemeta $ENV{$name};
      s/^$row\n//m or die "$name row missing\n";
    }
    $_ .= "\n$ENV{CMC_T02}\n$ENV{CMC_T03}\n$ENV{CMC_T07}\n";
  ' "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
rm "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md.bak"
cmc_expect_fail evidence-rows-relocated "${cmc_case}" \
  'riga T-02 canonica'

cmc_case="$(cmc_fixture evidence-rows-other-table)"
cmc_t02="$(grep -E '^\| T-02 \|' \
  "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md")"
cmc_t03="$(grep -E '^\| T-03 \|' \
  "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md")"
cmc_t07="$(grep -E '^\| T-07 \|' \
  "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md")"
CMC_T02="${cmc_t02}" CMC_T03="${cmc_t03}" CMC_T07="${cmc_t07}" \
  perl -0pi.bak -e '
    for my $name (qw(CMC_T02 CMC_T03 CMC_T07)) {
      my $row = quotemeta $ENV{$name};
      s/^$row\n//m or die "$name row missing\n";
    }
    $_ .= "\n## Matrice non autoritativa\n\n| Test | Esito | Evidence |\n|---|---|---|\n$ENV{CMC_T02}\n$ENV{CMC_T03}\n$ENV{CMC_T07}\n";
  ' "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
rm "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md.bak"
cmc_expect_fail evidence-rows-other-table "${cmc_case}" \
  'riga T-02 canonica'

cmc_case="$(cmc_fixture task-raw-html-block)"
printf '%s\n' '<pre>hidden task chronology</pre>' \
  >>"${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md"
cmc_expect_fail task-raw-html-block "${cmc_case}" \
  'Task chronology contiene commenti, fence o heading indentati non ammessi, oppure HTML'

cmc_case="$(cmc_fixture evidence-raw-html-block)"
printf '%s\n' '<pre>hidden evidence matrix</pre>' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-raw-html-block "${cmc_case}" \
  'Evidence TASK-040 contiene commenti, fence o heading indentati non ammessi, oppure HTML'

cmc_case="$(cmc_fixture task-processing-instruction)"
printf '%s\n' '<?governance hidden?>' \
  >>"${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md"
cmc_expect_fail task-processing-instruction "${cmc_case}" \
  'Task chronology contiene commenti, fence o heading indentati non ammessi, oppure HTML'

cmc_case="$(cmc_fixture evidence-cdata-block)"
printf '%s\n' '<![CDATA[' 'hidden evidence' ']]>' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-cdata-block "${cmc_case}" \
  'Evidence TASK-040 contiene commenti, fence o heading indentati non ammessi, oppure HTML'

cmc_case="$(cmc_fixture task-multiline-html-block)"
printf '%s\n' '<pre' 'class="hidden">' 'hidden chronology' '</pre>' \
  >>"${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md"
cmc_expect_fail task-multiline-html-block "${cmc_case}" \
  'Task chronology contiene commenti, fence o heading indentati non ammessi, oppure HTML'

cmc_case="$(cmc_fixture readme-raw-html-state)"
perl -0pi.bak -e '
  s/^## Stato$/<pre>\n## Stato/m or die "README state heading missing\n";
' "${cmc_case}/README.md"
rm "${cmc_case}/README.md.bak"
cmc_expect_fail readme-raw-html-state "${cmc_case}" \
  'README contiene commenti, fence o heading indentati non ammessi, oppure HTML'

cmc_case="$(cmc_fixture readme-summary-mismatch)"
IFS=$'\t' read -r cmc_summary_status cmc_summary_phase < <(
  sed -nE 's/^TASK-040 .*`(ACTIVE|BLOCKED) \/ (FIX|REVIEW)`:.*$/\1\t\2/p' \
    "${cmc_case}/README.md"
)
[[ "${cmc_summary_phase}" == 'FIX' ]] && \
  cmc_wrong_summary_phase='REVIEW' || cmc_wrong_summary_phase='FIX'
CMC_SUMMARY_STATUS="${cmc_summary_status}" \
  CMC_SUMMARY_PHASE="${cmc_summary_phase}" \
  CMC_WRONG_SUMMARY_PHASE="${cmc_wrong_summary_phase}" \
  perl -0pi.bak -e '
  my $source = quotemeta $ENV{CMC_SUMMARY_PHASE};
  my $status = quotemeta $ENV{CMC_SUMMARY_STATUS};
  s/^(TASK-040 .*`$status \/ )$source(`:)/${1}$ENV{CMC_WRONG_SUMMARY_PHASE}$2/m
    or die "README summary missing\n";
' "${cmc_case}/README.md"
rm "${cmc_case}/README.md.bak"
cmc_expect_fail readme-summary-mismatch "${cmc_case}" \
  'Riepilogo README TASK-040 incoerente'

cmc_case="$(cmc_fixture evidence-ca06-count-mismatch)"
perl -0pi.bak -e '
  s/(^\| CA-06 \| security source )([0-9]+)( e app artifact 207;)/
    $1 . ($2 - 1) . $3/em
    or die "CA-06 count missing\n";
' "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
rm "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md.bak"
cmc_expect_fail evidence-ca06-count-mismatch "${cmc_case}" \
  'Matrice CA-06 incoerente con il gate security corrente'

cmc_case="$(cmc_fixture evidence-t04-count-mismatch)"
perl -0pi.bak -e '
  s/(^\| T-04 \| PASS \| scanner )([0-9]+)(\/207)/
    $1 . ($2 - 1) . $3/em
    or die "T-04 count missing\n";
' "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
rm "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md.bak"
cmc_expect_fail evidence-t04-count-mismatch "${cmc_case}" \
  'Matrice T-04 incoerente con il gate security corrente'

cmc_case="$(cmc_fixture evidence-security-zero-coordinated)"
perl -0pi.bak -e '
  s/(^\| CA-06 \| security source )[0-9]+( e app artifact )[0-9]+/${1}0${2}0/m
    or die "CA-06 counts missing\n";
  s/(^\| T-04 \| PASS \| scanner )[0-9]+\/[0-9]+/${1}0\/0/m
    or die "T-04 counts missing\n";
  s/(^- security source )[0-9]+(; artifact )[0-9]+/${1}0${2}0/m
    or die "gate security counts missing\n";
' "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
rm "${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md.bak"
cmc_expect_fail evidence-security-zero-coordinated "${cmc_case}" \
  'Matrice T-04 incoerente con il gate security corrente'

cmc_case="$(cmc_fixture evidence-duplicate-ca06-visible-table)"
printf '%s\n' \
  '' \
  '## Matrice CA non autoritativa' \
  '' \
  '| CA | Evidence | Esito |' \
  '|---|---|---|' \
  '| CA-06 | security source 0 e app artifact 0; config esterna assente | PASS |' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-duplicate-ca06-visible-table "${cmc_case}" \
  'riga CA-06 canonica e globale'

cmc_case="$(cmc_fixture evidence-duplicate-t04-visible-table)"
printf '%s\n' \
  '' \
  '## Matrice T non autoritativa' \
  '' \
  '| Test | Esito | Evidence |' \
  '|---|---|---|' \
  '| T-04 | PASS | scanner 0/0 e fixture 0/0 + 0/0 |' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-duplicate-t04-visible-table "${cmc_case}" \
  'riga T-04 canonica e globale'

cmc_case="$(cmc_fixture evidence-duplicate-ca06-no-outer-pipes)"
printf '%s\n' \
  '' \
  '## Matrice CA GFM senza outer pipe' \
  '' \
  'CA | Evidence | Esito' \
  '---|---|---' \
  'CA-06 | security source 0 e app artifact 0 | PASS' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-duplicate-ca06-no-outer-pipes "${cmc_case}" \
  'riga CA-06 canonica e globale'

cmc_case="$(cmc_fixture evidence-duplicate-t04-no-trailing-pipe)"
printf '%s\n' \
  '' \
  '## Matrice T GFM senza trailing pipe' \
  '' \
  '| Test | Esito | Evidence' \
  '|---|---|---' \
  '| T-04 | PASS | scanner 0/0' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-duplicate-t04-no-trailing-pipe "${cmc_case}" \
  'riga T-04 canonica e globale'

cmc_case="$(cmc_fixture evidence-duplicate-ca06-trailing-space)"
printf '%s\n' \
  '' \
  '## Matrice CA GFM con trailing whitespace' \
  '' \
  '| CA | Evidence | Esito |' \
  '|---|---|---|' \
  '| CA-06 | security source 0 e app artifact 0 | PASS |   ' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-duplicate-ca06-trailing-space "${cmc_case}" \
  'riga CA-06 canonica e globale'

cmc_case="$(cmc_fixture evidence-duplicate-t04-trailing-space)"
printf '%s\n' \
  '' \
  '## Matrice T GFM con trailing whitespace' \
  '' \
  '| Test | Esito | Evidence |' \
  '|---|---|---|' \
  '| T-04 | PASS | scanner 0/0 |   ' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-duplicate-t04-trailing-space "${cmc_case}" \
  'riga T-04 canonica e globale'

cmc_case="$(cmc_fixture evidence-duplicate-ca06-blockquote)"
printf '%s\n' \
  '' \
  '> | CA | Evidence | Esito |' \
  '> |---|---|---|' \
  '> | CA-06 | security source 0 e app artifact 0 | PASS |' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-duplicate-ca06-blockquote "${cmc_case}" \
  'riga CA-06 canonica e globale'

cmc_case="$(cmc_fixture evidence-duplicate-t04-blockquote)"
printf '%s\n' \
  '' \
  '> | Test | Esito | Evidence |' \
  '> |---|---|---|' \
  '> | T-04 | PASS | scanner 0/0 |' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-duplicate-t04-blockquote "${cmc_case}" \
  'riga T-04 canonica e globale'

cmc_case="$(cmc_fixture evidence-duplicate-ca06-extra-column)"
printf '%s\n' \
  '' \
  '| CA | Evidence | Esito | Note |' \
  '|---|---|---|---|' \
  '| CA-06 | security source 0 e app artifact 0 | PASS | conflitto |' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-duplicate-ca06-extra-column "${cmc_case}" \
  'riga CA-06 canonica e globale'

cmc_case="$(cmc_fixture evidence-duplicate-t04-extra-column)"
printf '%s\n' \
  '' \
  '| Test | Esito | Evidence | Note |' \
  '|---|---|---|---|' \
  '| T-04 | PASS | scanner 0/0 | conflitto |' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-duplicate-t04-extra-column "${cmc_case}" \
  'riga T-04 canonica e globale'

cmc_case="$(cmc_fixture evidence-duplicate-ca06-entity)"
printf '%s\n' \
  '' \
  '| CA | Evidence | Esito |' \
  '|---|---|---|' \
  '| CA&#45;06 | security source 0 e app artifact 0 | PASS |' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-duplicate-ca06-entity "${cmc_case}" \
  'markup inline ambiguo o caratteri non ASCII'

cmc_case="$(cmc_fixture evidence-duplicate-t04-entity)"
printf '%s\n' \
  '' \
  '| Test | Esito | Evidence |' \
  '|---|---|---|' \
  '| T-0&#52; | PASS | scanner 0/0 |' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-duplicate-t04-entity "${cmc_case}" \
  'markup inline ambiguo o caratteri non ASCII'

cmc_case="$(cmc_fixture evidence-duplicate-ca06-escape)"
printf '%s\n' \
  '' \
  '| CA | Evidence | Esito |' \
  '|---|---|---|' \
  '| CA\-06 | security source 0 e app artifact 0 | PASS |' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-duplicate-ca06-escape "${cmc_case}" \
  'markup inline ambiguo o caratteri non ASCII'

cmc_case="$(cmc_fixture evidence-duplicate-t04-escape)"
printf '%s\n' \
  '' \
  '| Test | Esito | Evidence |' \
  '|---|---|---|' \
  '| T\-04 | PASS | scanner 0/0 |' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-duplicate-t04-escape "${cmc_case}" \
  'markup inline ambiguo o caratteri non ASCII'

cmc_case="$(cmc_fixture evidence-duplicate-ca06-emphasis)"
printf '%s\n' \
  '' \
  '| CA | Evidence | Esito |' \
  '|---|---|---|' \
  '| CA-**06** | security source 0 e app artifact 0 | PASS |' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-duplicate-ca06-emphasis "${cmc_case}" \
  'markup inline ambiguo o caratteri non ASCII'

cmc_case="$(cmc_fixture evidence-duplicate-t04-emphasis)"
printf '%s\n' \
  '' \
  '| Test | Esito | Evidence |' \
  '|---|---|---|' \
  '| T-**04** | PASS | scanner 0/0 |' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-duplicate-t04-emphasis "${cmc_case}" \
  'markup inline ambiguo o caratteri non ASCII'

cmc_case="$(cmc_fixture evidence-duplicate-ca06-inline-html)"
printf '%s\n' \
  '' \
  '| CA | Evidence | Esito |' \
  '|---|---|---|' \
  '| CA-<span>06</span> | security source 0 e app artifact 0 | PASS |' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-duplicate-ca06-inline-html "${cmc_case}" \
  'markup inline ambiguo o caratteri non ASCII'

cmc_case="$(cmc_fixture evidence-duplicate-t04-non-ascii)"
printf '%s\n' \
  '' \
  '| Test | Esito | Evidence |' \
  '|---|---|---|' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
printf '%b\n' '| T-\342\200\21304 | PASS | scanner 0/0 |' \
  >>"${cmc_case}/docs/TASKS/EVIDENCE/TASK-040/README.md"
cmc_expect_fail evidence-duplicate-t04-non-ascii "${cmc_case}" \
  'markup inline ambiguo o caratteri non ASCII'

cmc_case="$(cmc_fixture task-role-mismatch)"
cmc_source_role="$(
  sed -nE 's/^- exact (technical|review) SHA: `[0-9a-f]{40}`;$/\1/p' \
    "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md" | tail -n 1
)"
[[ "${cmc_source_role}" == 'technical' ]] && cmc_wrong_role='review' || \
  cmc_wrong_role='technical'
CMC_SOURCE_ROLE="${cmc_source_role}" CMC_WRONG_ROLE="${cmc_wrong_role}" \
  perl -0pi.bak -e '
  my $source = quotemeta $ENV{CMC_SOURCE_ROLE};
  s/(.*^- exact )$source( SHA: `[0-9a-f]{40}`;\n)/${1}$ENV{CMC_WRONG_ROLE}$2/ms
    or die "current task role missing\n";
' "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md"
rm "${cmc_case}/docs/TASKS/TASK-040-ios-testflight-release.md.bak"
cmc_expect_fail task-role-mismatch "${cmc_case}" \
  'Ruolo revision task/manifest incoerente'

cmc_case="$(cmc_fixture manifest-role-mismatch)"
CMC_SOURCE_ROLE="${cmc_source_role}" CMC_WRONG_ROLE="${cmc_wrong_role}" \
  perl -0pi.bak -e '
  my $source = quotemeta $ENV{CMC_SOURCE_ROLE};
  s/(\| TASK-040 \|[^\n]*\| `[0-9a-f]{7,40}` )$source( \|)/${1}$ENV{CMC_WRONG_ROLE}$2/
    or die "current manifest role missing\n";
' "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
rm "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md.bak"
cmc_expect_fail manifest-role-mismatch "${cmc_case}" \
  'Ruolo revision task/manifest incoerente'

cmc_case="$(cmc_fixture worklog-label-mismatch)"
cmc_source_label="$(
  sed -nE 's/^- \*\*(Technical SHA|Exact HEAD)\*\*: `[0-9a-f]{40}`\.$/\1/p' \
    "${cmc_case}/docs/AI_WORKLOG.md" | tail -n 1
)"
[[ "${cmc_source_label}" == 'Technical SHA' ]] && \
  cmc_wrong_label='Exact HEAD' || cmc_wrong_label='Technical SHA'
CMC_SOURCE_LABEL="${cmc_source_label}" CMC_WRONG_LABEL="${cmc_wrong_label}" \
  perl -0pi.bak -e '
  my $source = quotemeta $ENV{CMC_SOURCE_LABEL};
  s/(.*^## [^\n]+ — TASK-040 Fix [^\n]+\n.*?^- \*\*)$source(\*\*: `[0-9a-f]{40}`\.)/${1}$ENV{CMC_WRONG_LABEL}$2/ms
    or die "current worklog revision label missing\n";
' "${cmc_case}/docs/AI_WORKLOG.md"
rm "${cmc_case}/docs/AI_WORKLOG.md.bak"
cmc_expect_fail worklog-label-mismatch "${cmc_case}" \
  'Ruolo worklog incoerente'

cmc_case="$(cmc_fixture worklog-heading-role-mismatch)"
cmc_source_suffix="$(
  sed -nE 's/^## [0-9-]+ — TASK-040 Fix [0-9]+ (e handoff|re-review)$/\1/p' \
    "${cmc_case}/docs/AI_WORKLOG.md" | tail -n 1
)"
[[ "${cmc_source_suffix}" == 'e handoff' ]] && \
  cmc_wrong_suffix='re-review' || cmc_wrong_suffix='e handoff'
CMC_SOURCE_SUFFIX="${cmc_source_suffix}" CMC_WRONG_SUFFIX="${cmc_wrong_suffix}" \
  perl -0pi.bak -e '
  my $source = quotemeta $ENV{CMC_SOURCE_SUFFIX};
  s/(.*^## [0-9-]+ — TASK-040 Fix [0-9]+ )$source$/${1}$ENV{CMC_WRONG_SUFFIX}/ms
    or die "current worklog heading role missing\n";
' "${cmc_case}/docs/AI_WORKLOG.md"
rm "${cmc_case}/docs/AI_WORKLOG.md.bak"
cmc_expect_fail worklog-heading-role-mismatch "${cmc_case}" \
  'Ruolo worklog incoerente'

cmc_expect_handoff_path README.md allowed
cmc_expect_handoff_path docs/TASKS/EVIDENCE/TASK-040/README.md allowed
cmc_expect_handoff_path test_driver/task_040_probe.dart denied
cmc_expect_handoff_path assets/release/app-icon-master.png denied
cmc_expect_handoff_path analysis_options.yaml denied
cmc_expect_post_sha_path_collection

printf 'Governance release train: %s/%s fixture PASS.\n' \
  "${cmc_assertion_count}" "${cmc_assertion_count}"
