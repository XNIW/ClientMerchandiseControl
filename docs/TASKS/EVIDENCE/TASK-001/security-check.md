# Security check

## Esito

`PASS`.

## Controlli eseguiti

- pattern per token GitHub, JWT a tre segmenti, private key e chiavi live: nessun match;
- file `.env`, certificati, provisioning profile e keystore versionabili: nessuno;
- `config/*.local.json`: nessun file presente;
- URL production hardcoded: nessuno;
- build artifact e coverage: ignorati, non versionati;
- prerelease nel lockfile: nessuno;
- `DEVELOPMENT_TEAM` rimosso dal progetto iOS;
- publishable key usata soltanto come nome di configurazione; nessun valore reale.

`ios/Flutter/ephemeral/flutter_native_integration.env` è un file generato e ignorato da
`ios/.gitignore`; non è un file di configurazione applicativa e non è versionato.

I match testuali `service_role`/`secret key` sono esclusivamente divieti nella
documentazione o scanner, non credenziali.

Gitleaks non era installato e non è stato aggiunto come dipendenza permanente; il controllo
mirato richiesto è stato eseguito con `rg`, `find`, `git check-ignore` e ispezione Git.
