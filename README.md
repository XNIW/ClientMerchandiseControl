# ClientMerchandiseControl

Applicazione Flutter Android/iOS destinata ai clienti dei negozi dell'ecosistema
Merchandise Control. Il codice include catalogo, account, carrello, checkout,
ordini, consegna, inbox, assistenza e recensioni. Il ledger TEST readonly del
12 ottobre contiene161ricevute e quattro migration Client canoniche ancora assenti.
Il dato32/57RPC è storico del10ottobre; non descrive il catalogo corrente.
OAuth, mappa TEST, push, percorsi autenticati e distribuzione restano da qualificare:
il prodotto non è dichiarato operativamente completo. Il
[rapporto verificabile](docs/TASKS/EVIDENCE/TASK-054/README.md) separa sorgenti,
fixture, staging, dispositivi e distribuzione.

## Relazione con Merchandise Control

Il client consuma il dominio pubblico Storefront sul Supabase esistente. Non
legge direttamente le tabelle inventory interne. Admin Console governerà pubblicazione,
prezzi, promozioni e fulfillment; Merchandise Control e Win7POS restano sistemi
operativi.

## Stack

- Flutter 3.44.8 / Dart 3.12.2;
- Android Kotlin e iOS Swift;
- Material 3;
- Riverpod;
- go_router;
- Supabase Flutter Auth con PKCE;
- `app_links` e storage Keychain/Keystore;
- gen_l10n e intl.

## Struttura

- `lib/app/`: app, router, tema e branding tecnico;
- `lib/core/`: configurazione, bootstrap backend, formatter e widget condivisi;
- `lib/features/`: shell e feature-first UI;
- `lib/l10n/`: risorse spagnolo, italiano, inglese e cinese semplificato;
- `test/`: unit e widget test;
- `docs/`: governance, architettura, roadmap, task ed evidence;
- `scripts/`: doctor e quality gate locali.

## Requisiti

- macOS con Xcode per il target iOS;
- Android SDK/Emulator per il target Android;
- Flutter stable `3.44.8`;
- CocoaPods per le dipendenze iOS.

Verificare l'ambiente:

```bash
scripts/doctor.sh
```

## Setup

```bash
flutter pub get
flutter gen-l10n
```

Avvio development senza backend:

```bash
flutter run
```

L'app non effettua richieste Supabase quando URL e publishable key sono assenti.

Per usare una configurazione locale:

```bash
cp config/app_config.example.json config/app_config.local.json
flutter run --dart-define-from-file=config/app_config.local.json
```

`config/*.local.json` è ignorato. Non inserire service role, secret key, password o valori
production nel repository.

Per preparare staging, copiare l'esempio nel file locale ignorato, valorizzare URL,
publishable key non-production e `STOREFRONT_SHOP_SLUG` con lo slug pubblico assegnato;
mantenere `GOOGLE_AUTH_ENABLED=false`: il runtime distribuibile non abilita OAuth
finché non esiste un dominio HTTPS posseduto e verificato:

```bash
cp config/app_config.staging.example.json config/app_config.staging.local.json
flutter run --dart-define-from-file=config/app_config.staging.local.json
flutter build apk --debug --dart-define-from-file=config/app_config.staging.local.json
flutter build ios --simulator --debug --dart-define-from-file=config/app_config.staging.local.json
```

Il contratto staging richiede il sentinel non instradabile
`https://clientmerchandisecontrol.invalid/auth-callback/` e rifiuta il flag `true`.
Il sentinel non è registrato come callback nativa e non dichiara ownership. Una futura
riattivazione richiede App Links/Universal Links verificati e un task autorizzato.
Sessione e verifier restano protetti in Keychain/Keystore. Development, staging OAuth
e production restano fail-closed. TASK-011 continua a verificare il solo endpoint Auth
health senza tabelle o dati; TASK-012 non aggiunge query o dati commerciali.
TASK-013 usa lo slug esclusivamente con l'RPC pubblico `storefront_home_v1`;
TASK-014 estende lo stesso boundary con `storefront_categories_v1` e
`storefront_catalog_v1`.

### Mappa delivery opzionale

