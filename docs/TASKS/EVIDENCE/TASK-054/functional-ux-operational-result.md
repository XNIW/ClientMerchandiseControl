# CLIENT_TASK054_FUNCTIONAL_UX_OPERATIONAL_RESULT

## Risposte operative

1. **Cliente:** catalogo pubblico, ricerca/preferiti, carrello locale, account e indirizzo
   manuale, pickup, checkout con metodo offline, storico, assistenza, recensioni e inbox
   hanno implementazioni e prove deterministiche. Questa run esercita componenti reali
   e repository di produzione con transport sintetico; non certifica ancora un ordine
   cliente sullo staging condiviso.
2. **Gestione negozio:** pubblicazione/prezzo/immagini e gestione commerce sono integrate
   in Admin. Non è attestata la catena gestionale Android/iOS → sync → pubblicazione →
   Client sulle due piattaforme. Il Worker TEST usa il backend autorizzato, ma la versione
   attiva non contiene una ricevuta SHA che provi la main attesa.
3. **Telefono:** servono finestra writer/recovery remota, tre migration canoniche,
   identità/shop TEST approvati, servizio readonly TLS, riferimenti auth/provider se ON
   e runtime/firma/canale per il bundle Client. iPhone rilevato ma non disponibile;
   nessun Android fisico disponibile. Production **NOT_ACTIVATED**.

## Revisioni e confini

Client baseline aggiornata `12f03c7cc81970facb363d0bebedb194c084a218`, PR27 già
MERGED. Admin baseline `f21339bb6c49a87057f629bc67c6519c478b50de`; nuova main
`4532831b30de8ba19d1c26a040c0bfc6b64b794a` include PR119/df79d440, riconciliata
con fetch reale. PR117 già MERGED6d5f3768. La CI Client main36924259905 ha5job
con step applicabili SUCCESS sullo SHA12f03c7; queste sono prove baseline, non del
nuovo candidato. Nessuna PR storica ricreata.

Writer unico nel worktree `task054-functional-ux`, branch `codex/task054-functional-ux`.
Checkout Client originario a8423c868 e `supabase/` non tracciata preservati. Admin
canonical pulito a f21339bb; nessuna modifica ai repository gestionali concorrenti.
Snapshot e ricevute storiche rimangono congelati; questo documento è l'overlay corrente.

## Difetti riprodotti e correzioni

| ID | Superficie/stato e impatto osservato | Causa e intervento | Regressione |
|---|---|---|---|
| UX054-01 | Recensioni pubbliche, Android393 e320, testo200%: overflow27px; badge acquisto verificato troncato | Row rigida e Chip monoriga; Wrap per rating/count, badge con testo flessibile e token esistenti | ES/IT/EN/zh-Hans320x568, testo2, bounds, intero badge e semantics |
| UX054-02 | Assistenza320/200%: dropdown tipo89px e motivo49px; label Motivo presentata come Otro, testo selezionato tagliato | Dropdown senza espansione/densità; isExpanded, itemHeight dinamico e isDense=false; label motivo localizzata | Quattro lingue, righe non eleggibili disabilitate, submit vuoto senza chiamata create |
| UX054-03 | Delivery320/200%: selector oltre larghezza, azioni indirizzo161/105/21px nelle lingue occidentali; pickup troppo stretto | Direzione verticale da testo150%, dati indirizzo separati dalle azioni Wrap; CTA pickup sotto i dettagli a testo grande | Quattro lingue, scelta pickup conservata e assenza overflow |
| F054-04 | R18 richiede non lette; UI aveva solo categorie/read-all | Filtro locale sulle pagine caricate, senza filtrare cache o alterare RPC/cursor; reset owner/shop già governato dal controller | Lettura singola e read-all aggiornano filtro; riaprire tutte conserva4elementi |
| UX054-05 | Inbox in errore mostrava Checkout no disponible | Titolo riusato dalla feature sbagliata; titolo Notifiche nel ramo errore | Cattura nativa error, retry esistente conservato |
| F054-06 | Cart loaded → offline mutation: eccezione non gestita dalle CTA | Controller pubblicava failure ma rethrow restava senza handler UI; catch delle sole CartRepositoryException, senza nascondere errori inattesi | Increase/decrease/remove/clear: righe conservate e tentativo successivo riuscito |
| T054-07 | Vecchia integration checkout usava pickup radio/azione ordine prima di TASK051 e provider account non inizializzato | Harness aggiornato ai componenti correnti e due route checkout/payment; override delivery sintetico esplicito | Stessi assert timeout/riuso idempotency e conferma finale, senza cambiare codice checkout |

Nessun tema nuovo, dependency upgrade, target iOS elevato, baseline golden aggiornata,
policy quantità/CLP cambiata o provider implicitamente attivato.

## Prove visuali e limiti

