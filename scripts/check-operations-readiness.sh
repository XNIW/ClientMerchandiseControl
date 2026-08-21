#!/usr/bin/env bash
set -euo pipefail

cmc_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_repo_root="$(cd -- "${cmc_script_dir}/.." && pwd)"
cd -- "${cmc_repo_root}"

cmc_mode=''
if [[ "${1:-}" == '--mode' && -n "${2:-}" && -z "${3:-}" ]]; then
  cmc_mode="$2"
else
  printf '%s\n' 'USAGE STATUS=MISSING SOURCE=--mode prelaunch-or-live OWNER=operations-owner VERIFY=use-an-allowed-mode' >&2
  exit 2
fi

case "${cmc_mode}" in
  prelaunch|live) ;;
  *)
    printf '%s\n' 'MODE STATUS=MISSING SOURCE=prelaunch-or-live OWNER=operations-owner VERIFY=use-an-allowed-mode' >&2
    exit 2
    ;;
esac

cmc_local_failures=0
cmc_live_failures=0

cmc_emit() {
  local cmc_requirement="$1"
  local cmc_status="$2"
  local cmc_source="$3"
  local cmc_owner="$4"
  local cmc_verify="$5"

  case "${cmc_status}" in
    READY|MISSING|NOT_APPLICABLE|UNVERIFIABLE_EXTERNAL) ;;
    *)
      printf '%s\n' 'CHECKER_STATUS STATUS=MISSING SOURCE=internal-contract OWNER=operations-owner VERIFY=review-checker' >&2
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
    cmc_local_failures=$((cmc_local_failures + 1))
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
    cmc_local_failures=$((cmc_local_failures + 1))
  fi
}

cmc_check_file OPERATIONS_RUNBOOK \
  docs/operations/POST-LAUNCH-OPERATIONS-RUNBOOK.md
cmc_check_file INCIDENT_RESPONSE docs/operations/INCIDENT-RESPONSE.md
cmc_check_file MONITORING_ALERTS docs/operations/MONITORING-AND-ALERTS.md
cmc_check_file KILL_SWITCH_RUNBOOK docs/operations/KILL-SWITCH-RUNBOOK.md
cmc_check_file OPERATIONS_READINESS_TEST scripts/test-operations-readiness.sh
cmc_check_file TASK_042_GOVERNANCE \
  docs/TASKS/TASK-042-post-launch-monitoring-support-maintenance.md
cmc_check_file TASK_042_EVIDENCE docs/TASKS/EVIDENCE/TASK-042/README.md
cmc_check_file OBSERVABILITY_RUNBOOK docs/operations/OBSERVABILITY-RUNBOOK.md
cmc_check_file PRODUCTION_ROLLBACK_RUNBOOK \
  docs/releases/PRODUCTION-ROLLBACK-RUNBOOK.md
cmc_check_file PRODUCTION_READINESS_CHECKER \
  scripts/check-production-readiness.sh
cmc_check_file TELEMETRY_PRIVACY_CHECKER scripts/check-telemetry-privacy.sh

for cmc_section in \
  '## Health check' \
  '## Synthetic smoke' \
  '## Release version tracking' \
  '## Alert triage' \
  '## Incident ownership' \
  '## Support flow' \
  '## Privacy request' \
  '## Account deletion' \
  '## Backup/restore' \
  '## Retention' \
  '## Provider outage' \
  '## Rollback' \
  '## Escalation' \
  '## Maintenance cadence' \
  '## Drill sintetici prelaunch'; do
  cmc_section_id="$(printf '%s' "${cmc_section:3}" | tr '[:lower:] /-' '[:upper:]___')"
  cmc_check_contains "OPERATIONS_${cmc_section_id}" \
    docs/operations/POST-LAUNCH-OPERATIONS-RUNBOOK.md "${cmc_section}"
done

for cmc_signal in \
  'backend availability' \
  'backend latency/error rate' \
  'auth failure rate' \
  'catalog RPC failure' \
  'checkout failure' \
  'order creation ambiguity' \
  'payment webhook failure' \
  'payment reconciliation mismatch' \
  'push notification degradation' \
  'delivery tracking stale rate' \
  'Realtime reconnect failure' \
  'Maps provider failure' \
  'crash-free sessions' \
  'release version adoption' \
  'cleanup/retention failure' \
  'account deletion failure'; do
  cmc_signal_id="$(printf '%s' "${cmc_signal}" | tr '[:lower:] /-' '[:upper:]___')"
  cmc_check_contains "ALERT_${cmc_signal_id}" \
    docs/operations/MONITORING-AND-ALERTS.md "${cmc_signal}"
done

for cmc_severity in SEV-0 SEV-1 SEV-2 SEV-3; do
  cmc_check_contains "INCIDENT_${cmc_severity}" \
    docs/operations/INCIDENT-RESPONSE.md "### ${cmc_severity}"
done

for cmc_incident_field in \
  '**Detection**' \
  '**Owner**' \
  '**Containment**' \
  '**Kill switch**' \
  '**Recovery**' \
  '**Communication template**' \
  '**Evidence**' \
  '**Postmortem**'; do
  cmc_incident_id="$(printf '%s' "${cmc_incident_field}" | tr -cd '[:alpha:]')"
  cmc_check_contains "INCIDENT_FIELD_${cmc_incident_id}" \
    docs/operations/INCIDENT-RESPONSE.md "${cmc_incident_field}"
