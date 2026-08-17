# TASK-040 — iOS TestFlight release

## Informazioni generali

- **Task ID**: TASK-040
- **Titolo**: iOS TestFlight release
- **File task**: `docs/TASKS/TASK-040-ios-testflight-release.md`
- **Stato**: ACTIVE
- **Fase**: FIX
- **Responsabile**: CODEX_FIXER
- **Data creazione**: 2026-08-17
- **Ultimo aggiornamento**: 2026-08-17
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-040/`
- **Handoff**: CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX

## Dipendenze

- **Dipende da**: TASK-033, TASK-034, TASK-035, TASK-036, TASK-037, TASK-038,
  TASK-039
- **Sblocca**: TASK-041
- **Writer**: Client; Admin e repository operativi read-only

## Obiettivo

Produrre e verificare un release candidate iOS production-like, incluso archive
quando tecnicamente possibile, con configuration/signing/entitlement/privacy boundary
fail-closed. Caricare soltanto su TestFlight se certificato, provisioning, App Store
Connect credential e autorizzazione di upload risultano realmente presenti.

## Scope

- inventario Xcode/Flutter, scheme/configuration, bundle/version/build e signing;
- release build `--no-codesign` e archive non firmato quando supportato;
- validator source/app/archive per Info.plist, entitlements, privacy manifest, dSYM,
  framework, debug/staging/secret/dev callback e provider fail-closed;
- Universal Links, push entitlement, Maps native setup, account deletion,
  accessibility e store metadata boundary;
- preflight App Store Connect read-only e upload TestFlight solo con gate completo;
- gate locali, CI release, review/security diff-scoped, PR, merge e main CI.

## Non incluso

- pubblicazione App Store production o public rollout;
- creazione di certificati, profili, App Store Connect key o account;
- attivazione Maps billing/key, OAuth production, push production o backend;
- acquisti reali, dati cliente, valori legali inventati o modifiche production.

## Criteri di accettazione

| CA | Criterio | Evidence attesa |
|---|---|---|
| CA-01 | release config e signing sono completi oppure falliscono chiusi | STATIC/TEST |
| CA-02 | bundle/version/build, scheme e deployment target sono verificati | BUILD/STATIC |
| CA-03 | release app/archive e dSYM sono prodotti e identificati con SHA-256 | BUILD |
| CA-04 | Info.plist, entitlement, URL scheme/Universal Links e push sono least-privilege | SECURITY |
| CA-05 | privacy manifest app/SDK e store metadata sono presenti e coerenti | STATIC/TEST |
| CA-06 | nessun debug, localhost, staging value, secret, test fixture o dev callback è nell'artifact | SECURITY |
| CA-07 | Maps/OAuth/push/telemetry restano fail-closed senza configurazione esterna | STATIC/TEST |
| CA-08 | symbol, architecture e embedded framework sono validati | BUILD/STATIC |
| CA-09 | TestFlight è uploaded solo con prerequisiti reali; altrimenti il blocker esterno è esatto | RELEASE |
| CA-10 | review indipendente, exact-SHA CI e zero P0/P1/P2 sono reali | REVIEW/CI |

## Test case

| Test | Copertura | Procedura attesa |
|---|---|---|
| T-01 | CA-01/02 | source validator e negative fixture per config/signing/version |
| T-02 | CA-03/08 | clean Flutter release no-codesign, xcodebuild archive e artifact inspection |
| T-03 | CA-04/05 | plist/entitlement/privacy manifest validator e fixture negative |
| T-04 | CA-06/07 | security scan source/artifact, strings/config/provider fail-closed |
| T-05 | CA-09 | probe credential/signing read-only; upload solo con gate completo |
| T-06 | device | iOS Simulator smoke release se installabile; physical iOS separato |
| T-07 | CA-10 | check canonico, security diff-scoped, review distinta, PR/main CI e hygiene |

## Planning — `CODEX_PLANNER`

1. inventariare Xcode, scheme, build setting, entitlement, signing identity, profile e
   soli nomi degli input App Store Connect;
2. definire validator e matrice release/source/app/archive con output redatto;
3. implementare il minimo per un build/archive riproducibile senza fallback debug o
   staging;
4. ispezionare bundle, privacy manifest, symbol, framework, architecture e config;
5. provare simulator/device e TestFlight capability senza mutazioni fuori confine;
6. produrre evidence, review indipendente e closeout exact-SHA.

### Rischi e mitigazioni

- signing/profile assenti: RC no-codesign verificato e blocker esterno preciso;
- archive no-codesign non esportabile: conservare archive verificabile e non
  dichiararlo upload-ready;
- entitlement aggiunto impropriamente: derive-and-compare fail-closed, nessun push/
  associated-domain inventato;
- provider non configurato: sentinel/flag restano OFF, nessun fallback staging;
- tool Xcode nondeterministico: comandi canonici, DerivedData isolato e artifact hash;
- TestFlight ambiguity: nessun upload senza identity, credential, bundle access e
  gate esplicito tutti presenti.

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | archive/build no-codesign non equivale a TestFlight upload | Evidence reale | ATTIVA |
| D-02 | nessun certificato/profile/App Store key viene generato o inventato | Gate esterno | ATTIVA |
| D-03 | production-like incompleta fallisce chiusa, mai verso staging | Separazione ambienti | ATTIVA |
| D-04 | mandato 2026-08-16 autorizza Planning→Execution | ADR-015 | ATTIVA |

### Handoff a Execution

- **Autorizzazione USER_APPROVER**: mandato 2026-08-16 e ADR-015
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Execution — `CODEX_EXECUTOR`

- aggiunto `scripts/check-ios-release.sh`: source/app/archive, identity,
  version/build, platform/architecture, privacy app+SDK, framework, dSYM, signature,
  provisioning e App Store Connect falliscono chiusi con output bounded;
- release config canonica production mantiene OAuth/Maps disabilitati e nessun
  backend/callback/shop esterno; Maps native resta `NOT_CONFIGURED`;
- `flutter build ios --release --no-codesign` e `xcodebuild archive` sono `PASS`
  sullo SHA tecnico `4c4db2a82ddb276066763fcdb24227bbf2937a4f`;
- archive `Runner.xcarchive` 201.328 KiB, app 36.708 KiB, bundle
  `com.xniw.clientmerchandisecontrol`, versione `0.1.0 (1)`, iOS 14, arm64;
- executable SHA-256
  `7aaa6f37f276f5f458a09772711b8a1c7a0c2cfbf95f6ad85598fe868f5e1928`;
  Runner/dSYM UUID corrispondente, 7 dSYM, 8 privacy manifest e 207 file app;
- signing `UNSIGNED`: una identity Apple Development, zero Apple Distribution,
  zero provisioning profile e zero App Store Connect API key; upload TestFlight
  `NOT_RUN`, `--require-upload-ready` respinto con
  `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`;
- Universal Links, push/APNs e Maps restano activation gate esterni; nessun
  entitlement/dominio/key/billing è stato inventato o attivato;
- scanner artifact aggiornato per la variante linker reale del public identifier
  Google Maps, ancora vincolata a fingerprint+prefisso+endpoint esatti; fixture
  security 52/52 negative e 6/6 positive;
- CI aggiunge un job macOS release no-codesign+archive+validator; runbook TestFlight
  documenta export/upload senza eseguirli;
- Simulator: smoke integration debug 1/1 `PASS`; debug production-like install/launch
  `PASS` e resta fail-closed alla launch screen; Release Simulator `NOT_RUN`
  perché Flutter lo rifiuta esplicitamente; physical iOS `BLOCKED` con prerequisite
  device collegato e autorizzato (zero device fisici collegati).

Gate executor:

- `scripts/check.sh` exit 0; 788/788 non-performance, repeat 5×14=70/70,
  performance 10/10, format 297/0, analyze zero issue;
- security source 676, artifact app 207, fixture 52/52 negative + 6/6 positive;
- governance 9/9, architecture 7/7, release metadata 12×3 e action pins `PASS`;
- Android debug e iOS Simulator debug build `PASS`; production e App Store Connect
  invariati.

`CODEX_EXECUTION_COMPLETE_TO_REVIEW`.

## Review

`CHANGES_REQUIRED` sul revision set `f30b13e..c8893dc`: 0 P0, 0 P1, finding
riproducibili su binding app/archive, firma invalida riclassificata unsigned,
entitlement Xcode 26, profilo embedded incompatibile con lo scanner, runtime config
non attestata, UTF-16/path traversal/privacy manifest decoy, test CI strutturalmente
deboli ed evidence device non canonica. Security report sealed:
`21115fc2692b7361a29123422edee14fc4bd752d1429a94e1c641b50ee352f32`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Fix

- binding app/archive ristretto all'app canonica interna e URL scheme/eseguibile
  validati come set esatti; firma presente ma invalida non viene più riclassificata
  `UNSIGNED`;
- estrazione entitlement compatibile con Xcode 26, allowlist top-level fail-closed e
  profilo embedded ammesso soltanto al root app dopo decode CMS/App Store checks;
- runtime production completo attestato da SHA-256 nel Mach-O prima di upload-ready;
  il template canonico incompleto resta deliberatamente non uploadabile;
- scanner artifact esteso a UTF-16LE/BE, file/stream bounded e profilo scoped;
  privacy manifest SDK verificati con path esatti;
- fixture iOS avversariali 8/8, security 56/56 negative + 7/7 positive, runtime
  config 3/3, gate mirati 53/53 e `scripts/check.sh` exit 0;
- clean release/archive sullo SHA tecnico `9065d9c7a3d9bf34dd8c183c9adbccc896f124d9`:
  candidate unsigned valido, executable SHA-256
  `caa81fa3e2c0a067b4ecbf91f83267fb7dba6c95d54da27bf4022ced821f142c`,
  Runner/dSYM UUID `F278496B-FCCE-3ADD-A310-7E94973B62D0`;
- `--require-upload-ready` resta correttamente bloccato con
  `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`; nessuna firma, IPA, upload o
  configurazione production reale è stata creata.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 8

`CHANGES_REQUIRED` su `e88f8762aab52ad7b176cbc0e0bd80b23d2aaf43`.
La security re-review classifica 2 P2 e 2 P3: la matrice AST lega soltanto lo
slug, il control flow può ritornare un config alternativo prima dell'attestation,
i contenuti framework/bundle non hanno digest revision-bound e il worklog non è
cronologico. La review prodotto aggiunge i sibling P3: library URI collidibile per
suffisso, Mach-O extensionless non inventariato e fixture constructor non
analyzer-clean. Report security canonico sealed SHA-256
`169a5154053c28503744c0de8a8d2a9c923520062e339e28d93b038a83df8f84`;
report prodotto sealed SHA-256
`877c30e186d5bd38da82639a023021a3da117defeb63d93d2c6167bc715b92ca`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 9

- `F-040-RR8-ARCH-CONFIG-01` e `F-040-RR8-ARCH-CONTROL-01` sono coperti da un
  validator analyzer-resolved che lega i nove field compile-time, i sette argomenti
  `AppConfig.fromValues`, gli otto input dell'attestation e l'esatto control flow
  production/try/catch/return agli elementi canonici;
- library URI, costruttori e metodi sono risolti sul package canonico; le fixture sono
  formattate e analyzer-clean prima del probe e coprono binding attacker, guard sempre
  vera e library decoy; architecture negative 17/17 `PASS`;
- l'inventory artifact enumera ogni Mach-O regolare, inclusi file extensionless, e
  attesta il contenuto loadable dei cinque eseguibili più l'albero esatto dei nove
  bundle; tamper `__text`, binary replacement, risorsa bundle e componenti extra sono
  respinti; fixture iOS 26/26 `PASS`;
- il worklog è cronologico e il gate governance verifica che l'ultimo blocco del task
  contenga l'handoff corrente; governance 10/10 `PASS`;
- `scripts/check.sh` sullo SHA tecnico
  `34d342b38b41d73cfe590b2cfe5defd5aab6be40` è `PASS`: 801/801
  non-performance, 10/10 performance, repeat 5x14=70/70, security 681 e
  61/61 negative + 7/7 positive, format 301/0, analyze e build debug Android/iOS;
- clean release/archive no-codesign `PASS`: 201.344 KiB, app 36.724 KiB/207 file,
  8 privacy manifest e 7 dSYM; runtime SHA-256
  `2ad06c3f2e0e980ab1907b1ecb353c43e3ce98aad21eb0f02b8fd319f682c336`,
  wrapper SHA-256
  `caa81fa3e2c0a067b4ecbf91f83267fb7dba6c95d54da27bf4022ced821f142c`
  e UUID app/dSYM `F278496B-FCCE-3ADD-A310-7E94973B62D0`;
- un secondo archive ripete byte-for-byte wrapper e digest normalizzato. Il validator
  ammette esclusivamente i due layout deterministici `flutter build`/archive e resta
  fail-closed per ogni altro digest;
- upload gate exit 1 `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`: 0 Apple
  Distribution, 0 provisioning, 0/3 input App Store Connect; device iOS fisici
  offline, nessuna firma, IPA, upload o mutazione production.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 2

`CHANGES_REQUIRED` sul revision set `be978225..2b7c148`: prodotto 1 P2, security
0 P0/P1/P2 e 3 P3. Il P2 consente una `.app` symlink extra non inventariata;
i P3 riguardano materializzazione JWT source, lista directory prima del cap e gate CI
basato su substring. Report security sealed SHA-256
`083337065a0ad22367124162a36766391f9dabd180f3d6f00b9512835b4f9e28`.
Firma, attestation/parità, CMS, UTF-16/chunk, manifest malformati, aggregate bound e
runtime Dart risultano chiusi e non vengono riaperti.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Re-review Fix 1

`CHANGES_REQUIRED` sul revision set `c8893dc..be978225`: 0 P0/P1, 6 P2
security, 4 P3 security e un P2 tecnico. Restano riproducibili firma corrotta
riclassificata unsigned, `ApplicationPath` archive, runtime attestation non
semantica/parità `AppConfig`, scanner su cut/CMS decoded/UTF-16 JWT+PEM, CI gate
artifact e manifest privacy semantico, oltre ai bound aggregate/JWT buffer.
Security report sealed SHA-256
`e76c6beab23628a979cf20284253e85d7c6afbd1dd5280f629976a4e06ba6d88`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 2

- firma Mach-O presente ma illeggibile/invalida è sempre un errore; l'archive accetta
  soltanto `ApplicationPath=Applications/Runner.app` e una sola app canonica;
- `ReleaseConfigAttestation` è ora l'unica implementazione di parser JSON flat,
  validazione key/JWT/URL/callback/flag e digest semantico condivisa da tool e app;
  production verifica digest e marker compilato prima del bootstrap;
- upload readiness cerca esattamente un marker completo nel runtime Dart
  `Frameworks/App.framework/App`, non nel wrapper nativo né come digest raw;
- CMS decoded, JWT/PEM ASCII e UTF-16, boundary di chunk, massimo 4.096 file e 512 MiB
  aggregati sono fail-closed; ogni privacy manifest previsto viene anche validato;
- la CI governance isola il job artifact reale e le fixture coprono job assente/
  duplicato, archive alterato, signature SuperBlob corrotta, profilo decoded, manifest
  invalido e divergenze runtime;
- regressioni: config/governance 39/39, fixture iOS 13/13, security 60/60 negative
  e 7/7 positive, analyze e governance release train 9/9 `PASS`;
- build production sintetico senza credenziali reali `PASS` con un solo marker nel
  runtime Dart; clean build/archive canonico sullo SHA tecnico `d4a9edc` `PASS`;
- candidate finale unsigned: archive 201.344 KiB, app 36.724 KiB/207 file,
  8 privacy manifest, 7 dSYM, App.framework SHA-256
  `2ad06c3f2e0e980ab1907b1ecb353c43e3ce98aad21eb0f02b8fd319f682c336`,
  Runner/dSYM UUID `BECE880B-91F5-36D2-AD95-F366FB669F41`;
- upload gate ancora correttamente respinto da
  `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`; nessuna firma reale, IPA, credenziale,
  configurazione production o upload è stata creata.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Fix 3

- l'app-set dell'archive enumera ora ogni entry top-level `*.app` senza seguire o
  ignorare symlink e richiede l'unica directory reale canonica `Runner.app`; la
  regressione `Extra.app` symlink è respinta;
- il source scanner JWT è streaming con memoria bounded e token-size cap; la lista
  artifact viene interrotta a 4.096 entry durante `find`, prima di materializzare
  input illimitati, e la fixture 4.097 file fallisce chiusa;
- il gate CI usa `package:yaml` come dipendenza dev diretta e verifica job, step,
  nomi e comandi esatti dal documento YAML; sentinelle in commenti o step no-op non
  soddisfano più il gate;
- il binding architetturale lega esattamente `STOREFRONT_SHOP_SLUG` al relativo
  `String.fromEnvironment`; una chiave sostituita è respinta;
- config runtime letta da un singolo file descriptor con cap 64 KiB; hash primario
  del candidate legato al runtime Dart e hash wrapper nativo riportato separatamente;
  ogni privacy manifest richiesto è validato anche semanticamente;
- gate mirati `PASS`: config/CI 15/15, iOS release 15/15, security 61/61 negative
  + 7/7 positive, governance 9/9, architecture 8/8, source 680, artifact 207 e
  `flutter analyze` senza issue;
- build production sintetico esterno `PASS` con digest
  `b6d7f55b1f96785f7e4836d45fb11cd58e6aca6282f166660ca09529db0806a6`
  presente una sola volta in `App.framework/App`; il file temporaneo è stato
  eliminato e non versionato;
- clean build/archive dallo SHA tecnico `12931389b2692bff5739325946ae48ad0eeff730`:
  archive 201.344 KiB, app 36.724 KiB/207 file, 8 privacy manifest, 7 dSYM,
  App.framework SHA-256
  `2ad06c3f2e0e980ab1907b1ecb353c43e3ce98aad21eb0f02b8fd319f682c336`,
  wrapper SHA-256
  `caa81fa3e2c0a067b4ecbf91f83267fb7dba6c95d54da27bf4022ced821f142c`
  e UUID app/dSYM `F278496B-FCCE-3ADD-A310-7E94973B62D0`;
- `scripts/check.sh` `PASS`: 798/798 non-performance, 10/10 performance,
  repeat resilience 5×14=70, format 300 file, Android debug e iOS Simulator debug;
  upload gate ancora correttamente bloccato da firma Distribution assente, con
  0 profili e 0 input App Store Connect. Device fisici iOS presenti solo offline.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 3

`CHANGES_REQUIRED` su `ed0dc628dff7f904d47d214218662d2c2ff587ed`:
0 P0/P1/P2 e 5 P3 complessivi. Restano aperti execution controls YAML non
allowlisted (`if:false`), decoy comment nel binding architetturale, schema privacy
nested incompleto, FIFO canonico bloccante e matrice evidence corrente non riallineata.
Il P2 `.app` symlink e i P3 JWT/file cap della re-review precedente sono confermati
chiusi. Security report sealed SHA-256
`5ba397a40bbfb3ce7d9690deb6a147541f611f2e7f626ef4afaffa7d72167786`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 4

- il parser YAML rifiuta ora job o step release con chiavi di esecuzione aggiuntive,
  inclusi `if`, `continue-on-error` e `shell`; quattro mutazioni reali del workflow
  sono regressioni negative;
- il binding `STOREFRONT_SHOP_SLUG` viene verificato dopo la rimozione dei commenti,
  quindi un decoy commentato non sostituisce più il compile-time binding reale;
- ogni privacy manifest valida chiavi e tipi nested esatti, reason/purpose non vuoti,
  booleani e set unici; la forma `[{}]` è respinta sul candidate reale;
- il runtime-config tool rifiuta FIFO e ogni entity non regular prima di `openSync`,
  con test bounded che dimostra l'assenza del blocco;
- evidence corrente riallineata a quattro digest, source 680 e artifact/gate Fix 4;
- regressioni `PASS`: runtime/CI 17/17, iOS 15/15, architecture 9/9,
  validator source/artifact 680/207 e `flutter analyze` senza issue;
- `scripts/check.sh` exit 0: 800/800 non-performance, 10/10 performance,
  resilience repeat 5×14=70/70, format 300/0, Android debug e iOS Simulator
  debug build `PASS`;
- clean build/archive dallo SHA tecnico
  `16f29012e89170a0de2c9b348ec134c4d495b33d`: archive 201.344 KiB,
  app 36.724 KiB/207 file, 8 privacy manifest, 7 dSYM, runtime SHA-256
  `2ad06c3f2e0e980ab1907b1ecb353c43e3ce98aad21eb0f02b8fd319f682c336`,
  wrapper SHA-256
  `7aaa6f37f276f5f458a09772711b8a1c7a0c2cfbf95f6ad85598fe868f5e1928`
  e UUID app/dSYM `BECE880B-91F5-36D2-AD95-F366FB669F41`;
- upload gate ancora correttamente bloccato da
  `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`; nessuna IPA, firma, credenziale,
  configurazione reale, upload o mutazione production.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 4

`CHANGES_REQUIRED` su `6139063623ea6395ec0beca808990739b2fa3792`:
0 P0/P1/P2 e 5 P3. Restano riproducibili override workflow-level
`defaults.run`/`BASH_ENV`, decoy Dart in stringhe/commenti annidati, enum privacy
Apple inesistenti ma regex-conformi, race regular→FIFO prima di `openSync` e digest
wrapper errato nelle evidence. Le chiusure nested `{}`, modifier job/step locali,
FIFO statica, app-set/signature e runtime binding restano valide. Security report
sealed SHA-256
`0e98a5c4dd7faf79571002b7edad4b4bb5624449dbb7eb3961e941de024762df`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 5

- il gate CI è ora un contratto YAML completo: root, trigger, permission, concurrency,
  environment, job e nove step ordinati sono allowlisted; `defaults.run`, `BASH_ENV`,
  step aggiuntivi e override di esecuzione falliscono chiusi;
- il binding `STOREFRONT_SHOP_SLUG` è verificato sul vero AST Dart tramite `analyzer`
  già compatibile col lockfile; stringhe, raw string e commenti annidati non possono
  più fungere da decoy;
- privacy manifest accetta soltanto categorie, tipi, purpose e required-reason Apple
  realmente usati dall'app e dagli SDK, con pairing esatto e regressioni negative;
- runtime config usa `python3` dichiarato nel preflight e un singolo descriptor
  `O_NONBLOCK|O_NOFOLLOW`, con `fstat` prima/dopo e verifica identity/size/mtime;
  la race regular-to-FIFO è respinta senza bloccare;
- evidence wrapper Fix 4 corretta al digest fisico verificato
  `7aaa6f37f276f5f458a09772711b8a1c7a0c2cfbf95f6ad85598fe868f5e1928`;
- gate mirati `PASS`: runtime/CI 17/17, iOS release 16/16, architecture 10/10,
  security 61/61 negative + 7/7 positive, source/artifact 681/207 e analyze;
- `scripts/check.sh` exit 0: 800/800 non-performance, 10/10 performance,
  resilience repeat 5x14=70/70, format 301/0, Android debug e iOS Simulator debug;
- clean release/archive sullo SHA tecnico
  `ae452c6b10a9b69c9535476c02b01d8ed3ec74b5`: archive 201.344 KiB,
  app 36.724 KiB/207 file, 8 privacy manifest, 7 dSYM, runtime SHA-256
  `2ad06c3f2e0e980ab1907b1ecb353c43e3ce98aad21eb0f02b8fd319f682c336`,
  wrapper SHA-256
  `7aaa6f37f276f5f458a09772711b8a1c7a0c2cfbf95f6ad85598fe868f5e1928`
  e UUID app/dSYM `BECE880B-91F5-36D2-AD95-F366FB669F41`;
- upload gate exit 1 `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`; nessuna IPA,
  firma Distribution, provisioning, input App Store Connect, upload o mutazione
  production.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 5

`CHANGES_REQUIRED` su `354fd2442190cf172e41adf1070e94cb8d31cd5b`:
0 P0/P1/P2 e 3 P3. Il gate AST accetta il campo canonico fuori da `AppConfig`;
la lettura runtime-config non impedisce il cambio atomico di un ancestor in symlink;
il validator privacy non lega ancora il contenuto minimo al singolo SDK atteso.
I cinque finding Fix 4 sono confermati chiusi. Gate nominali 681/207, 61/61 + 7/7,
10/10 architecture, 17/17 runtime/CI e 16/16 iOS restano verdi ma non coprono i
tre PoC. Security report sealed SHA-256
`47444ae52e31ad64aa40ac1ffb3828bd56897c93d00f6178cab739cfdf35e346`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 6

- il parser AST richiede l'unica declaration direttamente in `AppConfig` e lega
  entrambi i consumer reali di `AppConfig.fromEnvironment`; getter, classi, `part`
  o field inutilizzati non soddisfano il gate;
- la lettura runtime config percorre ogni componente con directory descriptor e
  `openat(O_DIRECTORY|O_NOFOLLOW)`, poi apre il basename nonblocking sullo stesso
  parent fd; 30 tentativi ancestor-symlink non leggono mai il config alternativo;
- gli otto privacy manifest attesi sono legati a digest semantici canonici per
  app/SDK e lockfile corrente; il manifest Google Maps sostituito con quello vuoto
  è respinto;
- gate mirati `PASS`: runtime/CI 18/18, iOS release 17/17, architecture 11/11,
  security 61/61 negative + 7/7 positive, source/artifact 681/207 e analyze;
- `scripts/check.sh` exit 0: 801/801 non-performance, 10/10 performance,
  resilience repeat 5x14=70/70, format 301/0, Android debug e iOS Simulator debug;
- clean release/archive sullo SHA tecnico
  `2523385d65dba7dac4dbdf075173c69260111796`: archive 201.344 KiB,
  app 36.724 KiB/207 file, 8 privacy manifest, 7 dSYM, runtime SHA-256
  `2ad06c3f2e0e980ab1907b1ecb353c43e3ce98aad21eb0f02b8fd319f682c336`,
  wrapper SHA-256
  `7aaa6f37f276f5f458a09772711b8a1c7a0c2cfbf95f6ad85598fe868f5e1928`
  e UUID app/dSYM `BECE880B-91F5-36D2-AD95-F366FB669F41`;
- upload gate exit 1 `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`; nessuna IPA,
  firma Distribution, provisioning, input App Store Connect, upload o mutazione
  production.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 6

`CHANGES_REQUIRED` su `74f65036f7cd295e09fb457e21c804f26e49d70b`:
0 P0/P1/P2 e 2 P3. Il validator AST lega ancora i consumer al solo lexema,
quindi un parametro omonimo di `AppConfig.fromEnvironment` può ombreggiare il
field canonico e instradare i due consumer verso `ATTACKER_SHOP_SLUG`. Inoltre
l'exact set degli otto privacy manifest non è legato all'exact inventory dei
framework/bundle: una copia Mach-O `Extra.framework` senza manifest è stata
accettata come candidate valido. Ancestor-symlink TOCTOU e sostituzione del
manifest Google Maps risultano chiusi. Gate completi nominali verdi ma insufficienti
rispetto ai due PoC; report prodotto sealed SHA-256
`32b79e76daec872db0be080ebe06bf1bb58153518a8356a1f40bdb8fb3a12fe9`
e report security canonico sealed SHA-256
`3765b04359849bed1fd2d6bb0a95376d2d7974db2fd6fb3d79ec85044b573baa`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 7

- il validator usa un resolved unit analyzer e confronta l'identità semantica del
  `PropertyAccessorElement.variable` dei due consumer con il `VariableElement` del
  field static const dichiarato direttamente in `AppConfig`; il parametro omonimo
  basato su `ATTACKER_SHOP_SLUG` è respinto;
- framework e bundle embedded sono ora inventory exact: quattro framework e sette
  bundle canonici, directory reali non symlink, con gli otto manifest privacy e
  relativi digest già legati agli SDK applicabili; `Extra.framework` senza manifest
  è respinto da `EMBEDDED_FRAMEWORK_SET_INVALID`;
- gate mirati `PASS`: architecture 12/12, iOS release 18/18, runtime/CI 18/18,
  security 61/61 negative + 7/7 positive, source/artifact 681/207 e analyze;
- `scripts/check.sh` exit 0: 801/801 non-performance, 10/10 performance,
  resilience repeat 5x14=70/70, format 301/0, Android debug e iOS Simulator debug;
- clean release/archive sullo SHA tecnico
  `d94b071b3c916a914c9db87cd588621feee4e75d`: archive 201.344 KiB,
  app 36.724 KiB/207 file, 8 privacy manifest, 7 dSYM, runtime SHA-256
  `2ad06c3f2e0e980ab1907b1ecb353c43e3ce98aad21eb0f02b8fd319f682c336`,
  wrapper SHA-256
  `7aaa6f37f276f5f458a09772711b8a1c7a0c2cfbf95f6ad85598fe868f5e1928`
  e UUID app/dSYM `BECE880B-91F5-36D2-AD95-F366FB669F41`;
- upload gate exit 1 `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`; device fisici
  iOS presenti solo offline, nessuna firma, IPA, provisioning, input App Store
  Connect, upload o mutazione production.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 7

`CHANGES_REQUIRED` su `189c5e74fb3f32d76a6e8bffb87ca6a95e791fed`:
0 P0/P1/P2 e 4 P3. Il validator non lega ancora il costruttore
`String.fromEnvironment` all'elemento `dart:core`, né i due consumer canonici alle
invocazioni reali raggiungibili del factory. L'inventory iOS è top-level e
case-sensitive, non include dylib/nesting e non attesta l'identità del contenuto sotto
nomi allowlisted. Infine le sezioni evidence dichiarate correnti conservano SHA e
conteggi Fix 6. Report security sealed SHA-256
`fbd804ea9d7057f6c300f4ea91a59439e7327871c287bec4e9f950b27cb99bf2`;
report prodotto sealed SHA-256
`a1a49bdd9744478abd024fe71d4976f731ad1d7d5fa4cf80d452d65c208d743d`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 8

- il validator AST lega l'initializer al costruttore const risolto di `dart:core`,
  limita il factory ai quattro statement canonici, verifica gli exact target
  `AppConfig.fromValues`/`ReleaseConfigAttestation.fromValues`, i set completi di
  argomenti e mappe e gli unici due riferimenti al field;
- l'inventory iOS è recursive e case-insensitive, rifiuta dylib e componenti extra,
  e lega framework/bundle canonici a executable, bundle ID, install name e simboli
  distintivi; le regressioni coprono casing, nesting, sostituzioni e dylib;
- gate mirati `PASS`: architecture 14/14, iOS release 23/23, config/governance
  36/36, runtime/CI 18/18, security 61/61 negative + 7/7 positive,
  source/artifact 681/207 e analyze;
- `scripts/check.sh` exit 0: 801/801 non-performance, 10/10 performance,
  resilience repeat 5x14=70/70, format 301/0 e build debug Android/iOS;
- clean release/archive sullo SHA tecnico
  `41f5cbab7c60ee872a1e2f5ef591e16c18e89b6e`: archive 201.344 KiB,
  app 36.724 KiB/207 file, 8 privacy manifest, 7 dSYM, runtime SHA-256
  `2ad06c3f2e0e980ab1907b1ecb353c43e3ce98aad21eb0f02b8fd319f682c336`,
  wrapper SHA-256
  `7aaa6f37f276f5f458a09772711b8a1c7a0c2cfbf95f6ad85598fe868f5e1928`
  e UUID app/dSYM `BECE880B-91F5-36D2-AD95-F366FB669F41`;
- upload gate exit 1 `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`: 0 Apple
  Distribution, 0 provisioning, 0 input ASC e iPhone fisico offline; nessuna firma,
  IPA, upload o mutazione production.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 9

`CHANGES_REQUIRED` su exact HEAD
`b5b9ac64299f0dc79f8b43970ca98937cd71c670`.

- security: 0 P0, 0 P1, 1 P2 e 2 P3; report canonico sealed SHA-256
  `8d346f407851cd9312518984b8a807d0973754fd80a5324226bf87a40d51a5a3`;
- `F-040-RR9-IOS-01` P2: il digest section-only omette header, load command e
  `__LINKEDIT`; clear `MH_PIE`, set `MH_ALLOW_STACK_EXECUTION` e modifica
  `LC_LOAD_DYLIB` raggiungono candidate-valid anche dopo firma ad hoc;
- `F-040-RR9-GOV-01/02` P3: manifest e matrice T restano Fix 8 e il tail task
  operativo termina ancora con Fix 8; il gate governance non correla tali fonti;
- review prodotto: 0 P0/P1/P2 e 2 P3 sul medesimo root Mach-O e su una frase che
  sovradichiara byte identity dell'archive completo;
- CONFIG/CONTROL/library identity, inventory extensionless, bundle content e
  cronologia `AI_WORKLOG` sono confermati chiusi;
- gate indipendenti verdi ma insufficienti: architecture 17/17, iOS 26/26,
  config/governance 44/44, governance 10/10, analyze e candidate/upload boundary.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 10

- exact technical SHA
  `da83b266bf6298c5a869b74cd271782782c7b4ef`; il digest canonicalizza la sola
  firma su copia isolata e attesta tutti i byte Mach-O residui, inclusi header,
  load command, sezioni e `__LINKEDIT`;
- regressioni `macho-header-pie-disabled`, `macho-header-stack-executable` e
  `macho-load-command-digest` chiudono `F-040-RR9-IOS-01`; la suite iOS è
  `29/29 PASS`, inclusi app unsigned, firma ad hoc, firma corrotta, privacy e
  inventory completa;
- `check-governance-state.sh` correla status/revision/gate del release manifest,
  tail Fix/handoff e matrici T-02/T-03 con artifact/gate correnti; fixture
  governance `15/15 PASS` chiudono `F-040-RR9-GOV-01/02`;
- clean release/archive no-codesign realmente rigenerati sul source SHA
  `01dd140852733c14ae53d067e7454458cababe19`: archive 201.344 KiB, app
  36.724 KiB/207 file, 8 privacy manifest, 7 dSYM, runtime SHA-256
  `2ad06c3f2e0e980ab1907b1ecb353c43e3ce98aad21eb0f02b8fd319f682c336`,
  wrapper SHA-256
  `caa81fa3e2c0a067b4ecbf91f83267fb7dba6c95d54da27bf4022ced821f142c`
  e UUID app/dSYM `F278496B-FCCE-3ADD-A310-7E94973B62D0`;
- candidate reale `PASS`, signing `UNSIGNED`; upload gate exit 1 esatto
  `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`, quindi IPA/TestFlight/production
  restano `NOT_RUN` senza credenziali esterne;
- `scripts/check.sh` sullo SHA tecnico finale: 801/801 non-performance,
  performance 10/10, repeat 5x14=70/70, security source 681 + 61/61 negative +
  7/7 positive, governance 15/15, architecture 17/17, format 301/0, analyze e
  build debug Android/iOS `PASS`; worktree pulito.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 10

`CHANGES_REQUIRED` su exact HEAD
`a85d60774212f212d3ee8dd274db99af011925c8`: 0 P0/P1/P2 e 2 P3.

- `F-040-RR10-GOV-01`: il parser first-match/substrings accetta manifest
  duplicati contraddittori, stato T-02/T-03 `FAIL` e gate `Fix 100`;
- `F-040-RR10-GOV-02`: la chronology è opzionale, considera commenti HTML e
  non valida l'ordine completo dei cicli Fix;
- `F-040-RR9-IOS-01` è chiuso: fixture iOS 29/29, tamper header/load-command/
  firma respinti, scanner source 681/artifact 207 e 61/61 + 7/7;
- report security sealed SHA-256
  `10deb98767cac73818233dc9f073934c31c7a81d0768c4fa68f82b5dfbef1837`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Chiusura

- **Classificazione target**: `DONE_TESTFLIGHT_UPLOADED` oppure
  `TECHNICALLY_COMPLETE_EXTERNAL_CREDENTIAL_REQUIRED`
- **Production App Store**: vietata
- **Data completamento**: non ancora
