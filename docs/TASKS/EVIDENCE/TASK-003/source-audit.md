# TASK-003 — Source audit

## Metodo e classificazione dei claim

Audit eseguito in sola lettura il 2026-07-30. Le fonti Git sono ancorate a HEAD e branch
locali fissi; non è stato eseguito `fetch`. I risultati remoti sono limitati a metadata
read-only e sono sanitizzati: nessun URL completo, key, token, project ref completo o
dato commerciale è riportato.

Le osservazioni sono classificate così:

- **osservato**: presente nel codice, nei documenti o nei metadata letti;
- **decisione TASK-003**: ownership target scelta dal contratto, non comportamento già
  implementato;
- **limite**: ciò che la fonte non dimostra.

Gli alias usati nelle citazioni sono:

- `Client:` root di questo repository;
- `Admin:` root di `merchandise-control-admin-web`;
- `Android:` root di `MerchandiseControlSplitView`;
- `iOS:` root di `iOSMerchandiseControl`;
- `POS:` root di `Win7POS`;
- `Storico:` root della directory non-Git `MerchandiseControlSupabase`.

## Provenance fissata

| Fonte | Ref/stato sanitizzato | Ruolo nell'audit |
|---|---|---|
| Client | `f3905caf3a4abf7b2682b5dcd9ed491dba019ea0`, branch `milestone/003-004-storefront-contract-environments` | Contratto logico e consumer futuro |
| Admin | `710ff981f7bb0381159724ec02bbfec39a27eedf`, branch `main`, clean | Server boundary e migration/contract authority candidata |
| Android | `c21de310c0a717f481a79d938888cbb99e8f930c`, branch `integrate/mac-final-android-20260717T150455Z`, 1 untracked preesistente | Inventory operativo Android |
| iOS | `c1b7b706c5f05cd7e8dda74cea1122f6483df7ec`, branch `main`, 1 tracked modified preesistente | Inventory operativo iOS |
| POS | `81acd479c187469fe0dc31f9b0fb3a162312c1cc`, branch `backup/win7pos-dirty-20260722-81acd479`, 13 record dirty preesistenti | Vendita fiscale, stock e cache catalogo POS |
| Supabase storico | non-Git, 18 migration SQL, zero Edge Functions implementate | Provenance genealogica, non authority |
| Supabase canonico non-production | unico progetto accessibile `merchandisecontrol-dev`, ref abbreviato `jpgo…kyvm`, `ACTIVE_HEALTHY`, regione `sa-east-1`, sola branch `main` | Runtime remoto collegato all'Admin; metadata read-only |

Fingerprint, algoritmo, dirty state e verifica finale sono in `external-integrity.md`.

## Client Flutter

### Osservato

- Il bootstrap legge `AppConfig` e inizializza Supabase, senza query o repository dati:
  `Client:lib/bootstrap.dart:8-19` e
  `Client:lib/core/backend/supabase_bootstrap.dart:12-33`.
- Development può restare non configurato; gli altri ambienti richiedono URL e
  publishable key insieme. L'origin deve essere HTTPS e la key ammessa è publishable o
  legacy JWT con ruolo `anon`:
  `Client:lib/core/config/app_config.dart:14-50,53-71,78-135`.
- `BackendStatus.ready` riflette soltanto configurazione/bootstrap, non una health
  query live: `Client:lib/core/backend/backend_status.dart:5-11` e
  `Client:lib/core/backend/supabase_bootstrap.dart:17-25`.

### Decisione TASK-003

Il Client è owner di UI, stato/cache locale, deep link e intenti cliente. È consumer
della futura proiezione Storefront e non possiede inventory, pubblicazione, prezzo,
availability, autorizzazione o vendita fiscale.

### Limite

Non esistono ancora DTO, query, repository o contract test Storefront runtime; restano
rispettivamente nei task TASK-005, TASK-006 e TASK-010/TASK-011.

## Admin e Supabase canonico

### Osservato nel repository Admin

- Master Console, Admin Console shop-scoped e POS/Staff sono responsabilità distinte:
  `Admin:README.md:5-11`.
