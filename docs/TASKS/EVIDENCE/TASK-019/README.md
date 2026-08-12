# Evidence TASK-019

## Snapshot di handoff

- **Stato**: `VALIDATED_PENDING_INTEGRATED_REVIEW`
- **Fase**: `EXECUTION`
- **Handoff**: `CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`
- **Client runtime revision**: `8f6c67dd3372ee9a6421f7071e58f4c0808f11b1`
- **Admin/Supabase revision**: `1f1ba507bbdde96197276738aacd7e290c20f8fe`
- **PR**: Client #5 `DRAFT`; Admin #67 `DRAFT`
- **Migration staging**: `20260802043000_storefront_v1_catalog_performance`
- **Review integrata**: `NOT_RUN`
- **Production write**: `NOT_RUN`

Il checkpoint è tecnico: non costituisce review e non porta TASK-019 a `DONE`.

## Revision set e modifiche

### Client Flutter

- `b03463f` — pass UI/UX moderno sulle superfici Storefront esistenti e audit pattern;
- `581f0f0` — browsing guest non subordinato ad Auth/bootstrap;
- `db56e6a` — contenuto live pubblicato prima della persistenza cache;
- `c730f04` — contenuto pubblico prioritario rispetto alla health diagnostics;
- `a0119be` — revalidation corretta dopo reconnect;
- `d5dfa2e` — timing esplicito del trasporto pubblico;
- `1367704` — separazione first usable shell/Home data;
- `f4074e2` — classificazione frame janky/severe/frozen;
- `fd5eb94` — smoke staging indipendente da ID fixture effimeri;
- `8f6c67d` — regressione lifecycle Activity Sheet su target iPad corretto.

Il confine pubblico usa PostgREST/RPC allow-listed; la UI non attende sessione Google,
storage Auth o diagnostica server per rendere la shell guest. Nessuna tabella inventory,
campo interno o URL storage privato è stato introdotto.

### Admin/Supabase

- `5b78710f` — UI Storefront responsive sul design system esistente;
- `af45583f` — hydration catalogo bounded e query misurate;
- `20260802043000_storefront_v1_catalog_performance.sql` — indici additive FTS/keyset,
  planner-safe read path e contract load;
- `37d8daad`..`1f1ba507` — fixture staging completa, immagini pubbliche, hold fuori DB,
  rerun idempotente e artifact distinti per `run_attempt`.

## Comandi e gate Client

| Gate | Comando/provenienza | SHA | Exit/durata/conteggio | Esito |
|---|---|---|---|---|
| Gate completo | `/usr/bin/time -p ./scripts/check.sh` | `8f6c67d` | exit 0; 98,32 s; 343 test ordinari + 1 performance | PASS |
| Coverage | `flutter test --coverage --exclude-tags performance` + `lcov.info` | `8f6c67d` | 4.689/5.667 linee; 82,74% | PASS |
| Cache 25k | `flutter test --tags performance --concurrency=1` | `8f6c67d` | 1/1; open 302 ms; write 20k 446 ms | PASS |
| Android debug | `flutter build apk --debug` nel gate | `8f6c67d` | exit 0 | PASS |
| iOS Simulator debug | `flutter build ios --simulator --debug --no-codesign` nel gate | `8f6c67d` | exit 0 | PASS |
| Android release universal | `flutter build apk --release --dart-define-from-file=config/app_config.staging.local.json` | `8f6c67d` | exit 0; 77,91 s; 63,5 MB | PASS |
| Android release split | `flutter build apk --release --split-per-abi --dart-define-from-file=config/app_config.staging.local.json` | `8f6c67d` | exit 0; 11,52 s; arm64 22,1 MB | PASS |
| Live extended dataset | quattro target integration staging su `emulator-5554` | `fd5eb94` | exit 0; 4/4; 2m49s | PASS |
| XCTest Activity Sheet | `xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner -destination 'platform=iOS Simulator,id=C68346BB-6888-40A1-BA80-2188C87AD59C' -resultBundlePath <tmp>/RunnerTests.xcresult` | `8f6c67d` | exit 0; 3/3; 11,835 s | PASS |
| CI Client | GitHub Actions run `30759482376` | `8f6c67d` | Quality 4m35s; iOS 3m26s; Android 9m01s; 3/3 | PASS |

