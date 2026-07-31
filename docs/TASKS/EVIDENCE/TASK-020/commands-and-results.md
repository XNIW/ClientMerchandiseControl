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
| CMD-D01 | worktree Fix, Android | `flutter test integration_test/auth_callback_flow_test.dart` | FAIL | exit 1; più device disponibili, nessun test avviato | corretto specificando `-d`; CMD-F04/CMD-F07 passano |
| CMD-D02 | worktree Fix, Android | primo `flutter test -d emulator-5554 integration_test/auth_callback_flow_test.dart` | FAIL | terminato manualmente dopo 54 s; exit non conservato | `pumpAndSettle` su progress persistente corretto; CMD-F04 passa |
| CMD-D03 | worktree Fix, Android | tre integration file aggregati senza define staging | FAIL | exit 1; guest/callback 2/2 PASS, readiness rifiuta `development` | errore d'invocazione; CMD-F05 passa con define corretto |
| CMD-D04 | worktree Fix, Android staging | primo readiness con define corretto | FAIL | exit 1; stato transitorio `offline` | host health HTTP 200, airplane mode 0 e connettività emulator PASS; rerun CMD-F05 exit 0 |
| CMD-D05 | Execution, iOS staging | build Android/iOS staging avviate in parallelo sulla stessa directory | FAIL | iOS exit 1 per lock Flutter/ephemeral | contesa del tool, non compilazione; esecuzione isolata e CMD-F03 exit 0 |
| CMD-R01 | Supabase staging, dashboard | aprire Auth URL configuration e provider Google con sessione esistente | BLOCKED | dashboard ferma su MFA; nessun write | prerequisito: intervento umano MFA; vietato a Codex inserirlo |
| CMD-R02 | Supabase staging, probe read-only | health/settings pubblici e authorize PKCE con redirect non seguito | PASS | exit 0; health HTTP 200, provider Google attivo, authorize HTTP 302 al dominio Google | non prova la callback Supabase configurata lato provider |
| CMD-CI01 | handoff precedente `2f25f3f` | `gh run view 30614374801` e `gh run view 30614438284` con JSON job/step/annotation | BLOCKED | comando exit 0; ogni run 3/3 job `failure`, zero step, una annotation/job | billing/spending GitHub prima del runner; prerequisito: ripristino Billing & plans |

I `FAIL` diagnostici restano evidence reali e non vengono trasformati in `PASS`: i
rerun conformi sono identificati separatamente. I comandi con callback usano qui un
placeholder redatto; l'URI esatto è validato dal codice e non viene persistito con
query o code.

## Matrice criteri di accettazione

