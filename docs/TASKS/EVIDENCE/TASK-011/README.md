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
- `fix-evidence.md`: risoluzione finding, regressioni e gate Fix;
- `screenshots/manifest.md`: provenance e digest dei due PNG runtime;
- `re-review-report.md`: chiusura finding originali e nuovo finding provenance;
- `remote-write-provenance.md`: writer set task-scoped e traffico esterno concorrente;
- `re-review-2-report.md`: seconda re-review e finding documentali residui;
- le evidence del terzo Fix/re-review e closeout verranno aggiunte dalle rispettive fasi.

## Regole

- nessun URL, key, project ref completo, token, payload o dato personale;
- soli esiti `PASS`, `FAIL`, `BLOCKED` e `NOT_RUN`;
- ogni claim di esecuzione richiede comando reale, output pertinente ed exit code;
- nessuna query o mutazione remota appartiene a TASK-011.

## Matrice CA

| CA | Tipo | Esito | Evidenza |
|---|---|---|---|
| CA-01–CA-03, CA-05–CA-30 | VARI | PASS | Re-review tecnica e Fix provenance verificati. |
| CA-04, CA-31 | MANUAL/SECURITY | FAIL | Due finding documentali aperti. |
| CA-32 | CI | NOT_RUN | Richiede CI sullo SHA finale. |

## Matrice test

| Test | Tipo | Esito | Evidenza |
|---|---|---|---|
| T-01, T-03–T-27 | VARI | PASS | Re-review tecnica e Fix provenance verificati. |
| T-02, T-28 | MANUAL/SECURITY | FAIL | Due finding documentali aperti. |
| T-29 | CI | NOT_RUN | Richiede CI sullo SHA finale. |
