# ClientMerchandiseControl

Applicazione Flutter Android/iOS destinata ai clienti dei negozi dell'ecosistema
Merchandise Control. La fondazione corrente offre una shell localizzata e compilabile;
catalogo, account, carrello e ordini verranno collegati nei task futuri.

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

## Test e build

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
flutter build apk --debug
flutter build ios --simulator --debug
```

Il gate completo è:

```bash
scripts/check.sh
```

## Governance

Leggere prima [docs/MASTER-PLAN.md](docs/MASTER-PLAN.md), quindi il
[task attivo](docs/TASKS/TASK-001-bootstrap-foundation.md). Esiste un solo task attivo;
Codex esegue/fixa e Claude/ChatGPT pianifica/revisiona. `DONE` richiede conferma esplicita
dell'utente.

## Stato

`TASK-001` è `ACTIVE / REVIEW / READY_FOR_REVIEW`. La review non è ancora stata
eseguita e il task non è `DONE`.
