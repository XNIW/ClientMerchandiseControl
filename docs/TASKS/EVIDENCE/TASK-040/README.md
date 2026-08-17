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
| CA-03 | release app/archive, 4 digest, 7 dSYM e Runner UUID | PASS |
| CA-04 | custom scheme bounded; entitlement/Universal Links/push assenti e bloccati | PASS |
| CA-05 | manifest app byte-identico e 8 privacy manifest app/SDK; exact component inventory da correggere | FAIL |
| CA-06 | security source 681 e app artifact 207; config esterna assente | PASS |
| CA-07 | OAuth/Maps/push/telemetry fail-closed; Maps native sentinel | PASS |
| CA-08 | arm64, Mach-O app/framework e Runner dSYM UUID corrispondente | PASS |
| CA-09 | 0 Distribution/profile/ASC key; upload readiness exit 1 redatto | PASS |
| CA-10 | re-review indipendente e PR/main CI da eseguire | NOT_RUN |

## Matrice T -> risultato

| Test | Esito | Evidence |
|---|---|---|
| T-01 | PASS | source gate, runtime/CI 18/18 e config/signing boundary |
| T-02 | PASS | clean release no-codesign e archive Xcode exact SHA `2523385` |
| T-03 | FAIL | fixture nominale 17/17, ma `Extra.framework` senza manifest è accettato |
| T-04 | PASS | scanner 681/207 e fixture 61/61 + 7/7 |
| T-05 | PASS | inventory redatto e upload gate bloccato sulla Distribution signature |
| T-06a | PASS | Simulator debug integration 1/1 realmente eseguita |
| T-06b | NOT_RUN | Release Simulator non supportato dal comando Flutter release |
| T-06c | BLOCKED | physical iOS offline; prerequisite: device collegato e autorizzato |
| T-07 | FAIL | re-review Fix 6 `CHANGES_REQUIRED`; PR/main CI non eseguite |

## Activation boundary

- signing identity: 1 Apple Development, 0 Apple Distribution;
- provisioning: zero file; App Store Connect API key: zero; env rilevanti: zero;
- App Store Connect access/upload: `NOT_RUN`, prerequisite reali assenti;
- production App Store: vietata;
- physical iOS: `BLOCKED`, zero device collegati; separato dal Simulator.

## Artifact evidence corrente — Fix 6

- source exact SHA: `2523385d65dba7dac4dbdf075173c69260111796`;
- archive: `build/ios/archive/Runner.xcarchive`, 201.344 KiB, non versionato;
- app: 36.724 KiB, 207 file, bundle `com.xniw.clientmerchandisecontrol`,
  `0.1.0 (1)`, `iphoneos`, arm64, unsigned;
- runtime Dart `App.framework/App` SHA-256:
  `2ad06c3f2e0e980ab1907b1ecb353c43e3ce98aad21eb0f02b8fd319f682c336`;
- native wrapper `Runner` SHA-256:
  `7aaa6f37f276f5f458a09772711b8a1c7a0c2cfbf95f6ad85598fe868f5e1928`;
- Info.plist SHA-256:
  `8888ca9f64b9c8f60b6a4a18079131c0db551f0630a6b539ee93b6b9980b3fb8`;
- app PrivacyInfo SHA-256:
  `5dd288d8eda8adac284ea005bb82585023eb82ae5302e26ffc27979a41ba40cd`;
- Runner Mach-O/dSYM UUID `BECE880B-91F5-36D2-AD95-F366FB669F41`;
- archive signing identity/team vuoti; nessuna IPA/export/upload prodotto.

## Gate executor corrente — Fix 6

- `scripts/check.sh`: exit 0;
- non-performance 801/801; performance 10/10; resilience repeat 70/70;
- format 301 file/0 cambi; analyze 0 issue;
- governance 9/9; architecture negative 11/11; localization/telemetry/action pin PASS;
- security source 681; artifact 207; fixture negative 61/61, positive 7/7;
- validator iOS avversariale 17/17, runtime/CI 18/18;
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

## Gate Fix 2

- runtime fix SHA `d4a9edc`, gate governance fix SHA `ae1e3c7`; parser/attestation semantica condivisa fra tool e
  `AppConfig`, firma invalida fail-closed, archive app-set esatto e marker verificato
  nel Mach-O Dart `Frameworks/App.framework/App`;
