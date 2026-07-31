# TASK-020 — Supabase Auth, deep link e session lifecycle

## Informazioni generali

- **Task ID**: TASK-020
- **Titolo**: Supabase Auth, deep link e session lifecycle
- **File task**:
  `docs/TASKS/TASK-020-supabase-auth-deep-link-session-lifecycle.md`
- **Stato**: BLOCKED
- **Fase**: REVIEW
- **Responsabile**: CODEX_RE_REVIEWER
- **Data creazione**: 2026-07-31
- **Ultimo aggiornamento**: 2026-07-31
- **Ultimo agente**: CODEX_FIXER
- **Review outcome**: CHANGES_REQUIRED
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-020/`
- **Handoff**: CODEX_FIX_BLOCKED_TO_RE_REVIEW

## Dipendenze

- **Dipende da**: TASK-004 `DONE`; TASK-011 `DONE`; TASK-012 `DONE`
- **Sblocca**: TASK-021, TASK-022, TASK-027, TASK-033 e TASK-035

## Scope

- implementare Google OAuth reale tramite Supabase Auth, PKCE e browser esterno;
- usare esclusivamente la callback canonica
  `com.xniw.clientmerchandisecontrol://auth-callback/`;
- registrare un intent-filter Android preciso e un URL scheme iOS minimo;
- mantenere disabilitato il deep-link observer permissivo dello SDK e convalidare
  scheme, host, path e payload prima di qualunque exchange;
- introdurre `AuthRepository`, `SupabaseAuthRepository`, `AuthController`,
  `AuthState`, `AuthenticatedCustomer`, `AuthFailure` e `AuthErrorMapper` con
  Riverpod e responsabilità concrete;
- gestire sessione iniziale, callback, `onAuthStateChange`, refresh SDK, cold
  restore, resume, sessione scaduta, logout, dispose, duplicati e race;
- proteggere sessione e verifier PKCE tramite un solo adapter Android
  Keystore/iOS Keychain, senza fallback plaintext;
- collegare gli stati Auth alla schermata Account mantenendo Home, Catalogo e
  Carrello sempre disponibili al guest;
- normalizzare metadata non attendibili senza usarli per autorizzazione e senza
  riaprire il caricamento avatar remoto escluso da TASK-012;
- aggiungere copy localizzata, test unit/widget/integration deterministici e smoke
  OAuth reali su Android Emulator e iOS Simulator;
- aggiungere esclusivamente la callback canonica alla redirect allow-list del solo
  Supabase staging esistente, preservando ogni configurazione preesistente;
- produrre threat model, evidence sanitizzate, review indipendente A–E, eventuale
  Fix/re-review, CI, PR milestone e merge normale soltanto se tutti i gate sono
  soddisfatti.

## Contesto

TASK-004 ha definito un contratto compile-time fail-closed con callback esatta e kill
switch Google. TASK-011 ha collegato lo staging e inizializza oggi Supabase con
auto-refresh, persistence, PKCE storage e deep-link detection intenzionalmente
disabilitati. TASK-012 ha consegnato Account guest/authenticated puramente
presentazionale e ha imposto avatar soltanto da bytes locali bounded.

Le versioni bloccate sono `supabase_flutter 2.16.0`, `supabase 2.14.0`,
`gotrue 2.26.0` e `app_links 7.2.1`. L'API reale espone
`signInWithOAuth(..., redirectTo:, authScreenLaunchMode:)`; PKCE è il default. Lo
storage predefinito Flutter persiste sessione e verifier in SharedPreferences e non
soddisfa il requisito mobile per token critici. Inoltre il deep-link observer interno
considera Auth qualunque URI contenente code, token o parametri errore senza verificare
scheme, host o path. TASK-020 deve quindi usare storage sicuro custom e un callback
coordinator applicativo con `detectSessionInUri: false`.

Il progetto Supabase non-production canonico risulta `ACTIVE_HEALTHY`; TASK-011 ha
verificato provider Google configurato e callback mobile ancora assente dalla
allow-list. La verifica corrente diretta di provider e redirect deve essere ripetuta
prima del solo write remoto autorizzato. Il file staging locale è presente, ignorato,
valido e mantiene attualmente `GOOGLE_AUTH_ENABLED=false`.

La CI closeout di TASK-012 è attualmente `BLOCKED / CI_EXTERNAL` prima del runner per
billing/spending GitHub. Questo rischio non modifica i criteri: una CI non eseguita non
può diventare `PASS`.

## Non incluso

- login con password, email OTP, magic link, Apple, Facebook o provider diversi da
  Google;
- dipendenza `google_sign_in`, client Google nativo separato o SDK Firebase;
- creazione di account Google, inserimento di password/MFA o modifica delle
  credenziali OAuth condivise;
- Universal Links, Android App Links verificati, Associated Domains, signing o
  provisioning production;
- OAuth, redirect, Site URL, provider o credenziali del progetto production;
- creazione, eliminazione o modifica di progetti Supabase diversi dallo staging
  canonico;
- schema, migration, RLS, grant, tabelle, RPC, Storage, Edge Function o dati
  commerciali/customer;
- profilo, indirizzi, privacy/cancellazione account di TASK-021;
- download/cache/rendering remoto dell'avatar; TASK-020 usa il fallback locale
  TASK-012;
- route guard o login obbligatorio per Home, Catalogo, Carrello o browsing pubblico;
- catalogo reale, prezzi, stock, carrello persistente, checkout, ordine o pagamento;
- modifica di TASK-005–TASK-010, TASK-013–TASK-019, TASK-021 e successivi;
- repository esterni, App Store, Google Play, TestFlight o release production;
- force push, amend remoto, merge forzato o auto-merge.

## File coinvolti

- `pubspec.yaml` e `pubspec.lock`;
- `lib/core/backend/supabase_bootstrap.dart` e storage Auth sicuro concreto;
- feature-first Auth sotto `lib/features/auth/`;
- integrazione Account sotto `lib/features/account/`;
- wiring eager in app/router senza route guard guest;
- `lib/l10n/app_*.arb` e output `gen_l10n`;
- `android/app/src/main/AndroidManifest.xml`;
- `ios/Runner/Info.plist`;
- test Auth sotto `test/core/`, `test/features/auth/` e
  `test/features/account/`;
- `integration_test/auth_callback_flow_test.dart` e regressioni integration
  esistenti;
- `docs/ARCHITECTURE/AUTH-BOUNDARY.md`,
  `docs/ARCHITECTURE/MOBILE-ARCHITECTURE.md`, `docs/ENVIRONMENT.md`,
  `README.md` e `docs/SECURITY/GOOGLE-OAUTH-THREAT-MODEL.md`;
