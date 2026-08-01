# Execution evidence — TASK-012

## Revisione verificata

- Base Execution: `f47b77e`
- Commit tecnico:
  `14cdc5175b9a596c8a4237e6796fefe3e7beda63`
- Branch: `milestone/011-012-020-authenticated-storefront-foundation`
- Diff tecnico: 42 file, 4291 inserimenti, 287 rimozioni
- Dipendenze runtime e target nativi: invariati

## Deliverable

| Area | Risultato |
|---|---|
| Shell | Quattro branch persistenti, app bar localizzata, back verso Home e CTA centralizzate |
| Home | Ricerca, categorie, offerte/future state, featured/future state e CTA data-safe |
| Catalogo | Search/filter/sort foundation e cinque stati derivati dalla sola readiness |
| Carrello | Empty state customer-safe e CTA reale verso Catalogo |
| Account | Guest runtime; modello authenticated iniettabile, avatar sicuro e logout obbligatorio |
| Design system | Page full-width, section, empty state, search launcher e banner responsive |
| Localizzazione | es-CL primaria/fallback; parità es, it, en, zh-Hans e bundle `app_zh` |
| Accessibilità | Semantics, 48 dp, light/dark, 200%, SafeArea e quattro viewport |
| Runtime | Smoke 1/1 Android e 1/1 iOS, screenshot sanitizzati e log process-scoped |

La UI non inventa prodotti, prezzi, stock, immagini, sconti o disponibilità. Catalogo
non esegue query e Account non implementa OAuth, callback o session lifecycle.

## Matrice CA

| CA | Esito | Evidenza |
|---|---|---|
| CA-01 | PASS | `planning-audit.md`; governance/Git verificati con exit 0. |
| CA-02 | PASS | Audit originalità in `security-review.md`; nessun asset o brand terzo. |
| CA-03 | PASS | `design_tokens_test.dart` e `storefront_theme_test.dart`; test PASS, exit 0. |
| CA-04 | PASS | `app_brand_test.dart` e test titolo applicativo; PASS, exit 0. |
| CA-05 | PASS | `app_shell_screen_test.dart` e smoke dual-platform; PASS, exit 0. |
| CA-06 | PASS | Test subtree/back in `app_shell_screen_test.dart` e integrazione; PASS, exit 0. |
| CA-07 | PASS | Test guest readiness e smoke in `app_guest_flow_test.dart`; PASS, exit 0. |
| CA-08 | PASS | `home_screen_test.dart`, gerarchia e ricerca Home; PASS, exit 0. |
| CA-09 | PASS | CTA Home in widget/integration test, senza query; PASS, exit 0. |
| CA-10 | PASS | Categorie future in `home_screen_test.dart` e audit data-safe; PASS, exit 0. |
| CA-11 | PASS | Sezioni future in `home_screen_test.dart`; PASS, exit 0. |
| CA-12 | PASS | Widget test Home e scan dati commerciali in `security-review.md`; PASS. |
| CA-13 | PASS | `catalog_screen_test.dart`, incluso albero Semantics dei controlli; PASS, exit 0. |
| CA-14 | PASS | `catalog_presentation_state_test.dart` e stati in `catalog_screen_test.dart`; PASS, exit 0. |
| CA-15 | PASS | Retry Catalogo/controller single-flight; test PASS, exit 0. |
| CA-16 | PASS | Scan query/RPC/Storage in `security-review.md`; zero accessi applicativi. |
| CA-17 | PASS | Stato vuoto e CTA in `cart_screen_test.dart`; PASS, exit 0. |
| CA-18 | PASS | Assenza checkout/totali verificata in `cart_screen_test.dart`; PASS, exit 0. |
| CA-19 | PASS | Guest Account in `account_screen_test.dart`; PASS, exit 0. |
| CA-20 | PASS | Port Google iniettabile e fail-closed in `account_screen_test.dart`; PASS, exit 0. |
| CA-21 | PASS | Account authenticated, fallback avatar e logout in test dedicati; PASS, exit 0. |
| CA-22 | PASS | Casi null/vuoti/lunghi e avatar locale invalido/bounded; test PASS, exit 0. |
| CA-23 | PASS | Scan e widget test: nessun profilo, form o impostazione aggiuntiva. |
| CA-24 | PASS | Runtime guest e scan token/sessione in `security-review.md`; zero occorrenze operative. |
| CA-25 | PASS | `app_localizations_contract_test.dart` e resolver locale; PASS, exit 0. |
| CA-26 | PASS | Parità ARB e audit stringhe in `security-review.md`; PASS. |
| CA-27 | PASS | `clp_currency_formatter_test.dart`; PASS, exit 0. |
| CA-28 | PASS | Test light/dark e semantic colors; PASS, exit 0. |
| CA-29 | PASS | `task012_reflow_accessibility_test.dart` e smoke 200%; PASS, exit 0. |
| CA-30 | PASS | Test Semantics UI, regressione Catalogo e smoke nativo; PASS, exit 0. |
| CA-31 | PASS | Guideline e misure 48 dp in test accessibilità; PASS, exit 0. |
| CA-32 | PASS | Test compact/large, inset e orientamenti; PASS, exit 0. |
| CA-33 | PASS | Test full-width, scroll-to-end e bounds; PASS, exit 0. |
| CA-34 | PASS | Scan I/O/network e smoke process-scoped in `runtime-smoke.md`; PASS. |
| CA-35 | PASS | Gate e build con exit 0 registrati in `commands-and-results.md`. |
| CA-36 | PASS | Smoke 1/1 Android e 1/1 iOS, screenshot in `runtime-smoke.md`. |
| CA-37 | PASS | `git diff --check`, scan secret/artifact e confinement; PASS, exit 0. |
| CA-38 | NOT_RUN | Richiede la re-review indipendente successiva al ciclo FIX. |
| CA-39 | NOT_RUN | Richiede la CI sullo SHA finale approvato dalla re-review. |

