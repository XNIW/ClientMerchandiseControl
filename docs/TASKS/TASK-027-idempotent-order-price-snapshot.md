# TASK-027 — Creazione ordine idempotente e price snapshot

## Informazioni generali

- **Task ID**: TASK-027
- **Titolo**: Creazione ordine idempotente e price snapshot
- **File task**: `docs/TASKS/TASK-027-idempotent-order-price-snapshot.md`
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-02
- **Ultimo aggiornamento**: 2026-08-03
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-027/`
- **Handoff**: CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW

## Dipendenze

- **Dipende da**: TASK-005, TASK-020, TASK-023, TASK-025, TASK-026
- **Checkpoint consumati**: schema/RLS; auth; cart/revalidation; hold; checkout quote
- **Sblocca**: TASK-028, TASK-029, TASK-030, TASK-031, TASK-032, TASK-033, TASK-034,
  TASK-035, TASK-037
- **Repository writer**: Admin/Supabase, poi Client; nessun writer POS in questo task

## Scope

- creare un ordine customer/shop-scoped in un'unica transazione server-side partendo da
  una quote TASK-026 confermata e ancora valida;
- autenticare il customer, verificare shop e rileggere cart, publication, prezzo,
  promozione, quantità, availability e hold sotto un ordine di lock deterministico;
- creare `order`, item snapshot immutabili, primo status event e outbox nella stessa
  transazione, consumando hold e capacità esattamente una volta;
- definire ID pubblico ordine, version/status, fulfillment snapshot e snapshot economico
  CLP senza esporre source product, costo, supplier o inventory operativa;
- rendere create/read-by-idempotency idempotenti e recuperabili dopo timeout ambiguo;
  stessa key/payload restituisce lo stesso ordine, payload diverso confligge;
- ignorare totale, sconto, prezzo, promotion e customer/shop autoritativi inviati dal
  client; ogni divergenza deve fallire chiuso o richiedere una nuova quote;
- integrare nel Client la conferma finale e una receipt minima accessibile/localizzata,
  mantenendo cart e intent quando l'esito remoto è ambiguo;
- produrre replay, pgTAP/RLS, concurrency duplicate/ultimo pezzo, staging E2E, Flutter
  unit/widget/integration Android/iOS, build e smoke headless;
- mantenere production e tutti i feature flag invariati/OFF.

## Non incluso

- lista, dettaglio completo, timeline e cancellazione ordine, di competenza TASK-028;
- queue e transizioni operative Admin, di competenza TASK-029;
- consegna POS o creazione vendita fiscale, di competenza TASK-030;
- invio push, di competenza TASK-031;
- provider/pagamento online, di competenza TASK-032;
- attivazione production, migrazioni distruttive o dipendenza da GUI/dispositivo fisico;
- fiducia in totale, prezzo, sconto, fee, shop, customer, order ID o clock client.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Create autentica customer/shop e accetta soltanto quote confermata, owner-scoped, valida e non consumata | CONTRACT/PGTAP |
| CA-02 | Cart/catalogo/prezzo/promo/availability/hold sono riletti e bloccati server-side | SECURITY/CONCURRENCY |
| CA-03 | Order, item snapshot, status event e outbox sono atomici; hold/capacity sono consumati una volta | PGTAP/INTEGRATION |
| CA-04 | Totale/prezzo/sconto/fee/customer/shop malevoli non diventano autorità | SECURITY |
| CA-05 | Idempotency replaya lo stesso ordine e key/payload confliggente fallisce chiuso | CONCURRENCY/INTEGRATION |
| CA-06 | Duplicate, timeout ambiguo e retry non creano doppio ordine, doppio consumo o doppia outbox | CONCURRENCY |
| CA-07 | Snapshot economico/fulfillment resta immutabile e privacy-safe dopo cambi catalogo | CONTRACT/PGTAP |
| CA-08 | Client mostra conferma reale, preserva intent ambiguo e svuota cart soltanto dopo esito autorevole | UNIT/WIDGET/INTEGRATION |
| CA-09 | RLS nega anon, cross-user e cross-shop; mobile usa soltanto RPC strict | SECURITY/PGTAP |
| CA-10 | Gate Admin/Supabase/Client, staging e smoke headless passano sul revision set | CI/BUILD/SMOKE |
| CA-11 | Production resta invariata e nessun secret/config/artifact è versionato | SECURITY/GIT |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-09 | PGTAP/RLS | owner create/read; anon, cross-user, cross-shop e quote non confermata denied |
| T-02 | CA-02, CA-04 | PGTAP/SECURITY | ricalcolo e input economici/customer/shop malevoli ignorati o rifiutati |
| T-03 | CA-03 | PGTAP | ordine, item snapshot, event, outbox e consume hold nello stesso commit/rollback |
| T-04 | CA-05, CA-06 | CONCURRENCY | due sessioni stessa key e key diverse su stessa quote; un solo ordine/outbox/consume |
| T-05 | CA-07 | CONTRACT | modifica catalogo successiva non muta snapshot e response non espone dati interni |
| T-06 | CA-08 | UNIT/WIDGET | success, timeout/read recovery, conflict, expired/reprice e cart clear post-success |
| T-07 | CA-08 | ANDROID_EMU/IOS_SIM | checkout confermato -> create order -> receipt con tap reali headless |
| T-08 | CA-10 | STAGING | fixture sintetica completa, order create/replay, rollback/cleanup e exact SHA |
| T-09 | CA-10, CA-11 | CI/GIT | replay migration, gate, secret scan e production unchanged |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | La quote confermata è un prerequisito, non l'autorità finale dell'ordine | Consente la rivalidazione atomica al commit | ATTIVA |
| D-02 | Order, snapshot, primo event, outbox e consumo hold condividono una transazione | Evita stati parziali e side effect fantasma | ATTIVA |
| D-03 | Snapshot usa soli campi pubblici/economici necessari e diventa immutabile | Conserva storico senza leakage operativo | ATTIVA |
| D-04 | Idempotency key è legata a quote/version/payload server-derived | Evita duplicate e riuso ambiguo | ATTIVA |
| D-05 | Il Client svuota il cart soltanto dopo ordine autorevole recuperabile | Evita perdita dati su timeout ambiguo | ATTIVA |
| D-06 | POS, push, payment e workflow Admin restano nei task successivi | Mantiene il confine del task | ATTIVA |
| D-07 | Planning ed Execution sono autorizzati dal prompt USER_APPROVER del 2026-08-02 | Mantiene il release train headless continuo | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Trasformare una quote confermata in un ordine atomico, immutabile e idempotente, pronto
per tracking, Admin e handoff POS senza confondere ordine cliente e vendita fiscale.

### Analisi

- TASK-026 conferma quote con prezzi/fulfillment rivalidati, ma non crea side effect di
  ordine e la quote può diventare stale prima del commit;
- TASK-025 fornisce hold monotono, ma il consumo deve essere serializzato con order e
  item snapshot per impedire doppio uso;
- gli schemi correnti vanno auditati per nomi `order`/`sale`, audit/outbox esistenti e
  compatibilità futura POS prima di introdurre le tabelle minime;
- idempotency deve distinguere replay, conflitto e timeout ambiguo senza fidarsi di ID,
  owner o payload economico client;
- l'ordine deve conservare snapshot pubblici e fulfillment sufficienti allo storico,
  evitando coupling all'inventory operativo.

### Approccio autorizzato

1. audit read-only di schema order/sale/event/outbox, quote/cart/hold, writer inventory,
   convenzioni ID/RLS/audit e contratti POS di riferimento;
2. definizione invarianti, state machine iniziale, snapshot allow-list, lock order e
   ownership transazionale;
3. migration additiva minima con tabelle private/FORCE RLS, indici, constraint, RPC
   create/read idempotenti e grant strict;
4. pgTAP e concorrenza per replay/conflict, due sessioni, rollback parziale, stale
   quote, hold expiry e malicious economic input;
5. staging guarded con fixture sintetiche, exact-SHA, replay e cleanup verificabile;
6. repository/controller/receipt Client strettamente necessari, con pending operation
   persistita e cart clear post-success;
7. integration Android/iOS, build, smoke, security/artifact scan e gate completi;
8. evidence/checkpoint e attivazione TASK-028 soltanto con verde tecnico.

### Rischi e mitigazioni

- doppio ordine/outbox: unique constraint + ledger + lock della quote nella transazione;
- oversell/doppio consume: ordine lock deterministico su quote/cart/hold/inventory;
- prezzo stale: ricalcolo finale e nuova quote richiesta senza side effect parziale;
- timeout ambiguo: read/replay per idempotency key prima di creare un nuovo intent;
- snapshot incompleto/leakage: allow-list contrattuale e test negative fields;
- deadlock: lock order unico, transazioni brevi e race multi-session;
- coupling POS: outbox neutra e ordine cliente distinto da fiscal sale.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: prompt headless Storefront v1 2026-08-02

## Execution — `CODEX_EXECUTOR`

### Audit e implementazione

- l'audit read-only ha confermato che `pos_sales` rappresenta la vendita fiscale e non
  poteva essere riusata come ordine cliente; prima del task non esistevano aggregate
  order/event/outbox customer, mentre cart, quote, hold e helper ATP/capacità erano i
  boundary corretti da estendere;
- Admin/Supabase introduce `customer_orders`, `customer_order_items`,
  `customer_order_status_events`, `customer_order_outbox` e
  `customer_order_mutations`, tutte private e FORCE RLS, con create/read RPC strict;
- `customer_order_create_v1` autentica il customer, deriva lo shop dalla quote, usa
  advisory lock e row lock, rivalida cart/catalogo/prezzo/promo/availability/hold,
  crea aggregate/event/outbox, consuma quote/hold e svuota il cart in una transazione;
- l'outbox usa `documentKind=customer_order` e `fiscalStatus=not_created`; nessun write
  viene effettuato su `pos_sales` e il consumo POS resta TASK-030;
- snapshot economico, fulfillment, item, status event e envelope outbox hanno trigger
  espliciti di immutabilità/append-only, con cancellazioni referenziali controllate;
- il Client usa un adapter RPC allow-list, persiste pending operation e order ID per
  account/shop, replaya la stessa key dopo timeout/offline, aggiorna il cart soltanto
  dopo receipt autorevole e mostra una receipt accessibile/localizzata;
- Android e iOS hanno attraversato con tap reali quote, conferma, timeout ambiguo,
  replay e receipt; gli artifact normali sono stati installati e avviati headlessly.

### Revision set eseguito

- Admin/Supabase: `599511c03cb502b9b76561ff320cfdbb4073b1ee`, PR #67 draft;
- Client runtime: `64c8f711547f8d5c5dc18650a03a9d5345bb71b7`, PR #5 draft;
- migration: `20260803033000_storefront_v1_customer_orders` e
  `20260803034500_storefront_v1_customer_order_capacity`;
- staging: run `30783882947`, attempt 2, artifact `8844663559`, digest
  `ea8ae759e6af6fc1a194f8a0f9b168164fd0e19003bfaf046298c3f092e5ece3`;
- production e feature flag: invariati/OFF.

### Gate

- replay completo migration, pgTAP 35/35 e concorrenza duplicate/replay: `PASS`;
- Admin lint/typecheck/build/security e foundation 845 pass + 2 skip: `PASS`;
- Admin CI `30783886282`, Cloudflare `30783886269` e staging exact-SHA
  `30783882947`: `PASS`;
- Client gate canonico: 497/497 test, performance 1/1, coverage
  9.531/12.477 (76,39%), analyze/format/security/governance/architecture e build
  Android/iOS: `PASS`;
- integration checkout/order Android API 35 e iPhone 17 Pro iOS 26.5: 1/1 per
  piattaforma, `PASS`; smoke artifact Android/iOS: `PASS`;
- CI Client `30784085502`: `BLOCKED` esterno, tre job con zero runner/step e
  annotazione billing/spending limit; nessun test CI viene dichiarato eseguito.

## Checkpoint release train — `CODEX_EXECUTOR`

TASK-027 è tecnicamente validato e consegnato alla futura review integrata con stato
`VALIDATED_PENDING_INTEGRATED_REVIEW`. La fixture staging è stata ripulita dai test;
la migration ledger e i post-check sono persistenti. Non è stata eseguita review
formale intermedia, non sono stati modificati production o POS e nessun task è `DONE`.

Il primo run staging `30783882947` fu cancellato senza step dalla coda concurrency
condivisa, perché più workflow storiche si erano attivate sulla modifica della reusable
workflow. Dopo la conclusione degli apply già in coda, l'attempt 2 sullo stesso SHA è
passato integralmente. Il primo smoke Android non trovava `adb` nel `PATH`; il comando
corretto ha usato il path SDK assoluto ed è passato, senza un terzo retry cieco.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.

## Chiusura

- **Conferma utente**: ricevuta in forma condizionata dal release train
- **Merge autorizzato**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: TASK-028 dopo checkpoint verde
- **Riepilogo finale**: ordine atomico/idempotente, receipt e staging validati; review
  integrata differita al freeze multi-repository
- **Data completamento**: non ancora