La mappa usa `google_maps_flutter` ed è disattivata per default. Timeline, finestra di
consegna e fallback testuale restano disponibili senza provider. Per uno staging già
autorizzato e configurato servono due chiavi distinte e ristrette al solo Maps SDK:

- Android: `ANDROID_GOOGLE_MAPS_API_KEY` nell'ambiente della build, oppure
  `MAPS_API_KEY` in `android/local.properties` locale;
- iOS: `IOS_GOOGLE_MAPS_API_KEY=<valore>` in
  `ios/Flutter/Maps.local.xcconfig`, file ignorato da Git.

Solo dopo aver verificato package/bundle, firme, quote e billing dello staging, avviare
con entrambi i gate compile-time:

```bash
flutter run \
  --dart-define=DELIVERY_MAPS_ENABLED=true \
  --dart-define=DELIVERY_MAPS_NATIVE_CONFIGURED=true \
  --dart-define-from-file=config/app_config.staging.local.json
```

Senza uno dei due gate il widget Google non viene istanziato. La produzione resta
`OFF` finché un activation record separato non attesta chiavi ristrette e prova su
device. Il Client non chiede posizione, non calcola ETA o percorsi e non invia order ID,
customer ID, alias del corriere o coordinate a log, analytics e push.

## Test e build

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
flutter build apk --debug
flutter build ios --simulator --debug
```

Gli smoke staging reali, esclusi dalla CI perché usano il file locale ignorato, sono:

```bash
flutter test integration_test/backend_readiness_smoke_test.dart -d emulator-5554 --dart-define-from-file=config/app_config.staging.local.json
flutter test integration_test/backend_readiness_smoke_test.dart -d <IOS_SIMULATOR_ID> --dart-define-from-file=config/app_config.staging.local.json
flutter test integration_test/storefront_home_live_smoke_test.dart -d emulator-5554 --dart-define-from-file=config/app_config.staging.local.json
flutter test integration_test/storefront_home_live_smoke_test.dart -d <IOS_SIMULATOR_ID> --dart-define-from-file=config/app_config.staging.local.json
```

Il primo smoke conserva il gate storico di readiness; dal TASK-013 la Home avvia anche
il proprio controller dati. Il secondo attende esplicitamente il payload reale
`storefront_home_v1` e verifica fixture pubblica, immagini, prezzi CLP, versione catalogo
uniforme e assenza di sessione customer.

Lo smoke Catalogo reale di TASK-014 usa lo stesso file staging locale ignorato:

```bash
flutter test integration_test/storefront_catalog_live_smoke_test.dart -d emulator-5554 --dart-define-from-file=config/app_config.staging.local.json
flutter test integration_test/storefront_catalog_live_smoke_test.dart -d <IOS_SIMULATOR_ID> --dart-define-from-file=config/app_config.staging.local.json
```

Lo smoke guest di TASK-012 non richiede backend:

```bash
flutter test integration_test/app_guest_flow_test.dart -d emulator-5554
flutter test integration_test/app_guest_flow_test.dart -d <IOS_SIMULATOR_ID>
```

Lo smoke Auth deterministico non usa Google o secret:

```bash
flutter test integration_test/auth_callback_flow_test.dart -d emulator-5554
flutter test integration_test/auth_callback_flow_test.dart -d <IOS_SIMULATOR_ID>
```

Gli smoke OAuth live richiedono staging locale, provider e redirect verificati e un
account test già autenticato. Non inserire password/MFA tramite automazione e non
salvare screenshot o log contenenti identità, callback, code o token.

Il gate completo è:

```bash
scripts/check.sh
```

## Governance

Leggere prima [docs/MASTER-PLAN.md](docs/MASTER-PLAN.md), quindi il task attivo indicato
dal Master Plan e il [protocollo workflow](docs/CODEX-WORKFLOW-PROTOCOL.md).
`AGENTS.md` è l'unica istruzione operativa root. Può esistere un solo task attivo;
Codex assume ruoli logici distinti per planning, execution, review, fix e re-review.
Soltanto `USER_APPROVER` autorizza `DONE`, merge e attivazione del task successivo. Per
il release train `STOREFRONT_V1`, l'autorizzazione condizionata è già registrata dal
prompt del 2026-08-01 e resta soggetta a checkpoint e review integrata reali.

## Stato

- **Task attivo**: TASK-054
- **File task**: docs/TASKS/TASK-054-integrated-staging-e2e-closeout.md
- **Stato task**: BLOCKED
- **Fase**: REVIEW
- **Indicatore**: CODEX_REVIEW_BLOCKED
- **Release train**: CLIENT_COMMERCE_JOURNEY_COMPLETION
- **Stato release train**: OPERATIONAL_COMPLETION
- **Review integrata**: BLOCKED — Quality finale e gate nativi/live distinti

Sul commit pubblicato `dd9c0b2`, Quality `38887332867` è PASS: 1252 test,
1 SKIP, 11 performance, 352 Python, format 411/0 e analyze 0. Visual
`38889394269` e journal `38889397834` completano bootstatus e falliscono
nella successiva readiness; app e fixture non sono state eseguite. Cleanup
visual PASS; journal FAIL, con secondo cleanup della risorsa PASS. I leader
osservati sono HOST, senza PID guest o causa del timeout qualificati.

Il finding P2 `IOS-OWNED-KILL-EPERM-RR-01` è riprodotto e corretto nel
worktree: dopo il solo KILL/EPERM, un wait proprio bounded 2s e lo stesso
errore propagato. Patch `27ac8561`, review distinta `7be308cb` APPROVED
soltanto source/pure/privacy; primary 124 e cleanup FAIL restano preservati.
I gate sul successivo candidato sono NOT_RUN. È applicato anche il riordino
minimo dell'unica query CoreSimulator UUID già prevista, con ownership fresca
e STOP su errore/rifiuto, per recuperare evidenza prima censurata dalla ps.
Patch `dd199b8d`, review distinta `b178343f` APPROVED solo source/pure: 80
tracer e 17 readiness PASS dell'autore; 17 mirati PASS indipendenti.
Nessun token generico dimostra guest PID o sito d'attesa. Budget 300/30
invariati; PR29 draft, merge HOLD, nessun SDK Mac o nuovo accesso.

Il paragrafo seguente conserva il freeze precedente ai run dd9.

Re-review finale del freeze diagnostico b350aa96: 9 source e 7 documenti
verificati per hash; esito globale BLOCKED, CODEX_REVIEW_BLOCKED. Il composito
1ad30c7006ad conserva approval dc0d9927 solo source/pure/privacy: root 284
Python/12 suite e reviewer 51 test/176 casi, con provenienze distinte. Security
1157/zero/exit0 precede gli ultimi metadati di handoff; pin4, governance e
whitespace PASS da ricevute terminali. Nessun nuovo test, scan o SDK Mac.
Quality hosted format/analyze/fullhost sul futuro SHA e nuove domande native
restano NOT_RUN; soltanto dopo Quality PASS saranno eseguite sul medesimo
candidato visual reason/identity/reap e journal passivo/checkpoint. FullCI7
NOT_RUN, budget300/30 e guard invariati; nessuna acceptance nativa/live o causa
storica inferita. e77 conserva i propri PASS/FAIL, V1/RED/setupfail e cutoff
restano immutati. PR29 draft/HOLD; Maps/live e gli altri gate restano distinti.


Il paragrafo seguente conserva il piano di ripresa precedente all'applicazione.

Ripresa corrente16ottobre sul baseline e77 dopo tre run terminali: Quality
PASS1252/1SKIP+11performance, visualFAIL124/observerEPERM, journalFAIL124
readiness prima app/fixture. Nessun Simulator residuo attestato; quiescenza
observer non dimostrata, senza leak inferito. Il mandato continuativo è
riconfermato: diagnosi recuperabile source/pure e fix revisionati, poi nuove
prove hosted solo con ipotesi falsificabile. PrimoTERM/EPERM: conservare
motivo precleanup e wait; journal: trace passiva sul medesimo Popen senza
observer/sample. Budget300/30 e attestazioni invariati. Nessun SDK/device
Mac, reset, retry identico, nuovo accesso/deploy/merge o DONE. FullCI7e77
NOT_RUN, Maps/live e altri gate distinti; root unico writer, PR29draft/HOLD.

Il paragrafo seguente conserva il freeze precedente ai tre run e77.

Candidato successivo ad a2a: fix IOS-BOOT-OBS-RR-02 dopo ESRCH e nuovo
failureOrigin journal body|terminal_gate, entrambi con due review distinte
APPROVED soltanto source/pure. Root: 12 suite Python, 248 PASS, exit0.
Quality hosted (format/analyze/full host) NOT_RUN al freeze; solo dopo PASS
una verifica ios-visual del cleanup corretto e una ios-address-journal del
nuovo discriminante, sul medesimo candidato e runner separati. FullCI7
nuovo head NOT_RUN; sei altri job SKIPPED per selector, nessun Androidrepeat.
I due run a2a sono terminali FAIL: bootstatus0/117.566s poi observercleanup2
con cleanupFAIL; journal seedPASS23482→recover23761 assertionFAIL e cleanup
PASS separato. Causa e sottoproba precise non qualificate; nessun PASS
trasferito o retry identico. Maps/live e gli altri gate restano distinti.

Il freeze seguente precede i run mirati a2a e conserva quel cutoff.

Freeze composito: BOOTV2 e enumfix approvati source/pure da reviewer
distinti,12suitePython240PASS. P2FalseInventory corretto prima di apply/CI.
Due nuove domande mirate iOS sul futuro stessohead NOT_RUN al cutoff;
fullCI7nuovoheadNOT_RUN e d1955/2 nontrasferito.

Il paragrafo seguente conserva il cutoff precedente alla preparazioneV2.

Supplemento in corso: osservazione bounded DURANTE bootstatus owned,prima
della readiness, per distinguere attesa migrazione/servizio. Stesso300s e
sequenza/guard/cleanup, no warmup/reset/bypass. Source/pure/review prima
di una nuova prova visual e una separata journalenum; entrambeNOT_RUN.

Ultimo ciclo: canonicald195/run38862344656 terminale5SUCCESS/2FAIL.
Quality1252/1SKIP+11performance,Androidvisual137+4,journalAndroid e release
unsigned2PASS. iOSvisual falliscebootstatus300 prima readiness; journaliOS
raggiunge la fixture nativa e fallisce seed, restartNOT_RUN/causaUNKNOWN.
Corretto IOS-JOURNAL-OBS-RR-01: enum failure già sanitizzato conservato nei
diagnostics,45testPythonPASS e review distinta. Nuovo head e unica prova
miratajournal da qualificare separatamente; fullCI7NOT_RUN sul nuovo head.

Il freeze seguente precede la CI d195 e conserva il proprio cutoff.

Ripresa16ottobre: diagnostica source AndroidVM/lifecycle/PID/APK e iOS
PID/stack/UUID revisionata distintamente;9suitePython178PASS. Il primo
focused38860609181/c559 fallisce ad analyze per3lint, testNOT_RUN; patch
formatter autentica e lint corretti dopo review distinta. Nuovo focused
38861373311 su90f3807 PASS506/1SKIP,format405/0/analyze0:9unit nuovi
inclusi. Unica CI7job strumentata NOT_RUN al freeze; esiti nei Checks PR29.
Quality2e9/run38845283993 resta PASS1243/1SKIP+11performance; native9d
restano4SUCCESS/3FAIL. Nessuna nuova acceptance nativa o Maps/live.

I checkpoint seguenti sono storici e mantengono i propri cutoff.

Addendum12ottobre: esito add scoped, riconciliazione cart/checkout e UI tracking
corretti. [Dossier corrente](docs/TASKS/EVIDENCE/TASK-054/CLIENT_TASK054_CART_TRACKING_ADDENDUM.md):
freeze app07649, re-review source/widget APPROVED scoped; Quality1242PASS/1SKIP,
11performance e due release unsigned PASS. Guest Android/iOS e journal indirizzi Android
superano storage/kill/restart; Android4b produce137Flutter+4OS. Il collector iOS
è sourceapproved; la nuova CIeb0 conserva visual prepare/cleanup FAIL e journal
SDK seed FAIL dopo avvio app, con restart/recover NOT_RUN e cause distinte.
Maps/R17, R13/R14 autenticati, Auth/firma/R24/AT e C04 restano aperti.
La nuova CI PR29 eb0dc22 ha 1241 PASS/1 FAIL/1 SKIP: QUALITY-RR-01 riguarda
il validatore del selettore hosted. Fix mirato source/focused qualificato con
497 PASS/1 SKIP/analyze0 e formatter adottato in21a; Quality sul nuovo head PR
da leggere separatamente nei Checks. Nessun delta applicativo lib/native/config/deps.
Android finale journal e corpus137+4 PASS; journal iOS SDK seed FAIL e visual
iOS prepare/cleanup FAIL conservati con cause e limiti distinti.
Il checkpoint precedente ba11/527/QAcb9 e tutti i negativi sono conservati nel
[rapporto storico](docs/TASKS/EVIDENCE/TASK-054/CLIENT_TASK054_NEXT_INTEGRATION_RESULT.md).

Il checkpoint PR29 `43fd7af` conserva CI43 terminale: cinque job PASS,
journal iOS FAIL in preparazione e job smoke/visual CANCELLED30min. Lo smoke
è PASS; visual91PASS/1FAIL resta distinto dal budget. Badge predefinito al200%
corretto dopo RED/review in16e4681; la proiezione degli inset del solo harness
bf9be05 è approvato e integrato in2327948. La preview iOS7e è approvata e integrata in d4a7e97; nuova CI del composto da avviare; il rapporto corrente
sul branch evidence distingue checkpoint e candidato finale. Firma/upload/
install Client TEST e percorsi autenticati rimangono NOT_RUN/BLOCKED.

TASK-054 è riaperto dal mandato del 2026-09-28 per audit funzionale e completamento
nel perimetro di sviluppo. Le attestazioni di closeout seguenti sono storiche:
TASK-050–053 restano invariati; staging era classificato
`STAGING_PARTIAL_EXTERNAL` perché apply ed E2E-01…25 live sono `BLOCKED` dopo i due
tentativi provider/CLI bounded. Nessuna migration production o activation è avvenuta.

TASK-046–TASK-049 sono `DONE`: contratto Admin/Supabase ed editor Android/iOS sono
integrati, E2E-01…14 staging e release candidate sono verificati e il Client resta
read-only. Android Internal, TestFlight, physical smoke e backend production restano
classificati come requisiti esterni; public store rollout non è stato eseguito.

TASK-043, TASK-044 e TASK-045 restano `DONE`: tutte le PR coordinate sono state fuse
normalmente e le CI PR/main exact-SHA sono verdi. Il train
`CLIENT_FINAL_PRODUCT_COMPLETION` ha chiuso TASK-034 su `main` con review e CI
exact-SHA verdi; TASK-035 è `DONE` con PR #13, CI PR/main 3/3 e zero finding.
TASK-036 è `DONE`: re-review indipendente `APPROVED`, zero finding P0/P1/P2/P3,
PR Admin #93 e Client #14 integrate, CI PR/main verdi e staging verificato.
TASK-037 è `DONE`: `F-037-R01`–`F-037-R04` chiusi, PR #16 e main CI exact-SHA
verdi, budget invariato e production non modificata. TASK-038 è `DONE`: re-review
`APPROVED`, PR #17, merge `ce2ab134` e main CI `31995128511` verdi. TASK-039 è
`DONE / TECHNICALLY_COMPLETE_EXTERNAL_CREDENTIAL_REQUIRED`: PR #18, merge
`f30b13e9` e main CI `32019746636` sono verdi; signing e Play restano esterni.
TASK-041 è `DONE / PRODUCTION_READY_PENDING_EXTERNAL_ACTIVATION`: PR #20, CI PR/main
5/5 e merge `ce6045e4` sono verdi. TASK-042 è
`DONE / POST_LAUNCH_OPERATIONS_READY_PRELAUNCH`: il mandato
USER_APPROVER del 2026-08-21 autorizza il solo closeout tecnico operations-readiness,
senza go-live, pubblicazione store, migration production, billing o attivazione
provider. TASK-040
resta `DONE / TECHNICALLY_COMPLETE_EXTERNAL_CREDENTIAL_REQUIRED`: D-05 limita
il boundary locale ai writer same-UID cooperativi, la targeted final re-review è
`APPROVED` con zero P0/P1/P2/P3 e la CI PR #19 exact-SHA è verde 5/5. Il progetto
resta incorporato; `F-041-R01` è `FIXED_VALIDATED` e la re-review TASK-041 è
`APPROVED` con zero P0/P1/P2/P3. Il progetto resta temporaneamente `ACTIVE` durante
TASK-042; l'unica passata FIX ha corretto i tre finding P2
`F-042-R01`–`F-042-R03`, tutti `FIXED_VALIDATED` dalla re-review indipendente con
P0/P1/P2/P3 zero. Il progetto resta `IDLE` e nessun task successivo e attivo.
Distribution, provisioning,
App Store Connect, device fisico ed eventuali production provider key restano
activation requirement esterni; nessun upload TestFlight è stato dichiarato.

`TASK-001`–`TASK-004` sono `DONE`; la PR batch #3 TASK-003/TASK-004 è merged.
TASK-011 è `DONE` dopo re-review indipendente `APPROVED` e CI approvazione
`30601758281` 3/3 `PASS`; CI closeout `30602210469` è 3/3 `PASS` sullo SHA esatto.
TASK-012 è `DONE` con re-review indipendente `APPROVED`, quattro P2 chiusi e CI
handoff/approvazione `30606916073` / `30607430241` entrambe 3/3 `PASS`. TASK-020
è `DONE`: la Re-review 6 sullo SHA
`671494f` ha verificato allow-list staging, provider Google, OAuth live Android/iOS,
callback iOS warm/cold, restore, logout e nuovo login. Finding aperti 0 P0/P1/P2/P3;
CI finale `30713857455` 3/3 `PASS`, step applicabili `success`, annotation 0/0/0.
PR #4 è merged normalmente con commit `b2d70b5`; branch remoto eliminato e il closeout
su `main` è stato verificato dalla CI `30714350425`. Il release train Storefront v1 ha
attraversato un blocco storico sul worktree dedicato per una limitazione esterna
dell'ambiente della Deep Security Scan. Dopo il mandato finale, TASK-005–TASK-010
pertinenti e
TASK-013–TASK-019 sono `VALIDATED_PENDING_INTEGRATED_REVIEW`; il checkpoint Milestone
3 è `PASS`. TASK-021 ha completato profilo, indirizzi, privacy e cancellazione request
owner-only ed è `VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-022 ha completato registro
device, consenso notifiche e token lifecycle privacy-safe ed è
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-023 ha completato guest cart persistente,
merge owner idempotente e price revalidation server-side ed è anch'esso
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-024 ha completato disponibilità commerciale
privacy-safe, freshness, Admin preview e refresh cache/cart ed è
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-025 ha completato hold atomici,
idempotenti e scadibili senza quantità inventory pubblica ed è anch'esso
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-026 ha completato checkout
server-authoritative per ritiro, prenotazione e consegna configurabile ed è anch'esso
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-027 ha completato ordine, item snapshot,
status event, outbox e receipt atomici/idempotenti ed è anch'esso
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-028 ha completato storico, dettaglio,
timeline, cache read-only, deep link e cancellazione controllata ed è anch'esso
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-029 ha completato queue, detail, RBAC e
workflow operativo ordini nella Admin Console; TASK-030 ha completato l'handoff POS
idempotente e il confine tra ordine cliente e vendita fiscale. Entrambi sono
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-031 ha completato la pipeline idempotente
di notifiche ordine e l'integrazione Client privacy-safe ed è anch'esso
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-032 ha completato metodi v1,
stato/idempotenza pagamento, boundary provider/webhook fail-closed e checkpoint
Milestone 4 629/629; è `VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-033 è concluso
`DONE / REVIEW / USER_APPROVED_DONE`: i 18 finding del report canonico sono corretti
e validati, il gate locale aggregato è `PASS` e la CI pubblica `31646041242` ha
eseguito realmente `Quality`, Android e iOS con esito `SUCCESS`. Google OAuth resta
fail-closed `OFF`; nessun task successivo è attivo.
Gli altri task del train restano `TODO` fino al rispettivo checkpoint.
