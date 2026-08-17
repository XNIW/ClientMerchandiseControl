# TASK-037 — Performance, immagini, cache e load testing

## Informazioni generali

- **Task ID**: TASK-037
- **Titolo**: Performance, immagini, cache e load testing
- **File task**: `docs/TASKS/TASK-037-performance-images-cache-load.md`
- **Stato**: ACTIVE
- **Fase**: FIX
- **Responsabile**: CODEX_FIXER
- **Data creazione**: 2026-08-17
- **Ultimo aggiornamento**: 2026-08-17
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-037/`
- **Handoff**: CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX

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

### Baseline e finding

- la baseline locale è stata congelata prima della modifica con cinque run sul
  dataset 25k: open 296–479 ms, write 480–510 ms, catalog p95 1.226–1.290 us e
  search p95 3.836–4.592 us;
- `StorefrontVerifiedImageLoader` conservava ogni payload verificato in una
  `Map` process-lifetime senza cap per entry o byte e non deduplicava download
  concorrenti dello stesso digest (`F-037-E01`, P2 performance/reliability);
- l'audit delle altre collection residenti ha confermato cap o teardown già
  presenti per auth callback, notification routes, favorites, probe backend,
  realtime/polling e cache ordini; nessun altro fix speculativo è stato applicato;
- la baseline TASK-019 resta la provenance del journey staging storico; TASK-037
  ha rieseguito backend staging sullo schema corrente e ha preparato un nuovo
  journey profile Android durante una fixture sintetica con cleanup automatico.

### Implementazione

- cache immagini content-addressed trasformata in LRU con doppio limite
  `64 entry / 24 MiB`, copie isolate per consumer, eviction deterministica e
  validazione fail-closed dei limiti;
- single-flight per digest: una sola request concorrente, rimozione dell'in-flight
  su successo o failure e retry successivo consentito;
- regressione widget che prova che uno snapshot location ricostruisce soltanto
  `_DeliveryTrackingSection` e non body/header/items/timeline dell'ordine;
- benchmark ripetibili small/medium/extreme, carrello al cap canonico di 100 righe,
  cache ordini al cap 50 e selector/filter su 500 ordini;
- `build_daemon` aggiornato isolatamente da `4.1.3` ritirata a `4.1.5`; nessun'altra
  dipendenza o constraint è cambiato.

### Risultati deterministici e device

- cinque repeat finali dei quattro benchmark: tutti `PASS`; sul profilo 25k
  open 1 ms, write 513–545 ms, catalog p95 559–714 us e search p95
  4.124–4.603 us;
- cart 100 righe: read p95 0,522–0,682 ms, mutation p95 0,804–0,962 ms;
- order cache 50 righe/17.105 byte: write p95 0,833–1,133 ms e read p95
  1,539–1,647 ms; selector 500 ordini p95 0,154–0,167 ms;
- stress immagini 256 payload e rebuild tracking: repeat valido `10 x 2 = 20/20`;
- Android 15 API 35 profile: cold 5 campioni p50/p95/p99
  1.146/1.359/1.359 ms, warm 100/411/411 ms; PSS 124.473 KB al launch e
  131.292 KB dopo soak gesture, RSS 239.952/252.244 KB;
- iOS Simulator resta coperto dal build/smoke automatico; profile AOT e memoria
  fisica iOS sono `PHYSICAL_VALIDATION_PENDING_DEVICE` perché l'iPhone rilevato è
  offline. Nessun PASS manuale o fisico è inferito.

### Staging, gate e deviazioni

- run Admin `31985297932`, exact SHA `59668348`, dataset 91.200 righe equivalenti:
  catalog p95 50,608 ms, search p95 718,325 ms, detail p95 6,069 ms,
  keyset/FTS osservati e cleanup zero;
- run Admin `31985724356` con fixture committed: cinque journey Android profile
  sul Client SHA `398bd05`, tutti `PASS`; first meaningful Home p95 2.660 ms,
  2.657 frame complessivi, frame p95 per run 21,636–25,157 ms, p99
  33,457–49,255 ms e zero frame >700 ms; cleanup e residue zero confermati;
- reinstallazione dello stesso artifact/config dopo il journey: PSS 170.239 KB e
  RSS 291.160 KB, entro budget ma con margine RSS esplicitamente registrato;
- due tentativi client profile iniziali sono `FAIL` di harness prima della rete
  (`SUPABASE_ANON_KEY` e `ENABLE_GOOGLE_AUTH` non sono i nomi contrattuali) e un
  tentativo durante la transazione non committed è `FAIL` con Home unavailable;
  nessuno è contato come evidence positiva;
- il gate canonico finale sull'exact SHA `dc56102` è `PASS`: 760 test
  non-performance, 70/70 repeat TASK-034, 4 performance, security su 634 file,
  localization/governance/architecture, analyze/format e build Android/iOS
  Simulator;
- production, limiti server, DDL e dati reali non sono stati modificati.

### Handoff a Review

- **Revision set**: `96a9359..dc56102`
- **Prossima fase**: REVIEW
- **Prossimo ruolo**: CODEX_REVIEWER read-only distinto
- **Handoff**: CODEX_EXECUTION_COMPLETE_TO_REVIEW
- **Finding executor aperti**: 0 P0/P1/P2/P3

## Review — `CODEX_REVIEWER`

### Esito indipendente sullo SHA `5866465`

`CHANGES_REQUIRED`, con `0 P0 / 0 P1 / 2 P2 / 1 P3`:

- `F-037-R01` P2: la single-flight non conserva la deadline assoluta baseline;
  timeout header e stream possono sommarsi. Richiesti deadline globale condivisa,
  scheduler controllato, cleanup e retry dopo timeout;
- `F-037-R02` P2: matrici CA/evidence e T/risultato mancanti e budget non misurati
  per page append, checkout navigation, tracking publication, decode immagine e
  request count; CA-05/CA-07 non hanno mapping exact-SHA sufficiente;
- `F-037-R03` P3: oracle LRU non separano cap entry/byte né distinguono FIFO;
  l'assert sul tipo State del rebuild è vacuo e va sostituito con widget/root
  osservabili.

Gate reviewer: analyze, 19/19 mirati, repeat 20/20, performance 12/12,
governance 9/9, security 634 file + fixture 41/41 e 4/4, architecture 7/7,
format/diff, staging exact-SHA e cleanup tutti `PASS`. Production invariata.

## Fix — `CODEX_FIXER`

### Correzioni candidate

- `F-037-R01`: il Future condiviso usa ora una deadline assoluta via
  `AppScheduler`; timeout, cleanup `_inFlight` e retry sono provati senza sleep.
  Soltanto un download concluso entro deadline può popolare la cache;
- `F-037-R02`: aggiunti benchmark con 5 warm-up e 30 campioni per Home cache
  warm, page append, product-detail render, checkout navigation, tracking
  publication e decode 1024→480; ogni harness riporta p50/p95/p99 e request
  count. Aggiunte le matrici CA/T e la classificazione esplicita di ogni budget;
- `F-037-R03`: test distinti provano promozione MRU vs FIFO e limite byte vs
  limite entry; il rebuild test usa State/Element osservabili e tipi Widget, non
  un nome State impossibile nel callback.

Sul candidate tecnico `35fb338`, i 10 benchmark sono `10/10 PASS`; deadline/LRU
`10/10`, suite mirata modificata `64/64`, analyze e diff `PASS`. Il soak
resilience/lifecycle sullo SHA `6974afb` è `20 x 14 = 280/280 PASS`; le sole
modifiche successive aggiungono harness performance e saranno incluse nel gate
finale exact-SHA.

### Matrice CA -> evidence candidate

| CA | Evidence verificata | Stato |
|---|---|---|
| CA-01 | tabella budget completa in evidence, SHA/ambiente/warm-up/campioni/p50/p95/p99 | PASS |
| CA-02 | small 1k, medium 10k, extreme 25k/250 categorie, cart 100, ordini 50/500, staging 91.200 equivalenti | PASS |
| CA-03 | cache 25k, append 36x24, LRU entry/byte, single-flight e 256 immagini | PASS |
| CA-04 | `storefront_verified_image_loader_test.dart`, decode 1024→480 e `cacheWidth` 480/1440 | PASS |
| CA-05 | Home warm, product render, checkout navigation e 2.657 frame staging | PASS |
| CA-06 | State/Element order detail stabili; tracking p95 0,353 ms | PASS |
| CA-07 | Manual scheduler lifecycle + repeat 20x14, timer/subscription a zero | PASS |
| CA-08 | baseline pre-fix, fix LRU/deadline e regressioni sullo stesso harness | PASS |
| CA-09 | `scripts/check.sh` su `6934539` exit 0; re-review distinta da eseguire | PASS — gate locale; review pending |
| CA-10 | diff senza DDL/config production; staging cleanup/residue 0 | PASS |

### Matrice T -> risultato candidate

| Test | Comando/evidence | Stato |
|---|---|---|
| T-01 | `flutter test --tags performance --concurrency=1`; 10 benchmark/dataset | PASS |
| T-02 | catalog controller/cache e race TASK-034 exact-SHA | PASS |
| T-03 | loader 10/10, decode target-sized, LRU stress 256 | PASS |
| T-04 | journey staging + rebuild order detail + tracking publication | PASS |
| T-05 | `CMC_TASK034_REPEAT_COUNT=20 ...`; 280/280 con scheduler manuale | PASS |
| T-06 | baseline/finale documentati; nessuna ottimizzazione senza finding | PASS |
| T-07 | check canonico `6934539` PASS; security diff/re-review/PR/main CI | NOT_RUN — re-review e CI sono il prossimo gate |

### Handoff a Re-review

- **Revision set review**: `5866465..6934539` più il commit documentale di handoff
- **Gate canonico candidate**: `scripts/check.sh` su
  `69345390118bba1df7555b90e2d1afbdca7d03af`, exit 0; security 635 file,
  suite non-performance con coverage, repeat TASK-034 `5 x 14 = 70/70`,
  performance `10/10`, analyze/format/governance/architecture e build Android/iOS
  Simulator verdi
- **Prossima fase**: REVIEW
- **Prossimo ruolo**: CODEX_RE_REVIEWER read-only distinto
- **Handoff**: CODEX_FIX_COMPLETE_TO_RE_REVIEW
- **Finding fixer aperti**: 0 P0/P1/P2/P3; `F-037-R01`–`F-037-R03` candidati chiusi

### Re-review indipendente sullo SHA `6a21285`

`APPROVED`, con `0 P0 / 0 P1 / 0 P2 / 0 P3`:

- `F-037-R01` `CLOSED`: deadline assoluta condivisa, cache entro deadline,
  cleanup single-flight e retry deterministico verificati;
- `F-037-R02` `CLOSED`: matrici CA/T complete e 10 benchmark con warm-up,
  campioni, p50/p95/p99 e request count bounded;
- `F-037-R03` `CLOSED`: oracle MRU/FIFO, cap byte separato e tracking con
  State/Element osservabili verificati.

Gate autonomi reviewer: loader/order 21/21, deadline 1/1, rebuild 1/1,
performance 10/10, repeat lifecycle/race `20 x 14 = 280/280`, analyze,
governance 9/9, architecture 7/7, security 635 file + fixture 41/41 e 4/4,
format/diff e worktree clean tutti `PASS`. Il delta `6934539..6a21285` è soltanto
documentale. Order backend staging resta correttamente `NOT_RUN`, non è un
finding tecnico e non viene promosso a PASS.

- **Esito**: APPROVED
- **Handoff**: CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION
- **Gate successivo**: PR exact-SHA, merge normale e main post-merge CI

### Main post-merge CI — finding `F-037-R04`

PR #15 è stata integrata normalmente con merge `8b20bca` dopo CI PR
`31988449054` 3/3 `PASS`. La main CI exact-SHA `31988842715` ha invece
terminato `FAIL`: i build Android/iOS e le rispettive scansioni bundle sono
`PASS`, ma Quality ha 771 test `PASS` e un benchmark `FAIL`.

`F-037-R04` P2: `.github/workflows/ci.yml` eseguiva tutti i benchmark tagged
`performance` dentro `flutter test --coverage`, in parallelo con l'intera suite.
Sul runner main il p95 search 25k era 15,335 ms contro il budget 15 ms, mentre il
gate canonico locale isola già correttamente i benchmark con
`--tags performance --concurrency=1`. Il risultato dipende quindi dalla contesa
del runner e non misura il budget congelato in modo ripetibile.

Fix candidato: allineare CI al gate canonico con coverage che esclude il tag
performance e uno step performance seriale separato; aggiungere una regressione
governance che impedisca di riunire nuovamente i due carichi. Il budget resta
15 ms e non viene allentato.

## Chiusura

- **Conferma utente**: ricevuta e condizionata a review/gate reali
- **Merge autorizzato**: dopo review `APPROVED` e CI exact-SHA verde
- **Follow-up candidate**: TASK-038
- **Data completamento**: non ancora
