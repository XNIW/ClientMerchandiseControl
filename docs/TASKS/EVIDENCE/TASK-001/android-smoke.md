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
