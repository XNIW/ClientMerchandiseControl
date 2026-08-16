# TASK-043 — Storefront commerce information architecture and UX refresh

## Informazioni generali

- **Task ID**: TASK-043
- **Titolo**: Storefront commerce information architecture and UX refresh
- **File task**: `docs/TASKS/TASK-043-storefront-commerce-information-architecture-ux-refresh.md`
- **Stato**: DONE
- **Fase**: REVIEW
- **Responsabile**: USER_APPROVER
- **Data creazione**: 2026-08-16
- **Ultimo aggiornamento**: 2026-08-16
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-043/`
- **Handoff**: USER_APPROVED_DONE

## Dipendenze

- **Dipende da**: TASK-033, TASK-013–TASK-018, TASK-020–TASK-023, TASK-026–TASK-028, TASK-031
- **Sblocca**: TASK-044

## Scope

- shell `StatefulShellRoute` a cinque destinazioni Home, Catalogo, Ordini, Carrello,
  Account con stato per branch, rail adattiva, badge reali e resume auth;
- Home compatta, data-backed, con contesto reale, ricerca, ordine attivo, promozioni,
  categorie, prodotti e dati locali reali soltanto quando disponibili;
- Catalogo con header discovery compatto, filtri adattivi e scroll/paginazione stabili;
- gerarchia Product Detail più compatta mantenendo availability e CTA server-authoritative;
- Carrello compatto con repricing inline e riepilogo sticky SafeArea;
- Account trasformato in hub a sezioni con identità bounded, ordini, preferiti,
  indirizzi, notifiche, privacy, impostazioni e logout;
- Ordini come destinazione primaria con filtri supportati, stati resilienti, cache,
  pagination e deep link;
- localizzazione `es-CL`, `it`, `en`, `zh-Hans`, accessibilità e visual QA bounded.

## Contesto

L'audit runtime Android sul commit iniziale `8423c868f345ee87eee7ed58ee9eb793d98412db`
ha verificato dati staging reali e sei stati principali. La Home impiega il primo
viewport per welcome e promotion; Ordini è una route esterna alla shell; Account usa
una sola card molto lunga; le righe Carrello sono alte; Product Detail privilegia una
gallery troppo estesa. I contratti esistenti per catalogo, carrello, account e ordini
restano la fonte di verità e non vengono sostituiti da mock.

## Non incluso

- tracking delivery, migration, Realtime e mappa (TASK-044/TASK-045);
- nuovi stati ordine, coupon, wallet, punti, membership, recensioni, chat o feed;
- GPS continuo, personalizzazione invasiva o claim promozionali non server-authoritative;
- modifiche production, store release, refactor opportunistici o inventory/POS.

## File coinvolti

- `lib/app/router/`, `lib/features/shell/`, `lib/features/home/`,
  `lib/features/catalog/`, `lib/features/cart/`, `lib/features/account/`,
  `lib/features/orders/`, `lib/l10n/`;
- test unit/widget/integration pertinenti;
- `docs/MASTER-PLAN.md`, `README.md`, `docs/AI_WORKLOG.md`, ADR-013 ed evidence TASK-043.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Esiste una shell a cinque branch reali, con stato/scroll preservato e Ordini terza destinazione | WIDGET/INTEGRATION |
| CA-02 | Ordini guest devia ad Account e riprende Ordini dopo login; deep link e notifiche aprono il contesto corretto | UNIT/WIDGET |
| CA-03 | Rail adattiva e back navigation restano coerenti su mobile/tablet | WIDGET |
| CA-04 | Badge Carrello/Ordini derivano soltanto da conteggi reali e hanno semantics localizzate | UNIT/WIDGET/A11Y |
| CA-05 | Home mostra nel primo viewport contesto reale, ricerca e contenuto commerciale senza header/placeholder dominante | WIDGET/VISUAL |
| CA-06 | L'ordine attivo usa priorità outForDelivery > ready > preparing > accepted > confirmed e apre il dettaglio | UNIT/WIDGET |
| CA-07 | Promozioni, categorie, prodotti e recenti non inventano dati; cache/offline/retry mantengono geometria stabile | UNIT/WIDGET |
| CA-08 | Catalogo conserva search, filtri, sort, pagination e scroll con layout adattivo e bottom sheet mobile | WIDGET |
| CA-09 | Product Detail ha gallery progressiva compatta e CTA SafeArea soltanto quando disponibile | WIDGET |
| CA-10 | Carrello mostra contesto, righe compatte, variazioni inline e totale/CTA sticky | WIDGET |
| CA-11 | Account è un hub a sezioni e non espone capability o valori economici inesistenti | WIDGET |
| CA-12 | Ordini supporta All/Active/Completed/Cancelled, loading/offline/empty/error/retry e pagination deterministica | UNIT/WIDGET |
| CA-13 | Tutte le stringhe nuove passano da gen_l10n nelle quattro lingue e i formati esistenti restano coerenti | STATIC/UNIT |
| CA-14 | Visual QA copre viewport bounded, light/dark e text scale senza overflow P0–P2 | VISUAL |
| CA-15 | Gate canonici Client, CI exact-SHA PR e CI main post-merge sono reali e verdi | COMMAND/CI |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-03 | WIDGET | Verificare cinque destinazioni, branch state e rail |
| T-02 | CA-02 | UNIT/WIDGET | Verificare pending destination e resume auth/deep link |
| T-03 | CA-04 | UNIT/WIDGET | Mutare conteggi reali e verificare badge/semantics |
| T-04 | CA-05, CA-07 | WIDGET/GOLDEN | Render Home data/offline/loading e confrontare geometria |
| T-05 | CA-06 | UNIT | Ordinare fixture multi-status e verificare selezione attiva |
| T-06 | CA-08 | WIDGET | Ricerca, categorie, count, sort/filter sheet, load more e refresh cached |
| T-07 | CA-09 | WIDGET | Verificare gallery, availability e CTA con capability on/off |
| T-08 | CA-10 | WIDGET | Verificare righe, repricing, unavailable e barra sticky |
| T-09 | CA-11 | WIDGET | Verificare hub guest/auth, sezioni reali, privacy e logout |
| T-10 | CA-12 | UNIT/WIDGET | Verificare filtri e tutti gli stati Orders più pagination |
| T-11 | CA-13 | STATIC/UNIT | Generare l10n e testare assenza stringhe hardcoded nuove |
| T-12 | CA-14 | VISUAL | Screenshot/golden su matrice bounded e text scale 1.0/1.3/2.0 |
| T-13 | CA-15 | COMMAND | Eseguire format, analyze, test coverage, build Android/iOS e scripts/check.sh |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | L'istruzione USER_APPROVER del 2026-08-16 riapre il progetto e autorizza l'intero ciclo TASK-043 senza nuova conferma intermedia. | Mandato esplicito | ATTIVA |
| D-02 | Restano invariati RPC e stati ordine correnti in TASK-043; i campi tracking/ETA saranno versionati in TASK-044. | Separare UX da contratto e migration | ATTIVA |
| D-03 | Conteggi e badge non mostrano valori finché lo stato reale non è caricato. | Evitare numeri inferiti | ATTIVA |
| D-04 | I riferimenti Taobao/Meituan sono principi funzionali, non target visuali copiabili. | Identità e proprietà intellettuale | ATTIVA |
| D-05 | La review è logicamente separata dal writer nella stessa sessione, salvo disponibilità futura di reviewer distinto. | Vincolo operativo dichiarato | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Ridurre il costo di navigazione e aumentare la chiarezza commerce mantenendo invariati i
confini Storefront, l'autorità server e la resilienza già validata.

### Analisi

La codebase ha già `StatefulShellRoute.indexedStack`, cache SWR, order controller,
resume auth, design token e gen_l10n. L'intervento riusa questi elementi: aggiunge il
branch Orders, ricompone le superfici e introduce selettori/view model puri per ordine
attivo e filtri, senza duplicare repository o leggere tabelle operative.

### Approccio

1. rendere Ordini un branch e centralizzare selezione/auth resume nella shell/router;
2. creare piccoli componenti commerce riusabili basati sui provider esistenti;
3. compattare Home, Catalogo, Product Detail e Cart preservando controller/cache;
4. trasformare Account e Orders in hub/lista adattivi;
5. completare l10n, test, visual QA, gate e documentazione evidence.

### Rischi

- regressioni di route index e back navigation: copertura router/shell dedicata;
- watch eager Orders che causa richieste guest/globali: provider auth-scoped e nessun
  badge inferito;
- overflow text scale: Wrap/Flexible/Sliver e matrici viewport;
- scope creep nel contratto: campi tracking esclusi fino a TASK-044.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION
- **Autorizzazione USER_APPROVER**: ricevuta nel prompt del 2026-08-16; applicata come `CODEX_PLANNING_APPROVED_TO_EXECUTION`

## Execution — `CODEX_EXECUTOR`

### Obiettivo compreso

Implementare esclusivamente CA-01–CA-15 sui contratti reali correnti.

### File controllati

- router e shell: `lib/app/router/`, `lib/features/shell/`;
- superfici commerce: Home, Catalogo, Product Detail, Cart, Account e Orders;
- ARB e output `gen_l10n` per es-CL, it, en e zh-Hans;
- unit/widget/integration test toccati dal nuovo indice di navigazione;
- governance checker e fixture release-train.

### Piano minimo

Completato secondo Planning senza nuovi RPC, schema o capability speculative.

### Modifiche fatte

- introdotto il quinto branch Orders con route detail annidata, resume auth della URI
  originale e rail adattiva;
- aggiunti selettori puri per filtro, conteggio e priorità ordine attivo;
- ricomposte Home, Catalogo, Product Detail, Cart e Account sui controller/cache reali;
- resa Orders una lista primaria filtrabile con stati resilienti e pagination;
- aggiornati l10n, test widget/integration e fixture di governance per il nuovo train.

### Check eseguiti

- `dart format --output=none --set-exit-if-changed .`: `PASS`, exit 0;
- `flutter analyze`: `PASS`, exit 0;
- `flutter test --coverage --exclude-tags performance`: `PASS`, 571 test;
- performance cache 20k: `PASS`, 1 test dedicato; totale 572 test;
- `flutter build apk --debug`: `PASS`, exit 0;
- `flutter build ios --simulator --debug`: `PASS`, exit 0;
- `bash scripts/check.sh`: `PASS`, exit 0, scanner/boundary/governance/test/build verdi;
- smoke Android development `app_shell_smoke_test` + `app_guest_flow_test`: `PASS`,
  2/2; `auth_callback_flow_test`: `PASS`, 1/1; order history: `PASS`, 1/1;
- staging post-change con il file locale storico: `BLOCKED`, perché il file non contiene
  `STOREFRONT_SHOP_SLUG` e ha una callback non più valida; l'avvio fail-closed è stato
  osservato e nessun valore è stato stampato. Non è stato dichiarato uno smoke staging.

### Matrice CA -> evidence

| CA | Evidence | Esito |
|---|---|---|
| CA-01 | shell/widget e smoke Android, cinque branch e subtree preservato | PASS |
| CA-02 | router callback con `/orders?filter=active`, test deep link/notifiche esistenti | PASS |
| CA-03 | rail 1024×768, back e portrait/landscape integration | PASS |
| CA-04 | conteggi derivati da cart/order controller e semantics plurali localizzate | PASS |
| CA-05 | Home compatta e screenshot Android bounded | PASS |
| CA-06 | `customer_order_selectors_test.dart` e card Home tappabile | PASS |
| CA-07 | controller/cache/offline esistenti e zero dati commerciali inventati | PASS |
| CA-08 | bottom sheet mobile, grid, search/pagination/cache testati | PASS |
| CA-09 | gallery 16:10, quantity e CTA SafeArea testati | PASS |
| CA-10 | contesto fulfillment, righe compatte e summary sticky testati | PASS |
| CA-11 | hub autenticato/guest, shortcut reali e capability vietate assenti | PASS |
| CA-12 | filtri Orders, stati, load-more e cache controller testati | PASS |
| CA-13 | parità ARB/placeholder e quattro locale | PASS |
| CA-14 | sette viewport, light/dark, scale 1.0/1.3/2.0 e runtime tablet | PASS |
| CA-15 | gate locali, PR #8 exact-SHA e main post-merge run `31933418566` verdi | PASS |

### Matrice T-NN -> risultato

| Test | Risultato | Evidence |
|---|---|---|
| T-01 | PASS | shell widget/integration |
| T-02 | PASS | router callback/deep link |
| T-03 | PASS | selettori conteggio + semantics shell |
| T-04 | PASS | Home widget + screenshot locali sanitizzati |
| T-05 | PASS | selector unit test |
| T-06 | PASS | catalog widget/controller |
| T-07 | PASS | product detail widget/controller |
| T-08 | PASS | cart widget/controller |
| T-09 | PASS | account widget/auth integration |
| T-10 | PASS | orders unit/widget/integration |
| T-11 | PASS | gen_l10n + contract test |
| T-12 | PASS | matrice reflow + visual runtime bounded |
| T-13 | PASS | locali, PR run `31933134837` e main run `31933418566` 3/3 verdi |

### Rischi rimasti

- il file staging locale storico deve essere rigenerato fuori Git prima di uno smoke
  data-backed; il Client resta correttamente fail-closed;
- la review è logicamente separata nella stessa sessione, non una sessione distinta;
- lo smoke staging data-backed resta `BLOCKED_CONFIGURATION` per configurazione locale
  storica, senza impatto sul codice o sui gate PR/main verificati.

### Handoff a Review

- **Prossima fase**: REVIEW
- **Prossimo ruolo**: CODEX_REVIEWER
- **Handoff**: CODEX_EXECUTION_COMPLETE_TO_REVIEW

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

Review logica read-only sul revision set `72f80ba`, separata dal writer per ruolo ma
nella stessa sessione.

Finding:

1. `T043-REV-NAV-001` — **P2**: `PopScope.canPop` dipende soltanto dall'indice branch;
   sul dettaglio `/orders/:orderId` può bloccare il pop annidato e inviare Home invece
   di tornare alla lista Orders. Impatto: back Android/iOS incoerente con CA-03.
2. `T043-REV-DATA-002` — **P2**: badge shell e shortcut Account contano `state.orders`
   anche quando `nextCursor != null`; un conteggio di pagina parziale viene quindi
   presentato come totale reale, contro CA-04/CA-11.

Conteggio: 0 P0, 0 P1, 2 P2, 0 P3. Esito: `CHANGES_REQUIRED`.

Handoff: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

Re-review read-only sul revision set `f0e761d..e2a6475`:

- `T043-REV-NAV-001`: **CLOSED**, regressione router verifica il back dal dettaglio
  alla branch Orders e il comportamento root-branch resta coperto;
- `T043-REV-DATA-002`: **CLOSED**, conteggio nullable su paginazione incompleta e
  shortcut Account non numerici finché `hasMore`/`isLoadingMore` sono veri;
- gate canonico `bash scripts/check.sh`: `PASS`, exit 0; scanner 574 file, governance
  9/9, boundary 7/7, format, analyze, 571 test non-performance, performance 1/1,
  APK debug e iOS Simulator debug verdi;
- finding aperti: 0 P0, 0 P1, 0 P2, 0 P3.

Esito re-review: `APPROVED`. Handoff:
`CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION`; l'autorizzazione USER_APPROVER è
già registrata, quindi il passo successivo è PR e CI exact-SHA senza bypass.

## Fix — `CODEX_FIXER`

- `T043-REV-NAV-001`: chiuso facendo dipendere `PopScope` anche dalla reale capacità
  di pop della route annidata; il back da `/orders/:orderId` torna alla lista Orders,
  mentre il back dalla root di una branch secondaria continua a tornare alla Home.
- `T043-REV-DATA-002`: chiuso rendendo nullo il conteggio attivo quando `hasMore` è
  vero; shell e Account non mostrano badge/shortcut numerici finché la paginazione non
  è completa.
- regressioni aggiunte al router auth/orders e ai selettori; format, `flutter analyze`
  e 25 test mirati shell/router/account/selectors: `PASS`, exit 0.

Handoff: `CODEX_FIX_COMPLETE_TO_RE_REVIEW` sul commit `ec3cb4d`.

## Chiusura

- **Conferma utente**: ricevuta in anticipo nel prompt del 2026-08-16, condizionata a review e CI reali verdi
- **Merge autorizzato da USER_APPROVER**: sì, normale e senza bypass dopo `APPROVED`
- **Follow-up candidate**: TASK-044, attivato separatamente dopo main CI verde
- **Riepilogo finale**: PR #8 fusa normalmente in `main` con merge commit
  `e9bd0306b07b105f3fb46da783ab2fd24ef44246`; PR CI `31933134837` e main CI
  `31933418566` hanno concluso Quality, Android e iOS 3/3 `SUCCESS`; branch remoto
  integrato eliminato.
- **Data completamento**: 2026-08-16
