# TASK-022 — Registrazione device, consenso notifiche e token lifecycle

## Informazioni generali

- **Task ID**: TASK-022
- **Titolo**: Registrazione device, consenso notifiche e token lifecycle
- **File task**: `docs/TASKS/TASK-022-customer-devices-push-consent.md`
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-02
- **Ultimo aggiornamento**: 2026-08-02
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-022/`
- **Handoff**: CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW

## Dipendenze

- **Dipende da**: TASK-020, TASK-021
- **Checkpoint consumati**: Auth Google/PKCE/session lifecycle; profilo owner-scoped
- **Sblocca**: TASK-031, TASK-035, TASK-036
- **Repository writer**: Admin/Supabase per schema/RPC, poi Client Flutter; un solo
  writer alla volta

## Scope

- creare `customer_devices` owner-scoped con ID riga opaco, installation ID casuale e
  non invasivo, piattaforma, locale, consent, token, last seen, revoke e lifecycle;
- non derivare l'installation ID da IMEI, seriale, advertising ID, IDFA, MAC, email o
  altri identificatori hardware/account;
- trattare il push token come routing secret revocabile, mai come identità o prova di
  autenticazione;
- registrare/aggiornare/revocare tramite contratti server idempotenti che derivano
  l'owner da `auth.uid()`, deduplicano token/installazione e non restituiscono il token;
- applicare FORCE RLS owner-only, grant minimi e accesso service-side separato per la
  futura pipeline TASK-031;
- persistere localmente soltanto installation ID, stato consenso e materiale minimo di
  revoca, con storage bounded e cleanup al logout;
- introdurre `PushTokenProvider`/repository/controller testabili senza collegare la UI
  direttamente a plugin o MethodChannel;
- gestire consenso esplicito, deny/revoke, token refresh/rotation, reinstall, account
  switch, duplicati, timeout, offline e retry;
- aggiornare Account con stato notifiche onesto, accessibile e localizzato in es-CL,
  it, en e zh-Hans;
- produrre migration replay, pgTAP/RLS, unit/widget/integration, smoke Android/iOS e
  staging headless; non inviare notifiche reali in questo task.

## Non incluso

- pipeline eventi ordine e invio push, di competenza TASK-031;
- payload lock-screen, template notifica e deep link ordine, di competenza TASK-031;
- analytics/advertising identifier, fingerprint hardware o tracking cross-app;
- credenziali APNs/FCM, certificati, service account o secret nel client/repository;
- inventare configurazioni Firebase/Apple mancanti o dichiarare token live su Simulator
  quando la piattaforma/provider non li fornisce;
- modifica production, invio push reale o richiesta di interazione GUI.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Installation ID è random, app-scoped, persistente e non deriva da hardware/PII | UNIT/SECURITY |
| CA-02 | Token non è identità, non entra nei log e non viene restituito dalle read/RPC cliente | PGTAP/SECURITY |
| CA-03 | RLS nega anon/cross-user e consente soltanto lifecycle owner autorizzato | PGTAP |
| CA-04 | Register/update/refresh sono idempotenti e deduplicano installation/token | PGTAP/CONCURRENCY |
| CA-05 | Consent è esplicito, revocabile e separato dalla permission OS | UNIT/WIDGET |
| CA-06 | Token rotation, revoke e logout cleanup invalidano il routing precedente | INTEGRATION |
| CA-07 | Platform, locale e last seen sono validati/bounded e aggiornati server-side | UNIT/PGTAP |
| CA-08 | Account switch non associa un device/token al nuovo owner implicitamente | UNIT/INTEGRATION |
| CA-09 | Offline/timeout/retry preservano intent senza mostrare consenso server non confermato | UNIT/WIDGET |
| CA-10 | UI è localizzata, accessibile, dark/200% e non blocca browsing o logout | WIDGET/A11Y |
| CA-11 | Gate Client/Admin/Supabase, staging e smoke headless passano sul revision set | CI/BUILD/SMOKE |
| CA-12 | Production resta invariata e nessun secret/config/artifact è versionato | SECURITY/GIT |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-02 | UNIT/STATIC | install ID UUID casuale; scan vieta hardware ID, token log/response |
| T-02 | CA-03 | PGTAP | owner success; anon/cross-user read/write/revoke denial |
| T-03 | CA-04 | PGTAP/CONCURRENCY | register duplicato e token rotation concorrente convergono a una riga attiva |
| T-04 | CA-05 | UNIT/WIDGET | grant, deny, revoke e permission OS separata dal consent server |
| T-05 | CA-06 | INTEGRATION | refresh sostituisce token; logout revoke/cleanup; retry idempotente |
| T-06 | CA-07 | UNIT/PGTAP | platform/locale/last-seen invalidi o client-forged sono rifiutati |
| T-07 | CA-08 | UNIT/INTEGRATION | logout/login altro owner non riusa associazione precedente |
| T-08 | CA-09 | UNIT/WIDGET | offline, timeout, resume e retry non creano successo autorevole falso |
| T-09 | CA-10 | WIDGET/A11Y | quattro locale, fallback es, dark, 200%, compact/landscape, Semantics/48 |
| T-10 | CA-11, CA-12 | CI/SMOKE/GIT | gate completi, staging, Android/iOS, secret scan e production unchanged |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Installation ID è un UUID v4 generato dall'app e non un device fingerprint | Minimizza tracking e resta stabile quanto basta per il lifecycle locale | ATTIVA |
| D-02 | Il token è un routing secret revocabile e non compare in select/RPC response/log | Un token non autentica l'utente e la sua esposizione abilita abuso notifiche | ATTIVA |
| D-03 | Permission OS e consent server sono stati distinti | La permission tecnica non costituisce consenso applicativo implicito | ATTIVA |
| D-04 | La UI dipende da un provider astratto; il provider live può restare non configurato senza inventare credenziali | Consente test riproducibili e integrazione successiva TASK-031 | ATTIVA |
| D-05 | Logout privilegia revoca autenticata e cleanup locale; failure di rete resta retryable e sanitizzata | Logout non deve richiedere GUI né perdere il diritto di revoca | ATTIVA |
| D-06 | Planning ed Execution sono autorizzati dal prompt USER_APPROVER del 2026-08-02 | Mantiene il release train headless continuo | ATTIVA |
| D-07 | La CI Client `30766494620` resta `BLOCKED` per billing GitHub prima dell'avvio dei runner; i gate locali sullo SHA esatto non vengono trasformati in CI `PASS` | Mantiene evidence onesta e applica il principio non bloccante del release train | ATTIVA |
| D-08 | Il provider live resta esplicitamente `notConfigured` finché APNs/FCM non fornisce credenziali/configurazione verificata | TASK-022 definisce lifecycle e boundary senza inventare token o invii reali di TASK-031 | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Fornire un registro device privacy-safe e un lifecycle consenso/token idempotente,
riusabile dalla pipeline notifiche TASK-031 senza confondere token, device e identità.

### Analisi

- TASK-020 espone sessione owner e logout ma non possiede hook device-specific;
- TASK-021 offre la superficie Account e pattern repository/controller owner-scoped;
- APNs/FCM richiedono configurazioni esterne che non possono essere inventate o
  versionate; schema e adapter devono restare verificabili anche senza invio reale;
- il cleanup logout deve avvenire prima della perdita della sessione quando online e
  degradare in modo esplicito/idempotente quando offline;
- TASK-031 consumerà soltanto device attivi e consentiti dal server.

### Approccio autorizzato

1. audit read-only di Auth logout/storage, config mobile, capability push e pattern RLS;
2. migration additiva con table/constraint/index/RLS e RPC register/revoke/status;
3. pgTAP owner/cross-user/dedup/rotation/revoke/concurrency e replay locale;
4. apply guarded e smoke staging sintetico con cleanup;
5. installation storage, token provider abstraction, repository/controller e hook logout;
6. UI consenso/stato notifiche e localizzazioni;
7. test unit/widget/integration e smoke Android/iOS headless;
8. gate completi, evidence/checkpoint e attivazione TASK-023 soltanto se tecnicamente
   verde; eventuale provider credential live resta `BLOCKED` esterno, mai `PASS`.

### Rischi e mitigazioni

- token leakage: response allow-list, error sanitization, log scan e nessun dump raw;
- account crossover: owner derivato server-side e revoke prima del cambio sessione;
- doppio token: unique hash/installation e upsert transazionale;
- deny scambiato per grant: state machine separata e UI esplicita;
- logout offline: cleanup locale immediato, intento revoke idempotente e server TTL;
- scope creep TASK-031: nessun event consumer o push reale anticipato.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: prompt headless Storefront v1 2026-08-02

## Execution — `CODEX_EXECUTOR`

### Modifiche completate

- migration additiva Admin/Supabase `20260802194500` con `customer_devices`, UUID
  opachi, installation UUID app-scoped, token hash/dedup, lifecycle consenso/revoca,
  expiry, FORCE RLS owner-only, grant minimi e RPC register/revoke/status;
- contratti server idempotenti che derivano l'owner da `auth.uid()`, validano
  platform/locale/permission e non restituiscono né loggano il push token;
- storage Flutter bounded e testabile: persiste installation ID, decisione owner e
  operazione retry minima, mai il token; UUID v4 generato con `Random.secure`;
- `PushTokenProvider`, repository strict, controller single-flight e coordinatore
  logout con revoke autenticata, cleanup locale e retry idempotente offline;
- UI Account Material 3 per consenso/stato notifiche, permission OS separata,
  localizzazione es-CL/it/en/zh-Hans, dark, text scale 200%, compact/landscape,
  Semantics e target di almeno 48 logical pixel;
- integration flow headless Android/iOS per grant, token registration/rotation,
  revoke e processo ancora vivo; provider live non configurato espone lo stato reale.

### Gate eseguiti

- Admin/Supabase SHA `c8f4048f5f442726bec1693e808e19fe6dd40fc4`, PR #67
  draft: migration replay `PASS`; pgTAP TASK-022 58/58 e suite completa 27 file/
  1.640 test `PASS`; race/dedup token concorrente, foundation, verify e security
  `PASS`;
- staging run `30764930029`, job `91541826190`, sullo SHA esatto: dry-run, postverify
  device contract e cleanup `PASS`; artifact `8838637043`, SHA-256
  `ec7764abe27e019d95ecbcb7df3378445565bd2c951fd54a47fdf35395771d6f`;
- Admin CI `30764931962` e Cloudflare build `30764931964`: `PASS`; deploy staging
  correttamente `SKIPPED` perché il delta TASK-022 è database-only;
- Client SHA `b113f44a1c7b150e9b07e770aa8a7c158a2b8111`, PR #5 draft:
  `scripts/check.sh` exit 0 in 119 s; security 465 file, governance 8/8,
  architecture 7/7, analyze/format, 403 test, coverage 6.329/7.851 (80,61%),
  benchmark 1/1 e build Android/iOS Simulator `PASS`;
- integration device lifecycle su Android Emulator API 35: 1/1 `PASS`, exit 0 in
  23 s; iPhone 17 Pro Simulator iOS 26.5: 1/1 `PASS`, exit 0 in 33 s;
- smoke degli artifact normali ricostruiti: install/launch Android exit 0, cold launch
  2.327 ms, screenshot e accessibility tree coerenti, PID vivo e zero crash; install/
  launch/screenshot iOS exit 0 e Home offline coerente;
- CI Client `30766494620`: `BLOCKED`, tre job con zero runner/step e annotazione
  billing/spending limit; nessun failure di codice o retry cieco dichiarato;
- production non è stata invocata, i flag restano OFF e nessun secret/config/artifact
  è versionato.

### Matrici

CA-01..CA-10 e CA-12: `PASS`. CA-11: gate tecnici, staging e smoke `PASS`; solo il
sottogate GitHub-hosted Client CI è `BLOCKED` esterno. T-01..T-09: `PASS`; T-10:
security/Git/production unchanged `PASS`, Client CI `BLOCKED`. Le evidence
riproducibili sono in `docs/TASKS/EVIDENCE/TASK-022/README.md`.

### Handoff

`CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`. Nessuna review formale è stata
eseguita e TASK-022 non è `DONE`.

## Checkpoint release train — `CODEX_EXECUTOR`

TASK-022 è `VALIDATED_PENDING_INTEGRATED_REVIEW` sul revision set Client/Admin
registrato. Il blocker CI Client è esclusivamente esterno e resta esplicitamente
`BLOCKED`; production è invariata. Il task successivo autorizzato è TASK-023.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.

## Chiusura

- **Conferma utente**: ricevuta in forma condizionata dal release train
- **Merge autorizzato**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: TASK-023 attivato dal checkpoint tecnico
- **Riepilogo finale**: validato tecnicamente, in attesa della review integrata
- **Data completamento**: non ancora
