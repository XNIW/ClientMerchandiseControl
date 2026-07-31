# Commands and results — TASK-011

## Gate locali

| Comando/verifica | Esito | Risultato sanitizzato |
|---|---|---|
| `bash scripts/doctor.sh` | PASS | exit 0; toolchain disponibile |
| test mirati backend/shell | PASS | exit 0 |
| `flutter analyze` | PASS | exit 0, nessuna issue |
| `flutter test --coverage` | PASS | exit 0, 105/105 |
| `bash scripts/check.sh` | PASS | exit 0; test, analyze, build Android/iOS |
| `flutter build apk --debug --dart-define-from-file=…` | PASS | exit 0 |
| `flutter build ios --simulator --debug --dart-define-from-file=…` | PASS | exit 0 |
| `bash -n scripts/*.sh` | PASS | exit 0 |
| action pin scan | PASS | azioni bloccate a SHA |
| governance validator | PASS | un solo task ACTIVE e fase coerente |
| architecture boundary + 5 fixture negative | PASS | baseline e 5/5 fixture |
| `git diff --check` | PASS | exit 0 |
| `flutter pub deps --style=compact` | PASS | exit 0; `http` diretto |
| `flutter pub outdated` | PASS | exit 0 informativo; nessun upgrade |

## Gate security e confinement

| Verifica | Esito | Risultato |
|---|---|---|
| scan query/data API | PASS | nessuna tabella, RPC, Storage o subscription |
| scan secret material | PASS | nessuna credenziale o token tracciato |
| scan URL staging | PASS | nessun URL reale tracciato |
| config/artifact tracking | PASS | file locale ignorato; artifact non tracciati |
| Android network policy | PASS | `INTERNET` nel main; niente cleartext |
| iOS network policy | PASS | nessuna eccezione ATS permissiva |
| write Supabase | PASS | zero |

## CI tecnica

- Run: `30598076908`
- Evento: `workflow_dispatch`
- SHA: `2e646595ad01807be292179adc61013fdd1b2700`
- Stato: `completed / success`
- Job: Quality, Android debug build, iOS Simulator debug build — 3/3 `success`
- Step: tutti `success`
- Annotation: 0/0/0

La CI dello SHA finale resta `NOT_RUN` fino al closeout.

## Gate Fix

| Comando/verifica | Esito | Risultato sanitizzato |
|---|---|---|
| test health | PASS | exit 0, 10/10 |
| test backend + banner | PASS | exit 0, 41/41 |
| `flutter analyze` | PASS | exit 0 |
| `flutter test --coverage` | PASS | exit 0, 108/108 |
| `bash scripts/check.sh` | PASS | exit 0, 108/108 e build debug Android/iOS |
| build staging Android | PASS | exit 0 |
| build staging iOS | PASS | exit 0 |
| smoke bootstrap Android | PASS | exit 0, 1/1 |
| smoke bootstrap iOS | PASS | exit 0, 1/1 |
| screenshot/digest/log/config | PASS | due PNG validi e scan sanitizzati |
| CI `30599648372` | PASS | SHA Fix, 3/3 job, annotation 0/0/0 |

## Matrice CA

| CA | Esito | Evidenza |
|---|---|---|
| CA-05–CA-30 | PASS | Gate unit/widget/static/build/smoke Fix sopra. |
| CA-32 | NOT_RUN | La run è tecnica, non sullo SHA finale. |

## Matrice test

| Test | Esito | Evidenza |
|---|---|---|
| T-03–T-27 | PASS | Test, smoke, build e gate Fix sopra. |
| T-29 | NOT_RUN | Riservato allo SHA finale. |
