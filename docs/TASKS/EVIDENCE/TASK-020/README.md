# Evidence TASK-020

Snapshot di handoff:
`ACTIVE / REVIEW / CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION`.

## Stato

- Planning: `PASS`
- Autorizzazione Execution: `PASS` — concessa e applicata dal prompt end-to-end
- Execution: `PASS` per i gate automatizzabili; dipendenze esterne esplicitate
- Review: `CHANGES_REQUIRED` — cinque reviewer, 1 P1, 18 P2 e 2 P3 consolidati
- Fix: `PASS` sul commit tecnico `408f14d` per i finding implementati; gate locali
  214/214, coverage 80,1%, build e smoke fake dual-platform
- Re-review 1: `CHANGES_REQUIRED` — 16/21 finding originari chiusi; restano 1 P1,
  6 P2 e 3 P3
- Fix 2: `PASS` sul commit tecnico
  `036dcd1be047d49d6b53738d06e5e58caf608f34`; audit candidate 0 P0/P1/P2,
  gate 218/218, coverage 79,9%, build/smoke fake dual-platform e scanner 629 file
- Re-review 2: `CHANGES_REQUIRED` — 0 P0, 0 P1, 4 P2 e 0 P3; scanner path,
  tombstone multi-failure e provenance Git/CI/bundle
- Fix 3: `PASS` sul commit tecnico
  `5740c835a116af16ab2e7ca6c55c927d180ece90`; i quattro P2 sono stati
  affrontati, gli audit candidate riportano 0 P0/P1/P2, i gate locali hanno
  221/221 test e coverage 1802/2247 (80,2%), scanner 336 file con 22/22 fixture
  negative e 1/1 positiva, build e smoke fake dual-platform
- Re-review 3: `CHANGES_REQUIRED` — RR2-001…004 chiusi; 0 P0, 0 P1, 1 P2 e
  1 P3 aperti per JWT customer accettato dallo scanner e path host non redatto
- Fix 4: `PASS` sul commit tecnico
  `9dbd53532f7a49040d0bf94fcd1a28abf5a0d382`; i due finding sono stati
  affrontati senza dichiararli chiusi, scanner 336 file, 32/32 fixture negative
  respinte e 2/2 positive accettate, build development/staging dual-platform e
  artifact finali 548 + 81 = 629 file
- Re-review 4: `BLOCKED` — cinque shard A–E, 0 P0/P1/P2/P3; entrambi i finding
  RR3 chiusi; scanner 32/32 + 2/2 e 21/21 probe `PASS`
- Ripresa Prelude 2026-08-01: callback warm iOS `PASS` sullo SHA `0676826`;
  Supabase Auth config ancora `BLOCKED` dopo Dashboard login richiesto e API 401
- CI: `PASS` sullo SHA `67adf5d`; run `30708934520`, 3/3 job e zero annotation
- Re-review 6: `APPROVED` sullo SHA `671494f`; allow-list staging e OAuth/session
  lifecycle live Android/iOS `PASS`, 0 P0/P1/P2/P3
- CI corrente: `PASS`; run `30709395137`, 3/3 job, annotation 0/0/0
- PR/merge: draft PR #4 sullo SHA `671494f`, `MERGEABLE/CLEAN`; merge e sync
  post-merge ancora `NOT_RUN`
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

- Nessuno. Il rischio quota FREE staging resta da monitorare senza upgrade/billing.
- Il merge e la verifica post-merge non sono blocker esterni: sono il closeout
  autorizzato successivo e restano `NOT_RUN` finché non eseguiti.

Le evidence finali dovranno contenere esattamente una riga per ciascuno dei 40 CA e
38 test, con soli esiti `PASS`, `FAIL`, `BLOCKED` o `NOT_RUN`. Non sono ammessi URL,
key, project ref completi, OAuth code, token, session object, account Google, email,
PII, password, secret, callback con query/fragment o screenshot non redatti.
