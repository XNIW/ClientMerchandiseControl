# TASK-033 — Evidence remediation sicurezza mirata

## Provenance

- Scan canonica: `da548633-6547-4157-a55f-8e8ab1b11f0d`.
- Revisione analizzata: `0668ea7adb0a0b55946024b73506ebd28cd1b53a`.
- Report sigillato SHA-256:
  `6de4206f7e4aaa3432ccebd8b44884221bad55f534ce31be5e01b29a05c03f11`.
- Coverage scan: `complete`, 61/61 candidati; deferred 0.
- Findings reportabili: 18/18, di cui 2 medium e 16 low.
- Metodo: correzione e validazione puntuale del report esistente; nessuna nuova
  discovery, threat model o scansione repository-wide.
- Production, dati reali e credenziali privilegiate: non acceduti e non modificati.

## Matrice finding → fix → regressione

| # | ID canonico | Severità | Controllo post-fix | Regressione primaria | Esito |
|---|---|---|---|---|---|
| 1 | `report-446fa0ff70562186` | medium | Intento logout ridondante e durevole prima dei side effect; restore negato; rimozione solo dopo login esplicito persistito | `test/core/backend/secure_supabase_auth_storage_test.dart`, `test/features/auth/application/auth_controller_test.dart` | FIXED_VALIDATED |
| 2 | `report-dfa55428c0611893` | medium | Checkout vincolato a owner, shop e generation prima/dopo ogni await, persistenza e publish | `test/features/checkout/application/checkout_controller_test.dart` | FIXED_VALIDATED |
| 3 | `report-74a8a0a2189f38f5` | low | Fencing order cache prima e dopo save; risultati stale non entrano nello store/UI | `test/features/orders/application/customer_order_controller_test.dart` | FIXED_VALIDATED |
| 4 | `report-76e05d822ccc1704` | low | Logout globale; revoca fallita in coda bounded durevole e retry al bootstrap | `test/features/auth/data/supabase_auth_repository_test.dart`, `test/core/backend/secure_supabase_auth_storage_test.dart` | FIXED_VALIDATED |
| 5 | `report-1ab47c7e59be364c` | low | Diniego auth remoto purga lista, dettaglio, memoria e cache ordine | `test/features/orders/application/customer_order_controller_test.dart` | FIXED_VALIDATED |
| 6 | `report-5d571837c79819ba` | low | Workflow cart queue/in-flight vincolato a subject, shop e generation fino ai sink | `test/features/cart/application/cart_controller_test.dart` | FIXED_VALIDATED |
| 7 | `report-afb0f0bec1b37d50` | low | Revoche device multiple preservate per owner; store v2 atomico e migrazione v1 | `test/features/customer_devices/shared_preferences_customer_device_store_test.dart`, `test/features/customer_devices/customer_device_sign_out_coordinator_test.dart` | FIXED_VALIDATED |
| 8 | `report-895997caec63a375` | low | Hold controller vincolato a owner/shop/generation attraverso RPC, save e publish | `test/features/reservations/reservation_hold_controller_test.dart` | FIXED_VALIDATED |
| 9 | `report-d2d6348d5b02b117` | low | Dialog address/export/confirm chiusi su logout, expiry o cambio subject | `test/features/account/customer_account_panel_test.dart` | FIXED_VALIDATED |
| 10 | `report-215865570ca30925` | low | Callback accettata solo con flow attivo bounded; exchange cancellabile con deadline | `test/features/auth/application/auth_controller_test.dart`, `integration_test/auth_callback_flow_test.dart` | FIXED_VALIDATED |
| 11 | `report-53ea024068664f2c` | low | Fetch immagini limitato alla exact Supabase origin e al bucket/path pubblico | `test/features/storefront/presentation/storefront_verified_image_loader_test.dart` | FIXED_VALIDATED |
| 12 | `report-df0c3a9762ed3df1` | low | Terminazione automatica centralizzata attraversa cleanup reservation/order/device | `test/features/auth/application/auth_controller_test.dart`, `test/features/account/account_auth_states_test.dart` | FIXED_VALIDATED |
| 13 | `report-e7bd99cda2432a0d` | low | Timeout, redirect OFF, MIME image, limite stream 5 MiB e verifica SHA-256 prima del rendering/cache | `test/features/storefront/presentation/storefront_verified_image_loader_test.dart` | FIXED_VALIDATED |
| 14 | `report-5fc1125d909fa1f7` | low | Risposta hold verificata per operation, hold, shop, publication e quantity | `test/features/reservations/supabase_reservation_hold_repository_test.dart` | FIXED_VALIDATED |
| 15 | `report-8f2e1ea2b1584229` | low | Status/register/revoke device vincolati all'identity lifecycle; completion stale scartata | `test/features/customer_devices/customer_device_controller_test.dart` | FIXED_VALIDATED |
| 16 | `report-10da5c048bfdebfc` | low | Risposta Storefront home rifiutata se lo shop non coincide con quello configurato | `test/features/storefront/data/supabase_storefront_repository_test.dart` | FIXED_VALIDATED |
| 17 | `report-76236a6629a9150c` | low | Quote/order verificati contro ID, shop, cart/version, selection e payment richiesti | `test/features/checkout/data/supabase_checkout_repository_test.dart` | FIXED_VALIDATED |
| 18 | `report-19d142e259ff9cb5` | low | Handler OAuth privato rimosso; Google sempre OFF senza dominio verificato; route customer-sensitive negate sullo scheme privato | `test/core/backend/auth_native_configuration_test.dart`, test mapper Kotlin/Swift e `test/features/deep_links/storefront_deep_link_test.dart` | FIXED_VALIDATED |

