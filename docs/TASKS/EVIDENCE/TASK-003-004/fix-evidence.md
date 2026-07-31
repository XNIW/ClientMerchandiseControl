# TASK-003/TASK-004 — Fix integrato

## Perimetro

- **Baseline revisionata**:
  `c8258f83c55b2b1a85f2e590d60f64fcfa1d5f0e`
- **Report sorgente**: `integrated-review-report.md`
- **Finding autorizzati**: `T003-INT-ARCH-001`–`004`
- **Finding emerso in re-review**: `T003004-REREV-SEC-001`
- **SHA tecnico finale**:
  `211ad692010d7b54b8541c45cb7f6a38e3f7d5fe`
- **Handoff**: `CODEX_FIX_COMPLETE_TO_RE_REVIEW`

Il Fix resta confinato ai contratti architetturali, alle decisioni già nel perimetro,
ai quality gate e ai validator. Non modifica runtime Flutter, configurazione locale,
backend, Supabase o repository esterni.

## Cicli di correzione

| Ciclo | SHA | Esito |
|---|---|---|
| 1 | `0151793f009070d4f9a568582f37d59e6774cc2d` | Separa owner/control plane/writer, riallinea TASK-012 e DAG, introduce il validator. CI `30593995010` 3/3 `PASS`; re-review `CHANGES_REQUIRED` perché due fonti normative e le regressioni erano incomplete. |
| 2 | `9595c98944b505c7ea57b69e28f2218317fe5760` | Corregge Data Boundary, ADR-008 e decisione TASK-002; rende marker-bounded il DAG e aggiunge quattro fixture negative. CI `30594944030` 3/3 `PASS`; re-review `CHANGES_REQUIRED` per bypass riproducibile della riga decisionale `D-04`. |
| 3 | `211ad692010d7b54b8541c45cb7f6a38e3f7d5fe` | Distingue righe roadmap da altre tabelle normative e aggiunge la fixture esatta `D-04`; 5/5 mutazioni respinte. CI `30595351101` 3/3 `PASS`. |

Una CI verde non ha sostituito la re-review: entrambi i bypass sono stati corretti
prima dell'handoff finale.

## Finding corretti

| Finding | Esito | Evidenza |
|---|---|---|
| `T003-INT-ARCH-001` | PASS | Tassonomia coerente in Storefront contract, ADR-010, Cross-repo ownership, System Context e `STOREFRONT-DATA-BOUNDARY.md:37-45`; i decision owner sono ruoli business, Admin Console è control plane e server/Supabase applicano la decisione. |
| `T003-INT-ARCH-002` | PASS | `QUALITY-GATES.md:49-52` ammette set autorizzati e split per layer; la matrice richiede celle complete e owner business semanticamente validi senza cardinalità uno sui ruoli cooperativi. |
| `T003-INT-ARCH-003` | PASS | ADR-008, ADR-009, System Context, Mobile Architecture e decisione `D-04` descrivono TASK-012 come guest/data-safe; il validator scansiona record logici di tutte le fonti normative. |
| `T003-INT-ARCH-004` | PASS | ADR-009 contiene 11 righe univoche tra marker e 23 edge diretti equivalenti al Master Plan dopo normalizzazione. |
| `T003004-REREV-SEC-001` | PASS | `check-architecture-boundaries.sh:148-213` è source-aware; `test-architecture-boundaries.sh:83-126` respinge owner di sistema, scope ADR-008, decisione TASK-002, DAG duplicato e gate a cardinalità uno. |

## Matrice CA

| CA | Tipo | Esito | Evidenza |
|---|---|---|---|
| CA-05 | STATIC | PASS | Responsabilità, non-responsabilità e flussi vietati restano espliciti per ogni sistema. |
| CA-06 | STATIC | PASS | Matrice cross-repo completa, non duplicata e semanticamente validata. |
| CA-10 | STATIC | PASS | Supabase resta runtime/enforcement e non acquisisce business decision authority. |
| CA-11 | STATIC | PASS | Storefront contract mantiene vocabolario normativo, versione e ownership distinte. |
| CA-24 | STATIC | PASS | ADR-009 descrive workstream paralleli mantenendo un solo task attivo. |
| CA-25 | STATIC/GIT | PASS | Restano autorizzate soltanto le dipendenze già emendate di TASK-010, TASK-011 e TASK-020. |
| CA-26 | STATIC | PASS | DAG ADR-009 allineato 11/11 al Master Plan; 42 nodi e zero cicli. |
| CA-27 | STATIC/GIT | PASS | TASK-005–010 e TASK-013+ restano presenti, con scope e stato `TODO` invariati. |
| CA-30 | STATIC/FORMAT/ANALYZE/UNIT/BUILD_ANDROID/BUILD_IOS/GIT | PASS | Validator, fixture e gate aggregato eseguiti con exit 0. |
| CA-31 | MANUAL/STATIC | PASS | Tre re-review indipendenti terminano senza P0/P1/P2 aperti. |
| CA-32 | CI | PASS | Run `30595351101` sullo SHA esatto, 3/3 job, step `success`, annotation 0/0/0. |

