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
| CA-10 | review indipendente e PR/main CI da eseguire | NOT_RUN |

## Matrice T -> risultato

| Test | Esito | Evidence |
|---|---|---|
| T-01 | PASS | source gate + 6 governance test + config/signing boundary |
| T-02 | PASS | clean release no-codesign e archive Xcode exact SHA `4c4db2a` |
| T-03 | PASS | plist/privacy/entitlement/framework/dSYM artifact validator |
| T-04 | PASS | scanner 676/207 e fixture 52/52 + 6/6 |
| T-05 | PASS | inventory redatto e upload gate bloccato sulla Distribution signature |
| T-06a | PASS | Simulator debug integration 1/1 realmente eseguita |
| T-06b | NOT_RUN | Release Simulator non supportato dal comando Flutter release |
| T-06c | BLOCKED | physical iOS assente; prerequisite: device collegato e autorizzato |
| T-07 | NOT_RUN | review, PR/main CI e hygiene non iniziate |

## Activation boundary

- signing identity: 1 Apple Development, 0 Apple Distribution;
- provisioning: zero file; App Store Connect API key: zero; env rilevanti: zero;
- App Store Connect access/upload: `NOT_RUN`, prerequisite reali assenti;
- production App Store: vietata;
- physical iOS: `BLOCKED`, zero device collegati; separato dal Simulator.

## Artifact evidence

- source exact SHA: `4c4db2a82ddb276066763fcdb24227bbf2937a4f`;
- archive: `build/ios/archive/Runner.xcarchive`, 201.328 KiB, non versionato;
- app: 36.708 KiB, 207 file, bundle `com.xniw.clientmerchandisecontrol`,
  `0.1.0 (1)`, `iphoneos`, arm64, unsigned;
- executable SHA-256:
  `7aaa6f37f276f5f458a09772711b8a1c7a0c2cfbf95f6ad85598fe868f5e1928`;
- Info.plist SHA-256:
  `8888ca9f64b9c8f60b6a4a18079131c0db551f0630a6b539ee93b6b9980b3fb8`;
- app PrivacyInfo SHA-256:
  `5dd288d8eda8adac284ea005bb82585023eb82ae5302e26ffc27979a41ba40cd`;
- Runner Mach-O/dSYM UUID `BECE880B-91F5-36D2-AD95-F366FB669F41`;
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
