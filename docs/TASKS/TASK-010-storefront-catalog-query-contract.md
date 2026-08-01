# TASK-010 — Catalog query contract, search, pagination e fixture estese

## Informazioni generali

- **Task ID**: TASK-010
- **Titolo**: Catalog query contract, search, pagination e fixture estese
- **File task**: `docs/TASKS/TASK-010-storefront-catalog-query-contract.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-01
- **Ultimo aggiornamento**: 2026-08-01
- **Ultimo agente**: CODEX_EXECUTOR
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-010/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

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

Da completare durante l'Execution.

### Piano minimo

Il planning approvato sopra è vincolante.

### Modifiche fatte

Non ancora implementate.

### Check eseguiti

NOT_RUN — inizio Execution.

### Matrice CA -> evidence

Da completare.

### Matrice T-NN -> risultato

Da completare.

### Rischi rimasti

Da verificare durante implementazione e staging.

### Handoff a Review

Non applicabile prima della review integrata.

## Checkpoint release train — `CODEX_EXECUTOR`

Da compilare al checkpoint Milestone 1. Il checkpoint non è una review.

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
