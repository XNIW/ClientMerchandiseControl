# Target users e jobs-to-be-done

I profili sono situazioni d'uso, non personas demografiche. Una stessa persona può
attraversarne più di una. Non vengono attribuiti età, genere, reddito, disabilità,
competenza tecnica o comportamento non supportati da ricerca.

## Profili richiesti

| Profilo | Obiettivo | Necessità | Frustrazione | Vincoli | Job-to-be-done | Momenti critici |
|---|---|---|---|---|---|---|
| Visitatore anonimo | capire cosa offre il negozio | accesso senza account, orientamento e informazioni essenziali | login prematuro o catalogo opaco | nessuna sessione cliente | quando apro l'app, voglio esplorare l'offerta senza registrarmi | primo avvio, Home, catalogo vuoto |
| Cliente registrato | riprendere scelte e gestire i propri dati | accesso motivato, sessione sicura, profilo e privacy | perdita di contesto o richiesta dati eccessiva | autenticazione e consenso server-side | quando una funzione richiede identità, voglio accedere e tornare al punto iniziale | login, sessione scaduta, cancellazione account |
| Cliente con ordine attivo | capire stato e prossima azione | storico coerente, aggiornamenti verificati e recovery | stato ambiguo o successo prematuro | eventi e ordine autorevoli sono server-side | dopo la conferma, voglio seguire l'ordine senza rischiare duplicati | risposta incerta, cambio stato, notifica/deep link |
| Cliente con ritiro in negozio | sapere quando e dove ritirare | opzione configurata, luogo/orario e conferma chiari | ritiro promesso ma non disponibile | fulfillment governato dal negozio | quando scelgo il ritiro, voglio conoscere condizioni e readiness reali | selezione slot, hold scaduto, ordine pronto |
| Cliente con consegna | capire copertura, costo e tempi prima di confermare | indirizzo, condizioni e costo rivalidati | costi nascosti o copertura scoperta tardi | indirizzi e logistica sono dati sensibili/server-side | quando scelgo consegna, voglio decidere con tutti i costi e vincoli visibili | validazione indirizzo, variazione costo, mancata copertura |
| Operatore del negozio, stakeholder esterno | pubblicare condizioni corrette e ricevere intenti validi | Admin Console/POS e ownership chiare | client che modifica dati operativi | non usa l'app cliente come strumento operativo | quando aggiorno l'offerta, voglio che il client mostri solo la proiezione autorizzata | pubblicazione, prezzo, disponibilità, handoff ordine |

## Esigenze trasversali

- Su rete o dispositivo limitato, il contenuto essenziale precede le immagini e retry/
  freshness sono comprensibili.
- Con text scaling, screen reader o modalità di accesso diverse, ogni funzione resta
  leggibile, annunciata e azionabile.
- Prezzo e disponibilità possono cambiare: vecchio/nuovo valore, input preservato e
  scelta esplicita sono necessari.

## Jobs trasversali

| Momento | Job | Esito desiderato |
|---|---|---|
| Quando cerco un articolo | voglio restringere l'offerta con termini e filtri comprensibili | trovo un risultato rilevante o un vuoto recuperabile |
| Quando valuto un prodotto | voglio capire prezzo corrente, eventuale promozione e disponibilità | decido senza informazioni fuorvianti |
| Quando salvo o aggiungo | voglio ritrovare la mia selezione e sapere se è ancora valida | stato persistente e condizioni rivalidate |
| Quando qualcosa cambia | voglio capire cosa è cambiato e scegliere come continuare | vecchio/nuovo valore, input preservato, azione esplicita |
| Quando la rete fallisce | voglio distinguere dati disponibili, scaduti e non caricati | posso riprovare senza perdere contesto |

I task futuri devono validare questi profili con ricerca, analytics privacy-safe e test di
usabilità prima di introdurre segmentazioni più specifiche.