Comando riproducibile: `CMC_VISUAL_OUTPUT_DIR=build/task054/visual bash
scripts/test-task054-visual.sh --device OWNED_DEVICE_ID`; per CI iOS `--ios` crea,
attende e rimuove soltanto il proprio simulatore. `CMC_VISUAL_CAPTURE=true` è solo un
flag test; repository/identità sintetici, nessun secret o ordine remoto.

Android proprio `emulator-5580`, API35, AVD Codex_Mobile_Parity_API_35, debug,
720x1280/density360 (320x568dp); baseline1080x2400/density420. Locale native capture
ES-CL, scale1/2. Run candidata Android:41test/55capture, PASS/exit0. Le quattro lingue sono verificate nei widget test, non dedotte dai PNG.
Screenshot locali ignorati in `build/task054`, trasferiti da integration_test e
ispezionati come UI reale: non sono mockup. Artefact CI iOS `task054-ios-visual-fixtures`
contiene soltanto queste fixture sintetiche, retention7giorni.

Prima: `android-baseline/16-reviews-product-scale2.png`,
`android-compact-before/21-assistance-form-scale2.png`,
`android-compact-before/25-delivery-provider-off-scale2.png`.
Dopo: directory finale e hash nel receipt locale `build/task054/visual-receipt.json`.
Prima iOS NOT_RUN: toolchain locale Xcode27 incompleta/target14 non supportato;
la nuova cattura CI compatibile è una verifica separata. Nessun PASS screenshot
prima/dopo iOS dedotto dalla corrispondenza del codice.

La suite esercita account CRUD/privacy, checkout pickup timeout/price-change/metodo
online OFF/receipt, storico/detail/dialog cancel, assistenza, recensioni e inbox loaded,
empty/error/loading, delivery OFF e pickup, Home/catalog/product/cart
loaded/empty/offline/error. Cart error/ offline sono assertati sullo stato del controller:
le prime catture con quei nomi erano semplicemente loaded e non valgono per quei casi.
I test falliti del harness sono preservati localmente e superati solo dopo correzione.

NOT_RUN: UI Admin commerce autenticata (nessun account/shop pilota approvato e stack
locale condiviso senza owner esclusivo), tracking nativo live, auth live, modali con
IME OS verificata visivamente, VoiceOver/TalkBack interattivi, contrasto misurato,
lifecycle kill/restart al commit e signed physical. Semantics widget non equivalgono
allo screen reader nativo. Nessuna attestazione visuale per gli stati non catturati.

## Backend fresco e applicazione condizionata

[Metadata fresco](metadata-preflight-20261001.json): target unico jpgoimipbothfgkokyvm,
PG17.6.1.104, osservazione2026-10-01T21:44:00.63145Z, history147.32/55 RPC presenti
con firma/default/grants/settings/bodyhash conformi;23assenti.1/2 indici. Source gate
PASS/exit0; metadata confronto FAIL/exit1. Piano esatto:20260823023037 commerce,
20260823150000 righe assistenza,20260928200000 dedup.16hash canonici e150receipt
index verificati contro Admin; nessun drift nascosto/repair.

Recovery locale147→150→147 preesistente:14hash e contenuto verificati indipendentemente,
ACL/cataloghi e6digest sintetici identici, cleanup Storage API. Rinnovo recovery
NOT_RUN perché nessun apply e sorgenti invariati. Non è backup remoto: backups=null,
PITR=false. Query/transaction/lock snapshot0 non dimostra finestra writer/cron.
Apply **BLOCKED**, nessuna mutazione staging. Gate reale
`python3 scripts/check-backend-compatibility.py --live --app-config PATH` tentato:
exit2, **BLOCKED CMC_BACKEND_PGSERVICE_and_artifact_config**. Snapshot diagnostico
non sostituisce gate distribuzione.

Admin Worker staging: versione bdd42368-1398-4b74-8139-43d4b290dddf100%, creata
2026-09-29T01:31:09Z, backend corretto. SHA main deployed NOT_RUN. Workflow dispatch
scrive secret QA e deploya ref completa; TASK159 richiede release selettiva, quindi
non è stato eseguito un deploy full-main senza la ricevuta di coordinamento.

## Livelli e residui esterni

