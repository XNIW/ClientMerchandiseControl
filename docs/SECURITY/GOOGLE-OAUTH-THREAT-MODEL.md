# Google OAuth mobile threat model

## Metadata e stato

- **Target**: `ClientMerchandiseControl`, TASK-020
- **Piattaforme**: Android e iOS
- **Flusso**: Supabase Auth Google, OAuth Authorization Code + PKCE
- **Redirect configurato**:
  `https://clientmerchandisecontrol.invalid/auth-callback/` (sentinel non instradabile)
- **Ambiente remoto in scope**: solo staging non-production canonico
- **Stato del documento**: modello storico TASK-020 aggiornato dal closeout TASK-033;
  OAuth distribuibile è disabilitato finché manca un dominio HTTPS verificato

Questo modello non assegna `PASS`. Distingue controlli implementati nel worktree,
verifiche da eseguire e dipendenze esterne ancora da provare.

## Valutazione sintetica

Il rischio dominante del custom scheme non verificabile è stato rimosso dalla superficie
OAuth distribuibile: Android non registra più il callback Auth, iOS non espone uno
scheme Auth e staging/production rifiutano `GOOGLE_AUTH_ENABLED=true`. Il valore
`.invalid` è un sentinel non instradabile, non una pretesa di ownership. OAuth potrà
tornare operativo soltanto con dominio HTTPS posseduto e App Links/Universal Links
verificati su entrambe le piattaforme.

La seconda area critica è la persistenza. Lo SDK bloccato usa SharedPreferences per
sessione e verifier se non configurato diversamente. TASK-020 sostituisce entrambi con
un adapter Keychain/Keystore fail-closed e conserva in SharedPreferences soltanto
marker booleani non sensibili di installazione e cleanup pendente. Un terzo journal
non sensibile, in Application Support, registra per primo il cleanup prima di
qualunque delete e resta separato dalle API SharedPreferences e Keychain/Keystore.

L'identità Auth non è autorizzazione. Un client modificato, un metadata falsificato o
una route visibile non devono ottenere dati: grant, RLS e validazione server-side
restano obbligatori nei futuri task Storefront.

## Scope

In scope:

- avvio Google OAuth nel browser esterno;
- callback cold/warm, validazione, exchange e replay;
- verifier PKCE e sessione locale;
- restore, refresh SDK, expiry, cancellazione, logout e dispose;
- mapping di identità/metadata e presentazione Account;
- configurazione nativa e redirect allow-list staging;
- log, screenshot, evidence e bundle client.

Fuori scope:

- sicurezza dell'account Google o delle credenziali OAuth condivise;
- implementazione interna di Google/Supabase;
- RLS/schema/dati customer futuri;
- password, OTP, magic link, MFA, Apple o altri provider;
- provisioning di dominio, Universal/App Links verificati e produzione.

## Architettura e data flow

```text
[Config staging/production]
        |
        | GOOGLE_AUTH_ENABLED=true
        v
[AppConfig] -- deny --> [errore fail-closed prima del bootstrap]

[Harness test-only] -> [AuthCallbackValidator/AuthController]
        |                         |
        | nessun provider         | lifecycle, timeout, replay
        | nessun handler nativo   v
        +----------------> [fake repository + secure-storage tests]
```

Il bool di `signInWithOAuth` prova soltanto l'apertura del browser. L'autenticazione
deriva da sessione SDK valida dopo exchange o restore.

## Asset

| Asset | Sensibilità | Proprietario logico | Requisito |
|---|---|---|---|
| Verifier PKCE | critico, effimero | runtime Auth sul device | confidenzialità, cancellazione e binding al code |
| Authorization code | critico, effimero | flusso OAuth | mai loggato/persistito; exchange una volta |
| Access/refresh token e session JSON | critico | Supabase Auth/customer | Keychain/Keystore, mai evidence o plaintext |
| Subject customer | personale interno | Supabase Auth | non esposto/loggato e non usato come ruolo |
| Email/display name | PII/display | customer | bounded, customer-safe, non autorizzativo |
| Publishable key/staging origin | configurazione pubblicabile ma sensibile operativamente | progetto staging | compile-time locale, niente evidence completa |
| Redirect allow-list | configurazione security-critical | Supabase staging | append esatto, no wildcard/drift/production |
| Stato Riverpod e route | dato non fidato | client | non autorizzano risorse |
| Log/screenshot/evidence | artifact potenzialmente esportabile | repository/workflow | sanitizzazione preventiva |

## Trust boundary

1. **Persona ↔ browser/Google**: UI e account selection sono esterni all'app.
2. **Google ↔ Supabase Auth**: provider, state/CSRF upstream e credenziali OAuth sono
   gestiti dai servizi.
3. **Supabase ↔ OS**: nessun callback OAuth è registrato nel runtime corrente; una
   futura integrazione richiede HTTPS verificato.
4. **OS ↔ Dart**: lo scheme Storefront privato ammette soltanto route pubbliche bounded;
   route customer-sensitive falliscono chiuso.
5. **Dart ↔ SDK**: nessun input URI raggiunge l'exchange prima del validator.
6. **SDK ↔ secure storage**: token e verifier entrano in storage privilegiato.
7. **Auth domain ↔ UI**: soltanto customer normalizzato; nessun oggetto SDK/sessione.
8. **Client ↔ futuri dati Storefront**: client ostile; enforcement solo server-side.
9. **Runtime ↔ Git/CI/evidence**: valori locali e PII non devono attraversare il
   confine di versionamento.

## Attori e capacità

- app malevola installata sul device che registra lo stesso custom scheme;
- sito/app che tenta di iniettare URI arbitrari;
- attaccante con accesso a log, screenshot, artifact o backup;
- utente con browser già autenticato su un account diverso;
- rete ostile/offline che interrompe exchange, refresh o logout;
- metadata controllati dall'identity provider o da una sessione compromessa;
- client modificato/rooted/jailbroken che altera route o stato locale;
- errore operativo che modifica redirect staging o usa config production.

Non si assume che device rooted/jailbroken, browser o OS compromessi possano essere
resi affidabili dal client.

## Invarianti

- `detectSessionInUri` e Flutter deep linking restano disabilitati.
- Nessun listener nativo OAuth è registrato nel runtime distribuibile.
- Solo scheme, host, path `/` e query allowlisted raggiungono l'exchange.
- Fragment e token implicit non sono mai accettati.
- Un callback è consumato al massimo una volta nel processo.
- Cancel attende e compensa un exchange già in-flight prima di rendere disponibile
  Retry; logout e dispose invalidano o ripuliscono risultati tardivi.
- Sessione e verifier non usano storage plaintext.
- Authenticated viene pubblicato solo dopo una persistenza esplicita riuscita; gli
  errori storage SDK sono osservabili e non abilitano fallback.
- Restore non forza Account; solo successo callback lo fa.
- Home, Catalogo e Carrello restano guest-accessible.
- Metadata/email/route/cache non autorizzano.
- Nessun secret o PII entra in log, Git o evidence.

## Scenari di minaccia

