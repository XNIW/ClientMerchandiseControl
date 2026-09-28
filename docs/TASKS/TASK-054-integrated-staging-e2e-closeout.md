# TASK-054 — Integrated staging E2E and closeout

- **Release train**: `CLIENT_COMMERCE_JOURNEY_COMPLETION`
- **Stato**: BLOCKED
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Evidence directory**: docs/TASKS/EVIDENCE/TASK-054/
- **Dipende da**: TASK-050–053 e merge Admin/Client
- **Planning**: usa esclusivamente architecture/file map di TASK-050

## Scope

Applicare solo allo staging autorizzato il dataset sintetico e completare E2E-01…25,
review integrata diff-scoped, ancestry/CI/hygiene e closeout. Nessuna activation,
migration production, store upload, credential/device discovery o modifica dei
repository read-only.

## Gate

E2E reali con `PASS/FAIL/NOT_RUN/BLOCKED`, P0/P1/P2 zero, CI exact-SHA e main,
cleanup fixture/worktree/branch e stato finale progetto `IDLE`.

## Review integrata storica — closeout 2026-08-23

- Esito: `APPROVED`; P0 0, P1 0, P2 0, P3 1 non bloccante nel typegen
  schema-wide Admin. I sette RPC Admin consumati a runtime sono tipizzati.
- Admin main: `ebeeb057eb454e164f8f595e4be97e4fcd573b78`, CI verde.
- Client main implementativo:
  `7b16aa81d44b7425727dc774d5842ccd277883e3`, CI run `32633356160` verde
  5/5.
- Production, store, payment reale, refund reale e push reale: `NOT_RUN` per scope.

## Staging E2E-01…25

La migration non è stata applicata a `jpgoimipbothfgkokyvm`: i due tentativi
provider/CLI bounded non hanno concluso e il limite di retry è esaurito. Di
conseguenza gli E2E live dipendenti restano tutti `BLOCKED`; le suite locali e i
contract test non vengono presentati come sostituti di staging.

| E2E | Stato live | Motivo |
|---|---|---|
| E2E-01 | BLOCKED | migration staging non applicata |
| E2E-02 | BLOCKED | migration staging non applicata |
| E2E-03 | BLOCKED | migration staging non applicata |
| E2E-04 | BLOCKED | migration staging non applicata |
| E2E-05 | BLOCKED | migration staging non applicata |
| E2E-06 | BLOCKED | migration staging non applicata |
| E2E-07 | BLOCKED | migration staging non applicata |
| E2E-08 | BLOCKED | migration staging non applicata |
| E2E-09 | BLOCKED | migration staging non applicata |
| E2E-10 | BLOCKED | migration staging non applicata |
| E2E-11 | BLOCKED | migration staging non applicata |
| E2E-12 | BLOCKED | migration staging non applicata |
| E2E-13 | BLOCKED | migration staging non applicata |
| E2E-14 | BLOCKED | migration staging non applicata |
| E2E-15 | BLOCKED | migration staging non applicata |
| E2E-16 | BLOCKED | migration staging non applicata |
| E2E-17 | BLOCKED | migration staging non applicata |
| E2E-18 | BLOCKED | migration staging non applicata |
| E2E-19 | BLOCKED | migration staging non applicata |
| E2E-20 | BLOCKED | migration staging non applicata |
| E2E-21 | BLOCKED | migration staging non applicata |
| E2E-22 | BLOCKED | migration staging non applicata |
| E2E-23 | BLOCKED | migration staging non applicata |
| E2E-24 | BLOCKED | migration staging non applicata |
| E2E-25 | BLOCKED | migration staging non applicata |

## Classificazione storica del closeout

`CLIENT_COMMERCE_JOURNEY_TECHNICALLY_COMPLETE`

`STAGING_PARTIAL_EXTERNAL`

`PROJECT_IDLE`


## Emendamento utente — 2026-09-28

Il nuovo prompt riapre la verifica operativa e autorizza analisi, implementazione,
test locali, review e fix in continuità nel perimetro di sviluppo. Non riusa come
mandato le autorizzazioni staging/merge del train chiuso. Nessuna modifica ai task
futuri o conversione dei vecchi VALIDATED_PENDING_INTEGRATED_REVIEW in DONE.
Admin ha TASK-159 concorrente: il checkout corrente resta in sola lettura; eventuali
fix dimostrati richiedono un candidato isolato e review coordinata.

