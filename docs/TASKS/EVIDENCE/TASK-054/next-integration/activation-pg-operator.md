# TASK-054 — applicatore PostgreSQL operatore preparato

Il driver è concreto e provato nel clone locale. **NON ESEGUIBILE sul TEST finché l'endpoint ufficiale e i riferimenti operatore sono incompleti.** Il coordinatore root resta l'unico operatore remoto. Nessuna credenziale è stata creata o cercata da questa lane.

## Atomicità reale e rettifica

Tre canonici contengono BEGIN/COMMIT: commerce7/3602, dedup3/13, v3 3/180. Il driver mantiene i loro byte e commit. Solo order_lines riceve un wrapper transazionale. Nessun `psql -1`, transaction globale o modifica dei quattro file. La receipt history viene inserita in una **transazione successiva**, soltanto dopo SQL exit0 e readback coerente dello stadio sul manifest completo57. L'intero file UTF8 canonico è conservato come singolo elemento di `statements text[]`; name esclude il prefisso versione. Questi sono i tipi osservati nel clone e accettati solo quando l'introspection effettiva del target coincide: nessuna assunzione sullo schema remoto.

Prima di ogni invio SQL, `pending.json` viene scritto con replace atomico, fsync del file e fsync della directory. Contiene versione, digest canonico, digest effettivamente inviato e digest/versioni history precedenti. SQL exit nonzero, timeout o errore di readback/history mantengono il marker. Anche la perdita dell'ACK dopo un vero commit history mantiene pending. Un nuovo avvio vede pending/completed e rifiuta il reinvio automatico; nessun autorepair o falsa receipt.

Gli originali dell'audit inesatto sono preservati in `../superseded-initial-audit/`. Il primo harness Python fallì prima di qualunque DB call perché il filename operator.py ombreggiava lo standard library; è stato rinominato pg_operator.py. Queste storie negative restano nelle receipt.

## Input e comando

`endpoint-metadata.template.json` è deliberatamente verified:false, hostname/login assenti. Root deve sostituirlo con un file protetto e un riferimento ufficiale verificato del progetto TEST. Direct accetta soltanto db.jpgoimipbothfgkokyvm.supabase.co/loginpostgres; Session pooler richiede l'host ufficiale esatto e loginpostgres.jpgoimipbothfgkokyvm, porta5432. Nessun cluster dedotto o fallback6543.

Il service dedicato si chiama `cmc_task054_test_operator`. Il driver forza host, hostaddr vuoto, porta5432, databasepostgres, login associato al progetto, TLSverify-full, GSSdisable e optionsvuote dopo service. Passfile e CA sono imposti anche nei parametri libpq, oltre ai soli riferimenti in ambiente. Password inline nel service e prompt password sono rifiutati. Non usa il ruolo supabase_read_only_user. `current_user/session_user=postgres` e current_database=postgres sono verificati con una transazione readonly separata prima dell'apply. Questo è il verifier dell'operatore, non il gate del ruolo readonly.

Comandi riproducibili — i percorsi `/protected/...` devono essere forniti dall'operatore, non sono file creati o credenziali fittizie:

```bash
PGSERVICEFILE=/protected/operator/pg_service.conf \
PGPASSFILE=/protected/operator/pgpass \
PGSSLROOTCERT=/Users/minxiang/.codex/outputs/task054-activation-20261008/access/certs/supabase-ca-2021.crt \
bash /Users/minxiang/.codex/outputs/task054-activation-20261008/backend-channel-audit/pg-operator/run-operator.sh \
verify /protected/operator/endpoint-metadata.json /protected/operator/operation-state
```

Dopo verifier, root conferma finestra/writer/cron e refresh della recovery. Il secondo comando richiede le due receipt protette:

```bash
PGSERVICEFILE=/protected/operator/pg_service.conf \
PGPASSFILE=/protected/operator/pgpass \
PGSSLROOTCERT=/Users/minxiang/.codex/outputs/task054-activation-20261008/access/certs/supabase-ca-2021.crt \
bash /Users/minxiang/.codex/outputs/task054-activation-20261008/backend-channel-audit/pg-operator/run-operator.sh \
apply /protected/operator/endpoint-metadata.json /protected/operator/operation-state \
/protected/operator/window.json /protected/operator/recovery.json
```

Il driver controlla la finestra attuale prima delle query/apply; i campi minimi delle receipt sono in `operator-input-requirements.json`. Root conserva jobID/stati cron originali e ne esegue ripristino/readback su **ogni** uscita. Il driver non muta cron e non prende in carico l'esclusione degli altri writer.

## Guard e readback

