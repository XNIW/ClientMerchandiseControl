# TASK-030 — Win7POS handoff, reservation release e confine vendita fiscale

## Informazioni generali

- **Task ID**: TASK-030
- **Titolo**: Win7POS handoff, reservation release e confine vendita fiscale
- **File task**: `docs/TASKS/TASK-030-win7pos-handoff-fiscal-boundary.md`
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-03
- **Ultimo aggiornamento**: 2026-08-03
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-030/`
- **Handoff**: CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW

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

### Audit e implementazione

- l'audit ha riusato trusted device/session, transport, sync supervisor, migrazioni
  SQLite additive e confine `SaleRepository` già presenti in Win7POS; il checkout
  originale dirty è rimasto intatto;
- la migration additiva `20260803060000_storefront_v1_pos_order_handoff` introduce il
  receipt ledger privato `FORCE RLS`, claim bounded con lease e ack versionato,
  idempotente e service-boundary-only; anon/authenticated non eseguono gli RPC;
- l'envelope `pos-customer-order-handoff-v1` espone soltanto snapshot pubblico
  confermato, quantità, fulfillment, status version, idempotency/correlation key e
  `fiscalStatus`; customer PII, inventory source ID e dati fiscali interni non sono
  serializzati;
- Win7POS aggiunge la migration SQLite `0012-customer-order-inbox`, inbox bounded e
  durevole, claim CAS, replay/ack persistente, generation fence, retention e una lane
  `CustomerOrders` supervisionata in bootstrap/start-of-day/WPF;
- gli outcome `accepted`, `rejected`, `prepared` e `completed` restano operativi: non
  creano vendite. Un `posSaleId` è ammesso soltanto se riferisce una vendita già
  `accepted` dello stesso shop; ordine cliente e vendita fiscale restano distinti;
- la PR Win7POS `#88` è draft e mergeable/CLEAN; la PR Admin `#67` resta draft e
  mergeable/CLEAN. Nessun consumer o flag production è stato attivato.

### Revision set eseguito

- Admin/Supabase finale: `64ef3170f5830e044ac130b127c94149d25ee1fc`, PR #67;
- codice API deployato staging: `bc5c9c92f844ce089c45819f5f80d10f6b949c84`;
  i commit successivi modificano esclusivamente harness/workflow E2E;
- Win7POS finale: `6c2eb9c8a0b6666f5dd59a2a132e616f5a8d5474`, PR #88;
- Client runtime invariato: `1855100f34a3563787b1ac71eafb4af60a1b72e6`,
  PR #5; governance pre-checkpoint `7cbc59d008eeb245ea0aac99d9d5a8c7ea9ef2ce`;
- migration staging: `20260803060000_storefront_v1_pos_order_handoff`;
- apply staging: run `30801335746`, job `91646346920` `PASS`; verifica finale:
  run `30801747388` `PASS`; deploy: run `30804781883` `PASS`;
- E2E staging finale: run `30805397611`, artifact `8852546826`, digest
  `sha256:cadd41e159f94eb2dcdc71566902945c53e3be38fff0bbeab136edfd9e92ee0c`.

### Gate

- pgTAP dedicato: 40/40 `PASS`; race locale due consumer: exit 0 in 0,74 s,
  una lease, reclaim attempt 2, stale ack `lease_conflict`, replay idempotente,
  un receipt e zero fiscal sale;
- foundation Admin sul worktree Win7POS corretto: exit 0 in 11,456 s, 865 test,
  863 pass e 2 skip; lint, typecheck, security scan, formatting e diff check `PASS`;
- CI Admin finale `30805402075`: Verify 3m07s e Database/pgTAP 2m51s `PASS`;
  Cloudflare build `30805402072`: 2m53s `PASS`, deploy production skipped;
- E2E `30805397611`: exit 0, job 42 s, contratto 16.996 ms; auth denial,
  claim/replay, accepted/replay, stale version, prepared, fiscal mismatch, completed e
  post-completion tutti `PASS`; order version 5, tre receipt, outbox delivered,
  zero `pos_sales`, zero riferimento fiscale e cleanup con zero righe attive;