- La `service_role` è dichiarata server-only e vietata nel client/browser:
  `Admin:README.md:20-33`; l'implementazione importa `server-only` e crea il client
  privilegiato senza persistenza sessione:
  `Admin:src/lib/supabase/admin.ts:1-9,27-71`.
- Win7POS parla soltanto con Admin Web HTTPS; il client Admin server-only parla a
  Supabase:
  `Admin:docs/POS_SYNC_ARCHITECTURE.md:5-36`.
- Admin/Supabase sono descritti come source of truth online per shop, catalogo, stock,
  ledger e audit, mentre Win7POS conserva il mirror offline:
  `Admin:docs/POS_SYNC_ARCHITECTURE.md:44-60`.
- Il contratto POS ha versioni centralizzate nell'Admin e replicate nel consumer
  Win7POS:
  `Admin:docs/POS_SYNC_ARCHITECTURE.md:71-90`.
- La CI Admin avvia Supabase locale, applica le migration presenti nel repository e
  lancia pgTAP:
  `Admin:.github/workflows/ci.yml:22-51`.
- Il workflow staging verifica ref allowlisted, branch, delta ledger locale/remoto,
  dry-run e apply esplicito:
  `Admin:.github/workflows/staging-catalog-v2-deploy.yml:31-79,97-120,167-205`.
- Il linked project e un apply storico sono documentati con ref redatto:
  `Admin:README.md:149-163`.
- Il remap TASK-142 è documentato: versione locale `20260727055520`, versione remota
  `20260727084040`:
  `Admin:docs/TASKS/EVIDENCE/TASK-143/README.md:197-203`.
- `shops.shop_id` nasce UUID primary key e le relazioni shop-scoped usano UUID:
  `Admin:supabase/migrations/20260530041048_task_005g_admin_web_schema_rls.sql:27-55`.
- L'evidence schema immagini dichiara il bucket `product-images` con `public=false`;
  il management contract ne fissa nome, limiti, UUID shop/product/version e input
  distinti per intent/finalize/remove/read:
  `Admin:docs/TASKS/EVIDENCE/TASK-137/01-schema-rls-and-grants.md:14-25` e
  `Admin:src/server/shop-admin/product-images/contract.ts:3-50,59-120`.
- Non esiste `supabase/functions/` nel repository Admin. Le funzioni server correnti
  sono route Next.js e funzioni PostgreSQL/RPC, non Edge Functions.
- Non è presente un dominio, artifact o API pubblica Storefront. Le API osservate sono
  Admin/POS/management operative.

### Osservato nel progetto remoto, sanitizzato

- Un solo progetto accessibile: `merchandisecontrol-dev`, ref abbreviato
  `jpgo…kyvm`, stato `ACTIVE_HEALTHY`, regione `sa-east-1`.
- La sola branch è `main`.
- Ledger remoto: 96 migration logiche. `supabase migration list --linked` è allineato
  per 95 versioni 1:1 più il remap TASK-142 locale/remoto già citato.
- Edge Functions: `0`.
- Metadata: `shops.shop_id` è `uuid NOT NULL`.
- Metadata grants: le tabelle legacy `products` e `history_entries` hanno anche grant
  `anon`. Questo non prova accessibilità effettiva né autorizza il Client: grant, RLS e
  contratto sono controlli distinti. Entrambe restano nella denylist.
- Tutte le operazioni remote di questo audit sono state list/introspection read-only:
  nessun apply, deploy, branch change, SQL mutativo o modifica Auth.

### Decisione TASK-003

Il repository Admin è migration authority corrente e contract owner dei futuri artifact
server-facing Storefront. Supabase è runtime di persistenza/enforcement, non business
decision owner. Schema, RLS, grant e RPC Storefront saranno definiti in TASK-005;
proiezione e query contract in TASK-006/TASK-010.

### Limiti

- `ACTIVE_HEALTHY` descrive il progetto, non una readiness end-to-end del futuro
  Storefront.
- Nessuna Edge Function oggi non è una decisione permanente: una funzione futura deve
  vivere nel repository Admin, oppure in un backend dedicato autorizzato da ADR/task.
- Il grant `anon` legacy richiede hardening/verifica in TASK-005; TASK-003 non applica
  DDL.

## Android operativo

### Osservato

