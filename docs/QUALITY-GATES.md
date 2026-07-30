# Quality gate

## Gate locali obbligatori

| Gate | Comando |
|---|---|
| Dipendenze | `flutter pub get` |
| Localizzazioni | `flutter gen-l10n` |
| Formattazione | `dart format --output=none --set-exit-if-changed .` |
| Analisi | `flutter analyze` |
| Test | `flutter test --coverage` |
| Android | `flutter build apk --debug` |
| iOS Simulator | `flutter build ios --simulator --debug` |
| Script | `bash -n scripts/doctor.sh scripts/check.sh` |
| Gate aggregato | `bash scripts/check.sh` |
| Git | `git diff --check` |

`scripts/check.sh` esegue la sequenza completa con `set -euo pipefail`. Tipi, esiti e
requisiti di evidence sono definiti in `docs/CODEX-WORKFLOW-PROTOCOL.md`.

## Gate specifici TASK-002

- test brand resolver, token, semantic theme light/dark, contrasto, `copyWith` e `lerp`;
- scan statico di raw color e metriche feature con allowlist motivata;
- resolver e rendering reale di es, it, en e zh-Hans;
- quattro tab, back e persistenza shell;
- viewport 320×568, 568×320, 390×844 e almeno 1024×768, incluso testo 200%;
- Semantics, target minimo e banner debug;
- confronto di package, bundle identifier, target e repository esterni con la baseline.

## Gate specifici TASK-003

### Audit, ref e integrità

- ogni repository e workspace osservato ha path logico sanitizzato, ref/HEAD/branch e
  dirty state iniziali registrati prima di usarne le evidenze;
- i repository Git esterni sono letti con `GIT_OPTIONAL_LOCKS=0`, senza fetch, checkout,
  cleanup, stage o altre scritture;
- fingerprint di stato e contenuto iniziali/finali usano la stessa procedura versionata
  e devono coincidere per ogni fonte; un mismatch è `FAIL`, non una deviazione
  documentale;
- workspace Supabase storico, repository Admin e progetto non-production canonico sono
  distinti; project ref, URL, key e dati reali restano redatti;
- ogni claim architetturale cita una ref fissa e una fonte tracciabile; file dirty,
  artifact locali e stato remoto sono provenance, non contract authority.

### Ownership e contratto

- la matrice cross-repo assegna per ogni dominio un solo decision owner, writer,
  projector, consumer, contract owner e change owner, oltre alle non-responsabilità;
- Admin è authority di migration, RLS, grant, RPC, future Edge Functions e contratto
  server machine-readable; Client possiede contratto logico, adapter e test consumer;
- il contratto Storefront usa termini normativi, contract ID/versione, error policy,
  allowlist/denylist e compatibility protocol per cambi additive, deprecation e
  breaking;
- ogni risorsa è shop-scoped; `shop_id` ricevuto dal client è input non fidato e non
  sostituisce la risoluzione server-side;
- catalogo pubblico, prezzi, promozioni, disponibilità e immagini pubblicate restano
  separati da inventory, costi, stock operativo, management API, signed URL interni e
  superfici POS;
- prezzo e disponibilità sono server-authoritative e rivalidabili; ordine cliente e
  vendita fiscale POS restano entità ed eventi distinti;
- il protocollo repo-first richiede source revisionata, conformance test, apply
  allowlisted e riconciliazione di qualunque drift remoto prima di ulteriori change.

### Auth e security boundary

- la capability matrix distingue guest, customer, staff e server senza ereditarietà
  implicita;
- publishable key, identità di sessione e autorizzazione sono verifiche distinte;
- UI, route, cache, email, `shop_id` e `user_metadata` non sono fonti di autorizzazione;
- grant Data API e RLS sono entrambi verificati: la presenza dell'uno non implica
  l'altro;
- view, RPC e future Edge Functions falliscono in modo chiuso e non allargano
  implicitamente `anon` o `authenticated`;
- service role, secret key, credenziali DB e token privilegiati non entrano nel Client,
  nelle evidence o nei contratti pubblici.

### DAG e diff confinement

- il parser roadmap trova esattamente 42 task, zero cicli e reachability coerente per i
  workstream catalogo e autenticazione;
- soltanto le dipendenze autorizzate di TASK-010, TASK-011 e TASK-020 possono cambiare;
  titoli, scope, risultati attesi, numerazione e stati dei task futuri restano invariati;
- durante l'esecuzione di TASK-003, TASK-003 era l'unico task `ACTIVE`; il parallelismo
  del grafo non autorizzava execution concorrenti o più writer;
- il diff è limitato ai documenti, ADR, evidence e governance elencati nel task:
  `lib/`, `test/`, `integration_test/`, `config/`, `pubspec*`, target nativi e backend
  devono restare invariati;
- `git diff --check`, link scan, governance check, scansione secret/URL/config locale,
  parser DAG e `bash scripts/check.sh` devono avere comando, output pertinente ed exit
  code registrati.

## Gate specifici TASK-004

### Contratto e matrice

- `CMC-CLIENT-CONFIG 1.0.0` dichiara esattamente `APP_ENV`, `SUPABASE_URL`,
  `SUPABASE_PUBLISHABLE_KEY`, `AUTH_REDIRECT_URI` e `GOOGLE_AUTH_ENABLED`, senza altri
  input compile-time;
