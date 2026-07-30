# Target users e jobs-to-be-done

I profili sono situazioni d'uso, non personas demografiche. Una stessa persona può
attraversarne più di una. Non vengono attribuiti età, genere, reddito, disabilità,
competenza tecnica o comportamento non supportati da ricerca.

## Profili comportamentali

| Profilo | Obiettivo | Necessità e vincoli | Frustrazione da evitare |
|---|---|---|---|
| Esploratore anonimo | capire rapidamente cosa offre il negozio | accesso senza account, orientamento chiaro, informazioni essenziali | login prematuro, catalogo vuoto senza spiegazione |
| Cliente con acquisto pianificato | trovare un articolo o una categoria specifica | ricerca, filtri comprensibili, condizioni confrontabili | risultati opachi, prezzi ambigui |
| Cliente sensibile a disponibilità e tempo | sapere se vale la pena procedere | stato commerciale onesto, ritiro/consegna e tempi confermati dal server | falsa urgenza o stock operativo esposto |
| Cliente di ritorno | riprendere preferiti, carrello o ordine | continuità, sessione sicura, stato e prossima azione | perdita silenziosa di input o contesto |
| Cliente su rete o dispositivo limitato | completare il journey con connettività instabile | contenuto essenziale prima delle immagini, retry e stato di freschezza | spinner indefiniti, schermate bloccate |
| Cliente con esigenze di accesso diverse | leggere, comprendere e azionare ogni funzione | testo scalabile, Semantics, contrasto, target ampi, nessuna informazione solo colore | contenuto troncato o controlli non annunciati |

## Jobs-to-be-done

| Momento | Job | Esito desiderato |
|---|---|---|
| Quando apro l'app | voglio capire dove sono e cosa posso fare senza registrarmi | raggiungo catalogo e informazioni pubbliche |
| Quando cerco un articolo | voglio restringere l'offerta con termini e filtri comprensibili | trovo un risultato rilevante o un vuoto recuperabile |
| Quando valuto un prodotto | voglio capire prezzo corrente, eventuale promozione e disponibilità | decido senza informazioni fuorvianti |
| Quando salvo o aggiungo | voglio ritrovare la mia selezione e sapere se è ancora valida | stato persistente e condizioni rivalidate |
| Quando mi viene chiesto l'accesso | voglio sapere perché serve e cosa accade ai miei dati | concedo solo il minimo necessario |
| Quando confermo | voglio vedere costi, modalità e condizioni aggiornati | consenso informato e risultato non duplicato |
| Quando qualcosa cambia | voglio capire cosa è cambiato e scegliere come continuare | vecchio/nuovo valore, input preservato, azione esplicita |
| Quando la rete fallisce | voglio distinguere dati disponibili, scaduti e non caricati | posso riprovare senza perdere contesto |
| Dopo una richiesta | voglio conoscere stato, prossima azione e canale di supporto | tracciamento comprensibile e coerente |

## Momenti critici

- primo avvio e consenso eventuale;
- empty state, offline, timeout e dati stale;
- variazione di prezzo o disponibilità;
- autenticazione e recupero sessione;
- conferma di hold, ordine, pagamento o cancellazione;
- ritorno da notifica o deep link;
- testo al 200%, screen reader e orientamento landscape.

I task futuri devono validare questi profili con ricerca, analytics privacy-safe e test di
usabilità prima di introdurre segmentazioni più specifiche.
