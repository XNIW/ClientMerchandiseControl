# Runtime smoke — TASK-012

## Revisione verificata

- Commit runtime:
  `14cdc5175b9a596c8a4237e6796fefe3e7beda63`
- Profilo: development offline, senza configurazione remota
- Test: `integration_test/app_guest_flow_test.dart`
- Dati/remoto: zero query, zero sessioni e zero write

## Comandi finali

### Android

```text
flutter test integration_test/app_guest_flow_test.dart \
  -d emulator-5554 --reporter expanded
```

- target: Android Emulator 15 / API 35, arm64;
- build/install integration debug completati;
- test: `00:17 +1: All tests passed!`;
- exit 0, 1/1 `PASS`.

### iOS

```text
flutter test integration_test/app_guest_flow_test.dart \
  -d <IOS_SIMULATOR_ID> --reporter expanded
```

- target: iPhone 17 Pro Simulator, iOS 26.5;
- Xcode integration debug build completata;
- test: `00:13 +1: All tests passed!`;
- exit 0, 1/1 `PASS`.

Entrambi i processi sono terminati. L'identificatore iOS completo non è necessario
nelle evidence persistenti.

## Copertura reale

Il test avvia l'entrypoint reale e verifica:

- cold launch development offline e shell usabile;
- Home rifinita, ricerca e CTA verso Catalogo;
- quattro tab, selected index, subtree e scroll Home preservati;
- Carrello vuoto e CTA reale;
- Account guest e Google fail-closed;
- back da Account a Home;
- light/dark, text scale 200% e portrait/landscape;
- heading, label, azioni Semantics e target 48 dp;
- assenza di immagini e valori commerciali sintetici;
- nessuna eccezione Flutter e processo vivo a fine flusso.

## Failure intermedi

Quattro run Android intermedi hanno restituito `FAIL` prima del run finale:

1. label Semantics assente sul controllo Google disabilitato;
2. confronto scroll eseguito dopo un `ensureVisible` che alterava il valore atteso;
3. clamp reale dello scroll Home quando il banner shell cambiava l'altezza del viewport;
4. `SemanticsHandle` rilasciato nel teardown anziché prima delle verifiche finali.

Ogni causa è stata corretta e coperta da regressione. Il terzo failure ha portato il
banner nel contenuto Home, mantenendo stabile il viewport delle branch. Dettagli in
`development-findings.md`.

## Screenshot sanitizzati

Dopo gli smoke sono state costruite e avviate le app debug normali sullo stesso commit,
separate dagli integration runner. Sono stati acquisiti:

- Home Android dark, landscape, testo sistema 200%;
- Account guest Android nelle stesse condizioni;
- Home iOS light, portrait, locale italiana del simulatore.

Le tre immagini sono state ispezionate visivamente. Non mostrano URL, key, callback,
token, account, email, user ID, notifiche o dati commerciali. Un primo screenshot
Android catturato mentre era ancora installato il target integration mostrava soltanto
lo splash Flutter: è stato rifiutato e sovrascritto dal runtime normale.

## Log

- Android: log limitato al PID app normale, 0 marker crash/error e 0 marker
  secret/config;
- iOS: log limitato al PID della normal app, 0 marker crash/error e 0 marker
  secret/config;
- un errore orientamento appartenente a un precedente PID integration non è stato
  attribuito alla normal app; il run integration finale ha verificato realmente
  portrait e landscape con exit 0.

## Matrice

| Criteri/test | Esito | Evidenza |
|---|---|---|
| CA-05–CA-09, CA-17, CA-19 | PASS | Flusso guest e CTA dual-platform. |
| CA-29–CA-34 | PASS | Tema, 200%, Semantics, target, orientamento e processo vivo. |
| CA-36 | PASS | Smoke 1/1 e screenshot su entrambe le piattaforme. |
| T-26, T-30, T-31 | PASS | Comandi e artifact sopra. |

## Smoke del ciclo FIX

- Commit:
  `3acbc42d9abd5bffe0230d3b9bca27baf345cfea`
- Android Emulator 15/API 35:
  `flutter test integration_test/app_guest_flow_test.dart -d emulator-5554
  --reporter expanded`; 1/1 `PASS`, exit 0.
- iPhone 17 Pro Simulator/iOS 26.5:
  `flutter test integration_test/app_guest_flow_test.dart -d <IOS_SIMULATOR_ID>
  --reporter expanded`; 1/1 `PASS`, exit 0.
- Normal app Android: build/install/launch e dump UIAutomator Catalogo `PASS`;
  ricerca, Filter, Sort e spiegazione hanno quattro nodi e bounds distinti.

Le modifiche FIX non cambiano copy, layout visuale o dati mostrati. Gli screenshot
Execution restano artifact della revisione tecnica originaria; la regressione impattata
è coperta sul commit FIX da test Semantics e dump nativo. Entrambi i processi
integration sono terminati.