| Livello | Esito/disposizione | Prova e limite |
|---|---|---|
| CODE | verifiche mirate PASS; gate candidato da associare | 12accessibilità e filtro non lette; candidato nuovo separato da baseline866 |
| BACKEND_RUNTIME | FAIL | metadata32/55 e1/2; apply BLOCKED finestra/recovery remota |
| STAGING_E2E | NOT_RUN | nessuna UI→API→persistenza→Admin→Client autenticata completa |
| AUTH_LIVE | NOT_RUN | provider/dominio/callback/TEST allow-list non attestati |
| ADDRESS_PROVIDER_LIVE | NOT_RUN; OFF | manuale e adapter verificabili separatamente da servizio |
| PHYSICAL_DEVICES | NOT_RUN | iPhone non disponibile, nessun Android fisico |
| DISTRIBUTION | BLOCKED | backend TLS e runtime/firma/canale non attestati; nessun upload |
| MAIN_INTEGRATION | baseline PASS; nuovo candidato NOT_RUN | PR27/117 già integrate; nuova PR solo dopo review/CI |
| UI_VISUAL_QA | PASS sottoinsieme Android fixture; restante NOT_RUN | copertura/stati e prima/dopo descritti, iOS candidato da CI |
| AUTHORING_CHAIN | NOT_RUN | R24: nessuna creazione/modifica/sync/pubblicazione/readback pilot |
| ADMIN_STAGING | BLOCKED | ref backend corretto, SHAdeploy e chain business non attestati |
| PRODUCTION | NOT_ACTIVATED | zero rollout o modifica |

| Risorsa/owner | Tentativo | Passo minimo e prova di chiusura |
|---|---|---|
| Backend owner: finestra/recovery | preflight/history/hash e recovery locale; nessun writer visibile non attesta esclusione | ricevuta writer/cron coordinata e recuperabilità stato remoto; dry-run/apply canonico;55RPC/2indici/150history/RLS reali |
| Backend/release: CMC_BACKEND_PGSERVICE | env presence e servizio locale assenti; live gate exit2 | riferimento esterno readonlyTLS + configartifact approvata; gate live exit0 |
| Auth/domain: AUTH_CALLBACK_VERIFIED_HOST/AUTH_REDIRECT_URI | runbook e nativeconfig; nessun riferimento approvato | ownershipAASA/assetlinks esatte e TESTprovider/allow-list; R02/03 cold/warm/revoke |
| Address: ADDRESS_PHOTON_ORIGIN/ADDRESS_PROVIDER_APPROVED/flags/chiavi ristrette | nessun valore approvato, Maps.local.xcconfig assente | receiptprovider e scopechiavi; R05/26 GPS/denied/manuale/salvataggio, senza endpoint implicito |
| Admin release owner: SHAdeployment/selectiveTASK159 | Wrangler readonly target/100% e assenzaSHA; coordinamento chat attivo | receiptcommit/versione autorizzata e deploy selettivo; probeclient/Admin stesso backend |
| Native owners: pilot/shop e finestra R24 | chat Correggi sync e parità Android/iOS coordinata; branch143/144 attivi preservati | fixturesTEST approvate e receipt authoringAndroid/iOS+sync+Admin+Client; SLAapprovato |
| Mobile release: IOS_EXPECTED_TEAM_ID/IOS_EXPECTED_SIGNING_CERT_SHA256/IOS_RELEASE_RUNTIME_CONFIG_PATH e canale; equivalenti Android | presence-only e runbook; key.properties assente; target14 preservato | config/firma/destinazione approvate, build/upload/ricezione/install/smoke fisico distinti |

Online payment/R27: **OFF**, nessun PSP sandbox approvato o reale attivato. Push/R28:
**OFF**, nessuna consegna APNs/FCM live; inbox e device registration non lo provano.

## Matrice acceptance preservata

La tabella seguente è un mapping di prove parziali al caso composto, senza trasformare
un frammento fixture in PASS end-to-end. Tutti i30casi restano NOT_RUN su staging
Android/iOS. I25ID storici e provenance incompleta sono conservati nel file storico.

## Mapping esatto R01–R15

