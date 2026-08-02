# Storefront v1 — Checkpoint riprendibile

- **Fase corrente**: EXECUTION / Milestone 3 / TASK-017 offline cache
- **Task corrente**: TASK-017
- **Repository writer corrente**: ClientMerchandiseControl
- **Branch**: `integration/storefront-v1`
- **SHA Client TASK-016 candidate**: `242e631805b569a49a0217c4129b1586e8ad1dbf`
- **SHA Admin corrente**: `a9036f0bda741d686afbdac13d3d08ef897f059b`
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
- **Gate ancora necessari**: execution TASK-017, migration/cleanup/search offline,
  benchmark 20k e smoke offline/reconnect Android/iOS
- **Comando successivo esatto**: `flutter pub add drift:^2.34.3 drift_flutter:^0.3.1 && flutter pub add --dev drift_dev:^2.34.5 build_runner:^2.16.0`
- **Blocker**: nessuno
- **Processi ancora attivi**: nessuno
- **Stato staging**: Auth/Google callback `PASS`; Milestone 1 schema/RLS/projection/API
  `PASS`; Milestone 2 Admin publish/promozioni/immagini/rollback/cleanup `PASS`;
  fixture pubblica, Home, Catalog, Discovery e Detail guest Android/iOS `PASS`;
  TASK-017 cache offline `NOT_RUN`; production invariata

## Vincoli di ripresa

Rileggere nell'ordine `AGENTS.md`, `docs/MASTER-PLAN.md`, il task corrente,
`docs/CODEX-WORKFLOW-PROTOCOL.md`, questo checkpoint e il release manifest. Non
ripetere il Prelude e non usare i checkout dirty di Win7POS o SplitView.
