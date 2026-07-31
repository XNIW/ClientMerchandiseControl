# ClientMerchandiseControl

Applicazione Flutter Android/iOS destinata ai clienti dei negozi dell'ecosistema
Merchandise Control. La fondazione corrente offre una shell guest localizzata,
accessibile e data-safe con Home, Catalogo, Carrello e Account; dati Storefront,
autenticazione e ordini verranno collegati nei task proprietari futuri.

## Relazione con Merchandise Control

Il client consumerà un futuro dominio pubblico Storefront sul Supabase esistente. Non
legge direttamente le tabelle inventory interne. Admin Console governerà pubblicazione,
prezzi, promozioni e fulfillment; Merchandise Control e Win7POS restano sistemi
operativi.

## Stack

- Flutter 3.44.8 / Dart 3.12.2;
- Android Kotlin e iOS Swift;
- Material 3;
- Riverpod;
- go_router;
- Supabase Flutter;
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

Per preparare staging, copiare l'esempio nel file locale ignorato, valorizzare URL e
publishable key non-production e impostare `GOOGLE_AUTH_ENABLED=false` finché la
callback non è registrata dal task OAuth:

```bash
cp config/app_config.staging.example.json config/app_config.staging.local.json
flutter run --dart-define-from-file=config/app_config.staging.local.json
flutter build apk --debug --dart-define-from-file=config/app_config.staging.local.json
flutter build ios --simulator --debug --dart-define-from-file=config/app_config.staging.local.json
```

Il contratto staging richiede la callback
`com.xniw.clientmerchandisecontrol://auth-callback/`. La configurazione locale corrente
usa `GOOGLE_AUTH_ENABLED=false` fino a TASK-020. TASK-011 inizializza lo SDK senza
session persistence e verifica l'endpoint Auth health ufficiale, senza interrogare
tabelle o dati. Il banner resta customer-safe e il retry è soltanto manuale.
TASK-012 non aggiunge query o dati commerciali: Catalogo rappresenta solo readiness,
Account resta guest a runtime e il controllo Google rimane disabilitato fino a
TASK-020.

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
```

Lo smoke guest di TASK-012 non richiede backend:

```bash
flutter test integration_test/app_guest_flow_test.dart -d emulator-5554
flutter test integration_test/app_guest_flow_test.dart -d <IOS_SIMULATOR_ID>
```

Il gate completo è:

```bash
scripts/check.sh
```

## Governance

Leggere prima [docs/MASTER-PLAN.md](docs/MASTER-PLAN.md), quindi il task attivo indicato
dal Master Plan e il [protocollo workflow](docs/CODEX-WORKFLOW-PROTOCOL.md).
`AGENTS.md` è l'unica istruzione operativa root. Può esistere un solo task attivo;
Codex assume ruoli logici distinti per planning, execution, review, fix e re-review.
Soltanto `USER_APPROVER` autorizza `DONE`, merge e attivazione del task successivo.

## Stato

- **Task attivo**: TASK-012
- **File task**: `docs/TASKS/TASK-012-app-shell-design-system-localization-accessibility.md`
- **Stato task**: ACTIVE
- **Fase**: REVIEW
- **Indicatore**: CODEX_FIX_COMPLETE_TO_RE_REVIEW

`TASK-001`–`TASK-004` sono `DONE`; la PR batch #3 TASK-003/TASK-004 è merged.
TASK-011 è `DONE` dopo re-review indipendente `APPROVED` e CI approvazione
`30601758281` 3/3 `PASS`; CI closeout `30602210469` è 3/3 `PASS` sullo SHA esatto.
TASK-012 è l'unico task `ACTIVE`, in `REVIEW` dopo il Fix dei quattro finding P2 sullo
SHA tecnico `3acbc42d9abd5bffe0230d3b9bca27baf345cfea`; la re-review indipendente è
obbligatoria. OAuth, redirect allow-list e deep link restano TASK-020; TASK-005–TASK-010
e TASK-013 in avanti non sono attivi.
