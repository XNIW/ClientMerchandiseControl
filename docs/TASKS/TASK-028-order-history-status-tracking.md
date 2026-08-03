# TASK-028 — Storico, dettaglio e stato ordine

## Informazioni generali

- **Task ID**: TASK-028
- **Titolo**: Storico, dettaglio e stato ordine
- **File task**: `docs/TASKS/TASK-028-order-history-status-tracking.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-03
- **Ultimo aggiornamento**: 2026-08-03
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-028/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

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

Audit read-only da avviare sul contract order/event/RLS e sui pattern Client per
router, cache owner-scoped, logout e UI Account/Orders. Nessuna migration viene scelta
prima di avere fissato allow-list, cursor, policy cancellazione e lifecycle cache.

## Checkpoint release train — `CODEX_EXECUTOR`

Da compilare dopo i gate tecnici; nessuna review formale intermedia.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.

## Chiusura

- **Conferma utente**: ricevuta in forma condizionata dal release train
- **Merge autorizzato**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: TASK-029 dopo checkpoint verde
- **Riepilogo finale**: in esecuzione
- **Data completamento**: non ancora
