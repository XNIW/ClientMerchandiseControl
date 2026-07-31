# Re-review report — TASK-011, ciclo 2

## Target e indipendenza

- Target:
  `978b25781605e9c20b4702c3aed6dd7b196803cd`
- Reviewer: due sessioni `CODEX_RE_REVIEWER` read-only indipendenti
- Worktree: pulito e allineato a origin durante la verifica
- Modifiche reviewer: nessuna

## Finding

### T011-REREV2-PROV-001 — P2 — OPEN

Due frasi in `docs/AI_WORKLOG.md` affermano ancora «Supabase resta read-only» e
«Nessun write Supabase eseguito» senza qualificare esplicitamente client/azioni Codex
TASK-011. Devono distinguere il writer set del task dal traffico Admin esterno
concorrente già documentato.

### T011-REREV2-GOV-002 — P2 — OPEN

La registrazione «Fix 2 — provenance zero-write» è collocata dentro la sezione Review
del task, benché appartenga al Fixer. Inoltre `remote-write-provenance.md` dichiara di
«chiudere» il finding prima della verifica indipendente. La registrazione deve essere
spostata sotto Fix e l'evidence deve dichiarare soltanto di indirizzare/correggere il
finding in attesa di re-review.

Le citazioni storiche del claim globale nel report del ciclo 1 e nel racconto Review
sono chiaramente superseded e possono restare.

## Controlli indipendenti

| Controllo | Esito | Evidenza |
|---|---|---|
| SHA, branch, worktree e origin | PASS | target esatto, pulito, tracking 0/0 |
| diff Fix | PASS | 12 file esclusivamente documentali |
| governance | PASS | unico TASK-011 ACTIVE, REVIEW al momento della verifica |
| sanitizzazione | PASS | zero email, IP, UUID, URL/ref, request ID o credenziale |
| confinement client | PASS | solo `GET /auth/v1/health`, zero mutazioni/Admin/Data API |
| CI `30600817975` | PASS | SHA esatto, 3/3 job, tutti gli step success, annotation 0/0/0 |

## Matrice CA

| CA | Esito | Evidenza |
|---|---|---|
| CA-01–CA-03 | PASS | Governance, progetto e config verificati. |
| CA-04 | FAIL | Due claim attivi restano non qualificati. |
| CA-05–CA-30 | PASS | Nessun finding tecnico aperto. |
| CA-31 | FAIL | Due P2 documentali aperti. |
| CA-32 | NOT_RUN | Riservato alla CI sullo SHA finale approvato. |

## Matrice test

| Test | Esito | Evidenza |
|---|---|---|
| T-01 | PASS | Governance e target. |
| T-02 | FAIL | Provenance non ancora completamente task-scoped. |
| T-03–T-27 | PASS | Gate tecnici precedenti non impattati. |
| T-28 | FAIL | Re-review `CHANGES_REQUIRED`. |
| T-29 | NOT_RUN | CI finale successiva. |

## Esito

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`
