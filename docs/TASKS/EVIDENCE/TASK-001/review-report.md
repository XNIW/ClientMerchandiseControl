# Report review indipendente e re-review — TASK-001

## Esito

- **Baseline revisionata**: `83b855728f5cf3192f7f1daa1e37b787440423a9`.
- **Verdetto iniziale**: `CHANGES_REQUIRED`.
- **Distribuzione iniziale**: 0 P0, 3 P1, 8 P2, 3 P3.
- **Commit governance**: `4c4b2e3`.
- **Commit tecnico re-revisionato**:
  `3f0d992a7c1b6e9f9291e7617b53c0cf6c3f8734`.
- **Verdetto re-review**: `APPROVED`.
- **Distribuzione finale**: 14 `RESOLVED`, 0 finding aperti, 0 nuovi finding.

Le posizioni `Baseline` descrivono il commit iniziale e restano immutabili come evidenza
storica. Le posizioni `Risoluzione` indicano il codice verificato post-fix.

## Finding P1

### REV-001 — P1 — Governance Codex-only assente

- **Stato**: RESOLVED
- **Baseline**: `AGENTS.md:9`, `CLAUDE.md:1`,
  `docs/MASTER-PLAN.md:11`, `docs/CODEX-EXECUTION-PROTOCOL.md:1`.
- **Evidenza iniziale**: ruoli operativi divisi tra prodotti diversi, due file root e
  assenza di CA-22/T-23.
- **Impatto**: handoff non deterministico e dipendenza operativa da sistemi esterni al
  workflow approvato.
- **Correzione richiesta**: consolidare governance, ruoli, protocollo e controlli in un
  workflow esclusivamente Codex.
- **Test di regressione**: T-23, unicità dei file operativi e audit classificato dei
  riferimenti legacy.
- **Risoluzione**: `AGENTS.md:1`, `AGENTS.md:33`, `AGENTS.md:88`,
  `docs/CODEX-WORKFLOW-PROTOCOL.md:1`, `docs/DECISIONS/ADR-006-codex-only-governance.md:1`,
  `docs/TASKS/EVIDENCE/TASK-001/codex-only-governance-migration.md:1`.
- **Verifica**: secondo file root assente, un solo protocollo, ruoli/handoff Codex
  completi, T-23 `PASS`.
- **Commit di risoluzione**: `4c4b2e3`.

### REV-002 — P1 — Contratto zh-Hans e risoluzione locale errati

- **Stato**: RESOLVED
- **Baseline**: `lib/l10n/app_zh.arb:2`,
  `lib/app/client_merchandise_control_app.dart:27`, `ios/Runner/Info.plist:1`,
  `ios/Runner.xcodeproj/project.pbxproj:198`.
- **Evidenza iniziale**: cinese dichiarato come `zh`, matching solo per lingua e
  metadata iOS incompleti.
- **Impatto**: zh-Hant poteva ricevere testi semplificati e iOS non dichiarava tutte le
  lingue effettive.
- **Correzione richiesta**: introdurre `zh-Hans`, matching script-aware, scansione delle
  preferenze e metadata nativi coerenti.
- **Test di regressione**: zh-Hans/CN/SG, zh-Hant/generico, fallback spagnolo e matrice
  metadata iOS.
- **Risoluzione**: `lib/l10n/app_zh_Hans.arb:2`,
  `lib/app/client_merchandise_control_app.dart:9`,
  `lib/app/client_merchandise_control_app.dart:41`, `ios/Runner/Info.plist:17`,
  `ios/Runner.xcodeproj/project.pbxproj:202`.
- **Verifica**: zh-Hans supportato, zh-Hant/generico non mappato implicitamente al
  semplificato, CN/SG/Hans mappati, fallback spagnolo e metadata nativi testati.
- **Commit di risoluzione**: `3f0d992`.

### REV-003 — P1 — Chiavi Supabase privilegiate o arbitrarie accettate

- **Stato**: RESOLVED
- **Baseline**: `lib/core/config/app_config.dart:18`,
  `lib/core/backend/supabase_bootstrap.dart:7`.
