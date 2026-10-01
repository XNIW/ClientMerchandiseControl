# ADR-014 — Google Maps nativo dietro adapter fail-closed per il tracking delivery

- Stato: ACCETTATA
- Data: 2026-08-16
- Task: TASK-044, TASK-045

## Contesto

La mappa del dettaglio ordine deve funzionare su Android e iOS Flutter, avere copertura
utile in Cile, non introdurre un routing o un ETA calcolato dal Client e restare
deterministica nei test. Il repository non contiene e non deve contenere chiavi mappa.
Il mandato non autorizza l'attivazione di un servizio a pagamento.

Le fonti ufficiali consultate il 2026-08-16 attestano che:

- `google_maps_flutter` 2.18 integra gli SDK mobili nativi Android/iOS e richiede
  Android 24 e iOS 14;
- la matrice Google Maps Platform riporta copertura cartografica in Cile;
- lo SKU mobile `Maps SDK` è riportato con uso senza costo nella tariffa corrente, ma
  configurazione, billing account e API key restano prerequisiti del provider;
- Google raccomanda chiavi distinte e ristrette per application/package, certificato
  Android, bundle iOS e sole API necessarie.

Riferimenti:

- https://developers.google.com/maps/flutter-package/config
- https://developers.google.com/maps/coverage
- https://developers.google.com/maps/billing-and-pricing/pricing
- https://developers.google.com/maps/api-security-best-practices

## Decisione

TASK-045 userà il plugin mantenuto `google_maps_flutter` esclusivamente dietro un
`DeliveryMapAdapter` dell'applicazione. Il widget Google non sarà istanziato quando una
di queste condizioni manca: feature flag esplicito, chiave nativa valida per
l'ambiente, snapshot owner-scoped `liveCourier`, sessione attiva e posizione fresca.
In assenza di configurazione l'esito è testuale e fail-closed, non una mappa vuota.

Android e iOS useranno chiavi diverse, fornite fuori Git alla build nativa e ristrette
rispettivamente a package+SHA di firma e bundle identifier; entrambe saranno limitate
al solo Maps SDK. Nessuna chiave abilita Routes, Places, geocoding o telemetria
applicativa. Coordinate, order ID, customer ID e alias courier non entrano in parametri
tile, log, analytics o crash report.

L'adapter pubblico accetta soltanto tre marker bounded (negozio, destinazione,
corriere), un viewport e callback di recenter. Un fake deterministico copre unit,
widget, golden e CI senza rete o chiavi. Il marker non viene interpolato e nessuna
polyline viene disegnata finché un futuro servizio server-side autorizzato non fornisce
un percorso valido.

L'activation switch production resta `OFF` finché billing/configurazione, quote,
restrizioni delle due chiavi e validazione su device non sono attestati. Questa
decisione non attiva un servizio esterno e non promette che la tariffa rimanga
invariata.

## Conseguenze

- Android/iOS possono usare una base cartografica consistente senza implementare tile
  lifecycle o licenze custom nel Client.
- test e CI non dipendono dalla rete del provider.
- una provider exception degrada alla stessa alternativa testuale accessibile;
  timeline, ETA server-side e freshness restano disponibili.
- il provider può essere sostituito implementando l'adapter senza cambiare il dominio
  tracking.
- serving production richiede un activation record separato, ma la chiave mancante non
  blocca codice, test o staging con configurazione dedicata.

## Alternative considerate

- **MapLibre + tile provider**: valida per ridurre il lock-in, ma richiede comunque un
  servizio tile autorizzato, policy di caching/attribution, verifica di copertura Cile e
  un contratto operativo aggiuntivo non già disponibile. Rinviata, non esclusa.
- **Apple MapKit**: non offre una soluzione Android equivalente nello stesso adapter
  operativo iniziale.
- **Static map server-side**: meno interattiva e richiede un proxy/signing service;
  non soddisfa recenter e aggiornamento marker isolato.
- **Mappa custom o coordinate su canvas**: scartata perché simulerebbe contesto
  geografico e qualità cartografica non verificati.

## Estensione di sviluppo TASK-054 — indirizzo (2026-09-28)

Il nuovo mandato autorizza una scelta tecnica in assenza di precedente decisione
per ricerca/reverse. Si riusa Google Maps SDK già presente per il pin indirizzo,
con `GoogleAddressMapPort` distinto dal tracking. Attivazione solo staging con
`ADDRESS_MAPS_ENABLED=true` e `DELIVERY_MAPS_NATIVE_CONFIGURED=true`; chiavi native
ristrette già approvate secondo questo ADR. Nessuna attivazione o nuovo billing.

Ricerca e reverse usano l'adapter concreto Photon, API GeoJSON, con endpoint
`ADDRESS_PHOTON_ORIGIN` HTTPS esplicitamente approvato, `ADDRESS_SEARCH_ENABLED=true`,
`ADDRESS_PROVIDER_APPROVED=true`, `APP_ENV=staging`. Non esiste endpoint pubblico
implicito. La decisione conserva Google per la mappa ma evita di imporre un nuovo
servizio Places a pagamento per memorizzare indirizzi; Photon permette un servizio
compatibile scelto/gestito dall'owner. Non è autorizzato avviare hosting o acquistarlo.

Fonti primarie consultate: [Photon README/API](https://github.com/komoot/photon/blob/master/README.md),
[API v1](https://github.com/komoot/photon/blob/master/docs/api-v1.md),
[licenza software Apache2.0](https://github.com/komoot/photon/blob/master/LICENSE),
[licenza dati OSM](https://www.openstreetmap.org/copyright) e
[linee guida attribuzione](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines).
Il server demo Photon non offre SLA, limita utilizzi e può sospendere richieste:
non viene selezionato automaticamente. Il software non impone una tariffa d'uso;
serving/rete e condizioni dell'endpoint restano da approvare. La licenza software
non sostituisce ODbL dei dati: attribuzione OSM e riferimento licenza sono visibili
nell'editor. L'owner deve verificare condizioni/privacy dell'endpoint prima di ON.

Il provider riceve solo query indirizzo o coordinate del pin, mai identità/sessione
Supabase; niente log/telemetria o cache persistente provider. Una pagina di otto
risultati vive in memoria fino a query/dispose/cambio account. HTTPS, niente redirect,
risposta max64KiB, timeout6s, cooldown429 max300s, latest-query-wins e invalidazione
account proteggono le richieste. Input manuale resta completo con provider OFF,
rete/GPS negati o imprecisi. Cambiare campi geografici invalida il pin precedente;
la conferma pin conserva la coordinata scelta. Solo il server decide zona/fee/slot.

Test transport controllato e widget non attestano servizio/chiave/GPS reali.
Dopo configurazione approvata eseguire E2E-054-R05/R26 su Android/iOS; finché manca,
ADDRESS_PROVIDER_LIVE resta NOT_RUN e le capacità restano OFF per default.
