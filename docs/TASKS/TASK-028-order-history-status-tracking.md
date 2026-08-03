# TASK-028 — Storico, dettaglio e stato ordine

## Informazioni generali

- **Task ID**: TASK-028
- **Titolo**: Storico, dettaglio e stato ordine
- **File task**: `docs/TASKS/TASK-028-order-history-status-tracking.md`
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-03
- **Ultimo aggiornamento**: 2026-08-03
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-028/`
- **Handoff**: CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW

## Dipendenze

- **Dipende da**: TASK-027
- **Checkpoint consumati**: customer order atomico, item snapshot, status event, receipt
- **Sblocca**: TASK-031, TASK-034, TASK-036
- **Repository writer**: Admin/Supabase, poi Client; nessun writer POS

## Scope

- aggiungere lista ordini owner-scoped con paginazione deterministica, filtri bounded e
  refresh esplicito;
- estendere dettaglio ordine con fulfillment snapshot, item e timeline status ordinata
  per versione, senza esporre dati inventory/POS interni;
- integrare Client con lista, card, detail, timeline, error/retry e empty state
  accessibili/localizzati;
- mantenere una cache locale read-only bounded per consultare lista/dettaglio offline e
  riconciliare al reconnect senza generare mutazioni;
- supportare deep link ordine/notifica strict, solo per owner autenticato, con fail
  closed su ID invalido, cross-user o ordine non trovato;
- consentire cancellazione soltanto negli stati e nelle finestre autorizzate dal server,
  idempotente, con status event append-only e audit; nessuna regola client è autorità;
- produrre pgTAP/RLS, pagination, concurrency/replay, Flutter unit/widget/integration
  Android/iOS, staging E2E, build e smoke headless;
- mantenere production e tutti i feature flag invariati/OFF.

## Non incluso

- queue/transizioni operative Admin, di competenza TASK-029;
- handoff/ack POS o vendita fiscale, di competenza TASK-030;
- invio push, di competenza TASK-031;
- pagamento, support chat o dati fiscali completi;
- modifica arbitraria dell'ordine o della timeline dal Client;
- activation production o dipendenza da GUI/dispositivo fisico.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | List/detail/timeline sono owner-scoped, paginati e privacy-safe | CONTRACT/PGTAP |
| CA-02 | Timeline è append-only, ordinata per version e coerente con lo stato ordine | PGTAP |
| CA-03 | Cache read-only mostra l'ultimo snapshot verificato offline e riconcilia al reconnect | UNIT/INTEGRATION |
| CA-04 | Deep link ordine autentica e fallisce chiuso per ID invalido/cross-user/not-found | SECURITY/INTEGRATION |
| CA-05 | Cancellazione è server-authoritative, idempotente e ammessa solo dalla policy | CONCURRENCY/PGTAP |
| CA-06 | Client presenta lista, card, dettaglio, timeline, refresh, empty/error/retry accessibili | WIDGET/INTEGRATION |
| CA-07 | Quattro locale, CLP, dark, text scale 200%, compact/tablet e Semantics passano | A11Y/L10N |
| CA-08 | Gate Admin/Supabase/Client, staging e smoke headless passano sul revision set | CI/BUILD/SMOKE |
| CA-09 | Production resta invariata e nessun secret/config/artifact viene versionato | SECURITY/GIT |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-02 | PGTAP/RLS | owner list/detail/timeline; anon/cross-user/cross-shop denied |
| T-02 | CA-01 | CONTRACT | keyset stabile, limite bounded, nessun duplicato o internal field |
| T-03 | CA-03 | UNIT/INTEGRATION | online seed -> offline read -> restart -> reconnect refresh |
| T-04 | CA-04 | SECURITY | deep link valido, invalido, cross-user, logout/login identity switch |
| T-05 | CA-05 | CONCURRENCY | cancel allowed/replay/conflict/race con transizione server |
| T-06 | CA-06, CA-07 | WIDGET | lista/detail/timeline/empty/error, viewport/a11y/l10n matrix |
| T-07 | CA-06 | ANDROID_EMU/IOS_SIM | ordine -> history -> detail -> refresh/cancel con tap reali |
| T-08 | CA-08, CA-09 | STAGING/CI/GIT | exact SHA, fixture/cleanup, gate e production unchanged |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Lista e dettaglio consumano soltanto snapshot order customer | Evita coupling all'inventory e a `pos_sales` | ATTIVA |
| D-02 | Timeline deriva dagli event append-only e non da log client | Mantiene ordine e audit verificabili | ATTIVA |
| D-03 | Cache è bounded, owner/shop-scoped e read-only | Offline utile senza diventare autorità | ATTIVA |
| D-04 | Cancellazione è una RPC di transizione idempotente | Impedisce update tabellari e race client | ATTIVA |
| D-05 | Deep link conserva solo order ID pubblico/route e autentica prima della lettura | Riduce disclosure cross-user | ATTIVA |
| D-06 | Admin operativo, POS e push restano nei task successivi | Mantiene il confine del task | ATTIVA |
| D-07 | Planning ed Execution sono autorizzati dal prompt USER_APPROVER del 2026-08-02 | Mantiene il release train headless continuo | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Rendere gli ordini TASK-027 consultabili e recuperabili online/offline dal solo owner,
con timeline affidabile, cancellazione controllata e navigazione profonda sicura.

### Analisi

- l'RPC TASK-027 legge una receipt singola ma manca lista keyset, timeline e policy di
  cancellazione;
- status events esistono già e sono append-only: la projection customer deve mantenere
  version, ordine e allow-list senza introdurre una seconda fonte di stato;
- il cart vuoto dopo order rende essenziale una destinazione Orders indipendente dal
  draft checkout;
- la cache Storefront esistente fornisce pattern Drift/recovery, ma i dati order devono
  essere separati per owner e rimossi al logout/identity switch;
- deep link notifica deve sospendere il routing fino all'auth senza rivelare esistenza.

### Approccio autorizzato

1. audit read-only di order payload/event/RLS, router, shell Account e cache/logout;
2. definizione contract list/detail/timeline/cancel, keyset e allow-list;
3. migration additiva con RPC strict, transition lock e pgTAP ownership/pagination;
4. repository/cache/controller e UI Orders/Detail originali nel design system attuale;
5. deep link strict, auth/identity switch e offline/reconnect;
6. concurrency cancel/status, staging exact-SHA e cleanup;
7. integration Android/iOS, gate completi, evidence e checkpoint TASK-029.

### Rischi e mitigazioni

- leakage cross-user: owner derivato da `auth.uid()` e risposta indistinguibile not-found;
- timeline incoerente: lock order, status_version monotono ed event nello stesso commit;
- duplicati pagination: cursor `(placed_at,id)` e ordinamento stabile;
- cache PII stale: namespace owner/shop, clear logout e retention bounded;
- cancel race: idempotency ledger e transition policy server-side;
- scope creep Admin/POS: nessuna queue, ack o vendita fiscale in TASK-028.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: prompt headless Storefront v1 2026-08-02

## Execution — `CODEX_EXECUTOR`

### Audit e implementazione

- l'audit ha confermato `customer_orders`, item snapshot, status event, outbox e
  mutation ledger come authority privata; nessuna lettura diretta mobile, coupling a
  inventory operativo o scrittura `pos_sales` è stata introdotta;
- la migration additiva `20260803050000_storefront_v1_customer_order_history` aggiunge
  tre RPC strict owner/shop-scoped per list, detail e cancel, keyset `(placed_at,id)`,
  policy cancellazione fail-closed, lock deterministici e replay idempotente;
- la timeline espone soltanto status/version/timestamp pubblici e deriva dagli event
  append-only; detail e card usano gli snapshot immutabili TASK-027 e omettono tenant,
  owner, stock preciso, costo, token, metadata POS e identificatori operativi;
- cancel valida policy, stato, versione e deadline server-side; transizione, event,
  outbox POS-neutral, ledger e rilascio ATP/capacità avvengono nella stessa transazione;
- il Client introduce adapter RPC allow-list, cache bounded owner/shop-scoped e
  read-only, pending cancel persistita con stessa idempotency key, lista/dettaglio/
  timeline, refresh/error/empty/offline e deep link ordine sospeso fino all'auth;
- logout e identity switch eliminano la cache ordine; race bootstrap deep link,
  payload cache corrotto, errore cancel deterministico e reflow 320x568 al 200% hanno
  regressioni dedicate;
- Android API 35 e iPhone 17 Pro iOS 26.5 hanno eseguito il flow history/detail/
  refresh/cancel con tap reali e gli artifact debug sono stati installati e avviati.

### Revision set eseguito

- Admin/Supabase: `119169375fa477995b41c34b3766deca32fec056`, PR #67 draft;
- Client runtime: `1855100f34a3563787b1ac71eafb4af60a1b72e6`, PR #5 draft;
- migration: `20260803050000_storefront_v1_customer_order_history`;
- staging: run `30787890770`, artifact migration `8845914762`, digest
  `4d6abb98931d6d431e1fb7bdd9478e53402104ca30065165b4f9d3699c11b29f`, artifact
  TASK-028 `8845928446`, digest
  `ce89e37b17a078468db259158e9c00f7b950146bc20ee78aa75378ea20edf748`;
- production e feature flag: invariati/OFF; cancellazione staging resta OFF di default.

### Gate

- replay migration, pgTAP TASK-028 30/30, lint SQL e race due sessioni: `PASS`;
- Admin foundation 845 pass + 2 skip, security/lint/typecheck/build/Playwright: `PASS`;
- Admin CI `30787892745`, Cloudflare `30787892757` e staging exact-SHA
  `30787890770`: `PASS`;
- Client gate canonico exit 0: 526/526 test funzionali, performance 1/1, coverage
  11.123/14.388 (77,31%), analyze/format/security/governance/architecture e build
  Android/iOS: `PASS`;
- integration order history Android e iOS: 1/1 per piattaforma; install/launch e
  screenshot CLI degli artifact debug: `PASS`;
- CI Client `30787721420`: `BLOCKED` esterno, tre job con zero runner/step e
  annotazione billing/spending limit; non viene dichiarata eseguita.

## Checkpoint release train — `CODEX_EXECUTOR`

TASK-028 è tecnicamente validato e consegnato alla futura review integrata come
`VALIDATED_PENDING_INTEGRATED_REVIEW`. Staging ha mantenuto la cancellazione fail-closed
per ogni shop esistente e le fixture pgTAP/race sono state ripulite. Nessuna review
formale intermedia, modifica production, transizione Admin o consumo POS è stata
eseguita.

Il primo run staging fu cancellato con zero step dalla coda GitHub condivisa. Il
secondo rilevò correttamente che la migration predecessore era già applicata: il
workflow TASK-028 è stato corretto per provare il solo delta realmente pending e il
run finale è passato. Non sono stati usati retry ciechi, GUI o dati production.

### Matrice CA -> evidence

| Criterio | Evidence | Stato |
|---|---|---|
| CA-01 | RPC owner/shop, keyset e response allow-list pgTAP | PASS |
| CA-02 | event append-only, version monotona e timeline ordinata | PASS |
| CA-03 | cache bounded, identity purge, offline/restart/reconnect | PASS |
| CA-04 | parser/deep link strict, auth queue e cross-owner fail-closed | PASS |
| CA-05 | policy, stale version, replay/conflict e race due sessioni | PASS |
| CA-06 | widget e integration lista/detail/timeline/refresh/cancel | PASS |
| CA-07 | quattro locale, CLP, dark, 200%, compact/tablet e Semantics | PASS |
| CA-08 | gate locali, CI Admin, staging e smoke mobile headless | PASS |
| CA-09 | scan 542 file; production invariata e flag OFF | PASS |

### Matrice T-NN -> risultato

| Test | Risultato | Stato |
|---|---|---|
| T-01 | owner ammesso; anon/cross-user/cross-shop negati | PASS |
| T-02 | keyset deterministico, limite 50 e zero field interno | PASS |
| T-03 | online seed, offline read, restart e reconnect refresh | PASS |
| T-04 | deep link valido/invalido, auth, logout e identity switch | PASS |
| T-05 | cancel disabled/allowed, stale, replay, conflict e race | PASS |
| T-06 | matrix widget/a11y/l10n senza overflow | PASS |
| T-07 | Android/iOS flow con tap, build, install e launch | PASS |
| T-08 | staging exact-SHA, cleanup, CI e production unchanged | PASS |

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.

## Chiusura

- **Conferma utente**: ricevuta in forma condizionata dal release train
- **Merge autorizzato**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: TASK-029 dopo checkpoint verde
- **Riepilogo finale**: storico/timeline/cancellazione e Client offline/deep link
  validati; review integrata differita al freeze multi-repository
- **Data completamento**: non ancora
