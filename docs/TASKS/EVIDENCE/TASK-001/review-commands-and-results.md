# Comandi e risultati review/fix/re-review — TASK-001

La prima tabella fotografa il commit
`83b855728f5cf3192f7f1daa1e37b787440423a9`, prima delle correzioni.

| Verifica | Stato | Exit code / risultato |
|---|---|---|
| `bash -n scripts/doctor.sh && bash -n scripts/check.sh` | PASS | `0` |
| `bash scripts/doctor.sh` | PASS | `0` |
| `flutter pub get` | PASS | `0` |
| `flutter gen-l10n` | PASS | `0` |
| `flutter pub deps --style=compact` | PASS | `0` |
| `flutter pub outdated` | PASS | `0` |
| `dart format --output=none --set-exit-if-changed .` | PASS | `0` |
| `flutter analyze` | PASS | `0` |
| `flutter test --coverage` | PASS | `0`, 16 test |
| `git diff --check` | PASS | `0` |
| `flutter build apk --debug` | PASS | `0`, circa 10,9 s |
| `flutter build ios --simulator --debug` | PASS | `0`, circa 9 s |
| Android Emulator smoke post-fix | NOT_RUN | previsto dopo le correzioni |
| iOS Simulator smoke post-fix | NOT_RUN | previsto dopo le correzioni |

## Gate post-fix e re-review

I gate seguenti verificano il commit tecnico
`3f0d992a7c1b6e9f9291e7617b53c0cf6c3f8734`. Gli aggiornamenti documentali successivi
non modificano codice, toolchain o workflow. Le durate sono riportate dove misurate;
negli altri casi non sono state registrate e non vengono inferite.

| Verifica | Stato | Exit code / risultato |
|---|---|---|
| Validazioni XML/plist/YAML, governance e diff | PASS | `0` |
| `bash -n scripts/*.sh` | PASS | `0` |
| `bash scripts/check-action-pins.sh` | PASS | `0`, sei action dirette immutabili |
| resolver Flutter via PATH | PASS | `0`, Flutter 3.44.8 / revisione `058e0af2c2` |
| resolver via `FLUTTER_ROOT` e fallback | PASS | `0` |
| resolver eseguito e sourced in shell interattiva/non-interattiva | PASS | `0` |
| resolver con `FLUTTER_ROOT` inesistente | PASS | rifiuto atteso, exit interno `127` |
| `flutter doctor -v` | PASS | `0`, circa 6,53 s, `No issues found` |
| `bash scripts/doctor.sh` | PASS | `0`, circa 7,84 s |
| `flutter pub get` | PASS | `0`, circa 0,67 s |
| `flutter pub get --enforce-lockfile` | PASS | `0`, circa 0,65 s |
| `flutter gen-l10n` | PASS | `0`, circa 0,32 s |
| `flutter pub deps --style=compact` | PASS | `0` |
| `flutter pub outdated` | PASS | `0`, 2 dipendenze dirette vincolate a versioni precedenti ma stable/locked |
| `dart format --output=none --set-exit-if-changed .` | PASS | `0`, 28 file, 0 modificati, circa 0,14 s |
| `flutter analyze` | PASS | `0`, circa 5,45 s |
| `flutter test --coverage` | PASS | `0`, 38 test, circa 3,62 s |
| `flutter build apk --debug` | PASS | `0`, circa 10,92 s |
| `flutter build ios --simulator --debug` | PASS | `0`, circa 16,35 s |
| `bash scripts/check.sh` | PASS | `0`, circa 25,43 s; rerun pre-commit `0`, 24,20 s |
| struttura, identificatori e assenza demo counter | PASS | `0` |
| probe action dirette/annidate mutabili | PASS | `0`, dirette mutabili 0, annidate mutabili 0 |
| Android Emulator smoke post-fix | PASS | install, cold launch, quattro tab, back, rotazione e log |
| iOS Simulator smoke post-fix | PASS | install, launch, quattro tab, rotazione, accessibilità e log |
| re-review app/config/UI | PASS | 38 test, format e analyze; nessun finding |
| re-review governance/CI/security | PASS | CA-22/T-23 e finding correlati; nessun finding |
| GitHub Actions run `30555712533` | PASS | Quality 1m59, Android 7m07, iOS 3m06; 0 annotazioni |
| Gitleaks | NOT_RUN | binario non disponibile |
| ShellCheck | NOT_RUN | binario non disponibile |

`flutter doctor -v` ha emesso warning informativi sulla discovery Watch e su un iPhone
fisico non disponibile; nessun device fisico è stato usato e il risultato terminale è
`No issues found`.

## Anomalie operative non attribuite al prodotto

| Tentativo | Stato | Risoluzione |
|---|---|---|
| Preflight security con Python di sistema privo di TOML | FAIL | runtime Python fornito, exit `0` |
| Aggiornamento unità di avanzamento security non valido | FAIL | payload corretto e scan completato |
| Preparazione validatore con tupla trattata come oggetto | FAIL | comando corretto, validatore exit `0` |
| Lettura `docs/WORKLOG.md` inesistente | FAIL | letto `docs/AI_WORKLOG.md` |
| Generazione l10n iniziale senza template `app_zh.arb` | FAIL | aggiunta base tecnica e rigenerazione exit `0` |
| Due prime asserzioni widget semantiche non deterministiche | FAIL | test resi deterministici, rerun `PASS` |
| Prima suite config: porta `99999` accettata da `Uri` | FAIL | controllo esplicito `1..65535`, rerun `PASS` |
| Primo parse YAML da directory Android con path errato | FAIL | path corretto, parse exit `0` |
| Primo comando re-review con variabile `FLUTTER_BIN` inesistente | FAIL | uso di `flutter` dal PATH, gate `PASS` |
| Primo `git grep` con pattern `-----BEGIN` interpretato come opzione | FAIL | uso di `-e`, nessun secret reale |
| Primo avvio emulator GUI senza device terminale | BLOCKED | usato AVD headless controllato |
| Poll del secondo tentativo emulator | FAIL | exit `2`, poi AVD headless booted in 19,25 s |
| Primo `gh pr view` con campo JSON `autoMerge` non valido | FAIL | campo `autoMergeRequest`, query exit `0` |
| Applicazione patch UI con contesto cambiato | FAIL | diff riletto e patch mirata applicata |

Queste anomalie non sostituiscono né invalidano i gate reali elencati sopra.