- `APP_ENV` ammette soltanto development, staging e production; l'omissione seleziona
  development, ma non introduce fallback tra ambienti;
- development vuoto è valido e non chiama l'inizializzatore Supabase; URL, key,
  callback o Google attivo devono fallire prima del bootstrap remoto;
- staging richiede tuple URL/key, callback canonica e flag Google esplicito; `false`
  resta un kill switch valido;
- production richiede gli stessi input completi, accetta soltanto Google `false` in
  questo milestone e non usa valori staging;
- URL/key sono atomici, l'URL è una origin HTTPS e soltanto publishable key moderne o
  legacy `anon` sono accettate;
- la sola callback valida è
  `com.xniw.clientmerchandisecontrol://auth-callback/`, inclusi scheme, host, path e
  slash finale esatti, senza wildcard, user info, porta, query o fragment;
- il parser Google accetta soltanto i literal lowercase `true` e `false`; l'assenza è
  ammessa soltanto in development e vale `false`;
- diagnostica, `toString` ed errori espongono soltanto ambiente e booleani, mai URL, key,
  callback o input rifiutati.

Il gate unitario mirato è:

`flutter test test/core/config/app_config_test.dart test/core/backend/supabase_bootstrap_test.dart`

### Esempi e configurazione locale

- i due example JSON contengono esattamente le cinque chiavi contrattuali, sono JSON
  validi e non contengono URL/key reali;
- l'esempio development è offline; l'esempio staging usa la callback canonica e
  placeholder non operativi;
- `config/app_config.staging.local.json` esiste localmente, è coperto da
  `/config/*.local.json` e non compare in `git ls-files`, diff o evidence;
- README contiene i comandi run, APK debug e iOS Simulator con
  `--dart-define-from-file=config/app_config.staging.local.json`;
- nessuna configurazione production o valore remoto reale è versionato.

La verifica del file locale controlla soltanto esistenza, ignore e tracking; non ne
stampa o persiste il contenuto.

### Confinamento e security

- nessun nuovo package, flag, `.env`, logger, health probe, query, OAuth, session
  lifecycle, deep link nativo, `shop_id`, schema o dato commerciale;
- manifest Android, plist iOS, dipendenze e repository esterni restano invariati;
- Supabase e gli altri sistemi osservati restano zero-write;
- secret key, `service_role`, credenziali provider, token, URL production, config
  locali, artifact e valori staging reali sono assenti da Git, output ed evidence;
- la validità della configurazione non viene dichiarata come readiness, OAuth
  funzionante o autorizzazione;
- `git diff --check`, test mirati, `bash scripts/check.sh`, build e smoke development
  dual-platform devono avere output pertinente ed exit code reali.

## Gate runtime

I task che modificano UI o bootstrap richiedono avvio reale su Android Emulator e iOS
Simulator, navigazione e screenshot sanitizzati. Build e smoke sono gate distinti. Per
TASK-002 lo smoke include quattro tab, back, light/dark, portrait/landscape, testo
ingrandito e controllo dei log. TASK-003 è documentale: non richiede nuovi smoke quando
il diff confinement conferma zero modifiche runtime; il gate aggregato continua però a
verificare test e build della baseline.

Per TASK-004 lo smoke usa development senza define su entrambi i simulatori, verifica
avvio e interazione con la shell offline, banner tecnico debug e assenza di
inizializzazione Supabase. Non effettua login, connessione staging o test live remoti.

## Gate security

Nessun secret, configurazione locale, dato cliente, provisioning profile, certificato,
URL production o artifact di build può essere versionato. Il diff deve inoltre confermare
che TASK-002 non introduce networking o dati commerciali finti.

Per TASK-003 la scansione copre anche project ref/URL completi, token, service role,
credenziali DB, dump, file `.env*`, config locale, log e artifact cross-repo. Le evidence
possono registrare presenza, classe del target, digest e ref abbreviata; non il valore
sensibile. Le superfici operative osservate non diventano per questo API Storefront
autorizzate.

Per TASK-004 la scansione copre inoltre i cinque input contrattuali, callback inattese,
chiavi moderne/legacy privilegiate, configurazioni production e file
`config/*.local.json`. La publishable key non è un secret, ma il valore staging reale
resta fuori da Git, log ed evidence; la scansione deve registrare soltanto esito e classe
del controllo.

## Gate CI

La PR deve avviare quality, Android build e iOS Simulator build sullo SHA revisionato.
Vanno ispezionati job, step, annotation e commit associato. Un job pending non è `PASS`;
quota o policy esterna è `BLOCKED`, con causa `CI_EXTERNAL`, tentativo e prerequisito di
sblocco documentati.

## Integrità del gate

Gli unici esiti ammessi sono `PASS`, `FAIL`, `NOT_RUN` e `BLOCKED`. Ogni comando ancora
attivo deve terminare prima dell'handoff. In `EXECUTION`, un gate obbligatorio `FAIL`,
`NOT_RUN` o `BLOCKED` impedisce la consegna a Review; dopo `FIX` il task torna comunque
a Review e il gate non superato determina l'esito del re-reviewer.
