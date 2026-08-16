# TASK-035 — Observability, crash reporting e analytics privacy-safe

## Informazioni generali

- **Task ID**: TASK-035
- **Titolo**: Observability, crash reporting e analytics privacy-safe
- **File task**: `docs/TASKS/TASK-035-observability-crash-analytics.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-16
- **Ultimo aggiornamento**: 2026-08-16
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-035/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

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

In corso.

### File controllati

In corso.

### Piano minimo

Inventario, implementazione bounded, test privacy negativi, integrazione mirata,
documentazione e gate canonici.

### Modifiche fatte

Non ancora.

### Check eseguiti

Non ancora.

### Matrice CA -> evidence

Non ancora.

### Matrice T-NN -> risultato

Non ancora.

### Rischi rimasti

Non ancora classificati.

### Handoff a Review

- **Prossima fase**: REVIEW
- **Prossimo ruolo**: CODEX_REVIEWER
- **Handoff**: CODEX_EXECUTION_COMPLETE_TO_REVIEW

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

Non ancora eseguita.

## Fix — `CODEX_FIXER`

Non applicabile finché non esiste un finding approvato.

## Chiusura

- **Conferma utente**: ricevuta e condizionata a review/gate reali
- **Merge autorizzato da USER_APPROVER**: sì, dopo review `APPROVED` e CI exact-SHA verde
- **Follow-up candidate**: TASK-036, soltanto dopo closeout TASK-035
- **Riepilogo finale**: non ancora
- **Data completamento**: non ancora
