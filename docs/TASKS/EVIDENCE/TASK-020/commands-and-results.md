# Commands and results — TASK-020

## Gate eseguiti

| Comando/verifica | Esito | Exit/evidence pertinente |
|---|---|---|
| `bash scripts/doctor.sh` | PASS | exit 0, nessun issue |
| `bash -n` sugli script versionati | PASS | exit 0 |
| action pin check | PASS | 1 workflow verificato |
| governance check | PASS | TASK-020 unico `ACTIVE`, fase `EXECUTION` |
| architecture boundaries | PASS | boundary e 5/5 fixture negative |
| `flutter pub get --enforce-lockfile` | PASS | exit 0 |
| `flutter pub deps` / `flutter pub outdated` | PASS | grafo risolto; versioni dirette correnti compatibili |
| `flutter gen-l10n` | PASS | exit 0 |
| `dart format --output=none --set-exit-if-changed .` | PASS | 84 file, zero modifiche |
| `flutter analyze` | PASS | zero issue |
| `flutter test --coverage` | PASS | 192/192; 1567/2009 linee, 78,0% |
| `bash scripts/check.sh` | PASS | exit 0; include test e build development |
| `git diff --check` | PASS | exit 0 |
| `flutter build apk --debug` staging | PASS | exit 0 |
| build iOS staging parallela | FAIL | exit 1, lock Flutter/ephemeral condiviso |
| `flutter build ios --simulator --debug` staging isolata | PASS | exit 0 |
| tre integration test Android | PASS | 3/3, exit 0 |
| tre integration test iOS | PASS | 3/3, exit 0 |
| callback warm nativo Android + ADB | PASS | event stream e validator, exit 0 |
| callback warm nativo iOS + `simctl` | BLOCKED | conferma OS pendente; Mac locked |
| merged manifest / compiled plist | PASS | handler minimi e backup/deep-link flags coerenti |
| scan sorgenti/diff/bundle | PASS | zero secret-shaped value e zero runtime log Auth |
| Supabase discovery/settings/authorize | PASS | staging sano, Google attivo, 302 Google |
| Supabase redirect allow-list | BLOCKED | dashboard MFA; nessuna API point-update |

Il `FAIL` della build iOS parallela è registrato come tentativo reale: non era un
errore di compilazione, ma una contesa prodotta da due processi Flutter sulla stessa
directory. Il rerun isolato sullo stesso worktree è terminato con exit 0.

## Matrice criteri di accettazione

| CA | Tipo | Esito | Evidence |
|---|---|---|---|
| CA-01 | GIT/STATIC | PASS | dipendenze DONE, branch milestone e TASK-020 unico ACTIVE |
| CA-02 | GIT/STATIC | PASS | diff confinato ad Auth/Account/bootstrap/native/l10n/test/docs |
| CA-03 | STATIC/SECURITY | PASS | API/changelog/source package e lockfile verificati |
| CA-04 | UNIT/SECURITY | PASS | matrice config development/staging/production fail-closed |
| CA-05 | UNIT/STATIC/SECURITY | PASS | Supabase Google, PKCE, browser esterno; zero `google_sign_in` |
| CA-06 | STATIC/UNIT | PASS | boundary iniettabili; widget senza import Supabase |
| CA-07 | UNIT | PASS | tutti gli stati dominio e transizioni testati |
| CA-08 | UNIT/SECURITY | PASS | validator strict e matrice URI/payload negativa |
| CA-09 | STATIC/BUILD_ANDROID/ANDROID_EMU | PASS | manifest source/merged e routing Android preciso |
| CA-10 | STATIC/BUILD_IOS/IOS_SIM | PASS | plist minimo, forwarding iOS e validator Dart |
| CA-11 | MANUAL/SECURITY | BLOCKED | Google attivo; callback provider non verificabile oltre MFA |
| CA-12 | MANUAL/SECURITY | BLOCKED | allow-list non leggibile/modificabile senza MFA |
| CA-13 | SECURITY/MANUAL | BLOCKED | before/after impossibile; nessun write remoto |
| CA-14 | UNIT | PASS | current session e auth stream alimentano un solo controller |
| CA-15 | UNIT/WIDGET/ANDROID_EMU/IOS_SIM | PASS | callback fake autentica e porta ad Account su Android/iOS |
| CA-16 | UNIT | PASS | single-flight, replay, concorrenza e stale result testati |
| CA-17 | UNIT/ANDROID_EMU/IOS_SIM/SECURITY | PASS | invalido/corrotto/duplicato non autentica e non crasha |
| CA-18 | UNIT/ANDROID_EMU/IOS_SIM | BLOCKED | unit expiry/restore PASS; terminate/relaunch live bloccato |
| CA-19 | UNIT | PASS | dispose e late event/future testati |
| CA-20 | UNIT/WIDGET/ANDROID_EMU/IOS_SIM | PASS | logout locale, errore remoto e login successivo testati |
| CA-21 | UNIT/STATIC/SECURITY | PASS | adapter unico Keychain/Keystore e nessun fallback plaintext |
| CA-22 | UNIT/SECURITY | PASS | mapper/log/bundle/Git/evidence scan sanitizzato |
| CA-23 | UNIT/WIDGET/SECURITY | PASS | identity bounded, bidi/control/markup reject, avatar locale |
| CA-24 | STATIC/SECURITY | PASS | client non autorizzativo; zero API/dati fuori scope |
| CA-25 | WIDGET | PASS | tutti gli stati Account, azioni e disable testati |
| CA-26 | UNIT/WIDGET | PASS | error mapping e copy localizzata customer-safe |
| CA-27 | WIDGET/ANDROID_EMU/IOS_SIM | PASS | Home/Catalogo/Carrello guest-accessible |
| CA-28 | WIDGET/ANDROID_EMU/IOS_SIM | PASS | locale, temi, 200%, semantics, 48 dp e reflow testati |
| CA-29 | WIDGET/ANDROID_EMU/IOS_SIM | PASS | guest e callback fake non regressivi su entrambi i target |
| CA-30 | ANDROID_EMU/MANUAL/SECURITY | BLOCKED | live Android dipende da allow-list/MFA; flag false |
| CA-31 | IOS_SIM/MANUAL/SECURITY | BLOCKED | live iOS dipende da allow-list e conferma OS; flag false |
| CA-32 | ANDROID_EMU/IOS_SIM/MANUAL | BLOCKED | matrice live dipende da OAuth remoto abilitabile |
| CA-33 | STATIC/SECURITY | PASS | threat model TM-01…TM-30 completo |
| CA-34 | STATIC/GIT | PASS | 12 file evidence; 40 righe CA e 38 righe T |
| CA-35 | STATIC/FORMAT/ANALYZE/UNIT/GIT | PASS | tutti i gate repository obbligatori con exit reali |
| CA-36 | STATIC/SECURITY/GIT | PASS | dipendenze minime e scan mirato senza secret/artifact |
| CA-37 | BUILD_ANDROID/BUILD_IOS | PASS | build development e staging Android/iOS reali |
| CA-38 | MANUAL/STATIC/SECURITY | FAIL | review A–E completata; 1 P1 e 18 P2 consolidati aperti |
| CA-39 | CI | BLOCKED | run 30614374801/30614438284, zero step; CI_EXTERNAL billing |
| CA-40 | GIT/CI | FAIL | PR #4 draft esiste ma confinement da correggere; merge vietato |

