# Storefront v1 — Checkpoint riprendibile

- **Fase corrente**: EXECUTION / Milestone 4 / TASK-027 ordine idempotente
- **Task corrente**: TASK-027
- **Repository writer corrente**: merchandise-control-admin-web / Supabase
- **Branch**: `integration/storefront-v1`
- **SHA Client runtime corrente**: `9406df7d5b5d5a69a0edc033359be38f3bdf656f`
- **SHA Admin/Supabase corrente**: `86088dc739c59725735533c64133678e96641a9a`
- **Gate eseguiti**: Prelude OAuth Android/iOS `PASS`; PR #4 merge `PASS`; main CI
  `30714350425` `PASS`; repository preflight `PASS`
- **Gate governance**: validator `PASS`; fixture negative/positive 8/8 `PASS`; link
  check `PASS`; `git diff --check` `PASS`; security scan 342 file `PASS`; architecture
  boundary e fixture 5/5 `PASS`; CI `30715196235` sullo SHA esatto `PASS`, job
  Quality/iOS/Android 3/3 e annotazioni 0/0/0
- **Git/PR**: branch remota pubblicata; PR Client `#5`, `DRAFT`
- **Admin canonico**: schema/RLS TASK-005 applicato a staging con run
  `30717903744`; ledger/postcheck esatti, 6 tabelle authoring FORCE RLS, zero policy
  cliente e default flag OFF; production invariata
- **Gate TASK-005**: replay 100 migration `PASS` 27.75s; pgTAP 19 file/1330 test
  `PASS` 46.80s; Storefront 48/48; CI `30717750929` e Cloudflare
  `30717750934` `PASS`; dry-run `30717871139` e apply `30717903744` `PASS`
- **Gate TASK-006**: replay 102 migration `PASS`; pgTAP 20 file/1378 test `PASS`;
  concurrency due writer `PASS`; CI `30719303538`, Cloudflare `30719303536`, dry-run
  `30719307636`, apply `30719348489` e smoke staging publish/promo/pause/rollback `PASS`
- **Gate TASK-010/Milestone 1**: replay 104 migration; pgTAP 21 file/1428 test;
  CI `30721537778`; Cloudflare `30721537758`; dry-run `30721664685`; staging
  apply/postverify/load `30721691138`; 20k/100/65k, cleanup 0, tutti `PASS` sul budget
  NANO documentato. Target iniziali catalog/search restano `FAIL`, detail `PASS`.
- **Gate TASK-007**: replay 105 migration; pgTAP 22 file/1.449 test; TASK-007 21/21;
  CI `30723885377`, Cloudflare `30723885380`, staging apply `30723486727`, deploy/smoke
  `30723988967` e acceptance autenticata `30724135568`, tutti `PASS`; fixture residue 0
- **Gate TASK-008**: replay 106 migration; pgTAP 23 file/1.472 test; TASK-008 23/23;
  CI `30725543266`, Cloudflare PR `30725543260`, dry-run `30725661643`, apply/postverify
  `30725690931`, deploy/smoke `30725801242` e acceptance autenticata `30725925704`
  1/1 in 33,1 s, tutti `PASS`; fixture residue 0
- **Gate TASK-009/Milestone 2**: Admin SHA `429c9ca8`; replay 107; pgTAP 24
  file/1.504 test e immagini 32/32; CI `30729546565`; build `30729546558`;
  migration `30728431358`; deploy `30729642919`; acceptance E2E + cleanup
  `30729785520`, tutti `PASS`; production invariata
- **Gate TASK-013**: Client SHA `2aefa17f`; 240 test, coverage 81,17%, security,
  governance, architecture, analyze e build Android/iOS `PASS`; CI `30732213362`
  3/3 `PASS`; Android readiness 1/1, Home Android 1/1 e Home iOS 1/1 `PASS`;
  fixture Admin SHA `a9036f0b`, deploy `30731372117`, CI `30731757331` e acceptance
  `30731760038` `PASS`; production invariata
- **Gate TASK-014**: Client SHA `61d8781c`; 254 test, coverage 82,42%, security,
  governance, architecture, analyze e build Android/iOS `PASS`; CI `30733287396`
  3/3 `PASS`; Catalog Android 1/1 in 14 s e iOS 1/1 in 2 s `PASS`; production invariata
