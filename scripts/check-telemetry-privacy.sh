#!/usr/bin/env bash
set -euo pipefail

cmc_telemetry_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmc_telemetry_repo_root="$(cd -- "${cmc_telemetry_script_dir}/.." && pwd)"
cd "${cmc_telemetry_repo_root}"

cmc_telemetry_event_file="lib/core/observability/observability_event.dart"
cmc_telemetry_port_file="lib/core/observability/observability_port.dart"

if [[ ! -f "${cmc_telemetry_event_file}" || ! -f "${cmc_telemetry_port_file}" ]]; then
  printf '%s\n' 'Telemetry privacy scan: boundary canonico mancante.' >&2
  exit 1
fi

# Nessun attributo di dominio sensibile può entrare nello schema tipizzato.
cmc_telemetry_forbidden_attribute="['\"](?:email|phone|address|latitude|longitude|coordinates|trackingUrl|trackingURL|token|oauthCode|paymentSecret|query|uuid|publicationId|orderId|cart|pushToken)['\"]"
if rg --quiet --pcre2 "${cmc_telemetry_forbidden_attribute}" \
  "${cmc_telemetry_event_file}"; then
  printf '%s\n' 'Telemetry privacy scan: attributo sensibile nello schema eventi.' >&2
  exit 1
fi

# Logger ed exporter restano confinati nel port centrale; le feature emettono solo
# factory tipizzate e non possono serializzare o esportare autonomamente.
cmc_telemetry_logger_files="$(
  rg --files-with-matches 'developer\.log\(' lib || true
)"
if [[ "${cmc_telemetry_logger_files}" != "${cmc_telemetry_port_file}" ]]; then
  printf '%s\n' 'Telemetry privacy scan: logger non confinato al port centrale.' >&2
  exit 1
fi

if rg --quiet '\b(?:debugPrint|print)\s*\(' lib; then
  printf '%s\n' 'Telemetry privacy scan: print/debugPrint vietato nel runtime.' >&2
  exit 1
fi

if rg --quiet \
  'toSafeMap\(|CrashSafeTelemetrySerializer|AnalyticsExporter|CrashReporter' \
  lib/features lib/app; then
  printf '%s\n' 'Telemetry privacy scan: serializzazione/export fuori dal boundary.' >&2
  exit 1
fi

cmc_telemetry_factory_count="$({
  rg --count '^  factory ObservabilityEvent\.' "${cmc_telemetry_event_file}" || true
} | tail -n 1)"
if [[ "${cmc_telemetry_factory_count}" != "12" ]]; then
  printf '%s\n' 'Telemetry privacy scan: catalogo eventi inatteso; review allowlist richiesta.' >&2
  exit 1
fi

printf '%s\n' \
  'Telemetry privacy scan: 12 eventi allowlisted, logger/export confinati, zero attributi sensibili.'
