# TASK-054 — Acceptance operativa, revisione R

Nuova revisione autorizzata dal mandato successivo del 2026-09-28. Non ricostruisce né certifica retroattivamente E2E-01…25: la loro provenance assente e lo stato storico BLOCKED restano nel task. Fonti: TASK-050–053, CA del nuovo emendamento TASK-054, test Client/Admin indicati. La ricerca mirata già registrata non è stata ripetuta. Questa matrice deve essere approvata dai reviewer prima del closeout.

## Protocollo comune obbligatorio a ogni caso

Piattaforme: Android e iOS, salvo confronto golden macOS e comandi SQL/CI esplicitamente indicati. Staging esclusivo `jpgoimipbothfgkokyvm`; locale isolato non lo attesta. Fixture: namespace univoco `cmc054r-<run UTC>-<caso>`, UUID generati per la run; nessuna identità reale nelle evidence. Setup: manifest degli ID creati fuori Git con permessi0600, owner A/B e shop S/T sintetici creati tramite percorso autorizzato, snapshot dei soli conteggi iniziali; nessun riuso di record preesistenti. Provider/device richiedono i prerequisiti specifici. Teardown di OGNI caso: annullare/rilasciare solo ordini/hold/casi della run attraverso API autorizzate, rimuovere sole fixture create in ordine dipendenze, revocare sessioni e svuotare namespace locali; ripetere cleanup e verificare zero residui e conteggi preesistenti invariati. Se un record audit è append-only, registrare ID e retention autorizzata senza cancellazione diretta. I test pgTAP usano transazione e ROLLBACK. Un mancato setup impedisce l’esecuzione: non si sostituisce un pilota/shop.

Ogni esecuzione deve registrare SHA Client/Admin, build/config hash, versione OS/device, RPC target e timestamp, comando+exit, assert riusciti/falliti, fixture/cleanup sanitizzati. Risultati ammessi PASS/FAIL/NOT_RUN/BLOCKED. Colonna dei test indica il collegamento al requisito, non certifica che ogni passo live sia già automatizzato. Il risultato complessivo resta NOT_RUN finché non eseguito end-to-end; le parti deterministiche sono rendicontate separatamente in validation/residuals.

## E2E-054-R01 — Ingresso guest e capacità effettive

- **Fonte/requisito:** TASK-054 CA-O1; manifest RPC.
- **Precondizioni:** Guest, configurazione staging approvata e 55 contratti presenti.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Avviare senza sessione; Home/catalogo/dettaglio; confrontare risposta readiness con metadata live; ripetere con RPC assente nel transport controllato.
- **Atteso/assert:** Nessun accesso inventory; capacità assente produce errore esplicito, mai lista vuota/successo. Assert su 55 firme/grants/body/history e UI readiness.
- **Test correlati:** `integration_test/backend_readiness_smoke_test.dart; test/features/shell/backend_readiness_banner_test.dart`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging + deterministico.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R02 — Sessione e callback del provider

- **Fonte/requisito:** TASK-054 CA-O3; TASK-050 accesso.
- **Precondizioni:** Dominio approvato, associazioni native e allow-list Supabase verificate; tester autorizzato.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Login e annullamento; callback cold/warm; riaprire app; refresh; callback con host/path/state non validi.
- **Atteso/assert:** Solo callback esatta completa PKCE; cancellazione non crea sessione; refresh mantiene owner; invalidi respinti senza dati/log sensibili. Assert sessione e navigazione una volta.
- **Test correlati:** `integration_test/auth_native_callback_delivery_test.dart; integration_test/auth_callback_flow_test.dart; test/core/config/oauth_activation_test.dart`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; provider live + deterministico.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R03 — Logout, revoca e A→B→A con richieste in volo