- `docs/MASTER-PLAN.md`, `docs/AI_WORKLOG.md`, questo task e
  `docs/TASKS/EVIDENCE/TASK-020/`.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | TASK-004, TASK-011 e TASK-012 risultano `DONE`; TASK-020 è l'unico task `ACTIVE` sul branch milestone previsto e Master Plan, task, README ed evidence concordano | GIT/STATIC |
| CA-02 | Il diff resta limitato ad Auth client, Account integration, bootstrap, configurazione nativa, localizzazioni, test, threat model ed evidence; nessun catalogo reale, profilo TASK-021, ordine, pagamento o repository esterno è modificato | GIT/STATIC |
| CA-03 | Changelog, documentazione corrente e sorgenti delle versioni bloccate di `supabase_flutter`/GoTrue sono auditati; firma OAuth, PKCE, lifecycle e persistenza usati corrispondono all'API realmente installata, con lockfile versionato | STATIC/SECURITY |
| CA-04 | Development resta senza OAuth/rete Auth, staging richiede backend/callback/flag completi, production mantiene Google disabilitato e fallisce chiuso senza fallback a staging | UNIT/SECURITY |
| CA-05 | Il login usa esclusivamente Supabase Auth Google con `AuthFlowType.pkce`, browser esterno e redirect canonico; `google_sign_in` non viene aggiunto salvo impossibilità provata, ADR e test equivalenti | UNIT/STATIC/SECURITY |
| CA-06 | Esistono responsabilità concrete e iniettabili per `AuthRepository`, `SupabaseAuthRepository`, `AuthController`, `AuthState`, `AuthenticatedCustomer`, `AuthFailure` e `AuthErrorMapper`; nessun widget importa o invoca Supabase direttamente | STATIC/UNIT |
| CA-07 | `AuthState` rappresenta almeno guest, authenticating, authenticated, cancelling/cancelled, signingOut, recoverableError e configurationError, senza combinazioni contraddittorie | UNIT |
| CA-08 | Il validatore callback accetta soltanto scheme, host e path canonici e un solo payload OAuth atteso; scheme/host/path errati, wildcard, user-info, porta, fragment, campi corrotti o payload inattesi non autenticano | UNIT/SECURITY |
| CA-09 | Android dichiara un solo intent-filter `VIEW` browsable preciso per scheme, host e path `/`, con `exported`/launch mode coerenti e senza wildcard o redirect aperto | STATIC/BUILD_ANDROID/ANDROID_EMU |
| CA-10 | iOS registra esclusivamente lo scheme previsto in `CFBundleURLTypes`; host/path restano verificati nel layer applicativo, il callback è inoltrato all'SDK e non vengono introdotti Universal Link o signing production | STATIC/BUILD_IOS/IOS_SIM |
| CA-11 | Nel solo progetto staging esistente sono verificati provider Google attivo e callback Supabase lato provider, senza creare progetto o sostituire credenziali condivise | MANUAL/SECURITY |
| CA-12 | La redirect allow-list staging riceve soltanto `com.xniw.clientmerchandisecontrol://auth-callback/`; redirect preesistenti sono preservati e non cambiano Site URL, production, provider, secret o wildcard | MANUAL/SECURITY |
| CA-13 | La modifica staging ha evidence before/after sanitizzata, esito verificato e project ref parzialmente oscurato; URL, key, client secret e dati personali non sono persistiti | SECURITY/MANUAL |
| CA-14 | Bootstrap Auth legge la sessione iniziale e sottoscrive `onAuthStateChange`; gli eventi rilevanti aggiornano una sola fonte di stato coerente | UNIT |
| CA-15 | Login, ritorno callback e sessione valida rendono immediatamente visibile Account authenticated e riportano l'utente alla destinazione Account | UNIT/WIDGET/ANDROID_EMU/IOS_SIM |
| CA-16 | Login e callback sono single-flight/idempotenti: doppio tap, eventi duplicati, completamenti fuori ordine e callback concorrenti non aprono flussi multipli né sovrascrivono stato più recente | UNIT |
| CA-17 | Ogni callback è consumato al massimo una volta; callback invalido, corrotto, ripetuto o privo di sessione non autentica, non espone dettagli e non causa crash | UNIT/ANDROID_EMU/IOS_SIM/SECURITY |
| CA-18 | Cold start, terminate/relaunch e resume ripristinano una sessione valida; refresh resta delegato all'SDK e una sessione scaduta/revocata rimuove lo stato authenticated con recovery customer-safe | UNIT/ANDROID_EMU/IOS_SIM |
| CA-19 | Dispose chiude subscription e risorse; eventi o future tardive dopo dispose non mutano stato né producono eccezioni | UNIT |
| CA-20 | Logout rende subito guest, elimina la sessione locale, gestisce in modo fail-closed l'errore di rete/remoto, non elimina l'account Google e permette un login successivo | UNIT/WIDGET/ANDROID_EMU/IOS_SIM |
| CA-21 | La persistenza scelta è motivata dall'audit SDK e protegge sessione/PKCE con Android Keystore e iOS Keychain; nessun token resta in storage plaintext o SharedPreferences | UNIT/STATIC/SECURITY |
| CA-22 | Access token, refresh token, OAuth code/state, callback completa, sessione, user object e dati personali non compaiono in log, eccezioni, crash output, screenshot, bundle, Git o evidence | UNIT/SECURITY |
| CA-23 | `AuthenticatedCustomer` usa ID soltanto internamente e normalizza display name ed email con null/bounds/fallback; metadata sono non fidati, non eseguono HTML e non rendono instabile la UI; avatar remoto non è caricato | UNIT/WIDGET/SECURITY |
| CA-24 | Email, route, cache, `shop_id` e `user_metadata` non autorizzano nulla; il client usa solo publishable key e non interroga inventory, RPC, Storage o tabelle customer/profile fuori scope | STATIC/SECURITY |
| CA-25 | Account rende correttamente tutti gli stati Auth: progress e pulsante disabilitato durante login/logout, cancellazione non critica, retry manuale senza loop, fallback avatar/nome e logout obbligatorio | WIDGET |
| CA-26 | Offline, cancellazione, provider indisponibile, configurazione mancante, callback invalido, sessione scaduta ed errore inatteso hanno mapping stabile e copy localizzata customer-safe, senza stack trace | UNIT/WIDGET |
| CA-27 | Home, Catalogo e Carrello restano navigabili da guest durante login, cancellazione, offline ed errori Auth; nessun login è imposto al browsing pubblico | WIDGET/ANDROID_EMU/IOS_SIM |
| CA-28 | UI Auth mantiene es-CL primaria/fallback, it, en e zh-Hans, light/dark, text scale 200%, Semantics, live status, target 48 dp, portrait/landscape e zero overflow | WIDGET/ANDROID_EMU/IOS_SIM |
| CA-29 | `app_guest_flow_test.dart` resta non regressivo e `auth_callback_flow_test.dart` copre deterministicamente login, callback fake, authenticated, restart, logout, guest, callback invalido e assenza crash senza Google reale | WIDGET/ANDROID_EMU/IOS_SIM |
| CA-30 | Smoke Android staging completa installazione pulita, OAuth Google reale con account di test già disponibile, callback, session restore, logout, relogin e controllo crash/ANR/log | ANDROID_EMU/MANUAL/SECURITY |
| CA-31 | Smoke iOS staging completa installazione pulita, OAuth Google reale, callback, session restore, logout e controllo crash/log, senza password/MFA inseriti da Codex e senza signing production | IOS_SIM/MANUAL/SECURITY |
| CA-32 | Smoke errori verifica offline pre-login, cancellazione provider, callback invalido, doppio tap, background durante OAuth, ritorno senza sessione, logout offline e staging config mancante | ANDROID_EMU/IOS_SIM/MANUAL |
| CA-33 | `docs/SECURITY/GOOGLE-OAUTH-THREAT-MODEL.md` tratta CSRF/state, PKCE, redirect hijacking/custom-scheme collision, leakage, fixation/replay, callback corrotto, logout, metadata, screenshot, resume, account switching e cancellation con mitigazioni/test | STATIC/SECURITY |
| CA-34 | Tutti i 12 file evidence prescritti esistono, sono sanitizzati e contengono matrici complete una-riga-per-CA e una-riga-per-T con soli `PASS`, `FAIL`, `BLOCKED`, `NOT_RUN` | STATIC/GIT |
| CA-35 | Doctor, syntax shell, action pins, governance, architecture boundaries, pub get/deps/outdated, gen-l10n, format, analyze, suite coverage, `scripts/check.sh` e `git diff --check` hanno comando, output pertinente ed exit code reali | STATIC/FORMAT/ANALYZE/UNIT/GIT |
| CA-36 | Dipendenze nuove sono minime, stabili e motivate; scan mirato esclude secret, service role, OAuth secret, config locale, production URL, certificati, provisioning, keystore, PII e artifact | STATIC/SECURITY/GIT |
| CA-37 | APK debug e iOS Simulator debug compilano realmente; build staging con file locale ignorato resta distinta dagli smoke runtime | BUILD_ANDROID/BUILD_IOS |
| CA-38 | I cinque reviewer indipendenti A–E verificano nuovo HEAD, CA, test, runtime ed evidence e chiudono tutti i finding P0/P1/P2 | MANUAL/STATIC/SECURITY |
| CA-39 | CI sullo SHA finale esegue job/step applicabili, test Auth deterministici, build Android/iOS, pin e scan senza Google/staging secret; SHA, annotation e risultato sono verificati `PASS` | CI |
| CA-40 | PR authenticated foundation contiene soltanto TASK-011/012/020, viene unita con merge normale solo dopo review/CI verdi; main locale coincide con origin/main, worktree è pulito, Master è `IDLE` e task futuri restano invariati | GIT/CI |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-02 | GIT/STATIC | Verificare dipendenze, branch, task unico, governance e diff confinement prima dell'Execution |
| T-02 | CA-03 | STATIC/SECURITY | Auditare changelog/docs/sorgenti package e registrare firme, opzioni, storage e versioni bloccate |
| T-03 | CA-04 | UNIT/SECURITY | Provare development, staging e production, Google abilitato/disabilitato, config incompleta e diagnostica sanitizzata |
| T-04 | CA-11, CA-12, CA-13 | MANUAL/SECURITY | Verificare staging; applicare una sola aggiunta allow-list e confrontare insiemi before/after sanitizzati |
| T-05 | CA-08, CA-17 | UNIT/SECURITY | Tabella callback: valida, scheme/host/path errati, porta/user-info/fragment/wildcard, payload mancante/corrotto/inatteso e replay |
| T-06 | CA-09 | STATIC/ANDROID_EMU | Ispezionare manifest e usare ADB con URI canonico e varianti invalide, verificando routing preciso e processo vivo |
| T-07 | CA-10 | STATIC/IOS_SIM | Ispezionare plist e usare `simctl openurl` con URI canonico e varianti invalide, senza Universal Link/signing |
| T-08 | CA-05 | UNIT/STATIC | Fake repository verifica provider Google, PKCE, browser esterno e redirect canonico senza dipendenza nativa Google |
| T-09 | CA-06, CA-24 | STATIC/UNIT | Verificare dependency direction, provider Riverpod, assenza Supabase nei widget e denylist dati/API |
| T-10 | CA-07, CA-14 | UNIT | Eseguire tabella transizioni guest/authenticating/authenticated/cancelling/cancelled/signingOut/error/configurationError |
| T-11 | CA-14, CA-19 | UNIT | Provare sessione iniziale, eventi auth stream, refresh/sign-out/expiry, unsubscribe e late event dopo dispose |
| T-12 | CA-16, CA-17 | UNIT | Provare doppio tap, callback/evento duplicato, completamenti fuori ordine e stale result |
| T-13 | CA-18 | UNIT | Simulare cold restore, resume, refresh SDK, sessione scaduta/revocata e fallback guest |
| T-14 | CA-20 | UNIT | Provare logout riuscito, errore/offline, pulizia locale immediata e nuovo login |
| T-15 | CA-21 | UNIT/STATIC/SECURITY | Testare adapter storage, first-install cleanup, read/write/delete/errori e scan per persistenza plaintext |
| T-16 | CA-23 | UNIT/WIDGET/SECURITY | Provare metadata nulli, vuoti, HTML-like o troppo lunghi, email/ID e avatar sempre locale/fallback |
| T-17 | CA-22, CA-26 | UNIT/SECURITY | Tabella error mapper/redactor con token, code, callback e PII sentinella; nessun valore deve riapparire |
| T-18 | CA-25 | WIDGET | Renderizzare ogni stato Account e verificare Google, progress, disable, cancellation, error, retry, authenticated e logout |
| T-19 | CA-27 | WIDGET | Navigare Home/Catalogo/Carrello/Account come guest durante login e stati Auth recuperabili |
| T-20 | CA-26, CA-28 | UNIT/WIDGET | Verificare parità ARB, es-CL/it/en/zh-Hans, fallback es e assenza stringhe Auth hardcoded |
| T-21 | CA-25, CA-28 | WIDGET | Renderizzare Auth light/dark, 200%, compact/large, portrait/landscape; verificare Semantics, 48 dp e zero overflow |
| T-22 | CA-27, CA-29 | ANDROID_EMU/IOS_SIM | Rieseguire `app_guest_flow_test.dart` su entrambi i target senza regressioni guest |
| T-23 | CA-15, CA-18, CA-20, CA-29 | ANDROID_EMU/IOS_SIM | Eseguire `auth_callback_flow_test.dart` fake: login, callback, Account, restart, logout e ritorno guest |
| T-24 | CA-17, CA-29 | ANDROID_EMU/IOS_SIM | Iniettare callback invalido/corrotto/ripetuto e ritorno senza sessione; verificare guest e nessun crash |
| T-25 | CA-33 | STATIC/SECURITY | Review threat model contro ogni minaccia prescritta, mitigazione, rischio residuo e test associato |
| T-26 | CA-22, CA-24, CA-36 | STATIC/SECURITY/GIT | Scan sorgenti, diff, bundle/log/evidence per secret, token, PII, config locale, production e API/tabelle vietate |
| T-27 | CA-34 | STATIC/GIT | Verificare i 12 file evidence, cardinalità CA/T, stati ammessi e assenza contenuti sensibili |
| T-28 | CA-35 | STATIC/GIT | Eseguire doctor, `bash -n`, action pins, governance e architecture checks |
| T-29 | CA-35 | FORMAT/ANALYZE/UNIT | Eseguire pub get/deps/outdated, gen-l10n, format check, analyze, suite completa con coverage e `scripts/check.sh` |
| T-30 | CA-37 | BUILD_ANDROID | Compilare APK debug development e staging con file locale ignorato |
| T-31 | CA-37 | BUILD_IOS | Compilare iOS Simulator debug development e staging con file locale ignorato |
| T-32 | CA-30 | ANDROID_EMU/MANUAL/SECURITY | Eseguire i 17 passi live Android, includendo terminate/relaunch, logout, relogin e log sanitizzati |
| T-33 | CA-31 | IOS_SIM/MANUAL/SECURITY | Eseguire i 17 passi live iOS, includendo terminate/relaunch, logout e log sanitizzati |
| T-34 | CA-32 | ANDROID_EMU/IOS_SIM/MANUAL | Eseguire matrice error smoke su entrambi i target e registrare il comportamento logout offline effettivamente supportato |
| T-35 | CA-38 | MANUAL/STATIC/SECURITY | Reviewer A–E verificano indipendentemente HEAD e producono finding riproducibili con file:riga |
| T-36 | CA-39 | CI | Ispezionare sullo SHA finale job, step, annotation, test Auth deterministici e assenza di secret/live OAuth |
| T-37 | CA-01, CA-02, CA-40 | GIT | Verificare stage selettivo, commit, tracking, PR scope e worktree prima del closeout |
| T-38 | CA-40 | GIT/CI | Dopo merge verificare SHA PR, `main == origin/main`, worktree pulito, Master `IDLE` e task non autorizzati ancora `TODO` |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Il prompt end-to-end preautorizza l'intero ciclo, ma Planning, applicazione dell'autorizzazione, Execution, Review, Fix e closeout restano transizioni e commit distinti. | Preservare protocollo, provenance e separazione ruoli | ATTIVA |
| D-02 | Strategia primaria: Supabase OAuth Google, `AuthFlowType.pkce`, browser esterno e callback canonica; nessun `google_sign_in`. | Usare la API installata, centralizzare provider e ridurre superficie nativa | ATTIVA |
| D-03 | `detectSessionInUri` resta `false`; un solo coordinator `app_links` valida origine e payload prima dell'exchange. | L'handler SDK 2.16.0 non verifica scheme/host/path | ATTIVA |
| D-04 | `app_links 7.2.1` diventa dipendenza diretta, `flutter_secure_storage 10.3.1` è l'unica nuova dipendenza runtime esterna e `shared_preferences 2.5.5`, già transitiva, è promossa direct soltanto per marker booleani non sensibili. | Evitare dipendenze transitive implicite e proteggere token/verifier | ATTIVA |
| D-05 | Un solo adapter implementa `LocalStorage` e `GotrueAsyncStorage`; usa namespace dedicato, Keychain non sincronizzato/this-device, Keystore, first-install cleanup e cleanup tombstone bounded. | Evitare storage concorrenti, plaintext e sessioni residue dopo reinstall/logout fallito | ATTIVA |
| D-06 | Auth vive sotto `lib/features/auth/`; Account consuma soltanto stati e callback dominio. | Rispettare feature-first MVVM/Riverpod e vietare Supabase nei widget | ATTIVA |
| D-07 | Il controller è eager, single-flight e generation-safe; un exchange cancellato viene compensato prima del retry e la navigazione Account avviene solo dopo callback persistito, non durante cold restore. | Non perdere cold callback, non conservare sessioni cancellate e non disturbare l'avvio autenticato | ATTIVA |
| D-08 | `AuthenticatedCustomer` conserva ID interno e campi UI bounded; ignora avatar remoto e metadata autorizzativi. | Metadata Google sono input non fidato e TASK-012 vieta provider avatar network-capable | ATTIVA |
| D-09 | L'unico write remoto ammesso aggiunge l'URI esatto alla allow-list del solo staging preservando l'insieme esistente. | Evitare wildcard, drift, produzione e credenziali condivise | ATTIVA |
| D-10 | Logout usa esplicitamente `SignOutScope.local`, tenta indipendentemente delete sessione/verifier e registra tombstone non sensibili da ritentare al bootstrap. | Fail-closed sul device senza promettere logout globale | ATTIVA |
| D-11 | Development resta guest senza Auth remoto; staging usa kill switch; production continua a rifiutare Google in questo milestone. | Nessun fallback o modifica production | ATTIVA |
| D-12 | CI usa solo fake deterministici; Google reale e config staging restano smoke locali sanitizzati. | Non introdurre account, secret o flakiness in CI | ATTIVA |
| D-13 | Codex usa solo account Google di test già autenticato; password, MFA, CAPTCHA o nuovo account diventano blocker esterno esplicito. | Rispettare il limite di credenziali e interazione umana | ATTIVA |
| D-14 | Il threat model target-scoped è persistito nel path richiesto dall'utente, che prevale sul default della skill. | Rendere verificabili i rischi OAuth del milestone | ATTIVA |
| D-15 | Il billing/spending GitHub osservato resta rischio `CI_EXTERNAL`; nessun run senza runner viene reinterpretato come verde. | Evidence reale e gate CI non inferiti | ATTIVA |
| D-16 | TASK-020 chiude la PR milestone comune con TASK-011/TASK-012 solo dopo review A–E e CI verdi; nessun task futuro viene attivato. | Rispettare batch autorizzato e stop condition | ATTIVA |
| D-17 | L'istruzione esplicita `USER_APPROVER` impone di completare review, test automatizzabili e PR anche quando password/MFA è l'unico blocker esterno; i gate live restano `BLOCKED` e non consentono `APPROVED`, `DONE` o merge. | Preservare il lavoro e distinguere review tecnica da accettazione finale senza inventare `PASS` | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Consegnare una fondazione Auth cliente reale e sicura che permetta Google login,
restore e logout su Android/iOS senza imporre autenticazione al browsing guest, senza
esporre token o dati e senza estendere il client oltre il dominio Storefront futuro.