- **Evidenza iniziale**: qualunque stringa non vuota poteva raggiungere il client.
- **Impatto**: una configurazione errata poteva incorporare nel client una credenziale
  privilegiata o sconosciuta.
- **Correzione richiesta**: allowlist publishable/anon e rifiuto fail-closed di secret,
  service role, JWT malformati e valori arbitrari.
- **Test di regressione**: casi positivi publishable/anon, matrice negativa e verifica
  che l'errore non esponga la chiave.
- **Risoluzione**: `lib/core/config/app_config.dart:109`,
  `test/core/config/app_config_test.dart:116`,
  `test/core/config/app_config_test.dart:135`,
  `test/core/config/app_config_test.dart:159`.
- **Verifica**: allowlist `sb_publishable_*` o JWT legacy con ruolo `anon`; secret,
  service role, JWT malformati e valori arbitrari rifiutati senza includere il valore
  nell'errore.
- **Commit di risoluzione**: `3f0d992`.

## Finding P2

### REV-004 — P2 — Preferenze locale successive ignorate

- **Stato**: RESOLVED
- **Baseline**: `lib/app/client_merchandise_control_app.dart:27`.
- **Impatto**: una preferenza supportata successiva alla prima veniva ignorata.
- **Correzione richiesta**: scorrere tutte le preferenze in ordine.
- **Test di regressione**: `[de, it]` deve selezionare italiano.
- **Risoluzione**: `lib/app/client_merchandise_control_app.dart:34`,
  `lib/app/client_merchandise_control_app.dart:41`,
  `test/app/client_merchandise_control_app_test.dart:25`.
- **Verifica**: la lista è scandita in ordine e `[de, it]` seleziona italiano.
- **Commit di risoluzione**: `3f0d992`.

### REV-005 — P2 — Parsing configurazione non sufficientemente fail-closed

- **Stato**: RESOLVED
- **Baseline**: `lib/core/config/app_config.dart:34`,
  `lib/core/config/app_environment.dart:6`.
- **Impatto**: URL ambigue/non canoniche o un ambiente esplicitamente vuoto potevano
  raggiungere il bootstrap.
- **Correzione richiesta**: accettare soltanto origin HTTPS canoniche e distinguere
  assenza dell'ambiente da valore vuoto.
- **Test di regressione**: matrice scheme/userinfo/path/query/fragment/porta e
  `APP_ENV` vuoto.
- **Risoluzione**: `lib/core/config/app_config.dart:56`,
  `lib/core/config/app_config.dart:78`, `lib/core/config/app_environment.dart:6`,
  `test/core/config/app_config_test.dart:74`.
- **Verifica**: soltanto origin HTTPS canoniche, senza userinfo/path/query/fragment e
  con porta valida; `APP_ENV` esplicitamente vuoto è rifiutato, mentre l'assenza resta
  development.
- **Commit di risoluzione**: `3f0d992`.

### REV-006 — P2 — Test offline non dimostrava zero inizializzazioni

- **Stato**: RESOLVED
- **Baseline**: `lib/core/backend/supabase_bootstrap.dart:7`,
  `test/core/backend/supabase_bootstrap_test.dart:7`.
- **Impatto**: una regressione di rete in modalità offline poteva restare verde.
- **Correzione richiesta**: introdurre una seam per l'initializer e osservare il numero
  e gli argomenti delle chiamate.
- **Test di regressione**: zero chiamate offline, una chiamata esatta configurata e
  propagazione errore senza retry.
- **Risoluzione**: `lib/core/backend/supabase_bootstrap.dart:6`,
  `lib/core/backend/supabase_bootstrap.dart:21`,
  `test/core/backend/supabase_bootstrap_test.dart:7`,
  `test/core/backend/supabase_bootstrap_test.dart:21`.
- **Verifica**: seam deterministica; zero chiamate offline, una chiamata esatta quando
  configurato e propagazione degli errori, senza rete reale.
- **Commit di risoluzione**: `3f0d992`.

