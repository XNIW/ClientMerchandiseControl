# Backend TASK-054 — package e rollback compatibile

Il package locale contiene esclusivamente le quattro migration autorizzate,
byte-identiche a `f16c5f4f37051e7876a847fb1ae2e544c89377d2` e al merge
`02ea44b95d4a05baddbf46f24251f0d5f0dea294`. Il manifest
`canonical-package/manifest.json` fissa ordine, target e SHA-256. La preparazione
è PASS; nessuna migration è stata applicata al TEST condiviso.

## Prerequisiti effettivi

- Target verificato: `jpgoimipbothfgkokyvm`, ACTIVE_HEALTHY; host DB diretto
  `db.jpgoimipbothfgkokyvm.supabase.co`.
- Snapshot Management API readonly 2026-10-08 19:59:38 UTC: 32 RPC presenti e
  conformi su 57, 25 assenti; tutte quattro le migration assenti; un indice su
  due; history155. Questa prova non sostituisce TLS o sessioni Client.
- Il target ha solo AAAA; il Mac corrente non ha IPv6 raggiungibile. Il resolver
  applicativo restituisce gaierror. Un host/runner con connettività IPv6 al target
  diretto è necessario per il gate attuale; non vengono sostituiti hostaddr,
  pooler, sslmode o hostname. Nessun add-on a pagamento viene attivato.
- Il ruolo login readonly `supabase_read_only_user` esiste, ma nessuna credenziale
  approvata, passfile o service profile è disponibile. Un alias si costruisce
  autonomamente dopo l'arrivo di ruolo/accesso/trust protetti: il nome dell'alias
  non è un input che deve scegliere l'utente. Non è stato creato un service con
  valori fittizi. Il gate reale eseguito termina exit2, BLOCKED.
- I quattro cron storefront risultano attivi con schedule e command-MD5 invariati
  nel receipt corrente. La finestra 20:15–20:45 UTC è solo proposta, non confermata.
  Non è avvenuta alcuna pausa o riattivazione cron.
- Shop pilota, sessioni sintetiche reali A/B, config artifact completa e finestra
  writer/cron restano sotto il coordinatore. La prova Auth SQL locale usa solo
  fixture canoniche isolate e non crea account condivisi o sessioni Client.

## Sequenza apply condizionata

1. Ricevere conferma della finestra con inizio/fine UTC, writer interessati,
   responsabile cron e ripristino. Verificare accesso readonly TLS verify-full,
   artifact target e accesso di apply approvato. Il PASS iOS è indipendente.
2. Rileggere immediatamente schema/history/cron/attività/Storage e riesportare le
   righe coinvolte, parent e history sul target. Confrontare gli input immutabili
   con i package già provati; ripetere soltanto le prove invalidate da delta reali.
   I due orphan restano conservati finché non esiste una decisione di repair.
3. Pausare esclusivamente i cron concordati, dopo aver salvato stato/schedule/hash.
   La sola assenza momentanea di transazioni non è attestazione della finestra.
4. Applicare nell'ordine i quattro byte canonici del manifest attraverso il
   percorso operatore approvato. Registrare ciascuna receipt/history reale
   soltanto dopo successo. Non fare migration repair o inventare versioni;
   il rehearsal psql locale non attesta atomicità del percorso remoto.
5. Eseguire readback completo manifest57: identity arguments, argomenti/default,
   result, security-definer, settings, definition-MD5, grants, due indici validi,
   RLS/FORCE RLS e ACL di ledger/helper/RPC. Con baseline invariata atteso history159;
   migrazioni legittime concorrenti sono riconciliate come insieme, non rimosse.
6. Eseguire gate readonly TLS fresco, poi chiamate Client con vere sessioni TEST
   owner e account estraneo. Le query privilegiate e SQL claims locali sono lane
   distinte. Ripristinare gli stati cron concordati e rileggerli anche in caso di
   failure, conservando receipt e causa.

