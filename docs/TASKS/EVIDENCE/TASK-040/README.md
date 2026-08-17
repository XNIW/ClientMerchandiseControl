# Evidence TASK-040

Snapshot di handoff:
`ACTIVE / EXECUTION / CODEX_PLANNING_APPROVED_TO_EXECUTION`.

## Provenance

- Client baseline: `f30b13e9bfc1ea8b792d2048c0b067077e2d307c`;
- TASK-039 PR #18 e CI PR/main exact-SHA verdi;
- Admin baseline read-only: `59668348e4c728b44b998c80f1aded61e6114a3f`;
- production, App Store Connect e TestFlight invariati all'attivazione.

## Matrice CA -> evidence

| CA | Evidence | Esito |
|---|---|---|
| CA-01 | da eseguire | NOT_RUN |
| CA-02 | da eseguire | NOT_RUN |
| CA-03 | da eseguire | NOT_RUN |
| CA-04 | da eseguire | NOT_RUN |
| CA-05 | da eseguire | NOT_RUN |
| CA-06 | da eseguire | NOT_RUN |
| CA-07 | da eseguire | NOT_RUN |
| CA-08 | da eseguire | NOT_RUN |
| CA-09 | da eseguire | NOT_RUN |
| CA-10 | da eseguire | NOT_RUN |

## Matrice T -> risultato

| Test | Esito | Evidence |
|---|---|---|
| T-01 | NOT_RUN | execution non iniziata |
| T-02 | NOT_RUN | execution non iniziata |
| T-03 | NOT_RUN | execution non iniziata |
| T-04 | NOT_RUN | execution non iniziata |
| T-05 | NOT_RUN | execution non iniziata |
| T-06 | NOT_RUN | execution non iniziata |
| T-07 | NOT_RUN | execution non iniziata |

## Activation boundary

- signing identity/provisioning: da verificare senza stampare valori sensibili;
- App Store Connect credential/access: da verificare senza upload finché il gate non è
  completo;
- production App Store: vietata;
- physical iOS: separato da Simulator e classificato onestamente.
