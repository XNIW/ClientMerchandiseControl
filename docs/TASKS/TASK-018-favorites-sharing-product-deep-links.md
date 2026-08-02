# TASK-018 — Preferiti, condivisione e deep link prodotto

## Informazioni generali

- **Task ID**: TASK-018
- **Titolo**: Preferiti, condivisione e deep link prodotto
- **File task**: `docs/TASKS/TASK-018-favorites-sharing-product-deep-links.md`
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-02
- **Ultimo aggiornamento**: 2026-08-02
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-018/`
- **Handoff**: CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW

## Dipendenze

- **Dipende da**: TASK-012, TASK-016, TASK-017
- **Checkpoint consumati**: TASK-013..TASK-017
- **Sblocca**: TASK-036

## Scope

- aggiungere preferiti guest persistenti, idempotenti e shop-scoped in Drift;
- mantenere i preferiti locali durante login, restore e logout; nessuna sync remota
  finché il contratto customer non espone una capability esplicita;
- offrire toggle dal dettaglio, lista preferiti, empty/error/offline state e apertura
  della stessa route prodotto pubblica;
- integrare il dialogo di condivisione nativo con testo localizzato e URI Storefront
  tecnico privo di PII, token, prezzo autoritativo o dati interni;
- supportare deep link cold/warm per prodotto e categoria con shop nel link, schema,
  host, path, ID/slug e cardinalità strict;
- riusare l'unico source `app_links` già posseduto dal confine Auth, con validator e
  consumer separati, senza riabilitare il deep linking permissivo Flutter/Supabase;
- gestire link invalido, altro shop, prodotto unpublished, cache offline e cold start;
- verificare Android/iOS, callback OAuth invariata, Semantics, testo 200% e quattro
  locale.

## Non incluso

- backend, RLS o sync multi-device dei preferiti: non esiste ancora una capability
  customer autorizzata;
- dominio HTTPS, Universal Links/App Links verificati o public brand non disponibili:
  appartengono a TASK-038/TASK-041 e non vengono inventati;
- landing di una specifica promozione: il contratto v1 non espone un filtro sicuro per
  promotion ID; i prodotti scontati restano disponibili in Catalogo;
- carrello, profilo, notifiche, write backend o production.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Schema favorite contiene solo shop/publication/timestamp pubblici e migra v1→v2 | UNIT/SECURITY |
| CA-02 | Toggle è idempotente, bounded, persistente e non viene perso da login/logout | UNIT/INTEGRATION |
| CA-03 | Lista e dettaglio gestiscono favorito, empty, orphan/unpublished e offline onestamente | WIDGET |
| CA-04 | Share usa UI nativa, payload localizzato bounded e URI canonico senza PII | UNIT/INTEGRATION |
| CA-05 | Product/category link includono shop e accettano solo forma canonica | UNIT/SECURITY |
| CA-06 | Altro shop, scheme/host/path/query/fragment/ID malformati sono ignorati fail-closed | UNIT/SECURITY |
| CA-07 | Cold/warm link usano un solo source e non interferiscono con OAuth callback | UNIT/INTEGRATION |
| CA-08 | Unpublished mostra unavailable; offline usa solo cache valida o stato offline | INTEGRATION |
| CA-09 | Semantics, focus, 200%, dark e locale es/it/en/zh-Hans restano verdi | WIDGET |
| CA-10 | Gate, CI e smoke deep link Android/iOS sono PASS sullo SHA candidato | CI/BUILD/INTEGRATION |

## Test case

| Test | Criteri | Procedura attesa |
|---|---|---|
| T-01 | CA-01, CA-02 | migration v1→v2, add/remove duplicato, reopen, cap e shop isolation |
| T-02 | CA-02, CA-03 | guest favorite, login/restore/logout, lista offline e orphan nascosto |
| T-03 | CA-04 | share service fake/native, anchor iPad, cancel/failure e payload sanitizzato |
| T-04 | CA-05, CA-06 | matrice URI canonica/malevola prodotto e categoria |
| T-05 | CA-07 | source unico, callback Auth e Storefront cold/warm concorrenti |
| T-06 | CA-08 | prodotto published/unpublished e offline cache hit/miss |
| T-07 | CA-09 | Semantics, focus, dark, 200%, locale e viewport matrix |
| T-08 | CA-10 | gate completo e open-url native Android/iOS cold/warm |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Favorites diventano tabella Drift schema v2 nello store locale pubblico | Riusa transazioni/shop scope senza storage plaintext parallelo | ATTIVA |
| D-02 | Il record favorite conserva solo shop slug, publication UUID e timestamp | Preferenza minima, nessun dato commerciale duplicato o PII | ATTIVA |
| D-03 | Nessuna sync account finché manca il contratto server | Login non crea capacità o grant impliciti | ATTIVA |
| D-04 | URI tecnico: `com.xniw.clientmerchandisecontrol://storefront/{shop}/product/{uuid}` | Include shop, separa host da Auth e non inventa un dominio pubblico | ATTIVA |
| D-05 | Categoria usa lo stesso formato con `/category/{slug}` | Copre discovery senza aggiungere API o filtro promozione inesistente | ATTIVA |
| D-06 | `share_plus 13.2.1` è pin esatto | BSD-3, Android/iOS e API `SharePlus`; evita i downgrade transitive causati da 12.0.2 e non adotta la 13.3 appena pubblicata | ATTIVA |
| D-07 | Il source nativo `app_links` resta unico e broadcast | Evita callback concorrenti; ogni consumer valida il proprio namespace | ATTIVA |
| D-08 | USER_APPROVER: «Il gate manuale di osservazione dell’Activity Sheet è sostituito da un gate automatico nativo più forte e riproducibile. La modifica non riduce la copertura: richiede la presentazione reale di `UIActivityViewController` in un processo Simulator e la verifica del payload, del presentation context e del dismiss.» | Emendamento autorizzato dal prompt di ripresa 2026-08-02; elimina la dipendenza GUI senza ridurre il contratto verificato | ATTIVA |

