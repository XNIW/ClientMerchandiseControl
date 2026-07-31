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

| CA | Esito | Evidence |
|---|---|---|
| CA-01 | PASS | dipendenze DONE, branch milestone e TASK-020 unico ACTIVE |
| CA-02 | PASS | diff confinato ad Auth/Account/bootstrap/native/l10n/test/docs |
| CA-03 | PASS | API/changelog/source package e lockfile verificati |
| CA-04 | PASS | matrice config development/staging/production fail-closed |
| CA-05 | PASS | Supabase Google, PKCE, browser esterno; zero `google_sign_in` |
| CA-06 | PASS | boundary iniettabili; widget senza import Supabase |
| CA-07 | PASS | tutti gli stati dominio e transizioni testati |
| CA-08 | PASS | validator strict e matrice URI/payload negativa |
| CA-09 | PASS | manifest source/merged e routing Android preciso |
| CA-10 | PASS | plist minimo, forwarding iOS e validator Dart |
| CA-11 | PASS | Google attivo; authorize PKCE porta al dominio Google |
| CA-12 | BLOCKED | allow-list non leggibile/modificabile senza MFA |
| CA-13 | BLOCKED | before/after impossibile; nessun write remoto |
| CA-14 | PASS | current session e auth stream alimentano un solo controller |
| CA-15 | PASS | callback fake autentica e porta ad Account su Android/iOS |
| CA-16 | PASS | single-flight, replay, concorrenza e stale result testati |
| CA-17 | PASS | invalido/corrotto/duplicato non autentica e non crasha |
| CA-18 | PASS | restore/refresh/expiry/revoca simulati e fake device |
| CA-19 | PASS | dispose e late event/future testati |
| CA-20 | PASS | logout locale, errore remoto e login successivo testati |
| CA-21 | PASS | adapter unico Keychain/Keystore e nessun fallback plaintext |
| CA-22 | PASS | mapper/log/bundle/Git/evidence scan sanitizzato |
| CA-23 | PASS | identity bounded, bidi/control/markup reject, avatar locale |
| CA-24 | PASS | client non autorizzativo; zero API/dati fuori scope |
| CA-25 | PASS | tutti gli stati Account, azioni e disable testati |
| CA-26 | PASS | error mapping e copy localizzata customer-safe |
| CA-27 | PASS | Home/Catalogo/Carrello guest-accessible |
| CA-28 | PASS | locale, temi, 200%, semantics, 48 dp e reflow testati |
| CA-29 | PASS | guest e callback fake non regressivi su entrambi i target |
| CA-30 | BLOCKED | live Android dipende da allow-list/MFA; flag false |
| CA-31 | BLOCKED | live iOS dipende da allow-list e conferma OS; flag false |
| CA-32 | BLOCKED | matrice live dipende da OAuth remoto abilitabile |
| CA-33 | PASS | threat model TM-01…TM-30 completo |
| CA-34 | PASS | 12 file evidence; 40 righe CA e 38 righe T |
| CA-35 | PASS | tutti i gate repository obbligatori con exit reali |
| CA-36 | PASS | dipendenze minime e scan mirato senza secret/artifact |
| CA-37 | PASS | build development e staging Android/iOS reali |
| CA-38 | NOT_RUN | review A–E attende SHA tecnico |
| CA-39 | NOT_RUN | CI attende SHA revisionato |
| CA-40 | NOT_RUN | PR/merge/main sync/IDLE non ancora eseguiti |

## Matrice test

| Test | Esito | Risultato |
|---|---|---|
| T-01 | PASS | governance, branch, dipendenze e diff verificati |
| T-02 | PASS | audit package/API/storage completato |
| T-03 | PASS | matrice AppConfig e bootstrap completa |
| T-04 | BLOCKED | allow-list before/write/after fermata da MFA |
| T-05 | PASS | callback strict, corrotti, extra, duplicati e replay |
| T-06 | PASS | manifest e ADB canonico/varianti |
| T-07 | PASS | plist e `simctl` scheme/varianti; validator host/path |
| T-08 | PASS | fake repository prova Google/PKCE/browser/redirect |
| T-09 | PASS | dependency direction e denylist dati/API |
| T-10 | PASS | tabella completa degli stati Auth |
| T-11 | PASS | restore, auth stream, expiry e dispose |
| T-12 | PASS | doppio tap, duplicati, race e stale result |
| T-13 | PASS | cold restore, resume, refresh, expiry/revoca |
| T-14 | PASS | logout successo/offline/pulizia/nuovo login |
| T-15 | PASS | storage CRUD, first install, allow-list e failure |
| T-16 | PASS | metadata ostili, fallback e avatar locale |
| T-17 | PASS | mapper/redactor senza riemissione dei sentinella |
| T-18 | PASS | ogni stato Account renderizzato |
| T-19 | PASS | browsing guest durante stati Auth |
| T-20 | PASS | parità ARB e locale supportati |
| T-21 | PASS | temi, viewport, 200%, semantics e target |
| T-22 | PASS | guest flow Android e iOS |
| T-23 | PASS | callback fake Android e iOS |
| T-24 | PASS | invalido/ripetuto/senza sessione, zero crash |
| T-25 | PASS | threat model verificato contro scope prescritto |
| T-26 | PASS | scan source/diff/bundle/log/evidence |
| T-27 | PASS | cardinalità evidence e stati ammessi |
| T-28 | PASS | doctor, shell, pin, governance e architecture |
| T-29 | PASS | pub/l10n/format/analyze/coverage/check |
| T-30 | PASS | APK development e staging |
| T-31 | PASS | iOS Simulator development e staging |
| T-32 | BLOCKED | 17 passi live Android dipendono da allow-list |
| T-33 | BLOCKED | 17 passi live iOS dipendono da allow-list/dialogo OS |
| T-34 | BLOCKED | smoke errori live non eseguibile con flag false |
| T-35 | NOT_RUN | review A–E attende SHA tecnico |
| T-36 | NOT_RUN | CI attende SHA revisionato |
| T-37 | NOT_RUN | commit/PR scope e closeout ancora da eseguire |
| T-38 | NOT_RUN | merge e riallineamento main ancora da eseguire |
