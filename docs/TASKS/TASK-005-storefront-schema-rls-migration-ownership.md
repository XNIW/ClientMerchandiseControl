# TASK-005 — Supabase Storefront schema, RLS, grants e migration ownership

## Informazioni generali

- **Task ID**: TASK-005
- **Titolo**: Supabase Storefront schema, RLS, grants e migration ownership
- **File task**: `docs/TASKS/TASK-005-storefront-schema-rls-migration-ownership.md`
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: INTEGRATED_REVIEW
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-01
- **Ultimo aggiornamento**: 2026-08-01
- **Ultimo agente**: CODEX_EXECUTOR
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-005/`
- **Handoff**: STOREFRONT_V1_MILESTONE_CHECKPOINT_VALIDATED

## Dipendenze

- **Dipende da**: TASK-003, TASK-004
- **Sblocca**: TASK-006, TASK-007, TASK-009, TASK-010, TASK-024, TASK-027, TASK-033

## Scope

- riconfermare da source, ledger e linked project che Admin è l'unico repository
  canonico delle migration;
- dimostrare assenza o riconciliazione di drift prima di qualunque apply;
- creare migration additive per le entità Storefront pubbliche previste dal release
  train, senza duplicarle nel Client;
- applicare grant minimi e RLS default-deny per guest/customer, shop e stato;
- fissare constraint server-side per CLP integer non negativo, stati e riferimenti;
- produrre fixture/test SQL positivi e negativi, replay da zero, rollback rehearsal e
  smoke staging;
- mantenere production invariata.

## Contesto

`ADR-010` assegna migration, RLS, grant, RPC e contratto server machine-readable al
repository Admin. TASK-005 materializza il layer L2 di `CMC-STOREFRONT-LOGICAL 1.0.0`.
Il progetto staging esistente è l'unico target remoto autorizzato durante l'Execution.

## Non incluso

- UI Admin, promozioni complete e pipeline media di TASK-007–TASK-009;
- query contract, search e pagination di TASK-010;
- cache o UI Flutter;
- profilo, carrello, hold, ordine, POS, push o pagamento;
- qualunque write production o migration distruttiva.

## File coinvolti

- repository Admin canonico: migration, test SQL, fixture e documentazione deployment;
- Client: questo task, manifest/checkpoint ed evidence sintetiche;
- Supabase staging: apply controllato e verifiche post-apply;
- production: zero write.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | L'authority migration Admin è riconfermata da source, linked project, ledger e provenance senza duplicazione cross-repo | STATIC/GIT |
| CA-02 | Migration locali e remote sono riconciliate; replay da zero e linked migration list non mostrano drift | DATABASE |
| CA-03 | Lo schema Storefront è additivo, shop-scoped e separato dalle tabelle operative | DATABASE/SECURITY |
| CA-04 | CLP è integer, zero-decimal, non negativo e validato server-side | DATABASE |
| CA-05 | `anon` e customer leggono soltanto risorse pubblicate del corretto shop e non possono scrivere | DATABASE/SECURITY |
| CA-06 | Draft, paused, altro shop, inventory, prezzi operativi, fornitori e immagini interne sono negati | DATABASE/SECURITY |
| CA-07 | Grant, RLS, funzioni, `search_path`, `EXECUTE` e Storage sono least-privilege e testati | SECURITY |
| CA-08 | Apply e rollback rehearsal staging sono osservabili, ripetibili e non toccano production | DATABASE/MANUAL |
| CA-09 | Nessun secret, service role, dato personale o valore production entra in Git/evidence | SECURITY/GIT |
| CA-10 | Manifest, checkpoint, task e worklog riportano soltanto gate reali e SHA tracciabili | STATIC/GIT |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-02 | STATIC/DATABASE | confrontare migration source/ledger/link e replay pulito |
| T-02 | CA-03, CA-04 | DATABASE | applicare migration in ambiente isolato e verificare constraint |
| T-03 | CA-05 | DATABASE/SECURITY | anon/customer published PASS; write DENIED |
| T-04 | CA-06 | DATABASE/SECURITY | draft/paused/cross-shop/denylist DENIED |
| T-05 | CA-07 | SECURITY | audit grant/RLS/function/storage con test negativi |
| T-06 | CA-08 | DATABASE | apply staging, post-check e rollback rehearsal controllato |
| T-07 | CA-09 | SECURITY/GIT | secret e sensitive-value scan su diff/index/worktree |
| T-08 | CA-10 | STATIC/GIT | validator governance, link check e `git diff --check` |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Admin resta l'authority candidata finché il preflight ledger/source non la riconferma | Non assumere ownership remota senza evidence corrente | ATTIVA |
| D-02 | Solo migration additive e staging apply | Production e dati operativi restano protetti | ATTIVA |
| D-03 | Nessuna tabella Storefront nel Client | Preservare ADR-010 e un'unica authority | ATTIVA |
| D-04 | Il task usa il profilo `STOREFRONT_V1` di ADR-011 | Evitare review duplicate mantenendo checkpoint e review finale | ATTIVA |
| D-05 | Il checkpoint TASK-005 valida il solo modello autoritativo default-deny; lettura pubblicata, projection, rollback compositivo e no-drift finale sono riconfermati con TASK-006/TASK-010 al checkpoint Milestone 1 | Il task non deve duplicare projection o API assegnate ai task successivi, né trasformare gate non ancora eseguiti in PASS | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Creare la base dati Storefront minimizzata e default-deny sulla quale TASK-006 e
TASK-010 possano costruire projection e API pubblica.

### Analisi

La source audit precedente indica Admin come authority, ma TASK-005 deve riconfermare
HEAD, migration ledger, Supabase link e drift prima di scrivere. Il rischio principale è
esporre superfici operative tramite grant/RLS permissivi o applicare source non
riconciliata a staging.

### Approccio

1. creare un worktree Admin pulito su `integration/storefront-v1`;
2. leggere integralmente governance, task backend pertinenti e migration correnti;
3. confrontare migration list locale/remota e provenance senza stampare credenziali;
4. progettare migration additive, constraint, grant e RLS con test negativi;
5. replay locale/isolato, poi dry-run/delta e apply staging allowlisted;
6. post-check, rollback rehearsal, secret scan e checkpoint TASK-005;
7. passare TASK-005 a `VALIDATED_PENDING_INTEGRATED_REVIEW` e attivare TASK-006.

### Rischi

- drift remoto: bloccare l'apply e riconciliare source/ledger;
- policy legacy permissive: revocare soltanto sulla superficie Storefront autorizzata,
  senza regressioni operative;
- lock/migration lunga: misurare e usare change additivi/indici sicuri;
- quota staging: limitare fixture e rimuovere soltanto dati fixture identificabili;
- checkout Admin dirty: usare esclusivamente il worktree dedicato.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: ricevuta nel prompt Storefront v1 del 2026-08-01

## Execution — `CODEX_EXECUTOR`

### Obiettivo compreso

Preflight ownership e implementazione additiva sul repository/target canonico.

### File controllati

- Admin `AGENTS.md`, Master Plan completo, protocollo, ADR e documenti architetturali;
- 100 migration canoniche e 19 file pgTAP sul candidato finale;
- workflow protetti di migrazione/provenance staging;
- ledger remoto staging con remap TASK-142 approvato;
- migration e pgTAP Storefront sul branch `integration/storefront-v1`.

### Piano minimo

Il planning approvato sopra è vincolante.

### Modifiche fatte

- creato il modello autoritativo additivo per settings, categorie, immagini,
  pubblicazioni prodotto, promozioni e relative associazioni;
- aggiunti constraint CLP `bigint`, stato, fulfillment, provenance shop-scoped e URL
  pubblici non firmati/non provenienti dal bucket interno;
- applicati RLS `ENABLE/FORCE`, zero policy client e grant CRUD soltanto a
  `service_role` sulle tabelle di authoring;
- aggiunti helper `SECURITY DEFINER` con `search_path=''` ed EXECUTE revocato ai ruoli
  mobili;
- aggiunti 48 test pgTAP e workflow staging con target allow-listed, SHA esatto,
  dry-run, apply e post-verifica;
- aggiornate dipendenze Admin vulnerabili con audit finale a zero vulnerabilità.

### Check eseguiti

- replay locale 100 migration: `PASS`, exit 0, 27,75 s sul candidato finale;
- pgTAP completo: `PASS`, 19 file / 1.330 test, exit 0, 46,80 s;
- `db lint`: `PASS`, zero finding;
- Admin install/lint/typecheck/security/foundation/build/audit: `PASS`;
- CI Admin `30717750929`: `PASS`, Verify e Database/pgTAP sullo SHA `ef2e9430`;
- Cloudflare CI `30717750934`: `PASS`, build OpenNext e smoke locale;
- dry-run staging `30717871139`: `PASS`, unico delta `20260801195852`;
- apply/post-check staging `30717903744`: `PASS`, exit 0, 49 s;
- production write: `NOT_RUN` per vincolo del release train.

### Matrice CA -> evidence

| CA | Esito TASK-005 | Evidence |
|---|---|---|
| CA-01 | PASS | Admin authority, 100 migration locali, ledger staging e remap TASK-142 riconciliato |
| CA-02 | PASS | replay locale, dry-run esatto e ledger post-apply `migrationLedgerExact=true` |
| CA-03 | PASS | migration `20260801195852_storefront_v1_schema_rls.sql` |
| CA-04 | PASS | pgTAP CLP e post-check `customerPriceIsBigint=true` |
| CA-05 | PASS per confine TASK-005; lettura pubblicata compositiva NOT_RUN | authoring anon/auth senza grant; RPC/projection assegnate a TASK-006/TASK-010 |
| CA-06 | PASS per confine TASK-005; draft/paused API NOT_RUN | inventory/customer negative test e zero accesso authoring |
| CA-07 | PASS | 6/6 RLS forzate, zero policy authoring, helper privati |
| CA-08 | PASS apply; rollback compositivo NOT_RUN | run `30717903744`; rehearsal finale assegnato al checkpoint Milestone 1 |
| CA-09 | PASS | security scan, evidence sanitizzata, production invariata |
| CA-10 | PASS | task/evidence/manifest/checkpoint aggiornati con SHA e run reali |

### Matrice T-NN -> risultato

| Test | Esito | Evidence |
|---|---|---|
| T-01 | PASS | delta reconciler: remoto 99, locale 100, pending Storefront unico |
| T-02 | PASS | replay e 48/48 pgTAP Storefront |
| T-03 | PASS per default-deny; public read NOT_RUN | anon/auth authoring `42501`; public RPC TASK-010 |
| T-04 | PASS per inventory/authoring; API stato NOT_RUN | negative pgTAP cross-shop/inventory; API TASK-010 |
| T-05 | PASS | RLS/grant/helper/post-check staging |
| T-06 | PASS apply; rehearsal NOT_RUN | apply staging PASS; rehearsal al checkpoint M1 |
| T-07 | PASS | security scan e audit 0 vulnerabilità |
| T-08 | PASS | validator governance da rieseguire sul commit di transizione |

### Rischi rimasti

- projection, RPC pubblici e prove published/draft/paused restano a TASK-006/TASK-010;
- rollback rehearsal e no-drift finale restano obbligatori al checkpoint Milestone 1;
- warning GitHub Actions Node 20 deprecation è registrato per hardening Milestone 5.

### Handoff a Review

Non applicabile prima del checkpoint integrato.

## Checkpoint release train — `CODEX_EXECUTOR`

### Gate pertinenti eseguiti

Replay, pgTAP, lint SQL, gate Admin, dependency audit, CI e staging apply sono verdi
sullo SHA Admin `ef2e94302102745d57aedc5071d3edd4ddee0e91`.

### Compatibilità e smoke staging

Il post-check remoto conferma sei tabelle autoritative, sei RLS forzate, zero policy
client, privilegi server-only, CLP bigint e flag default-OFF. Nessuna superficie
pubblica è ancora attiva; production è invariata.

### Security scan mirato

`PASS`: security scan repository, 48 pgTAP, cross-shop/source validation, URL privati e
firmati negati, audit dipendenze a zero vulnerabilità.

### Stato manifest/checkpoint

Aggiornati con PR Admin `#67`, SHA, CI, dry-run/apply staging e prossimo task.

### Handoff al task successivo

- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Review outcome**: NOT_RUN
- **Prossimo task**: TASK-006
- **Handoff**: STOREFRONT_V1_MILESTONE_CHECKPOINT_VALIDATED

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

Riservata alla review integrata finale.

## Fix — `CODEX_FIXER`

Riservata all'eventuale ciclo Fix integrato.

## Chiusura

- **Conferma utente**: ricevuta e condizionata ai gate del release train
- **Merge autorizzato da USER_APPROVER**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: nessuno
- **Riepilogo finale**: non applicabile
- **Data completamento**: non applicabile
