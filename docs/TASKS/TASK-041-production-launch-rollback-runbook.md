# TASK-041 — Production launch, rollback e runbook

## Informazioni generali

- **Task ID**: TASK-041
- **Titolo**: Production launch, rollback e runbook
- **File task**: `docs/TASKS/TASK-041-production-launch-rollback-runbook.md`
- **Stato**: ACTIVE
- **Fase**: REVIEW
- **Responsabile**: CODEX_RE_REVIEWER
- **Data creazione**: 2026-08-21
- **Ultimo aggiornamento**: 2026-08-21
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-041/`
- **Outcome previsto**: PRODUCTION_READY_PENDING_EXTERNAL_ACTIVATION
- **Handoff**: CODEX_FIX_COMPLETE_TO_RE_REVIEW

## Dipendenze

- **Dipende da**: TASK-039, TASK-040
- **Sblocca**: TASK-042
- **Writer**: Client; Admin, Supabase e gli altri repository restano read-only

## Scope

- definire checklist, launch runbook e rollback runbook per il confine tecnico
  controllabile prima dell'attivazione production;
- implementare un checker read-only con modalità `technical` e `activation`;
- inventariare i requisiti Supabase, Auth, Android, iOS, Maps, pagamenti,
  notifiche, observability e legal/store senza leggere o stampare secret;
- attestare i kill switch già presenti e i fallback fail-closed;
- classificare credenziali, billing, console, owner value e approvazioni mancanti
  come activation requirement esterni, non come blocker del codice.

## Non incluso

- migration, deploy, dati, secret o policy production;
- upload, release o rollout App Store/Play, TestFlight e transazioni reali;
- acquisti, billing, provisioning, certificati o nuovi provider;
- modifica della gestione prodotti mobile, redesign, refactor o nuovi servizi;
- riapertura delle validazioni artifact TASK-039/040 o deep security scan.

## Criteri di accettazione

| CA | Descrizione | Tipo |
|---|---|---|
| CA-01 | Checklist e runbook coprono il flusso A-L e separano tecnica da activation | STATIC |
| CA-02 | Checker technical è read-only, redatto, idempotente e passa sul repository completo | STATIC/TEST |
| CA-03 | Checker activation fallisce chiuso senza attestazioni esterne | TEST |
| CA-04 | Matrice copre Supabase, Auth, Android, iOS, Maps, payment, notification, observability e legal/store | STATIC |
| CA-05 | Kill switch esistenti sono documentati e verificati senza duplicare flag | STATIC/TEST |
| CA-06 | Production resta invariata e nessun secret o dato reale compare nelle evidence | SECURITY |
| CA-07 | Review indipendente, CI exact-SHA, merge normale e hygiene sono reali | REVIEW/CI/GIT |

## Test case

| Test | Criteri | Procedura attesa |
|---|---|---|
| T-01 | CA-01/04 | validazione strutturale dei tre documenti e della matrice |
| T-02 | CA-02 | sintassi, technical mode, idempotenza e controllo read-only |
| T-03 | CA-03 | activation mode senza input esterni e fixture con attestazioni sintetiche |
| T-04 | CA-05 | verifica dei sette fallback separati contro config e runtime esistenti |
| T-05 | CA-06 | security client diff-scoped e scansione output redatto |
| T-06 | CA-07 | governance, action pins, review distinta, PR/main CI e ancestry |

## Decisioni

| ID | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Il mandato USER_APPROVER 2026-08-21 autorizza Planning, Execution, Review, merge e TASK-042 | Closeout mirato esplicito | ATTIVA |
| D-02 | Le assenze esterne sono activation requirement e non CODE_BLOCKER | Il codice indipendente deve completarsi | ATTIVA |
| D-03 | I checker consumano sole attestazioni booleane, mai valori sensibili | Redazione e least privilege | ATTIVA |
| D-04 | I kill switch esistenti sono riusati; nessun flag runtime duplicato | Evitare scope creep e regressioni | ATTIVA |
| D-05 | TASK-039/040 e relativi artifact non vengono rigenerati | Il diff non modifica runtime o release configuration | ATTIVA |

## Planning — `CODEX_PLANNER`

1. riusare manifest, runbook, configuration matrix ed evidence TASK-039/040;
2. creare i tre documenti operativi con matrice e sequenza A-L;
3. implementare checker e test shell minimali, read-only e redatti;
4. eseguire una sola volta i gate final-candidate richiesti, incluso activation
   fail-closed atteso;
5. consegnare il commit a un reviewer read-only distinto per review prodotto e
   security diff-scoped;
6. con esito `APPROVED`, pubblicare PR, verificare CI exact-SHA, fondere
   normalmente e osservare la CI `main`.

### Rischi e mitigazioni

- valore esterno assente: output `MISSING` o `UNVERIFIABLE_EXTERNAL`, nessun secret;
- documentazione divergente dal runtime: riferimenti a file e gate già validati;
- checker che muta stato: sole letture locali e test di stato Git prima/dopo;
- CI o cleanup non osservabile: singolo retry e classificazione esterna prevista;
- regressione fuori scope: nessun codice applicativo o release artifact modificato.

## Execution — `CODEX_EXECUTOR`

- creati checklist di activation, launch runbook A-L e rollback runbook senza
  valori production, secret o owner inventati;
- implementati checker read-only `technical`/`activation` e 13 test di contratto;
- technical mode: exit 0, 72 righe `READY`, 59 requisiti esterni
  `UNVERIFIABLE_EXTERNAL`, risultato `READY`;
- activation mode: exit 1 atteso, 71 righe `READY`, 59 requisiti esterni `MISSING`,
  risultato fail-closed;
- verificati i sette kill switch/fallback esistenti; nessun flag o codice runtime
  aggiunto;
- `git diff --check`, sintassi shell, test readiness, governance state, action pins
  e security client 690 file sono `PASS`;
- la prima suite governance ha rilevato fixture non aggiornata per TASK-041; il primo
  rerun ha rilevato un hardcode TASK-040 residuo; il secondo e ultimo rerun mirato ha
  concluso 101/101 `PASS` dopo il fix minimo della fixture;
- `scripts/check.sh`, AAB, archive iOS e performance non eseguiti perché il diff non
  modifica codice applicativo o release configuration;
- candidate tecnico: `92323f309ac39d4ea9565ef841c8a358a2b257a7`;
- production, Admin, Supabase, provider, billing e store invariati.

`CODEX_EXECUTION_COMPLETE_TO_REVIEW`.

## Review — `CODEX_REVIEWER`

- exact HEAD `ec735a0efdae128c8b1f7e82ca578358c1a56476`, range da
  `fdb1fa7962fa7a8eea7ecb0505adc812571fb1db`;
- coverage: 12 file cambiati e supporting code dei sette fallback;
- gate reviewer: diff, sintassi, readiness 13/13, technical, activation, governance
  state, action pins e security 695 file eseguiti; la sessione governance 101/101
  non ha restituito l'exit finale dopo yield e non è stata dichiarata PASS reviewer;
- security formale `FORMAL_EXTERNAL_SCANNER_NOT_AVAILABLE` per Python 3.9 senza
  `tomllib/tomli`; review manuale diff-scoped, nessun report sealed;
- `F-041-R01` P2: `NOT_APPLICABLE` può essere assegnato a un singolo requisito
  optional mentre gli altri prerequisiti della capability sono `READY`, senza
  attestare capability OFF e fallback verificato;
- fix richiesto: stato N/A atomico per capability, due attestazioni redatte
  `disabled`/`fallback verified` e regressioni per mix, gruppo N/A e required N/A;
- conteggio: P0 0, P1 0, P2 1, P3 0;
- esito: `CHANGES_REQUIRED`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Fix — `CODEX_FIXER`

- chiuso `F-041-R01`: `NOT_APPLICABLE` è ora atomico per capability opzionale;
- un gruppo N/A richiede tutti i suoi requisiti `not_applicable` e le attestazioni
  redatte `disabled=true` e `fallback verified=true`;
- i mix `READY`/N/A, l'attestazione incompleta e il N/A su requisito obbligatorio
  falliscono chiuso;
- aggiunte regressioni per N/A isolato, gruppo Maps N/A completo, fallback mancante e
  requisito obbligatorio N/A; readiness test 15/15 `PASS`;
- gate finali: technical exit 0 (72 READY, 59 UNVERIFIABLE_EXTERNAL), activation exit
  1 atteso (71 READY, 59 requisiti MISSING), governance 101/101, action pins e security
  client 695 file `PASS`;
- exact technical SHA: `87e00953e3eff81078f305cadbaa176e57ff103e`;
- nessuna modifica a codice applicativo, release configuration o production.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

## Chiusura

Da compilare dopo review, CI e merge reali.

`CODEX_PLANNING_APPROVED_TO_EXECUTION`.
