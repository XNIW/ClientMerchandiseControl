# UX principles

## Chiarezza e controllo

- Ogni schermata ha un titolo riconoscibile e un obiettivo primario.
- Le azioni secondarie non competono visivamente con quella primaria.
- La navigazione, il back e il cambio orientamento preservano il contesto.
- Le azioni irreversibili richiedono conseguenza e conferma; quando possibile viene
  offerto undo.
- La progressive disclosure evita di chiedere dati o decisioni prima che servano.

## Verità commerciale

- Il prezzo corrente è espresso in CLP interi e proviene dal server.
- Il prezzo originale appare soltanto con una promozione valida e viene annunciato
  semanticamente insieme al prezzo corrente; colore e barratura non bastano.
- Validità, condizioni, costi aggiuntivi, ritiro e consegna sono visibili prima della
  conferma.
- Zero, trattino o valore locale non sostituiscono un prezzo sconosciuto.
- Non vengono usati countdown, scarsità, urgenza o risparmio non verificati.
- La disponibilità pubblica è qualitativa e controllata; quantità operative, costi e
  fornitori non vengono mostrati.
- In caso di variazione vengono mostrati vecchio e nuovo valore e viene richiesta una
  nuova conferma.

TASK-002 definisce questi guardrail ma non crea card prodotto, prezzi, promo o stock.

## Stati e resilienza

- Loading, vuoto, offline, stale, errore e contenuto disponibile sono distinguibili.
- Un errore preserva dati già caricati e input recuperabili.
- Retry e riconnessione sono espliciti, idempotenti e non duplicano intenti.
- Le immagini sono progressive e non bloccano contenuto o azioni essenziali.
- Un dato non verificabile fallisce in modo chiuso nelle azioni commerciali.
- La UI non promette successo prima della risposta autorevole.

## Accessibilità

- Target interattivi di progetto: almeno 48×48 logical pixel su Android e iOS.
- Testo e azioni restano leggibili, raggiungibili e non troncati al 200%.
- Titoli hanno semantica heading; controlli espongono label, ruolo, stato e selezione.
- Icone decorative sono escluse dall'albero semantico.
- Stato, errore, promozione e disponibilità non dipendono soltanto dal colore.
- Contrasto obiettivo: almeno 4,5:1 per testo normale e 3:1 per testo grande o componenti
  essenziali.
- L'ordine di lettura segue quello visivo; live region sono usate solo per cambiamenti
  importanti e non ripetitivi.
- Matrice minima foundation: 320×568, 568×320, 390×844 e 1024×768, light/dark e 200%.

I test automatici riducono regressioni ma non sostituiscono test futuri con TalkBack,
VoiceOver e persone.

## Privacy e fiducia

- Il catalogo pubblico non richiede account.
- Login, indirizzi, notifiche e altri dati vengono richiesti solo con motivo esplicito.
- Default e permessi minimizzano raccolta ed esposizione.
- Informazioni sensibili non vengono inserite in log, screenshot, analytics o errori.
- Nessun dark pattern, preselezione commerciale o consenso accorpato.

## Coerenza visiva e motion

- Material 3 e font di sistema sono la base accessibile.
- Token descrivono spaziatura, raggi, dimensioni, breakpoint, durata e colori semantici.
- Dark mode non è un'inversione automatica di significato.
- Motion è breve, funzionale e disattivabile tramite preferenza di sistema.
- Il colore supporta gerarchia e stato, ma testo, icona o semantica rendono il significato
  comprensibile anche senza colore.
