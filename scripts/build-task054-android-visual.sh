#!/usr/bin/env bash
set -euo pipefail
# Lo stesso target/define del drive canonico, prima di allocare l'AVD proprio.
cmc_visual_build_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${cmc_visual_build_script_dir}/resolve-flutter.sh"
flutter build apk --debug --no-pub \
  --target=integration_test/task054_visual_flow_test.dart \
  --dart-define=CMC_VISUAL_CAPTURE=true \
  --dart-define=CMC_OS_FRAME_CAPTURE=true
