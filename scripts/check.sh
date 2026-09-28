#!/usr/bin/env bash
set -euo pipefail

cmc_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=resolve-flutter.sh
source "${cmc_script_dir}/resolve-flutter.sh"
cmc_backend_config=''
if [[ $# -gt 0 ]]; then
  [[ $# -eq 2 && "$1" == '--backend-config' ]] || {
    printf 'USAGE: check.sh [--backend-config /absolute/config.json]\n' >&2
    exit 2
  }
  cmc_backend_config="$2"
fi
flutter pub get --enforce-lockfile
python3 "${cmc_script_dir}/check-backend-compatibility.py" --source-only
PYTHONDONTWRITEBYTECODE=1 python3 "${cmc_script_dir}/test-backend-compatibility.py"
if [[ -n "${cmc_backend_config}" ]]; then
  python3 "${cmc_script_dir}/check-backend-compatibility.py" \
    --live --app-config "${cmc_backend_config}"
fi

bash -n "${cmc_script_dir}"/*.sh
bash "${cmc_script_dir}/check-action-pins.sh"
bash "${cmc_script_dir}/check-client-security.sh"
bash "${cmc_script_dir}/test-client-security-scan.sh"
bash "${cmc_script_dir}/check-telemetry-privacy.sh"
bash "${cmc_script_dir}/check-user-facing-localization.sh"
bash "${cmc_script_dir}/test-user-facing-localization-scan.sh"
bash "${cmc_script_dir}/check-governance-state.sh"
bash "${cmc_script_dir}/test-governance-release-train.sh"
bash "${cmc_script_dir}/check-architecture-boundaries.sh"
bash "${cmc_script_dir}/test-architecture-boundaries.sh"
git diff --check
git diff --cached --check
flutter gen-l10n
bash "${cmc_script_dir}/check-release-metadata.sh"
bash "${cmc_script_dir}/check-android-release.sh" --source-only
bash "${cmc_script_dir}/check-ios-release.sh" --source-only
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage --exclude-tags performance
CMC_TASK034_REPEAT_COUNT=5 bash "${cmc_script_dir}/test-task034-resilience-repeat.sh"
flutter test --tags performance --concurrency=1
flutter build apk --debug
flutter build ios --simulator --debug
git diff --check
git diff --cached --check
