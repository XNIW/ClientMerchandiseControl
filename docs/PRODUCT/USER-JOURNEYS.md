# User journeys

Questi journey descrivono il comportamento futuro atteso. TASK-002 non li implementa e
non introduce dati simulati.

## Journey principali

| # | Journey futuro | Percorso nominale | Failure e recovery essenziali | Owner |
|---|---|---|---|---|
| 1 | Avvio ed esplorazione anonima | apertura → Home → catalogo | backend non disponibile: stato esplicito, retry, nessun login forzato | TASK-011–TASK-014 |
| 2 | Browse per categoria | catalogo → categoria → lista | categoria vuota o rimossa: spiegazione e ritorno al catalogo | TASK-014 |
| 3 | Ricerca e filtri | query → risultati → filtro/ordine | zero risultati: query preservata e modifica filtri | TASK-015 |
| 4 | Valutazione prodotto | risultato → dettaglio → prezzo/disponibilità | dato stale o prodotto non pubblicato: blocco fail-closed e alternativa | TASK-016–TASK-017 |
| 5 | Preferito o condivisione | dettaglio → salva/condividi → ritorno | deep link non valido o offline: messaggio recuperabile | TASK-018 |
| 6 | Accesso e profilo | intent protetto → motivo → login → ritorno al punto iniziale | sessione scaduta: rinnovo sicuro senza loop o perdita contesto | TASK-020–TASK-021 |
| 7 | Carrello e rivalidazione | aggiunta → quantità → riepilogo → revalidation | prezzo cambiato: mostra vecchio/nuovo; indisponibile: conserva righe valide | TASK-023–TASK-024 |
| 8 | Prenotazione e fulfillment | carrello → hold → ritiro/consegna → conferma | hold scaduto o opzione non disponibile: spiegazione e nuova scelta | TASK-025–TASK-026 |
| 9 | Creazione e tracking ordine | conferma → ordine idempotente → dettaglio/storico | risposta incerta: recupero per idempotency key, mai doppio ordine | TASK-027–TASK-028 |
| 10 | Preparazione e notifiche | evento server → notifica consentita → stato ordine | token/permesso assente: stato resta disponibile nell'app | TASK-029–TASK-031 |
| 11 | Pagamento, se adottato | provider approvato → autorizzazione → esito riconciliato | esito ambiguo: nessuna seconda addebito e stato verificato server-side | TASK-032–TASK-034 |

## Regole trasversali

1. Ogni schermata identifica il contesto e una prossima azione primaria.
2. Il back conserva il percorso e non scarta input senza conferma.
3. Loading, vuoto, offline, stale ed errore sono stati distinti.
4. Errori dichiarano cosa è successo, cosa è stato conservato e come proseguire.
5. Prezzo e disponibilità vengono rivalidati prima di hold, ordine o pagamento.
6. Nessun success state viene mostrato prima della conferma autorevole del server.
7. Deep link e notifiche non aggirano login, autorizzazione o shop scope.
8. Immagini mancanti non impediscono nome, prezzo, stato e azione essenziale.
9. Orientamento, resize, text scale e cambio tema preservano tab e contesto.

## Criterio di uscita futuro

Ogni task proprietario trasforma il journey interessato in criteri, test nominali,
failure path e smoke reali. Questa mappa non sostituisce i contratti né l'acceptance dei
task successivi.
