# TASK-004 — Environment strategy e configuration contract

## Informazioni generali

- **Task ID**: TASK-004
- **Titolo**: Environment strategy development/staging/production e configuration contract
- **File task**: `docs/TASKS/TASK-004-environment-strategy-configuration-contract.md`
- **Stato**: ACTIVE
- **Fase**: PLANNING
- **Responsabile**: CODEX_PLANNER
- **Data creazione**: 2026-07-30
- **Ultimo aggiornamento**: 2026-07-30
- **Ultimo agente**: CODEX_PLANNER
- **Review outcome**: NOT_RUN
- **Reviewer**: non assegnato
- **Approver**: USER_APPROVER
- **Indicatore**: CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION
- **DONE**: NO
- **Merge**: NO — PR batch con TASK-003 dopo review e CI finali
- **User approval**: GRANTED_BY_END_TO_END_PROMPT, da applicare con transizione esplicita
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-004/`
- **Handoff**: CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION

## Dipendenze

- **Dipende da**: TASK-001 e TASK-003 `DONE`; CI finale TASK-003 run `30585880180`
  `PASS` sullo SHA esatto `108b4f214a045dfc8157dd85eb87b9ce58c02d6b`
- **Sblocca**: TASK-005 e TASK-011; fornisce il contratto di configurazione a TASK-020

## Scope

- matrice normativa per `development`, `staging` e `production`;
- contratto versionato `CMC-CLIENT-CONFIG 1.0.0` composto soltanto da
  `APP_ENV`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `AUTH_REDIRECT_URI` e
  `GOOGLE_AUTH_ENABLED`;
- parsing e validazione fail-closed di ambiente, tuple backend, publishable key,
  flag booleano e callback mobile;
- development rigorosamente offline, senza backend né OAuth;
- staging con backend completo, callback esatta e kill switch OAuth esplicito;
- production senza fallback a staging e OAuth production non abilitabile in questo
  milestone;
- diagnostica strutturata e sanitizzata senza URL, key o redirect raw;
- esempi versionati development/staging e file staging locale ignorato;
- comandi README esatti per run e build da configurazione locale;
- test unitari, bootstrap offline, security scan, build e smoke development
  Android/iOS;
- documentazione architetturale e aggiornamento di ADR-005;
- review indipendente, eventuale Fix, re-review, CI e closeout separati da TASK-003.

## Contesto

La foundation corrente accetta URL e key anche in development e il bootstrap inizializza
Supabase quando la coppia è presente. Questo non garantisce il requisito development
offline. Inoltre il runtime non conosce callback OAuth né kill switch Google e gli esempi
contengono soltanto tre input.

L'audit read-only ha identificato un solo progetto non-production canonico, attivo e
collegato all'ecosistema. Il provider Google risulta configurato, ma la callback mobile
vincolante non è presente nella redirect allow-list. TASK-004 definisce e implementa il
contratto locale senza modificare il progetto remoto: la connessione/readiness appartiene
a TASK-011 e la modifica della allow-list, il deep link e OAuth reale appartengono a
TASK-020.

## Non incluso

- probe di rete, health check, retry, offline detection o `BackendReadinessState`;
- login Google, PKCE, session lifecycle, secure storage, logout o refresh token;
- configurazione Android/iOS del deep link o callback handling;
- modifica di redirect allow-list, provider Auth, progetto, branch, schema, dati,
  Storage, Edge Functions o altri sistemi Supabase;
- query a Storefront, inventory o qualsiasi tabella;
- `shop_id`, discovery/binding shop, catalogo, fixture o dati commerciali;
- URL, key, project ref completi, client ID, client secret, token o credenziali in Git,
  output, log o evidence;
- configurazione o OAuth production;
- nuovi package, dipendenze o flag oltre i cinque input contrattuali;
- modifica di scope, stato o priorità dei task futuri.

## File coinvolti

- `lib/core/config/app_config.dart`;
- `lib/core/config/app_environment.dart` soltanto se richiesto dal parsing;
- `lib/core/backend/supabase_bootstrap.dart`;
- `test/core/config/app_config_test.dart`;
- `test/core/backend/supabase_bootstrap_test.dart`;
- `config/app_config.example.json`;
- `config/app_config.staging.example.json`;
- `config/app_config.staging.local.json` esclusivamente locale e ignorato;
- `docs/ARCHITECTURE/ENVIRONMENT-STRATEGY.md`;
- `docs/ARCHITECTURE/MOBILE-ARCHITECTURE.md` per il solo confine configurazione;
- `docs/DECISIONS/ADR-005-configuration-and-secrets.md`;
- `docs/QUALITY-GATES.md`, `README.md`, `docs/MASTER-PLAN.md`,
  `docs/AI_WORKLOG.md`;
- questo task e `docs/TASKS/EVIDENCE/TASK-004/`.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | TASK-003 è `DONE` e la CI finale sul suo SHA esatto è `PASS` prima dell'attivazione | GIT/CI |
| CA-02 | TASK-004 è l'unico task `ACTIVE` e Planning/autorizzazione sono tracciati separatamente | STATIC/GIT |
| CA-03 | Una matrice normativa distingue development, staging e production senza fallback impliciti | STATIC |
| CA-04 | `CMC-CLIENT-CONFIG 1.0.0` contiene esattamente i cinque input autorizzati | STATIC/UNIT |
| CA-05 | `APP_ENV` accetta soltanto development, staging e production con parsing esplicito | UNIT |
| CA-06 | Development vuoto è valido e non inizializza rete, backend o OAuth | UNIT/ANDROID_EMU/IOS_SIM |
| CA-07 | Development rifiuta URL, key, callback o Google OAuth abilitato | UNIT/SECURITY |
| CA-08 | Staging richiede tuple backend completa, callback e flag Google esplicito | UNIT |
| CA-09 | `GOOGLE_AUTH_ENABLED=false` è un kill switch valido in staging e non un fallback | UNIT/STATIC |
| CA-10 | Production richiede configurazione completa, vieta OAuth production in questo milestone e non usa staging | UNIT/SECURITY |
| CA-11 | URL e key sono una tuple; l'URL è origin HTTPS e la key è publishable/anon, mai privilegiata | UNIT/SECURITY |
| CA-12 | Chiavi secret/service-role e valori malformati sono rifiutati senza essere ripetuti negli errori | UNIT/SECURITY |
| CA-13 | La sola callback accettata è `com.xniw.clientmerchandisecontrol://auth-callback/`, assoluta e senza wildcard/query/fragment | UNIT/SECURITY |
| CA-14 | Errori, `toString`, diagnostica e test non espongono URL, key o redirect raw | UNIT/SECURITY |
| CA-15 | La diagnostica espone soltanto ambiente e booleani di presenza/abilitazione | UNIT/STATIC |
| CA-16 | L'esempio development contiene esattamente cinque chiavi e resta offline/fail-safe | STATIC/UNIT |
| CA-17 | L'esempio staging contiene esattamente cinque chiavi, callback esatta e placeholder non operativi | STATIC/UNIT |
| CA-18 | Il file staging locale esiste, è ignorato/non tracciato e i suoi valori reali non entrano nelle evidence | GIT/SECURITY |
| CA-19 | README documenta i comandi esatti run, APK debug e iOS Simulator con il file staging locale | STATIC |
| CA-20 | Il banner tecnico development resta visibile soltanto in debug | WIDGET/STATIC |
| CA-21 | TASK-004 non introduce readiness, networking applicativo, OAuth, deep link nativo, shop o query dati | GIT/STATIC |
| CA-22 | Git non contiene config locale, URL/key reali, secret, dati reali o configurazione production | SECURITY/GIT |
| CA-23 | Il diff è confinato ai file approvati e i sistemi/repository esterni restano zero-write | GIT/SECURITY |
| CA-24 | I test mirati coprono matrice, callback, flag, sanitizzazione e bootstrap development | UNIT |
| CA-25 | Format, analyze, suite completa e build Android/iOS sono `PASS` con exit code reali | FORMAT/ANALYZE/UNIT/BUILD_ANDROID/BUILD_IOS |
| CA-26 | Smoke development reale su Android Emulator e iOS Simulator conferma avvio offline | ANDROID_EMU/IOS_SIM |
| CA-27 | Review indipendente termina senza finding P0, P1 o P2 aperti | MANUAL/STATIC |
| CA-28 | CI sullo SHA finale completa job, step e annotation con esito `PASS` | CI |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-02 | GIT/CI/STATIC | Verificare closeout TASK-003, task unico e governance |
| T-02 | CA-03, CA-04 | STATIC/UNIT | Verificare matrice e allowlist esatta dei cinque input |
| T-03 | CA-05, CA-06 | UNIT | Costruire development vuoto e verificare stato offline |
| T-04 | CA-07 | UNIT | Provare separatamente URL, key, callback e Google true in development |
| T-05 | CA-08, CA-13 | UNIT | Costruire staging completo con callback esatta e Google true |
| T-06 | CA-09 | UNIT | Costruire staging completo con Google false |
| T-07 | CA-08 | UNIT | Omettere uno alla volta URL, key, callback e flag staging |
| T-08 | CA-10 | UNIT | Provare production incompleto, Google true e assenza di fallback |
| T-09 | CA-05 | UNIT | Provare case/whitespace ammessi e valori ambiente sconosciuti/vuoti |
| T-10 | CA-11 | UNIT | Provare tuple parziale e matrice URL HTTPS origin |
| T-11 | CA-11, CA-12 | UNIT/SECURITY | Provare publishable moderna, anon legacy e chiavi privilegiate/malformate |
| T-12 | CA-13 | UNIT | Accettare soltanto la callback esatta |
| T-13 | CA-13 | UNIT/SECURITY | Provare scheme/host/path/slash/HTTP/query/fragment/user-info/port/wildcard invalidi |
| T-14 | CA-08, CA-09, CA-10 | UNIT | Provare flag `true`/`false`, assente, vuoto, case e valore invalido |
| T-15 | CA-14, CA-15 | UNIT/SECURITY | Ispezionare diagnostica e rappresentazioni sanitizzate |
| T-16 | CA-12, CA-14 | UNIT/SECURITY | Verificare che errori non contengano i valori rifiutati |
| T-17 | CA-16, CA-17 | STATIC/UNIT | Parsare gli esempi e verificare chiavi, callback e placeholder fail-closed |
| T-18 | CA-18 | GIT/SECURITY | Verificare esistenza locale, `git check-ignore` e assenza da index/diff |
| T-19 | CA-19 | STATIC | Verificare letteralmente i tre comandi README |
| T-20 | CA-20 | WIDGET/STATIC | Eseguire i test del banner e controllare il guard `kDebugMode` |
| T-21 | CA-06, CA-26 | ANDROID_EMU | Avviare development senza define e interagire con la shell offline |
| T-22 | CA-06, CA-26 | IOS_SIM | Avviare development senza define e interagire con la shell offline |
| T-23 | CA-21, CA-23 | GIT/STATIC | Applicare allowlist diff e scan simboli fuori scope |
| T-24 | CA-12, CA-14, CA-18, CA-22, CA-23 | SECURITY/GIT | Eseguire scan secret/config/prod/artifact e attestare zero-write esterno |
| T-25 | CA-24, CA-25 | FORMAT/ANALYZE/UNIT/BUILD_ANDROID/BUILD_IOS | Eseguire test mirati e `bash scripts/check.sh` |
| T-26 | CA-27 | MANUAL/STATIC | Review indipendenti su config, security e governance/evidence |
| T-27 | CA-28 | CI | Ispezionare SHA, job, step e annotation del run finale |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Il prompt end-to-end preautorizza il ciclo completo, ma ogni cambio fase resta una transizione esplicita. | Preservare il protocollo e l'autorità utente | ATTIVA |
| D-02 | TASK-004 implementa soltanto il contratto locale; connection/readiness è TASK-011 e OAuth/deep link/allow-list è TASK-020. | Evitare scope creep e falsi claim di connettività | ATTIVA |
| D-03 | Development rifiuta qualsiasi backend, callback e OAuth reale. | Garantire offline e nessuna rete per costruzione | ATTIVA |
| D-04 | `GOOGLE_AUTH_ENABLED=false` è un kill switch staging valido, mai un fallback ad altro ambiente. | Consentire configurazione locale fail-closed finché manca la callback remota | ATTIVA |
| D-05 | `CMC-CLIENT-CONFIG 1.0.0` ha esattamente cinque input compile-time. | Evitare duplicazioni e proliferazione di flag | ATTIVA |
| D-06 | Callback client unica ed esatta; registrazione nativa e allow-list remota restano TASK-020. | Separare validazione locale da integrazione OAuth | ATTIVA |
| D-07 | Il file staging locale può contenere valori reali ma è ignorato; esempi ed evidence non li contengono. | Separazione ambiente e igiene credenziali | ATTIVA |
| D-08 | Provider Google e redirect sono stati osservati read-only; nessuna mutazione remota avviene in TASK-004. | Il prompt assegna la mutazione a TASK-020 | ATTIVA |
| D-09 | ADR-005 viene emendato, non sostituito da un ADR concorrente. | Mantenere una sola decisione per config/secrets | ATTIVA |
| D-10 | TASK-003 e TASK-004 condividono branch e PR batch, ma hanno commit, evidence e review separati. | Preservare un solo task attivo e tracciabilità | ATTIVA |
| D-11 | Production richiede tuple, callback e flag esplicito `false`; `true` è rifiutato in questo milestone. | Nessun OAuth production autorizzato e nessun fallback staging | ATTIVA |
| D-12 | Il file locale staging usa la callback esatta e il kill switch `false` finché la allow-list non viene aggiornata in TASK-020. | Fail-closed rispetto allo stato remoto osservato | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Rendere impossibile l'uso accidentale di backend/OAuth in development e di staging come
fallback production, definendo un contratto compile-time minimo, validato, sanitizzato
e pronto per la connessione di TASK-011 e l'autenticazione di TASK-020.

