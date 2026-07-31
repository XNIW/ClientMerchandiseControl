# Commands and results — TASK-020

## Revision set Fix

- Commit tecnico verificato:
  `408f14d242e9d35bfcefbebd10858dcb9e38d028`.
- Base `main` e `origin/main`:
  `40d118eebf78eeabea9e26747adb00053dd875bc`.
- Target:
  Android Emulator `emulator-5554` e iPhone 17 Pro Simulator iOS 26.5.
- Config staging:
  file locale ignorato, cinque chiavi contrattuali, kill switch Google `false`;
  nessun valore raw è riportato qui.

## Command evidence canonica

| ID | Revisione/target | Comando o azione esatta | Esito | Exit/output redatto | Warning, deviazione o prerequisito |
|---|---|---|---|---|---|
| CMD-F01 | `408f14d`, host + Android/iOS | `bash scripts/check.sh` | PASS | exit 0; doctor/pin/shell/security/governance/architecture/pub/l10n/format/analyze; 214/214 test; 1745/2179 linee, 80,1%; APK e iOS Simulator development costruiti | warning Xcode `objective_c.framework` non bloccante; 10 package più recenti non risolvibili dai constraint |
| CMD-F02 | `408f14d`, host | `flutter pub deps --style=compact && flutter pub outdated --no-dev-dependencies` | PASS | exit 0; grafo risolto; dipendenze dirette al newest resolvable | major Riverpod fuori constraint; nessun upgrade opportunistico |
| CMD-F03 | `408f14d`, Android+iOS staging | `flutter build apk --debug --dart-define-from-file=config/app_config.staging.local.json && flutter build ios --simulator --debug --dart-define-from-file=config/app_config.staging.local.json` | PASS | exit 0; APK debug e Runner simulator staging costruiti | file locale verificato ignorato; valori non stampati |
| CMD-F04 | `408f14d`, Android | `flutter test -d emulator-5554 integration_test/app_guest_flow_test.dart integration_test/auth_callback_flow_test.dart` | PASS | exit 0; 2/2 | launch, guest navigation, interleaving Auth, callback fake, Account, restore simulato, logout, errore e processo vivo |
| CMD-F05 | `408f14d`, Android staging | `flutter test -d emulator-5554 integration_test/backend_readiness_smoke_test.dart --dart-define-from-file=config/app_config.staging.local.json` | PASS | exit 0; 1/1; readiness `ready` | health Auth data-free; nessuna sessione customer |
| CMD-F06 | `408f14d`, Android warm callback | `flutter test -d emulator-5554 integration_test/auth_native_callback_delivery_test.dart` + `adb shell am start -W -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d <callback-canonica-redatta> <application-id>` | PASS | harness exit 0; ADB exit 0/status `ok`; 1/1 | callback query redatta; zero exchange |
| CMD-F07 | `408f14d`, iOS | `flutter test -d <ios-simulator-id> integration_test/app_guest_flow_test.dart integration_test/auth_callback_flow_test.dart` | PASS | exit 0; 2/2 | stesso flusso fake deterministico Android |
| CMD-F08 | `408f14d`, iOS staging | `flutter test -d <ios-simulator-id> integration_test/backend_readiness_smoke_test.dart --dart-define-from-file=config/app_config.staging.local.json` | PASS | exit 0; 1/1; readiness `ready` | health Auth data-free; nessuna sessione customer |
| CMD-F09 | `408f14d`, iOS warm callback | `flutter test -d <ios-simulator-id> integration_test/auth_native_callback_delivery_test.dart` + `xcrun simctl openurl <ios-simulator-id> <callback-canonica-redatta>` | BLOCKED | `simctl` exit 0; harness exit 1 dopo timeout 30 s | dialogo OS del custom scheme non accettabile con Mac locked; prerequisito: conferma interattiva OS |
| CMD-F10 | `408f14d`, host | `bash scripts/check-client-security.sh && bash scripts/test-client-security-scan.sh` | PASS | exit 0; 336 file tracciati, zero violazioni; fixture negative 3/3 respinte | scanner stampa solo path, mai valori |
| CMD-F11 | `408f14d`, host | `flutter analyze && flutter test test/core/backend/secure_supabase_auth_storage_test.dart test/features/auth/data/supabase_auth_repository_test.dart test/features/auth/application/auth_controller_test.dart` | PASS | exit 0; zero issue; 45/45 | regressioni finding lifecycle/storage |
| CMD-F12 | `408f14d`, host | `git diff --check && git diff --cached --check` | PASS | exit 0 | nessun whitespace error |
| CMD-F13 | `408f14d`, host | `git diff --name-only 40d118eebf78eeabea9e26747adb00053dd875bc` + denylist TASK-003/004 | PASS | exit 0; zero path TASK-003, TASK-004 o `TASK-003-004` nel diff milestone | il confinement remoto diventa verificabile dopo push |
| CMD-B01 | `036dcd1`, APK + Runner.app ricostruiti da CMD-S03 | `bash scripts/check-client-security.sh --artifact build/app/outputs/flutter-apk/app-debug.apk --artifact build/ios/iphonesimulator/Runner.app` | PASS | exit 0; 336 file Git e 629 file artifact verificati, zero secret privilegiati | correlazione esatta tra SHA, build staging e bundle scansionati; PEM coerenti e path sensibili inclusi |
| CMD-D01 | worktree Fix, Android | `flutter test integration_test/auth_callback_flow_test.dart` | FAIL | exit 1; più device disponibili, nessun test avviato | corretto specificando `-d`; CMD-F04/CMD-F07 passano |
| CMD-D02 | worktree Fix, Android | primo `flutter test -d emulator-5554 integration_test/auth_callback_flow_test.dart` | FAIL | terminato manualmente dopo 54 s; exit non conservato | `pumpAndSettle` su progress persistente corretto; CMD-F04 passa |
| CMD-D03 | worktree Fix, Android | tre integration file aggregati senza define staging | FAIL | exit 1; guest/callback 2/2 PASS, readiness rifiuta `development` | errore d'invocazione; CMD-F05 passa con define corretto |
| CMD-D04 | worktree Fix, Android staging | primo readiness con define corretto | FAIL | exit 1; stato transitorio `offline` | host health HTTP 200, airplane mode 0 e connettività emulator PASS; rerun CMD-F05 exit 0 |
| CMD-D05 | Execution, iOS staging | build Android/iOS staging avviate in parallelo sulla stessa directory | FAIL | iOS exit 1 per lock Flutter/ephemeral | contesa del tool, non compilazione; esecuzione isolata e CMD-F03 exit 0 |
| CMD-R01 | Supabase staging, dashboard | aprire Auth URL configuration e provider Google con sessione esistente | BLOCKED | dashboard ferma su MFA; nessun write | prerequisito: intervento umano MFA; vietato a Codex inserirlo |
| CMD-R02 | Supabase staging, probe read-only | health/settings pubblici e authorize PKCE con redirect non seguito | PASS | exit 0; health HTTP 200, provider Google attivo, authorize HTTP 302 al dominio Google | non prova la callback Supabase configurata lato provider |
| CMD-CI01 | handoff precedente `2f25f3f` | `gh run view 30614374801` e `gh run view 30614438284` con JSON job/step/annotation | BLOCKED | comando exit 0; ogni run 3/3 job `failure`, zero step, una annotation/job | billing/spending GitHub prima del runner; prerequisito: ripristino Billing & plans |
| CMD-RR01 | `0ddd26a`, cinque shard read-only A–E | review di intent/CA, lifecycle, security/storage, UI/native ed evidence/Git/CI; suite mirate | FAIL | shard: 23/23, 45/45, 56/56 e 41/41 + 6/6 test `PASS`; 16/21 finding originari chiusi; 1 P1, 6 P2 e 3 P3 aperti | esito consolidato `CHANGES_REQUIRED`; nessun reviewer ha modificato il worktree |
| CMD-CI02 | handoff `0ddd26a` | `gh run view 30619705565` e API annotation dei job `91121069809`, `91121069668`, `91121069636` | BLOCKED | exit 0; 3/3 job `failure`, `runner_id=0`, zero step e una annotation/job | billing/spending GitHub prima del runner; prerequisito: ripristino Billing & plans |
| CMD-S01 | `036dcd1`, host + Android/iOS | `bash scripts/check.sh` | PASS | exit 0; pin/security/governance/architecture/pub/l10n/format/analyze; 218/218 test; 1770/2214 linee, 79,9%; build development duale | 10 package latest non risolvibili dai constraint; nessun artifact versionato |
| CMD-S02 | `036dcd1`, host | `flutter pub deps --style=compact && flutter pub outdated --no-dev-dependencies` | PASS | exit 0; dipendenze al newest resolvable | major Riverpod fuori constraint; nessun upgrade opportunistico |
| CMD-S03 | `036dcd1`, Android+iOS staging | `flutter build apk --debug --dart-define-from-file=config/app_config.staging.local.json && flutter build ios --simulator --debug --dart-define-from-file=config/app_config.staging.local.json` | PASS | exit 0; APK e Runner simulator staging ricostruiti in sequenza | file locale ignorato; valori non stampati |
| CMD-S04 | `036dcd1`, Android | `flutter test -d emulator-5554 integration_test/app_guest_flow_test.dart integration_test/auth_callback_flow_test.dart` | PASS | exit 0; 2/2 | guest, callback fake, restore, logout, errori e browsing interleaved |
| CMD-S05 | `036dcd1`, Android staging | `flutter test -d emulator-5554 integration_test/backend_readiness_smoke_test.dart --dart-define-from-file=config/app_config.staging.local.json` | PASS | exit 0; 1/1; readiness `ready` | health Auth data-free |
| CMD-S06 | `036dcd1`, Android warm callback | harness nativo + `adb shell am start -W ... <callback-canonica-redatta>` | PASS | ADB exit 0/status `ok`; harness exit 0; 1/1 | processo warm, validator canonico, zero exchange |
| CMD-S07 | `036dcd1`, iOS | `flutter test -d <ios-simulator-id> integration_test/app_guest_flow_test.dart integration_test/auth_callback_flow_test.dart` | PASS | exit 0; 2/2 | flussi fake deterministici equivalenti ad Android |
| CMD-S08 | `036dcd1`, iOS staging | `flutter test -d <ios-simulator-id> integration_test/backend_readiness_smoke_test.dart --dart-define-from-file=config/app_config.staging.local.json` | PASS | exit 0; 1/1; readiness `ready` | health Auth data-free |
| CMD-S09 | `036dcd1`, iOS warm callback | harness nativo + `xcrun simctl openurl <ios-simulator-id> <callback-canonica-redatta>` | BLOCKED | `simctl` exit 0; harness exit 1 dopo timeout 30 s | dialogo OS del custom scheme non accettabile con Mac locked; prerequisito: conferma interattiva |
| CMD-S10 | `036dcd1`, host | `flutter analyze && flutter test <storage/repository/controller/evidence>` | PASS | exit 0; zero issue; 50/50 | include callback provider identico dopo Retry e referential integrity delle matrici |
| CMD-S11 | `036dcd1`, host | `bash scripts/check-client-security.sh && bash scripts/test-client-security-scan.sh` | PASS | exit 0; 336 file; 16/16 fixture negative respinte e 1/1 positiva accettata | GOCSPX, service-role JWT, symlink Git, PEM, estensioni/path e read failure fail-closed |
| CMD-S12 | candidate Fix sul diff `51b6949..036dcd1`, tre audit read-only | audit lifecycle/evidence e due cicli scanner con probe sanitizzati | PASS | 0 P0/P1/P2 residui; controller+governance 26/26; bundle 629 file | non sostituisce la re-review A–E sul revision set di handoff |
| CMD-S13 | `036dcd1`, Git/PR | `git status`, diff check/scope, push e `gh pr view 4` | PASS | worktree pulito prima dell'aggiornamento evidence; branch/upstream/PR head allineati; zero path TASK-003/004 | PR #4 `OPEN/DRAFT`, base `main`, head `036dcd1`, mergeable |
| CMD-S14 | `036dcd1`, GitHub Actions | `gh run view 30624421347` + API job/annotation | BLOCKED | 3/3 job `failure`, `runner_id=0`, zero step, una annotation/job | billing/spending GitHub prima del runner; prerequisito: ripristino Billing & plans |
| CMD-Q01 | tecnico `036dcd1`, handoff `7b4bf15`, cinque shard read-only A–E | re-review di intent, lifecycle, security, UI/native ed evidence/Git/CI con suite mirate | FAIL | 0 P0, 0 P1, 4 P2, 0 P3; suite 39/39, 53/53 e 40/40 `PASS` | esito consolidato `CHANGES_REQUIRED`; scanner path, tombstone e provenance evidence da correggere |
| CMD-Q02 | handoff `7b4bf15`, GitHub Actions | `gh run view 30624825908` + API job/annotation | BLOCKED | 3/3 job `failure`, `runner_id=0`, zero step, una annotation/job | billing/spending GitHub prima del runner; prerequisito: ripristino Billing & plans |
| CMD-Q03 | handoff `7b4bf15`, Git/PR | `git status`, ref locali/remote, API PR files/checks | PASS | branch/upstream/PR allineati, worktree pulito, 143 path e zero TASK-003/004 | PR #4 `OPEN/DRAFT`, base `main`, mergeable |