## Bug direttamente collegati

- Il fencing condiviso auth ora impedisce cleanup incompleto anche per terminazioni
  automatiche, non soltanto per tap logout.
- Il carrello non possiede un digest immagine nel contratto persistito: per evitare un
  fetch non verificabile usa il placeholder locale finché il contratto non fornisce il
  digest, senza fallback di rete.
- Il lifecycle device normalizza lo stato locale sul nuovo owner e conserva le revoche
  precedenti invece di sovrascriverle.
- La review ha rilevato che il primo buffer immagine verificato era condiviso con la
  cache mutabile; il FIX restituisce copie difensive e la regressione prova che una
  mutazione del consumer non può contaminare letture successive.
- La re-review auth ha rilevato un purge incondizionato nel drain bootstrap; il FIX
  preserva una sessione valida quando non esistono revoche e blocca un nuovo OAuth
  finché la coda precedente non è stata realmente drenata.

## Gate locali eseguiti

| Gate | Comando / evidenza | Esito |
|---|---|---|
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test` | PASS |
| Analyze | `flutter analyze` | PASS |
| Suite Flutter | `flutter test --coverage -r compact`: 566 test | PASS |
| Coverage | `12076/15541`, 77,70% | PASS |
| Android native | Gradle 9.1 `:app:testDebugUnitTest` | PASS |
| iOS native | `xcodebuild test ... CODE_SIGNING_ALLOWED=NO`: 4/4 | PASS |
| Android build | `flutter build apk --debug` | PASS |
| iOS build | `flutter build ios --simulator --debug` | PASS |
| Android smoke | `app_shell_smoke_test.dart` su API 35: 1/1 | PASS |
| iOS smoke | `app_shell_smoke_test.dart` su iOS 26.5: 1/1 | PASS |
| Diff whitespace | `git diff --check` | PASS |
| Gate aggregato | `bash scripts/check.sh`: exit 0 | PASS |

Gli smoke hanno esercitato avvio reale, quattro destinazioni, back/tab state, tema
chiaro/scuro, text scale 200%, portrait/landscape, semantics e profilo development
offline. I simulatori sono stati arrestati al termine.

## Vincolo funzionale intenzionale

Il repository non contiene un dominio HTTPS posseduto e verificato. Per eliminare la
collisione del private URI scheme, Google OAuth è quindi indisponibile nei profili
distribuibili: staging e production rifiutano `GOOGLE_AUTH_ENABLED=true`; il redirect
`.invalid` è un sentinel non instradabile. La riattivazione richiede una decisione
futura con App Links/Universal Links verificati su entrambi gli OS.

## Validazione indipendente

La validazione post-fix deve essere eseguita sul diff candidato e sullo SHA pubblicato,
senza riusare i claim dell'Execution. Per ciascuno dei 18 ID deve confermare che source,
control e sink del report non siano più collegabili e che la regressione indicata passi.
