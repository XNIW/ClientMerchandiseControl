# TASK-001 evidence

Stato snapshot: Execution locale completata; PR e CI ancora da eseguire.

## Criteri di accettazione

| CA | Tipo | Esito | Evidenza |
|---|---|---|---|
| CA-01 | STATIC | PASS | `GOVERNANCE-REFERENCE-AUDIT.md` |
| CA-02 | STATIC | PASS | Governance root e `docs/` |
| CA-03 | STATIC | PASS | 42 righe backlog, una sola ACTIVE |
| CA-04 | STATIC | PASS | Soli `android/` e `ios/` |
| CA-05 | STATIC/BUILD | PASS | ID nativi + build PASS |
| CA-06 | STATIC/ANALYZE | PASS | `lib/`, pubspec, analyze |
| CA-07 | UNIT/SECURITY | PASS | AppConfig test + `security-check.md` |
| CA-08 | UNIT/WIDGET/SMOKE | PASS | bootstrap test + smoke dual-platform |
| CA-09 | STATIC/WIDGET | PASS | ARB, app widget test e screenshot |
| CA-10 | UNIT | PASS | `clp_currency_formatter_test.dart` |
| CA-11 | WIDGET/SMOKE | PASS | shell test + smoke |
| CA-12 | FORMAT/ANALYZE/UNIT/WIDGET | PASS | `commands-and-results.md` |
| CA-13 | BUILD_ANDROID | PASS | APK debug |
| CA-14 | BUILD_IOS | PASS | Runner.app Simulator |
| CA-15 | ANDROID_EMU | PASS | `android-smoke.md`, screenshot |
| CA-16 | IOS_SIM | PASS | `ios-smoke.md`, screenshot |
| CA-17 | CI | NOT_RUN | PR non ancora aperta |
| CA-18 | SECURITY/GIT | PASS | `security-check.md` |
| CA-19 | GIT | NOT_RUN | Repo/branch presenti; commit finale e PR pendenti |
| CA-20 | GIT | PASS | `git-state.md` |
| CA-21 | STATIC/GIT | NOT_RUN | Transizione finale dopo CI |

## Test case

| Test | Tipo | Esito | Evidenza |
|---|---|---|---|
| T-01 | STATIC/GIT | PASS | audit + HEAD esterni invariati |
| T-02 | STATIC | PASS | governance e backlog |
| T-03 | STATIC | PASS | target e identificatori |
| T-04 | STATIC/ANALYZE | PASS | struttura + analyze |
| T-05 | UNIT | PASS | development senza config |
| T-06 | UNIT | PASS | staging/production validi |
| T-07 | UNIT | PASS | production incompleta rifiutata |
| T-08 | UNIT | PASS | URL non valido rifiutato |
| T-09 | UNIT | PASS | CLP, negativi, null/invalid |
| T-10 | WIDGET | PASS | app offline e spagnolo |
| T-11 | WIDGET | PASS | quattro destinazioni, no counter |
| T-12 | WIDGET | PASS | navigazione shell |
| T-13 | FORMAT | PASS | format check |
| T-14 | ANALYZE | PASS | No issues found |
| T-15 | UNIT/WIDGET | PASS | 16 test |
| T-16 | BUILD_ANDROID | PASS | APK debug |
| T-17 | BUILD_IOS | PASS | iOS Simulator debug |
| T-18 | ANDROID_EMU | PASS | `android-smoke.md` |
| T-19 | IOS_SIM | PASS | `ios-smoke.md` |
| T-20 | CI | NOT_RUN | PR non ancora aperta |
| T-21 | SECURITY | PASS | `security-check.md` |
| T-22 | GIT | NOT_RUN | commit finale/PR/tracking pendenti |
