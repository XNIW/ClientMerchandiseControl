# Review indipendente recovery popolato TASK-054

Esito: **APPROVED**, esclusivamente per recovery locale scoped e package delle
quattro migrazioni canoniche. Nessun finding aperto nel perimetro revisionato.
Non costituisce approvazione dell'apply condiviso né chiusura del backend TEST.

La review ha eseguito `python3 review-readonly.py` con exit code 0: 50 controlli,
39 comandi registrati. Le interrogazioni dei due database assegnati hanno usato
`default_transaction_read_only=on` e `BEGIN READ ONLY`. Nessuna mutazione dei
database o dei repository; sono stati scritti soltanto questi artifact di review.

| Verifica | Risultato | Prova |
|---|---|---|
| Quattro package byte-identici all'authority f16c5f4f e merge 02ea44b9, ancestry valida | PASS | git show, SHA-256; commands.json/checks.json |
| Contratto corrente in entrambi i DB | PASS | 57 RPC, firme/default/result/grants/settings/definition MD5; due indici; history 159 |
| Ledger sorgente | PASS | Due intenti, un owner, un indirizzo collegato e una tombstone; owner presenti, hash payload corretti |
| Ledger ripristinato dopo prove v2 | PASS | Tre intenti, due owner, un indirizzo collegato e due tombstone; zero collegamenti altrui o owner mancanti |
| Export e restore scoped | PASS | Solo customer_addresses e ledger v3; digest checkpoint identici; dump protetto e SHA-256 pari all'input restore |
| Guardia inverse specifica | PASS | Target locale e sei digest sono le sole sostituzioni; guardia byte-identica; ricevuta exit 3 e messaggio P0001 esatto |
| Riproduzione indipendente della guardia | PASS | Stessa guardia estratta eseguita in READ ONLY: nonempty ledger/P0001; digest invariati |
| FORCE RLS e privilegi ledger | PASS | Nessun privilegio tabella anon/authenticated/service_role; helper privato non eseguibile da anon |
| Compatibilità SQL v2 | PASS | Ricevute edit/delete v2, reconcile v3 aggiornato, tombstone/replay senza resurrezione |
| Auth globale | NOT_RUN | Prerequisito esplicito: identità/sessioni sintetiche equivalenti già presenti prima del restore scoped |
| Apply condiviso TEST, TLS remoto, Client autenticato e rollback nativo | NOT_RUN | Fuori dalla presente review locale; richiedono proprie prove |

Il primo inverse storico si è fermato sulla guardia `changed customer_addresses`:
il suo P0001 generico **non prova** la guardia del ledger. La prova successiva ha
aggiornato soltanto target locale e sei costanti digest al checkpoint corrente;
ha raggiunto esattamente `Recovery blocked: nonempty
app_private.customer_address_create_intents_v3`. Le ricevute prima/dopo confermano
identici digest di dati/Auth e metadati schema/history.

Il rollback applicativo compatibile conserva schema e intenti v3. La compatibilità
SQL osservata copre edit/delete v2 e reconcile v3; non qualifica retry create v2,
una vecchia app nativa o il downgrade del journal. Un rollback app deve conservare
la risoluzione degli intenti pendenti oppure sospendere nuove creazioni fino alla
loro risoluzione. L'inverse non deve mai eliminare un ledger popolato.

Il restore globale Auth non è una dipendenza di questa procedura: la destinazione
era stata preparata con identità e sessioni locali equivalenti prima dell'export.
Questo prerequisito non può essere omesso in una diversa destinazione.

`review.json` contiene gli hash degli input revisionati; `commands.json` contiene
comandi, exit code, durata e hash stdout/stderr. Nessun raw export o dato personale
è incluso in questa review.
