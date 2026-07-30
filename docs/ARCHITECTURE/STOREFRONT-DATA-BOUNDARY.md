# Storefront data boundary

## Scopo e stato

Questo documento definisce il confine logico fra dominio operativo, proiezione
Storefront e client pubblico. È un contratto normativo di TASK-003: non assegna ancora
nomi fisici a schema, tabelle, view, RPC, bucket o DTO e non applica migration.

I termini `MUST`, `MUST NOT`, `SHOULD` e `MAY` esprimono requisito, divieto,
raccomandazione e possibilità. Tutto ciò che non è esplicitamente pubblicabile è
privato per default.

## Flusso autorizzato

```text
Android/iOS/POS operativi
        |
        | eventi o dati operativi autorizzati
        v
Admin control plane + projector server-side
        |
        | proiezione pubblicata, minimizzata e shop-scoped
        v
Storefront read/write contracts
        |
        | publishable key + grant + RLS + eventuale customer identity
        v
ClientMerchandiseControl
```

Non esiste un flusso diretto dal client pubblico verso inventory, POS o client
operativi. Un errore Storefront MUST NOT attivare fallback verso tabelle o API
operative.

## Livelli di verità

| Verità | Contenuto | Decision owner | Writer/enforcer | Consumer pubblico |
|---|---|---|---|---|
| Operativa | Inventory interna, costo, stock grezzo, storico, sessioni di lavoro, vendita fiscale e movimenti | Domini operativi e POS secondo ownership cross-repo | Android, iOS, POS e servizi operativi autorizzati | Mai |
| Pubblicazione | Quali shop, categorie, prodotti, immagini e promozioni sono visibili | Admin Console | Projector/server Storefront | Sì, dopo pubblicazione |
| Commerciale | Prezzo cliente, promozione valida, disponibilità commerciale e opzioni di fulfillment | Admin/server; POS resta owner della vendita fiscale | Servizi server-authoritative | Sì, come valore rivalidabile |
| Customer | Identità, preferenze, profilo, carrello, intenti e ordini del cliente | Customer per i propri dati, server per invarianti | API/RPC customer-scoped | Soltanto il customer autorizzato |

Supabase è piattaforma di persistenza ed enforcement; non decide autonomamente cosa
pubblicare o quale prezzo applicare.

## Shop scope

Ogni risorsa Storefront MUST appartenere a uno `shop_id` UUID. Il valore ricevuto dal
client è un selettore non fidato:

- guest: la risorsa è leggibile soltanto se shop e risorsa sono pubblicati e attivi;
- customer: oltre alle condizioni pubbliche, dati e mutazioni private richiedono
  ownership/membership server-authoritative;
- server: ogni proiezione e mutazione valida lo shop e non accetta scope implicito o
  cross-shop;
- cache key, deep link e route MUST includere lo shop quando il dato è shop-scoped, ma
  non costituiscono autorizzazione.

Un identificatore assente, malformato, sconosciuto o non autorizzato produce risposta
vuota o errore sicuro secondo il contratto della risorsa, mai un default shop globale.

## Risorse pubblicabili

La futura allowlist Storefront MAY comprendere soltanto risorse logiche equivalenti a:

- shop pubblico: identificatore, nome pubblico, stato pubblicato e opzioni commerciali
  approvate;
- categoria pubblicata: identificatore pubblico, label, ordinamento e stato visibile;
- prodotto pubblicato: identificatore pubblico, nome, descrizione cliente, categoria,
  attributi commerciali approvati e stato visibile;
- prezzo cliente: valuta, importo effettivo, eventuale prezzo precedente e intervallo di
  validità calcolati server-side;
- promozione: label, regole già risolte per la presentazione e intervallo valido;
- disponibilità commerciale: stato coarse-grained approvato, non quantità inventory
  grezza;
- immagine pubblicata: variante derivata, MIME/dimensioni approvati, URL pubblico o
  riferimento CDN e versione/cache metadata non sensibili;
- opzioni di ritiro, consegna o prenotazione già validate per lo shop.

La presenza nell'allowlist logica non espone automaticamente un campo. TASK-005 e
TASK-010 devono definire schema e DTO minimizzati, grant, RLS e contract test.

## Campi e dati vietati

Il read model Storefront MUST NOT contenere:

- costo di acquisto, margine interno, regole di pricing non pubbliche o prezzo
  operativo grezzo;
- quantità stock raw, ubicazione interna, soglie operative o movimenti di magazzino;
- supplier identity, condizioni fornitore, note interne o documenti di acquisto;
- tombstone, watermark, outbox, revisioni interne, lease, lock, retry o metadata di
  sincronizzazione;
- sessioni operative, diagnostica, audit log o storico non destinato al customer;
- ruoli staff, membership interne, device, credential, PIN, hash o stato lockout;
- chiavi, token, project ref, connection string, signed management URL o path di bucket
  sorgente;
- dati fiscali POS, sequenze documento, movimenti vendita o dati di altri clienti;
- email, telefono, indirizzo o altro dato personale dentro risorse guest;
- identificatori interni che permettano correlazione o accesso a superfici operative,
  quando non siano il deliberato identificatore pubblico.

La minimizzazione si applica anche a errori, log, analytics, cache, immagini, metadata e
payload Realtime.

