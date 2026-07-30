# TASK-004 evidence

Snapshot di handoff:
`ACTIVE / REVIEW / CODEX_EXECUTION_COMPLETE_TO_REVIEW`.

- Base: closeout TASK-003
  `108b4f214a045dfc8157dd85eb87b9ce58c02d6b`
- Branch: `milestone/003-004-storefront-contract-environments`
- Tipo task: configurazione runtime, documentazione e test
- Planning: completo; autorizzazione condizionata applicata con commit separato
- Audit staging: read-only e sanitizzato; nessuna modifica remota
- Commit tecnico:
  `9ecffdfc7de38e979a48bac201ddd36a5296b78b`
- Gate Execution: tutti gli applicabili `PASS`
- Test: 70/70 suite completa; 27/27 mirati; 1/1 compile-time staging locale
- Smoke: Android Emulator e iOS Simulator development `PASS`
- CI tecnica: run `30588442946` sullo SHA esatto `9ecffdfc7de38e979a48bac201ddd36a5296b78b`,
  3/3 job, tutti gli step `success`, annotation 0/0/0
- Review: `NOT_RUN`
- CI handoff: `NOT_RUN`, richiede push del commit che contiene queste evidence
- DONE/PR/merge: `NOT_RUN`

Evidence disponibili:

- `planning-summary.md`
- `environment-audit.md`
- `execution-evidence.md`
- `local-config-attestation.md`
- `security-diff-scan.md`
- `runtime-smoke.md`

Evidence previste in review:

- `review-report.md`
- eventuale `fix-evidence.md`
- eventuale `re-review-report.md`
- `closeout.md`

## Criteri di accettazione — stato Planning

| CA | Esito | Motivo |
|---|---|---|
| CA-01 | PASS | TASK-003 closeout CI `30585880180` verificata prima dell'attivazione |
| CA-02 | PASS | commit Planning `1cc13b4`, autorizzazione `57b4a50`, governance exit 0 |
| CA-03 | PASS | `docs/ARCHITECTURE/ENVIRONMENT-STRATEGY.md` |
| CA-04 | PASS | contratto e `AppConfig.fromEnvironment`: cinque input esatti |
| CA-05 | PASS | test environment parsing |
| CA-06 | PASS | unit/bootstrap e smoke Android/iOS development senza Supabase |
| CA-07 | PASS | test development URL/key/callback/Google e initializer zero |
| CA-08 | PASS | test staging completo e missing-field matrix |
| CA-09 | PASS | test staging `false` e contratto kill switch |
| CA-10 | PASS | test production completa false/incompleta/true e zero fallback |
| CA-11 | PASS | test tuple, origin HTTPS e publishable/anon |
| CA-12 | PASS | test secret/service-role/malformed e messaggi sanitizzati |
| CA-13 | PASS | callback esatta e matrice di 13 varianti invalide |
| CA-14 | PASS | test errori, diagnostics e `toString` senza raw values |
| CA-15 | PASS | mappa sanitizzata con ambiente e tre booleani |
| CA-16 | PASS | esempio development JSON, cinque chiavi e offline |
| CA-17 | PASS | esempio staging JSON, cinque chiavi, callback e placeholder vuoti |
| CA-18 | PASS | file locale presente, shape valida, ignorato e non tracciato |
| CA-19 | PASS | README contiene i tre comandi letterali richiesti |
| CA-20 | PASS | test widget/banner e guard `kDebugMode` nel gate completo |
| CA-21 | PASS | diff scan: zero readiness/OAuth/native/shop/query |
| CA-22 | PASS | scan tracked/untracked: zero valore staging/prod, secret o local config |
| CA-23 | PASS | 11 file tecnici allowlisted; Supabase/repository esterni zero-write |
| CA-24 | PASS | 27/27 test mirati `PASS` |
| CA-25 | PASS | `scripts/check.sh` exit 0; 70/70 test e due build |
| CA-26 | PASS | smoke reali Android Emulator e iOS Simulator exit 0 |
| CA-27 | NOT_RUN | review non ancora iniziata |
| CA-28 | PASS | CI tecnica `30588442946`, SHA esatto, 3/3 job e annotation 0/0/0 |

## Test case — stato Planning

| Test | Esito | Motivo |
|---|---|---|
| T-01 | PASS | prerequisiti, CI TASK-003 e governance verificati |
| T-02 | PASS | matrice e cinque input verificati staticamente e nei test |
| T-03 | PASS | development vuoto e compile-time default |
| T-04 | PASS | development rifiuta input remoti/auth; initializer zero |
| T-05 | PASS | staging completo con auth attiva |
| T-06 | PASS | staging completo con auth disabilitata |
| T-07 | PASS | staging missing-field matrix |
| T-08 | PASS | production incompleta/true/no fallback |
| T-09 | PASS | environment case/whitespace/vuoti/ignoti |
| T-10 | PASS | tuple e origin HTTPS matrix |
| T-11 | PASS | publishable moderna, legacy anon e privilegiata/malformed |
| T-12 | PASS | callback canonica |
| T-13 | PASS | callback invalid matrix |
| T-14 | PASS | flag strict true/false/assente/case/invalido |
| T-15 | PASS | diagnostica strutturata sanitizzata |
| T-16 | PASS | errori non ripetono marker sensibili |
| T-17 | PASS | esempi JSON con shape e contenuto fail-closed |
| T-18 | PASS | presenza/ignore/tracking file locale |
| T-19 | PASS | tre comandi README verificati letteralmente |
| T-20 | PASS | test banner e guard debug |
| T-21 | PASS | Android integration smoke exit 0 |
| T-22 | PASS | iOS integration smoke exit 0 |
| T-23 | PASS | diff confinement e scan simboli fuori scope |
| T-24 | PASS | scan security/config/artifact e zero-write |
| T-25 | PASS | test mirati e `scripts/check.sh` exit 0 |
| T-26 | NOT_RUN | review non ancora iniziata |
| T-27 | PASS | CI `30588442946` su `9ecffdf…`, step e annotation ispezionati |
