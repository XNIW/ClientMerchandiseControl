# Evidence TASK-042

Snapshot di handoff:
`ACTIVE / REVIEW / CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

## Provenance

- Client baseline `origin/main`: `ce6045e4799cdc0c51cbd15cd173510e5cae88a4`;
- TASK-041 PR #20 head `02e0f950a57e1e34c33b73aaf882a7a829efa13f`;
- TASK-041 merge `ce6045e4799cdc0c51cbd15cd173510e5cae88a4`;
- TASK-041 PR CI `32451681206` e main CI `32453135940`: 5/5 job `PASS`, zero step
  falliti, ancestry verificata;
- Admin `origin/main`: `59668348e4c728b44b998c80f1aded61e6114a3f`, read-only;
- checkout primario Client preservato; production e provider invariati.

## Planning evidence

- autorizzazione USER_APPROVER: prompt 2026-08-21;
- scope: quattro runbook operations, checker read-only, test/drill, evidence e governance;
- adapter: TASK-035 no-op/fixture, nessun SaaS nuovo;
- live boundary: production, destination, provider e release restano attestazioni esterne;
- gate final candidate: definiti nella sezione Test del task.

## Gate executor

| Comando | Esito | Exit/evidence |
|---|---|---|
| git diff --check | PASS | exit 0, worktree e origin/main...HEAD |
| bash -n operations scripts | PASS | exit 0, due script |
| test operations readiness | PASS | exit 0, 76/76 e drill 10/10 |
| operations prelaunch | PASS | exit 0, 86 READY e 4 UNVERIFIABLE_EXTERNAL |
| operations live | PASS | exit 1 atteso, 4 requisiti esterni MISSING |
| governance state | PASS | exit 0 |
| governance fixture | PASS | exit 0, 101/101 |
| action pins | PASS | exit 0, un workflow |
| telemetry privacy | PASS | exit 0, 12 eventi e zero attributi sensibili |
| client security | PASS | exit 0, 703 file e zero violazioni |
| scripts/check.sh | NOT_RUN | nessun diff runtime o release configuration |

## Matrice CA -> evidence

| CA | Evidence | Esito |
|---|---|---|
| CA-01 | quattro runbook e sezioni operations validate dal checker | PASS |
| CA-02 | sedici segnali, payload allowlisted e owner placeholder | PASS |
| CA-03 | SEV-0 fino a SEV-3 e otto campi operativi | PASS |
| CA-04 | prelaunch exit 0, idempotenza e read-only | PASS |
| CA-05 | live exit 1 con quattro activation requirement mancanti | PASS |
| CA-06 | fixture-bound drill 10/10, mapping esatto e allowlist log completa | PASS |
| CA-07 | sette kill switch e fallback verificati | PASS |
| CA-08 | review, PR/main CI e merge sono fase successiva | NOT_RUN |

## Matrice T -> risultato

| Test | Esito | Evidence |
|---|---|---|
| T-01 | PASS | struttura, segnali, severity, supporto e privacy |
| T-02 | PASS | sintassi, prelaunch, idempotenza e read-only |
| T-03 | PASS | live default MISSING e fixture completa READY |
| T-04 | PASS | 10/10 drill fixture-bound, mapping mutato rifiutato e zero PII |
| T-05 | PASS | Maps, tracking, carrier, payment, push, telemetry e promotions |
| T-06 | NOT_RUN | gate locali verdi; review e CI/merge da eseguire |

## Review indipendente

- range: `ce6045e4799cdc0c51cbd15cd173510e5cae88a4..f85bc3b99685674d7bc31b9f2775c6d3d5285f13`;
- esito: `CHANGES_REQUIRED`;
- severita: P0 0, P1 0, P2 3, P3 0;
- `F-042-R01`: health/runbook non allineato a `/auth/v1/health` e all'RPC reale
  `storefront_home_v1`;
- `F-042-R02`: drill solo strutturali, privi di binding e risultato operativo esatto;
- `F-042-R03`: log-safety denylist incompleta e fail-open;
- requisiti live/owner: esterni, non finding;
- sicurezza: review manuale diff-scoped;
  `FORMAL_EXTERNAL_SCANNER_NOT_AVAILABLE`.

## Candidate tecnico

- exact SHA: `d7d4fa9a94b07dd6422e4018a524ca9e5478bfe1`;
- diff: quattro documenti operations e due script shell;
- codice applicativo, dipendenze e release configuration: invariati;
- production, Admin e Supabase: read-only/invariati;
- live esterno: `EXTERNAL_MONITORING_DESTINATION_REQUIRED` e owner values, non
  CODE_BLOCKER.

## Fix evidence

- exact SHA: `b57bb86b1f31302aef87d4423cc12328b8ec0d0b`;
- `F-042-R01`: probe Auth e RPC Storefront riallineati al runtime, endpoint inventato
  vietato dal checker;
- `F-042-R02`: 10/10 drill collegati a fake/fixture/contratti esistenti, output esatto e
  mapping alterato rifiutato;
- `F-042-R03`: allowlist sull'intero record e 12/12 input sensibili/extra rifiutati;
- test: 76/76, prelaunch exit 0, live exit 1 atteso;
- governance 101/101, pins, privacy e security 703 file `PASS`;
- `scripts/check.sh`: `NOT_RUN`, nessun diff applicativo o release configuration;
- production e requisiti esterni invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.
