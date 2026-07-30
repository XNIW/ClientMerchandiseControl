#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  flutter_bin="${FLUTTER_ROOT:-${HOME}/develop/flutter}/bin"
  if [[ ! -x "${flutter_bin}/flutter" ]]; then
    printf 'Flutter non trovato. Configurare PATH o FLUTTER_ROOT.\n' >&2
    exit 127
  fi
  export PATH="${flutter_bin}:${PATH}"
fi

flutter pub get
flutter gen-l10n
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
flutter build apk --debug
flutter build ios --simulator --debug
