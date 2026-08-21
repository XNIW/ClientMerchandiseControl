#!/usr/bin/env bash

cmc_governance_set_review_role_policy() {
  local cmc_policy_phase="$1"
  local cmc_policy_indicator="$2"

  cmc_governance_expected_revision_role=''
  cmc_governance_expected_worklog_suffix=''
  cmc_governance_expected_worklog_revision_label=''

  case "${cmc_policy_phase}:${cmc_policy_indicator}" in
    REVIEW:CODEX_EXECUTION_COMPLETE_TO_REVIEW | \
      REVIEW:CODEX_FIX_COMPLETE_TO_RE_REVIEW | \
      REVIEW:CODEX_FIX_BLOCKED_TO_RE_REVIEW)
      cmc_governance_expected_revision_role='technical'
      cmc_governance_expected_worklog_suffix='e handoff'
      cmc_governance_expected_worklog_revision_label='Technical SHA'
      ;;
    REVIEW:CODEX_REVIEW_BLOCKED | \
      REVIEW:CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION | \
      FIX:CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX)
      cmc_governance_expected_revision_role='review'
      cmc_governance_expected_worklog_suffix='re-review'
      cmc_governance_expected_worklog_revision_label='Exact HEAD'
      ;;
  esac
}
