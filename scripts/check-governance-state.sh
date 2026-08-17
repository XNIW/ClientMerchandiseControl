#!/usr/bin/env bash
set -euo pipefail

cmc_repo_root="${CMC_GOVERNANCE_REPO_ROOT:-$(git rev-parse --show-toplevel)}"
cmc_master_plan="${cmc_repo_root}/docs/MASTER-PLAN.md"
cmc_readme="${cmc_repo_root}/README.md"
cmc_worklog="${cmc_repo_root}/docs/AI_WORKLOG.md"
cmc_release_manifest="${cmc_repo_root}/docs/releases/CLIENT-FINAL-PRODUCT-COMPLETION-MANIFEST.md"
cmc_violation_count=0

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

    if [[ "${cmc_release_train}" == "CLIENT_FINAL_PRODUCT_COMPLETION" ]]; then
      if [[ ! -f "${cmc_release_manifest}" ]]; then
        printf 'Release manifest assente: %s\n' "${cmc_release_manifest}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      else
        cmc_manifest_row_count="$(
          awk -F'|' -v task="${cmc_active_task}" '
            {
              value=$2
              gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
              if (value == task) count++
            }
            END { print count + 0 }
          ' "${cmc_release_manifest}"
        )"
        cmc_manifest_status=''
        cmc_manifest_revision_field=''
        cmc_manifest_revision=''
        cmc_manifest_gate=''
        if [[ "${cmc_manifest_row_count}" -ne 1 ]]; then
          printf 'Release manifest richiede esattamente una riga per %s: ricevute=%s.\n' \
            "${cmc_active_task}" "${cmc_manifest_row_count}" >&2
          cmc_violation_count=$((cmc_violation_count + 1))
        else
          IFS=$'\t' read -r \
            cmc_manifest_status \
            cmc_manifest_revision_field \
            cmc_manifest_gate < <(
              awk -F'|' -v task="${cmc_active_task}" '
                function trim(value) {
                  gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
                  return value
                }
                trim($2) == task {
                  printf "%s\t%s\t%s\n", trim($3), trim($4), trim($7)
                }
              ' "${cmc_release_manifest}"
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
        fi
        cmc_expected_manifest_status="${cmc_task_status} / ${cmc_phase}"
        if [[ "${cmc_manifest_status}" != "${cmc_expected_manifest_status}" ]]; then
          printf 'Release manifest status incoerente per %s: atteso=%q, ricevuto=%q.\n' \
            "${cmc_active_task}" "${cmc_expected_manifest_status}" \
            "${cmc_manifest_status}" >&2
          cmc_violation_count=$((cmc_violation_count + 1))
        fi

        cmc_task_semantic="$(
          perl -0pe 's/<!--.*?-->//gs' "${cmc_task_file}"
        )"
        if grep -Eq '<!--|-->' "${cmc_task_file}"; then
          printf 'Task chronology non può contenere commenti HTML: %s.\n' \
            "${cmc_active_task}" >&2
          cmc_violation_count=$((cmc_violation_count + 1))
        fi

        cmc_fix_section_count="$(
          grep -Ec '^## Fix$' <<<"${cmc_task_semantic}" || true
        )"
        cmc_fix_heading_count=0
        cmc_expected_fix_number=1
        cmc_expected_fix_kind='Re-review'
        cmc_last_fix_heading=''
        if [[ "${cmc_fix_section_count}" -ne 1 ]]; then
          printf 'Task chronology richiede esattamente una sezione Fix: ricevute=%s.\n' \
            "${cmc_fix_section_count}" >&2
          cmc_violation_count=$((cmc_violation_count + 1))
        else
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
            awk '
              /^## Fix$/ { capture=1; next }
              capture && /^## Chiusura$/ { exit }
              capture && /^### (Re-review )?Fix [0-9]+$/ { print }
            ' <<<"${cmc_task_semantic}"
          )
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
            <<<"${cmc_task_semantic}" | tail -n 1 | cut -d: -f1 || true
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
            ' <<<"${cmc_task_semantic}"
          )"
          cmc_last_fix_label="$(
            head -n 1 <<<"${cmc_last_fix_block}" | \
              sed -E 's/^### (Re-review )?(Fix [0-9]+)$/\2/'
          )"
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
          if [[ "${cmc_last_fix_handoff_count}" -ne 1 || \
            "${cmc_last_fix_semantic_line}" != "\`${cmc_indicator}\`." ]]; then
            printf 'Tail task incoerente con handoff %s per %s.\n' \
              "${cmc_indicator}" "${cmc_active_task}" >&2
            cmc_violation_count=$((cmc_violation_count + 1))
          fi
          if [[ -z "${cmc_last_fix_revision}" || \
            "${cmc_manifest_revision}" != "${cmc_last_fix_revision:0:7}"* ]]; then
            printf 'Release manifest revision incoerente per %s: task=%q, manifest=%q.\n' \
              "${cmc_active_task}" "${cmc_last_fix_revision}" \
              "${cmc_manifest_revision}" >&2
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
        fi
      fi
    fi

    if [[ "${cmc_active_task}" == "TASK-040" && \
      -f "${cmc_evidence_readme}" ]]; then
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
      cmc_t02_row_count="$(
        grep -Ec '^\| T-02 \|' "${cmc_evidence_readme}" || true
      )"
      cmc_t03_row_count="$(
        grep -Ec '^\| T-03 \|' "${cmc_evidence_readme}" || true
      )"
      cmc_t02_status=''
      cmc_t02_evidence=''
      cmc_t03_status=''
      cmc_t03_evidence=''
      if [[ "${cmc_t02_row_count}" -ne 1 ]]; then
        printf 'Matrice TASK-040 richiede esattamente una riga T-02: ricevute=%s.\n' \
          "${cmc_t02_row_count}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      else
        IFS=$'\t' read -r cmc_t02_status cmc_t02_evidence < <(
          awk -F'|' '
            function trim(value) {
              gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
              return value
            }
            trim($2) == "T-02" { printf "%s\t%s\n", trim($3), trim($4) }
          ' "${cmc_evidence_readme}"
        )
      fi
      if [[ "${cmc_t03_row_count}" -ne 1 ]]; then
        printf 'Matrice TASK-040 richiede esattamente una riga T-03: ricevute=%s.\n' \
          "${cmc_t03_row_count}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      else
        IFS=$'\t' read -r cmc_t03_status cmc_t03_evidence < <(
          awk -F'|' '
            function trim(value) {
              gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
              return value
            }
            trim($2) == "T-03" { printf "%s\t%s\n", trim($3), trim($4) }
          ' "${cmc_evidence_readme}"
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
      if [[ "${cmc_t02_status}" != 'PASS' || \
        -z "${cmc_artifact_revision}" || -z "${cmc_t02_revision}" || \
        "${cmc_t02_revision}" != "${cmc_artifact_revision:0:${#cmc_t02_revision}}" ]]; then
        printf 'Matrice T-02 incoerente con artifact evidence corrente: artifact=%q.\n' \
          "${cmc_artifact_revision}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      fi
      if [[ "${cmc_t03_status}" != 'PASS' || \
        -z "${cmc_ios_fixture_count}" || -z "${cmc_t03_fixture_count}" || \
        "${cmc_t03_fixture_count}" != "${cmc_ios_fixture_count}" ]]; then
        printf 'Matrice T-03 incoerente con gate iOS corrente: gate=%q.\n' \
          "${cmc_ios_fixture_count}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      fi
    fi

    if [[ ! -f "${cmc_worklog}" ]]; then
      printf 'Worklog governance assente: %s\n' "${cmc_worklog}" >&2
      cmc_violation_count=$((cmc_violation_count + 1))
    else
      cmc_last_worklog_line="$(
        grep -nE "^## .*— ${cmc_active_task}([[:space:]]|$)" \
          "${cmc_worklog}" | tail -n 1 | cut -d: -f1 || true
      )"
      if [[ ! "${cmc_last_worklog_line}" =~ ^[0-9]+$ ]]; then
        printf 'Worklog corrente assente per %s.\n' "${cmc_active_task}" >&2
        cmc_violation_count=$((cmc_violation_count + 1))
      else
        cmc_last_worklog_block="$(
          awk -v start="${cmc_last_worklog_line}" '
            NR < start { next }
            NR > start && /^## / { exit }
            { print }
          ' "${cmc_worklog}"
        )"
        if ! grep -Fq -- "\`${cmc_indicator}\`" \
          <<<"${cmc_last_worklog_block}"; then
          printf 'Worklog corrente incoerente con handoff %s per %s.\n' \
            "${cmc_indicator}" "${cmc_active_task}" >&2
          cmc_violation_count=$((cmc_violation_count + 1))
        fi
      fi
    fi
  fi
fi

cmc_table_active_count="$(
  awk -F'|' '
    /^\| TASK-[0-9][0-9][0-9] / {
      status=$4
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
      if (status == "ACTIVE") count++
    }
    END { print count + 0 }
  ' "${cmc_master_plan}"
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
  ' "${cmc_master_plan}"
)"

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
      ' "${cmc_master_plan}"
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
