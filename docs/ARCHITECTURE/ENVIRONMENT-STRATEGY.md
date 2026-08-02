# Environment strategy e configuration contract

## Metadati

| Voce | Valore |
|---|---|
| Contract ID | `CMC-CLIENT-CONFIG` |
| Versione | `1.1.0` |
| Stato | baseline normativa di configurazione client |
| Task di origine | TASK-004; estensione autorizzata TASK-013 |
| Contract owner | repository `ClientMerchandiseControl` |
| Consumer | bootstrap Flutter Android/iOS |

Questo documento governa esclusivamente la selezione dell'ambiente e la validazione
locale della configurazione compile-time. Non attesta connessione, salute o disponibilità
del backend e non implementa OAuth, callback handling o deep link nativi.

I termini **MUST**, **MUST NOT**, **SHOULD** e **MAY** indicano rispettivamente requisito
obbligatorio, divieto, raccomandazione e possibilità. Tutto ciò che non è esplicitamente
ammesso fallisce in modo chiuso.

## Input contrattuali

`CMC-CLIENT-CONFIG 1.1.0` contiene esattamente sei input. Rispetto alla baseline
`1.0.0`, TASK-013 aggiunge il solo contesto tenant pubblico necessario al contratto
Storefront:

| Input | Forma | Regola |
|---|---|---|
| `APP_ENV` | stringa compile-time | se omesso seleziona `development`; se presente accetta, dopo trim e normalizzazione del case, soltanto `development`, `staging` o `production` |
| `SUPABASE_URL` | stringa compile-time | origin HTTPS assoluta, senza credenziali, path applicativo, query o fragment |
| `SUPABASE_PUBLISHABLE_KEY` | stringa compile-time | publishable key moderna; una legacy key con ruolo `anon` è ammessa soltanto per compatibilità |
| `AUTH_REDIRECT_URI` | stringa compile-time | callback mobile canonica e allowlisted dal contratto |
| `GOOGLE_AUTH_ENABLED` | stringa compile-time booleana | dopo trim accetta soltanto i literal lowercase `true` o `false`; un valore assente è ammesso soltanto in development e vale `false` |
| `STOREFRONT_SHOP_SLUG` | stringa compile-time | slug pubblico lowercase di 3–63 caratteri (`a-z`, `0-9`, `-`), assente in development e obbligatorio in staging/production |

Non fanno parte del contratto project ref, `shop_id` UUID, Google client ID/secret, account di
test, timeout, log level, endpoint health o altri flag. L'aggiunta di un input richiede
una nuova versione del contratto e un task autorizzato.

Gli input vengono forniti tramite `--dart-define` o `--dart-define-from-file` e hanno una
sola authority in `AppConfig`. File `.env`, letture runtime del filesystem, default
remoti e fallback tra ambienti sono vietati.

## Matrice normativa degli ambienti

| Dimensione | Development | Staging | Production |
|---|---|---|---|
| Selezione | default quando `APP_ENV` è omesso, oppure valore esplicito | `APP_ENV=staging` esplicito | `APP_ENV=production` esplicito |
| URL e publishable key | assenti; qualunque valore è errore | entrambi obbligatori e validi | entrambi obbligatori e validi |
| Callback | assente; qualunque valore è errore | callback canonica obbligatoria | callback canonica obbligatoria |
| Google flag | assente o `false`; `true` è errore | `true` o `false` esplicito | soltanto `false` esplicito |
| Storefront shop slug | assente; qualunque valore è errore | obbligatorio, pubblico e validato | obbligatorio, senza derivazione da staging |
| Backend | nessuna inizializzazione Supabase e nessuna richiesta | SDK più health Auth data-free TASK-011 | nessun uso autorizzato in questo milestone |
| OAuth | vietato | il flag dichiara soltanto capability/kill switch; flusso reale resta TASK-020 | vietato in questo milestone |
| Dati | nessun dato commerciale | soltanto dati non-production, quando introdotti dai task proprietari | nessun dato o valore production versionato |
| Diagnostica | banner tecnico soltanto in debug e soli indicatori sanitizzati | soli indicatori sanitizzati | errore fail-closed senza dettagli sensibili |
| Fallback | nessuno | nessuno | nessun fallback a staging |

Una configurazione valida dimostra soltanto conformità a questa matrice. Non dimostra che
un progetto sia raggiungibile, che Auth sia pronto, che la callback sia registrata
remotamente o che l'utente sia autorizzato.

### Development

Development MUST restare offline per costruzione. URL, key, callback e shop slug vuoti,
insieme a Google assente o `false`, producono una configurazione valida senza
inizializzare Supabase. La presenza di un URL, una key, una callback, uno shop slug o
`GOOGLE_AUTH_ENABLED=true`
MUST fallire prima del bootstrap remoto.

Il banner tecnico MAY rendere visibile lo stato development soltanto in build debug.
Non autorizza backend, OAuth, dati fittizi o comportamento diverso in release.

### Staging

Staging MUST avere la tuple URL/key completa, la callback canonica, il flag Google
esplicito e lo shop slug pubblico. `GOOGLE_AUTH_ENABLED=false` è un kill switch valido
e fail-closed: non rende opzionali gli altri input, non seleziona un altro ambiente e
non concede un fallback tenant.

