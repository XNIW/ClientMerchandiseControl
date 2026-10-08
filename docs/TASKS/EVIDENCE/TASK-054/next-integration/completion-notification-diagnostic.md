# TASK-054 — supplemento finale: notifiche postapply e review distinta

Review readonly del 2026-10-08, separata dall'autore delle prove SQL. Fonte Admin immutabile `f16c5f4f37051e7876a847fb1ae2e544c89377d2`. Questo supplemento aggiorna esclusivamente la caratterizzazione postapply del precedente `diagnostic.md`; provenienza fixture, otto parent mancanti e repair non applicata restano invariati.

**Esito della review della diagnostica: APPROVED, limitatamente alla classificazione delle prove SQL locali riportata qui.** Non approva TASK-054, integrità TEST, Auth live o UI nativa. Nessuna mutazione DB/repository eseguita dal reviewer.

## Prove dirette, una transazione per tentativo

L'autore ha eseguito i RPC canonici senza wrapper nelle otto transazioni isolate di `characterize-direct-calls.py`, ciascuna terminata in ROLLBACK su `task054_v3_populated_restored`.

| Tentativo | Risultato SQL registrato | Exit |
|---|---|---|
| Lista owner | status ok, items2, unread2 | 0 |
| Mark-read owner | status ok, readAt presente | 0 |
| Mark-all owner | status ok, updated2 | 0 |
| Route legacy | status ok | 0 |
| Dettaglio ordine mancante | status not_found | 0 |
| Lista altro owner | status ok, items0 | 0 |
| Mark-read altro owner | status not_found | 0 |
| Mark-all altro owner | status ok, updated0 | 0 |

I digest notifiche prima/dopo coincidono: `dece14af4bd75c8d8f787c0b6aa5f951`. Il reviewer ha confrontato tutti gli otto file SQL salvati con i corrispondenti `sql_sha256` dei receipt: 8/8 coincidono. Le risposte e i codici sono prove eseguite dall'autore, ispezionate dal reviewer; il reviewer non ha rieseguito le mutazioni.

## Replay con COMMIT in transazioni separate

`characterize-separate-transactions.py` crea un nuovo database probe dal candidato popolato e invoca un solo RPC per sessione/transazione. Le cinque sessioni terminano ciascuna in COMMIT.

| Tentativo | Risultato registrato | Exit |
|---|---|---|
| Primo mark-read | ok | 0 |
| Replay mark-read sullo stesso id | ok | 0 |
| Mark-all dei restanti eventi unread | ok, updated1 | 0 |
| Replay mark-all | ok, updated0 | 0 |
| Lista finale | ok, items2, unread0 | 0 |

Il reviewer ha ricostruito staticamente i cinque SQL dalle costanti AST del programma, senza eseguirlo: 5/5 hash coincidono con i receipt. Ha poi interrogato **soltanto in READ ONLY** `task054_notification_replay_probe`: exit0, 2 righe/read2/unread0, 2 riferimenti mancanti per ciascuno dei quattro parent, zero deliveries/receipts, `session_replication_role=origin`. La lettura terminale verifica autonomamente la persistenza di read_at nel probe, senza riparazione o cancellazione degli orfani.

Il reviewer ha inoltre confrontato internamente i quattro corpi `prosrc` nel probe con le funzioni canoniche delle migration Admin: lista, mark-read, mark-all e route legacy coincidono byte-per-byte a `f16c5f4f`. Hash per corpo in `reviewer-probe-readonly-receipt.json`.

## Correzione della lettura dei fallimenti iniziali

Il primissimo batch con due UPDATE nella stessa transazione ha prodotto exit3/SQLSTATE23503. L'autore ha corretto l'interpretazione: il primo mark-read riusciva; falliva il secondo, non il primo. Il reviewer ha successivamente verificato `original-batch-byte-reconstructed.sql`: SHA-256 `19cbec5e62daf2c77adf0ba4a1306ed35835b32e8e30a1d98fe700bd659a2946`, identico all'input conservato nel receipt iniziale. La linea14 contiene la chiamata diretta etichettata `owner_mark_replay`, seconda invocazione mark-read del batch. `original-batch-diagnosis.json` registra il rerun dell'autore sul medesimo input: psql exit3/23503, nessun COMMIT. Il reviewer attesta autonomamente hash e posizione del statement; non ha rieseguito SQL mutativo.

La variante con wrapper `pg_temp.safe_mark` cattura il foreign_key_violation e registra:

- primo mark-read: ok;
- replay nella stessa transazione: sql_error, SQLSTATE23503;
- mark-all: ok, updated1;
- unread finale:0; altro owner lista0/mark not_found/all0.

`postapply-observed.json` contiene queste osservazioni. Il codice corrente `characterize-local-postapply.py` conserva però le vecchie assertion che aspettano failure sia al primo mark-read sia al replay sia al mark-all: il programma fallisce exit1 prima di scrivere `postapply-receipt.json`. Questo è un errore dell'assertion del harness; non costituisce un receipt PASS e non prova una failure del primo mark-read o del mark-all. `postapply-commands.json` registra invece exit0 dei comandi SQL del wrapper e digest identici prima/dopo ROLLBACK.

Il 23503 nel replay nello stesso contesto transazionale resta un edge case locale reale su dati referenzialmente corrotti; non viene cancellato dalla diagnosi. Il Client invoca RPC distinti attraverso richieste separate, e le prove dirette/con COMMIT separato non riproducono quel fallimento. Non attribuiamo un errore generale al normale percorso mark-read/all sulla base del batch iniziale.

## Matrice finale delle lane

| Lane | Esito | Significato |
|---|---|---|
| SQL canonico postapply, owner/foreign owner | PASS locale | Prove dirette eseguite e receipt ispezionati |
| Replay RPC in transazioni separate | PASS locale | Prove eseguite; stato finale probe letto autonomamente |
| Replay nella stessa transazione corrotta | FAIL locale | 23503 registrato; differente dal percorso RPC separato |
| Assertion della variante wrapper | FAIL harness | Aspettative obsolete; non utilizzabile come gate prodotto |
| Integrità relazionale | FAIL | Otto riferimenti tuttora mancanti |
| Auth/sessione reale | NOT_RUN | SQL set_config di claims sintetici; nessun login/sessione/token reale |
| UI/navigazione Flutter o device postapply | NOT_RUN | Route e dettaglio verificati solo come funzioni SQL; nessuna interazione UI qui |
| Push/consegna | NOT_RUN | Route SQL non equivale a push o receipt di consegna |
| Apply TEST condiviso/repair | NOT_RUN | Nessuna modifica remota o repair effettuata |

I due eventi possono quindi comparire e diventare read nel contesto SQL owner simulato, mentre la destinazione ordine continua a produrre not_found. Il risultato conferma l'impatto distinto su inbox, marker read e business navigation; non autorizza a dichiarare Auth live o integrità verdi. I successi locali non cambiano i prerequisiti di finestra/recovery/owner review per eventuali azioni TEST.

## Tracciabilità

`reviewer-supplemental-receipt.json` contiene hash SHA-256 degli artifact esaminati, 13/13 confronti SQL diretti/separati e il confronto aggiuntivo del batch negativo. `reviewer-probe-readonly-receipt.json` conserva comando, exit, query hash, stdout/stderr hash, conteggi sanitizzati e confronto source. `supplemental-checksums.json` fissa gli artifact finali della review.
