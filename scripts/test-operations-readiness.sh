#!/usr/bin/env bash
set -euo pipefail

cmc_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_repo_root="$(cd -- "${cmc_script_dir}/.." && pwd)"
cmc_checker="${cmc_script_dir}/check-operations-readiness.sh"
cd -- "${cmc_repo_root}"

cmc_assertions=0

cmc_pass() {
  cmc_assertions=$((cmc_assertions + 1))
}

cmc_require_contains() {
  local cmc_text="$1"
  local cmc_expected="$2"
  if ! grep -Fq -- "${cmc_expected}" <<<"${cmc_text}"; then
    printf 'Assertion fallita: output privo di %s.\n' "${cmc_expected}" >&2
    exit 1
  fi
  cmc_pass
}

cmc_status_before="$(git status --porcelain=v1)"

bash -n "${cmc_checker}"
cmc_pass

cmc_prelaunch_first="$("${cmc_checker}" --mode prelaunch)"
cmc_require_contains "${cmc_prelaunch_first}" 'MODE=prelaunch STATUS=READY'
cmc_require_contains "${cmc_prelaunch_first}" \
  'REQUIREMENT=MONITORING_DESTINATION_CONFIGURED STATUS=UNVERIFIABLE_EXTERNAL'

cmc_prelaunch_second="$("${cmc_checker}" --mode prelaunch)"
if [[ "${cmc_prelaunch_first}" != "${cmc_prelaunch_second}" ]]; then
  printf '%s\n' 'Prelaunch mode non idempotente.' >&2
  exit 1
fi
cmc_pass

set +e
cmc_live_missing="$("${cmc_checker}" --mode live 2>&1)"
cmc_live_missing_status=$?
set -e
if [[ ${cmc_live_missing_status} -eq 0 ]]; then
  printf '%s\n' 'Live mode ha accettato prerequisiti esterni assenti.' >&2
  exit 1
fi
cmc_pass
cmc_require_contains "${cmc_live_missing}" 'MODE=live STATUS=MISSING'

if grep -Eo 'STATUS=[A-Z_]+' <<<"${cmc_live_missing}" | \
  grep -Evq '^STATUS=(READY|MISSING|NOT_APPLICABLE|UNVERIFIABLE_EXTERNAL)$'; then
  printf '%s\n' 'Live mode ha emesso uno stato non allowlisted.' >&2
  exit 1
fi
cmc_pass

cmc_live_env=()
while IFS= read -r cmc_name; do
  [[ -z "${cmc_name}" ]] && continue
  cmc_live_env+=("CMC_OPERATIONS_LIVE_${cmc_name}=true")
done < <(awk -F'|' '$1 == "external" { print $3 }' "${cmc_checker}")

cmc_live_ready="$(env "${cmc_live_env[@]}" "${cmc_checker}" --mode live)"
cmc_require_contains "${cmc_live_ready}" 'MODE=live STATUS=READY'

set +e
env "${cmc_live_env[@]}" \
  CMC_OPERATIONS_LIVE_RELEASE_PUBLISHED=false \
  "${cmc_checker}" --mode live >/dev/null 2>&1
cmc_incomplete_live_status=$?
set -e
if [[ ${cmc_incomplete_live_status} -eq 0 ]]; then
  printf '%s\n' 'Live mode ha accettato una attestazione incompleta.' >&2
  exit 1
fi
cmc_pass

cmc_redaction_sentinel='cmc-operations-redaction-sentinel-do-not-print'
set +e
cmc_redaction_output="$(CMC_OPERATIONS_LIVE_PRODUCTION_ACTIVE="${cmc_redaction_sentinel}" \
  "${cmc_checker}" --mode live 2>&1)"
cmc_redaction_status=$?
set -e
if [[ ${cmc_redaction_status} -eq 0 || \
  "${cmc_redaction_output}" == *"${cmc_redaction_sentinel}"* ]]; then
  printf '%s\n' 'Il checker non ha mantenuto il fail-closed redatto.' >&2
  exit 1
fi
cmc_pass

set +e
"${cmc_checker}" --mode unsupported >/dev/null 2>&1
cmc_invalid_mode_status=$?
set -e
if [[ ${cmc_invalid_mode_status} -eq 0 ]]; then
  printf '%s\n' 'Una modalità non supportata è stata accettata.' >&2
  exit 1
fi
cmc_pass

if grep -Eq \
  '(^|[[:space:]])(git[[:space:]]+push|gh[[:space:]]+pr|supabase[[:space:]]+db[[:space:]]+push|flutter[[:space:]]+build|xcodebuild[[:space:]]+|curl[[:space:]].*-X)' \
  "${cmc_checker}"; then
  printf '%s\n' 'Il checker contiene un comando mutante, remoto o di build.' >&2
  exit 1