Il live set sul runtime `fd5eb94` è code-equivalent a `8f6c67d`: l'unica modifica
successiva è nel target XCTest iOS. Il gate completo e la CI sono invece sullo SHA
esatto finale.

## UI hardening e visual QA

- audit: `docs/PRODUCT/STOREFRONT-UI-PATTERN-AUDIT.md`, 228 righe, pattern generali
  provenienti da fonti pubbliche, zero screenshot/asset proprietari;
- design system: spacing, radii, elevation, surface, semantic colors, typography,
  price/promo/status, motion, breakpoint, target minimo e max content width;
- Client: Home, Catalogo, product card, Detail, Preferiti, Account e shell; loading,
  skeleton, empty, offline, retry e immagini progressive;
- matrix widget parametrizzata: 320x568, 360x800, 390x844, 430x932, 768x1024 e
  1024x768; text scale 1,0/1,3/2,0; light/dark; es-CL/it/en/zh-Hans;
  portrait/landscape;
- verifica: nessun overflow, CTA critica fuori viewport o crash; Semantics e target
  48 dp verificati; layout wide usa densità e navigazione adattive;
- Admin Playwright locale:
  `node scripts/testing/run-playwright-target.mjs local tests/e2e/storefront-v1-admin-publications-local.spec.ts --project=chromium-desktop`,
  exit 0, 1/1 in 6,7 s (10,9 s totali).

Stato UI pattern audit, Client, Admin, matrix e visual QA: `PASS`.

## Dataset e benchmark staging

Workflow `TASK-019 Storefront Performance Staging`, run `30757512517`, attempt 3,
Admin SHA `1f1ba507bbdde96197276738aacd7e290c20f8fe`: `PASS` in 18m09s.

### Cardinalità verificata

| Campo | Valore |
|---|---:|
| products | 22.000 |
| categories | 100 |
| publications | 22.000 |
| published / draft / paused | 20.000 / 1.000 / 1.000 |
| projection rows | 20.000 |
| promotion links | 5.000 |
| equivalent related rows | 69.200 |
| image-backed projections | 100 |
| distinct public image URLs | 4 |
| fixture rows after cleanup | 0 |

Le immagini sono URL pubbliche reali della fixture; `realImageTemplate=true`. Il dataset
è sintetico, namespaced e non contiene dati cliente.

### API/query — 30 campioni per endpoint

| Metrica | p50 | p95 | p99 | max | Target iniziale | Esito |
|---|---:|---:|---:|---:|---:|---|
| Catalog page | 27,867 ms | 30,114 ms | 31,228 ms | 31,415 ms | p95 <=500 ms | PASS |
| Search FTS | 594,101 ms | 599,739 ms | 686,107 ms | 721,213 ms | p95 <=750 ms | PASS |
| Product detail | 1,784 ms | 4,923 ms | 6,195 ms | 6,479 ms | p95 <=400 ms | PASS |

Altri risultati: bulk projection 33.442,307 ms; promotion rebuild 14.287,832 ms;
rebuild idempotente 2.065,752 ms; `searchFtsIndexUsed=true`,
`catalogKeysetIndexUsed=true`, EXPLAIN catalog execution 123,267 ms, catalog version 3.

Artifact sanitizzato locale `/tmp/storefront-v1-run3.FWIwYS`:

- `contract-load.jsonl`: SHA-256
  `dcd08a9c1439bad95c766fba5a4b41d519f10e8868caf5eb7707dcdc228ed15d`;
- `delta.json`: `aca7ab5894217ca547a55c252f1d13712fd866ccb068c081097cfecd55349c1d`;
- `post-verify.json`: `d7724fb553844a16c1fa6514632f0cb33b76239a6b5302a6bb2a2b7fb6300460`;
- `contract-load-verdict.json`:
  `7f12aeef6ce31ae7084c07bd8ed26def98b037ae0ed11d18055ada29e46ecfff`;