- Application-scoped repository, auth, coordinator e subscriber applicano il flusso
  `Supabase event -> coordinator -> repository -> Room -> UI`, con fallback
  offline-first:
  `Android:app/src/main/java/com/example/merchandisecontrolsplitview/MerchandiseControlApplication.kt:61-89,129-143`.
- Il client crea direttamente Supabase Auth, PostgREST e Realtime:
  `Android:app/src/main/java/com/example/merchandisecontrolsplitview/MerchandiseControlApplication.kt:158-177`.
- Room v20 contiene prodotti, fornitori, categorie, price/history, bridge, tombstone,
  watermark e outbox:
  `Android:app/src/main/java/com/example/merchandisecontrolsplitview/data/AppDatabase.kt:13-51`.
- Il prodotto operativo include barcode, descrizioni, purchase price, retail price,
  stock e riferimenti versione immagine:
  `Android:app/src/main/java/com/example/merchandisecontrolsplitview/data/Product.kt:8-44`.
- Il repository possiede CRUD/import, price history, dirty marking e sync
  bidirezionale. Un full remote snapshot può eliminare copie locali clean, mentre righe
  dirty proteggono le modifiche locali:
  `Android:app/src/main/java/com/example/merchandisecontrolsplitview/data/InventoryRepository.kt:501-681,2633-2717,3380-3515,6341-6451`.
- Il remote data source legge/scrive direttamente
  `inventory_suppliers`, `inventory_categories`, `inventory_products`:
  `Android:app/src/main/java/com/example/merchandisecontrolsplitview/data/SupabaseCatalogRemoteDataSource.kt:23-180,268-303`.
- Lo storico prezzi usa direttamente `inventory_product_prices`:
  `Android:app/src/main/java/com/example/merchandisecontrolsplitview/data/SupabaseProductPriceRemoteDataSource.kt:22-175`.
- Sessioni e sync usano `shared_sheet_sessions`, `sync_events`, Realtime e RPC:
  `Android:app/src/main/java/com/example/merchandisecontrolsplitview/data/SupabaseSessionBackupRemoteDataSource.kt:19-84`,
  `Android:app/src/main/java/com/example/merchandisecontrolsplitview/data/SupabaseSyncEventRemoteDataSource.kt:11-104`,
  `Android:app/src/main/java/com/example/merchandisecontrolsplitview/data/SupabaseSyncEventRealtimeSubscriber.kt:29-79`.
- Shop/device usano `mobile_linked_shops` e RPC registration/status:
  `Android:app/src/main/java/com/example/merchandisecontrolsplitview/data/ShopContext.kt:127-140` e
  `Android:app/src/main/java/com/example/merchandisecontrolsplitview/data/ShopDeviceRegistrationRemoteDataSource.kt:77-167`.
- Immagini: management API bearer, signed URL per bucket/path vincolato, record remoto
  finalizzato autorevole e cache best-effort:
  `Android:app/src/main/java/com/example/merchandisecontrolsplitview/productimage/ProductImageApiClient.kt:41-59,141-221`,
  `Android:app/src/main/java/com/example/merchandisecontrolsplitview/productimage/ProductImageService.kt:255-317` e
  `Android:app/src/main/java/com/example/merchandisecontrolsplitview/productimage/ProductImageCache.kt:9-19,84-110`.

### Decisione TASK-003

Android resta writer/consumer inventory operativo. Non è API, projector o contract owner
Storefront. Room è la truth runtime/offline del client; lo stato condiviso converge nel
remote operativo, senza diventare per questo un read model pubblico.

### Limiti

La directory Android contiene hardening SQL parziale e DTO client, non lo schema live
completo. `Android:docs/SUPABASE.md:24-72` e
`Android:supabase/migrations/README.md:13-27,39-46,67-83` vietano di dedurre la
migration authority dai DTO. I match `Storefront` osservati sono icone UI, non un
dominio dati.

## iOS operativo

### Osservato

- L'app compone SwiftData, Supabase/Auth, sync e image service:
  `iOS:iOSMerchandiseControl/iOSMerchandiseControlApp.swift:66-85,159-221`.
- I modelli SwiftData includono purchase price, retail price, stock, immagine e storico
  prezzi:
  `iOS:iOSMerchandiseControl/Models.swift:67-192`.
