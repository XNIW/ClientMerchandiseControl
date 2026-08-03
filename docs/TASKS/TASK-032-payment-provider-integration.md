# TASK-032 — Decisione provider e integrazione pagamenti

## Informazioni generali

- **Task ID**: TASK-032
- **Titolo**: Decisione provider e integrazione pagamenti
- **File task**: `docs/TASKS/TASK-032-payment-provider-integration.md`
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-03
- **Ultimo aggiornamento**: 2026-08-03
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-032/`
- **Handoff**: CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW

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

### Audit e implementazione

- l'audit read-only ha confermato che non esistono credential o configurazioni
  non-interattive di un provider online approvato: nessun provider, merchant account o
  pagamento sandbox è stato inventato e `online_payment` resta fail-closed/OFF;
- la migration additiva
  `20260803122644_storefront_v1_customer_payments` introduce settings revisionati,
  payment/attempt/event/mutation/webhook receipt privati `FORCE RLS`, RPC customer e
  service separate, `search_path` vuoto e grant espliciti;
- `pay_at_pickup` è il metodo v1 disponibile per pickup configurato; COD compare solo
  con shop, delivery zone e slot abilitati. Importo, sconto, stock, shop, owner e stato
  non sono accettati come input autorevole dal client;
- order create/read v2 materializzano payment snapshot e initial attempt nello stesso
  confine atomico dell'ordine. Retry ambiguo e due richieste simultanee con la stessa
  idempotency key producono un solo order/payment/attempt/event/mutation;
- `PaymentProvider` e webhook boundary sono server-side e dormant: firma/raw-body,
  dedup e transizioni out-of-order falliscono chiuso quando il provider è `none`;
- Admin espone configurazione pagamenti Storefront revision-bound con audit redatto;
  il Client usa modelli/repository/controller strict, persiste il metodo nel retry e
  mostra soltanto metodo/stato pubblico nella review e nella ricevuta;
- la UI Material 3 riusa design system, gerarchia e componenti checkout esistenti;
  selezione offline, tile online disabilitata, Semantics, target 48 px, text scale e
  localizzazioni es-CL/it/en/zh-Hans sono coperti da widget e golden test;
- pagamento, ordine e vendita fiscale POS restano distinti: nessuna transizione
  pagamento crea `pos_sales` o un riferimento fiscale. Production è invariata.

### Revision set eseguito

- Admin/Supabase payment: `cddb3f295d735ff3e16eaf705676807cb85efaab`, PR #67;
- Admin/Supabase Milestone 4 finale:
  `e0406834af09173902e2f64948dd5834f4a9fac5`, PR #67;
- commit funzionale Admin/Supabase: `a1fa997c44d6a5804c636363ff75cbb3409a14f2`;
- Client runtime finale: `72f98eea574300f77d42e96e09557f0dd55ac2d5`, PR #5;
- Win7POS invariato: `6c2eb9c8a0b6666f5dd59a2a132e616f5a8d5474`, PR #88;
- migration staging: `20260803122644_storefront_v1_customer_payments`;
- Admin CI `30817700671`, Cloudflare `30817700396`, staging payment
  `30817695207` e POS regression `30817693665`: `PASS` sullo SHA finale;
- CI Client `30818475635`: `BLOCKED` esterna per billing/spending limit, con tre job
  senza runner né step; i gate locali sullo SHA runtime sono `PASS`.

### Gate tecnici TASK-032

- pgTAP payment 36/36, provider contract 10/10 e race due writer con un solo aggregate:
  `PASS`; staging pickup/COD, refund workflow, webhook dormant, cleanup e production
  unchanged: `PASS`;
- Admin CI finale: foundation 882 test, 869 pass + 13 skip, zero fail; lint, typecheck,
  build, database e Playwright Chromium 48/48 `PASS`;
- Client canonico `scripts/check.sh`: exit 0 in circa 120 s; 543 test funzionali e
  benchmark 20k 1/1, analyze/format/security/governance/architecture e build debug
  Android/iOS `PASS`;
- coverage finale: 11.600/14.935 linee, 77,67%; test payment/checkout mirati 45/45;
- integration checkout reale: Android Emulator API 35 1/1 e iOS Simulator 26.5 1/1;
- build release sullo SHA runtime: Android AAB 65.463.366 byte in 13,58 s e iOS
  release compile senza firma in 32,93 s; scan artifact 65 file, zero secret;
- digest AAB:
  `sha256:0f92c5b0c1a0e2ff4035a41be18c3d7dd8950d7a7ea5f0404289fc47319da7f7`;
  digest executable iOS:
  `sha256:093e60f99faba0ac69caa02001bc406508602cafc8004ac41c570d789bd5fa74`.

## Checkpoint release train — `CODEX_EXECUTOR`

L'implementazione, i gate specifici di TASK-032 e il checkpoint E2E aggregato
Milestone 4 sono verdi. TASK-032 passa a
`VALIDATED_PENDING_INTEGRATED_REVIEW`; nessuna review formale intermedia è stata
eseguita.

Il primo E2E POS concorrente `30815887397` ha osservato `db_failure` mentre la migration
payment veniva applicata in parallelo. Il retry dopo l'applicazione è passato e la causa
primaria è stata rimossa condividendo il concurrency group
`storefront-v1-staging-order-payment`; una regressione statica verifica il lock. Sullo
SHA finale, POS `30817693665` e payment `30817695207` sono entrambi verdi.

Il checkpoint aggregato finale è la run `30822286720` sullo SHA Admin/Supabase
`e0406834af09173902e2f64948dd5834f4a9fac5`: migration dry-run/post-verifica e
acceptance sono `PASS`, 13 suite/629 assertion su 629, incluse 40 assertion sullo
stesso ordine. Il flusso copre publish, visibilità catalogo, owner, cart, quote,
repricing, hold, order/payment, transizioni Admin, POS claim/ack, notification e
timeline, oltre ai casi malevoli e di replay. I run specifici TASK-027
`30822288899`, TASK-028 `30822288363` e TASK-029 `30822288362` attempt 2 sono
anch'essi `PASS` sullo stesso SHA.

Durante l'acceptance sono stati corretti, con regressioni, la promozione atomica
dell'indirizzo default e gli assert globali non isolati di order/history/Admin/POS/
notification. La migration additiva finale è
`20260803143000_storefront_v1_default_address_transition`; production e feature flag
restano invariati/OFF. L'artifact sanitizzato Milestone 4 è `8859500219`, digest
`sha256:b2fad3f10af44a11c0cdd62b43fa2a10e5433740248db5c5666a6605c454819a`.

### Matrice CA -> evidence

| Criterio | Evidence | Stato |
|---|---|---|
| CA-01 | settings/fulfillment shop-scoped, pgTAP pickup | PASS |
| CA-02 | COD opt-in su shop+zone+slot e parser Client strict | PASS |
| CA-03 | provider `none`, online defaults/flag OFF e request negata | PASS |
| CA-04 | ledger monotono, retry ambiguo e race due writer | PASS |
| CA-05 | provider interface 10/10, firma/dedup/raw-body dormant | PASS |
| CA-06 | RPC v2 senza importi/stati autorevoli e UI allow-list | PASS |
| CA-07 | failure/cancel/refund espliciti, zero vendita fiscale | PASS |
| CA-08 | widget/golden/Semantics e quattro locale | PASS |
| CA-09 | Admin/Client/staging e Milestone 4 629/629 verdi; production invariata | PASS |

### Matrice T-NN -> risultato

| Test | Risultato | Stato |
|---|---|---|
| T-01 | pickup ammesso; COD/cross-shop/disabled negati | PASS |
| T-02 | online OFF senza credential e request fail-closed | PASS |
| T-03 | un aggregate per due request e replay identico | PASS |
| T-04 | firma assente/errata e provider disabled non persistono receipt | PASS |
| T-05 | 45/45 Client payment/checkout, quattro locale e Semantics | PASS |
| T-06 | collection/refund senza `pos_sales` o fiscal reference | PASS |
| T-07 | staging pickup/COD e Milestone 4 exact-SHA 629/629 con rollback | PASS |
| T-08 | scan repository/artifact e production unchanged | PASS |

Provider online reale: `BLOCKED` esterno, perché non esistono credential sandbox
non-interattive approvate. Non limita i metodi offline v1 né il checkpoint Milestone 4.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.

## Chiusura

- **Conferma utente**: ricevuta in forma condizionata dal release train
- **Merge autorizzato**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: TASK-033 attivato dopo checkpoint verde
- **Riepilogo finale**: validato, attende la review integrata finale
- **Data completamento**: non ancora
