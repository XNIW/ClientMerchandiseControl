# ClientMerchandiseControl

Applicazione Flutter Android/iOS destinata ai clienti dei negozi dell'ecosistema
Merchandise Control. La fondazione corrente offre una shell guest localizzata,
accessibile e data-safe con Home e Catalogo Storefront reali, Carrello e Account, più
Google OAuth customer verificato in staging tramite Supabase Auth. Search/discovery,
commerce e ordini avanzano nei task proprietari del release train.

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

Per preparare staging, copiare l'esempio nel file locale ignorato, valorizzare URL,
publishable key non-production e `STOREFRONT_SHOP_SLUG` con lo slug pubblico assegnato;
mantenere `GOOGLE_AUTH_ENABLED=false` finché la callback non è verificata nella
redirect allow-list:

```bash
cp config/app_config.staging.example.json config/app_config.staging.local.json
flutter run --dart-define-from-file=config/app_config.staging.local.json
flutter build apk --debug --dart-define-from-file=config/app_config.staging.local.json
flutter build ios --simulator --debug --dart-define-from-file=config/app_config.staging.local.json
```

Il contratto staging richiede la callback
`com.xniw.clientmerchandisecontrol://auth-callback/`. Con il flag `true`, TASK-020 usa
Google OAuth, PKCE e browser esterno; sessione e verifier sono conservati in
Keychain/Keystore e ogni callback è validato prima dell'exchange. Development e
production restano fail-closed. TASK-011 continua a verificare il solo endpoint Auth
health senza tabelle o dati; TASK-012 non aggiunge query o dati commerciali.
TASK-013 usa lo slug esclusivamente con l'RPC pubblico `storefront_home_v1`;
TASK-014 estende lo stesso boundary con `storefront_categories_v1` e
`storefront_catalog_v1`.

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

- **Task attivo**: TASK-028
- **File task**: docs/TASKS/TASK-028-order-history-status-tracking.md
- **Stato task**: ACTIVE
- **Fase**: EXECUTION
- **Indicatore**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Release train**: STOREFRONT_V1
- **Stato release train**: EXECUTION
- **Review integrata**: NOT_RUN

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
su `main` è stato verificato dalla CI `30714350425`. Il release train Storefront v1 è
ora in `EXECUTION` sul worktree dedicato: TASK-005–TASK-010 pertinenti e
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
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-028 è l'unico task attivo e realizza
storico, dettaglio, timeline, cache read-only, deep link e cancellazione controllata.
Gli altri task del train restano `TODO` fino al rispettivo checkpoint.