| R / titolo della acceptance | Fonte nel mandato corrente | Componenti obbligatorie | Prova parziale attualmente rendicontabile | Esito composito / prerequisito residuo |
|---|---|---|---|---|
| R01 — Ingresso guest e capacità effettive | §3 backend; §4 gate; §5 guest; §8 Home/catalogo | C manifest/readiness e transport negativo; S 55 firme/grants/body/history; D guest su entrambe; U capacità assenti esplicite | Baseline gate source positivo/negativo e readiness deterministica; nuove PNG Home/catalogo/dettaglio loaded/empty/offline/error Android con fixture. Nessuna verifica API reale da queste PNG | NOT_RUN; B. Runtime incompatibile nel precedente snapshot resta FAIL, apply BLOCKED finché manca finestra |
| R02 — Sessione e callback del provider | §4 Auth; §5 login/cancel/cold/warm/refresh; §11 fisico | C config/PKCE/callback negative; A provider live; D cold/warm; L refresh/cancel; U feedback e navigazione una volta | Baseline test config/callback/lifecycle registrati; nuove catture non comprendono login live né callback cold/warm | NOT_RUN; A + F, P per acceptance fisica |
| R03 — Logout, revoca e A→B→A con richieste in volo | §5 sessioni; §9 revoca; §10 timer/subscription | C e L race A-B-A/purge/dispose; S revoca reale e owner cache; D lifecycle; U dati rimossi/errore dominante | Baseline regressioni account/order/delivery/inbox e finding C-02/C-03 chiusi dalla re-review su ecba981; nuova run UX non riesegue sessione reale | NOT_RUN; B + A + F; suite di race del candidato stabile da associare al nuovo SHA |
| R04 — CRUD indirizzo e default | §5 CRUD/default/conflitti; §9 validazione/keyboard | C draft/versione/default/geografia; S RPC v2 e riletture; D editor; L conflitti/switch; U campi/errori/IME | Nuove catture Android account-loaded/address-editor/address-new/address-saved e flusso fixture CRUD; pin invalidation e conflitti hanno test baseline. Default unico e versioni remote non verificati dalle fixture | NOT_RUN; B + A + F. Tastiera nativa e validazione compact editor ancora da attestare |
| R05 — Ricerca, resolve, reverse e pin | §4 indirizzi separati; §5 GPS/provider; §9 fallback; §11 permessi | C transport/batch/epoch; S G; D GPS/map pin; L query fuori ordine; U ricerca/pin/errore | Adapter e transport race baseline; la nuova superficie Delivery è provider OFF, quindi non dimostra ricerca/resolve/reverse/pin live | NOT_RUN; G + F e D/P per permessi native. Mappa tracking non sblocca la mappa indirizzi |
| R06 — Delivery/pickup e concorrenza contesto | §5 delivery/pickup; §9 negozio e contesto | C versione/context; S select/preview cross-shop; D selezione; L risposte sovrapposte; U contesto coerente su Home/cart/checkout | PNG Android delivery-provider-off scale1/2; fix selettore verticale ≥150% implementato dal writer, con ulteriore overflow iniziale in diagnosi. Test baseline su preview/select epoch | NOT_RUN; B + A + F. Regressione/re-capture post-fix e congruenza cross-surface da concludere |
| R07 — Zona, slot, costo e contesto stale | §5 zona/slot/costo; §9 prezzi/feedback | C checkout stale/failure; S authority zona/fee/slot e quote; D selezione/retry; L modifica indirizzo; U rifiuto leggibile | PNG checkout mode/pickup/slot/payment con repository sintetico; controller/SQL baseline coprono rifiuti. Nessuna quote staging o slot esaurito live | NOT_RUN; B + A + F |
| R08 — Carrello guest persistente e merge | §5 persist/merge; §9 offline; §11 lifecycle | C SQLite reale e merge/idempotenza; S carrello account/merge; D restart/login; L A-B/logout; U righe corrette | Nuove fixture Storefront usano Drift cache/guest cart in memoria reali; PNG cart-loaded/cart-empty. Questo non è restart su storage durevole né merge server dopo login | NOT_RUN; B + A + F. Riavvio processo/storage persistente e merge vero ancora da eseguire |
| R09 — Prezzi, disponibilità e rimozioni | §5 variazioni; §6 pubblicazione; §9 righe esplicite | C diff e total; S variazione operatore/readback; D checkout; U prezzi cambiati/non pubblicati/indisponibili | PNG checkout-price-change e timeout con fake repository; baseline Cart/SQL disponibilità. Catalogo fixture offre due prodotti sintetici e immagini assenti | NOT_RUN; B + A + F + ADM; manca la variazione operatore → quote → riscontro UI |
| R10 — Checkout pickup v2 | §5 percorso verticale; §7 metodi offline | C controller/RPC request; S quote v2/hold/order/Admin; D pickup; U step/receipt | PNG checkout-pickup/slot/payment/receipt; flusso fixture timeout e retry, non backend reale | NOT_RUN; B + A + F + ADM; UI→API→persistenza→Admin→Client obbligatoria |
| R11 — Checkout delivery v2 | §5 delivery verticale; §7 server validation | C address/context version e snapshot; S quote/order fulfillment; D delivery; L edit post-order; U fee/zona/receipt | Test controller/repository baseline; nuova capture checkout è percorso pickup, quindi non coverage delivery completo | NOT_RUN; B + A + F + ADM; snapshot immutabile post-edit da rileggere server |
| R12 — Hold concorrenti, scadenza e notifiche | §3 migration/indici; §5 concorrenza/expiry | C dedup e clocks; S stock atomico/expiry/2 indici; D feedback; L race; U scadenza | Baseline SQL/recovery e regressione due hold/same owner dopo correttiva; nessun hold creato nel backend condiviso da nuova capture | NOT_RUN; B + F; due hold distinti e duplicato stesso hold da verificare con ruoli reali |
| R13 — Idempotenza ordine e risposta persa | §5 doppio tap/lost response; §7 pending; §10 duplicati | C chiave attempt/recovery; S ordine unico/hold/slot/POS; D tap e recovery; L commit senza risposta; U pending/retry | Nuovo flusso fixture checkout richiede riuso chiave dopo timeout, orderRequests=2 con stessa key; baseline unit/SQL. Due chiamate fake non dimostrano un commit remoto unico | NOT_RUN; B + A + F + ADM; perdita risposta dopo commit e conteggi remoti/POS |
| R14 — Kill/restart e ambiguità | §5 kill/restart; §7 recovery; §11 lifecycle | C draft persistente owner; S recovery autorevole; D kill/restart; L owner switch; U pending onesto | Baseline draft store/controller e flusso timeout fixture; la nuova suite visual smonta widget tra casi, non uccide/riavvia il processo nell'ambiguità | NOT_RUN; B + A + F; kill/restart e rete interrotta al punto commit |
| R15 — Metodi pagamento previsti e OFF | §7 R15 esplicito | C metodi/payload/permessi; S COD/pickup server; D selezione; U online OFF/pending distinto da paid | PNG checkout-payment/payment-offline-provider-off/receipt; baseline metodi offline e validator. Scelta OFF conservata, nessuna attivazione online | NOT_RUN; B + A + F. COD e pay-at-pickup da eseguire secondo configurazione server reale |

