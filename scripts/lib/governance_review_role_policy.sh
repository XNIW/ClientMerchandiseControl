#!/usr/bin/env bash

cmc_governance_set_review_role_policy() {
  local cmc_policy_phase="$1"
  local cmc_policy_indicator="$2"

  cmc_governance_expected_revision_role=''
  cmc_governance_expected_worklog_suffix=''
  cmc_governance_expected_worklog_revision_label=''

  if [[ "${cmc_policy_phase}" == 'REVIEW' && \
    "${cmc_policy_indicator}" != 'CODEX_REVIEW_BLOCKED' ]]; then
    cmc_governance_expected_revision_role='technical'
    cmc_governance_expected_worklog_suffix='e handoff'
    cmc_governance_expected_worklog_revision_label='Technical SHA'
  elif [[ "${cmc_policy_phase}" == 'FIX' || \
    "${cmc_policy_indicator}" == 'CODEX_REVIEW_BLOCKED' ]]; then
    cmc_governance_expected_revision_role='review'
    cmc_governance_expected_worklog_suffix='re-review'
    cmc_governance_expected_worklog_revision_label='Exact HEAD'
  fi
}
