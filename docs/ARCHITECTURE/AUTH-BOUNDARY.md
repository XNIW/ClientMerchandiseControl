# Auth boundary Storefront e mobile

## Scopo e stato

Questo documento conserva il contratto normativo Storefront definito da TASK-003 e
registra l'implementazione mobile customer di TASK-020. Il client usa Supabase Auth
Google per stabilire un'identità di sessione; non assegna ruoli, non autorizza risorse e
non interroga inventory, profilo, ordini o tabelle Storefront.

I termini `MUST`, `MUST NOT`, `SHOULD` e `MAY` indicano rispettivamente requisito
obbligatorio, divieto, raccomandazione e possibilità. Una capability non elencata è
negata per default.

## Principi

1. Una API key identifica **quale componente** accede al progetto.
2. Una sessione valida identifica **chi** effettua la richiesta.
3. Soltanto grant, RLS e controlli server-side determinano **cosa** quel soggetto può
   fare.
4. UI, route, cache locale, email, `shop_id` e metadata modificabili dal client non
   autorizzano alcun accesso.
5. Supabase applica i controlli, ma non decide pubblicazione, prezzi, disponibilità,
   fulfillment o fiscalità.
6. Il fallimento di qualunque prerequisito di sicurezza termina in diniego, mai in un
   fallback verso superfici operative o credenziali più privilegiate.

## Attori

### Guest

Un guest usa il client pubblico con una publishable key e senza una sessione cliente
valida. Il ruolo database atteso è `anon`.

Il guest MAY leggere soltanto risorse Storefront esplicitamente pubblicate per uno shop
attivo. Non possiede identità cliente, membership, ordine, profilo o capability di
scrittura remota.

### Customer

Un customer è un utente con sessione Supabase Auth valida nel client pubblico. La
sessione fornisce un subject stabile, normalmente `auth.uid()`, e il ruolo database
`authenticated`.

Essere autenticato non concede accesso generale. Ogni risorsa privata MUST essere
vincolata al subject, allo shop e allo stato server-side pertinente. Le mutazioni future
MUST passare da interfacce customer-scoped che applichino autorizzazione, validazione,
idempotenza e audit secondo il rischio.

### Staff

Uno staff member opera nei prodotti Admin, Android operativo, iOS operativo o POS con
identità, ruoli e lifecycle propri. Una sessione staff non diventa una capability
Storefront e non deve essere riutilizzata dal client pubblico.

Il client pubblico MUST NOT offrire route, query, RPC o escalation staff. Un customer
che è anche staff mantiene capability customer finché usa il contesto pubblico; il
passaggio al contesto staff richiede un boundary separato e una nuova autorizzazione.

### Server

Il server comprende componenti Admin server-only, funzioni database e future funzioni
server-side approvate. Può detenere una secret key, una legacy `service_role` o una
connessione database soltanto in un ambiente non pubblico.

Una credenziale server può bypassare RLS: per questo non costituisce autorizzazione
business. Ogni operazione privilegiata MUST verificare l'attore, lo shop, la capability
richiesta e gli invarianti di dominio; le mutazioni sensibili MUST essere idempotenti e
auditabili. Il server MUST usare il privilegio minimo necessario.

## Publishable key, identity e authorization

| Livello | Cosa prova | Cosa non prova | Controllo richiesto |
|---|---|---|---|
| Publishable key | La richiesta proviene da un componente pubblico ammesso a raggiungere i servizi Supabase | Identità utente, ownership, membership, ruolo staff o diritto su uno shop | Grant minimi e RLS per `anon` o per il JWT utente allegato |
| Sessione/JWT cliente | Il token valido identifica un subject e una sessione entro issuer, audience e scadenza attesi | Accesso a tutte le righe, membership corrente, shop scelto dalla UI o permesso staff | RLS, lookup server-authoritative e, quando richiesto, controllo sessione corrente |
| Authorization | Il subject può eseguire una specifica azione su una specifica risorsa nello stato corrente | Nessuna capability ulteriore | Grant, RLS, policy di dominio, validazione e audit |
| Secret key / `service_role` | Il chiamante è un componente server configurato | Intento legittimo, shop corretto o permesso dell'utente finale | Guard server-side esplicito prima dell'accesso privilegiato |

