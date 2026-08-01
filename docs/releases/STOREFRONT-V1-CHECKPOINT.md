# Storefront v1 — Checkpoint riprendibile

- **Fase corrente**: EXECUTION / TASK-006 projection
- **Task corrente**: TASK-006
- **Repository writer corrente**: merchandise-control-admin-web (Supabase canonico)
- **Branch**: `integration/storefront-v1`
- **SHA Client checkpoint parent**: `8d854b2594c7f5ab727702d800d5bfe08f1a8264`
- **SHA Admin corrente**: `ef2e94302102745d57aedc5071d3edd4ddee0e91`
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
- **Gate ancora necessari**: projection/version/rebuild TASK-006; API/RPC/search/load
  TASK-010; replay, no-drift e rollback rehearsal compositi del checkpoint Milestone 1
- **Comando successivo esatto**: `rg -n "storefront_(product_publications|promotions|categories|settings|image_publications)" supabase/migrations/20260801195852_storefront_v1_schema_rls.sql supabase/tests/storefront_v1_schema_rls.sql`
- **Blocker**: nessuno
- **Processi ancora attivi**: nessuno
- **Stato staging**: Auth/Google callback `PASS`; Storefront schema/RLS TASK-005
  `PASS`; projection/API `NOT_RUN`; production invariata

## Vincoli di ripresa

Rileggere nell'ordine `AGENTS.md`, `docs/MASTER-PLAN.md`, il task corrente,
`docs/CODEX-WORKFLOW-PROTOCOL.md`, questo checkpoint e il release manifest. Non
ripetere il Prelude e non usare i checkout dirty di Win7POS o SplitView.
