# Android Emulator smoke

- **Tipo**: `ANDROID_EMU`
- **Esito**: `PASS`
- **Ambiente**: Medium Phone API 35, arm64, 1080x2400
- **Configurazione app**: development senza backend e senza dart-define

## Procedura

1. Avvio AVD esistente senza wipe e attesa `sys.boot_completed=1`.
2. `flutter run --debug --no-resident` — exit `0`.
3. Verifica app in foreground con package `com.xniw.clientmerchandisecontrol`.
4. Dump accessibilità: Home e quattro tab presenti.
5. Tap reale sulla seconda destinazione.
6. Dump accessibilità: Catalog selezionato e contenuto Catalog visibile.
7. Processo app ancora presente; nessun marker `FATAL EXCEPTION`/`Unhandled Exception`.
8. Ispezione visiva screenshot: nessun overflow evidente.

Il device era configurato in inglese; la UI ha usato correttamente la localizzazione
inglese supportata. Il fallback spagnolo è verificato dai widget test.

## Screenshot

- `android-home.png`
- `android-catalog.png`

Gli screenshot sono evidenza visiva complementare; il PASS deriva anche da avvio, stato
foreground, dump accessibilità e navigazione.

## Re-run post-fix — 2026-07-30

- **Tipo**: `ANDROID_EMU`
- **Esito**: `PASS`
- **Commit tecnico**: `3f0d992a7c1b6e9f9291e7617b53c0cf6c3f8734`
- **Ambiente**: AVD `Medium_Phone_API_35`, API 35, headless, 1080x2400, density 420
- **Configurazione app**: development offline, nessun dart-define o backend

### Procedura post-fix

1. Avvio AVD headless in sessione controllata e attesa boot terminale: 19,25 s.
2. Install APK, `pm clear` e cold launch del package
   `com.xniw.clientmerchandisecontrol`: exit `0`, `TotalTime 5630 ms`.
3. Verifica package/versione, processo vivo, Home e banner offline.
4. Navigazione reale Home -> Catalog -> Cart -> Account -> Home con dump accessibilità.
5. Da Account, back di sistema reale -> Home.
6. Rotazione landscape, ispezione visiva e ritorno portrait.
7. Verifica logcat e `dumpsys activity exit-info`: nessun crash, ANR, fatal, assert,
   overflow o richiesta backend.
8. Arresto pulito dell'emulator: exit `0`.

La sola riga rete è il Dart VM service locale di debug; il warning HWUI di fallback
formato non è un errore applicativo.

### Screenshot post-fix

- `android-review-home.png`
- `android-review-catalog.png`
- `android-review-account.png`
- `android-review-landscape.png`

Due tentativi GUI precedenti non hanno prodotto un device terminale; sono registrati
come `BLOCKED`/`FAIL` nei comandi della review e non sono usati come evidenza del `PASS`.