| CA | Tipo | Esito | Evidence |
|---|---|---|---|
| CA-01 | GIT/STATIC | PASS | CMD-F01/CMD-F13; dipendenze DONE, TASK-020 unico task corrente e diff milestone confinato |
| CA-02 | GIT/STATIC | PASS | CMD-F13; zero path TASK-003/004, catalogo reale, profilo, ordine o pagamento |
| CA-03 | STATIC/SECURITY | PASS | CMD-F02; sorgenti/API GoTrue/Supabase installate e lockfile verificati |
| CA-04 | UNIT/SECURITY | PASS | CMD-F01; matrice config development/staging/production fail-closed |
| CA-05 | UNIT/STATIC/SECURITY | PASS | CMD-F01/CMD-F02; Supabase Google, PKCE, browser esterno e zero `google_sign_in` |
| CA-06 | STATIC/UNIT | PASS | CMD-F01; boundary Auth iniettabili e widget senza import Supabase |
| CA-07 | UNIT | PASS | CMD-F01/CMD-F11; stati dominio e transizioni, inclusi cancel/expiry/storage |
| CA-08 | UNIT/SECURITY | PASS | CMD-F01; validator strict e matrice URI/payload negativa |
| CA-09 | STATIC/BUILD_ANDROID/ANDROID_EMU | PASS | CMD-F01/CMD-F03/CMD-F06; manifest preciso, build e routing warm reali |
| CA-10 | STATIC/BUILD_IOS/IOS_SIM | BLOCKED | plist/build/validator PASS in CMD-F01/F03; CMD-F09 ricezione warm non attestata; causa: conferma OS, prerequisito: interazione sul Mac sbloccato |
| CA-11 | MANUAL/SECURITY | BLOCKED | CMD-R01/R02; provider attivo PASS, callback Supabase lato provider non verificabile oltre MFA; prerequisito: MFA umano |
| CA-12 | MANUAL/SECURITY | BLOCKED | CMD-R01; allow-list before/write/after fermata da MFA; nessun write |
| CA-13 | SECURITY/MANUAL | BLOCKED | CMD-R01; before/after non ottenibili, project ref solo mascherato; prerequisito: accesso dashboard dopo MFA |
| CA-14 | UNIT | PASS | CMD-F01/F11; current session e auth/storage stream alimentano un solo controller |
| CA-15 | UNIT/WIDGET/ANDROID_EMU/IOS_SIM | PASS | CMD-F04/F07; callback fake da Home autentica e seleziona Account su entrambi i target |
| CA-16 | UNIT | PASS | CMD-F11; single-flight, replay, cancel/exchange, restore race e stale verifier |
| CA-17 | UNIT/ANDROID_EMU/IOS_SIM/SECURITY | PASS | CMD-F01/F04/F07; callback invalida/corrotta/duplicata non autentica e non crasha |
| CA-18 | UNIT/ANDROID_EMU/IOS_SIM | BLOCKED | unit restore/expiry/recovery SDK PASS in CMD-F11; terminate/relaunch con sessione reale non eseguibile senza OAuth live/MFA |
| CA-19 | UNIT | PASS | CMD-F11; dispose e future/eventi tardivi testati con compensazione |
| CA-20 | UNIT/WIDGET/ANDROID_EMU/IOS_SIM | PASS | CMD-F01/F04/F07/F11; logout locale, cleanup indipendente, tombstone e nuovo login |
| CA-21 | UNIT/STATIC/SECURITY | PASS | CMD-F01/F10/F11; adapter unico Keychain/Keystore e nessun fallback plaintext |
| CA-22 | UNIT/SECURITY | PASS | CMD-F01/F10; error mapper, source, Git, bundle ed evidence sanitizzati |
| CA-23 | UNIT/WIDGET/SECURITY | PASS | CMD-F01; identity bounded, markup/control/bidi rifiutati e avatar locale |
| CA-24 | STATIC/SECURITY | PASS | CMD-F01/F10/F13; client non autorizzativo, publishable config soltanto e zero API dati vietate |
| CA-25 | WIDGET | PASS | CMD-F01; tutti gli stati Account e azioni renderizzati |
| CA-26 | UNIT/WIDGET | PASS | CMD-F01/F11; mapping stabile, expiry retryable e copy customer-safe |
| CA-27 | WIDGET/ANDROID_EMU/IOS_SIM | PASS | CMD-F04/F07; Home/Catalogo/Carrello navigabili durante authenticating/cancelling/offline |
| CA-28 | WIDGET/ANDROID_EMU/IOS_SIM | PASS | CMD-F01/F04/F07; locale, temi, 200%, semantics, 48 dp, portrait/landscape |
| CA-29 | WIDGET/ANDROID_EMU/IOS_SIM | PASS | CMD-F04/F07; guest e callback fake non regressivi su entrambi i target |
| CA-30 | ANDROID_EMU/MANUAL/SECURITY | BLOCKED | build/fake/native PASS in CMD-F03/F04/F06; live 17 passi fermato da allow-list/MFA, flag false |
| CA-31 | IOS_SIM/MANUAL/SECURITY | BLOCKED | build/fake PASS in CMD-F03/F07; live fermato da MFA e conferma OS CMD-F09, flag false |
| CA-32 | ANDROID_EMU/IOS_SIM/MANUAL | BLOCKED | subset fake/error PASS in CMD-F01/F04/F07; matrice live richiede OAuth remoto abilitabile dopo MFA |
| CA-33 | STATIC/SECURITY | PASS | threat model TM-01…TM-30 aggiornato; CMD-F01/F11 |
| CA-34 | STATIC/GIT | PASS | 12 file esatti; parser in CMD-F01 valida 40 CA, 38 T, tipo/stato/cardinalità |
| CA-35 | STATIC/FORMAT/ANALYZE/UNIT/GIT | PASS | CMD-F01/F02/F12 con comando, output ed exit reali |
| CA-36 | STATIC/SECURITY/GIT | PASS | CMD-F02/F10; dipendenze minime, 336 file puliti e 3/3 fixture respinte |
| CA-37 | BUILD_ANDROID/BUILD_IOS | PASS | CMD-F01 development e CMD-F03 staging, entrambi i target exit 0 |
| CA-38 | MANUAL/STATIC/SECURITY | NOT_RUN | fix tecnico `408f14d` pronto; re-review A–E sul nuovo HEAD non ancora eseguita |
| CA-39 | CI | BLOCKED | CMD-CI01; due run precedenti, 3 job/run senza step; prerequisito billing/spending GitHub |
| CA-40 | GIT/CI | BLOCKED | PR #4 draft aperta; scope locale corretto CMD-F13, ma re-review/CI/live gate impediscono merge, DONE e sync main |

## Matrice test

