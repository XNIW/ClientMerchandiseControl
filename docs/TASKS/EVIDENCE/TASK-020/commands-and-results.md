# Commands and results — TASK-020

## Revision set corrente — Fix 3

- Commit tecnico verificato:
  `5740c835a116af16ab2e7ca6c55c927d180ece90`.
- Handoff Re-review 2 -> Fix 3:
  `7825145f16e0de33725a36470df0ebc20bedfcbe`.
- Base `main` e `origin/main`:
  `40d118eebf78eeabea9e26747adb00053dd875bc`.
- Target:
  Android Emulator `emulator-5554` e iPhone 17 Pro Simulator
  `240F400E-5EFA-486A-9137-FFBBE70F604D`, iOS 26.5.
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
| CMD-B01 | `5740c83`, bundle staging finali ricostruiti da CMD-X05 | `shasum -a 256 build/app/outputs/flutter-apk/app-debug.apk`; `runner_root=build/ios/iphonesimulator/Runner.app; runner_files=$(mktemp); runner_manifest=$(mktemp); find "$runner_root" -type f -print0 > "$runner_files"; LC_ALL=C sort -z "$runner_files" -o "$runner_files"; while IFS= read -r -d '' runner_file; do runner_rel=${runner_file#"$runner_root"/}; runner_hash_line=$(shasum -a 256 "$runner_file"); runner_hash=${runner_hash_line%% *}; printf '%s\0%s\0' "$runner_rel" "$runner_hash" >> "$runner_manifest"; done < "$runner_files"; shasum -a 256 "$runner_manifest"; rm "$runner_files" "$runner_manifest"`; `bash scripts/check-client-security.sh --artifact build/app/outputs/flutter-apk/app-debug.apk`; `bash scripts/check-client-security.sh --artifact build/ios/iphonesimulator/Runner.app`; stessi digest prima/dopo | PASS | exit 0; APK `88af2ad662d7f6f13f14cae00c576072c433cb5d9507f5206bbf688ee0f5ff70`; Runner tree `4332441962a60da4c0544bef6825fb14dc3b6b7e1a16b4e3794da5730fa1d85c`; 548 + 81 = 629 file artifact; digest invariati | build eseguita dopo tutti gli integration test; valori staging non stampati; artifact locali non versionati |
| CMD-D01 | worktree Fix, Android | `flutter test integration_test/auth_callback_flow_test.dart` | FAIL | exit 1; più device disponibili, nessun test avviato | corretto specificando `-d`; CMD-F04/CMD-F07 passano |
| CMD-D02 | worktree Fix, Android | primo `flutter test -d emulator-5554 integration_test/auth_callback_flow_test.dart` | FAIL | terminato manualmente dopo 54 s; exit non conservato | `pumpAndSettle` su progress persistente corretto; CMD-F04 passa |
| CMD-D03 | worktree Fix, Android | tre integration file aggregati senza define staging | FAIL | exit 1; guest/callback 2/2 PASS, readiness rifiuta `development` | errore d'invocazione; CMD-F05 passa con define corretto |
| CMD-D04 | worktree Fix, Android staging | primo readiness con define corretto | FAIL | exit 1; stato transitorio `offline` | host health HTTP 200, airplane mode 0 e connettività emulator PASS; rerun CMD-F05 exit 0 |
| CMD-D05 | Execution, iOS staging | build Android/iOS staging avviate in parallelo sulla stessa directory | FAIL | iOS exit 1 per lock Flutter/ephemeral | contesa del tool, non compilazione; esecuzione isolata e CMD-F03 exit 0 |
| CMD-D06 | candidate Fix 3, host | `flutter test test/core/backend/secure_supabase_auth_storage_test.dart` e `flutter analyze lib/core/backend/secure_supabase_auth_storage.dart test/core/backend/secure_supabase_auth_storage_test.dart test/core/backend/supabase_bootstrap_test.dart test/features/auth/data/supabase_auth_repository_test.dart` avviati in parallelo | FAIL | analyze exit 1 per contesa su `ios/Flutter/ephemeral/Packages/.packages`; storage 16/16 `PASS` | comando analyze rieseguito isolato con exit 0; CMD-X03 è il gate conforme |
| CMD-D07 | `5740c83`, Android warm callback | `adb -s emulator-5554 shell am start -W -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d <callback-canonica-redatta> com.xniw.clientmerchandisecontrol` | FAIL | exit 127, `adb` non presente nel `PATH`; harness rimasto attivo | rerun con path SDK esplicito in CMD-X08, exit 0 e harness 1/1 |
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
| CMD-S10 | `036dcd1`, host | `flutter analyze && flutter test test/core/backend/secure_supabase_auth_storage_test.dart test/features/auth/data/supabase_auth_repository_test.dart test/features/auth/application/auth_controller_test.dart test/governance/task020_evidence_matrix_test.dart` | PASS | exit 0; zero issue; 50/50 | include callback provider identico dopo Retry e referential integrity delle matrici |
| CMD-S11 | `036dcd1`, host | `bash scripts/check-client-security.sh && bash scripts/test-client-security-scan.sh` | PASS | exit 0; 336 file; 16/16 fixture negative respinte e 1/1 positiva accettata | GOCSPX, service-role JWT, symlink Git, PEM, estensioni/path e read failure fail-closed |
| CMD-S13 | `036dcd1`, Git/PR | `git status`, diff check/scope, push e `gh pr view 4` | PASS | worktree pulito prima dell'aggiornamento evidence; branch/upstream/PR head allineati; zero path TASK-003/004 | PR #4 `OPEN/DRAFT`, base `main`, head `036dcd1`, mergeable |
| CMD-S14 | `036dcd1`, GitHub Actions | `gh run view 30624421347` + API job/annotation | BLOCKED | 3/3 job `failure`, `runner_id=0`, zero step, una annotation/job | billing/spending GitHub prima del runner; prerequisito: ripristino Billing & plans |
| CMD-Q01 | tecnico `036dcd1`, handoff `7b4bf15`, cinque shard read-only A–E | re-review di intent, lifecycle, security, UI/native ed evidence/Git/CI con suite mirate | FAIL | 0 P0, 0 P1, 4 P2, 0 P3; suite 39/39, 53/53 e 40/40 `PASS` | esito consolidato `CHANGES_REQUIRED`; scanner path, tombstone e provenance evidence da correggere |
| CMD-Q02 | handoff `7b4bf15`, GitHub Actions | `gh run view 30624825908 --json databaseId,event,headSha,status,conclusion,jobs,url`; API `/actions/runs/30624825908/jobs` e `/check-runs/<job-id>/annotations` | BLOCKED | 3/3 job `failure`, `runner_id=0`, zero step, una annotation/job | billing/spending GitHub prima del runner; prerequisito: ripristino Billing & plans |
| CMD-Q03 | handoff `7b4bf15`, Git/PR | `git status --short --branch`; `git rev-parse HEAD '@{upstream}'`; `gh pr view 4 --json ...`; API paginata `/pulls/4/files` con conteggio e denylist TASK-003/004 | PASS | branch/upstream/PR allineati, worktree pulito, 143 path e zero TASK-003/004 | PR #4 `OPEN/DRAFT`, base `main`, mergeable |
| CMD-X01 | `5740c83`, host + Android/iOS | `bash scripts/check.sh` | PASS | exit 0; 221/221 test; coverage 1802/2247, 80,2%; analyze zero issue; build development Android/iOS; scanner 336 e 22/22 + 1/1; architettura 5/5 | 10 package latest non risolvibili dai constraint; nessun artifact versionato |
| CMD-X02 | `5740c83`, host | `flutter pub deps --style=compact && flutter pub outdated --no-dev-dependencies` | PASS | exit 0; `path_provider 2.1.6` direct e grafo al newest resolvable | promozione da transitive a direct senza upgrade; nessun update opportunistico |
| CMD-X03 | `5740c83`, host | `flutter analyze lib/core/backend/secure_supabase_auth_storage.dart test/core/backend/secure_supabase_auth_storage_test.dart test/core/backend/supabase_bootstrap_test.dart test/features/auth/data/supabase_auth_repository_test.dart && flutter test test/core/backend/secure_supabase_auth_storage_test.dart test/core/backend/supabase_bootstrap_test.dart test/features/auth/data/supabase_auth_repository_test.dart` | PASS | exit 0; zero issue; 33/33 | include journal file reale, restart dopo failure simultanee, target separati, first-install ed errore read fail-closed |
| CMD-X04 | `5740c83`, host | `bash -n scripts/*.sh && bash scripts/check-architecture-boundaries.sh && bash scripts/test-architecture-boundaries.sh && bash scripts/check-client-security.sh && bash scripts/test-client-security-scan.sh` | PASS | exit 0; boundary 5/5; 336 file; fixture security 22/22 negative e 1/1 positiva | scanner copre entrambi i propri path, index/worktree, symlink, enumerazione Git e decoder failure; audit finale 0 P0/P1/P2 |
| CMD-X05 | `5740c83`, Android+iOS staging | verifica SHA/worktree/config ignorata; `flutter clean`; `flutter pub get --enforce-lockfile`; `flutter build apk --debug --dart-define-from-file=config/app_config.staging.local.json`; `flutter build ios --simulator --debug --dart-define-from-file=config/app_config.staging.local.json`; ricontrollo SHA/worktree | PASS | exit 0; APK e Runner.app finali costruiti in sequenza sullo SHA esatto | eseguito dopo tutti gli integration test; file staging ignorato, valori non stampati |
| CMD-X06 | `5740c83`, Android | `flutter test -d emulator-5554 integration_test/app_guest_flow_test.dart integration_test/auth_callback_flow_test.dart` | PASS | exit 0; 2/2 | guest, browsing, callback fake, restore simulato, logout ed errori |
| CMD-X07 | `5740c83`, Android staging | `flutter test -d emulator-5554 integration_test/backend_readiness_smoke_test.dart --dart-define-from-file=config/app_config.staging.local.json` | PASS | exit 0; 1/1; readiness `ready` | health Auth data-free; nessuna sessione customer |
| CMD-X08 | `5740c83`, Android warm callback | `flutter test -d emulator-5554 integration_test/auth_native_callback_delivery_test.dart` + `/Users/minxiang/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell am start -W -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d <callback-canonica-redatta> com.xniw.clientmerchandisecontrol` | PASS | ADB exit 0, `Status: ok`; harness exit 0; 1/1 | query sintetica non persistita; zero exchange; CMD-D07 conserva il primo tentativo non conforme |
| CMD-X09 | `5740c83`, iOS Simulator | `flutter test -d 240F400E-5EFA-486A-9137-FFBBE70F604D integration_test/app_guest_flow_test.dart integration_test/auth_callback_flow_test.dart` | PASS | exit 0; 2/2 | flussi fake equivalenti ad Android |
| CMD-X10 | `5740c83`, iOS staging | `flutter test -d 240F400E-5EFA-486A-9137-FFBBE70F604D integration_test/backend_readiness_smoke_test.dart --dart-define-from-file=config/app_config.staging.local.json` | PASS | exit 0; 1/1; readiness `ready` | health Auth data-free |
| CMD-X11 | `5740c83`, iOS warm callback | `flutter test -d 240F400E-5EFA-486A-9137-FFBBE70F604D integration_test/auth_native_callback_delivery_test.dart` + `xcrun simctl openurl 240F400E-5EFA-486A-9137-FFBBE70F604D <callback-canonica-redatta>` | BLOCKED | `simctl` exit 0; harness exit 1 per timeout 30 s; ispezione locale conferma dialogo “Apri” OS | Mac locked impedisce l'accettazione; screenshot temporaneo eliminato e non versionato |
| CMD-X12 | diff `7825145..5740c83`, tre audit candidate read-only | agenti `task020_fix3_candidate_storage`, `task020_fix3_candidate_scanner`, `task020_fix3_candidate_arch`; confronto finding/codice/test/docs; rerun CMD-X03/X04 e diff-check | PASS | inizialmente 5 P2 consolidati nello stesso scope; tutti corretti; esito finale 0 P0, 0 P1, 0 P2 | non sostituisce la re-review A–E sul revision set di handoff |
| CMD-X13 | `5740c83`, Git/PR | `git fetch origin`; `git rev-parse HEAD`; `git rev-parse '@{upstream}'`; `git rev-parse origin/milestone/011-012-020-authenticated-storefront-foundation`; `git rev-parse main`; `git rev-parse origin/main`; `git status --short --branch`; `gh pr view 4 --json state,isDraft,baseRefName,headRefName,headRefOid,mergeable,url`; `pr_paths=$(gh api --paginate repos/XNIW/ClientMerchandiseControl/pulls/4/files --jq '.[].filename')`; `awk 'END {print NR}' <<< "$pr_paths"`; `if rg -F 'TASK-003' <<< "$pr_paths"; then exit 1; fi`; `if rg -F 'TASK-004' <<< "$pr_paths"; then exit 1; fi` | PASS | SHA locali/upstream/PR allineati; worktree pulito al controllo pre-evidence; 143 path; zero TASK-003/004; `main == origin/main == 40d118e` | PR #4 `OPEN/DRAFT`, base `main`, `MERGEABLE`; il rerun durante la scrittura evidence mostra soltanto i 13 file di handoff attesi |
| CMD-X14 | `5740c83`, GitHub Actions | `gh run view 30626914509 --json databaseId,event,headSha,status,conclusion,jobs,url`; `gh api repos/XNIW/ClientMerchandiseControl/actions/runs/30626914509/jobs`; `gh api repos/XNIW/ClientMerchandiseControl/check-runs/91144201237/annotations`; `gh api repos/XNIW/ClientMerchandiseControl/check-runs/91144201270/annotations`; `gh api repos/XNIW/ClientMerchandiseControl/check-runs/91144201297/annotations` | BLOCKED | run esatta; job iOS `91144201237`, Quality `91144201270`, Android `91144201297`; `runner_id=0`, zero step, una annotation/job | billing/spending GitHub prima del runner; prerequisito: ripristino Billing & plans |
| CMD-X15 | handoff Review 2 -> Fix `7825145`, GitHub Actions | `gh run view 30625584995 --json databaseId,event,headSha,status,conclusion,jobs,url`; `gh api repos/XNIW/ClientMerchandiseControl/actions/runs/30625584995/jobs`; `gh api repos/XNIW/ClientMerchandiseControl/check-runs/91139952621/annotations`; `gh api repos/XNIW/ClientMerchandiseControl/check-runs/91139952622/annotations`; `gh api repos/XNIW/ClientMerchandiseControl/check-runs/91139952766/annotations` | BLOCKED | job Android `91139952621`, iOS `91139952622`, Quality `91139952766`; `runner_id=0`, zero step | una annotation billing/spending per job; nessun codice repository eseguito |
| CMD-X16 | worktree evidence Fix 3 | `bash scripts/check-governance-state.sh && flutter test test/governance/task020_evidence_matrix_test.dart && git diff --check` | PASS | exit 0; governance coerente; parser 1/1; esattamente 12 file evidence, 40 CA e 38 T; zero whitespace error | eseguito dopo l'aggiornamento canonico di matrici e stato |

