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

## Re-run post-fix — 2026-07-30

- **Tipo**: `IOS_SIM`
- **Esito**: `PASS`
- **Commit tecnico**: `3f0d992a7c1b6e9f9291e7617b53c0cf6c3f8734`
- **Ambiente**: iPhone 17 Simulator, iOS 26.5
- **Configurazione app**: locale italiano, development offline, nessun dart-define

### Procedura post-fix

1. Avvio Simulator standard e impostazione locale italiana; nessun device fisico usato.
2. Installazione di `Runner.app`, verifica bundle e avvio con PID osservato.
3. Ispezione UI e accessibilità: Home, banner offline, SafeArea, heading e quattro tab
   univoci.
4. Interazione reale Home -> Catalogo -> Carrello -> Account -> Home tramite UI del
   Simulator; contenuto e tab selezionata verificati a ogni passaggio.
5. Rotazione landscape, ispezione visiva e ripristino portrait.
6. Verifica processo vivo e 311 righe di log: nessun crash, fatal, eccezione, assert,
   overflow, Supabase o richiesta backend.
7. Verifica `Info.plist`: bundle corretto, `en`/`es`/`it`/`zh-Hans`, target
   `iphonesimulator`; firma ad hoc e nessun team/profilo production.
8. Terminazione app e shutdown del Simulator.

Le occorrenze di `assertion`/`XPCErrors` nei sottosistemi di lifecycle sono state
ispezionate e non rappresentano assert o errori dell'app. Il Dart VM service è locale.

### Screenshot post-fix

- `ios-review-home.png`
- `ios-review-catalog.png`
- `ios-review-account.png`
- `ios-review-landscape.png`