## Recovery scoped con ledger popolato

La prova locale nuova ha esportato un indirizzo e due intenti, incluso un
tombstone, e li ha ripristinati in una destinazione isolata con gli stessi parent
Auth/session sintetici già presenti. I digest PostgreSQL nativi dei dati, ledger
e prerequisiti Auth sono identici. Stesso intento, replay, hash incompatibile,
altro owner e cancellazione prima/dopo restore rispettano il contratto.

Non serve un restore globale Auth per questa procedura: identità/sessioni
equivalenti sono un prerequisito della destinazione, non contenuti dell'export
scoped. Se una procedura diversa perde anche questi parent, la presente prova non
copre quel recovery e va esplicitata la nuova dipendenza.

La prima inverse storica si è fermata su `changed customer_addresses`; quel
P0001 non era la prova del ledger. Il package locale successivo vincola solamente
target e sei digest al checkpoint popolato corrente; conserva byte-identico il
guard nonempty. Rifiuta con P0001 e messaggio esatto `nonempty
app_private.customer_address_create_intents_v3`, senza alterare schema, righe o
history. La review distinta riproduce il guard in readonly e approva il perimetro.

## Rollback applicativo dopo un uso v3

Un ledger popolato non deve essere eliminato. Il rollback operativo mantiene
schema additivo, entrambe RPC v3, helper, ACL/RLS e history della migration v3.
Non si esegue l'inverse fisica né si retrocede la history per simulare rollback.

Il bundle Client di rollback deve conservare il modulo v3 del candidato corrente:
journal cifrato/account-scoped, decoder e chiavi di storage, intento+payload
immutabili, riconciliazione server e cancellazione journal soltanto dopo conferma.
Le modifiche non pertinenti possono essere ritirate mantenendo queste capacità.
Un bundle precedente al supporto journal/v3 non è un rollback qualificato mentre
esistono intenti pendenti: richiede un candidato compatibile, oppure un flusso di
recovery che sospenda nuove creazioni finché gli intenti pendenti sono risolti.
Non si ricrea un indirizzo via v2 dopo un esito v3 incerto e non si cancellano dati
app, journal o intenti per liberare il percorso.

Edit/delete v2 funzionano sullo schema v3 preservato e reconcile v3 restituisce
l'indirizzo canonico aggiornato o il tombstone deleted. Questa compatibilità è
provata SQL locale. Create/retry v2, downgrade app nativa, installazione e rollback
di distribuzione rimangono NOT_RUN e non vengono qualificati da edit/delete.
L'eventuale rollback Worker riguarda la versione dell'applicazione e conserva
gli oggetti DB additivi; l'owner Worker verifica separatamente la vecchia versione
attiva, binding e asset del relativo artifact.

## Notifiche orfane

La diagnostica attribuisce il namespace fixture al payment concurrency harness;
il suo cleanup replica omette notification_* e sopprime i cascade. È un meccanismo
coerente, non un receipt dell'esecuzione originaria. Le quattro migration locali
passano conservando i due eventi e gli otto riferimenti mancanti; integrità FAIL.

Le nuove prove SQL locali postapply separano lista/mark-read/navigation, owner e
foreign owner. Lista può restituire i due eventi al contesto uid/slug coincidente;
il target legacy risolve, poi dettaglio ordine restituisce not_found. Mark-read e
mark-all in transazioni separate funzionano e i replay sono idempotenti. Un doppio
UPDATE nello stesso batch ha prodotto23503; il risultato è conservato come edge
SQL distinto dal normale trasporto RPC a transazioni separate. Nessuna di queste
prove è una vera sessione Client TEST.

Il repair proposto è mirato al cleanup del harness e, dopo decisione esplicita,
alle sole righe fixture orfane con snapshot/recovery e predicati hash-bound. Non
si inventano parent e non si indeboliscono FK. Nessuna riparazione è applicata.
