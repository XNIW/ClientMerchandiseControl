# Storefront v1 — Checkpoint riprendibile

- **Fase corrente**: EXECUTION / TASK-005 preflight
- **Task corrente**: TASK-005
- **Repository writer corrente**: ClientMerchandiseControl, poi Admin canonico
- **Branch**: `integration/storefront-v1`
- **SHA governance**: `7b7931b03831090241a40602dc999b846a75a9f0`
- **Gate eseguiti**: Prelude OAuth Android/iOS `PASS`; PR #4 merge `PASS`; main CI
  `30714350425` `PASS`; repository preflight `PASS`
- **Gate governance**: validator `PASS`; fixture negative/positive 8/8 `PASS`; link
  check `PASS`; `git diff --check` `PASS`; security scan 342 file `PASS`; architecture
  boundary e fixture 5/5 `PASS`
- **Gate ancora necessari**: push/CI governance; poi ownership/ledger/drift TASK-005
- **Comando successivo esatto**: `git push -u origin integration/storefront-v1`
- **Blocker**: nessuno
- **Processi ancora attivi**: nessuno
- **Stato staging**: Auth/Google callback `PASS`; Storefront schema/API `NOT_RUN`;
  production invariata

## Vincoli di ripresa

Rileggere nell'ordine `AGENTS.md`, `docs/MASTER-PLAN.md`, il task corrente,
`docs/CODEX-WORKFLOW-PROTOCOL.md`, questo checkpoint e il release manifest. Non
ripetere il Prelude e non usare i checkout dirty di Win7POS o SplitView.
