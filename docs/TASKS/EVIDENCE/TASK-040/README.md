# Evidence TASK-040

Snapshot di handoff:
`ACTIVE / FIX / CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Provenance

- Client baseline: `f30b13e9bfc1ea8b792d2048c0b067077e2d307c`;
- TASK-039 PR #18 e CI PR/main exact-SHA verdi;
- Admin baseline read-only: `59668348e4c728b44b998c80f1aded61e6114a3f`;
- production, App Store Connect e TestFlight invariati all'attivazione.

## Matrice CA -> evidence

| CA | Evidence | Esito |
|---|---|---|
| CA-01 | production template + source/artifact/signing validator | PASS |
| CA-02 | Xcode settings e archive plist: bundle/version/build/iOS 14 | PASS |
| CA-03 | release app/archive, 3 hash, 7 dSYM e Runner UUID | PASS |
| CA-04 | custom scheme bounded; entitlement/Universal Links/push assenti e bloccati | PASS |
| CA-05 | manifest app byte-identico e 8 privacy manifest app/SDK | PASS |
| CA-06 | security source 676 e app artifact 207; config esterna assente | PASS |
| CA-07 | OAuth/Maps/push/telemetry fail-closed; Maps native sentinel | PASS |
| CA-08 | arm64, Mach-O app/framework e Runner dSYM UUID corrispondente | PASS |
| CA-09 | 0 Distribution/profile/ASC key; upload readiness exit 1 redatto | PASS |
| CA-10 | re-review indipendente e PR/main CI da eseguire | NOT_RUN |

## Matrice T -> risultato

| Test | Esito | Evidence |
|---|---|---|
| T-01 | PASS | source gate, runtime config 3/3 e config/signing boundary |
| T-02 | PASS | clean release no-codesign e archive Xcode exact SHA `9065d9c7` |
| T-03 | PASS | plist/privacy/entitlement/framework/dSYM + fixture iOS 8/8 |
| T-04 | PASS | scanner 679/207 e fixture 56/56 + 7/7 |
| T-05 | PASS | inventory redatto e upload gate bloccato sulla Distribution signature |
| T-06a | PASS | Simulator debug integration 1/1 realmente eseguita |
| T-06b | NOT_RUN | Release Simulator non supportato dal comando Flutter release |
| T-06c | BLOCKED | physical iOS assente; prerequisite: device collegato e autorizzato |
| T-07 | NOT_RUN | fix handoff pronto; re-review, PR/main CI e hygiene da eseguire |

## Activation boundary

- signing identity: 1 Apple Development, 0 Apple Distribution;
- provisioning: zero file; App Store Connect API key: zero; env rilevanti: zero;
- App Store Connect access/upload: `NOT_RUN`, prerequisite reali assenti;
- production App Store: vietata;
- physical iOS: `BLOCKED`, zero device collegati; separato dal Simulator.

## Artifact evidence

- source exact SHA: `9065d9c7a3d9bf34dd8c183c9adbccc896f124d9`;
- archive: `build/ios/archive/Runner.xcarchive`, 201.328 KiB, non versionato;
- app: 36.708 KiB, 207 file, bundle `com.xniw.clientmerchandisecontrol`,
  `0.1.0 (1)`, `iphoneos`, arm64, unsigned;
- executable SHA-256:
  `caa81fa3e2c0a067b4ecbf91f83267fb7dba6c95d54da27bf4022ced821f142c`;
- Info.plist SHA-256:
  `8888ca9f64b9c8f60b6a4a18079131c0db551f0630a6b539ee93b6b9980b3fb8`;
- app PrivacyInfo SHA-256:
  `5dd288d8eda8adac284ea005bb82585023eb82ae5302e26ffc27979a41ba40cd`;
- Runner Mach-O/dSYM UUID `F278496B-FCCE-3ADD-A310-7E94973B62D0`;
- archive signing identity/team vuoti; nessuna IPA/export/upload prodotto.

## Gate executor

- `scripts/check.sh`: exit 0;
- non-performance 788/788; performance 10/10; resilience repeat 70/70;
- format 297 file/0 cambi; analyze 0 issue;
- governance 9/9; architecture negative 7/7; localization/telemetry/action pin PASS;
- security source 676; artifact 207; fixture negative 52/52, positive 6/6;
- release metadata 12 capability × 3 ambienti; Android/iOS debug build PASS;
- release Simulator: comando tentato, Flutter dichiara modalità non supportata;
  debug production-like install/launch PASS con provider fail-closed;
- Xcode 26.6 (17F113), Flutter 3.44.8; warning SPM Google Maps upstream noto;
- worktree pulito allo SHA artifact; production invariata.

## Gate Fix 1

- finding prodotto/security riprodotti e corretti con regressioni dedicate;
- gate mirati Flutter 53/53, runtime config 3/3, iOS release fixture 8/8;
- security fixture 56/56 negative + 7/7 positive, source 679 e artifact 207;
- `scripts/check.sh` exit 0: suite completa, performance 10/10, resilience repeat
  5x14, analyze, Android debug e iOS Simulator debug `PASS`;
- format 299 file/0 cambi, governance 9/9, diff check e source validator `PASS`;
- clean build/archive exact `9065d9c7`, validator candidate `PASS`, signing
  `UNSIGNED`, upload readiness exit 1 per Distribution assente;
- artifact 201.328 KiB, app 36.708 KiB/207 file, 8 privacy manifest, 7 dSYM,
  arm64 e Runner/dSYM UUID corrispondente;
- worktree pulito; nessun secret, profilo, IPA, upload o mutazione production.

## Re-review Fix 1

- exact HEAD `be978225677304b9f5c8dce5fd3ba05dca7533e8`, worktree pulito;
- prodotto/security `CHANGES_REQUIRED`: 0 P0/P1, 6 P2 security, 4 P3 security,
  un P2 tecnico; report sealed SHA-256
  `e76c6beab23628a979cf20284253e85d7c6afbd1dd5280f629976a4e06ba6d88`;
- fixture correnti 8/8 iOS, 56/56 + 7/7 security, 54/54 Flutter e governance
  9/9 verdi ma insufficienti rispetto ai probe avversariali aggiuntivi;
- firma corrotta, archive `ApplicationPath`, digest-esca/parità runtime,
  cut/CMS/UTF-16 JWT+PEM, gate CI/privacy e bound aggregate/JWT da correggere;
- nessun upload, firma reale, profilo reale o mutazione production.
