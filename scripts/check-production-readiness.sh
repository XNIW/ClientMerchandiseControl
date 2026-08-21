#!/usr/bin/env bash
set -euo pipefail

cmc_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_repo_root="$(cd -- "${cmc_script_dir}/.." && pwd)"
cd -- "${cmc_repo_root}"

cmc_mode=''
if [[ "${1:-}" == '--mode' && -n "${2:-}" && -z "${3:-}" ]]; then
  cmc_mode="$2"
else
  printf '%s\n' 'USAGE STATUS=MISSING SOURCE=--mode technical-or-activation OWNER=release-owner VERIFY=use-an-allowed-mode' >&2
  exit 2
fi

case "${cmc_mode}" in
  technical|activation) ;;
  *)
    printf '%s\n' 'MODE STATUS=MISSING SOURCE=technical-or-activation OWNER=release-owner VERIFY=use-an-allowed-mode' >&2
    exit 2
    ;;
esac

cmc_technical_failures=0
cmc_activation_failures=0

cmc_emit() {
  local cmc_requirement="$1"
  local cmc_status="$2"
  local cmc_source="$3"
  local cmc_owner="$4"
  local cmc_verify="$5"

  case "${cmc_status}" in
    READY|MISSING|NOT_APPLICABLE|UNVERIFIABLE_EXTERNAL) ;;
    *)
      printf '%s\n' 'CHECKER_STATUS STATUS=MISSING SOURCE=internal-contract OWNER=release-owner VERIFY=review-checker' >&2
      exit 3
      ;;
  esac

  printf 'REQUIREMENT=%s STATUS=%s SOURCE=%s OWNER=%s VERIFY=%s\n' \
    "${cmc_requirement}" "${cmc_status}" "${cmc_source}" "${cmc_owner}" \
    "${cmc_verify}"
}

cmc_check_file() {
  local cmc_requirement="$1"
  local cmc_path="$2"
  if [[ -f "${cmc_path}" ]]; then
    cmc_emit "${cmc_requirement}" READY "${cmc_path}" repository-owner \
      "test -f ${cmc_path}"
  else
    cmc_emit "${cmc_requirement}" MISSING "${cmc_path}" repository-owner \
      "test -f ${cmc_path}"
    cmc_technical_failures=$((cmc_technical_failures + 1))
  fi
}

cmc_check_contains() {
  local cmc_requirement="$1"
  local cmc_path="$2"
  local cmc_pattern="$3"
  if [[ -f "${cmc_path}" ]] && grep -Fq -- "${cmc_pattern}" "${cmc_path}"; then
    cmc_emit "${cmc_requirement}" READY "${cmc_path}" repository-owner \
      "grep -F [REDACTED_PATTERN] ${cmc_path}"
  else
    cmc_emit "${cmc_requirement}" MISSING "${cmc_path}" repository-owner \
      "grep -F [REDACTED_PATTERN] ${cmc_path}"
    cmc_technical_failures=$((cmc_technical_failures + 1))
  fi
}

cmc_check_absent_regex() {
  local cmc_requirement="$1"
  local cmc_path="$2"
  local cmc_pattern="$3"
  if [[ -f "${cmc_path}" ]] && ! grep -Eiq -- "${cmc_pattern}" "${cmc_path}"; then
    cmc_emit "${cmc_requirement}" READY "${cmc_path}" security-owner \
      "grep -Ei [REDACTED_FORBIDDEN_PATTERN] ${cmc_path} expects-no-match"
  else
    cmc_emit "${cmc_requirement}" MISSING "${cmc_path}" security-owner \
      "grep -Ei [REDACTED_FORBIDDEN_PATTERN] ${cmc_path} expects-no-match"
    cmc_technical_failures=$((cmc_technical_failures + 1))
  fi
}

cmc_check_file PRODUCTION_ACTIVATION_CHECKLIST \
  docs/releases/PRODUCTION-ACTIVATION-CHECKLIST.md
