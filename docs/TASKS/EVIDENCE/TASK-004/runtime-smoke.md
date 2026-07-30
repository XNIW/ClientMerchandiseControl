# Runtime smoke — TASK-004

## Procedura

Test eseguito in development senza `--dart-define`, usando
`integration_test/app_shell_smoke_test.dart`.

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

## Risultati

| Piattaforma | Target sanitizzato | Esito | Exit |
|---|---|---|---|
| Android | Emulator Android 15 API 35 | PASS | 0 |
| iOS | iPhone 17 Pro Simulator iOS 26.5 | PASS | 0 |

Android ha costruito/installato l'APK e completato 1/1 smoke. iOS ha costruito con
Xcode e completato 1/1 smoke. Entrambi hanno attestato
`developmentNetworkingDisabled=PASS` e `processAlive=PASS`.

Non è stato eseguito OAuth o uno smoke di rete staging: appartengono rispettivamente a
TASK-020 e TASK-011.
