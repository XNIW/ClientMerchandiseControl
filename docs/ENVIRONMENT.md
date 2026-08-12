# Ambiente

## Inventario iniziale sanitizzato

- Workspace iniziale: vuoto, senza `.git`.
- Sistema: macOS 26.6, arm64.
- Xcode: 26.6 (build 17F113).
- Git: 2.50.1.
- GitHub CLI: 2.96.0, autenticato come `XNIW`.
- Java: OpenJDK 21.0.10.
- Android Studio: presente.
- Android SDK: presente in directory utente; platform 31, 34, 35 e 36 rilevate.
- Android AVD: due configurazioni esistenti, inclusa API 35 arm64.
- iOS Simulator: runtime 26.1, 26.2, 26.4 e 26.5 presenti.
- Flutter iniziale: non installato.
- CocoaPods iniziale: non installato.

## Toolchain TASK-001

Flutter 3.44.8 stable è stato installato dal bundle ufficiale macOS arm64 con verifica
SHA-256. CocoaPods 1.17.0 e gli strumenti Android richiesti sono presenti; tutte le
licenze Android risultano accettate.

`scripts/doctor.sh` risolve Flutter dal `PATH` o da `FLUTTER_ROOT`, con fallback
portabile a `$HOME/develop/flutter`. Il controllo finale termina con exit `0` e
`No issues found`.

Nessun path personale completo deve essere copiato negli artefatti di evidence.

## Uso della toolchain nel workflow

`CODEX_EXECUTOR` e `CODEX_FIXER` registrano versione, comando ed exit code dei gate
eseguiti. `CODEX_REVIEWER` e `CODEX_RE_REVIEWER` non riusano tali claim come prova:
risolvono la toolchain sul proprio ambiente e rieseguono le verifiche obbligatorie. Un
tool assente o un processo non terminato è `BLOCKED` o `NOT_RUN` con motivazione, mai un
`PASS` inferito.

## Runtime Auth mobile

TASK-020 usa le versioni bloccate `supabase_flutter 2.16.0`, `supabase 2.14.0`,
`gotrue 2.26.0`, `app_links 7.2.1` e `flutter_secure_storage 10.3.1`.
`shared_preferences 2.5.5`, già transitive dello SDK, è dichiarata direttamente solo
per il marker booleano non sensibile della nuova installazione; non contiene sessione o
verifier.

La configurazione development non accetta backend, callback, OAuth o Storefront e non
inizializza Supabase. Staging richiede i sei input di `CMC-CLIENT-CONFIG 1.2.0`, incluso
lo slug pubblico `STOREFRONT_SHOP_SLUG`, il sentinel HTTPS `.invalid` e
`GOOGLE_AUTH_ENABLED=false`. Anche production mantiene obbligatoriamente il flag
`false` e non eredita valori staging. Il runtime distribuibile rifiuta Google OAuth
finché non esiste un dominio HTTPS posseduto e verificato.

Il file locale staging resta ignorato:

```bash
flutter run --dart-define-from-file=config/app_config.staging.local.json
flutter test integration_test/auth_callback_flow_test.dart -d <DEVICE>
```

`AUTH_REDIRECT_URI` usa esclusivamente
`https://clientmerchandisecontrol.invalid/auth-callback/`: è un sentinel non
instradabile, non un dominio posseduto né una callback registrata. Nessun profilo
staging/production può attivare Google. Una futura riattivazione richiede App
Links/Universal Links verificati e una nuova decisione autorizzata. URL, publishable
key, project ref completo, account di test, code, token e sessioni non appartengono a
documentazione, Git o evidence.

Android disabilita backup applicativo per impedire il ripristino incoerente del
materiale cifrato. iOS usa Keychain non sincronizzato e this-device; il marker nel
container applicativo elimina le sole chiavi Auth note al primo avvio dopo
reinstallazione. Un errore dello storage è fail-closed.
