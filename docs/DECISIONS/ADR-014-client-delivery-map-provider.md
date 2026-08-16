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
