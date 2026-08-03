# TASK-030 — Win7POS handoff, reservation release e confine vendita fiscale

## Informazioni generali

- **Task ID**: TASK-030
- **Titolo**: Win7POS handoff, reservation release e confine vendita fiscale
- **File task**: `docs/TASKS/TASK-030-win7pos-handoff-fiscal-boundary.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-03
- **Ultimo aggiornamento**: 2026-08-03
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-030/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Dipendenze

- **Dipende da**: TASK-006, TASK-024, TASK-027, TASK-029
- **Checkpoint consumati**: catalog projection, availability, customer order/outbox e
  workflow Admin order
- **Sblocca**: TASK-034, Milestone 4 E2E
- **Repository writer**: Admin/Supabase per protocollo inbox/lease/ack, poi Win7POS per
  transport e consumer; nessun writer Client salvo regressione strettamente necessaria

## Scope

- definire un envelope POS versionato e allow-list con order ID/code, shop, item
  snapshot pubblico confermato, quantità, fulfillment, idempotency/correlation key e
  status version, senza dati customer eccedenti;
- esporre un pull/claim bounded autenticato per device/shop POS, con lease, retry,
  backoff, ack e replay idempotente senza accesso diretto alle tabelle;
- aggiungere inbox/dedup locale Win7POS durevole, compatibile `net48`/x86/Windows 7,
  capace di attraversare offline, restart, reconnect e risposta ambigua;
- mappare risposte operative `accepted`, `rejected`, `prepared`, `completed` al contract
  server senza confondere stato ordine, preparazione operativa e vendita fiscale;
- registrare un riferimento vendita fiscale soltanto dopo una vendita realmente
  completata dal flusso POS; il consumo ordine non crea automaticamente una vendita;
- rilasciare/ricalcolare reservation/availability nei soli stati terminali autorizzati,
  in modo idempotente e server-authoritative;
- produrre pgTAP/RLS, race duplicate/lease/replay, unit/integration/harness POS,
  offline/reconnect e staging E2E sanitizzato;
- mantenere production e consumer flag invariati/OFF.

## Non incluso

- creazione automatica di vendita fiscale, boleta, pagamento o rimborso;
- modifica dei prezzi/item snapshot confermati dal POS;
- invio push, di competenza TASK-031;
- provider pagamento, di competenza TASK-032;
- UI WPF estesa oltre lo stato operativo minimo necessario al consumer;
- claim di Windows 7 fisico senza runner/dispositivo reale;
- attivazione production, secret nel client POS o dipendenza da GUI/macOS sbloccato.

## File coinvolti

- Admin/Supabase: migration additiva, RPC strict claim/ack/status, lease/inbox ledger,
  RLS/grant/indici, pgTAP e workflow staging;
- Win7POS: contratti in `Win7POS.Core/Online`, transport/consumer durevole in WPF,
  test Core/Integration/harness e CI Windows;
- task, evidence, release manifest, checkpoint e worklog.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Solo device/session POS autorizzato può claimare eventi del proprio shop | RLS/PGTAP |
| CA-02 | Envelope è versionato, bounded, privacy-safe e distinto da una vendita fiscale | CONTRACT/SECURITY |
| CA-03 | Claim usa lease/visibility timeout e non perde eventi dopo crash/reconnect | CONCURRENCY/INTEGRATION |
| CA-04 | Inbox/ack/replay sono idempotenti e un duplicato non crea doppia vendita | UNIT/CONCURRENCY |
| CA-05 | accepted/rejected/prepared/completed rispettano version e state machine server | PGTAP/INTEGRATION |
| CA-06 | fiscal sale reference compare soltanto dopo commit fiscale reale | CONTRACT/INTEGRATION |
| CA-07 | Offline/restart/reconnect, timeout ambiguo e ack perso sono recuperabili | HARNESS/INTEGRATION |
| CA-08 | Restore/build/test `net48` x86 e Windows runner sono verdi | BUILD/CI |
| CA-09 | Staging E2E e cleanup passano; production e flag restano invariati/OFF | STAGING/SECURITY |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-02 | PGTAP | device shop ammesso; anon/revoked/cross-shop negati; payload allow-list |
| T-02 | CA-03 | CONCURRENCY | due consumer competono: una lease; expiry rende l'evento reclaimable |
| T-03 | CA-04 | UNIT/INTEGRATION | duplicate/replay/restart producono un inbox record e zero doppia vendita |
| T-04 | CA-05 | PGTAP | ack valido, stale, backward, terminale e fulfillment incompatibile |
| T-05 | CA-06 | INTEGRATION | order ricevuto non crea sale; sale commit associa un solo riferimento |
| T-06 | CA-07 | HARNESS | offline -> queue -> reconnect -> claim -> ack perso -> replay -> complete |
| T-07 | CA-08 | BUILD/CI | restore/build/test net48 x86 e runner Windows supportato |
| T-08 | CA-09 | STAGING/GIT | exact SHA, E2E, cleanup, secret scan e production unchanged |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Ordine cliente, handoff operativo e vendita fiscale sono tre documenti distinti | Evita una vendita implicita o duplicata | ATTIVA |
| D-02 | Il POS consuma solo RPC strict con sessione/device shop-scoped | Il client non è confine di autorizzazione | ATTIVA |
| D-03 | Claim e ack usano lease, idempotency e status version | Crash/retry non devono perdere o duplicare eventi | ATTIVA |
| D-04 | L'inbox locale è bounded, durevole e non contiene PII non necessaria | Supporta Win7 offline riducendo esposizione dati | ATTIVA |
| D-05 | Il riferimento fiscale è opzionale e validato soltanto dopo sale commit reale | Preserva il confine fiscale | ATTIVA |
| D-06 | Il test fisico Windows 7 mancante è BLOCKED esterno, non un PASS inferito | Mantiene evidence onesta senza fermare gate indipendenti | ATTIVA |
| D-07 | Planning ed Execution sono autorizzati dal prompt USER_APPROVER del 2026-08-02 | Mantiene il release train headless continuo | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Consegnare gli ordini confermati a Win7POS con un protocollo pull/ack affidabile e
idempotente, mantenendo esplicito il confine fra ordine cliente, lavoro operativo e
vendita fiscale.

### Analisi

- TASK-027/029 producono outbox POS-neutral append-only, ma non esistono ancora claim,
  lease, ack o consumer POS;
- Win7POS possiede già contratti transport/sync, trusted device/session, outbox drain,
  supervisor offline e commit guard della vendita da riusare senza nuovo runtime;
- un push diretto al POS renderebbe reconnect e Windows 7 più fragili: il pull bounded
  con lease consente replay verificabile;
- la deduplica deve essere persistente su entrambi i lati e includere event ID,
  status version e idempotency key;
- nessun ack operativo può creare una riga fiscale: l'associazione al sale è un passo
  separato dopo il commit locale autorevole.

### Approccio autorizzato

1. audit read-only di contratti online, trusted device/session, sync supervisor,
   persistence locale e sale commit Win7POS, più outbox/RPC Admin;
2. fissare envelope, state/ack matrix, lease, dedup key, retry/backoff, retention e
   privacy allow-list;
3. migration additiva con ledger/claim/ack strict, RLS/grant e pgTAP/race;
4. contratti Core net48 e adapter transport senza dipendenze incompatibili con Win7;
5. inbox durevole, consumer bounded e associazione fiscale separata/idempotente;
6. unit/integration/harness offline/reconnect/duplicate/ack-lost e staging exact-SHA;
7. restore/build/test Windows, evidence/checkpoint e attivazione TASK-031 solo con
   verde tecnico; Win7 fisico resta attestato soltanto se realmente disponibile.

### Rischi e mitigazioni

- doppia vendita: nessun sale automatico, dedup durable e sale commit guard;
- evento perso: lease reclaimable, ack monotono e outbox retained;
- cross-shop: device/shop derivati server-side e denial uniforme;
- PII offline: envelope allow-list, retention bounded e log sanitizer;
- Win7/TLS/runtime: sole API/librerie già compatibili net48, test Windows x86;
- loop retry: budget/backoff/jitter e poison state osservabile senza drop silenzioso.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: prompt headless Storefront v1 2026-08-02

## Execution — `CODEX_EXECUTOR`

Audit read-only da avviare sui contratti online/sync/sale commit Win7POS e sullo schema
outbox/Admin. Nessuna migration o persistenza locale viene fissata prima di avere
mappato envelope, lease, deduplica e confine fiscale esistenti.

## Checkpoint release train — `CODEX_EXECUTOR`

Da compilare dopo i gate tecnici; nessuna review formale intermedia.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.

## Chiusura

- **Conferma utente**: ricevuta in forma condizionata dal release train
- **Merge autorizzato**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: TASK-031 dopo checkpoint verde
- **Riepilogo finale**: in esecuzione
- **Data completamento**: non ancora
