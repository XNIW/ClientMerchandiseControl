# Evidence TASK-038

Snapshot corrente:
`ACTIVE / FIX / CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Provenance

- Client baseline: `c4ec680ddc0dd1b0537e7c6013f0f5c49e2db894`;
- Admin baseline read-only: `59668348e4c728b44b998c80f1aded61e6114a3f`;
- production: invariata;
- candidate tecnico: `fe8c5824921508086d68fa43f5d658c72b80e2b4`;
- valori legal/store esterni: classificati `NEEDS_OWNER_VALUE`, mai inferiti.

## Execution evidence

### Asset, identity e native privacy

- app/package/bundle: `Client Merchandise Control` e
  `com.xniw.clientmerchandisecontrol`; versione `0.1.0+1` con policy store
  documentata;
- master icon originale 1024×1024 opaco, SHA-256
  `726cd88e7b94c51ffdc2cd9e4bdef25e74b13868aef365bd3326cfbdaa96be48`;
  Google Play 512, cinque densità Android e 19 slot AppIcon iOS validati;
- Android adaptive icon v26, monochrome/themed icon v33 e splash Android 12;
  iOS launch mark vettoriale senza asset Flutter residuo;
- `plutil -lint ios/Runner/PrivacyInfo.xcprivacy`: exit 0; bundle Simulator
  contiene il manifest app con Name, Email Address, Physical Address, User ID,
  Purchase History, Search History e Other User Content, tutti linked,
  App Functionality e tracking false;
- nessuna permission location client; notification prompt e token restano
  fail-closed finché APNs/FCM non è configurato.

### Metadata, legal e configurazione

- metadata Android/iOS, screenshot matrix, review notes, data-safety/app-privacy,
  attribution Maps e licenze OSS versionati in `docs/releases/`;
- legal entity/address/controller, privacy/support/deletion URL, store review
  contacts e dichiarazioni owner-dependent sono `NEEDS_OWNER_VALUE` con owner e
  impatto RC/production, senza identità o claim inventati;
- `config/release_configuration_matrix.json`: 12 capability × development,
  staging, production; ogni cella contiene policy, fallback e validation;
- `scripts/check-release-metadata.sh`: exit 0,
  `RELEASE_METADATA_READY`; test validator 4/4, inclusi secret-shaped config e
  privacy manifest vuoto/incompleto;
- audit bounded: 163 package risolti, 17 dipendenze esterne dirette + 2 SDK;
  33 aggiornamenti incompatibili riportati dal resolver. Nessun update richiesto
  per security, build o store compatibility è stato applicato in TASK-038.

### Gate exact-SHA

Sul candidate tecnico `fe8c582`:

- `scripts/check.sh`: exit 0;
- security source scan: 657 file, 41/41 fixture negative e 4/4 positive;
- telemetry/localization/governance/architecture: PASS, governance 9/9 e
  architecture negative 7/7;
- `dart format`: 291 file, 0 modificati; `flutter analyze`: 0 issue;
- suite non-performance: 768/768 PASS; resilience repeat:
  `5 × 14 = 70/70 PASS`; performance: 10/10 PASS;
- `flutter build apk --debug`: PASS;
- `flutter build ios --simulator --debug`: PASS; warning upstream non bloccante
  `google_maps_flutter_ios` senza supporto Swift Package Manager;
- scan APK: 549 file, nessun secret privilegiato; scan Runner.app: 233 file,
  nessun secret privilegiato;
- Android Emulator arm64: install/launch PASS e Home offline fail-closed visibile;
  iOS Simulator: install/launch PASS e Home offline fail-closed visibile;
- `xcrun xctrace list devices`: due device iOS fisici presenti ma `Offline`;
  `adb devices` tramite SDK: solo `emulator-5554`, nessun Android fisico.

### Security diff-scoped

- scan canonica: `e8233586-d75a-4e1d-9bb7-cb356d544f77`, range
  `c4ec680ddc0dd1b0537e7c6013f0f5c49e2db894..7e02ae1ad4bfda111d8f4c7b8d600431e46a85de`;
- 17 file eseguibili/configurativi revisionati full-file, threat model e supporting
  review; zero finding security reportable;
- tre finding di release review corretti prima dell'handoff: fixture Google-key
  sintetica contigua che bloccava lo scanner, manifest privacy app-owned vuoto e
  percorso locale nell'artwork provenance;
- TASK-033 riutilizzato: nessuna Deep Security Scan repository-wide ripetuta e
  production non modificata.

## Matrice CA -> evidence

| CA | Evidence | Esito |
|---|---|---|
| CA-01 | validator asset/identity, APK e Runner.app build, Emulator/Simulator smoke | PASS |
| CA-02 | plist lint, sette collected types, zero location permission, fail-closed providers | PASS |
| CA-03 | store listing, screenshot matrix, TestFlight/internal notes | PASS |
| CA-04 | capability→data evidence, app+SDK separation, owner approval gate | PASS |
| CA-05 | activation checklist con soli `NEEDS_OWNER_VALUE` reali | PASS |
| CA-06 | dependency/license inventory e Maps attribution | PASS |
| CA-07 | matrice 12×3 e validator/fixture negative | PASS |
| CA-08 | audit dependency/debt bounded e source/artifact scanner | PASS |
| CA-09 | gate dual-platform/security verdi; review indipendente e CI | NOT_RUN |

## Matrice T -> risultato

| Test | Risultato | Evidence |
|---|---|---|
| T-01 | PASS | manifest/plist/project, asset dimension/alpha, build Android/iOS |
| T-02 | PASS | 4/4 validator, mapping privacy, owner template |
| T-03 | PASS | 163 package inventory, license/Maps attribution |
| T-04 | PASS | 12×3 matrix, security fixture 41/41+4/4 |
| T-05 | PASS | outdated e debt scan bounded, nessun helper/secret in release path |
| T-06 | NOT_RUN | review distinta, PR/main exact-SHA e hygiene sono fase successiva |

## Handoff

### Review indipendente

- exact SHA `c7af4ca37ec05e5caabee73906e1844793e430b4`;
- esito `CHANGES_REQUIRED`: 0 P0, 0 P1, 1 P2, 0 P3;
- `F-038-R01`: `p_payment_method` prova la raccolta della forma di pagamento, ma
  manifest, validator ed evidence omettono `NSPrivacyCollectedDataTypePaymentInfo`;
- probe checkout 1/1, `plutil`, validator 4/4 e tutti gli altri gate autonomi
  riprodotti dal reviewer; worktree finale pulito e production invariata.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`; fix limitato a `F-038-R01`. Nessun
`DONE`, merge o attivazione TASK-039 è inferito.
