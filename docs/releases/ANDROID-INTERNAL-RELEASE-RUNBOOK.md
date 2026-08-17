# Android Internal Testing release runbook

## Confine

Questo runbook produce e valida un release candidate Android. L'unico target di
upload ammesso è **Google Play Internal testing**. Nessun comando qui promuove una
release in production, avvia un rollout pubblico, crea credenziali o modifica
provider/backend.

Il package canonico è `com.xniw.clientmerchandisecontrol`; la versione corrente è
`0.1.0+1`. Prima di ogni upload il proprietario Play deve confermare che il
`versionCode` non sia già stato usato.

## Configurazione production-like fail-closed

`config/app_config.production.release.json` contiene soltanto flag pubblici e
disabilitati. Non contiene backend, callback, shop o secret. La build risultante
fallisce chiusa al bootstrap finché la configurazione production completa non è
fornita da un secret store approvato; non degrada a development o staging.

Build canonica pulita:

```sh
flutter clean
flutter pub get --enforce-lockfile
flutter build appbundle --release \
  --dart-define-from-file=config/app_config.production.release.json
flutter build apk --release \
  --dart-define-from-file=config/app_config.production.release.json
bash scripts/check-android-release.sh \
  --aab build/app/outputs/bundle/release/app-release.aab \
  --apk build/app/outputs/flutter-apk/app-release.apk
```

L'APK è un derivato locale per ispezionare il manifest compilato; l'AAB è il solo
artifact candidabile a Play. Nessun artifact viene versionato.

## Signing

Il signing release è configurabile soltanto con tutti e quattro i valori, mai in
forma parziale:

| Variabile CI | `android/key.properties` locale | Contenuto |
|---|---|---|
| `ANDROID_KEYSTORE_PATH` | `storeFile` | path di un keystore approvato |
| `ANDROID_KEYSTORE_PASSWORD` | `storePassword` | secret store only |
| `ANDROID_KEY_ALIAS` | `keyAlias` | alias approvato |
| `ANDROID_KEY_PASSWORD` | `keyPassword` | secret store only |

La readiness di upload richiede inoltre
`ANDROID_SIGNING_CERT_SHA256`, valorizzato dal release owner con il fingerprint
SHA-256 pubblico del certificato di upload approvato. Il validator confronta lo
stesso signer sull'AAB (`jarsigner`/`keytool`) e sull'APK (`apksigner`, incluse
le firme v2-only); per l'AAB usa la verifica strict per-entry, rifiuta entry
post-sign e richiede un unico signature block/certificato. Il valore non viene
stampato.

`android/key.properties`, keystore e credenziali sono ignorati da Git. Una
configurazione parziale o un keystore assente interrompono Gradle prima della
build. Il release build non usa mai il debug signing.

## Validator

Il validator controlla R8/obfuscation/optimization, resource shrinking, mapping,
ABI, package/version, `debuggable=false`, cleartext disabilitato, policy CA di
sistema, Maps `NOT_CONFIGURED` con flag Dart spenti, deep link canonico,
allowlist esatta di permission e componenti esportati, signature state, SHA-256
e secret scan degli artifact. Legge
direttamente il manifest protobuf dell'AAB, confronta i `libapp.so` AAB/APK per
ogni ABI e riconosce gli archivi dal contenuto. Prima dell'estrazione la
scansione security impone al massimo 2.048 entry, 512 MiB compressi e non
compressi e rapporto di espansione massimo 200×. Include payload, entry
duplicate, central directory bounded a 4 MiB (nomi, commento globale,
commenti per-entry ed extra field) e container raw, anche se il file è
rinominato; il release validator accetta soltanto estensioni canoniche `.aab`
e `.apk`.

```sh
bash scripts/check-android-release.sh --source-only
```

Per richiedere esplicitamente la readiness di upload:

```sh
PLAY_INTERNAL_UPLOAD_AUTHORIZED=true \
PLAY_SERVICE_ACCOUNT_JSON_PATH=/path/owned/service-account.json \
PLAY_SERVICE_ACCOUNT_EXPECTED_EMAIL=release-owner@owned-project.iam.gserviceaccount.com \
PLAY_SERVICE_ACCOUNT_EXPECTED_PROJECT_ID=owned-project \
ANDROID_SIGNING_CERT_SHA256=<approved-public-sha256> \
bash scripts/check-android-release.sh \
  --aab build/app/outputs/bundle/release/app-release.aab \
  --apk build/app/outputs/flutter-apk/app-release.apk \
  --require-upload-ready
```

Il comando non esegue l'upload. `ANDROID_INTERNAL_UPLOAD_INPUTS_VALIDATED`
significa soltanto che artifact, signer e forma/identità attesa della credenziale
sono coerenti; accesso reale a package e track resta da verificare con Play e non
è inferito dal file locale. Il comando non stampa password, chiavi, alias, path
di credential o contenuti del service account. `/dev/null`, JSON malformato,
account/progetto diversi e fingerprint non corrispondente falliscono chiusi.

## Internal testing activation checklist

Owner: release/store owner.

1. confermare accesso al Play Console e all'app con package canonico;
2. approvare Google Play App Signing e fornire l'upload keystore tramite secret
   store;
3. confermare un `versionCode` non ancora usato;
4. completare i valori `NEEDS_OWNER_VALUE` e le dichiarazioni Data safety;
5. fornire autorizzazione esplicita al solo track Internal e credenziale scoped,
   oppure caricare manualmente l'AAB firmato;
6. rieseguire il validator con `--require-upload-ready`;
7. verificare read-only che service account, package e track Internal siano
   effettivamente accessibili, quindi eseguire l'upload soltanto se autorizzato;
8. eseguire smoke Internal senza acquisti reali e registrare release ID/versione;
9. non promuovere alcun track oltre Internal in questo release train.

## Capability esterne ancora chiuse

- Android App Links/OAuth: richiedono dominio HTTPS posseduto, `assetlinks.json`,
  fingerprint del certificato release e redirect provider esatto. Finché assenti,
  OAuth production resta vietato e il deep link storefront usa lo scheme bounded;
- Maps: key assente significa adapter nativo disabilitato e UI status-only;
- notifiche, analytics e crash reporting: nessuna configurazione remota è inclusa;
- online payment: resta disabilitato server-authoritatively.

## Recovery

Un candidato non caricato si scarta senza mutazioni remote. Un artifact caricato in
Internal può essere disattivato nel track e sostituito soltanto da un
`versionCode` superiore. Non riusare o sovrascrivere artifact firmati e non
eliminare la chiave di upload senza seguire la procedura di reset Play Console.