## Planning — `CODEX_PLANNER`

### Analisi

- TASK-017 fornisce Drift, shop scope, recovery e cache pubblica; lo schema corrente è
  v1 e non contiene preferiti;
- TASK-016 fornisce route/detail e stati published/unpublished/offline;
- TASK-020 possiede già custom scheme, inoltro native cold/warm e un solo source
  `app_links`; il validator Auth accetta esclusivamente host `auth-callback`;
- Android registra oggi soltanto l'intent filter Auth, mentre iOS registra lo scheme e
  delega host/path alla validazione Dart;
- non esiste dominio pubblico verificato né API customer favorite, quindi entrambi
  restano esplicitamente fuori scope.
- il tentativo iniziale con `share_plus 12.0.2` risolveva versioni inferiori di
  `win32` e `flutter_secure_storage_windows`; il pin `13.2.1` conserva le versioni
  preesistenti ed è compatibile con Flutter 3.44.8, Dart 3.12, iOS 13 e Gradle 9.1.

### Approccio autorizzato

1. aggiungere schema v2 favorite, adapter e test migration/isolation/bounds;
2. creare provider/actions e lista favorite, poi toggle accessibile nel detail;
3. integrare share service iniettabile e dialogo nativo con anchor corretto;
4. creare builder/validator URI prodotto/categoria e coordinatore sul source unico;
5. aggiornare intent filter Android e mantenere iOS/Auth fail-closed;
6. aggiungere unit/widget/integration e open-url cold/warm Android/iOS;
7. eseguire gate completo, CI e consegnare al checkpoint solo se tutto è verde.

### Rischi

- collisione OAuth/Storefront: host e validator disgiunti sullo stesso stream;
- cross-shop link: shop obbligatorio e confronto constant-shape col config corrente;
- perdita favorite su catalog invalidation: la tabella non viene cancellata dal
  refresh catalogo; gli orphan non vengono mostrati come prodotti reali;
- share sheet iPad: origine geometrica bounded obbligatoria;
- link pubblico senza app: nessuna promessa di fallback finché manca un dominio
  verificato; store metadata lo renderà esplicito;
- doppio tap/race: toggle transazionale e source event deduplicato.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: prompt release train 2026-08-01

## Execution — `CODEX_EXECUTOR`

### Modifiche completate

- database Drift schema v2 con tabella `storefront_favorites` shop-scoped, migration
  v1→v2, indice di ordinamento, cap 1.000 record e toggle transazionale idempotente;
- preferiti guest persistenti durante reopen/login/logout, lista/empty/error/orphan,
  azioni accessibili e stessa route prodotto pubblica;
- `share_plus 13.2.1` esatto con service iniettabile, anchor iPad bounded e payload
  localizzato composto soltanto da nome pubblico e URI canonico;
- boundary espliciti `ShareRequest`, `ShareResult`, `ProductShareService`,
  `PlatformProductShareService`, `ProductPublicLinkBuilder` e
  `ProductFavoriteRepository`; la UI non invoca direttamente plugin o MethodChannel;
- pulsante Share stateful con Semantics esplicita, target 48 px e guardia single-flight;
  adapter platform con mapping `completed/dismissed/unavailable` e failure sanitizzato;
- codec strict per product/category link, confronto shop e rifiuto di scheme, host,
  userinfo, port, query, fragment, cardinalità o encoding non canonici;
- source `app_links` singleton broadcast condiviso con Auth, consumer separati,
  queue cold fino al router ready e deduplica cold/warm di due secondi;