## Matrice test

| Test | Tipo | Esito | Evidenza |
|---|---|---|---|
| T-04 | STATIC | PASS | Completezza e unicità della matrice ownership verificate dai reviewer indipendenti. |
| T-05 | STATIC | PASS | Responsabilità e forbidden flow per sistema restano coerenti. |
| T-06 | STATIC | PASS | Versione, ownership e change protocol del contratto restano espliciti. |
| T-13 | STATIC/GIT | PASS | Diff allowlist delle dipendenze e ADR-009 verificata. |
| T-14 | STATIC | PASS | Parser indipendente: 42 task, zero cicli, 11/11 righe e 23/23 edge diretti. |
| T-15 | STATIC/GIT | PASS | Titoli, scope, risultati e stati dei task futuri confrontati; nodi fuori autorizzazione invariati. |
| T-18 | STATIC/GIT | PASS | Governance, validator, fixture e `git diff --check` exit 0. |
| T-19 | FORMAT/ANALYZE/UNIT/BUILD_ANDROID/BUILD_IOS | PASS | `bash scripts/check.sh`, exit 0; 72/72 test e due build. |
| T-20 | MANUAL/STATIC | PASS | Re-review architecture, security e integrata `APPROVED`. |
| T-21 | CI | PASS | Run `30595351101`, SHA esatto, 3/3 job, tutti gli step `success`, annotation 0/0/0. |
| REG-01 | STATIC | PASS | Mutazione `Admin Console` come business decision owner respinta. |
| REG-02 | STATIC | PASS | ADR-008 e TASK-002 `D-04` data-backed respinte; TASK-013 legittimo accettato. |
| REG-03 | STATIC | PASS | Riga DAG duplicata e gate «un solo» respinti. |

## Gate e security

| Gate | Esito | Evidenza |
|---|---|---|
| `bash -n scripts/*.sh` su Bash 3.2.57 | PASS | exit 0 |
| `bash scripts/check-architecture-boundaries.sh` | PASS | exit 0 |
| `bash scripts/test-architecture-boundaries.sh` | PASS | exit 0, 5/5 fixture respinte |
| Governance e action pin | PASS | entrambi exit 0 |
| `bash scripts/check.sh` | PASS | exit 0; analyze senza issue, 72/72 test, APK e iOS Simulator build |
| Scansione secret/injection/symlink/confinement | PASS | nessun pattern ad alta confidenza, runtime/config o symlink nel delta; cleanup temporaneo senza residui |
| Config staging locale | PASS | presente, ignorata e non tracciata; nessun valore riportato |
| `shellcheck` | NOT_RUN | binario non installato; Bash 3.2 locale e Ubuntu CI hanno eseguito sintassi e script reali |
| Codex Security app-backed | BLOCKED | helper Python bundled non avviabile; il limite non è convertito in `PASS`. Review security manuale e shard indipendente completati. |
| CI finale tecnica | PASS | `30595351101` su `211ad692…`; Quality 2m8s, Android 8m5s, iOS 3m23s |

Warning non bloccante: sette package hanno versioni più recenti incompatibili con i
constraint correnti; nessuna dipendenza è stata aggiornata fuori scope.

## Rischi non bloccanti non corretti

Restano i quattro P3 già registrati dalla review integrata:

- `T003-INT-ARCH-005`, diagramma fiscale ambiguo;
- `T003004-INT-GOV-002`, riga CI TASK-002 obsoleta;
- `T003-REREV-002`, locator `versionId` incompleto;
- `T004-REREV-001`, conteggio storico 70/70 invece di 72/72.

Il Fix non li ha modificati perché non bloccano i criteri e non erano autorizzati nel
perimetro correttivo.

## Handoff

- **Gate obbligatori**: `PASS`
- **P0/P1/P2 noti prima della re-review**: 0 aperti sul contenuto finale
- **Re-review indipendente**: obbligatoria sullo SHA tecnico finale
- **Indicatore**: `CODEX_FIX_COMPLETE_TO_RE_REVIEW`