### Analisi

- Le dipendenze TASK-004, TASK-011 e TASK-012 sono `DONE`; la baseline locale è
  pulita, allineata, `flutter analyze` passa e 141/141 test passano.
- Il contratto config contiene già callback canonica, kill switch staging e
  production fail-closed.
- Il bootstrap corrente è intenzionalmente incompatibile con Auth reale: disabilita
  refresh, persistence e PKCE storage.
- PKCE è il default della API bloccata, ma va dichiarato esplicitamente insieme al
  browser esterno.
- Il default SDK usa SharedPreferences per sessione e verifier; serve un adapter
  sicuro per entrambi e una strategia first-install per il Keychain iOS persistente.
- Il callback interno SDK è troppo permissivo; la validazione applicativa deve
  precedere qualunque `exchangeCodeForSession`/`getSessionFromUrl`.
- Android può confinare scheme/host/path nel manifest; iOS può registrare soltanto lo
  scheme e dipende sempre dal validator Dart.
- `AccountScreen` è guest statico e l'Auth runtime deve essere eager per non perdere
  cold callback avviate sulla Home.
- L'avatar remoto non appartiene a TASK-020: nome/email sono bounded, l'ID resta
  interno e il fallback locale TASK-012 resta il solo rendering.
- Il connector Supabase vede un solo progetto non-production sano; l'audit dashboard
  corrente richiede una sessione autenticata e deve essere ripetuto prima del write.