| ID | Scenario e catena | Impatto | Controlli implementati | Rischio residuo / verifica |
|---|---|---|---|---|
| TM-01 | App malevola registra il vecchio custom scheme e intercetta il code | DoS; tentativo di furto sessione | callback OAuth nativo rimosso; Google sempre OFF; sentinel `.invalid` non instradabile | Riaprire solo con App/Universal Links verificati |
| TM-02 | URI OAuth con scheme/host/path falso raggiunge l'app | Login spoof/injection | nessun handler OAuth nativo; validator mantenuto solo negli harness test-only | Test source/native/config provano assenza handler e fail-closed |
| TM-03 | Fragment con access/refresh/provider token tenta implicit flow | Token injection/leak | `AuthFlowType.pkce`; fragment sempre rifiutato; `detectSessionInUri:false` | Verificare zero chiamate repository e nessun token in output |
| TM-04 | Query include code duplicato, vuoto, enorme, controlli o campi extra | parser ambiguity, DoS, bypass | `queryParametersAll`, cardinalità uno, allow-list, bounds e caratteri visibili | Bounds sono client-side; testare duplicati/oversize su device |
| TM-05 | Callback contiene contemporaneamente code ed errore | confusion attack | forme query mutuamente esclusive | Unit test e invalid smoke |
| TM-06 | Replay dello stesso callback o doppia consegna cold/warm | doppio exchange/stato fuori ordine | fingerprint bounded, coda seriale, PKCE code one-time | Collisione fingerprint può causare solo DoS locale. Test duplicate |
| TM-07 | Callback valido arriva prima che Supabase sia pronto | callback perso o crash | listener eager, coda bounded prima della factory, drain seriale | Coda solo memoria e max quattro. Test cold callback |
| TM-08 | Due tap aprono due browser e sovrascrivono verifier | account confusion/exchange failure | login single-flight e `_oauthFlowActive` | Browser/OS esterno resta non controllabile. Test doppio tap |
| TM-09 | Cancel/provider failure seguito da callback/exchange tardivo | riautenticazione indesiderata o verifier nuovo eliminato | termination single-flight, suppress/ignore, attesa exchange, sign-out/purge compensativo prima di Retry; failure vecchia non elimina PKCE corrente | Process kill durante rete resta boundary OS; test successo/errore tardivo, provider cancellation, cold restore guest e callback vecchio→nuovo |
| TM-10 | Logout mentre exchange/session event è in volo | stato torna authenticated | generation, soppressione eventi, coda pulita, attesa exchange e secondo purge compensativo prima di Guest/nuovo login | Verificare side effect sessione, future tardive e stream fuori ordine |
| TM-11 | Logout offline o delete locale fallisce | token remoto o sessione locale restano validi | intento durevole scritto prima della pulizia; restore negato; revoca globale tentata e accodata in modo bounded per retry; delete sessione/verifier indipendenti | Se nessun canale persistente può scrivere, il processo corrente resta fail-closed; regressioni coprono restart, retry e login esplicito |
| TM-12 | Access token scaduto o refresh token revocato | UI conserva customer stale oppure il client impedisce un recovery SDK valido | sessioni senza expiry valida o `Session.isExpired` non espongono identity; errore retryable degrada a guest ma preserva il refresh token in storage sicuro; un vero `signedOut` esegue purge | Test restore expired/offline, scadenza durante offline, refresh successivo e revoca |
| TM-13 | Sessione/verifier finiscono in SharedPreferences | furto da backup/device | adapter unico LocalStorage+GotrueAsyncStorage; FSS; nessun fallback | Verificare source/lock e storage test; device compromesso resta rischio |
| TM-14 | Android backup ripristina ciphertext senza chiave o su altro device | crash o sessione incoerente | `android:allowBackup=false`; namespace Keystore; this app non migra secret | Ispezionare merged manifest/build |
| TM-15 | Keychain sopravvive a uninstall iOS | sessione precedente riappare | marker app-container non sensibile; first-install delete delle sole due chiavi | Install/clean smoke richiesto; perdita marker causa logout sicuro |
| TM-16 | Errore Keychain/Keystore induce fallback debole o sessione solo-memory | token plaintext, restore incoerente o UI authenticated non persistita | persistenza esplicita prima di authenticated, stream failure sanitizzato, purge locale, nessun fallback e configurationError UI | Verificare write exchange/refresh, delete indipendenti, marker/tombstone e retry initialization |
| TM-17 | Metadata contiene HTML, controlli, bidi, stringhe enormi, role/shop falsi | UI spoof, overflow, privilege confusion | normalizzazione/bounds; markup/control reject; ID interno; nessun uso autorizzativo | Unicode confusables leciti restano display-only. Unit/widget test |
| TM-18 | `avatar_url` forza download/SSRF/tracking | leakage IP, contenuto ostile | repository ignora URL; `avatarBytes:null`; solo fallback locale | Verificare assenza `NetworkImage`/HTTP in Account |
| TM-19 | Messaggio SDK include callback/code/token/email e viene loggato | credential/PII leakage | `debug:false`; mapper a categorie chiuse; nessun `toString` raw | Scan source/test/log/device; i log OS/browser esterni vanno redatti |
| TM-20 | Screenshot/task switcher cattura email o account selector | PII exposure | niente screenshot persistenti non redatti; UI mostra solo campi bounded | Nessun secure-screen flag nello scope; device/user resta boundary |
| TM-21 | Browser usa account Google diverso da quello atteso | account switching involontario | selezione gestita dal browser; identità visualizzata dopo callback; logout/relogin disponibili | Smoke deve usare solo account test già presente; password/MFA sono blocker esterno |
| TM-22 | CSRF/state upstream è assente o alterato | login CSRF/account swap | Supabase/Google gestiscono authorize; PKCE lega code e verifier; app non inventa secondo state | Il callback finale non espone state da convalidare localmente; verificare documentazione/versione/provider staging |
| TM-23 | Session fixation tramite JSON locale o code altrui | sessione attaccante | secure storage, parsing/session validation SDK, PKCE exchange | Device compromesso/rooted può alterare runtime; server deve validare JWT/RLS |
| TM-24 | App modificata cambia route, email, `shop_id` o stato Riverpod | accesso customer/staff indebito | nessun dato API nello scope; client dichiarato non-authority; publishable key | Futuri endpoint devono imporre grant/RLS/server validation |
| TM-25 | Redirect allow-list riceve wildcard o sostituisce valori esistenti | open redirect/drift o outage | write autorizzato solo append dell'URI esatto staging, confronto set before/after | Controllo remoto/evidence ancora da eseguire; produzione vietata |
| TM-26 | Due handler (`app_links`, Flutter o SDK) consumano lo stesso URI | exchange doppio/leak | Flutter, SDK e auto-handling iOS del plugin disabilitati; App/Scene delegate convergono nello stesso singleton; un source Dart applicativo | Ispezionare manifest/plist/delegate/options e test subscription unica |
| TM-27 | Coda callback viene riempita con URI malevoli | memoria/availability | massimo quattro pending, bounds payload e 64 fingerprint | DoS locale limitato; nessun rate limit OS possibile |
| TM-28 | Dispose lascia subscription o future che scrivono stato/sessione | crash/use-after-dispose o sessione tardiva | cancel subscription, `_disposed`, generation, guard state e compensazione best-effort dell'exchange posseduto | Test dispose + late exchange/event |
| TM-29 | Config staging/production viene confusa | traffico o OAuth sull'ambiente errato | `AppConfig` exact matrix; development offline; production Google false; no fallback | File locale ignorato e scan Git; build per ambiente |
| TM-30 | Evidence/CI include config locale, key, project ref, account o token | esposizione persistente | ignore rules, CI fake-only, scan source/index/worktree/bundle; soltanto legacy JWT `role=anon` è pubblicabile, customer/service/ruoli non pubblicabili falliscono chiuso; evidence sanitizzate | Verificare diff, untracked, bundle/log e output prima del commit |

