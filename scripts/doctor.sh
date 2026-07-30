#!/usr/bin/env bash
set -euo pipefail

sanitize() {
  local machine_name
  machine_name="$(hostname)"
  sed -E \
    -e "s|${HOME}|<HOME>|g" \
    -e "s|${machine_name}|<HOST>|g" \
    -e 's/[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}/<DEVICE_ID>/g' \
    -e 's/iPhone di [^.]*/<PHYSICAL_IPHONE>/g'
}

printf 'System\n'
sw_vers | sanitize
uname -a | sanitize

printf '\nCore tools\n'
git --version
gh --version | head -n 1
printf 'GitHub account: %s\n' "$(gh api user --jq .login)"
flutter --version | sanitize
dart --version 2>&1 | sanitize

printf '\nApple tools\n'
xcodebuild -version
xcrun simctl list runtimes | sanitize
pod --version

printf '\nAndroid tools\n'
java -version 2>&1 | sanitize
android_sdk_path="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-${HOME}/Library/Android/sdk}}"
printf 'Android SDK: %s\n' "$(printf '%s' "$android_sdk_path" | sanitize)"
"${android_sdk_path}/platform-tools/adb" version | sanitize

printf '\nFlutter doctor\n'
flutter doctor -v | sanitize
