#!/usr/bin/env bash
set -euo pipefail

cmc_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=resolve-flutter.sh
source "${cmc_script_dir}/resolve-flutter.sh"

bash -n "${cmc_script_dir}"/*.sh
bash "${cmc_script_dir}/check-action-pins.sh"
git diff --check
git diff --cached --check
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
flutter build apk --debug
flutter build ios --simulator --debug
git diff --check
git diff --cached --check
