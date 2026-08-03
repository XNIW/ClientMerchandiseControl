# TASK-031 — Notifiche push e order status events

## Informazioni generali

- **Task ID**: TASK-031
- **Titolo**: Notifiche push e order status events
- **File task**: `docs/TASKS/TASK-031-order-notifications.md`
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-03
- **Ultimo aggiornamento**: 2026-08-03
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-031/`
- **Handoff**: CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW

## Dipendenze

- **Dipende da**: TASK-022, TASK-027, TASK-028, TASK-029
- **Checkpoint consumati**: device/consent/token lifecycle, order/status event/outbox,
  history/timeline/deep link e workflow Admin
- **Sblocca**: TASK-035, TASK-036, Milestone 4 E2E
- **Repository writer**: Admin/Supabase per event/outbox/dispatcher, poi Client per
  receive/deep link/preferences; nessun writer Win7POS salvo regressione di contract

## Scope

- definire gli eventi notificabili `confirmed`, `rejected`, `preparing`, `ready`,
  `out_for_delivery`, `completed`, `cancelled` e `reservation_expiring`;
- produrre un outbox notifiche append-only e idempotente nello stesso confine
  autorevole degli status event, senza duplicare timeline o stato ordine;
- implementare dispatcher bounded con lease, retry/backoff, deduplica, poison state,
  correlation/request ID e recovery da timeout ambiguo;
- selezionare solo device/token attivi dello stesso owner con consenso valido,
  rispettando revoke, rotation, logout cleanup, locale e platform;
- introdurre un provider interface e un adapter server-side; usare un provider reale
  soltanto se credenziali staging non interattive già configurate, senza inventarle;
- minimizzare il payload lock-screen: stato pubblico, codice ordine abbreviato e deep
  link opaco; nessun indirizzo, email, note, item, totale, token o internal ID;
- gestire nel Client foreground/background/cold start, deduplica, tap/deep link,
  refresh timeline, token expired e consenso/revoca con fallback sicuro;
- localizzare es-CL, it, en e zh-Hans e verificare accessibilità, duplicate delivery,
  delayed/out-of-order, offline/reconnect e staging headless;
- mantenere production e `push_enabled` OFF.

## Non incluso

- notifiche marketing, segmentazione comportamentale o campagne promozionali;
- SMS, email o provider acquistato/non configurato;
- PII o contenuto ordine dettagliato nella lock screen;
- pagamento/rimborso, di competenza TASK-032;
- attivazione production, nuovi contratti legali o autenticazione interattiva provider;
- claim di consegna fisica a un device senza receipt/provider evidence reale.

## File coinvolti

- Admin/Supabase: migration additiva, outbox/attempt ledger/RPC dispatcher, RLS,
  pgTAP, harness provider e workflow staging;
- Client: notification domain/repository/controller, platform adapter, deep link,
  preferences Account, l10n e test Android/iOS headless;
- task, evidence, release manifest, checkpoint e worklog.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Ogni status autorizzato produce al massimo un evento notificabile/versione | PGTAP/CONCURRENCY |
| CA-02 | Solo device owner attivo, consentito e non revocato è destinatario | RLS/SECURITY |
| CA-03 | Dispatcher lease/retry/replay è idempotente e recupera timeout ambiguo | INTEGRATION/CONCURRENCY |
| CA-04 | Payload lock-screen è versionato, localizzato, bounded e privacy-safe | CONTRACT/SECURITY |
| CA-05 | Token rotation/expiry/revoke/logout non produce invii successivi | PGTAP/INTEGRATION |
| CA-06 | Tap foreground/background/cold apre l'ordine owner-scoped e aggiorna timeline | MOBILE/INTEGRATION |
| CA-07 | Duplicate, delayed, out-of-order e offline non causano crash o stato regressivo | UNIT/INTEGRATION |
| CA-08 | UI preferenze e messaggi sono accessibili e localizzati nelle quattro lingue | WIDGET/A11Y/L10N |
| CA-09 | Gate Admin/Client/staging passano; provider esterno è attestato solo se reale | CI/STAGING |
| CA-10 | Production e push flag restano OFF; zero secret/token/artifact viene versionato | SECURITY/GIT |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01 | PGTAP | status event duplicato/replay crea una sola notifica per versione |
| T-02 | CA-02, CA-05 | PGTAP | owner ammesso; cross-user/revoked/no-consent/expired negati |
| T-03 | CA-03 | CONCURRENCY | due dispatcher, una lease; retry e ack perso non duplicano delivery |
| T-04 | CA-04 | CONTRACT | allow-list payload e snapshot localizzati senza PII/token |
| T-05 | CA-05 | INTEGRATION | rotation/revoke/logout invalida la destinazione in modo monotono |
| T-06 | CA-06, CA-07 | MOBILE | foreground/background/cold, duplicate/out-of-order/offline e deep link |
| T-07 | CA-08 | WIDGET/A11Y | preferenze, Semantics, target, text scale e quattro locale |
| T-08 | CA-09, CA-10 | STAGING/CI/GIT | exact SHA, provider/harness, cleanup, secret scan, production unchanged |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Status event ordine resta authority; notifica è una delivery derivata | Evita divergenza fra push e timeline | ATTIVA |
| D-02 | Dedupe key include order, event version, channel e destination generation | Retry/rotation non devono duplicare o inviare al token vecchio | ATTIVA |
| D-03 | Token e provider credential restano solo server-side e mai nei log | Riduce esposizione di segreti e identificatori | ATTIVA |
| D-04 | Payload lock-screen usa una allow-list minima e deep link pubblico/opaco | Protegge PII su device bloccato | ATTIVA |
| D-05 | Assenza di credential provider reale è `BLOCKED` esterno per il solo delivery gate | Non si finge un push reale e non si ferma il lavoro indipendente | ATTIVA |
| D-06 | Planning ed Execution sono autorizzati dal prompt USER_APPROVER del 2026-08-02 | Mantiene il release train headless continuo | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Consegnare aggiornamenti ordine affidabili, minimizzati e owner-scoped, collegando gli
status event server-authoritative al Client senza trasformare il token push in identità
o dichiarare consegne non realmente osservate.

### Analisi

- TASK-022 fornisce installation/device/consent/token lifecycle, ma non un dispatcher;
- TASK-027/029 producono status event e outbox atomici da usare come fonte, senza
  aggiungere scritture parallele dal Client o dal POS;
- retry provider, token rotation e timeout ambiguo richiedono ledger e generation
  fencing, non un semplice boolean `sent`;
- il Client deve trattare il push come hint: dopo il tap rilegge la timeline
  owner-scoped e non applica uno stato autorevole dal payload;
- le credenziali provider e la firma mobile vanno prima rilevate in sola lettura;
  l'assenza resta un blocker esterno limitato al delivery reale.

### Approccio autorizzato

1. audit read-only di customer devices, order event/outbox, config Android/iOS,
   deep-link router e qualsiasi provider già installato/configurato;
2. fissare event/payload allow-list, recipient eligibility, dedup key, lease/retry,
   token generation e privacy/log policy;
3. migration additiva con outbox/attempt ledger privati, RLS/grant e pgTAP;
4. provider interface, adapter reale se già configurato e fake server harness forte
   per errori/timeout/duplicate senza usare secret nel repository;
5. Client receive/tap/deep-link/refresh e preference UI nelle quattro lingue;
6. unit/widget/integration Android/iOS e staging exact-SHA con cleanup;
7. evidence/checkpoint e attivazione TASK-032 soltanto con verde tecnico, mantenendo
   distinto l'eventuale blocker provider esterno.

### Rischi e mitigazioni

- duplicate push: dedup ledger e ack idempotente;
- token stale/reassigned: destination generation e owner/consent recheck al claim;
- PII lock-screen: schema allow-list e test negativi;
- out-of-order: event version monotona e refresh server-side dopo tap;
- provider outage: lease/retry bounded, poison state e metriche senza token;
- deep-link hijack: route owner-scoped e ordine riletto dopo auth.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: prompt headless Storefront v1 2026-08-02

## Execution — `CODEX_EXECUTOR`

### Audit e implementazione

- l'audit ha riusato `customer_devices`, consent/revoke/rotation di TASK-022 e gli
  status event autorevoli di TASK-027/TASK-029; non esistevano credential APNs/FCM o
  variabili provider nei secret/ambienti GitHub e nessun provider è stato inventato;
- la migration additiva `20260803104431_storefront_v1_order_notifications` introduce
  event, delivery per destination generation e receipt ledger privati `FORCE RLS`,
  senza policy client; trigger e reservation-expiry producer materializzano una sola
  notifica per event/version/destination eleggibile;
- claim e ack sono service-only, bounded e idempotenti: lease, retry/backoff,
  dead-letter, replay ack, generation fence e revoca token sono verificati; il flag
  `customer_order_push_enabled` è fail-closed e resta `false`;
- il dispatcher espone una provider interface server-side e un recording provider di
  test forte. Il payload lock-screen è versionato/localizzato e contiene soltanto
  status pubblico, codice abbreviato e route opaca; token, owner/order ID, email,
  indirizzo, item, totale e receipt provider raw non sono persistiti o loggati;
- il Client aggiunge repository/controller owner-scoped, parser strict della risposta
  `customer_notification_route_v1`, coalescing duplicate, LRU bounded, generation
  fence, recovery offline e refresh reale del dettaglio ordine dopo il tap;
- Android mappa l'extra allow-listed `deepLink` in `Intent.data` sia in `onCreate` sia
  in `onNewIntent`; iOS configura `UNUserNotificationCenter`, foreground presentation,
  tap response e cold-start `SceneDelegate` verso `app_links`, usando un mapper nativo
  canonico senza ID interni;
- gli smoke headless Android/iOS hanno aperto la route opaca staging fino al gate Auth
  guest; il contenuto ordine non è stato fidato dal push. Production è invariata e il
  delivery APNs/FCM reale resta `BLOCKED` esterno per assenza di credenziali.

### Revision set eseguito

- Admin/Supabase finale: `e9bcbc8c98a7dc1d0fdcfdbd549d7968a2fdbb19`, PR #67;
- Client runtime finale: `ed2f8a5c95f70ce057860027408d9f61314d6f4e`, PR #5;
- Win7POS invariato: `6c2eb9c8a0b6666f5dd59a2a132e616f5a8d5474`, PR #88;
- migration staging: `20260803104431_storefront_v1_order_notifications`, applicata
  dalla run `30809256239` sullo SHA SQL `353ade50`; dry-run/post-verify finale
  `30811747216` sullo SHA `e9bcbc8c`;
- CI Admin `30811750153`, Cloudflare `30811750080` e staging notification E2E
  `30811747216`: `PASS` sullo SHA finale;
- CI Client `30811578997`: `BLOCKED` esterna per billing/spending limit, tre job senza
  runner né step; i gate locali sullo SHA runtime finale sono `PASS`.

### Gate

- pgTAP dedicato: 40/40 `PASS`; race locale due dispatcher, lease/reclaim, ack replay,
  rotation/revoke e flag OFF: `PASS`; dispatcher foundation 7/7 `PASS`;
- CI Admin finale: foundation 872 test, 859 pass + 13 skip e zero failure; database,
  lint, typecheck, security, build, Playwright smoke e Cloudflare build `PASS`;
- E2E staging: recording provider 2 messaggi, 1 delivery terminale, payload localizzato,
  route opaca owner-scoped, revoked/rotated/flag-OFF non claimati, cleanup zero e
  `productionWriteRequested=false`; provider credential usata `false`;
- Client canonico `scripts/check.sh`: exit 0, 538 test, coverage
  11.280/14.565 (77,45%), benchmark 1/1, analyze/format/security/governance/
  architecture e build Android/iOS `PASS`;
- test notification/deep-link mirati: 19/19 in 4,37 s; Android JVM mapper 1/1 in
  0,013 s; XCTest Runner 4/4 in 9,624 s su iPhone 17 Pro iOS 26.5, incluso mapper
  notifiche e regressioni Activity Sheet;
- build staging exact-SHA: Android debug 7,4 s e iOS Simulator debug 11,9 s `PASS`;
  smoke Android cold/warm e `simctl openurl` iOS sono `PASS` senza Computer Use;
- scan finale: 559 file tracciati, zero secret/config locale/artifact versionato;
  production e tutti i flag push restano invariati/OFF.

## Checkpoint release train — `CODEX_EXECUTOR`

TASK-031 è tecnicamente validato e consegnato alla futura review integrata come
`VALIDATED_PENDING_INTEGRATED_REVIEW`. Event sourcing, recipient eligibility,
dispatcher idempotente, payload privacy-safe e route mobile headless hanno evidence
locale, CI e staging. Nessuna review formale intermedia è stata eseguita.

Il primo run staging `30809256239` ha applicato correttamente la migration e superato
pgTAP/E2E, ma la sola verifica dell'artifact JSON è fallita perché `npm run` aveva
inserito il banner npm prima del JSON. Il workflow è stato corretto per invocare Node
direttamente e una regressione statica impedisce la ricomparsa; la run finale
`30811747216` è interamente verde. La CI Client non è un failure tecnico: GitHub non ha
avviato alcuno step per billing, quindi resta dichiarata `BLOCKED` esterna.

### Matrice CA -> evidence

| Criterio | Evidence | Stato |
|---|---|---|
| CA-01 | trigger/status version, unique ledger e pgTAP duplicate/replay | PASS |
| CA-02 | eligibility owner/consent/revoke/expiry e tabelle FORCE RLS | PASS |
| CA-03 | race due dispatcher, lease/reclaim, retry e ack replay | PASS |
| CA-04 | payload v1 nelle quattro lingue, allow-list e test negativi PII | PASS |
| CA-05 | generation fence, rotation, invalid token, revoke/logout boundary | PASS |
| CA-06 | router cold/warm, Android intent reale, iOS mapper/openurl e detail refresh | PASS |
| CA-07 | duplicate/out-of-order/latest-wins/offline e timeout senza crash | PASS |
| CA-08 | preferenze TASK-022 riusate; payload/l10n es-CL/it/en/zh-Hans e Semantics | PASS |
| CA-09 | Admin CI/staging e gate Client locali verdi; provider live non disponibile | PASS |
| CA-10 | flag OFF, production invariata e scan 559 file senza secret/artifact | PASS |

### Matrice T-NN -> risultato

| Test | Risultato | Stato |
|---|---|---|
| T-01 | una notifica per status/version; older event soppresso | PASS |
| T-02 | soli device owner consentiti; cross-user/revoked/expired negati | PASS |
| T-03 | un lease winner, retry/reclaim e ack replay idempotente | PASS |
| T-04 | quattro locale, payload bounded e nessun dato interno | PASS |
| T-05 | rotation/revoke/logout invalidano monotonamente la destination | PASS |
| T-06 | cold/warm/background contract e route opaca con refresh ordine | PASS |
| T-07 | preferenze esistenti accessibili; fallback es e quattro locale | PASS |
| T-08 | exact SHA, cleanup, secret scan e production unchanged | PASS |

Gate provider APNs/FCM reale: `BLOCKED` esterno, perché nessuna credenziale non
interattiva è disponibile. Il recording provider non viene presentato come consegna
fisica a un device.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.

## Chiusura

- **Conferma utente**: ricevuta in forma condizionata dal release train
- **Merge autorizzato**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: TASK-032 attivato dopo checkpoint verde
- **Riepilogo finale**: notifiche ordine tecnicamente validate; review integrata
  differita al freeze multi-repository
- **Data completamento**: non ancora
