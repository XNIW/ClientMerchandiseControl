# iOS Simulator smoke

- **Tipo**: `IOS_SIM`
- **Esito**: `PASS`
- **Ambiente**: iPhone 17 Pro, iOS 26.5
- **Configurazione app**: development senza backend e senza dart-define

## Procedura

1. Boot Simulator e attesa stato terminale.
2. `flutter run --debug --no-resident` — exit `0`.
3. Screenshot e accessibilità: Home visibile, quattro tab presenti.
4. Tap reale su `Catalogo` tramite controllo accessibilità macOS.
5. Nuovo stato accessibilità: tab 2 selezionata e contenuto Catalogo visibile.
6. Query log recente del processo Runner: nessun marker fatal/crash.
7. Ispezione visiva screenshot: nessun overflow evidente.

Il Simulator era configurato in italiano e ha selezionato correttamente la localizzazione
italiana.

## Screenshot

- `ios-home.png`
- `ios-catalog.png`

Gli screenshot sono evidenza visiva complementare; il PASS deriva anche da avvio, albero
accessibilità aggiornato e navigazione reale.
