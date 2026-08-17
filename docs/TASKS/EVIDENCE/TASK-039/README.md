# Evidence TASK-039

Snapshot di handoff:
`ACTIVE / REVIEW / CODEX_EXECUTION_COMPLETE_TO_REVIEW`.

## Provenance

- Client baseline: `ce2ab1343d183cb7d64345711902714b1db69ca1`;
- Admin baseline read-only: `59668348e4c728b44b998c80f1aded61e6114a3f`;
- TASK-038 PR #17 e PR/main CI exact-SHA verdi;
- production e Play Console: invariati al bootstrap.

## Matrice CA -> evidence

| CA | Evidence | Esito |
|---|---|---|
| CA-01 | signing all-or-none Gradle + validator negative partial/missing keystore | PASS |
| CA-02 | clean AAB 67.773.321 byte, package/version e SHA-256 | PASS |
| CA-03 | R8 JSON: obfuscation/optimization/shrinking true, debug false; 3 ABI | PASS |
| CA-04 | manifest compilato, cleartext false, exported/permission guard; HTTPS App Link owner-dependent separato | PASS |
| CA-05 | source/artifact scanner 666/132 e config production-like pubblica | PASS |
| CA-06 | Maps/OAuth/notification/telemetry fail-closed; config e test mirati | PASS |
| CA-07 | probe credenziali vuoto e upload readiness blocked su signed AAB richiesto | PASS |
| CA-08 | review distinta e PR/main exact-SHA | NOT_RUN |

## Matrice T -> risultato

| Test | Risultato | Evidence |
|---|---|---|
| T-01 | PASS | source validator; partial signing e missing keystore exit 1 redatti |
| T-02 | PASS | clean appbundle/APK, R8 mapping, package 0.1.0+1 e ABI |
| T-03 | PASS | apkanalyzer manifest, debuggable false, network policy e artifact scan |
| T-04 | PASS | no credential file/env/GitHub secret/var; Internal upload `NOT_RUN` corretto |
| T-05 | NOT_RUN | review indipendente, PR/main CI e hygiene sono fase successiva |

## Artifact evidence exact-SHA

- SHA sorgente: `6b878f35aebfe0e98fa305c624747711fd81f1b0`;
- AAB: `build/app/outputs/bundle/release/app-release.aab`, non versionato,
  SHA-256 `6c321e2fcafcf4cd3a7044f366ebaa5c1c2d0e41e2a84c425e931a1b76a84718`;
- APK inspection: `build/app/outputs/flutter-apk/app-release.apk`, non
  versionato, SHA-256
  `82ee832fb88d64eef3d04e0a8f4a5a7f4ddcaf0a2fb13efcfea82bfee81b91ce`;
- package/version: `com.xniw.clientmerchandisecontrol`, `0.1.0+1`;
- min/target SDK: 24/36; ABI: arm64-v8a, armeabi-v7a, x86_64;
- permission: INTERNET, ACCESS_NETWORK_STATE e dynamic receiver permission
  signature-scoped; nessuna location o notification permission;
- Maps manifest sentinel `NOT_CONFIGURED`, Dart flags false; no capability
  attivata dal sentinel;
- signing: `UNSIGNED`; install emulator `NOT_RUN` per assenza certificato,
  tentativo tecnico respinto con `INSTALL_PARSE_FAILED_NO_CERTIFICATES`;
- Play/Internal: `NOT_RUN`, mancano upload signing e identità Play scoped;
- production, store track e backend: invariati.

## Gate executor

- `scripts/check.sh`: exit 0 sul candidate tecnico;
- non-performance 772/772; performance 10/10; repeat 5×14=70/70;
- format 292 file/0 cambi; analyze 0 issue;
- metadata, telemetry, localization, governance 9/9 e architecture 7/7 PASS;
- security: source 666, fixture 41/41 + 4/4, artifact 132, zero vietati;
- Android debug e iOS Simulator debug build PASS;
- AAB/APK release puliti e `check-android-release.sh` PASS.

## Handoff

`CODEX_EXECUTION_COMPLETE_TO_REVIEW`; reviewer distinto deve validare diff,
artifact e classificazione
`TECHNICALLY_COMPLETE_EXTERNAL_CREDENTIAL_REQUIRED` prima di PR/merge.