- Il prompt autorizza l'uso di un account Google test esistente, ma non consente a
  Codex di inserire password, MFA, risolvere CAPTCHA senza consenso o creare account.

### Approccio

1. Applicare in una transizione distinta l'autorizzazione già concessa e passare a
   `EXECUTION`.
2. Dichiarare soltanto le dipendenze dirette necessarie e implementare l'adapter
   sicuro iniettabile con first-install cleanup bounded.
3. Rendere il bootstrap single-flight e configurarlo esplicitamente con PKCE,
   auto-refresh, storage sicuro, deep-link detection disabilitata e debug off.
4. Implementare i tipi dominio, repository Supabase, validator/coordinator callback,
   error mapper e controller Riverpod eager con lifecycle, deduplica e generation.
5. Collegare Account e navigazione callback mantenendo le tre feature guest
   indipendenti da Auth.
6. Configurare manifest/plist minimi e testarne source, merged output, cold e warm
   delivery.
7. Verificare e aggiornare una sola volta la redirect allow-list staging con before /
   after sanitizzato e abilitare il kill switch solo nel file locale ignorato.
8. Completare localizzazione, threat model, unit/widget/integration fake e regressioni.
9. Eseguire gate, build e smoke error/live reali su Android e iOS senza log sensibili.
10. Consegnare uno SHA tecnico a cinque reviewer indipendenti A–E; correggere solo
    finding approvati e ripetere gate/re-review.