- test config/governance 39/39, fixture iOS 13/13, scanner fixture 60/60 negative
  + 7/7 positive, source 680, artifact 207, analyze e governance 9/9 `PASS`;
- build production sintetico esterno `PASS`: file canonico bounded, nessun valore reale,
  un solo marker completo nel runtime Dart; file temporaneo rimosso e non versionato;
- clean release/archive canonico dallo SHA tecnico `d4a9edc`: candidate unsigned
  `PASS`, archive 201.344 KiB, app 36.724 KiB/207 file, 8 privacy manifest e 7 dSYM;
- Runner SHA-256
  `7aaa6f37f276f5f458a09772711b8a1c7a0c2cfbf95f6ad85598fe868f5e1928`;
  App.framework SHA-256
  `2ad06c3f2e0e980ab1907b1ecb353c43e3ce98aad21eb0f02b8fd319f682c336`;
  Info.plist `8888ca9f64b9c8f60b6a4a18079131c0db551f0630a6b539ee93b6b9980b3fb8`,
  privacy `5dd288d8eda8adac284ea005bb82585023eb82ae5302e26ffc27979a41ba40cd`;
- Runner/dSYM UUID `BECE880B-91F5-36D2-AD95-F366FB669F41`; signing `UNSIGNED`,
  upload readiness `BLOCKED_DISTRIBUTION_SIGNATURE`; nessuna IPA/upload/production.

## Re-review Fix 2

- exact HEAD `2b7c1480aa7c1e18dfce58abb076cf388b2ed9d2`, worktree pulito;
- prodotto `CHANGES_REQUIRED`: 1 P2, app-set archive aggirabile con `.app` symlink;
- security `CHANGES_REQUIRED`: 3 P3 su JWT source non bounded, file cap tardivo e
  test CI artifact soddisfacibile da step no-op; 0 P0/P1/P2 security;
- report sealed SHA-256
  `083337065a0ad22367124162a36766391f9dabd180f3d6f00b9512835b4f9e28`;
- gate indipendenti 39/39, 13/13, 60/60 + 7/7, governance 9/9 e architecture
  7/7 verdi; insufficienti rispetto ai quattro probe residui;
- nessun upload, firma reale, profilo reale o mutazione production.

## Gate Fix 3

- exact technical SHA `12931389b2692bff5739325946ae48ad0eeff730`;
  `.app` symlink extra, JWT streaming, cap 4.096 entry durante enumerazione, YAML CI
  strutturato, exact-key architecture, single-handle config e privacy schema hanno
  regressioni dedicate;
- config/CI 15/15, iOS validator 15/15, security 61/61 negative + 7/7 positive,
  governance 9/9, architecture 8/8, source 680, artifact 207, analyze e diff check
  `PASS`;
- build production sintetico esterno `PASS`: digest
  `b6d7f55b1f96785f7e4836d45fb11cd58e6aca6282f166660ca09529db0806a6`
  presente una sola volta nel runtime Dart; fixture eliminata e non versionata;
- clean release/archive canonico: 201.344 KiB, app 36.724 KiB/207 file,
  8 privacy manifest, 7 dSYM; runtime SHA-256
  `2ad06c3f2e0e980ab1907b1ecb353c43e3ce98aad21eb0f02b8fd319f682c336`,
  wrapper SHA-256
  `caa81fa3e2c0a067b4ecbf91f83267fb7dba6c95d54da27bf4022ced821f142c`,
  Info.plist `8888ca9f64b9c8f60b6a4a18079131c0db551f0630a6b539ee93b6b9980b3fb8`,
  privacy `5dd288d8eda8adac284ea005bb82585023eb82ae5302e26ffc27979a41ba40cd`
  e UUID app/dSYM `F278496B-FCCE-3ADD-A310-7E94973B62D0`;
- `scripts/check.sh` exit 0: 798/798 non-performance, 10/10 performance,
  repeat 70/70, format 300/0, Android debug e iOS Simulator debug;
- signing `UNSIGNED`, upload gate exit 1
  `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`; Distribution 0, profili 0,
  App Store Connect input 0/3. Device iOS fisici offline, quindi physical smoke
  `BLOCKED`; nessuna IPA, firma, config reale, upload o production mutation.

## Re-review Fix 3

