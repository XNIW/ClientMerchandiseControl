# TASK-008 — Admin Console: prezzi pubblici, sconti e promozioni

## Informazioni generali

- **Task ID**: TASK-008
- **Titolo**: Admin Console: prezzi pubblici, sconti e promozioni programmate
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-01
- **Ultimo aggiornamento**: 2026-08-01
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-008/`
- **Handoff**: CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW

## Dipendenze

- **Dipende da**: TASK-005, TASK-006, TASK-007
- **Sblocca**: TASK-013, TASK-019, TASK-023, TASK-027

## Scope

- estendere il control plane Storefront con prezzi cliente, modalità prezzo e
  compare-at price validati server-side;
- implementare promozioni programmate multi-prodotto con priorità, esclusioni e
  risoluzione deterministica dei conflitti;
- attivare/scadere automaticamente le promozioni senza countdown o percentuali false;
- fornire lista, editor e anteprima Admin usando projection e contratto pubblico v1;
- registrare audit before/after per promozioni e operazioni bulk;
- coprire start/end, conflitti, prezzo negativo, compare-at, RBAC e staging E2E.

## Non incluso

- pipeline immagini pubbliche TASK-009;
- carrello, checkout e price revalidation ordine TASK-023/TASK-027;
- provider pagamento TASK-032;
- modifiche production.

## Criteri di accettazione

| CA | Descrizione |
|---|---|
| CA-01 | Prezzi CLP sono integer, non negativi e rivalidati server-side |
| CA-02 | `compare_at_price_clp` è nullo o non inferiore al prezzo corrente |
| CA-03 | Intervalli promozione richiedono start < end e validità temporale reale |
| CA-04 | Associazioni multi-prodotto, esclusioni e priorità sono shop-scoped |
| CA-05 | Conflitti hanno una regola deterministica e nessun doppio sconto ambiguo |
| CA-06 | Start/scadenza aggiornano projection/versione in modo idempotente |
| CA-07 | Anteprima e API pubblica mostrano lo stesso prezzo/sconto valido |
| CA-08 | RBAC e audit coprono create/update/activate/expire/bulk e deny |
| CA-09 | Gate Admin, SQL, E2E e staging sono PASS senza residue fixture |

## Test case

| Test | Criteri | Procedura |
|---|---|---|
| T-01 | CA-01, CA-02 | zero/max/negativo/decimale e compare-at malevolo |
| T-02 | CA-03, CA-06 | promozione futura, start, end e rebuild ripetuto |
| T-03 | CA-04, CA-05 | più prodotti, esclusione, priorità e conflitto |
| T-04 | CA-07 | confronto preview/projection/API sullo stesso timestamp |
| T-05 | CA-08 | permessi manage, audit before/after e ruolo negato |
| T-06 | CA-09 | lint/typecheck/unit/build/pgTAP/Playwright/staging |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | CLP solo `bigint`/integer server-side | La valuta non ammette decimali nel dominio v1 | ATTIVA |
| D-02 | Vince il prezzo effettivo più basso; a parità priorità e UUID | Nessun doppio sconto ambiguo e tie-break stabile | ATTIVA |
| D-03 | Validità ricalcolata read-time e projection ricostruibile | Evita sconti stale tra job pianificati | ATTIVA |
| D-04 | Nessun cron esterno se Postgres/job esistente basta | Riduce dipendenze e failure surface | ATTIVA |

## Planning — `CODEX_PLANNER`

### Approccio autorizzato

1. verificare schema promozioni, projection e scheduler già presenti;
2. definire mutazioni transazionali e regola conflitti;
3. implementare editor/lista/anteprima senza duplicare il contratto pubblico;
4. aggiungere audit, negative test, boundary temporali e concorrenza;
5. eseguire replay, gate Admin, E2E locale e staging;
6. consegnare a `VALIDATED_PENDING_INTEGRATED_REVIEW` solo con checkpoint verde.

### Rischi

- clock boundary: timestamp server e test con istanti controllati;
- prezzi incoerenti: constraint più revalidation nella stessa transazione;
- promozioni concorrenti: lock/unique policy e tie-break deterministico;
- scope creep checkout: snapshot ordine resta fuori da TASK-008.

### Handoff

`CODEX_PLANNING_APPROVED_TO_EXECUTION` — autorizzazione USER_APPROVER nel prompt del
release train; production resta fuori scope.

## Execution — `CODEX_EXECUTOR`

### Modifiche completate

- control plane promozioni shop-scoped con lista, filtri, editor, prodotti multipli ed
  esclusioni;
- sconti prezzo fisso CLP e percentuale in basis point, con validazione server-side;
- fuso orario esplicito `America/Santiago`/`UTC`, intervalli start/end e stato effettivo
  calcolato sul tempo server;
- riconciliazione automatica ogni minuto tramite `pg_cron`, read-time safety e
  projection pubblica ricostruibile;
- lock transazionale per shop e conflitto deterministico
  `lowest_effective_price_then_priority_then_uuid`;
- permesso `storefront.promotions.manage`, lease-bound RPC e audit before/after;
- test pgTAP, Foundation, Playwright locale e acceptance staging autenticata.

### Gate eseguiti

- revision set Admin:
  `0ec146b4379b8f0da13229fd3c807ac084d2858f`, PR `#67` draft;
- replay locale: 106 migration, `PASS` in 27,5 s;
- pgTAP completo: 23 file / 1.472 test, `PASS` in 43 s; TASK-008 23/23;
- lint, typecheck, security scan, dependency audit, build e secret scan: `PASS`;
- E2E locale pubblicazione -> promozione -> prezzo pubblico -> pausa -> audit: 1/1
  `PASS` in 5,0 s;
- CI Admin `30725543266`: `PASS`; Cloudflare PR build `30725543260`: `PASS`;
- staging dry-run `30725661643`: `PASS`; apply/postverify/benchmark
  `30725690931`: `PASS`, schema `20260802010000`, ledger 106 migration;
- Cloudflare staging deploy/smoke `30725801242`: `PASS` sullo SHA esatto;
- acceptance staging autenticata `30725925704`: 1/1 `PASS` in 33,1 s, con cleanup;
- production write: `NOT_RUN`; production invariata.

### Matrici

CA-01..CA-09 e T-01..T-06: `PASS`. Evidence sintetica:
`docs/TASKS/EVIDENCE/TASK-008/README.md`.

### Handoff

`CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`. Nessuna review formale è stata
eseguita e TASK-008 non è `DONE`.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.