done

for cmc_capability in \
  '## Maps' \
  '## Live courier tracking' \
  '## External carrier tracking' \
  '## Payments' \
  '## Notifications' \
  '## Non-essential telemetry' \
  '## Non-essential promotions'; do
  cmc_capability_id="$(printf '%s' "${cmc_capability:3}" | tr '[:lower:] /-' '[:upper:]___')"
  cmc_check_contains "KILL_SWITCH_${cmc_capability_id}" \
    docs/operations/KILL-SWITCH-RUNBOOK.md "${cmc_capability}"
done

for cmc_drill in \
  'backend unavailable' \
  'Maps unavailable' \
  'payment provider unavailable' \
  'push unavailable' \
  'stale delivery tracking' \
  'malformed catalog publication' \
  'bad release requiring rollback' \
  'notification retry flood' \
  'cleanup/retention failure' \
  'auth session expiry'; do
  cmc_drill_id="$(printf '%s' "${cmc_drill}" | tr '[:lower:] /-' '[:upper:]___')"
  cmc_check_contains "DRILL_${cmc_drill_id}" \
    docs/operations/POST-LAUNCH-OPERATIONS-RUNBOOK.md "${cmc_drill}"
done

cmc_check_contains OBSERVABILITY_NOOP_PRODUCTION \
  lib/core/observability/observability_providers.dart \
  'AppEnvironment.production => const NoopObservabilityPort()'
cmc_check_contains OBSERVABILITY_TYPED_EVENTS \
  lib/core/observability/observability_event.dart \
  'enum ObservabilityEventName'
cmc_check_contains OBSERVABILITY_REDACTOR \
  lib/core/observability/telemetry_redactor.dart \
  'final class TelemetryRedactor'
cmc_check_contains KILL_SWITCH_MAPS \
  lib/features/delivery_tracking/application/delivery_map_adapter.dart \
  "bool.fromEnvironment('DELIVERY_MAPS_ENABLED')"
cmc_check_contains KILL_SWITCH_TRACKING \
  lib/features/delivery_tracking/domain/delivery_tracking_models.dart \
  'enum DeliveryTrackingMode { statusOnly, externalCarrier, liveCourier }'
cmc_check_contains KILL_SWITCH_PAYMENT \
  lib/features/checkout/domain/checkout_models.dart \
  'enum OnlinePaymentConfiguration { notConfigured }'
cmc_check_contains KILL_SWITCH_NOTIFICATIONS \
  lib/features/customer_devices/data/unconfigured_push_token_provider.dart \
  'UnconfiguredPushTokenProvider'
cmc_check_contains EXTERNAL_MONITORING_CLASSIFICATION \
  docs/operations/MONITORING-AND-ALERTS.md \
  'EXTERNAL_MONITORING_DESTINATION_REQUIRED'
cmc_check_contains OWNER_VALUE_CLASSIFICATION \
  docs/operations/POST-LAUNCH-OPERATIONS-RUNBOOK.md \
  'NEEDS_OWNER_VALUE'

cmc_live_matrix() {
  cat <<'CMC_MATRIX'
external|required|PRODUCTION_ACTIVE|Production release owner|Production activation record
external|required|MONITORING_DESTINATION_CONFIGURED|Operations privacy owner|Approved monitoring destination
external|required|PRODUCTION_PROVIDERS_CONFIGURED|Provider owners|Provider activation or capability OFF record
external|required|RELEASE_PUBLISHED|Store release owner|Published release and version record
CMC_MATRIX
}

while IFS='|' read -r cmc_kind cmc_applicability cmc_name cmc_owner cmc_source; do
  [[ "${cmc_kind}" == 'external' && "${cmc_applicability}" == 'required' ]] || \
    continue
  if [[ "${cmc_mode}" == 'prelaunch' ]]; then
    cmc_emit "${cmc_name}" UNVERIFIABLE_EXTERNAL "${cmc_source}" "${cmc_owner}" \
      "test [REDACTED CMC_OPERATIONS_LIVE_${cmc_name}] = true"
  else
    cmc_flag="CMC_OPERATIONS_LIVE_${cmc_name}"
    if [[ "${!cmc_flag:-}" == 'true' ]]; then
      cmc_emit "${cmc_name}" READY "${cmc_source}" "${cmc_owner}" \
        "test [REDACTED CMC_OPERATIONS_LIVE_${cmc_name}] = true"
    else
      cmc_emit "${cmc_name}" MISSING "${cmc_source}" "${cmc_owner}" \
        "test [REDACTED CMC_OPERATIONS_LIVE_${cmc_name}] = true"
      cmc_live_failures=$((cmc_live_failures + 1))
    fi
  fi
done < <(cmc_live_matrix)

if [[ ${cmc_local_failures} -gt 0 ]]; then
  cmc_emit "MODE=${cmc_mode}" MISSING local-operations-contract repository-owner \
    'review-local-readiness-output'
  exit 1
fi

if [[ "${cmc_mode}" == 'live' && ${cmc_live_failures} -gt 0 ]]; then
  cmc_emit MODE=live MISSING external-live-activation operations-owner \
    'complete-redacted-live-attestations'
  exit 1
fi

cmc_emit "MODE=${cmc_mode}" READY local-operations-contract operations-owner \
  'readiness-contract-satisfied'
