# TASK-037 — Performance, immagini, cache e load testing

## Informazioni generali

- **Task ID**: TASK-037
- **Titolo**: Performance, immagini, cache e load testing
- **File task**: `docs/TASKS/TASK-037-performance-images-cache-load.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-17
- **Ultimo aggiornamento**: 2026-08-17
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-037/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Dipendenze

- **Dipende da**: TASK-009, TASK-017, TASK-019, TASK-027, TASK-034, TASK-036
- **Sblocca**: TASK-039, TASK-040
- **Writer iniziale**: Client; Admin/Supabase soltanto davanti a una regressione
  query/index o a uno smoke staging realmente necessario

## Scope

- congelare budget misurabili per launch, first meaningful content, catalogo,
  dettaglio, cart, checkout, ordini, tracking, immagini, memoria, cache e rete;
- misurare prima di ottimizzare su dataset small, medium, 25k/extreme sintetico e
  staging realistico quando disponibile;
- profilare rebuild/invalidation Riverpod, virtualizzazione liste, decode/cache
  immagini, query Drift/Postgres, parsing JSON, main isolate, realtime/polling,
  retention, subscription e route disposal;
- correggere soltanto regressioni dimostrate con confronto before/after, test di
  non regressione e soak/repeat deterministici;
- provare che un location update non ricostruisca l'intero order detail;
- mantenere limiti server canonici, contratti commerce, privacy e production
  invariati.

## Non incluso

- refactor cosmetici o dipendenze nuove senza necessità misurata;
- aumento arbitrario dei limiti server, benchmark basati su wall-clock sleep o
  dati reali cliente;
- dichiarare miglioramenti senza baseline/campioni/ambiente e confronto finale;
- migration o deploy production, acquisti SaaS o attivazioni a pagamento.

## Budget congelati prima della misura

| Superficie | Budget release verificabile |
|---|---|
| Cold launch processo | p95 <= 5 s su emulator/simulator disponibile |
| Warm launch processo | p95 <= 1 s |
| First meaningful Storefront content | p95 <= 3 s su rete staging normale; cache warm <= 1 s |
| Catalog search | backend p95 <= 750 ms; trasformazione/cache locale p95 <= 15 ms |
| Filter/sort locale | p95 <= 100 ms |
| Page append | p95 <= 500 ms e zero duplicati/salti |
| Product detail | backend p95 <= 400 ms; navigazione/render locale p95 <= 250 ms |
| Cart open | cache warm p95 <= 250 ms |
| Checkout navigation | p95 <= 400 ms, esclusa latenza provider esterno |
| Order list/detail | cache warm p95 <= 300 ms; backend p95 <= 750 ms |
| Tracking update | pubblicazione UI p95 <= 100 ms; nessun rebuild dell'intero detail |
| Image decode | thumbnail target-sized p95 <= 32 ms, zero full-size decode non necessario |
| Frame/UI | p95 build+raster <= 32 ms; zero frame >700 ms nel percorso campionato |
| Memoria | PSS <= 200 MB e RSS <= 300 MB sul percorso release misurabile |
| Cache database | 25k prodotti: open <=1 s, write <=2 s, query catalog/search p95 <=15 ms |
| Network | una request per azione logica, salvo retry/fallback classificati e bounded |

## Criteri di accettazione

| CA | Descrizione | Tipo |
|---|---|---|
| CA-01 | Ogni budget ha ambiente, campioni, warm-up, p50/p95/p99 e SHA | PERFORMANCE/EVIDENCE |
| CA-02 | Dataset small/medium/25k e ordini sintetici coprono cardinalità e cleanup | UNIT/LOAD |
| CA-03 | Cache/ricerca/paginazione restano bounded, deterministiche e senza leak | UNIT/STRESS |
| CA-04 | Immagini usano sizing/decode/cache bounded e failure placeholder | WIDGET/PROFILE |
| CA-05 | Rebuild/provider invalidation e parsing/main-isolate rispettano il budget | PROFILE |
| CA-06 | Tracking aggiorna la regione necessaria senza rebuildare order detail | WIDGET/PROFILE |
| CA-07 | Realtime/polling/subscription/route disposal superano soak e repeat | STRESS |
| CA-08 | Ogni fix misurato ha evidence before/after e regressione automatica | REVIEW |
| CA-09 | Gate Client/Admin/DB applicabili, review distinta e CI exact-SHA sono verdi | CI/REVIEW |
| CA-10 | Production, contratti canonici e dati reali restano invariati | SECURITY |

## Test case

| Test | Criteri | Procedura attesa |
|---|---|---|
| T-01 | CA-01/02 | Harness ripetibile su small/medium/25k, centinaia categorie e ordini sintetici |
| T-02 | CA-03 | Cold/warm cache, catalog/search/page append concorrente, cancellation e disposal |
| T-03 | CA-04 | URL thumbnail, decode target, cache eviction, slow/error image e memory pressure |
| T-04 | CA-05/06 | Contatori build/provider e frame timing per Home/catalog/detail/order/tracking |
| T-05 | CA-07 | Fake scheduler soak/repeat su realtime, polling, background/foreground e route dispose |
| T-06 | CA-08 | Baseline congelata, fix minimo, stessa misura post-fix e delta documentato |
| T-07 | CA-09/10 | Gate canonici, security diff, review indipendente, PR/main CI e hygiene |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Riutilizzare harness TASK-019 e cache benchmark esistenti | Confronto storico e nessuna dipendenza speculativa | ATTIVA |
| D-02 | Controllable clock/fake scheduler per soak logici | Evita flake e sleep | ATTIVA |
| D-03 | Nessuna ottimizzazione senza finding misurato | Preserva architetture funzionanti | ATTIVA |
| D-04 | Dataset remoto soltanto staging sintetico e con cleanup | Privacy e ripetibilità | ATTIVA |
| D-05 | Il mandato 2026-08-16 autorizza Planning→Execution | ADR-015 | ATTIVA |

## Planning — `CODEX_PLANNER`

### Approccio

1. inventariare harness e metriche TASK-019/TASK-034 e congelare la baseline;
2. misurare dataset small/medium/25k e percorsi commerce/tracking senza modifiche;
3. isolare rebuild, cache, immagini, parsing, query, subscription e leak;
4. correggere soltanto i budget falliti o le regressioni strutturali provate;
5. rieseguire identica misura, repeat/soak e gate canonici;
6. consegnare revision set ed evidence a reviewer read-only distinto.

### Rischi

- rumore emulator/staging: separare metriche deterministic-local da runtime e
  registrare hardware/toolchain/campioni;
- benchmark che misura warm-up: scartare warm-up e riportare distribuzione;
- suite troppo lenta: mantenere stress bounded e ripetibile, senza ridurre copertura;
- ottimizzazione che altera semantica: test commerce/resilience restano gate.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: mandato 2026-08-16 e ADR-015

## Execution — `CODEX_EXECUTOR`

In corso.

## Review — `CODEX_REVIEWER`

Non ancora eseguita.

## Fix — `CODEX_FIXER`

Non applicabile finché la review non produce finding.

## Chiusura

- **Conferma utente**: ricevuta e condizionata a review/gate reali
- **Merge autorizzato**: dopo review `APPROVED` e CI exact-SHA verde
- **Follow-up candidate**: TASK-038
- **Data completamento**: non ancora
