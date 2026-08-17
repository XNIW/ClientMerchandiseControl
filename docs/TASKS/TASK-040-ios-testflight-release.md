# TASK-040 — iOS TestFlight release

## Informazioni generali

- **Task ID**: TASK-040
- **Titolo**: iOS TestFlight release
- **File task**: `docs/TASKS/TASK-040-ios-testflight-release.md`
- **Stato**: ACTIVE
- **Fase**: REVIEW
- **Responsabile**: CODEX_RE_REVIEWER
- **Data creazione**: 2026-08-17
- **Ultimo aggiornamento**: 2026-08-17
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-040/`
- **Handoff**: CODEX_FIX_COMPLETE_TO_RE_REVIEW

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

## Chiusura

- **Classificazione target**: `DONE_TESTFLIGHT_UPLOADED` oppure
  `TECHNICALLY_COMPLETE_EXTERNAL_CREDENTIAL_REQUIRED`
- **Production App Store**: vietata
- **Data completamento**: non ancora
