# Evidence TASK-041

Snapshot di handoff:
`ACTIVE / REVIEW / CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

## Provenance

- Client initial `origin/main`: `fdb1fa7962fa7a8eea7ecb0505adc812571fb1db`;
- Admin initial `origin/main`: `59668348e4c728b44b998c80f1aded61e6114a3f`;
- checkout primario Client pulito e preservato; worktree TASK-041 pulito da remote;
- PR Client pertinenti aperte: zero; production invariata.

## Planning evidence

- autorizzazione USER_APPROVER: prompt 2026-08-21;
- scope: documentazione, checker read-only, evidence e governance;
- gate final candidate: definiti nella sezione Test del task;
- activation esterna: separata dal completamento tecnico.

## Candidate tecnico

- exact SHA: `92323f309ac39d4ea9565ef841c8a358a2b257a7`;
- diff: documentazione release, due checker/test shell e fix fixture governance;
- codice applicativo/configurazione release: invariati;
- Admin/Supabase e production: read-only/invariati.

## Gate executor

| Comando | Esito | Exit/evidence |
|---|---|---|
| `git diff --check` | PASS | exit 0 |
| `bash -n scripts/check-production-readiness.sh` | PASS | exit 0 |
| `bash -n scripts/test-production-readiness.sh` | PASS | exit 0 |
| `scripts/test-production-readiness.sh` | PASS | exit 0, 13/13 |
| `scripts/check-production-readiness.sh --mode technical` | PASS | exit 0, 72 READY, 59 UNVERIFIABLE_EXTERNAL |
| `scripts/check-production-readiness.sh --mode activation` | PASS | exit 1 atteso, 71 READY, 59 requisiti MISSING |
| `scripts/check-governance-state.sh` | PASS | exit 0 |
| `scripts/test-governance-release-train.sh` | PASS | FAIL fixture, FAIL primo rerun, secondo rerun exit 0 101/101 |
| `scripts/check-action-pins.sh` | PASS | exit 0, un workflow |
| `scripts/check-client-security.sh` | PASS | exit 0, 690 file, zero violazioni |
| `scripts/check.sh` | NOT_RUN | nessun diff runtime o release configuration |

## Matrice CA -> evidence

| CA | Evidence | Esito |
|---|---|---|
| CA-01 | checklist e launch A-L più rollback operativi | PASS |
| CA-02 | technical exit 0 e test readiness 13/13 | PASS |
| CA-03 | activation exit 1 con 59 requisiti esterni MISSING | PASS |
| CA-04 | nove domini e requisiti owner/source coperti | PASS |
| CA-05 | sette fallback separati verificati sul boundary esistente | PASS |
| CA-06 | security client 690 file, output redatto, production invariata | PASS |
| CA-07 | review, PR/main CI e merge sono fase successiva | NOT_RUN |

## Matrice T -> risultato

| Test | Esito | Evidence |
|---|---|---|
| T-01 | PASS | sezioni A-L e nove domini validate dal checker |
| T-02 | PASS | sintassi, idempotenza, read-only e technical mode |
| T-03 | PASS | activation default fail-closed e fixture completa READY |
| T-04 | PASS | Maps, tracking, carrier, payment, push, telemetry e promotions |
| T-05 | PASS | scanner client 690 file; review diff-scoped da eseguire |
| T-06 | NOT_RUN | local governance 101/101 e pins PASS; review/CI/merge da eseguire |

## Review indipendente

- exact HEAD: `ec735a0efdae128c8b1f7e82ca578358c1a56476`;
- esito: `CHANGES_REQUIRED`, P0 0, P1 0, P2 1, P3 0;
- `F-041-R01`: N/A opzionale non atomico per capability;
- security manuale diff-scoped completata; formal scanner non disponibile;
- worktree invariato dal reviewer.

## Fix e regressioni

- exact technical SHA: `87e00953e3eff81078f305cadbaa176e57ff103e`;
- `F-041-R01`: chiuso nel checker imponendo N/A atomico per capability e doppia
  attestazione redatta di capability disabilitata e fallback verificato;
- `scripts/test-production-readiness.sh`: exit 0, 15/15;
- technical: exit 0, 72 READY e 59 UNVERIFIABLE_EXTERNAL;
- activation: exit 1 atteso, 71 READY e 59 requisiti MISSING;
- governance state exit 0; governance fixture exit 0, 101/101; action pins exit 0,
  un workflow; security client exit 0, 695 file, zero violazioni;
- `scripts/check.sh`: NOT_RUN, nessun diff runtime o release configuration;
- production, Admin, Supabase, store e provider invariati.
