# Execution evidence — TASK-004

## Revisione verificata

- Base Execution: `57b4a50ae78bb8dd1990efced5e8ffab6fde3267`
- Commit tecnico: `9ecffdfc7de38e979a48bac201ddd36a5296b78b`
- Branch: `milestone/003-004-storefront-contract-environments`
- Worktree dopo commit tecnico: pulito; presente soltanto il file locale ignorato
- Modifiche tecniche: 11 file, 786 inserimenti, 22 rimozioni

## Deliverable

| Area | Risultato |
|---|---|
| Runtime | `AppConfig` a cinque input, matrice fail-closed e diagnostics sanitizzate |
| Bootstrap | development short-circuit esplicito, nessun initializer |
| Test | ambiente, tuple, key, callback, flag, secrecy, esempi e compile-time local |
| Config | example development/staging e file staging locale ignorato |
| Documenti | environment strategy, ADR-005, mobile architecture, quality gate e README |
| Remoto | nessuna modifica Supabase o repository esterno |

## Comandi e risultati

| Comando/verifica | Esito | Dettaglio |
|---|---|---|
| `bash scripts/doctor.sh` | PASS | exit 0, Flutter doctor senza issue |
| primo test mirato | FAIL | exit 1, import test mancante; corretto prima dei retry |
| test mirati finali | PASS | exit 0, 27/27 |
| compile-time test staging locale | PASS | exit 0, 1/1; nessun valore stampato |
| `dart format --output=none --set-exit-if-changed .` | PASS | exit 0, 40 file invariati |
| `flutter analyze` | PASS | exit 0, zero issue |
| `flutter test --coverage` via `scripts/check.sh` | PASS | exit 0, 70/70 |
| `flutter build apk --debug` | PASS | exit 0 |
| `flutter build ios --simulator --debug` | PASS | exit 0 |
| build APK con staging local | PASS | exit 0 |
| build iOS Simulator con staging local | PASS | exit 0 |
| Android integration smoke | PASS | exit 0 |
| iOS integration smoke | PASS | exit 0 |
| `bash -n scripts/*.sh` | PASS | exit 0 |
| `flutter pub deps --style=compact` | PASS | exit 0, informativo |
| `flutter pub outdated` | PASS | exit 0, informativo; nessun upgrade |
| `bash scripts/check.sh` finale | PASS | exit 0 |
| JSON/README/local/security/confinement | PASS | tutti exit 0 |
| CI `30588442946` | PASS | SHA esatto, 3/3 job, tutti gli step, annotation 0/0/0 |

## Warning e deviazioni

- Il primo test mirato non compilava perché il test bootstrap non importava il tipo
  `AppConfigurationException`. Correzione limitata al test; retry finale 27/27.
- Sette package hanno versioni più recenti incompatibili con i constraint: nessun
  aggiornamento automatico autorizzato.
- `gen-l10n` usa correttamente `l10n.yaml`.
- Il doctor ha segnalato soltanto discovery di un Apple Watch; Android Emulator e iOS
  Simulator usati dai gate erano disponibili e hanno completato gli smoke.
- Un primo loop statico ha usato per errore la variabile speciale zsh `path`: i check
  precedenti erano già `PASS`, ma il successivo `git status` non era risolvibile. Il
  retry identico con variabile `evidence_file` ha completato exit 0.

## Scope

Scope conforme. Nessuna dipendenza, `.env`, logger, health probe, OAuth, sessione,
deep link nativo, `shop_id`, query, schema, dato commerciale o configurazione
production è stata introdotta.
