#!/usr/bin/env bash

cmc_governance_path_is_handoff_document() {
  local cmc_path="$1"

  case "${cmc_path}" in
    README.md|docs/MASTER-PLAN.md|docs/AI_WORKLOG.md|\
      docs/TASKS/TASK-040-ios-testflight-release.md|\
      docs/TASKS/EVIDENCE/TASK-040/README.md|\
      docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}