cmc_check_file PRODUCTION_LAUNCH_RUNBOOK \
  docs/releases/PRODUCTION-LAUNCH-RUNBOOK.md
cmc_check_file PRODUCTION_ROLLBACK_RUNBOOK \
  docs/releases/PRODUCTION-ROLLBACK-RUNBOOK.md
cmc_check_file PRODUCTION_READINESS_TEST \
  scripts/test-production-readiness.sh
cmc_check_file TASK_041_GOVERNANCE \
  docs/TASKS/TASK-041-production-launch-rollback-runbook.md
cmc_check_file TASK_041_EVIDENCE \
  docs/TASKS/EVIDENCE/TASK-041/README.md
cmc_check_file ANDROID_RELEASE_VALIDATOR scripts/check-android-release.sh
cmc_check_file IOS_RELEASE_VALIDATOR scripts/check-ios-release.sh
cmc_check_file RELEASE_METADATA_VALIDATOR scripts/check-release-metadata.sh
cmc_check_file CLIENT_SECURITY_VALIDATOR scripts/check-client-security.sh
cmc_check_file TELEMETRY_PRIVACY_VALIDATOR scripts/check-telemetry-privacy.sh

for cmc_section in \
  '## A. Preflight' \
  '## B. Backup' \
  '## C. Migration order' \
  '## D. Backend activation' \
  '## E. Provider activation' \
  '## F. Store release activation' \
  '## G. Canary' \
  '## H. Smoke test' \
  '## I. Monitoring iniziale' \
  '## J. Rollback decision' \
  '## K. Rollback execution' \
  '## L. Recovery verification'; do
  cmc_check_contains "LAUNCH_ORDER_${cmc_section:3:1}" \
    docs/releases/PRODUCTION-LAUNCH-RUNBOOK.md "${cmc_section}"
done

for cmc_domain in SUPABASE AUTH ANDROID IOS MAPS PAYMENTS NOTIFICATIONS OBSERVABILITY LEGAL/STORE; do
  cmc_check_contains "ACTIVATION_MATRIX_${cmc_domain//\//_}" \
    docs/releases/PRODUCTION-ACTIVATION-CHECKLIST.md "## ${cmc_domain}"
done

cmc_check_contains ANDROID_CANDIDATE_ATTESTED \
  docs/TASKS/EVIDENCE/TASK-039/README.md \
  'DONE / REVIEW / USER_APPROVED_DONE'
cmc_check_contains IOS_CANDIDATE_ATTESTED \
  docs/TASKS/EVIDENCE/TASK-040/README.md \
  'DONE / REVIEW / USER_APPROVED_DONE'
cmc_check_contains CONFIGURATION_CONTRACT_SUPABASE \
  config/release_configuration_matrix.json '"name": "supabaseUrlPublicKey"'
cmc_check_contains CONFIGURATION_CONTRACT_MAPS \
  config/release_configuration_matrix.json '"name": "maps"'
cmc_check_contains CONFIGURATION_CONTRACT_PAYMENT \
  config/release_configuration_matrix.json '"name": "payment"'
cmc_check_contains CONFIGURATION_CONTRACT_NOTIFICATIONS \
  config/release_configuration_matrix.json '"name": "notifications"'
cmc_check_contains CONFIGURATION_CONTRACT_OBSERVABILITY \
  config/release_configuration_matrix.json '"name": "crashReporting"'
cmc_check_contains CONFIGURATION_CONTRACT_TRACKING \
  config/release_configuration_matrix.json '"name": "tracking"'
cmc_check_contains KILL_SWITCH_MAPS \
  lib/features/delivery_tracking/application/delivery_map_adapter.dart \
  "bool.fromEnvironment('DELIVERY_MAPS_ENABLED')"
cmc_check_contains KILL_SWITCH_TRACKING_MODES \
  lib/features/delivery_tracking/domain/delivery_tracking_models.dart \
  'enum DeliveryTrackingMode { statusOnly, externalCarrier, liveCourier }'
