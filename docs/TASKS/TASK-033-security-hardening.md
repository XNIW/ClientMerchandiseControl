# TASK-033 — Threat model, RLS abuse testing, rate limit e security hardening

## Informazioni generali

- **Task ID**: TASK-033
- **Titolo**: Threat model, RLS abuse testing, rate limit e security hardening
- **File task**: `docs/TASKS/TASK-033-security-hardening.md`
- **Stato**: BLOCKED
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-03
- **Ultimo aggiornamento**: 2026-08-08
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-033/`
- **Handoff**: BLOCKED_SECURITY_SCAN_TOOL_PERMISSION_PROFILE

## Dipendenze

- **Dipende da**: TASK-005, TASK-020, TASK-025, TASK-027, TASK-032
- **Checkpoint consumati**: schema/RLS Storefront, OAuth PKCE/session lifecycle,
  reservation hold, order idempotente, payment boundary e Milestone 4 E2E 629/629
- **Sblocca**: TASK-038, TASK-039, TASK-040 e freeze integrato
- **Repository writer**: nessuno durante la scansione profonda read-only; dopo il
  report canonico, un solo writer per volta sul repository proprietario di eventuali
  hardening e regressioni approvati dallo scope

## Scope

- produrre un threat model multi-repository con attacker, asset, trust boundary,
  ingressi, sink privilegiati e dipendenze esterne;
- eseguire una Deep Security Scan ripetuta e read-only su Client Flutter,
  Admin/Supabase e Win7POS del worktree release train, seguita da validazione
  centralizzata e attack-path analysis;
- verificare RLS/grant/FORCE RLS, cross-tenant/cross-user/cross-shop, auth/PKCE,
  callback/deep link/share payload, storage pubblico e upload immagini;
- verificare Edge Function/RPC, `search_path`, SQL dinamico, privilegi, secret,
  configurazione fail-closed, log e PII;
- verificare rate limit e abuse control per catalogo, auth, hold exhaustion, order
  spam, replay/idempotenza, webhook, notification e POS inbox/outbox;
- verificare Admin RBAC, audit, supply chain, CI, artifact e mobile platform boundary;
- correggere soltanto finding tecnici confermati P0/P1/P2 dentro lo scope, con
  regressioni e gate impattati; registrare P3/follow-up senza scope creep;
- mantenere production invariata e tutte le capability sensibili OFF.

## Non incluso

- penetration test distruttivi, denial of service non bounded o accesso a dati reali;
- modifica production, rotazione credential, acquisto di scanner o servizi;
- pubblicazione di raw scan, token, URL sensibili, PII o exploit riutilizzabili contro
  sistemi esterni;
- accettazione di contratti, attivazione provider payment/push o bypass di MFA;
- refactor opportunistici non necessari a chiudere un finding confermato.

## File coinvolti

- artifact canonici della Codex Security Deep Scan nel workspace gestito dalla skill,
  non versionati nel repository;
- codice/test Client, Admin/Supabase o Win7POS soltanto dopo la scansione e soltanto per
  hardening confermati;
- task/evidence sanitizzata, Master Plan, checkpoint, release manifest e worklog.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | threat model e inventory coprono i tre repository e i confini remoti | SECURITY/STATIC |
| CA-02 | RLS/grant/cross-tenant/cross-user/cross-shop sono verificati con test negativi | PGTAP/SECURITY |
| CA-03 | auth PKCE, callback, deep link e share payload non espongono authority o dati interni | SECURITY/UNIT |
| CA-04 | storage, RPC/Function e SQL `search_path` falliscono chiuso | SECURITY/PGTAP |
| CA-05 | hold/order/payment/webhook/POS/push resistono a spam, replay e race bounded | SECURITY/CONCURRENCY |
| CA-06 | Admin RBAC/audit e log/PII/secret rispettano least privilege e minimizzazione | SECURITY/INTEGRATION |
| CA-07 | dipendenze, CI e artifact non introducono secret o finding P0/P1/P2 aperti | SECURITY/CI |
| CA-08 | ogni finding confermato ha prova, posizione, severità, fix e regressione | SECURITY/DOCUMENTATION |
| CA-09 | production resta invariata e i flag sensibili restano OFF | CONFIG/GIT |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-08 | SECURITY | Deep Scan completa discovery, validation, attack path e report canonico |
| T-02 | CA-02 | PGTAP | owner e tenant corretti ammessi; cross-user/shop/tenant negati |
| T-03 | CA-03 | UNIT/INTEGRATION | callback/link/share malformati o malevoli falliscono chiuso |
| T-04 | CA-04 | STATIC/PGTAP | grants, search_path, storage e service-only boundary verificati |
| T-05 | CA-05 | CONCURRENCY | hold exhaustion, duplicate order, webhook/POS/push replay e timeout |
| T-06 | CA-06 | INTEGRATION | RBAC Admin, audit allow-list e log sanitizer su flussi privilegiati |
| T-07 | CA-07 | SECURITY/CI | secret e dependency scan dei revision set finali e artifact applicabili |
| T-08 | CA-09 | GIT/STAGING | post-verifica staging e prova read-only di production/flag OFF |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | La Deep Security Scan è read-only e non condivide writer con discovery/validation | Preserva l'indipendenza della verifica | ATTIVA |
| D-02 | Gli artifact raw restano nel workspace gestito; Git riceve solo evidence sanitizzata | Evita secret, PII e repository bloat | ATTIVA |
| D-03 | Finding P0/P1/P2 confermati vengono corretti nello scope con regressione | Il release train non può congelare difetti tecnici aperti | ATTIVA |
| D-04 | P3 è ammesso solo se realmente opzionale e fuori dai criteri | Mantiene la soglia richiesta senza scope creep | ATTIVA |
| D-05 | Test abuse/load restano bounded e usano fixture rollback-safe | Nessun impatto distruttivo o su dati reali | ATTIVA |
| D-06 | Planning ed Execution sono autorizzati dal prompt USER_APPROVER del 2026-08-02 | Mantiene il train headless continuo | ATTIVA |
| D-07 | L'emendamento USER_APPROVER del 2026-08-08 richiede una nuova Deep Security Scan repository-wide del solo Client allo SHA `ec74166ea20786b8deaa9965cac103984c927820`; il precedente manifest fallito non è accettabile e la review TASK-032/TASK-033 segue solo dopo completion reale | Rende immutabili target e condizione di avanzamento della ripresa | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Ridurre il rischio residuo Storefront v1 con una verifica profonda, ripetuta e
riproducibile dei confini di fiducia e con hardening mirato dei soli finding tecnici
confermati, senza modificare production.

### Analisi

- il revision set attraversa client pubblico, control plane, database/RPC, code
  asincrone, POS e provider dormant: una scansione per singolo repository perderebbe
  attack path cross-repository;
- i checkpoint funzionali provano happy/negative path ma non sostituiscono discovery
  indipendente, validazione e analisi di exploit chain;
- RLS, idempotenza e flag OFF sono controlli centrali che vanno provati sia staticamente
  sia con principal ostili e concorrenza bounded;
- i raw log di scan non sono evidence versionabile: il task conserva soltanto risultati
  canonici, conteggi, finding sanitizzati e comandi riproducibili.

### Approccio autorizzato

1. capability preflight della skill `codex-security:deep-security-scan` sul root dei
   worktree release train;
2. discovery ripetuta read-only sui tre repository e accettazione del manifest
   terminale;
3. threat model canonico, validation, attack-path analysis e report sigillato;
4. triage dei finding rispetto a scope, exploitability e controlli compensativi;
5. hardening P0/P1/P2 con writer seriale e regressioni dedicate;
6. RLS/abuse/concurrency/secret/dependency/staging gate sul candidato finale;
7. evidence/checkpoint e attivazione TASK-034 soltanto con zero P0/P1/P2 aperti.

### Rischi e mitigazioni

- falsi positivi: validazione centralizzata e prova di reachability prima del fix;
- scan incompleta: preflight capability e manifest terminale obbligatori;
- collisione writer: nessuna modifica durante scan, poi un repository writer alla volta;
- test abusivi: fixture isolate, rollback, limiti e mutex staging;
- leakage evidence: artifact raw non versionati e sanitizer prima dell'handoff;
- deriva revision set: SHA e worktree puliti registrati prima e dopo ogni fase.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: prompt headless Storefront v1 2026-08-02

## Execution — `CODEX_EXECUTOR`

### Ripresa 2026-08-08

- repository Client, remote, branch, PR #5 e SHA sono stati verificati; il worktree di
  integrazione era tracked-clean ma conteneva output ignorati, quindi è stato creato un
  worktree detached sterile con HEAD esatto
  `ec74166ea20786b8deaa9965cac103984c927820`, 564 file tracciati e nessun file
  untracked/ignored;
- il repository Admin è stato verificato in sola lettura sullo SHA
  `e0406834af09173902e2f64948dd5834f4a9fac5`, coincidente con branch remoto e PR #67;
- il precedente `coordinator-manifest.json` esiste ancora, ha timestamp
  `2026-08-03T13:57:58-0400`, stato `failed` e causa `usage limit`; non è stato copiato,
  accettato o usato per candidate/findings;
- il nuovo preflight helper `deep_security_scan` ha exit code 0 e stato `ready`;
  goal tools e `features.goals` risultano disponibili e non è stata applicata alcuna
  modifica persistente di configurazione;
- una sola chiamata a `start_codex_security_deep_scan`, target Client isolato e scope
  `.`, non ha avviato né riagganciato discovery. Errore terminale esatto:
  `Deep Scan cannot safely start a read-only worker: the parent must provide a managed filesystem permission profile.`;
- il tool non ha restituito `scanId`, discovery manifest o failure-manifest. Come
  prescritto, non è stato eseguito un secondo tentativo e non sono iniziati validation,
  attack-path, draft, completion, integrated review, fix o merge;
- production, Supabase, Storage, secret e infrastruttura pubblica sono rimasti
  invariati.

### Esito gate

| Gate | Risultato | Stato |
|---|---|---|
| Git/SHA/isolation Client | worktree detached pulito su `ec74166e` | PASS |
| SHA Admin read-only | `e0406834`, branch/remote allineati | PASS |
| Vecchio failure-manifest | acquisito solo come storia; non riutilizzato | PASS |
| Capability/config preflight fresco | helper exit 0, `ready` | PASS |
| Nuova Deep discovery | worker read-only privo di managed permission profile | BLOCKED |
| Manifest/candidate pages/threat model | discovery non avviata | NOT_RUN |
| Validation/attack-path/draft/completion/report | dipendenti dalla discovery | NOT_RUN |
| Review integrata/closeout/merge | vietati dalla stop condition | NOT_RUN |

Il task resta `BLOCKED / EXECUTION`; non esiste una scan parziale da rappresentare come
validata.

### Residual audit remoto 2026-08-08

- il ref Client congelato, la PR #5 e il worktree detached restano sullo SHA esatto;
- un solo rerun CI exact-SHA (`30824651949`, attempt 2) è rimasto
  `BLOCKED_EXTERNAL` per billing, con tre job e zero step;
- il drift di governance introdotto dal passaggio `ACTIVE -> BLOCKED` è stato risolto
  nel solo worktree documentale rendendo il checker status-aware e aggiungendo una
  fixture negativa; governance corrente `PASS`, regressioni `9/9 PASS`, shell syntax e
  `git diff --check` `PASS`;
- nessun codice runtime, merge, deploy o sistema production è stato modificato. Il
  batch documentazione/governance è isolato su un branch post-target dedicato, non è
  integrato e non fa parte del target da scansionare.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.

## Chiusura

- **Conferma utente**: ricevuta in forma condizionata dal release train
- **Merge autorizzato**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: nessuno finché TASK-033 resta bloccato
- **Riepilogo finale**: Deep Security Scan non avviata per managed filesystem
  permission profile assente nel parent host
- **Data completamento**: non ancora
