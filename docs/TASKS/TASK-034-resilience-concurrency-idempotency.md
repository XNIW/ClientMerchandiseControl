# TASK-034 — Offline, reconnect, concorrenza e idempotenza

## Informazioni generali

- **Task ID**: TASK-034
- **Titolo**: Offline, reconnect, concorrenza e idempotenza
- **File task**: `docs/TASKS/TASK-034-resilience-concurrency-idempotency.md`
- **Stato**: ACTIVE
- **Fase**: REVIEW
- **Responsabile**: CODEX_RE_REVIEWER
- **Data creazione**: 2026-08-16
- **Ultimo aggiornamento**: 2026-08-16
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-034/`
- **Handoff**: CODEX_FIX_COMPLETE_TO_RE_REVIEW

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

- scheduler/clock condivisi, controller Auth, Catalogo e Delivery Tracking;
- regressioni Auth repository, Cart, Catalogo e tracking e repeat runner bounded;
- matrice resilienza, gate Client, contratti DB Admin/POS e staging delivery tracking;
- governance, manifest, worklog ed evidence TASK-034.

### Piano minimo

Completato secondo il Planning approvato: inventario, gap riproducibili, fix minimi,
test deterministici/repeat, database locale, staging guarded e gate canonici.

### Modifiche fatte

- introdotti `AppClock`/`AppScheduler` iniettati e un scheduler manuale per eliminare
  wall-clock dai deadline OAuth, debounce catalogo e polling/freshness tracking;
- OAuth in-flight ora scade deterministicamente dopo cinque minuti, cancella il task
  schedulato e ignora callback tardive senza lasciare la UI bloccata;
- corretto il boundary freshness tracking da `>` a `>=`, così lo snapshot diventa
  stale esattamente alla deadline; polling/reconnect e dispose sono controllabili;
- aggiunte regressioni su refresh Auth concorrente, query/category stale, doppio tap
  Cart autenticato e race tracking; repeat runner eseguibile integrato in `check.sh`;
- completata la matrice canonica con authority, idempotency, version, retry,
  reconciliation ed evidence per ogni cella richiesta;
- Admin: corretti i default manuali del workflow migration staging, aggiunto smoke
  exact-SHA/allowlisted con pgTAP transazionale, sanitizzazione e cleanup verificato.

### Check eseguiti

- `flutter analyze`: `PASS`, exit `0`;
- suite mirata Client: `314/314 PASS`, exit `0`;
- repeat critiche Execution: `10 x 6 = 60 PASS`, exit `0`;
- `bash scripts/check.sh`: `PASS`, inclusi security/config scan, governance, format,
  analyze, suite completa `627/627` con coverage, repeat, benchmark 25k, APK debug e iOS
  Simulator debug;
- Admin `supabase db reset`: `PASS`; 10 file pgTAP commerce/tracking,
  `483/483 PASS`; 11 harness concorrenza Admin/POS: `PASS`;
- Admin `npm run verify`: `PASS`; Foundation `982 PASS`, `2 SKIP` giustificati;
- staging migration dry-run `31967227338` e apply `31967270575`: `PASS`, sola
  `20260816072836` applicata; production non toccata;
- staging smoke `31969351269` sullo SHA Admin `6fea61bb`: `60/60 PASS`, evidence
  sanitizzata, migration ledger presente e fixture cleanup `true`;
- advisor post-DDL: zero `ERROR`; warning/info schema-wide osservati e distinti dai
  gate RLS/RPC tracking passati.

### Matrice CA -> evidence

| CA | Evidence | Esito |
|---|---|---|
| CA-01 | `docs/quality/TASK-034-RESILIENCE-MATRIX.md` | PASS |
| CA-02–CA-07 | `CLIENT-314`, regressioni scheduler; Fix 3 tracking `23/23`, `REPEAT-140` | PASS |
| CA-04–CA-08 | `DB-483`, `DB-RACE-11` | PASS |
| CA-09 | scheduler manuale + repeat Fix 3 `10 x 14` | PASS |
| CA-10 | gate completi, Admin PR #90/#91/#92, staging run `31969351269` | PASS |

### Matrice T-NN -> risultato

| Test | Risultato |
|---|---|
| T-01 | PASS — tutte le celle classificate, nessun critical `UNTESTED` |
| T-02–T-07 | PASS — suite Client 314; Fix 3 tracking 23 e repeat 140 |
| T-08 | PASS — DB 483 e 11 harness concorrenti |
| T-09 | PASS — nessuna nuova race usa sleep/wall-clock |
| T-10 | PASS — gate locali, staging guarded e cleanup reali; CI Client resta alla fase Review/PR |

### Rischi rimasti

- lo smoke staging prova realmente DB/RPC/RLS con identità sintetiche, ma non viene
  presentato come smoke UI su device fisico; la physical validation resta classificata
  separatamente nei task di acceptance/release;
- gli advisor Supabase segnalano warning schema-wide preesistenti e RPC
  `SECURITY DEFINER` intenzionalmente callable da `authenticated`, auto-autorizzanti
  DB-side; zero error e nessun bypass rilevato dai 60 test tracking;
- annotation GitHub Actions Node 20 -> 24 sono warning infrastrutturali non bloccanti.

### Handoff a Review

- **Prossima fase**: REVIEW
- **Prossimo ruolo**: CODEX_REVIEWER
- **Handoff**: CODEX_EXECUTION_COMPLETE_TO_REVIEW

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

### Review iniziale indipendente

- **Revision set**: `e5a1384e7526e288f7657c32bff42f1ab957633e..d59883f460632e42aca9eee1ea1714708344b599`;
- **Esito**: `CHANGES_REQUIRED`, 0 P0, 0 P1, 1 P2, 0 P3;
- **Finding `TASK034-R-001` (P2)**: la cella critical tracking logout/account
  switch/lifecycle era attestata senza cambiare realmente identità mentre
  polling/reconnect/freshness erano attivi e senza asserire il teardown dei task dello
  scheduler;
- **Verifiche reviewer**: 79 test mirati, repeat `10 x 6 = 60`, analyze, governance,
  architecture e diff check `PASS`; staging run `31969351269` verificato sullo SHA
  Admin esatto `6fea61bb`;
- **Handoff**: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Re-review 1 indipendente

- **Revision set**: Fix `0dccca810e309c849c290a857bd1975bb4fd797b`, evidence
  `68f1f6a59ed2089504b9447740a8ca60cb3cf04b`;
- **Esito**: `CHANGES_REQUIRED`, 0 P0, 0 P1, 1 P2, 0 P3;
- **Finding `TASK034-R-001` (P2 residuo)**: identity, `close(clearCache: true)` e
  unauthorized catturavano il cache store soltanto dopo l'attesa dell'unsubscribe;
  un dispose durante `removeChannel()` poteva quindi causare un `ref.read` post-dispose
  e interrompere il purge owner-scoped;
- **Gate reviewer**: tracking `19/19`, repeat `90/90`, analyze, governance 9/9,
  architecture negative 7/7 e diff check `PASS`;
- **Handoff**: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Re-review 2 indipendente

- **Revision set**: Fix 2 `c514f388607fe93cc25e17a0622e705b6be1dd58`, evidence
  `8c8ccb9f2031f6fcb3667d08e3b05cabb216c059`;
- **Esito**: `CHANGES_REQUIRED`, 0 P0, 0 P1, 1 P2, 1 P3;
- **Finding P2 residuo**: mentre l'unsubscribe restava pendente, stato e coordinate
  dell'account A rimanevano pubblici e il purge non iniziava; i test verificavano solo
  dopo avere rilasciato il `Completer`;
- **P3**: la matrice T-02–T-07 conservava il conteggio Fix precedente;
- **Gate reviewer**: tracking `22/22`, repeat `120/120`, analyze, governance 9/9,
  architecture negative 7/7 e diff check `PASS`;
- **Handoff**: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Fix — `CODEX_FIXER`

- sostituita la dipendenza ricostruttiva dall'identità con listener lifecycle espliciti:
  A→logout e A→B ora incrementano generation, arrestano runtime, serializzano il purge
  della cache owner-scoped e pubblicano soltanto lo stato della nuova identità;
- il cache store viene catturato prima dell'attesa della coda snapshot, evitando letture
  Riverpod dopo un eventuale dispose;
- aggiunte tre regressioni con `StateProvider` mutabile e `ManualAppScheduler`: logout
  durante fallback, cambio account durante fallback e dispose con subscription/timer
  attivi; avanzamento di dieci minuti ed evento dal vecchio stream non producono load,
  save o stato cross-account; `activeTaskCount == 0`;
- `flutter analyze`, test tracking `19/19` e repeat Fix `10 x 9 = 90` sono `PASS`, exit
  `0`; `scripts/check.sh` sul commit Fix `0dccca8` è `PASS`: 630 test
  non-performance con coverage, repeat predefinito `45/45`, benchmark 25k, APK debug
  e iOS Simulator debug;
- **Handoff**: `CODEX_FIX_COMPLETE_TO_RE_REVIEW`; il Fix non si auto-approva.

### Fix 2

- il `DeliveryTrackingCacheStore` viene ora catturato prima di ogni boundary asincrono
  nei tre percorsi identity, close con purge e unauthorized, e passato esplicitamente
  alla coda di cleanup; dopo l'unsubscribe nessun accesso Riverpod è necessario;
- il fake espone una cancellazione subscription controllata da due `Completer`;
  tre regressioni dispongono il container mentre l'unsubscribe è bloccato e poi
  verificano purge deterministico per identity/logout, close e unauthorized;
- `flutter analyze`, tracking `22/22` e repeat `10 x 12 = 120` sono `PASS`, exit `0`;
  `scripts/check.sh` sullo SHA Fix 2 `c514f38` è `PASS`: 633 test non-performance
  con coverage, repeat predefinito `60/60`, benchmark 25k, APK debug e iOS Simulator
  debug;
- **Handoff**: `CODEX_FIX_COMPLETE_TO_RE_REVIEW`; è richiesta una nuova re-review
  indipendente.

### Fix 3

- le transizioni identity pubblicano sincronicamente `signedOut`/`idle` senza snapshot;
  close pubblica subito `idle` e unauthorized subito il failure senza snapshot;
- stop runtime e purge serializzato vengono avviati in parallelo, così il purge non è
  subordinato a un `removeChannel()` potenzialmente pendente;
- le regressioni A→null, A→B, close e unauthorized verificano stato fail-closed e
  cache owner purgata prima di rilasciare il `Completer` dell'unsubscribe; il test
  A→B asincrono è aggiunto direttamente;
- il primo gate Fix 3 ha riprodotto una mutazione provider durante widget dispose;
  `close` differisce quindi a un microtask (non timer), mantenendo l'ordine fail-closed
  prima dello stop; la regressione router è inclusa nel repeat;
- `flutter analyze`, tracking `23/23` e repeat `10 x 14 = 140` sono `PASS`; conteggio
  T-02–T-07 corretto; gate canonico e SHA Fix 3 seguono nelle evidence;
- **Handoff**: `CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

## Chiusura

- **Conferma utente**: ricevuta e condizionata a review/gate reali
- **Merge autorizzato da USER_APPROVER**: sì, dopo review `APPROVED` e CI exact-SHA verde
- **Follow-up candidate**: TASK-035, soltanto dopo closeout TASK-034
- **Riepilogo finale**: non ancora
- **Data completamento**: non ancora
