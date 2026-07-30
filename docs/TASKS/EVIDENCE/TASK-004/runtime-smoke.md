# Runtime smoke — TASK-004

## Revisione Fix verificata

- Commit tecnico:
  `bccb6f55a9ceaf46d946c95fc79b5b7d3ae02055`
- Profilo: development senza `--dart-define`
- Test: `integration_test/app_shell_smoke_test.dart`
- Stato del codice durante i rerun: HEAD sul commit tecnico; nessuna modifica Dart
  successiva

## Comandi finali e output pertinente

### Android

```bash
flutter test integration_test/app_shell_smoke_test.dart -d emulator-5554
```

- target sanitizzato: Android Emulator, Android 15 / API 35;
- build APK completata;
- un primo install ha segnalato spazio interno insufficiente; Flutter ha rimosso
  automaticamente la versione precedente e reinstallato lo stesso APK;
- test: `00:13 +1: All tests passed!`;
- processo finale: exit 0, 1/1 `PASS`.

### iOS

```bash
flutter test integration_test/app_shell_smoke_test.dart -d "iPhone 17 Pro"
```

- target sanitizzato: iPhone 17 Pro Simulator, iOS 26.5;
- Xcode build completata;
- test: `00:09 +1: All tests passed!`;
- processo finale: exit 0, 1/1 `PASS`.

Il warning Android è una deviazione del primo tentativo di install nello stesso comando,
non un gate lasciato fallito: il retry automatico e il processo complessivo sono
terminati exit 0. Nessun processo di verifica è rimasto attivo.

## Copertura della procedura

La procedura:

- avvia realmente l'app;
- verifica Home, NavigationBar e banner development debug;
- verifica che `Supabase.instance` non sia inizializzata;
- naviga Home/Catalogo/Carrello/Account;
- verifica back e persistenza tab;
- alterna tema light/dark;
- applica testo 200%;
- prova portrait/landscape;
- verifica semantics e assenza di dati commerciali fittizi.

## Screenshot sanitizzati

Le schermate sono state catturate dopo un lancio development `--no-resident` sullo
stesso commit tecnico:

```bash
flutter run -d emulator-5554 --debug --no-resident
<ANDROID_SDK>/platform-tools/adb -s emulator-5554 exec-out screencap -p > docs/TASKS/EVIDENCE/TASK-004/screenshots/android-development-home.png
flutter run -d "iPhone 17 Pro" --debug --no-resident
xcrun simctl io booted screenshot docs/TASKS/EVIDENCE/TASK-004/screenshots/ios-development-home.png
```

Ispezione visiva reale:

- entrambe mostrano la Home e il banner development offline;
- nessuna mostra URL, key, callback, token, account, dato cliente o dato commerciale;
- Android è in dark mode e iOS in light mode, coerentemente con il tema di sistema;
- manifest, dimensioni e digest sono in `screenshots/manifest.md`.

## Risultato finale

| Piattaforma | Target sanitizzato | Esito | Exit |
|---|---|---|---|
| Android | Emulator Android 15 API 35 | PASS | 0 |
| iOS | iPhone 17 Pro Simulator iOS 26.5 | PASS | 0 |

Il test verifica direttamente che `Supabase.instance` non sia inizializzata e pubblica
nel proprio `reportData` `developmentNetworkingDisabled=PASS` e
`processAlive=PASS`.

Non è stato eseguito OAuth o uno smoke di rete staging: appartengono rispettivamente a
TASK-020 e TASK-011.
