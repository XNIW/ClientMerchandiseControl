#!/usr/bin/env bash
set -euo pipefail

cmc_repo_root="${CMC_GOVERNANCE_REPO_ROOT:-$(git rev-parse --show-toplevel)}"
cmc_authority_repo_root="$({ cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P; })"
source "${cmc_authority_repo_root}/scripts/lib/governance_path_policy.sh"
cmc_master_plan="${cmc_repo_root}/docs/MASTER-PLAN.md"
cmc_readme="${cmc_repo_root}/README.md"
cmc_worklog="${cmc_repo_root}/docs/AI_WORKLOG.md"
cmc_release_manifest="${cmc_repo_root}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
cmc_violation_count=0

cmc_reject_ambiguous_markdown() {
  local cmc_file="$1"
  local cmc_label="$2"
  local cmc_mode="${3:-all}"
  local cmc_raw_pattern='<!--|-->|^[ ]{0,3}<(\?|!\[CDATA\[|![[:upper:]]|/?[[:alpha:]][[:alnum:]-]*([[:space:]]|/?>|$))'
  local cmc_pattern="${cmc_raw_pattern}"

  if [[ "${cmc_mode}" == 'all' ]]; then
    cmc_pattern="${cmc_pattern}|^[[:space:]]*(\`\`\`|~~~)|^[[:space:]]+#{2,3}[[:space:]]"
  fi
  if grep -Eq "${cmc_pattern}" "${cmc_file}"; then
    printf '%s contiene commenti, fence o heading indentati non ammessi, oppure HTML: %s.\n' \
      "${cmc_label}" "${cmc_file}" >&2
    cmc_violation_count=$((cmc_violation_count + 1))
  fi
}

cmc_canonical_table_rows() {
  local cmc_file="$1"
  local cmc_section="$2"
  local cmc_header="$3"
  local cmc_delimiter="$4"

  awk \
    -v section="${cmc_section}" \
    -v header="${cmc_header}" \
    -v delimiter="${cmc_delimiter}" '
      $0 == section {
        section_count++
        in_section = section_count == 1
        next
      }
      in_section && /^## / {
        in_section = 0
        in_rows = 0
      }
      in_section && $0 == header {
        header_count++
        if (header_count == 1) {
          if ((getline next_line) <= 0 || next_line != delimiter) {
            invalid = 1
            next
          }
          in_rows = 1
        }
        next
      }
      in_rows {
        if ($0 ~ /^\|.*\|$/) {
          print
          row_count++
          next
        }
        in_rows = 0
      }
      END {
        if (section_count != 1 || header_count != 1 || invalid || row_count == 0) {
          exit 1
        }
      }
    ' "${cmc_file}"
}

cmc_git_commit_is_valid() {
  local cmc_revision="$1"

  [[ -n "${cmc_revision}" ]] &&
    git -C "${cmc_authority_repo_root}" cat-file -e \
      "${cmc_revision}^{commit}" 2>/dev/null &&
    git -C "${cmc_authority_repo_root}" merge-base --is-ancestor \
      "${cmc_revision}" HEAD
}

cmc_field() {
  local cmc_file="$1"
  local cmc_label="$2"

  sed -n "s/^- \\*\\*${cmc_label}\\*\\*: //p" "${cmc_file}" |
    head -n 1 |
    tr -d '`'
}

cmc_compare() {
  local cmc_label="$1"
  local cmc_expected="$2"
  local cmc_actual="$3"
  local cmc_source="$4"

  if [[ -z "${cmc_expected}" || -z "${cmc_actual}" ||
    "${cmc_expected}" != "${cmc_actual}" ]]; then
    printf '%s incoerente: Master Plan=%q, %s=%q\n' \
      "${cmc_label}" "${cmc_expected}" "${cmc_source}" "${cmc_actual}" >&2
    cmc_violation_count=$((cmc_violation_count + 1))
  fi
}

cmc_active_task="$(cmc_field "${cmc_master_plan}" "Task attivo")"
cmc_task_status="$(cmc_field "${cmc_master_plan}" "Stato task")"
cmc_phase="$(cmc_field "${cmc_master_plan}" "Fase")"
cmc_indicator="$(cmc_field "${cmc_master_plan}" "Indicatore")"
cmc_release_train="$(cmc_field "${cmc_master_plan}" "Release train")"
cmc_release_train_state="$(cmc_field "${cmc_master_plan}" "Stato release train")"
cmc_integrated_review="$(cmc_field "${cmc_master_plan}" "Review integrata")"

cmc_reject_ambiguous_markdown "${cmc_master_plan}" "Master Plan"
cmc_reject_ambiguous_markdown "${cmc_readme}" "README" raw-only
cmc_master_backlog_rows=''
if ! cmc_master_backlog_rows="$(
  cmc_canonical_table_rows \
    "${cmc_master_plan}" \
    '## Backlog completo' \
    '| ID | Titolo | Stato | Dipendenze | Repository interessati | Risultato atteso |' \
    '|---|---|---|---|---|---|'
)"; then
  printf 'Master Plan privo della tabella canonica Backlog completo.\n' >&2
  cmc_violation_count=$((cmc_violation_count + 1))
fi

cmc_compare \
  "Task attivo" \
  "${cmc_active_task}" \
  "$(cmc_field "${cmc_readme}" "Task attivo")" \
  "README"
cmc_compare \
  "Stato task" \
  "${cmc_task_status}" \
  "$(cmc_field "${cmc_readme}" "Stato task")" \
  "README"
cmc_compare \
  "Fase" \
  "${cmc_phase}" \
  "$(cmc_field "${cmc_readme}" "Fase")" \
  "README"
cmc_compare \
  "Indicatore" \
  "${cmc_indicator}" \
  "$(cmc_field "${cmc_readme}" "Indicatore")" \
  "README"

cmc_readme_summary_count="$(
  sed -nE \
    's/^TASK-040 è l.unico task `(ACTIVE \/ (FIX|REVIEW))`:.*$/\1/p' \
    "${cmc_readme}" | awk 'NF { count++ } END { print count + 0 }'
)"
cmc_readme_summary_state="$(
  sed -nE \
    's/^TASK-040 è l.unico task `(ACTIVE \/ (FIX|REVIEW))`:.*$/\1/p' \
    "${cmc_readme}"
)"
cmc_expected_readme_summary="${cmc_task_status} / ${cmc_phase}"
if [[ "${cmc_active_task}" == 'TASK-040' && \
  ( "${cmc_readme_summary_count}" -ne 1 || \
    "${cmc_readme_summary_state}" != "${cmc_expected_readme_summary}" ) ]]; then
  printf 'Riepilogo README TASK-040 incoerente: atteso=%q, ricevuto=%q, righe=%s.\n' \
    "${cmc_expected_readme_summary}" "${cmc_readme_summary_state}" \
    "${cmc_readme_summary_count}" >&2
  cmc_violation_count=$((cmc_violation_count + 1))
fi

cmc_active_task_normalized="$(
  printf '%s' "${cmc_active_task}" | tr '[:upper:]' '[:lower:]'
)"

