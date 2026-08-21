# TASK-048 — Cross-surface staging E2E and release candidate

## Stato

- **Task ID**: TASK-048
- **Titolo**: Cross-surface staging E2E and release candidate
- **File task**: `docs/TASKS/TASK-048-cross-surface-staging-e2e-release-candidate.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Release train**: MOBILE_STOREFRONT_PRODUCT_CONTROL
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-21
- **Ultimo aggiornamento**: 2026-08-21
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-048/`
- **Handoff**: MOBILE_STOREFRONT_INTEGRATED_STAGING_E2E

## Scope

- Validare sul solo staging e con fixture sintetiche E2E-01…E2E-14.
- Confermare propagation e identità unica Admin/Android/iOS → Client.
- Eseguire una review cross-repo bounded e generare soltanto i release candidate
  Android/iOS operativi realmente impattati.
- Non modificare il Client Flutter se i compatibility test confermano il public
  projection corrente; nessuna migration production o store rollout pubblico.

## Gate

- Migration history, pgTAP/RLS e dataset sintetico staging verificati.
- E2E-01…14 con `PASS` o finding tecnico corretto prima del closeout.
- Candidate con version/build, commit e SHA-256 quando appropriato.
- Un solo task Client ACTIVE; TASK-049 resta TODO fino al completamento reale.