La publishable key è recuperabile dal bundle mobile e non è un secret. Secret key,
`service_role`, password database, token amministrativi e credenziali provider MUST NOT
entrare nel client, negli asset, nei log, negli screenshot o in Git.

## Metadata e claim

- `user_metadata` e `raw_user_meta_data` sono modificabili dall'utente e MUST NOT essere
  usati in RLS o in qualunque decisione di autorizzazione.
- Email, telefono, display name, locale e provider sono attributi di identità o profilo;
  non provano membership, ownership o ruolo.
- `app_metadata` o custom claim server-managed MAY contribuire a un controllo, ma non
  sostituiscono lo stato autorevole quando revoca e freshness sono rilevanti. Un JWT può
  contenere claim obsoleti fino al refresh.
- `shop_id` inviato dal client è un selettore non fidato. RLS o server MUST verificare
  che la risorsa appartenga allo shop richiesto e che l'attore abbia la capability
  necessaria.
- Per operazioni ad alto impatto, il server SHOULD verificare lifecycle e revoca della
  sessione oltre a firma, audience e scadenza del JWT.

## Matrice delle capability

| Capability | Guest | Customer | Staff | Server |
|---|---|---|---|---|
| Leggere catalogo Storefront pubblicato di uno shop attivo | Sì, tramite allowlist Storefront e policy `anon` | Sì | Non tramite il client pubblico | Sì, se richiesto dal flusso server |
| Leggere prezzo/promozione/disponibilità commerciale pubblicata | Sì, come valore server-authoritative | Sì | Non tramite superfici customer | Sì |
| Leggere profilo, preferiti, carrello o ordini di un customer | No | Soltanto le proprie risorse e lo shop ammesso | No tramite Storefront | Solo per un caso d'uso autorizzato e auditabile |
| Creare o modificare risorse customer | No, salvo futura capability anon esplicitamente approvata | Solo tramite API/RPC customer-scoped e idempotente | No tramite Storefront | Sì, con guard di dominio |
| Pubblicare prodotti, prezzi, promozioni o immagini | No | No | Solo nel control plane autorizzato | Solo come esecuzione della decisione Admin |
| Leggere o mutare inventory operativo, costo o stock grezzo | No | No | Solo tramite prodotti operativi autorizzati | Solo per proiezione o workflow esplicitamente autorizzato |
| Gestire staff, device, policy, migration o configurazione Auth | No | No | Solo nel control plane pertinente | Solo con ruolo privilegiato dedicato |
| Usare secret key, `service_role` o connessione database | No | No | No in client/browser | Sì, server-only e least privilege |

`Sì` significa soltanto che il contratto ammette la capability; schema e implementazione
restano governati dai relativi task.

## Grant, RLS e funzioni

Grant e RLS sono due livelli obbligatori e indipendenti:

- un `GRANT` stabilisce se `anon` o `authenticated` può raggiungere una tabella, view,
  sequenza o funzione;
- una policy RLS stabilisce quali righe quel ruolo può leggere o mutare;
- l'assenza di un grant non può essere compensata allargando RLS;
- l'esistenza di RLS non rende sicuro un grant eccessivo;
- nessuna esposizione automatica della Data API viene assunta.

Per ogni oggetto Storefront futuro:

1. i grant MUST essere espliciti, minimi e separati per `anon` e `authenticated`;
2. ogni tabella o view esposta MUST avere RLS attiva o una protezione equivalente
   documentata e verificata;
3. le policy customer MUST verificare ownership e shop scope, non soltanto
   `TO authenticated`;
4. una policy `UPDATE` MUST avere sia `USING` sia `WITH CHECK`; la lettura necessaria
   alla mutazione deve essere autorizzata esplicitamente;
5. una view esposta SHOULD essere `security_invoker`; altrimenti deve restare in schema
   non esposto o avere grant revocati;
6. `EXECUTE` sulle funzioni MUST essere revocato da `PUBLIC` e concesso soltanto ai
   ruoli necessari;
7. `SECURITY DEFINER` è vietato come scorciatoia per superare RLS. Se indispensabile,
   resta in uno schema non esposto, fissa `search_path`, verifica l'attore e limita
   `EXECUTE`;