- **Fonte/requisito:** TASK-050 CA5; TASK-054 §10.
- **Precondizioni:** Due owner sintetici, risposte ritardabili e cache per owner.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Avviare load/mutation/paginazione; logout o revoca; entrare B poi A; completare risposte vecchie; dispose.
- **Atteso/assert:** Nessun risultato/notifica/cache della vecchia epoch; errore autorizzazione conserva priorità anche se purge fallisce. Assert stato, store, chiamate e assenza callback dopo dispose.
- **Test correlati:** `test/features/account/application/customer_account_controller_test.dart; test/features/orders/application/customer_order_controller_test.dart; test/features/delivery_context/delivery_context_lifecycle_test.dart`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging + deterministico.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R04 — CRUD indirizzo e default

- **Fonte/requisito:** TASK-050 CA1,CA2.
- **Precondizioni:** Owner A/B; indirizzo sintetico v2.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Creare indirizzo completo e default; modificare versione; inviare versione obsoleta; cambiare strada di indirizzo con pin; eliminare e rileggere.
- **Atteso/assert:** Versione server monotona, default unico; conflitto non sovrascrive; edit geografia invalida coordinate/source; nessun indirizzo B. Assert RPC v2 e rilettura server.
- **Test correlati:** `integration_test/customer_account_flow_test.dart; test/features/account/customer_account_panel_test.dart`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging + deterministico.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R05 — Ricerca, resolve, reverse e pin

- **Fonte/requisito:** TASK-050 CA2; TASK-054 §8.
- **Precondizioni:** Provider approvato configurato; consenso GPS separato.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Cercare e scegliere suggerimento nell'editor; attivare GPS per aprire il pin, spostarlo e confermare; reverse; modificare testo; risposte fuori ordine.
- **Atteso/assert:** Ultima query vince; resolve solo del batch corrente; pin confermato conservato; nessuna autorizzazione zona dal geocoder; provider non riceve identità/token. Assert transport e payload manuale finale.
- **Test correlati:** `test/features/delivery_context/photon_address_provider_test.dart; test/features/delivery_context/address_provider_adapters_test.dart`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; provider live + transport.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R06 — Delivery/pickup e concorrenza contesto

- **Fonte/requisito:** TASK-050 CA3,CA4; TASK-051.
- **Precondizioni:** Shop con pickup e delivery sintetici.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Selezionare delivery A, subito pickup, completare risposta A in ritardo; ripetere preview sovrapposte e cambio shop.
- **Atteso/assert:** Home/carrello/checkout mostrano stesso contesto corrente; nessun sovrascrivere da shop/epoch precedente. Assert versione e ordine delle richieste.
- **Test correlati:** `test/features/delivery_context/delivery_context_lifecycle_test.dart; test/features/delivery_context/delivery_context_screen_test.dart`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging + deterministico.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R07 — Zona, slot, costo e contesto stale

- **Fonte/requisito:** TASK-050 CA3; TASK-051 CA1.
- **Precondizioni:** Zone supportate/non supportate e slot limitati.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Preview fuori zona; indirizzo modificato/eliminato dopo quote; slot esaurito; costo aggiornato.
- **Atteso/assert:** Server decide area/fee/slot; stato stale blocca submit e richiede nuova validazione; quote conserva snapshot coerente. Assert rifiuti e nessun ordine.
- **Test correlati:** `test/features/checkout/application/checkout_controller_test.dart; Admin storefront_v1_checkout_fulfillment.sql`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging + SQL isolato.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R08 — Carrello guest persistente e merge

- **Fonte/requisito:** TASK-051; requisiti carrello ereditati.
- **Precondizioni:** Guest locale e owner A con carrello server.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Aggiungere articoli offline; riavviare; login; merge; ripetere chiave; logout/cambio B.
- **Atteso/assert:** Quantità riconciliate una volta, persistono nel namespace corretto; niente righe/chiavi A in B. Assert SQLite, RPC e rilettura.
- **Test correlati:** `integration_test/customer_cart_flow_test.dart; test/features/cart/application/cart_controller_test.dart`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging + deterministico.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R09 — Prezzi, disponibilità e rimozioni

