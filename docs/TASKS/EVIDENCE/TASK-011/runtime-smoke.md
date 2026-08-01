# Runtime smoke — TASK-011 Fix

## Revisione verificata

- Commit runtime:
  `8621606d03d06b70f2a421c985c63b96ee3ef47a`
- Profilo: staging con file locale ignorato
- Test: `integration_test/backend_readiness_smoke_test.dart`
- Accesso remoto: solo `GET /auth/v1/health`, nessun dato commerciale

## Comandi finali e output pertinente

### Android

```bash
flutter test integration_test/backend_readiness_smoke_test.dart \
  -d emulator-5554 \
  --dart-define-from-file=config/app_config.staging.local.json
```

- target: `sdk gphone64 arm64`, Android 15 / API 35 Emulator;
- APK integration debug compilato e installato;
- test: `00:15 +1: All tests passed!`;
- processo finale: exit 0, 1/1 `PASS`.

### iOS

```bash
flutter test integration_test/backend_readiness_smoke_test.dart \
  -d 240F400E-5EFA-486A-9137-FFBBE70F604D \
  --dart-define-from-file=config/app_config.staging.local.json
```

- target: iPhone 17 Pro Simulator, iOS 26.5;
- Xcode integration debug build completata;
- test: `00:30 +1: All tests passed!`;
- processo finale: exit 0, 1/1 `PASS`.

I comandi sono stati eseguiti in parallelo sullo stesso SHA e sono entrambi terminati;
nessun processo di test è rimasto attivo.

## Copertura della procedura

Lo smoke:

- chiama il vero `bootstrap()` e usa il `ProviderScope` montato dall'entrypoint;
- osserva Home, shell, NavigationBar e banner `initializing` prima del health;
- attende `ready` dal probe staging reale con timeout di 30 secondi;
- verifica SDK Supabase inizializzato, sessione cliente assente e Google disabilitato;
- tocca realmente Catalogo, verifica la schermata e `selectedIndex == 1`;
- non crea container/app alternativi e non invoca direttamente `retry()`;
- termina senza eccezioni e registra soltanto `reportData` sanitizzato.

## Screenshot sanitizzati

Dopo gli smoke, l'app è stata rilanciata in modo persistente sullo stesso commit:

```bash
flutter run -d emulator-5554 --debug \
  --dart-define-from-file=config/app_config.staging.local.json
<ANDROID_SDK>/platform-tools/adb -s emulator-5554 shell input tap 405 2215
<ANDROID_SDK>/platform-tools/adb -s emulator-5554 exec-out screencap -p \
  > docs/TASKS/EVIDENCE/TASK-011/screenshots/android-staging-catalog.png

flutter run -d 240F400E-5EFA-486A-9137-FFBBE70F604D --debug \
  --dart-define-from-file=config/app_config.staging.local.json
xcrun simctl io 240F400E-5EFA-486A-9137-FFBBE70F604D screenshot \
  docs/TASKS/EVIDENCE/TASK-011/screenshots/ios-staging-home.png
```

Ispezione visiva reale:

- Android mostra Catalogo selezionato in dark mode;
- iOS mostra Home in light mode;
- nessun banner di errore: entrambi gli avvii hanno raggiunto readiness;
- non compaiono URL, key, callback, token, account, user ID o dati commerciali;
- dimensioni, byte e digest sono in `screenshots/manifest.md`.

Un primo tentativo di screenshot eseguito dopo la chiusura automatica degli integration
runner mostrava le Home dei simulatori: è stato ispezionato, rifiutato e sovrascritto;
non è presente nelle evidence.

## Log e secret scan

- Android app PID log scan: `PASS`; nessun pattern token/key/service role.
- iOS `Runner` log scan: `PASS`; nessun pattern token/key/service role.
- I tre match `refresh_token` nel log Android globale appartenevano a un servizio di
  sistema con PID diverso, non al processo app.
- Scan runtime/documenti per chiavi concrete: `PASS`; i soli fixture fake restano nei
  test config.
- Config staging locale: ignorata e non tracciata, `PASS`.

## Risultato finale

| Piattaforma | Target | Esito | Exit |
|---|---|---|---|
| Android | Emulator Android 15 / API 35 | PASS | 0 |
| iOS | iPhone 17 Pro Simulator iOS 26.5 | PASS | 0 |

## Matrice CA

| CA | Esito | Evidenza |
|---|---|---|
| CA-20 | PASS | Shell visibile durante `initializing` e dopo `ready`. |
| CA-22 | PASS | Report, log e screenshot sanitizzati. |
| CA-26 | PASS | Health Auth staging reale valido. |
| CA-27 | PASS | Bootstrap/interazione Android 1/1. |
| CA-28 | PASS | Bootstrap/interazione iOS 1/1. |

## Matrice test

| Test | Esito | Evidenza |
|---|---|---|
| T-22 | PASS | Probe staging data-free. |
| T-23 | PASS | Android cold start, readiness e navigazione. |
| T-24 | PASS | iOS cold start, readiness e navigazione. |
