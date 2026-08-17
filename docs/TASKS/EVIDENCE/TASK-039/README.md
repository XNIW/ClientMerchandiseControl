# Evidence TASK-039

Snapshot di handoff:
`ACTIVE / REVIEW / CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

## Provenance

- Client baseline: `ce2ab1343d183cb7d64345711902714b1db69ca1`;
- Admin baseline read-only: `59668348e4c728b44b998c80f1aded61e6114a3f`;
- TASK-038 PR #17 e PR/main CI exact-SHA verdi;
- production e Play Console: invariati al bootstrap.

## Matrice CA -> evidence

| CA | Evidence | Esito |
|---|---|---|
| CA-01 | signing all-or-none Gradle + validator negative partial/missing keystore | PASS |
| CA-02 | clean AAB exact-SHA, manifest protobuf diretto, package/version e SHA-256 | PASS |
| CA-03 | R8 JSON: obfuscation/optimization/shrinking true, debug false; 3 ABI | PASS |
| CA-04 | manifest compilato, cleartext false, exported/permission guard; HTTPS App Link owner-dependent separato | PASS |
| CA-05 | source/artifact scanner 671/285, payload, metadata per-entry e container ZIP inclusi | PASS |
| CA-06 | Maps/OAuth/notification/telemetry fail-closed; config e test mirati | PASS |
| CA-07 | probe credenziali vuoto e upload readiness blocked su signed AAB richiesto | PASS |
| CA-08 | review iniziale distinta conclusa; re-review e PR/main exact-SHA | NOT_RUN |

## Matrice T -> risultato

| Test | Risultato | Evidence |
|---|---|---|
| T-01 | PASS | validator; entry post-sign, multi-signer, `/dev/null`, JSON/account/progetto/signer errati exit 1 redatti |
| T-02 | PASS | clean appbundle/APK, manifest AAB protobuf, payload ABI e firma APK v2-only |
| T-03 | PASS | manifest AAB+APK con allowlist esatta, network policy e archive scan payload/metadata/container 285 file |
| T-04 | PASS | no credential file/env/GitHub secret/var; Internal upload `NOT_RUN` corretto |
| T-05 | NOT_RUN | review indipendente, PR/main CI e hygiene sono fase successiva |

## Artifact evidence exact-SHA

- SHA sorgente tecnico: `4f2e6867649374f4b93b581475560c2a6ae5de50`;
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

## Fix evidence

- clean AAB/APK rigenerati sullo SHA tecnico `6b4a79d…b3e1b49`, con SHA-256
  byte-identici al candidato precedente e nuova validazione diretta AAB;
- scanner source 671; scanner artifact 281 file estratti; fixture security
  42/42 negative e 5/5 positive, incluso AAB DEFLATED;
- manifest protobuf AAB e Play credential validator: 10/10 mirati;
- fixture integrazione: AAB JAR-signed + APK v1 false/v2 true, signer coerente,
  `/dev/null` e account diverso respinti, input coerenti accettati;
- `scripts/check.sh`: exit 0; 779/779 non-performance, 10/10 performance,
  repeat TASK-034 5×14=70/70, format 296/0, analyze zero issue, build debug
  Android e iOS Simulator `PASS`;
- firma reale, identità Play e upload Internal restano `NOT_RUN`: credenziali
  esterne assenti, production invariata.

## Security Fix 2 evidence

- clean AAB/APK release sullo SHA `35a60a0…a1a210`, SHA-256 e dimensioni
  byte-identici: `6c321e2f…a84718` / 67.773.321 byte e
  `82ee832f…b91ce` / 70.137.338 byte;
- `jarsigner -strict` per-entry e singolo signer: fixture post-sign e
  multi-signer respinte; AAB JAR-signed più APK v2-only coerente accettato;
- scanner content-based: `.bundle`, `.AAB`, extensionless, entry name e commento
  secret-shaped respinti; 47/47 negative e 5/5 positive;
- allowlist AAB: tre permission canoniche, permission custom `signature` e due
  exported approvati; fixture `READ_SMS` e service esportato respinte;
- validator reale: source 671, artifact 283, package/version/ABI/firma/SHA
  coerenti, `ANDROID_RELEASE_CANDIDATE_READY_UNSIGNED`;
- `scripts/check.sh`: 781/781 non-performance, 10/10 performance, repeat
  5×14=70/70, format 296/0, analyze e build debug Android/iOS `PASS`.

## Security Fix 3 evidence

- clean AAB/APK release sullo SHA tecnico `4f2e686…e5de50`, byte-identici:
  `6c321e2f…a84718` / 67.773.321 byte e `82ee832f…b91ce` /
  70.137.338 byte;
- signature set case-insensitive: secondo block `.rSa`, firma parziale e
  multi-signer respinti; AAB singolo signer più APK v2-only coerente accettato;
- scanner preflight prima dell'estrazione: cap 2.048 entry, 512 MiB
  compressed/uncompressed, rapporto 200× e metadata 4 MiB; commento per-entry,
  archive sovra-espanso e archive con 2.049 entry respinti;
- alias manifest `uses-permission-sdk-23` e `uses-permission-sdk-m` respinti;
  validator manifest 5/5 e fixture security 50/50 negative + 5/5 positive;
- validator release reale: source 671, artifact 285, package/version/ABI/firma
  e SHA coerenti, `ANDROID_RELEASE_CANDIDATE_READY_UNSIGNED`;
- `scripts/check.sh`: exit 0; 782/782 non-performance, 10/10 performance,
  repeat 5×14=70/70, format 296/0, analyze, Android debug e iOS Simulator
  debug `PASS`.

## Security Fix 4 evidence

- SHA tecnico `e7cb2d970cb987267a2cce9f23a187e2bc712f25`;
- stream aggregato decompresso con cap 512 MiB prima di test/estrazione;
  byte effettivi, size dichiarata e rapporto 200× devono essere coerenti;
- fixture forged: archive 16.457 byte, dichiarato 2.000.000/16.285 byte,
  output reale 16.777.216 byte, scanner exit 1 con output redatto;
- fixture security 51/51 negative + 5/5 positive; validator reale source 671
  e artifact 285, firma unsigned e SHA artifact invariati;
- `scripts/check.sh` exit 0: 782/782 non-performance, 10/10 performance,
  repeat 70/70, format 296/0, analyze e build debug Android/iOS `PASS`;
  fixture firma avversariale `PASS`.

## Handoff

La Security Fix 4 sullo SHA tecnico
`e7cb2d970cb987267a2cce9f23a187e2bc712f25` chiude il PoC di
`F-039-SR06` con un bound sui byte effettivamente emessi e regressione
forged-header. Handoff corrente `CODEX_FIX_COMPLETE_TO_RE_REVIEW`;
Play/Internal e production restano invariati.