8. Storage richiede policy e grant propri; un bucket pubblico non rende pubblicabile un
   asset non approvato.

## Denylist auth e interfacce vietate

Il client pubblico MUST NOT raggiungere direttamente:

- schemi `auth`, `app_private`, `storage`, `realtime` o altri schemi interni;
- tabelle con prefissi `inventory_`, `platform_`, `pos_`, `staff_` o `audit_`;
- `shops`, `shop_members`, `shop_devices`, `profiles`, `shared_sheet_sessions`,
  `shared_sheet_session_diagnostics` e `sync_events`;
- RPC con prefissi `platform_`, `pos_`, `staff_`, `shop_staff_`, `shop_device_` o
  `product_image_`;
- RPC operative come `record_sync_event` e `mobile_linked_shops`;
- API Admin/POS, endpoint di management Supabase, specifica OpenAPI, SQL diretto,
  GraphQL operativo o interfacce usate dai client inventory;
- bucket sorgente, signed URL amministrative e API di gestione immagini.

La denylist è un minimo esplicito, non un'allowlist inversa. Un nuovo oggetto resta
vietato finché il contratto Storefront versionato non lo ammette.

## Comportamento fail-closed

| Condizione | Risposta obbligatoria |
|---|---|
| URL o publishable key mancanti/non validi | Non inizializzare il backend: development resta offline; staging/production espongono un errore di configurazione senza fallback fra ambienti |
| Sessione assente su capability customer | Negare e richiedere autenticazione; nessun fallback guest che esponga dati privati |
| JWT scaduto, issuer/audience errati o sessione revocata | Negare, rimuovere lo stato autenticato locale e avviare il recovery previsto |
| Membership, ownership, shop o claim non verificabili | Negare; non fidarsi di cache, route, email o metadata client |
| Grant/RLS nega la richiesta | Propagare un errore sicuro; non provare tabelle operative o chiavi privilegiate |
| Shop non attivo o risorsa non pubblicata/scaduta | Omettere o negare la risorsa |
| Rete indisponibile | Usare soltanto cache esplicitamente classificata; nessuna commercial truth nuova viene inventata |
| Versione contratto sconosciuta o payload incompatibile | Fallire come contract mismatch e non deserializzare permissivamente |

Errori cliente non devono rivelare policy, nomi interni, query, token, identificatori
privilegiati o differenze utili all'enumerazione di account e risorse.

## Verifiche richieste ai task di implementazione

I task che materializzano questo contratto MUST aggiungere almeno:

- test guest/customer positivi e negativi per grant e RLS;
- tentativi cross-user e cross-shop;
- verifica che `user_metadata`, email e `shop_id` manipolati non elevino privilegi;
- test di revoca, token scaduto e claim stale;
- scansione di bundle, log ed evidence per secret e `service_role`;
- verifica di view, funzioni, `EXECUTE`, `SECURITY DEFINER` e Storage;
- test che ogni accesso denylist fallisca senza fallback.

## Implementazione mobile TASK-020

### Componenti e dipendenze

```text
AccountScreen
  -> AuthController (Riverpod, eager)
  -> AuthRepository
  -> SupabaseAuthRepository
  -> Supabase Auth Google / PKCE / browser esterno

OS callback
  -> AppLinksAuthCallbackSource
  -> AuthCallbackValidator
  -> AuthController
  -> exchangeCodeForSession
  -> onAuthStateChange
```

I widget dipendono soltanto da `AuthState`, `AuthenticatedCustomer` e azioni del
controller. Nessun widget importa Supabase. Il repository concreto traduce oggetti SDK
in valori dominio bounded e non espone sessione, token o `User`.

### Runtime e configurazione

- development: guest, zero inizializzazione/rete Auth;
- staging con kill switch `false`: guest, zero OAuth;
- staging completo con flag `true`: Google OAuth attivo;
- production: Google obbligatoriamente disabilitato nel milestone.

`SupabaseBootstrap` dichiara `AuthFlowType.pkce`, `autoRefreshToken:true`,
`detectSessionInUri:false`, `debug:false` e lo stesso
`SecureSupabaseAuthStorage` per sessione e verifier.

### Callback canonico

L'unico URI accettato è:

```text
com.xniw.clientmerchandisecontrol://auth-callback/
```

