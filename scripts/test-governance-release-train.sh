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
grep -E '^\| TASK-040 \|' \
  "${cmc_case}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md" \
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
  s/(validator iOS avversariale )29\/29/${1}1\/29/
    or die "current iOS gate count missing\n";
  s/(^\| T-03 \|[^\n]*fixture iOS )29\/29/${1}1\/29/m
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

printf 'Governance release train: 44/44 fixture PASS.\n'