- exact HEAD `ed0dc628dff7f904d47d214218662d2c2ff587ed`, worktree pulito;
- prodotto `CHANGES_REQUIRED`: 2 P3 su privacy nested e execution controls YAML;
- security `CHANGES_REQUIRED`: 4 P3 su YAML, comment decoy, privacy nested e FIFO;
  governance separata 1 P3 su evidence storica non qualificata; totale unificato
  0 P0/P1/P2 e 5 P3;
- report security sealed SHA-256
  `5ba397a40bbfb3ce7d9690deb6a147541f611f2e7f626ef4afaffa7d72167786`;
- `.app` symlink, JWT streaming, preventive entry cap e runtime hash confermati
  chiusi; gate 61/61 + 7/7, 15/15 iOS, 15/15 config/CI, 8/8 architecture e
  9/9 governance verdi ma insufficienti per i probe residui;
- nessun upload, firma reale, profilo, config reale o mutation production.

## Gate Fix 4

- exact technical SHA `16f29012e89170a0de2c9b348ec134c4d495b33d`;
  execution controls `if`/`continue-on-error`/`shell`, comment decoy del binding,
  privacy manifest nested incompleto e FIFO canonico sono respinti da regressioni
  sul boundary reale;
- mirati `PASS`: runtime/CI 17/17, iOS release fixture 15/15, architecture 9/9,
  source/artifact validator 680/207 e `flutter analyze` senza issue;
- `scripts/check.sh` exit 0: 800/800 non-performance, 10/10 performance,
  resilience repeat 5×14=70/70, format 300/0, Android debug e iOS Simulator
  debug build `PASS`;
- clean release no-codesign e archive exact-SHA `PASS`: 201.344 KiB,
  app 36.724 KiB/207 file, 8 privacy manifest, 7 dSYM, runtime SHA-256
  `2ad06c3f2e0e980ab1907b1ecb353c43e3ce98aad21eb0f02b8fd319f682c336`,
  wrapper SHA-256
  `7aaa6f37f276f5f458a09772711b8a1c7a0c2cfbf95f6ad85598fe868f5e1928`
  e UUID app/dSYM `BECE880B-91F5-36D2-AD95-F366FB669F41`;
- upload gate exit 1 `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`; zero
  Distribution, profili o input App Store Connect, nessuna IPA/upload/production;
- la sezione Artifact evidence e il gate corrente sono riallineati al Fix 4;
  blocchi Fix 1–3 restano esplicitamente storici.

## Re-review Fix 4

- exact HEAD `6139063623ea6395ec0beca808990739b2fa3792`, worktree pulito;
- prodotto/security `CHANGES_REQUIRED`: 0 P0/P1/P2 e 5 P3 unificati su
  workflow-level override, lexer Dart, allowlist Apple, race regular→FIFO e digest
  evidence wrapper;
- report security sealed SHA-256
  `0e98a5c4dd7faf79571002b7edad4b4bb5624449dbb7eb3961e941de024762df`;
- closure `{}` privacy, job/step modifier locali, FIFO statica, app-set/signature e
  runtime binding preservate; gate nominali 17/17, 9/9, 15/15 e 680/207 verdi ma
  insufficienti rispetto ai nuovi PoC;
- nessun upload, firma, profilo, config reale o mutation production.

## Gate Fix 5

- exact technical SHA `ae452c6b10a9b69c9535476c02b01d8ed3ec74b5`;
  root/job/step CI allowlisted, AST Dart reale, allowlist Apple esatta,
  single-descriptor nonblocking runtime config e prerequisito `python3` hanno
  regressioni sul boundary reale;
- mirati `PASS`: runtime/CI 17/17, iOS release fixture 16/16, architecture 10/10,
  source/artifact validator 681/207 e `flutter analyze` senza issue;
- `scripts/check.sh` exit 0: 800/800 non-performance, 10/10 performance,
  resilience repeat 5x14=70/70, format 301/0, Android debug e iOS Simulator
  debug build `PASS`;
- clean release no-codesign e archive exact-SHA `PASS`: 201.344 KiB,
  app 36.724 KiB/207 file, 8 privacy manifest, 7 dSYM, runtime SHA-256
  `2ad06c3f2e0e980ab1907b1ecb353c43e3ce98aad21eb0f02b8fd319f682c336`,
  wrapper SHA-256
  `7aaa6f37f276f5f458a09772711b8a1c7a0c2cfbf95f6ad85598fe868f5e1928`,
  Info.plist `8888ca9f64b9c8f60b6a4a18079131c0db551f0630a6b539ee93b6b9980b3fb8`,
  privacy `5dd288d8eda8adac284ea005bb82585023eb82ae5302e26ffc27979a41ba40cd`
  e UUID app/dSYM `BECE880B-91F5-36D2-AD95-F366FB669F41`;