Android filtra scheme, host e path `/`; iOS registra soltanto lo scheme e delega
host/path a Dart. Flutter deep linking e l'observer Supabase permissivo sono
disabilitati. Su iOS anche l'handling automatico di `app_links` è disabilitato:
`AppDelegate` inoltra il custom scheme warm e `SceneDelegate` inoltra cold/warm e
universal activity allo stesso singleton del plugin, preservando i callback `super`.
Un solo source Dart `app_links` unifica cold e warm callback e resta l'unico consumer
applicativo.

Prima di qualunque exchange il validator richiede URI assoluto, scheme/host/path
canonici, user-info vuoto, nessuna porta o fragment e una query di una delle due forme:

- un solo `code` PKCE non vuoto, visibile e bounded;
- `error` con soli `error_code`/`error_description` opzionali, tutti bounded.

Token implicit, parametri extra, duplicati, valori corrotti o callback misti
`code+error` sono rifiutati. Il controller conserva soltanto un fingerprint bounded per
deduplica; callback, code e valori errore non vengono loggati.

### Lifecycle

`AuthController` apre il listener prima di attendere il repository, accoda al massimo
quattro callback e serializza l'exchange. Login e logout sono single-flight; un
generation token impedisce a future tardive di prevalere dopo cancel, logout o dispose.

La sessione corrente e `onAuthStateChange` alimentano una sola state machine:

- restore valido -> authenticated senza navigazione forzata;
- browser aperto -> authenticating, non successo;
- callback valido -> exchange e authenticated con navigazione ad Account;
- cancellazione -> verifier eliminato e callback tardivo ignorato;
- refresh/user update -> customer rimappato;
- expiry/revoca -> guest con notice customer-safe;
- logout -> signingOut, pulizia locale, guest anche con errore remoto.

Home, Catalogo e Carrello non hanno route guard e restano disponibili.

### Persistenza

`SecureSupabaseAuthStorage` implementa sia `LocalStorage` sia
`GotrueAsyncStorage`. Mappa esclusivamente sessione e verifier su due chiavi:

- Android: namespace dedicato, RSA-OAEP SHA-256, AES-GCM e backup app disabilitato;
- iOS: Keychain service dedicato, non sincronizzato,
  `first_unlock_this_device`.

SharedPreferences contiene soltanto il marker booleano di installazione e due tombstone
booleani non sensibili per i cleanup pendenti. Se il marker di installazione è assente,
l'adapter elimina le chiavi Auth e i tombstone sicuri noti prima di marcarlo, mitigando
la persistenza Keychain dopo uninstall. Ogni purge scrive inoltre un tombstone
ridondante nel secure store prima del delete: al bootstrap basta uno dei due marker per
negare il restore e ritentare la pulizia. Lettura, scrittura, delete o marker falliti
producono un errore sanitizzato e nessun fallback plaintext.

### Identity non fidata

`AuthenticatedCustomer` conserva il subject interno e ricava email solo dal campo SDK
dedicato. Nome e email sono trim/bounded; controlli, bidi override, markup-like e tipi
non stringa ricadono nel fallback UI. `avatar_url`, `role`, `shop_id`,
`app_metadata` e `user_metadata` non autorizzano né avviano rete. TASK-020 passa
`avatarBytes:null`.

### Authorization

Una sessione valida prova soltanto l'identità Supabase. Route, email, cache, subject,
metadata e stato Riverpod non sono un confine di autorizzazione. Ogni futura risorsa
customer richiede grant minimi, RLS e validazione server-side sul dominio Storefront.
Il client usa soltanto publishable key e non contiene credenziali privilegiate.

### Osservabilità ed evidence

Supabase `debug` è disabilitato. Errori e copy usano categorie chiuse; non includono
messaggi SDK raw. Origin staging e publishable key sono configurazione pubblica
compile-time attesa nel bundle mobile, ma i loro valori raw restano vietati in log,
test output persistente, screenshot, crash report ed evidence. Sono vietati ovunque
nel client, nel bundle e in Git: secret key, legacy `service_role`, OAuth client
secret, password, token amministrativi, certificati e credenziali di signing. Callback
completa, code/state, access/refresh/provider token, session/User, account test e PII
non devono comparire in alcun output persistente o evidence.
