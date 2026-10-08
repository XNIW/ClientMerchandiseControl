# Recovery locale scoped — tre canoniche e address v3

**Fedeltà recovery `PASS`; integrità relazionale `FAIL` preesistente.** Il ciclo
eseguito l'8 ottobre 2026, dalle 17:26 alle 17:29 UTC, estende la prova precedente
alla migration v3 esatta di `f16c5f4f`, SHA-256
`b290c6373d2d49a3c9fb4847e5ee8f47f2ce11f4eeeb17da4d3fc4086a615e56`.
Il JSON omonimo contiene hash, comandi, exit, ricevute e limiti verificabili.

Il preflight sul DB locale `task054_scoped_recovery_current` verifica zero altre
connessioni e transazioni, `session_replication_role=origin`, history 155 e
metadata identici alla baseline già recuperata. Il container rimane isolato con
`network=none`. Root assegna un lease esclusivo per tutto il ciclo; nessuna SQL
di scrittura è inviata al TEST `jpgoimipbothfgkokyvm`.

La sequenza effettiva della history è **155 → 158 → 159 → 158 → 155**. Le quattro
ricevute locali seguono apply SQL realmente completati. Durante l'inverse vengono
rimosse soltanto quelle ricevute aggiunte nel clone: nessuna history condivisa
viene alterata e non si afferma atomicità del runner CLI remoto.

Dopo i quattro apply il contratto locale completo è `PASS`: **57 RPC, due indici
e history 159**, senza errori. Il nuovo ledger è vuoto, owner `postgres`, RLS e
FORCE RLS attivi, nessun privilegio diretto per PUBLIC, anon, authenticated o
service_role. L'helper privato non concede EXECUTE a questi ruoli; le due RPC
pubbliche v3 lo concedono soltanto ad authenticated. Owner e privilegi sono
controllati esplicitamente, oltre ai campi del manifest.

L'inverse v3, ispezionata prima dell'esecuzione, acquisisce il lock sul ledger e
ne verifica il vuoto. Rimuove con `RESTRICT` soltanto la nuova tabella e le tre
funzioni v3; restituisce metadata e righe identici al checkpoint dopo le tre
canoniche. Le 1.035 assertion SQL storiche non sono ripetute.

Storage viene verificato tramite API sullo stesso DB: GET bucket privato 200,
DELETE 200, readback **HTTP 400 con body statusCode 404**. Bucket e oggetti finali
sono zero; schema e tutte le 73 righe della history Storage restano identici.
L'immagine locale v1.69.0 usa il prefisso verificato di 62 migrazioni, freeze alla
61 e aggiornamento degli hash disabilitato. Il comando API e il cleanup terminano
exit 0; l'attach Docker termina 137 per la rimozione esplicita dopo il successo
dell'API. Un successivo inventario conferma assente il container Storage proprio.

Dopo inverse3 gli otto fingerprint del catalogo coincidono con la baseline
registrata. Il confronto finale readonly tra TEST e clone verifica **12/12 digest
nativi PostgreSQL identici** — 11 proiezioni di righe più history — senza
normalizzazione numerica o coercizione stringhe. Coincidono inoltre tutti i
**1.238 flag trigger**, inclusi quelli interni.

Le due notifiche già orfane sono conservate con gli stessi otto riferimenti
mancanti: nessun parent inventato o record cancellato. Le righe Auth contengono
soltanto 13 ID esistenti; nessuna sessione o credenziale viene creata o recuperata.
Il ledger v3 resta vuoto: la prova non copre il suo recupero dopo popolamento.

Runtime autenticato, recovery globale/Auth e apply TEST restano `NOT_RUN`.
La procedura condivisa richiede ancora finestra writer/cron attestata, refresh
degli input di recovery, configurazione artifact approvata e gate readonly/TLS.
Questa prova conserva separati il recupero fedele e l'integrità dei dati.

Tutti i comandi del ciclo sono terminali; il lease heavy è rilasciato. Il DB
PostgreSQL è conservato per review e il suo container Admin non viene rimosso.
Export e dettagli protetti rimangono fuori Git, directory 0700/file 0600. Questa
capsule aggiunge soltanto due file nuovi; le evidence backend precedenti restano
immutate.

La review indipendente delle ricevute e dei metadati termina `PASS`, senza finding
aperti: 50 entry dei comandi di fase e sei di ispezione readonly hanno exit 0.
Il reviewer non riesegue SQL e
non legge export raw; l'esito resta limitato al ciclo locale con ledger vuoto.