## Matrice test

| Test | Esito | Evidenza |
|---|---|---|
| T-01 | PASS | Governance/Git in `planning-audit.md`; comandi exit 0. |
| T-02 | PASS | Audit manuale/statico in `security-review.md`; nessuna copia o dato fittizio. |
| T-03 | PASS | `flutter test test/app/design_system/design_tokens_test.dart test/app/design_system/storefront_theme_test.dart`; exit 0. |
| T-04 | PASS | `flutter test test/app/branding/app_brand_test.dart test/app/client_merchandise_control_app_test.dart`; exit 0. |
| T-05 | PASS | `flutter test test/features/shell/app_shell_screen_test.dart`; exit 0. |
| T-06 | PASS | Test shell/readiness guest e integrazione; exit 0. |
| T-07 | PASS | `flutter test test/features/home/home_screen_test.dart`; exit 0. |
| T-08 | PASS | Widget test Home più audit data-safe; exit 0. |
| T-09 | PASS | `flutter test test/features/catalog/catalog_screen_test.dart`; exit 0. |
| T-10 | PASS | Test stato/presentazione Catalogo; exit 0. |
| T-11 | PASS | Test retry Catalogo e controller single-flight; exit 0. |
| T-12 | PASS | Scan statico query/I/O/network in `security-review.md`; nessun match operativo. |
| T-13 | PASS | `flutter test test/features/cart/cart_screen_test.dart`; exit 0. |
| T-14 | PASS | Test CTA Carrello verso Catalogo; exit 0. |
| T-15 | PASS | Test Account guest e port Google; exit 0. |
| T-16 | PASS | Test Account authenticated e logout obbligatorio; exit 0. |
| T-17 | PASS | Test fallback e limiti avatar/testi Account; exit 0. |
| T-18 | PASS | Scan runtime guest, form/token/sessione; nessuna violazione. |
| T-19 | PASS | `flutter test test/l10n/app_localizations_contract_test.dart test/app/client_merchandise_control_app_test.dart`; exit 0. |
| T-20 | PASS | `flutter test test/core/formatting/clp_currency_formatter_test.dart`; exit 0. |
| T-21 | PASS | Test destinazioni e temi light/dark; exit 0. |
| T-22 | PASS | Test reflow 200% compact/large; exit 0. |
| T-23 | PASS | Test Semantics UI e regressione Catalogo; exit 0. |
| T-24 | PASS | Guideline e misura target interattivi; exit 0. |
| T-25 | PASS | Test SafeArea, orientamento, full-width, scroll e bounds; exit 0. |
| T-26 | PASS | `flutter test integration_test/app_guest_flow_test.dart` su Android e iOS; 1/1, exit 0 per piattaforma. |
| T-27 | PASS | Toolchain, l10n, format, analyze, test e `scripts/check.sh`; exit 0 in `commands-and-results.md`. |
| T-28 | PASS | `flutter build apk --debug`; exit 0. |
| T-29 | PASS | `flutter build ios --simulator --debug`; exit 0. |
| T-30 | PASS | Smoke normale e screenshot Android in `runtime-smoke.md`; exit 0. |
| T-31 | PASS | Smoke normale e screenshot iOS in `runtime-smoke.md`; exit 0. |
| T-32 | PASS | `git diff --check` e scan secret/artifact/confinement; exit 0. |
| T-33 | NOT_RUN | Richiede la re-review indipendente dei quattro finding dopo FIX. |
| T-34 | NOT_RUN | Richiede l'ispezione CI sullo SHA finale dopo re-review. |

## Failure di sviluppo

I failure intermedi non sono stati occultati. Due difetti applicativi e due difetti
dell'harness sono stati corretti e coperti da regressione; il dettaglio è in
`development-findings.md`. I run finali sono tutti conclusi e non restano processi di
verifica attivi.

## Esito

`CODEX_EXECUTION_COMPLETE_TO_REVIEW`
