# User journeys

Questi journey descrivono il comportamento futuro atteso. TASK-002 non li implementa e
non introduce dati simulati.

## Journey minimi

| # | Journey futuro | Percorso nominale | Failure e recovery essenziali | Owner |
|---|---|---|---|---|
| 1 | Apertura e scoperta catalogo | apertura anonima → Home → catalogo/categoria | catalogo vuoto: spiegazione e prossima azione, nessun login forzato | TASK-011–TASK-014 |
| 2 | Ricerca prodotto | query → risultati → filtro/ordine → prodotto | zero risultati: query preservata e modifica filtri | TASK-015–TASK-016 |
| 3 | Visualizzazione promozione | prodotto pubblicato → prezzo originale/attuale → condizioni/validità | promo scaduta o non verificabile: mostra solo il prezzo autorevole | TASK-008, TASK-013, TASK-016 |
| 4 | Prodotto verso carrello | dettaglio → aggiunta → carrello → rivalidazione | aggiunta non valida: motivo, contenuto precedente preservato | TASK-016, TASK-023 |
| 5 | Prenotazione | carrello → hold atomico → scadenza esplicita | hold fallito/scaduto: nessun successo, nuova scelta possibile | TASK-024–TASK-025 |
| 6 | Ritiro | hold → opzione ritiro configurata → luogo/orario → conferma | slot o ritiro non più disponibile: torna alla scelta senza perdere righe valide | TASK-026–TASK-030 |
| 7 | Consegna | indirizzo → copertura/costo → riepilogo → conferma | indirizzo non coperto o costo cambiato: spiega e richiede conferma | TASK-021, TASK-026 |
| 8 | Ordine verso stato | creazione idempotente → conferma → dettaglio/storico → eventi | risposta incerta: recupero per idempotency key, mai doppio ordine | TASK-027–TASK-031 |
| 9 | Errore di connessione | richiesta → timeout/offline → stato conservato → retry/reconnect | distingue cache stale da dato assente e non duplica intenti | TASK-017, TASK-034 |
| 10 | Prezzo cambiato | rivalidazione → vecchio/nuovo prezzo → nuova conferma | rifiuto: ritorno al carrello; nessun addebito o ordine implicito | TASK-023, TASK-027 |
| 11 | Prodotto non più disponibile | rivalidazione → riga indisponibile → alternative/continua | conserva righe valide e non espone stock operativo | TASK-024–TASK-025 |

## Journey aggiuntivi già previsti

| Journey futuro | Regola essenziale | Owner |
|---|---|---|
| Accesso e profilo | motivo prima del login, ritorno al punto iniziale, sessione fail-closed | TASK-020–TASK-021 |
| Preferito, condivisione e deep link | un link non valido non aggira shop scope o autenticazione | TASK-018 |
| Pagamento, se adottato | esito ambiguo riconciliato server-side, mai secondo addebito automatico | TASK-032–TASK-034 |

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

Ogni task proprietario trasforma il journey interessato in criteri, test nominali,
failure path e smoke reali. Questa mappa non sostituisce i contratti né l'acceptance dei
task successivi.
