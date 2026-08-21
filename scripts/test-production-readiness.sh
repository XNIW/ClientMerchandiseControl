#!/usr/bin/env bash
set -euo pipefail

cmc_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_repo_root="$(cd -- "${cmc_script_dir}/.." && pwd)"
cmc_checker="${cmc_script_dir}/check-production-readiness.sh"
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

cmc_technical_first="$("${cmc_checker}" --mode technical)"
cmc_require_contains "${cmc_technical_first}" 'MODE=technical STATUS=READY'

cmc_technical_second="$("${cmc_checker}" --mode technical)"
if [[ "${cmc_technical_first}" != "${cmc_technical_second}" ]]; then
  printf '%s\n' 'Technical mode non idempotente.' >&2
  exit 1
fi
cmc_pass

set +e
cmc_activation_missing="$(${cmc_checker} --mode activation 2>&1)"
cmc_activation_missing_status=$?
set -e
if [[ ${cmc_activation_missing_status} -eq 0 ]]; then
  printf '%s\n' 'Activation mode ha accettato prerequisiti esterni assenti.' >&2
  exit 1
fi
cmc_pass
cmc_require_contains "${cmc_activation_missing}" \
  'MODE=activation STATUS=MISSING'

if grep -Eo 'STATUS=[A-Z_]+' <<<"${cmc_activation_missing}" | \
  grep -Evq '^STATUS=(READY|MISSING|NOT_APPLICABLE|UNVERIFIABLE_EXTERNAL)$'; then
  printf '%s\n' 'Activation mode ha emesso uno stato non allowlisted.' >&2
  exit 1
fi
cmc_pass

cmc_activation_env=()
while IFS= read -r cmc_name; do
  [[ -z "${cmc_name}" ]] && continue
  cmc_activation_env+=("CMC_ACTIVATION_${cmc_name}=true")
done < <(
  awk -F'|' \
    '$1 == "external" || $1 == "optional" { print $3 }' \
    "${cmc_checker}"
)

cmc_activation_ready="$(env "${cmc_activation_env[@]}" \
  "${cmc_checker}" --mode activation)"
cmc_require_contains "${cmc_activation_ready}" \
  'MODE=activation STATUS=READY'

set +e
env "${cmc_activation_env[@]}" \
  CMC_ACTIVATION_MAPS_BILLING_APPROVAL=not_applicable \
  "${cmc_checker}" --mode activation >/dev/null 2>&1
cmc_isolated_optional_status=$?
set -e
if [[ ${cmc_isolated_optional_status} -eq 0 ]]; then
  printf '%s\n' 'Un N/A isolato ha superato il gate capability.' >&2
  exit 1
fi
cmc_pass

cmc_maps_not_applicable_env=()
while IFS= read -r cmc_assignment; do
  [[ -z "${cmc_assignment}" ]] && continue
  cmc_maps_not_applicable_env+=("${cmc_assignment}")
done < <(
  awk -F'|' '
    $1 == "external" { print "CMC_ACTIVATION_" $3 "=true" }
    $1 == "optional" {
      if ($3 == "ANDROID_MAPS_KEY_RESTRICTION" ||
          $3 == "IOS_MAPS_KEY_RESTRICTION" ||
          $3 ~ /^MAPS_/) {
        print "CMC_ACTIVATION_" $3 "=not_applicable"
      } else {
        print "CMC_ACTIVATION_" $3 "=true"
      }
    }
  ' "${cmc_checker}"
)

cmc_activation_optional="$(env "${cmc_maps_not_applicable_env[@]}" \
  CMC_ACTIVATION_MAPS_DISABLED=true \
  CMC_ACTIVATION_MAPS_FALLBACK_VERIFIED=true \
  "${cmc_checker}" --mode activation)"
cmc_require_contains "${cmc_activation_optional}" \
  'REQUIREMENT=MAPS_BILLING_APPROVAL STATUS=NOT_APPLICABLE'

set +e
env "${cmc_maps_not_applicable_env[@]}" \
  CMC_ACTIVATION_MAPS_DISABLED=true \
  "${cmc_checker}" --mode activation >/dev/null 2>&1
cmc_missing_fallback_status=$?
set -e
if [[ ${cmc_missing_fallback_status} -eq 0 ]]; then
  printf '%s\n' 'Capability N/A senza fallback verificato ha superato il gate.' >&2
  exit 1
fi
cmc_pass

set +e
env "${cmc_activation_env[@]}" \
  CMC_ACTIVATION_SUPABASE_PROJECT_IDENTIFIED=not_applicable \
  "${cmc_checker}" --mode activation >/dev/null 2>&1
cmc_required_not_applicable_status=$?
set -e
if [[ ${cmc_required_not_applicable_status} -eq 0 ]]; then
  printf '%s\n' 'Un requisito required ha accettato NOT_APPLICABLE.' >&2
  exit 1
fi
cmc_pass

cmc_redaction_sentinel='cmc-redaction-sentinel-do-not-print'
set +e
cmc_redaction_output="$(CMC_ACTIVATION_SUPABASE_URL="${cmc_redaction_sentinel}" \
  "${cmc_checker}" --mode activation 2>&1)"
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
  '(^|[[:space:]])(git[[:space:]]+push|gh[[:space:]]+pr|supabase[[:space:]]+db[[:space:]]+push|flutter[[:space:]]+build|xcodebuild[[:space:]])' \
  "${cmc_checker}"; then
  printf '%s\n' 'Il checker contiene un comando mutante o di build.' >&2
  exit 1
fi
cmc_pass

cmc_status_after="$(git status --porcelain=v1)"
if [[ "${cmc_status_before}" != "${cmc_status_after}" ]]; then
  printf '%s\n' 'Il test o il checker ha modificato il worktree.' >&2
  exit 1
fi
cmc_pass

printf 'PRODUCTION_READINESS_TESTS=%d/%d STATUS=READY\n' \
  "${cmc_assertions}" "${cmc_assertions}"