## Planning audit approvato dal mandato corrente

Obiettivo: ricostruire i percorsi reali e correggere i difetti dimostrati, mantenendo
separati codice, database locale, staging, dispositivi, distribuzione e production.

1. Baseline Git/CI/PR e inventario UI/controller/repository/backend per tutte le aree.
2. Manifest RPC completo, firme/parametri/payload e migration reconciliation readonly;
   gate ripetibile di compatibilità integrato e preflight distribuzione fail-closed.
3. Validazione SQL isolata delle migration canoniche, dipendenze e recovery; niente
   reset/apply sul database condiviso e niente migrazioni duplicate.
4. Riproduzione e correzione dei difetti Client, OAuth/provider solo entro configurazioni
   validate, fallback manuale e server authority conservati.
5. Gate canonici, benchmark esistenti, build unsigned e smoke locale quando possibile.
6. Review distinta e re-review; E2E originali preservati e prerequisiti esterni precisi.

Non incluso: nuovi provider, wallet/loyalty/chat, production, billing, DNS/OAuth dashboard,
pagamenti/rimborsi reali, store upload, merge, aggiornamenti massivi o inventario privato.
Rischi: deriva schema, staging condiviso e callback/provider non configurati. Mitigazioni:
readonly metadata, database dedicato, failure chiusa, fixture sintetiche e nessun secret.

| CA | Criterio | Test |
|---|---|---|
| CA-01 | Inventario completo e baseline verificata | T-01 lettura Git/CI e percorsi |
| CA-02 | Compatibilità RPC e migrazioni verificabile, blocco su drift | T-02 contract gate positivo/negativo e snapshot readonly |
| CA-03 | SQL canonico riproducibile isolato e piano apply/recovery | T-03 pgTAP locale e schema/grants/RLS |
| CA-04 | Difetti dimostrati corretti senza indebolire confini | T-04 regressioni unit/widget, auth e account switch |
| CA-05 | Qualità/build/performance con evidence della revisione | T-05 check.sh e benchmark canonici |
| CA-06 | E2E originali e requisiti esterni classificati onestamente | T-06 matrice e review distinta |

Handoff planning: CODEX_PLANNING_APPROVED_TO_EXECUTION, già autorizzato dal prompt.

## Execution audit — 2026-09-28

Audit e fix locali eseguiti; evidence strutturata nel
[README](EVIDENCE/TASK-054/README.md). Staging32/55 RPC,23assenti e due migration
canoniche mancanti. Validazione SQL isolata1034/1034; regressioni dimostrate
corrette in delivery context, inbox e assistenza. Gate source/artifact backend
aggiunto a CI, check integrato e preflight upload.

Sul candidato runtime6353c9b:843 test PASS e2 golden FAIL,39 focused PASS,
70 race e10 benchmark PASS. I due golden falliscono anche a baseline. Smoke iOS
diagnostico PASS con override locale15.0; build canonica Xcode 27 FAIL su target14.0
e Android locale BLOCKED da download Gradle. CI separata nella PR draft27. OAuth/provider indirizzi,
E2E originali e review distinta restano prerequisiti esterni. Nessun apply condiviso,
store upload, production, merge o DONE.

| CA / T | Evidence | Stato |
|---|---|---|
| CA-01 / T-01 | functional-audit.md, baseline Git/CI e percorsi | PASS statico, live distinto |
| CA-02 / T-02 | manifest55, gate11 test; schema remoto incompatibile rilevato | PASS controllo; runtime FAIL |
| CA-03 / T-03 | backend-reconciliation.md;23 suite1034 SQL | PASS locale; apply BLOCKED |
| CA-04 / T-04 | finding R01–R11, regressioni FAIL prima/PASS dopo | PASS deterministico; review NOT_RUN |
| CA-05 / T-05 | validation.md; qualità/build/performance | BLOCKED per gate ancora non verdi |
| CA-06 / T-06 | matrice25 ID e requisiti esterni | BLOCKED fonte originale e review distinta |

L'Execution non è review-ready: resta BLOCKED in EXECUTION, senza transizione fittizia
CODEX_EXECUTION_COMPLETE_TO_REVIEW.