cmc_check_contains KILL_SWITCH_PAYMENT \
  lib/features/checkout/data/supabase_checkout_repository.dart \
  'option.method == CheckoutPaymentMethod.onlinePayment &&'
cmc_check_contains KILL_SWITCH_NOTIFICATIONS \
  lib/features/customer_devices/data/unconfigured_push_token_provider.dart \
  'UnconfiguredPushTokenProvider'
cmc_check_contains KILL_SWITCH_TELEMETRY \
  lib/core/observability/observability_providers.dart \
  'AppEnvironment.production => const NoopObservabilityPort()'
cmc_check_contains KILL_SWITCH_PROMOTIONS \
  docs/releases/PRODUCTION-ROLLBACK-RUNBOOK.md \
  'promozioni non essenziali: sospendere publication/promozione lato Admin'
cmc_check_absent_regex SERVICE_ROLE_ABSENT_FROM_RELEASE_TEMPLATE \
  config/app_config.production.release.json \
  'service[_-]?role|sb_secret_|private[_-]?key|webhook[_-]?secret'

cmc_activation_matrix() {
  cat <<'CMC_MATRIX'
external|required|SUPABASE_PROJECT_IDENTIFIED|Backend owner|Supabase production project settings
external|required|SUPABASE_URL|Backend owner|Release secret store
external|required|SUPABASE_PUBLISHABLE_KEY|Backend owner|Release secret store
local|required|SUPABASE_SERVICE_ROLE_ABSENT_CLIENT|Security owner|Client security validator
local|required|SUPABASE_MIGRATION_INVENTORY|Database owner|Admin migration inventory at pinned SHA
external|required|SUPABASE_BACKUP_VERIFIED|Database owner|Production backup record
external|required|SUPABASE_RESTORE_PLAN|Database owner|Owner-approved restore plan
external|required|SUPABASE_RLS|Database security owner|Production RLS verification
external|required|SUPABASE_GRANTS|Database security owner|Production grants verification
external|required|SUPABASE_REALTIME|Backend owner|Realtime publication and quota
external|required|SUPABASE_SCHEDULED_CLEANUP|Database owner|Cleanup schedule and alert
external|required|SUPABASE_PAYMENT_WEBHOOK|Payment backend owner|Signed production webhook
external|required|SUPABASE_NOTIFICATION_PIPELINE|Notification owner|Production dispatcher and dead-letter
external|required|SUPABASE_DELIVERY_TRACKING|Operations owner|Tracking migration RLS retention and mode
external|required|SUPABASE_SHOP_TIMEZONE|Product backend owner|Owner-approved IANA timezone
local|required|SUPABASE_ROLLBACK_FORWARD_FIX|Release database owner|Production rollback runbook
external|required|AUTH_PROVIDER_PRODUCTION|Identity owner|Production identity provider
external|required|AUTH_REDIRECT_HTTPS|Identity web owner|Owned HTTPS redirect
external|required|AUTH_ANDROID_APP_LINKS|Android web owner|Asset Links association
external|required|AUTH_IOS_UNIVERSAL_LINKS|iOS web owner|AASA association
external|required|AUTH_CALLBACK_ALLOWLIST|Identity owner|Exact provider callback allowlist
local|required|AUTH_LOGOUT_REVOKE|Identity owner|TASK-020 lifecycle evidence
local|required|AUTH_SESSION_LIFECYCLE|Identity owner|TASK-020 session evidence
local|required|ANDROID_RELEASE_CANDIDATE|Android release owner|TASK-039 evidence
local|required|ANDROID_APPLICATION_ID|Android release owner|Release source contract
local|required|ANDROID_VERSION|Android release owner|Release metadata
external|required|ANDROID_SIGNING|Android release owner|Approved upload signing identity
external|required|ANDROID_PLAY_CONSOLE_ACCESS|Store owner|Play Console application access
external|required|ANDROID_INTERNAL_TRACK_STATE|Store owner|Internal track release record
external|required|ANDROID_APP_LINKS|Android web owner|Owned domain and association
optional|optional|ANDROID_FCM|Notification owner|Production FCM project and sender
optional|optional|ANDROID_MAPS_KEY_RESTRICTION|Maps owner|Package and signing restricted key
external|required|ANDROID_PRIVACY_STORE_METADATA|Privacy store owner|Approved Data safety and listing
local|required|IOS_RELEASE_CANDIDATE|iOS release owner|TASK-040 evidence
local|required|IOS_BUNDLE_ID|iOS release owner|Release source contract
local|required|IOS_VERSION_BUILD|iOS release owner|Release metadata
external|required|IOS_APPLE_DISTRIBUTION|iOS release owner|Approved Distribution identity
external|required|IOS_PROVISIONING|iOS release owner|Approved App Store profile
external|required|IOS_APP_STORE_CONNECT|Store owner|App Store Connect record and role
external|required|IOS_UNIVERSAL_LINKS|iOS web owner|AASA association
optional|optional|IOS_APNS|Notification owner|Production APNs key entitlement and sender
optional|optional|IOS_MAPS_KEY_RESTRICTION|Maps owner|Bundle restricted key
local|required|IOS_PRIVACY_MANIFEST|Privacy iOS owner|Validated privacy manifest
external|required|IOS_TESTFLIGHT_STATUS|Store owner|Processed build and authorized group
optional|optional|MAPS_BILLING_APPROVAL|Maps billing owner|Maps billing account
optional|optional|MAPS_QUOTA|Maps operations owner|Quota and alert policy
optional|optional|MAPS_ANDROID_RESTRICTED_KEY|Maps owner|Android restricted key
optional|optional|MAPS_IOS_RESTRICTED_KEY|Maps owner|iOS restricted key
optional|optional|MAPS_APP_RESTRICTIONS|Maps owner|Package bundle and certificate restrictions
optional|optional|MAPS_USAGE_MONITORING|Maps operations owner|Usage alert destination
local|required|MAPS_ROTATION_PROCEDURE|Security Maps owner|Rollback runbook
local|required|MAPS_LEAK_RESPONSE|Security Maps owner|Rollback runbook
local|required|MAPS_KILL_SWITCH|Operations owner|Fail-closed double gate
optional|optional|PAYMENTS_PROVIDER_PRODUCTION|Payment owner|Production payment provider
optional|optional|PAYMENTS_MERCHANT_ACCOUNT|Payment owner|Approved merchant account
optional|optional|PAYMENTS_WEBHOOK_ENDPOINT|Payment backend owner|Production HTTPS webhook
optional|optional|PAYMENTS_SIGNATURE_SECRET|Payment security owner|Secret store and rotation
local|required|PAYMENTS_RETRY_IDEMPOTENCY|Payment backend owner|TASK-032 contract
optional|optional|PAYMENTS_RECONCILIATION|Finance payment owner|Reconciliation cadence and alert
optional|optional|PAYMENTS_REFUND_CANCEL|Payment support owner|Provider-specific procedure
local|required|PAYMENTS_KILL_SWITCH|Operations payment owner|Server-authoritative notConfigured
optional|optional|NOTIFICATIONS_FCM|Notification owner|Production FCM configuration
optional|optional|NOTIFICATIONS_APNS|Notification owner|Production APNs configuration
optional|optional|NOTIFICATIONS_CREDENTIALS|Notification security owner|Secret store and rotation
local|required|NOTIFICATIONS_DEVICE_REGISTRATION|Backend mobile owner|TASK-022 lifecycle
external|required|NOTIFICATIONS_CONSENT|Privacy product owner|Approved consent disclosure
local|required|NOTIFICATIONS_RETRY_DEAD_LETTER|Backend operations owner|TASK-031 contract
local|required|NOTIFICATIONS_KILL_SWITCH|Operations owner|Unconfigured provider fallback
optional|optional|OBSERVABILITY_CRASH_ADAPTER|Operations privacy owner|Reviewed production crash adapter
optional|optional|OBSERVABILITY_ANALYTICS_ADAPTER|Product privacy owner|Reviewed analytics adapter
external|required|OBSERVABILITY_PRIVACY_CONSENT|Privacy product owner|Approved consent and sampling
local|required|OBSERVABILITY_PII_REDACTION|Security privacy owner|Typed schema and privacy scanner
external|required|OBSERVABILITY_ALERT_DESTINATION|Operations owner|Production alert destination
local|required|OBSERVABILITY_RELEASE_VERSION|Release owner|Candidate version and build
local|required|OBSERVABILITY_ENVIRONMENT_SEPARATION|Operations security owner|Production no-op and attested config
external|required|LEGAL_OWNER_VALUES|Legal owner|Approved entity address copyright and trader values
external|required|LEGAL_PRIVACY_URL|Privacy web owner|Published HTTPS privacy policy
external|required|LEGAL_SUPPORT_CONTACT|Support owner|Published support URL and real contact
external|required|LEGAL_ACCOUNT_DELETION|Identity privacy owner|Published deletion URL and verified workflow
external|required|LEGAL_STORE_QUESTIONNAIRES|Privacy store owner|Approved App Privacy and Data safety
external|required|LEGAL_DESCRIPTIONS|Product brand owner|Approved store descriptions
external|required|LEGAL_SCREENSHOTS|Brand store owner|Sanitized signed-candidate screenshots
local|required|LEGAL_OPEN_SOURCE_ATTRIBUTION|Legal release owner|LicensePage and attribution document
CMC_MATRIX
}

