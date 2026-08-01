# TASK-006 — Storefront catalog projection e aggiornamento operativo

## Informazioni generali

- **Task ID**: TASK-006
- **Titolo**: Storefront catalog projection e aggiornamento operativo
- **File task**: `docs/TASKS/TASK-006-storefront-catalog-projection.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-01
- **Ultimo aggiornamento**: 2026-08-01
- **Ultimo agente**: CODEX_EXECUTOR
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-006/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Dipendenze

- **Dipende da**: TASK-005
- **Sblocca**: TASK-007, TASK-008, TASK-010, TASK-024, TASK-030

## Scope

- creare `storefront_catalog_items` e `storefront_catalog_versions` come projection
  denormalizzata minimizzata e ricostruibile;
- derivare esclusivamente dati pubblici approvati dalle tabelle autoritative TASK-005;
- aggiornare publish/pause/category/image/settings/promotion in modo sincrono,
  transazionale e idempotente;
- serializzare per shop, assegnare versioni monotone soltanto quando il contenuto cambia
  e supportare rebuild deterministico;
- includere prezzo cliente CLP, compare-at/sconto valido, immagine pubblica,
  fulfillment, disponibilità commerciale, sort key e documento di ricerca;
- mantenere le tabelle projection non scrivibili e non leggibili direttamente dai
  ruoli mobili; TASK-010 fornirà il contratto RPC versionato;
- applicare, verificare e osservare la migration soltanto su staging.

## Contesto

TASK-005 ha installato il modello autoritativo default-deny in staging. TASK-006 crea il
read model L3 di `CMC-STOREFRONT-LOGICAL 1.0.0`, senza copiare costo, fornitore, stock
esatto, owner, path privati o metadata POS.

## Non incluso

- RPC pubblici, keyset pagination e search endpoint di TASK-010;
- UI/azioni Admin di TASK-007–TASK-009;
- proiezione stock operativo completa di TASK-024;
- cache o UI Flutter;
- write production.

## File coinvolti

- Admin/Supabase canonico: migration, pgTAP e workflow staging;
- Client: task, evidence e checkpoint centrali;
- staging: projection vuota/fixture sintetiche e post-check;
- production: invariata.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Projection e version table sono additive, shop-scoped e prive di dati interni | DATABASE/SECURITY |
| CA-02 | Publish/upsert e pause/delete aggiornano la projection nella stessa transazione | DATABASE |
| CA-03 | Operazioni ripetute senza variazioni non duplicano righe né incrementano la versione | DATABASE/CONCURRENCY |
| CA-04 | Rebuild per shop produce lo stesso contenuto e una versione monotona soltanto al cambio | DATABASE |
| CA-05 | Prezzo/sconto/promozione sono CLP integer, temporalmente validi e deterministici | DATABASE |
| CA-06 | Categoria, immagine, fulfillment, disponibilità, featured/sort e search document sono coerenti | DATABASE |
| CA-07 | `anon`/customer non possono leggere o scrivere direttamente la projection e nessun helper privato è eseguibile | SECURITY |
| CA-08 | Cross-shop, source internal leakage e race concorrenti sono negate/testate | SECURITY/CONCURRENCY |
| CA-09 | Replay, pgTAP, CI, dry-run/apply e smoke staging sono PASS sullo stesso SHA | DATABASE/CI |
| CA-10 | Production resta invariata; manifest/checkpoint/evidence sono sanitizzati | SECURITY/GIT |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-07 | STATIC/SECURITY | verificare colonne, grant, RLS e denylist campi interni |
| T-02 | CA-02 | DATABASE | pubblicare, aggiornare e mettere in pausa una pubblicazione |
| T-03 | CA-03 | DATABASE | ripetere refresh invariato e confrontare row/version |
| T-04 | CA-04 | DATABASE | rebuild due volte, poi mutare contenuto e ricostruire |
| T-05 | CA-05, CA-06 | DATABASE | prezzo base, promozione, scadenza, immagine e sort |
| T-06 | CA-07, CA-08 | SECURITY | anon/auth write/read, helper execute e cross-shop denial |
| T-07 | CA-03, CA-08 | CONCURRENCY | publish/pause concorrente e advisory lock per shop |
| T-08 | CA-09, CA-10 | CI/MANUAL | replay, pgTAP, apply/post-check staging e secret scan |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | La projection pubblica non contiene `source_product_id` | Il client non deve poter risalire all'inventory operativo | ATTIVA |
| D-02 | Le tabelle projection restano default-deny; TASK-010 espone RPC minimizzati | Evitare query client arbitrarie e preservare il contratto versionato | ATTIVA |
| D-03 | Aggiornamenti sincroni e lock advisory per shop precedono eventuale outbox asincrona | Garantire coerenza v1 senza introdurre infrastruttura speculativa | ATTIVA |
| D-04 | Un rebuild invariato non incrementa `catalog_version` | Versione e invalidazione cache devono rappresentare un cambio reale | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Creare un read model Storefront minimizzato, deterministico, versionato e ricostruibile
che TASK-010 possa esporre senza accedere all'inventory.

### Analisi

La projection deve bilanciare aggiornamento transazionale, bulk/rebuild efficiente e
promozioni temporali. Il rischio principale è copiare riferimenti interni o incrementare
versioni a ogni retry, rendendo cache e osservabilità inaffidabili.

### Approccio

1. migration additiva con projection/version state e indici di lettura;
2. funzione payload privata che seleziona esclusivamente campi pubblici;
3. refresh idempotente per pubblicazione con lock advisory per shop;
4. rebuild deterministico per shop con fingerprint e version bump condizionale;
5. trigger minimali sulle tabelle autoritative;
6. pgTAP positivo/negativo/idempotenza/concorrenza;
7. replay, CI, dry-run/apply staging e checkpoint TASK-006.

### Rischi

- promozione scaduta senza evento: TASK-008 aggiungerà scheduler e TASK-010 filtrerà
  temporalmente al confine API;
- bulk trigger costosi: rebuild per shop e benchmark del Milestone 1 misurano il budget;
- deadlock: lock advisory acquisito sempre sulla chiave shop prima delle write;
- leakage: column denylist e contract test bloccano source ID, costi, fornitori e path.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: ricevuta nel prompt Storefront v1 del 2026-08-01

## Execution — `CODEX_EXECUTOR`

### Obiettivo compreso

Projection, versionamento e aggiornamento transazionale nel repository Admin canonico.

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

Non applicabile prima del checkpoint integrato.

## Checkpoint release train — `CODEX_EXECUTOR`

Da compilare dopo i gate TASK-006. Il checkpoint non è una review.

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