## Mapping esatto R16–R30

| R / titolo della acceptance | Fonte nel mandato corrente | Componenti obbligatorie | Prova parziale attualmente rendicontabile | Esito composito / prerequisito residuo |
|---|---|---|---|---|
| R16 — Ordini, stati, timeline e cancellazione | §5 storico/cancel; §8 ordine; §9 back | C owner/cursor/cache; S transizioni Admin/cancel; D lista/detail/dialog; L A-B-A; U timeline | PNG orders-loaded/order-detail/order-cancel-dialog e cancellazione fake con una richiesta; baseline race controller. Stato Admin live non cambiato dalla suite fixture | NOT_RUN; B + A + F + ADM |
| R17 — Tracking e indisponibilità provider | §4 distinzione Maps; §5 tracking; §8 tracking; §9 fallback | C tracking/map gate/golden; S stream owner; D native; L subscription/dispose; U mappa OFF/testo/stale | Baseline probe false/throw/timeout/logout e due golden checkout/tracking; nuova order-detail generica non è una prova di tracking live. Provider Maps può restare OFF | NOT_RUN; B + A + F; stream/stale/fallback e confronto golden del nuovo candidato da associare |
| R18 — Inbox, filtri e paginazione | §5 inbox/badge/filtri; §8 inbox; §9 errori | C cursor/dedup/read; S badge e owner; D inbox/azioni; L loadMore/revoca/filter; U empty/error/category | PNG inbox scale1/2 loaded; baseline lifecycle late page/revoca. La nuova fixture ha quattro elementi, nextCursor=null: non verifica pagina successiva o badge server | NOT_RUN; B + A + F. Filtro non lette aggiunto e regredito sulle pagine caricate; live/paginazione restano da verificare |
| R19 — Consenso e deep link proprietario | §5 link autorizzati; §7 push OFF; §11 permessi | C consenso/route allow-list; S device registry/owner resolution; D link; L logout in volo; U stato consenso | Baseline device flow e route controller; nuova suite visual non esercita device-consenso/link. Push reale separato R28 | NOT_RUN; B + A + F; device registry/link con permessi applicativi, non token mock |
| R20 — Riordino e conferma differenze | §5 riordino; §9 differenze/prezzo | C preview/apply/key; S attuale prezzo/stock; D conferma/cancel; L replay; U diff esplicite | Baseline customer_reorder_attempt e SQL. Nuova order-detail non esegue preview/conferma di riordino | NOT_RUN; B + A + F + ADM |
| R21 — Assistenza righe ordine e Admin | §5 righe/qty/evidence/Admin; §8 assistenza; §9 validazione | C righe/eleggibilità/create; S ticket/evidence privata/RBAC/audit; D picker; L retry/owner; U dropdown/errore | PNG assistance-form scale1/2; writer corregge label Motivo e reflow dropdown; nuove regressioni ES/IT/EN/zh-Hans verificheranno checkbox non eleggibile e submit senza selezione. Capture corrente non invia né allega file | NOT_RUN; B + A + F + ADM. Max3 allegati/privacy Storage/gestione Admin/cross-shop da eseguire |
| R22 — Recensioni verificate e moderazione | §5 verified/moderazione; §8 recensioni/Admin; §9 accessibilità | C repository/unicità; S acquisto verificato/RLS/moderazione/aggregate; D submit/edit; L stale owner; U count/stars/badge/dialog | PNG reviews-account/reviews-product scale1/2; overflow prima riprodotto, writer sostituisce Row con Wrap; nuova regressione verifica count24/badge/semantics nei quattro locale. Fixture non verifica acquisto server | NOT_RUN; B + A + F + ADM. Re-capture post-fix + submit/duplicate/edit/moderate/readback live |
| R23 — Ricerca assistita e deep link | §5 ricerca/paginazione; §9 keyboard; §10 search/scroll | C debounce/history max10/route; S catalogo pubblico; D input/link; L risposte/dispose; U suggerimenti/history | PNG catalog loaded/empty/offline/error; transport fixture usa DTO produzione e search history in memoria; baseline search assist/deep link. Capture semplice non digita 11 ricerche né apre deep link | NOT_RUN; B + F; nuova interazione input/history/link e assenza risultati tardivi |
| R24 — Authoring operativo e visibilità pubblica | §6 integralmente; §5 catena; §8 Admin immagini; §10 propagation | C projection/image contracts; S inventory→publication/prezzo/cache; D authoring Android/iOS e lettura Client Android/iOS; L shop/concorrenza; U immagini/versioni | Baseline SQL Admin publications/images/POS e task authoring integrati sono fonti. Nessuna creazione/modifica nelle app native operative o pubblicazione/readback cross-platform da queste capture Client | NOT_RUN; B + F + ADM + N. Vedere scomposizione obbligatoria sotto |
| R25 — Reconnect e isolamento trasversale | §3 ruoli/cross-owner/shop; §5 offline; §9 revoca; §11 rete | C epoch/cache/retry; S RLS/grants reali; D reconnect; L context/cart/order/inbox/aftersales; U errori/recovery | Baseline race/SQL RLS; nuove Home/catalog/product offline-cache fixture. Cart offline/error iniziali non qualificati; writer ora inietta failure reale del confine e aggiunge assert prima capture | NOT_RUN; B + A + F. Reconnect/switch trasversale e riletture anon/customer/operator |
| R26 — Fallback indirizzo e GPS | §4 provider/GPS distinti; §5 fallback; §9 manuale | C adapter timeout/429/accuracy/epoch; S salvataggio manuale; D denied/GPS/pin; L logout; U OFF/validazione/IME | PNG Delivery provider OFF e editor indirizzo separato; baseline transport cooldown/race. OFF non prova timeout/429/denial GPS né accuracy>250m | NOT_RUN; B + A + F per save; G/config controllata + D/P per GPS. Provider non approvato resta OFF |
| R27 — Pagamento provider sandbox | §7 R27 esplicito | C integrazione approvata; S sandbox webhook/order/Admin; D callback; L duplicate/ambiguous; U pending | Nessuna sandbox eseguita; il metodo offline e provider OFF non sono questo caso | NOT_RUN; disposizione OFF. Owner payments deve attestare implementation/decisione/provider/canale sandbox approvati. Nessun nuovo servizio implicito |
| R28 — Push provider e cold/warm link | §7 R28 esplicito; §11 fisico | C provider/entitlement; S delivery receipt/token owner; D fisico cold/warm; L revoke/logout; U consent/navigation | Nessuna consegna provider/fisico eseguita; inbox e registrazione device deterministica non sono push reale | NOT_RUN; disposizione OFF. Provider/entitlements/canale approvati + P + B + A + F |
| R29 — Artifact, firma e ambiente distribuito | §4 gate TLS; §11 distribuzione; §13 merge; §14 ricevute | C validator/gate/CI; S compatibilità; D interno/install/fisico; L native smoke; U uso reale | Baseline build unsigned/signature validator avversariali e CI precedenti; nuovo candidato, firma/upload/ricezione/install non attestati. Main merge27/117 va riconciliato live separatamente | NOT_RUN; DISTRIBUTION BLOCKED per B + P/runtime/canale e `CMC_BACKEND_PGSERVICE` TLS approvato |
| R30 — Smoke nativo e superfici visuali | §8 audit visivo; §9 UX/accessibilità; §10 performance; §11 device; §12 golden | C build/golden/gate; D Android+iOS avvio/navigazione/restart; L processo; U prima/dopo/locali/scale/focus/IME | Baseline Android/iOS shell smoke e due golden documentati; nuova Android fixture 41 PNG su 29 test, run iniziale FAIL due overflow. Fix reflow/delivery e filtro completati; nuova run finale e CI restano receipt separate | NOT_RUN composito; post-fix Android/iOS, golden/gate del candidato stabile, visual review e lifecycle restart da chiudere; P resta distinta |

