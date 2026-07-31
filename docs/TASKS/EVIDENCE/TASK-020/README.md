# Evidence TASK-020

Snapshot di handoff:
`ACTIVE / REVIEW / CODEX_EXECUTION_COMPLETE_TO_REVIEW`.

## Stato

- Planning: `PASS`
- Autorizzazione Execution: `PASS` — concessa e applicata dal prompt end-to-end
- Execution: `PASS` per i gate automatizzabili; dipendenze esterne esplicitate
- Review: `NOT_RUN`
- Fix/re-review: `NOT_RUN`
- CI: `NOT_RUN`
- PR/merge: `NOT_RUN`
- DONE: `NO`

## Indice

- [planning-summary.md](planning-summary.md) — baseline, gap, scope, strategia e
  handoff.
- [environment-audit.md](environment-audit.md) — staging, configurazione locale,
  toolchain e limiti esterni sanitizzati.
- [auth-architecture.md](auth-architecture.md) — decisioni API/PKCE, boundary,
  storage, state machine e implementazione.
- [supabase-staging-config.md](supabase-staging-config.md) — discovery, provider,
  authorize probe e blocker allow-list.
- [security-review.md](security-review.md) — threat model, scan e rischi residui.
- [commands-and-results.md](commands-and-results.md) — gate e matrici complete
  CA/T.
- [android-google-auth-smoke.md](android-google-auth-smoke.md) — build, callback
  nativo, fake flow e limite live Android.
- [ios-google-auth-smoke.md](ios-google-auth-smoke.md) — build, fake flow,
  LaunchServices e limite live iOS.
- [review-report.md](review-report.md) — stato review A–E.
- [ci-status.md](ci-status.md) — stato CI dello SHA TASK-020.
- [git-state.md](git-state.md) — branch, scope e stato Git sanitizzato.

## Blocchi esterni aperti

- Supabase dashboard: MFA necessario per leggere/modificare la redirect allow-list;
  nessun write remoto è stato eseguito.
- iOS Simulator: conferma OS del custom scheme pendente; il Mac locked impedisce
  l'accettazione automatica del dialogo.
- GitHub Actions: il limite billing/spending osservato nel closeout TASK-012 resta da
  riverificare sullo SHA finale.

Le evidence finali dovranno contenere esattamente una riga per ciascuno dei 40 CA e
38 test, con soli esiti `PASS`, `FAIL`, `BLOCKED` o `NOT_RUN`. Non sono ammessi URL,
key, project ref completi, OAuth code, token, session object, account Google, email,
PII, password, secret, callback con query/fragment o screenshot non redatti.
