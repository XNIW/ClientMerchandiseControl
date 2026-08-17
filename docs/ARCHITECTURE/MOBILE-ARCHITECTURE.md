# Mobile architecture

## Stack

- Flutter e Dart stable;
- soli target Android/Kotlin e iOS/Swift;
- Material 3 con adattamenti idiomatici iOS;
- Riverpod per stato e dependency injection;
- go_router per navigazione dichiarativa;
- HTTP bounded per readiness e Storefront pubblico, Supabase Flutter soltanto per Auth customer;
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
compile-time [`CMC-CLIENT-CONFIG 1.3.0`](ENVIRONMENT-STRATEGY.md): legge esattamente
`APP_ENV`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `AUTH_REDIRECT_URI` e
`GOOGLE_AUTH_ENABLED`, più `STOREFRONT_SHOP_SLUG` e l'attestazione production
`RELEASE_CONFIG_SHA256`, valida l'intera matrice prima di qualunque inizializzazione e
fornisce al bootstrap soltanto lo stato già normalizzato.

Development non accetta valori backend/callback né Google attivo e non inizializza
Supabase. Staging ammette l'inizializzazione SDK soltanto con tuple, callback e flag
completi; TASK-011 la completa con un health check Auth ufficiale e privo di dati.
Production non eredita mai staging e accetta soltanto il kill switch Google
disabilitato. Anche staging rifiuta `GOOGLE_AUTH_ENABLED=true`: il sentinel HTTPS
`.invalid` non è instradabile e non è registrato nativamente. OAuth può essere
riattivato soltanto con dominio posseduto e App Links/Universal Links verificati.

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
- `initializing`: probe diagnostico staging in corso;
- `ready`: `GET /auth/v1/health` concluso con HTTP 200 e payload
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
mappa gli esiti senza inizializzare lo SDK Auth; il controller Riverpod avvia un solo
check staging, riusa l'operazione concorrente e permette soltanto retry manuale. Non
esistono polling, auto-retry o recheck su resume in TASK-011.

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

TASK-013 introduce `StorefrontRepository` e la prima implementazione
`SupabaseStorefrontRepository`: il primo render usa esclusivamente l'RPC
`storefront_home_v1`, con shop slug esplicito, limiti bounded, timeout, cancellazione e
mapping DTO allow-listed. Nessun widget accede direttamente a Supabase; payload con
campi o tipi fuori contratto falliscono chiusi e gli URL immagine devono appartenere al
bucket pubblico `storefront-product-images`.

TASK-014 estende lo stesso adapter con i soli RPC pubblici versionati
`storefront_categories_v1` e `storefront_catalog_v1`. Il cursor keyset resta opaco,
ogni pagina conserva `catalogVersion` e sort server, e il controller scarta risposte
stale o sequenze che mescolano versioni diverse. La griglia è un singolo
`CustomScrollView` lazy; selezione categoria, refresh e load-more sono separati e un
errore incrementale conserva gli elementi già visibili fino al retry esplicito. Le
immagini usano esclusivamente la variante pubblica `card`, con decode width bounded,
placeholder ed errore sicuro; nessun widget interroga tabelle o Storage direttamente.

TASK-015 aggiunge il solo RPC pubblico `storefront_search_v1`: query normalizzata tra
2 e 120 caratteri, debounce di 300 ms, cancellation/generation guard e cursor keyset
separato. Categoria e ricerca sono componibili nel contratto Search; disponibilità,
sconto e i quattro ordinamenti restano parametri server-side del contratto Catalog.
L'interfaccia disabilita esplicitamente i filtri non supportati durante Search, invece
di simulare una composizione client-side. Ogni cambio criterio annulla la sequenza
precedente, valida query e versione restituite e riparte dalla prima pagina.

TASK-016 aggiunge `storefront_product_detail_v1` nello stesso adapter allowlisted.
La route `/product/:publicationId` accetta soltanto il publication UUID pubblico e
fallisce chiusa prima della rete per valori invalidi. Un controller family auto-dispose
isola lifecycle, cancellation e retry di ogni dettaglio. Il payload riusa la shape
pubblica strict, verifica catalog version e identità richiesta/restituita; unavailable
non distingue shop assente da prodotto non pubblicato. La UI usa soltanto l'immagine
pubblica `detail`, prezzi CLP, promozione, availability commerciale e capability di
fulfillment, senza quantità stock, inventory ID o azioni future simulate.

