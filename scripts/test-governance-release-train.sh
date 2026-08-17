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
}

cmc_case="$(cmc_fixture valid)"
cmc_expect_pass valid "${cmc_case}"

cmc_case="$(cmc_fixture duplicate-active)"
sed -i.bak \
  's/| TASK-031 | Notifiche push e order status events | VALIDATED_PENDING_INTEGRATED_REVIEW |/| TASK-031 | Notifiche push e order status events | ACTIVE |/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_expect_fail duplicate-active "${cmc_case}" \
  'Un task corrente ACTIVE richiede esattamente una riga ACTIVE'

cmc_case="$(cmc_fixture wrong-active)"
sed -i.bak \
  's/- \*\*Task attivo\*\*: TASK-040/- **Task attivo**: TASK-008/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_expect_fail wrong-active "${cmc_case}" \
  'Task ACTIVE in roadmap incoerente'

cmc_case="$(cmc_fixture premature-done)"
sed -i.bak \
  's/| TASK-045 | Client live map, integrated acceptance and closeout | DONE |/| TASK-045 | Client live map, integrated acceptance and closeout | ACTIVE |/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_expect_fail premature-done "${cmc_case}" \
  'Un task corrente ACTIVE richiede esattamente una riga ACTIVE'

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
sed -i.bak \
  's/| TASK-040 | iOS TestFlight release | ACTIVE |/| TASK-040 | iOS TestFlight release | TODO |/' \
  "${cmc_case}/docs/MASTER-PLAN.md"
rm "${cmc_case}/docs/MASTER-PLAN.md.bak"
cmc_expect_fail active-header-without-active-row "${cmc_case}" \
  'Un task corrente ACTIVE richiede esattamente una riga ACTIVE'

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
  'Tail task incoerente con handoff'

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

printf 'Governance release train: 15/15 fixture PASS.\n'
