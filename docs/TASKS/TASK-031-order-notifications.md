# TASK-031 — Notifiche push e order status events

## Informazioni generali

- **Task ID**: TASK-031
- **Titolo**: Notifiche push e order status events
- **File task**: `docs/TASKS/TASK-031-order-notifications.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-03
- **Ultimo aggiornamento**: 2026-08-03
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-031/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

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

Audit read-only iniziale su schema device/consent, order status/outbox, configurazione
mobile e provider disponibili. Nessuna credenziale o dipendenza viene aggiunta prima
di avere verificato il confine già esistente.

## Checkpoint release train — `CODEX_EXECUTOR`

Da compilare dopo i gate tecnici; nessuna review formale intermedia.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.

## Chiusura

- **Conferma utente**: ricevuta in forma condizionata dal release train
- **Merge autorizzato**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: TASK-032 dopo checkpoint verde
- **Riepilogo finale**: in esecuzione
- **Data completamento**: non ancora
