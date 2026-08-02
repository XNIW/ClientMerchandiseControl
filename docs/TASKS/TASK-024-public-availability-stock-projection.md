# TASK-024 — Proiezione disponibilità e stock pubblico

## Informazioni generali

- **Task ID**: TASK-024
- **Titolo**: Proiezione disponibilità e stock pubblico
- **File task**: `docs/TASKS/TASK-024-public-availability-stock-projection.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-02
- **Ultimo aggiornamento**: 2026-08-02
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-024/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Dipendenze

- **Dipende da**: TASK-005, TASK-006, TASK-010
- **Checkpoint consumati**: Storefront schema/projection/query; Detail e Cart
- **Sblocca**: TASK-025, TASK-030
- **Repository writer**: Admin/Supabase, poi Client; POS soltanto per contract test
  read-only in questa fase

## Scope

- definire una proiezione commerciale shop/product con stati `available`, `low_stock`,
  `unavailable`, `reservation_only`, `pickup_only`, `delivery_only`;
- derivare lo stato lato server da segnali operativi autorizzati senza esporre quantità,
  costo, supplier, location o altri dettagli inventory;
- rendere refresh/event ingestion idempotenti, monotoni e shop-scoped, con timestamp di
  freshness e fallback fail-closed;
- integrare la disponibilità in Home/Catalog/Search/Detail/Cart e nella preview Admin;
- invalidare/aggiornare cache e righe carrello quando una publication cambia stato;
- testare RLS/grant, cross-shop, replay/out-of-order, stale state e contratti staging;
- mantenere production e feature flag invariati.

## Non incluso

- quantità stock precisa nel client o nell'Admin Storefront pubblico;
- reservation hold, oversell prevention e scadenza, di competenza TASK-025;
- checkout/zone/slot/fee, ordine o vendita fiscale;
- modifica del dominio inventory operativo o dei repository di riferimento;
- write production o dipendenza da dispositivo/GUI manuale.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | I sei stati commerciali sono un contratto server canonico e bounded | CONTRACT |
| CA-02 | Nessuna risposta espone quantità, costo, supplier o ID inventory | SECURITY |
| CA-03 | Proiezione e ingest sono shop-scoped, idempotenti e resistono a replay/out-of-order | PGTAP/CONCURRENCY |
| CA-04 | Stato stale/assente fallisce chiuso senza dichiarare disponibilità falsa | PGTAP/INTEGRATION |
| CA-05 | Home/Catalog/Search/Detail/Cart consumano coerentemente lo stato pubblico | UNIT/WIDGET/INTEGRATION |
| CA-06 | Cache aggiorna/invalida stato senza perdere favorite o cart guest | UNIT/INTEGRATION |
| CA-07 | Admin preview mostra stato commerciale senza controlli inventory | UNIT/PLAYWRIGHT |
| CA-08 | Gate Admin/Supabase/Client e staging headless passano sul revision set | CI/SMOKE |
| CA-09 | Production resta invariata e nessun secret/artifact è versionato | SECURITY/GIT |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-02 | PGTAP/CONTRACT | enum/input/output allow-list e negative internal fields |
| T-02 | CA-03 | PGTAP/CONCURRENCY | duplicate/replay/out-of-order e cross-shop denial |
| T-03 | CA-04 | PGTAP | missing/stale/unpublished diventano unavailable/fail-closed |
| T-04 | CA-05 | UNIT/WIDGET | sei stati su card/detail/cart e fulfillment coerente |
| T-05 | CA-06 | UNIT/INTEGRATION | refresh/cache migration conserva favorite/cart e aggiorna availability |
| T-06 | CA-07 | UNIT/PLAYWRIGHT | preview Admin responsive e accessibile |
| T-07 | CA-08, CA-09 | CI/GIT | replay, pgTAP, gate, staging, mobile smoke e production unchanged |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Il contratto espone stati, mai quantità precisa | Riduce leakage inventory e coupling operativo | ATTIVA |
| D-02 | Stato assente/stale non equivale ad available | Disponibilità falsa può causare oversell e cattiva UX | ATTIVA |
| D-03 | Hold e concorrenza sull'ultimo pezzo restano TASK-025 | Mantiene separata la proiezione informativa dalla prenotazione atomica | ATTIVA |
| D-04 | Planning ed Execution sono autorizzati dal prompt USER_APPROVER del 2026-08-02 | Consente il release train headless continuo | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Fornire una disponibilità commerciale pubblica coerente e privacy-safe, pronta per gli
hold transazionali senza rendere il client o la proiezione fonte dell'inventory.

### Analisi

- i sei stati sono già modellati nel contratto Client, ma manca l'evidence di derivazione
  operativa, freshness e concorrenza end-to-end;
- publication/query espongono availability e fulfillment, quindi il delta deve essere
  additivo e compatibile con Home/Catalog/Search/Detail/Cart;
- TASK-025 richiede un segnale affidabile ma non deve dipendere da una quantità pubblica;
- Admin e POS sono confini operativi distinti: in TASK-024 il POS non riceve ordini e la
  vendita fiscale resta fuori scope.

### Approccio autorizzato

1. audit read-only di schema publication/projection, funzioni di sync, Admin preview e
   contratti operativi disponibili;
2. migration additiva minima per freshness/event version e ingest idempotente, soltanto
   se il contratto corrente non copre i criteri;
3. pgTAP e concorrenza per sei stati, cross-shop, replay/out-of-order e leakage;
4. staging apply/postverify con fixture sintetiche e cleanup;
5. integrazione Client/cache/UI e Admin preview strettamente necessaria;
6. gate completi, smoke Android/iOS, evidence/checkpoint e attivazione TASK-025.

### Rischi e mitigazioni

- stato vecchio dichiarato disponibile: freshness bounded e fallback unavailable;
- eventi fuori ordine: source version/timestamp monotono e idempotency;
- leakage stock: allow-list risposta e test negative su quantità/costo/ID;
- regressione catalog performance: indici e benchmark query esistenti;
- scope creep inventory/POS: nessuna mutazione dei repository operativi in questa fase.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: prompt headless Storefront v1 2026-08-02

## Execution — `CODEX_EXECUTOR`

Audit read-only da avviare nel writer Admin/Supabase; nessuna modifica Client finché il
contratto canonico e le lacune reali non sono determinati.

## Checkpoint release train — `CODEX_EXECUTOR`

Da compilare dopo i gate tecnici; nessuna review formale intermedia.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.

## Chiusura

- **Conferma utente**: ricevuta in forma condizionata dal release train
- **Merge autorizzato**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: TASK-025 dopo checkpoint verde
- **Riepilogo finale**: in esecuzione
- **Data completamento**: non ancora
