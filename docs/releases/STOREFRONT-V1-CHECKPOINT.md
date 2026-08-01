# Storefront v1 — Checkpoint riprendibile

- **Fase corrente**: EXECUTION / Milestone 2 / TASK-008 prezzi e promozioni
- **Task corrente**: TASK-008
- **Repository writer corrente**: merchandise-control-admin-web
- **Branch**: `integration/storefront-v1`
- **SHA Client checkpoint parent**: `857f098b124c00bbfd072194d048173d44671151`
- **SHA Admin corrente**: `25f858931bf0ffe09213186a6b8b124df0311c97`
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
- **Gate ancora necessari**: implementazione e gate TASK-008; poi TASK-009 e checkpoint
  Milestone 2
- **Comando successivo esatto**: `rg -n "storefront_promotions|promotion_products|price_source_mode|compare_at" supabase src tests`
- **Blocker**: nessuno
- **Processi ancora attivi**: nessuno
- **Stato staging**: Auth/Google callback `PASS`; Milestone 1 schema/RLS/projection/API
  `PASS`; Admin Storefront TASK-007 publish/audit/pause `PASS`; production invariata

## Vincoli di ripresa

Rileggere nell'ordine `AGENTS.md`, `docs/MASTER-PLAN.md`, il task corrente,
`docs/CODEX-WORKFLOW-PROTOCOL.md`, questo checkpoint e il release manifest. Non
ripetere il Prelude e non usare i checkout dirty di Win7POS o SplitView.
