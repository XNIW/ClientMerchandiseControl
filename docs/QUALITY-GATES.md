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

- la matrice cross-repo assegna per ogni dominio un domain owner accountable e un
  decision owner business non ambigui; elenca separatamente i writer, projector e
  consumer autorizzati e rende esplicito ogni split per layer di contract/change
  ownership, oltre alle non-responsabilità;
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
  parser DAG, `bash scripts/check-architecture-boundaries.sh`,
  `bash scripts/test-architecture-boundaries.sh` e `bash scripts/check.sh` devono avere
  comando, output pertinente ed exit code registrati.

## Gate specifici TASK-004

### Contratto e matrice

- `CMC-CLIENT-CONFIG 1.0.0` dichiara esattamente `APP_ENV`, `SUPABASE_URL`,
  `SUPABASE_PUBLISHABLE_KEY`, `AUTH_REDIRECT_URI` e `GOOGLE_AUTH_ENABLED`, senza altri
  input compile-time;
- `APP_ENV` ammette soltanto development, staging e production; l'omissione seleziona
  development, ma non introduce fallback tra ambienti;
- development vuoto è valido e non chiama l'inizializzatore Supabase; URL, key,
  callback o Google attivo devono fallire prima del bootstrap remoto;
- staging richiede tuple URL/key, sentinel callback canonico e flag Google esplicito
  `false`; `true` fallisce chiuso finché manca un dominio HTTPS verificato;
- production richiede gli stessi input completi, accetta soltanto Google `false` in
  questo milestone e non usa valori staging;
- URL/key sono atomici, l'URL è una origin HTTPS e soltanto publishable key moderne o
  legacy `anon` sono accettate;
- il solo valore redirect valido è il sentinel non instradabile
  `https://clientmerchandisecontrol.invalid/auth-callback/`, incluso scheme, host,
  path e slash finale esatti, senza wildcard, user info, porta, query o fragment;
- il parser Google accetta soltanto i literal lowercase `true` e `false`; l'assenza è
  ammessa soltanto in development e vale `false`;
- diagnostica, `toString` ed errori espongono soltanto ambiente e booleani, mai URL, key,
  callback o input rifiutati.

Il gate unitario mirato è:

`flutter test test/core/config/app_config_test.dart test/core/backend/supabase_bootstrap_test.dart`

### Esempi e configurazione locale

- i due example JSON contengono esattamente le cinque chiavi contrattuali, sono JSON
  validi e non contengono URL/key reali;
- l'esempio development è offline; l'esempio staging usa il sentinel `.invalid`,
  Google disabilitato e placeholder non operativi;
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

## Gate specifici TASK-011

- `BackendReadinessState` contiene i sette stati richiesti e non deriva `ready` dalla
  sola configurazione o inizializzazione;
- development e production eseguono zero initialize/probe; staging usa soltanto
  `GET /auth/v1/health` con `apikey` e redirect disabilitati;
- timeout completa l'abort trigger reale; dispose e cancel ignorano risultati obsoleti;
- mapping copre 200/payload, 401/403/404, 408/429/5xx, risposta invalida e trasporto;
- check iniziale e retry concorrenti sono single-flight; non esistono polling,
  auto-retry o loop su resume;
- UI customer-safe localizzata copre initializing/offline/misconfigured/auth-required/
  recoverable, retry accessibile e browsing guest non bloccato;
- Android main contiene `INTERNET`; iOS non contiene eccezioni ATS permissive;
- test mirati:
  `flutter test test/core/backend test/features/shell/backend_readiness_banner_test.dart`;
- smoke reale staging Android/iOS tramite
  `integration_test/backend_readiness_smoke_test.dart` e file locale ignorato;
- build staging Android/iOS con `--dart-define-from-file`, separati dagli smoke;
- scan statico conferma zero query/RPC/Storage/inventory, zero valori staging e zero
  session/token nei log.

## Gate specifici TASK-012

- test unit/widget mirati per Home, Catalogo, Carrello, Account e shell, inclusi tutti
  gli stati readiness, CTA, tab persistence, back e port presentazionali;
- parità automatica delle chiavi e dei placeholder ARB per es-CL, it, en e zh-Hans,
  bundle tecnico `app_zh` sincronizzato e fallback es-CL verificato;
- rendering delle quattro destinazioni light/dark e al 200% sui viewport 320×568,
  568×320, 390×844 e 1024×768, con inset SafeArea;
- ispezione di heading, live region, label, icone decorative e assenza di Semantics
  duplicate; ogni target interattivo è almeno 48×48 dp;
- contenuto full-width entro il max-width, scroll-to-end e bounds dimostrano testo e
  CTA completi, raggiungibili e tappabili;
- scan data-safe conferma zero prodotti, prezzi, stock, sconti, immagini o urgenza
  inventati e zero query/RPC/Storage/inventory;
- Account runtime guest, Google fail-closed senza callback, authenticated soltanto
  tramite modello iniettato e logout obbligatorio;
- smoke reale guest Android/iOS tramite `integration_test/app_guest_flow_test.dart`,
  con quattro tab, CTA, back, tema, testo 200%, orientamenti e screenshot sanitizzati;