## R24 deve restare una catena, non un conteggio di repository

| Sottocomponente R24 obbligatoria | Prova necessaria | Stato corrente di questa run |
|---|---|---|
| Authoring Android gestionale | Creazione/modifica campi previsti + immagine con pilota/shop TEST; History Entry/outbox e sync letti | NOT_RUN nella suite Client fixture; N |
| Authoring iOS gestionale | Stessa prova separata, inclusi native save/sync e concorrenza | NOT_RUN; N |
| Pubblicazione/prezzo Admin | UI → RPC con operator same-shop → proiezione persistita; unpublished non diventa pubblico | NOT_RUN; B/F/ADM |
| Immagini nuove/sostituite/rimosse | Storage API, versioni/URL pubblici e invalidazione cache; assenza immagine con fallback | Nuova fixture prova solo fallback immagini assenti; mutazioni/versione catena NOT_RUN |
| Consumo Client Android e iOS | API pubblica → cache → render dei medesimi ID/versioni/prezzo/disponibilità | Nuove PNG sintetiche Android sono parziali; catena live NOT_RUN |
| Shop/concorrenza/propagazione | Cambi S→T/aggiornamenti concorrenti; tempi confrontati con budget già approvato | NOT_RUN; non inventare nuovo SLA |
| Confini inventory/POS/fiscale | Ruolo Client mutation inventory negata; auto-sync, History Entry/outbox/POS invariati | Test contrattuali baseline separati; prove live nuove NOT_RUN |