| Test | Tipo | Esito | Risultato |
|---|---|---|---|
| T-01 | GIT/STATIC | PASS | CMD-F01/F13; governance, branch, dipendenze e diff verificati |
| T-02 | STATIC/SECURITY | PASS | CMD-F02; API/storage installati auditati |
| T-03 | UNIT/SECURITY | PASS | CMD-F01; matrice AppConfig/bootstrap completa |
| T-04 | MANUAL/SECURITY | BLOCKED | CMD-R01; allow-list before/write/after fermata da MFA, nessun write; prerequisito MFA umano |
| T-05 | UNIT/SECURITY | PASS | CMD-F01; callback strict, corrotti, extra, duplicati e replay |
| T-06 | STATIC/ANDROID_EMU | PASS | CMD-F01/F06; manifest e ADB warm canonico reali |
| T-07 | STATIC/IOS_SIM | BLOCKED | static/plist PASS CMD-F01; CMD-F09 `simctl` exit 0 ma harness timeout; prerequisito conferma OS |
| T-08 | UNIT/STATIC | PASS | CMD-F01/F11; fake repository prova Google/PKCE/browser/redirect |
| T-09 | STATIC/UNIT | PASS | CMD-F01/F13; dependency direction e denylist dati/API |
| T-10 | UNIT | PASS | CMD-F01/F11; tabella stati Auth e transizioni |
| T-11 | UNIT | PASS | CMD-F11; restore, stream, expiry recovery e dispose |
| T-12 | UNIT | PASS | CMD-F11; doppio tap, cancel/exchange, restore race e stale result |
| T-13 | UNIT | BLOCKED | unit restore/expiry/recovery SDK PASS CMD-F11; terminate/relaunch secure reale richiede OAuth live/MFA |
| T-14 | UNIT | PASS | CMD-F11; logout, cleanup indipendente/tombstone e nuovo login |
| T-15 | UNIT/STATIC/SECURITY | PASS | CMD-F01/F10/F11; storage CRUD, install, cleanup, failure stream |
| T-16 | UNIT/WIDGET/SECURITY | PASS | CMD-F01; metadata ostili, fallback e avatar locale |
| T-17 | UNIT/SECURITY | PASS | CMD-F01/F10; mapper/redactor senza sentinella |
| T-18 | WIDGET | PASS | CMD-F01; ogni stato Account renderizzato |
| T-19 | WIDGET | PASS | CMD-F01/F04/F07; browsing guest durante stati Auth |
| T-20 | UNIT/WIDGET | PASS | CMD-F01; parità ARB e locale supportati |
| T-21 | WIDGET | PASS | CMD-F01; light/dark, viewport, 200%, semantics e target |
| T-22 | ANDROID_EMU/IOS_SIM | PASS | CMD-F04/F07; guest flow dual-platform |
| T-23 | ANDROID_EMU/IOS_SIM | PASS | CMD-F04/F07; callback fake dual-platform e ritorno Account |
| T-24 | ANDROID_EMU/IOS_SIM | PASS | CMD-F04/F07; invalido/senza sessione, zero crash |
| T-25 | STATIC/SECURITY | PASS | threat model TM-01…TM-30; CMD-F01/F11 |
| T-26 | STATIC/SECURITY/GIT | PASS | CMD-F10/F13; scan source/diff/bundle/evidence e scope |
| T-27 | STATIC/GIT | PASS | parser evidence in CMD-F01; 12 file, 40/38, tipi e stati |
| T-28 | STATIC/GIT | PASS | CMD-F01/F12; doctor, shell, pin, governance, architecture e diff |
| T-29 | FORMAT/ANALYZE/UNIT | PASS | CMD-F01/F02; pub/l10n/format/analyze/214 test/coverage/check |
| T-30 | BUILD_ANDROID | PASS | CMD-F01/F03; APK development e staging |
| T-31 | BUILD_IOS | PASS | CMD-F01/F03; iOS Simulator development e staging |
| T-32 | ANDROID_EMU/MANUAL/SECURITY | BLOCKED | subset automatico PASS CMD-F04/F05/F06; 17 passi live dipendono da CMD-R01 |
| T-33 | IOS_SIM/MANUAL/SECURITY | BLOCKED | subset automatico PASS CMD-F07/F08; live dipende da CMD-R01 e CMD-F09 |
| T-34 | ANDROID_EMU/IOS_SIM/MANUAL | BLOCKED | error fake PASS CMD-F01/F04/F07; matrice live non eseguibile con flag false/MFA |
| T-35 | MANUAL/STATIC/SECURITY | NOT_RUN | re-review A–E sul nuovo HEAD non ancora eseguita |
| T-36 | CI | BLOCKED | CMD-CI01; due run handoff precedente fermati prima del runner; nuovi run dopo push |
| T-37 | GIT | NOT_RUN | commit tecnico PASS e scope locale CMD-F13; tracking/PR remoto da verificare dopo push |
| T-38 | GIT/CI | BLOCKED | merge/sync/main/IDLE vietati finché re-review, CI e gate live restano non verdi |
