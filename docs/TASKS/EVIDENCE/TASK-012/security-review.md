# Security and confinement review — TASK-012 Execution

## Confini verificati

| Area | Esito | Evidenza |
|---|---|---|
| Dati commerciali | PASS | Nessun prodotto, prezzo, stock, sconto, urgenza o immagine sintetici |
| Accesso remoto | PASS | Nessuna query, RPC, Storage, Functions o nuova request |
| Auth | PASS | Runtime guest; Google disabilitato; zero token/sessione/storage/callback |
| Account model | PASS | Dopo FIX, avatar limitato a bytes locali 1…512 KiB, copiati e renderizzati con `Image.memory`; nessun provider/URI remoto |
| Segreti | PASS | Zero service role, secret key, token o config locale tracciati |
| Supabase | PASS | Zero write staging e production; nessuna modifica remota |
| Dipendenze | PASS | Nessuna dipendenza aggiunta o aggiornata |
| Native | PASS | Nessuna modifica Android/iOS |
| Repository esterni | PASS | Nessun repository esterno modificato |
| Artifact | PASS | Build, coverage e log esclusi; soli PNG sanitizzati versionabili |

## Originalità e customer safety

La composizione usa pattern astratti e-commerce — ricerca prominente, categorie,
sezioni future, tab persistenti ed empty state — con Material 3, token e copy propri.
Non sono presenti logo, asset, palette, immagini, testi, icone proprietarie o layout
pixel-perfect di Amazon, Falabella o altri marchi.

Le sezioni future dichiarano esplicitamente l'assenza di contenuto. `ready` continua a
significare soltanto Auth health TASK-011; il Catalogo non lo trasforma in prova di
schema, pubblicazione o disponibilità.

## Localizzazione e presentazione

- tutte le nuove stringhe customer-facing e semantic label sono negli ARB;
- parità automatica di chiavi e placeholder per es, it, en, zh-Hans;
- es-CL è primaria/fallback e `app_zh` resta sincronizzato;
- nessun raw color funzionale o font size feature-specifico;
- la factory authenticated richiede un callback logout non-null per tipo, anche in
  release; l'implementazione interna non accetta callback nullable.

## Scan sanitizzati

- diff UI query/RPC/Storage/Functions: 0;
- pattern secret/token privilegiati nel diff: 0;
- `config/*.local.json` tracciati: 0;
- artifact build/coverage/log candidati a Git: 0;
- log normal app Android/iOS con marker secret/config: 0;
- screenshot con dato personale o configurazione: 0.
- sink `NetworkImage`, `ImageProvider`, URI o HTTP nel perimetro Account: 0;
- test avatar con `HttpOverrides`: 0 client HTTP creati.

## Rettifica del ciclo FIX

La review indipendente ha invalidato due claim dell'autoverifica Execution: il
costruttore authenticated dipendeva da un `assert` e il port avatar accettava un
`ImageProvider` generico. I finding `T012-REV-SEC-001` e
`T012-REV-SEC-002` hanno quindi prevalso sui precedenti `PASS`.

Il ciclo FIX ha rimosso entrambi i percorsi: le viste guest/authenticated hanno API
distinte e l'avatar accetta soltanto una copia bounded di bytes locali. Bytes corrotti
ricadono nel fallback deterministico; un payload vuoto o oltre 512 KiB viene rifiutato.
La loro chiusura resta soggetta a re-review indipendente.

## Esito Execution

L'autoverifica Execution non aveva rilevato problemi P0/P1/P2, ma la review
indipendente ha poi aperto i finding sopra rettificati. Questo documento non sostituisce
la re-review e non costituisce approvazione del lavoro del fixer.
