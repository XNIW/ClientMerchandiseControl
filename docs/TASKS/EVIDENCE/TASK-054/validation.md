# Verifiche TASK-054

## Provenance

Client base `493c2c9bc73c2788e97d4141a4fe01216dc8a39a`, candidato sul branch
`codex/client-functional-audit`; Admin SQL `fe4907adc51ff842720e1c7eb36aa05e0fa53cb8`.
Gli hash del revision set e le ricevute Git/CI finali sono nel README di evidence.
Ambiente host: Mac Apple M3 Max arm64, macOS 27.0 build26A428, Flutter 3.44.8
`058e0af2c2`, Dart 3.12.2. Test flutter_test/debug, dataset sintetici versionati;
benchmark host senza rete business. I risultati non sono misure release su telefono.

Log completi fuori Git, anche conservati in `~/.codex/outputs/client-functional-audit/evidence/`; nessuna credenziale o dato
cliente in evidence. Exit0 TAP è accettato soltanto dopo conteggio e assenza `not ok`.

## Registro locale

| Verifica / comando | Atteso | Osservato | Esito / exit |
|---|---|---|---|
| `scripts/check.sh` con Flutter `--no-version-check` | gate completi | source contract, security, governance, architecture, localizzazione, metadata e release source PASS; primo analyze segnala2 braces, corrette | FAIL / 1 iniziale, non presentato come gate completo PASS |
| `dart format --output=none --set-exit-if-changed .` | zero differenze | 344 file,0 cambiamenti dopo formatter | PASS / 0 |
| `flutter --no-version-check analyze --no-pub` finale | zero issues | No issues found | PASS / 0 |
| `flutter test --coverage --exclude-tags performance` | tutta la suite | 843 PASS,2 golden FAIL sul candidato6353c9b:6 px checkout e18 px tracking su macOS 27 | FAIL / 1; golden non aggiornati |
| due test `--name golden` con tutti i sorgenti runtime ripristinati temporaneamente da HEAD base, poi restituiti al candidato | distinguere regressione | stessi2 fallimenti, stessi conteggi pixel | FAIL / 1 baseline; limite locale confermato |
| suite funzionale `--no-pub --coverage --exclude-tags performance --name '^(?!golden)'` | comportamento non visuale |840/840 PASS prima dell'ultima regressione purge-cache | PASS / 0, non sostituisce golden |
| delivery_context + customer_notifications + after_sales sul candidato finale | race, revoca, dispose, errori repository |39/39 PASS; include purge cache fallito con errore autorizzazione ancora visibile | PASS / 0 |
| `CMC_TASK034_REPEAT_COUNT=5 bash scripts/test-task034-resilience-repeat.sh` | race canoniche ripetibili |5×14=70 PASS | PASS / 0 |
| `flutter test --tags performance --concurrency=1` | budget invariati |10/10 PASS prima/dopo | PASS / 0 |
| `check-backend-compatibility.py --source-only` |55 consumer allineati |55/55, runtime NOT_RUN | PASS / 0 |
| `test-backend-compatibility.py` | rifiuto drift e artifact non coerente |11 test, incluse varianti signature/grant/body/history e3 ABI mancanti/diverse/duplicate | PASS / 0 |
| `bash scripts/test-governance-release-train.sh` dopo il fix della fixture storica | fixture TASK-040 indipendente da nuovi task bloccati | 101/101 fixture PASS; prima falliva dopo il commit dello stato BLOCKED di TASK-054 | PASS / 0 locale; nuova CI da verificare |
| gate snapshot SQL isolato |55 firme/grants/body corrispondenti |PASS scope=snapshot_only | PASS / 0, history ricostruzione non ricevuta CLI |
| gate snapshot metadata staging | rilevare incompatibilità reale |23 missing_rpc,2 missing_migration | FAIL / 1; runtime non compatibile |
| gate `--live` senza connessione autorizzata | niente falso PASS |prerequisite=CMC_BACKEND_PGSERVICE_and_artifact_config | BLOCKED / 2 |
| Admin foundation `node --test tests/foundation/client-commerce-journey-v1.test.mjs` |8 contratti/superfici |8/8 PASS | PASS / 0 |
| Admin typegen completo isolato + `npm run typecheck` |schema-wide allineato |incompatibilità nullability in più domini | FAIL / 2; P3 non chiuso |
| Admin candidate additivo commerce + `npm run typecheck` |nessun cast nuovo, tipi mancanti aggiunti |typecheck completo PASS nella copia isolata | PASS / 0; integrazione NOT_RUN |
| `git apply --check` patch Admin sul checkout canonico readonly |patch applicabile |nessun errore | PASS / 0; nessuna scrittura Admin |
| Android debug build |APK development |primo tentativo interrotto143 durante download Gradle 9.1.0; mirror ufficiale timeout28 dopo90s/3,1MiB di221MiB | BLOCKED toolchain locale, nuova CI da verificare |
| iOS simulator debug build |app compilata |Xcode 27 rifiuta target minimo14.0; build canonica exit1 | FAIL / 1 locale |
| smoke shell Android/iOS |avvio e interazione effettivi |iOS: app_shell_smoke_test PASS / 0, interazione reale; Android bloccato dal toolchain | PASS iOS diagnostico / BLOCKED Android |
| release AAB/APK/iOS unsigned |artifact e preflight distinti |eseguiti dai job CI del commit della PR; nessuna build firmata o upload | NOT_RUN locale; esito remoto nella ricevuta finale |
| fisico, signing/store upload, payment/refund/push reale |collaudo reale autorizzato |prerequisiti/mandato assenti | BLOCKED o NOT_RUN per scope, nessun PASS |