## Denylist di tabelle, schemi e interfacce

Il client pubblico MUST NOT interrogare direttamente:

- schemi `auth`, `app_private`, `storage`, `realtime` o altri schemi interni;
- qualunque tabella `inventory_*`, incluse categorie, prodotti, prezzi, immagini e
  supplier operative;
- `shops`, `shop_members`, `shop_devices`, `profiles`, `shared_sheet_sessions`,
  `shared_sheet_session_diagnostics`, `sync_events` e `audit_logs`;
- tabelle o view con prefissi `platform_`, `pos_`, `staff_` o equivalenti futuri;
- RPC con prefissi `platform_`, `pos_`, `staff_`, `shop_staff_`, `shop_device_` o
  `product_image_`;
- RPC operative `record_sync_event`, `mobile_linked_shops` e qualsiasi interfaccia
  inventory consumata da Android/iOS;
- API HTTP Admin/POS, endpoint Supabase Management, SQL diretto, GraphQL operativo o
  specifica OpenAPI del progetto;
- bucket sorgente, API di upload/cleanup amministrative o signed URL interne.

La denylist è prefix-inclusive e non esaustiva. Una superficie nuova resta vietata finché
il contract owner non la aggiunge a un contratto Storefront versionato.

## Prezzi, promozioni e disponibilità

- Il client MUST mostrare i valori commerciali restituiti dal server senza
  ricalcolarli da costo, stock o regole locali.
- Importo, valuta, sconto, intervallo temporale e shop MUST essere coerenti nello stesso
  payload o nella stessa versione contrattuale.
- Il client MAY formattare il valore per locale, ma non ne cambia semantica o
  precisione.
- Cache e UI MUST distinguere dato fresco, stale e non disponibile.
- Carrello, reservation e checkout futuri MUST rivalidare prezzo, promozione,
  disponibilità e fulfillment sul server.
- Una disponibilità pubblica non prova stock fisico né costituisce una reservation.
- In caso di conflitto, il server rifiuta o restituisce un nuovo stato; il client non
  forza il valore precedente.

## Immagini

La pubblicazione immagini è una proiezione separata dalla gestione asset:

1. Admin approva source, associazione prodotto/shop e stato di pubblicazione.
2. Un componente server produce o seleziona la variante pubblica.
3. Il Storefront espone soltanto il riferimento pubblico versionato.
4. Il client consuma la variante pubblica e applica caching coerente con la versione.

Originale privato, bucket/path sorgente, upload token, cleanup API, signed management URL
e diagnostica restano vietati. La rimozione o revoca di un'immagine deve poter
invalidare la variante pubblica senza rendere accessibile la sorgente.

## Customer order e vendita fiscale

Un ordine cliente e una vendita fiscale POS sono entità distinte:

- l'ordine esprime intenti, righe e fulfillment del customer;
- il server salva snapshot e transizioni secondo il contratto order;
- il POS può ricevere un handoff esplicito e produrre una vendita fiscale separata;
- identificatori, stati ed eventi non vengono riutilizzati come se fossero la stessa
  entità;
- il completamento fiscale non viene inferito dalla UI cliente;
- retry e handoff MUST essere idempotenti, correlabili e auditabili.

Il client pubblico non scrive stock, movimenti o documenti fiscali.

## Boundary delle mutazioni

Una futura mutazione Storefront è ammessa soltanto se:

1. usa un'interfaccia Storefront/customer esplicitamente versionata;
2. autentica il customer quando la capability non è guest;
3. verifica ownership, shop e stato server-side;
4. valida input e transizione di dominio;
5. usa una idempotency key quando il retry può duplicare effetti;
6. registra audit o correlation metadata minimizzati quando richiesto;
7. restituisce un esito sicuro senza dettagli interni.

La publishable key, una route visibile o una riga presente in cache non soddisfano questi
requisiti.

## Comportamento fail-closed

| Condizione | Comportamento |
|---|---|
| Storefront non configurato | Nessun accesso operativo: development resta offline; staging/production falliscono come configurazione invalida senza fallback |
| Shop non valido, non attivo o non pubblicato | Nessun dato dello shop |
| Risorsa non pubblicata o fuori finestra | Omissione o stato non disponibile |
| Grant o RLS negano | Errore sicuro, nessun retry privilegiato o fallback inventory |
| Payload non conforme alla versione | Contract mismatch, nessun parsing permissivo |
| Rete assente | Soltanto cache classificata; nessun prezzo/stock inventato |
| Dato commerciale stale al checkout | Rifiuto o revalidation server-side |
| Proiezione incompleta | Stato indisponibile; mai join client-side con dati operativi |

## Verifiche future obbligatorie

I task di implementazione MUST dimostrare:

- allowlist field-by-field e denylist con scan statico;
- grant e RLS guest/customer, inclusi tentativi cross-shop e cross-user;
- assenza di costo, stock raw, supplier, metadata sync e dati personali nei payload
  guest;
- commercial revalidation e finestre temporali;
- separazione fra immagini pubbliche e management;
- separazione order/POS con retry idempotente;
- nessun fallback verso tabelle, RPC o API operative;
- errori, log, cache e analytics sanitizzati.
