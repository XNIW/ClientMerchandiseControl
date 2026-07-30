# Comandi e risultati

Output sintetico e sanitizzato. Nessun log build completo è versionato.

| Comando | Exit | Esito | Nota |
|---|---:|---|---|
| preflight tool discovery iniziale | 1 | FAIL | Flutter, adb in PATH e CocoaPods inizialmente mancanti; corretti nei passaggi successivi |
| audit GitHub API dei quattro repository | 0 | PASS | Ref e file documentati nell'audit |
| installazione Flutter + SHA-256 | 0 | PASS | Flutter 3.44.8 stable |
| `flutter doctor -v` finale | 0 | PASS | No issues found |
| `flutter create -h` | 0 | PASS | `--empty` e target supportati verificati |
| `flutter create --empty --platforms=android,ios ... .` | 0 | PASS | Progetto creato nella root |
| `flutter pub get` | 0 | PASS | Lockfile generato |
| `flutter gen-l10n` | 0 | PASS | es/it/en/zh generate |
| `dart format --output=none --set-exit-if-changed .` | 0 | PASS | 0 file da modificare nel gate finale |
| `flutter analyze` | 0 | PASS | No issues found |
| `flutter test --coverage` | 0 | PASS | 16 test passati |
| `flutter build apk --debug` | 0 | PASS | Primo build 354,6 s; rerun 6,9 s |
| `flutter build ios --simulator --debug` | 0 | PASS | Primo build 67,8 s; rerun 13,2 s |
| `scripts/check.sh` | 0 | PASS | Sequenza completa superata |
| `bash -n scripts/doctor.sh scripts/check.sh` | 0 | PASS | Script validi |
| parse YAML CI con Ruby/Psych | 0 | PASS | Sintassi valida |
| `git diff --check` | 0 | PASS | Nessun errore whitespace |

Il primo giro test ha avuto exit `1`: ha rilevato simbolo CLP in posizione errata e una
simulazione locale non corretta. Il formatter e il resolver locale sono stati corretti;
i rerun finali sono PASS senza indebolire i test.

Il resolver segnala versioni più nuove incompatibili con i constraint correnti: è
informativo. Le versioni dirette sono stabili e il lockfile non contiene prerelease.