- `supabase-dry-run.txt`:
  `d114acdedc2e5cf0de05f134a4d9009d159cebc87e813245dbcb4dbee10ad812`;
- `remote-ledger.tsv`:
  `839dbc7e4933b2314848b475d6b835cb8d3fff99f80f43fb00ae9705bea8b84e`.

Gli artifact restano locali/GitHub e non sono versionati. Il dry-run finale riporta
remote database up to date; ledger ultimo `20260802043000`.

## Profilo mobile e cache

### Scenario profile Android sul dataset attivo

Comando:

`flutter drive --profile -d emulator-5554 --driver=test_driver/integration_test.dart --target=integration_test/storefront_performance_live_test.dart --dart-define-from-file=config/app_config.staging.local.json --dart-define=STOREFRONT_SHOP_SLUG=task010-load`

Exit 0, 1/1, runtime `fd5eb94`:

| Metrica | Campioni | p50 | p95 | p99/max | Esito |
|---|---:|---:|---:|---:|---|
| First usable dal bootstrap Flutter | 1 | 139 ms | 139 ms | 139 ms | PASS |
| Home data-backed | 1 | 3.257 ms | 3.257 ms | 3.257 ms | PASS |
| Backend ready | 1 | 3.285 ms | 3.285 ms | 3.285 ms | PASS |
| Catalog | 1 | 875 ms | 875 ms | 875 ms | PASS |
| Search | 1 | 1.573 ms | 1.573 ms | 1.573 ms | PASS |
| Detail via deep link | 1 | 985 ms | 985 ms | 985 ms | PASS |
| Favorite add/remove | 1 | 54 ms | 54 ms | 54 ms | PASS |

Il target <=3 s è applicato al first usable interattivo definito prima dell'esecuzione:
Home visibile con search e navigazione operative. `homeDataMs` è mantenuto separato e
non viene presentato come first usable. I tempi endpoint mobili sono one-shot journey;
i percentili robusti di rete/query sono i 30 campioni server precedenti.

### Frame, immagini e memoria

- frame profile: 439 campioni; p50/p95/p99 7.814/44.763/101.114 us;
- 37 frame >32 ms, 5 >100 ms, 0 >700 ms; budget dichiarato p99 <120 ms e zero
  frozen frame: `PASS`; i cinque severe frame restano input per TASK-037 finale;
- source image massimo 1.200x1.200 WebP, card 720 px, decode client bounded
  192/480-720/1.440 px; massimo effettivo sorgente ~5,76 MB RGBA; zero OOM;
- release arm64 dopo Home: PSS 73.661 KB, RSS 189.492 KB, swap 0; budget
  PSS <=200 MB/RSS <=300 MB: `PASS`.

### Cache e startup

| Scenario | Campioni | Dati | p50 | p95 | p99 | Esito |
|---|---:|---|---:|---:|---:|---|
| cache catalog | benchmark locale | 25.000 righe | 636 us | 1.319 us | 8.452 us | PASS |
| cache search | benchmark locale | 25.000 righe | 3.262 us | 4.466 us | 7.653 us | PASS |
| cold process arm64 split release | 5 | 4.105/3.354/4.565/3.287/4.154 ms | 4.105 ms | 4.565 ms | 4.565 ms | PASS |
| warm process arm64 split release | 5 | 436/152/390/519/427 ms | 427 ms | 519 ms | 519 ms | PASS |

Il cold process emulator supera 3 s, ma non è marcato come first usable e non ha un
budget separato nel criterio CA-08. È registrato come baseline reale per TASK-037; il
warm process e la cache warm sono <=1 s. Un avvio cold singolo successivo ha misurato
3.040 ms e non sostituisce la serie da cinque campioni.

## Tentativi falliti e causa primaria

