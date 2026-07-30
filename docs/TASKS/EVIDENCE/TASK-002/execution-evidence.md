# TASK-002 — Evidence di Execution

## Revisione verificata

- Base merged: `f6bd88263fe8369c9ececa38367f629f3d1a929f`
- Commit tecnico verificato:
  `ec599758948a303b0862935fcf9ae9003a64aa00`
- Branch: `task/002-product-scope-branding-design-system`
- Flutter: `3.44.8`
- Dart: `3.12.2`
- Host: macOS 26.6 arm64
- Timestamp ultimo gate locale: `2026-07-30T15:05:10-04:00`

Il commit di handoff aggiunge soltanto governance ed evidence a questo albero tecnico.
La review deve comunque verificare il proprio SHA, senza assumere questi risultati.

## Deliverable

- product scope, MVP, utenti/jobs, journey, UX e content/localization definiti;
- brand registry esplicito con public/legal/marketing identity non verificati;
- ADR-007 e ADR-008 accettati;
- token per spacing, radii, sizes, breakpoint e motion;
- `ColorScheme` Material 3 e `StorefrontSemanticColors` light/dark;
- `StorefrontPage`, `StorefrontStatusBanner` e placeholder tokenizzati;
- shell a quattro destinazioni preservata con copy cliente localizzato;
- test brand, l10n, token, tema, contrasto, widget, viewport e Semantics;
- smoke Flutter automatico reale Android/iOS sull'entry point `main()`.

## Gate finali

| Gate | Comando | Esito | Sintesi |
|---|---|---|---|
| Aggregato | `bash scripts/check.sh` | `PASS` / exit `0` | lock, l10n, format, analyze, 59 test, APK e Runner iOS |
| Format | incluso nel gate aggregato | `PASS` | 40 file, 0 modificati |
| Analyze | incluso nel gate aggregato | `PASS` | nessuna issue |
| Unit/widget | `flutter test --coverage` nel gate | `PASS` | 59/59 |
| Android build | `flutter build apk --debug` nel gate | `PASS` | APK debug creato |
| iOS build | `flutter build ios --simulator --debug` nel gate | `PASS` | Runner Simulator creato |
| Android smoke | `flutter test integration_test/app_shell_smoke_test.dart -d emulator-5554 --reporter expanded` | `PASS` / exit `0` | 1/1, build/install/launch/interazioni/teardown |
| iOS smoke | `flutter test integration_test/app_shell_smoke_test.dart -d <IOS_SIM_UDID> --reporter expanded` | `PASS` / exit `0` | 1/1, Xcode build/launch/interazioni/teardown |
| Dependency graph | `flutter pub deps --style=compact` | `PASS` / exit `0` | unica direct dev addition: Flutter SDK `integration_test` |
| Outdated audit | `flutter pub outdated` | `PASS` / exit `0` | dev dependencies aggiornate; nessun upgrade eseguito |
| Diff whitespace | `git diff --check` | `PASS` / exit `0` | nessun errore |
| Security diff | Codex Security scan `40f261c3-5a0d-4e50-8603-3c4ab42cc838` | `PASS` | 15/15 receipt, 0 finding |
| Repository esterni | fingerprint iniziale/finale | `PASS` | 4/4 invariati, zero write |
| Identifier/target | `aapt2`, `plutil`, `rg`, diff baseline | `PASS` | package e soli target Android/iOS invariati |

Hash artifact locali, non versionati:

- `build/app/outputs/flutter-apk/app-debug.apk`:
  `b1017e87bcbd543cb1542553d957870f3f3f292d67a444d85bbb473967d53c9f`;
- inventario file `build/ios/iphonesimulator/Runner.app`:
  `8b7056c4dfbedd0331cbbe1391169ac3699c426178b59fb4d73b3481877b2da0`.

## Check statici TASK-002

| Controllo | Esito | Evidenza |
|---|---|---|
| Raw color/metriche nei feature/shared widget | `PASS` | `rg` su `lib/features`, `lib/core/widgets` e widget foundation: 0 match dopo allowlist dei token |
| Fake commerce | `PASS` | nessun prodotto/prezzo/stock numerico o immagine commerciale; `price` è soltanto un ruolo cromatico semantico |
| Networking nuovo | `PASS` | nessun nuovo import/sink HTTP, socket, query Supabase, RPC, storage o realtime in `lib/` |
| Secret e URL production | `PASS` | scan delle sole righe aggiunte: 0 firma secret, private key, service role o endpoint production |
| Development offline | `PASS` | unit test, integration smoke e log sanitizzati confermano Supabase non inizializzato |
| Dipendenze | `PASS` | `integration_test` è SDK-only e dev-only; nessuna direct runtime dependency cambia |

Per gli scan `rg`, exit `1` significa zero match ed è il risultato atteso; non è stato
convertito in un `PASS` senza interpretazione. Il report security indipendente conserva
le receipt full-file.

## Identità tecnica invariata

- package Dart: `client_merchandise_control`;
- Android namespace/applicationId:
  `com.xniw.clientmerchandisecontrol`;
- iOS bundle identifier:
  `com.xniw.clientmerchandisecontrol`;
- APK: min SDK 24, target SDK 36;
- directory target applicative presenti: `android/` e `ios/`;
- nessun target web, macOS, Windows o Linux aggiunto.

La sola modifica nativa nel range TASK-002 è `developmentRegion = es` nel progetto
iOS, coerente con la localizzazione primaria e senza variazione di target o identifier.

## Tentativi e warning

- Un primo comando con `--device-timeout` ha restituito exit `64`: l'opzione non è
  supportata da `flutter test`; il comando finale corretto è quello registrato sopra.
- Due iterazioni iOS del test hanno rilevato, prima del commit tecnico, una query
  Semantics troppo generica e un handle Semantics dismesso in ritardo. Entrambe sono
  state corrette; i run finali Android/iOS sono `PASS`.
- `xcrun simctl ... log erase` ha restituito exit `1` (`Operation not permitted`);
  il fallback ha usato una finestra temporale e un filtro sul processo `Runner`.
- `aapt2` non era nel `PATH`; il controllo identifier è stato rieseguito con il path
  SDK esplicito ed è `PASS`.
- `flutter pub get` e `flutter pub outdated` segnalano versioni major più recenti per
  package già vincolati. Non sono upgrade richiesti né finding di TASK-002.

Non restano gate Execution obbligatori in `FAIL`, `BLOCKED` o `NOT_RUN`.
