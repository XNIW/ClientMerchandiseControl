# TASK-029 — Admin Console: gestione e preparazione ordini

## Informazioni generali

- **Task ID**: TASK-029
- **Titolo**: Admin Console: gestione e preparazione ordini
- **File task**: `docs/TASKS/TASK-029-admin-order-queue-management.md`
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-03
- **Ultimo aggiornamento**: 2026-08-03
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-029/`
- **Handoff**: CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW

## Dipendenze

- **Dipende da**: TASK-007, TASK-027, checkpoint tecnico TASK-028
- **Checkpoint consumati**: Admin RBAC/shop scope, customer order/snapshot/event/outbox,
  history/timeline e cancellation policy
- **Sblocca**: TASK-030, TASK-031
- **Repository writer**: Admin/Supabase; nessun writer Client o POS salvo regressioni
  strettamente necessarie al contratto già approvato

## Scope

- aggiungere una queue ordini shop-scoped con paginazione deterministica, ricerca e
  filtri persistenti per stato, fulfillment e finestra temporale;
- aggiungere detail operativo con item/fulfillment snapshot, timeline customer,
  audit amministrativo e stato POS/push solo quando realmente disponibile;
- implementare transizioni server-authoritative `accept`, `reject`, `preparing`,
  `ready`, `out_for_delivery`, `complete` e `cancel` secondo stato e fulfillment;
- rendere ogni mutation idempotente, version-checked, autenticata e autorizzata da
  membership/ruolo shop, con event/audit/outbox atomici;
- mantenere ordine cliente distinto da vendita fiscale e non scrivere `pos_sales`;
- realizzare UI Admin responsive con queue, status chip, filtri persistenti, split view
  list/detail, loading/error/empty, shortcut/focus order e conferme non ambigue;
- eseguire pgTAP/RBAC/cross-tenant, state-machine/concurrency/replay, unit/integration,
  Playwright headless, staging exact-SHA, build, security e cleanup;
- mantenere production e feature flag invariati/OFF.

## Non incluso

- consumer/ack/replay Win7POS e vendita fiscale, di competenza TASK-030;
- invio push e gestione provider notifiche, di competenza TASK-031;
- pagamento o rimborso, di competenza TASK-032;
- bulk transition irreversibili o modifica di prezzo/item/indirizzo dopo conferma;
- accesso service-role dal browser, secret client-side o bypass RBAC;
- activation production, rollout o dipendenza da GUI/dispositivo fisico.

## File coinvolti

- Admin Console: route Storefront Orders, componenti queue/detail, adapter server e
  test unit/Playwright nel design system esistente;
- Supabase: migration additiva, RPC Admin strict, indici/audit e pgTAP;
- workflow staging exact-SHA e artifact sanitizzati;
- task, evidence, release manifest, checkpoint e worklog.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Queue/detail sono shop-scoped, paginati, filtrabili e privacy-safe | CONTRACT/PGTAP |
| CA-02 | Solo ruoli autorizzati possono leggere o mutare ordini del proprio shop | RBAC/PGTAP |
| CA-03 | State machine rifiuta transizioni invalide e rispetta fulfillment/stato terminale | PGTAP |
| CA-04 | Mutation è idempotente, version-checked e atomica con event/audit/outbox | CONCURRENCY/PGTAP |
| CA-05 | Order customer resta separato da `pos_sales` e l'outbox è POS-neutral | SECURITY/CONTRACT |
| CA-06 | Queue, filtri, detail, timeline e azioni sono responsive e accessibili | UI/PLAYWRIGHT |
| CA-07 | Loading/error/empty/retry, double submit e timeout ambiguo sono recuperabili | UNIT/INTEGRATION |
| CA-08 | Audit non contiene token/PII e ogni transition ha actor, request e correlation ID sanitizzati | SECURITY/PGTAP |
| CA-09 | Gate Admin/Supabase, staging e browser headless passano sul revision set | CI/BUILD/STAGING |
| CA-10 | Production resta invariata e zero secret/config/artifact viene versionato | SECURITY/GIT |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-02 | PGTAP/RBAC | owner shop ammesso; anon, ruolo insufficiente e cross-shop negati |
| T-02 | CA-01 | CONTRACT | cursor stabile, filtri combinati, limite bounded e zero internal field |
| T-03 | CA-03 | PGTAP | attraversare ogni arco valido e rifiutare skip/backward/terminal mutation |
| T-04 | CA-04 | CONCURRENCY | due operatori stessa version: un commit, replay uguale, loser stale |
| T-05 | CA-04, CA-08 | PGTAP | transition/event/audit/outbox atomici e rollback senza record parziali |
| T-06 | CA-05 | SECURITY | nessuna vendita fiscale, duplicate replay o field operativo nella UI |
| T-07 | CA-06, CA-07 | UNIT/PLAYWRIGHT | filtri persistenti, list/detail, azioni, confirm, error/retry e keyboard |
| T-08 | CA-06 | RESPONSIVE/A11Y | compact/wide, focus order, target, Semantics/ARIA e contrasto |
| T-09 | CA-09, CA-10 | STAGING/CI/GIT | exact SHA, fixture/cleanup, gate completi e production unchanged |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | La state machine e l'autorizzazione sono esclusivamente server-side | Il browser Admin non è un confine di sicurezza | ATTIVA |
| D-02 | Ogni mutation richiede idempotency key e expected status version | Impedisce doppio avanzamento e lost update | ATTIVA |
| D-03 | Event, audit e outbox sono nello stesso commit dell'ordine | Evita timeline o handoff divergenti | ATTIVA |
| D-04 | L'Admin mostra snapshot confermato e non modifica dati economici/order item | Preserva il contratto customer-order TASK-027 | ATTIVA |
| D-05 | Nessuna bulk transition irreversibile in v1 | Riduce danni operativi e ambiguità di conferma | ATTIVA |
| D-06 | POS consumer e push sender restano spenti fino ai rispettivi task | Mantiene dipendenze e responsabilità separate | ATTIVA |
| D-07 | Planning ed Execution sono autorizzati dal prompt USER_APPROVER del 2026-08-02 | Mantiene il release train headless continuo | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Fornire agli operatori autorizzati una coda ordini efficiente e un workflow di
preparazione affidabile, shop-scoped e idempotente, senza fondere ordine cliente,
handoff POS e vendita fiscale.

### Analisi

- TASK-027/028 forniscono aggregate, snapshot, status event, outbox e timeline customer,
  ma nessuna API o UI operativa Admin per avanzare lo stato;
- l'Admin esistente possiede pattern RBAC/shop membership, navigazione Storefront,
  tabelle responsive e test Playwright da riusare prima di creare nuovi componenti;
- i consumer POS/push non esistono ancora: la mutation deve produrre envelope
  compatibile e osservabile senza fingere ack o delivery esterni;
- accept/reject/preparing/ready/delivery/complete/cancel richiedono una state machine
  esplicita per fulfillment e lock/versioning per operatori concorrenti;
- ricerca e filtri devono evitare N+1 e offset instabile, mantenendo snapshot e PII
  minimizzati nel browser.

### Approccio autorizzato

1. audit read-only di route/componenti Storefront Admin, session/RBAC, order schema,
   event/outbox e pattern audit esistenti;
2. definizione state machine, role matrix, list/detail payload allow-list, cursor e
   idempotency/version contract;
3. migration additiva minima con RPC strict, indici, audit/event/outbox atomici e
   pgTAP ownership/transizioni;
4. concurrency/replay a due sessioni e staging guarded con fixture sintetiche/cleanup;
5. queue/detail Admin nel design system corrente, filtri persistenti, split view,
   error/loading/empty e keyboard/focus;
6. unit/integration/Playwright responsive, security, build, CI e staging exact-SHA;
7. evidence/checkpoint e attivazione TASK-030 soltanto con verde tecnico.

### Rischi e mitigazioni

- cross-tenant: membership e shop derivati server-side, risposta not-found uniforme;
- doppia transition: advisory/row lock, expected version e ledger idempotente;
- state skip: tabella/arco esplicito validato nel server e testato esaustivamente;
- audit PII: allow-list di actor/request/correlation ID e nessun payload cliente grezzo;
- coupling POS/push: outbox neutra, consumer assenti e nessun claim di ack/notifica;
- UX pericolosa: azioni contestuali, conferma esplicita e nessuna bulk transition;
- query lenta/N+1: keyset e detail separato con explain/load bounded.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: prompt headless Storefront v1 2026-08-02

## Execution — `CODEX_EXECUTOR`

### Audit e implementazione

- l'audit ha confermato `customer_orders`, item snapshot, status event e outbox come
  authority dell'ordine cliente e `pos_sales` come confine fiscale separato; il browser
  non legge tabelle private né usa `service_role`;
- la migration additiva `20260803053000_storefront_v1_admin_orders` aggiunge i permessi
  `orders.view`/`orders.manage`, un ledger mutation privato `FORCE RLS`, RPC strict per
  queue/detail e transizione, indici bounded e grant minimi;
- queue e detail derivano lo shop dall'authorization context, usano keyset
  `(placed_at,id)`, limite massimo 50 e payload allow-list; la ricerca copre soltanto
  codice ordine e nome pubblico item;
- la state machine server-side implementa `accept`, `reject`, `preparing`, `ready`,
  `out_for_delivery`, `complete` e `cancel`, con archi specifici per pickup,
  reservation e delivery, `expected_status_version`, lock e idempotency key;
- ogni commit valido aggiorna ordine, event append-only, audit redatto, outbox
  POS-neutral e ledger nella stessa transazione; replay identico restituisce lo stesso
  risultato, payload divergente e secondo operatore stale falliscono chiusi;
- la route `/shop/orders` riusa shell e design system esistenti: filtri persistenti,
  ricerca, status chip, queue/detail responsive, timeline, stato handoff e azioni
  contestuali con conferma, keyboard/focus e messaggi recuperabili;
- il deploy staging applicativo è sullo SHA `1a50fcd1`; i commit successivi fino a
  `23bfab60` modificano soltanto fixture/test e sono stati verificati dalla CI e
  dall'acceptance exact-SHA;
- la fixture Storefront persistente è stata resa idempotente e non distruttiva: upsert
  bounded dello shop canonico, nessuna cancellazione di shop/audit/ordini e verifica
  pubblica finale; le server action streaming sono attese tramite target UUID distinto
  e navigation `commit`.

### Revision set eseguito

- Admin/Supabase finale: `23bfab60b91ef192dbb726bde454287cea144c8f`, PR #67 draft;
- SHA applicativo deployato: `1a50fcd1e16107c381bf0cf8ed47991b7c8afd73`;
- Client runtime invariato: `1855100f34a3563787b1ac71eafb4af60a1b72e6`, PR #5 draft;
- migration staging: `20260803053000_storefront_v1_admin_orders`;
- apply/verify staging: run `30791945888`; artifact migration `8847378085`, digest
  `sha256:0791420eb645f90d3bd3dd58b5472cf332f92351023ce848d885ae6dc32e755b`;
  artifact TASK-029 `8847396310`, digest
  `sha256:347f6dd964f64bd9a1572069ce8ac9337f1f525e38ca2db7eb1bd74b0cf61e4f`;
- deploy staging: run `30796888108`; acceptance finale exact-SHA: run `30798109969`;
  fixture artifact `8849757536`, digest
  `sha256:c2b596c2bdbfc827ac3def9889565a1dc53ac0f48bc694e4bb5d8022d6c454e5`;
- production e feature flag: invariati/OFF; consumer POS e push non attivati.

### Gate

- `supabase db reset`: exit 0, 27,18 s; replay migration completo `PASS`;
- pgTAP TASK-029: exit 0, 34/34, 1,60 s; race due operatori: exit 0, 1,33 s;
- suite foundation locale: exit 0, 858 totali, 856 pass + 2 skip, 11,39 s;
- `npm run verify` con worktree Win7POS release richiesto: exit 0, 21,27 s;
- Playwright locale queue/detail desktop+tablet: exit 0, 2/2, 8,66 s; regressione
  pubblicazione finale: exit 0, 1/1, 11,8 s;
- CI finale `30798108711`: `PASS` sullo SHA esatto; job Verify 2m52s, Database
  migrations/pgTAP 3m6s, UI smoke 48/48 e build `/shop/orders` inclusa;
- Cloudflare PR build `30798108767`: `PASS` in 3m34s; deploy production `NOT_RUN`
  perché correttamente skipped;
- staging acceptance `30798109969`: pubblicazione/promozioni/fulfillment 1/1 in 55,2 s,
  queue/transizione ordine 1/1 in 8,8 s, cleanup 0 e fixture persistente `PASS`;
- contratti dipendenti TASK-024 `30798106257` e TASK-026 `30798106250`: `PASS`;
- dependency audit: exit 0, 660 package, 0 vulnerabilità; secret/diff/artifact scan e
  worktree Admin pulito: `PASS`.

## Checkpoint release train — `CODEX_EXECUTOR`

TASK-029 è tecnicamente validato e consegnato alla futura review integrata come
`VALIDATED_PENDING_INTEGRATED_REVIEW`. Lo staging ha verificato publish/fulfillment,
queue/detail, transizione reale, assenza di `pos_sales`, cleanup e fixture persistente.
Nessuna review formale intermedia o modifica production è stata eseguita.

I tentativi non candidati sono preservati: grant `service_role` del ledger incompleto,
lettura fulfillment immediata non coerente, navigation RSC fredda, fixture distruttiva
incompatibile con gli ordini persistenti e predicate URL che poteva soddisfarsi sul
target precedente. Ogni causa primaria è stata corretta con una regressione; il run
finale non è un retry cieco.

### Matrice CA -> evidence

| Criterio | Evidence | Stato |
|---|---|---|
| CA-01 | RPC queue/detail shop-scoped, keyset, filtri e allow-list pgTAP | PASS |
| CA-02 | permission matrix personale/POS Admin e denial anon/cross-shop | PASS |
| CA-03 | state machine esaustiva per pickup/reservation/delivery | PASS |
| CA-04 | lock/version/ledger, race due operatori ed event/audit/outbox atomici | PASS |
| CA-05 | contract/outbox `documentKind=customer_order`, zero write `pos_sales` | PASS |
| CA-06 | Playwright desktop/tablet, axe, focus, queue/detail/timeline/azioni | PASS |
| CA-07 | loading/error/empty, double submit, stale e timeout recuperabili | PASS |
| CA-08 | audit metadata allow-list e correlation/request UUID sanitizzati | PASS |
| CA-09 | gate locali, CI, deploy e staging exact-SHA | PASS |
| CA-10 | scan secret/artifact, production invariata e flag OFF | PASS |

### Matrice T-NN -> risultato

| Test | Risultato | Stato |
|---|---|---|
| T-01 | owner/manager ammessi; insufficient role, anon e cross-shop negati | PASS |
| T-02 | cursor stabile, filtri combinati, limite 50 e zero field interno | PASS |
| T-03 | tutti gli archi validi e skip/backward/terminal rifiutati | PASS |
| T-04 | un commit, un stale loser e replay identico | PASS |
| T-05 | event/audit/outbox/ledger atomici e rollback senza record parziali | PASS |
| T-06 | fiscal status `not_created` e zero riga `pos_sales` | PASS |
| T-07 | UI locale e staging, filtri/detail/confirm/error/keyboard | PASS |
| T-08 | compact/wide, target, focus, Semantics/ARIA e contrasto | PASS |
| T-09 | staging exact-SHA, fixture idempotente, cleanup e production unchanged | PASS |

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.

## Chiusura

- **Conferma utente**: ricevuta in forma condizionata dal release train
- **Merge autorizzato**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: TASK-030 attivato dopo checkpoint verde
- **Riepilogo finale**: queue e workflow Admin ordini tecnicamente validati; review
  integrata differita al freeze multi-repository
- **Data completamento**: non ancora
