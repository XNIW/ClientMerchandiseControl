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

cmc_governance_collect_post_sha_paths() {
  local cmc_repository="$1"
  local cmc_revision="$2"
  local cmc_destination="$3"

  git -C "${cmc_repository}" diff --no-renames --name-only -z \
    "${cmc_revision}..HEAD" -- >"${cmc_destination}"
}
