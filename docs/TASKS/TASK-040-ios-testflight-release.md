# TASK-040 — iOS TestFlight release

## Informazioni generali

- **Task ID**: TASK-040
- **Titolo**: iOS TestFlight release
- **File task**: `docs/TASKS/TASK-040-ios-testflight-release.md`
- **Stato**: BLOCKED
- **Fase**: REVIEW
- **Responsabile**: CODEX_RE_REVIEWER
- **Data creazione**: 2026-08-17
- **Ultimo aggiornamento**: 2026-08-18
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-040/`
- **Handoff**: CODEX_FIX_BLOCKED_TO_RE_REVIEW

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

### Re-review Fix 2

`CHANGES_REQUIRED` sul revision set `be978225..2b7c148`: prodotto 1 P2, security
0 P0/P1/P2 e 3 P3. Il P2 consente una `.app` symlink extra non inventariata;
i P3 riguardano materializzazione JWT source, lista directory prima del cap e gate CI
basato su substring. Report security sealed SHA-256
`083337065a0ad22367124162a36766391f9dabd180f3d6f00b9512835b4f9e28`.
Firma, attestation/parità, CMS, UTF-16/chunk, manifest malformati, aggregate bound e
runtime Dart risultano chiusi e non vengono riaperti.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

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

- exact review SHA: `a85d60774212f212d3ee8dd274db99af011925c8`;
- esito `CHANGES_REQUIRED`: 0 P0/P1/P2 e 2 P3.

- `F-040-RR10-GOV-01`: il parser first-match/substrings accetta manifest
  duplicati contraddittori, stato T-02/T-03 `FAIL` e gate `Fix 100`;
- `F-040-RR10-GOV-02`: la chronology è opzionale, considera commenti HTML e
  non valida l'ordine completo dei cicli Fix;
- `F-040-RR9-IOS-01` è chiuso: fixture iOS 29/29, tamper header/load-command/
  firma respinti, scanner source 681/artifact 207 e 61/61 + 7/7;
- report security sealed SHA-256
  `10deb98767cac73818233dc9f073934c31c7a81d0768c4fa68f82b5dfbef1837`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 11

- exact technical SHA: `32017f34bc840e384fdd4e5023727027cb9ec0cf`;
- manifest TASK-040, T-02 e T-03 richiedono cardinalità esatta uno, colonne
  strutturate e stato `PASS`; il gate `Fix N` usa un token completo;
- la chronology task è obbligatoria, priva di commenti HTML, sequenziale da
  Re-review Fix 1 a Fix 11 e lega SHA/handoff a linee etichettate e terminali;
- i blocchi storici Fix 1–10 sono riordinati nella successione canonica;
- fixture governance 26/26 includono duplicati e righe Markdown non canoniche,
  `FAIL`, `Fix 100`, revisioni non-prefix, heading assenti/fuori sezione,
  comment-decoy e ordine errato;
- `scripts/check.sh` sullo SHA tecnico: 801/801 non-performance, performance
  10/10, repeat 5x14=70/70, security source 681 + 61/61 negative + 7/7
  positive, governance 26/26, architecture 17/17, format 301/0, analyze e
  build debug Android/iOS `PASS`;
- archive e TestFlight boundary non sono cambiati: candidate unsigned già
  validato; firma Distribution, provisioning e credenziali ASC restano assenti.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 11

- exact review SHA: `0fec3ab0f4af8747e82695bc97e4cf61b8799114`;
- prodotto e security `CHANGES_REQUIRED`: 0 P0/P1/P2 e 3 P3;
- `F-040-RR11-GOV-MARKDOWN-01`: il parser accetta prose/blockquote,
  indentazione code block, commenti/code fence e conteggi parziali come evidence;
- `F-040-RR11-GOV-HISTORY-01`: chronology rollback e un task globale successivo
  possono lasciare verde il gate;
- `F-040-RR11-GOV-SHA-01`: formato/prefix non provano esistenza e ancestry Git;
- report security sealed SHA-256
  `45cd14b5ad3a76bb10e1741331ea6ae7675b749f6248821e4c5f77662cc2c3b5`;
- gate completo reviewer verde, ma insufficiente rispetto ai probe avversariali;
- TestFlight, signing, credenziali e production invariati.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 12

- exact technical SHA: `60e3125ad1055df71c6e04dfb783728f7ad80085`;
- `F-040-RR11-GOV-MARKDOWN-01` chiuso: manifest/matrici richiedono righe
  Markdown/colonne/indentazione esatte, i documenti rifiutano comment/fence e
  il rapporto iOS deve essere completo e nonzero;
- `F-040-RR11-GOV-HISTORY-01` chiuso: ciclo task ancorato alla history Git e
  correlato a gate corrente, T-07 e ultimo heading globale del worklog;
- `F-040-RR11-GOV-SHA-01` chiuso: SHA task/manifest/artifact esistono, sono
  ancestor e in REVIEW il task coincide con l'ultimo commit tecnico;
- worklog richiede esattamente uno SHA e un handoff strutturati e correlati;
- fixture governance 44/44 coprono i PoC originali e sibling compositivi;
- `scripts/check.sh` exact-SHA exit 0: 801/801, performance 10/10, repeat
  70/70, security 681 + 61/61 + 7/7, architecture 17/17, format 301/0,
  analyze e build debug Android/iOS `PASS`;
- nessun delta runtime/archive/signing; TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 12

- exact review SHA: `8f32012dd1514bab74bbf96e13dee0f5100c94b1`;
- prodotto/security `CHANGES_REQUIRED`: 0 P0/P1/P2 e 3 P3;
- `F-040-RR12-GOV-MARKDOWN-01`: relocation fuori dalla tabella/sezione e raw
  HTML block passano il parser lessicale;
- `F-040-RR12-GOV-ROLE-01`: label technical/review e handoff/re-review non sono
  correlate alla fase;
- `F-040-RR12-GOV-SHA-02`: path tecnici omessi dalla pathspec consentono un
  commit post-SHA non attestato;
- closure Fix 11 confermata; gate verdi ma insufficienti ai sibling;
- report security sealed SHA-256
  `79fbaa3cd39b8ffc0e1ec47f1b67fd8354f1c5f9155716f4fc5028eee4a6a95d`;
- TestFlight, signing, credenziali e production invariati.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 13

- exact technical SHA: `906fecf10995f2ee1bf673a3b090ac5458530c99`;
- `F-040-RR12-GOV-MARKDOWN-01` chiuso: backlog Master, revision manifest e
  matrice T sono validati soltanto dentro sezione, header, delimiter e tabella
  canonici; raw HTML e relocation falliscono chiusi;
- `F-040-RR12-GOV-ROLE-01` chiuso: fase, heading, ruolo SHA task/manifest e
  label/suffix worklog sono correlati esattamente;
- `F-040-RR12-GOV-SHA-02` chiuso: il delta post-SHA in REVIEW usa una allowlist
  documentale chiusa; qualunque path tecnico, inclusi `test_driver`, `assets`
  e configurazioni root, invalida l'handoff;
- fixture governance 60/60 sui PoC Fix 12 e sibling; security source 682,
  fixture 61/61 negative + 7/7 positive;
- `scripts/check.sh` exact-SHA exit 0: 801/801, performance 10/10, repeat
  70/70, architecture 17/17, format 301/0, analyze e build debug Android/iOS
  `PASS`;
- nessun delta runtime/archive/signing; TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 13

- exact review SHA: `0c94618bb2aa187ef9dc7c3e3204894f2437b7ff`;
- prodotto/security `CHANGES_REQUIRED`: 0 P0/P1/P2 e 4 P3;
- `F-040-RR13-GOV-MARKDOWN-01`: raw CommonMark PI/CDATA/tag multilinea e
  README fuori dal rejector passano;
- `F-040-RR13-GOV-SUMMARY-01`: riepilogo README contraddice la fase corrente;
- `F-040-RR13-GOV-COUNT-01`: CA-06/T-04 non sono correlati al source count;
- `F-040-RR13-GOV-PATH-01`: rename implicito e rc Git ignorato rendono lossy
  l'inventario post-SHA;
- closure Fix 12 dirette confermate; gate nominali verdi ma insufficienti;
- report security sealed SHA-256
  `3c90a6276c2e0ac41408355a1021fd450f35bd68d23408d018bd79638a1f9cdc`;
- TestFlight, signing, credenziali e production invariati.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 14

- exact technical SHA: `8389f922580b139e4469c11e343f51361cacb218`;
- `F-040-RR13-GOV-MARKDOWN-01` chiuso: tutti gli opener raw CommonMark,
  inclusi processing instruction, CDATA e tag multilinea, falliscono chiusi;
  il README è incluso nel controllo senza vietare i code fence legittimi;
- `F-040-RR13-GOV-SUMMARY-01` chiuso: il riepilogo README è unico e deve
  coincidere con stato/fase strutturati;
- `F-040-RR13-GOV-COUNT-01` chiuso: CA-06 e T-04 sono righe canoniche,
  correlate al gate security corrente e rifiutano conteggi zero/parziali;
- `F-040-RR13-GOV-PATH-01` chiuso: l'inventario post-SHA è NUL-delimited,
  usa `--no-renames`, conserva source/destination e propaga il return code Git;
- fixture governance 70/70 sui PoC originali e sibling; security source 682,
  fixture 61/61 negative + 7/7 positive;
- `scripts/check.sh` exact-SHA exit 0: 801/801, performance 10/10, repeat
  70/70, architecture 17/17, format 301/0, analyze e build debug Android/iOS
  `PASS`;
- nessun delta runtime/archive/signing; TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 14

- exact review SHA: `37d08d2010956a5671c75bc002a6f00d4d76ad8d`;
- prodotto `APPROVED`; security `CHANGES_REQUIRED`: 0 P0/P1/P2 e 1 P3;
- i quattro finding Fix 13 sono chiusi con probe autonomi e gate 70/70;
- `F-040-RR14-GOV-COUNT-01`: una seconda tabella Markdown visibile può
  duplicare CA-06 o T-04 con conteggi `0/0` perché manca la cardinalità
  globale;
- report security sealed SHA-256
  `2a6441ea50ba4cd99491fcd33c04fef51d90e4462a3482285310c31b180798c7`;
- TestFlight, signing, credenziali e production invariati.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 15

- exact technical SHA: `da014b18a29bd616f436cb998ea212e58c17b254`;
- `F-040-RR14-GOV-COUNT-01` chiuso: CA-06 e T-04 richiedono esattamente
  una riga sia nella tabella canonica sia nell'intero documento;
- le due tabelle sibling visibili con conteggi confliggenti `0/0` falliscono
  chiuse con regressioni dedicate;
- fixture governance 72/72; security source 682, fixture 61/61 negative +
  7/7 positive;
- `scripts/check.sh` exact-SHA exit 0: 801/801, performance 10/10, repeat
  70/70, architecture 17/17, format 301/0, analyze e build debug Android/iOS
  `PASS`;
- nessun delta runtime/archive/signing; TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 15

- exact review SHA: `bb3d986a438c5288808c3d825224f1f564b0af74`;
- prodotto/security `CHANGES_REQUIRED`: 0 P0/P1/P2 e 1 P3;
- `F-040-RR15-GOV-COUNT-01`: il conteggio globale richiede outer pipe e
  cardinalità esatta, quindi ignora varianti GFM visibili senza outer pipe,
  blockquote, trailing whitespace o colonna extra;
- le duplicate canoniche restano correttamente respinte e gli errori `awk`
  falliscono chiusi;
- report security sealed SHA-256
  `d69ca479c0f77640102ab9a7b022e35e241f0d26eefb81a97a9c3529641d71c9`;
- TestFlight, signing, credenziali e production invariati.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 16

- exact technical SHA: `ee0d4818e9abe41a13f3f30d4b937658db91b977`;
- `F-040-RR15-GOV-COUNT-01` chiuso: il conteggio globale considera ogni
  occorrenza CA-06/T-04 su qualunque riga con pipe, mentre il parser canonico
  continua a imporre sezione, tabella e formato dell'attestazione autorevole;
- otto regressioni coprono assenza di outer/trailing pipe, trailing whitespace,
  blockquote ed extra column per entrambe le matrici;
- governance 80/80; security source 682, fixture 61/61 negative + 7/7 positive;
- `scripts/check.sh` exact-SHA exit 0: 801/801, performance 10/10, repeat
  70/70, architecture 17/17, format 301/0, analyze e build debug Android/iOS
  `PASS`;
- nessun delta runtime/archive/signing; TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 16

- exact review SHA: `e01ae0807ce4431e6ebebd34e24a64319d9381da`;
- prodotto/security `CHANGES_REQUIRED`: 0 P0/P1/P2 e 1 P3;
- `F-040-RR16-GOV-COUNT-01`: il conteggio raw non riconosce marker GFM
  semanticamente equivalenti costruiti con entity, escape o emphasis;
- closure diretta Fix 15 confermata; governance 80/80, scanner 682 + 61/61
  negative + 7/7 positive e hygiene verdi;
- report security sealed SHA-256
  `725921680988f34724c4e2ef726262d6e6a77caed2e0d43fbe7b481e95e31bc5`;
- TestFlight, signing, credenziali e production invariati.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 17

- exact technical SHA: `ff52b9d326f001477aa5dac1b72005ed4a707f77`;
- `F-040-RR16-GOV-COUNT-01` chiuso con una policy fail-closed sulle righe con
  pipe: entity, escape, HTML inline, emphasis/link/strike, markup residuo e
  caratteri non ASCII sono vietati;
- restano allowlisted soltanto `NOT_RUN` e l'esatto digest backtick T-02 già
  validato strutturalmente dagli altri controlli;
- otto regressioni nuove coprono entity, escape, emphasis, inline HTML e
  zero-width, oltre alle otto varianti Fix 16; governance 88/88;
- `scripts/check.sh` exact-SHA exit 0: 801/801, performance 10/10, repeat
  70/70, security 682 + 61/61 negative + 7/7 positive, architecture 17/17,
  format 301/0, analyze e build debug Android/iOS `PASS`;
- nessun delta runtime/archive/signing; TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 17

- exact review SHA: `36175e687a8ed913a332f77184fd5acffdae7aa6`;
- prodotto/security `APPROVED`, zero P0/P1/P2/P3;
- 13/13 probe avversariali autonomi, governance 88/88 e report security
  sealed SHA-256
  `a9f961ddd5e99733eb96fe7d50796d269db85d5516b0eed0eadc7b99484c27ae`;
- la CI PR exact-SHA resta il gate successivo e TestFlight/production restano
  invariati.

`CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION`.

### Fix 18

- exact technical SHA: `16384ff7c1f7e857117a6eb2ebdd1b5d6f0e1fdd`;
- CI PR #19 run `32089730726`, exact head `bae1f9be`: job Quality `FAIL`
  perché il checkout `fetch-depth: 1` non conteneva gli SHA tecnici/artifact
  usati dal gate governance; job iOS release candidate `FAIL` dopo build e
  archive su `EMBEDDED_COMPONENT_DIGEST_MISMATCH`;
- il checkout del solo job Quality usa ora `fetch-depth: 0`, preservando il
  boundary read-only e rendendo disponibile la lineage completa;
- regressione YAML dedicata: il job Quality deve avere un unico parametro
  checkout `fetch-depth: 0`;
- il validator iOS riceve il reference `build/ios/iphoneos/Runner.app` prodotto
  nello stesso workspace: framework e dylib sono confrontati whole-Mach-O; il
  wrapper Runner usa ancora un digest whole-Mach-O ma normalizza firma e il
  solo `LC_UUID`, mentre l'UUID Runner/dSYM resta verificato separatamente;
- candidate reale con e senza reference `PASS`, scanner 682/207; fixture iOS
  29/29, test Flutter/YAML 12/12, governance 88/88, security source 682,
  action pin, syntax, format 301/0, analyze e diff check `PASS`;
- nessun delta al runtime applicativo o all'artifact; signing, TestFlight e
  production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 18

- exact HEAD `e86b15aa4c9cfaf67b340ea79b581a69297668c4`;
- reviewer prodotto `APPROVED`, zero P0/P1/P2/P3: full-history e portabilità
  clean-worktree riprodotte, gate impattati verdi;
- security review `CHANGES_REQUIRED`: `F-040-RR18-IOS-REF-01` P2 ha provato
  che candidate e reference co-mutabili accettavano lo stesso tamper `__text`;
  `F-040-RR18-IOS-ARCH-01` P3 ha provato che un framework FAT
  `x86_64 arm64` superava il controllo di membership;
- il finalizer security Fix 18 non ha prodotto un report sealed perché Python
  3.9 non supporta `zip(..., strict=True)`; i finding restano riprodotti e
  validi, senza trasformare il blocco tooling in un falso PASS.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 19

- exact technical SHA: `85f2a01777e43ecd9c521ef0434e601dae3e3340`;
- un nuovo attestor canonicalizza i quattro Mach-O reference subito dopo la
  build e pubblica soltanto quattro SHA-256 come output dello step CI; archive,
  reference e candidate successivi devono corrispondere a quel valore già
  catturato, quindi un paired tamper non può riscrivere il trust anchor;
- reference e candidate richiedono exact `arm64`; una slice FAT non è più
  accettata per semplice presenza della slice arm64;
- regressioni: attestation mancante/malformata, paired reference tamper e FAT;
  validator iOS 33/33 `PASS`;
- candidate reale exact technical SHA `PASS`, source/artifact 683/207;
  Flutter/YAML 12/12, security source 683, action pin, syntax, format 301/0,
  analyze e diff check `PASS`;
- runtime applicativo, artifact, signing, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 19

- exact HEAD `4a9ccf3e4edf0f9fe99a3eadc5f9b8e9659c909d`;
- `F-040-RR18-IOS-REF-01` e `F-040-RR18-IOS-ARCH-01` chiusi nel codice;
- prodotto `CHANGES_REQUIRED`, un P2 e due P3: runbook stale, parser
  attestation non canonico e fixture FAT che falliva sul digest;
- security `CHANGES_REQUIRED`, un P3 sulla fixture exact-arm64; report sealed
  SHA-256 `6f280b6352031e760137c7296811413bf8b56c1b5ecc18125958a773356a0470`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 20

- exact technical SHA: `247a5ee51911aeb5d9a835b75a2640a87291544c`;
- entrambi i flow del runbook acquisiscono l'attestation subito dopo la build
  reference e la passano al validator senza ricalcolarla dopo l'archive;
- test Flutter di parità workflow/runbook e ordine build-attestor-archive;
- il validator accetta solo l'intera forma canonica 4×SHA-256; trailing comma
  e newline sono fixture negative;
- le fixture FAT raggiungono separatamente l'attestor e il validator con
  attestation coerente, verificando le reason exact-arm64;
- validator iOS 36/36, Flutter/YAML 13/13, candidate reale 683/207, security
  683, analyze, action pin, syntax, format e diff check `PASS`;
- runtime, artifact, signing, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 20

- exact HEAD `2fcb7739f5c87d57a53ac50947eb96d12927c564`;
- i tre finding Fix 19 chiusi; prodotto/security `CHANGES_REQUIRED` per due
  P3 nel test harness: il parity test accettava comment-decoy e la reason del
  validator era confrontata come sottostringa;
- report security sealed SHA-256
  `924ae9531ca5e28bc5977706f76db17c8cc11fa8a7d38f81cf7bad8553473631`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 21

- exact technical SHA: `3fdc8c40fc30607dd710677816a6658b7aade030`;
- il test runbook estrae esclusivamente i fenced block Bash, scarta le righe
  commentate e valida cardinalità/ordine nei tre flow; mutant dedicato;
- la reason validator usa confronto full-line e una fixture `_SUFFIX` prova
  che il substring matching non può produrre PASS;
- validator iOS 37/37, Flutter/YAML 14/14, candidate reale 683/207, security
  683, analyze, action pin, syntax, format e diff check `PASS`;
- runtime, artifact, signing, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 21

- exact HEAD `3832f99957e63b5944890f722911c5e072f3b0d6`;
- prodotto `CHANGES_REQUIRED`, un P3: inline comment/no-op e invocation
  composta post-archive superavano il parser lessicale;
- security `CHANGES_REQUIRED`, due P3: lo stesso bypass runbook e reason
  attesa accompagnata da reason duplicate/wrong;
- report security sealed SHA-256
  `6ce9533b0121c2a3b38b983df4cd7c39d36b646191bfe5787164049a32afda49`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 22

- exact technical SHA: `3376caf44a474833c67b7eff37b5fe4b33675520`;
- i tre fenced block richiedono l'intero contenuto eseguibile e ordine
  completo; comment, inline no-op, branch/funzione non eseguiti e attestor
  composto post-archive sono regressioni negative;
- i matcher reason validator e attestor impongono esattamente una riga
  normalizzata, uguale a quella attesa; suffix, duplicate ed exact+wrong sono
  respinti;
- validator iOS 39/39, Flutter/YAML 14/14, candidate reale 683/207, security
  683, analyze, action pin, syntax, format e diff check `PASS`;
- runtime, artifact, signing, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 22

- exact HEAD `74242e6703b81c3edc504e6629059b16e70f1900`;
- prodotto `CHANGES_REQUIRED`, un P3: commenti o blank line dopo `\`
  venivano filtrati prima del confronto e potevano spezzare il comando reale;
- security `CHANGES_REQUIRED`, due P3: continuation-breaker e seconda reason
  con CRLF/trailing-space non conteggiata;
- report security sealed SHA-256
  `b456d1c8337e53c9b9c920ee442b3bc9374a1f710c7120f8ab077eb0e3233c6b`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 23

- exact technical SHA: `8375a08f1ede8337c71d1353255d9df1c238f197`;
- il confronto exact conserva tutte le righe fisiche, incluse commenti e righe
  vuote; fixture comment/blank subito dopo una continuation devono fallire;
- validator e attestor contano tutte le righe col prefisso reserved prima del
  confronto exact; fixture duplicate con CRLF/trailing-space devono fallire;
- validator iOS 41/41, Flutter/YAML 14/14, candidate reale 683/207, security
  683, analyze, action pin, syntax, format e diff check `PASS`;
- runtime, artifact, signing, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 23

- exact HEAD `1f8ee4be6568220a4bd9c42bc02ee7b7a319969b`;
- prodotto/security `CHANGES_REQUIRED`, un P3: `trim()` cancellava
  space/tab/CR dopo `\`, ricostruendo una continuation non eseguita da Bash;
- report security sealed SHA-256
  `01d410fe2036b1c25d13a15d51281313136743b700f960c718aed78e096dba8d`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 24

- exact technical SHA: `f3edb1adea45be2682655a886111c439fa61b55a`;
- il parser applica solo `trimLeft()` e preserva il margine destro fisico;
- fixture dedicate backslash+space, backslash+tab e backslash+CR devono
  fallire insieme ai comment/blank breaker precedenti;
- Flutter/YAML 14/14, governance 88/88, security 683, analyze, action pin,
  syntax, format e diff check `PASS`; iOS 41/41 e candidate 683/207 riusati
  per ancestry, essendo invariati script/runtime/artifact;
- signing, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 24

- exact HEAD `eb2efaa598e44ce1c1ee55b58dddfb49e2c1b218`;
- prodotto/security `CHANGES_REQUIRED`, un P3: `trimLeft()` cancellava un
  `CR` iniziale su una riga continuata, accettando un comando non canonico;
- report security sealed SHA-256
  `3299eebf5015a29184398dd81943f4e8390e1e44e8fa79207d9d00829f05638c`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 25

- exact technical SHA: `a6f813600aa8fd23a8d818904c599c386544200f`;
- rimosse split/trim/filter/reconstruction: i tre fenced block Bash sono
  confrontati direttamente raw byte-for-byte con gli snapshot canonici;
- fixture leading CR più tutti i breaker e decoy precedenti devono fallire;
- Flutter/YAML 14/14, governance 88/88, security 683, analyze, action pin,
  syntax, format e diff check `PASS`; iOS 41/41 e candidate 683/207 riusati
  per ancestry, essendo invariati script/runtime/artifact;
- signing, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 25

- exact HEAD `bb979c030afac3553d00306d677a5e3a52a4b8f4`;
- prodotto/security `CHANGES_REQUIRED`, un P3: il primo blocco canonico
  nascosto dentro un commento HTML restava regex-matchable ma invisibile;
- report security sealed SHA-256
  `696b9e3bae99d41b54a1a6da2aa65332a9923b844f2b79a75de84d769e8d13a2`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 26

- exact technical SHA: `e1b6fca4a2abb409610a47473f7c57a48d9ecc7c`;
- fingerprint SHA-256 dell'intero runbook richiesta prima di ogni parse;
- confronto raw byte-for-byte dei tre blocchi mantenuto come secondo guard;
- fixture HTML comment e blockquote, oltre a tutti i breaker precedenti,
  devono fallire;
- Flutter/YAML 14/14, governance 88/88, security 683, analyze, action pin,
  syntax, format e diff check `PASS`; iOS 41/41 e candidate 683/207 riusati
  per ancestry, essendo invariati script/runtime/artifact;
- signing, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 26

- exact HEAD `2a5bd08c93c9b5bec7a6d7168fe11f626408a706`;
- prodotto e security `APPROVED`, zero P0/P1/P2/P3;
- report security sealed SHA-256
  `6c96f403ee9ee6d9f933774d3ee3293dbc9352c8575def29e708fa8bc0a96e43`;
- CI PR/main exact-SHA, merge e hygiene restavano `NOT_RUN`.

`CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION`.

### Fix 27

- exact technical SHA: `59d35f81344030528e3b19522656f67e275e3f11`;
- la CI PR exact-SHA `32107743243` ha riprodotto due blocker: GNU `grep`
  rifiutava lettura e append sullo stesso file e lo step iOS eseguiva `--app`
  come comando separato per una continuation assente;
- il fixture governance cattura la riga prima dell'append; lo step iOS usa una
  continuation esplicita e il test confronta il `run` YAML multilinea esatto;
- re-review diff-scoped prodotto e security `APPROVED`, zero P0/P1/P2/P3;
- Flutter/YAML 14/14, governance 88/88, security 683, architecture, analyze,
  action pin, syntax, format e diff check `PASS`; il blocco attestor reale
  estratto dal workflow termina con exit 0;
- signing, TestFlight e production invariati; nuova CI exact-SHA richiesta.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 27

- exact review SHA: `46aec479314a58342f58f12bf8efd1c2e2533aab`;
- review diff-scoped prodotto/security `APPROVED`, ma la CI PR exact-SHA
  `32109274228` ha chiuso il gate integrato con `CHANGES_REQUIRED`;
- 4/5 job `PASS`; iOS release ha fallito il candidate per digest whole-Mach-O
  non riproducibile fra build e archive e ha saltato la fixture dipendente;
- finding tecnico P2 `EMBEDDED_COMPONENT_DIGEST_MISMATCH`, nessuna modifica a
  signing, TestFlight o production.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 28

- run PR `32109274228`, exact head
  `46aec479314a58342f58f12bf8efd1c2e2533aab`: Quality, Android debug,
  Android release e iOS Simulator debug `PASS`; iOS release `FAIL` nello step
  candidate con `EMBEDDED_COMPONENT_DIGEST_MISMATCH`; fixture iOS successiva
  non eseguita per dipendenza;
- exact technical SHA: `d6838bd77e9e7578c90a283539aeeb4e0ec1868c`;
- `normalize-ios-macho-uuid.pl` canonicalizza fail-closed l'unico `LC_UUID`
  di thin/fat arm64 senza escludere sezioni eseguibili; reference e candidate
  `objective_c` restano whole-Mach-O bound;
- due clean build/archive in checkout assoluti distinti hanno prodotto i due
  soli digest Runner verificati di Xcode 26.6: l'indirect symbol table è
  identica e la differenza è la scelta completa fra i due slot GOT equivalenti
  di `_objc_msgSend`; entrambi sono exact allowlisted, nessuna sezione viene
  rimossa dal digest;
- candidate reali sui due checkout `PASS`, source/artifact 684/207; una
  mutazione parziale degli Objective-C stub fallisce; fixture iOS 43/43,
  Flutter/YAML 12/12, analyze, security, syntax, format e diff check `PASS`;
- `scripts/check.sh` `PASS`: 804/804 non-performance, performance 10/10,
  resilience repeat 70/70, Android debug e iOS Simulator debug;
- signing, provisioning, TestFlight, runtime applicativo e production
  invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 28

- exact reviewed HEAD:
  `45113accf0af42f6b44abc6957b7aa12dc99ca14`;
- prodotto e security `APPROVED`, zero P0/P1/P2/P3; report security sealed
  SHA-256
  `3e23f695c81e5cf370caf90826d8b8c9f390378d689240a5d26c54eed2eb6806`;
- la CI PR exact-SHA `32116655699` ha chiuso Quality, Android debug/release e
  iOS Simulator `PASS`, ma iOS release ha fallito il candidate con
  `EMBEDDED_BUNDLE_DIGEST_MISMATCH`; build, attestation e archive erano verdi,
  fixture dipendente non eseguita;
- finding tecnico P2: il digest dei resource bundle includeva
  `BuildMachineOSBuild`, metadato Xcode dipendente dal macOS host;
- signing, provisioning, TestFlight e production invariati.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 29

- exact technical SHA: `cd67e37aca282665dbec80e7c2d0e482ee712315`;
- il digest tree dei bundle converte ogni `Info.plist` in JSON canonico e
  rimuove esclusivamente `BuildMachineOSBuild`; ogni altra chiave, path e
  risorsa continua a partecipare al digest SHA-256;
- candidate reale source/artifact 684/207 `PASS`; la fixture con solo host
  build diverso passa, mentre nuova chiave plist e risorsa inattesa falliscono
  `EMBEDDED_BUNDLE_DIGEST_MISMATCH`;
- validator iOS avversariale 45/45, security 684, action pin, syntax e diff
  check `PASS`;
- runtime, firma, provisioning, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 29

- exact review SHA: `9e4b543fc1d56433e08a3c316520e54924dba1f7`;
- review prodotto `APPROVED`, zero P0/P1/P2/P3;
- review security `CHANGES_REQUIRED`, zero P0/P1/P2 e un P3:
  `F-040-RR29-IOS-PLIST-BOUND-01`; un plist valido da 96 MiB veniva
  canonicalizzato in 32,88 secondi con RSS massimo 615.563.264 byte;
- report security sealed SHA-256
  `f60ec18f69ebb73ee2aacf470a9459998fdbf8ac422ccce78dac128460ec8f82`;
- candidate 684/207 e fixture iOS 45/45 restavano verdi; runtime, firma,
  provisioning, TestFlight e production invariati.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 30

- exact technical SHA: `2fa97d1cbc956e4ddbe1bd2ab14f2c4f95be50e1`;
- ogni `Info.plist` dei resource bundle viene misurato con `stat` e rifiutato
  oltre 1 MiB prima di invocare `plutil` o il serializer JSON;
- regressione con plist valido da 1.049.942 byte respinta con
  `EMBEDDED_BUNDLE_DIGEST_UNREADABLE`; esecuzione 6,9 secondi complessivi e
  RSS massimo 26.329.088 byte;
- candidate reale 684/207, validator iOS 46/46 e `scripts/check.sh` `PASS`:
  804/804 non-performance, performance 10/10, repeat 70/70, analyze e build
  debug Android/iOS;
- runtime, firma, provisioning, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 30

- exact review SHA: `8fc931d8fcb5012d7cdf486aa78b480fdf214c13`;
- prodotto/security `CHANGES_REQUIRED`, zero P0/P1/P2 e un P3:
  `F-040-RR30-IOS-PLIST-BOUND-01`;
- un binary plist valido sotto 1 MiB espandeva a circa 49 MiB JSON e il
  validator raggiungeva 387.284.992 byte RSS; inoltre `PlistBuddy` leggeva
  l'identità prima del cap e `stat` riapriva il pathname;
- report security sealed SHA-256
  `249d26f6749abc2a7737d071a1f529513657f264322c4428ce31ca9ce8419a9a`;
- candidate 684/207 `PASS`; fixture reviewer 46/46 interrotta e classificata
  correttamente `NOT_RUN`; signing, TestFlight e production invariati.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 31

- exact technical SHA: `0ac9b5fa3f31c8c31e2057add45bd82b4cc79f17`;
- nuovo canonicalizer Python stdlib legge lo stesso fd tramite component-walk
  `O_NOFOLLOW`, verifica stabilità del file e applica cap 1 MiB input,
  16.384 oggetti/elementi e 4 MiB output canonico;
- rimosse le letture `PlistBuddy` dei resource bundle e la pipeline
  `plutil | JSON::PP`; identity e digest condividono il parser bounded;
- PoC shared-reference: helper 14.385.152 byte RSS e validator 26.279.936
  byte RSS con reason `EMBEDDED_BUNDLE_DIGEST_MISMATCH`; fixture object-count
  oltre 20.000 respinta `EMBEDDED_BUNDLE_DIGEST_UNREADABLE`;
- candidate reale 685/207, validator iOS 48/48, security, syntax, diff e probe
  helper symlink/identity/malformed/determinismo `PASS`;
- runtime, firma, provisioning, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 31

- exact review SHA: `8148c798045164e646bf64120d4ce3f64703650e`;
- prodotto/security `CHANGES_REQUIRED`: un P2
  `F-040-RR31-IOS-PLIST-TOCTOU-01` e due P3 su FIFO bloccante ed entity bomb
  XML; il binary shared-reference di Fix 30 è invece chiuso;
- lo swap deterministico dopo il digest conservava un plist tampered con
  identity valida e `IOS_RELEASE_CANDIDATE_VALID`; un FIFO bloccava prima di
  `fstat`; 26 livelli di entity XML richiedevano 5,78 secondi;
- report security sealed SHA-256
  `2e8430aece87ed94c4a686638a8b25188d51bc2d9437768ca7a9fc0bee52c0b7`;
- candidate 685/207 e fixture iOS 48/48 restavano verdi; signing, TestFlight e
  production invariati.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 32

- exact technical SHA: `b1c98d1aa6805f102ae0e49c046b03351c0f5d4b`;
- il canonicalizer apre il leaf con `O_NONBLOCK`, rifiuta non-regular file,
  internal subset ed entity declaration XML prima di `plistlib`;
- il comando `--validate-identity-and-digest` produce identity e digest dalla
  stessa lettura/fstat bounded; il validator non riapre più il plist fra i due
  controlli;
- regressioni dedicate coprono swap atomico della vecchia API split, identity
  errata con reason precisa, FIFO diretto/end-to-end ed entity bomb a 28
  livelli con timeout discriminante;
- candidate reale 685/207, validator iOS 53/53, security 685, Flutter/YAML
  12/12, governance 88/88, action pin, syntax e diff check `PASS`;
- `scripts/check.sh` exact handoff exit 0: 804/804 non-performance,
  performance 10/10, repeat resilience 70/70, analyze e build debug
  Android/iOS `PASS`;
- runtime, firma, provisioning, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 32

- exact review SHA: `1a2332e4ca574203b73afa7da788072d83ae7a43`;
- prodotto/security `CHANGES_REQUIRED`, P0 0 / P1 0 / P2 1 / P3 0;
- `F-040-RR32-IOS-PLIST-POSTCHECK-01`: identity e digest condividono una
  lettura, ma un replace atomico subito dopo il ritorno del helper lascia nel
  bundle un plist same-identity con `CMCRaceTamper` e il validator raggiunge
  comunque `IOS_RELEASE_CANDIDATE_VALID`;
- FIFO ed EntityDecl/internal subset XML sono chiusi;
- report security sealed SHA-256
  `44c1aa5ade0239f4e586c56b85de2ba01fc8f55c08b00ced9b13924236c90b5c`;
- candidate 685/207, fixture iOS 53/53, governance 88/88 e gate mirati
  restano verdi; la regression corrente intercetta però solo la vecchia flag
  `--digest` e non prova il boundary nuovo.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 33

- exact technical SHA: `1e15fd24e694a40bf5b0afb2f9d1f46f2ae0dbfd`;
- il nuovo attestor exact-tree legge l'intera app con cap preventivi di 4.096
  entry, 128 MiB per file e 512 MiB aggregati, rifiuta symlink/non-regular e
  verifica stabilità di leaf e directory;
- il validator calcola il digest prima e dopo tutti i controlli, fallisce con
  `ARTIFACT_CHANGED_DURING_VALIDATION` se differiscono ed emette il digest
  finale `IOS_RELEASE_ARTIFACT_TREE_SHA256`;
- la regression intercetta `--validate-identity-and-digest` sul path canonico
  effettivo, esegue lo swap post-helper, prova che il tamper è avvenuto e
  richiede la reason exact-tree;
- candidate reale 686/207 `PASS`, digest albero
  `ba2da55082d0a50b42d2cd88c555e552f4b7de05136df19ab4d41441cd9d8f3a`,
  validator iOS 53/53, source/security, governance 88/88, Flutter/YAML 12/12,
  syntax, py_compile, action pin e diff check `PASS`;
- `scripts/check.sh` exact handoff exit 0: 804/804 non-performance,
  performance 10/10, repeat resilience 70/70, analyze e build debug
  Android/iOS `PASS`;
- runtime, firma, provisioning, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 33

- exact review SHA: `d704b6529aea27298d7c75bbf74a1aaf1ac2b81c`;
- prodotto/security `CHANGES_REQUIRED`: P0 0 / P1 0 / P2 2 / P3 2;
- `F-040-RR33-IOS-POSTFINAL-RACE-01`: uno swap dopo la seconda attestazione
  conserva un artifact divergente mentre il validator emette ancora
  `IOS_RELEASE_CANDIDATE_VALID`; il marker upload precede inoltre il gate
  exact-tree finale;
- `F-040-RR33-IOS-ANCESTOR-SWAP-01`: controlli sul path originale e digest
  sul path canonico possono divergere quando un ancestor viene ruotato;
- `F-040-RR33-IOS-TREE-METADATA-01` e
  `F-040-RR33-IOS-TREE-DEPTH-01`: directory vuote/mode non entrano nel digest
  e una profondita di 1.100 directory produce traceback `RecursionError`;
- report security sealed SHA-256
  `a3d57e923e44d8a4bbc2b3cb425b79b686bc27e845b71021b4a88ddf895eb551`;
- candidate 686/207, fixture iOS 53/53, governance 88/88 e gate mirati
  restano verdi, ma non provano un artifact trattenuto e digest-bound.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 34

- exact technical SHA: `793f8a41d5abde0a61bfb669f2ec66980dba523b`;
- il validator risolve una sola volta l'app sorgente in uno snapshot privato,
  esegue su quello snapshot tutti i controlli e produce un payload ZIP
  deterministico, read-only e digest-bound come unico artifact trattenuto;
- `attest-ios-app-tree.py` include directory, mode ed empty directory nel tree
  digest, applica cap di entry, profondita, file e totale, usa open leaf
  non-follow/non-blocking e gestisce profondita invalida senza traceback;
- il seal usa soltanto entry stored sotto `Runner.app/`; l'extractor rifiuta
  traversal, symlink, formati compressi, duplicati e digest payload errato,
  quindi ricalcola e confronta il tree digest estratto;
- il marker candidate e, quando applicabile, il marker upload vengono emessi
  soltanto dopo seal, estrazione e verifica; il runbook vincola il consumer al
  payload e allo SHA-256 pubblicato;
- regressioni post-seal e ancestor swap provano che le mutazioni del path
  originale non entrano nel payload trattenuto; mode, empty directory,
  profondita 65, tamper byte, traversal, symlink e DEFLATED sono fail-closed;
- candidate reale 686/207 `PASS`, tree SHA-256
  `88808438585983a997fbab3c5c54850e559dd7698ac3f0df73604cb8d82aaf2d`,
  sealed payload SHA-256
  `d1e63a6f7ed75d52b9155563e503ed2c43d2066f00d8dac9e987b928ce13e10f`;
- validator iOS 60/60, governance 88/88, Flutter/YAML 12/12,
  security source 686 e fixture 61/61 + 7/7, syntax, pycompile, action pin,
  format, analyze e diff check `PASS`;
- `scripts/check.sh` exact technical SHA exit 0: 804/804 non-performance,
  performance 10/10, repeat resilience 70/70 e build debug Android/iOS
  `PASS`;
- runtime, firma, provisioning, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 34

- exact review SHA: `dd18f8fd8d0068da54c631077e35477ab5cd9366`;
- prodotto `CHANGES_REQUIRED`: P0 0 / P1 0 / P2 3 / P3 3;
- security `CHANGES_REQUIRED`: P0 0 / P1 0 / P2 1 / P3 1;
- `F-040-RR34-IOS-SNAPSHOT-SWAP-01`: snapshot, controlli e seal possono
  riaprire lo stesso pathname dopo sostituzioni e osservare tree differenti;
- `F-040-RR34-IOS-RETAINED-UPLOAD-01`: il seal può cambiare dopo l'ultimo
  hash e il runbook esporta ancora dall'archive sorgente anziché ricostruire
  esclusivamente dal payload verificato;
- `F-040-RR34-IOS-ANCESTOR-OPEN-01` e
  `F-040-RR34-IOS-EXTRACT-SYMLINK-01`: open root non è component-bound e il
  ripristino mode può seguire un ancestor symlink concorrente;
- i P3 richiedono cap ZIP pre-materializzazione, errori redatti, snapshot ed
  extract transazionali e prossima azione Master Plan coerente;
- tree metadata e depth Fix 33 sono chiusi; candidate 686/207, iOS 60/60,
  governance 88/88 e gate mirati restano verdi;
- report security sealed SHA-256
  `16f4b633e587e2083530f30289dc98937a60ead4b6b2e61adff83fe5e9f33d7a`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 35

- exact technical SHA: `906c1dc62427e801f5af68a7d990a0bab4a7433d`;
- il payload ZIP deterministico viene creato prima dei controlli e la snapshot
  di validazione viene estratta dallo stesso descriptor e verificata contro il
  tree digest; il payload interno resta l'unica source trattenuta;
- publish ed extract riaprono i path con component-walk `O_NOFOLLOW`, verificano
  lo SHA-256 prima/durante/dopo la copia e il runbook ricostruisce l'archive di
  export esclusivamente dall'app estratta dal payload exact-SHA;
- extractor e snapshot sono transazionali; directory mode restoration e cleanup
  usano descriptor relativi, mentre EOCD/count/central-directory/path/depth sono
  bounded prima di `ZipFile.infolist`;
- regressioni dedicate coprono post-publish tamper, ancestor swap sulla nuova API,
  ancestor symlink, race mode/symlink, deep tree, duplicate/encrypted/DEFLATED,
  traversal e 4.097 entry con output parziale assente e diagnostica redatta;
- candidate reale 686/207 `PASS`, tree SHA-256
  `88808438585983a997fbab3c5c54850e559dd7698ac3f0df73604cb8d82aaf2d`,
  sealed payload SHA-256
  `d1e63a6f7ed75d52b9155563e503ed2c43d2066f00d8dac9e987b928ce13e10f`;
- validator iOS 65/65, Flutter/YAML 13/13, governance 88/88, security
  source 686 e fixture 61/61 + 7/7, syntax, pycompile, action pin,
  architecture, format, analyze e diff check `PASS`;
- `scripts/check.sh` exact technical SHA exit 0: 804/804 non-performance,
  performance 10/10, repeat resilience 70/70 e build debug Android/iOS
  `PASS`;
- upload-ready reale exit 1 esatto
  `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`; signing, provisioning,
  physical iOS, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 35

- exact review SHA: `00212e02f50a4cc862296b6473b7c2a84abc484a`;
- prodotto/security `CHANGES_REQUIRED`: P0 0 / P1 0 / P2 2 / P3 3
  dopo deduplicazione;

- `F-040-RR35-IOS-SNAPSHOT-RACE-01` P2: ABA malicious→benign→malicious
  consente di validare una snapshot safe e pubblicare il seal unsafe;
- `F-040-RR35-IOS-EXTRACT-ABA-01` P2: hash ZIP A, consumo ZIP B e ripristino
  ZIP A possono estrarre byte non legati allo SHA dichiarato;
- `F-040-RR35-IOS-ZIP-COUNT-01` P3: un EOCD con count falsificato basso
  raggiunge `infolist()` con 50.001 record reali;
- `F-040-RR35-IOS-CLEANUP-ABA-01` P3: una race di profondità durante rollback
  può lasciare la destination creata;
- `F-040-RR35-RUNBOOK-RELATIVE-PATH-01` P3: i due extract documentati usano
  path relativi rifiutati dall'helper absolute-only;
- iOS 65/65, candidate 686/207, Flutter/YAML, governance, architecture,
  analyze, format, syntax e action pin restano verdi; signing, TestFlight e
  production invariati;
- security report sealed SHA-256
  `d2ce42a18882e7293f31332d2f1e6e20a3df8f8f320ee8c1e2b14567f30805b3`.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 36

- exact technical SHA: `9753feac0e455e2f9be326b50e599d64cdeff1ab`;
- il validator mantiene aperto un guard `kqueue` su root, directory e file della
  snapshot sigillata per tutti i controlli e rifiuta write, rename, delete,
  link, extend o revoke prima della pubblicazione del marker candidate;
- l'extractor copia e verifica il payload in un file privato prima di parsare o
  estrarre, impedendo l'interleaving ZIP A-B-A, e confronta il conteggio reale
  dei record central-directory con EOCD prima di `ZipFile.infolist()`;
- il rollback rinomina atomicamente la destination creata in quarantena e la
  elimina con passi e operazioni bounded, senza lasciare output parziali;
- il runbook usa root, archive, snapshot, payload e destination assoluti; il
  flusso upload valida ed esporta la medesima copia archive ricostruita dal
  payload exact-SHA;
- regressioni guard no-mutation/mutation/root-ABA, full validator ABA,
  extract A-B-A, EOCD count falsificato e cleanup profondo sono verdi;
- candidate reale 686/207 `PASS`, tree SHA-256
  `88808438585983a997fbab3c5c54850e559dd7698ac3f0df73604cb8d82aaf2d`,
  sealed payload SHA-256
  `d1e63a6f7ed75d52b9155563e503ed2c43d2066f00d8dac9e987b928ce13e10f`;
- validator iOS 70/70, Flutter/YAML 12/12, governance 88/88, security
  source 686 e fixture 61/61 + 7/7, syntax, pycompile, action pin,
  architecture, format, analyze e diff check `PASS`;
- `scripts/check.sh` exact technical SHA exit 0: 804/804 non-performance,
  performance 10/10, repeat resilience 70/70 e build debug Android/iOS
  `PASS`;
- upload-ready reale exit 1 esatto
  `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`; signing, provisioning,
  physical iOS, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 36

- exact review SHA: `54152d09373acdfc7aa52038aab7b3625b16bb26`;
- prodotto/security `CHANGES_REQUIRED`: P0 0 / P1 0 / P2 1 / P3 2 dopo
  deduplicazione;
- `F-040-RR36-IOS-GUARD-PARENT-ABA-01` P2: il descriptor parent viene
  scartato; un ABA dell'intera directory privata mostra un decoy benigno ai
  controlli path-based mentre guard e seal restano sul bundle malevolo;
- `F-040-RR36-IOS-GUARD-ATTRIB-01` P3: la mask omette `KQ_NOTE_ATTRIB` e un
  chmod ABA può soddisfare transitoriamente il controllo executable;
- `F-040-RR36-IOS-CLEANUP-ABA-01` P3: la quarantine viene riaperta per nome
  senza verifica device/inode e una sostituzione concorrente può cancellare un
  victim diverso;
- extract ZIP A-B-A, count EOCD reale e runbook path/archive sono chiusi;
  iOS 70/70, candidate 686/207, Flutter/YAML 12/12, governance 88/88,
  scanner, architecture, analyze e syntax restano verdi;
- il finalizer security è fallito prima del sealing per schema relativo
  mancante; bundle non sealed preservato, nessun `report.md` dichiarato;
  signing, TestFlight e production invariati.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 37

- exact technical SHA: `102caa49070c7870234119f31d142c79965b1fd2`;
- il guard conserva il descriptor del parent privato e osserva
  rename/delete/revoke dell'ancestor senza introdurre falsi positivi sulle
  scritture legittime dei sibling temporanei;
- root e descriptor figli includono `KQ_NOTE_ATTRIB`; mode e ctime iniziali
  vengono confrontati alla chiusura, così chmod/chown ABA resta fail-closed
  mentre le sole letture del validator non invalidano il candidate;
- il canale guard usa descriptor FIFO già aperti prima del child: una failure
  anticipata produce EOF e gli swap path successivi non possono redirigere il
  controllo;
- il rollback riserva una quarantine random 128-bit, sposta atomicamente la
  destination e pulisce esclusivamente il descriptor/inode originale; collisione
  e swap quarantine preservano il victim e lasciano al massimo un tombstone
  vuoto nel root temporaneo;
- regressioni full-validator parent ABA e mode ABA, più collisione/swap cleanup,
  sono verdi; validator iOS 73/73 e Flutter/YAML 12/12 `PASS`;
- candidate reale 686/207 `PASS`, tree SHA-256
  `88808438585983a997fbab3c5c54850e559dd7698ac3f0df73604cb8d82aaf2d`,
  sealed payload SHA-256
  `d1e63a6f7ed75d52b9155563e503ed2c43d2066f00d8dac9e987b928ce13e10f`;
- governance 88/88, security 61/61 + 7/7, architecture 17/17, analyze,
  format, syntax, pycompile, action pin e diff check `PASS`;
- `scripts/check.sh` exact technical SHA exit 0: 804/804 non-performance,
  performance 10/10, repeat resilience 70/70 e build debug Android/iOS
  `PASS`;
- upload-ready reale exit 1 con reason esatta
  `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`; signing, provisioning,
  physical iOS, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 37

- exact review SHA: `365bdb560f80aa9a924291894dba5eaaac237650`;
- prodotto/security `CHANGES_REQUIRED`: P0 0 / P1 0 / P2 1 / P3 2 dopo
  deduplicazione;
- `F-040-RR37-IOS-GUARD-ANCESTOR-ABA-01` P2: il guard lega il parent
  immediato ma non l'intera ancestor chain; un ABA sopra `tmp_root` mostra un
  decoy ai controlli Bash mentre il seal attacker-controlled resta guardato e
  viene pubblicato come candidate valido;
- `F-040-RR37-IOS-TMP-CLEANUP-01` P3: il trap finale usa `rm -rf` sul pathname
  del temp root e può cancellare una directory victim sostituita dopo STOP;
- `F-040-RR37-IOS-CLEANUP-CHILD-ABA-01` P3: `_clear_directory` non confronta
  l'identità `fstat` del child aperto con lo `stat` precedente e può svuotare
  un victim sostituito;
- immediate-parent ABA, mode/ctime ABA, FIFO early-exit/path swap, collisione
  quarantine e root quarantine victim swap risultano chiusi;
- gate reviewer: iOS 73/73, candidate 686/207, Flutter/YAML 12/12,
  governance 88/88, scanner, architecture, analyze e syntax `PASS`;
- report security sealed SHA-256
  `71a0b2c671636cfb8076000e47314b1443d596114aa04c1e690d8464f41e4711`;
  signing, TestFlight e production invariati.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 38

- exact technical SHA: `96fe31f8b149220a87b6bcb0a64c2f63875fd4e5`;
- il guard apre e conserva descriptor per ogni componente assoluto dalla root
  alla directory privata, registra rename/delete/revoke sugli ancestor e
  verifica nuovamente device/inode per ogni edge prima del verdetto;
- il cleanup del temp root usa l'identità `device,inode` catturata subito dopo
  `mktemp`, riapre il percorso component-bound e rifiuta qualunque sostituzione
  con `TEMP_CLEANUP_REFUSED` prima di emettere marker candidate/upload;
- `_clear_directory` confronta il `fstat` del child appena aperto con lo
  `lstat` precedente, impedendo che lo swap `stat→open` svuoti un victim;
- regressioni full-validator ancestor-chain ABA, temp-root victim swap e
  child-identity swap sono verdi; validator iOS 76/76 e Flutter/YAML 12/12
  `PASS`;
- candidate reale 686/207 `PASS`, tree SHA-256
  `88808438585983a997fbab3c5c54850e559dd7698ac3f0df73604cb8d82aaf2d`,
  sealed payload SHA-256
  `d1e63a6f7ed75d52b9155563e503ed2c43d2066f00d8dac9e987b928ce13e10f`;
- governance 88/88, security 61/61 + 7/7, architecture 17/17, analyze,
  format, syntax, pycompile, action pin e diff check `PASS`;
- `scripts/check.sh` exact technical SHA exit 0: 804/804 non-performance,
  performance 10/10, repeat resilience 70/70 e build debug Android/iOS
  `PASS`;
- upload-ready reale exit 1 con reason esatta
  `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`; signing, provisioning,
  physical iOS, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 38

- exact review SHA: `41e1aef9fb679587af574423b28c3fd86d802430`;
- prodotto/security `CHANGES_REQUIRED`: P0 0 / P1 0 / P2 0 / P3 3 per
  prodotto; security deduplica le tre schedule in un root P3 CWE-367/59;
- `F-040-RR38-IOS-CLEANUP-POSTCLEAR-ABA-01` P3: dopo la ricorsione il child
  viene chiuso e rimosso per nome, consentendo la cancellazione di una victim
  vuota sostituita;
- `F-040-RR38-IOS-TMP-IDENTITY-CAPTURE-01` P3: l'identità viene acquisita in
  un processo successivo a `mktemp` e la sequenza stat/rename resta separata;
- `F-040-RR38-IOS-TMP-TOMBSTONE-LEAK-01` P3: ogni cleanup nominale conserva
  un tombstone, con crescita osservata non bounded;
- ancestor-chain ABA, temp-root swap post-identity e child `stat→open` sono
  chiusi; gate reviewer iOS 76/76, candidate 686/207, Flutter/YAML 12/12,
  governance 88/88, scanner, architecture, analyze e syntax `PASS`;
- report security sealed SHA-256
  `7f25fcfbf8c5702c8424a5c040b3824f600090a69c332b99d17abbe7da27c515`;
  signing, TestFlight e production invariati.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 39

- exact technical SHA: `8b820b96f6f3f288c2194bf0ca2a1dbbd2c5bdbe`;
- la root `cmc-ios-release.*` viene creata e attestata atomicamente da
  `--create-temp-directory` sotto lock esclusivo, con path canonico e identita
  `device,inode` restituiti nello stesso processo;
- il cleanup non usa piu terminali `unlink`/`rmdir`: ogni entry viene spostata
  con `renameatx_np(RENAME_EXCL)`, confrontata per identita e svuotata tramite
  descriptor; hardlink, collisioni e sostituzioni falliscono chiusi;
- i tombstone trattenuti sono privi di payload e soggetti al cap fail-closed di
  512 entry per parent temporaneo; le nuove root Fix 39 ispezionate conservano
  zero file non vuoti, mentre i residui storici dei fix precedenti non vengono
  alterati distruttivamente;
- regressioni root pre-identity, post-clear directory swap, terminali name-based,
  hardlink e retention cap sono verdi; validator iOS 80/80 e Flutter/YAML 12/12
  `PASS`;
- candidate reale 686/207 `PASS`, unsigned; tree SHA-256
  `88808438585983a997fbab3c5c54850e559dd7698ac3f0df73604cb8d82aaf2d`
  e sealed payload SHA-256
  `d1e63a6f7ed75d52b9155563e503ed2c43d2066f00d8dac9e987b928ce13e10f`;
- `scripts/check.sh` exact technical SHA exit 0: 804/804 non-performance,
  performance 10/10, repeat resilience 70/70, security 686 + 61/61 + 7/7,
  governance 88/88, architecture 17/17, analyze/format e build debug
  Android/iOS `PASS`;
- upload-ready reale exit 1 con reason esatta
  `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`; signing, provisioning,
  physical iOS, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 39

- exact review SHA: `338a0e7ac46e697e23e2cb67f38c449c01fb52eb`;
- prodotto e security `CHANGES_REQUIRED`: P0 0 / P1 0 / P2 0 / P3 3;
- `F-040-RR39-IOS-HARDLINK-TOCTOU-01`: un hardlink creato dopo il primo
  controllo `st_nlink == 1` viene troncato insieme all'inode temporaneo;
- `F-040-RR39-IOS-LOCK-ABA-CAP-01`: unlink/recreate del pathname lock separa
  due flock e consente a due creator di superare il cap;
- `F-040-RR39-IOS-RETAINED-NAME-ABA-01`: il set retained basato sul nome
  salta un replacement nonzero introdotto dopo la quarantine;
- closure Fix 38 confermata per post-clear ABA e temp identity capture; il cap
  nominale richiede il fix lock ABA;
- gate reviewer: iOS 80/80, candidate 686/207, Flutter/YAML 12/12,
  governance 88/88, architecture 17/17, analyze/format/syntax/pins/diff
  `PASS`; upload-ready resta bloccato sulla Distribution signature;
- report security sealed SHA-256
  `25c488eb561cf1f74459ba7c56b9ee51f5551310bd6bd4ea3669cb66ce58e979`;
  signing, TestFlight e production invariati.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 40

- exact technical SHA: `7fdd29a6ffd8f10d2c6a065cc30ad5c4220f4ff1`;
- il cleanup ripete `st_nlink == 1` sul descriptor e sulla entry quarantine
  immediatamente prima del truncate e lo riattesta dopo fsync, preservando i
  byte dell'alias nel probe late-hardlink;
- la serializzazione usa `flock` direttamente sul descriptor del parent
  component-bound; il test interprocess sostituisce continuamente il vecchio
  pathname lock e con cap 1 produce esattamente una root;
- retained non è più un set di nomi: ogni pass confronta device/inode/mode e,
  per i file, link-count e size zero; replacement file/directory post-quarantine
  viene rilevato e preservato con cleanup fail-closed;
- i parent temporanei con tab/newline sono respinti prima della `mkdir`, senza
  root residue; il cap resta 512 e il default TMPDIR locale contava 416 entry
  storiche/bounded dopo i probe, senza cancellazioni manuali;
- validator iOS 84/84, Flutter/YAML 12/12, governance 88/88, security
  61/61 + 7/7, architecture 17/17, analyze/format/syntax/pins/diff `PASS`;
- candidate reale 686/207 `PASS`, unsigned; tree SHA-256
  `88808438585983a997fbab3c5c54850e559dd7698ac3f0df73604cb8d82aaf2d`
  e sealed payload SHA-256
  `d1e63a6f7ed75d52b9155563e503ed2c43d2066f00d8dac9e987b928ce13e10f`;
- `scripts/check.sh` exact technical SHA exit 0: 804/804 non-performance,
  performance 10/10, repeat resilience 70/70 e build debug Android/iOS;
- upload-ready reale exit 1 con reason esatta
  `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`; signing, provisioning,
  physical iOS, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 40

- exact review SHA: `37ac7524b300a8d0c0106bf02c327532d4d321e6`;
- prodotto e security `CHANGES_REQUIRED`: P0 0 / P1 0 / P2 0 / P3 3;
- `F-040-RR40-IOS-HARDLINK-FTRUNCATE-01`: un hardlink iniettato dentro
  l'ultima chiamata `ftruncate` viene troncato prima del post-check;
- `F-040-RR40-IOS-RETAINED-POSTVALIDATE-ABA-01`: replacement file/directory
  dopo l'ultima validazione retained può lasciare payload nonzero con cleanup
  dichiarato riuscito;
- `F-040-RR40-IOS-CAP-ADVISORY-RACE-01`: una entry non cooperativa fra count e
  `mkdir` supera il cap pur restituendo un record valido;
- closure diretta Fix 39 confermata per late-link post-quarantine, legacy-lock
  ABA cooperativo, replacement immediato post-quarantine e parent speciale;
- gate reviewer: iOS 84/84, candidate 686/207, Flutter/YAML 14/14,
  governance 88/88, architecture 17/17, analyze/format/syntax/pins/diff
  `PASS`; upload-ready resta bloccato sulla Distribution signature;
- report security sealed SHA-256
  `48421238422626c0eae874ae97284e50335ca342b3896eeb20593f4b1c5d4ebd`;
  signing, TestFlight e production invariati.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 41

- exact technical SHA: `dda9c1f8a4933267d625c72a8c20db834260811d`;
- prima di azzerare un file, il cleanup copia al massimo 128 MiB nel buffer
  anonimo `BytesIO`; se il link-count cambia dentro `ftruncate`, ripristina i
  byte e fallisce chiuso senza alterare l'alias esterno;
- retained file, directory e FIFO sono riaperti via descriptor, verificati per
  identity/timestamp/link-count e attraversati ricorsivamente per payload zero;
  servono due pass terminali stabili prima del successo;
- dopo `mkdir` la parent chain e il conteggio cap sono verificati due volte;
  un inserimento non cooperativo sopra il cap rimuove soltanto la root appena
  creata e non restituisce alcun record;
- l'oracolo lock richiede esplicitamente `LOCK_EX`; regressioni exact-window
  hardlink, retained file/directory/child e count-to-mkdir `PASS`;
- due tentativi intermedi della suite hanno correttamente rilevato FIFO non
  ammessi e backup `TemporaryFile` name-based; entrambi sono stati corretti
  prima del commit tecnico e il run finale è 86/86 `PASS`;
- Flutter/YAML 12/12, governance 88/88, security 61/61 + 7/7, architecture
  17/17, analyze/format/syntax/pins/diff `PASS`;
- candidate reale 686/207 `PASS`, unsigned; tree SHA-256
  `88808438585983a997fbab3c5c54850e559dd7698ac3f0df73604cb8d82aaf2d`
  e sealed payload SHA-256
  `d1e63a6f7ed75d52b9155563e503ed2c43d2066f00d8dac9e987b928ce13e10f`;
- `scripts/check.sh` exact technical SHA exit 0: 804/804 non-performance,
  performance 10/10, repeat resilience 70/70 e build debug Android/iOS;
- upload-ready reale exit 1 con reason esatta
  `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`; signing, provisioning,
  physical iOS, TestFlight e production invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Re-review Fix 41

- exact review SHA: `e0c36cb2931c857cde796367e1fe8dd33e957fbd`;
- prodotto `CHANGES_REQUIRED`: P0 0 / P1 0 / P2 0 / P3 4;
- `F-040-RR41-IOS-RETAINED-FINAL-NAMESPACE-ABA-01`: replacement nonzero
  dopo l'ultima validazione retained viene accettato dal ritorno terminale;
- `F-040-RR41-IOS-RETAINED-FINAL-CHILD-ABA-01`: un child nonzero aggiunto
  allo stesso inode directory dopo l'ultima validazione viene accettato;
- `F-040-RR41-IOS-CAP-FINAL-COUNT-RACE-01`: una entry inserita dopo
  l'ultimo count produce un record sopra cap;
- `F-040-RR41-IOS-ROLLBACK-RMDIR-ABA-01`: il rollback name-based può
  cancellare una directory-vittima vuota sostituita dopo i controlli;
- security `CHANGES_REQUIRED`: P0 0 / P1 0 / P2 0 / P3 4, aggregando le
  due varianti retained e aggiungendo l'undercount reviewer Fix 40;
- hardlink dentro `ftruncate`, backup bounded, FIFO e `LOCK_EX` risultano
  chiusi; la minaccia repository-controlled same-UID resta in scope;
- gate reviewer: iOS 86/86 in 739 s, candidate 686/207, Flutter/YAML
  corrente 12/12, governance 88/88, architecture 17/17 e upload-negative
  esatto `PASS`; reference aggregate pre/post identica;
- report security sealed SHA-256
  `12262eff11ef5616c813aa320142b7b6f3269bfed9de669688d51deb32d75207`;
  signing, TestFlight e production invariati.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 42

- exact technical SHA: `1d4d5e03995ac6873cd48c54d827b8e031ef013a`;
- la threat capability repository-controlled same-UID resta in scope: `flock`
  e advisory, mode `0700` e ACL dello stesso owner non sono un confine e
  macOS non offre qui delete fd-bound o lock filesystem obbligatori;
- fixed pool e quarantine opaca chiudono quota/retained soltanto se il GC
  resta `NOT_RUN` fino a un teardown affidabile dei writer; nello stesso UID
  un processo detached può continuare a mutare il namespace;
- l'implementazione sicura richiede supervisor con UID distinto, sandbox/ACL
  enforceable o runner/VM effimera distrutta dopo il job;
- restringere il contratto ai soli writer cooperativi sotto `LOCK_EX` richiede
  una decisione esplicita del `USER_APPROVER` e non è stata assunta;
- nessun ulteriore re-check temporale è stato aggiunto; blocker, oracle e
  alternative sono registrati in
  `docs/TASKS/EVIDENCE/TASK-040/fix42-isolation-blocker.md`;
- gate reviewer Fix 41 restano evidence: iOS 86/86, candidate 686/207,
  governance 88/88 e upload-negative esatto; nessun upload o accesso
  production.

`CODEX_FIX_BLOCKED_TO_RE_REVIEW`.

### Re-review Fix 42

- exact review SHA: `f59cf91a288ff97c3899e235c843192bce6aca7d`;
- prodotto `CHANGES_REQUIRED`: P0 0 / P1 0 / P2 0 / P3 1;
- `F-040-RR42-GOV-BLOCKED-ROW-BINDING-01`: mutare soltanto la riga backlog
  TASK-040 da `BLOCKED` a `TODO`, lasciando header/task/evidence/manifest
  bloccati, produceva governance exit 0;
- il checker contava e correlava soltanto le righe `ACTIVE`, senza imporre
  sempre esattamente una riga del task corrente con stato uguale all'header;
- il blocker tecnico Fix 42 è confermato e richiede ancora un boundary esterno
  o una decisione esplicita del `USER_APPROVER` sul threat model;
- governance nominale 88/88, syntax e diff `PASS`; suite iOS non rieseguita
  correttamente perché il codice release è invariato.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 43

- exact technical SHA: `a116f1197b6a7085ba92a21ccfa7336dd316b8c4`;
- il checker richiede sempre esattamente una riga globale e canonica del task
  corrente nel backlog, anche quando lo stato header è `BLOCKED`;
- lo stato della riga TASK-040 deve coincidere con `Stato task`; il probe
  Fix 42 con header/task/evidence/manifest `BLOCKED` e backlog `TODO` fallisce
  ora con diagnostica specifica;
- una seconda riga TASK-040 fuori dalla tabella canonica è respinta dalla
  cardinalità globale, evitando fonti roadmap contraddittorie;
- `bash -n`, governance canonica, fixture governance 91/91 e `git diff
  --check` sono `PASS`; codice release, artifact e boundary iOS sono invariati;
- il finding governance Fix 42 è corretto, ma il blocker di isolamento
  same-UID resta esterno e non viene reinterpretato come `PASS`.

`CODEX_FIX_BLOCKED_TO_RE_REVIEW`.

### Re-review Fix 43

- exact review SHA: `41f1fce1651e936299bd4af5bdf23ed10e609962`;
- prodotto `CHANGES_REQUIRED`: P0 0 / P1 0 / P2 0 / P3 1;
- `F-040-RR43-GOV-GLOBAL-INDENTED-DUPLICATE-01`: una seconda riga
  TASK-040 fuori tabella con 1–3 spazi iniziali è CommonMark visibile, ma il
  conteggio globale `^\|` la ignorava e il checker restava exit 0;
- closure Fix 42 confermata per `BLOCKED -> TODO`, `DONE` e
  `VALIDATED_PENDING_INTEGRATED_REVIEW`, duplicate non indentate e relocation;
- governance 91/91, syntax, action pins, diff e hygiene `PASS`; codice release
  invariato e suite iOS correttamente non duplicata;
- la lane security separata non ha restituito un handoff dopo timeout ed è
  stata interrotta senza attribuire verdict o report; sarà rieseguita sul Fix44;
- il blocker di isolamento same-UID resta confermato e separato.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Fix 44

- exact technical SHA: `3d9dd674d0fff7566345afbb42de99f486fa1ab0`;
- il conteggio globale normalizza ora 0–3 spazi iniziali prima di riconoscere
  le righe backlog, sia per la cardinalità `ACTIVE` sia per TASK-040;
- le duplicate TASK-040 fuori tabella con 1, 2 e 3 spazi CommonMark vengono
  tutte respinte, mantenendo esattamente una riga globale e canonica;
- restano verdi le regressioni `BLOCKED -> TODO`, `DONE`,
  `VALIDATED_PENDING_INTEGRATED_REVIEW`, duplicate non indentate e relocation;
- `bash -n`, governance canonica, fixture 94/94, action pins e diff-check
  `PASS`; codice release, artifact e suite iOS sono invariati;
- il finding Fix 43 è corretto, ma l'isolamento same-UID resta un prerequisito
  esterno e non viene convertito in `PASS`.

`CODEX_FIX_BLOCKED_TO_RE_REVIEW`.

## Chiusura

- **Classificazione target**: `DONE_TESTFLIGHT_UPLOADED` oppure
  `TECHNICALLY_COMPLETE_EXTERNAL_CREDENTIAL_REQUIRED`
- **Production App Store**: vietata
- **Data completamento**: non ancora