- build debug Android/iOS e gate aggregato restano distinti dagli smoke.

I test mirati principali sono:

`flutter test test/features test/app/design_system/task012_reflow_accessibility_test.dart test/app/client_merchandise_control_app_test.dart test/l10n`

## Gate specifici TASK-013

- configurazione compile-time con un solo `STOREFRONT_SHOP_SLUG`, obbligatorio in
  staging/production, vietato in development e mai riportato nella diagnostica;
- un solo adapter Supabase autorizzato a invocare `storefront_home_v1`; nessuna query
  diretta a inventory, authoring, Storage o bucket interno;
- decoder DTO strict allow-list per API/schema/status, valori CLP integer non negativi,
  URL HTTPS pubblici versionati e `catalogVersion` uniforme;
- repository con timeout, cancellation token e failure taxonomy deterministica;
- controller Riverpod protetto da risultati stale e Home guest con loading, empty,
  retry, offline/unavailable, categorie, featured, offerte e immagini pubbliche;
- test unit/widget per payload valido e malevolo, failure/cancellation, retry, dark mode,
  text scale 200%, viewport e localizzazioni es/it/en/zh-Hans;
- fixture staging deterministica priva di dati personali, verificata via RPC anonimo e
  con letture interne negate;
- smoke reale Android/iOS tramite
  `integration_test/storefront_home_live_smoke_test.dart`, separato da build e CI;
- `flutter analyze`, suite completa con coverage, build debug Android/iOS, architecture
  boundary, secret scan e CI sullo stesso SHA candidato.

## Gate specifici TASK-014

- l'unico adapter Supabase allowlista `storefront_categories_v1` e
  `storefront_catalog_v1`, oltre al precedente Home, senza query dirette a
  tabelle/view/Storage;
- DTO strict per status, API version, catalog version, cursor opaco, sort, categorie e
  prodotti, con duplicate ID/slug e shape sconosciute rifiutati;
- limit `1..100`, keyset cursor invariato, cancellation/generation guard, single-flight
  e reset bounded su `catalog_changed`;
- griglia Sliver lazy adattiva, categoria server-side, pull-to-refresh, posizione per
  categoria/tab, stato load-more separato e retry esplicito senza loop automatici;
- immagini pubbliche `card` con lazy build, decode width bounded, placeholder/error e
  nessun bucket/path interno;
- unit/widget su pagination, stale response, duplicate page, refresh, error/retry,
  es/it/en/zh-Hans, dark mode, text scale 200% e compact/landscape/large;
- smoke guest reale Android/iOS tramite
  `integration_test/storefront_catalog_live_smoke_test.dart`, build, secret scan e CI
  eseguiti sullo stesso SHA candidato.

## Gate specifici TASK-015

- l'unico adapter Supabase allowlista anche `storefront_search_v1`; nessun altro file
  può invocare RPC, tabelle/view o Storage;
- Search DTO strict su status/API/catalog version/query/relevance/cursor/item e verifica
  che la query restituita coincida con quella richiesta;
- query normalizzata `2..120`, debounce 300 ms, cancellation/generation guard, clear e
  keyset Search senza mescolare pagine o criteri;
- categoria componibile con Search; availability/discounted/sort solo Catalog e
  disabilitati esplicitamente durante Search;
- availability typed, discounted e quattro sort inoltrati server-side con reset prima
  pagina atomico;
- widget su tastiera/search action, clear, filtri, locale, dark mode, text scale 200% e
  compact/landscape; smoke reale Android/iOS sul contratto staging.

## Gate specifici TASK-016

- l'unico adapter Supabase allowlista anche `storefront_product_detail_v1`; UUID
  publication invalido non effettua rete e response ID differente fallisce chiusa;
- DTO strict su status/API/catalog version/item, senza shape extra o dati parziali;
- controller route-scoped auto-dispose con cancellation, stale guard, readiness e retry;
- card Home/Catalog/Search navigano alla stessa route e back ripristina il consumer;
- detail mostra soltanto dati pubblici, variante immagine `detail` bounded, availability
  commerciale e fulfillment senza quantità;
- unit/widget su valid/unavailable/offline/malformed/dispose, sei availability, quattro
  locale, dark, text scale 200% e compact/landscape;
- smoke published/unpublished reale Android/iOS, build, secret scan e CI sullo stesso
  SHA candidato.

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

Per TASK-011 la scansione copre inoltre request health, redirect, timeout/cancellation,
permission Android, opzioni Auth disabilitate, query dati vietate, config locale e
output smoke. La publishable key è inviata soltanto al gateway staging validato e non
deve apparire in log, eccezioni, widget o evidence.

Per TASK-012 la scansione copre inoltre stringhe customer-facing fuori dagli ARB,
colori/metriche funzionali hardcoded, dati commerciali sintetici, query o I/O autonomo,
sessioni/token, URI avatar interpretati dal widget, callback OAuth, nuove dipendenze,
config locale e artifact. La UI authenticated di test non costituisce una sessione e
non può rendere operativo Google prima di TASK-020.

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
