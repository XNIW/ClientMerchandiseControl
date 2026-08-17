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

`android/key.properties`, keystore e credenziali sono ignorati da Git. Una
configurazione parziale o un keystore assente interrompono Gradle prima della
build. Il release build non usa mai il debug signing.

## Validator

Il validator controlla R8/obfuscation/optimization, resource shrinking, mapping,
ABI, package/version, `debuggable=false`, cleartext disabilitato, policy CA di
sistema, Maps `NOT_CONFIGURED` con flag Dart spenti, deep link canonico, guard sul
receiver esportato, signature state, SHA-256 e secret scan degli artifact.

```sh
bash scripts/check-android-release.sh --source-only
```

Per richiedere esplicitamente la readiness di upload:

```sh
PLAY_INTERNAL_UPLOAD_AUTHORIZED=true \
PLAY_SERVICE_ACCOUNT_JSON_PATH=/path/owned/service-account.json \
bash scripts/check-android-release.sh \
  --aab build/app/outputs/bundle/release/app-release.aab \
  --apk build/app/outputs/flutter-apk/app-release.apk \
  --require-upload-ready
```

Il comando non esegue l'upload. Non stampa password, chiavi, alias, path di
credential o contenuti del service account.

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
7. eseguire smoke Internal senza acquisti reali e registrare release ID/versione;
8. non promuovere alcun track oltre Internal in questo release train.

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
