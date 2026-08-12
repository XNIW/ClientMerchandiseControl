# TASK-025 — Reservation hold atomico e scadenza

## Informazioni generali

- **Task ID**: TASK-025
- **Titolo**: Reservation hold atomico e scadenza
- **File task**: `docs/TASKS/TASK-025-reservation-hold-atomic-expiry.md`
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-02
- **Ultimo aggiornamento**: 2026-08-02
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-025/`
- **Handoff**: CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW

## Dipendenze

- **Dipende da**: TASK-023, TASK-024
- **Checkpoint consumati**: cart/version/revalidation; availability/freshness pubblica
- **Sblocca**: TASK-026, TASK-027, TASK-033, TASK-034
- **Repository writer**: Admin/Supabase, poi Client; nessun writer POS in questa fase

## Scope

- modellare hold owner-scoped e shop/publication-scoped con quantità, stato,
  `expires_at`, idempotency key e riferimenti pubblici bounded;
- usare lato server l'inventory operativo autorevole e lock transazionali senza esporre
  quantità precise al client o trasformare la proiezione TASK-024 in fonte stock;
- creare hold in modo atomico, consumare disponibilità prenotabile, rifiutare quantità
  non disponibile e impedire oversell quando due clienti competono per l'ultimo pezzo;
- rendere create/read/release/retry idempotenti, con owner derivato da `auth.uid()`,
  shop verificato server-side e chiavi duplicate/conflicting esplicite;
- gestire expiry e cleanup concorrente senza doppio rilascio, resurrezione o quantità
  negativa; stato stale/expired non resta utilizzabile;
- supportare release esplicito, cart change, logout/account switch, app kill, timeout
  ambiguo e reconnect senza falso successo client;
- integrare nel Client soltanto repository/controller/stato e feedback necessari a
  prenotazione/expiry, mantenendo il checkout completo in TASK-026;
- produrre migration replay, pgTAP RLS, concurrency multi-session, staging smoke,
  unit/widget/integration Android/iOS e gate completi;
- mantenere production e feature flag invariati/OFF.

## Non incluso

- indirizzo, zone, slot, fee o flusso checkout, di competenza TASK-026;
- creazione/consumo dell'ordine finale, di competenza TASK-027;
- handoff POS, vendita fiscale o compensazione POS, di competenza TASK-030;
- pagamento, notifica o rollout production;
- quantità stock precisa in response, UI, log, metriche pubbliche o Admin Storefront;
- modifica distruttiva dell'inventory operativo o dipendenza da GUI/dispositivo fisico.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Hold usa chiavi shop/publication/customer, quantità bounded, stato ed expiry server-side | CONTRACT/PGTAP |
| CA-02 | Owner deriva da auth e FORCE RLS nega anon/cross-user/cross-shop | SECURITY/PGTAP |
| CA-03 | Create è transazionale e due clienti sull'ultimo pezzo producono un solo hold attivo | CONCURRENCY |
| CA-04 | Idempotency retry restituisce lo stesso risultato e una key conflicting è rifiutata | PGTAP/CONCURRENCY |
| CA-05 | Expiry/release restituiscono capacità una sola volta e non resuscitano hold terminali | PGTAP/CONCURRENCY |
| CA-06 | Availability e quantità autorevoli sono rilette server-side; nessun dato inventory preciso è pubblico | SECURITY/CONTRACT |
| CA-07 | Cart change/logout/account switch/app kill/timeout/reconnect non perdono intent né mostrano successi falsi | UNIT/INTEGRATION |
| CA-08 | Client espone stato active/expiring/expired/released/error accessibile e localizzato | WIDGET/A11Y |
| CA-09 | Cleanup è bounded, osservabile e sicuro sotto worker concorrenti | PGTAP/LOAD |
| CA-10 | Gate Admin/Supabase/Client, staging e smoke headless passano sul revision set | CI/BUILD/SMOKE |
| CA-11 | Production resta invariata e nessun secret/config/artifact è versionato | SECURITY/GIT |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-02 | PGTAP | create/read/release owner; anon/cross-user/cross-shop denial |
| T-02 | CA-03 | CONCURRENCY | due clienti concorrenti sull'ultimo pezzo; uno success, uno unavailable |
| T-03 | CA-04 | PGTAP/CONCURRENCY | retry stessa key, payload uguale/differente e timeout ambiguo |
| T-04 | CA-05, CA-09 | PGTAP | expiry/release/cleanup concorrenti e nessun doppio ritorno capacità |
| T-05 | CA-06 | CONTRACT/SECURITY | input totale/stock malevolo ignorato; response negative internal fields |
| T-06 | CA-07 | UNIT/INTEGRATION | cart mutation, app kill, logout/switch, offline/reconnect e retry |
| T-07 | CA-08 | WIDGET/A11Y | stati hold, countdown onesto, locale/theme/200%/viewport/Semantics |
| T-08 | CA-09 | LOAD | molti hold active/expired, batch cleanup bounded e lag misurato |
| T-09 | CA-10 | ANDROID_EMU/IOS_SIM | create/retry/expiry/release in processi Simulator headless |
| T-10 | CA-10, CA-11 | CI/GIT | replay, staging exact SHA, gate, secret scan e production unchanged |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | L'inventory operativo server-side è autorevole; availability pubblica è solo informativa | Impedisce oversell basato su uno stato astratto o stale | ATTIVA |
| D-02 | Un hold attivo consuma capacità nella stessa transazione che lo crea | Evita finestre race fra verifica e prenotazione | ATTIVA |
| D-03 | Owner, shop e tempo server non sono accettati come autorità dal client | Chiude spoofing cross-user/cross-shop e clock manipulation | ATTIVA |
| D-04 | Idempotency key è legata all'hash del payload; stesso payload replaya, payload diverso confligge | Evita doppio hold e key reuse ambiguo | ATTIVA |
| D-05 | Release, expiry e consume sono transizioni terminali monotone | Evita doppio rilascio e resurrezione | ATTIVA |
| D-06 | Checkout/order/POS restano TASK-026/027/030 | Mantiene il task limitato alla prenotazione atomica | ATTIVA |
| D-07 | Planning ed Execution sono autorizzati dal prompt USER_APPROVER del 2026-08-02 | Mantiene il release train headless continuo | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Creare un hold breve, atomico e idempotente che impedisca oversell e sia utilizzabile
dal checkout successivo senza esporre l'inventory operativo al client.

### Analisi

- TASK-023 fornisce cart versionato e revalidation, ma non riserva capacità;
- TASK-024 espone stati commerciali privacy-safe e lock writer sul prodotto operativo,
  ma intenzionalmente non pubblica quantità e non può essere la fonte dell'hold;
- il contratto deve individuare l'autorità stock privata reale, la granularità del lock
  e la policy di release prima di scegliere lo schema minimo;
- timeout e retry richiedono un ledger idempotente; expiry e cleanup richiedono
  transizioni monotone e batch bounded;
- il Client deve mostrare soltanto l'esito commerciale e il tempo residuo server-derived,
  non quantità o dettagli inventory.

### Approccio autorizzato

1. audit read-only di inventory schema/writer, cart RPC, availability lock, cron/worker,
   RLS e convenzioni idempotency esistenti;
2. definizione del modello di capacità privato e delle invarianti lock/expiry/release;
3. migration additiva minima con hold, ledger, indici, FORCE RLS e RPC strict;
4. pgTAP owner/cross-shop, last-piece race, replay/conflict ed expiry concorrente;
5. apply guarded e staging smoke con fixture sintetiche e cleanup a zero;
6. repository/controller/UI Client strettamente necessari, con retry/offline/session;
7. integration Android/iOS, load cleanup, gate completi, evidence/checkpoint;
8. attivazione TASK-026 soltanto dopo checkpoint tecnico verde.

### Rischi e mitigazioni

- oversell: lock dell'autorità stock e decremento/ledger nella stessa transazione;
- doppio rilascio: stato terminale monotono e compare-and-set sotto lock;
- starvation/deadlock: ordine lock unico, transazioni brevi e concurrency test;
- hold exhaustion: limiti owner/shop, TTL bounded, rate limit candidate per TASK-033;
- clock skew: `clock_timestamp()` server e `expires_at` non controllato dal client;
- leakage: response allow-list e test negative su quantità/costo/location/source ID;
- cleanup in ritardo: read fail-closed sugli expired e worker batch idempotente;
- scope creep checkout/order: nessuna fee, indirizzo, order snapshot o vendita fiscale.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: prompt headless Storefront v1 2026-08-02

## Execution — `CODEX_EXECUTOR`

Execution completata sul revision set Client runtime
`fe85ce910313843c00c83760b67563f7ea6ef2e7` e Admin/Supabase
`448a778cc57ed1a441b87a71bb93be4315374d08`.

- l'audit ha confermato `inventory_products.stock_quantity` come autorità privata
  on-hand e ha mantenuto la proiezione TASK-024 esclusivamente informativa;
- le migration additive `20260803000951_storefront_v1_reservation_holds` e
  `20260803003855_storefront_v1_reservation_hold_eligibility` introducono hold e
  ledger idempotency privati, FORCE RLS, grant minimi, TTL server-side di 15 minuti,
  limite di 25 hold attivi per customer/shop e cleanup cron bounded;
- create/read/release sono RPC strict, owner-scoped e shop/publication-scoped: owner,
  clock e disponibilità derivano lato server, mentre le response espongono soltanto
  riferimenti pubblici e stato commerciale;
- la creazione serializza il prodotto operativo, sottrae gli hold attivi da ATP e
  impedisce oversell senza decrementare lo stock on-hand; due sessioni reali sull'ultimo
  pezzo producono un solo hold attivo;
- expiry, release e consumo sono transizioni monotone; replay identico restituisce lo
  stesso esito, key riutilizzata con payload diverso confligge e il cleanup usa batch
  massimi di 400 righe;
- il Client aggiunge repository, storage locale versionato, coordinator, controller e
  panel Product Detail/Cart; pending create/release sopravvivono a timeout, offline,
  restart e cambio account, e il countdown è derivato dal tempo server;
- la UI espone active/expiring/expired/released/consumed/error in quattro lingue, con
  Semantics, target minimi, dark mode e text scale 200%, senza creare una falsa CTA di
  prenotazione nel carrello.

Comandi, conteggi, benchmark, digest, tentativi falliti corretti e matrici CA/Test sono
registrati in `docs/TASKS/EVIDENCE/TASK-025/README.md`. Production non è stata
invocata e tutti i flag restano OFF.

## Checkpoint release train — `CODEX_EXECUTOR`

### Gate pertinenti eseguiti

- Admin/Supabase: replay, 54/54 pgTAP dedicati, 196 assertion isolate, concurrency
  multi-session, 1.200 hold load/cleanup, foundation 826 test, security/typecheck/lint,
  CI `30776746985`, Cloudflare `30776746979` e staging `30776745250`: `PASS`;
- Client: pub get/l10n/format/analyze, 461 test, coverage 8.063/10.202 (79,03%),
  benchmark 25.000 righe, security scan, Android debug/release e iOS simulator/
  release no-codesign: `PASS`;
- integration reservation create/read/release/retry/expiry su Android API 35 e iPhone
  17 Pro iOS 26.5: 2/2 per piattaforma; artifact smoke e scan: `PASS`;
- CI Client exact-SHA `30776491402`: `BLOCKED` esterna perché i tre job non hanno
  avviato runner o step per billing/spending limit; non è dichiarata `PASS`.

### Staging e performance cleanup

La migration staging più recente è `20260803003855`. Il load rollback-only ha creato
1.200 hold sintetici, di cui 1.000 expired e 200 futuri attivi; tre cleanup bounded
hanno processato 1.000/1.000 righe con p50/p95/p99
498,463/502,698/503,075 ms, nessun residuo expired e stock on-hand invariato.

### Handoff al task successivo

- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Review outcome**: NOT_RUN
- **Prossimo task**: TASK-026
- **Handoff**: STOREFRONT_V1_MILESTONE_CHECKPOINT_VALIDATED

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.

## Chiusura

- **Conferma utente**: ricevuta in forma condizionata dal release train
- **Merge autorizzato**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: TASK-026 attivato dal checkpoint tecnico
- **Riepilogo finale**: validato tecnicamente, in attesa della review integrata
- **Data completamento**: non ancora