- **Fonte/requisito:** TASK-051 CA1,CA3.
- **Precondizioni:** Prodotti pubblicati, prezzo/stock modificabili da operatore.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Carrello con tre righe; cambiare prezzo, esaurire una, rimuovere pubblicazione altra; aggiornare checkout.
- **Atteso/assert:** Diff esplicite, totale server; righe non valide non ordinate silenziosamente; inventory privato non esposto. Assert payload, totale e catalogo pubblico.
- **Test correlati:** `test/features/cart/application/cart_controller_test.dart; Admin storefront_v1_public_availability.sql`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging + SQL isolato.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R10 — Checkout pickup v2

- **Fonte/requisito:** TASK-051 CA2,CA3.
- **Precondizioni:** Owner A, pickup valido, stock e slot.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Creare quote tramite customer_checkout_quote_create_v2; hold; confermare ordine e rileggere Admin.
- **Atteso/assert:** Ordine unico owner/shop, snapshot pickup, prezzo/slot/hold coerenti; RPC consumate realmente presenti. Assert ID, quantità e stati Admin.
- **Test correlati:** `integration_test/customer_checkout_live_smoke_test.dart; Admin storefront_v1_checkout_fulfillment.sql`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging autenticato.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R11 — Checkout delivery v2

- **Fonte/requisito:** TASK-051 CA2,CA3.
- **Precondizioni:** Indirizzo v2 e contesto corrente supportato.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Quote v2 con address/context version; hold; submit; modificare indirizzo dopo ordine; rileggere ordine.
- **Atteso/assert:** Snapshot fulfillment immutabile, fee e zona server; nessun indirizzo attuale sostituisce quello ordinato. Assert righe ordine/Admin e contesto versione.
- **Test correlati:** `integration_test/customer_checkout_live_smoke_test.dart; Admin client_commerce_journey_v1.sql`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging autenticato.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R12 — Hold concorrenti, scadenza e notifiche

- **Fonte/requisito:** TASK-051; TASK-054 §4.
- **Precondizioni:** Stock sintetico limitato e due owner; clock/test scadenza supportato.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Due hold sulla stessa disponibilità; scadere/rilasciare; creare secondo hold stesso owner/shop; notificare due volte.
- **Atteso/assert:** Niente oversell; risorse restituite; due hold distinti generano due notifiche, duplicato stesso hold no. Assert concorrenza SQL e indici canonici.
- **Test correlati:** `integration_test/customer_reservation_hold_flow_test.dart; Admin storefront_v1_order_notifications.sql`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging + SQL isolato.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R13 — Idempotenza ordine e risposta persa

- **Fonte/requisito:** TASK-051 CA4.
- **Precondizioni:** Quote/hold validi e trasporto con risposta persa.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Doppio tap e retry stessa attempt; interrompere risposta dopo commit; recovery prima di nuovo submit.
- **Atteso/assert:** Un ordine, un consumo hold/slot, niente doppio effetto POS; recovery legge esito autorevole. Assert conteggi e chiavi.
- **Test correlati:** `test/features/checkout/application/checkout_controller_test.dart; Admin storefront_v1_customer_orders.sql`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging + deterministico.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R14 — Kill/restart e ambiguità

- **Fonte/requisito:** TASK-051 CA4.
- **Precondizioni:** Tentativo persistito e ordine ambiguo.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Chiudere processo tra submit e risposta; riavviare stesso owner; riprendere recovery; poi cambio owner.
- **Atteso/assert:** Nessun nuovo tentativo automatico prima della lettura; draft proprietario; stato pending onesto se rete manca. Assert ordine unico e UI recovery.
- **Test correlati:** `test/features/checkout/data/shared_preferences_checkout_draft_store_test.dart; integration_test/customer_checkout_flow_test.dart`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; emulatore/simulatore staging.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R15 — Metodi pagamento previsti e OFF

