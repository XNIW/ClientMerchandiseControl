# iOS TestFlight release runbook

Questo runbook prepara e valida esclusivamente TestFlight. Non autorizza una release
App Store production, non genera certificati o profili e non accetta credenziali nel
repository o nei log.

## Candidate canonico

- bundle: `com.xniw.clientmerchandisecontrol`;
- version/build: `0.1.0 (1)`;
- scheme/configuration: `Runner / Release`;
- minimum iOS: `14.0`;
- build config: `config/app_config.production.release.json`;
- fallback provider: OAuth, Maps, push, analytics/crash e online payment restano
  fail-closed finché i rispettivi activation gate non sono approvati.

```bash
flutter clean
flutter pub get --enforce-lockfile
bash scripts/check-ios-release.sh --source-only
flutter build ios --release --no-codesign \
  --dart-define-from-file=config/app_config.production.release.json
cmc_ios_reference_output="$(
  bash scripts/create-ios-reference-attestation.sh \
    --app build/ios/iphoneos/Runner.app
)"
case "${cmc_ios_reference_output}" in
  IOS_REFERENCE_ATTESTATION=*) ;;
  *) exit 1 ;;
esac
cmc_ios_reference_attestation="${cmc_ios_reference_output#IOS_REFERENCE_ATTESTATION=}"
[[ "${cmc_ios_reference_attestation}" =~ \
  ^[0-9a-f]{64}(,[0-9a-f]{64}){3}$ ]] || exit 1
xcodebuild archive \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/ios/archive/Runner.xcarchive \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO
bash scripts/check-ios-release.sh \
  --app build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app \
  --archive build/ios/archive/Runner.xcarchive \
  --reference-app build/ios/iphoneos/Runner.app \
  --reference-attestation "${cmc_ios_reference_attestation}"
```

Il candidate unsigned dimostra build, archive, bundle/version, architettura, privacy,
security scan e dSYM. Non è installabile su device e non è caricabile su TestFlight.

## Input esterni per export/upload

Owner Apple Developer/App Store Connect deve fornire tramite keychain/secret store:

- certificato `Apple Distribution` valido e fingerprint SHA-256 approvato;
- App Store provisioning profile per il bundle, senza device list né
  `get-task-allow`, con Team ID approvato;
- accesso al record App Store Connect del bundle;
- API key App Store Connect least-privilege, Key ID e Issuer ID;
- conferma `IOS_TESTFLIGHT_UPLOAD_AUTHORIZED=true` per il solo canale TestFlight;
- privacy owner approval, Support/Privacy URL, review contact e account/procedura
  review; i valori `NEEDS_OWNER_VALUE` non vanno sostituiti con dati inventati.
- file JSON runtime production esterno e completo: backend HTTPS, publishable key,
  callback canonica, shop slug e capability flag fail-closed. Il file non va
  versionato né stampato.

Il preflight upload legge solo i file indicati e non stampa chiavi, certificati,
profile o subject. Gli input richiesti sono:

```text
IOS_TESTFLIGHT_UPLOAD_AUTHORIZED
IOS_EXPECTED_TEAM_ID
IOS_EXPECTED_SIGNING_CERT_SHA256
IOS_RELEASE_RUNTIME_CONFIG_PATH
APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_API_KEY_PATH
```

Il build firmato deve usare lo stesso file runtime che verrà attestato. Il path deve
essere canonico, un file regolare non-symlink di massimo 64 KiB. Calcolare il digest
semantico senza stampare i valori e passarlo insieme allo stesso file:

```bash
export IOS_RELEASE_RUNTIME_CONFIG_PATH=/path/esterno/production.json
IOS_RELEASE_CONFIG_SHA256="$(dart run tool/check_ios_runtime_config.dart \
  --config "${IOS_RELEASE_RUNTIME_CONFIG_PATH}")"
flutter build ios --release \
  --dart-define-from-file="${IOS_RELEASE_RUNTIME_CONFIG_PATH}" \
  --dart-define="RELEASE_CONFIG_SHA256=${IOS_RELEASE_CONFIG_SHA256}"
cmc_ios_reference_output="$(
  bash scripts/create-ios-reference-attestation.sh \
    --app build/ios/iphoneos/Runner.app
)"
case "${cmc_ios_reference_output}" in
  IOS_REFERENCE_ATTESTATION=*) ;;
  *) exit 1 ;;
esac
cmc_ios_reference_attestation="${cmc_ios_reference_output#IOS_REFERENCE_ATTESTATION=}"
[[ "${cmc_ios_reference_attestation}" =~ \
  ^[0-9a-f]{64}(,[0-9a-f]{64}){3}$ ]] || exit 1
```

`AppConfig` e il validator condividono parser, set esatto di otto chiavi e regole di
canonicalizzazione. Il digest SHA-256 è calcolato sulla rappresentazione semantica
canonica, non sui byte o sull'ordine del JSON. `AppConfig` rifiuta production se il
digest non corrisponde ai valori realmente compilati. Il validator richiede esattamente
un marker completo `CMC_RELEASE_CONFIG_ATTESTATION_V1:<digest>` nel Mach-O Dart
`Frameworks/App.framework/App`; un digest-esca, un file diverso/incompleto o la shell
compilata con il template fail-closed non può raggiungere upload-ready.

Dopo un archive firmato nella stessa sessione, senza ricalcolare l'attestazione
successivamente all'archive, eseguire prima:

```bash
bash scripts/check-ios-release.sh \
  --app build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app \
  --archive build/ios/archive/Runner.xcarchive \
  --reference-app build/ios/iphoneos/Runner.app \
  --reference-attestation "${cmc_ios_reference_attestation}" \
  --require-upload-ready
```

Il path `--app` deve essere esattamente l'app interna all'archive. Il profilo embedded
è ammesso dallo scanner solo in quel root path, dopo decode CMS e controlli App Store;
profili altrove restano vietati.

Solo l'output `IOS_TESTFLIGHT_UPLOAD_INPUTS_VALIDATED` consente di procedere. Creare
un `ExportOptions.plist` esterno al repository con method App Store Connect, team e
signing approvati, quindi eseguire `xcodebuild -exportArchive` in una directory
temporanea. Validare nuovamente IPA e checksum prima di un upload tramite Xcode o
transport Apple autenticato con la API key. Non usare `--upload` né promuovere il
build senza un nuovo gate owner esplicito sul candidate firmato.

## Entitlement e activation boundary

- custom callback scheme: presente e bounded;
- Universal Links: bloccato finché owner fornisce dominio HTTPS e file AASA verificato;
- push/APNs: bloccato finché capability, entitlement e backend sender production sono
  configurati insieme;
- Maps: `NOT_CONFIGURED`; attivazione separata richiede billing, quota e key iOS
  ristretta al bundle;
- location cliente: non richiesta e nessuna `NSLocation*UsageDescription` va aggiunta;
- account deletion web URL, privacy/support URL e review credentials:
  `NEEDS_OWNER_VALUE` nella store metadata.

## TestFlight smoke e rollback

Usare solo account/ordini staging sintetici e nessun acquisto reale. Verificare cold
start, guest catalog, auth callback dove autorizzato, cart/revalidation, checkout
senza charge, ordini, deep link, background/foreground, status-only tracking e
accessibility smoke. Non inserire PII, token, coordinate o URL tracking nei feedback.

Un build TestFlight errato va disabilitato per i tester e sostituito con build number
incrementato; non riusare lo stesso build. Provider non essenziali restano OFF durante
la diagnosi. Una regressione auth/checkout/privacy o un crash P0/P1 blocca ogni gruppo
tester e richiede nuova review exact-SHA.
