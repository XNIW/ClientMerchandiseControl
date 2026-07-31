# Evidence TASK-020

Snapshot di handoff:
`ACTIVE / PLANNING / CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION`.

## Stato

- Planning: `PASS`
- Autorizzazione Execution: `NOT_RUN` — concessa dal prompt, transizione distinta
  ancora da applicare
- Execution: `NOT_RUN`
- Review: `NOT_RUN`
- Fix/re-review: `NOT_RUN`
- CI: `NOT_RUN`
- PR/merge: `NOT_RUN`
- DONE: `NO`

## Indice corrente

- [planning-summary.md](planning-summary.md) — baseline, gap, scope, strategia e
  handoff.
- [environment-audit.md](environment-audit.md) — staging, configurazione locale,
  toolchain e limiti esterni sanitizzati.
- [auth-architecture.md](auth-architecture.md) — decisioni API/PKCE, boundary,
  storage, state machine e piano file.

## Evidence obbligatorie da completare

- `supabase-staging-config.md`
- `security-review.md`
- `commands-and-results.md`
- `android-google-auth-smoke.md`
- `ios-google-auth-smoke.md`
- `review-report.md`
- `ci-status.md`
- `git-state.md`

Le evidence finali dovranno contenere esattamente una riga per ciascuno dei 40 CA e
38 test, con soli esiti `PASS`, `FAIL`, `BLOCKED` o `NOT_RUN`. Non sono ammessi URL,
key, project ref completi, OAuth code, token, session object, account Google, email,
PII, password, secret, callback con query/fragment o screenshot non redatti.