- Win7POS locale mirato: 66/66 test in 7,81 s; gate statici 46/46 in 23,35 s;
  Core/Data Release x86 e format dei file modificati `PASS`;
- CI Windows `30804008501`: exit 0 in 12m46s, 878/878 test, 46/46 gate,
  solution/WPF x86, selftest e quattro smoke runtime `PASS`;
- Security Supply Chain `30804007997`: CodeQL, dependency/SBOM, secret/history e
  reproducibility `PASS`; artifact test `8852297572`, CodeQL `8852145917` e supply
  chain `8852051074` con digest registrati nelle evidence;
- test fisico Windows 7: `BLOCKED` esterno, perché nessun runner/dispositivo fisico è
  disponibile; non viene convertito in un PASS inferito e non invalida i gate Windows
  hostati/net48 x86 realmente eseguiti.

## Checkpoint release train — `CODEX_EXECUTOR`

TASK-030 è tecnicamente validato e consegnato alla futura review integrata come
`VALIDATED_PENDING_INTEGRATED_REVIEW`. Il protocollo claim/lease/ack, l'inbox durevole,
offline/reconnect/replay e il confine fiscale hanno evidence locale, CI Windows e
staging live; nessuna review formale intermedia è stata eseguita.

I tentativi non candidati sono preservati: il dispatch iniziale del workflow nuovo ha
restituito 404 perché non ancora presente sul default branch ed è stato sostituito da
un trigger push branch-scoped; il primo E2E ha rilevato il vincolo immagine/categoria
di una publication `published`, il secondo il nome PK errato nella sola cleanup proof.
Le due cause distinte sono state corrette con regressioni; il run finale non è un retry
cieco. La suite completa macOS Win7POS resta un diagnostico `FAIL` non candidato
(838/876, 38 incompatibilità baseline path/reparse/fixture); il gate Windows esatto è
878/878 `PASS`.

### Matrice CA -> evidence

| Criterio | Evidence | Stato |
|---|---|---|
| CA-01 | RPC service-only, trusted session/device e denial anon/cross-shop | PASS |
| CA-02 | envelope versionato/allow-list e fiscal status esplicito | PASS |
| CA-03 | race due consumer, lease expiry/reclaim e generation fence | PASS |
| CA-04 | inbox/receipt durable, duplicate e ack replay idempotenti | PASS |
| CA-05 | pgTAP state/version e staging accepted/prepared/completed | PASS |
| CA-06 | bogus sale rifiutata, zero sale automatica e zero fiscal reference | PASS |
| CA-07 | unit/harness timeout, offline, restart, reconnect e ack perso | PASS |
| CA-08 | CI Windows net48/x86, WPF e smoke runtime | PASS |
| CA-09 | migration/deploy/E2E/cleanup staging; production invariata | PASS |

### Matrice T-NN -> risultato

| Test | Risultato | Stato |
|---|---|---|
| T-01 | device autorizzato ammesso; auth invalida e ruoli cliente negati | PASS |
| T-02 | un claim winner, loser vuoto, expiry e reclaim attempt 2 | PASS |
| T-03 | un inbox/receipt, duplicate/restart/replay senza doppia vendita | PASS |
| T-04 | ack valido, stale/version conflict e archi server-authoritative | PASS |
| T-05 | ordine ricevuto/completato con zero `pos_sales` | PASS |
| T-06 | offline/timeout/reconnect/ack replay coperti da unit e harness | PASS |
| T-07 | CI Windows 878/878, WPF Release x86 e smoke | PASS |
| T-08 | staging exact contract, cleanup zero, secret scan e production OFF | PASS |

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.

## Chiusura

- **Conferma utente**: ricevuta in forma condizionata dal release train
- **Merge autorizzato**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: TASK-031 attivato dopo checkpoint verde
- **Riepilogo finale**: handoff POS idempotente tecnicamente validato; review integrata
  differita al freeze multi-repository
- **Data completamento**: non ancora
