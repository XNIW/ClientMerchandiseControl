# Evidence TASK-045

Snapshot di handoff:
`ACTIVE / EXECUTION / CODEX_PLANNING_APPROVED_TO_EXECUTION`.

## Provenance

- Client base: `fd044d4b9b7a7bd4c4d3ccf71b977a01bc39563f`;
- branch: `codex/task-045-client-live-map-20260816`;
- worktree: linked e pulito da `origin/main`; checkout primario preservato;
- Admin/Supabase authority: main `2e8ec07e1609b7bfa7b1a5210f232fc60bbf5412`,
  contratto TASK-044 già integrato e verificato;
- production, billing e provider key: non acceduti, activation `OFF`.

## Planning

- ADR-014 governa provider, adapter, fake, chiavi native separate e fail-closed;
- UI e test riusano Material 3, token, localizzazioni e contratti reali esistenti;
- nessun ETA, route, marker o movimento viene inventato dal Client.

## Execution

Da aggiornare con CA/T-NN, comandi, exit code e artifact sanitizzati.
