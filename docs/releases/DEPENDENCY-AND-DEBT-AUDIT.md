# Dependency and technical-debt audit — TASK-038

Audit bounded del 2026-08-17; nessun upgrade indiscriminato.

## Dependency disposition

Inventario: 163 package risolti, 17 package diretti esterni più Flutter e
`flutter_localizations` SDK.

| Package | Current | Resolvable/latest osservato | Security/store need | Breaking risk | Disposition |
|---|---:|---:|---|---|---|
| flutter_riverpod | 2.6.1 | 2.6.1 / 3.4.2 | nessuna incompatibilità provata | alta, major API | keep |
| flutter_secure_storage | 10.3.1 | 11.0.0 / 11.0.0 | nessuna incompatibilità provata | alta, native migration | keep |
| go_router | 17.3.0 | 17.5.0 / 17.5.0 | nessuna | media, routing/deep link | keep nel train |
| intl | 0.20.2 | 0.20.2 / 0.20.3 | vincolata dal Flutter SDK corrente | bassa ma non risolvibile | keep |
| share_plus | 13.2.1 | 13.3.0 / 13.3.0 | nessuna | bassa/media native | keep nel train |
| sqlite3 | 3.5.0 | 3.5.1 / 3.5.1 | nessuna advisory rilevata dal tooling locale | bassa | keep; rivalutare separatamente |
| supabase_flutter | 2.16.0 | 2.17.2 / 2.17.2 | nessun build/store blocker | media, auth/session | keep nel train |

Le altre dipendenze dirette risultano compatibili col lock e col toolchain corrente.
TASK-038 non modifica `pubspec.yaml` o `pubspec.lock`: asset/legal readiness non è una
ragione sufficiente per introdurre rischio routing, auth, storage o database.

## Debt scan

Lo scan bounded copre `TODO`, `FIXME`, `HACK`, skip/suppression, debug helper,
localhost, test fixture e feature flag obsolete nei path release. Le sole sentinel
`NOT_CONFIGURED` Maps sono intenzionali e fail-closed in Gradle/xcconfig/native
bootstrap. I riferimenti localhost nel parser delivery sono denylist security, non una
destinazione runtime.

Non è stata rimossa alcuna suppression giustificata da capability esterna. Gli asset
marketing finali, i valori legal/support e le credenziali provider sono activation gate
espliciti, non debt nascosto.