- **Fonte/requisito:** TASK-051 CA3; contratto payments.
- **Precondizioni:** COD/pickup abilitati; provider online disabilitato.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Scegliere metodi esposti; tentare route online non configurata; leggere recovery pagamento e transizioni vietate.
- **Atteso/assert:** Solo metodi autorizzati dal server; nessun charge/refund dal Client; online OFF esplicito; non confondere pending con paid. Assert payload e permessi.
- **Test correlati:** `Admin storefront_v1_customer_payments.sql; test/features/checkout/data/supabase_checkout_repository_test.dart`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging + SQL isolato.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R16 — Ordini, stati, timeline e cancellazione

- **Fonte/requisito:** TASK-051 CA5; requisiti ordini.
- **Precondizioni:** Ordini A/B in stati cancellabili/non cancellabili.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Paginare; aprire dettaglio; cambiare stato Admin; cancellare; risposta ritardata durante A→B→A.
- **Atteso/assert:** Stato e timeline coerenti, cancellazione ammessa una volta; cache corrente non riceve pagina vecchia; nessun ordine B. Assert ID/cursori/store.
- **Test correlati:** `integration_test/customer_order_history_flow_test.dart; test/features/orders/application/customer_order_controller_test.dart`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging + deterministico.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R17 — Tracking e indisponibilità provider

- **Fonte/requisito:** TASK-054 §10; requisiti tracking.
- **Precondizioni:** Ordine owner corretto con tracking sintetico, provider OFF/errore.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Aprire tracking; cambiare account/dispose; ricevere update tardivo; fallimento mappa.
- **Atteso/assert:** Solo tracking del proprio ordine; subscription rimossa; fallback stato/timeline, nessuna coordinata reale in log; golden confrontato sul runner macOS.
- **Test correlati:** `integration_test/customer_delivery_tracking_flow_test.dart; test/features/delivery_tracking/delivery_tracking_controller_test.dart`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging + deterministico.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R18 — Inbox, filtri e paginazione

- **Fonte/requisito:** TASK-052 CA1,CA2.
- **Precondizioni:** Notifiche sintetiche oltre una pagina, owner A/B.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Paginare e filtrare non lette; mark read/all; ritardare loadMore; revoca o cambio filtro/sessione.
- **Atteso/assert:** Cursor coerente, dedupe, badge server; niente pagina vecchia o PII di B; errore auth prevale su purge cache. Assert righe, contatori e namespace.
- **Test correlati:** `test/features/customer_notifications/customer_notification_inbox_lifecycle_test.dart; Admin client_commerce_journey_v1.sql`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging + deterministico.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R19 — Consenso e deep link proprietario

- **Fonte/requisito:** TASK-052 CA3; requisiti devices.
- **Precondizioni:** Consenso iniziale OFF, device sintetico, notifiche A/B.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Dare/revocare consenso; registrazione device; aprire link owner/cross-owner e route non ammessa; logout in volo.
- **Atteso/assert:** Nessuna registrazione senza consenso; revoca/disassociazione; route allow-list e owner-check senza accesso privato. Assert payload/route/device-store.
- **Test correlati:** `integration_test/customer_device_flow_test.dart; test/features/customer_notifications/customer_notification_route_controller_test.dart`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging + deterministico.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R20 — Riordino e conferma differenze

- **Fonte/requisito:** TASK-052 CA4,CA5.
- **Precondizioni:** Ordine storico con prezzo attuale diverso e riga rimossa.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Preview riordino; mostrare differenze; annullare; poi confermare e ripetere stessa mutation.
- **Atteso/assert:** Carrello usa prezzo/disponibilità correnti solo dopo consenso, idempotenza e owner; nessuna copia di snapshot scaduto. Assert preview/apply/count.
- **Test correlati:** `test/features/orders/application/customer_reorder_attempt_test.dart; Admin client_commerce_journey_v1.sql`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging + deterministico.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R21 — Assistenza righe ordine e Admin

