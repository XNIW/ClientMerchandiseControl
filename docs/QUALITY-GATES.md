# Quality gate

## Gate locali obbligatori

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
| Gate aggregato | `bash scripts/check.sh` |
| Git | `git diff --check` |

`scripts/check.sh` esegue la sequenza completa con `set -euo pipefail`. Tipi, esiti e
requisiti di evidence sono definiti in `docs/CODEX-WORKFLOW-PROTOCOL.md`.

## Gate specifici TASK-002

- test brand resolver, token, semantic theme light/dark, contrasto, `copyWith` e `lerp`;
- scan statico di raw color e metriche feature con allowlist motivata;
- resolver e rendering reale di es, it, en e zh-Hans;
- quattro tab, back e persistenza shell;
- viewport 320×568, 568×320, 390×844 e almeno 1024×768, incluso testo 200%;
- Semantics, target minimo e banner debug;
- confronto di package, bundle identifier, target e repository esterni con la baseline.

## Gate runtime

I task che modificano UI o bootstrap richiedono avvio reale su Android Emulator e iOS
Simulator, navigazione e screenshot sanitizzati. Build e smoke sono gate distinti. Per
TASK-002 lo smoke include quattro tab, back, light/dark, portrait/landscape, testo
ingrandito e controllo dei log.

## Gate security

Nessun secret, configurazione locale, dato cliente, provisioning profile, certificato,
URL production o artifact di build può essere versionato. Il diff deve inoltre confermare
che TASK-002 non introduce networking o dati commerciali finti.

## Gate CI

La PR deve avviare quality, Android build e iOS Simulator build sullo SHA revisionato.
Vanno ispezionati job, step, annotation e commit associato. Un job pending non è `PASS`;
quota o policy esterna è `BLOCKED`, con causa `CI_EXTERNAL`, tentativo e prerequisito di
sblocco documentati.

## Integrità del gate

Gli unici esiti ammessi sono `PASS`, `FAIL`, `NOT_RUN` e `BLOCKED`. Ogni comando ancora
attivo deve terminare prima dell'handoff. In `EXECUTION`, un gate obbligatorio `FAIL`,
`NOT_RUN` o `BLOCKED` impedisce la consegna a Review; dopo `FIX` il task torna comunque
a Review e il gate non superato determina l'esito del re-reviewer.
