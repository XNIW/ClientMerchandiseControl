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

## Addendum TASK-013 — 2026-08-02

Il contratto passa a
[`CMC-CLIENT-CONFIG 1.1.0`](../ARCHITECTURE/ENVIRONMENT-STRATEGY.md) aggiungendo
esclusivamente `STOREFRONT_SHOP_SLUG`. È uno slug pubblico, non uno `shop_id` interno:
resta assente in development, è obbligatorio in staging/production e non compare nelle
diagnostiche. La sua presenza seleziona il tenant del contratto RPC pubblico ma non
concede autorizzazioni, grant o accesso a tabelle.

## Addendum sicurezza TASK-033 — 2026-08-12

Il contratto passa a
[`CMC-CLIENT-CONFIG 1.2.0`](../ARCHITECTURE/ENVIRONMENT-STRATEGY.md). La precedente
callback privata `com.xniw.clientmerchandisecontrol://auth-callback/` è revocata perché
non offre ownership esclusiva dell'app. In assenza di un dominio HTTPS posseduto e
verificato, `AUTH_REDIRECT_URI` accetta soltanto il sentinel non instradabile
`https://clientmerchandisecontrol.invalid/auth-callback/` e staging/production
rifiutano `GOOGLE_AUTH_ENABLED=true`.

Il sentinel non è una callback deployabile, non è registrato nativamente e non dichiara
ownership del dominio. La riattivazione OAuth richiede una nuova decisione esplicita,
App Links/Universal Links verificati su Android/iOS e allow-list remota esatta. Lo
scheme privato iOS resta ammesso soltanto per i link pubblici bounded di prodotto e
categoria; route customer-sensitive come ordine e notifica falliscono chiuso.

## Addendum release TASK-040 — 2026-08-17

Il contratto passa a
[`CMC-CLIENT-CONFIG 1.3.0`](../ARCHITECTURE/ENVIRONMENT-STRATEGY.md) aggiungendo
`RELEASE_CONFIG_SHA256`, obbligatorio soltanto in production. È il digest non secret
del file esterno completo fornito allo stesso build; l'app lo valida e il gate iOS
richiede il digest nel Mach-O prima di dichiarare upload-ready. Il template versionato
resta intenzionalmente incompleto e non può produrre una app production avviabile.
