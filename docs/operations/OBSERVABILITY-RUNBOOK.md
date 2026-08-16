# Observability e diagnostica privacy-safe

## Stato provider

Il Client usa `ObservabilityPort` come unico boundary. La configurazione di default è:

| Ambiente | Adapter | Export remoto | Fallback |
|---|---|---|---|
| development | logger locale strutturato | vietato | payload JSON redatto in `dart:developer` |
| test | no-op tramite provider di default/override | vietato | collector esplicito soltanto nel test |
| staging | no-op | disabilitato finché exporter e consenso non sono iniettati | nessun invio |
| production | no-op | disabilitato finché exporter e consenso non sono iniettati | nessun invio |

`ConfigurableProductionObservabilityPort` accetta exporter analytics e crash distinti,
consenso, sampling, rate limit e limiti buffer. Se una capability viene marcata enabled
senza il relativo exporter, la configurazione è rifiutata. Nessun DSN, endpoint o secret
è presente nel repository.

Il buffer è solo in memoria, bounded per numero e byte e usato soltanto dopo un errore
di un exporter configurato. Non persiste payload su disco e applica eviction FIFO.

## Consent policy

- `none`: nessun evento o crash remoto;
- `diagnostics`: soltanto failure, reconnect, performance e crash sanitizzati;
- `analytics`: anche view e outcome commerce bounded;
- il consenso profilo esistente non viene reinterpretato automaticamente come consenso
  analytics;
- revoke richiede una nuova composizione del port con `none`; gli eventi successivi non
  vengono esportati e non esiste buffer persistente da cancellare;
- sviluppo locale non costituisce export remoto e usa soltanto schemi già redatti.

## Event catalog

Gli eventi sono factory tipizzate: i caller non possono allegare mappe arbitrarie.

| Evento | Attributi ammessi |
|---|---|
| `appStart` | cold/warm |
| `screenView` | enum screen, mai path o ID |
| `catalogQueryResult` | browse/search/filter/append/refresh, outcome, bucket count/cache/duration, failure taxonomy |
| `addToCartOutcome` | outcome, bucket quantità, failure taxonomy |
| `checkoutStep` | enum step, outcome, failure taxonomy |
| `orderCreated` | outcome, failure taxonomy |
| `orderStatus` | gruppo status e source, mai order ID |
| `notificationRouting` | destinazione enum e outcome, mai route token |
| `trackingAvailability` | mode e availability, mai coordinate/URL/session ID |
| `trackingSignal` | disconnect/reconnect/duplicate/out-of-order e outcome |
| `backendFailure` | component, category, retryable, correlation ID generato localmente |
| `performanceBudgetViolation` | operation e bucket budget/observed |

Sono vietati nome, email, telefono, indirizzo, coordinate, tracking URL, token Auth,
OAuth code, payment secret, query raw, UUID di dominio, contenuto carrello, push token,
payload backend raw ed exception message. Il crash payload contiene solo categoria,
component, fingerprint one-way e breadcrumb bounded con il solo nome evento.

## Tassonomia errori

`offline`, `timeout`, `unauthorized`, `invalidInput`, `conflict`, `unavailable`,
`invalidPayload`, `rateLimited`, `unexpected`. Le feature mappano esclusivamente il
proprio enum in questa tassonomia; `toString()` dell'errore non attraversa il port.

## Procedura diagnostica

| Segnalazione utente | Controlli consentiti | Non cercare/registrare |
|---|---|---|
| app non parte | `appStart`, crash category/component, release/build | nome, email, config raw |
| login non riesce | `backendFailure component=auth`, category e rate | OAuth code, token, callback completa |
| catalogo vuoto/lento | `catalogQueryResult`, cache, outcome, duration bucket; performance violation | query raw, product ID, URL immagine |
| aggiunta carrello fallita | `addToCartOutcome`, quantità bucket, failure | contenuto carrello o publication ID |
| checkout bloccato | sequenza `checkoutStep`, failure e `orderCreated` | address ID, indirizzo, quote/order UUID, payment secret |
| ordine non aggiornato | `orderStatus` group/source e backend failure orders | order code/ID o righe ordine |
| notifica apre pagina errata | `notificationRouting` destination/outcome | route token o push token |
| tracking assente/stale | `trackingAvailability`, `trackingSignal` | coordinate, courier ID, tracking URL/session |

Per ogni caso verificare prima environment, release version e activation flag. Correlare
solo con `SafeCorrelationId` generato dal Client; non copiare UUID di dominio. Se manca
un segnale, riprodurre in staging con dati sintetici e adapter collector, non aumentare
temporaneamente il logging a payload raw.

## Admin

L'Admin mantiene l'audit operativo in tabelle/RPC canoniche, separato da analytics e
non soggetto a sampling. Le API POS esistenti restituiscono un `serverRequestId` safe e
hashano l'edge correlation; i mutation boundary con correlation ID la validano prima
del passaggio agli RPC. Gli error response sono strutturati e non includono service
role, password DB o payload Supabase raw. TASK-035 non modifica l'audit né aggiunge un
exporter Admin perché non è configurato alcun provider esterno autorizzato.

## Incidenti di leakage

1. disabilitare l'exporter/activation flag senza disabilitare catalogo o account;
2. revocare/ruotare la credenziale nel secret store esterno, mai nel repository;
3. preservare soltanto ID incidente, release, event name e fingerprint safe;
4. eliminare payload remoti secondo retention/provider policy;
5. correggere redactor/schema e aggiungere un test negativo prima della riattivazione;
6. non riportare il valore leaked in issue, PR, log o evidence.