## Matrice test

| Test | Tipo | Esito | Risultato |
|---|---|---|---|
| T-01 | GIT/STATIC | PASS | governance, branch, dipendenze e diff verificati |
| T-02 | STATIC/SECURITY | PASS | audit package/API/storage completato |
| T-03 | UNIT/SECURITY | PASS | matrice AppConfig e bootstrap completa |
| T-04 | MANUAL/SECURITY | BLOCKED | allow-list before/write/after fermata da MFA |
| T-05 | UNIT/SECURITY | PASS | callback strict, corrotti, extra, duplicati e replay |
| T-06 | STATIC/ANDROID_EMU | PASS | manifest e ADB canonico/varianti |
| T-07 | STATIC/IOS_SIM | BLOCKED | plist PASS; callback warm `simctl` fermato dal dialogo OS |
| T-08 | UNIT/STATIC | PASS | fake repository prova Google/PKCE/browser/redirect |
| T-09 | STATIC/UNIT | PASS | dependency direction e denylist dati/API |
| T-10 | UNIT | PASS | tabella completa degli stati Auth |
| T-11 | UNIT | PASS | restore, auth stream, expiry e dispose |
| T-12 | UNIT | PASS | doppio tap, duplicati, race e stale result |
| T-13 | UNIT | BLOCKED | unit restore/expiry PASS; lifecycle processo reale non eseguito |
| T-14 | UNIT | PASS | logout successo/offline/pulizia/nuovo login |
| T-15 | UNIT/STATIC/SECURITY | PASS | storage CRUD, first install, allow-list e failure |
| T-16 | UNIT/WIDGET/SECURITY | PASS | metadata ostili, fallback e avatar locale |
| T-17 | UNIT/SECURITY | PASS | mapper/redactor senza riemissione dei sentinella |
| T-18 | WIDGET | PASS | ogni stato Account renderizzato |
| T-19 | WIDGET | PASS | browsing guest durante stati Auth |
| T-20 | UNIT/WIDGET | PASS | parità ARB e locale supportati |
| T-21 | WIDGET | PASS | temi, viewport, 200%, semantics e target |
| T-22 | ANDROID_EMU/IOS_SIM | PASS | guest flow Android e iOS |
| T-23 | ANDROID_EMU/IOS_SIM | PASS | callback fake Android e iOS |
| T-24 | ANDROID_EMU/IOS_SIM | PASS | invalido/ripetuto/senza sessione, zero crash |
| T-25 | STATIC/SECURITY | PASS | threat model verificato contro scope prescritto |
| T-26 | STATIC/SECURITY/GIT | PASS | scan source/diff/bundle/log/evidence |
| T-27 | STATIC/GIT | PASS | cardinalità evidence, tipi e stati ammessi |
| T-28 | STATIC/GIT | PASS | doctor, shell, pin, governance e architecture |
| T-29 | FORMAT/ANALYZE/UNIT | PASS | pub/l10n/format/analyze/coverage/check |
| T-30 | BUILD_ANDROID | PASS | APK development e staging |
| T-31 | BUILD_IOS | PASS | iOS Simulator development e staging |
| T-32 | ANDROID_EMU/MANUAL/SECURITY | BLOCKED | 17 passi live Android dipendono da allow-list |
| T-33 | IOS_SIM/MANUAL/SECURITY | BLOCKED | 17 passi live iOS dipendono da allow-list/dialogo OS |
| T-34 | ANDROID_EMU/IOS_SIM/MANUAL | BLOCKED | smoke errori live non eseguibile con flag false |
| T-35 | MANUAL/STATIC/SECURITY | FAIL | cinque reviewer indipendenti; finding tecnici/documentali aperti |
| T-36 | CI | BLOCKED | due run sullo SHA handoff fermati prima del runner |
| T-37 | GIT | FAIL | commit/tracking PASS; PR draft include tre path fuori confinement |
| T-38 | GIT/CI | NOT_RUN | merge e riallineamento main ancora da eseguire |