| Tentativo | Causa | Correzione | Esito candidato |
|---|---|---|---|
| Profile install | build release installata con versionCode 2001 > profile 1 | package di test rimosso, nessun reset dati esteso | FAIL |
| Profile config | config locale su `storefront-v1-staging`, test richiede tenant load | override esplicito dello slug sintetico | FAIL |
| Profile dopo run | fixture già ripulita, Home fail-closed `unavailable` | nessun retry cieco; mantenuto campione raccolto durante hold e cleanup 0 | FAIL |
| XCTest iPhone, due tentativi | `UIActivityViewController` adatta il popover su compact width | target iPad richiesto e snapshot anchor/lifecycle stabilizzato | FAIL |
| XCTest iPad finale | target/presentation context corretti | 3/3 sullo SHA esatto | PASS |
| APK x86_64 su emulator arm64 | ABI incompatibile | build/install arm64 split corrispondente | FAIL |

Nessun `PASS` deriva da uno di questi tentativi. I package di test sono stati
force-stop/uninstall e non resta un processo app indefinito.

## Admin, CI e sicurezza

- Playwright Storefront locale 1/1 `PASS`;
- Admin CI `30757513891`: Verify 2m43s e Database migrations/pgTAP 2m45s `PASS`;
- Cloudflare `30757513885`: build 2m48s `PASS`; deploy staging/production `NOT_RUN`
  perché il trigger PR/push è build-only;
- workflow staging performance `30757512517`, attempt 3: `PASS`;
- RLS FORCE su projection, anon/authenticated access diretto denied, RPC pubblici
  allow-listed, helper privati denied, `search_path` fissato, campi interni assenti;
- secret scan Client/Admin: `PASS`; config locale, URL/key, APK, xcresult, coverage e
  artifact load non versionati;
- production migration/deploy/write: `NOT_RUN`; flag Storefront/orders/reservations/
  delivery/push/online payment restano OFF per policy.

## Matrice CA -> evidence

| CA | Evidence | Esito |
|---|---|---|
| CA-01 | audit 228 righe, zero asset/screenshot proprietari | PASS |
| CA-02 | token Material 3, CLP e test quattro locale/theme/breakpoint/target | PASS |
| CA-03 | Home live/skeleton/empty/offline/retry e smoke | PASS |
| CA-04 | Catalog/card/detail responsive e boundary pubblico | PASS |
| CA-05 | Admin responsive, preview, focus/keyboard e Playwright | PASS |
| CA-06 | matrix viewport/text scale/theme/locale/orientamento senza overflow critico | PASS |
| CA-07 | cardinalità 22k/100/69,2k, immagini/promozioni/mix e cleanup 0 | PASS |
| CA-08 | first usable 139 ms; warm process/cache <1 s | PASS |
| CA-09 | API p95 30,114/599,739/4,923 ms | PASS |
| CA-10 | keyset index, cancellation/stale guard e suite pagination | PASS |
| CA-11 | p99 frame 101,114 ms <120 ms, zero frozen/OOM, memoria nel budget | PASS |
| CA-12 | live Home/Catalog/Detail/Favorite, deep link/share/cache/offline regressioni | PASS |
| CA-13 | comandi, SHA, exit, durata, campioni e percentile registrati | PASS |
| CA-14 | gate completi e CI Client/Admin/Supabase verdi | PASS |
| CA-15 | production `NOT_RUN`, flag OFF | PASS |

## Matrice T-NN -> risultato

| Test | Esito |
|---|---|
| T-01 audit bounded | PASS |
| T-02 visual matrix | PASS |
| T-03 Client real data/stati/Semantics | PASS |
| T-04 Admin responsive/focus/bulk/preview | PASS |
| T-05 seed/load/cleanup | PASS |
| T-06 startup/first usable | PASS |
| T-07 load/EXPLAIN/keyset | PASS |
| T-08 frame/memory/image/cache | PASS |
| T-09 Android/iOS headless e regressioni share/deep link/favorite/offline | PASS |
| T-10 gate/CI/secret/production | PASS |

## Esito

TASK-019 è `VALIDATED_PENDING_INTEGRATED_REVIEW`; Milestone 3 è `PASS`. Finding
formali P0/P1/P2/P3: `NOT_RUN` fino alla review integrata finale.
