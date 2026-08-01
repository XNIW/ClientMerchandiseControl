# Storefront v1 — Checkpoint riprendibile

- **Fase corrente**: EXECUTION / TASK-005 preflight
- **Task corrente**: TASK-005
- **Repository writer corrente**: merchandise-control-admin-web (Supabase canonico)
- **Branch**: `integration/storefront-v1`
- **SHA governance**: `4fd560af7e7eea70ff8fe786b084846cd932d5d6`
- **Gate eseguiti**: Prelude OAuth Android/iOS `PASS`; PR #4 merge `PASS`; main CI
  `30714350425` `PASS`; repository preflight `PASS`
- **Gate governance**: validator `PASS`; fixture negative/positive 8/8 `PASS`; link
  check `PASS`; `git diff --check` `PASS`; security scan 342 file `PASS`; architecture
  boundary e fixture 5/5 `PASS`; CI `30715196235` sullo SHA esatto `PASS`, job
  Quality/iOS/Android 3/3 e annotazioni 0/0/0
- **Git/PR**: branch remota pubblicata; PR Client `#5`, `DRAFT`
- **Admin canonico**: worktree
  `/Users/minxiang/Projects/_release_train/storefront-v1/merchandise-control-admin-web`,
  branch `integration/storefront-v1`, baseline
  `f259e3e049bc31bce9a57afe466142109b081eec`; migration TASK-150 applicata a
  staging nel run `30702026325`, Worker staging aggiornato nel run `30713577326`
- **Gate ancora necessari**: schema/proiezione/API/RLS TASK-005/006/010, replay,
  ledger linked finale, load test e smoke staging
- **Comando successivo esatto**: `rg -n "storefront" supabase/migrations supabase/tests src tests`
- **Blocker**: nessuno
- **Processi ancora attivi**: nessuno
- **Stato staging**: Auth/Google callback `PASS`; migration ledger verificato fino a
  TASK-150 tramite workflow guarded; Storefront schema/API `NOT_RUN`; production
  invariata

## Vincoli di ripresa

Rileggere nell'ordine `AGENTS.md`, `docs/MASTER-PLAN.md`, il task corrente,
`docs/CODEX-WORKFLOW-PROTOCOL.md`, questo checkpoint e il release manifest. Non
ripetere il Prelude e non usare i checkout dirty di Win7POS o SplitView.