## Gap da dichiarare senza trasformarli in bug

| Area | Limite osservabile del nuovo harness/evidence | Passo indipendente utile |
|---|---|---|
| Loading | Nuovi commerce cases catturano solo loaded/OFF. `captureVisual` chiama pumpAndSettle, incompatibile con spinner che animano indefinitamente | Cattura con pump bounded e timeout; Completer controllato e chiusura/smontaggio finale. Non chiamare PASS loading da una capture loaded |
| After-sales states | Form loaded scale1/2; assenti capture list/detail/empty/error/loading/mutation/evidence picker | Montare produzione con repository empty/error/loading; verificare esito submit e selezione disabilitata, max3 allegati soltanto con fake picker o device dichiarato |
| Reviews states | Account/public loaded; assenti empty/error/loading e dialog submit/edit/error con commento preservato | Aprire dialog produzione, failure repository controllata, busy/reset e annullamento; non promuovere aggregate/verifica acquisto dal DTO fixture |
| Inbox states | Loaded quattro elementi, categorie; niente nextCursor, auth-expired, offline-cache/empty/error/loading | Fixture pagina2/Completer, revoca in volo, count/badge e retry; verificare stato prima della capture |
| Cart offline/error | Primi PNG state-named erano cart loaded locale: soltanto RPC Storefront falliva. Writer ha già corretto test con readFailure/error e loaded→mutation offline + assert | Preservare primi PNG come baseline non qualificata; nuove capture + assert failureKind e contenuto conservato, confronto prima/dopo |
| Keyboard/focus | Test account digitano campi, ma le capture sono effettuate prima dell'immissione oppure dopo save; nessuna assert IME native aperta o viewInsets>0 | Focus campo indirizzo/note/review, IME effettiva, scroll/save/back con focus e capture; non sintetizzare viewInsets presentandole come tastiera device |
| Testo 200% | Nuovi commerce al 200% coprono cinque superfici; Home/catalog/product/cart hanno nuove capture scale1. Regressioni widget mirate quattro locale non equivalgono a device 200% su tutte le superfici | Screenshot compact/post-fix per viewport reale dichiarato, nomi lunghi e testi locali; conservare i due overflow prima e ogni altro errore diagnostico |
| VoiceOver/TalkBack | Test semantics e target baseline/mirati sono distinti dall'uso reale degli screen reader | VoiceOver/TalkBack nativi quando disponibili, ordine lettura/focus/azioni; misure contrasto per le superfici modificate. Se non eseguiti: NOT_RUN |
| Tema scuro | Supportato da AppTheme; nuove capture device usano tema light | Non inventare requisito nuovo; riusare suite dark esistente e capture pertinente solo se eseguita |
| Tracking | Golden e test map gate baseline; nessuna nuova native capture tracking live/stale/provider fallback identificata | Catturare card produzione con fixture map OFF/stale in dettaglio ordine e attestare test/golden esatti |
| Admin commerce | Nessuna capture delle superfici pubblicazioni/immagini/orders/aftersales/moderation in questa suite Client | Ramo Admin locale/staging autorizzato con componenti dati sintetici, deploy attestato separatamente |
| R18 wording | Acceptance richiede «filtrare non lette», sorgenti TASK052/UI/controller/repository espongono filtro categoria e unreadCount, non unread filter | Segnalare divergenza esplicita; verificare fonte approvata, non aggiungere prodotto o abbassare il criterio silenziosamente |
| Performance | 10 benchmark baseline PASS documentati, nuova run non ancora associata al candidato UX stabile | Rieseguire benchmark10 canonici una volta sul candidato stabile; nuove misure solo per rischi osservati. Nessuna latenza staging dalle fixture |

