# TASK-002 — Runtime smoke Android e iOS

## Matrice

| Piattaforma | Device | Runtime | Comando finale | Esito |
|---|---|---|---|---|
| Android | `Medium_Phone_API_35`, `emulator-5554`, arm64 | Android 15 / API 35 | `flutter test integration_test/app_shell_smoke_test.dart -d emulator-5554 --reporter expanded` | `PASS`, exit `0`, 1/1 |
| iOS | iPhone 17 Pro, UDID `240F400E…604D` | iOS Simulator 26.5 | `flutter test integration_test/app_shell_smoke_test.dart -d <IOS_SIM_UDID> --reporter expanded` | `PASS`, exit `0`, 1/1 |

I run finali sono stati eseguiti dopo `bash scripts/check.sh` sul commit tecnico
`ec599758948a303b0862935fcf9ae9003a64aa00`.

## Scenari osservati dal test

- cold launch dell'entry point reale `main()` in development non configurato;
- Home, `NavigationBar` e banner offline presenti;
- `Supabase.instance` non inizializzato;
- portrait osservato dopo il launch;
- label, azione tap, selected state e touch target di tutte le destinazioni;
- Home, Catalog, Cart e Account visitate;
- persistenza del subtree Home e back da Account verso Home;
- light e dark theme effettivamente risolti;
- text scale 200% su tutte le destinazioni;
- rotazione reale in landscape e nuova visita di tutte le destinazioni;
- nessun valore commerciale numerico o immagine prodotto;
- nessuna eccezione Flutter e processo vivo fino al teardown.

## Log sanitizzati

Non sono conservati log completi.

- Android, solo PID applicativo:
  `{"fatal_or_anr":0,"flutter_errors":0,"backend_client_markers":0}`;
- iOS, solo processo `Runner` e ultimi cinque minuti:
  `{"crash_or_uncaught_markers":0,"backend_client_markers":0}`.

Il log globale dell'emulatore Android contiene traffico dei servizi Google e dati locali
del device non pertinenti; è stato escluso dall'evidence e non versionato. Nessun
risultato di rete del sistema operativo è attribuito all'app.

## Evidenza visiva

Le immagini sotto `screenshots/` sono diagnostica visuale sanitizzata. Il gate runtime
deriva dai run automatici sopra, non dagli screenshot isolati. Il manifest separato
registra hash, dimensioni e scenario di ciascuna immagine.

## Re-run dopo Fix

I gate runtime sono stati ripetuti dopo le correzioni di review:

- Android, tentativo 1: `FAIL` prima dell'avvio del test,
  `INSTALL_FAILED_INSUFFICIENT_STORAGE`;
- remediation: rimossa soltanto cache ricreabile dell'emulatore con
  `pm trim-caches 2G`, spazio disponibile da 636 MiB a 1,1 GiB;
- Android, retry: `PASS`, exit `0`, 1/1;
- iOS Simulator: `PASS`, exit `0`, 1/1.

Il primo esito Android non è attribuito al codice applicativo e non viene occultato; il
retry è stato eseguito soltanto dopo aver risolto la causa ambientale.