- L'adapter crea, aggiorna e legge direttamente
  `inventory_suppliers`, `inventory_categories`, `inventory_products`, owner/shop
  scoped:
  `iOS:iOSMerchandiseControl/Sync/Remote/CatalogRemoteSupabaseAdapter.swift:11-100,118-171,173-237`.
- Le query remote impongono owner e shop:
  `iOS:iOSMerchandiseControl/Sync/Remote/SupabaseRemoteQueryExecutor.swift:16-116,142-213`.
- `inventory_product_prices` è letto/scritto direttamente:
  `iOS:iOSMerchandiseControl/Sync/Remote/ProductPriceRemoteSupabaseAdapter.swift:11-65`.
- `shared_sheet_sessions` è letto/scritto direttamente:
  `iOS:iOSMerchandiseControl/Sync/Remote/HistorySessionRemoteSupabaseAdapter.swift:36-133`.
- La policy operativa impone patch parziali, price history append-only e protezione
  delle righe dirty:
  `iOS:docs/SYNC_POLICY.md:3-30`.
- Un inventory count può aggiornare stock e retail price e creare price history
  `INVENTORY_SYNC`:
  `iOS:iOSMerchandiseControl/Sync/Recovery/InventorySyncService.swift:53-60,181-280`.
- Immagini: management API bearer e signed URL same-origin con bucket/path esatti:
  `iOS:iOSMerchandiseControl/ProductImages/ProductImageAPIClient.swift:178-223,367-455`;
  il wire contract vieta blob, bytes, local path e signed/upload URL nel domain model:
  `iOS:contracts/product-image-v1.json:5-16,57-101,152-155`.

### Decisione TASK-003

iOS resta writer/consumer inventory operativo e owner del proprio adapter, non API,
projector o contract owner Storefront. SwiftData è truth runtime/offline; il remote
operativo è convergenza condivisa.

### Limiti

La protezione dirty e la sync bidirezionale impediscono di dichiarare un unico writer
globale sulla sola base del client. I match `storefront` osservati sono SF Symbols UI,
non un dominio dati pubblico.

## Win7POS

### Osservato

- Architettura WPF -> Core -> Data -> SQLite/Admin API, senza Supabase diretto:
  `POS:README.md:18-35` e
  `POS:docs/ARCHITECTURE/POS_ADMIN_SUPABASE_SYNC_ARCHITECTURE.md:6-44`.
- SQLite contiene cache catalogo, stock, price history, sales, sale lines, stock
  movements e outbox; il documento elenca anche le tabelle Supabase operative/security:
  `POS:docs/ARCHITECTURE/POS_ADMIN_SUPABASE_SYNC_ARCHITECTURE.md:46-64`.
- Catalog import e sales outbox passano all'Admin; in conflitto offline Admin/Supabase
  resta autoritativo per la cache catalogo:
  `POS:docs/ARCHITECTURE/POS_ADMIN_SUPABASE_SYNC_ARCHITECTURE.md:91-109,147-161`.
- La vendita, le righe, il movimento stock e la sales outbox sono una transazione
  SQLite atomica:
  `POS:src/Win7POS.Data/Repositories/SaleRepository.cs:52-100`.
- Sale/refund/void generano movimenti stock idempotenti e aggiornano `product_meta`;
  l'outbox conserva payload e hash stabili:
  `POS:src/Win7POS.Data/Repositories/SaleRepository.cs:653-842`.
- L'architettura POS assegna a `PosAdminWebClient` l'unico trasporto HTTP concreto
  verso Admin Web; l'implementazione corrispondente è nel layer Data:
  `POS:docs/ARCHITECTURE/POS_ADMIN_SUPABASE_SYNC_ARCHITECTURE.md:100-106` e
  `POS:src/Win7POS.Data/Online/PosAdminWebClient.cs:14-20,53-100,189-201`.
- Le immagini sono soltanto `DESIGN_READY / IMPLEMENTATION_NOT_STARTED`; nessun campo,
  migration, download o UI è implementato:
  `POS:docs/plans/WIN7POS_PRODUCT_IMAGE_READINESS.md:1-49,72-120`.

### Decisione TASK-003