I `FAIL` diagnostici restano evidence reali e non vengono trasformati in `PASS`: i
rerun conformi sono identificati separatamente. I comandi con callback usano qui un
placeholder redatto; l'URI esatto è validato dal codice e non viene persistito con
query o code.

## Matrice criteri di accettazione

| CA | Tipo | Esito | Evidence |
|---|---|---|---|
| CA-01 | GIT/STATIC | PASS | CMD-X01/X13; dipendenze DONE, TASK-020 unico task corrente e diff milestone confinato |
| CA-02 | GIT/STATIC | PASS | CMD-X13; zero path TASK-003/004, catalogo reale, profilo, ordine o pagamento |
| CA-03 | STATIC/SECURITY | PASS | CMD-X02; sorgenti/API GoTrue/Supabase installate e lockfile verificati |
| CA-04 | UNIT/SECURITY | PASS | CMD-X01; matrice config development/staging/production fail-closed |
| CA-05 | UNIT/STATIC/SECURITY | PASS | CMD-X01/X02; Supabase Google, PKCE, browser esterno e zero `google_sign_in` |
| CA-06 | STATIC/UNIT | PASS | CMD-X01; boundary Auth iniettabili e widget senza import Supabase |
| CA-07 | UNIT | PASS | CMD-X01/X03; stati dominio e transizioni, inclusi cancel/expiry/storage |
| CA-08 | UNIT/SECURITY | PASS | CMD-X01; validator strict e matrice URI/payload negativa |
| CA-09 | STATIC/BUILD_ANDROID/ANDROID_EMU | PASS | CMD-X01/X05/X08; manifest preciso, build e routing warm reali |
| CA-10 | STATIC/BUILD_IOS/IOS_SIM | BLOCKED | plist/build/validator PASS in CMD-X01/X05; CMD-X11 ricezione warm non attestata; causa: conferma OS, prerequisito: interazione sul Mac sbloccato |
| CA-11 | MANUAL/SECURITY | BLOCKED | CMD-R01/R02; provider attivo PASS, callback Supabase lato provider non verificabile oltre MFA; prerequisito: MFA umano |
| CA-12 | MANUAL/SECURITY | BLOCKED | CMD-R01; allow-list before/write/after fermata da MFA; nessun write |
| CA-13 | SECURITY/MANUAL | BLOCKED | CMD-R01; before/after non ottenibili, project ref solo mascherato; prerequisito: accesso dashboard dopo MFA |
| CA-14 | UNIT | PASS | CMD-X01/X03; current session e auth/storage stream alimentano un solo controller |
| CA-15 | UNIT/WIDGET/ANDROID_EMU/IOS_SIM | PASS | CMD-X06/X09; callback fake da Home autentica e seleziona Account su entrambi i target |
| CA-16 | UNIT | PASS | CMD-X01; single-flight, replay code-only, provider Retry, cancel/exchange, restore race e stale verifier |
| CA-17 | UNIT/ANDROID_EMU/IOS_SIM/SECURITY | PASS | CMD-X01/X06/X09; callback invalida/corrotta/duplicata non autentica e non crasha |
| CA-18 | UNIT/ANDROID_EMU/IOS_SIM | BLOCKED | unit restore/expiry/recovery SDK PASS in CMD-X01; terminate/relaunch con sessione reale non eseguibile senza OAuth live/MFA |
| CA-19 | UNIT | PASS | CMD-X01; dispose e future/eventi tardivi testati con compensazione |
| CA-20 | UNIT/WIDGET/ANDROID_EMU/IOS_SIM | PASS | CMD-X01/X03/X06/X09; logout locale, cleanup indipendente, tre marker e nuovo login |
| CA-21 | UNIT/STATIC/SECURITY | PASS | CMD-X01/X03/X04; adapter unico Keychain/Keystore, journal non sensibile e nessun fallback plaintext |
| CA-22 | UNIT/SECURITY | PASS | CMD-X01/X03/X04/CMD-B01; error mapper, source, Git, bundle ed evidence sanitizzati |
| CA-23 | UNIT/WIDGET/SECURITY | PASS | CMD-X01; identity bounded, markup/control/bidi rifiutati e avatar locale |
| CA-24 | STATIC/SECURITY | PASS | CMD-X01/X04/X13; client non autorizzativo, publishable config soltanto e zero API dati vietate |
| CA-25 | WIDGET | PASS | CMD-X01; tutti gli stati Account e azioni renderizzati |
| CA-26 | UNIT/WIDGET | PASS | CMD-X01; mapping stabile, expiry retryable e copy customer-safe |
| CA-27 | WIDGET/ANDROID_EMU/IOS_SIM | PASS | CMD-X06/X09; Home/Catalogo/Carrello navigabili durante authenticating/cancelling/offline |
| CA-28 | WIDGET/ANDROID_EMU/IOS_SIM | PASS | CMD-X01/X06/X09; locale, temi, 200%, semantics, 48 dp, portrait/landscape |
| CA-29 | WIDGET/ANDROID_EMU/IOS_SIM | PASS | CMD-X06/X09; guest e callback fake non regressivi su entrambi i target |
| CA-30 | ANDROID_EMU/MANUAL/SECURITY | BLOCKED | build/fake/readiness/native PASS in CMD-X05/X06/X07/X08; live 17 passi fermato da allow-list/MFA, flag false |
| CA-31 | IOS_SIM/MANUAL/SECURITY | BLOCKED | build/fake/readiness PASS in CMD-X05/X09/X10; live fermato da MFA e conferma OS CMD-X11, flag false |
| CA-32 | ANDROID_EMU/IOS_SIM/MANUAL | BLOCKED | subset fake/error PASS in CMD-X01/X06/X09; matrice live richiede OAuth remoto abilitabile dopo MFA |
| CA-33 | STATIC/SECURITY | PASS | threat model TM-01…TM-30 aggiornato; CMD-X01/X03/X12 |
| CA-34 | STATIC/GIT | PASS | CMD-X01; 12 file esatti e parser valida 40 CA, 38 T, tipo/stato/cardinalità/comando |
| CA-35 | STATIC/FORMAT/ANALYZE/UNIT/GIT | PASS | CMD-X01/X02/X13 con comando, output ed exit reali |
| CA-36 | STATIC/SECURITY/GIT | PASS | CMD-X02/X04/CMD-B01; dipendenze minime, 336 file puliti, 22/22 fixture negative e 1/1 positiva |
| CA-37 | BUILD_ANDROID/BUILD_IOS | PASS | CMD-X01 development e CMD-X05 staging, entrambi i target exit 0 |
| CA-38 | MANUAL/STATIC/SECURITY | NOT_RUN | CMD-X12; audit candidate finali 0 P0/P1/P2, ma la re-review A–E sullo SHA tecnico/handoff corrente non è ancora eseguita |
| CA-39 | CI | BLOCKED | CMD-X14; run esatta sullo SHA tecnico, 3 job senza runner/step; prerequisito billing/spending GitHub |
| CA-40 | GIT/CI | BLOCKED | CMD-X12/X13/X14; PR #4 draft e scope remoto corretto, ma re-review/CI/live gate impediscono merge, DONE e sync main |

