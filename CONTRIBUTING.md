# Contribuire

Il progetto usa una governance task-based con un solo task attivo.

## Flusso

1. Il planner crea il planning e porta il task da `PLANNING` a `EXECUTION`.
2. Codex implementa su un branch `task/NNN-descrizione`.
3. L'Execution produce evidence e passa a `REVIEW`.
4. La review decide `APPROVED`, `CHANGES_REQUIRED` o `REJECTED`.
5. Un fix torna sempre a `REVIEW`.
6. `DONE` richiede review approvata e conferma esplicita dell'utente.

Non avviare un secondo task mentre il primo è `ACTIVE`.

## Commit e Pull Request

- Commit atomici, descrittivi e limitati allo scope.
- Nessun force push o auto-merge.
- La PR punta a `main` e include check, evidence, rischi e non incluso.
- Nessun merge prima della review.

## Quality gate

Eseguire `scripts/check.sh` e documentare ogni risultato. Un comando non eseguito è
`NOT_RUN`, non `PASS`. Consultare `docs/QUALITY-GATES.md` e
`docs/CODEX-EXECUTION-PROTOCOL.md`.

## Evidence e secret

Le evidenze concise vivono in `docs/TASKS/EVIDENCE/TASK-NNN/`. Non inserire log enormi,
path personali non necessari, dati cliente, token, password o configurazioni production.
