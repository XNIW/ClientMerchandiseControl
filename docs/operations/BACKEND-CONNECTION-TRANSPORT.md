# Gate readonly: connessione diretta e Session pooler

Il gate `scripts/check-backend-compatibility.py` mantiene il manifest completo
di RPC, firme, permessi, migrazioni e indici. Il trasporto predefinito è `direct`.
Per una rete IPv4 si può scegliere esplicitamente `session-pooler`, sulla porta
5432. Non esiste fallback al Transaction pooler o alla porta 6543.

L'operatore recupera l'host esatto da **Connect → Session pooler** del progetto
o dalla Management API autorizzata. Il cluster non si deduce dalla regione.
Il riferimento pubblico, esterno a Git, usa questa struttura; i segnaposto vanno
sostituiti con i valori verificati, mai con una password:

```json
{
  "schema_version": 1,
  "environment": "staging",
  "project_ref": "<project-ref>",
  "connection_type": "session-pooler",
  "host": "<host-esatto-da-Connect>",
  "port": 5432,
  "database": "postgres",
  "username": "supabase_read_only_user.<project-ref>",
  "sslmode": "verify-full",
  "source": {
    "kind": "supabase-dashboard-connect",
    "url": "https://supabase.com/dashboard/project/<project-ref>"
  }
}
```

Per la Management API, `source.kind` è `supabase-management-api` e `source.url`
è `https://api.supabase.com/v1/projects/<project-ref>/config/database/pooler`.
Il campo source documenta la provenienza controllata dall'operatore: non è
un'attestazione crittografica. Il gate confronta progetto e ambiente con la
configurazione dell'artifact e impone hostname Supabase, username con project-ref,
database, porta e TLS. Non ricava queste scelte dal profilo di servizio.

Il ruolo DB previsto è `supabase_read_only_user`; il pooler usa il nome di login
`supabase_read_only_user.<project-ref>`, il diretto usa il solo nome del ruolo.
Host e utente sono parametri espliciti libpq, `hostaddr` viene svuotato e le
options del service sono sostituite da `default_transaction_read_only=on`.
`sslmode=verify-full` verifica CA e hostname; `gssencmode=disable` impedisce che
GSS sostituisca TLS. Il certificato pubblico va recuperato dalle impostazioni DB
ufficiali e referenziato tramite `sslrootcert`/`PGSSLROOTCERT`. Password e trust
restano nei riferimenti protetti dell'operatore, mai in argv o nel JSON pubblico.

Prima dell'apply, eseguire il controllo di connessione e identità:

```sh
python3 scripts/check-backend-compatibility.py --connection-only \
  --service cmc_task054_test_readonly --app-config /percorso/protetto/app_config.test.json \
  --connection-type session-pooler --endpoint-metadata /percorso/protetto/endpoint.test.json \
  --receipt /percorso/protetto/connection-receipt.json
```

La query legge solo timestamp, database, ruolo corrente/sessione, attributi di
privilegio amministrativo e stato readonly. `BEGIN READ ONLY` e `ROLLBACK` sono
espliciti. Il suo PASS ha scope `live_connection_identity`, `schema_result=NOT_RUN`
e non autorizza l'apply: privilegi del canale operatore, recuperabilità, confronto
del delta atteso e finestra writer/cron hanno prove distinte. Le RPC ancora
assenti non impediscono questo controllo preliminare.
Nella receipt `rpcs` è il numero atteso dal manifest, non il numero verificato
dal preapply; `endpoint_metadata_sha256` usa il JSON normalizzato con chiavi
ordinate e separatori `,` e `:`, non i byte originali del file.

Dopo l'apply, sostituire `--connection-only` con `--live` e usare un nuovo path
receipt. Questo controllo richiede l'intero manifest, oltre all'identità readonly.
`--snapshot` rimane una verifica di metadata senza autenticazione o handshake.
Input mancanti riportano collegamento `NOT_RUN`; fallimenti di connessione/query
riportano `BLOCKED`, distinguendo errori TLS/autenticazione riconosciuti senza
stampare stderr; uno schema incompleto dopo connessione valida resta `FAIL`.
Una receipt viene scritta solo dopo una risposta valida e recente: non riusare
un file precedente quando l'invocazione fallisce prima della risposta.

I wrapper di release esistenti possono scegliere lo stesso trasporto attraverso
`CMC_BACKEND_CONNECTION_TYPE=session-pooler` e
`CMC_BACKEND_ENDPOINT_METADATA=/percorso/protetto/endpoint.test.json`.
Le opzioni CLI hanno precedenza. Queste due variabili contengono modalità e path,
non credenziali; non modificano le verifiche source-only. Senza selezione esplicita
rimane il diretto. Nessun PASS locale sostituisce connessione TLS o uso TEST reale.

Fonti: [connessioni Supabase](https://supabase.com/docs/guides/database/connecting-to-postgres),
[porta Session pooler 5432](https://supabase.com/changelog/32755-supabase-connection-pooler-deprecating-session-mode-on-port-6543-on-february-28-2025),
[precedenza del service libpq](https://www.postgresql.org/docs/current/libpq-pgservice.html).
