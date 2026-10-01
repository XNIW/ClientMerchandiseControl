# Audit funzionale operativo — 2026-09-28

## Metodo e confini dell'evidence

Baseline Client `493c2c9bc73c2788e97d4141a4fe01216dc8a39a`, Admin
`fe4907adc51ff842720e1c7eb36aa05e0fa53cb8`. Gli SHA non sono istruzioni di reset.
L'audit segue sorgenti UI → stato → repository → RPC/tabella → parser → UI e confronta
le dipendenze con metadata remoti letti, schema SQL isolato e suite eseguite.
L'esito dei test è nel [registro verifiche](validation.md); la presenza di codice o di
una firma SQL non dimostra un percorso autenticato nello staging.

Tutti i percorsi `lib/` e `test/` qui sotto sono relativi alla radice Client. Le fixture
sono sintetiche dei test versionati, senza identità, indirizzi, coordinate o ordini reali.
Il backend locale è `cmc_verified` nel container dedicato senza rete né porte pubblicate;
lo staging è `jpgoimipbothfgkokyvm`, interrogato esclusivamente per metadata.

## Baseline multi-repository

Tutti i remote sono `https://github.com/XNIW/<repository>.git`.
Le revisioni remote sono state riconfermate tramite GitHub; non si sono aggiornati i
checkout operativi né cancellate modifiche dell'utente.

| Repository | Branch / HEAD locale all'inizio | origin/main locale / main remoto | Worktree, task e PR |
|---|---|---|---|
| ClientMerchandiseControl | main / `8423c868f345ee87eee7ed58ee9eb793d98412db` | entrambi `493c2c9bc73c2788e97d4141a4fe01216dc8a39a` dopo fetch | originale pulito, 326 commit indietro; TASK-054 riaperto in checkout gestito `codex/client-functional-audit`; nessuna PR iniziale |
| merchandise-control-admin-web | main / `fe4907adc51ff842720e1c7eb36aa05e0fa53cb8` | stesso SHA | pulito; TASK-159 WeChat REVIEW concorrente preservato; nessuna PR aperta |
| MerchandiseControlSplitView | main / `ca0a58d8f63fa6447427c2e06846b4c9198e4be5` | cached `ca0a58d8`; remoto `d7c4953c4ed6bc2a33cc5dbfd009eb862f70feac` | tre file locali modificati, preservati; TASK-142 authoring DONE sul remoto; nessuna PR aperta |
| iOSMerchandiseControl | main / `99aa69c483b6c98c70d20d0fc9311f41240b325b` | cached e remoto `30d226d0fb9b8679a1dd034c6e82319645337f22` | pulito; TASK-143 ACTIVE/REVIEW/APPROVED awaiting integration sul riferimento; nessuna PR aperta |
| Win7POS | `backup/win7pos-dirty-20260722-81acd479` / `81acd479c187469fe0dc31f9b0fb3a162312c1cc` | cached `fea70fa7c52d60f6b3e855efb0c275ad1d1be692`; remoto `bedcf17a97d814a3b098387cc2720ff2b11abbbf` | modifiche utente preservate; Master Plan con lo stesso percorso assente; PR #112 draft performance e #108/#107/#106/#101/#100 dipendenze, fuori scope |

La CI storica Client `32635780234` appartiene esattamente a `493c2c9`: cinque job,
step completati e zero annotation. Non è evidence del nuovo candidato.
La discordanza iOS tra closeout Client e task ancora aperto viene conservata: nessuna
chiusura o integrazione operativa è inferita dalla sola narrativa cross-repository.

## Matrice funzionale

Per ogni riga, `S` indica test statici/deterministici e SQL isolato nel registro;
`L` indica un collaudo autenticato live nuovo. I test S non sostituiscono L.
Le fonti TASK/ADR sono quelle già approvate; nessuna funzionalità di prodotto aggiunta.

