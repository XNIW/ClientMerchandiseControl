# TASK-001 evidence

Stato snapshot: re-review completata;
`ACTIVE / REVIEW / CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION`.

## Criteri di accettazione

| CA | Tipo | Esito | Evidenza |
|---|---|---|---|
| CA-01 | STATIC | PASS | `GOVERNANCE-REFERENCE-AUDIT.md` |
| CA-02 | STATIC | PASS | Governance root e `docs/` |
| CA-03 | STATIC | PASS | 42 righe backlog, una sola ACTIVE |
| CA-04 | STATIC | PASS | Soli `android/` e `ios/` |
| CA-05 | STATIC/BUILD | PASS | ID nativi + build PASS |
| CA-06 | STATIC/ANALYZE | PASS | `lib/`, pubspec, analyze |
| CA-07 | UNIT/SECURITY | PASS | matrice AppConfig fail-closed + `review-security-check.md` |
| CA-08 | UNIT/WIDGET/SMOKE | PASS | seam bootstrap, zero chiamate offline + smoke dual-platform |
| CA-09 | STATIC/WIDGET | PASS | es/it/en/zh-Hans, resolver, metadata iOS, widget e screenshot |
| CA-10 | UNIT | PASS | `clp_currency_formatter_test.dart` |
| CA-11 | WIDGET/SMOKE | PASS | shell test + smoke |
| CA-12 | FORMAT/ANALYZE/UNIT/WIDGET | PASS | `review-commands-and-results.md`, 38 test |
| CA-13 | BUILD_ANDROID | PASS | APK debug |
| CA-14 | BUILD_IOS | PASS | Runner.app Simulator |
| CA-15 | ANDROID_EMU | PASS | `android-smoke.md`, quattro screenshot post-fix |
| CA-16 | IOS_SIM | PASS | `ios-smoke.md`, quattro screenshot post-fix |
| CA-17 | CI | PASS | `ci-status.md`, Quality/Android/iOS sul commit tecnico |
| CA-18 | SECURITY/GIT | PASS | `security-check.md` + `review-security-check.md` |
| CA-19 | GIT | PASS | repository privato, branch, commit e PR #1 |
| CA-20 | GIT | PASS | `git-state.md` |
| CA-21 | STATIC/GIT | PASS | task e Master Plan `ACTIVE / REVIEW`, mai `DONE` |
| CA-22 | STATIC/GIT | PASS | `codex-only-governance-migration.md` |

## Test case

| Test | Tipo | Esito | Evidenza |
|---|---|---|---|
| T-01 | STATIC/GIT | PASS | audit + HEAD esterni invariati |
| T-02 | STATIC | PASS | governance e backlog |
| T-03 | STATIC | PASS | target e identificatori |
| T-04 | STATIC/ANALYZE | PASS | struttura + analyze |
| T-05 | UNIT | PASS | development senza config e zero initializer call |
| T-06 | UNIT | PASS | staging/production validi e publishable/anon allowlist |
| T-07 | UNIT | PASS | config parziale o privilegiata rifiutata |
| T-08 | UNIT | PASS | origin non HTTPS/non canonica rifiutata |
| T-09 | UNIT | PASS | CLP, zero negativo, grandi, null e non finiti |
| T-10 | WIDGET | PASS | app offline, spagnolo e fallback |
| T-11 | WIDGET | PASS | quattro destinazioni, contenuto reale e no counter |
| T-12 | WIDGET | PASS | navigazione shell e back secondaria -> Home |
| T-13 | FORMAT | PASS | format check |
| T-14 | ANALYZE | PASS | No issues found |
| T-15 | UNIT/WIDGET | PASS | 38 test |
| T-16 | BUILD_ANDROID | PASS | APK debug |
| T-17 | BUILD_IOS | PASS | iOS Simulator debug |
| T-18 | ANDROID_EMU | PASS | `android-smoke.md` |
| T-19 | IOS_SIM | PASS | `ios-smoke.md` |
| T-20 | CI | PASS | GitHub Actions Quality, Android e iOS |
| T-21 | SECURITY | PASS | `security-check.md` + `review-security-check.md` |
| T-22 | GIT | PASS | remote privato, tracking e handoff verificati |
| T-23 | STATIC/GIT | PASS | `codex-only-governance-migration.md` |

CA-21 conserva il token storico `READY_FOR_REVIEW` nel planning approvato; D-05 lo
normalizza all'handoff Codex-only finale
`CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION`, senza alterare gli invarianti
`ACTIVE / REVIEW`, mai `DONE`.
