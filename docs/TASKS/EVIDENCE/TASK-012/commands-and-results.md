# Commands and results — TASK-012

## Gate locali finali

| Comando/verifica | Esito | Risultato sanitizzato |
|---|---|---|
| `scripts/doctor.sh` | PASS | exit 0; Flutter 3.44.8, Dart 3.12.2, toolchain Android/iOS disponibile |
| `flutter pub get --enforce-lockfile` | PASS | exit 0; lockfile rispettato |
| `flutter pub deps --style=compact` | PASS | exit 0; grafo ispezionato |
| `flutter pub outdated` | PASS | exit 0 informativo; 7 package segnalati, 2 vincoli diretti non aggiornati |
| `flutter gen-l10n` | PASS | exit 0 |
| `dart format --output=none --set-exit-if-changed .` | PASS | exit 0; 60 file, 0 modificati |
| `flutter analyze` | PASS | exit 0; nessuna issue |
| test mirati TASK-012 | PASS | exit 0; 60/60 |
| `flutter test --coverage` | PASS | exit 0; 139/139 |
| `bash -n scripts/*.sh` | PASS | exit 0 |
| `bash scripts/check-action-pins.sh` | PASS | 1 workflow verificato |
| `bash scripts/check-governance-state.sh` | PASS | unico task TASK-012, fase Execution |
| boundary architetturali | PASS | baseline positiva e 5/5 fixture negative respinte |
| `bash scripts/check.sh` | PASS | exit 0; 139/139, analyze e build debug Android/iOS |
| `flutter build apk --debug` | PASS | exit 0 |
| `flutter build ios --simulator --debug` | PASS | exit 0 |
| `git diff --check` | PASS | exit 0 |

`flutter pub outdated` non autorizza un major upgrade Riverpod o un cambio dei vincoli:
non sono stati modificati `pubspec.yaml` o `pubspec.lock`.

## Runtime

| Verifica | Esito | Risultato |
|---|---|---|
| smoke Android Emulator | PASS | exit 0; 1/1 |
| smoke iOS Simulator | PASS | exit 0; 1/1 |
| screenshot Android | PASS | Home e Account, dark, landscape, testo sistema 200% |
| screenshot iOS | PASS | Home, light, portrait, copy italiana |
| log Android process-scoped | PASS | 0 crash/error, 0 secret/config marker |
| log iOS normal app process-scoped | PASS | 0 crash/error, 0 secret/config marker |

Comandi, scenari e failure intermedi sono dettagliati in `runtime-smoke.md` e
`development-findings.md`.

## Security e confinement

| Verifica | Esito | Risultato |
|---|---|---|
| query/RPC/Storage/Functions nel diff UI | PASS | zero |
| secret/token privilegiati nel diff | PASS | zero |
| config locale tracciata | PASS | zero |
| build/coverage/log candidati a Git | PASS | zero |
| dipendenze e target nativi | PASS | diff vuoto |
| repository esterni | PASS | nessuna scrittura |
| Supabase staging/production | PASS | nessuna scrittura TASK-012 |

## CI tecnica

- Run: `30604787251`
- Evento: `workflow_dispatch`
- SHA: `14cdc5175b9a596c8a4237e6796fefe3e7beda63`
- Stato al primo snapshot: `in_progress`
- Esito finale: `completed / success`
- Job: Quality, Android debug build e iOS Simulator debug build — 3/3 `success`
- Step: tutti `success`
- Annotation: 0/0/0

La CI richiesta da CA-39 resta distinta e sarà eseguita sullo SHA finale revisionato.
