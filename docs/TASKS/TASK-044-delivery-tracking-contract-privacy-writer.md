# TASK-044 — Delivery tracking contract, privacy boundary and operational writer

## Informazioni generali

- **Task ID**: TASK-044
- **Titolo**: Delivery tracking contract, privacy boundary and operational writer
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-16
- **Ultimo aggiornamento**: 2026-08-16
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-044/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

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

In corso sul piano approvato. Nessun gate è dichiarato prima dell'esecuzione reale.

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

Non avviata.

## Fix — `CODEX_FIXER`

Non avviato.

## Chiusura

- **Conferma utente**: pre-autorizzata, condizionata a review e CI reali verdi
- **Merge**: autorizzato soltanto normale e senza bypass
- **Data completamento**:
