# TASK-035 — Observability, crash reporting e analytics privacy-safe

## Informazioni generali

- **Task ID**: TASK-035
- **Titolo**: Observability, crash reporting e analytics privacy-safe
- **File task**: `docs/TASKS/TASK-035-observability-crash-analytics.md`
- **Stato**: DONE
- **Fase**: REVIEW
- **Responsabile**: USER_APPROVER
- **Data creazione**: 2026-08-16
- **Ultimo aggiornamento**: 2026-08-16
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-035/`
- **Handoff**: USER_APPROVED_DONE

## Dipendenze

- **Dipende da**: TASK-011, TASK-020, TASK-027, TASK-031, TASK-034
- **Sblocca**: TASK-036, TASK-039, TASK-040

## Scope

- definire un port tipizzato unico per log strutturati, analytics, crash reporting,
  breadcrumb e misure performance;
- fornire no-op development/test, logger locale strutturato e adapter production
  configurabili che falliscono chiusi quando non configurati;
- applicare tassonomia errori, correlation/request ID safe, redazione centrale,
  sampling, rate limiting, serialization crash-safe e buffer offline bounded;
- emettere eventi bounded per lifecycle, view, catalogo, carrello, checkout, ordini,
  notifiche, tracking, failure backend e budget performance;
- integrare i boundary Client e Admin pertinenti senza confondere audit operativo con
  analytics e senza aggiungere automaticamente SaaS a pagamento;
- provare negativamente che coordinate, token, OAuth code, payment secret, PII, URL di
  tracking, query raw, push token e contenuto completo del carrello non possano uscire;
- documentare ambiente, consenso, lifecycle e runbook diagnostico.

## Contesto

Il prodotto dispone di error model e boundary remoti, ma non di una pipeline canonica
di observability. Print isolati e log di tool non costituiscono telemetria production.
Il task deve riusare i provider già presenti quando esistono, mantenere development e
test deterministici e lasciare production inattiva in assenza di configurazione
esplicita.

## Non incluso

- acquisto o attivazione automatica di un provider SaaS;
- inserimento di DSN, API key, project ref, service role o altri secret nel repository;
- logging di payload remoti raw, dati cliente o coordinate;
- modifica dei contratti di autorizzazione, audit trail operativo o retention canonici;
- dashboard production o alert live che richiedano account esterni non disponibili.

## File coinvolti

- `lib/core/observability/` e bootstrap/lifecycle Client;
- boundary feature Client strettamente necessari agli eventi bounded;
- test unit/widget/integration e scanner privacy dedicati;
- Admin logging/API correlation soltanto se emerge un gap reale nel writer canonico;
- documentazione diagnostica, configuration matrix, evidence e governance.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Port unico e adapter no-op/local/production configurabile fail-closed | UNIT/STATIC |
| CA-02 | Event catalog bounded copre tutti i flussi richiesti senza payload arbitrari | UNIT/REVIEW |
| CA-03 | Redazione centrale blocca PII, coordinate, token, secret, URL tracking e query raw | NEGATIVE/SECURITY |
| CA-04 | Tassonomia, correlation ID, breadcrumb, sampling e rate limit sono deterministici e bounded | UNIT/STRESS |
| CA-05 | Serialization e buffer offline non possono crashare né crescere senza limite | UNIT/STRESS |
| CA-06 | Consent, lifecycle ed environment separation impediscono export non autorizzato | UNIT/INTEGRATION |
| CA-07 | Client integra lifecycle e outcome commerce/tracking senza regressioni funzionali | UNIT/WIDGET |
| CA-08 | Admin mantiene audit separato da analytics, correlation safe e zero service-role leakage | UNIT/STATIC |
| CA-09 | Runbook diagnostico collega sintomo, evento/categoria e controllo senza dati sensibili | DOCUMENT/REVIEW |
| CA-10 | Gate completi, review indipendente, CI exact-SHA e zero P0/P1/P2 | CI/REVIEW |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01 | UNIT | Verificare no-op, logger locale e production adapter disabilitato/abilitato |
| T-02 | CA-02 | UNIT | Enumerare schema eventi e rifiutare nomi/campi non allowlisted |
| T-03 | CA-03 | NEGATIVE | Iniettare ogni classe PII/secret vietata e cercarla negli export serializzati |
| T-04 | CA-04 | UNIT/STRESS | Usare clock/scheduler controllati per sampling, bucket rate e breadcrumb eviction |
| T-05 | CA-05 | UNIT/STRESS | Provare oggetti non serializzabili, overflow e replay/flush bounded |
| T-06 | CA-06 | UNIT/INTEGRATION | Provare consent off/on/revoke e isolamento development/staging/production |
| T-07 | CA-07 | UNIT/WIDGET | Verificare eventi bounded dei flussi Client senza side effect o dati raw |
| T-08 | CA-08 | UNIT/STATIC | Verificare errori/correlation Admin, audit separato e scanner credenziali |
| T-09 | CA-09 | STATIC | Verificare completezza e sanitizzazione del runbook diagnostico |
| T-10 | CA-10 | CI/REVIEW | Eseguire gate canonici, security diff review, review indipendente e CI exact-SHA |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Nessun SaaS aggiunto prima dell'audit provider/tooling | Evita spesa e lock-in non autorizzati | ATTIVA |
| D-02 | Eventi e attributi sono tipi/allowlist, non mappe arbitrarie dai caller | Riduce leakage accidentale | ATTIVA |
| D-03 | Tutti gli exporter production partono disabilitati e falliscono chiusi | Config mancante non deve abilitare invio | ATTIVA |
| D-04 | Audit operativo e analytics restano pipeline semanticamente separate | L'audit non è soggetto a sampling/consenso analytics | ATTIVA |
| D-05 | Il mandato 2026-08-16 vale come autorizzazione Planning→Execution | ADR-015 consente sequenza autonoma | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Rendere diagnosi, crash e product analytics osservabili con schema bounded e privacy
by construction, senza introdurre una dipendenza esterna o una capability production
implicita.

### Analisi

L'esecuzione parte da un inventario di logger, error taxonomy, config, consent e
provider esistenti nel Client e nell'Admin. Il port centrale deve redigere prima di
buffer/export, non delegare la privacy ai singoli caller. Le integrazioni feature sono
minime e provate sugli outcome, mai sui payload di dominio completi.

### Approccio

1. inventariare tooling e confini già presenti, inclusi package e log raw;
2. definire schema eventi, attributi sicuri, tassonomia e policy consent/environment;
3. implementare port, redactor, limiter, buffer e adapter senza nuove dipendenze se non
   tecnicamente indispensabili;
4. integrare bootstrap/lifecycle e i punti outcome commerce/tracking pertinenti;
5. correggere l'Admin soltanto se l'audit riproduce leakage o assenza di correlation;
6. aggiungere test negativi e stress deterministici, runbook e evidence;
7. eseguire gate completi e consegnare a reviewer distinto.

### Rischi

- regressioni dovute a instrumentation nel path funzionale: mitigare con chiamate
  best-effort che non alterano l'outcome del dominio;
- leakage da stringhe/errori arbitrari: impedire campi liberi e redigere centralmente;
- code/buffer non bounded: limiti espliciti, eviction e test stress;
- provider esterno assente: classificare come config esterna, mantenendo adapter
  production disabilitato e testabile.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: ricevuta nel mandato 2026-08-16 e ADR-015

## Execution — `CODEX_EXECUTOR`

### Obiettivo compreso

Introdurre un boundary unico, typed e fail-closed per diagnostica, analytics e crash,
senza provider SaaS o secret e senza consentire ai caller di allegare payload di
dominio arbitrari.

### File controllati

- Client: bootstrap, router, Auth, Catalog, Cart, Checkout, Orders e Delivery Tracking;
- `lib/core/observability/`: schema eventi, port/adapters, redactor e provider;
- test core e controller, scanner statico privacy e gate canonico;
- Admin: boundary POS correlation/error e audit esistenti, verificati read-only;
- runbook diagnostico ed evidence TASK-035.

### Piano minimo

Inventario, implementazione bounded, test privacy negativi, integrazione mirata,
documentazione, gate canonici e consegna a reviewer distinto.

### Modifiche fatte

- aggiunto `ObservabilityPort` con no-op, logger locale strutturato e adapter production
  configurabile con exporter analytics/crash distinti;
- aggiunti consent `none/diagnostics/analytics`, sampling deterministico, rate limit a
  clock controllato, breadcrumb e buffer in-memory bounded, flush retry e
  serialization crash-safe;
- definito un catalogo di 12 factory tipizzate con soli enum, booleani e bucket;
- centralizzata la redazione di PII, URL, coordinate, UUID, token e secret; crash ed
  errori non esportano messaggio o stack raw ma un fingerprint one-way bounded;
- integrati cold/warm start, screen mapping senza path/ID, notification routing senza
  route token e outcome bounded di Auth/Catalog/Cart/Checkout/Orders/Tracking;
- aggiunto `scripts/check-telemetry-privacy.sh` al gate canonico: logger/exporter
  confinati, nessun `print/debugPrint`, schema senza attributi sensibili;
- documentati provider, ambiente, consenso, tassonomia e runbook “utente segnala X”;
- verificato read-only l'Admin: `serverRequestId`, client ID validato, edge correlation
  hashata, error response strutturati e audit separato; nessuna modifica necessaria.

### Check eseguiti

| Gate | Risultato reale |
|---|---|
| scanner telemetry | `PASS`, 12 eventi allowlisted, zero attributi sensibili |
| test mirati core + commerce | `87/87 PASS` |
| Admin correlation/audit foundation | `14/14 PASS` sul revision set già integrato |
| `scripts/check.sh` | `PASS`, exit `0` |
| suite non-performance con coverage | `652/652 PASS` |
| repeat race TASK-034 preservato | `5 x 14 = 70/70 PASS` |
| benchmark cache 25k | `PASS`, 1 test performance |
| analyze / format / diff | `PASS`, zero issue |
| security scanner | `621` file, `41/41` negative e `4/4` positive |
| build Android debug | `PASS`, APK generato |
| build iOS Simulator debug | `PASS`, `Runner.app` generata |

Warning non bloccanti già noti: 34 package hanno versioni più recenti incompatibili
con i constraint correnti; il plugin Maps iOS segnala futura adozione SPM. Nessun
package è stato aggiunto o aggiornato in TASK-035.

### Matrice CA -> evidence

| CA | Evidence | Esito |
|---|---|---|
| CA-01 | port/adapters + config negative tests | PASS |
| CA-02 | 12 factory tipizzate enumerate dal test e dallo scanner | PASS |
| CA-03 | redactor + payload crash/feature con PII, secret, URL, UUID e coordinate | PASS |
| CA-04 | clock controllato, correlation safe, sampling/rate/breadcrumb bounded | PASS |
| CA-05 | serializer non-crashing e buffer FIFO count/byte bounded con retry | PASS |
| CA-06 | consent none/diagnostics/analytics, lifecycle e default staging/prod no-op | PASS |
| CA-07 | test controller commerce/tracking nel gate 652/652 | PASS |
| CA-08 | Admin source audit + 14 foundation test | PASS |
| CA-09 | `docs/operations/OBSERVABILITY-RUNBOOK.md` | PASS |
| CA-10 | gate tecnici verdi; review e CI exact-SHA | NOT_RUN |

### Matrice T-NN -> risultato

| Test | Risultato |
|---|---|
| T-01 | PASS |
| T-02 | PASS |
| T-03 | PASS |
| T-04 | PASS |
| T-05 | PASS |
| T-06 | PASS |
| T-07 | PASS |
| T-08 | PASS |
| T-09 | PASS |
| T-10 | NOT_RUN: richiede review indipendente e CI PR/main |

### Rischi rimasti

- nessun provider remoto è configurato: staging e production restano correttamente
  no-op e fail-closed, non costituisce bug né claim di monitoraggio live;
- consent dinamico e lifecycle di un futuro SaaS saranno responsabilità del composition
  root che inietterà l'adapter; non esiste buffer persistente da drenare o eliminare;
- nessun finding tecnico P0/P1/P2 noto all'handoff; reviewer indipendente obbligatorio.

### Handoff a Review

- **Prossima fase**: REVIEW
- **Prossimo ruolo**: CODEX_REVIEWER
- **Handoff**: CODEX_EXECUTION_COMPLETE_TO_REVIEW

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

### Esito review indipendente

- revision set `08221a6..8201acd`, worktree pulito e nessuna dipendenza nuova;
- esito `CHANGES_REQUIRED`: 0 P0, 2 P1, 2 P2 e 1 P3;
- `F-035-R01` P1: emissioni observability sincrone possono interrompere un checkout
  dopo la creazione ordine o leggere Riverpod dopo dispose;
- `F-035-R02` P1: il crash boundary restituisce `true` senza previous handler e
  sopprime il fallback root-isolate, anche con port no-op;
- `F-035-R03` P2: rate limiter e coda condivisi fanno starvation/blocco del crash,
  l'admission non è bounded e la config non ha cap superiori;
- `F-035-R04` P2: secret key JSON quotate non sono redatte e la truncation finale può
  produrre JSON invalido;
- `F-035-R05` P3: scanner rieseguito sul revision set conta 621 file, non 611;
- gate autonomi esistenti verdi, ma CA-01/03/04/05/07/10 restano `FAIL` fino al Fix.

Handoff: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Esito re-review Fix 1

- revision set `08221a6..46e1a87`, worktree pulito;
- `F-035-R01`, `R02`, `R03` e `R05` chiusi;
- `F-035-R04` riaperto P2: redactor e scanner non coprono password/passphrase,
  authorization, cookie, private key, DSN, secret e credential;
- gate autonomi: test mirati `122/122`, repeat core `340/340`, repeat commerce
  `40/40`, analyze, format, security, governance e architecture verdi;
- severità residua: 0 P0, 0 P1, 1 P2, 0 P3.

Handoff: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Fix — `CODEX_FIXER`

### Correzioni

- `F-035-R01`: tutte le emissioni usano helper best-effort/no-throw; il helper da
  Riverpod assorbe anche il `Ref` già disposed. Regressioni provano ordine già creato
  con port throwing e add-to-cart completato dopo dispose;
- `F-035-R02`: il crash boundary isola il reporter, delega il previous handler e
  restituisce `false` quando il fallback embedder deve ancora gestire l'errore;
- `F-035-R03`: limiter, coda e timeout analytics/crash sono separati; admission,
  buffer, breadcrumb, rate e timeout hanno cap massimi fail-closed. Exporter sospeso
  usa scheduler controllato e non blocca il crash reporter;
- `F-035-R04`: redazione ricorsiva key-aware copre token, OAuth/client/payment secret,
  push/API/service role e coordinate; la truncation è strutturale e sempre JSON valido;
- `F-035-R05`: evidence scanner corretta a 621 file. Il denylist statico copre alias
  snake/camel e fallisce esplicitamente su errore `rg`.

### Verifica Fix

| Gate | Esito |
|---|---|
| test core + controller instrumentati | `122/122 PASS` |
| repeat core observability | `20 x 17 = 340/340 PASS` |
| repeat regressioni commerce | `20 x 2 = 40/40 PASS` |
| scanner telemetry / tracked source | `PASS`, 12 eventi / 621 file |
| security diff pre-fix | 15/15 file, zero finding security reportabili/deferred |
| primo gate canonico | `FAIL` governance prima della suite; README riallineato |
| `scripts/check.sh` sullo SHA `00455df` | `PASS`, exit `0` |
| suite non-performance coverage | `659/659 PASS` |
| repeat TASK-034 | `5 x 14 = 70/70 PASS` |
| benchmark cache 25k | `PASS`, 1 test performance |
| Android debug / iOS Simulator debug | `PASS / PASS` |

Warning invariati: 34 package hanno versioni più recenti incompatibili; Maps iOS
segnala futura adozione SPM. Nessuna dipendenza aggiunta.

Handoff: `CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Fix 2 — `F-035-R04`

