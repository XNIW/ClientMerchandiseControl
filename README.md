# ClientMerchandiseControl

Applicazione Flutter Android/iOS destinata ai clienti dei negozi dell'ecosistema
Merchandise Control. Il codice include catalogo, account, carrello, checkout,
ordini, consegna, inbox, assistenza e recensioni. Il readback TEST TASK-054
del9 ottobre 2026 rileva32/57RPC conformi,25 mancanti e quattro migration non
applicate; risorse esterne restano da configurare per OAuth, indirizzi assistiti e push: il prodotto non è dichiarato
operativamente completo. Il [rapporto verificabile](docs/TASKS/EVIDENCE/TASK-054/README.md)
separa codice, SQL locale, staging, dispositivi e distribuzione. Quality8fc è PASS
1095test/1SKIP+11performance. Il nuovo Prepare iOS headless passa, ma SDK27
non compila il target14 richiesto; le prove UI dipendenti restano NOT_RUN.

## Relazione con Merchandise Control

Il client consuma il dominio pubblico Storefront sul Supabase esistente. Non
legge direttamente le tabelle inventory interne. Admin Console governerà pubblicazione,
prezzi, promozioni e fulfillment; Merchandise Control e Win7POS restano sistemi
operativi.

## Stack

- Flutter 3.44.8 / Dart 3.12.2;
- Android Kotlin e iOS Swift;
- Material 3;
- Riverpod;
- go_router;
- Supabase Flutter Auth con PKCE;
- `app_links` e storage Keychain/Keystore;
- gen_l10n e intl.

## Struttura

- `lib/app/`: app, router, tema e branding tecnico;
- `lib/core/`: configurazione, bootstrap backend, formatter e widget condivisi;
- `lib/features/`: shell e feature-first UI;
- `lib/l10n/`: risorse spagnolo, italiano, inglese e cinese semplificato;
- `test/`: unit e widget test;
- `docs/`: governance, architettura, roadmap, task ed evidence;
- `scripts/`: doctor e quality gate locali.

## Requisiti

- macOS con Xcode per il target iOS;
- Android SDK/Emulator per il target Android;
- Flutter stable `3.44.8`;
- CocoaPods per le dipendenze iOS.

Verificare l'ambiente:

```bash
scripts/doctor.sh
```

## Setup

```bash
flutter pub get
flutter gen-l10n
```

Avvio development senza backend:

```bash
flutter run
```

L'app non effettua richieste Supabase quando URL e publishable key sono assenti.

Per usare una configurazione locale:

```bash
cp config/app_config.example.json config/app_config.local.json
flutter run --dart-define-from-file=config/app_config.local.json
```

`config/*.local.json` è ignorato. Non inserire service role, secret key, password o valori
production nel repository.

Per preparare staging, copiare l'esempio nel file locale ignorato e valorizzare
URL, publishable key TEST e `STOREFRONT_SHOP_SLUG`. Il percorso base senza OAuth
mantiene `GOOGLE_AUTH_ENABLED=false`; l'Auth TEST autorizzata richiede il dominio
HTTPS controllato, `AUTH_CALLBACK_VERIFIED_HOST` e la callback esatta
`https://<host>/auth-callback/`, oltre alle associazioni native e hosted verificate.
Il sentinel `.invalid` dell'esempio non dimostra ownership o login operativo.

```bash
cp config/app_config.staging.example.json config/app_config.staging.local.json
flutter run --dart-define-from-file=config/app_config.staging.local.json
flutter build apk --debug --dart-define-from-file=config/app_config.staging.local.json
flutter build ios --simulator --debug --dart-define-from-file=config/app_config.staging.local.json
```

TASK-054 distingue configurazione, firma, callback e prova Google reale. La nuova
qualifica esplicita del preflight TEST ha review source approvata; Quality8fc è
terminale PASS e il successivo runner3f8 ha review e50test scoped. Gli artifact unsigned già verificati
non attestano distribuzione o login. Sessione e verifier rimangono protetti in
Keychain/Keystore, e la configurazione non valida fallisce in modo chiuso.

### Mappa delivery opzionale

La mappa usa `google_maps_flutter` ed è disattivata per default. Timeline, finestra di
consegna e fallback testuale restano disponibili senza provider. Per uno staging già
autorizzato e configurato servono due chiavi distinte e ristrette al solo Maps SDK:

- Android: `ANDROID_GOOGLE_MAPS_API_KEY` nell'ambiente della build, oppure
  `MAPS_API_KEY` in `android/local.properties` locale;
- iOS: `IOS_GOOGLE_MAPS_API_KEY=<valore>` in
  `ios/Flutter/Maps.local.xcconfig`, file ignorato da Git.

Solo dopo aver verificato package/bundle, firme, quote e billing dello staging, avviare
con entrambi i gate compile-time:

```bash
flutter run \
  --dart-define=DELIVERY_MAPS_ENABLED=true \
  --dart-define=DELIVERY_MAPS_NATIVE_CONFIGURED=true \
  --dart-define-from-file=config/app_config.staging.local.json
```

Senza uno dei due gate il widget Google non viene istanziato. La produzione resta
`OFF` finché un activation record separato non attesta chiavi ristrette e prova su
device. Il Client non chiede posizione, non calcola ETA o percorsi e non invia order ID,
customer ID, alias del corriere o coordinate a log, analytics e push.

## Test e build

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
flutter build apk --debug
flutter build ios --simulator --debug
```

Gli smoke staging reali, esclusi dalla CI perché usano il file locale ignorato, sono:

```bash
flutter test integration_test/backend_readiness_smoke_test.dart -d emulator-5554 --dart-define-from-file=config/app_config.staging.local.json
flutter test integration_test/backend_readiness_smoke_test.dart -d <IOS_SIMULATOR_ID> --dart-define-from-file=config/app_config.staging.local.json
flutter test integration_test/storefront_home_live_smoke_test.dart -d emulator-5554 --dart-define-from-file=config/app_config.staging.local.json
flutter test integration_test/storefront_home_live_smoke_test.dart -d <IOS_SIMULATOR_ID> --dart-define-from-file=config/app_config.staging.local.json
```

Il primo smoke conserva il gate storico di readiness; dal TASK-013 la Home avvia anche
il proprio controller dati. Il secondo attende esplicitamente il payload reale
`storefront_home_v1` e verifica fixture pubblica, immagini, prezzi CLP, versione catalogo
uniforme e assenza di sessione customer.

Lo smoke Catalogo reale di TASK-014 usa lo stesso file staging locale ignorato:

```bash
flutter test integration_test/storefront_catalog_live_smoke_test.dart -d emulator-5554 --dart-define-from-file=config/app_config.staging.local.json
flutter test integration_test/storefront_catalog_live_smoke_test.dart -d <IOS_SIMULATOR_ID> --dart-define-from-file=config/app_config.staging.local.json
```

Lo smoke guest di TASK-012 non richiede backend:

```bash
flutter test integration_test/app_guest_flow_test.dart -d emulator-5554
flutter test integration_test/app_guest_flow_test.dart -d <IOS_SIMULATOR_ID>
```

Lo smoke Auth deterministico non usa Google o secret:

```bash
flutter test integration_test/auth_callback_flow_test.dart -d emulator-5554
flutter test integration_test/auth_callback_flow_test.dart -d <IOS_SIMULATOR_ID>
```

Gli smoke OAuth live richiedono staging locale, provider e redirect verificati e un
account test già autenticato. Non inserire password/MFA tramite automazione e non
salvare screenshot o log contenenti identità, callback, code o token.

Il gate completo è:

```bash
scripts/check.sh
```

## Governance

Leggere prima [docs/MASTER-PLAN.md](docs/MASTER-PLAN.md), quindi il task attivo indicato
dal Master Plan e il [protocollo workflow](docs/CODEX-WORKFLOW-PROTOCOL.md).
`AGENTS.md` è l'unica istruzione operativa root. Può esistere un solo task attivo;
Codex assume ruoli logici distinti per planning, execution, review, fix e re-review.
Soltanto `USER_APPROVER` autorizza `DONE`, merge e attivazione del task successivo. Per
il release train `STOREFRONT_V1`, l'autorizzazione condizionata è già registrata dal
prompt del 2026-08-01 e resta soggetta a checkpoint e review integrata reali.

## Stato

- **Task attivo**: TASK-054
- **File task**: docs/TASKS/TASK-054-integrated-staging-e2e-closeout.md
- **Stato task**: BLOCKED
- **Fase**: REVIEW
- **Indicatore**: CODEX_REVIEW_BLOCKED
- **Release train**: CLIENT_COMMERCE_JOURNEY_COMPLETION
- **Stato release train**: OPERATIONAL_COMPLETION
- **Review integrata**: BLOCKED — gate live; integrazione sviluppo separata e condizionata

Checkpoint storico8ottobre del candidato PR29 `f326faa`, ancora draft:
CI37848510649 terminale5PASS/2FAIL
iOSpostbootinventory, prima dell'app. Android92fixture e137PNG+4OS; review
mirata73Flutter+4OS senza nuovi finding,64riusi perhash con limiti storici.
Il badge predefinito è corretto negli8stati journal; iOS0PNG e gate nativi
NOT_RUN. Quality1064PASS+1SKIP,11benchmark; unsignedAndroid/iOSPASS.
TEST21:58:32/57RPCconformi,25assenti,4migrationassenti,1/2indici/history155.
Worker22:13 versione22107a6f invariata; nessunapply/deploy/installClient.
Il rapporto sul branch evidence distingue tutti i livelli e i prerequisiti.

Nel corrente9ottobre, source8fc Quality38001393798 è PASS1095/1SKIP+11performance;
runner headless3f8 source APPROVED/50test, PreparelocalePASS e buildcriticaFAIL
primaapp per SDK27min15 contro target14. CleanupPASS/0PNG, nessunapply/deploy.
Il [rapporto corrente](docs/TASKS/EVIDENCE/TASK-054/CLIENT_TASK054_NEXT_INTEGRATION_RESULT.md)
e il registro residui prevalgono sul checkpoint storico sopra.

TASK-054 è riaperto dal mandato del 2026-09-28 per audit funzionale e completamento
nel perimetro di sviluppo. Le attestazioni di closeout seguenti sono storiche:
TASK-050–053 restano invariati; staging era classificato
`STAGING_PARTIAL_EXTERNAL` perché apply ed E2E-01…25 live sono `BLOCKED` dopo i due
tentativi provider/CLI bounded. Nessuna migration production o activation è avvenuta.

TASK-046–TASK-049 sono `DONE`: contratto Admin/Supabase ed editor Android/iOS sono
integrati, E2E-01…14 staging e release candidate sono verificati e il Client resta
read-only. Android Internal, TestFlight, physical smoke e backend production restano
classificati come requisiti esterni; public store rollout non è stato eseguito.

TASK-043, TASK-044 e TASK-045 restano `DONE`: tutte le PR coordinate sono state fuse
normalmente e le CI PR/main exact-SHA sono verdi. Il train
`CLIENT_FINAL_PRODUCT_COMPLETION` ha chiuso TASK-034 su `main` con review e CI
exact-SHA verdi; TASK-035 è `DONE` con PR #13, CI PR/main 3/3 e zero finding.
TASK-036 è `DONE`: re-review indipendente `APPROVED`, zero finding P0/P1/P2/P3,
PR Admin #93 e Client #14 integrate, CI PR/main verdi e staging verificato.
TASK-037 è `DONE`: `F-037-R01`–`F-037-R04` chiusi, PR #16 e main CI exact-SHA
verdi, budget invariato e production non modificata. TASK-038 è `DONE`: re-review
`APPROVED`, PR #17, merge `ce2ab134` e main CI `31995128511` verdi. TASK-039 è
`DONE / TECHNICALLY_COMPLETE_EXTERNAL_CREDENTIAL_REQUIRED`: PR #18, merge
`f30b13e9` e main CI `32019746636` sono verdi; signing e Play restano esterni.
TASK-041 è `DONE / PRODUCTION_READY_PENDING_EXTERNAL_ACTIVATION`: PR #20, CI PR/main
5/5 e merge `ce6045e4` sono verdi. TASK-042 è
`DONE / POST_LAUNCH_OPERATIONS_READY_PRELAUNCH`: il mandato
USER_APPROVER del 2026-08-21 autorizza il solo closeout tecnico operations-readiness,
senza go-live, pubblicazione store, migration production, billing o attivazione
provider. TASK-040
resta `DONE / TECHNICALLY_COMPLETE_EXTERNAL_CREDENTIAL_REQUIRED`: D-05 limita
il boundary locale ai writer same-UID cooperativi, la targeted final re-review è
`APPROVED` con zero P0/P1/P2/P3 e la CI PR #19 exact-SHA è verde 5/5. Il progetto
resta incorporato; `F-041-R01` è `FIXED_VALIDATED` e la re-review TASK-041 è
`APPROVED` con zero P0/P1/P2/P3. Il progetto resta temporaneamente `ACTIVE` durante
TASK-042; l'unica passata FIX ha corretto i tre finding P2
`F-042-R01`–`F-042-R03`, tutti `FIXED_VALIDATED` dalla re-review indipendente con
P0/P1/P2/P3 zero. Il progetto resta `IDLE` e nessun task successivo e attivo.
Distribution, provisioning,
App Store Connect, device fisico ed eventuali production provider key restano
activation requirement esterni; nessun upload TestFlight è stato dichiarato.

`TASK-001`–`TASK-004` sono `DONE`; la PR batch #3 TASK-003/TASK-004 è merged.
TASK-011 è `DONE` dopo re-review indipendente `APPROVED` e CI approvazione
`30601758281` 3/3 `PASS`; CI closeout `30602210469` è 3/3 `PASS` sullo SHA esatto.
TASK-012 è `DONE` con re-review indipendente `APPROVED`, quattro P2 chiusi e CI
handoff/approvazione `30606916073` / `30607430241` entrambe 3/3 `PASS`. TASK-020
è `DONE`: la Re-review 6 sullo SHA
`671494f` ha verificato allow-list staging, provider Google, OAuth live Android/iOS,
callback iOS warm/cold, restore, logout e nuovo login. Finding aperti 0 P0/P1/P2/P3;
CI finale `30713857455` 3/3 `PASS`, step applicabili `success`, annotation 0/0/0.
PR #4 è merged normalmente con commit `b2d70b5`; branch remoto eliminato e il closeout
su `main` è stato verificato dalla CI `30714350425`. Il release train Storefront v1 ha
attraversato un blocco storico sul worktree dedicato per una limitazione esterna
dell'ambiente della Deep Security Scan. Dopo il mandato finale, TASK-005–TASK-010
pertinenti e
TASK-013–TASK-019 sono `VALIDATED_PENDING_INTEGRATED_REVIEW`; il checkpoint Milestone
3 è `PASS`. TASK-021 ha completato profilo, indirizzi, privacy e cancellazione request
owner-only ed è `VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-022 ha completato registro
device, consenso notifiche e token lifecycle privacy-safe ed è
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-023 ha completato guest cart persistente,
merge owner idempotente e price revalidation server-side ed è anch'esso
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-024 ha completato disponibilità commerciale
privacy-safe, freshness, Admin preview e refresh cache/cart ed è
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-025 ha completato hold atomici,
idempotenti e scadibili senza quantità inventory pubblica ed è anch'esso
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-026 ha completato checkout
server-authoritative per ritiro, prenotazione e consegna configurabile ed è anch'esso
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-027 ha completato ordine, item snapshot,
status event, outbox e receipt atomici/idempotenti ed è anch'esso
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-028 ha completato storico, dettaglio,
timeline, cache read-only, deep link e cancellazione controllata ed è anch'esso
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-029 ha completato queue, detail, RBAC e
workflow operativo ordini nella Admin Console; TASK-030 ha completato l'handoff POS
idempotente e il confine tra ordine cliente e vendita fiscale. Entrambi sono
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-031 ha completato la pipeline idempotente
di notifiche ordine e l'integrazione Client privacy-safe ed è anch'esso
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-032 ha completato metodi v1,
stato/idempotenza pagamento, boundary provider/webhook fail-closed e checkpoint
Milestone 4 629/629; è `VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-033 è concluso
`DONE / REVIEW / USER_APPROVED_DONE`: i 18 finding del report canonico sono corretti
e validati, il gate locale aggregato è `PASS` e la CI pubblica `31646041242` ha
eseguito realmente `Quality`, Android e iOS con esito `SUCCESS`. Google OAuth resta
fail-closed `OFF`; nessun task successivo è attivo.
Gli altri task del train restano `TODO` fino al rispettivo checkpoint.
