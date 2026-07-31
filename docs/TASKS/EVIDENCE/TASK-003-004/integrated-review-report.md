# TASK-003/TASK-004 — Review integrata

## Esito

- **Baseline**: merge TASK-002
  `46686ace3b4670f207147f12110d8133ced01e8e`
- **Revisione verificata**:
  `c8258f83c55b2b1a85f2e590d60f64fcfa1d5f0e`
- **Modalità**: sessioni read-only indipendenti dagli executor/fixer individuali
- **Verdetto**: `CHANGES_REQUIRED`
- **Handoff**: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`
- **Finding**: 0 P0, 0 P1, 4 P2 e 4 P3
- **PR/merge**: vietati fino a Fix, re-review e CI terminale

Il target include il closeout TASK-004 e la sua attestazione CI. Il delta
`0fc8d8b…c8258f8` modifica soltanto cinque file documentali/evidence TASK-004 e non
altera i finding.

## Finding bloccanti

### T003-INT-ARCH-001 — P2 — OPEN — Business decision owner non univoco

- **Posizioni**:
  `docs/ARCHITECTURE/STOREFRONT-INTEGRATION-CONTRACT.md:13`,
  `docs/DECISIONS/ADR-010-storefront-contract-ownership.md:31`,
  `docs/ARCHITECTURE/CROSS-REPO-OWNERSHIP.md:20,49-54`.
- **Descrizione**: alcuni documenti assegnano la decisione commerciale ad Admin
  Console/Admin server, mentre la matrice assegna ruoli business distinti. Ruolo
  accountable, control plane e writer/enforcer risultano conflati.
- **Impatto**: ownership non priva di ambiguità; falliscono CA-05/CA-06/CA-11 e
  T-04/T-05/T-06.
- **Correzione richiesta**: separare ruolo business autorizzato, Admin Console come
  control plane e Admin server come writer/enforcer.
- **Regressione richiesta**: validator cross-documento della tassonomia ownership.

### T003-INT-ARCH-002 — P2 — OPEN — Quality gate incompatibile con la matrice

- **Posizioni**: `docs/QUALITY-GATES.md:49-50` e
  `docs/ARCHITECTURE/CROSS-REPO-OWNERSHIP.md:47-55`.
- **Descrizione**: il gate richiede letteralmente «un solo» writer, projector,
  consumer, contract owner e change owner; la matrice contiene correttamente set
  autorizzati, split Client-logical/Admin-machine-readable e change owner coordinati.
- **Impatto**: CA-30 è un falso `PASS`; il gate non è soddisfacibile secondo la sua
  formulazione.
- **Correzione richiesta**: distinguere accountability univoca da set autorizzati e
  split per layer.
- **Regressione richiesta**: validator di completezza/non ambiguità senza cardinalità
  uno sui ruoli cooperativi.

`T003-REREV-001` P3 è assorbito ed elevato da questo finding.

### T003-INT-ARCH-003 — P2 — Scope data-backed prematuro per TASK-012

- **Posizioni**: `docs/ARCHITECTURE/SYSTEM-CONTEXT.md:124`,
  `docs/ARCHITECTURE/MOBILE-ARCHITECTURE.md:157`,
  `docs/MASTER-PLAN.md:62-64` e
  `docs/DECISIONS/ADR-009-parallel-catalog-authentication-workstreams.md:45-49`.
- **Descrizione**: TASK-012 è descritto come «shell cliente data-backed», mentre il
  workstream autenticazione deve restare data-safe e senza catalogo reale. Le prime UI
  commerciali data-backed appartengono a TASK-013/TASK-014 dopo TASK-010.
- **Impatto**: scope creep catalogo nel workstream auth; falliscono CA-24/CA-27 e
  T-13/T-15.
- **Correzione richiesta**: assegnare a TASK-012 shell guest/data-safe, baseline
  accessibile e stati readiness; rendere esplicito il confine in ADR-009.
- **Regressione richiesta**: scan delle associazioni TASK-012/data-backed contro Master
  e ADR.

### T003-INT-ARCH-004 — P2 — Topologia ADR-009 divergente dal Master

- **Posizioni**:
  `docs/DECISIONS/ADR-009-parallel-catalog-authentication-workstreams.md:24-26` e
  `docs/MASTER-PLAN.md:55-60,70-72`.
- **Descrizione**: ADR-009 mostra TASK-007/TASK-008/TASK-009 e TASK-021/TASK-022 come
  peer; il Master impone invece
  `TASK-005 -> TASK-006 -> TASK-007 -> {TASK-008,TASK-009} -> TASK-010` e
  `TASK-011 -> TASK-012 -> TASK-020 -> TASK-021 -> TASK-022`.
- **Impatto**: l'ADR che governa i workstream suggerisce sequenze di attivazione non
  valide.
- **Correzione richiesta**: allineare entrambe le catene.
- **Regressione richiesta**: confronto automatico dell'edge set ADR/Master.

## Finding non bloccanti

### T003-INT-ARCH-005 — P3 — OPEN — Flusso fiscale ambiguo nel diagramma

`docs/ARCHITECTURE/SYSTEM-CONTEXT.md:42-46` fa confluire stock e vendita fiscale nel
projector Storefront. I testi normativi mantengono correttamente vendita fiscale e
ordine cliente separati. Separare graficamente projector catalogo/disponibilità e
flusso operativo ordine-POS.

### T003004-INT-GOV-002 — P3 — OPEN — Stato CI TASK-002 obsoleto

`docs/TASKS/TASK-002-product-scope-branding-design-system.md:360` riporta
`NOT_RUN`, mentre evidence e righe successive attestano run `30577156105` `PASS` e
PR #2 merged. Il finding è fuori dal perimetro TASK-003/TASK-004 e non blocca il batch.

### T003-REREV-002 — P3 — OPEN — Locator `versionId` incompleto

Il finding storico resta aperto in
`docs/TASKS/EVIDENCE/TASK-003/re-review-report.md`.

### T004-REREV-001 — P3 — OPEN — Conteggio suite obsoleto

Il finding storico `70/70` contro `72/72` resta aperto in
`docs/TASKS/EVIDENCE/TASK-004/re-review-report.md`.

## Verifiche autonome

| Gate | Esito | Evidenza |
|---|---|---|
| Merge base | PASS | `origin/main` a `46686ace…` |
| Governance/action pin/shell/diff | PASS | comandi reali, exit 0 |
| Test config/bootstrap | PASS | 29/29 |
| Suite completa/analyze | PASS | 72/72; zero issue |
| DAG Master | PASS | 42 task, zero cicli, TASK-005–TASK-042 `TODO` |
| Config staging locale | PASS | presente, ignorata, non tracciata |
| Security manuale | PASS | zero URL Supabase reali, JWT, private key, project ref completo o artifact |
| Screenshot | PASS | byte/dimensioni/SHA-256 coerenti, nessun dato sensibile |
| CI closeout TASK-004 | PASS | `30592502472` su `0fc8d8b…`, 3/3 job, tutti gli step, annotation 0/0/0 |
| Security app-backed | BLOCKED | setup scaduto; non contato come `PASS` |

## Handoff

- **Esito**: `CHANGES_REQUIRED`
- **P0/P1 aperti**: 0
- **P2 aperti**: 4
- **P3 aperti**: 4
- **Fix autorizzato**: i quattro P2, con regressioni; i P3 restano non bloccanti
- **Re-review**: obbligatoria su un nuovo SHA
- **Indicatore**: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`