### Analisi

- TASK-003 è `DONE` e il run terminale sul suo closeout è `PASS`.
- `AppConfig` gestisce oggi tre input, tuple URL/key e validazione publishable, ma
  permette backend configurato in development.
- `SupabaseBootstrap` evita la rete soltanto quando la tuple è assente.
- Non esistono callback, kill switch Google o diagnostica contrattuale.
- `.gitignore` contiene già `/config/*.local.json`.
- Lo staging canonico è attivo e il provider Google è configurato; la callback mobile
  richiesta è assente dalla allow-list.
- L'audit non ha modificato Supabase, repository esterni o dati.

### Approccio

1. Documentare matrice e contratto `CMC-CLIENT-CONFIG 1.0.0`.
2. Estendere `AppConfig` con callback e flag strict, preservando la validazione key.
3. Rendere development offline per costruzione e production fail-closed.
4. Esporre soltanto diagnostica sanitizzata.
5. Aggiornare esempi, creare il file locale ignorato con kill switch e documentare i
   comandi esatti.
6. Aggiungere test di matrice, callback, secrecy e bootstrap.
7. Eseguire gate completi e smoke development sui due simulatori.
8. Consegnare a reviewer indipendenti config/security/governance.

### Rischi

- **Rete accidentale in development**: rifiutare la tuple, non affidarsi soltanto
  all'assenza di valori.