## I 25 ID storici restano preservati senza remapping retroattivo

La provenance originale incompleta non consente associazione uno-a-uno con R01–R30.
Il mandato attuale autorizza nuova acceptance, non inventa le vecchie definizioni.
La causa storica «mandato assente» è stata superseded, ma non i risultati o la mancanza
di provenance. Nel task storico rimangono i seguenti ID con esito BLOCKED:

| ID storico | Stato preservato | Nota |
|---|---|---|
| E2E-01 | BLOCKED | Scenario originale non ricostruito; niente PASS retroattivo |
| E2E-02 | BLOCKED | Stessa provenance incompleta |
| E2E-03 | BLOCKED | Stessa provenance incompleta |
| E2E-04 | BLOCKED | Stessa provenance incompleta |
| E2E-05 | BLOCKED | Stessa provenance incompleta |
| E2E-06 | BLOCKED | Stessa provenance incompleta |
| E2E-07 | BLOCKED | Stessa provenance incompleta |
| E2E-08 | BLOCKED | Stessa provenance incompleta |
| E2E-09 | BLOCKED | Stessa provenance incompleta |
| E2E-10 | BLOCKED | Stessa provenance incompleta |
| E2E-11 | BLOCKED | Stessa provenance incompleta |
| E2E-12 | BLOCKED | Stessa provenance incompleta |
| E2E-13 | BLOCKED | Stessa provenance incompleta |
| E2E-14 | BLOCKED | Stessa provenance incompleta |
| E2E-15 | BLOCKED | Stessa provenance incompleta |
| E2E-16 | BLOCKED | Stessa provenance incompleta |
| E2E-17 | BLOCKED | Stessa provenance incompleta |
| E2E-18 | BLOCKED | Stessa provenance incompleta |
| E2E-19 | BLOCKED | Stessa provenance incompleta |
| E2E-20 | BLOCKED | Stessa provenance incompleta |
| E2E-21 | BLOCKED | Stessa provenance incompleta |
| E2E-22 | BLOCKED | Stessa provenance incompleta |
| E2E-23 | BLOCKED | Stessa provenance incompleta |
| E2E-24 | BLOCKED | Stessa provenance incompleta |
| E2E-25 | BLOCKED | Stessa provenance incompleta |

## Dimensioni separate per la consegna finale

| Dimensione | Stato utilizzabile al momento di questa bozza |
|---|---|
| CODE | PASS baseline documentata; nuovo candidato UX ha fix/regressioni in corso, nessun PASS globale qui |
| BACKEND_RUNTIME | Ultimo snapshot documentale FAIL; risultato fresco da riportare dal ramo backend |
| STAGING_E2E | R01–R30 NOT_RUN compositi; prerequisiti apply/fixture/accessi BLOCKED separatamente |
| AUTH_LIVE | NOT_RUN; riferimenti provider/domain/associazioni approvati richiesti |
| ADDRESS_PROVIDER_LIVE | NOT_RUN; provider non approvato/config non attestata resta OFF |
| UI_VISUAL_QA | Capture baseline Android native fixture presenti; run iniziale FAIL; post-fix Android/iOS e giudizio visuale ancora da attestare |
| AUTHORING_CHAIN | R24 NOT_RUN end-to-end; native/Admin/Client devono essere attestati separatamente |
| ADMIN_STAGING | Deploy SHA/target e superfici commerce da verificare; main/CI non equivalgono a deploy |
| PHYSICAL_DEVICES | NOT_RUN; device disponibile non equivale a install/smoke autorizzato |
| DISTRIBUTION | BLOCKED per backend/config/firma/canale; unsigned/upload/install restano separati |
| MAIN_INTEGRATION | PR27/117 già integrate dal mandato precedente; nuova integrazione subordinata a reviewer distinti e CI exact-SHA |
| PRODUCTION | NOT_ACTIVATED |

Parametri mancanti da nominare senza segreti: `CMC_BACKEND_PGSERVICE` (backend/release
owner, TLS e config esterna approvata); `AUTH_CALLBACK_VERIFIED_HOST` /
`AUTH_REDIRECT_URI` (domain/auth owner + TEST allow-list/assetlinks/AASA);
`ADDRESS_PHOTON_ORIGIN` / `ADDRESS_PROVIDER_APPROVED` / `ADDRESS_SEARCH_ENABLED` /
`ADDRESS_MAPS_ENABLED` (address owner, probe/chiavi ristrette); `IOS_EXPECTED_TEAM_ID`,
`IOS_EXPECTED_SIGNING_CERT_SHA256`, `IOS_RELEASE_RUNTIME_CONFIG_PATH` e destinazione
canale interno/equivalenti Android (mobile/release owner). La finestra writer non è
un parametro da inventare: serve coordinamento effettivo prima dell'apply.
