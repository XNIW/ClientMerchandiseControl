# TASK-018 — Preferiti, condivisione e deep link prodotto

## Informazioni generali

- **Task ID**: TASK-018
- **Titolo**: Preferiti, condivisione e deep link prodotto
- **File task**: `docs/TASKS/TASK-018-favorites-sharing-product-deep-links.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-02
- **Ultimo aggiornamento**: 2026-08-02
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-018/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

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
| D-06 | `share_plus 12.0.2` è il candidato iniziale | BSD-3, maturo, Android/iOS e API `SharePlus`; evita il major 13 appena pubblicato | ATTIVA |
| D-07 | Il source nativo `app_links` resta unico e broadcast | Evita callback concorrenti; ogni consumer valida il proprio namespace | ATTIVA |

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

In avvio.

## Checkpoint release train — `CODEX_EXECUTOR`

Da compilare dopo i gate TASK-018. Nessuna review formale intermedia.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.
