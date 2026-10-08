# Backend operativo — 8 ottobre 2026

`PASS` fedeltà del recovery scoped corrente; `FAIL` integrità relazionale
preesistente; `NOT_RUN` recovery globale e account Auth. Nessuna scrittura sul TEST
`jpgoimipbothfgkokyvm`. I risultati aggregati e i digest delle ricevute sono nel
file JSON omonimo. I dati esportati restano nel package protetto esterno a Git.

## Target e contratti

La lettura TEST delle 15:07 UTC sul manifest iniziale di 55 RPC trova 32 firme
compatibili, 23 RPC assenti, tre migrazioni assenti e l'indice safe-dedup assente:
gate snapshot `FAIL`, exit 1, 27 errori. Confrontati anche argomenti/default,
risultato, `SECURITY DEFINER`, impostazioni, MD5 definizione ed EXECUTE anon/auth.
Questa lettura non viene presentata come controllo del manifest finale di 57 RPC.

Il manifest finale di 57 RPC è stato confrontato indipendentemente con le due
ricevute finali Admin confermate dall'autore: **57 RPC e due indici `PASS`**, nessun
errore sulle sorgenti consumer. Le ricevute sono coerenti fra loro. La history
locale Admin è realmente presente ma vuota: il gate completo resta `FAIL`, con
17 migrazioni richieste mancanti. Nessuna history è stata inventata per farlo
passare. Questo DB Admin è distinto dal DB usato per il recovery corrente.

Il comando reale `python3 scripts/check-backend-compatibility.py --live` termina
`BLOCKED`, exit 2: mancano il riferimento di configurazione TEST approvata e una
connessione protetta readonly con TLS `verify-full`. L'accesso Management API
esistente consente letture/export protetti, ma non sostituisce quel gate.

## Recovery corrente scoped

Sono state esportate le righe effettive delle sei tabelle coinvolte: sei ordini,
due notifiche, un setting e zero righe nelle altre tre. La closure include solo
gli antenati esistenti necessari: sette profili, sette shop, sei slot, sei punti
di ritiro e 13 ID Auth esistenti. Non sono esportate credenziali Auth. La history
contiene 155 righe reali; il bucket scoped e i suoi oggetti sono inizialmente zero.
La API backup del progetto risponde 200 con zero backup e PITR disabilitato.

Il restore avviene nel solo `task054_scoped_recovery_current`, dentro il container
isolato `network=none` condiviso con la lane Admin ma in DB separato. La baseline
Storage locale era anteriore al target: è stata ricostruita nel solo DB proprio
dalle definizioni correnti prima del caricamento. Gli otto fingerprint di catalogo
risultano allora identici al target.

Il restore conserva due notifiche già orfane: per ciascuna mancano i parent di
ordine, evento sorgente, shop e utente, **due righe e otto riferimenti**. I FK nel
target risultano validati; questo non elimina gli orphan osservati. Non sono
inventati parent né eliminate righe. `session_replication_role=replica` è usato
soltanto nella transazione di restore locale, seguito da `origin` prima degli apply.

Le tre canoniche immutate sono realmente applicate, poi invertite. History:
**155 → 158 locale → 155 identiche**. I tre record locali seguono gli apply psql
effettivi; non provano atomicità del runner CLI remoto. Le righe originali e gli
otto fingerprint del catalogo ritornano uguali, inclusi RLS e ACL verificati.
Il readback readonly finale confronta direttamente tra TEST e clone i digest
nativi PostgreSQL delle 11 proiezioni di righe e della history: tutti identici,
senza normalizzazione numerica o coercizione stringhe. Coincidono inoltre tutti
i **1.238 flag trigger**, compresi i trigger interni, nei tre schemi controllati.

Storage è verificato tramite API sullo stesso clone: GET del bucket privato 200,
DELETE 200, readback HTTP **400 con body `statusCode: 404`**, conteggi finali zero.
L'immagine locale v1.69.0 conosce 62 delle 73 migrazioni registrate nel target:
il prefisso ha nomi/hash identici. Il freeze alla propria migrazione 61 e il
refresh hash disabilitato consentono l'avvio; tutte le 73 righe history e tutti
i metadati rimangono identici dopo l'API. Questa prova non è un runtime Storage
remoto né un recupero di bytes di oggetti assenti.

Il primo restore aveva già eseguito `COMMIT` con SQL exit 0 quando il confronto
Python fallì su serializzazione int/float integrale: **non era un rollback**.
La ricevuta del fallimento è preservata; il successivo confronto nativo sopra
non dipende dalla correzione del comparatore. Sono preservati anche il primo
rollback Storage per ordine delle funzioni e i tentativi di startup bloccati
dal freeze a una migrazione assente nell'immagine. Nessuno viene promosso a PASS.

Restore SQL, apply, API e inverse sono terminali con exit 0. Il container Storage
creato dalla lane è stato rimosso; il suo attach termina 137 per il cleanup
esplicito dopo il risultato API. Non restano processi di verifica pendenti.
Il DB locale è conservato per la review; il container resta di proprietà Admin.

## Limiti e prerequisiti

La fedeltà scoped è `PASS`; l'integrità rimane `FAIL` con gli stessi orphan.
Il risultato non è un backup globale, non recupera account Auth o oggetti di
altri bucket e non autorizza automaticamente la procedura su un target condiviso.
La nuova migrazione address v3 `20261008151018` non è inclusa nel ciclo recovery
delle tre canoniche storiche. Le 1.035 verifiche SQL storiche non sono state
ripetute in assenza di drift delle tre canoniche e del catalogo pertinente.

L'apply TEST resta `NOT_RUN`: occorrono configurazione approvata, connessione
readonly protetta/TLS, finestra con unico writer e esclusione cron attestata,
refresh di export/history/Storage e review della procedura che conserva gli orphan.
Alla lettura risultano quattro cron attivi; nessuno è stato fermato. Gli smoke
autenticati e il readback condiviso del nuovo contratto restano `NOT_RUN`.

Package esterno: `task054-operational-backend-20261008`, directory 0700 e file
0600. Questa evidence contiene solo conteggi, stati, hash di ricevute e metadati
tecnici; nessuna riga cliente o credenziale viene copiata in Git.
