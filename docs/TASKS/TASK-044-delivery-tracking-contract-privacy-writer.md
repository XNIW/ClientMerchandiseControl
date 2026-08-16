# TASK-044 — Delivery tracking contract, privacy boundary and operational writer

## Informazioni generali

- **Task ID**: TASK-044
- **Titolo**: Delivery tracking contract, privacy boundary and operational writer
- **Stato**: ACTIVE
- **Fase**: REVIEW
- **Responsabile**: CODEX_RE_REVIEWER
- **Data creazione**: 2026-08-16
- **Ultimo aggiornamento**: 2026-08-16
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-044/`
- **Handoff**: CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION

## Dipendenze

- **Dipende da**: TASK-043, TASK-020, TASK-026–TASK-031, TASK-033
- **Sblocca**: TASK-045
- **Writer**: Client Flutter e Admin Web/migration authority; repository POS/inventory
  e client di riferimento restano read-only.

## Scope

- contratto versionato `statusOnly`, `externalCarrier`, `liveCourier` e read model
  `DeliveryTrackingSnapshot` minimo, server-authoritative e privacy-safe;
- schema additivo per sessioni, assignment, latest location, lifecycle senza percorso
  preciso persistente, carrier esterno, idempotenza/rate limit e cleanup;
- RPC/view customer owner-scoped e write boundary courier dedicato, RLS/grant espliciti;
- Courier Mode mobile-first nell'Admin con autenticazione/permessi, consenso Start/Stop,
  foreground geolocation throttled e stato pausa visibile;
- Client consumer con parsing/validazione, cache ultimo snapshot, deduplica, freshness,
  Realtime owner/order scoped, dispose e polling bounded fallback;
- decision record provider mappa e adapter/fake necessari a TASK-045;
- privacy copy, retention, redaction e security review mirata del nuovo confine.

## Non incluso

- percorso o ETA calcolati dal Client, marker simulati, background tracking garantito;
- cronologia indefinita coordinate, telefono/email/subject ID courier al customer;
- service role nel browser/Client, GPS prima di Start, push con coordinate;
- modifica di inventory operativo, vendita fiscale, POS o stato ordine fiscale;
- activation production, chiavi provider production, app companion background o store release.

## Criteri di accettazione

| CA | Descrizione | Tipo |
|---|---|---|
| CA-01 | I tre tracking mode e snapshot pubblico validano campi, versioni, freshness e URL | UNIT/CONTRACT |
| CA-02 | Schema impone coordinate/timestamp/version/unique session e chiusura/riassegnazione sicure | DB |
| CA-03 | Customer legge solo il proprio ordine; anon/cross-customer/cross-shop sono negati | RLS/ABUSE |
| CA-04 | Courier scrive solo assignment attivo proprio, senza mutare ordine/cliente/destinazione | RLS/RPC |
| CA-05 | Replay, idempotenza, out-of-order, rate limit e input numerici invalidi falliscono chiuso | DB/SECURITY |
| CA-06 | Admin autorizzato assegna/start/stop; staff senza permesso e courier-only sono bounded | DB/E2E |
| CA-07 | Retention conserva latest location e lifecycle senza coordinate; completed/cancelled rimuove il dato preciso | DB/PRIVACY |
| CA-08 | Courier Mode produce foreground location reale solo dopo consenso/Start e applica throttling | UNIT/E2E |
| CA-09 | Client subscribe è order-scoped, deduplica, cache/stale/fallback e cleanup sono deterministici | UNIT/WIDGET |
| CA-10 | External URL è HTTPS allowlisted/validata e nessuna coordinate/PII entra in log, analytics o push | SECURITY |
| CA-11 | Provider decision/adapter resta fail-closed senza key e testabile senza rete | ADR/UNIT |
| CA-12 | Gate canonici Admin/Client, CI exact-SHA e main post-merge sono reali e verdi | COMMAND/CI |

## Test case

| Test | Criteri | Procedura |
|---|---|---|
| T-01 | CA-01 | parse valid/invalid per tutti i mode, timezone UTC e version monotona |
| T-02 | CA-02/07 | migration/reset, vincoli, trigger close/reassign e cleanup retention |
| T-03 | CA-03 | due customer, due shop: owner pass; anon/cross-owner/enumeration deny |
| T-04 | CA-04/06 | due courier, assignment proprio/altrui, permission admin/staff/courier-only |
| T-05 | CA-05 | replay key, duplicate, stale/future, NaN/infinite/range/accuracy/rate limit |
| T-06 | CA-08 | geolocation fake e browser foreground: start/throttle/pause/stop/refresh |
| T-07 | CA-09 | subscribe/reconnect/backoff/poll/cache/stale/logout/account/order/dispose |
| T-08 | CA-10 | URL injection e redaction log/analytics/push fixture |
| T-09 | CA-11 | fake map adapter, flag off, missing key e provider exception |
| T-10 | CA-12 | script canonici, build, PR CI e main CI exact-SHA |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | L'autorizzazione del 2026-08-16 copre l'intero ciclo e i merge normali dopo review/CI. | Mandato USER_APPROVER | ATTIVA |
| D-02 | Si conserva soltanto latest location; lifecycle non contiene coordinate precise. | Minimizzazione e retention | ATTIVA |
| D-03 | Realtime è un acceleratore owner/order-scoped; RPC snapshot + polling bounded è il fallback autorevole. | Resilienza e RLS verificabile | ATTIVA |
| D-04 | Courier Mode web dichiara soltanto foreground; nessuna promessa background. | Limiti browser/OS reali | ATTIVA |
| D-05 | TASK-151 WeChat Admin resta preservato; delivery usa branch/worktree separato e riconcilia conflitti senza riscriverne evidence. | Concorrenza sicura | ATTIVA |

## Planning — `CODEX_PLANNER`

### Analisi e approccio

1. inventariare schema/RPC/order permissions/Admin route e Client repository correnti;
2. fissare ADR contratto, privacy, provider e confine foreground;
3. implementare migration e test pgTAP prima delle superfici applicative;
4. implementare Admin Courier Mode sul boundary autenticato senza service role browser;
5. implementare modelli/repository/controller Client con fake deterministici;
6. eseguire security diff review mirata, gate, review/fix/re-review, PR/CI/merge/main.

### Rischi

- IDOR/Realtime leak: publication, grant, RLS e test con identità distinte;
- impersonation/replay: assignment attivo, subject server-side, idempotency e monotonicità;
- geolocation web sospesa: copy foreground, pausa rilevata, nessun claim background;
- provider map non configurato: adapter e flag fail-closed, nessuna key in Git;
- task Admin concorrente: branch isolato e nessuna riscrittura del task/evidence WeChat.

### Handoff a Execution

- **Handoff planning**: CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION
- **Autorizzazione**: già ricevuta nel prompt del 2026-08-16
- **Transizione applicata**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Execution — `CODEX_EXECUTOR`

### Implementazione consegnata

- Admin/Supabase: migration additiva con sessioni, assignment, latest location,
  lifecycle senza coordinate, idempotenza, cleanup, feed Realtime owner-scoped e RPC
  dedicate customer/admin/courier;
- Courier Mode: writer web mobile-first con consenso esplicito, start/stop e
  geolocalizzazione foreground throttled; nessuna promessa di background;
- Client: modello/versioning dei tre tracking mode, parser stretto, RPC owner-scoped,
  Realtime filtrato per ordine, polling bounded, cache cifrata e card testuale nel
  dettaglio ordine;
- privacy: terminal redaction, nessuna history di coordinate, nessuna coordinata in
  log/analytics/push e feed pubblico senza `shop_id` interno;
- provider: decision record Google Maps nativo, configurazione production fail-closed
  e nessuna chiave versionata.

### Evidence e gate pre-review

- revision set Client: `e9bd0306b07b105f3fb46da783ab2fd24ef44246..aa24851a380099d7878bbbfa590e2e856f9d3d6e`;
- revision set Admin: `5cf73e4f6de4cfcc36e56514ec77c0cc9cb970e3..c94e4711b06244704ff577eedd9fca69bccc837d`;
- `supabase db reset`: `PASS`; pgTAP tracking: `55/55 PASS`; foundation mirato:
  `7/7 PASS`; suite foundation: `978 PASS`, `2 SKIP`, `0 FAIL`;
- `npm run verify`: `PASS`, build incluso;
- `flutter analyze`: `PASS`; tracking/orders mirati: `20 PASS`;
- `bash scripts/check.sh`: `PASS`, scanner 587 file, 586 test più performance,
  APK debug e iOS Simulator debug verdi.

### Handoff a Review

`CODEX_EXECUTION_COMPLETE_TO_REVIEW` sui revision set sopra. L'ADR provider non
committato è stato escluso esplicitamente dalla review security del codice.

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

### Review indipendente read-only

La review mirata security/privacy ha letto integralmente i file assegnati e ha
validato staticamente e dinamicamente i confini Client, Courier Mode, server/RPC e
database. Esito: `CHANGES_REQUIRED`, con sei finding P2 e due finding P3; nessun P0/P1.

| Finding | Priorità | Evidenza | Correzione richiesta |
|---|---:|---|---|
| T044-REV-CLIENT-001 | P2 | race compare/cache/publish riprodotta: terminale v6 può essere sovrascritto da live v5 | serializzare l'accettazione monotona e aggiungere regressione concorrente |
| T044-REV-CLIENT-002 | P2 | RPC `unauthorized` cancella il disco ma conserva snapshot preciso in memoria e avvia runtime | stop fail-closed, azzeramento snapshot e nessuna subscribe |
| T044-REV-COURIER-001 | P2 | Start asincrono seguito da unmount può creare un watch GPS orfano | generation/mounted token e cleanup post-await con regressione |
| T044-REV-DB-001 | P2 | cleanup elimina latest row ma il feed Realtime conserva coordinate scadute | redigere atomicamente il feed degli ordini eliminati |
| T044-REV-DB-002 | P2 | un salto dichiarato grande aggira `min_interval` configurato | rendere l'intervallo un floor assoluto server-side |
| T044-REV-DB-003 | P2 | RPC DB accetta hostname IPv4 numerico, poi normalizzato a loopback dal Client | validazione canonica/fail-closed anche al boundary SQL |
| T044-REV-CLIENT-003 | P3 | IndexedStack conserva Realtime/polling quando il branch Orders è offstage | integrare visibilità branch nel lifecycle runtime |
| T044-REV-CLIENT-004 | P3 | dettaglio ordine terminale può mostrare snapshot live cached se RPC è offline | stato ordine autorevole prevalente e rimozione cache precisa |

Hardening di prodotto inclusi nel Fix: guard route-wide per courier-only, ruolo UI
`Courier` invece di `Shop manager`, niente polling sync non autorizzato e stop del GPS
quando il documento diventa hidden. I controlli IDOR, cross-shop, assignment/lease,
service-role server-only, RLS customer A/B e terminal redaction ordinaria non hanno
prodotto altri finding.

### Handoff a Fix

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Fix — `CODEX_FIXER`

### Primo ciclo

- serializzato compare/cache/publish del Client e reso `unauthorized` fail-closed con
  stop runtime, azzeramento in-memory e clear cache ordinato;
- stato ordine terminale reso autorevole sul tracking cached e runtime legato alla
  visibilità della branch Orders;
- lifecycle Courier Mode protetto con generation token, compensazione pause e stop
  foreground su unmount/hidden; shell courier-only bounded;
- cleanup DB ora redige feed e latest coordinate nella stessa transazione, intervallo
  minimo assoluto e hostname esterno DNS-style fail-closed;
- regression test aggiunti per i sei P2 e due P3. Re-review: sette finding chiusi;
  `CLIENT-T044-UI-01` restava aperto sui cambi branch programmatici.

### Secondo ciclo

- `StatefulNavigationShell.currentIndex` sincronizza il lifecycle tracking anche per
  deep link e `router.go`, con regressione Orders -> Catalog -> Orders e nessun doppio
  runtime sullo stesso indice;
- freshness corrente rivalutata a ogni polling prima del dedup del payload, così una
  posizione non resta `fresh` oltre soglia senza un nuovo snapshot;
- presenter mappa protetto da generation post-render contro `dispose` concorrente;
  aggiunte regressioni esplicite `statusOnly`, `externalCarrier`, terminale e race.

### Gate candidate Fix

- Client commit: `61cd16bee70a925c1110645c708551de58ac3427`;
- `flutter analyze`: `PASS`, exit 0;
- tracking + shell + Orders + deep-link mirati: `48 PASS`, exit 0;
- Admin commit: `663a292a626adc25230bad7c1917f930f94f5dca`;
- `supabase db reset`: `PASS`; pgTAP tracking: `60/60 PASS`; foundation mirato:
  `9/9 PASS`; typecheck/lint: `PASS`.

### Handoff a re-review

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`. I reviewer read-only hanno già chiuso i finding
Client runtime, Courier Mode e DB; la re-review finale dei due gap Client del secondo
ciclo resta vincolante prima dei gate canonici, PR e CI.

