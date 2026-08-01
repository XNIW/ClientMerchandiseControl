# Storefront v1 — Checkpoint riprendibile

- **Fase corrente**: EXECUTION / governance completamento
- **Task corrente**: TASK-005
- **Repository writer corrente**: ClientMerchandiseControl, poi Admin canonico
- **Branch**: `integration/storefront-v1`
- **SHA base**: `6a50b421057a09d4152653a78512d268a7fa4d69`
- **Gate eseguiti**: Prelude OAuth Android/iOS `PASS`; PR #4 merge `PASS`; main CI
  `30714350425` `PASS`; repository preflight `PASS`
- **Gate ancora necessari**: validator governance, link check, `git diff --check`,
  commit/push/CI governance; poi ownership/drift TASK-005
- **Comando successivo esatto**: `bash scripts/check-governance-state.sh`
- **Blocker**: nessuno
- **Processi ancora attivi**: nessuno
- **Stato staging**: Auth/Google callback `PASS`; Storefront schema/API `NOT_RUN`;
  production invariata

## Vincoli di ripresa

Rileggere nell'ordine `AGENTS.md`, `docs/MASTER-PLAN.md`, il task corrente,
`docs/CODEX-WORKFLOW-PROTOCOL.md`, questo checkpoint e il release manifest. Non
ripetere il Prelude e non usare i checkout dirty di Win7POS o SplitView.