### REV-007 — P2 — Back di sistema usciva da una destinazione secondaria

- **Stato**: RESOLVED
- **Baseline**: `lib/features/shell/presentation/app_shell_screen.dart:26`.
- **Impatto**: rischio di uscita accidentale e comportamento incoerente con la
  navigazione a tab.
- **Correzione richiesta**: il primo back da una tab secondaria deve tornare a Home.
- **Test di regressione**: `handlePopRoute` e back reale Android da Account.
- **Risoluzione**: `lib/features/shell/presentation/app_shell_screen.dart:26`,
  `test/features/shell/app_shell_screen_test.dart:80`.
- **Verifica**: `PopScope` riporta la tab secondaria a Home; widget test e smoke Android
  reali confermano il comportamento.
- **Commit di risoluzione**: `3f0d992`.

### REV-008 — P2 — Semantica duplicata nell'header

- **Stato**: RESOLVED
- **Baseline**: `lib/core/widgets/feature_placeholder.dart:28`.
- **Impatto**: screen reader poteva annunciare due volte il titolo.
- **Correzione richiesta**: rendere decorativa l'icona e conservare un solo heading.
- **Test di regressione**: conteggio semantico deterministico del titolo.
- **Risoluzione**: `lib/core/widgets/feature_placeholder.dart:28`,
  `test/features/shell/app_shell_screen_test.dart:111`.
- **Verifica**: icona esclusa dalla semantica e un solo heading annunciabile.
- **Commit di risoluzione**: `3f0d992`.

### REV-009 — P2 — Copertura widget incompleta e asserzione falsamente positiva

- **Stato**: RESOLVED
- **Baseline**: `test/app/client_merchandise_control_app_test.dart:8`,
  `test/features/shell/app_shell_screen_test.dart:25`.
- **Impatto**: regressioni di contenuto, locale, tema, accessibilità e layout potevano
  superare la suite.
- **Correzione richiesta**: asserire contenuti reali ed estendere la matrice widget.
- **Test di regressione**: quattro destinazioni, lingue/fallback, tema scuro, testo
  200%, semantica e viewport compatta/estesa.
- **Risoluzione**: `test/app/client_merchandise_control_app_test.dart:15`,
  `test/app/client_merchandise_control_app_test.dart:83`,
  `test/app/client_merchandise_control_app_test.dart:104`,
  `test/app/client_merchandise_control_app_test.dart:125`,
  `test/app/client_merchandise_control_app_test.dart:145`,
  `test/features/shell/app_shell_screen_test.dart:52`,
  `test/features/shell/app_shell_screen_test.dart:111`,
  `test/features/shell/app_shell_screen_test.dart:131`,
  `test/features/shell/app_shell_screen_test.dart:145`.
- **Verifica**: contenuto reale di quattro tab, lingue/fallback, tema scuro, text scale
  200%, semantica e layout compatto/esteso; suite completa 38/38 `PASS`.
- **Commit di risoluzione**: `3f0d992`.

### REV-010 — P2 — Dipendenze GitHub Actions mutabili

- **Stato**: RESOLVED
- **Baseline**: `.github/workflows/ci.yml:29`, `.github/workflows/ci.yml:36`,
  `.github/workflows/ci.yml:54`, `.github/workflows/ci.yml:61`,
  `.github/workflows/ci.yml:73`, `.github/workflows/ci.yml:80`.
- **Impatto**: il codice eseguito in CI poteva cambiare senza diff revisionabile.
- **Correzione richiesta**: fissare tutte le action dirette a SHA, eliminare la cache
  transitiva mutabile e aggiungere un controllo preventivo.
- **Test di regressione**: policy statica per `uses:` e probe delle action annidate.
- **Risoluzione**: `.github/workflows/ci.yml:30`,
  `.github/workflows/ci.yml:37`, `.github/workflows/ci.yml:70`,
  `.github/workflows/ci.yml:73`, `.github/workflows/ci.yml:91`,
  `.github/workflows/ci.yml:94`, `scripts/check-action-pins.sh:1`.