- intent filter Android Storefront separato da quello Auth; iOS continua a delegare la
  validazione host/path al boundary Dart fail-closed;
- correzione della race reale Catalog bootstrap/deep-link: il load schedulato usa i
  criteri correnti e non sovrascrive più la categoria consegnata warm/cold;
- smoke live staging preferiti e matrice nativa deep link/share su Android e iOS.
- target XCTest Runner non parallelo con vera presentazione di
  `UIActivityViewController` su `UIWindow`/host attivo, payload ispezionabile,
  popover iPad, cancel/completion, doppia presentazione e background/resume.

### Difetti corretti durante Execution

- il primo test URI uppercase usava per errore un UUID privo di lettere; fixture resa
  discriminante senza indebolire il validator;
- placeholder favorite compatto causava overflow e Semantics incompleta a text scale
  200%; layout e label sono ora regressioni widget;
- la queue iniziale GoRouter poteva navigare prima dell'inizializzazione; il consumo è
  post-frame e coperto per cold/warm/deduplica;
- il bootstrap catalogo sovrascriveva la categoria deep-linked; il controller ora
  rilegge i criteri effettivi al momento del load;
- il primo smoke Android usava lo shop harness `storefront-test` invece dello staging
  reale `storefront-v1-staging`; input corretto e rerun cold/warm `PASS`.
- i primi XCTest hanno esposto due difetti del test host: reset dello stato prima del
  dismiss UIKit e clone paralleli in competizione sulla key window; stato/dismiss sono
  stati sincronizzati con polling deterministico e il target UI è ora non parallelo;
- il primo gate completo di questa ripresa si è fermato su un lint
  `unnecessary_string_interpolations` (exit 1 in 34,33 s); il test è stato corretto e
  il gate completo è stato rieseguito dall’inizio con exit 0.

### Gate eseguiti

- revision set tecnico Client
  `a0e139a6365dc4639ba66c110c91dcc2720feee5`, PR `#5` draft;
- suite mirata ripresa 22/22 `PASS`; gate completo `scripts/check.sh` exit 0 in
  79,66 s con 329 test, coverage 4.249/5.199 linee (81,73%), security 415 file,
  fixture security 32/32 negative e 2/2 positive, governance 8/8, architecture 7/7,
  analyze e build Android/iOS `PASS`;
- XCTest nativo `xcodebuild test` su iPad (A16), iOS Simulator 26.5: 3/3 `PASS`,
  0 fail/skip, exit 0; `xcresulttool` conferma presentazione reale, payload, popover,
  cancel/completion, single-flight e background/resume in 13,54 s;
- Android Emulator `emulator-5554`: deep link prodotto staging, tap Share via
  accessibility tree, chooser `ACTION_SEND` `text/plain`, payload esatto, cancel e
  doppio tap 1/1 `PASS`; PID processo invariato `26527` e un solo chooser;
- CI Client `30751191932`: Quality 4m23s, iOS Simulator 3m38s e Android 8m41s,
  3/3 `PASS`, tutti gli step applicabili `success` e annotation 0/0/0 sullo SHA esatto;
- favorite live staging Android 1/1 in 23 s e iOS 1/1 in 6 s: `PASS`;
- Android native: product cold, category warm, share chooser, payload pubblico e
  cross-shop fail-closed `PASS`; iOS native: product cold, category warm e cross-shop
  fail-closed `PASS`;
- scan log live Android/iOS: zero match per access/refresh token, bearer o OAuth code;
- Activity Sheet iOS manuale: `NOT_RUN` per decisione D-08; il gate sostitutivo XCTest
  con vera `UIActivityViewController` è `PASS` e non richiede interazione GUI;
- artifact candidato: build staging APK exit 0 in 8,15 s, SHA-256
  `5bd05d1e4a923ee7a62d8533321d6315513c6dd6754559a58e3aa41efa4be54e`; Runner
  Simulator executable SHA-256
  `3f19e6660670e6d1221c313cd9ba247e7f8c0515d3c42c9322aa81e52803d6f0`;
- production write: `NOT_RUN`; production invariata.

### Matrici e handoff

- CA-01..CA-10 e T-01..T-08: `PASS`;
- handoff: `CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`.

## Checkpoint release train — `CODEX_EXECUTOR`

TASK-018 è `VALIDATED_PENDING_INTEGRATED_REVIEW`: Flutter, Android chooser, XCTest
`UIActivityViewController`, preferiti, deep link, build e CI sono verdi sul revision
set registrato. Production è invariata; nessuna review formale intermedia è stata
eseguita. Il task successivo autorizzato è TASK-019, iniziando dal work package
`STOREFRONT-V1-UI-HARDENING`.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.
