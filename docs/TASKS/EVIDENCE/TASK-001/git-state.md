# Git state

- Repository: `XNIW/ClientMerchandiseControl`
- Visibilità: private
- Default branch: `main`
- `main` locale: `4978e03972e327bfa76a923189f10fdbdb237cd7`
- `origin/main`: `4978e03972e327bfa76a923189f10fdbdb237cd7`, invariato
- Seed commit: `4978e03` — `chore: initialize ClientMerchandiseControl repository`
- Branch TASK-001: `task/001-bootstrap-foundation`
- Tracking branch: `origin/task/001-bootstrap-foundation`
- Commit fondazione: `6a9c0b6` — app, governance, test ed evidence
- Commit CI: `4a3d502` — aggiornamento checkout per runner Node 24
- Commit handoff execution: `83b8557` — baseline della review indipendente
- Commit governance Codex-only: `4c4b2e3`
- Commit fix post-review: `3f0d992`
- Force push: non eseguito
- Merge/auto-merge: non eseguito
- Pull Request: `#1`, aperta e non draft
- URL: https://github.com/XNIW/ClientMerchandiseControl/pull/1

## Repository esterni

Nessuno dei quattro repository è stato modificato da TASK-001. Il controllo finale
preserva esattamente gli SHA e i dirty state preesistenti:

- Android interno, `<HOME>/Projects/MerchandiseControlSplitView`: HEAD
  `c21de310c0a717f481a79d938888cbb99e8f930c`; resta un log non tracciato preesistente.
- iOS interno, `<HOME>/Desktop/iOSMerchandiseControl`: HEAD
  `c1b7b706c5f05cd7e8dda74cea1122f6483df7ec`; resta modificato lo scheme preesistente.
- Admin Console, `<HOME>/Projects/merchandise-control-admin-web`: HEAD
  `e1783f57509c8011902c1f076d3b1f5ee2e56309`; worktree pulito.
- Win7POS, `<HOME>/Projects/Win7POS`: HEAD
  `81acd479c187469fe0dc31f9b0fb3a162312c1cc`; restano le modifiche e il file non
  tracciato preesistenti.

I commit/ref letti sono elencati in
`docs/REFERENCES/GOVERNANCE-REFERENCE-AUDIT.md`.

## Modifiche locali esterne al repository

- path Flutter presente una sola volta in `$HOME/.zprofile`; `zsh -n` exit `0` e nessun
  secret nel file;
- installazione locale della toolchain Flutter/CocoaPods/Android necessaria ai gate.

Nessun repository esterno è stato scritto.
