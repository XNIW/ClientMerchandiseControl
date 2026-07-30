# Migrazione governance Codex-only — TASK-001

## Emendamento

L'utente ha autorizzato esplicitamente il 2026-07-30 la migrazione della governance
operativa di TASK-001 a un workflow esclusivamente Codex. L'emendamento è registrato
come D-05 nel task e come ADR-006.

## Modifiche

- `AGENTS.md` è l'unica istruzione operativa root e contiene contesto, ordine di lettura,
  ruoli, stati, transizioni, gate, evidence, sicurezza, Git/GitHub e stop condition.
- Il precedente secondo file di istruzioni root è stato eliminato senza stub o redirect.
- `docs/CODEX-EXECUTION-PROTOCOL.md` è stato sostituito atomicamente da
  `docs/CODEX-WORKFLOW-PROTOCOL.md`; non esistono protocolli concorrenti.
- I ruoli logici sono `CODEX_PLANNER`, `CODEX_EXECUTOR`, `CODEX_REVIEWER`,
  `CODEX_FIXER`, `CODEX_RE_REVIEWER` e `USER_APPROVER`.
- Soltanto `USER_APPROVER` può autorizzare `DONE`, merge e attivazione del task
  successivo.
- README, contribution guide, security policy, quality gate, Definition of Done,
  environment, task template, Pull Request template, audit governance, task e Master
  Plan sono stati riallineati.
- CA-22 e T-23 rendono la migrazione verificabile senza alterare silenziosamente il
  contratto precedente.

## Audit riferimenti legacy

Comando:

```text
rg -n -i 'CLAUDE\.md|Claude|ChatGPT|Cursor|READY_FOR_CLAUDE_REVIEW' . \
  --hidden --glob '!.git/**' --glob '!.dart_tool/**' --glob '!build/**'
```

Classificazione dei risultati residui:

| Posizione | Classificazione | Motivazione |
|---|---|---|
| `docs/REFERENCES/GOVERNANCE-REFERENCE-AUDIT.md` | storico legittimo | nomi dei file letti nei repository sorgente il 2026-07-29; la nota li dichiara non operativi |
| `docs/TASKS/EVIDENCE/TASK-001/review-report.md` | storico legittimo | descrive il finding REV-001 osservato sul commit baseline, prima della migrazione |
| questo documento | falso positivo | contiene il comando di audit e la sua classificazione, non un'istruzione operativa |

Non restano istruzioni, responsabili, handoff o dipendenze operative assegnati a sistemi
esterni. Le occorrenze in `.git/` sono escluse perché appartengono alla storia Git, non
all'albero operativo.

## Verifiche

| Verifica | Stato | Evidenza |
|---|---|---|
| Unica istruzione root | PASS | `AGENTS.md` presente; secondo file root assente |
| Unico protocollo workflow | PASS | solo `docs/CODEX-WORKFLOW-PROTOCOL.md` |
| Ruoli e transizioni deterministiche | PASS | `AGENTS.md` e protocollo |
| Un solo task `ACTIVE` | PASS | `docs/MASTER-PLAN.md` |
| `USER_APPROVER` unico autorizzato a `DONE` e merge | PASS | governance e ADR-006 |
| Riferimenti legacy operativi | PASS | nessun risultato operativo nell'audit classificato |
| TASK-002 non attivato | PASS | stato `TODO` nel Master Plan |

Esito T-23: `PASS`.