Win7POS è origine fattuale della vendita fiscale/offline e del relativo movimento stock.
Admin/server possiede ack, ledger e convergenza online. Il catalogo POS è una cache di
vendita. Win7POS non è un endpoint né un fallback del Client Storefront.

### Limiti

Il worktree POS era già dirty. Le conclusioni sopra dipendono da documenti e
`SaleRepository.cs` clean; nessun claim canonico dipende dai file dirty elencati in
`external-integrity.md`. Il gate hardware Windows 7 non è stato eseguito.

## Workspace Supabase storico

### Osservato

- Non è un worktree Git: non esistono HEAD, branch o provenance riproducibile.
- La missione dichiara Android come fonte primaria, Room-first e Supabase futuro:
  `Storico:AGENTS.md:3-19,31-45`.
- Il Master lo descrive come workspace preparatorio, mapping e stub prudenti:
  `Storico:MASTER_PLAN.md:3-13,181-190`.
- Lo stesso Master dichiara il progetto locale non prova dello stato live:
  `Storico:MASTER_PLAN.md:31-39`.
- Sono presenti 18 migration SQL. Il README continua a descrivere la cartella come
  riservata a migration future:
  `Storico:supabase/migrations/README.md:1-19`.
- `supabase/functions/` contiene soltanto il README, che rinvia ogni implementazione a
  un bisogno futuro:
  `Storico:supabase/functions/README.md:1-9`.
- Diciassette dei diciotto basename migration ricorrono nell'Admin; il solo basename
  non trovato è `20260618141000_task135_harden_task108_backup_tables.sql`. È confronto
  nominale, non equivalenza semantica né istruzione di copy/apply.

### Decisione TASK-003

Il workspace è provenance storica, non migration authority, contract owner o prova
live. Ogni artifact unico richiede confronto semantico e nuovo task Admin prima di
essere considerato.

## Denylist operativa per il Client

Le seguenti superfici osservate sono vietate al Client pubblico:

- `inventory_products`, `inventory_categories`, `inventory_suppliers`,
  `inventory_product_prices`;
- `shared_sheet_sessions`, `sync_events`, `history_entries`,
  `product_price_summary`;
- `pos_catalog_import_batches`, sales/ledger/stock movement, `audit_logs`;
- `shops`, `shop_devices`, `pos_device_credentials`, `pos_sessions`,
  `staff_accounts`, `shop_inventory_sources`;
- RPC membership/device/sync/recovery e RPC service-only;
- `/api/shop/product-images/*`, bucket `product-images`, upload URL e signed URL
  operative;
- ogni SQLite/Room/SwiftData locale dei sistemi operativi.

Il divieto vale anche quando una superficie legacy possiede grant `anon`. Non è ammesso
fallback dalla futura query Storefront a una tabella della denylist.

## Source-of-truth risultante

| Dominio | Stato osservato | Decisione target |
|---|---|---|
| Catalogo operativo | Android/iOS possono originare mutazioni offline; Admin/Supabase mantiene lo stato condiviso; POS conserva una cache riconciliata | Il projector Admin produce un read model Storefront separato |
| Prezzi | Purchase/retail e history sono operativi; history è append-only | Costo mai pubblico; prezzo/promozione cliente sono server-authoritative e rivalidabili |
| Stock | Inventory count può aggiornare snapshot; il POS origina movimenti vendita offline | Availability pubblica è una proiezione server-side, non `stock_quantity` grezzo |
| Immagini | Record/versione finalizzata e oggetto remoto sono autoritativi; cache mobile best-effort; POS non implementato | Pipeline Admin pubblica soltanto riferimenti pubblici approvati |
| Ordine/vendita | Il Client non ha ancora ordine runtime; il POS origina la vendita fiscale | Ordine cliente e vendita fiscale restano entità/eventi distinti con handoff esplicito |

## Limiti globali

- Nessun comportamento production è stato verificato o modificato.
- Nessuna query dati reali o mutazione remota è stata eseguita.
- L'audit prova topologia e responsabilità correnti, non la correttezza completa di ogni
  policy RLS storica.
- Il read model Storefront, la sua allowlist fisica e le API non esistono ancora.
- La migration authority Admin è una decisione supportata da provenance Git, pipeline
  e linked parity; non autorizza TASK-003 ad applicare schema.