### Re-review finale read-only

- `T044-REV-CLIENT-001/002`: `CLOSED`, commit Client `d466a08`;
- `T044-REV-COURIER-001`: `CLOSED`, commit Admin `663a292`;
- `T044-REV-DB-001/002/003`: `CLOSED`, reset e pgTAP 60/60 sul commit Admin;
- `T044-REV-CLIENT-004`: `CLOSED`, stato ordine terminale e cache precisa;
- `T044-REV-CLIENT-003`: `CLOSED` sul commit `1801347`, con test separati del
  boundary router (`true -> false -> true`, nessun duplicato) e del controller
  (`watch -> cancel -> watch`);
- finding aggiuntivi CA-11: freshness temporale e `present/dispose` concorrente
  `CLOSED` sul commit `61cd16b` con 17/17 test mirati;
- nessun finding P0/P1/P2/P3 resta aperto.

Gate canonici candidate PR: Client `scripts/check.sh` completa format, analyze,
598 test con coverage, performance 1/1, APK debug e iOS Simulator debug; Admin
`npm run verify` e suite foundation completano 980 pass, 2 skip, 0 fail. Esito:
`APPROVED / CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION`; il prompt
USER_APPROVER autorizza già push, PR, CI exact-SHA e merge normale senza bypass.

## Chiusura

- **Conferma utente**: pre-autorizzata, condizionata a review e CI reali verdi
- **Merge**: autorizzato soltanto normale e senza bypass
- **Data completamento**:
