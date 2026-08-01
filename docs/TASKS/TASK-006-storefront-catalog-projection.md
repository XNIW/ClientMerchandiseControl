# TASK-006 — Storefront catalog projection e aggiornamento operativo

## Informazioni generali

- **Task ID**: TASK-006
- **Titolo**: Storefront catalog projection e aggiornamento operativo
- **File task**: `docs/TASKS/TASK-006-storefront-catalog-projection.md`
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: INTEGRATED_REVIEW
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-01
- **Ultimo aggiornamento**: 2026-08-01
- **Ultimo agente**: CODEX_EXECUTOR
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-006/`
- **Handoff**: STOREFRONT_V1_MILESTONE_CHECKPOINT_VALIDATED

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

- `merchandise-control-admin-web/supabase/migrations/20260801211500_storefront_v1_catalog_projection.sql`;
- `merchandise-control-admin-web/supabase/migrations/20260801213500_storefront_v1_catalog_projection_grants.sql`;
- `merchandise-control-admin-web/supabase/tests/storefront_v1_catalog_projection.sql`;
- `merchandise-control-admin-web/scripts/testing/storefront-v1-projection-concurrency.sh`;
- workflow staging, package scripts e gate repository esistenti.

### Piano minimo

Il planning approvato sopra è vincolante.

### Modifiche fatte

- aggiunte projection `storefront_catalog_items` e version state
  `storefront_catalog_versions`, entrambe FORCE RLS e senza policy cliente;
- aggiunti payload minimizzato, fingerprint SHA-256, version bump condizionale,
  refresh per pubblicazione e rebuild deterministico per shop;
- aggiunti trigger statement-level con transition table e advisory lock per shop;
- aggiunti prezzo/promozione CLP integer, immagini pubbliche, fulfillment, disponibilità,
  sort key, normalizzazione accenti, FTS `simple` e trigram;
- aggiunto harness concorrente reale a due writer;
- corretta in migration additiva separata la default ACL cloud che aveva concesso DML
  a `service_role`; la migration già applicata non è stata riscritta.

### Check eseguiti

- `PASS` — replay completo locale, 102 migration, exit 0;
- `PASS` — pgTAP completo, 20 file / 1378 test, exit 0, 44.99 s;
- `PASS` — suite Storefront TASK-005 + TASK-006, 96/96;
- `PASS` — harness concorrente: due writer sullo stesso shop, zero deadlock,
  due righe e fingerprint/versione esatti;
- `PASS` — lint DB mirato, lint/typecheck/build/security/foundation e dependency audit;
- `PASS` — CI Admin `30719303538` e Cloudflare `30719303536` sullo SHA
  `a2a45ef84b19e39d21e42673c31e2e8fc90e88f4`;
- `PASS` — dry-run riparazione ACL `30719307636` e apply staging
  `30719348489` sullo stesso SHA;
- `PASS` — postverify staging digest
  `74d323682c7545b45a95c02db5108fd11f8ef7b92c9f07451671aa4d626af796`;
- `PASS` — smoke comportamentale remoto: publish, promozione, pause/versione;
  rollback finale verificato con zero fixture persistenti;
- `NOT_RUN` — production write, vietata in questa fase.

### Matrice CA -> evidence

| CA | Stato | Evidence |
|---|---|---|
| CA-01 | PASS | migration projection + pgTAP colonne/grant/RLS |
| CA-02 | PASS | 48 test TASK-006 + smoke staging publish/pause |
| CA-03 | PASS | refresh/rebuild idempotenti e harness concorrente |
| CA-04 | PASS | fingerprint/version testati localmente e su staging |
| CA-05 | PASS | promo percentuale/fissa, expiry e CLP bigint |
| CA-06 | PASS | category/image/flags/search assertions |
| CA-07 | PASS | anon/auth zero table/helper privilege; service role SELECT-only |
| CA-08 | PASS | cross-shop denial, denylist e due writer reali |
| CA-09 | PASS | replay, 1378 pgTAP, CI/dry-run/apply/postverify/smoke stesso SHA |
| CA-10 | PASS | production invariata; artifact raw fuori repository |

### Matrice T-NN -> risultato

| Test | Stato | Risultato |
|---|---|---|
| T-01 | PASS | projection minimizzata, FORCE RLS e grant confinati |
| T-02 | PASS | publish/update/pause transazionali |
| T-03 | PASS | retry invariato senza duplicati/version bump |
| T-04 | PASS | rebuild deterministico e monotono al solo cambio |
| T-05 | PASS | prezzo, promozione, expiry, immagine e sort |
| T-06 | PASS | deny mobile/helper e cross-shop |
| T-07 | PASS | harness concorrente dopo correzione del deadlock iniziale |
| T-08 | PASS | replay, CI e staging; production NOT_RUN per policy |

### Rischi rimasti

Lo scheduler di scadenza promozioni e il filtro temporale read-time restano nello scope
TASK-008/TASK-010. API pubblica e benchmark endpoint non sono inferiti da TASK-006.

### Handoff a Review

Non applicabile prima del checkpoint integrato.

## Checkpoint release train — `CODEX_EXECUTOR`

### Gate pertinenti eseguiti

Replay, 1378 pgTAP, 96 test Storefront mirati, concurrency, lint, build, audit, CI,
dry-run/apply, postverify e smoke staging sono `PASS` sul revision set Admin
`a2a45ef84b19e39d21e42673c31e2e8fc90e88f4`.

### Compatibilità e smoke staging

Le migration TASK-005 restano nel ledger; la repair ACL è additiva. Lo smoke remoto ha
verificato publish -> promo -> pause e `fixture_rows_after_rollback = 0`. Nessuna write
production.

### Security scan mirato

Campi interni assenti, SQL function `search_path` vuoto, helper non eseguibili dai ruoli
mobili, tabelle default-deny e `service_role` SELECT-only.

### Stato manifest/checkpoint

Aggiornati al termine della transizione TASK-006 -> TASK-010.

### Handoff al task successivo

- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Review outcome**: NOT_RUN
- **Prossimo task**: TASK-010
- **Handoff**: STOREFRONT_V1_MILESTONE_CHECKPOINT_VALIDATED

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