while IFS='|' read -r cmc_kind cmc_applicability cmc_name cmc_owner cmc_source; do
  [[ -z "${cmc_kind}" ]] && continue
  cmc_status=''
  cmc_verify=''
  if [[ "${cmc_kind}" == 'local' ]]; then
    if [[ ${cmc_technical_failures} -eq 0 ]]; then
      cmc_status=READY
    else
      cmc_status=MISSING
    fi
    cmc_verify='rerun-technical-mode'
  elif [[ "${cmc_mode}" == 'technical' ]]; then
    cmc_status=UNVERIFIABLE_EXTERNAL
    cmc_verify="test [REDACTED CMC_ACTIVATION_${cmc_name}] = true"
  else
    cmc_flag="CMC_ACTIVATION_${cmc_name}"
    cmc_value="${!cmc_flag:-}"
    if [[ "${cmc_value}" == 'true' ]]; then
      cmc_status=READY
    elif [[ "${cmc_kind}" == 'optional' && \
      "${cmc_applicability}" == 'optional' && \
      "${cmc_value}" == 'not_applicable' ]]; then
      cmc_status=NOT_APPLICABLE
    else
      cmc_status=MISSING
      cmc_activation_failures=$((cmc_activation_failures + 1))
    fi
    cmc_verify="test [REDACTED ${cmc_flag}] = true"
  fi
  cmc_emit "${cmc_name}" "${cmc_status}" "${cmc_source}" "${cmc_owner}" \
    "${cmc_verify}"
done < <(cmc_activation_matrix)

if [[ ${cmc_technical_failures} -ne 0 ]]; then
  printf 'MODE=%s STATUS=MISSING SOURCE=repository OWNER=repository-owner VERIFY=repair-technical-requirements\n' \
    "${cmc_mode}"
  exit 1
fi

if [[ "${cmc_mode}" == 'activation' && ${cmc_activation_failures} -ne 0 ]]; then
  printf '%s\n' 'MODE=activation STATUS=MISSING SOURCE=external-activation OWNER=release-owner VERIFY=complete-owner-attestations'
  exit 1
fi

printf 'MODE=%s STATUS=READY SOURCE=readiness-contract OWNER=release-owner VERIFY=completed\n' \
  "${cmc_mode}"
