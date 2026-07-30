# Quality gate

## Gate locali TASK-001

| Gate | Comando |
|---|---|
| Dipendenze | `flutter pub get` |
| Localizzazioni | `flutter gen-l10n` |
| Formattazione | `dart format --output=none --set-exit-if-changed .` |
| Analisi | `flutter analyze` |
| Test | `flutter test --coverage` |
| Android | `flutter build apk --debug` |
| iOS Simulator | `flutter build ios --simulator --debug` |
| Script | `bash -n scripts/doctor.sh scripts/check.sh` |
| Git | `git diff --check` |

`scripts/check.sh` esegue la sequenza completa con `set -euo pipefail`.
Tipi, esiti e requisiti di evidence sono definiti in
`docs/CODEX-WORKFLOW-PROTOCOL.md`.

## Gate runtime

TASK-001 richiede avvio reale su Android Emulator e iOS Simulator, navigazione tra almeno
due destinazioni e screenshot sanitizzati. La sola build non sostituisce lo smoke.

## Gate security

Nessun secret, configurazione locale, dato cliente, provisioning profile, certificato o
artifact di build può essere versionato.

## Gate CI

La PR deve avviare quality, Android build e iOS Simulator build. Un job pending non è
`PASS`; quota o policy esterna è `BLOCKED`, con causa `CI_EXTERNAL`, tentativo e
prerequisito di sblocco documentati.

## Integrità del gate

Gli unici esiti ammessi sono `PASS`, `FAIL`, `NOT_RUN` e `BLOCKED`. Ogni comando ancora
attivo deve terminare prima dell'handoff. In `EXECUTION`, un gate obbligatorio `FAIL`,
`NOT_RUN` o `BLOCKED` impedisce la consegna a Review; dopo `FIX` il task torna comunque
a Review e il gate non superato determina l'esito del re-reviewer.