- **Gate TASK-015**: Client SHA `6739bf66`; 266 test, coverage 83,18%, security 379
  file, governance, architecture, analyze e build Android/iOS `PASS`; CI
  `30734363845` 3/3 `PASS`; Discovery Android 1/1 in 20 s e iOS 1/1 in 3 s `PASS`;
  production invariata
- **Gate TASK-016**: Client SHA `242e6318`; 282 test, coverage 82,51%, security 388
  file, governance, architecture, analyze e build Android/iOS `PASS`; CI
  `30735374419` 3/3 `PASS`; Detail published/unpublished Android 1/1 in 17 s e iOS
  1/1 in 3 s `PASS`; tentativo Android harness iniziale `FAIL` corretto; production invariata
- **Gate TASK-017**: Client SHA `e5f4bd8`; 303 test, coverage 81,57%, security 402
  file, governance 8/8, architecture 7/7, analyze e build Android/iOS `PASS`; cache
  suite 19/19, 25.000 righe, open 247 ms, write 20k 444 ms, catalog p95 1.195 µs e
  search p95 3.824 µs; CI `30737515662` 3/3 `PASS`, annotation 0/0/0; offline/reconnect
  Android 1/1 in 45,98 s e iOS 1/1 in 27,09 s `PASS`; production invariata
- **Gate TASK-018**: repository boundary share/favorite/link, 329 test, coverage 81,73%,
  gate locale exit 0 in 79,66 s, CI `30751191932` 3/3 con annotation 0/0/0,
  favorite e deep link Android/iOS, chooser Android reale e XCTest
  `UIActivityViewController` 3/3 su iPad Simulator 26.5: `PASS`; zero match token nei
  log live; manual Activity Sheet `NOT_RUN` per decisione USER_APPROVER D-08
- **Gate TASK-019/Milestone 3**: Client `8f6c67d`, 344 test, coverage 82,74%, gate
  completo 98,32 s e CI `30759482376` 3/3 `PASS`; XCTest iPad 3/3 `PASS`; smoke live
  Android 4/4 `PASS`; first usable 139 ms, cache warm e warm process <1 s, zero
  frozen frame/OOM. Admin `1f1ba507`, CI `30757513891`, Cloudflare build
  `30757513885`, Playwright 1/1 e staging performance `30757512517` attempt 3 tutti
  `PASS`. Dataset 22.000 prodotti/100 categorie/69.200 righe equivalenti; p95
  catalog/search/detail 30,114/599,739/4,923 ms; migration `20260802043000`, cleanup 0
- **Gate TASK-021**: Admin `27770dbe`, migration staging `20260802181823`, tre tabelle
  FORCE RLS/nove policy/cinque RPC, pgTAP 64/64 e suite 26 file/1.582 test; CI
  `30761579498`, Cloudflare `30761579496`, staging `30761578366` e performance
  regression `30761578384` `PASS`. Client `4f25b539`, 371 test, coverage 80,91%, gate
  completo 100,41 s, build Android/iOS e integration Account Android/iOS 1/1 `PASS`.
  CI Client `30763287350` `BLOCKED` esterna: tre job senza runner/step per billing.
- **Gate TASK-022**: Admin `c8f4048f`, migration staging `20260802194500`, tabella
  `customer_devices` FORCE RLS e RPC register/revoke/status; pgTAP 58/58, suite 27
  file/1.640 test, CI `30764931962`, Cloudflare `30764931964` e staging
  `30764930029` `PASS`; artifact `8838637043`, digest
  `ec7764abe27e019d95ecbcb7df3378445565bd2c951fd54a47fdf35395771d6f`.
  Client `b113f44`, 403 test, coverage 80,61%, gate completo 119 s, build Android/iOS,
  integration device Android 1/1 in 23 s e iOS 1/1 in 33 s, artifact smoke e
  accessibility tree `PASS`. CI Client `30766494620` `BLOCKED` esterna: tre job senza
  runner/step per billing. Provider live non configurato, nessun push finto.
- **Gate TASK-023**: Admin `80556a90`, migration staging `20260802210000` + bridge
  pubblico `20260802213000`, tre tabelle FORCE RLS, quattro RPC slug-based, pgTAP
  98/98 e suite 28 file/1.738 test; CI `30768157319`, Cloudflare `30768157310` e
  staging `30768155279` `PASS`. Client `e8d71d38`, cache Drift v3, cart guest/account,
  merge/revalidation, 429 test, coverage 79,55%, build Android debug/release e iOS
  debug/release compile, integration Android/iOS e smoke artifact `PASS`. CI Client
  `30770239675` `BLOCKED` esterna per billing prima dei runner.
