# Review report — TASK-011

## Target e indipendenza

- Revisione: `b4b2234f889df91ea422b769153f662c942dadf3`
- Commit tecnico: `2e646595ad01807be292179adc61013fdd1b2700`
- Reviewer: tre sessioni read-only distinte dall'Executor
- Shard: runtime/architettura, platform/UI/evidence, security/confinement
- Worktree finale reviewer: pulito e allineato a origin

## Finding

### T011-REV-001 — P2 — Auto-check non provato

Il test controller chiama `retry()` manualmente. Rimuovendo la microtask automatica
l'intera suite resta 105/105 `PASS`. Il Fix deve attendere l'auto-check senza invocarlo
e dimostrare anche l'assenza di auto-retry.

### T011-REV-002 — P2 — `recoverableError` non coperto

Nessun widget test istanzia questo stato. La rimozione del relativo retry lascia 6/6
test banner verdi. Il Fix deve verificare shell, copy, Semantics, target, tap,
single-flight e transizione `initializing`.

### T011-REV-003 — P2 — Smoke senza entrypoint reale

Lo smoke crea direttamente container e app e chiama il notifier; non attraversa
`bootstrap()` e non naviga. Il Fix deve eseguire cold start via bootstrap, osservare la
shell durante `initializing`, attendere `ready` e interagire con una destinazione.

### T011-REV-004 — P2 — Evidence runtime non riproducibile

Comandi e target sono abbreviati e mancano screenshot sanitizzati/manifest/digest. Il
Fix deve rieseguire sui due simulatori e registrare comando sanitizzato completo,
target/OS, output, exit code, immagini e SHA-256.

### T011-REV-005 — P2 — Payload health non vincolato a GoTrue

Un JSON 200 con `name: "Other Service"` e le altre stringhe non vuote produce
`healthy` e poi `ready`. Il Fix deve richiedere `name == "GoTrue"` e coprire il
servizio errato come `invalidResponse`/`recoverableError`.

### T011-REV-006 — P3 — Body health senza limite

`toBytes()` accumula l'intero body. Il Fix deve imporre una soglia piccola, abortire
al superamento e verificare che l'esito non sia mai `healthy`.

## Gate indipendenti

| Gate | Esito | Evidenza |
|---|---|---|
| format/analyze | PASS | exit 0 |
| test runtime/backend/shell | PASS | 38/38 |
| test platform/UI | PASS | 44/44 |
| test security/config/backend | PASS | 62/62 |
| suite completa | PASS | 105/105 |
| architecture + fixture negative | PASS | baseline e 5/5 |
| scan query/secret/config/network | PASS | nessun leak/query/write |
| smoke corrente Android/iOS | PASS | 1/1 per piattaforma, ma design/evidence insufficienti |
| CI handoff `30598639082` | PASS | SHA esatto, 3/3 job, step verdi, annotation 0/0/0 |
| mutation auto-check/recoverable | FAIL | due regressioni non rilevate |

## Matrice CA

| CA | Esito | Evidenza |
|---|---|---|
| CA-01–CA-05 | PASS | Governance, staging e modello verificati. |
| CA-06 | FAIL | Payload di altro servizio può produrre falso `ready`. |
| CA-07–CA-24 | PASS | Runtime, mapping, lifecycle, UI e policy verificati staticamente/test. |
| CA-25 | FAIL | Copertura auto-check e `recoverableError` non sensibile. |
| CA-26 | PASS | Probe reale GoTrue valido e sanitizzato. |
| CA-27–CA-28 | FAIL | Smoke corrente non attraversa bootstrap/interazione e manca evidence richiesta. |
| CA-29–CA-30 | PASS | Gate locali/CI tecnica e confinement riusciti. |
| CA-31 | FAIL | Cinque P2 restano aperti. |
| CA-32 | NOT_RUN | CI finale successiva al Fix/re-review. |

## Matrice test

| Test | Esito | Evidenza |
|---|---|---|
| T-01–T-06 | PASS | Baseline, request e health ufficiale verificati. |
| T-07 | FAIL | Manca caso JSON completo di servizio diverso. |
| T-08–T-11 | PASS | Timeout, trasporto e status verificati. |
| T-12 | FAIL | Auto-check non provato senza retry manuale. |
| T-13–T-15 | PASS | Single-flight, retry e dispose verificati. |
| T-16–T-17 | FAIL | `recoverableError` e retry accessibile non coperti. |
| T-18–T-22 | PASS | L10n, policy, scan e probe host verificati. |
| T-23–T-24 | FAIL | Smoke reale non soddisfa entrypoint/interazione/evidence. |
| T-25–T-27 | PASS | Build/check/diff riusciti. |
| T-28 | FAIL | Review `CHANGES_REQUIRED`. |
| T-29 | NOT_RUN | CI finale successiva. |

## Esito

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`