- Il manifest package e i quattro hash sono fissati; transazioni native e posizioni top-level controllate. Il contratto57 e il relativo gate sono copie byte-identiche del sorgente revisionato0cec1058, con SHA bloccati nel driver.
- `preapply-introspection.sql` qualifica identità readonly dell'operatore, tutti i tipi/default/nullability/generation delle colonne history e PKversion. Il SHA di `qualified-profile.json` è fissato nel driver e verificato prima delle query; lo schema remoto deve coincidere con quel profilo; altrimenti stop e review dell'introspection, mai type cast inventati.
- All'inizio devono mancare tutte e quattro le versioni. Versioni baseline ed errori del manifest completo devono corrispondere al delta acquisito. I57RPC non sono richiesti prima dell'apply. Gli errori attesi per stadio sono registrati da una vera esecuzione locale; gli errori inattesi fermano il driver senza aggiungere la receipt.
- Ogni history INSERT blocca la tabella, ricontrolla digest/assenza della versione e usa una transazione propria. Sono verificati name e statements esatti, poi nuovamente tutti i57 contratti, il delta history e il digest dei contenuti delle righe history precedenti, escludendo solo la nuova versione. Il risultato finale locale è57RPC/2indici/history159 e le sole quattro versioni aggiunte.
- I `.preview.sql` sono gli input SQL consultabili e hashati, non un comando alternativo che salti verifier/window/marker. I canonici originali restano nel package immutato.

## Recupero delimitato di un marker ambiguo

Prima operazione: **sole letture**, nessun reinvio del canonico e nessun INSERT history. Conserva marker/log/lock/cron-state e usa verifier più manifest57 per confrontare lo stadio attuale con `qualified-profile.json`.

- SQL non applicato e versione assente: resta pending fino alla decisione root; un nuovo tentativo richiede nuova esclusione e confronto input, non una ripetizione automatica.
- SQL applicato/stadio esatto e versione assente: stato APPLIED_UNRECORDED. Root prepara la sola receipt history dalla funzione `history_input()` usando il digest corrente verificato e il canonico hash-bound; la fa revisionare nel perimetro del marker prima della sola transazione history. Non riesegue SQL già committato.
- Versione presente con name/statements esatti e stadio coerente: history può aver committato con ACK perso. Nessun secondo INSERT o apply. Root registra la riconciliazione readonly e definisce l'eventuale ripresa dei soli file rimanenti.
- Qualunque altro stato/drift: stop, preservazione e review scoped. Nessuna inverse sul TEST o cancellazione di ledger/journal.

Questa gestione riconosce il gap SQL/history; non lo presenta come atomicità globale. Le prove negative locali hanno attraversato sia SQL committato/history assente sia history realmente committata/ACK perso.

## Prove locali bounded

Container già esistente `cmc-task054-address-create-20261008`, networknone; nessun download. Quattro clone iniziali e un clone per ACK perso; baseline originale invariata. Primo blocco19casi/66comandi PASS; supplemento15casi/11comandi SQL PASS, oltre ai comandi di setup/CLI/parse/hygiene registrati nelle receipt. Non sono ripetute le suite33/54 di recovery.

Sono provati: successo completo57/2/159, rollback del primo SQL nativo, rollback del wrapper order_lines, rollback della transazione history dopo SQL committato, crash prima della history, ACK perso dopo history committata, blocco retry prima di SQL, schema history non qualificato rifiutato, versione già presente rifiutata, endpoint incompleto/errato rifiutato, opzioni libpq imposte contro service ostile (solo parse senza connessione), password/ruolo readonly non usati, finestra scaduta ferma prima del comando. Nessun SQL remoto/TLS reale/Client Auth qualificato. Tutti i processi propri sono terminali; clone conservati per reviewer readonly.

## Fix dalla review operativa

La review R1 ha riprodotto offline due finding P2: PG-01 consentiva un profilo qualificato alterato; PG-02 accettava versioni corrette senza confrontare i contenuti history precedenti. Il driver e il manifest R1 sono preservati byte-identici in `superseded-review-r1/`. Nessuna corruzione reale del DB è stata eseguita dal reviewer: il PoC riproduceva il controllo mancante usando le stdout locali.

Il fix pinna il profilo prima di qualsiasi query e all'ingresso apply; nel readback post-history già presente aggiunge il digest delle righe precedenti e lo confronta con il digest prima dell'INSERT, prima di chiudere pending. Nessun SQL canonico/preview, manifest57, schema history o DDL è cambiato.

Il source corrente è associato a `fix-regression/summary.json`:13 controlli mirati PASS, inclusi i due negativi e blocco retry, più due letture SQL effettive sui clone esistenti che verificano il nuovo digest. Il replay positivo dei quattro stadi è esplicitamente offline, non un secondo apply. Le prove originali19+15 rimangono associate al protocollo R1; il delta corrente è verificato dai13 controlli e dalla re-review. Nessuna fullsuite ripetuta, nessuna mutazione locale aggiuntiva e zero SQL remoto.
