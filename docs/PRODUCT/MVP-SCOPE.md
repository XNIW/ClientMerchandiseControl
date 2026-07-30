# MVP scope

L'MVP è il percorso completo verso un client Storefront utilizzabile; non coincide con
TASK-002. Ogni capability entra nel prodotto soltanto quando il task proprietario supera
i propri gate.

## Capability previste

| Area | Risultato MVP | Task proprietari |
|---|---|---|
| Contratti e ambienti | ownership cross-repo, configurazione e confine Storefront verificabili | TASK-003–TASK-005 |
| Contenuto pubblico | proiezione catalogo, pubblicazione, prezzi, promozioni e immagini | TASK-006–TASK-010 |
| Connessione e shell | staging fail-closed, health state e shell prodotto accessibile | TASK-011–TASK-012 |
| Discovery | home, categorie, ricerca, dettaglio, cache, preferiti e performance catalogo | TASK-013–TASK-019 |
| Cliente | autenticazione, profilo/privacy e consenso notifiche | TASK-020–TASK-022 |
| Acquisto | carrello rivalidato, disponibilità pubblica, hold, ritiro/consegna e ordine | TASK-023–TASK-028 |
| Operazioni | preparazione ordine, handoff POS, eventi/notifiche e decisione pagamenti | TASK-029–TASK-032 |
| Qualità e rilascio | security, resilienza, osservabilità, accessibilità, performance e asset legali | TASK-033–TASK-038 |
| Distribuzione | Android internal, TestFlight, lancio e operatività | TASK-039–TASK-042 |

## Esperienza MVP attesa

- esplorazione anonima di home, categorie, ricerca e dettaglio;
- immagini pubbliche non bloccanti e cache con stato di freschezza comprensibile;
- prezzi CLP e promozioni server-side, senza costi o risparmi nascosti;
- preferiti e carrello persistenti secondo le decisioni dei task proprietari;
- autenticazione richiesta soltanto al momento necessario;
- profilo, indirizzi e cancellazione account con privacy by default;
- disponibilità commerciale qualitativa, hold e rivalidazione atomica;
- checkout per ritiro e consegna soltanto quando configurati dal negozio;
- creazione idempotente, storico e stato ordine;
- notifiche con consenso esplicito;
- eventuale pagamento soltanto dopo la decisione e integrazione di TASK-032.

## Fuori dal MVP iniziale

- gestione dell'inventory operativa, costi, fornitori o funzioni POS;
- modifica diretta di catalogo, pubblicazione, prezzi o fulfillment dal client;
- quantità di stock grezze presentate al pubblico;
- marketplace multi-negozio, loyalty, advertising o social commerce;
- pagamenti prima che provider, sicurezza, rimborsi e flussi siano decisi;
- pubblicazione automatica sugli store o auto-merge;
- accesso diretto a tabelle operative o uso del client come confine autorizzativo.

## Regola anti-anticipazione

Journey e principi documentati ora esprimono intenti futuri, non implementazioni. In
TASK-002 restano esclusi modelli commerciali, fixture prodotto, networking, schema,
repository, ViewModel e schermate data-backed. TASK-012 conserva l'ownership della shell
prodotto; TASK-038 conserva brand, legal e store asset definitivi.
