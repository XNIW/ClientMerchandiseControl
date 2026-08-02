# TASK-009 — Pipeline immagini pubbliche Storefront

## Informazioni generali

- **Task ID**: TASK-009
- **Titolo**: Pipeline immagini pubbliche Storefront
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-01
- **Ultimo aggiornamento**: 2026-08-01
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-009/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Dipendenze

- **Dipende da**: TASK-005, TASK-007
- **Sblocca**: TASK-013, TASK-014, TASK-016, TASK-037

## Scope

- riusare la pipeline immagini prodotto interna soltanto come sorgente approvata;
- creare namespace/bucket pubblico Storefront separato dal bucket operativo;
- pubblicare esclusivamente versioni `ready`, approvate e associate alla pubblicazione;
- produrre varianti `thumb`, `card` e `detail` compresse, downsampled e versionate;
- validare content type, dimensioni, payload, path e rimuovere EXIF quando opportuno;
- garantire idempotenza, cache immutable, sostituzione, rollback e orphan cleanup;
- integrare editor/anteprima/audit Admin e riferimento immagine nel contratto pubblico;
- coprire storage policy, RBAC, input malevoli, E2E locale e staging.

## Non incluso

- download o pubblicazione diretta dal client cliente;
- redesign della pipeline immagini operativa esistente;
- caricamento arbitrario in bucket interno;
- image cache Flutter TASK-014/TASK-017;
- modifiche production.

## Criteri di accettazione

| CA | Descrizione |
|---|---|
| CA-01 | Bucket/namespace pubblico è separato e non espone path o oggetti interni |
| CA-02 | Solo immagini `ready`, approvate e shop-scoped possono essere pubblicate |
| CA-03 | `thumb`, `card` e `detail` rispettano limiti, formato e dimensioni definiti |
| CA-04 | Content type, payload, filename e path traversal sono validati server-side |
| CA-05 | Pubblicazione/sostituzione sono idempotenti, versionate e cache immutable |
| CA-06 | Rollback ripristina la versione precedente e cleanup rimuove solo orphan sicuri |
| CA-07 | Contratto pubblico e anteprima Admin usano gli stessi riferimenti pubblicati |
| CA-08 | RBAC, storage policy e audit negano cliente, cross-shop e ruolo non autorizzato |
| CA-09 | Gate Admin, SQL/storage, E2E e staging sono PASS senza fixture residue |

## Test case

| Test | Criteri | Procedura |
|---|---|---|
| T-01 | CA-01, CA-02 | ready/draft/rejected, cross-shop e bucket interno denied |
| T-02 | CA-03, CA-04 | MIME falso, oversized, EXIF, path traversal e varianti |
| T-03 | CA-05, CA-06 | doppia richiesta, sostituzione, rollback e orphan cleanup |
| T-04 | CA-07 | anteprima/projection/API restituiscono la stessa versione |
| T-05 | CA-08 | permissions manage, audit e ruolo non autorizzato |
| T-06 | CA-09 | lint/typecheck/unit/build/pgTAP/storage/Playwright/staging |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | La sorgente operativa non diventa mai pubblica | Preserva il confine public/internal | ATTIVA |
| D-02 | Nomi oggetto content-addressed/versionati e cache immutable | Evita cache stale e collisioni | ATTIVA |
| D-03 | Derivazione server-side idempotente con stato esplicito | Il client non controlla trasformazioni o path | ATTIVA |
| D-04 | Rollback cambia il riferimento pubblicato, non riscrive la versione | Ripristino atomico e auditabile | ATTIVA |

## Planning — `CODEX_PLANNER`

### Approccio autorizzato

1. censire pipeline, bucket, storage policy e worker immagini esistenti;
2. definire ownership degli oggetti pubblici e lifecycle versione/rollback/cleanup;
3. implementare trasformazioni e mutazioni Admin fail-closed;
4. integrare anteprima e projection senza duplicare il contratto pubblico;
5. aggiungere negative test, idempotenza, cache header e staging E2E;
6. consegnare a `VALIDATED_PENDING_INTEGRATED_REVIEW` e chiudere il checkpoint
   Milestone 2 solo con tutti i gate verdi.

### Rischi

- esposizione bucket interno: policy separate e test anon/auth negativi;
- decompression bomb/oversized: limiti prima della decodifica e timeout;
- oggetti orfani: cleanup conservativo con reference check;
- cache stale: URL/versione immutabile e cambio atomico del riferimento;
- scope creep Flutter: TASK-009 espone il contratto, il client lo consuma nei task
  catalogo dedicati.

### Handoff

`CODEX_PLANNING_APPROVED_TO_EXECUTION` — autorizzazione USER_APPROVER nel prompt del
release train; production resta fuori scope.

## Execution — `CODEX_EXECUTOR`

In avvio nel repository Admin canonico.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.