- upload gate exit 1 `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`; zero
  Distribution, profili o input App Store Connect, nessuna IPA/upload/production;
- il digest wrapper Fix 4 è stato corretto al valore fisico verificato; gli altri
  blocchi Fix 1-4 restano esplicitamente storici.

## Re-review Fix 5

- exact HEAD `354fd2442190cf172e41adf1070e94cb8d31cd5b`, worktree pulito;
- prodotto `CHANGES_REQUIRED`: un P3 sul field AST non vincolato alla classe
  `AppConfig`;
- security `CHANGES_REQUIRED`: tre P3 complessivi su ownership AST,
  ancestor-symlink TOCTOU e manifest privacy Google Maps sostituibile con un plist
  legittimo ma vuoto; 0 P0/P1/P2;
- report security sealed SHA-256
  `47444ae52e31ad64aa40ac1ffb3828bd56897c93d00f6178cab739cfdf35e346`;
- i cinque finding Fix 4 sono chiusi; gate 681/207, 61/61 + 7/7, 10/10,
  17/17 e 16/16 verdi ma insufficienti rispetto ai tre PoC aggiuntivi;
- nessun upload, firma, profilo, config reale o mutation production.

## Gate Fix 6

- exact technical SHA `2523385d65dba7dac4dbdf075173c69260111796`;
  declaration/consumer AST, ancestor component walk e digest semantico privacy
  per-SDK hanno regressioni sul boundary reale;
- mirati `PASS`: runtime/CI 18/18 con 30 race attempt, iOS release 17/17,
  architecture 11/11, source/artifact validator 681/207 e analyze senza issue;
- `scripts/check.sh` exit 0: 801/801 non-performance, 10/10 performance,
  resilience repeat 5x14=70/70, format 301/0, Android debug e iOS Simulator
  debug build `PASS`;
- clean release no-codesign e archive exact-SHA `PASS`: 201.344 KiB,
  app 36.724 KiB/207 file, 8 privacy manifest, 7 dSYM, runtime SHA-256
  `2ad06c3f2e0e980ab1907b1ecb353c43e3ce98aad21eb0f02b8fd319f682c336`,
  wrapper SHA-256
  `7aaa6f37f276f5f458a09772711b8a1c7a0c2cfbf95f6ad85598fe868f5e1928`,
  Info.plist `8888ca9f64b9c8f60b6a4a18079131c0db551f0630a6b539ee93b6b9980b3fb8`,
  privacy `5dd288d8eda8adac284ea005bb82585023eb82ae5302e26ffc27979a41ba40cd`
  e UUID app/dSYM `BECE880B-91F5-36D2-AD95-F366FB669F41`;
- upload gate exit 1 `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`; zero
  Distribution, profili o input App Store Connect, nessuna IPA/upload/production.

## Re-review Fix 6

- exact HEAD `74f65036f7cd295e09fb457e21c804f26e49d70b`, worktree pulito;
- prodotto/security `CHANGES_REQUIRED`: 0 P0/P1/P2 e 2 P3 unificati;
- `F-040-RR6-01`: i consumer AST sono name-bound, non symbol-bound; un parametro
  formale omonimo del factory ombreggia il field canonico e il gate resta verde;
- `F-040-PRIV-01`: l'inventory framework/bundle non è exact; `Extra.framework`
  Mach-O senza privacy manifest raggiunge `IOS_RELEASE_CANDIDATE_VALID`;
- ancestor-symlink TOCTOU e Google Maps empty-manifest sono confermati chiusi;
- gate completi nominali `PASS`: 801/801 non-performance, 10/10 performance,
  repeat 70/70, source/artifact 681/207, fixture security 61/61 + 7/7,
  architecture 11/11, runtime/CI 18/18 e iOS 17/17;
- report prodotto sealed SHA-256
  `32b79e76daec872db0be080ebe06bf1bb58153518a8356a1f40bdb8fb3a12fe9`
  e report security canonico sealed SHA-256
  `3765b04359849bed1fd2d6bb0a95376d2d7974db2fd6fb3d79ec85044b573baa`;
- nessuna firma, IPA, upload, credenziale o mutazione production.
