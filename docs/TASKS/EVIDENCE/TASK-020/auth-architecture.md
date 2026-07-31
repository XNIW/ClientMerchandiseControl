# Auth architecture — TASK-020

## Strategia

Il flusso autorizzato è:

```text
Account UI
  -> AuthController
  -> AuthRepository
  -> SupabaseAuthRepository
  -> Supabase Auth Google + PKCE nel browser esterno
  -> custom-scheme callback
  -> validator esatto
  -> exchange code
  -> onAuthStateChange
  -> AuthController
  -> Account authenticated
```

Il bool restituito da `signInWithOAuth` indica soltanto che il browser è stato
lanciato. Non è prova di login. La sessione autenticata deriva esclusivamente da
callback valida e stream/current session SDK.

## API reale

La versione installata espone:

```dart
Future<bool> signInWithOAuth(
  OAuthProvider provider, {
  String? redirectTo,
  String? scopes,
  LaunchMode authScreenLaunchMode = LaunchMode.platformDefault,
  Map<String, String>? queryParams,
});
```

Altre API usate: `currentSession`, `onAuthStateChange`,
`exchangeCodeForSession`, `signOut(scope: SignOutScope.local)`. PKCE è il default ma
verrà dichiarato esplicitamente; il client non inventa un secondo parametro `state`.

## Piano file

```text
lib/features/auth/
  domain/
    auth_failure.dart
    auth_repository.dart
    auth_state.dart
    authenticated_customer.dart
  data/
    auth_callback_source.dart
    auth_callback_validator.dart
    auth_error_mapper.dart
    supabase_auth_repository.dart
  application/
    auth_controller.dart
    auth_providers.dart

lib/core/backend/
  secure_supabase_auth_storage.dart
  supabase_bootstrap.dart

lib/features/account/presentation/
  account_screen.dart
```

Non sono stati creati layer o file senza responsabilità/consumatore reale.

## Callback boundary

`detectSessionInUri` resta `false`. Un solo `AppLinks` source cancellabile riceve cold
e warm URI. Prima dell'SDK il validator richiede:

- URI assoluto;
- scheme `com.xniw.clientmerchandisecontrol`;
- host `auth-callback`;
- path `/`;
- user-info vuoto;
- nessuna porta;
- nessun fragment;
- nessuna wildcard;
- successo con un solo `code` non vuoto, bounded e senza caratteri di controllo;
- oppure errore provider con sole chiavi allowlisted e valori bounded;
- nessun `access_token`, `refresh_token`, provider token o payload implicit;
- nessuna combinazione `code+error`, parametro extra o duplicato.

Callback rifiutato significa zero chiamate a Supabase, sessione invariata, errore
sanitizzato e nessun crash. Il code non viene loggato né conservato dopo l'exchange.

## Configurazione nativa

Android mantiene `MainActivity`, `singleTop` ed `exported=true`, disabilita il Flutter
deep-link handler e aggiunge un solo `VIEW`/`DEFAULT`/`BROWSABLE` filter con
scheme/host/path esatti. Nessun `autoVerify`, wildcard, `pathPrefix` o seconda
Activity.

iOS disabilita il Flutter deep-link handler e registra un solo
`CFBundleURLTypes`/scheme. Non aggiunge Universal Links, Associated Domains, reversed
Google client ID o signing. L'auto-handling `app_links` è disabilitato dopo la
registrazione del plugin; `AppDelegate` inoltra il custom scheme applicativo e
`SceneDelegate` inoltra connection options, URL contexts e user activity allo stesso
singleton, sempre dopo i callback `super`. Host/path sono verificati in Dart prima
dell'exchange e un solo source Dart consuma gli eventi.

## Secure persistence

`SecureSupabaseAuthStorage` implementa entrambi i port SDK:

- `LocalStorage` per il JSON sessione;
- `GotrueAsyncStorage` per il verifier PKCE.

Un solo namespace Auth usa Android Keystore con cifratura autenticata e iOS Keychain
non sincronizzato, limitato al device. Le chiavi ammesse sono bounded e separate. Gli
errori vengono emessi al boundary Auth e falliscono chiuso senza
SharedPreferences/plaintext fallback; exchange ed eventi refresh non pubblicano
authenticated prima di una scrittura esplicita riuscita.

Marker non sensibili nel container applicativo rilevano il primo avvio dopo install e
un cleanup sessione/PKCE rimasto pendente. Il cleanup registra per primo un journal
file di un byte in Application Support, indipendente dalle API SharedPreferences e
Keychain/Keystore, quindi scrive i due marker ridondanti esistenti. Il bootstrap
considera pendente uno qualsiasi dei tre marker e ritenta i delete prima di qualunque
restore. Questo mitiga sia la persistenza Keychain dopo disinstallazione sia failure
multiple durante logout/cancel. Android Auto Backup viene disabilitato; nessun marker
contiene token, verifier, identificativi o PII.

## Stato dominio

Stati minimi:

- `guest`;
- `authenticating`;
- `cancelling`;
- `cancelled`;
- `authenticated`;
- `signingOut`;
- `recoverableError`;
- `configurationError`.

Il controller è eager, possiede un solo repository e usa single-flight più generation
token. Callback, logout e dispose sono serializzati: risultati obsoleti non prevalgono.
Un callback resta pending in memoria finché Supabase è pronto, viene consumato una
volta e non è loggato.

| Evento | Stato risultante |
|---|---|
| launch senza sessione | guest |
| cold restore valido | authenticated, senza navigazione forzata |
| tap Google | authenticating |
| secondo tap | invariato, nessuna seconda launch |
| browser non lanciato | recoverableError |
| cancel esplicito | cancelling; attende exchange, sign-out/purge; poi cancelled |
| callback valida | persistenza confermata, authenticated e Account |
| callback invalida | recoverableError/guest-safe |
| refresh valido | authenticated idempotente |
| sessione scaduta con refresh retryable | identity rifiutata, guest con notice; refresh token sicuro preservato per il retry SDK |
| sessione revocata / `signedOut` | purge e guest con notice |
| logout | signingOut -> guest |
| logout offline | guest locale, limite revoca remota sanitizzato |
| callback tardivo | non può eliminare il verifier nuovo; exchange cancellato compensato |
| dispose | subscription cancellate, nessuna late emission e compensazione exchange |

## Identity e UI

`AuthenticatedCustomer` usa `user.id` soltanto come identità interna. Email deriva dal
campo SDK dedicato; nome da metadata è testo non fidato, trim/bounded e mai
autorizzativo. HTML, controlli e valori eccessivi ricadono nel fallback localizzato.

TASK-020 non passa `avatar_url`, `NetworkImage` o URI al widget Account: conserva
`avatarBytes:null` e riusa il fallback locale sicuro di TASK-012.

Home, Catalogo e Carrello non hanno route guard e restano disponibili in ogni stato
Auth. La UI disabilita azioni durante operazioni single-flight, offre cancel/retry
manuali e non avvia loop.

Matrice CA/T e comandi canonici:
`commands-and-results.md`, CMD-F01/F04/F07/F11, CA-03…CA-08, CA-14…CA-26 e
T-02/03/05/08…T-18/23/24.