`--no-version-check` evita il git fetch automatico del SDK Flutter installato;
versione/lockfile restano invariati. Due primi pub-get sono stati interrotti sui soli
processi della run; pub-get offline con enforce-lockfile poi PASS. Nessun upgrade.
I primi test parallelizzati hanno conflitto sul build-hook sqlite; rieseguiti seriali
con `--no-pub`. I tentativi di harness falliti non sono conteggiati come PASS.

## Suite SQL isolate

Tutte usano `supabase/tests/<nome>.sql` canonico Admin con
`psql -v ON_ERROR_STOP=1 -At`, fixture sintetiche e rollback dei test.

| Suite | Assertion | Esito / exit |
|---|---:|---|
| client_commerce_journey_v1 | 55 | PASS / 0 |
| storefront_delivery_tracking_v1 | 60 | PASS / 0 |
| storefront_v1_admin_images | 43 | PASS / 0 |
| storefront_v1_admin_orders | 34 | PASS / 0 |
| storefront_v1_admin_promotions | 23 | PASS / 0 |
| storefront_v1_admin_publications | 56 | PASS / 0 |
| storefront_v1_catalog_performance | 3 | PASS / 0 |
| storefront_v1_catalog_projection | 48 | PASS / 0 |
| storefront_v1_checkout_fulfillment | 57 | PASS / 0 |
| storefront_v1_customer_cart | 98 | PASS / 0 |
| storefront_v1_customer_devices | 58 | PASS / 0 |
| storefront_v1_customer_order_history | 30 | PASS / 0 |
| storefront_v1_customer_orders | 35 | PASS / 0 |
| storefront_v1_customer_payments | 37 | PASS / 0 |
| storefront_v1_customer_profiles_addresses | 64 | PASS / 0 |
| storefront_v1_customer_timezone | 13 | PASS / 0 |
| storefront_v1_milestone4_e2e | 40 | PASS / 0 |
| storefront_v1_order_notifications | 40 | PASS / 0 |
| storefront_v1_pos_order_handoff | 40 | PASS / 0 |
| storefront_v1_public_api | 53 | PASS / 0 |
| storefront_v1_public_availability | 44 | PASS / 0 |
| storefront_v1_reservation_holds | 54 | PASS / 0 |
| storefront_v1_schema_rls | 49 | PASS / 0 |

Totale: **1.034 assertion,23 suite**. Seed e bootstrap corretti sono descritti nel
[piano backend](backend-reconciliation.md); nessun test SQL sullo staging.

## Performance prima/dopo

Baseline runtime493c2c9 ripristinata temporaneamente nei quattro file modificati:
`git diff 493c2c9 --name-only -- lib` vuoto durante la misura; harness prestazionali
invariati. Candidato runtime6353c9b ripristinato prima della seconda misura.
Questa coppia finale sostituisce le misure esplorative precedenti del worktree.
5 warm-up e30 campioni per i benchmark che riportano percentili; identici harness,
dataset e budget TASK-019/034/037. Host condiviso con altri processi di sviluppo:
variazione osservata, nessun miglioramento attribuito arbitrariamente al fix.
Valori tripli p50/p95/p99 in microsecondi, salvo dove indicato.

| Metrica/dataset | Prima | Dopo | Controllo |
|---|---:|---:|---|
| Home cache |266/417/424 |224/337/348 |1 cache read,1 live fetch fake |
| Catalogo small1000 |843/1537/8903 |871/1613/6822 |250 categorie |
| Search small1000 |1041/1487/1702 |1031/1112/1163 |SQLite locale |
| Catalogo medium10000 |614/896/959 |581/767/770 |cursore bounded |
| Search medium10000 |3283/3606/3616 |2578/3585/4673 |SQLite locale |
| Catalogo extreme25000 |696/830/866 |593/728/956 |budget canonico PASS |
| Search extreme25000 |7623/8236/8268 |5544/6784/7316 |budget canonico PASS |
| Open/write cache small, ms |774/104 |494/86 |una misura setup per run |
| Open/write medium, ms |2/298 |1/274 |una misura setup per run |
| Open/write extreme, ms |1/618 |1/610 |una misura setup per run |
| Decode image1024→480 |8738/9176/9543 |8553/8729/8850 |dimensione decode bounded |
| Tracking publication |299/507/561 |289/516/525 |1 RPC/1subscription |
| Catalog append24 |285/448/525 |254/507/527 |36 richieste complessive |
| Detail render |52502/64742/70714 |39878/53209/53289 |1 RPC/navigation |
| Checkout navigation |12697/19020/19235 |11621/14689/15361 |0read extra/navigation |
| Guest cart100 read |461/801/878 |479/805/839 |SQLite |
| Guest cart100 mutation |697/1014/2358 |755/1018/2611 |SQLite |
| Order cache50 write |708/1096/1782 |588/1097/1757 |17105 byte |
| Order cache50 read |911/1668/2211 |801/1586/2384 |bounded |
| Order selector500 |90/186/453 |84/176/317 |derivazione locale |

