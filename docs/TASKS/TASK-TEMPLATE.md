# TASK-XXX — Titolo

## Informazioni generali

- **Task ID**: TASK-XXX
- **Titolo**:
- **File task**: `docs/TASKS/TASK-XXX-slug.md`
- **Stato**: TODO | ACTIVE | BLOCKED | DONE |
  VALIDATED_PENDING_INTEGRATED_REVIEW (solo `STOREFRONT_V1`)
- **Fase**: PLANNING | EXECUTION | REVIEW | FIX |
  INTEGRATED_REVIEW (solo `STOREFRONT_V1`)
- **Responsabile**: uno tra `CODEX_PLANNER`, `CODEX_EXECUTOR`, `CODEX_REVIEWER`,
  `CODEX_FIXER`, `CODEX_RE_REVIEWER`, `USER_APPROVER`
- **Data creazione**: YYYY-MM-DD
- **Ultimo aggiornamento**: YYYY-MM-DD
- **Ultimo agente**:
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-XXX/`
- **Handoff**:

## Dipendenze

- **Dipende da**:
- **Sblocca**:

## Scope

## Contesto

## Non incluso

## File coinvolti

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 |  |  |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01 |  |  |

## Decisioni

Le decisioni superate restano visibili con stato `OBSOLETA`.

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 |  |  | ATTIVA / OBSOLETA |

## Planning — `CODEX_PLANNER`

### Obiettivo

### Analisi

### Approccio

### Rischi

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION
- **Autorizzazione USER_APPROVER**: non ricevuta

## Execution — `CODEX_EXECUTOR`

### Obiettivo compreso

### File controllati

### Piano minimo

### Modifiche fatte

### Check eseguiti

### Matrice CA -> evidence

### Matrice T-NN -> risultato

### Rischi rimasti

### Handoff a Review

- **Prossima fase**: REVIEW
- **Prossimo ruolo**: CODEX_REVIEWER
- **Handoff**: CODEX_EXECUTION_COMPLETE_TO_REVIEW

## Checkpoint release train — `CODEX_EXECUTOR`

Compilare soltanto per un task incluso in `STOREFRONT_V1`. Il checkpoint non è una
review e non assegna un outcome.

### Gate pertinenti eseguiti

### Compatibilità e smoke staging

### Security scan mirato

### Stato manifest/checkpoint

### Handoff al task successivo

- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Review outcome**: NOT_RUN
- **Prossimo task**:
- **Handoff**: STOREFRONT_V1_MILESTONE_CHECKPOINT_VALIDATED

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

Per `STOREFRONT_V1` questa sezione resta vuota fino alla review integrata finale e
registra il revision manifest condiviso, non una review intermedia del singolo task.

### Problemi critici

### Problemi medi

### Miglioramenti opzionali

### Fix richiesti

### Esito

`APPROVED` | `CHANGES_REQUIRED` | `REJECTED` | `BLOCKED`

### Handoff

- `APPROVED` -> `CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION`
- `CHANGES_REQUIRED` -> `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`
- `REJECTED` -> `CODEX_REVIEW_REJECTED_TO_PLANNING`
- `BLOCKED` -> `CODEX_REVIEW_BLOCKED`

## Fix — `CODEX_FIXER`

### Fix applicati

### Check post-fix

### Handoff a Review

- **Prossima fase**: REVIEW
- **Prossimo ruolo**: CODEX_RE_REVIEWER
- **Handoff**: CODEX_FIX_COMPLETE_TO_RE_REVIEW | CODEX_FIX_BLOCKED_TO_RE_REVIEW

## Chiusura

- **Conferma utente**: non ancora | ricevuta
- **Merge autorizzato da USER_APPROVER**: no | sì
- **Follow-up candidate**:
- **Riepilogo finale**:
- **Data completamento**:
