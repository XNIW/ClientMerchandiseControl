# Mobile architecture

## Stack

- Flutter e Dart stable;
- soli target Android/Kotlin e iOS/Swift;
- Material 3 con adattamenti idiomatici iOS;
- Riverpod per stato e dependency injection;
- go_router per navigazione dichiarativa;
- Supabase Flutter per readiness e Auth customer;
- gen_l10n e intl.

## Struttura

L'architettura è feature-first, coerente con MVVM:

- View: widget e composizione UI;
- ViewModel/controller: stato e orchestrazione quando la feature lo richiede;
- repository: accesso a una fonte dati;
- service: integrazione tecnica;
- model/use case: soltanto quando aggiunge valore reale.

Non vengono creati livelli o interfacce vuoti. La shell, la configurazione, il design
system e i widget foundation hanno responsabilità concrete; repository e ViewModel
arrivano insieme alle feature data-backed.

## App e navigazione

`main.dart` delega a `bootstrap.dart`. `AppConfig` è l'unica authority del contratto
compile-time [`CMC-CLIENT-CONFIG 1.0.0`](ENVIRONMENT-STRATEGY.md): legge esattamente
`APP_ENV`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `AUTH_REDIRECT_URI` e
`GOOGLE_AUTH_ENABLED`, valida l'intera matrice prima di qualunque inizializzazione e
fornisce al bootstrap soltanto lo stato già normalizzato.

Development non accetta valori backend/callback né Google attivo e non inizializza
Supabase. Staging ammette l'inizializzazione SDK soltanto con tuple, callback e flag
completi; TASK-011 la completa con un health check Auth ufficiale e privo di dati.
Production non eredita mai staging, non inizializza rete e, finché OAuth production non
è autorizzato, accetta soltanto il kill switch Google disabilitato. In staging il flag
abilita il runtime Auth di TASK-020 soltanto con callback e backend completi.

`ClientMerchandiseControlApp` compone tema, localizzazione e router.
`StatefulShellRoute.indexedStack` mantiene quattro branch — Home, Catalogo, Carrello e
Account — e ne preserva lo stato. `AppRoutes` centralizza le location usate dalle CTA;
dalle tab root secondarie il back ritorna a Home. La shell assegna a ogni branch una app
bar riconoscibile: Home usa esclusivamente `AppBrand.effectiveDisplayName`, mentre le
altre destinazioni usano titoli localizzati.

In development senza configurazione l'app resta offline e usabile e mostra un banner
diagnostico debug accessibile. Staging e production incompleti sono errori espliciti,
senza fallback tra ambienti. Diagnostica ed errori espongono soltanto ambiente e
indicatori booleani, mai URL, key o callback raw. La Home ospita il banner nel proprio
scroll, così il viewport delle branch resta stabile; il Catalogo rappresenta localmente
gli stessi stati quando rilevanti, mentre Carrello e Account non vengono occupati da
diagnostica backend estranea al loro stato.

## Backend readiness

`BackendReadinessState` separa configurazione, inizializzazione e raggiungibilità:

- `unconfigured`: development offline, senza SDK o rete;
- `initializing`: SDK staging locale e probe in corso;
- `ready`: SDK inizializzato e `GET /auth/v1/health` concluso con HTTP 200 e payload
  health valido;
- `offline`: timeout abortito o errore di trasporto;
- `misconfigured`: ambiente non autorizzato oppure gateway/key/endpoint rifiutati;
- `authenticationRequired`: stato riservato a future operazioni session-aware;
- `recoverableError`: backend temporaneamente indisponibile o risposta incoerente.

`ready` attesta soltanto origin/key, gateway e liveness Auth. Non attesta database,
PostgREST, schema Storefront, RLS, grant, dati, OAuth o autorizzazione cliente.

Il health service costruisce un solo `GET` verso `/auth/v1/health`, usa esclusivamente
l'header `apikey`, non segue redirect e non registra request, response o eccezioni raw.
Un `AbortableRequest` applica timeout reale e cancellazione su dispose. Il repository
inizializza lo SDK e mappa gli esiti; il controller Riverpod avvia un solo check staging,
riusa l'operazione concorrente e permette soltanto retry manuale. Non esistono polling,
auto-retry o recheck su resume in TASK-011.

La shell viene renderizzata prima del check. Offline ed errori recuperabili mantengono
il browsing guest disponibile e mostrano copy localizzata customer-safe con retry;
development mostra il solo banner tecnico debug. Per TASK-020 le opzioni Auth SDK
usano ora PKCE, auto-refresh e un adapter Keychain/Keystore per sessione e verifier.
`detectSessionInUri` resta intenzionalmente disabilitato: il callback passa prima dal
validator applicativo esatto descritto in
[`AUTH-BOUNDARY.md`](AUTH-BOUNDARY.md).

## Shell cliente guest

TASK-012 sostituisce il placeholder tecnico con quattro superfici specifiche, senza
aggiungere dati o networking:

