# TASK-029 — Admin Console: gestione e preparazione ordini

## Informazioni generali

- **Task ID**: TASK-029
- **Titolo**: Admin Console: gestione e preparazione ordini
- **File task**: `docs/TASKS/TASK-029-admin-order-queue-management.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-03
- **Ultimo aggiornamento**: 2026-08-03
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-029/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

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

Audit read-only da avviare su navigazione/componenti/RBAC Admin e sul contract
order/event/outbox/audit. Nessuna state machine o migration viene fissata prima di
avere mappato ruoli, archi fulfillment e payload privacy-safe.

## Checkpoint release train — `CODEX_EXECUTOR`

Da compilare dopo i gate tecnici; nessuna review formale intermedia.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.

## Chiusura

- **Conferma utente**: ricevuta in forma condizionata dal release train
- **Merge autorizzato**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: TASK-030 dopo checkpoint verde
- **Riepilogo finale**: in esecuzione
- **Data completamento**: non ancora
