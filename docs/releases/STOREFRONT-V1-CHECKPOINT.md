# Storefront v1 — Checkpoint riprendibile

- **Fase corrente**: EXECUTION / Milestone 3 / TASK-013 Home reale
- **Task corrente**: TASK-013
- **Repository writer corrente**: ClientMerchandiseControl
- **Branch**: `integration/storefront-v1`
- **SHA Client checkpoint parent**: `ae726fadf8b0ffdc51d3a99da17c726e5381e744`
- **SHA Admin corrente**: `429c9ca88818c2f3c68a53cd4663843ae172cb8b`
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
- **Gate ancora necessari**: planning/execution TASK-013, fixture catalogo staging
  persistente e smoke Home reale Android/iOS
- **Comando successivo esatto**: `rg -n "HomeScreen|AppConfig|Supabase.instance|storefront_home_v1" lib test config docs`
- **Blocker**: nessuno
- **Processi ancora attivi**: nessuno
- **Stato staging**: Auth/Google callback `PASS`; Milestone 1 schema/RLS/projection/API
  `PASS`; Milestone 2 Admin publish/promozioni/immagini/rollback/cleanup `PASS`;
  catalogo client persistente TASK-013 ancora `NOT_RUN`; production invariata

## Vincoli di ripresa

Rileggere nell'ordine `AGENTS.md`, `docs/MASTER-PLAN.md`, il task corrente,
`docs/CODEX-WORKFLOW-PROTOCOL.md`, questo checkpoint e il release manifest. Non
ripetere il Prelude e non usare i checkout dirty di Win7POS o SplitView.