Il profilo target può usare `true` soltanto quando TASK-020 avrà configurato e verificato
allow-list remota, deep link nativi e flusso OAuth. In TASK-004 il file locale mantiene
il kill switch su `false`; TASK-011 inizializza lo SDK con session persistence,
auto-refresh e deep-link detection disabilitati, quindi verifica soltanto Auth health.

### Readiness staging

Una configurazione completa seleziona la possibilità di eseguire il check, non lo stato
`ready`. TASK-011 definisce:

- un solo `GET` ufficiale a `/auth/v1/health`;
- header `apikey` con la publishable key già validata;
- redirect disabilitati, timeout con abort reale e cancellazione lifecycle;
- retry esclusivamente manuale e single-flight;
- mapping sanitizzato fra offline, misconfigured e recoverable error;
- zero query, RPC, Storage, schema discovery o lettura dati.

Soltanto HTTP 200 con payload health coerente produce `ready`. Il risultato prova
liveness Auth e compatibilità origin/key, non autorizzazione, sessione, database o
Storefront. 401/403 del health indicano configurazione respinta, non login cliente.

### Production

Production MUST avere tuple URL/key, callback, flag e shop slug espliciti, senza
derivare alcun valore da staging. In questa baseline il solo valore ammesso per
`GOOGLE_AUTH_ENABLED` è `false`; `true` MUST fallire.

Nessuna configurazione production viene creata o versionata da TASK-004. L'assenza di
qualunque input obbligatorio è un errore, mai una richiesta di usare development o
staging.

## Validazione fail-closed

### Tuple backend

`SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY` sono atomici: entrambi presenti oppure
entrambi assenti, dove l'ambiente consente l'assenza. L'URL MUST essere una origin HTTPS
canonica; user info, porte non valide, path diversi da `/`, query e fragment sono
vietati.

Il client preferisce publishable key moderne. Una legacy key è valida soltanto se è un
JWT strutturalmente valido con ruolo `anon`. Secret key, `service_role`, password
database, token amministrativi e credenziali provider MUST essere rifiutati e MUST NOT
entrare nel bundle, nei log, negli screenshot, nelle evidence o in Git.

Una publishable key è recuperabile dal bundle e non è un secret né un'autorizzazione.
Per separazione degli ambienti, i valori reali restano comunque esclusi dai file
versionati e dalle evidence. Grant, RLS e controlli server-side rimangono obbligatori e
separati.

### Callback

L'unica callback accettata è:

`com.xniw.clientmerchandisecontrol://auth-callback/`

La URI MUST essere assoluta e coincidere esattamente, incluso lo slash finale. La sua
struttura è:

- scheme `com.xniw.clientmerchandisecontrol`;
- host `auth-callback`;
- path `/`;
- nessuna user info, porta, query o fragment.

HTTP/HTTPS, wildcard, scheme o host alternativi, path aggiuntivi e redirect arbitrari
MUST essere rifiutati. Questa validazione locale non registra URL scheme Android/iOS,
non gestisce il callback e non modifica la redirect allow-list Supabase: tutte queste
operazioni appartengono a TASK-020.

## Diagnostica e trattamento degli errori

Errori e rappresentazioni testuali MUST descrivere il campo o la regola violata senza
ripetere l'input ricevuto. La diagnostica MAY esporre soltanto:

- ambiente selezionato;
- backend configurato: sì/no;
- callback configurata: sì/no;
- Google Auth abilitata: sì/no.
- Storefront configurato: sì/no.

URL, publishable key, callback raw e shop slug MUST NOT comparire in `toString`,
eccezioni, log, test failure, screenshot o evidence. Nessun logger di valori viene
introdotto da questo contratto.

## File di configurazione

- `config/app_config.example.json` è l'esempio development versionato, contiene
  esattamente i sei input e resta offline.
- `config/app_config.staging.example.json` descrive lo shape staging con placeholder
  non operativi e la callback canonica.
- `config/app_config.staging.local.json` contiene gli eventuali valori staging locali,
  usa il kill switch `false`, è coperto da `/config/*.local.json` e MUST restare
  ignorato e non tracciato.

Il contenuto del file locale non viene stampato, copiato nelle evidence o usato in CI.
CI e smoke development usano configurazione vuota/deterministica; i test live staging
appartengono ai task proprietari.

## Confini con i task successivi

- TASK-011 identifica e verifica la connessione staging e definisce la readiness reale.
- TASK-020 configura la redirect allow-list, registra i deep link nativi, implementa
  Google OAuth e governa il lifecycle di sessione.
- TASK-013 introduce lo shop slug pubblico e il primo consumer RPC Storefront.
- TASK-005 e successivi possiedono schema, grant, RLS, dati e interfacce Storefront.

TASK-004 non effettua probe, query, login, scritture remote o modifiche a Supabase.

## Riferimenti Supabase

- [API keys](https://supabase.com/docs/guides/getting-started/api-keys)
- [Auth health](https://supabase.com/docs/guides/troubleshooting/how-do-i-check-gotrueapi-version-of-a-supabase-project-lQAnOR)
- [Redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls)
- [Native mobile deep linking](https://supabase.com/docs/guides/auth/native-mobile-deep-linking)