- Home offre gerarchia cliente, accessi a ricerca e categorie e sezioni future
  chiaramente vuote; ogni CTA apre la branch Catalogo;
- Catalogo presenta ricerca, filtri e ordinamento come controlli foundation
  disabilitati e mappa la sola readiness esistente in stati loading, vuoto, offline,
  unavailable e retryable; non esegue query;
- Carrello presenta uno stato vuoto senza totale, checkout o promessa commerciale e
  conduce al Catalogo;
- Account consuma lo stato dominio Auth: guest, autenticazione/cancellazione, errore
  recuperabile/configurazione, authenticated e logout. Il pulsante Google resta
  fail-closed in development, production e staging con kill switch disabilitato.

Nessuna superficie inventa prodotti, prezzi, stock, sconti, immagini o disponibilità.
L'avatar authenticated accetta soltanto bytes locali bounded già validati: TASK-020
passa sempre `null` e usa il fallback. Il widget non interpreta metadata o URI e non
avvia rete autonomamente.

## Design system

`AppTheme` è l'unico composition root light/dark. Token primitivi, semantic colors e
widget foundation sono descritti in `DESIGN-SYSTEM.md`. Le feature non definiscono
palette, font scale, breakpoint o spacing paralleli. `StorefrontPage` occupa tutta la
larghezza disponibile entro il max-width e mantiene scroll e padding responsive;
empty state, sezione, search launcher e status banner hanno responsabilità condivise
reali. I cataloghi ARB hanno parità per es-CL, it, en e zh-Hans; es-CL è la locale
primaria e il fallback deterministico.

## Dati e sicurezza

Il client è eseguito su un dispositivo pubblico e non costituisce mai un confine di
fiducia. Consumerà soltanto il futuro contratto Storefront, shop-scoped e protetto
server-side. La publishable key identifica il progetto Supabase ma non concede da sola
accesso; grant e RLS restano entrambi obbligatori.

Il client possiede:

- rendering, navigazione e accessibilità;
- raccolta degli intenti guest/customer;
- stato, cache e retry locali entro i contratti dei task proprietari;
- deep link e presentazione di freshness, errori ed esiti server.

Il client non possiede e non può dedurre:

- autorizzazione o ruoli;
- pubblicazione, prezzo, promozione o disponibilità commerciale;
- stock, costo, fornitore o altri dati inventory operativi;
- hold, conferma ordine, fulfillment, vendita fiscale o pagamento;
- decisioni staff o capability server.

## Ruoli nel client

| Ruolo | Comportamento mobile | Enforcement |
|---|---|---|
| `guest` | consulta la superficie Storefront pubblicata senza login | grant e RLS pubblici sul solo contratto allowlisted |
| `customer` | usa risorse pubblicate consentite ad `authenticated` e, con sessione valida, dati propri e intenti cliente | identità Auth più grant, RLS e validazione server-side |
| `staff` | nessun percorso operativo nel client pubblico | Admin Console e controlli server-side |
| `server` | nessuna credenziale o logica privilegiata distribuita nell'app | runtime server autorizzato, auditabile e idempotente |

Le capability `anon` e `authenticated` sono esplicite e non si ereditano implicitamente.
Una route visibile, uno stato Riverpod, un valore in cache, email, `shop_id` o
`user_metadata` non autorizzano accessi. La UI può anticipare o nascondere controlli per
chiarezza, ma il server deve rifiutare ogni operazione non consentita anche da un client
modificato.

## Confine di accesso dati

Repository e service mobili futuri possono dipendere soltanto dal contratto Storefront
definito per il loro task. Sono vietati:

- query dirette a tabelle, view, RPC o bucket inventory;
- collegamenti a database, API o protocollo Win7POS;
- chiamate alle API di management Admin o a endpoint staff-only;
- fallback verso Android/iOS operativi, POS o superfici legacy quando Storefront non è
  disponibile;
- `service_role`, token staff, secret di signing o URL production versionati nel client;
- generic schema discovery usata per raggiungere risorse non allowlisted.

Android/iOS Merchandise Control e Win7POS restano fonti e consumer del dominio
operativo attraverso pipeline server controllate. Non sono repository dati, SDK o
dipendenze runtime di questa app.

## Commercial truth e mutazioni

Il client presenta l'ultimo stato Storefront ricevuto insieme alla sua freshness, ma non
lo trasforma in verità autorizzativa. Prima di confermare un'azione commerciale il
server rivalida almeno shop, identità quando richiesta, prezzo, promozione,
disponibilità e idempotency key. Le mutazioni sensibili sono autorizzate, atomiche,
auditabili e fail-closed.

Ordine cliente e vendita fiscale POS mantengono identità e lifecycle distinti. Il client
non scrive una vendita POS, non scarica stock e non interpreta un successo locale come
conferma server.

## Auth, shop scope e stato locale

