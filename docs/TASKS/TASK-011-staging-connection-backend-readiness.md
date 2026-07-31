# TASK-011 — Connessione Flutter allo staging e backend health state

## Informazioni generali

- **Task ID**: TASK-011
- **Titolo**: Connessione Flutter allo staging e backend health state
- **File task**:
  `docs/TASKS/TASK-011-staging-connection-backend-readiness.md`
- **Stato**: ACTIVE
- **Fase**: REVIEW
- **Responsabile**: CODEX_RE_REVIEWER
- **Data creazione**: 2026-07-30
- **Ultimo aggiornamento**: 2026-07-30
- **Ultimo agente**: CODEX_FIXER
- **Review outcome**: CHANGES_REQUIRED
- **Reviewer**: CODEX_REVIEWER — tre sessioni read-only indipendenti
- **Approver**: USER_APPROVER
- **Indicatore**: CODEX_FIX_COMPLETE_TO_RE_REVIEW
- **DONE**: NO
- **Merge**: NO — milestone batch con TASK-012 e TASK-020
- **User approval**: GRANTED_CONDITIONALLY_BY_END_TO_END_PROMPT
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-011/`
- **Handoff**: CODEX_FIX_COMPLETE_TO_RE_REVIEW

## Dipendenze

- **Dipende da**: TASK-004 `DONE`; PR batch TASK-003/TASK-004 #3 merged con
  commit `40d118eebf78eeabea9e26747adb00053dd875bc`
- **Sblocca**: TASK-012 e, insieme a TASK-004/TASK-012, TASK-020

## Scope

- identificazione read-only del solo progetto Supabase non-production canonico e
  verifica della configurazione staging locale ignorata;
- inizializzazione Supabase staging con la publishable key già governata da
  `CMC-CLIENT-CONFIG 1.0.0`;
- sostituzione della readiness nominale con
  `BackendReadinessState`: `unconfigured`, `initializing`, `ready`, `offline`,
  `misconfigured`, `authenticationRequired` e `recoverableError`;
- probe ufficiale e data-free `GET /auth/v1/health` con header `apikey`, URL derivato
  soltanto dalla origin validata, redirect disabilitati e payload mai loggato;
- timeout con abort reale, cancellazione lifecycle, retry manuale, single-flight e
  protezione dai completamenti obsoleti;
- separazione concreta fra trasporto health, mapping repository e stato/controller
  Riverpod;
- avvio della shell prima del completamento della readiness, così che errori
  recuperabili non impediscano UI e retry;
- messaggi cliente localizzati e sanitizzati, dettagli tecnici assenti dalla UI;
- permesso Android `INTERNET` nel manifest principale; nessuna eccezione ATS iOS;
- test unitari/widget, build staging e smoke reale data-free su Android Emulator e
  iOS Simulator;
- gate, evidence, review indipendente, eventuale Fix, re-review e closeout individuale.

## Contesto

La baseline di TASK-004 valida correttamente ambiente, URL, publishable key, callback e
kill switch, ma considera `ready` la sola presenza della configurazione o il ritorno di
`Supabase.initialize`. Questo è un falso positivo: l'inizializzazione costruisce il
client, non prova che Auth sia raggiungibile.

L'audit read-only ha confermato un solo progetto non-production canonico, sano e nella
regione attesa. Il file staging locale è presente, valido, ignorato e non tracciato. Un
probe host sanitizzato verso l'endpoint Auth ufficiale ha restituito HTTP 200 e lo
schema GoTrue atteso, senza interrogare tabelle o leggere dati commerciali.

Il manifest Android principale non dichiara oggi `INTERNET`; gli overlay debug/profile
lo fanno, ma una build release staging non avrebbe rete. iOS usa HTTPS e non richiede
permission o eccezioni ATS. Il bootstrap attuale attende l'inizializzazione prima di
`runApp`, quindi un errore impedirebbe anche una UI customer-safe e il retry.

## Non incluso

- query, insert, update, delete, subscribe o RPC su qualsiasi tabella o dato;
- inventory, prezzi, immagini, fornitori, cronologia, movimenti, POS o Storefront
  data-backed;
- schema, migration, RLS, grant, Storage, Edge Function o branch Supabase;
- modifica remota di provider Google, Site URL, redirect allow-list o credenziali;
- Google OAuth, PKCE, deep link, callback handling, session lifecycle o secure storage;
- profilo cliente, `shop_id`, catalogo reale, prodotti, prezzi, stock o fixture;
- production networking, configurazione production o fallback staging/production;
- auto-retry, polling, timer periodici, observability o crash reporting;
- redesign della shell oltre al feedback minimo di readiness e retry;
- modifica di task futuri, dipendenze, scope, priorità o repository esterni.

## File coinvolti

- `pubspec.yaml`, `pubspec.lock`;
- `lib/bootstrap.dart`;
- `lib/core/backend/backend_readiness_state.dart`;
- `lib/core/backend/backend_health_service.dart`;
- `lib/core/backend/backend_readiness_repository.dart`;
- `lib/core/backend/backend_readiness_controller.dart`;
- `lib/core/backend/supabase_bootstrap.dart`;
- rimozione o migrazione di `lib/core/backend/backend_status.dart`;
- `lib/features/shell/presentation/app_shell_screen.dart`;
- `lib/app/design_system/widgets/storefront_status_banner.dart`;
- `lib/l10n/app_*.arb` e output `gen_l10n`;
- `android/app/src/main/AndroidManifest.xml`;
- test in `test/core/backend/` e `test/features/shell/`;
- `integration_test/backend_readiness_smoke_test.dart`;
- `docs/ARCHITECTURE/MOBILE-ARCHITECTURE.md`;
- `docs/ARCHITECTURE/ENVIRONMENT-STRATEGY.md`;
- `docs/QUALITY-GATES.md`, `README.md`, `docs/MASTER-PLAN.md`,
  `docs/AI_WORKLOG.md`;
- questo task e `docs/TASKS/EVIDENCE/TASK-011/`.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | PR #3 è merged, main locale/origin sono allineati e TASK-011 è l'unico task `ACTIVE` | GIT/STATIC |
| CA-02 | Il progetto Supabase usato è l'unico non-production canonico esistente; nessun nuovo progetto è creato | MANUAL/SECURITY |
| CA-03 | Il file staging locale ha i cinque input validi, resta ignorato/non tracciato e non viene stampato | GIT/SECURITY |
| CA-04 | Supabase e repository esterni restano zero-write durante TASK-011 | MANUAL/SECURITY |
| CA-05 | Esiste `BackendReadinessState` con tutti e soli gli stati richiesti | STATIC/UNIT |
| CA-06 | `ready` deriva da inizializzazione staging e health ufficiale riuscito, mai dalla sola config | UNIT/INTEGRATION |
| CA-07 | Development resta `unconfigured`, non inizializza SDK e non esegue rete | UNIT |
| CA-08 | Production resta fail-closed, `misconfigured` e senza rete o fallback staging | UNIT/SECURITY |
| CA-09 | Il probe usa soltanto `GET /auth/v1/health` e l'header publishable `apikey` | UNIT/SECURITY |
| CA-10 | Il probe non segue redirect e non può inoltrare la key a origin diverse | UNIT/SECURITY |
| CA-11 | Il probe non interroga tabelle, RPC, Storage, inventory o dati commerciali | STATIC/SECURITY |
| CA-12 | HTTP 200 con payload health atteso produce `ready` | UNIT |
| CA-13 | timeout ed errori di trasporto producono `offline` con abort reale della request | UNIT |
| CA-14 | 401/403/404 del health pubblico producono `misconfigured`, non login cliente | UNIT/SECURITY |
| CA-15 | 408/429/5xx o risposta incoerente producono `recoverableError` | UNIT |
| CA-16 | `authenticationRequired` esiste ma non viene inventato dal probe data-free | STATIC/UNIT |
| CA-17 | Il controller esegue un solo check iniziale staging e nessun polling/auto-retry | UNIT/STATIC |
| CA-18 | Retry concorrenti condividono una singola operazione e il retry è solo manuale | UNIT/WIDGET |
| CA-19 | Dispose/cancellazione abortiscono la request e ignorano completamenti obsoleti | UNIT |
| CA-20 | La shell viene renderizzata mentre lo staging è `initializing` o non raggiungibile | WIDGET/INTEGRATION |
| CA-21 | UI e Semantics mostrano soltanto messaggi localizzati customer-safe e un retry accessibile | WIDGET |
| CA-22 | URL, key, body, eccezioni, token e dettagli tecnici non entrano in UI, log o evidence | UNIT/SECURITY |
| CA-23 | Il manifest Android principale dichiara `INTERNET` senza cleartext o wildcard | STATIC/BUILD_ANDROID |
| CA-24 | iOS mantiene HTTPS/ATS fail-closed senza `NSAllowsArbitraryLoads` | STATIC/BUILD_IOS |
| CA-25 | Test unitari e widget coprono stati, mapping, timeout, abort, retry e sanitizzazione | UNIT/WIDGET |
| CA-26 | Un probe host reale staging data-free termina `PASS` con output sanitizzato | INTEGRATION |
| CA-27 | Smoke reale Android staging raggiunge `ready`, mantiene la shell e non logga valori | ANDROID_EMU |
| CA-28 | Smoke reale iOS staging raggiunge `ready`, mantiene la shell e non logga valori | IOS_SIM |
| CA-29 | Format, analyze, suite completa e build staging Android/iOS sono `PASS` | FORMAT/ANALYZE/UNIT/BUILD_ANDROID/BUILD_IOS |
| CA-30 | Diff, dipendenze, artifact e scan security sono confinati allo scope | GIT/SECURITY |
| CA-31 | Review indipendente termina con 0 finding P0, P1 o P2 aperti | MANUAL/STATIC |
| CA-32 | CI sullo SHA finale completa job, step e annotation con esito `PASS` | CI |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01 | GIT/STATIC | Verificare merge PR #3, branch, task unico e governance |
| T-02 | CA-02, CA-03, CA-04 | MANUAL/GIT/SECURITY | Audit sanitizzato di progetto, config locale e zero-write |
| T-03 | CA-05, CA-16 | STATIC/UNIT | Verificare enumerazione completa e semantica degli stati |
| T-04 | CA-06, CA-07, CA-08 | UNIT | Provare staging, development e production senza fallback |
| T-05 | CA-09, CA-10, CA-11 | UNIT/SECURITY | Ispezionare metodo, URI, header, redirect e assenza query |
| T-06 | CA-12 | UNIT | Restituire health 200 valido e attendere `ready` |
| T-07 | CA-12, CA-15 | UNIT | Restituire 200 con payload invalido e attendere errore recuperabile |
| T-08 | CA-13 | UNIT | Simulare timeout e verificare abort più stato `offline` |
| T-09 | CA-13 | UNIT | Simulare errore trasporto e verificare `offline` |
| T-10 | CA-14 | UNIT/SECURITY | Provare 401, 403 e 404 senza produrre auth cliente |
| T-11 | CA-15 | UNIT | Provare 408, 429, 5xx e status inattesi |
| T-12 | CA-17 | UNIT | Verificare un solo check iniziale e assenza di timer retry |
| T-13 | CA-18 | UNIT | Invocare retry concorrenti e contare una sola operazione |
| T-14 | CA-18, CA-21 | WIDGET | Toccare retry e verificare transizione `initializing` |
| T-15 | CA-19 | UNIT | Disporre durante request e verificare abort/late-result ignorato |
| T-16 | CA-20, CA-21 | WIDGET | Renderizzare shell per initializing/ready/offline/misconfigured/error |
| T-17 | CA-21 | WIDGET | Verificare Semantics e target minimo del retry |
| T-18 | CA-21, CA-22 | WIDGET/SECURITY | Verificare quattro locale e assenza dettagli tecnici |
| T-19 | CA-23, CA-24 | STATIC | Verificare permission Android e assenza eccezioni ATS iOS |
| T-20 | CA-22, CA-30 | STATIC/SECURITY/GIT | Scan URL/key/token/query/config locale/artifact e diff confinement |
| T-21 | CA-25, CA-29 | FORMAT/ANALYZE/UNIT | Eseguire test mirati, gen-l10n, format e analyze |
| T-22 | CA-26 | INTEGRATION | Eseguire health staging host con timeout e output sanitizzato |
| T-23 | CA-27 | ANDROID_EMU | Avviare integration smoke staging su Android Emulator |
| T-24 | CA-28 | IOS_SIM | Avviare integration smoke staging su iOS Simulator |
| T-25 | CA-29 | BUILD_ANDROID | Compilare APK debug con config staging locale |
| T-26 | CA-29 | BUILD_IOS | Compilare iOS Simulator debug con config staging locale |
| T-27 | CA-29, CA-30 | UNIT/BUILD_ANDROID/BUILD_IOS/GIT | Eseguire `bash scripts/check.sh` e `git diff --check` |
| T-28 | CA-31 | MANUAL/STATIC | Review indipendenti runtime, platform e security/evidence |
| T-29 | CA-32 | CI | Ispezionare SHA, job, step e annotation del run finale |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Il prompt end-to-end preautorizza il ciclo completo, ma Planning ed Execution restano transizioni distinte. | Preservare protocollo e autorità utente | ATTIVA |
| D-02 | Il probe è l'endpoint Auth ufficiale `/auth/v1/health`, verificato sulle fonti Supabase correnti e sullo staging reale. | Evitare endpoint inventati e letture dati | ATTIVA |
| D-03 | `http` viene dichiarato dipendenza diretta nella versione già risolta, usando `AbortableRequest`. | Ottenere trasporto iniettabile e cancellazione reale senza dipendenza speculativa | ATTIVA |
| D-04 | Trasporto, mapping repository e orchestration Riverpod hanno responsabilità concrete e test separati. | Isolare rete, policy e lifecycle senza layer vuoti | ATTIVA |
| D-05 | `authenticationRequired` è riservato a operazioni future session-aware; 401/403 del health indicano misconfigurazione. | Non confondere reachability con login | ATTIVA |
| D-06 | La shell parte prima del check; `ready` arriva soltanto dopo SDK più health. | Consentire UI, cancellazione e retry anche offline | ATTIVA |
| D-07 | Retry è esclusivamente manuale e single-flight; nessun polling o recheck automatico su resume in TASK-011. | Evitare loop aggressivi e race | ATTIVA |
| D-08 | Il probe disabilita redirect e non logga request/response. | Evitare key forwarding e leakage | ATTIVA |
| D-09 | Android dichiara `INTERNET` nel manifest main; iOS non introduce eccezioni ATS. | Supportare staging in ogni variante mantenendo HTTPS fail-closed | ATTIVA |
| D-10 | TASK-011 effettua solo letture remote data-free; allow-list e OAuth restano TASK-020. | Mantenere scope e zero-write Supabase | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Rendere la connessione staging verificabile, cancellabile e recuperabile senza
trasformare la configurazione in una falsa prova di readiness e senza aprire alcun
accesso ai dati Storefront o inventory.

### Analisi

- PR #3 è merged e main locale/origin erano allineati sul merge commit prima della
  creazione del branch milestone.
- La configurazione locale staging è valida, ignorata e non tracciata.
- L'endpoint Auth ufficiale è raggiungibile dallo staging reale con esito sanitizzato
  HTTP 200 e payload GoTrue valido.
- `BackendStatus.ready` è oggi derivato dalla config o dall'inizializzazione SDK.
- `bootstrap()` attende prima di `runApp`, impedendo recovery UI quando il backend
  fallisce.
- Android main non ha `INTERNET`; iOS HTTPS non richiede eccezioni.
- `http 1.6.0` è già risolto transitivamente e offre `AbortableRequest`, ma va
  dichiarato come dipendenza diretta per poterlo importare.
- Android Emulator e iOS Simulator sono disponibili per gli smoke staging reali.

### Approccio

1. Introdurre modello di readiness, health service abortibile, repository di mapping e
   controller Riverpod single-flight.
2. Spostare inizializzazione/readiness dopo `runApp` preservando development offline e
   production fail-closed.
3. Costruire il solo request ufficiale Auth con redirect off, timeout e cancellazione.
4. Aggiungere feedback minimo localizzato e retry manuale alla shell.
5. Correggere il permesso Android senza indebolire ATS iOS.
6. Coprire la state machine con unit/widget test e un integration smoke staging
   separato dalla CI hermetic.
7. Eseguire probe host, build e smoke reali sui due simulatori, scan e gate completi.
8. Consegnare lo SHA tecnico a reviewer read-only distinti.

### Rischi

- **Falso `ready`**: emetterlo soltanto dopo SDK e health 200 con payload atteso.
- **Socket lasciato vivo**: usare abort trigger reale anche per il timeout.
- **Key inoltrata da redirect**: `followRedirects=false`.
- **Race retry/dispose**: single-flight, cancellation token e generation guard.
- **UI bloccata dal bootstrap**: renderizzare prima del check asincrono.
- **401 interpretato come login**: mapparlo a `misconfigured`.
- **Leak nei log/evidence**: nessun body/URL/key in messaggi o output persistente.
- **Scope creep UI/OAuth**: solo banner/retry readiness; account e callback restano ai
  task proprietari.
- **Rete production**: guard esplicito prima di inizializzatore e probe.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION
- **Autorizzazione USER_APPROVER**: già concessa in forma condizionata dal prompt
  end-to-end; da applicare con transizione esplicita senza cambiare scope

## Execution — `CODEX_EXECUTOR`

### Obiettivo compreso

Connettere il client al solo staging canonico con inizializzazione SDK e probe Auth
data-free realmente verificati, mantenendo development offline, production fail-closed,
UI sempre renderizzabile e nessun accesso ai dati.

### File controllati

- runtime/config: `lib/bootstrap.dart`, `lib/core/backend/`;
- UI/localizzazione: shell, banner readiness e cinque cataloghi ARB;
- piattaforme: manifest Android principale e configurazione iOS;
- dipendenze: `pubspec.yaml`, `pubspec.lock`;
- test: unit, widget e integration smoke dedicato;
- documenti: architettura, ambiente, quality gate, README ed evidence TASK-011.

### Piano minimo

1. Separare trasporto health, mapping repository e controller Riverpod.
2. Rendere il probe abortibile, senza redirect, retry automatici o payload esposti.
3. Renderizzare la shell prima della readiness e offrire solo retry manuale accessibile.
4. Verificare policy native, suite, build e smoke reali dual-platform.
5. Consegnare il commit tecnico e le evidence a reviewer indipendenti.

### Modifiche fatte

- introdotti i sette stati esatti di `BackendReadinessState`;
- aggiunti `HttpBackendHealthService`, `BackendReadinessRepository` e
  `BackendReadinessController` con timeout, abort, single-flight e generation guard;
- `ready` richiede inizializzazione Supabase staging e health Auth valido;
- development e production non inizializzano SDK né rete; production resta
  `misconfigured`;
- avvio app anticipato rispetto al check e banner localizzati/customer-safe con retry;
- aggiunto `INTERNET` al manifest Android main, senza cleartext o eccezioni ATS;
- dichiarato `http 1.6.0` come dipendenza diretta;
- disabilitati persistence/auto-refresh/deep-link PKCE Auth predefiniti fino a TASK-020;
- aggiunti test unit/widget e smoke data-free reali Android/iOS;
- aggiornati architettura, strategia ambiente, quality gate e README.

Commit tecnico revisionabile:
`2e646595ad01807be292179adc61013fdd1b2700` (`32` file, `1811` inserimenti,
`64` rimozioni).

### Check eseguiti

| Gate | Esito | Evidenza |
|---|---|---|
| `bash scripts/doctor.sh` | PASS | exit 0; simulatori Android/iOS disponibili; warning LAN device fisico non bloccante |
| test mirati backend/shell | PASS | exit 0 |
| `flutter analyze` | PASS | exit 0, nessuna issue |
| `flutter test --coverage` | PASS | exit 0, 105/105 |
| `bash scripts/check.sh` | PASS | exit 0; 105/105, analyze e build debug Android/iOS |
| build staging Android | PASS | exit 0, APK debug con config locale ignorata |
| build staging iOS | PASS | exit 0, Simulator debug con config locale ignorata |
| smoke staging Android | PASS | exit 0, 1/1; readiness `ready`, sessione nulla, shell guest |
| smoke staging iOS | PASS | exit 0, 1/1; readiness `ready`, sessione nulla, shell guest |
| probe host Auth | PASS | HTTP 200, schema health valido, output sanitizzato |
| gate static/security/Git | PASS | scope, query, secret, URL, artifact, permission e ATS verificati |
| CI tecnica `30598076908` | PASS | SHA tecnico esatto, 3/3 job, step tutti `success`, annotation 0/0/0 |

### Matrice CA -> evidence

| CA | Esito | Evidenza |
|---|---|---|
| CA-01 | PASS | PR #3/merge e task unico verificati; `environment-audit.md`. |
| CA-02 | PASS | Unico progetto non-production canonico, nessuna creazione. |
| CA-03 | PASS | Config a cinque input valida, ignorata e non tracciata. |
| CA-04 | PASS | Zero write remoto; solo metadata e health data-free. |
| CA-05 | PASS | Enum con i sette stati esatti e test dedicati. |
| CA-06 | PASS | Repository richiede SDK più health valido per `ready`. |
| CA-07 | PASS | Test development: nessuna inizializzazione/rete. |
| CA-08 | PASS | Test production: fail-closed, nessun fallback/rete. |
| CA-09 | PASS | Test request: solo `GET /auth/v1/health` con `apikey`. |
| CA-10 | PASS | Redirect disabilitati e URI derivata dalla origin validata. |
| CA-11 | PASS | Scan query/API dati: nessuna tabella, RPC o Storage. |
| CA-12 | PASS | Test health 200/schema valido -> `ready`. |
| CA-13 | PASS | Test timeout/transport -> `offline` con abort. |
| CA-14 | PASS | Test 401/403/404 -> `misconfigured`. |
| CA-15 | PASS | Test 408/429/5xx/payload incoerente -> `recoverableError`. |
| CA-16 | PASS | Stato presente e mai prodotto dal probe data-free. |
| CA-17 | PASS | Un solo check iniziale, nessun timer/polling. |
| CA-18 | PASS | Retry manuale e concorrente single-flight verificato. |
| CA-19 | PASS | Dispose abortisce e completion obsoleta è ignorata. |
| CA-20 | PASS | Widget/smoke mostrano shell durante readiness non pronta. |
| CA-21 | PASS | Stringhe localizzate, Semantics e retry accessibile verificati. |
| CA-22 | PASS | Test e scan escludono URL/key/body/token/dettagli tecnici. |
| CA-23 | PASS | Manifest main con `INTERNET`, senza cleartext/wildcard. |
| CA-24 | PASS | Nessun `NSAllowsArbitraryLoads`; build iOS riuscita. |
| CA-25 | PASS | Suite copre stati, mapping, timeout, abort, retry e sanitizzazione. |
| CA-26 | PASS | Probe reale sanitizzato HTTP 200/schema valido. |
| CA-27 | PASS | Android Emulator reale: 1/1 e readiness `ready`. |
| CA-28 | PASS | iOS Simulator reale: 1/1 e readiness `ready`. |
| CA-29 | PASS | Format/analyze/test/build staging dual-platform riusciti. |
| CA-30 | PASS | Diff, dipendenze, artifact e scan confinati. |
| CA-31 | NOT_RUN | Appartiene alla Review indipendente. |
| CA-32 | NOT_RUN | La CI tecnica è verde; manca la CI sullo SHA finale. |

### Matrice T-NN -> risultato

| Test | Esito | Evidenza |
|---|---|---|
| T-01 | PASS | Merge, branch, task unico e governance verificati. |
| T-02 | PASS | Audit progetto/config e zero-write sanitizzato. |
| T-03 | PASS | Enum e semantica stati coperti da test. |
| T-04 | PASS | Matrice environment coperta da test. |
| T-05 | PASS | Metodo/URI/header/redirect/assenza query verificati. |
| T-06 | PASS | Health 200 valido -> `ready`. |
| T-07 | PASS | Payload health invalido -> `recoverableError`. |
| T-08 | PASS | Timeout con abort -> `offline`. |
| T-09 | PASS | Errore trasporto -> `offline`. |
| T-10 | PASS | 401/403/404 -> `misconfigured`. |
| T-11 | PASS | 408/429/5xx/status inattesi coperti. |
| T-12 | PASS | Check iniziale unico e nessun auto-retry. |
| T-13 | PASS | Retry concorrenti condividono una operazione. |
| T-14 | PASS | Retry widget -> `initializing`. |
| T-15 | PASS | Dispose/abort/late-result verificati. |
| T-16 | PASS | Shell renderizzata per tutti gli stati pertinenti. |
| T-17 | PASS | Semantics e target retry verificati. |
| T-18 | PASS | Locali es/en/it/zh-Hans e sanitizzazione verificati. |
| T-19 | PASS | Android permission e ATS iOS fail-closed. |
| T-20 | PASS | Scan security/Git/config/artifact/query riusciti. |
| T-21 | PASS | L10n, format, analyze e 105/105 riusciti. |
| T-22 | PASS | Probe host reale data-free riuscito. |
| T-23 | PASS | Smoke Android Emulator 1/1. |
| T-24 | PASS | Smoke iOS Simulator 1/1. |
| T-25 | PASS | Build APK staging exit 0. |
| T-26 | PASS | Build iOS Simulator staging exit 0. |
| T-27 | PASS | `scripts/check.sh` e `git diff --check` exit 0. |
| T-28 | NOT_RUN | Appartiene alla Review indipendente. |
| T-29 | NOT_RUN | Appartiene alla CI finale. |

### Rischi rimasti

- il check health prova raggiungibilità Auth, non disponibilità futura delle tabelle;
- i default Auth sono intenzionalmente disabilitati fino a TASK-020;
- lo smoke usa simulatori e staging, non device fisici o produzione;
- package più recenti incompatibili con i constraint sono informativi e non aggiornati.

### Handoff a Review

- **Prossima fase**: REVIEW
- **Prossimo ruolo**: CODEX_REVIEWER
- **Handoff**: CODEX_EXECUTION_COMPLETE_TO_REVIEW

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

### Problemi critici

Nessun finding P0 o P1.

### Problemi medi

- `T011-REV-001` P2: il test del check iniziale invoca `retry()` e non prova
  l'avvio automatico; una mutation che rimuove la microtask lascia 105/105 verdi.
- `T011-REV-002` P2: nessun widget test esercita `recoverableError`, il relativo
  copy/retry può sparire lasciando la suite verde.
- `T011-REV-003` P2: lo smoke costruisce app/container manualmente e chiama il
  notifier; non attraversa `bootstrap()` né compie un'interazione UI.
- `T011-REV-004` P2: l'evidence smoke non contiene comandi/target completi,
  screenshot sanitizzati e manifest con SHA-256.
- `T011-REV-005` P2: un JSON 200 di servizio diverso con tre stringhe non vuote è
  accettato come health Auth; manca il vincolo `name == "GoTrue"`.

### Miglioramenti opzionali

- `T011-REV-006` P3: il body health viene accumulato senza una soglia massima; introdurre
  un limite piccolo e abortire/mappare fail-closed in caso di superamento.

### Fix richiesti

1. Rendere il test controller sensibile all'auto-check e all'assenza di auto-retry.
2. Coprire `recoverableError` con shell, copy, Semantics, target e retry.
3. Rifare lo smoke tramite `bootstrap()`, osservare `initializing` e usare la
   navigazione reale.
4. Rieseguire Android/iOS con comandi/target/output completi e produrre screenshot
   sanitizzati più manifest.
5. Richiedere identità `GoTrue` e aggiungere la regressione servizio errato.
6. Chiudere anche il P3 con body limitato e test overflow.

### Esito

`CHANGES_REQUIRED`

Gate indipendenti:

- runtime: 38/38 mirati e 105/105 completi `PASS`, ma due mutation sopravvissute;
- platform/UI: 44/44 `PASS`; smoke corrente 1/1 Android e 1/1 iOS, ma non attraversa
  l'entrypoint reale e non soddisfa il gate evidence;
- security: 62/62 `PASS`; scan query/secret/config/network e OSV `PASS`;
- CI handoff `30598639082`: SHA esatto
  `b4b2234f889df91ea422b769153f662c942dadf3`, 3/3 job, tutti gli step `success`,
  annotation 0/0/0;
- worktree revisionato pulito e zero write Supabase.

Finding aperti: 0 P0, 0 P1, 5 P2, 1 P3.

### Handoff

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`

