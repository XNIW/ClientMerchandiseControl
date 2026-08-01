# TASK-010 — Catalog query contract, search, pagination e fixture estese

## Informazioni generali

- **Task ID**: TASK-010
- **Titolo**: Catalog query contract, search, pagination e fixture estese
- **File task**: `docs/TASKS/TASK-010-storefront-catalog-query-contract.md`
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-01
- **Ultimo aggiornamento**: 2026-08-01
- **Ultimo agente**: CODEX_EXECUTOR
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-010/`
- **Handoff**: CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW

## Dipendenze

- **Dipende da**: TASK-005, TASK-006
- **Sblocca**: TASK-013, TASK-014, TASK-015, TASK-016, TASK-019, TASK-024

## Scope

- esporre un contratto RPC pubblico versionato per health/settings, Home, categorie,
  catalogo, search, detail, featured, offerte e catalog version;
- accettare soltanto `public_slug`, cursor opachi/validati, filtri pubblici e page size
  limitata dalle impostazioni shop;
- usare keyset pagination e ordinamento deterministico, mai offset sul catalogo esteso;
- filtrare read-time Storefront disabilitato, righe non pubbliche e promozioni scadute;
- concedere EXECUTE soltanto ad `anon`, `authenticated` e ruoli backend necessari,
  mantenendo negate le tabelle projection e inventory;
- coprire search accent-insensitive in spagnolo, marca/categoria/alias pubblico e
  conservazione zh-Hans;
- creare fixture sintetiche staging e misurare 20.000 prodotti, 100 categorie e almeno
  50.000 righe-equivalenti senza dati production;
- validare replay, no drift, contract/security/load test e rollback staging.

## Contesto

TASK-005 e TASK-006 sono validate internamente. La projection contiene solo dati
pubblici approvati; TASK-010 è l'unico confine di lettura mobile e non espone tabelle
arbitrarie.

## Non incluso

- UI Admin TASK-007–TASK-009;
- UI/cache Flutter TASK-013–TASK-019;
- stock preciso, profilo, carrello o ordini;
- write production.

## File coinvolti

- Admin/Supabase canonico: migration RPC, pgTAP, contract/load harness e workflow;
- Client: task, evidence, manifest/checkpoint;
- staging: fixture sintetiche temporanee e benchmark sanitizzato.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Contratto v1 completo, minimizzato e versionato | API/SECURITY |
| CA-02 | Shop slug/page size/cursor/filter sono validati server-side | API/SECURITY |
| CA-03 | Catalog/search usano keyset deterministico e limite massimo | DATABASE/PERFORMANCE |
| CA-04 | Search normalizza accenti e supporta es/brand/category/zh-Hans | DATABASE |
| CA-05 | Detail/featured/offerte/Home non espongono righe non pubbliche o promo scadute | SECURITY/API |
| CA-06 | Anon/auth leggono via RPC ma non tabelle; inventory e helper restano negati | RLS/SECURITY |
| CA-07 | Cross-shop, injection, cursor malformato e payload eccessivo falliscono chiusi | SECURITY |
| CA-08 | Dataset 20k/100/50k-equivalenti rispetta budget p95 o documenta deviazione | PERFORMANCE |
| CA-09 | Replay, ledger/no-drift, pgTAP, contract/load e smoke staging sono PASS | CI/DATABASE |
| CA-10 | Rollback rehearsal è verificato e production resta invariata | RELEASE/SECURITY |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-05 | CONTRACT | chiamare ogni RPC e validare schema/campi |
| T-02 | CA-02, CA-03 | DATABASE | cursor avanti, tie e page size 0/max/oltre max |
| T-03 | CA-04 | SEARCH | accenti, spagnolo, marca, categoria e zh-Hans |
| T-04 | CA-05, CA-06 | SECURITY | draft/paused/altro shop/inventory/direct table denied |
| T-05 | CA-07 | SECURITY | slug/cursor/filter malevoli e cross-tenant |
| T-06 | CA-08 | LOAD | 20k prodotti, 100 categorie, 50k equivalenti, p50/p95 |
| T-07 | CA-09 | CI | replay, pgTAP, contract, CI, dry-run/apply/postverify |
| T-08 | CA-10 | RELEASE | rollback rehearsal staging e conferma production no-write |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | RPC `storefront_*_v1` come unico accesso mobile | Riduce superficie, stabilizza contratto e grants | ATTIVA |
| D-02 | Cursor opaco versionato con sort key e UUID | Evita offset e ambiguità sui tie | ATTIVA |
| D-03 | Filtri temporali anche read-time | Una projection non aggiornata non deve mostrare promo scadute | ATTIVA |
| D-04 | Fixture load sintetiche e cleanup verificato | Nessun dato personale/reale nelle evidence | ATTIVA |
| D-05 | Budget staging `staging-nano-20k-v1`: catalogo 800 ms, search 1.200 ms, detail 400 ms p95 | Il progetto staging esistente è NANO; target iniziali e deviazioni restano riportati separatamente | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Fornire al client un contratto pubblico sicuro, deterministico e misurabile sopra la
projection TASK-006.

### Analisi

Il rischio principale è trasformare la projection in una tabella pubblica interrogabile
arbitrariamente. RPC minimizzati con `search_path` vuoto, cursor validati e grant
espliciti mantengono il confine e consentono evoluzione backward compatible.

### Approccio

1. definire DTO JSON e cursor v1 condivisi tra RPC;
2. implementare resolver shop fail-closed e funzioni SECURITY DEFINER;
3. aggiungere catalog/search keyset e indici/plan assertions;
4. aggiungere contract/RLS/abuse test;
5. creare load harness sintetico transazionale con cleanup;
6. replay, CI, dry-run/apply/postverify e smoke staging;
7. checkpoint Milestone 1 composto.

### Rischi

- scadenza promozione tra rebuild e read: ricalcolo/filtraggio read-time;
- cursor manipolato: encoding/version/shape validati, failure chiusa;
- RPC costosa: page cap, statement timeout compatibile e query plan misurato;
- leakage: allow-list campi contract e negative test inventory/grants.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: ricevuta nel prompt Storefront v1 del 2026-08-01

## Execution — `CODEX_EXECUTOR`

### Obiettivo compreso

Contratto pubblico e gate TASK-010 nel repository Admin/Supabase canonico.

### File controllati

- `supabase/migrations/20260801223000_storefront_v1_public_api.sql`;
- `supabase/migrations/20260801230000_storefront_v1_public_api_planner.sql`;
- `supabase/tests/storefront_v1_public_api.sql` e test Storefront precedenti;
- `scripts/testing/storefront-v1-contract-load.{sh,sql}`;
- workflow staging guarded e PR Admin #67.

### Piano minimo

Il planning approvato sopra è vincolante.

### Modifiche fatte

- nove RPC pubblici versionati per settings/version/categories/catalog/search/detail,
  featured/offerte/Home;
- cursor keyset opachi con versione catalogo, cap server-side e ordinamento stabile;
- search accent-insensitive per spagnolo, zh-Hans, marca, categoria, alias e barcode
  esplicitamente pubblici;
- tabelle projection/inventory negate direttamente ad anon/auth; EXECUTE limitato al
  contratto pubblico;
- harness 20.000 prodotti/100 categorie/65.000 righe equivalenti con cleanup;
- fix planner additivo sul resolver read-only, mantenuto invoker e non eseguibile dai
  ruoli mobile; RPC pubblici ancora SECURITY DEFINER con `search_path` vuoto e timeout.

### Check eseguiti

- replay locale 104 migration: `PASS`;
- pgTAP completo 21 file/1.428 test: `PASS`; Storefront 146/146;
- lint DB exit 0, nessun warning nuovo Storefront; concurrency 2 writer `PASS`;
- lint/typecheck/security/foundation/build/verify/audit (0 vulnerabilità): `PASS`;
- CI Admin `30721537778` e Cloudflare `30721537758`: `PASS` sullo SHA
  `eca5c6e0351e3eba248dd96c5b04001e0deabea6`;
- staging dry-run `30721664685` e apply/postverify/load `30721691138`: `PASS`;
- staging 20k: catalogo p50/p95 597,599/604,479 ms; search
  1.048,437/1.074,024 ms; detail 0,642/2,485 ms; keyset e FTS index `PASS`;
- target iniziale: catalogo/search `FAIL`, detail `PASS`; budget NANO documentato:
  tutti e tre `PASS`; fixture residue 0 e artifact digest `bfe90763…`;
- production write: `NOT_RUN` e production invariata.

### Matrice CA -> evidence

CA-01..CA-07, CA-09 e CA-10 `PASS`; CA-08 `PASS` con deviazione NANO esplicita.
Evidence sintetica: `docs/TASKS/EVIDENCE/TASK-010/README.md`.

### Matrice T-NN -> risultato

T-01..T-08 `PASS`; per T-06 i target iniziali catalog/search restano riportati `FAIL`
e il gate usa soltanto il budget runner documentato consentito dal criterio CA-08.

### Rischi rimasti

Il runtime staging NANO è circa 3–4x più lento del runner locale su query che risolvono
promozioni per 20.000 righe. Il dettaglio è stato corretto; catalog/search richiedono
monitoraggio nel Milestone 3 e non possono essere presentati come target iniziali PASS.

### Handoff a Review

Non applicabile prima della review integrata.

## Checkpoint release train — `CODEX_EXECUTOR`

Milestone 1 `PASS`: TASK-005, TASK-006 e TASK-010 sono
`VALIDATED_PENDING_INTEGRATED_REVIEW`; schema/RLS/projection/API/load, replay,
ledger, staging smoke/rollback, security scan e backward compatibility sono verdi.
Nessuna review formale è stata eseguita e nessun task è `DONE`.

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

Riservata alla review integrata finale.

## Fix — `CODEX_FIXER`

Riservata all'eventuale ciclo Fix integrato.

## Chiusura

- **Conferma utente**: ricevuta e condizionata ai gate del release train
- **Merge autorizzato da USER_APPROVER**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: nessuno
- **Riepilogo finale**: non applicabile
- **Data completamento**: non applicabile