Il catalogo pubblico resta accessibile al guest. L'autenticazione abilita soltanto le
capability customer esplicitamente previste; non eredita automaticamente i grant `anon`
e non introduce un ruolo staff. Session identity e authorization sono concetti
distinti.

`AuthController` è eager e costituisce la sola fonte UI del lifecycle. Un
`AuthRepository` iniettabile separa dominio e SDK; `SupabaseAuthRepository` usa Google,
PKCE, browser esterno e callback canonica. Cold link e warm link confluiscono in una
sola subscription `app_links`, vengono validati e consumati una volta. Cancel resta in
corso finché un exchange posseduto non è terminato e compensato con sign-out/purge;
un risultato vecchio non elimina il verifier del retry. Risultati obsoleti dopo
cancellazione, logout o dispose non possono ripristinare authenticated.
Il restore valido non forza navigazione; soltanto un'autenticazione completata dal
callback conduce ad Account.

Su iOS l'inoltro nativo a `app_links` è manuale e converge nello stesso singleton:
`AppDelegate` copre il custom scheme consegnato dal lifecycle applicativo e
`SceneDelegate` copre connection options, URL contexts e user activity. L'handler
automatico del plugin e il deep linking Flutter restano disabilitati per evitare
consumer concorrenti; la validazione Dart resta obbligatoria.

Sessione e verifier PKCE condividono `SecureSupabaseAuthStorage`: Android usa
Keystore/RSA-OAEP/AES-GCM con backup applicativo disabilitato; iOS usa Keychain
non sincronizzato e vincolato al device. Marker booleani non sensibili nel container
applicativo cancellano le due chiavi Auth al primo avvio e ritentano un cleanup
sessione/PKCE fallito prima del restore. Ogni purge persiste prima un journal file di
un byte in Application Support, poi i marker SharedPreferences e secure store; uno
qualsiasi dei tre blocca il restore e i marker vengono cancellati solo dopo il delete
riuscito. Le mutazioni sono serializzate; le failure post-auth raggiungono il
controller e la sessione scaduta/non dotata di expiry valida non espone identity. Un
refresh retryable degrada la UI a guest senza eliminare il refresh token protetto,
così l'SDK può recuperare con un successivo `tokenRefreshed`; soltanto un vero
`signedOut` o il logout rimuove la sessione. Non esiste fallback SharedPreferences per
token. Se tutti e tre i canali persistenti e il delete falliscono insieme, il processo
corrente fallisce chiuso; dopo process death un intento mai persistito non è
ricostruibile.

Il logout usa `SignOutScope.local`: la sessione in memoria viene rimossa e l'adapter
tenta sempre, in modo indipendente, delete sessione e verifier. Un marker rimasto
pendente in uno dei tre canali blocca il restore e fa ritentare il purge al bootstrap.
Un errore offline può produrre un avviso customer-safe ma lo stato resta guest.

Ogni risorsa futura è vincolata a uno `shop_id` UUID validato dal server. Il client può
trasportare il contesto shop per routing e presentazione, ma non sceglie autonomamente
l'ambito autorizzato. Cache e persistenza locale devono essere separate per ambiente,
shop e identità quando applicabile, senza contenere credenziali privilegiate.

## Errori e assenza del backend

- Development resta offline e rifiuta qualunque configurazione remota.
- Staging e production incompleti falliscono in modo chiuso secondo il contratto
  ambiente.
- Una configurazione staging valida avvia il check ma non ne predetermina l'esito.
- Readiness `ready` prova soltanto la liveness Auth data-free, mai i dati Storefront.
- Il kill switch Google disabilita la capability locale senza selezionare un altro
  ambiente.
- Un errore Auth non abilita fallback anonimi per dati customer.
- Un errore Storefront non abilita accesso a inventory o POS.
- Dati scaduti vengono dichiarati come tali; il client non inventa prezzo, stock o
  disponibilità per completare la UI.

## Sequenza di implementazione

TASK-003 definisce soltanto ownership e trust boundary. Le implementazioni restano
assegnate a:

- TASK-004 per environment strategy e configurazione;
- TASK-005 per schema Storefront, migrations, grant e RLS;
- TASK-006–TASK-010 per proiezione, control plane, prezzi, immagini e query contract;
- TASK-011 per connessione staging e backend/auth readiness;
- TASK-012 per shell cliente guest/data-safe, stati readiness e baseline accessibile;
- TASK-017 per cache catalogo, freshness e invalidazione;
- TASK-020 per OAuth, deep link e session lifecycle, implementati nel confine Auth
  corrente;
- TASK-021–TASK-032 per dati cliente e flussi commerciali;
- TASK-033–TASK-037 per hardening, resilienza, osservabilità, accessibilità e
  performance.

Questo documento preserva le decisioni Flutter, Riverpod, go_router, MVVM e design
system già adottate. TASK-011 aggiunge readiness tecnica, TASK-012 la shell guest
data-safe e TASK-020 il solo lifecycle Auth customer; nessuno aggiunge schema,
DTO commerciali, inventory o dati reali.
