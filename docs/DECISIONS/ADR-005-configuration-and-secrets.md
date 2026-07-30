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

## Addendum TASK-004 — 2026-07-30

La decisione originaria resta valida ed è resa normativa dal contratto
[`CMC-CLIENT-CONFIG 1.0.0`](../ARCHITECTURE/ENVIRONMENT-STRATEGY.md). Gli input
compile-time sono esattamente:

- `APP_ENV`;
- `SUPABASE_URL`;
- `SUPABASE_PUBLISHABLE_KEY`;
- `AUTH_REDIRECT_URI`;
- `GOOGLE_AUTH_ENABLED`.

`AppConfig` è l'unica authority di parsing e validazione. Development rifiuta backend,
callback e Google OAuth attivo e non inizializza Supabase. Staging richiede tuple
URL/key, callback canonica e flag Google esplicito; `false` è un kill switch, non un
fallback. Production richiede configurazione completa, non eredita valori staging e in
questo milestone accetta soltanto Google disabilitato.

La callback client è fissata a
`com.xniw.clientmerchandisecontrol://auth-callback/`. Questa decisione non configura la
allow-list remota, non registra deep link Android/iOS e non implementa OAuth: sono
responsabilità di TASK-020. Connessione e readiness staging restano TASK-011.

Publishable key e legacy `anon` sono le sole classi di key ammesse nel client; secret
key, `service_role` e credenziali provider sono vietati. Anche i valori pubblici reali
restano fuori da file versionati, log ed evidence per separazione degli ambienti. I file
locali usano il suffisso `.local.json`, sono ignorati e non partecipano alla CI.

Non vengono introdotti `.env`, fallback, letture runtime del filesystem o flag ulteriori.
