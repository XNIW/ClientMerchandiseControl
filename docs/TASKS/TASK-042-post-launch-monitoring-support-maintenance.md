# TASK-042 — Post-launch monitoring, supporto e manutenzione

## Informazioni generali

- **Task ID**: TASK-042
- **Titolo**: Post-launch monitoring, supporto e manutenzione
- **File task**: `docs/TASKS/TASK-042-post-launch-monitoring-support-maintenance.md`
- **Stato**: ACTIVE
- **Fase**: FIX
- **Responsabile**: CODEX_FIXER
- **Data creazione**: 2026-08-21
- **Ultimo aggiornamento**: 2026-08-21
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-042/`
- **Outcome previsto**: POST_LAUNCH_OPERATIONS_READY_PRELAUNCH
- **Handoff**: CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX

## Dipendenze

- **Dipende da**: TASK-041
- **Sblocca**: nessun task in questo mandato
- **Writer**: Client; Admin, Supabase e gli altri repository restano read-only

## Scope

- definire runbook post-launch, incident response, monitoring/alerts e kill switch;
- implementare un checker read-only con modalità `prelaunch` e `live`;
- definire health check, smoke sintetici, tassonomia alert, supporto, privacy,
  backup/restore, retention, outage, rollback, escalation e manutenzione;
- riusare gli adapter observability TASK-035 e i fallback TASK-041 senza provider nuovo;
- eseguire dieci drill locali sintetici che attestino detection, severity, kill switch,
  fallback, recovery e assenza di PII;
- classificare destination, provider, owner e release production mancanti come requisiti
  esterni di operatività live, non come blocker del codice.

## Non incluso

- dichiarare o eseguire un go-live;
- configurare o acquistare monitoring SaaS, provider, billing o credenziali;
- inviare telemetria, push, transazioni o dati a utenti reali;
- migration, deploy o modifiche production;
- modifica del codice applicativo, della gestione prodotti o dei release candidate;
- simulatore complesso, deep security scan o nuovi validatori di superfici già chiuse.

## Criteri di accettazione

| CA | Descrizione | Tipo |
|---|---|---|
| CA-01 | Quattro runbook operativi coprono health, support, privacy, incidenti, kill switch e manutenzione | STATIC |
| CA-02 | Monitoring e alert coprono i sedici segnali minimi con payload redatto e owner esplicito | STATIC |
| CA-03 | Incident response definisce SEV-0 fino a SEV-3 con ciclo operativo completo | STATIC |
| CA-04 | Checker prelaunch e read-only, idempotente e passa sul repository completo | TEST |
| CA-05 | Checker live fallisce chiuso senza production, destination, provider e release attivi | TEST |
| CA-06 | Dieci drill sintetici verificano detection, severity, fallback, recovery e zero PII | TEST/SECURITY |
| CA-07 | Kill switch riusano i boundary esistenti e non disabilitano capability essenziali | STATIC/TEST |
| CA-08 | Review indipendente, CI exact-SHA, merge normale e hygiene sono reali | REVIEW/CI/GIT |

## Test case

| Test | Criteri | Procedura attesa |
|---|---|---|
| T-01 | CA-01/02/03 | validare struttura, segnali, severity, supporto e privacy dei quattro runbook |
| T-02 | CA-04 | sintassi, prelaunch mode, idempotenza e controllo read-only |
| T-03 | CA-05 | live mode senza input esterni e fixture sintetica completa |
| T-04 | CA-06 | eseguire i dieci drill table-driven e controllare campi bounded e redazione |
| T-05 | CA-07 | verificare i sette kill switch e i fallback esistenti |
| T-06 | CA-06/08 | security client diff-scoped, governance, action pins, review, CI e ancestry |

## Decisioni

| ID | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Il mandato USER_APPROVER 2026-08-21 autorizza Planning, Execution, Review e merge | Closeout mirato esplicito | ATTIVA |
| D-02 | PRELAUNCH passa senza valori owner o provider live | Il prodotto non e ancora lanciato | ATTIVA |
| D-03 | LIVE resta fail-closed fino alle quattro attestazioni esterne minime | Nessun claim production inferito | ATTIVA |
| D-04 | TASK-035 fornisce il boundary observability; test e drill usano no-op o fixture | Evitare SaaS e dati reali | ATTIVA |
| D-05 | I drill sono contratti shell table-driven, non un simulatore runtime nuovo | Scope bounded e deterministico | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Preparare prima del go-live un confine operativo verificabile per monitoraggio, supporto,
privacy e incident response, senza affermare che production o il monitoraggio live siano
attivi.

### Approccio minimo

1. chiudere TASK-041 con PR #20, CI PR/main e merge realmente osservati;
2. riusare il runbook observability TASK-035 e la matrice/rollback TASK-041;
3. creare soltanto i quattro documenti operations autorizzati;
4. implementare checker e test shell read-only con fixture sintetiche redatte;
5. eseguire i dieci drill come matrice bounded senza rete o wall-clock;
6. eseguire una sola volta i gate final-candidate mirati;
7. consegnare allo stesso reviewer indipendente read-only;
8. con esito APPROVED, pubblicare PR, verificare CI exact-SHA, fondere normalmente e
   osservare la CI `main`.

### Rischi e mitigazioni

- destination o owner esterno assente: classificazione esplicita, non CODE_BLOCKER;
- alert che richiede payload sensibile: schema allowlisted e test negativo PII;
- runbook non azionabile: ogni segnale ha detection, threshold, owner e response;
- drift dai kill switch: riferimenti a codice e documenti già validati;
- CI/cleanup non osservabile: singolo retry e classificazione esterna prevista;
- scope creep runtime: nessun file applicativo o configurazione release nel piano.

Il task è stato inizialmente aperto in `ACTIVE / PLANNING`; l'autorizzazione
USER_APPROVER contenuta nel mandato 2026-08-21 abilita immediatamente la transizione
bounded a Execution.

`CODEX_PLANNING_APPROVED_TO_EXECUTION`.

## Execution — `CODEX_EXECUTOR`

- creati i quattro runbook autorizzati per operations, incident response, monitoring e
  kill switch, senza provider o owner inventati;
- implementati checker read-only `prelaunch`/`live` e 24 test di contratto;
- eseguiti 10/10 drill locali table-driven con detection, severity, kill switch,
  fallback, recovery e log safe;
- prelaunch: exit 0, 81 READY, 4 UNVERIFIABLE_EXTERNAL, risultato READY;
- live: exit 1 atteso, 80 READY, quattro requisiti esterni MISSING e summary MISSING;
- definiti i sedici segnali minimi e SEV-0/1/2/3 con ciclo operativo completo;
- verificati i sette kill switch/fallback esistenti; nessun flag o codice runtime
  aggiunto;
- `git diff --check`, sintassi shell, governance state, governance 101/101, action pins,
  telemetry privacy e security client 703 file sono PASS;
- `scripts/check.sh`, AAB, archive iOS e performance locali sono NOT_RUN perché il diff
  non modifica codice applicativo o release configuration; la CI exact-SHA eseguirà i
  gate canonici;
- exact technical SHA: `d7d4fa9a94b07dd6422e4018a524ca9e5478bfe1`;
- production, Admin, Supabase, provider, billing e store invariati.

`CODEX_EXECUTION_COMPLETE_TO_REVIEW`.

## Review — `CODEX_REVIEWER`

- review indipendente read-only sul range
  `ce6045e4799cdc0c51cbd15cd173510e5cae88a4..f85bc3b99685674d7bc31b9f2775c6d3d5285f13`;
- P0: 0; P1: 0; P2: 3; P3: 0;
- `F-042-R01` P2: il runbook attribuiva a `BackendHealthService` un endpoint
  Storefront inesistente e stati non allineati al runtime; richiesti probe Auth reale,
  RPC Storefront reale e regressione contro il drift;
- `F-042-R02` P2: i drill verificavano soltanto la forma della tabella; richiesti
  fixture/adapter esistenti, risultato operativo esatto e test negativo su mapping
  alterato;
- `F-042-R03` P2: la denylist log era fail-open per identificativi, contenuto carrello,
  telefono e indirizzo; richiesta allowlist sull'intero record con casi negativi;
- requisiti live e owner mancanti restano esterni e non sono finding tecnici;
- security review manuale diff-scoped; scanner formale
  `FORMAL_EXTERNAL_SCANNER_NOT_AVAILABLE`, nessuna Deep Security Scan.

Esito: `CHANGES_REQUIRED`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Fix — `CODEX_FIXER`

Un'unica passata bounded corregge esclusivamente `F-042-R01`–`F-042-R03`, aggiunge le
regressioni richieste e riconsegna allo stesso reviewer indipendente.

## Chiusura

Da compilare dopo review, CI e merge reali.
