# Mobile architecture

## Stack

- Flutter e Dart stable;
- soli target Android/Kotlin e iOS/Swift;
- Material 3 con adattamenti idiomatici iOS;
- Riverpod per stato e dependency injection;
- go_router per navigazione dichiarativa;
- Supabase Flutter come client futuro;
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
è autorizzato, accetta soltanto il kill switch Google disabilitato. Il flag non
implementa login, sessione o deep link: queste responsabilità restano TASK-020.

`ClientMerchandiseControlApp` compone tema, localizzazione e router.
`StatefulShellRoute.indexedStack` mantiene quattro branch — Home, Catalogo, Carrello e
Account — e ne preserva lo stato. Dalle tab root secondarie il back ritorna a Home.

In development senza configurazione l'app resta offline e usabile e mostra un banner
diagnostico debug accessibile. Staging e production incompleti sono errori espliciti,
senza fallback tra ambienti. Diagnostica ed errori espongono soltanto ambiente e
indicatori booleani, mai URL, key o callback raw.

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
development mostra il solo banner tecnico debug. Fino a TASK-020 le opzioni Auth SDK
disabilitano persistence, auto-refresh e deep-link detection, evitando di importare
prematuramente il session lifecycle.

## Design system

`AppTheme` è l'unico composition root light/dark. Token primitivi, semantic colors e
widget foundation sono descritti in `DESIGN-SYSTEM.md`. Le feature non definiscono
palette, font scale, breakpoint o spacing paralleli.

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
- TASK-020 per OAuth, deep link e session lifecycle;
- TASK-021–TASK-032 per dati cliente e flussi commerciali;
- TASK-033–TASK-037 per hardening, resilienza, osservabilità, accessibilità e
  performance.

Questo documento preserva le decisioni Flutter, Riverpod, go_router, MVVM e design
system già adottate. TASK-011 aggiunge soltanto readiness tecnica staging: non aggiunge
flussi OAuth, deep link nativi, schema, DTO commerciali o dati reali.
