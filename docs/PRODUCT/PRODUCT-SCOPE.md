# Product scope

ClientMerchandiseControl è il client mobile pubblico dell'ecosistema Merchandise
Control. Consente alle persone di consultare l'offerta pubblicata da un singolo negozio
e, nei task futuri, di completare azioni commerciali controllate server-side.

## Problema

Il dominio operativo contiene informazioni che non sono adatte al pubblico: quantità di
magazzino, costi, fornitori, note interne e stati di lavorazione. Un cliente ha invece
bisogno di un'esperienza semplice e affidabile che mostri soltanto ciò che il negozio ha
scelto di pubblicare, con prezzi, promozioni e disponibilità commerciali coerenti.

## Visione e valore

L'app deve diventare il punto di accesso mobile del cliente al negozio:

- consultazione anonima e rapida del catalogo pubblico;
- informazioni commerciali comprensibili e mai più precise della fonte server-side;
- continuità tra scoperta, preferiti, carrello, prenotazione o ordine;
- recupero esplicito da rete debole, dati scaduti e variazioni commerciali;
- accessibilità e localizzazione come requisiti del prodotto, non rifiniture finali.

Per il negozio il valore atteso è un canale pubblico governabile da Admin Console, senza
esporre né duplicare l'inventory operativa e senza spostare decisioni di pubblicazione o
fulfillment nel client.

## Mercato e contesto iniziale

- Mercato iniziale: Cile.
- Valuta commerciale: CLP, visualizzata senza decimali.
- Lingua sorgente e fallback: spagnolo cileno-neutrale.
- Modello iniziale: un singolo negozio selezionato dalla configurazione o dal futuro
  contratto Storefront.
- Evoluzione prevista: ogni dato pubblico sarà shop-scoped tramite un futuro `shop_id`;
  la semantica e l'ownership del campo appartengono a TASK-003 e ai task backend.
- Piattaforme: Android e iOS dalla stessa codebase Flutter.

Non vengono assunti dimensione del negozio, settore merceologico, età, reddito o
abilità del cliente. Questi aspetti richiedono ricerca o dati reali futuri.

## Utenti e attori

Gli utenti diretti sono persone che esplorano o acquistano dal negozio, anonime o
autenticate quando una funzione lo richiede. I profili comportamentali e i loro jobs sono
descritti in `TARGET-USERS-AND-JOBS.md`.

Gli attori indiretti sono:

- personale del negozio, che decide contenuti e condizioni tramite Admin Console;
- sistemi operativi Android/iOS e Win7POS, che restano fonti operative;
- supporto e operations, nei task futuri di osservabilità e rilascio.

Il client non concede autorità a nessuno di questi attori e non è un confine di
autorizzazione.

Il personale del negozio è uno stakeholder esterno e non usa l'app cliente per operare.
L'esplorazione pubblica è anonima; autenticazione e profilo arrivano soltanto per
funzioni che richiedono identità, consenso o dati personali.

## Confine di sistema

- Admin Console governa pubblicazione, copy, immagini, prezzi, promozioni, disponibilità
  commerciale e fulfillment.
- Il futuro dominio Storefront espone una proiezione pubblica protetta server-side.
- Il client legge tale proiezione e invia intenti; non legge tabelle inventory e non
  decide prezzi, stock, hold, ordine o pagamento.
- Disponibilità pubblica e quantità operative sono concetti distinti.
- Ordine cliente e vendita fiscale restano eventi distinti fino al relativo handoff.
- Dati sensibili, autorizzazioni, rivalidazioni e idempotenza sono sempre server-side.

Il dettaglio architetturale è in `docs/ARCHITECTURE/STOREFRONT-DATA-BOUNDARY.md`.

## Dipendenze cross-repo

- Admin Console e Supabase dovranno produrre e proteggere la proiezione Storefront.
- Android/iOS operativi e Win7POS restano fonti di processi e inventory, mai dipendenze
  runtime dirette del client.
- TASK-003 assegna ownership e contratto; TASK-004–TASK-011 realizzano ambienti, schema,
  proiezioni, query e connessione staging.
- Il client resta avviabile offline finché quel contratto non esiste. La futura
  esperienza offline del catalogo, inclusi cache, freshness e invalidazione, appartiene
  a TASK-017.

## Principi di prodotto

1. Il catalogo pubblico è consultabile senza login.
2. Ogni informazione commerciale proviene da una fonte Storefront verificabile.
3. Prezzo, promozione, costo aggiuntivo e disponibilità non vengono mai inventati o
   ricostruiti dal client.
4. Prima di una conferma commerciale il server rivalida condizioni e disponibilità.
5. La UI preserva contesto e input recuperabili durante errori o riconnessione.
6. Le immagini migliorano la comprensione ma non bloccano contenuto e azioni essenziali.
7. Privacy, accessibilità, localizzazione e sicurezza falliscono in modo chiuso.
8. Un solo obiettivo primario per schermata riduce conflitti e pressione indebita.

## Risultati attesi, non metriche inventate

I task futuri potranno misurare, con consenso e telemetria privacy-safe:

- successo e tempo necessario nei journey principali;
- errori recuperabili e abbandoni dopo una rivalidazione;
- comprensione di prezzo, promozione e disponibilità;
- stabilità, performance e accessibilità sulla matrice device prevista.

TASK-002 non fissa target numerici senza baseline né abilita analytics.

## Non-obiettivi

- amministrare catalogo, prezzi, stock, utenti o ordini dal client;
- esporre costi, fornitori, quantità operative o note interne;
- sostituire Admin Console, i client operativi o Win7POS;
- offrire funzioni multi-store prima del relativo contratto;
- creare marketplace, programma fedeltà, social feed o advertising;
- scegliere provider di pagamento o logistica in anticipo;
- collegare backend, dati reali o feature commerciali in TASK-002.

## Possibili capability post-MVP

Multi-store, loyalty, advertising, social commerce e altre estensioni non sono approvate
né inserite automaticamente nel backlog. Potranno essere valutate soltanto dopo
evidenza d'uso, stabilità dell'MVP e autorizzazione dell'utente; TASK-002 non assegna
priorità o ownership a tali ipotesi.

## Confine di TASK-002

TASK-002 formalizza questa direzione, la brand foundation provvisoria, i principi UX e i
token applicati alla shell placeholder. Le capability restano attivate esclusivamente
dal task proprietario nel Master Plan.
