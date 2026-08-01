# TASK-007 — Admin Console: pubblicazione e visibilità Storefront

## Informazioni generali

- **Task ID**: TASK-007
- **Titolo**: Admin Console: pubblicazione e gestione visibilità prodotti
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-01
- **Ultimo aggiornamento**: 2026-08-01
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-007/`
- **Handoff**: CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW

## Dipendenze

- **Dipende da**: TASK-005, TASK-006, TASK-010
- **Sblocca**: TASK-008, TASK-009, TASK-029

## Scope

- creare `/shop/storefront` con sezioni Catalogo, Categorie pubbliche, Promozioni,
  Immagini pubbliche, Anteprima, Impostazioni e Audit;
- introdurre permessi Storefront specifici nel RBAC esistente;
- implementare lista pubblicazioni con ricerca, filtri, ordinamento, selezione e azioni
  bulk publish/pause;
- implementare editor prodotto per dati pubblici, fulfillment, featured, sort rank e
  stato, con validazione server-side;
- usare esclusivamente authoring/projection/API Storefront già validate;
- aggiungere audit before/after e anteprima basata sul contratto pubblico;
- coprire unit/integration/route/RBAC/E2E e staging preview.

## Non incluso

- motore promozioni completo TASK-008;
- pipeline varianti e bucket pubblico TASK-009;
- ordini Admin TASK-029;
- modifiche production.

## Criteri di accettazione

| CA | Descrizione |
|---|---|
| CA-01 | Route e navigazione Storefront coerenti con l'Admin esistente |
| CA-02 | RBAC granulare, nessun generico `admin=true` |
| CA-03 | Lista/filtri/bulk operano shop-scoped e fail-closed |
| CA-04 | Editor valida nome, categoria, prezzo, immagine e stato server-side |
| CA-05 | Publish/pause aggiornano projection/versione in modo idempotente |
| CA-06 | Anteprima usa il contratto pubblico v1 |
| CA-07 | Audit registra actor/shop/publication/before-after senza secret |
| CA-08 | Ruolo non autorizzato riceve deny verificato |
| CA-09 | Gate Admin e staging E2E obbligatori sono PASS |

## Test case

| Test | Criteri | Procedura |
|---|---|---|
| T-01 | CA-01, CA-02 | route/navigation e matrice permessi |
| T-02 | CA-03, CA-05 | publish singolo/bulk e pause con projection check |
| T-03 | CA-04 | validazioni client e server, input malevoli |
| T-04 | CA-06 | preview e API pubblica producono lo stesso DTO |
| T-05 | CA-07 | audit before/after e bulk operation |
| T-06 | CA-08 | accesso negato a ruolo non autorizzato |
| T-07 | CA-09 | lint/typecheck/unit/integration/build/Playwright/staging |

## Planning — `CODEX_PLANNER`

### Approccio autorizzato

1. censire route, server actions, RBAC e componenti catalogo esistenti;
2. estendere permessi e navigation senza introdurre un secondo auth model;
3. implementare query/mutazioni server-side shop-scoped;
4. costruire lista/editor/bulk/preview/audit riusando design system corrente;
5. aggiungere regression test e E2E staging;
6. validare checkpoint TASK-007 e attivare TASK-008 solo se verde.

### Rischi

- escalation RBAC: permessi espliciti e negative test;
- divergenza preview: unico contratto pubblico;
- publish parziale: mutazioni transazionali/idempotenti;
- scope creep verso promozioni/immagini: interfacce minime, implementazione nei task
  dedicati.

### Handoff

`CODEX_PLANNING_APPROVED_TO_EXECUTION` — autorizzazione USER_APPROVER nel prompt del
release train; production resta fuori scope.

## Execution — `CODEX_EXECUTOR`

### Modifiche completate

- route `/shop/storefront` con Catalogo, Categorie, Promozioni, Immagini, Anteprima,
  Impostazioni e Audit;
- otto permessi RBAC Storefront espliciti, propagati alla matrice canonica staff;
- read model, server action e RPC amministrative shop-scoped per publish/pause/bulk;
- editor con revalidation server-side, projection/versioning transazionale e audit
  before/after;
- anteprima alimentata dallo stesso contratto pubblico v1;
- test foundation, pgTAP, Playwright locale e acceptance staging protetta.

### Gate eseguiti

- revision set Admin:
  `25f858931bf0ffe09213186a6b8b124df0311c97`, PR `#67` draft;
- replay locale: 105 migration, `PASS`;
- pgTAP completo: 22 file / 1.449 test, `PASS` in 45 s; TASK-007 21/21;
- lint, typecheck, security scan, audit dipendenze e build: `PASS`;
- E2E locale publish -> projection pubblica -> audit -> pause: 1/1 `PASS`;
- CI Admin `30723885377`: `PASS`; Cloudflare PR build `30723885380`: `PASS`;
- staging migration apply/postverify `30723486727`: `PASS`, schema
  `20260802001000`, ledger 105 migration;
- Cloudflare staging deploy/smoke `30723988967`: `PASS` sullo SHA esatto;
- acceptance staging autenticata `30724135568`: 1/1 `PASS` in 1m19s, con cleanup;
- production write: `NOT_RUN`; production invariata.

### Matrici

CA-01..CA-09 e T-01..T-07: `PASS`. Evidence sintetica:
`docs/TASKS/EVIDENCE/TASK-007/README.md`.

### Handoff

`CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`. Nessuna review formale è stata
eseguita e TASK-007 non è `DONE`.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.