- **Staging scambiato per production**: nessun default/fallback e produzione completa
  con OAuth esplicitamente disabilitato.
- **OAuth abilitato prima della allow-list**: file locale con kill switch `false`;
  attivazione e mutazione remota soltanto in TASK-020.
- **Valori reali nei log/evidence**: diagnostica booleana, scan mirato e file ignorato.
- **Esempio apparentemente operativo**: placeholder vuoti fail-closed e istruzioni di
  copia nel file locale.
- **Scope creep verso readiness/deep link**: allowlist file e scan simboli fuori scope.
- **Regressione build**: test mirati, suite completa, build e smoke dual-platform.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION
- **Autorizzazione USER_APPROVER**: già concessa in forma condizionata dal prompt
  end-to-end; deve essere applicata con una transizione esplicita senza cambiare scope

## Execution — `CODEX_EXECUTOR`

Non iniziata. Il planner non registra modifiche o risultati Execution.

## Review — `CODEX_REVIEWER`

Non iniziata. Il reviewer sarà assegnato dopo l'handoff Execution.

## Fix — `CODEX_FIXER`

Non iniziato. Questa sezione sarà usata soltanto per finding approvati.

## Chiusura

Non applicabile in Planning. `DONE`, PR batch e merge richiedono Execution, review
indipendente, zero finding P0/P1/P2, gate terminali e conferma già condizionata.