## Controlli e verifiche repository

| Area | Implementazione | Verifica prevista |
|---|---|---|
| Config/bootstrap | `app_config.dart`, `supabase_bootstrap.dart` | config e bootstrap unit test |
| Storage | `secure_supabase_auth_storage.dart` | CRUD, first-install, tre tombstone/restart, journal file reale, persistenza osservabile, failure e retry unit test; device reinstall |
| Callback | `auth_callback_source.dart`, `auth_callback_validator.dart` | cold/warm, matrice URI, replay e device open-url |
| SDK boundary | `supabase_auth_repository.dart` | port fake, exact redirect, exchange/session/logout |
| Lifecycle | `auth_controller.dart` | single-flight, queue, cancel/exchange compensato, expiry, logout, race, retry e dispose |
| UI | `account_screen.dart` | stati, semantics, 48 dp, 200%, no network avatar |
| Native | Manifest e Info.plist | source test, merged build, adb/simctl |
| End-to-end fake | `auth_callback_flow_test.dart` | Android/iOS device |
| Runtime live | non applicabile finché manca un dominio verificato | il runtime deve negare OAuth senza handler nativi |
| Security | source/diff/bundle/log scan | review indipendente A–E |

## Rischi residui e condizioni di blocco

- OAuth resta intenzionalmente indisponibile finché non esistono dominio e link HTTPS
  verificati. Questa è una limitazione funzionale fail-closed, non rischio accettato.
- Un device rooted/jailbroken o un browser compromesso può osservare runtime/PII. Il
  server non deve fidarsi del client.
- La revoca globale può fallire offline; il device resta guest, il restore è negato e
  la revoca pending viene ritentata senza rappresentare il logout come già remoto.
- Se il filesystem, SharedPreferences e Keychain/Keystore rifiutano simultaneamente
  ogni mutazione, incluso il journal, un nuovo processo non può ricostruire un intento
  di logout mai persistito. Il runtime corrente fallisce chiuso; il journal
  addizionale copre il caso riproducibile in cui falliscono i due marker precedenti e
  il delete della sessione.
- Redirect allow-list/provider live non sono usati né attestati dal closeout: una
  futura riattivazione richiede un nuovo ciclo autorizzato e prove sanitizzate.
- Screenshot, log OS/browser e account selector richiedono redazione manuale prima di
  diventare evidence.

## Criterio di riesame

Il reviewer deve confrontare questo documento con lo SHA effettivo, ripetere i test
applicabili e aprire finding riproducibili per ogni divergenza. P0/P1/P2 restano
bloccanti; una mitigazione dichiarata ma non eseguita è `NOT_RUN` o `BLOCKED`, mai
`PASS`.
