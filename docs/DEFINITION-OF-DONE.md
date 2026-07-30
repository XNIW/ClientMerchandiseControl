# Definition of Done

Un task è tecnicamente pronto alla chiusura quando:

- scope e criteri sono soddisfatti;
- ogni CA e test case ha evidence;
- quality gate richiesti sono `PASS`;
- rischi e limiti sono documentati;
- tracking, worklog e handoff sono coerenti;
- il worktree è pulito e la PR è revisionabile;
- la review è `APPROVED`.

Il passaggio a `DONE` richiede inoltre conferma esplicita di `USER_APPROVER`.
Nessun ruolo Codex imposta autonomamente `DONE`, esegue merge o attiva il task
successivo.

Per TASK-001 il ciclo di review si è concluso con:

- Stato review: `ACTIVE`;
- Fase: `REVIEW`;
- Review outcome: `APPROVED`;
- Handoff: `CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION`;
- Conferma utente: ricevuta il 2026-07-30 tramite prompt end-to-end;
- Stato dopo conferma: `DONE`;
- Handoff dopo conferma: `USER_APPROVED_DONE`;
- Merge: completato con PR #1 dopo CI verde sul commit di closeout.