- **Verifica**: sei riferimenti diretti a SHA completi, nessuna action diretta o
  annidata mutabile e nessun `cache: true`; controllo statico `PASS`.
- **Commit di risoluzione**: `3f0d992`.

### REV-011 — P2 — Riproducibilità toolchain e quality gate incompleti

- **Stato**: RESOLVED
- **Baseline**: `.github/workflows/ci.yml:37`, `scripts/check.sh:4`,
  `scripts/doctor.sh:4`.
- **Impatto**: locale e CI potevano usare SDK/dipendenze o output generati differenti.
- **Correzione richiesta**: resolver comune con versione/revisione, lockfile enforced,
  l10n diff e controlli shell/whitespace.
- **Test di regressione**: esecuzione resolver nei percorsi supportati, gate completo e
  controlli statici CI.
- **Risoluzione**: `scripts/resolve-flutter.sh:4`, `scripts/check.sh:8`,
  `scripts/check.sh:12`, `.github/workflows/ci.yml:41`,
  `.github/workflows/ci.yml:44`, `.github/workflows/ci.yml:47`.
- **Verifica**: Flutter 3.44.8/revisione esatta, lockfile enforced, l10n diff, sintassi
  shell e whitespace verificati localmente e in CI.
- **Commit di risoluzione**: `3f0d992`.

## Finding P3

### REV-012 — P3 — Formatter CLP produceva `-$0`

- **Stato**: RESOLVED
- **Baseline**: `lib/core/formatting/clp_currency_formatter.dart:24`.
- **Impatto**: valori con modulo minore di mezzo peso mostravano uno zero negativo.
- **Correzione richiesta**: decidere il segno dopo l'arrotondamento CLP.
- **Test di regressione**: `-0.4` e `"-0,4"` -> `$0`; `-0.5` -> `-$1`.
- **Risoluzione**: `lib/core/formatting/clp_currency_formatter.dart:24`,
  `test/core/formatting/clp_currency_formatter_test.dart:24`.
- **Verifica**: il segno è calcolato dopo l'arrotondamento; `-0.4` produce `$0`.
- **Commit di risoluzione**: `3f0d992`.

### REV-013 — P3 — Label launcher Android tecnica

- **Stato**: RESOLVED
- **Baseline**: `android/app/src/main/AndroidManifest.xml:3`.
- **Impatto**: nome non presentabile in launcher e task switcher.
- **Correzione richiesta**: usare una risorsa stringa leggibile.
- **Test di regressione**: validazione manifest/risorsa e build Android.
- **Risoluzione**: `android/app/src/main/AndroidManifest.xml:3`,
  `android/app/src/main/res/values/strings.xml:3`.
- **Verifica**: label leggibile tramite risorsa XML valida e build Android `PASS`.
- **Commit di risoluzione**: `3f0d992`.

### REV-014 — P3 — Hardening nativo e ignore sensibili incompleti

- **Stato**: RESOLVED
- **Baseline**: `android/gradle/wrapper/gradle-wrapper.properties:5`,
  `android/app/build.gradle.kts:27`, `.gitignore:47`.
- **Impatto**: integrità download meno verificabile, firma debug nel release e rischio di
  versionare configurazioni locali.
- **Correzione richiesta**: checksum ufficiale, rimozione firma debug release e ignore
  mirati.
- **Test di regressione**: verifica checksum/config Gradle/ignore e build debug.
- **Risoluzione**: `android/gradle/wrapper/gradle-wrapper.properties:6`,
  `android/app/build.gradle.kts:7`, `.gitignore:50`, `.gitignore:56`.
- **Verifica**: checksum Gradle ufficiale, nessuna firma debug nel release, ignore
  mirati per environment/signing/config mobile; build debug e security scan `PASS`.
- **Commit di risoluzione**: `3f0d992`.

## Verdetto finale

Le due re-review indipendenti non hanno rilevato finding nuovi o residui. Tutti i
finding P1, P2 e P3 iniziali sono `RESOLVED`; non esistono finding P0. Il verdetto è
`APPROVED` e l'handoff è
`CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION`.