TASK-019 separa il browsing guest dal bootstrap Auth: un transport HTTP PostgREST
confinato invoca soltanto funzioni `storefront_*_v1`, usa la publishable key, limita la
risposta a 2 MiB e riduce gli errori remoti a codici sanitizzati. Home avvia il fetch
pubblico durante il probe diagnostico e non viene cancellata da un esito Auth health;
timeout e offline del contratto Storefront governano direttamente cache e retry. Lo SDK
Supabase resta inizializzato esclusivamente dal boundary Auth quando Google è abilitato.
Il client HTTP pubblico è condiviso tra Storefront e health per riusare connessioni; il
probe diagnostico automatico parte due secondi dopo la composizione della shell, così
non compete con il first usable content, ma retry, timeout e cancellazione restano
invariati.

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
`AuthRepository` iniettabile separa dominio e SDK. Il lifecycle Google/PKCE resta
verificabile soltanto tramite harness isolati: il runtime distribuibile non apre il
browser e non registra callback OAuth. Cancel resta in corso finché un exchange
posseduto non è terminato e compensato con sign-out/purge; risultati obsoleti dopo
cancellazione, logout o dispose non possono ripristinare authenticated. Il restore
valido non forza navigazione.

`app_links` continua a servire i deep link Storefront pubblici. Android non espone più
l'intent filter Auth; iOS mantiene il solo scheme Storefront e inoltra i lifecycle allo
stesso singleton. Prodotto e categoria sono ammessi; ordine e notifica falliscono
chiuso finché non esiste un Universal/App Link HTTPS verificato.

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

Il logout registra l'intento durevole prima di operazioni fallibili, rimuove lo stato
locale e tenta `SignOutScope.global`. Una revoca remota fallita viene conservata in una
coda bounded e ritentata al bootstrap; un marker pending blocca sempre il restore.
L'intento viene rimosso soltanto dopo un nuovo login esplicito persistito. Un errore
offline può produrre un avviso customer-safe ma lo stato resta guest.

I deep link Storefront v1 usano soltanto lo scheme tecnico già registrato, host
`storefront` e path canonico `/{shop}/product/{uuid}` oppure
`/{shop}/category/{slug}`. Il decoder rifiuta altro shop, user-info, porta, query,
fragment, encoding non canonico e segmenti extra. Il coordinator accoda il cold link
fino alla prima route disponibile, deduplica consegne cold/warm ravvicinate e non
interpreta mai una route come autorizzazione. Dominio HTTPS, Universal Links/App Links
verificati e fallback web restano subordinati a brand e dominio reali di release.

I preferiti guest sono una preferenza locale distinta dalla cache commerciale: Drift
schema v2 conserva soltanto shop slug, publication UUID e timestamp, con limite 1.000.
Invalidazione o cleanup catalogo possono rendere un record orphan ma non cancellano la
scelta; la UI in quel caso mostra uno stato unavailable generico e non dati stale. Login,
restore e logout non riscrivono questa tabella e nessuna sync account viene simulata.
La condivisione usa il dialogo nativo con anchor iPad e payload localizzato contenente
solo nome pubblico e URI canonico, mai prezzo autoritativo, token, PII o metadata interni.

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
- TASK-013 per Home pubblica data-backed e primo repository RPC-only;
- TASK-014 per categorie pubbliche, griglia lazy e keyset pagination;
- TASK-015 per ricerca, filtri e ordinamento server-side;
- TASK-016 per dettaglio e disponibilità commerciale;
- TASK-017 per cache catalogo, freshness e invalidazione;
- TASK-018 per preferiti guest, share nativo e deep link Storefront strict;
- TASK-020 per il lifecycle Auth storico; TASK-033 disabilita OAuth distribuibile e
  mantiene il confine fail-closed fino a link HTTPS verificati;
- TASK-021–TASK-032 per dati cliente e flussi commerciali;
- TASK-033–TASK-037 per hardening, resilienza, osservabilità, accessibilità e
  performance.

Questo documento preserva le decisioni Flutter, Riverpod, go_router, MVVM e design
system già adottate. TASK-011 aggiunge readiness tecnica, TASK-012 la shell guest
data-safe, TASK-013–TASK-018 il consumer Storefront pubblico e TASK-020 il solo
lifecycle Auth customer; nessuno assegna al client commercial truth, inventory o grant
staff.