11. Richiedere CI sullo SHA revisionato; soltanto se verde applicare closeout, PR
    milestone, merge normale e riallineamento main.

### Rischi

- **Callback hijacking/custom-scheme collision**: intent-filter minimo, validator
  esatto e PKCE; il custom scheme non è verificabile e resta rischio residuo/DoS.
- **Handler concorrenti**: disabilitare sia Flutter deep linking sia
  `detectSessionInUri`; un solo listener `app_links`.
- **Token plaintext o backup**: adapter Keychain/Keystore, backup Android disabilitato
  o escluso, namespace/chiavi bounded e nessun fallback SharedPreferences.
- **Keychain dopo reinstall**: marker non sensibile nel container app e cancellazione
  mirata delle sole chiavi Auth al primo avvio.
- **Cold callback persa**: avvio eager e queue bounded finché Supabase è pronto.
- **Race callback/logout/dispose**: single-flight, generation e serializzazione;
  callback tardive non possono riautenticare.
- **Cancellazione browser ambigua**: stato non critico e azione Cancel esplicita;
  nessun successo inferito dal bool di launch.
- **Sessione scaduta/offline**: stream con `onError`, restore customer-safe e logout
  locale immediato.
- **Metadata non fidati**: limiti, normalizzazione, fallback, zero HTML e zero uso
  autorizzativo.
- **Leak nei log/evidence**: `debug:false`, errori a codici chiusi, scan sentinella,
  screenshot/log sanitizzati e nessun URI completo.
- **Drift staging**: confronto di insiemi before/after, append esatto, nessun Site URL
  o provider/secret modificato.
- **Live OAuth esterno**: account/sessione Google, consent o CAPTCHA possono bloccare
  lo smoke senza autorizzare gestione credenziali.
- **CI esterna**: billing GitHub può impedire runner; resta `BLOCKED / CI_EXTERNAL`
  fino a ripristino.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Planning pronto**: CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION
- **Autorizzazione USER_APPROVER**: concessa e applicata dal prompt end-to-end il
  2026-07-31
- **Transizione**: PLANNING -> EXECUTION
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Execution — `CODEX_EXECUTOR`

### Implementazione

Autorizzata sul Planning commit `8eab82b` e consegnata nel commit tecnico
`82439dd3fdbbc2920f27e4606dceadb412f0a6e7`.

- introdotti dominio, repository, controller Riverpod eager, callback source/validator
  ed error mapper Auth senza dipendenze Supabase nei widget;
- configurati Google OAuth, PKCE esplicito, browser esterno, auto-refresh, storage
  sicuro unico e `detectSessionInUri:false`;
- aggiunto adapter fail-closed per sessione e verifier su Keystore/Keychain, con
  first-install cleanup mirato e backup Android disabilitato;
- integrati Account, navigazione solo da successo callback, stati/customer copy nei
  cinque bundle tecnici e regressioni accessibilità;
- registrati intent-filter Android e URL scheme iOS minimi; iOS inoltra manualmente
  App/Scene lifecycle allo stesso singleton `app_links`;
- aggiunti threat model TM-01…TM-30, 12 evidence, 51 nuovi test unit/widget rispetto
  alla baseline e integration fake/native dual-platform.

### Gate ed evidence

- `scripts/check.sh`: `PASS`, exit 0; format 84 file, analyze zero issue, 192/192,
  coverage 1567/2009 (78,0%), APK e iOS Simulator development;
- build staging: Android `PASS`; primo tentativo iOS parallelo `FAIL` per contesa lock
  Flutter, rerun isolato `PASS`;
- guest, callback fake e backend readiness: Android 3/3 `PASS`, iOS 3/3 `PASS`;
- callback warm nativo Android: `PASS`; routing manifest/plist e validazione negativa:
  `PASS`;
- callback warm nativo iOS: `BLOCKED` dalla conferma OS del custom scheme mentre il
  Mac è locked; LaunchServices ha risolto il bundle e nessun crash è avvenuto;
- Supabase staging: progetto canonico `ACTIVE_HEALTHY`, Google attivo e authorize PKCE
  302 verso Google `PASS`; redirect allow-list/write/after `BLOCKED` da MFA;
