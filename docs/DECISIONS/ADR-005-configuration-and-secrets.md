# ADR-005 — Configurazione e secret

- Stato: ACCETTATA
- Data: 2026-07-29
- Task: TASK-001

## Decisione

Usare `String.fromEnvironment` con `APP_ENV`, `SUPABASE_URL` e
`SUPABASE_PUBLISHABLE_KEY`, passati tramite `--dart-define` o
`--dart-define-from-file`.

## Conseguenze

Development può avviarsi offline senza credenziali. Production fallisce esplicitamente se
incompleta. Nessun `.env`, service role o fallback a backend casuali.
