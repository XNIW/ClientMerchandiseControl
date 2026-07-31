# Evidence TASK-011

Snapshot di handoff:
`ACTIVE / FIX / CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Indice

- `planning-summary.md`: scope, baseline, matrici iniziali e handoff Planning;
- `environment-audit.md`: audit staging sanitizzato e probe data-free;
- `execution-evidence.md`: deliverable e matrici dell'Execution;
- `commands-and-results.md`: gate locali, security e CI tecnica;
- `runtime-smoke.md`: probe e smoke staging reali Android/iOS;
- `security-review.md`: confinement e zero-write;
- `ci-status.md`: ispezione CI tecnica e gate finale pendente;
- `review-report.md`: review indipendente, finding e matrici;
- le evidence Fix, re-review e closeout verranno aggiunte dalle rispettive fasi.

## Regole

- nessun URL, key, project ref completo, token, payload o dato personale;
- soli esiti `PASS`, `FAIL`, `BLOCKED` e `NOT_RUN`;
- ogni claim di esecuzione richiede comando reale, output pertinente ed exit code;
- nessuna query o mutazione remota appartiene a TASK-011.

## Matrice CA

| CA | Tipo | Esito | Evidenza |
|---|---|---|---|
| CA-01–CA-05, CA-07–CA-24, CA-26, CA-29–CA-30 | VARI | PASS | Review indipendente. |
| CA-06, CA-25, CA-27–CA-28, CA-31 | VARI | FAIL | Cinque P2 aperti in `review-report.md`. |
| CA-32 | CI | NOT_RUN | Richiede CI sullo SHA finale. |

## Matrice test

| Test | Tipo | Esito | Evidenza |
|---|---|---|---|
| T-01–T-06, T-08–T-11, T-13–T-15, T-18–T-22, T-25–T-27 | VARI | PASS | Review indipendente. |
| T-07, T-12, T-16–T-17, T-23–T-24, T-28 | VARI | FAIL | Finding P2 aperti. |
| T-29 | CI | NOT_RUN | Richiede CI sullo SHA finale. |
