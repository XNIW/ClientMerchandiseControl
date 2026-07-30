# TASK-002 — Recovery backup

Backup non distruttivo creato prima della recovery:

`~/ClientMerchandiseControl-task002-recovery-20260730-142248`

## Baseline

- HEAD iniziale:
  `fd091d18d012d56ecf4e7a38f8a202439acd6204`;
- `origin/main`:
  `f6bd88263fe8369c9ececa38367f629f3d1a929f`;
- worktree tracked iniziale: pulito;
- untracked iniziali: nove screenshot TASK-002, copiati nel backup.

## Contenuto verificato

- bundle completo:
  `ClientMerchandiseControl-task002-recovery-20260730-142248.bundle`;
- patch dell'intero branch rispetto a `origin/main`;
- patch worktree tracked, correttamente vuota perché il worktree tracked era pulito;
- stato Git, HEAD/base e liste file;
- copia dei nove screenshot;
- `SHA256SUMS.txt`.

Digest principali:

- bundle:
  `e2e2551eed36afc8579d600ac66493df7cefa7dceda738a3e19c6c30315d44e1`;
- patch branch:
  `972ed61bb94b67ae900f6515308ef6ef5bec1551beefbcf6ec82aeef1747b6ea`.

`git bundle verify` ha restituito exit `0`, contiene HEAD iniziale e `main`, registra una
history completa e usa SHA-1 come object format Git. Il backup è esterno al repository e
non è stato modificato durante l'Execution.