- **Fonte/requisito:** TASK-053 CA1,CA2.
- **Precondizioni:** Ordine sintetico eleggibile, operatori same/cross-shop.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Caricare righe RPC; scegliere qty/reason; allegare max3 fixture innocue; inviare; aprire/gestire Admin; tentare cross-shop e refund dal Client.
- **Atteso/assert:** Solo righe/quantità eleggibili, evidence privata e ticket owner; Admin RBAC; Client non approva rimborso; effetti e audit riletti. Assert case/line/event/grants.
- **Test correlati:** `test/features/after_sales/supabase_customer_after_sales_repository_test.dart; Admin client_commerce_journey_v1.sql`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging Client+Admin.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R22 — Recensioni verificate e moderazione

- **Fonte/requisito:** TASK-053 CA3.
- **Precondizioni:** Acquisto eleggibile A, B senza acquisto, moderatore shop.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Inviare review; duplicare; edit; tentare B; moderare; leggere aggregate/public reviews.
- **Atteso/assert:** Unicità e acquisto verificato server; solo pubblicate contribuiscono a aggregate, body non moderato non pubblico. Assert owner/RLS/contatori.
- **Test correlati:** `test/features/reviews/supabase_customer_review_repository_test.dart; Admin client_commerce_journey_v1.sql`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging + SQL isolato.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R23 — Ricerca assistita e deep link

- **Fonte/requisito:** TASK-053 CA4,CA5.
- **Precondizioni:** Catalogo pubblico sintetico e cronologia locale.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Digitazione rapida, submit prima della risposta, dispose; 11 ricerche; offline; logout; link prodotto/shop validi e invalidi.
- **Atteso/assert:** Debounce/obsoleti cancellati, max10 history locale, cancellabile; submit non ripopola suggerimenti tardivi; route valida senza inventory write. Assert richieste/stato/store.
- **Test correlati:** `test/features/catalog/search_assist_test.dart; test/features/deep_links/storefront_deep_link_test.dart`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging + deterministico.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R24 — Authoring operativo e visibilità pubblica

- **Fonte/requisito:** TASK-054 §10; confine Storefront.
- **Precondizioni:** Shop/pilota TEST autorizzato, Android/iOS/Admin coordinati.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Creare/modificare prodotto e immagine nelle superfici operative; pubblicare e impostare prezzo Admin; rileggere Client; tentare mutation inventory dal ruolo Client.
- **Atteso/assert:** Visibilità dipende dalla proiezione pubblicata, update/versione immagini coerenti; Client non scrive inventory; History Entry/auto-sync/POS fiscale invariati. Assert sorgente/proiezione/catalogo e RBAC.
- **Test correlati:** `Admin storefront_v1_admin_publications.sql; storefront_v1_admin_images.sql; storefront_v1_pos_order_handoff.sql`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging cross-platform.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R25 — Reconnect e isolamento trasversale

- **Fonte/requisito:** TASK-050 CA5; TASK-054 §4,§10.
- **Precondizioni:** Owner A/B, shop S/T, cache e operazioni pendenti sintetiche.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Offline→reconnect durante context/cart/order/inbox/aftersales; revocare; tentare ID owner/shop altrui via ruoli anon/customer/operator.
- **Atteso/assert:** Errori onesti e retry idempotente; isolamento anche server; niente cache PII residua/privilegi ampliati. Assert permessi e riletture, non solo HTTP200.
- **Test correlati:** `test/features/delivery_context/delivery_context_lifecycle_test.dart; test/features/after_sales/customer_after_sales_controller_test.dart; Admin storefront_v1_schema_rls.sql`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; staging + SQL isolato.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R26 — Fallback indirizzo e GPS

- **Fonte/requisito:** TASK-050 CA2; TASK-054 §8.
- **Precondizioni:** Provider OFF/timeout/429, permesso negato e fix GPS impreciso.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Aprire editor in ciascuna condizione; completare tutti i campi manuali; negare GPS; accuracy>250m; annullare pin; logout durante search/reverse.
- **Atteso/assert:** Salvataggio manuale completo; nessun GPS silenzioso; impreciso richiede conferma pin o manuale; cooldown senza retry storm; risultati vecchi ignorati. Assert payload/source/accuracy/richieste.
- **Test correlati:** `test/features/delivery_context/photon_address_provider_test.dart; test/features/delivery_context/delivery_context_screen_test.dart`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; transport + dispositivi per GPS.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R27 — Pagamento provider sandbox