I `FAIL` diagnostici restano evidence reali e non vengono trasformati in `PASS`: i
rerun conformi sono identificati separatamente. I comandi con callback usano qui un
placeholder redatto; l'URI esatto è validato dal codice e non viene persistito con
query o code.

## Matrice criteri di accettazione

| CA | Tipo | Esito | Evidence |
|---|---|---|---|
| CA-01 | GIT/STATIC | PASS | CMD-S01/CMD-S13; dipendenze DONE, TASK-020 unico task corrente e diff milestone confinato |
| CA-02 | GIT/STATIC | PASS | CMD-S13; zero path TASK-003/004, catalogo reale, profilo, ordine o pagamento |
| CA-03 | STATIC/SECURITY | PASS | CMD-S02; sorgenti/API GoTrue/Supabase installate e lockfile verificati |
| CA-04 | UNIT/SECURITY | PASS | CMD-S01; matrice config development/staging/production fail-closed |
| CA-05 | UNIT/STATIC/SECURITY | PASS | CMD-S01/CMD-S02; Supabase Google, PKCE, browser esterno e zero `google_sign_in` |
| CA-06 | STATIC/UNIT | PASS | CMD-S01; boundary Auth iniettabili e widget senza import Supabase |
| CA-07 | UNIT | PASS | CMD-S01/CMD-S10; stati dominio e transizioni, inclusi cancel/expiry/storage |
| CA-08 | UNIT/SECURITY | PASS | CMD-S01; validator strict e matrice URI/payload negativa |
| CA-09 | STATIC/BUILD_ANDROID/ANDROID_EMU | PASS | CMD-S01/CMD-S03/CMD-S06; manifest preciso, build e routing warm reali |
| CA-10 | STATIC/BUILD_IOS/IOS_SIM | BLOCKED | plist/build/validator PASS in CMD-S01/S03; CMD-S09 ricezione warm non attestata; causa: conferma OS, prerequisito: interazione sul Mac sbloccato |
| CA-11 | MANUAL/SECURITY | BLOCKED | CMD-R01/R02; provider attivo PASS, callback Supabase lato provider non verificabile oltre MFA; prerequisito: MFA umano |
| CA-12 | MANUAL/SECURITY | BLOCKED | CMD-R01; allow-list before/write/after fermata da MFA; nessun write |
| CA-13 | SECURITY/MANUAL | BLOCKED | CMD-R01; before/after non ottenibili, project ref solo mascherato; prerequisito: accesso dashboard dopo MFA |
| CA-14 | UNIT | PASS | CMD-S01/S10; current session e auth/storage stream alimentano un solo controller |
| CA-15 | UNIT/WIDGET/ANDROID_EMU/IOS_SIM | PASS | CMD-S04/S07; callback fake da Home autentica e seleziona Account su entrambi i target |
| CA-16 | UNIT | PASS | CMD-S10/S12; single-flight, replay code-only, provider Retry, cancel/exchange, restore race e stale verifier |
| CA-17 | UNIT/ANDROID_EMU/IOS_SIM/SECURITY | PASS | CMD-S01/S04/S07; callback invalida/corrotta/duplicata non autentica e non crasha |
| CA-18 | UNIT/ANDROID_EMU/IOS_SIM | BLOCKED | unit restore/expiry/recovery SDK PASS in CMD-S10; terminate/relaunch con sessione reale non eseguibile senza OAuth live/MFA |
| CA-19 | UNIT | PASS | CMD-S10; dispose e future/eventi tardivi testati con compensazione |
| CA-20 | UNIT/WIDGET/ANDROID_EMU/IOS_SIM | PASS | CMD-S01/S04/S07/S10; logout locale, cleanup indipendente, tombstone e nuovo login |
| CA-21 | UNIT/STATIC/SECURITY | PASS | CMD-S01/S10/S11; adapter unico Keychain/Keystore e nessun fallback plaintext |
| CA-22 | UNIT/SECURITY | PASS | CMD-S01/S10/S11/CMD-B01; error mapper, source, Git, bundle ed evidence sanitizzati |
| CA-23 | UNIT/WIDGET/SECURITY | PASS | CMD-S01; identity bounded, markup/control/bidi rifiutati e avatar locale |
| CA-24 | STATIC/SECURITY | PASS | CMD-S01/S11/S13; client non autorizzativo, publishable config soltanto e zero API dati vietate |
| CA-25 | WIDGET | PASS | CMD-S01; tutti gli stati Account e azioni renderizzati |
| CA-26 | UNIT/WIDGET | PASS | CMD-S01/S10; mapping stabile, expiry retryable e copy customer-safe |
| CA-27 | WIDGET/ANDROID_EMU/IOS_SIM | PASS | CMD-S04/S07; Home/Catalogo/Carrello navigabili durante authenticating/cancelling/offline |
| CA-28 | WIDGET/ANDROID_EMU/IOS_SIM | PASS | CMD-S01/S04/S07; locale, temi, 200%, semantics, 48 dp, portrait/landscape |
| CA-29 | WIDGET/ANDROID_EMU/IOS_SIM | PASS | CMD-S04/S07; guest e callback fake non regressivi su entrambi i target |
| CA-30 | ANDROID_EMU/MANUAL/SECURITY | BLOCKED | build/fake/native PASS in CMD-F03/F04/F06; live 17 passi fermato da allow-list/MFA, flag false |
| CA-31 | IOS_SIM/MANUAL/SECURITY | BLOCKED | build/fake PASS in CMD-F03/F07; live fermato da MFA e conferma OS CMD-F09, flag false |
| CA-32 | ANDROID_EMU/IOS_SIM/MANUAL | BLOCKED | subset fake/error PASS in CMD-F01/F04/F07; matrice live richiede OAuth remoto abilitabile dopo MFA |
| CA-33 | STATIC/SECURITY | PASS | threat model TM-01…TM-30 aggiornato; CMD-S01/S10 |
| CA-34 | STATIC/GIT | PASS | CMD-S01/S10; 12 file esatti e parser valida 40 CA, 38 T, tipo/stato/cardinalità/comando |
| CA-35 | STATIC/FORMAT/ANALYZE/UNIT/GIT | PASS | CMD-S01/S02/S13 con comando, output ed exit reali |
| CA-36 | STATIC/SECURITY/GIT | PASS | CMD-S02/S11/CMD-B01; dipendenze minime, 336 file puliti, 16/16 fixture negative e 1/1 positiva |
| CA-37 | BUILD_ANDROID/BUILD_IOS | PASS | CMD-S01 development e CMD-S03 staging, entrambi i target exit 0 |
| CA-38 | MANUAL/STATIC/SECURITY | FAIL | CMD-Q01; cinque re-reviewer sul medesimo revision set, 0 P0/P1, 4 P2 e 0 P3 |
| CA-39 | CI | BLOCKED | CMD-Q02; run esatta sullo SHA handoff, 3 job senza runner/step; prerequisito billing/spending GitHub |
| CA-40 | GIT/CI | BLOCKED | CMD-Q01/Q02/Q03; PR #4 draft e scope remoto corretto, ma finding/CI/live gate impediscono merge, DONE e sync main |