## Matrice test

| Test | Tipo | Esito | Risultato |
|---|---|---|---|
| T-01 | GIT/STATIC | PASS | CMD-X01/X13; governance, branch, dipendenze e diff verificati |
| T-02 | STATIC/SECURITY | PASS | CMD-X02; API/storage installati auditati |
| T-03 | UNIT/SECURITY | PASS | CMD-X01; matrice AppConfig/bootstrap completa |
| T-04 | MANUAL/SECURITY | BLOCKED | CMD-R01; allow-list before/write/after fermata da MFA, nessun write; prerequisito MFA umano |
| T-05 | UNIT/SECURITY | PASS | CMD-X01; callback strict, corrotti, extra, duplicati e replay code-only |
| T-06 | STATIC/ANDROID_EMU | PASS | CMD-X01/X08; manifest e ADB warm canonico reali |
| T-07 | STATIC/IOS_SIM | BLOCKED | static/plist PASS CMD-X01; CMD-X11 `simctl` exit 0 ma harness timeout; prerequisito conferma OS |
| T-08 | UNIT/STATIC | PASS | CMD-X01; fake repository prova Google/PKCE/browser/redirect |
| T-09 | STATIC/UNIT | PASS | CMD-X01/X13; dependency direction e denylist dati/API |
| T-10 | UNIT | PASS | CMD-X01; tabella stati Auth e transizioni |
| T-11 | UNIT | PASS | CMD-X01; restore, stream, expiry recovery e dispose |
| T-12 | UNIT | PASS | CMD-X01; doppio tap, provider Retry, cancel/exchange, restore race e stale result |
| T-13 | UNIT | BLOCKED | unit restore/expiry/recovery SDK PASS CMD-X01; terminate/relaunch secure reale richiede OAuth live/MFA |
| T-14 | UNIT | PASS | CMD-X01/X03; logout, cleanup indipendente, journal e nuovo login |
| T-15 | UNIT/STATIC/SECURITY | PASS | CMD-X01/X03/X04; storage CRUD, first install, cleanup a tre marker e failure stream |
| T-16 | UNIT/WIDGET/SECURITY | PASS | CMD-X01; metadata ostili, fallback e avatar locale |
| T-17 | UNIT/SECURITY | PASS | CMD-X01/X04; mapper/redactor e scanner source/artifact senza sentinella |
| T-18 | WIDGET | PASS | CMD-X01; ogni stato Account renderizzato |
| T-19 | WIDGET | PASS | CMD-X01/X06/X09; browsing guest durante stati Auth |
| T-20 | UNIT/WIDGET | PASS | CMD-X01; parità ARB e locale supportati |
| T-21 | WIDGET | PASS | CMD-X01; light/dark, viewport, 200%, semantics e target |
| T-22 | ANDROID_EMU/IOS_SIM | PASS | CMD-X06/X09; guest flow dual-platform |
| T-23 | ANDROID_EMU/IOS_SIM | PASS | CMD-X06/X09; callback fake dual-platform e ritorno Account |
| T-24 | ANDROID_EMU/IOS_SIM | PASS | CMD-X06/X09; invalido/senza sessione, zero crash |
| T-25 | STATIC/SECURITY | PASS | threat model TM-01…TM-30; CMD-X01/X03/X12 |
| T-26 | STATIC/SECURITY/GIT | PASS | CMD-X04/X13/CMD-B01; scan source/index/worktree/bundle/evidence e scope |
| T-27 | STATIC/GIT | PASS | CMD-X16; parser evidence, 12 file, 40/38, tipi/stati/comandi |
| T-28 | STATIC/GIT | PASS | CMD-X01/X13; doctor, shell, pin, governance, architecture e diff |
| T-29 | FORMAT/ANALYZE/UNIT | PASS | CMD-X01/X02; pub/l10n/format/analyze/221 test/coverage/check |
| T-30 | BUILD_ANDROID | PASS | CMD-X01/X05; APK development e staging |
| T-31 | BUILD_IOS | PASS | CMD-X01/X05; iOS Simulator development e staging |
| T-32 | ANDROID_EMU/MANUAL/SECURITY | BLOCKED | subset automatico PASS CMD-X06/X07/X08; 17 passi live dipendono da CMD-R01 |
| T-33 | IOS_SIM/MANUAL/SECURITY | BLOCKED | subset automatico PASS CMD-X09/X10; live dipende da CMD-R01 e CMD-X11 |
| T-34 | ANDROID_EMU/IOS_SIM/MANUAL | BLOCKED | error fake PASS CMD-X01/X06/X09; matrice live non eseguibile con flag false/MFA |
| T-35 | MANUAL/STATIC/SECURITY | NOT_RUN | CMD-X12; audit candidate 0 P0/P1/P2, re-review formale sul revision set di handoff ancora da eseguire |
| T-36 | CI | BLOCKED | CMD-X14; run `30626914509` sullo SHA tecnico fermata prima del runner |
| T-37 | GIT | PASS | CMD-X13; branch/upstream/PR allineati, worktree pulito e zero path TASK-003/004 |
| T-38 | GIT/CI | NOT_RUN | CMD-X13/X14; verifica post-merge non eseguita perché re-review, CI e gate live non sono verdi e il merge resta vietato |