if [[ "${cmc_active_task_normalized}" != "nessuno" ]]; then
  cmc_task_relative="$(cmc_field "${cmc_master_plan}" "File task")"
  cmc_task_file="${cmc_repo_root}/${cmc_task_relative}"

  if [[ ! -f "${cmc_task_file}" ]]; then
    printf 'File task attivo assente: %s\n' "${cmc_task_relative}" >&2
    cmc_violation_count=$((cmc_violation_count + 1))
  else
    cmc_compare \
      "Stato task" \
      "${cmc_task_status}" \
      "$(cmc_field "${cmc_task_file}" "Stato")" \
      "task attivo"
    cmc_compare \
      "Fase" \
      "${cmc_phase}" \
      "$(cmc_field "${cmc_task_file}" "Fase")" \
      "task attivo"
    cmc_compare \
      "Indicatore/Handoff" \
      "${cmc_indicator}" \
      "$(cmc_field "${cmc_task_file}" "Handoff")" \
      "task attivo"

    cmc_evidence_relative="$(cmc_field "${cmc_task_file}" "Evidence directory")"
    cmc_evidence_readme="${cmc_repo_root}/${cmc_evidence_relative%/}/README.md"

    if [[ ! -f "${cmc_evidence_readme}" ]]; then
      printf 'README evidence assente: %s\n' "${cmc_evidence_readme}" >&2
      cmc_violation_count=$((cmc_violation_count + 1))
    else
      cmc_snapshot="$(
        sed -n '/^Snapshot di handoff:$/{
          n
          s/^`//
          s/`\.$//
          p
          q
        }' "${cmc_evidence_readme}"
      )"
      cmc_expected_snapshot="${cmc_task_status} / ${cmc_phase} / ${cmc_indicator}"

      if [[ "${cmc_snapshot}" != "${cmc_expected_snapshot}" ]]; then
        printf 'Snapshot evidence incoerente: atteso=%q, ricevuto=%q\n' \
          "${cmc_expected_snapshot}" "${cmc_snapshot}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      fi
    fi

    cmc_last_fix_revision=''
    cmc_last_fix_number=''
    cmc_expected_worklog_suffix=''
    cmc_expected_worklog_revision_label=''
    if [[ "${cmc_release_train}" == "CLIENT_FINAL_PRODUCT_COMPLETION" ]]; then
      if [[ ! -f "${cmc_release_manifest}" ]]; then
        printf 'Release manifest assente: %s\n' "${cmc_release_manifest}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      else
        cmc_reject_ambiguous_markdown \
          "${cmc_release_manifest}" "Release manifest"
        cmc_manifest_rows=''
        if ! cmc_manifest_rows="$(
          cmc_canonical_table_rows \
            "${cmc_release_manifest}" \
            '## Sequenza e revision set' \
            '| Task | Stato | Client revision | Admin revision | PR/merge | Gate |' \
            '|---|---|---|---|---|---|'
        )"; then
          printf 'Release manifest privo della tabella canonica Sequenza e revision set.\n' >&2
          cmc_violation_count=$((cmc_violation_count + 1))
        fi
        cmc_manifest_global_row_count="$(
          awk -v task="${cmc_active_task}" '
            function trim(value) {
              gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
              return value
            }
            function table_row(line, columns, leading) {
              leading=0
              while (substr(line, 1, 1) == " " && leading < 4) {
                line=substr(line, 2)
                leading++
              }
              if (leading > 3 || substr(line, 1, 1) != "|" ||
                  substr(line, length(line), 1) != "|") return 0
              return split(line, cmc_fields, "|") == columns + 2
            }
            {
              if (table_row($0, 6) && trim(cmc_fields[2]) == task) count++
            }
            END { print count + 0 }
          ' "${cmc_release_manifest}"
        )"
        cmc_manifest_row_count="$(
          awk -v task="${cmc_active_task}" '
            function trim(value) {
              gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
              return value
            }
            function table_row(line, columns) {
              if (substr(line, 1, 1) != "|" ||
                  substr(line, length(line), 1) != "|") return 0
              return split(line, cmc_fields, "|") == columns + 2
            }
            table_row($0, 6) && trim(cmc_fields[2]) == task { count++ }
            END { print count + 0 }
          ' <<<"${cmc_manifest_rows}"
        )"
        cmc_manifest_status=''
        cmc_manifest_revision_field=''
        cmc_manifest_revision=''
        cmc_manifest_gate=''
        cmc_manifest_revision_role=''
        if [[ "${cmc_manifest_row_count}" -ne 1 || \
          "${cmc_manifest_global_row_count}" -ne 1 ]]; then
          printf 'Release manifest richiede esattamente una riga canonica per %s: canoniche=%s, globali=%s.\n' \
            "${cmc_active_task}" "${cmc_manifest_row_count}" \
            "${cmc_manifest_global_row_count}" >&2
          cmc_violation_count=$((cmc_violation_count + 1))
        else
          IFS=$'\t' read -r \
            cmc_manifest_status \
            cmc_manifest_revision_field \
            cmc_manifest_gate < <(
              awk -v task="${cmc_active_task}" '
                function trim(value) {
                  gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
                  return value
                }
                function table_row(line, columns, leading) {
                  leading=0
                  while (substr(line, 1, 1) == " " && leading < 4) {
                    line=substr(line, 2)
                    leading++
                  }
                  if (leading > 3 || substr(line, 1, 1) != "|" ||
                      substr(line, length(line), 1) != "|") return 0
                  return split(line, cmc_fields, "|") == columns + 2
                }
                table_row($0, 6) && trim(cmc_fields[2]) == task {
                  printf "%s\t%s\t%s\n", trim(cmc_fields[3]),
                    trim(cmc_fields[4]), trim(cmc_fields[7])
                }
              ' <<<"${cmc_manifest_rows}"
            )
          cmc_manifest_revision="$(
            sed -nE \
              's/^`([0-9a-f]{7,40})`( [[:alnum:]_-]+)?$/\1/p' \
              <<<"${cmc_manifest_revision_field}"
          )"
          if [[ -z "${cmc_manifest_revision}" ]]; then
            printf 'Release manifest revision non strutturata per %s: %q.\n' \
              "${cmc_active_task}" "${cmc_manifest_revision_field}" >&2
            cmc_violation_count=$((cmc_violation_count + 1))
          fi
          cmc_manifest_revision_role="$(
            sed -nE \
              's/^`[0-9a-f]{7,40}` ([[:alnum:]_-]+)$/\1/p' \
              <<<"${cmc_manifest_revision_field}"
          )"
        fi
        cmc_expected_manifest_status="${cmc_task_status} / ${cmc_phase}"
        if [[ "${cmc_manifest_status}" != "${cmc_expected_manifest_status}" ]]; then
          printf 'Release manifest status incoerente per %s: atteso=%q, ricevuto=%q.\n' \
            "${cmc_active_task}" "${cmc_expected_manifest_status}" \
            "${cmc_manifest_status}" >&2
          cmc_violation_count=$((cmc_violation_count + 1))
        fi

        if [[ "${cmc_active_task}" == 'TASK-040' ]]; then
          cmc_reject_ambiguous_markdown "${cmc_task_file}" "Task chronology"
          cmc_task_semantic="$(<"${cmc_task_file}")"

        cmc_fix_section_count="$(
          grep -Ec '^## Fix$' <<<"${cmc_task_semantic}" || true
        )"
        cmc_fix_section=''
        cmc_fix_heading_count=0
        cmc_global_fix_heading_count="$(
          grep -Ec '^### (Re-review )?Fix [0-9]+$' \
            <<<"${cmc_task_semantic}" || true
        )"
        cmc_expected_fix_number=1
        cmc_expected_fix_kind='Re-review'
        cmc_last_fix_heading=''
        if [[ "${cmc_fix_section_count}" -ne 1 ]]; then
          printf 'Task chronology richiede esattamente una sezione Fix: ricevute=%s.\n' \
            "${cmc_fix_section_count}" >&2
          cmc_violation_count=$((cmc_violation_count + 1))
        else
          cmc_fix_section="$(
            awk '
              /^## Fix$/ { capture=1; next }
              capture && /^## Chiusura$/ { exit }
              capture { print }
            ' <<<"${cmc_task_semantic}"
          )"
          while IFS= read -r cmc_fix_heading; do
            [[ -z "${cmc_fix_heading}" ]] && continue
            cmc_fix_heading_count=$((cmc_fix_heading_count + 1))
            cmc_last_fix_heading="${cmc_fix_heading}"
            if [[ "${cmc_expected_fix_kind}" == 'Re-review' ]]; then
              cmc_expected_heading="### Re-review Fix ${cmc_expected_fix_number}"
              cmc_expected_fix_kind='Fix'
              cmc_expected_fix_number=$((cmc_expected_fix_number + 1))
            else
              cmc_expected_heading="### Fix ${cmc_expected_fix_number}"
              cmc_expected_fix_kind='Re-review'
            fi
            if [[ "${cmc_fix_heading}" != "${cmc_expected_heading}" ]]; then
              printf 'Task chronology fuori sequenza: atteso=%q, ricevuto=%q.\n' \
                "${cmc_expected_heading}" "${cmc_fix_heading}" >&2
              cmc_violation_count=$((cmc_violation_count + 1))
            fi
          done < <(
            grep -E '^### (Re-review )?Fix [0-9]+$' \
              <<<"${cmc_fix_section}" || true
          )
        fi
        if [[ "${cmc_global_fix_heading_count}" -ne \
          "${cmc_fix_heading_count}" ]]; then
          printf 'Task chronology contiene cicli Fix fuori dalla sezione canonica: globali=%s, canonici=%s.\n' \
            "${cmc_global_fix_heading_count}" "${cmc_fix_heading_count}" >&2
          cmc_violation_count=$((cmc_violation_count + 1))
        fi
        if [[ "${cmc_fix_heading_count}" -eq 0 ]]; then
          printf 'Task chronology priva di cicli Fix strutturati per %s.\n' \
            "${cmc_active_task}" >&2
          cmc_violation_count=$((cmc_violation_count + 1))
        elif [[ "${cmc_phase}" == 'FIX' && \
          "${cmc_last_fix_heading}" != '### Re-review Fix '* ]]; then
          printf 'Task chronology incoerente con fase FIX: ultimo=%q.\n' \
            "${cmc_last_fix_heading}" >&2
          cmc_violation_count=$((cmc_violation_count + 1))
        elif [[ "${cmc_phase}" == 'REVIEW' && \
          "${cmc_last_fix_heading}" == '### Re-review Fix '* ]]; then
          printf 'Task chronology incoerente con fase REVIEW: ultimo=%q.\n' \
            "${cmc_last_fix_heading}" >&2
          cmc_violation_count=$((cmc_violation_count + 1))
        fi

        cmc_last_fix_line="$(
          grep -nE '^### (Re-review )?Fix [0-9]+$' \
            <<<"${cmc_fix_section}" | tail -n 1 | cut -d: -f1 || true
        )"
        if [[ ! "${cmc_last_fix_line}" =~ ^[0-9]+$ ]]; then
          printf 'Tail task Fix corrente assente per %s.\n' \
            "${cmc_active_task}" >&2
          cmc_violation_count=$((cmc_violation_count + 1))
        else
          cmc_last_fix_block="$(
            awk -v start="${cmc_last_fix_line}" '
              NR < start { next }
              NR > start && /^#{2,3} / { exit }
              { print }
            ' <<<"${cmc_fix_section}"
          )"
          cmc_last_fix_label="$(
            head -n 1 <<<"${cmc_last_fix_block}" | \
              sed -E 's/^### (Re-review )?(Fix [0-9]+)$/\2/'
          )"
          cmc_last_fix_number="${cmc_last_fix_label#Fix }"
          cmc_last_fix_revision_count="$(
            sed -nE \
              's/^- exact (technical|review) SHA: `([0-9a-f]{40})`;$/\2/p' \
              <<<"${cmc_last_fix_block}" | awk 'NF { count++ } END { print count + 0 }'
          )"
          cmc_last_fix_revision="$(
            sed -nE \
              's/^- exact (technical|review) SHA: `([0-9a-f]{40})`;$/\2/p' \
              <<<"${cmc_last_fix_block}"
          )"
          cmc_last_fix_revision_role="$(
            sed -nE \
              's/^- exact (technical|review) SHA: `[0-9a-f]{40}`;$/\1/p' \
              <<<"${cmc_last_fix_block}"
          )"
          cmc_last_fix_handoff_count="$(
            grep -Ec "^\`${cmc_indicator}\`\\.$" \
              <<<"${cmc_last_fix_block}" || true
          )"
          cmc_last_fix_semantic_line="$(
            sed '/^[[:space:]]*$/d' <<<"${cmc_last_fix_block}" | tail -n 1
          )"
          if [[ "${cmc_last_fix_revision_count}" -ne 1 ]]; then
            printf 'Tail task richiede una sola exact review/technical SHA per %s: ricevute=%s.\n' \
              "${cmc_active_task}" "${cmc_last_fix_revision_count}" >&2
            cmc_violation_count=$((cmc_violation_count + 1))
          fi
          cmc_expected_task_heading=''
          cmc_expected_revision_role=''
          cmc_expected_worklog_suffix=''
          cmc_expected_worklog_revision_label=''
          if [[ "${cmc_phase}" == 'REVIEW' ]]; then
            cmc_expected_task_heading="### Fix ${cmc_last_fix_number}"
            cmc_expected_revision_role='technical'
            cmc_expected_worklog_suffix='e handoff'
            cmc_expected_worklog_revision_label='Technical SHA'
          elif [[ "${cmc_phase}" == 'FIX' ]]; then
            cmc_expected_task_heading="### Re-review Fix ${cmc_last_fix_number}"
            cmc_expected_revision_role='review'
            cmc_expected_worklog_suffix='re-review'
            cmc_expected_worklog_revision_label='Exact HEAD'
          fi
          if [[ "${cmc_last_fix_heading}" != "${cmc_expected_task_heading}" || \
            "${cmc_last_fix_revision_role}" != "${cmc_expected_revision_role}" || \
            "${cmc_manifest_revision_role}" != "${cmc_expected_revision_role}" ]]; then
            printf 'Ruolo revision task/manifest incoerente con fase %s: heading=%q, task=%q, manifest=%q.\n' \
              "${cmc_phase}" "${cmc_last_fix_heading}" \
              "${cmc_last_fix_revision_role}" "${cmc_manifest_revision_role}" >&2
            cmc_violation_count=$((cmc_violation_count + 1))
          fi
          if [[ "${cmc_last_fix_handoff_count}" -ne 1 || \
            "${cmc_last_fix_semantic_line}" != "\`${cmc_indicator}\`." ]]; then
            printf 'Tail task incoerente con handoff %s per %s.\n' \
              "${cmc_indicator}" "${cmc_active_task}" >&2
            cmc_violation_count=$((cmc_violation_count + 1))
          fi
          if [[ -z "${cmc_last_fix_revision}" || \
            -z "${cmc_manifest_revision}" || \
            "${cmc_manifest_revision}" != \
              "${cmc_last_fix_revision:0:${#cmc_manifest_revision}}" ]]; then
            printf 'Release manifest revision incoerente per %s: task=%q, manifest=%q.\n' \
              "${cmc_active_task}" "${cmc_last_fix_revision}" \
              "${cmc_manifest_revision}" >&2
            cmc_violation_count=$((cmc_violation_count + 1))
          fi
          if ! cmc_git_commit_is_valid "${cmc_last_fix_revision}"; then
            printf 'Tail task revision inesistente o fuori lineage per %s: %q.\n' \
              "${cmc_active_task}" "${cmc_last_fix_revision}" >&2
            cmc_violation_count=$((cmc_violation_count + 1))
          fi
          cmc_manifest_resolved_revision=''
          if [[ -n "${cmc_manifest_revision}" ]]; then
            cmc_manifest_resolved_revision="$(
              git -C "${cmc_authority_repo_root}" rev-parse --verify \
                "${cmc_manifest_revision}^{commit}" 2>/dev/null || true
            )"
          fi
          if [[ -z "${cmc_manifest_resolved_revision}" || \
            "${cmc_manifest_resolved_revision}" != "${cmc_last_fix_revision}" ]]; then
            printf 'Release manifest revision non risolve univocamente lo SHA task per %s.\n' \
              "${cmc_active_task}" >&2
            cmc_violation_count=$((cmc_violation_count + 1))
          fi
          if [[ -z "${cmc_last_fix_label}" || \
            ("${cmc_manifest_gate}" != "${cmc_last_fix_label}" && \
              "${cmc_manifest_gate}" != "${cmc_last_fix_label} "*) ]]; then
            printf 'Release manifest gate incoerente per %s: task=%q, manifest=%q.\n' \
              "${cmc_active_task}" "${cmc_last_fix_label}" \
              "${cmc_manifest_gate}" >&2
            cmc_violation_count=$((cmc_violation_count + 1))
          fi

          cmc_latest_review_fix_subject="$(
            git -C "${cmc_authority_repo_root}" log -1 --format='%s' \
              --extended-regexp \
              --grep='^docs\(task-040\): record fix [0-9]+ review findings$' || true
          )"
          cmc_latest_review_fix_number="$(
            sed -nE \
              's/^docs\(task-040\): record fix ([0-9]+) review findings$/\1/p' \
              <<<"${cmc_latest_review_fix_subject}"
          )"
          cmc_expected_current_fix_number=''
          if [[ "${cmc_latest_review_fix_number}" =~ ^[0-9]+$ ]]; then
            if [[ "${cmc_phase}" == 'FIX' ]]; then
              cmc_expected_current_fix_number="${cmc_latest_review_fix_number}"
            elif [[ "${cmc_phase}" == 'REVIEW' ]]; then
              cmc_expected_current_fix_number=$((cmc_latest_review_fix_number + 1))
            fi
          fi
          if [[ -z "${cmc_expected_current_fix_number}" || \
            "${cmc_last_fix_number}" != "${cmc_expected_current_fix_number}" ]]; then
            printf 'Ciclo Fix corrente non ancorato alla chronology Git: atteso=%q, ricevuto=%q.\n' \
              "${cmc_expected_current_fix_number}" "${cmc_last_fix_number}" >&2
            cmc_violation_count=$((cmc_violation_count + 1))
          fi

          if [[ "${cmc_phase}" == 'REVIEW' && \
            -n "${cmc_last_fix_revision}" ]]; then
            cmc_post_revision_paths="$(
              mktemp "${TMPDIR:-/tmp}/cmc-governance-post-sha.XXXXXX"
            )"
            if cmc_governance_collect_post_sha_paths \
              "${cmc_authority_repo_root}" \
              "${cmc_last_fix_revision}" \
              "${cmc_post_revision_paths}"; then
              while IFS= read -r -d '' cmc_post_revision_path; do
                [[ -z "${cmc_post_revision_path}" ]] && continue
                if ! cmc_governance_path_is_handoff_document \
                  "${cmc_post_revision_path}"; then
                  printf 'Delta post-SHA tecnico contiene path non documentale: %s.\n' \
                    "${cmc_post_revision_path}" >&2
                  cmc_violation_count=$((cmc_violation_count + 1))
                fi
              done <"${cmc_post_revision_paths}"
            else
              printf 'Impossibile enumerare il delta post-SHA tecnico per %q.\n' \
                "${cmc_last_fix_revision}" >&2
              cmc_violation_count=$((cmc_violation_count + 1))
            fi
            rm -f -- "${cmc_post_revision_paths}"
          fi
        fi
        fi
      fi
    fi

    if [[ "${cmc_active_task}" == "TASK-040" && \
      -f "${cmc_evidence_readme}" ]]; then
      cmc_reject_ambiguous_markdown \
        "${cmc_evidence_readme}" "Evidence TASK-040"
      cmc_evidence_acceptance_rows=''
      if ! cmc_evidence_acceptance_rows="$(
        cmc_canonical_table_rows \
          "${cmc_evidence_readme}" \
          '## Matrice CA -> evidence' \
          '| CA | Evidence | Esito |' \
          '|---|---|---|'
      )"; then
        printf 'Evidence TASK-040 priva della tabella canonica Matrice CA -> evidence.\n' >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      fi
      cmc_evidence_test_rows=''
      if ! cmc_evidence_test_rows="$(
        cmc_canonical_table_rows \
          "${cmc_evidence_readme}" \
          '## Matrice T -> risultato' \
          '| Test | Esito | Evidence |' \
          '|---|---|---|'
      )"; then
        printf 'Evidence TASK-040 priva della tabella canonica Matrice T -> risultato.\n' >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      fi
      cmc_current_gate_heading_count="$(
        grep -Ec '^## Gate executor corrente — Fix [0-9]+$' \
          "${cmc_evidence_readme}" || true
      )"
      cmc_current_gate_fix_number="$(
        sed -nE \
          's/^## Gate executor corrente — Fix ([0-9]+)$/\1/p' \
          "${cmc_evidence_readme}"
      )"
      if [[ "${cmc_current_gate_heading_count}" -ne 1 || \
        "${cmc_current_gate_fix_number}" != "${cmc_last_fix_number}" ]]; then
        printf 'Gate executor corrente non allineato al ciclo Fix task: task=%q, evidence=%q.\n' \
          "${cmc_last_fix_number}" "${cmc_current_gate_fix_number}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      fi
      cmc_current_artifact_block="$(
        awk '
          /^## Artifact evidence corrente/ { capture=1; next }
          capture && /^## / { exit }
          capture { print }
        ' "${cmc_evidence_readme}"
      )"
      cmc_current_gate_block="$(
        awk '
          /^## Gate executor corrente/ { capture=1; next }
          capture && /^## / { exit }
          capture { print }
        ' "${cmc_evidence_readme}"
      )"
      cmc_artifact_revision_count="$(
        sed -nE 's/^- source exact SHA: `([0-9a-f]{7,40})`;$/\1/p' \
          <<<"${cmc_current_artifact_block}" | \
          awk 'NF { count++ } END { print count + 0 }'
      )"
      cmc_artifact_revision="$(
        sed -nE 's/^- source exact SHA: `([0-9a-f]{7,40})`;$/\1/p' \
          <<<"${cmc_current_artifact_block}"
      )"
      cmc_ios_fixture_count_rows="$(
        grep -Eo 'validator iOS avversariale [0-9]+/[0-9]+' \
          <<<"${cmc_current_gate_block}" | \
          awk 'NF { count++ } END { print count + 0 }'
      )"
      cmc_ios_fixture_count="$(
        grep -Eo 'validator iOS avversariale [0-9]+/[0-9]+' \
          <<<"${cmc_current_gate_block}" | awk '{print $4}' || true
      )"
      cmc_security_gate_count_rows="$(
        sed -nE \
          's/^- security source ([0-9]+); artifact ([0-9]+); fixture negative ([0-9]+)\/([0-9]+), positive ([0-9]+)\/([0-9]+);$/\1\t\2\t\3\t\4\t\5\t\6/p' \
          <<<"${cmc_current_gate_block}" | \
          awk 'NF { count++ } END { print count + 0 }'
      )"
      cmc_security_gate_counts="$(
        sed -nE \
          's/^- security source ([0-9]+); artifact ([0-9]+); fixture negative ([0-9]+)\/([0-9]+), positive ([0-9]+)\/([0-9]+);$/\1\t\2\t\3\t\4\t\5\t\6/p' \
          <<<"${cmc_current_gate_block}"
      )"
      if [[ "${cmc_artifact_revision_count}" -ne 1 ]]; then
        printf 'Artifact evidence corrente richiede una sola source exact SHA: ricevute=%s.\n' \
          "${cmc_artifact_revision_count}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      fi
      if [[ "${cmc_ios_fixture_count_rows}" -ne 1 ]]; then
        printf 'Gate executor corrente richiede un solo conteggio validator iOS: ricevuti=%s.\n' \
          "${cmc_ios_fixture_count_rows}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      fi
      if [[ "${cmc_security_gate_count_rows}" -ne 1 ]]; then
        printf 'Gate executor corrente richiede un solo conteggio security strutturato: ricevuti=%s.\n' \
          "${cmc_security_gate_count_rows}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      fi
      cmc_t02_global_row_count="$(
        awk '
          function trim(value) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            return value
          }
          function table_row(line, columns, leading) {
            leading=0
            while (substr(line, 1, 1) == " " && leading < 4) {
              line=substr(line, 2)
              leading++
            }
            if (leading > 3 || substr(line, 1, 1) != "|" ||
                substr(line, length(line), 1) != "|") return 0
            return split(line, cmc_fields, "|") == columns + 2
          }
          {
            if (table_row($0, 3) && trim(cmc_fields[2]) == "T-02") count++
          }
          END { print count + 0 }
        ' "${cmc_evidence_readme}"
      )"
      cmc_t02_row_count="$(
        awk '
          function trim(value) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            return value
          }
          split($0, fields, "|") == 5 && trim(fields[2]) == "T-02" { count++ }
          END { print count + 0 }
        ' <<<"${cmc_evidence_test_rows}"
      )"
      cmc_t03_global_row_count="$(
        awk '
          function trim(value) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            return value
          }
          function table_row(line, columns, leading) {
            leading=0
            while (substr(line, 1, 1) == " " && leading < 4) {
              line=substr(line, 2)
              leading++
            }
            if (leading > 3 || substr(line, 1, 1) != "|" ||
                substr(line, length(line), 1) != "|") return 0
            return split(line, cmc_fields, "|") == columns + 2
          }
          {
            if (table_row($0, 3) && trim(cmc_fields[2]) == "T-03") count++
          }
          END { print count + 0 }
        ' "${cmc_evidence_readme}"
      )"
      cmc_t03_row_count="$(
        awk '
          function trim(value) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            return value
          }
          split($0, fields, "|") == 5 && trim(fields[2]) == "T-03" { count++ }
          END { print count + 0 }
        ' <<<"${cmc_evidence_test_rows}"
      )"
      cmc_t02_status=''
      cmc_t02_evidence=''
      cmc_t03_status=''
      cmc_t03_evidence=''
      cmc_t07_row_count=''
      cmc_t07_status=''
      cmc_t07_evidence=''
      cmc_ca06_row_count="$(
        awk '
          function trim(value) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            return value
          }
          split($0, fields, "|") == 5 && trim(fields[2]) == "CA-06" { count++ }
          END { print count + 0 }
        ' <<<"${cmc_evidence_acceptance_rows}"
      )"
      cmc_ca06_global_row_count="$(
        awk '
          function trim(value) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            return value
          }
          function table_row(line, columns, leading) {
            leading=0
            while (substr(line, 1, 1) == " " && leading < 4) {
              line=substr(line, 2)
              leading++
            }
            if (leading > 3 || substr(line, 1, 1) != "|" ||
                substr(line, length(line), 1) != "|") return 0
            return split(line, fields, "|") == columns + 2
          }
          table_row($0, 3) && trim(fields[2]) == "CA-06" { count++ }
          END { print count + 0 }
        ' "${cmc_evidence_readme}"
      )"
      cmc_t04_row_count="$(
        awk '
          function trim(value) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            return value
          }
          split($0, fields, "|") == 5 && trim(fields[2]) == "T-04" { count++ }
          END { print count + 0 }
        ' <<<"${cmc_evidence_test_rows}"
      )"
      cmc_t04_global_row_count="$(
        awk '
          function trim(value) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            return value
          }
          function table_row(line, columns, leading) {
            leading=0
            while (substr(line, 1, 1) == " " && leading < 4) {
              line=substr(line, 2)
              leading++
            }
            if (leading > 3 || substr(line, 1, 1) != "|" ||
                substr(line, length(line), 1) != "|") return 0
            return split(line, fields, "|") == columns + 2
          }
          table_row($0, 3) && trim(fields[2]) == "T-04" { count++ }
          END { print count + 0 }
        ' "${cmc_evidence_readme}"
      )"
      cmc_ca06_status=''
      cmc_ca06_evidence=''
      cmc_t04_status=''
      cmc_t04_evidence=''
      if [[ "${cmc_ca06_row_count}" -eq 1 && \
        "${cmc_ca06_global_row_count}" -eq 1 ]]; then
        IFS=$'\t' read -r cmc_ca06_evidence cmc_ca06_status < <(
          awk '
            function trim(value) {
              gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
              return value
            }
            split($0, fields, "|") == 5 && trim(fields[2]) == "CA-06" {
              printf "%s\t%s\n", trim(fields[3]), trim(fields[4])
            }
          ' <<<"${cmc_evidence_acceptance_rows}"
        )
      else
        printf 'Matrice TASK-040 richiede esattamente una riga CA-06 canonica e globale: canoniche=%s, globali=%s.\n' \
          "${cmc_ca06_row_count}" "${cmc_ca06_global_row_count}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      fi
      if [[ "${cmc_t04_row_count}" -eq 1 && \
        "${cmc_t04_global_row_count}" -eq 1 ]]; then
        IFS=$'\t' read -r cmc_t04_status cmc_t04_evidence < <(
          awk '
            function trim(value) {
              gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
              return value
            }
            split($0, fields, "|") == 5 && trim(fields[2]) == "T-04" {
              printf "%s\t%s\n", trim(fields[3]), trim(fields[4])
            }
          ' <<<"${cmc_evidence_test_rows}"
        )
      else
        printf 'Matrice TASK-040 richiede esattamente una riga T-04 canonica e globale: canoniche=%s, globali=%s.\n' \
          "${cmc_t04_row_count}" "${cmc_t04_global_row_count}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      fi
      if [[ "${cmc_t02_row_count}" -ne 1 || \
        "${cmc_t02_global_row_count}" -ne 1 ]]; then
        printf 'Matrice TASK-040 richiede esattamente una riga T-02 canonica: canoniche=%s, globali=%s.\n' \
          "${cmc_t02_row_count}" "${cmc_t02_global_row_count}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      else
        IFS=$'\t' read -r cmc_t02_status cmc_t02_evidence < <(
          awk '
            function trim(value) {
              gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
              return value
            }
            function table_row(line, columns, leading) {
              leading=0
              while (substr(line, 1, 1) == " " && leading < 4) {
                line=substr(line, 2)
                leading++
              }
              if (leading > 3 || substr(line, 1, 1) != "|" ||
                  substr(line, length(line), 1) != "|") return 0
              return split(line, cmc_fields, "|") == columns + 2
            }
            table_row($0, 3) && trim(cmc_fields[2]) == "T-02" {
              printf "%s\t%s\n", trim(cmc_fields[3]), trim(cmc_fields[4])
            }
          ' <<<"${cmc_evidence_test_rows}"
        )
      fi
      if [[ "${cmc_t03_row_count}" -ne 1 || \
        "${cmc_t03_global_row_count}" -ne 1 ]]; then
        printf 'Matrice TASK-040 richiede esattamente una riga T-03 canonica: canoniche=%s, globali=%s.\n' \
          "${cmc_t03_row_count}" "${cmc_t03_global_row_count}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      else
        IFS=$'\t' read -r cmc_t03_status cmc_t03_evidence < <(
          awk '
            function trim(value) {
              gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
              return value
            }
            function table_row(line, columns, leading) {
              leading=0
              while (substr(line, 1, 1) == " " && leading < 4) {
                line=substr(line, 2)
                leading++
              }
              if (leading > 3 || substr(line, 1, 1) != "|" ||
                  substr(line, length(line), 1) != "|") return 0
              return split(line, cmc_fields, "|") == columns + 2
            }
            table_row($0, 3) && trim(cmc_fields[2]) == "T-03" {
              printf "%s\t%s\n", trim(cmc_fields[3]), trim(cmc_fields[4])
            }
          ' <<<"${cmc_evidence_test_rows}"
        )
      fi
      cmc_t07_global_row_count="$(
        awk '
          function trim(value) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            return value
          }
          function table_row(line, columns, leading) {
            leading=0
            while (substr(line, 1, 1) == " " && leading < 4) {
              line=substr(line, 2)
              leading++
            }
            if (leading > 3 || substr(line, 1, 1) != "|" ||
                substr(line, length(line), 1) != "|") return 0
            return split(line, cmc_fields, "|") == columns + 2
          }
          table_row($0, 3) && trim(cmc_fields[2]) == "T-07" { count++ }
          END { print count + 0 }
        ' "${cmc_evidence_readme}"
      )"
      cmc_t07_row_count="$(
        awk '
          function trim(value) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            return value
          }
          split($0, fields, "|") == 5 && trim(fields[2]) == "T-07" { count++ }
          END { print count + 0 }
        ' <<<"${cmc_evidence_test_rows}"
      )"
      if [[ "${cmc_t07_row_count}" -ne 1 || \
        "${cmc_t07_global_row_count}" -ne 1 ]]; then
        printf 'Matrice TASK-040 richiede esattamente una riga T-07 canonica: canoniche=%s, globali=%s.\n' \
          "${cmc_t07_row_count}" "${cmc_t07_global_row_count}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      else
        IFS=$'\t' read -r cmc_t07_status cmc_t07_evidence < <(
          awk '
            function trim(value) {
              gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
              return value
            }
            function table_row(line, columns, leading) {
              leading=0
              while (substr(line, 1, 1) == " " && leading < 4) {
                line=substr(line, 2)
                leading++
              }
              if (leading > 3 || substr(line, 1, 1) != "|" ||
                  substr(line, length(line), 1) != "|") return 0
              return split(line, cmc_fields, "|") == columns + 2
            }
            table_row($0, 3) && trim(cmc_fields[2]) == "T-07" {
              printf "%s\t%s\n", trim(cmc_fields[3]), trim(cmc_fields[4])
            }
          ' <<<"${cmc_evidence_test_rows}"
        )
      fi
      cmc_t02_revision="$(
        sed -nE \
          's/^clean release no-codesign e archive Xcode exact SHA `([0-9a-f]{7,40})`$/\1/p' \
          <<<"${cmc_t02_evidence}"
      )"
      cmc_t03_fixture_count="$(
        sed -nE \
          's/^.*fixture iOS ([0-9]+\/[0-9]+)$/\1/p' \
          <<<"${cmc_t03_evidence}"
      )"
      cmc_ios_fixture_passed="${cmc_ios_fixture_count%%/*}"
      cmc_ios_fixture_total="${cmc_ios_fixture_count##*/}"
      cmc_t03_fixture_passed="${cmc_t03_fixture_count%%/*}"
      cmc_t03_fixture_total="${cmc_t03_fixture_count##*/}"
      if [[ "${cmc_t02_status}" != 'PASS' || \
        -z "${cmc_artifact_revision}" || -z "${cmc_t02_revision}" || \
        "${cmc_t02_revision}" != "${cmc_artifact_revision:0:${#cmc_t02_revision}}" ]]; then
        printf 'Matrice T-02 incoerente con artifact evidence corrente: artifact=%q.\n' \
          "${cmc_artifact_revision}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      fi
      if [[ "${cmc_t03_status}" != 'PASS' || \
        -z "${cmc_ios_fixture_count}" || -z "${cmc_t03_fixture_count}" || \
        "${cmc_t03_fixture_count}" != "${cmc_ios_fixture_count}" || \
        ! "${cmc_ios_fixture_passed}" =~ ^[0-9]+$ || \
        ! "${cmc_ios_fixture_total}" =~ ^[0-9]+$ || \
        ! "${cmc_t03_fixture_passed}" =~ ^[0-9]+$ || \
        ! "${cmc_t03_fixture_total}" =~ ^[0-9]+$ || \
        "${cmc_ios_fixture_passed}" -eq 0 || \
        "${cmc_ios_fixture_passed}" -ne "${cmc_ios_fixture_total}" || \
        "${cmc_t03_fixture_passed}" -ne "${cmc_t03_fixture_total}" ]]; then
        printf 'Matrice T-03 incoerente con gate iOS corrente: gate=%q.\n' \
          "${cmc_ios_fixture_count}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      fi
      if [[ "${cmc_t07_status}" != 'NOT_RUN' || \
        "${cmc_t07_evidence}" != \
          "Fix ${cmc_last_fix_number} handoff pronto; re-review, PR/main CI e hygiene da eseguire" ]]; then
        printf 'Matrice T-07 incoerente con il ciclo Fix corrente: task=%q, evidence=%q.\n' \
          "${cmc_last_fix_number}" "${cmc_t07_evidence}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      fi
      IFS=$'\t' read -r \
        cmc_security_source_count \
        cmc_security_artifact_count \
        cmc_security_negative_passed \
        cmc_security_negative_total \
        cmc_security_positive_passed \
        cmc_security_positive_total \
        <<<"${cmc_security_gate_counts}"
      cmc_ca06_counts="$(
        sed -nE \
          's/^security source ([0-9]+) e app artifact ([0-9]+); config esterna assente$/\1\t\2/p' \
          <<<"${cmc_ca06_evidence}"
      )"
      IFS=$'\t' read -r cmc_ca06_source_count cmc_ca06_artifact_count \
        <<<"${cmc_ca06_counts}"
      cmc_t04_counts="$(
        sed -nE \
          's/^scanner ([0-9]+)\/([0-9]+) e fixture ([0-9]+)\/([0-9]+) \+ ([0-9]+)\/([0-9]+)$/\1\t\2\t\3\t\4\t\5\t\6/p' \
          <<<"${cmc_t04_evidence}"
      )"
      IFS=$'\t' read -r \
        cmc_t04_source_count \
        cmc_t04_artifact_count \
        cmc_t04_negative_passed \
        cmc_t04_negative_total \
        cmc_t04_positive_passed \
        cmc_t04_positive_total \
        <<<"${cmc_t04_counts}"
      if [[ "${cmc_ca06_status}" != 'PASS' || \
        -z "${cmc_security_source_count}" || \
        "${cmc_ca06_source_count}" != "${cmc_security_source_count}" || \
        "${cmc_ca06_artifact_count}" != "${cmc_security_artifact_count}" ]]; then
        printf 'Matrice CA-06 incoerente con il gate security corrente: gate=%q, evidence=%q.\n' \
          "${cmc_security_gate_counts}" "${cmc_ca06_evidence}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      fi
      if [[ "${cmc_t04_status}" != 'PASS' || \
        -z "${cmc_security_source_count}" || \
        ! "${cmc_security_source_count}" =~ ^[1-9][0-9]*$ || \
        ! "${cmc_security_artifact_count}" =~ ^[1-9][0-9]*$ || \
        "${cmc_t04_source_count}" != "${cmc_security_source_count}" || \
        "${cmc_t04_artifact_count}" != "${cmc_security_artifact_count}" || \
        "${cmc_t04_negative_passed}" != "${cmc_security_negative_passed}" || \
        "${cmc_t04_negative_total}" != "${cmc_security_negative_total}" || \
        "${cmc_t04_positive_passed}" != "${cmc_security_positive_passed}" || \
        "${cmc_t04_positive_total}" != "${cmc_security_positive_total}" || \
        ! "${cmc_security_negative_passed}" =~ ^[1-9][0-9]*$ || \
        "${cmc_security_negative_passed}" -ne "${cmc_security_negative_total}" || \
        ! "${cmc_security_positive_passed}" =~ ^[1-9][0-9]*$ || \
        "${cmc_security_positive_passed}" -ne "${cmc_security_positive_total}" ]]; then
        printf 'Matrice T-04 incoerente con il gate security corrente: gate=%q, evidence=%q.\n' \
          "${cmc_security_gate_counts}" "${cmc_t04_evidence}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      fi
      if ! cmc_git_commit_is_valid "${cmc_artifact_revision}"; then
        printf 'Artifact source SHA inesistente o fuori lineage: %q.\n' \
          "${cmc_artifact_revision}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      fi
    fi

    if [[ ! -f "${cmc_worklog}" ]]; then
      printf 'Worklog governance assente: %s\n' "${cmc_worklog}" >&2
      cmc_violation_count=$((cmc_violation_count + 1))
    else
      cmc_reject_ambiguous_markdown "${cmc_worklog}" "Worklog"
      cmc_last_worklog_line="$(
        grep -nE "^## .*— ${cmc_active_task}([[:space:]]|$)" \
          "${cmc_worklog}" | tail -n 1 | cut -d: -f1 || true
      )"
      if [[ ! "${cmc_last_worklog_line}" =~ ^[0-9]+$ ]]; then
        printf 'Worklog corrente assente per %s.\n' "${cmc_active_task}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      else
        cmc_last_global_worklog_line="$(
          grep -nE '^## ' "${cmc_worklog}" | tail -n 1 | \
            cut -d: -f1 || true
        )"
        cmc_last_worklog_block="$(
          awk -v start="${cmc_last_worklog_line}" '
            NR < start { next }
            NR > start && /^## / { exit }
            { print }
          ' "${cmc_worklog}"
        )"
        cmc_worklog_fix_number="$(
          head -n 1 <<<"${cmc_last_worklog_block}" | \
            sed -nE \
              "s/^## [0-9-]+ — ${cmc_active_task} Fix ([0-9]+) (e handoff|re-review)$/\\1/p"
        )"
        cmc_worklog_suffix="$(
          head -n 1 <<<"${cmc_last_worklog_block}" | \
            sed -nE \
              "s/^## [0-9-]+ — ${cmc_active_task} Fix [0-9]+ (e handoff|re-review)$/\\1/p"
        )"
        cmc_worklog_revision_count="$(
          sed -nE \
            's/^- \*\*(Technical SHA|Exact HEAD)\*\*: `([0-9a-f]{40})`\.$/\2/p' \
            <<<"${cmc_last_worklog_block}" | \
            awk 'NF { count++ } END { print count + 0 }'
        )"
        cmc_worklog_revision="$(
          sed -nE \
            's/^- \*\*(Technical SHA|Exact HEAD)\*\*: `([0-9a-f]{40})`\.$/\2/p' \
              <<<"${cmc_last_worklog_block}"
        )"
        cmc_worklog_revision_label="$(
          sed -nE \
            's/^- \*\*(Technical SHA|Exact HEAD)\*\*: `[0-9a-f]{40}`\.$/\1/p' \
            <<<"${cmc_last_worklog_block}"
        )"
        cmc_worklog_handoff_count="$(
          grep -Ec "^- \*\*Handoff\*\*: \`${cmc_indicator}\`\\.$" \
            <<<"${cmc_last_worklog_block}" || true
        )"
        if [[ "${cmc_last_global_worklog_line}" != \
          "${cmc_last_worklog_line}" ]]; then
          printf 'Worklog corrente non è l ultimo heading globale per %s.\n' \
            "${cmc_active_task}" >&2
          cmc_violation_count=$((cmc_violation_count + 1))
        fi
        if [[ "${cmc_worklog_handoff_count}" -ne 1 ]]; then
          printf 'Worklog corrente incoerente con handoff %s per %s.\n' \
            "${cmc_indicator}" "${cmc_active_task}" >&2
          cmc_violation_count=$((cmc_violation_count + 1))
        fi
        if [[ "${cmc_active_task}" == 'TASK-040' ]]; then
          if [[ "${cmc_worklog_revision_count}" -ne 1 || \
            "${cmc_worklog_revision}" != "${cmc_last_fix_revision}" ]]; then
            printf 'Worklog corrente non correlato allo SHA task per %s: worklog=%q, task=%q.\n' \
              "${cmc_active_task}" "${cmc_worklog_revision}" \
              "${cmc_last_fix_revision}" >&2
            cmc_violation_count=$((cmc_violation_count + 1))
          fi
          if [[ "${cmc_worklog_suffix}" != \
              "${cmc_expected_worklog_suffix}" || \
            "${cmc_worklog_revision_label}" != \
              "${cmc_expected_worklog_revision_label}" ]]; then
            printf 'Ruolo worklog incoerente con fase %s: heading=%q, revision=%q.\n' \
              "${cmc_phase}" "${cmc_worklog_suffix}" \
              "${cmc_worklog_revision_label}" >&2
            cmc_violation_count=$((cmc_violation_count + 1))
          fi
          if [[ "${cmc_worklog_fix_number}" != \
            "${cmc_last_fix_number}" ]]; then
            printf 'Worklog corrente non correlato al ciclo Fix task: worklog=%q, task=%q.\n' \
              "${cmc_worklog_fix_number}" "${cmc_last_fix_number}" >&2
            cmc_violation_count=$((cmc_violation_count + 1))
          fi
        fi
      fi
    fi
  fi
