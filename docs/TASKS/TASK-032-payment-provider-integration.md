# TASK-032 — Decisione provider e integrazione pagamenti

## Informazioni generali

- **Task ID**: TASK-032
- **Titolo**: Decisione provider e integrazione pagamenti
- **File task**: `docs/TASKS/TASK-032-payment-provider-integration.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-03
- **Ultimo aggiornamento**: 2026-08-03
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-032/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Dipendenze

- **Dipende da**: TASK-027
- **Checkpoint consumati**: checkout/quote server-authoritative, customer order
  idempotente, Admin order workflow e confine fiscale POS
- **Sblocca**: TASK-033, TASK-038, Milestone 4 E2E
- **Repository writer**: Admin/Supabase per config/state/idempotency/webhook boundary,
  poi Client per selezione/metadati non autorevoli; Win7POS solo se una regressione del
  confine incasso/vendita lo rende strettamente necessario

## Scope

- supportare Storefront v1 con `pay_at_pickup` e `cash_on_delivery` soltanto quando la
  configurazione shop/fulfillment lo abilita;
- mantenere `online_payment` e relativo feature flag fail-closed/OFF senza inventare
  provider, merchant account o credential;
- introdurre un `PaymentProvider` interface server-side e un adapter disabled/recording
  per contract test; integrare un provider sandbox reale soltanto se credential non
  interattive già esistenti sono verificate in sola lettura;
- modellare payment intent/attempt/event con state machine monotona, idempotency key,
  correlation/request ID, timeout ambiguo, retry, failure, cancellation e refund;
- separare selezione metodo, stato pagamento, customer order e vendita fiscale POS;
- rivalidare server-side metodo, fulfillment, shop, importo snapshot e feature flag;
  il client non invia importo, sconto o stato pagamento autorevole;
- definire webhook contract autenticato, replay-safe, signature-verification boundary,
  raw-body discipline, event dedup e out-of-order handling senza attivare endpoint live
  quando manca un provider;
- esporre al Client e all'Admin solo stato pubblico/localizzato e azioni consentite,
  senza provider secret, internal metadata o dati carta;
- produrre migration/RLS/pgTAP/concurrency, unit/integration, staging E2E sanitizzato,
  ADR provider e rollback; mantenere production invariata.

## Non incluso

- acquisizione di merchant credential, acquisto servizi, billing o accettazione di
  contratti/termini provider;
- raccolta o storage diretto di PAN, CVC, bank credential o altri dati PCI;
- provider live o sandbox finto, pagamento online dichiarato completato senza receipt;
- attivazione production, rollout, rimborso monetario reale o riconciliazione contabile;
- creazione automatica di una vendita fiscale dal payment event;
- wallet/gift card/installment/BNPL o più provider concorrenti nella v1.

## File coinvolti

- Admin/Supabase: ADR, migration additiva, config/metodi/stati/attempt/event ledger,
  RPC strict, provider/webhook interface, RLS/grant, pgTAP e workflow staging;
- Client: modelli/repository/controller checkout/payment, UI metodo/stato, l10n e test;
- Win7POS: sola lettura salvo regressione del confine fiscale;
- task, evidence, release manifest, checkpoint e worklog.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | `pay_at_pickup` è disponibile solo per fulfillment/shop ammessi | PGTAP/INTEGRATION |
| CA-02 | `cash_on_delivery` è fail-closed e compare solo quando abilitato | PGTAP/CLIENT |
| CA-03 | online payment resta OFF senza credential; nessun completion finto | SECURITY/CONFIG |
| CA-04 | state machine e idempotency gestiscono retry, timeout e replay monotoni | PGTAP/CONCURRENCY |
| CA-05 | webhook boundary verifica firma/raw body e deduplica senza PII/secret nei log | CONTRACT/SECURITY |
| CA-06 | client non invia importo/stato autorevole e mostra solo metodo/stato pubblico | UNIT/WIDGET |
| CA-07 | refund/failure/cancel sono modellati senza creare vendita fiscale implicita | CONTRACT/INTEGRATION |
| CA-08 | UI e messaggi sono accessibili e localizzati es-CL/it/en/zh-Hans | WIDGET/A11Y/L10N |
| CA-09 | gate Admin/Client/staging e rollback passano; production resta invariata | CI/STAGING/GIT |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|
| T-01 | CA-01, CA-02 | PGTAP | metodo/fulfillment/shop ammessi; disabled/cross-shop negati |
| T-02 | CA-03 | SECURITY | nessuna credential: online OFF e request rifiutata fail-closed |
| T-03 | CA-04 | CONCURRENCY | due request stessa key: un attempt; retry/ack perso/replay coerenti |
| T-04 | CA-05 | CONTRACT | firma valida/assente/errata, event replay e out-of-order |
| T-05 | CA-06, CA-08 | UNIT/WIDGET | selezione/metadati allow-list, Semantics e quattro locale |
| T-06 | CA-07 | INTEGRATION | failure/cancel/refund non producono `pos_sales` né fiscal reference |
| T-07 | CA-09 | STAGING | order pay-at-pickup e COD configurato con exact SHA e cleanup |
| T-08 | CA-03, CA-09 | GIT/SECURITY | secret scan, flag production OFF e nessun write production |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Storefront v1 usa `pay_at_pickup`; COD è opt-in per shop/fulfillment | Offre metodi reali senza inventare un merchant provider | ATTIVA |
| D-02 | `online_payment` resta OFF in assenza di credential sandbox già configurate | Nessun pagamento online può essere simulato come reale | ATTIVA |
| D-03 | PaymentProvider e webhook boundary sono server-side e dormant quando disabled | Secret, signature e authority non appartengono al client | ATTIVA |
| D-04 | Importo e stato pagamento sono riletti/derivati server-side | Il client non è fonte economica o di autorizzazione | ATTIVA |
| D-05 | Pagamento, ordine e vendita fiscale restano aggregate distinti | Evita doppia vendita e commistione contabile | ATTIVA |
| D-06 | Il gate provider reale mancante è esterno e limitato all'online payment | Non blocca metodi v1, hardening o release tecnica | ATTIVA |
| D-07 | Planning ed Execution sono autorizzati dal prompt USER_APPROVER del 2026-08-02 | Mantiene il release train headless continuo | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Consegnare metodi di pagamento Storefront v1 realmente supportabili e server-
authoritative, preparando un confine provider/webhook sicuro senza dichiarare un
pagamento online che non sia stato eseguito da un provider verificato.

### Analisi

- TASK-026/027 forniscono quote e order total snapshot autorevoli, ma non un payment
  aggregate o una policy metodo/fulfillment;
- TASK-030 separa già l'ordine customer dalla vendita fiscale: il payment contract deve
  conservare lo stesso confine e non creare `pos_sales`;
- `pay_at_pickup` e COD non richiedono provider remoto, ma richiedono comunque state
  machine, idempotenza, audit e una semantica pubblica non ambigua;
- un provider online non può essere scelto senza verificare credential, paese, merchant
  contract e webhook; l'interfaccia deve quindi essere pronta ma disabled;
- timeout e webhook replay richiedono attempt/event ledger monotoni, non un boolean
  `paid` mutabile dal Client.

### Approccio autorizzato

1. audit read-only di checkout/order/payment fields, feature flag, environment/secret
   names, provider dependencies, Admin config e confine fiscale POS;
2. registrare ADR con provider decision, metodi v1, state machine, idempotency, webhook,
   refund/failure e criteri di futura attivazione online;
3. migration additiva con config, payment aggregate/attempt/event privati, RPC strict,
   RLS/grant e default fail-closed;
4. `PaymentProvider` interface e recording/disabled adapter per contract test; adapter
   sandbox reale solo se credential non interattive esistono davvero;
5. integrare order/checkout e UI Client/Admin senza importo o stato client-authoritative;
6. pgTAP/race/webhook harness, unit/widget/integration e staging exact-SHA con cleanup;
7. evidence/checkpoint e attivazione TASK-033 soltanto con verde tecnico, mantenendo
   distinto il blocker esterno di un eventuale provider online.

### Rischi e mitigazioni

- pagamento doppio: unique idempotency, provider event dedup e state monotona;
- timeout ambiguo: attempt persistente e read-after-timeout, mai nuovo addebito cieco;
- webhook spoof/replay: signature boundary, raw body e provider event ID unique;
- totale manipolato: snapshot ordine riletto server-side e nessun importo client;
- COD non autorizzato: config shop/fulfillment fail-closed;
- commistione fiscale: nessun payment transition crea una sale; riferimento separato;
- secret leakage: solo adapter server-side, log sanitizer e scan repository/artifact.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: prompt headless Storefront v1 2026-08-02

## Execution — `CODEX_EXECUTOR`

Audit read-only iniziale su schema checkout/order, feature flag, provider/credential,
Admin configuration, Client payment UI e confine fiscale Win7POS. Nessun provider o
dipendenza viene scelto prima dell'audit.

## Checkpoint release train — `CODEX_EXECUTOR`

Da compilare dopo i gate tecnici; nessuna review formale intermedia.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.

## Chiusura

- **Conferma utente**: ricevuta in forma condizionata dal release train
- **Merge autorizzato**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: TASK-033 dopo checkpoint verde
- **Riepilogo finale**: in esecuzione
- **Data completamento**: non ancora