## Matrice test

| Test | Tipo | Esito | Risultato |
|---|---|---|---|
| T-01 | GIT/STATIC | PASS | CMD-S01/S13; governance, branch, dipendenze e diff verificati |
| T-02 | STATIC/SECURITY | PASS | CMD-S02; API/storage installati auditati |
| T-03 | UNIT/SECURITY | PASS | CMD-S01; matrice AppConfig/bootstrap completa |
| T-04 | MANUAL/SECURITY | BLOCKED | CMD-R01; allow-list before/write/after fermata da MFA, nessun write; prerequisito MFA umano |
| T-05 | UNIT/SECURITY | PASS | CMD-S01/S10; callback strict, corrotti, extra, duplicati e replay code-only |
| T-06 | STATIC/ANDROID_EMU | PASS | CMD-S01/S06; manifest e ADB warm canonico reali |
| T-07 | STATIC/IOS_SIM | BLOCKED | static/plist PASS CMD-S01; CMD-S09 `simctl` exit 0 ma harness timeout; prerequisito conferma OS |
| T-08 | UNIT/STATIC | PASS | CMD-S01/S10; fake repository prova Google/PKCE/browser/redirect |
| T-09 | STATIC/UNIT | PASS | CMD-S01/S13; dependency direction e denylist dati/API |
| T-10 | UNIT | PASS | CMD-S01/S10; tabella stati Auth e transizioni |
| T-11 | UNIT | PASS | CMD-S10; restore, stream, expiry recovery e dispose |
| T-12 | UNIT | PASS | CMD-S10/S12; doppio tap, provider Retry, cancel/exchange, restore race e stale result |
| T-13 | UNIT | BLOCKED | unit restore/expiry/recovery SDK PASS CMD-S10; terminate/relaunch secure reale richiede OAuth live/MFA |
| T-14 | UNIT | PASS | CMD-S10; logout, cleanup indipendente/tombstone e nuovo login |
| T-15 | UNIT/STATIC/SECURITY | PASS | CMD-S01/S10/S11; storage CRUD, install, cleanup, failure stream |
| T-16 | UNIT/WIDGET/SECURITY | PASS | CMD-S01; metadata ostili, fallback e avatar locale |
| T-17 | UNIT/SECURITY | PASS | CMD-S01/S11; mapper/redactor senza sentinella |
| T-18 | WIDGET | PASS | CMD-S01; ogni stato Account renderizzato |
| T-19 | WIDGET | PASS | CMD-S01/S04/S07; browsing guest durante stati Auth |
| T-20 | UNIT/WIDGET | PASS | CMD-S01; parità ARB e locale supportati |
| T-21 | WIDGET | PASS | CMD-S01; light/dark, viewport, 200%, semantics e target |
| T-22 | ANDROID_EMU/IOS_SIM | PASS | CMD-S04/S07; guest flow dual-platform |
| T-23 | ANDROID_EMU/IOS_SIM | PASS | CMD-S04/S07; callback fake dual-platform e ritorno Account |
| T-24 | ANDROID_EMU/IOS_SIM | PASS | CMD-S04/S07; invalido/senza sessione, zero crash |
| T-25 | STATIC/SECURITY | PASS | threat model TM-01…TM-30; CMD-S01/S10 |
| T-26 | STATIC/SECURITY/GIT | PASS | CMD-S11/S13/CMD-B01; scan source/diff/bundle/evidence e scope |
| T-27 | STATIC/GIT | PASS | CMD-S01/S10; parser evidence, 12 file, 40/38, tipi/stati/comandi |
| T-28 | STATIC/GIT | PASS | CMD-S01/S13; doctor, shell, pin, governance, architecture e diff |
| T-29 | FORMAT/ANALYZE/UNIT | PASS | CMD-S01/S02; pub/l10n/format/analyze/218 test/coverage/check |
| T-30 | BUILD_ANDROID | PASS | CMD-S01/S03; APK development e staging |
| T-31 | BUILD_IOS | PASS | CMD-S01/S03; iOS Simulator development e staging |
| T-32 | ANDROID_EMU/MANUAL/SECURITY | BLOCKED | subset automatico PASS CMD-S04/S05/S06; 17 passi live dipendono da CMD-R01 |
| T-33 | IOS_SIM/MANUAL/SECURITY | BLOCKED | subset automatico PASS CMD-S07/S08; live dipende da CMD-R01 e CMD-S09 |
| T-34 | ANDROID_EMU/IOS_SIM/MANUAL | BLOCKED | error fake PASS CMD-S01/S04/S07; matrice live non eseguibile con flag false/MFA |
| T-35 | MANUAL/STATIC/SECURITY | FAIL | CMD-Q01; cinque shard completati, quattro finding P2 ancora aperti |
| T-36 | CI | BLOCKED | CMD-Q02; run `30624825908` sullo SHA handoff fermata prima del runner |
| T-37 | GIT | PASS | CMD-Q03; branch/upstream/PR allineati, worktree pulito e zero path TASK-003/004 |
| T-38 | GIT/CI | NOT_RUN | CMD-Q02/Q03; verifica post-merge non eseguita perché review, CI e gate live non sono verdi e il merge resta vietato |