- live OAuth ed error matrix live: `BLOCKED`; kill switch locale rimasto `false`;
- scan source/diff/bundle/evidence: `PASS`, nessun valore secret-shaped, config locale,
  runtime log Auth o artifact tracciato.

La transizione a Review applica D-17: l'Execution non dichiara soddisfatti i gate
esterni e non è eleggibile a `APPROVED`, `DONE` o merge. Serve una review indipendente
A–E dello SHA consegnato; i blocker restano aperti.

### Handoff

- **Prossima fase**: REVIEW
- **Prossimo ruolo**: CODEX_REVIEWER
- **Handoff**: CODEX_EXECUTION_COMPLETE_TO_REVIEW

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

Cinque reviewer read-only indipendenti hanno verificato il revision set:

- tecnico `82439dd3fdbbc2920f27e4606dceadb412f0a6e7`;
- handoff/evidence `2f25f3f74537856204fa42e9ea5d024f9c848332`.

Esito consolidato: 0 P0, 1 P1, 18 P2 e 2 P3. Il P1 riguarda la sessione SDK/persistita
che può sopravvivere a Cancel durante un exchange in-flight. I P2 coprono expiry,
race restore/cancel/retry, persistenza e cleanup fail-closed, coverage runtime/UI,
confinement PR, evidence/CI e policy della configurazione pubblicabile. I due P3
riguardano retry dell'initialization storage e provenance temporale.

Report completo:
`docs/TASKS/EVIDENCE/TASK-020/review-report.md`.

Esito: `CHANGES_REQUIRED`.

Handoff: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Re-review 1 del Fix

Cinque re-reviewer read-only indipendenti hanno verificato il revision set:

- tecnico `408f14d242e9d35bfcefbebd10858dcb9e38d028`;
- handoff pubblicato `0ddd26abd9d6c7a5eaa70aaba2481cfe0b05bfa7`.

Sedici dei ventuno finding originari sono chiusi. Restano aperti
T020-REV-003, T020-REV-007, T020-REV-015, T020-REV-016 e T020-REV-018; la
re-review ha inoltre consolidato un P1 sul Logout concorrente con exchange, un P2
sulla cancellazione provider e tre P3 documentali. Totale aperto: 0 P0, 1 P1, 6 P2
e 3 P3.

Verifiche autonome: suite mirate 45/45, 56/56, 41/41 e 23/23 `PASS`; callback fake
Android/iOS e callback warm Android `PASS`; branch/upstream e scope PR `PASS`.
La run CI `30619705565` sullo SHA di handoff ha tre job senza runner né step e una
annotation billing/spending per job, quindi resta `BLOCKED / CI_EXTERNAL`.

Report completo:
`docs/TASKS/EVIDENCE/TASK-020/review-report.md`.

Esito: `CHANGES_REQUIRED`.

Handoff: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Re-review 2 del Fix

Cinque re-reviewer read-only indipendenti hanno verificato il revision set:

- tecnico `036dcd1be047d49d6b53738d06e5e58caf608f34`;
- handoff/evidence `7b4bf152b496f7429b506c053f0e8ec5cf436b83`.

Gli shard intent/governance, lifecycle e UI/native non hanno trovato P0–P3 tecnici
nuovi. Gli shard security ed evidence hanno consolidato quattro P2:

- T020-RR2-001: lo scanner salta integralmente i propri due script, consentendo un
  bypass tramite quei path;
- T020-RR2-002: la combinazione failure di entrambi i marker, tombstone sicuro e
  delete può lasciare una sessione stale ripristinabile;
- T020-RR2-003: Git/CI evidence si ferma allo SHA tecnico e non registra lo SHA
  handoff con run `30624825908`;
- T020-RR2-004: artifact evidence senza digest, conteggio 629 divergente dal rerun
  627, header revision set e comandi con placeholder non esatti.

Totale aperto: 0 P0, 0 P1, 4 P2 e 0 P3. T020-REV-003 e T020-RR-001…005 risultano
chiusi; T020-REV-007/015/016/018 restano aperti per i quattro finding sopra.

Verifiche autonome: suite mirate lifecycle 53/53, intent/evidence 39/39 e UI/native
40/40 `PASS`; scanner 336 file, fixture 16/16 + 1/1 e bundle corrente 627 file
`PASS`; PR #4 `OPEN/DRAFT`, 143 path, zero TASK-003/004. La CI handoff run
`30624825908` ha tre job senza runner o step e una annotation billing/spending per
job, quindi resta `BLOCKED / CI_EXTERNAL`.

Esito: `CHANGES_REQUIRED`.

Handoff: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Re-review 3 del Fix

Cinque re-reviewer read-only indipendenti hanno verificato il revision set:

- tecnico `5740c835a116af16ab2e7ca6c55c927d180ece90`;
- handoff/evidence `891f96124f706c8a53168937ec701709301b3855`.

T020-RR2-001…004 risultano chiusi: scanner sui propri path e snapshot Git,
journal cleanup indipendente, provenance handoff/CI e digest/conteggi bundle sono
stati verificati autonomamente. T020-REV-007/016/018 sono chiusi; T020-REV-015
resta aperto tramite un nuovo gap semantico dello scanner.

Finding consolidati:

- T020-RR3-C-001, P2: lo scanner decodifica i JWT ma rifiuta soltanto
  `role=service_role`; un JWT sintetico valido `role=authenticated` è stato
  accettato come artifact con exit 0. Nessun JWT è presente nel Git corrente, ma
  un access token customer potrebbe superare source/index/worktree/bundle scan;
- T020-RR3-A-001, P3: CMD-X08 persiste il prefisso assoluto del path SDK locale;
  l'evidence deve redigere il path macchina senza alterare exit e risultato.

Il rilievo dello shard A sulla mancata auto-citazione dell'handoff non è consolidato
come finding: un commit non può contenere il proprio SHA o la propria run CI senza
circolarità. Lo shard E ha verificato HEAD/upstream/PR sullo SHA `891f961`; questa
re-review registra ora la provenance richiesta.

Verifiche autonome:

- storage/lifecycle: 33/33 `PASS`;
- scanner source: 336 file `PASS`; fixture esistenti 22/22 negative e 1/1 positiva
  `PASS`; boundary 5/5 `PASS`;
- artifact: APK 548 file con digest
  `88af2ad662d7f6f13f14cae00c576072c433cb5d9507f5206bbf688ee0f5ff70`;
  Runner 81 file con tree digest
  `4332441962a60da4c0544bef6825fb14dc3b6b7e1a16b4e3794da5730fa1d85c`;
- matrici: 12 file, 40 CA e 38 test `PASS`;
- PR #4: `OPEN/DRAFT`, base `main`, 143 path e zero TASK-003/004;
- CI handoff run `30628616615`: `BLOCKED / CI_EXTERNAL`; job Android
  `91149556012`, Quality `91149556044` e iOS `91149556060` con `runner_id=0`,
  zero step e una annotation billing/spending ciascuno.