| Requisito / fonte | Superficie e percorso concreto | Dipendenza runtime | Stato codice | Stato runtime / test | Priorità / azione |
|---|---|---|---|---|---|
| Home, categorie, catalogo — TASK-013/014 | HomeScreen/CatalogScreen → HomeController/CatalogController → SupabaseStorefrontRepository → `storefront_home_v1`, `storefront_categories_v1`, `storefront_catalog_v1` → DTO pubblico → card | Supabase/proiezioni Admin | implementato, testato deterministicamente | firme presenti; S: suite home/catalog/storefront + SQL; L NOT_RUN | P2: retest con pubblicazione reale sintetica dopo sblocco |
| Ricerca/filtri — TASK-015/052 | CatalogScreen → CatalogController/SearchAssistController → SearchAssistRepository + StorefrontRepository → search/suggestions → stato risultati | catalogo pubblico, RPC suggestions | ricerca implementata; suggerimenti non operativi nello staging | `storefront_search_v1` presente, suggestions assente; S presente; L BLOCKED | P1: applicazione canonica, nessuna sostituzione locale della ricerca server |
| Dettaglio — TASK-016 | ProductDetailScreen → ProductDetailController → StorefrontRepository → `storefront_product_detail_v1` → parser allow-list | catalogo pubblico, immagini/versione | implementato; no campi inventory privati nel modello pubblico | firma presente; unit/widget/SQL; L NOT_RUN | P2: readback di pubblicazione/modifica/ritiro |
| Immagini — TASK-009/037 | card/detail → StorefrontVerifiedImageLoader → HTTP digest verificato → LRU/single-flight → decode bounded | origin pubblico/oggetti pubblicati | implementato; cap 64 entry/24 MiB già esistente | stress/decode/SQL immagini verificati; rete/CDN live NOT_RUN | mantenere cap e test; non presentato come nuovo lavoro |
| Preferiti/condivisione/link — TASK-018 | FavoritesScreen/FavoriteButton → FavoritesController/ProductFavoriteRepository; share → ProductPublicLinkBuilder; router → StorefrontDeepLink | preferiti locali; dominio HTTPS owned per link distribuiti | implementato locale; collegamenti nativi distribuiti parziali | suite favorites/sharing/deep_links; associazioni dominio BLOCKED | P1 release: dominio e file associazione verificati |
| Offline — TASK-017/034 | controller catalogo → DriftStorefrontCacheRepository → SQLite → snapshot readonly e refresh; out-of-order/reconnect fenced | cache dispositivo, rete per rivalidare | implementato | suite cache/recovery e resilienza; offline reale device oltre smoke NOT_RUN | mantenere cache scoped e checkout server-authoritative |
| Auth — TASK-020 | AccountScreen/router → AuthController → SupabaseAuthRepository → PKCE + callback validator/source + SecureSupabaseAuthStorage → stato Auth | dominio callback, Google/Supabase provider, associazioni native | lifecycle deterministico implementato; login distribuibile incompleto | sentinel `.invalid`; Google true respinto staging/production; unit cancellazione/failure/cold-warm/duplicati/logout/refresh; live BLOCKED | P1: configurazione owned e collaudo callback reale; factory test non è soluzione |
| Profilo/privacy — TASK-021 | CustomerAccountPanel → CustomerAccountController → SupabaseCustomerAccountRepository → profilo owner-scoped/RPC privacy → parser/stato | sessione cliente, tabelle/RLS/RPC | implementato | S account/auth/storage + SQL privacy; L BLOCKED da login; address v2 assente | P1 runtime; export/deletion non eseguiti su utenti reali |
| Indirizzi — TASK-050/051 | editor/panel → CustomerAccountController → repository → address CRUD v2 → lista versionata | tre RPC v2 e provider indirizzi | CRUD/manuale implementato; map/search/reverse NotConfigured | SQL55 + unit/widget; staging BLOCKED | P1 migration; provider decision da utente, fallback manuale conservato |
| Delivery context — TASK-051 | DeliveryContextScreen → DeliveryContextController → SupabaseDeliveryContextRepository → read/select/preview → context/version/serviceability → checkout | tre RPC assenti; GPS Geolocator reale | 7 difetti riprodotti/corretti; debounce/timeout/fence lato UI | regressioni R01–R07 PASS locali; live BLOCKED | P1/P2: gate locali, migration e test zone/slot server |
| GPS/mappa indirizzi — TASK-051 | delivery screen → CurrentLocationPort → Geolocator; SearchPort/ReverseGeocodingPort/MapPort separati | permesso foreground, provider ancora non scelto | GPS concreto; tre adapter esterni mancanti per configurazione | test GPS off/negato/coordinate non valide, manual fallback; provider reale BLOCKED | ADR-014 autorizza solo Maps SDK tracking, non Places/geocoding; nessuna chiave riutilizzata |
| Carrello — TASK-023/034 | CartScreen/AddToCartButton → CartController → DriftGuestCartStore/SupabaseCustomerCartRepository → cart read/mutate/revalidate/merge → versioni/conflitti | sessione per cart remoto, proiezione attuale | implementato, prezzi CLP interi | suite cart + 98 SQL; merge/retry/doppio tap testati; L NOT_RUN | gate owner/shop e idempotenza preservati |
| Hold — TASK-025/034 | ReservationHoldPanel → controller/coordinator → SupabaseReservationHoldRepository → create/read/release → scadenza | stock/cron/server time | implementato | 54 SQL + unit/controller/resilience; live concorrenza NOT_RUN | non usare timer UI come autorità di stock |
| Checkout — TASK-026/027/051 | CheckoutScreen/PaymentScreen → CheckoutController → SupabaseCheckoutRepository → quote v2 per pickup/delivery, v1 solo reservation → confirm/order v2 → draft recovery | quote v2 mancante; order create/read v2 presenti | percorso implementato, draft v3 e chiave persistita | unit/widget/SQL quote57+orders35; L BLOCKED | P1 backend: nessun fallback v1 aggiunto |
| Ordini — TASK-028/034 | OrdersScreen/OrderDetailScreen → CustomerOrderController → repository → list/detail/cancel → cache/selectors/timeline | RPC presenti, sessione | implementato | 30 history + 35 orders SQL e unit/widget; golden locale FAIL baseline; L NOT_RUN | retest timeline monotona/cancel con fixture reale |
| Riordino — TASK-052 | CustomerReorderCard → CustomerReorderAttempt + repository → preview/apply → differenze da confermare → cart | due RPC assenti | implementato con tentativo idempotente, dati correnti | suite reorder + SQL55; L BLOCKED | P1 migration; non ripristinare prezzi storici |
| Pagamenti — TASK-032/ADR-012 | checkout options → payment method allow-list → order create v2 → snapshot pagamento → recovery | metodi offline consentiti shop/server | pay_at_pickup/cash_on_delivery supportati; online disabled per decisione | 37 SQL + unit/state machine; sandbox/provider/webhook reale NOT_RUN | configurazione esterna per online/refund; nessun incasso/rimborso reale |
| Tracking — TASK-044/045/ADR-014 | OrderDetail → DeliveryTrackingController → SupabaseDeliveryTrackingRepository → snapshot/feed realtime → adapter Google o stato testuale | snapshot owner, Realtime, due chiavi Maps SDK ristrette | adapter concreto presente; attivazione non configurata | 60 SQL; controller/cache/map tests; live map/device BLOCKED | non confondere con geocoding indirizzi |
| Inbox — TASK-052 | CustomerNotificationInboxScreen → InboxController → SupabaseCustomerNotificationRepository → list/read/all → cache/UI | tre RPC inbox assenti | implementato; corretti race e dati dopo revoca R08–R10 | regressioni locali PASS + SQL notification40/journey55; L BLOCKED | P1/P2: migration e collaudo destinatario reale |
| Push — TASK-022/031 | notification panel → CustomerDeviceController/signout coordinator → device repository + PushTokenProvider → claim/ack/route | FCM/APNs, credenziali/provisioning e adapter | consenso/registro/token lifecycle implementato; push provider Unconfigured | device58+notification40 SQL e unit; consegna push reale BLOCKED | decisione/configurazione provider, device reale; mock non prova consegna |
| Assistenza — TASK-053 | CustomerAfterSalesScreen → controller → repository → list/create/cancel/order_lines/evidence ticket/register → stati backend; Admin queue/read/mutate | sette RPC Client assenti, worker evidence/scansione | implementato; fix dispose R11 | controller/repository +55 SQL +8 foundation Admin; workflow live BLOCKED | migration, login e lavorazione Admin con fixture sintetica |
| Recensioni — TASK-053 | section/account/order card → FutureProvider/dialog → review repository → submit/update/list/product reviews → moderazione/aggregato | quattro RPC assenti, moderazione Admin | implementato; owner e acquisto verificati server-side | suite reviews/pagination +55 SQL; L BLOCKED | applicare migrazioni, verificare ordine completato e moderazione reale |
| Authoring Android/iOS/Admin — TASK-046–049 | native editor → StorefrontAuthoringContract / StorefrontAuthoring → API authoring versionata → proiezione → Client; Admin storefront read-model/mutations/images | sessioni operative autorizzate, ruolo/shop, backend | codice presente nelle revisioni remote correnti; nessuna ricostruzione | audit statico native + SQL publications56/promotions23/images43; nuovo E2E multi-app NOT_RUN | mantenere revisioni/idempotenza/payload pubblico; test ruolo revocato e cross-shop in SQL; retest UI coordinato |
| Vendita fiscale POS — TASK-030 | ordine/handoff → ledger idempotente → POS autorizzato | app POS e sessione operatore | dominio separato dal pagamento/ordine | 40 SQL handoff; nuovo POS/device E2E NOT_RUN | nessuna modifica o vendita fiscale dall'app Client |

