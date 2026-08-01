# Storefront v1 — Checkpoint riprendibile

- **Fase corrente**: EXECUTION / TASK-010 public catalog contract
- **Task corrente**: TASK-010
- **Repository writer corrente**: merchandise-control-admin-web (Supabase canonico)
- **Branch**: `integration/storefront-v1`
- **SHA Client checkpoint parent**: `b7e2e8e`
- **SHA Admin corrente**: `a2a45ef84b19e39d21e42673c31e2e8fc90e88f4`
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
- **Gate ancora necessari**: API/RPC/search/load TASK-010; replay, no-drift e rollback
  rehearsal compositi del checkpoint Milestone 1
- **Comando successivo esatto**: `rg -n "storefront_catalog_(items|versions)|security definer|keyset|search" supabase/migrations supabase/tests`
- **Blocker**: nessuno
- **Processi ancora attivi**: nessuno
- **Stato staging**: Auth/Google callback `PASS`; schema/RLS TASK-005 `PASS`;
  projection/version TASK-006 `PASS`; API TASK-010 `NOT_RUN`; production invariata

## Vincoli di ripresa

Rileggere nell'ordine `AGENTS.md`, `docs/MASTER-PLAN.md`, il task corrente,
`docs/CODEX-WORKFLOW-PROTOCOL.md`, questo checkpoint e il release manifest. Non
ripetere il Prelude e non usare i checkout dirty di Win7POS o SplitView.