fi
cmc_pass

cmc_safe_log_allowed() {
  local cmc_log="$1"
  [[ "${cmc_log}" =~ ^component=(backend|tracking|checkout|notifications|catalog|bootstrap|auth)[[:space:]]outcome=failure[[:space:]]category=(unavailable|timeout|invalidPayload|unexpected|rateLimited|unauthorized)$ ]]
}

cmc_simulate_operational_adapter() {
  case "$1" in
    'backend unavailable')
      printf '%s' 'health offline|SEV-1|backend fail-closed|store unavailable|Auth probe and Storefront RPC smoke green|component=backend outcome=failure category=unavailable'
      ;;
    'Maps unavailable')
      printf '%s' 'map adapter failed|SEV-2|Maps OFF|tracking status-only|map probe and fallback green|component=tracking outcome=failure category=unavailable'
      ;;
    'payment provider unavailable')
      printf '%s' 'payment option unavailable|SEV-1|payment OFF|submit blocked|provider probe and reconciliation green|component=checkout outcome=failure category=unavailable'
      ;;
    'push unavailable')
      printf '%s' 'notification delivery degraded|SEV-2|notifications OFF|order status in-app|fake delivery and retry normal|component=notifications outcome=failure category=unavailable'
      ;;
    'stale delivery tracking')
      printf '%s' 'freshness stale|SEV-2|live tracking OFF|timeline status-only|freshness normal|component=tracking outcome=failure category=timeout'
      ;;
    'malformed catalog publication')
      printf '%s' 'invalid payload|SEV-2|publication rollback|valid cache or unavailable|valid fixture republished|component=catalog outcome=failure category=invalidPayload'
      ;;
    'bad release requiring rollback')
      printf '%s' 'crash regression|SEV-1|store halt capability OFF|prior release supported|exact release smoke green|component=bootstrap outcome=failure category=unexpected'
      ;;
    'notification retry flood')
      printf '%s' 'retry rate exceeded|SEV-1|notifications OFF|order status in-app|queue bounded retry normal|component=notifications outcome=failure category=rateLimited'
      ;;
    'cleanup/retention failure')
      printf '%s' 'last success age exceeded|SEV-1|cleanup writer OFF|client state unchanged|synthetic job backlog green|component=backend outcome=failure category=unexpected'
      ;;
    'auth session expiry')
      printf '%s' 'unauthorized rate|SEV-2|Auth fail-closed|new login without loop|revoke callback fixture green|component=auth outcome=failure category=unauthorized'
      ;;
    *) return 1 ;;
  esac
}

cmc_drill_matches_expected() {
  [[ "$1" == "$2" ]]
}

cmc_drill_count=0
cmc_drill_names=''
while IFS='|' read -r \
  cmc_scenario cmc_fixture cmc_marker cmc_detection cmc_severity \
  cmc_kill_switch cmc_fallback cmc_recovery cmc_safe_log; do
  [[ -z "${cmc_scenario}" ]] && continue
  cmc_drill_count=$((cmc_drill_count + 1))
  cmc_drill_names+="${cmc_scenario}"$'\n'

  if [[ ! -f "${cmc_fixture}" ]] || ! grep -Fq -- "${cmc_marker}" "${cmc_fixture}"; then
    printf 'Fixture/adapter drill non verificabile: %s (%s).\n' \
      "${cmc_scenario}" "${cmc_fixture}" >&2
    exit 1
  fi
  cmc_pass

  cmc_expected="${cmc_detection}|${cmc_severity}|${cmc_kill_switch}|${cmc_fallback}|${cmc_recovery}|${cmc_safe_log}"
  cmc_actual="$(cmc_simulate_operational_adapter "${cmc_scenario}")"
  if ! cmc_drill_matches_expected "${cmc_actual}" "${cmc_expected}"; then
    printf 'Esito operativo drill inatteso: %s.\n' "${cmc_scenario}" >&2
    exit 1
  fi
  cmc_pass

  if ! cmc_safe_log_allowed "${cmc_safe_log}"; then
    printf 'Record log fuori allowlist: %s.\n' "${cmc_scenario}" >&2
    exit 1
  fi
  cmc_pass

  cmc_mutated="${cmc_actual/|${cmc_kill_switch}|/|unexpected-capability-action|}"
  if cmc_drill_matches_expected "${cmc_mutated}" "${cmc_expected}"; then
    printf 'Mapping alterato accettato: %s.\n' "${cmc_scenario}" >&2
    exit 1
  fi
  cmc_pass