- classificatore key-aware esteso con match exact/suffix bounded per password,
  passphrase, authorization, cookie, private key, DSN, secret e credential;
- regex testuale coerente per assegnazioni raw e scanner statico esteso agli alias
  snake/camel;
- fixture inline dello scanner prova 13 alias a ogni esecuzione senza scrivere secret;
- due regressioni negative decodificano il JSON, cercano ogni valore originario e
  provano anche il redactor testuale.

### Verifica Fix 2

| Gate | Esito |
|---|---|
| serializer/redactor | `16/16 PASS` |
| repeat serializer/redactor | `20 x 16 = 320/320 PASS` |
| scanner alias inline / telemetry | `13/13`, 12 eventi, `PASS` |
| `scripts/check.sh` sullo SHA `5486561` | `PASS`, exit `0` |
| suite non-performance coverage | `661/661 PASS` |
| repeat TASK-034 | `5 x 14 = 70/70 PASS` |
| benchmark cache 25k | `PASS`, open 469 ms, write 479 ms |
| Android debug / iOS Simulator debug | `PASS / PASS` |

Handoff: `CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Esito re-review Fix 2

- `F-035-R01`–`R05` chiusi; `F-035-R04` verificato con probe alias/JSON/scanner;
- zero finding P0/P1/P2 e nessun finding security reportabile o deferred;
- `F-035-R06` P3: evidence Fix 2 riportava 17 test e 340 repeat, mentre il
  conteggio reale è 16 test e `20 x 16 = 320`;
- gate autonomi: 16/16, repeat 320/320, scanner, analyze, governance 9/9,
  architecture 7/7, format e diff tutti verdi.

Handoff: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 3 — `F-035-R06`

- corretti esclusivamente i quattro claim Fix 2 da 17/340 a 16/320;
- nessun codice, test, scanner o boundary runtime modificato;
- governance `9/9` e diff check verdi sul Fix documentale.

Handoff: `CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 3 indipendente

- revision set `0197ffd..02968ce`, delta esclusivamente documentale;
- `F-035-R06` chiuso: Fix 2 `16/16` e `20 x 16 = 320/320`, conteggi Fix 1
  `17/17` e `20 x 17 = 340/340` preservati;
- governance state e release train `9/9`, diff check e worktree pulito `PASS`;
- `F-035-R01`–`R06` chiusi, zero finding P0/P1/P2/P3;
- esito `APPROVED`.

Handoff: `CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION`.

## Chiusura

- **Conferma utente**: ricevuta e condizionata a review/gate reali
- **Merge autorizzato da USER_APPROVER**: sì, dopo review `APPROVED` e CI exact-SHA verde
- **Follow-up candidate**: TASK-036, soltanto dopo closeout TASK-035
- **Riepilogo finale**: PR #13 merged normalmente come `ddb8cc8`; CI PR
  `31978060753` e CI `main` `31978389972` 3/3 verdi sui rispettivi exact SHA,
  tutti gli step applicabili `success`, zero annotation; branch remoto e locale
  eliminati. `F-035-R01`–`R06` chiusi, zero P0/P1/P2/P3.
- **Data completamento**: 2026-08-16
