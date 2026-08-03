# Evidence TASK-031

Snapshot di handoff:
`VALIDATED_PENDING_INTEGRATED_REVIEW / EXECUTION / CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`.

## Revision set

- Admin/Supabase: `e9bcbc8c98a7dc1d0fdcfdbd549d7968a2fdbb19`, PR #67 draft;
- Client runtime: `ed2f8a5c95f70ce057860027408d9f61314d6f4e`, PR #5 draft;
- Win7POS invariato: `6c2eb9c8a0b6666f5dd59a2a132e616f5a8d5474`, PR #88 draft;
- migration: `20260803104431_storefront_v1_order_notifications`;
- production e `customer_order_push_enabled`: invariati/OFF.

## Risultati riproducibili

| Gate | Comando/run | Exit/durata/test | Risultato |
|---|---|---|---|
| pgTAP dedicato | `supabase test db supabase/tests/storefront_v1_order_notifications.sql` | 0 / 40 su 40 | PASS |
| Race dispatcher | `scripts/testing/storefront-v1-order-notification-concurrency.sh` | 0 / lease-retry-replay | PASS |
| Dispatcher unit | test foundation dedicato | 0 / 7 su 7 | PASS |
| Admin verify locale | `npm run verify` | 0 | PASS |
| Admin CI finale | run `30811750153`, SHA `e9bcbc8c` | 859 pass + 13 skip / 0 fail | PASS |
| Cloudflare build | run `30811750080`, SHA `e9bcbc8c` | 0 / 3m19s | PASS |
| Migration staging | run `30809256239`, SHA `353ade50` | 0 / apply + post-verify | PASS |
| Staging final verify/E2E | run `30811747216`, SHA `e9bcbc8c` | 0 / 2m33s run | PASS |
| Flutter gate canonico | `bash scripts/check.sh` | 0 / 120,86 s / 538 test | PASS |
| Coverage Client | `flutter test --coverage` nel gate canonico | 11.280/14.565 / 77,45% | PASS |
| Notification/deep-link mirati | `flutter test` su quattro suite TASK-031 | 0 / 4,37 s / 19 su 19 | PASS |
| Android native mapper | `./gradlew :app:testDebugUnitTest` | 0 / 23 s / 1 su 1 | PASS |
| iOS native RunnerTests | `xcodebuild test ... iPhone 17 Pro,OS=26.5` | 0 / 9,624 s / 4 su 4 | PASS |
| Android staging build | `flutter build apk --debug --dart-define-from-file=...staging.local.json` | 0 / 7,4 s | PASS |
| iOS staging build | `flutter build ios --simulator --debug --dart-define-from-file=...staging.local.json` | 0 / 11,9 s | PASS |
| Android cold/warm intent | `adb am start -W ... --es deepLink <opaque>` | 0 / Auth gate visibile | PASS |
| iOS route headless | `simctl openurl ... <opaque>` | 0 / Auth gate visibile | PASS |
| Client CI | run `30811578997`, SHA `ed2f8a5` | zero runner/step; billing | BLOCKED |
| Provider APNs/FCM reale | audit secret/variable provider | 0 credential disponibile | BLOCKED |
| Review integrata | freeze Milestone 5 non ancora raggiunto | non eseguita | NOT_RUN |
| Production write/push | vietato prima della review integrata | non eseguito; flag OFF | NOT_RUN |

## Prova staging sanitizzata

Run finale `30811747216`:

- exact head `e9bcbc8c98a7dc1d0fdcfdbd549d7968a2fdbb19`;
- migration ledger locale/remoto 125/125 e migration `20260803104431` applicata;
- event/delivery/receipt privati, RLS forzata e boundary dispatcher/owner `PASS`;
- recording provider: 2 messaggi, 1 delivery terminale, nessuna credential provider;
- flag OFF, destination revoked e generation ruotata non claimate;
- payload localizzato e route opaca; order/owner/token/PII non esposti;
- cleanup: zero righe attive e shop archiviato;
- `productionWriteRequested=false`.

Artifact:

- E2E `8855111072`,
  `sha256:274d0f305e8797c8975d8184ceab2feb5f06848d9688a2caabb7555447c4e84e`;
- DB `8855089157`,
  `sha256:98ea12f379cdfc4bfa227c961a428578fa784d2a43192c886e2ad03ffbc4bcb7`;
- migration `8855061934`,
  `sha256:4176cae1ccb40991ec86c458324e8d7c8d325d8932a29d4accd8b60d560ebe48`.

## Diagnostica non candidata

- run staging `30809256239`: migration, pgTAP ed esecuzione E2E `PASS`; verifica
  evidence `FAIL` perché il banner `npm run` precedeva il JSON. Il workflow ora invoca
  Node direttamente e il test foundation verifica la regressione; run finale verde;
- CI Client `30811578997`: i tre job hanno `steps=[]`, `runner_id=0` e annotation
  billing/spending limit. È `BLOCKED` esterna, non un failure del codice;
- provider live: nessun secret/variable con nome APNs/FCM/Firebase/push nei repository
  o environment GitHub. Il recording provider resta test, non prova delivery fisica.

Nessun finding tecnico P0/P1/P2 è stato prodotto prima della review integrata.
