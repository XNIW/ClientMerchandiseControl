# TASK-034 — Offline, reconnect, concorrenza e idempotenza

## Informazioni generali

- **Task ID**: TASK-034
- **Titolo**: Offline, reconnect, concorrenza e idempotenza
- **File task**: `docs/TASKS/TASK-034-resilience-concurrency-idempotency.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-16
- **Ultimo aggiornamento**: 2026-08-16
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-034/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Dipendenze

- **Dipende da**: TASK-017, TASK-023, TASK-025, TASK-027, TASK-030, TASK-043, TASK-044, TASK-045
- **Sblocca**: TASK-035

## Scope

- costruire e mantenere una matrice canonica di failure/race per Auth, Catalogo,
  Carrello, Checkout, Ordini, Delivery Tracking e handoff Admin/POS;
- verificare authority server, idempotency key, expected version, classificazione retry,
  riconciliazione deterministica e assenza di side effect duplicati per le mutazioni;
- correggere esclusivamente gap riproducibili nei flussi esistenti e aggiungere test di
  regressione deterministici, inclusi repeat/stress per le race critiche;
- applicare e verificare su staging la migration delivery tracking già integrata, con
  dati sintetici, RLS owner-scoped, terminal redaction e cleanup;
- preservare capability e confini già integrati senza refactor cosmetici.

## Contesto

I controller Client e gli RPC Storefront possiedono già generation guard, idempotency,
expected version, cache e recovery in molti percorsi. Il task non assume che siano
completi: classifica ogni caso richiesto, collega evidence esistente quando ancora
valida e aggiunge nuove regressioni dove manca una prova diretta. La migration delivery
tracking è presente su `main` Admin ma assente dalla history staging al preflight.

## Non incluso

- nuove capability commerce, nuovi provider pagamento o stati ordine;
- accesso diretto del Client a inventory, fulfillment o tabelle operative;
- migration o activation switch production;
- modifiche ai repository read-only senza regressione cross-repository riproducibile;
- test basati su sleep/wall-clock quando sono disponibili clock, scheduler, `Completer`
  o time advancement controllati.

## File coinvolti

- `lib/features/auth/`, `catalog/`, `cart/`, `checkout/`, `orders/`,
  `delivery_tracking/` e relativi test;
- contract/RPC/test Storefront nell'Admin soltanto se emerge un gap reale;
- `docs/quality/`, `docs/releases/`, governance ed evidence TASK-034.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | La matrice canonica classifica ogni caso richiesto, con nessun critical `UNTESTED` | DOCUMENT/REVIEW |
| CA-02 | Auth copre offline/sessione, expiry/refresh concorrente, logout/account switch, callback/deep link duplicati e cancellazione in-flight | UNIT/INTEGRATION |
| CA-03 | Catalogo copre cache cold/warm/stale, offline/reconnect, refresh/pagination/query/filter race, immagini e version change | UNIT/WIDGET |
| CA-04 | Carrello copre mutazioni concorrenti/duplicate, restart/merge/offline/reconnect, reprice/unavailable/hold/quantity/idempotency/stale response | UNIT/DB |
| CA-05 | Checkout copre doppio submit, timeout ambiguo/response lost, resume/restart, price/stock/address/slot change, payment pending/duplicate e order recovery | UNIT/DB |
| CA-06 | Ordini copre refresh/pagination/cancel race, timeout ambiguo, eventi/push/deep link duplicati o fuori ordine, cache/reconnect/stale status | UNIT/DB |
| CA-07 | Delivery tracking copre reconnect/fallback, snapshot duplicate/out-of-order/stale, terminal/reassignment/session/auth/lifecycle/map/carrier failure | UNIT/WIDGET/DB |
| CA-08 | Admin/POS copre transition duplicate/version race, retry handoff/release, timeout-after-commit e terminal replay | DB/CONTRACT |
| CA-09 | Race critiche usano clock/scheduler controllabile e repeat/stress bounded, senza attese wall-clock fragili | UNIT/STRESS |
| CA-10 | Migration/RLS/live smoke staging sintetico, gate canonici, review indipendente, CI exact-SHA e zero P0/P1/P2 sono reali | DB/SMOKE/CI/REVIEW |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01 | STATIC | Validare completezza, severità, authority, retry, reconciliation ed evidence della matrice |
| T-02 | CA-02 | UNIT/INTEGRATION | Eseguire suite auth con request controllate, callback/deep link e account generation |
| T-03 | CA-03 | UNIT/WIDGET | Eseguire cache/query/pagination race con completion order controllato |
| T-04 | CA-04 | UNIT/DB | Eseguire mutation queue, duplicate key, stale version, offline persistence e reconciliation |
| T-05 | CA-05 | UNIT/DB | Eseguire submit/recovery/idempotency e failure server-authoritative |
| T-06 | CA-06 | UNIT/DB | Eseguire list/detail/cancel/event/deep-link monotonicity e cache offline |
| T-07 | CA-07 | UNIT/WIDGET/DB | Eseguire snapshot/lifecycle/fallback/terminal/auth/provider failure |
| T-08 | CA-08 | DB/CONTRACT | Eseguire RPC concurrency e retry Admin/POS senza effetti duplicati |
| T-09 | CA-09 | STRESS | Ripetere race critiche con scheduler deterministico e seed bounded |
| T-10 | CA-10 | COMMAND/CI | Reset/pgTAP, staging guarded smoke, gate Client/Admin, review, PR/main CI exact-SHA |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Il mandato USER_APPROVER del 2026-08-16 autorizza Planning→Execution e l'intero ciclo condizionato del task. | Autorizzazione esplicita | ATTIVA |
| D-02 | Le prove già integrate sono riusate soltanto se il boundary non è cambiato e la matrice collega una evidence specifica. | Evitare lavoro duplicato senza inferire PASS | ATTIVA |
| D-03 | Ogni fix resta server-authoritative e bounded; nessun retry automatico di una mutazione ambigua senza idempotency/recovery. | Prevenire side effect duplicati | ATTIVA |
| D-04 | La migration TASK-044 viene applicata solo allo staging tramite percorso guarded; production resta intatta. | Mandato e sicurezza | ATTIVA |
| D-05 | ADR-015 governa il lifecycle TASK-034–TASK-042 e sostituisce per questi task la review unica prevista da ADR-011. | Emendamento USER_APPROVER successivo | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Dimostrare e, dove necessario, correggere la resilienza deterministica dei flussi
commerce rispetto a offline, reconnessione, race e replay, dal Client fino ai contratti
Admin/Supabase.

### Analisi

La baseline contiene già protezioni distribuite: generation token nei controller,
pending mutation persistenti, idempotency key, expected version, snapshot monotoni,
fallback polling e RPC atomici. Il rischio principale è la copertura non uniforme e la
mancanza di una singola mappa verificabile tra failure mode e comportamento atteso.

### Approccio

1. inventariare implementazione e test e classificare ogni cella della matrice;
2. eseguire suite mirate e isolare i gap riproducibili;
3. aggiungere il minimo fix e regressioni deterministiche, con repeat sulle race;
4. validare database locale e staging, incluso delivery tracking owner-scoped;
5. eseguire gate completi, review indipendente, eventuale fix/re-review, CI e merge.

### Rischi

- test flake da timer reali: usare clock/scheduler e avanzamento controllati;
- retry ambiguo: riusare la stessa idempotency key e recuperare lo stato server;
- cache cross-account: invalidare per generation/account e verificare logout;
- scrittura staging: usare fixture sintetiche, allowlist, cleanup e workflow guarded;
- collisione Admin con workstream estranei: modificare soltanto il boundary Storefront
  in worktree dedicato e non alterare governance non correlata.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION
- **Autorizzazione USER_APPROVER**: ricevuta nel prompt del 2026-08-16; applicata come `CODEX_PLANNING_APPROVED_TO_EXECUTION`

## Execution — `CODEX_EXECUTOR`

### Obiettivo compreso

Completare CA-01–CA-10 senza modificare scope o attivare production.

### File controllati

In corso.

### Piano minimo

In corso secondo il Planning approvato.

### Modifiche fatte

In corso.

### Check eseguiti

In corso; nessun `PASS` viene registrato prima del comando reale.

### Matrice CA -> evidence

In corso.

### Matrice T-NN -> risultato

In corso.

### Rischi rimasti

In corso.

### Handoff a Review

- **Prossima fase**: REVIEW
- **Prossimo ruolo**: CODEX_REVIEWER
- **Handoff**: CODEX_EXECUTION_COMPLETE_TO_REVIEW

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

Non ancora eseguita.

## Fix — `CODEX_FIXER`

Non ancora necessario.

## Chiusura

- **Conferma utente**: ricevuta e condizionata a review/gate reali
- **Merge autorizzato da USER_APPROVER**: sì, dopo review `APPROVED` e CI exact-SHA verde
- **Follow-up candidate**: TASK-035, soltanto dopo closeout TASK-034
- **Riepilogo finale**: non ancora
- **Data completamento**: non ancora