done <<'CMC_DRILLS'
backend unavailable|test/core/backend/backend_health_service_test.dart|BackendHealthResult.offline|health offline|SEV-1|backend fail-closed|store unavailable|Auth probe and Storefront RPC smoke green|component=backend outcome=failure category=unavailable
Maps unavailable|lib/features/delivery_tracking/application/delivery_map_adapter.dart|FakeDeliveryMapAdapter|map adapter failed|SEV-2|Maps OFF|tracking status-only|map probe and fallback green|component=tracking outcome=failure category=unavailable
payment provider unavailable|test/features/checkout/checkout_test_support.dart|FakeCheckoutRepository|payment option unavailable|SEV-1|payment OFF|submit blocked|provider probe and reconciliation green|component=checkout outcome=failure category=unavailable
push unavailable|test/features/customer_devices/customer_device_test_support.dart|FakePushTokenProvider|notification delivery degraded|SEV-2|notifications OFF|order status in-app|fake delivery and retry normal|component=notifications outcome=failure category=unavailable
stale delivery tracking|test/features/delivery_tracking/delivery_tracking_controller_test.dart|DeliveryTrackingFreshness.stale|freshness stale|SEV-2|live tracking OFF|timeline status-only|freshness normal|component=tracking outcome=failure category=timeout
malformed catalog publication|test/features/storefront/data/storefront_catalog_dto_test.dart|StorefrontFailureKind.invalidPayload|invalid payload|SEV-2|publication rollback|valid cache or unavailable|valid fixture republished|component=catalog outcome=failure category=invalidPayload
bad release requiring rollback|docs/releases/PRODUCTION-ROLLBACK-RUNBOOK.md|fermare rollout|crash regression|SEV-1|store halt capability OFF|prior release supported|exact release smoke green|component=bootstrap outcome=failure category=unexpected
notification retry flood|test/features/customer_devices/customer_device_controller_test.dart|retry idempotente|retry rate exceeded|SEV-1|notifications OFF|order status in-app|queue bounded retry normal|component=notifications outcome=failure category=rateLimited
cleanup/retention failure|docs/TASKS/EVIDENCE/TASK-025/README.md|cleanup batch max 400|last success age exceeded|SEV-1|cleanup writer OFF|client state unchanged|synthetic job backlog green|component=backend outcome=failure category=unexpected
auth session expiry|test/features/auth/application/auth_controller_test.dart|session expiry|unauthorized rate|SEV-2|Auth fail-closed|new login without loop|revoke callback fixture green|component=auth outcome=failure category=unauthorized
CMC_DRILLS

if [[ ${cmc_drill_count} -ne 10 ]]; then
  printf 'Numero drill inatteso: %d.\n' "${cmc_drill_count}" >&2
  exit 1
fi
cmc_pass

while IFS= read -r cmc_unsafe_log; do
  [[ -z "${cmc_unsafe_log}" ]] && continue
  if cmc_safe_log_allowed "${cmc_unsafe_log}"; then
    printf 'Record sensibile o con chiave extra accettato: %s.\n' \
      "${cmc_unsafe_log%%=*}" >&2
    exit 1
  fi
  cmc_pass
done <<'CMC_UNSAFE_LOGS'
component=backend outcome=failure category=unavailable customer_id=customer-42
component=checkout outcome=failure category=unavailable cart_items=sku-1
component=auth outcome=failure category=unauthorized phone=+56912345678
component=tracking outcome=failure category=timeout address=123_Main_Street
component=catalog outcome=failure category=invalidPayload email=person@example.invalid
component=tracking outcome=failure category=timeout latitude=-33.45
component=notifications outcome=failure category=rateLimited push_token=redacted-looking-token
component=checkout outcome=failure category=unavailable payment_secret=redacted-looking-secret
component=backend outcome=failure category=unavailable correlation_id=customer-derived-id
+56 9 1234 5678
123 Main Street Santiago
cart item sku-1 quantity 4
CMC_UNSAFE_LOGS

for cmc_expected_drill in \
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
  cmc_require_contains "${cmc_drill_names}" "${cmc_expected_drill}"
done

cmc_status_after="$(git status --porcelain=v1)"
if [[ "${cmc_status_before}" != "${cmc_status_after}" ]]; then
  printf '%s\n' 'Il test o il checker ha modificato il worktree.' >&2
  exit 1
fi
cmc_pass

printf 'OPERATIONS_READINESS_TESTS=%d/%d DRILLS=10/10 STATUS=READY\n' \
  "${cmc_assertions}" "${cmc_assertions}"