fi

cmc_global_table_active_count="$(
  awk -F'|' '
    /^\| TASK-[0-9][0-9][0-9] / {
      status=$4
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
      if (status == "ACTIVE") count++
    }
    END { print count + 0 }
  ' "${cmc_master_plan}"
)"
cmc_table_active_count="$(
  awk -F'|' '
    /^\| TASK-[0-9][0-9][0-9] / {
      status=$4
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
      if (status == "ACTIVE") count++
    }
    END { print count + 0 }
  ' <<<"${cmc_master_backlog_rows}"
)"
cmc_table_active_task="$(
  awk -F'|' '
    /^\| TASK-[0-9][0-9][0-9] / {
      task=$2
      status=$4
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", task)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
      if (status == "ACTIVE") {
        print task
        exit
      }
    }
  ' <<<"${cmc_master_backlog_rows}"
)"

if [[ "${cmc_global_table_active_count}" -ne "${cmc_table_active_count}" ]]; then
  printf 'Righe ACTIVE fuori dalla tabella canonica Backlog completo: globali=%s, canoniche=%s.\n' \
    "${cmc_global_table_active_count}" "${cmc_table_active_count}" >&2
  cmc_violation_count=$((cmc_violation_count + 1))
fi

if [[ "${cmc_active_task_normalized}" == "nessuno" ]]; then
  if [[ "${cmc_table_active_count}" -ne 0 ]]; then
    printf 'Master dichiara nessun task attivo ma la roadmap contiene %s ACTIVE.\n' \
      "${cmc_table_active_count}" >&2
    cmc_violation_count=$((cmc_violation_count + 1))
  fi