## Fix — `CODEX_FIXER`

### Fix applicati

- `T011-REV-001`: test auto-check senza `retry()`, exactly-one e nessun auto-retry;
- `T011-REV-002`: widget test `recoverableError` con shell, copy, Semantics, target,
  tap, transizione e singola chiamata;
- `T011-REV-003`: smoke riscritto sul vero `bootstrap()`, banner `initializing`,
  readiness reale e navigazione Catalogo;
- `T011-REV-004`: smoke dual-platform rieseguito sullo SHA Fix; comandi, target,
  output, PNG sanitizzati e digest persistiti;
- `T011-REV-005`: health valido solo con `name == "GoTrue"` esatto;
- `T011-REV-006`: body health limitato a 8 KiB, overflow abortito e mappato
  `invalidResponse`.

Commit tecnico Fix:
`8621606d03d06b70f2a421c985c63b96ee3ef47a`.

### Check post-fix

| Gate | Esito | Evidenza |
|---|---|---|
| mutation auto-check | PASS | la rimozione della microtask rende rosso il nuovo test |
| mutation retry recoverable | PASS | la rimozione dell'azione rende rosso il nuovo test |
| test health | PASS | exit 0, 10/10 |
| test backend + banner | PASS | exit 0, 41/41 |
| `flutter analyze` | PASS | exit 0, nessuna issue |
| `flutter test --coverage` | PASS | exit 0, 108/108 |
| `bash scripts/check.sh` | PASS | exit 0; 108/108 e build debug Android/iOS |
| build staging Android/iOS | PASS | entrambi exit 0 |
| smoke bootstrap Android | PASS | exit 0, 1/1 |
| smoke bootstrap iOS | PASS | exit 0, 1/1 |
| screenshot/manifest | PASS | due PNG ispezionati, dimensioni/byte/SHA-256 verificati |
| log/config/secret scan | PASS | processi app puliti; config ignorata/non tracciata |
| CI Fix `30599648372` | PASS | SHA esatto, 3/3 job, step `success`, annotation 0/0/0 |

Tutti i finding sono dichiarati risolti dal Fix e richiedono verifica indipendente.

### Handoff a Review

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`

## Chiusura

- **Conferma utente**: già concessa in forma condizionata, non ancora applicabile
- **Merge autorizzato da USER_APPROVER**: sì, soltanto dopo TASK-011/012/020 `DONE`,
  review integrata, CI finale e PR batch verde
- **Follow-up candidate**: TASK-012 dopo closeout e CI finale TASK-011
- **Riepilogo finale**: non disponibile
- **Data completamento**: non disponibile
