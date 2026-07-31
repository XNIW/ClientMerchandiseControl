# TASK-011 — Connessione Flutter allo staging e backend health state

## Informazioni generali

- **Task ID**: TASK-011
- **Titolo**: Connessione Flutter allo staging e backend health state
- **File task**:
  `docs/TASKS/TASK-011-staging-connection-backend-readiness.md`
- **Stato**: ACTIVE
- **Fase**: PLANNING
- **Responsabile**: CODEX_PLANNER
- **Data creazione**: 2026-07-30
- **Ultimo aggiornamento**: 2026-07-30
- **Ultimo agente**: CODEX_PLANNER
- **Review outcome**: NOT_RUN
- **Reviewer**: non ancora assegnato
- **Approver**: USER_APPROVER
- **Indicatore**: CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION
- **DONE**: NO
- **Merge**: NO — milestone batch con TASK-012 e TASK-020
- **User approval**: GRANTED_CONDITIONALLY_BY_END_TO_END_PROMPT
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-011/`
- **Handoff**: CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION

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

`NOT_RUN` — fase non ancora iniziata.

### File controllati

`NOT_RUN` — fase non ancora iniziata.

### Piano minimo

`NOT_RUN` — fase non ancora iniziata.

### Modifiche fatte

`NOT_RUN` — fase non ancora iniziata.

### Check eseguiti

`NOT_RUN` — fase non ancora iniziata.

### Matrice CA -> evidence

`NOT_RUN` — fase non ancora iniziata.

### Matrice T-NN -> risultato

`NOT_RUN` — fase non ancora iniziata.

### Rischi rimasti

`NOT_RUN` — fase non ancora iniziata.

### Handoff a Review

- **Prossima fase**: REVIEW
- **Prossimo ruolo**: CODEX_REVIEWER
- **Handoff**: NOT_RUN

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

### Problemi critici

`NOT_RUN`

### Problemi medi

`NOT_RUN`

### Miglioramenti opzionali

`NOT_RUN`

### Fix richiesti

`NOT_RUN`

### Esito

`NOT_RUN`

### Handoff

`NOT_RUN`

## Fix — `CODEX_FIXER`

### Fix applicati

`NOT_RUN`

### Check post-fix

`NOT_RUN`

### Handoff a Review

`NOT_RUN`

## Chiusura

- **Conferma utente**: già concessa in forma condizionata, non ancora applicabile
- **Merge autorizzato da USER_APPROVER**: sì, soltanto dopo TASK-011/012/020 `DONE`,
  review integrata, CI finale e PR batch verde
- **Follow-up candidate**: TASK-012 dopo closeout e CI finale TASK-011
- **Riepilogo finale**: non disponibile
- **Data completamento**: non disponibile
