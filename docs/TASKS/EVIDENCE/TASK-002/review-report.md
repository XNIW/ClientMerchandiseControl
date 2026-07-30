# Review indipendente — TASK-002

## Esito iniziale

- **Revisione verificata**:
  `92d2697f0577cfb510d0a4bdd323195d6cfb42b2`.
- **Base**: `f6bd88263fe8369c9ececa38367f629f3d1a929f`.
- **Pull Request**: PR #2, draft, head e base coerenti.
- **Verdetto**: `CHANGES_REQUIRED`.
- **Handoff**: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.
- **Distribuzione**: 0 P0, 0 P1, 2 P2, 4 P3.

Tre reviewer read-only distinti hanno verificato governance/evidence, implementazione
Flutter/runtime/security e UI/accessibilità. I finding duplicati fra shard sono
consolidati sotto un solo ID.

## Finding P2

### T002-REV-001 — P2 — Stato operativo incoerente

- **Stato**: OPEN
- **Posizione**: `README.md:99`.
- **Evidenza**: il README root dichiara
  `ACTIVE / EXECUTION / CODEX_PLANNING_APPROVED_TO_EXECUTION`; Master Plan, task ed
  evidence TASK-002 dichiarano
  `ACTIVE / REVIEW / CODEX_EXECUTION_COMPLETE_TO_REVIEW`.
- **Impatto**: CA-33/T-27 non sono soddisfatti e un operatore può assumere ruolo e
  transizione errati.
- **Correzione richiesta**: riallineare lo snapshot del README alla fase effettiva.
- **Test di regressione**: confrontare task, fase e handoff in README, Master Plan, task
  attivo ed evidence.

### T002-REV-002 — P2 — Fingerprint esterni non riproducibili dalla evidence

- **Stato**: OPEN
- **Posizione**:
  `docs/TASKS/EVIDENCE/TASK-002/external-repository-integrity.md:5`.
- **Evidenza**: `STATUS_SHA256` omette `--branch`, `--untracked-files=all` e
  `LC_ALL=C`; `CONTENT_FINGERPRINT_V1` non documenta prefisso, label, separatori NUL,
  opzioni Git, ordine degli untracked e serializzazione dei blob. Il comando abbreviato
  non ricrea i digest persistiti.
- **Impatto**: CA-37/T-29 non dispongono di una prova persistente riproducibile.
- **Correzione richiesta**: versionare il blocco shell esatto e sanitizzato, rieseguirlo
  senza fetch/write e confrontare tutti gli otto digest.
- **Test di regressione**: quattro repository, due digest ciascuno, tutti identici alla
  baseline persistita.

## Finding P3

### T002-REV-003 — P3 — Copertura runtime sovradichiarata

- **Stato**: OPEN
- **Posizione**: `docs/TASKS/EVIDENCE/TASK-002/README.md:44`.
- **Evidenza**: CA-19 usa “device reali”, mentre le prove sono Android Emulator e iOS
  Simulator.
- **Correzione consigliata**: descrivere i runtime effettivi senza implicare hardware
  fisico.

### T002-REV-004 — P3 — Scope security sovradichiarato nella PR

- **Stato**: OPEN
- **Posizione**: PR #2, sezione “Verifiche dell'executor”.
- **Evidenza**: la scansione sigillata copre la revisione tecnica
  `f6bd882…ec599758` e una worklist full-file di 15 file, non il successivo commit
  documentale `92d2697`.
- **Correzione consigliata**: indicare target e copertura esatti.

### T002-REV-005 — P3 — Il test al 200% non prova scroll e visibilità completa

- **Stato**: OPEN, non bloccante per TASK-002
- **Posizione**: `test/features/shell/app_shell_screen_test.dart:144`,
  `integration_test/app_shell_smoke_test.dart:129`.
- **Evidenza**: i test verificano navigazione e assenza di eccezioni, non la
  raggiungibilità dell'ultima riga né i bounds completi delle label.
- **Correzione consigliata**: estendere la matrice di usabilità nella productizzazione
  della shell, senza alterare lo scope corrente.

### T002-REV-006 — P3 — Larghezza card dipendente dal copy

- **Stato**: OPEN, non bloccante per TASK-002
- **Posizione**: `lib/app/design_system/widgets/storefront_page.dart:27`,
  `lib/core/widgets/feature_placeholder.dart:23`.
- **Evidenza**: su viewport ampie la card Catalogo è più stretta delle altre perché il
  vincolo imposta solo la larghezza massima.
- **Correzione consigliata**: uniformare il riempimento orizzontale durante la
  productizzazione della shell.

## Verifiche autonome

| Verifica | Esito | Evidenza |
|---|---|---|
| `bash scripts/check.sh` | PASS | exit `0`; format 40/40, analyze pulito, 59/59 test, build Android/iOS |
| Smoke Android | PASS | integration test su API 35, exit `0`, 1/1 |
| Smoke iOS | PASS | integration test su iOS 26.5, exit `0`, 1/1 |
| Diff/dependency/config/static scan | PASS | diff check, deps, outdated, l10n, identifier, secret/network/fake-commerce |
| Screenshot | PASS | 9/9 hash e dimensioni coerenti; nessun dato cliente o secret |
| CI della revisione | PASS | run `30573839944`, SHA `92d2697…`, 3/3 job e tutti gli step, 0 annotation |
| Git e repository esterni | PASS | worktree pulito; fingerprint reali 4/4 invariati |

La CI sopra attesta la revisione iniziale, non il futuro SHA di closeout. La verifica
security resta diff-scoped e non equivale a una deep scan dell'intero repository.

## Handoff

- **Transizione**: `REVIEW -> FIX`
- **Esito**: `CHANGES_REQUIRED`
- **Finding obbligatori da risolvere**: `T002-REV-001`, `T002-REV-002`
- **Prossimo ruolo**: `CODEX_FIXER`
- **Merge**: vietato
