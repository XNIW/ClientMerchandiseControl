# Evidence TASK-020

Snapshot di handoff:
`ACTIVE / FIX / CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Stato

- Planning: `PASS`
- Autorizzazione Execution: `PASS` — concessa e applicata dal prompt end-to-end
- Execution: `PASS` per i gate automatizzabili; dipendenze esterne esplicitate
- Review: `CHANGES_REQUIRED` — cinque reviewer, 1 P1, 18 P2 e 2 P3 consolidati
- Fix: `PASS` sul commit tecnico `408f14d` per i finding implementati; gate locali
  214/214, coverage 80,1%, build e smoke fake dual-platform
- Re-review 1: `CHANGES_REQUIRED` — 16/21 finding originari chiusi; restano 1 P1,
  6 P2 e 3 P3
- CI: `BLOCKED / CI_EXTERNAL`
- PR/merge: draft PR #4 su `0ddd26a`; run `30619705565` senza runner; merge
  `BLOCKED`
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

Le matrici canoniche complete una-riga-per-CA e una-riga-per-test, con `Tipo`,
stato e command ID, sono in
[commands-and-results.md](commands-and-results.md). Ogni evidence focalizzata usa
quella matrice come indice normativo e documenta soltanto il proprio subset, evitando
duplicazioni che potrebbero divergere.

## Blocchi esterni aperti

- Supabase dashboard: MFA necessario per leggere/modificare la redirect allow-list;
  nessun write remoto è stato eseguito.
- iOS Simulator: conferma OS del custom scheme pendente; il Mac locked impedisce
  l'accettazione automatica del dialogo.
- GitHub Actions: la run `30619705565` sullo SHA di re-review ha tre job senza step,
  fermati prima del runner dal limite billing/spending.

Le evidence finali dovranno contenere esattamente una riga per ciascuno dei 40 CA e
38 test, con soli esiti `PASS`, `FAIL`, `BLOCKED` o `NOT_RUN`. Non sono ammessi URL,
key, project ref completi, OAuth code, token, session object, account Google, email,
PII, password, secret, callback con query/fragment o screenshot non redatti.
