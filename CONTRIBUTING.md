# Contribuire

Il progetto usa una governance task-based con un solo task attivo.

## Flusso

1. `CODEX_PLANNER` prepara il planning e attende l'autorizzazione dell'utente.
2. `CODEX_EXECUTOR` implementa su un branch `task/NNN-descrizione`.
3. L'Execution produce evidence e passa a `CODEX_REVIEWER`.
4. La review indipendente decide `APPROVED`, `CHANGES_REQUIRED`, `REJECTED` o `BLOCKED`.
5. `CODEX_FIXER` corregge i finding autorizzati e torna sempre a
   `CODEX_RE_REVIEWER`.
6. Soltanto `USER_APPROVER` può autorizzare `DONE`, merge e task successivo.

Non avviare un secondo task mentre il primo è `ACTIVE`.

## Commit e Pull Request

- Commit atomici, descrittivi e limitati allo scope.
- Nessun force push o auto-merge.
- La PR punta a `main` e include check, evidence, rischi e non incluso.
- Nessun merge prima della review.

## Quality gate

Eseguire `scripts/check.sh` e documentare ogni risultato. Un comando non eseguito è
`NOT_RUN`, non `PASS`. Consultare `docs/QUALITY-GATES.md` e
`docs/CODEX-WORKFLOW-PROTOCOL.md`.

## Evidence e secret

Le evidenze concise vivono in `docs/TASKS/EVIDENCE/TASK-NNN/`. Non inserire log enormi,
path personali non necessari, dati cliente, token, password o configurazioni production.
