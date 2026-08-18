# Evidence TASK-040

Snapshot di handoff:
`ACTIVE / REVIEW / CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

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
| CA-05 | manifest app byte-identico, 8 privacy manifest e inventory recursive exact 4 framework/9 bundle | PASS |
| CA-06 | security source 682 e app artifact 207; config esterna assente | PASS |
| CA-07 | OAuth/Maps/push/telemetry fail-closed; Maps native sentinel | PASS |
| CA-08 | arm64, Mach-O app/framework e Runner dSYM UUID corrispondente | PASS |
| CA-09 | 0 Distribution/profile/ASC key; upload readiness exit 1 redatto | PASS |
| CA-10 | re-review indipendente e PR/main CI da eseguire | NOT_RUN |

## Matrice T -> risultato

| Test | Esito | Evidence |
|---|---|---|
| T-01 | PASS | source gate, runtime/CI 18/18 e config/signing boundary |
| T-02 | PASS | clean release no-codesign e archive Xcode exact SHA `01dd140` |
| T-03 | PASS | plist/privacy/inventory framework+bundle+dylib/dSYM + fixture iOS 29/29 |
| T-04 | PASS | scanner 682/207 e fixture 61/61 + 7/7 |
| T-05 | PASS | inventory redatto e upload gate bloccato sulla Distribution signature |
| T-06a | PASS | Simulator debug integration 1/1 realmente eseguita |
| T-06b | NOT_RUN | Release Simulator non supportato dal comando Flutter release |
| T-06c | BLOCKED | physical iOS offline; prerequisite: device collegato e autorizzato |
| T-07 | NOT_RUN | Fix 17 handoff pronto; re-review, PR/main CI e hygiene da eseguire |

## Activation boundary

- signing identity: 1 Apple Development, 0 Apple Distribution;
- provisioning: zero file; App Store Connect API key: zero; env rilevanti: zero;
- App Store Connect access/upload: `NOT_RUN`, prerequisite reali assenti;
- production App Store: vietata;
- physical iOS: `BLOCKED`, zero device collegati; separato dal Simulator.

## Artifact evidence corrente — Fix 10

- source exact SHA: `01dd140852733c14ae53d067e7454458cababe19`;
- archive: `build/ios/archive/Runner.xcarchive`, 201.344 KiB, non versionato;
- app: 36.724 KiB, 207 file, bundle `com.xniw.clientmerchandisecontrol`,
  `0.1.0 (1)`, `iphoneos`, arm64, unsigned;
- runtime Dart `App.framework/App` SHA-256:
  `2ad06c3f2e0e980ab1907b1ecb353c43e3ce98aad21eb0f02b8fd319f682c336`;
- native wrapper `Runner` SHA-256:
  `caa81fa3e2c0a067b4ecbf91f83267fb7dba6c95d54da27bf4022ced821f142c`;
- Info.plist SHA-256:
  `8888ca9f64b9c8f60b6a4a18079131c0db551f0630a6b539ee93b6b9980b3fb8`;
- app PrivacyInfo SHA-256:
  `5dd288d8eda8adac284ea005bb82585023eb82ae5302e26ffc27979a41ba40cd`;
- Runner Mach-O/dSYM UUID `F278496B-FCCE-3ADD-A310-7E94973B62D0`;
- archive signing identity/team vuoti; nessuna IPA/export/upload prodotto.

## Gate executor corrente — Fix 17

- `scripts/check.sh`: exit 0;
- non-performance 801/801; performance 10/10; resilience repeat 70/70;
- format 301 file/0 cambi; analyze 0 issue;
- governance 88/88; architecture negative 17/17; localization/telemetry/action pin PASS;
- security source 682; artifact 207; fixture negative 61/61, positive 7/7;
- validator iOS avversariale 29/29 già invariato; governance mirata 88/88;
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

## Gate Fix 7

- exact technical SHA `d94b071b3c916a914c9db87cd588621feee4e75d`;
  consumer AST semanticamente legati al field `AppConfig` e inventory exact di
  quattro framework/sette bundle hanno regressioni sui due PoC reali;
- mirati `PASS`: architecture 12/12, iOS release fixture 18/18, runtime/CI
  18/18, source/artifact validator 681/207 e analyze senza issue;
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
  Distribution/profili/input App Store Connect, physical iOS offline, nessuna
  IPA/upload/production.

## Re-review Fix 7

- exact HEAD `189c5e74fb3f32d76a6e8bffb87ca6a95e791fed`, worktree pulito;
- esito indipendente `CHANGES_REQUIRED`: 0 P0/P1/P2 e 4 P3;
- `F-040-RR7-ARCH-01`: initializer accetta un costruttore omonimo non
  `dart:core String.fromEnvironment`;
- `F-040-RR7-ARCH-02`: consumer canonici irraggiungibili possono attestare un
  percorso reale dinamico/non canonico;
- `F-040-RR6-PRIV-01`: casing, nesting, dylib e sostituzione di componenti sotto
  nomi allowlisted non sono coperti dall'inventory shallow;
- `F-040-RR7-GOV-01`: le sezioni evidence correnti sono ancora associate a Fix 6;
- report security sealed SHA-256
  `fbd804ea9d7057f6c300f4ea91a59439e7327871c287bec4e9f950b27cb99bf2`;
  report prodotto sealed SHA-256
  `a1a49bdd9744478abd024fe71d4976f731ad1d7d5fa4cf80d452d65c208d743d`;
- TestFlight, store, signing e production invariati.

## Gate Fix 8

- exact technical SHA `41f5cbab7c60ee872a1e2f5ef591e16c18e89b6e`;
- `F-040-RR7-ARCH-01` chiuso: l'initializer è legato al `ConstructorElement`
  const di `dart:core String.fromEnvironment`; extension type omonima respinta;
- `F-040-RR7-ARCH-02` chiuso: factory con quattro statement canonici, constructor/
  method target risolti, set argomenti/mappe exact e due soli riferimenti al field;
  consumer irraggiungibili + percorso dinamico respinti;
- `F-040-RR6-PRIV-01` chiuso: inventory recursive case-insensitive, zero dylib,
  directory reali e identità framework/bundle legata a executable, bundle ID,
  install name e simboli distintivi; casing/nesting/replacement/dylib respinti;
- `F-040-RR7-GOV-01` chiuso: le sezioni correnti riportano Fix 8, SHA e conteggi
  realmente eseguiti;
- mirati `PASS`: architecture 14/14, iOS release 23/23, config/governance 36/36,
  runtime/CI 18/18, source/artifact 681/207 e analyze senza issue;
- `scripts/check.sh` exit 0: 801/801 non-performance, performance 10/10,
  resilience repeat 5x14=70/70, format 301/0, Android debug e iOS Simulator debug;
- clean release/archive exact-SHA `PASS`: 201.344 KiB, app 36.724 KiB/207 file,
  8 privacy manifest, 7 dSYM, runtime/wrapper/Info/privacy hash invariati e UUID
  app/dSYM `BECE880B-91F5-36D2-AD95-F366FB669F41`;
- upload gate exit 1 `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`: 0 Distribution,
  0 profili, 0 input ASC; iPhone fisico offline, nessun upload/production.

## Re-review Fix 8

- exact HEAD `e88f8762aab52ad7b176cbc0e0bd80b23d2aaf43`, worktree pulito;
- esito security `CHANGES_REQUIRED`: 0 P0/P1, 2 P2 e 2 P3;
- `F-040-RR8-ARCH-CONFIG-01` P2: i sette input config e gli otto input
  attestation non sono tutti legati agli stessi field compile-time;
- `F-040-RR8-ARCH-CONTROL-01` P2: guard/try shape-only consente un return
  alternativo prima dell'attestation;
- `F-040-RR8-ARCH-02` P3: l'identità library usa un suffisso collidibile;
- `F-040-RR8-PRIV-01/02` P3: Mach-O extensionless e contenuto framework/bundle
  mutato mantengono metadata validi e raggiungono candidate-valid;
- `F-040-RR8-GOV-01` P3: fixture constructor non analyzer-clean e worklog tail
  non cronologico;
- report security canonico sealed SHA-256
  `169a5154053c28503744c0de8a8d2a9c923520062e339e28d93b038a83df8f84`;
  report prodotto sealed SHA-256
  `877c30e186d5bd38da82639a023021a3da117defeb63d93d2c6167bc715b92ca`;
- upload/TestFlight/production invariati.

## Gate Fix 9

- exact technical SHA `34d342b38b41d73cfe590b2cfe5defd5aab6be40`;
  i nove field compile-time, sette consumer, otto input attestation e il control flow
  production sono legati agli elementi canonici dal resolved AST;
- exact content provenance su cinque Mach-O e nove bundle; build Flutter e archive
  hanno due wrapper digest deterministici allowlisted, il wrapper Runner è
  byte-identico tra i due archive e i payload normalizzati coincidono; i contenitori
  archive differiscono correttamente nel `CreationDate` di `Info.plist`;
- mirati `PASS`: config/governance 44/44, architecture 17/17, iOS release fixture
  26/26, source/artifact validator 681/207, security 61/61 negative + 7/7 positive;
- `scripts/check.sh` exit 0 sullo SHA corrente: 801/801 non-performance,
  performance 10/10, repeat 5x14=70/70, governance 10/10, format 301/0,
  analyze e build debug Android/iOS;
- clean release/archive no-codesign: 201.344 KiB, app 36.724 KiB/207 file,
  8 privacy manifest, 7 dSYM, runtime SHA-256
  `2ad06c3f2e0e980ab1907b1ecb353c43e3ce98aad21eb0f02b8fd319f682c336`,
  wrapper SHA-256
  `caa81fa3e2c0a067b4ecbf91f83267fb7dba6c95d54da27bf4022ced821f142c`,
  Info.plist `8888ca9f64b9c8f60b6a4a18079131c0db551f0630a6b539ee93b6b9980b3fb8`,
  privacy `5dd288d8eda8adac284ea005bb82585023eb82ae5302e26ffc27979a41ba40cd`
  e UUID app/dSYM `F278496B-FCCE-3ADD-A310-7E94973B62D0`;
- upload gate exit 1 `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`; 0 Distribution,
  0 provisioning e 0/3 input ASC; device fisici offline, nessuna IPA, firma,
  TestFlight o mutazione production.

## Re-review Fix 9

- exact HEAD `b5b9ac64299f0dc79f8b43970ca98937cd71c670`, worktree pulito;
- esito security `CHANGES_REQUIRED`: 0 P0/P1, 1 P2 e 2 P3; report sealed
  SHA-256 `8d346f407851cd9312518984b8a807d0973754fd80a5324226bf87a40d51a5a3`;
- `F-040-RR9-IOS-01`: digest section-only non copre header/load command/
  `__LINKEDIT`; flag PIE/stack-exec e dipendenza dylib alterati passano il gate;
- `F-040-RR9-GOV-01/02`: manifest/matrice T e tail task non sono allineati a Fix 9;
- review prodotto conferma il root Mach-O e corregge la claim: wrapper/digest sono
  ripetibili, non l'archive plist timestamped byte-per-byte;
- CONFIG/CONTROL/library identity, inventory Mach-O/bundle e worklog chronology
  restano chiusi; architecture 17/17, iOS 26/26, config 44/44 e governance 10/10
  verdi ma insufficienti rispetto ai nuovi probe;
- nessun upload, signing esterno, profilo, credenziale o mutazione production.

## Gate Fix 10

- technical SHA finale
  `da83b266bf6298c5a869b74cd271782782c7b4ef`; clean release/archive app-source
  SHA `01dd140852733c14ae53d067e7454458cababe19`;
- attestazione whole-Mach-O dopo normalizzazione della sola firma: header,
  load command, sezioni e `__LINKEDIT` sono nel digest; i due output exact-content
  `objective_c` osservati prima/dopo clean restano allowlisted per SHA completo;
- regression `MH_PIE`, `MH_ALLOW_STACK_EXECUTION` e `LC_LOAD_DYLIB`, oltre alle
  fixture preesistenti, `29/29 PASS`;
- governance reale e fixture `15/15 PASS`: manifest status/revision/gate, tail
  Fix/handoff e matrici T-02/T-03 sono correlate alle sezioni evidence correnti;
- `scripts/check.sh` sullo SHA finale: 801/801, performance 10/10, repeat 70/70,
  security 681 + 61/61 + 7/7, architecture 17/17, format 301/0, analyze e build
  debug Android/iOS `PASS`;
- archive unsigned 201.344 KiB, app 36.724 KiB/207 file, 8 privacy manifest,
  7 dSYM, runtime/wrapper/Info/privacy SHA invariati e UUID app/dSYM
  `F278496B-FCCE-3ADD-A310-7E94973B62D0`;
- candidate validator `PASS`; upload gate exit 1
  `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`; credenziali/IPA/upload/production
  invariati.

## Re-review Fix 10

- exact HEAD `a85d60774212f212d3ee8dd274db99af011925c8`, worktree pulito;
- prodotto/security `CHANGES_REQUIRED`: 0 P0/P1/P2 e 2 P3 governance;
- manifest e matrici T first-match/substrings accettano duplicati, `FAIL` e
  `Fix 100`; chronology task opzionale/comment-aware e ordine storico ambiguo;
- attestazione iOS Fix 10 chiusa: 29/29, tamper Mach-O e firma corrotta respinti,
  scanner 681/207 + 61/61 negative + 7/7 positive;
- report security sealed SHA-256
  `10deb98767cac73818233dc9f073934c31c7a81d0768c4fa68f82b5dfbef1837`;
- nessun upload, firma esterna, profilo, credenziale o mutazione production.

## Gate Fix 11

- technical SHA `32017f34bc840e384fdd4e5023727027cb9ec0cf`;
- cardinalità manifest/T-02/T-03, colonne e stato `PASS`, token Fix completo,
  chronology obbligatoria/sequenziale e comment-free;
- blocchi task Fix 1–10 riordinati nella successione canonica;
- governance fixture 26/26: duplicate/righe non canoniche, `FAIL`, `Fix 100`,
  revisioni non-prefix, chronology assente/fuori sezione/fuori ordine e
  comment-decoy sono respinti;
- `scripts/check.sh` exact-SHA exit 0: 801/801, performance 10/10, repeat 70/70,
  security 681 + 61/61 + 7/7, architecture 17/17, format 301/0, analyze e
  build debug Android/iOS `PASS`;
- nessun delta runtime/artifact/signing; TestFlight e production invariati.

## Re-review Fix 11

- exact HEAD `0fec3ab0f4af8747e82695bc97e4cf61b8799114`, worktree pulito;
- prodotto e security `CHANGES_REQUIRED`: 0 P0/P1/P2 e 3 P3 governance;
- `F-040-RR11-GOV-MARKDOWN-01`: righe non-table/code block, commenti,
  code fence e conteggi parziali possono soddisfare il parser;
- `F-040-RR11-GOV-HISTORY-01`: chronology e tail worklog non sono ancorati al
  ciclo Fix corrente e all'ultimo task globale;
- `F-040-RR11-GOV-SHA-01`: uno SHA inesistente ma auto-coerente passa formato
  e confronto prefisso senza risoluzione/ancestry Git;
- review prodotto: `scripts/check.sh` exit 0 con 801/801, performance 10/10,
  repeat 70/70, security 681 + 61/61 + 7/7, architecture 17/17 e build verdi;
- report security sealed SHA-256
  `45cd14b5ad3a76bb10e1741331ea6ae7675b749f6248821e4c5f77662cc2c3b5`;
- TestFlight, signing, credenziali e production invariati.

## Gate Fix 12

- exact technical SHA `60e3125ad1055df71c6e04dfb783728f7ad80085`;
- parser Markdown bounded: forma tabellare/colonne/indentazione esatte, zero
  comment/fence/heading indentati e rapporti fixture completi `passed == total > 0`;
- chronology ancorata al ciclo Fix derivato dalla history Git; task, manifest,
  gate corrente, T-07 e ultimo worklog condividono ciclo e SHA;
- SHA task/manifest/artifact risolti univocamente, ancestor e ultimo commit
  tecnico in REVIEW; worklog globale terminale con SHA/handoff strutturati;
- fixture governance 44/44 includono prose/blockquote, code block, extra column,
  comment/fence, conteggio parziale, tail globale, SHA assente/stale/inesistente
  e rollback del ciclo;
- `scripts/check.sh` exact-SHA: 801/801, performance 10/10, repeat 70/70,
  security 681 + 61/61 + 7/7, architecture 17/17, format 301/0, analyze e
  build debug Android/iOS `PASS`;
- artifact iOS e boundary esterni invariati; upload TestFlight `NOT_RUN`.

## Re-review Fix 12

- exact HEAD `8f32012dd1514bab74bbf96e13dee0f5100c94b1`, worktree pulito;
- prodotto/security `CHANGES_REQUIRED`: 0 P0/P1/P2 e 3 P3 governance;
- `F-040-RR12-GOV-MARKDOWN-01`: righe/heading non sono legati alla
  sezione/tabella canonica e raw HTML block conserva token non semantici;
- `F-040-RR12-GOV-ROLE-01`: label task/manifest/worklog non sono phase-bound;
- `F-040-RR12-GOV-SHA-02`: la pathspec latest-technical omette asset,
  `test_driver` e configurazioni root, consentendo evidence stale;
- closure diretta Fix 11 confermata; governance 44/44 e full gate exact-technical
  verdi ma insufficienti rispetto ai nuovi sibling;
- report security sealed SHA-256
  `79fbaa3cd39b8ffc0e1ec47f1b67fd8354f1c5f9155716f4fc5028eee4a6a95d`;
- TestFlight, signing, credenziali e production invariati.

## Gate Fix 13

- exact technical SHA `906fecf10995f2ee1bf673a3b090ac5458530c99`;
- `F-040-RR12-GOV-MARKDOWN-01` chiuso: Master, manifest ed evidence estraggono
  soltanto righe da sezione, header, delimiter e tabella canonici; HTML raw,
  relocation standalone e relocation in altra tabella falliscono chiusi;
- `F-040-RR12-GOV-ROLE-01` chiuso: REVIEW richiede task/manifest `technical`,
  worklog `Technical SHA` e heading `e handoff`; FIX richiede gli equivalenti
  `review`, `Exact HEAD` e `re-review`;
- `F-040-RR12-GOV-SHA-02` chiuso: dopo lo SHA tecnico REVIEW ammette soltanto
  i sei documenti di handoff; `test_driver`, `assets` e config root sono
  esplicitamente respinti;
- fixture governance 60/60 includono i PoC originali e le nuove regressioni di
  ownership tabellare, HTML, ruolo e path policy;
- `scripts/check.sh` exact-SHA exit 0: 801/801, performance 10/10, repeat 70/70,
  security source 682 + 61/61 + 7/7, architecture 17/17, format 301/0,
  analyze e build debug Android/iOS `PASS`;
- nessun delta runtime/archive/signing; TestFlight e production invariati.

## Re-review Fix 13

- exact HEAD `0c94618bb2aa187ef9dc7c3e3204894f2437b7ff`, worktree pulito;
- prodotto/security `CHANGES_REQUIRED`: 0 P0/P1/P2 e 4 P3 governance;
- `F-040-RR13-GOV-MARKDOWN-01`: PI, CDATA, tag multilinea e README non
  validato consentono contenuto non semantico con gate verde;
- `F-040-RR13-GOV-SUMMARY-01`: campi README REVIEW ma riepilogo `ACTIVE / FIX`;
- `F-040-RR13-GOV-COUNT-01`: CA-06/T-04 restano 681 contro source reale 682;
- `F-040-RR13-GOV-PATH-01`: rename detection perde il source path e l'errore
  `git diff` nella process substitution non viene propagato;
- closure exact-section/table, phase/role e direct post-SHA confermate;
- report security sealed SHA-256
  `3c90a6276c2e0ac41408355a1021fd450f35bd68d23408d018bd79638a1f9cdc`;
- TestFlight, signing, credenziali e production invariati.
