# Evidence TASK-032

Snapshot di handoff:
`VALIDATED_PENDING_INTEGRATED_REVIEW / EXECUTION / CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`.

L'implementazione TASK-032 e il checkpoint aggregato Milestone 4 sono tecnicamente
verdi; TASK-032 attende la review integrata finale.

## Revision set

- Admin/Supabase funzionale: `a1fa997c44d6a5804c636363ff75cbb3409a14f2`;
- Admin/Supabase payment con lock staging:
  `cddb3f295d735ff3e16eaf705676807cb85efaab`;
- Admin/Supabase Milestone 4 finale:
  `e0406834af09173902e2f64948dd5834f4a9fac5`, PR #67 draft;
- Client runtime: `72f98eea574300f77d42e96e09557f0dd55ac2d5`, PR #5 draft;
- Win7POS invariato: `6c2eb9c8a0b6666f5dd59a2a132e616f5a8d5474`,
  PR #88 draft;
- migration payment: `20260803122644_storefront_v1_customer_payments`;
- migration finale: `20260803143000_storefront_v1_default_address_transition`;
- production e online payment: invariati/OFF.

## Risultati riproducibili

| Gate | Comando/run | Exit/durata/test | Risultato |
|---|---|---|---|
| pgTAP payment locale/staging | `supabase test db ...customer_payments.sql` / run `30817695207` | 0 / 36 su 36 | PASS |
| Race payment | `npm run test:storefront:customer-payment-concurrency` | 0 / 2 writer, 1 aggregate | PASS |
| Provider contract | test Node `storefront-payment-provider` | 0 / 10 su 10 | PASS |
| Admin verify locale | `npm run verify` | 0 / 882 foundation | PASS |
| Admin CI finale | run `30817700671`, SHA `cddb3f29` | 869 pass + 13 skip / 0 fail | PASS |
| Admin Playwright | job CI `30817700671` | 0 / 48 su 48 / 16,5 s | PASS |
| Cloudflare build | run `30817700396`, SHA `cddb3f29` | 0 / 2m46s | PASS |
| Staging payment final | run `30817695207`, SHA `cddb3f29` | 0 / 2m52s | PASS |
| POS fiscal regression | run `30817693665`, SHA `cddb3f29` | 0 / 41 s | PASS |
| Flutter gate canonico | `bash scripts/check.sh` | 0 / circa 120 s / 543 + benchmark 1 | PASS |
| Coverage Client | `flutter test --coverage --exclude-tags performance` | 0 / 19,72 s / 543 | PASS |
| Coverage linee | `coverage/lcov.info` | 11.600/14.935 / 77,67% | PASS |
| Payment/checkout mirati | `flutter test` su suite TASK-032 | 0 / 45 su 45 / 3,36 s | PASS |
| Android integration | `flutter test integration_test/customer_checkout_flow_test.dart -d emulator-5554` | 0 / 1 su 1 / 29,51 s | PASS |
| iOS integration | stesso target su Simulator iPhone 17 Pro 26.5 | 0 / 1 su 1 / build 17,7 s | PASS |
| Android release AAB | `flutter build appbundle --release` | 0 / 13,58 s / 65.463.366 byte | PASS |
| iOS release compile | `flutter build ios --release --no-codesign` | 0 / 32,93 s / 22,8 MB | PASS |
| Artifact/secret scan | `check-client-security.sh --artifact ...` | 0 / 18,31 s / 65 file | PASS |
| Client CI | run `30818475635`, SHA `72f98eea` | zero runner/step; billing | BLOCKED |
| Provider online reale | audit credential/variable | zero credential approvata | BLOCKED |
| Milestone 4 E2E aggregato | run `30822286720`, SHA `e0406834` | 0 / 5m32s / 629 su 629 | PASS |
| TASK-027 staging finale | run `30822288899`, attempt 2 | 0 / 1m15s / 35 su 35 | PASS |
| TASK-028 staging finale | run `30822288363`, attempt 2 | 0 / 8m59s / 30 su 30 | PASS |
| TASK-029 staging finale | run `30822288362`, attempt 2 | 0 / 1m40s / 34 su 34 | PASS |
| Review integrata | freeze Milestone 5 non ancora raggiunto | non eseguita | NOT_RUN |
| Production write/payment | vietato prima della review integrata | non eseguito; flag OFF | NOT_RUN |

## Prova staging sanitizzata

Run finale `30817695207`:

- exact head `cddb3f295d735ff3e16eaf705676807cb85efaab`;
- migration `20260803122644` presente nel ledger remoto;
- payment tables `FORCE RLS`, client table access negato e service transition-only;
- pickup e COD configurato creano snapshot con totale server-derived;
- due richieste concorrenti producono un solo order/payment/attempt/event/mutation;
- payment e refund restano separati da `pos_sales` e fiscal reference;
- online defaults OFF, provider `none`, webhook disabled e production write `false`;
- fixture e righe TASK-032 rimosse al termine.

Artifact:

- payment `8857518647`,
  `sha256:41e10729fccfee6c2c6384a45e8f54cc46978d07db9a86373cc2a8c124901f2c`;
- migration `8857472744`,
  `sha256:255800b1ad905e439eb7ee2552cf82df813cf38c2c69a6a2834d8d2d9f35b98b`.

Checkpoint Milestone 4:

- acceptance `8859500219`, 23.855 byte,
  `sha256:b2fad3f10af44a11c0cdd62b43fa2a10e5433740248db5c5666a6605c454819a`;
- migration `8859345458`,
  `sha256:3f75147e37cb9118ff18a23ca6457707804b39768fc6d40f5bed66e1dc949a4b`;
- post-verifica: migration esatta, commerce table `FORCE RLS`, online defaults OFF,
  fixture integrata rollback e `productionWriteRequested=false`.

Release artifact locali sul Client runtime:

- AAB:
  `sha256:0f92c5b0c1a0e2ff4035a41be18c3d7dd8950d7a7ea5f0404289fc47319da7f7`;
- executable iOS non firmato:
  `sha256:093e60f99faba0ac69caa02001bc406508602cafc8004ac41c570d789bd5fa74`.

## Diagnostica non candidata

- run POS `30815887397`: `db_failure` durante applicazione concorrente della migration
  payment; non era un difetto del contract POS. Il lock condiviso
  `storefront-v1-staging-order-payment` e la regressione statica impediscono la race;
  sullo SHA finale i run POS e payment sono entrambi verdi;
- CI Client `30818475635`: Android/iOS/Quality hanno `steps=[]` e annotation GitHub
  billing/spending limit; è `BLOCKED` esterna, non un failure del codice;
- provider online: nessuna credential sandbox non-interattiva approvata. Il disabled
  adapter non viene presentato come pagamento online reale.
- i primi run aggregati hanno rilevato una violazione transitoria dell'unico indirizzo
  default e assert globali sensibili a fixture concorrenti. Migration additiva,
  isolamento shop/order e mutex condiviso sono le correzioni; la run finale 629/629 e
  i tre workflow legacy sul medesimo SHA ne costituiscono le regressioni.

Nessun finding tecnico P0/P1/P2 è stato prodotto prima della review integrata.