- **Fonte/requisito:** TASK-054 R15; confine pagamenti.
- **Precondizioni:** Sandbox e credenziali/canale già autorizzati, nessun denaro reale.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Checkout sandbox; annullamento e callback/webhook; duplicato evento; stato ambiguo; rimborso sandbox solo server/Admin se autorizzato.
- **Atteso/assert:** Stati idempotenti da webhook verificato; Client non si autocertifica paid; niente side effect reale. Assert ricevute sandbox e ordine Admin.
- **Test correlati:** `contratto payments e runbook provider; non implementare simulazione come live`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; provider sandbox.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R28 — Push provider e cold/warm link

- **Fonte/requisito:** TASK-054 R19; confine push.
- **Precondizioni:** Provider/entitlements/canale approvati e device fisico autorizzato.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Consenso; registrazione token; push sintetico; cold/warm; revoca/logout; push precedente e cross-owner.
- **Atteso/assert:** Consegna reale distinta da token mock; nessun payload PII o apertura owner errato; revoca effettiva server e device. Assert ricevuta/consegna/navigazione.
- **Test correlati:** `integration_test/customer_device_flow_test.dart per parte deterministica; ricevute provider da produrre`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; provider live + fisico.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R29 — Artifact, firma e ambiente distribuito

- **Fonte/requisito:** TASK-054 §11.
- **Precondizioni:** Gate verdi; firma e canali interni approvati, backend compatibile corrente.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Validare artifact; varianti firma corrotta/entitlement inatteso/config assente/backend incompatibile; installare interno; rileggere ambiente.
- **Atteso/assert:** Abusi respinti; ricevuta fresca lega commit/config/target; unsigned non è distribuito; nessuna produzione attivata. Assert validator/receipt/installazione.
- **Test correlati:** `scripts/test-android-release-signature.sh; scripts/test-ios-release-validator.sh; scripts/test-backend-compatibility.py`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; CI + canale interno/fisico.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.

## E2E-054-R30 — Smoke nativo e superfici visuali

- **Fonte/requisito:** TASK-054 §6.
- **Precondizioni:** Flutter3.44.8, iOS minimo14 invariato; emulatore/simulatore propri.
- **Setup:** protocollo comune; fixture specifiche descritte nelle precondizioni.
- **Passi:** Avvio guest Android e iOS; tab/navigation/restart; confronto checkout/tracking golden senza tolleranze.
- **Atteso/assert:** Interazione reale distinta da build e commerce; tracking Linux skip esplicito, confronto richiesto macOS; baseline OS27 limitata ai due diff ispezionati. Assert integration test e pixel comparator.
- **Test correlati:** `integration_test/app_shell_smoke_test.dart; due presentation golden test`.
- **Teardown:** protocollo comune, rollback SQL quando applicabile.
- **Piattaforma/ambiente:** Android+iOS; emulatore/simulatore + macOS.
- **Risultato:** NOT_RUN end-to-end della nuova revisione; prove parziali distinte nel registro residui.


## Collegamento eseguibile del mandato UX — 2026-10-01

`integration_test/task054_visual_flow_test.dart` e
`scripts/test-task054-visual.sh --device OWNED_DEVICE_ID|--ios` esercitano41casi
sintetici dei componenti Client, con55capture di superficie/stato. NON sono il
protocollo UI→API→persistenza→Admin→Client comune a R01–R30.
R18 aggiunge `customer_notification_unread_filter_test.dart`: filtro sulle pagine
caricate, letture singole/all e conservazione dei dati. Cursor/loadMore e isolamento
owner restano nei test lifecycle esistenti; l'acceptance live restaNOT_RUN.
R25 aggiunge4regressioni Cart quantity/remove/clear offline senza eccezioni UI e
retry riuscito. R21/R22/R26 aggiungono12widget compatti200% nei quattro locale.
Risultati per piattaforma e limiti sono nell'overlayoperativo, senza cambiarecriteri.