## Finding e regressioni

Ogni riproduzione usa completer/fake versionato e fixture sintetiche. L'errore è stato
eseguito sulla versione precedente alla correzione, con exit code 1; il fix è verificato
nella suite mirata, exit 0. Questo è evidence deterministica, non traffico live.

| ID / severità | Riproduzione, atteso → osservato prima | Causa e correzione | Test/evidence |
|---|---|---|---|
| F01 P1 | gate 55 RPC → staging ne espone 32; checkout v2 pickup/delivery non disponibile | due migration canoniche non applicate, nuovi oggetti assenti; piano pronto, nessun apply condiviso | gate snapshot remoto FAIL23+2; SQL isolato PASS; aperto runtime |
| R01 P1 | preview owner, logout, risposta → guest vuoto; prima contesto owner pubblicato | fence owner/shop/generazione prima di pubblicare preview | delivery_context_lifecycle_test: preview dopo logout, FAIL→PASS |
| R02 P2 | selezione A→logout→A → sessione nuova invariata; prima selezione vecchia sovrascriveva | generation per scope e mutation | stesso file: risposta A-B-A, FAIL→PASS |
| R03 P1 | refresh dopo revoca → contesto/cache vuoti; prima snapshot ancora visibile | cache ammessa solo su offline/timeout; UI cleared prima del purge, anche se lo storage fallisce | stesso file: revoca + errore purge, FAIL→PASS |
| R04 P2 | dispose durante preview → nessun accesso ref; prima eccezione | guard disposed prima di stato/ref tardivi | stesso file: dispose, FAIL→PASS |
| R05 P2 | contesto delivery salvato, tap pickup → pickup resta; prima build reimpostava delivery | sync del selettore solo quando cambia il contesto ricevuto | delivery_context_screen_test: modalità, FAIL→PASS |
| R06 P2 | query pendente, cancella testo → spinner finisce; prima rimaneva attivo | invalidazione query e reset dello stato searching | stesso file: query cancellata, FAIL→PASS |
| R07 P2 | query A fallisce dopo risposta B → suggerimenti B preservati; prima cancellati | fence query anche nel ramo errore; deadline8s search/resolve/reverse | stesso file: errore vecchio, FAIL→PASS |
| R08 P2 | pagina ordini pendente, filtro payment → solo payment; prima pagina ordini aggiunta | fence generazione pagination/filtro | inbox_lifecycle_test: pagina tardiva, FAIL→PASS |
| R09 P2 | mark-all pendente A-B-A → nuove notifiche unread; prima unread0 | fence sessione/generazione mutation | stesso file: mark-all tardivo, FAIL→PASS |
| R10 P1 | inbox, revoca, refresh → lista/cache vuote; prima notifiche visibili | failure autoritativa elimina snapshot; offline continua readonly | stesso file: revoca FAIL→PASS, offline PASS |
| R11 P2 | create assistenza, dispose, risposta → risultato scartato; prima Bad state su ref distrutta | controllo dispose anche nei fence e caricamenti assistenza | after_sales_controller_test: dispose, FAIL→PASS |
| R12 P2, correzione del candidato447d2a8 | preview concorrente con read/refresh → lettura ready; candidato rimaneva loading | preview conserva la generazione della lettura, loading conserva busy e denial invalida preview | due ordini completamento FAIL→PASS; non attribuito falsamente alla baseline |
| F02 P1 release | configurazione Google true staging/prod → login reale; respinta, sentinel non verificabile | risorsa esterna mancante, controlli di sicurezza corretti conservati | AppConfig/auth/native source + test; aperto |
| F03 P2 | ricerca/reverse/mappa indirizzi runtime → provider reale; NotConfigured | decisione di provider non presente; parti neutrali e manuale completate | ADR-014 scope tracking; aperto esterno |
| F04 P3 | rigenerazione completa Admin → typecheck; fallisce su nullability in POS/History/WeChat e commerce | schema-wide non riallineato; candidato additivo commerce locale tipizzato, senza cast nuovi | patch separata verificata typecheck; integrazione/review coordinata aperta |
| F05 P2 gate | golden originali macOS → pixel identici; 6 px checkout/18 px tracking diversi | riprodotto identico a baseline su macOS 27; causa raster specifica ambiente da confermare | full suite FAIL; goldens baseline FAIL; immagini attese non cambiate |

La review distinta non è ancora ottenuta: l'autore non assegna APPROVED ai propri fix.
Non si dichiarano zero finding aperti: F01/F02/F03/F04/F05 e collaudo live restano visibili.

## P3 Admin: candidato concreto, integrazione non attestata

La generazione reale con postgres-meta 0.97.0 sul DB isolato produce 13.176 righe contro
5.612 del file corrente. Sostituirlo integralmente rompe typecheck in domini estranei.
È stato preparato fuori dal checkout Admin un candidato che aggiunge 51 tabelle e 73
funzioni pubbliche commerce mancanti, conservando le definizioni esistenti (incluse le
sette RPC Admin già tipizzate). `npm run typecheck` exit0 e `git apply --check` exit0;
nessun cast `any`/`unknown` aggiunto. SHA256 patch:
`123242eaa408dfabdfd730c67fd842d822b924bf14f2588020d93a516aafe413`.

Il candidato non chiude il drift schema-wide e non è stato integrato, committato o
pubblicato nell'Admin: TASK-159 concorrente resta intatto. Owner: writer/reviewer Admin;
azione: coordinare la patch commerce e la restante rigenerazione fuori scope; verifica:
typecheck + foundation + confronto schema prima dell'integrazione. Non è un fix live.