Totale aperto: 0 P0, 0 P1, 1 P2 e 1 P3. Redirect allow-list/OAuth live,
callback warm iOS e CI restano blocker esterni distinti.

Esito: `CHANGES_REQUIRED`.

Handoff: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Fix — `CODEX_FIXER`

Autorizzato esclusivamente sui finding T020-REV-001…T020-REV-021 consolidati.

Commit tecnico candidato:
`408f14d242e9d35bfcefbebd10858dcb9e38d028`.

- T020-REV-001…007 e 020: serializzati cancel/exchange/cleanup, compensazione prima
  del retry, restore race chiusa, expiry valida distinta da recovery SDK retryable,
  persistenza esplicita e failure stream, delete sessione/PKCE indipendenti,
  tombstone ritentati e initialization retryable;
- T020-REV-008/009: lifecycle reale e callback provider non provati sono
  riclassificati `BLOCKED`, senza inferire restore/live o configurazione Google;
- T020-REV-010: rimossi dal diff milestone i tre path TASK-003/004 con commit
  normale; nessun rebase o force push;
- T020-REV-011/012: il callback fake parte da Home, seleziona Account e prova il
  browsing guest durante authenticating, cancelling e offline su Android/iOS;
- T020-REV-013: matrice Account completa su otto stati, due temi, tre viewport,
  scala 200%, Semantics/live region, target 48 dp e zero overflow;
- T020-REV-014/015: matrici con colonna `Tipo`, parser di regressione e scan CI
  sanitizzato con tre fixture negative;
- T020-REV-016…019/021: evidence CI/Git, dipendenza marker, command ID, confine
  publishable config e date locali corretti.

Gate sul commit tecnico:

- `scripts/check.sh`: `PASS`, exit 0; 214/214 test, coverage 1745/2179 (80,1%),
  analyze zero issue, security/governance/architecture e build development duale;
- build staging isolate Android/iOS: `PASS`, exit 0;
- guest, callback fake e readiness staging: Android 3/3 e iOS 3/3 `PASS`;
- callback warm Android: `PASS`; callback warm iOS: `BLOCKED`, `simctl` exit 0 e
  harness timeout 30 s per conferma OS non accettabile con Mac locked;
- allow-list/provider callback e OAuth live: `BLOCKED` da MFA, flag locale ancora
  `false`, zero write remoto;
- CI sullo SHA Fix: da richiedere dopo push; i run precedenti restano `BLOCKED /
  CI_EXTERNAL` per billing/spending.

I finding sono implementati ma non chiusi autonomamente dal fixer: serve re-review
indipendente A–E. Poiché gate obbligatori restano non superabili, la transizione
applicabile è:

- **Prossima fase**: REVIEW
- **Stato task**: BLOCKED
- **Prossimo ruolo**: CODEX_RE_REVIEWER
- **Handoff**: CODEX_FIX_BLOCKED_TO_RE_REVIEW

### Fix 2 dopo la re-review 1

Il secondo Fix è rimasto confinato ai dieci finding aperti dalla re-review 1 e ai
difetti riproducibili emersi dagli audit candidate degli stessi finding.

Commit tecnici:

- lifecycle, storage, scanner/evidence e documentazione:
  `51b6949e5438039dc3c08de8f77ab1f078b85479`;
- chiusura dei gap residui scanner, callback provider Retry e matrice evidence:
  `036dcd1be047d49d6b53738d06e5e58caf608f34`.

Interventi:

- T020-REV-003: restore e sessione corrente vengono ricontrollati dopo il cleanup
  pre-login prima di qualunque launch browser;
- T020-REV-007: tombstone ridondanti su secure storage e SharedPreferences bloccano
  il restore e ritentano il purge dopo failure multiple;
- T020-REV-015: scanner Git/artifact NUL-safe, service-role JWT e GOCSPX, blob
  symlink, path/estensioni sensibili case-insensitive, PEM coerenti, read/find/grep
  fail-closed e scan bundle CI;
- T020-REV-016/018: 12 evidence esatte, ogni CA/T deve riferire un command ID
  dichiarato, build e bundle sono legati allo SHA esatto e Git/CI reali sono
  aggiornati;
- T020-RR-001: Logout attende l'exchange e applica un secondo purge compensativo;
- T020-RR-002: cancel/failure provider termina l'epoca OAuth; la deduplica resta
  globale soltanto per callback con code e consente error/cancel identici dopo Retry;
- T020-RR-003/004/005: range README, formula architetturale e marker storage
  documentati senza ambiguità.

Gate sullo SHA tecnico finale:

- `scripts/check.sh`: `PASS`, exit 0; 218/218 test, coverage 1770/2214 (79,9%),
  analyze zero issue, security/governance/architecture e build development duale;
- build staging sequenziale Android/iOS: `PASS`, exit 0;
- scanner: `PASS`, 336 file Git, 16/16 fixture negative, 1/1 positiva e 629 file
  nei bundle staging ricostruiti;
- suite mirata Auth/storage/evidence: `PASS`, 50/50;
- guest, callback fake e readiness: Android 3/3 e iOS 3/3 `PASS`;
- callback warm Android: `PASS`; callback warm iOS: `BLOCKED`, `simctl` exit 0 e
  harness exit 1 per timeout 30 s sulla conferma OS con Mac locked;
- audit candidate lifecycle/evidence/scanner: 0 P0, 0 P1 e 0 P2 residui; non
  sostituiscono la re-review A–E;
- CI run `30624421347` sullo SHA `036dcd1`: `BLOCKED / CI_EXTERNAL`, 3/3 job
  senza runner o step e una annotation billing/spending per job;
- allow-list, callback provider e OAuth live: `BLOCKED` da MFA; flag locale
  `false`, zero write remoto.

Il fixer non chiude autonomamente i finding. Con gate obbligatori esterni non
superati, il revision set torna comunque a Review:

- **Prossima fase**: REVIEW
- **Stato task**: BLOCKED
- **Prossimo ruolo**: CODEX_RE_REVIEWER
- **Handoff**: CODEX_FIX_BLOCKED_TO_RE_REVIEW

### Fix 3 dopo la re-review 2

Il terzo Fix è rimasto confinato a T020-RR2-001…004 e ai difetti riproducibili
emersi dagli audit candidate nello stesso scope.

Revision set:

- handoff Re-review 2 -> Fix 3:
  `7825145f16e0de33725a36470df0ebc20bedfcbe`;
- commit tecnico Fix 3:
  `5740c835a116af16ab2e7ca6c55c927d180ece90`.

Interventi:

- T020-RR2-001 / T020-REV-015: lo scanner non esclude più i propri script, verifica
  separatamente snapshot Git index e worktree, symlink correnti e staged, fallimenti
  parziali dell'enumeratore Git e del decoder JWT; le fixture non incorporano
  direttamente i valori ostili che devono costruire;
- T020-RR2-002 / T020-REV-007: un journal non sensibile in Application Support,
  scritto prima dei marker SharedPreferences e secure store, rende ritentabile il
  cleanup dopo il riavvio anche quando entrambi i marker preesistenti e il delete
  falliscono; ogni read failure blocca il restore;
- T020-RR2-003 / T020-REV-016: Git, PR e CI sono correlati allo SHA tecnico corrente
  e alle run reali, con job, runner, step e annotation;
- T020-RR2-004 / T020-REV-018: bundle finali ricostruiti dopo gli integration test,
  conteggio 548 APK + 81 Runner = 629, digest SHA-256 APK
  `88af2ad662d7f6f13f14cae00c576072c433cb5d9507f5206bbf688ee0f5ff70` e
  Runner tree
  `4332441962a60da4c0544bef6825fb14dc3b6b7e1a16b4e3794da5730fa1d85c`,
  invariati prima/dopo lo scan.

Gate sullo SHA tecnico:

- `scripts/check.sh`: `PASS`, exit 0; 221/221 test, coverage 1802/2247 (80,2%),
  analyze zero issue, scanner 336 file con 22/22 fixture negative e 1/1 positiva,
  boundary architetturali 5/5 e build development Android/iOS;
- suite mirata storage/bootstrap/repository: `PASS`, 33/33; include riavvio reale
  su directory temporanea dopo failure simultanee, first install, read error
  fail-closed, separazione target e idempotenza;
- build staging sequenziale Android/iOS: `PASS`, exit 0; artifact finali correlati
  dai digest sopra;
- guest/callback fake e readiness: Android 3/3 e iOS 3/3 `PASS`;
- callback warm Android: `PASS`, ADB exit 0 `Status: ok`, harness 1/1; il primo
  tentativo con `adb` non nel `PATH` resta `FAIL` diagnostico e il rerun usa il path
  SDK esplicito;
- callback warm iOS: `BLOCKED`, `simctl` exit 0 e harness exit 1 per timeout 30 s;
  il dialogo OS è stato osservato ma non può essere accettato con Mac locked;
- audit candidate storage/scanner/architettura: 0 P0, 0 P1 e 0 P2 residui; non
  sostituiscono la re-review A–E;
- CI run `30626914509` sullo SHA `5740c83`: `BLOCKED / CI_EXTERNAL`; job iOS
  `91144201237`, Quality `91144201270` e Android `91144201297` hanno
  `runner_id=0`, zero step e una annotation billing/spending ciascuno;
- allow-list, callback provider e OAuth live: `BLOCKED` da MFA; kill switch
  `false`, zero write remoto.

Il `FAIL` analyze osservato durante l'esecuzione concorrente con una suite storage
resta registrato come contesa Flutter su `ios/Flutter/ephemeral/Packages/.packages`;
il rerun isolato sullo stesso SHA è `PASS`. Nessun risultato diagnostico è
reinterpretato.

Il fixer non chiude autonomamente i finding. Con gate obbligatori esterni non
superati, il revision set torna a Review:

- **Prossima fase**: REVIEW
- **Stato task**: BLOCKED
- **Prossimo ruolo**: CODEX_RE_REVIEWER
- **Handoff**: CODEX_FIX_BLOCKED_TO_RE_REVIEW

### Fix 4 dopo la re-review 3

Il quarto Fix è rimasto confinato ai due finding della re-review 3 senza
dichiararli autonomamente chiusi.

Revision set:

- handoff Re-review 3 -> Fix 4:
  `a621c3c08e1f6968bfe9af9c2e9e1f8c8d1d2d3b`;
- commit tecnico Fix 4:
  `9dbd53532f7a49040d0bf94fcd1a28abf5a0d382`.

Interventi:

- T020-RR3-C-001 / T020-REV-015: il decode JWT passa direttamente attraverso
  base64url, OpenSSL e `JSON::PP` senza command substitution; è consentito soltanto
  un JSON object con un unico ruolo scalare letterale `anon`. JWT customer,
  `service_role`, ruolo ignoto o mancante, duplicato o escaped, JSON invalido,
  payload NUL e failure decoder/parser sono respinti fail-closed;
- T020-RR3-A-001: CMD-X08 conserva comando, exit e risultato reali ma redige il
  prefisso host come `<android-sdk>/platform-tools/adb`;
- i documenti normativi descrivono il confine publishable senza introdurre token
  completi, secret o fallback permissivi.

Gate sullo SHA tecnico:

- `scripts/check.sh`: `PASS`, exit 0; 221/221 test, coverage 1802/2247 (80,2%),
  analyze zero issue, scanner 336 file, fixture 32/32 negative e 2/2 positive,
  boundary 5/5 e build development Android/iOS;
- build staging sequenziale Android/iOS: `PASS`, exit 0; file locale ignorato e
  nessun valore raw stampato;
- bundle finali: APK SHA-256
  `164225362dd64e859b3cab2688350e891f944a64cc55ece3f867189d9cc56e18`;
  Runner tree SHA-256
  `6295cd692517d40e4b817f3c96fd1b5972062a789aa0a5940196c37aff471a3d`;
  scan 548 + 81 = 629 file e digest invariati prima/dopo;
- audit candidate scanner read-only: 0 P0, 0 P1 e 0 P2 residui nello scope;
  non sostituisce la re-review formale;
- CI run `30630589047` sullo SHA `9dbd535`: `BLOCKED / CI_EXTERNAL`; job iOS
  `91155745893`, Android `91155745943` e Quality `91155745948` hanno
  `runner_id=0`, zero step e una annotation billing/spending ciascuno;
- allow-list, callback provider e OAuth live: `BLOCKED` da MFA; kill switch
  `false`, zero write remoto;
- callback warm iOS: `BLOCKED` dal dialogo OS non accettabile con Mac locked; il
  codice app e le prove native precedenti non sono stati modificati dal Fix 4.

Il fixer non chiude i finding e non approva il proprio lavoro. Con re-review e gate
obbligatori esterni non superati, il revision set torna a Review:

- **Prossima fase**: REVIEW
- **Stato task**: BLOCKED
- **Prossimo ruolo**: CODEX_RE_REVIEWER
- **Handoff**: CODEX_FIX_BLOCKED_TO_RE_REVIEW

## Chiusura

- **Conferma utente**: autorizzazione Execution applicata; conferma DONE condizionata
  a review/CI verdi
- **Merge autorizzato da USER_APPROVER**: sì, condizionato a review e CI verdi
- **Follow-up candidate**: nessuno attivabile in questo milestone
- **Riepilogo finale**: non ancora disponibile
- **Data completamento**: non applicabile