Launch reale, primo contenuto da rete staging, memoria dispositivo release, rete reale,
query live sotto carico: NOT_RUN, distinti dagli smoke development e dalle query SQL
isolate. Nessun budget aumentato, nessun refactor prestazionale senza difetto misurato.

## E2E originali, matrice preservata

La cronologia versionata Client/Admin conserva gli identificatori E2E-01…25 e l'esito
BLOCKED, ma non le descrizioni originali dei25 scenari. Ricerca nei task, evidence e
storia Git non le ha recuperate; richiesta la fonte all'utente. Non sono state inventate
etichette o sostituiti questi scenari con smoke più facili. Quanto segue aggiorna la
classificazione operativa lasciando immutata la tabella storica nel task.

Per ogni riga: Client base493c2c9/candidato presente branch; Adminfe4907ad; backend
staging condiviso; piattaforma Android/iOS prevista ma non esercitata; fixture originale
non recuperata/non creata; atteso=criterio originale da recuperare;
osservato=23 RPC assenti e prova non avviata. Evidence: metadata reconciliation, fonte
storica TASK-054 e TASK-157 Admin. Owner sblocco: utente/backend owner + reviewer.

| ID originale | Stato | Impedimento |
|---|---|---|
| E2E-01 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-02 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-03 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-04 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-05 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-06 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-07 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-08 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-09 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-10 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-11 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-12 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-13 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-14 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-15 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-16 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-17 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-18 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-19 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-20 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-21 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-22 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-23 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-24 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |
| E2E-25 | BLOCKED | fonte scenario originale + migration/mandato staging + login reale |

Le regressioni R01–R12 e il caso storage di R03 sono aggiunte autonome della run,
con atteso/osservato nella matrice finding. Non vengono rinominate E2E-01…25.

## Smoke iOS del candidato finale6353c9b

Comando effettivo: `XCODE_XCCONFIG_FILE=/tmp/cmc-functional-audit/ios-simulator-audit.xcconfig flutter --no-version-check test --no-pub integration_test/app_shell_smoke_test.dart -d EA223A82-1F51-40E7-9B2E-441686CA193A --reporter expanded`.
Il file xcconfig locale imposta soltanto `IPHONEOS_DEPLOYMENT_TARGET=15.0`: Xcode 27
rifiuta14.0, mentre il deployment target versionato e il preflight release rimangono14.0.
Nessuna elevazione del minimo supportato nel prodotto. Questa deviazione rende lo smoke
una verifica diagnostica del runtime development, non un PASS della build canonica.

Prima build simulator63,1 s su447d2a8; ripetizione finale6353c9b: build21,3s; test11s,1/1 PASS, exit0. Simulator dedicato iPhone17/iOS 27:
cold launch, cinque destinazioni, back/tab state, light/dark, text scale200%,
portrait/landscape, semantics/target touch e assenza di dati commerciali fittizi.
Supabase non inizializzato nel development non configurato. Nessun login/business live.
Warning: google_maps_flutter_ios non supporta ancora Swift Package Manager; CocoaPods
usato dal progetto. Nessun aggiornamento plugin o modifica del target per aggirare gate.

Controllo aggiuntivo del candidato447d2a8: due nuove prove con preview e read/refresh
completati in ordine invertito riproducono loading permanente. Corretto il coordinamento
fra lettura e preview;39/39 focused e analyzer PASS sul fix successivo. La prova red
appartiene al candidato447d2a8, non alla baseline493c2c9.

Il SQL emesso dal gate è stato eseguito anche attraverso il connector readonly sul
ref autorizzato:32 RPC/145 migration lette realmente, snapshot gate FAIL / 1 con23+2
assenze. Non è stato usato un pg_service privilegiato né fatto un apply.

I risultati finali della CI sono separati dai limiti locali: il confronto SHA, job,
step e annotation viene eseguito dopo la conclusione delle run e riportato nell'handoff.
Il checkout resta BLOCKED/EXECUTION; un job di build verde non abilita E2E o distribuzione.