elif [[ "${cmc_task_status}" == "ACTIVE" ]]; then
  if [[ "${cmc_table_active_count}" -ne 1 ]]; then
    printf 'Un task corrente ACTIVE richiede esattamente una riga ACTIVE: ricevute=%s.\n' \
      "${cmc_table_active_count}" >&2
    cmc_violation_count=$((cmc_violation_count + 1))
  elif [[ "${cmc_table_active_task}" != "${cmc_active_task}" ]]; then
    printf 'Task ACTIVE in roadmap incoerente: header=%q, roadmap=%q.\n' \
      "${cmc_active_task}" "${cmc_table_active_task}" >&2
    cmc_violation_count=$((cmc_violation_count + 1))
  fi
elif [[ "${cmc_table_active_count}" -ne 0 ]]; then
  printf 'Un task corrente %s non può lasciare righe ACTIVE: ricevute=%s.\n' \
    "${cmc_task_status}" "${cmc_table_active_count}" >&2
  cmc_violation_count=$((cmc_violation_count + 1))
fi

if [[ "${cmc_release_train}" == "STOREFRONT_V1" ]]; then
  case "${cmc_release_train_state}" in
    PLANNING|EXECUTION|INTEGRATED_REVIEW|FIX|CLOSEOUT|COMPLETE|BLOCKED) ;;
    *)
      printf 'Stato release train non valido: %q.\n' "${cmc_release_train_state}" >&2
      cmc_violation_count=$((cmc_violation_count + 1))
      ;;
  esac

  case "${cmc_integrated_review}" in
    NOT_RUN|APPROVED|CHANGES_REQUIRED|BLOCKED|REJECTED) ;;
    *)
      printf 'Esito review integrata non valido: %q.\n' "${cmc_integrated_review}" >&2
      cmc_violation_count=$((cmc_violation_count + 1))
      ;;
  esac

  cmc_release_scope=(
    005 006 007 008 009 010
    013 014 015 016 017 018 019
    021 022 023 024 025 026 027 028 029 030 031 032
    033 034 035 036 037 038 039 040 041 042
  )

  for cmc_task_number in "${cmc_release_scope[@]}"; do
    cmc_row_status="$(
      awk -F'|' -v task="TASK-${cmc_task_number}" '
        $2 ~ "^[[:space:]]*" task "[[:space:]]*$" {
          status=$4
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
          print status
          exit
        }
      ' <<<"${cmc_master_backlog_rows}"
    )"

    case "${cmc_row_status}" in
      TODO|ACTIVE|BLOCKED|VALIDATED_PENDING_INTEGRATED_REVIEW|DONE) ;;
      *)
        printf 'Stato roadmap non valido per TASK-%s: %q.\n' \
          "${cmc_task_number}" "${cmc_row_status}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
        ;;
    esac

    if [[ "${cmc_row_status}" == "DONE" && "${cmc_integrated_review}" != "APPROVED" ]]; then
      printf 'TASK-%s non può essere DONE prima della review integrata APPROVED.\n' \
        "${cmc_task_number}" >&2
      cmc_violation_count=$((cmc_violation_count + 1))
    fi

    if [[ "${cmc_row_status}" == "VALIDATED_PENDING_INTEGRATED_REVIEW" ]]; then
      cmc_validated_files="$(
        find "${cmc_repo_root}/docs/TASKS" -maxdepth 1 -type f \
          -name "TASK-${cmc_task_number}-*.md"
      )"
      cmc_validated_file_count="$(printf '%s\n' "${cmc_validated_files}" | \
        awk 'NF { count++ } END { print count + 0 }')"
      if [[ "${cmc_validated_file_count}" -ne 1 ]]; then
        printf 'TASK-%s validato richiede esattamente un file task: ricevuti=%s.\n' \
          "${cmc_task_number}" "${cmc_validated_file_count}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      else
        cmc_validated_status="$(cmc_field "${cmc_validated_files}" "Stato")"
        if [[ "${cmc_validated_status}" != "VALIDATED_PENDING_INTEGRATED_REVIEW" ]]; then
          printf 'TASK-%s validato incoerente nel file task: %q.\n' \
            "${cmc_task_number}" "${cmc_validated_status}" >&2
          cmc_violation_count=$((cmc_violation_count + 1))
        fi
      fi
    fi
  done

  if [[ "${cmc_release_train_state}" == "INTEGRATED_REVIEW" && \
    "${cmc_table_active_count}" -ne 0 ]]; then
    printf 'Durante INTEGRATED_REVIEW nessun task può restare ACTIVE.\n' >&2
    cmc_violation_count=$((cmc_violation_count + 1))
  fi
fi

if [[ "${cmc_violation_count}" -ne 0 ]]; then
  printf 'Controllo governance fallito: %d violazione/i.\n' \
    "${cmc_violation_count}" >&2
  exit 1
fi

printf 'Governance coerente: %s / %s / %s / %s.\n' \
  "${cmc_active_task}" "${cmc_task_status}" "${cmc_phase}" "${cmc_indicator}"
