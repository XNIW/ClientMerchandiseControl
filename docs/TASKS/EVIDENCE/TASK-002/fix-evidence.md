# Fix evidence — TASK-002

## Scope

Fix limitato ai finding della review sul commit `92d2697…`:

- `T002-REV-001`: stato operativo incoerente;
- `T002-REV-002`: fingerprint esterni non riproducibili;
- correzione delle imprecisioni documentali P3 `T002-REV-003` e
  `T002-REV-004`.

I finding UI P3 `T002-REV-005` e `T002-REV-006` restano non bloccanti e non sono stati
usati per ampliare TASK-002.

## Correzioni

| Finding | Stato Fix | Correzione | Regressione |
|---|---|---|---|
| T002-REV-001 | PASS | README, Master Plan, task ed evidence espongono la stessa terna operativa | `scripts/check-governance-state.sh` confronta automaticamente task/stato/fase/handoff |
| T002-REV-002 | PASS | algoritmo shell completo e sanitizzato versionato; procedura rieseguita su 4/4 repository | otto digest ricalcolati, exit `0`, tutti identici alla tabella |
| T002-REV-003 | PASS | CA-19 distingue Emulator e Simulator dall'hardware fisico | confronto con `runtime-smoke.md` |
| T002-REV-004 | PASS | corpo PR #2 corretto con target tecnico e worklist esatti | ispezione metadata PR |

## Risultati

- `bash scripts/check-governance-state.sh`: `PASS`, exit `0`.
- fingerprint read-only: `PASS`, exit `0`, otto digest su otto coincidenti.
- `bash -n scripts/*.sh`: `PASS`, exit `0`.
- `bash scripts/check.sh`: `PASS`, exit `0`; format 40/40, analyze pulito, 59/59
  test, APK debug e iOS Simulator build.
- smoke Android: primo tentativo `FAIL` prima del test per
  `INSTALL_FAILED_INSUFFICIENT_STORAGE`; `pm trim-caches 2G` ha liberato cache
  dell'emulatore; retry `PASS`, exit `0`, 1/1.
- smoke iOS: `PASS`, exit `0`, 1/1.
- `flutter pub deps --style=compact` e `flutter pub outdated`: `PASS`, exit `0`;
  nessuna modifica dipendenze, aggiornamenti major esistenti solo informativi.
- scan mirati secret e URL sul diff Fix: `PASS`, 0 match.
- `git diff --check` e `git diff --cached --check`: `PASS`.
- CI sul futuro SHA di closeout: `NOT_RUN`.

## Handoff previsto

Il Fix non approva le proprie correzioni. Dopo i gate applicabili, TASK-002 torna a
`REVIEW` con `CODEX_FIX_COMPLETE_TO_RE_REVIEW`.