- **Gate TASK-024**: Admin `9d457ee4`, migration staging `20260802220000`, segnale
  privato/freshness/ingest e sei stati fail-closed; pgTAP 243/243 e suite 1.782/1.782;
  CI `30772550353`, Cloudflare `30772550354`, staging `30772549228` `PASS`. Client
  `b34211f0`, cache Drift v4, 433 test, coverage 79,91%, build Android/iOS,
  integration refresh/restart Android/iOS e smoke artifact `PASS`. CI Client
  `30773126667` `BLOCKED` esterna per billing prima dei runner.
- **Gate TASK-025**: Admin `448a778c`, migration staging `20260803000951` + eligibility
  `20260803003855`, hold/ledger privati FORCE RLS, tre RPC strict, TTL/limiti server,
  cleanup cron; pgTAP 54/54, 196 assertion isolate, race ultimo pezzo e load 1.200 hold
  `PASS`; CI `30776746985`, Cloudflare `30776746979`, staging `30776745250` `PASS`.
  Client `fe85ce91`, storage pending/versionato, repository/coordinator/controller/UI,
  461 test, coverage 79,03%, build Android/iOS, integration reservation Android/iOS
  2/2 e smoke artifact `PASS`. CI Client `30776491402` `BLOCKED` esterna per billing.
- **Gate TASK-026**: Admin `86088dc7`, migration staging `20260803020000` + Admin
  `20260803021500`, fulfillment/quote/ledger privati FORCE RLS, quattro RPC customer e
  due Admin; pgTAP 56/56, suite 31 file/1.892 test e race ultimo slot `PASS`; CI
  `30779607356`, Cloudflare `30779607377`, staging `30779605562` `PASS`. Client
  `9406df7d`, checkout cinque step, restore/idempotency/repricing, 489 test, coverage
  77,10%, build Android/iOS, integration checkout Android/iOS 1/1, live staging e smoke
  artifact `PASS`. CI Client `30781669519` `BLOCKED` esterna per billing.
- **Gate ancora necessari**: TASK-027 ordine, item snapshot, status event, outbox,
  consume hold atomico, idempotency, malicious total e concurrency duplicate
- **Comando successivo esatto**: nel writer Admin/Supabase, mappare in sola lettura
  schema order/sale/event/outbox, quote/cart/hold, writer inventory, convenzioni ID/RLS/
  audit, lock/idempotency e boundary POS prima di scegliere schema e transaction order
- **Blocker**: GitHub-hosted CI Client `BLOCKED` esterna per billing/spending limit;
  nessun blocker tecnico corrente per TASK-027
- **Processi ancora attivi**: `caffeinate -dimsu`, PID `57046`; Android Emulator
  `emulator-5554`, API 35, sessione exec `90303`; iOS Simulator iPhone 17 Pro iOS 26.5
  UUID `240F400E-5EFA-486A-9137-FFBBE70F604D`. Sono controllati e necessari ai gate
  mobile successivi; `caffeinate` deve essere terminato al closeout del release train
- **Stato staging**: Auth/Google callback `PASS`; Milestone 1 schema/RLS/projection/API
  `PASS`; Milestone 2 Admin publish/promozioni/immagini/rollback/cleanup `PASS`;
  fixture pubblica, Home, Catalog, Discovery, Detail, cache offline/reconnect,
  favorite/share/deep link guest Android/iOS, XCTest share iOS, UI hardening,
  performance extended dataset, TASK-021 profile/address/privacy, TASK-022 device/
  consent/token lifecycle, TASK-023 cart/revalidation, TASK-024 availability/freshness/
  cache refresh, TASK-025 hold/idempotency/expiry/cleanup e TASK-026 fulfillment/quote/
  checkout `PASS`; TASK-027 attivato; production invariata

## Vincoli di ripresa

Rileggere nell'ordine `AGENTS.md`, `docs/MASTER-PLAN.md`, il task corrente,
`docs/CODEX-WORKFLOW-PROTOCOL.md`, questo checkpoint e il release manifest. Non
ripetere il Prelude e non usare i checkout dirty di Win7POS o SplitView.
