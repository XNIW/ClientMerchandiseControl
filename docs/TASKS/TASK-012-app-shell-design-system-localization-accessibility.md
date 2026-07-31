# TASK-012 — App shell, design system, localizzazione, CLP e accessibility baseline

## Informazioni generali

- **Task ID**: TASK-012
- **Titolo**: App shell, design system, localizzazione, CLP e accessibility baseline
- **File task**:
  `docs/TASKS/TASK-012-app-shell-design-system-localization-accessibility.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-07-30
- **Ultimo aggiornamento**: 2026-07-30
- **Ultimo agente**: CODEX_EXECUTOR
- **Review outcome**: NOT_RUN
- **Indicatore**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **DONE**: NO
- **Merge**: NO — milestone batch con TASK-011 e TASK-020
- **User approval**: GRANTED_AND_APPLIED_FROM_END_TO_END_PROMPT
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-012/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Dipendenze

- **Dipende da**: TASK-002 `DONE`; TASK-011 `DONE`
- **Sblocca**: TASK-013, TASK-014, TASK-018, TASK-020, TASK-023 e TASK-036

## Scope

- trasformare i placeholder tecnici esistenti in una shell cliente e-commerce
  rifinita, originale e data-safe;
- mantenere le quattro destinazioni persistenti Home, Catalogo, Carrello e Account
  sul router `StatefulShellRoute.indexedStack`;
- permettere sempre il browsing guest e richiedere il login soltanto per future
  funzioni personali;
- realizzare una Home guest con nome pubblico provvisorio centralizzato, ricerca
  evidente, accesso rapido alle categorie, sezioni future per offerte e prodotti in
  evidenza e CTA verso Catalogo;
- realizzare un Catalogo guest con ricerca, fondazione di filtri/ordinamento e stati
  customer-safe per loading, vuoto, offline, backend non disponibile ed errore
  recuperabile;
- realizzare un Carrello vuoto con spiegazione e CTA verso Catalogo;
- realizzare Account nei due stati puramente presentazionali `guest` e
  `authenticated`, con avatar e nome di fallback, email, sessione attiva e logout;
- definire un port di presentazione per “Continua con Google” e logout senza
  implementare OAuth, callback, persistenza o session lifecycle prima di TASK-020;
- usare Material 3 e i token di TASK-002, completandoli soltanto dove una
  responsabilità UI reale lo richiede;
- rendere tutta la copy localizzata in spagnolo cileno primario, italiano, inglese e
  cinese semplificato;
- preservare tema chiaro/scuro, SafeArea, target minimi, Semantics, text scale 200%,
  portrait/landscape, viewport compact/large, stato tab e back navigation;
- aggiungere test unitari/widget/integration guest, build e smoke reali
  dual-platform;
- produrre evidence, review indipendente, eventuale Fix, re-review, CI e closeout.

## Contesto

TASK-002 ha introdotto identità provvisoria centralizzata, principi UX, `ColorScheme`
Material 3, un solo `ThemeExtension`, token dimensionali e la shell a quattro
destinazioni. TASK-011 ha aggiunto readiness staging asincrona, fail-closed e
customer-safe senza accessi a dati. Le schermate di Home, Catalogo, Carrello e Account
sono però ancora istanze dello stesso `FeaturePlaceholder`: non esprimono gerarchia,
discovery, azioni o stati specifici.

Il requisito autorizzato chiede pattern generali riconoscibili delle migliori app
e-commerce, anche Amazon e Falabella, ma vieta qualunque copia di marchi, logo,
palette, testi, icone proprietarie, layout pixel-perfect, immagini, asset, nomi o dark
pattern. Questa fase deve quindi costruire una grammatica originale, onesta e pronta
per dati futuri, senza inventare prodotti, prezzi, stock, urgenza o costi.

Il runtime rimane guest fino a TASK-020. Lo stato authenticated di Account è un
contratto di rendering iniettabile e testabile, non una sessione simulata né una
scorciatoia di autenticazione. La readiness di TASK-011 può cambiare lo stato
presentazionale del Catalogo, ma non autorizza query a tabelle.

## Non incluso

- catalogo, categorie, prodotti, promozioni, prezzi, stock, immagini o disponibilità
  reali;
- fixture o mock commerciali mostrati come dati disponibili;
- query, insert, update, delete, subscribe o RPC verso tabelle Supabase;
- schema, migration, RLS, grant, Storage, Edge Function o modifiche remote;
- Google OAuth, PKCE, browser esterno, redirect allow-list, deep link o callback
  Android/iOS;
- session restore, refresh token, secure storage, auth stream o logout remoto;
- profilo cliente, indirizzi, preferiti, checkout, totale, consegna, pagamento,
  prenotazione o ordine;
- implementazione data-backed dei task TASK-013–TASK-019 o TASK-023;
- adozione di asset, dipendenze runtime o font non già autorizzati;
- modifica di TASK-005–TASK-010, TASK-013 e successivi, priorità, roadmap o
  repository esterni.

## File coinvolti

- `lib/app/client_merchandise_control_app.dart`;
- `lib/app/router/app_router.dart`;
- `lib/app/theme/app_theme.dart`;
- `lib/app/design_system/tokens/`;
- widget concreti in `lib/app/design_system/widgets/`;
- `lib/features/shell/presentation/app_shell_screen.dart`;
- presentazione e modelli UI sotto `lib/features/home/`,
  `lib/features/catalog/`, `lib/features/cart/` e `lib/features/account/`;
- eventuale rimozione di `lib/core/widgets/feature_placeholder.dart` se non ha più
  consumatori reali;
- `lib/l10n/app_*.arb` e output `gen_l10n`;
- test in `test/app/` e `test/features/`;
- `integration_test/app_guest_flow_test.dart` e adeguamento dello smoke shell
  esistente senza sovrapporsi ad `auth_callback_flow_test.dart` di TASK-020;
- `docs/ARCHITECTURE/MOBILE-ARCHITECTURE.md`, `docs/QUALITY-GATES.md`, `README.md`,
  `docs/MASTER-PLAN.md`, `docs/AI_WORKLOG.md`;
- questo task e `docs/TASKS/EVIDENCE/TASK-012/`.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | TASK-002 e TASK-011 sono `DONE`, TASK-012 è l'unico task `ACTIVE` e il repository parte pulito/allineato | GIT/STATIC |
| CA-02 | La shell adotta pattern e-commerce generali ma non copia brand, asset, palette, copy, icone o layout proprietari | MANUAL/STATIC |
| CA-03 | Material 3, `ColorScheme`, `StorefrontSemanticColors` e token TASK-002 restano le sole fonti di stile semantico | STATIC/WIDGET |
| CA-04 | Il nome pubblico provvisorio deriva esclusivamente da `AppBrand`, senza duplicazioni UI | STATIC/UNIT |
| CA-05 | Home, Catalogo, Carrello e Account restano quattro destinazioni persistenti e riconoscibili | WIDGET/INTEGRATION |
| CA-06 | Cambiare tab preserva il subtree/stato e back da una tab secondaria torna ragionevolmente a Home | WIDGET/INTEGRATION |
| CA-07 | Home, Catalogo e Carrello sono navigabili senza login in ogni stato backend recuperabile | WIDGET/INTEGRATION |
| CA-08 | Home espone app bar, gerarchia cliente e ricerca evidente | WIDGET |
| CA-09 | Ricerca e CTA principali di Home conducono al Catalogo senza eseguire query | WIDGET/INTEGRATION |
| CA-10 | Le categorie rapide sono affordance future oneste, accessibili e prive di dati inventati | WIDGET/SECURITY |
| CA-11 | Offerte e prodotti in evidenza sono sezioni future chiaramente indisponibili, non skeleton spacciati per contenuto | WIDGET/MANUAL |
| CA-12 | Home non presenta prodotti, immagini, prezzi, stock, sconti, urgenza o scarsità fittizi | STATIC/WIDGET/SECURITY |
| CA-13 | Catalogo espone ricerca e controlli fondazione di filtro/ordinamento disabilitati e spiegati finché i task proprietari non forniscono comportamento reale | WIDGET |
| CA-14 | Catalogo rappresenta distintamente loading, vuoto, offline, backend non disponibile ed errore recuperabile | UNIT/WIDGET |
| CA-15 | Solo lo stato recuperabile offre retry manuale; azioni concorrenti non creano loop o polling | UNIT/WIDGET |
| CA-16 | Catalogo non interroga tabelle, RPC, Storage, inventory o dati commerciali | STATIC/SECURITY |
| CA-17 | Carrello mostra stato vuoto, spiegazione breve e CTA “Esplora il catalogo” | WIDGET |
| CA-18 | Carrello non mostra checkout, totale, prezzo, costo consegna o promessa di disponibilità | STATIC/WIDGET |
| CA-19 | Account guest comunica il vantaggio del login, mostra “Continua con Google” e lascia esplicito il browsing anonimo | WIDGET |
| CA-20 | L'azione Google di TASK-012 attraversa un port iniettabile e comunica onestamente indisponibilità, senza OAuth o falsa autenticazione | UNIT/WIDGET/SECURITY |
| CA-21 | Account authenticated renderizza un avatar presentazionale opzionale con fallback locale sicuro, nome con fallback, email, sessione attiva e logout | UNIT/WIDGET |
| CA-22 | Dati presentazionali assenti, vuoti o troppo lunghi non provocano crash, leak, overflow o accesso diretto a metadata/URI remoti | UNIT/WIDGET/SECURITY |
| CA-23 | Account non introduce profilo aggiuntivo, form, indirizzi o impostazioni fuori scope | STATIC/WIDGET |
| CA-24 | Il runtime production di TASK-012 resta guest; nessun token, sessione o credenziale viene creato, persistito o loggato | STATIC/SECURITY |
| CA-25 | La locale primaria/fallback è spagnolo cileno; es-CL, it, en e zh-Hans mostrano copy completa, con parità automatica delle chiavi e bundle tecnico `app_zh` sincronizzato | UNIT/WIDGET |
| CA-26 | Nessuna stringa customer-facing o semantic label nuova è hardcoded fuori dai cataloghi ARB | STATIC |
| CA-27 | Formattazione CLP resta centralizzata, senza decimali e senza valori commerciali finti nella UI | UNIT/STATIC |
| CA-28 | Tema chiaro e scuro hanno contrasto e colori semantici coerenti senza colori funzionali hardcoded nei widget | STATIC/WIDGET |
| CA-29 | Tutte le schermate restano utilizzabili a text scale 200% | WIDGET/INTEGRATION |
| CA-30 | Heading, status, controlli e icone decorative hanno Semantics corrette e non duplicate | WIDGET/INTEGRATION |
| CA-31 | Tutti i controlli interattivi nuovi e di navigazione rispettano il target minimo di 48 dp | WIDGET/INTEGRATION |
| CA-32 | SafeArea con inset non nulli, portrait, landscape, 320 px compact e viewport large non producono overflow o contenuto irraggiungibile | WIDGET/INTEGRATION |
| CA-33 | Contenuto full-width entro il max-width, scroll-to-end e bounds dimostrano che testo e CTA restano completi, raggiungibili e tappabili, chiudendo i P3 TASK-002 | WIDGET/INTEGRATION |
| CA-34 | Rendering e azioni UI non bloccano il main thread e non aggiungono I/O sincrono o networking autonomo | STATIC/INTEGRATION |
| CA-35 | Format, gen-l10n, analyze, suite completa e build Android/iOS sono `PASS` | FORMAT/ANALYZE/UNIT/BUILD_ANDROID/BUILD_IOS |
| CA-36 | Smoke guest reale Android e iOS copre avvio, quattro tab, CTA, back, temi, 200% e orientamenti | ANDROID_EMU/IOS_SIM |
| CA-37 | Diff, dipendenze, artifact e scan security restano confinati allo scope | GIT/SECURITY |
| CA-38 | Review indipendente termina con 0 finding P0, P1 o P2 aperti | MANUAL/STATIC |
| CA-39 | CI sullo SHA finale completa job, step e annotation con esito `PASS` | CI |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01 | GIT/STATIC | Verificare dipendenze, task unico, branch, origin e governance |
| T-02 | CA-02, CA-12 | MANUAL/STATIC | Auditare originalità, assenza asset copiati e dati commerciali finti |
| T-03 | CA-03, CA-28 | STATIC/WIDGET | Verificare token, temi e assenza colori semantici hardcoded |
| T-04 | CA-04 | UNIT/WIDGET | Cambiare il nome tecnico in test e verificarne l'unica origine |
| T-05 | CA-05, CA-06 | WIDGET | Navigare quattro tab, preservare subtree/stato e provare back |
| T-06 | CA-07 | WIDGET | Provare browsing guest con readiness ready/offline/error |
| T-07 | CA-08, CA-09 | WIDGET | Verificare Home e aprire Catalogo da ricerca e CTA |
| T-08 | CA-10, CA-11, CA-12 | WIDGET/SECURITY | Verificare sezioni future oneste e assenza prodotti/prezzi/stock |
| T-09 | CA-13 | WIDGET | Verificare search, filtro e ordinamento foundation |
| T-10 | CA-14 | UNIT/WIDGET | Renderizzare loading, vuoto, offline, unavailable e recoverable |
| T-11 | CA-15 | UNIT/WIDGET | Toccare retry, provare duplicazione e assenza polling |
| T-12 | CA-16, CA-34 | STATIC/SECURITY | Scansionare query, I/O, network e dipendenze non autorizzate |
| T-13 | CA-17, CA-18 | WIDGET | Verificare Carrello vuoto, CTA e assenza valori/checkout |
| T-14 | CA-17 | WIDGET | Toccare la CTA Carrello e verificare Catalogo |
| T-15 | CA-19, CA-20 | UNIT/WIDGET | Verificare Account guest, Google port e messaggio onesto |
| T-16 | CA-21 | UNIT/WIDGET | Renderizzare Account authenticated completo e invocare logout |
| T-17 | CA-21, CA-22 | UNIT/WIDGET/SECURITY | Provare avatar presentazionale assente/errore e nome/email nulli, vuoti o lunghi |
| T-18 | CA-23, CA-24 | STATIC/WIDGET/SECURITY | Verificare guest runtime, assenza form, token e persistenza |
| T-19 | CA-25, CA-26 | UNIT/WIDGET | Provare parità ARB/placeholder, bundle `app_zh`, es-CL, it, en, zh-Hans e fallback |
| T-20 | CA-27 | UNIT | Verificare formatter CLP con zero decimali e locale cilena |
| T-21 | CA-28 | WIDGET | Renderizzare tutte le destinazioni in light e dark |
| T-22 | CA-29, CA-32 | WIDGET | Renderizzare tutte le destinazioni a 200% su compact/large |
| T-23 | CA-30 | WIDGET | Ispezionare Semantics heading, live status, label e decorazioni |
| T-24 | CA-31 | WIDGET | Eseguire guideline e misurare target interattivi |
| T-25 | CA-32, CA-33 | WIDGET | Provare inset SafeArea, portrait/landscape, full-width, scroll-to-end, bounds e zero overflow |
| T-26 | CA-05, CA-06, CA-07, CA-36 | INTEGRATION | Eseguire `app_guest_flow_test.dart` con flusso completo |
| T-27 | CA-35 | FORMAT/ANALYZE/UNIT | Eseguire gen-l10n, format, analyze e suite completa |
| T-28 | CA-35 | BUILD_ANDROID | Compilare APK debug |
| T-29 | CA-35 | BUILD_IOS | Compilare iOS Simulator debug |
| T-30 | CA-36 | ANDROID_EMU | Eseguire smoke guest reale su Android Emulator |
| T-31 | CA-36 | IOS_SIM | Eseguire smoke guest reale su iOS Simulator |
| T-32 | CA-37 | GIT/SECURITY | Eseguire diff check, governance, scan secret/artifact e confinement |
| T-33 | CA-38 | MANUAL/STATIC | Eseguire review indipendenti UI/a11y e architettura/security |
| T-34 | CA-39 | CI | Ispezionare SHA, job, step e annotation del run finale |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Il prompt end-to-end preautorizza il ciclo, ma Planning ed Execution restano transizioni e commit distinti. | Preservare protocollo e autorità utente | ATTIVA |
| D-02 | La shell usa pattern e-commerce generali e una composizione originale basata sui token esistenti. | Evitare clone, identità di terzi e scope branding non verificato | ATTIVA |
| D-03 | Le sezioni prive di dati usano empty/future state espliciti, mai card prodotto, prezzo o stock sintetici. | Rendere la UI credibile senza ingannare il cliente | ATTIVA |
| D-04 | Il runtime TASK-012 resta guest; lo stato authenticated è un modello presentazionale iniettabile usato dai test e pronto al wiring TASK-020. | Separare UI e autenticazione reale | ATTIVA |
| D-05 | “Continua con Google” è visibile ma fail-closed/disabilitato senza callback; il port diventa operativo soltanto col wiring TASK-020. | Soddisfare il contratto UI senza no-op o falsa sessione | ATTIVA |
| D-06 | Il Catalogo deriva soltanto stati customer-safe dalla readiness esistente e non esegue query o networking proprio. | Preservare il confine TASK-011/TASK-010 | ATTIVA |
| D-07 | Le CTA di Home e Carrello navigano alla branch Catalogo tramite go_router. | Offrire un flusso utile mantenendo stato e back policy | ATTIVA |
| D-08 | es-CL è locale primaria e fallback; il delegate può riusare il catalogo spagnolo finché non esistono varianti regionali divergenti. | Rendere esplicita la policy cilena senza duplicare copy identica | ATTIVA |
| D-09 | Nessuna nuova dipendenza runtime, immagine remota di prodotto, font o asset viene introdotto. | Ridurre rischio supply-chain e contenuto non autorizzato | ATTIVA |
| D-10 | `FeaturePlaceholder` viene rimosso solo se resta senza responsabilità o consumatori. | Evitare astrazioni vuote e file inutilizzati | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Consegnare una shell cliente originale, leggibile e accessibile che comunichi con
onestà cosa è già disponibile e cosa arriverà in futuro, permetta il browsing guest e
offra a TASK-020 un contratto Account stabile senza anticipare autenticazione o dati.

### Analisi

- Il router indexed-stack soddisfa già persistenza tab e back-to-Home.
- Il tema Material 3, i semantic colors e i token soddisfano la baseline, ma mancano
  componenti e gerarchie e-commerce concrete.
- Le quattro schermate condividono oggi un placeholder generico; vanno sostituite con
  composizioni specifiche, non con un mega-widget parametrico.
- La readiness di TASK-011 è già asincrona e testabile e può alimentare gli stati
  Catalogo senza introdurre rete.
- `AppBrand.effectiveDisplayName` è l'unica fonte autorizzata per il nome pubblico
  provvisorio.
- I cataloghi ARB coprono es, it, en e zh-Hans; la policy es-CL primaria deve diventare
  esplicita, il bundle tecnico `app_zh` deve restare sincronizzato e tutte le nuove
  stringhe devono essere complete.
- Il formatter CLP esiste già ed è testato; TASK-012 ne preserva il contratto ma non
  mostra importi, perché non esistono dati commerciali.
- I P3 TASK-002 su scroll/bounds e larghezza placeholder sono candidati naturali:
  verranno chiusi con layout specifici e test di raggiungibilità.

### Approccio

1. Definire piccoli modelli/port di presentazione per stato Catalogo e Account,
   mantenendo il runtime guest e senza repository remoto.
2. Costruire componenti condivisi soltanto per responsabilità ricorrenti: page
   scaffold, section header, empty/status surface e action card.
3. Implementare Home, Catalogo, Carrello e Account con copy ARB completa e CTA
   collegate alle branch esistenti.
4. Collegare la sola readiness esistente agli stati Catalogo e il port account
   temporaneo al messaggio customer-safe; nessuna query o auth.
5. Rafforzare temi/tokens e locale es-CL soltanto dove i nuovi widget lo richiedono.
6. Coprire singoli stati, fallback, Semantics, 48 dp, light/dark, 200%, viewports,
   scroll, tab e back con unit/widget test.
7. Eseguire flusso guest automatico e smoke reali Android/iOS, build, scan e gate
   completi.
8. Consegnare lo SHA tecnico a reviewer read-only distinti per UI/a11y e
   architettura/security.

### Rischi

- **UI ingannevole**: distinguere sempre future state e dati reali, senza card
  commerciali sintetiche.
- **Confusione TASK-020**: mantenere guest runtime e port senza OAuth, callback,
  storage o token.
- **Copia involontaria**: usare soltanto pattern astratti e Material Icons pubbliche,
  con composizione e palette proprie.
- **Overflow a 200%**: evitare row rigide, usare wrap/scroll e testare bounds reali.
- **Semantics duplicate**: escludere icone decorative e assegnare heading/action una
  sola volta.
- **Retry ambiguo**: delegare al controller readiness esistente e offrirlo solo nello
  stato recuperabile.
- **Stato tab perso**: preservare indexed stack e testare identità del subtree e
  posizione di scroll.
- **Scope creep del design system**: aggiungere solo token/widget consumati da più
  schermate o con responsabilità autonoma.
- **Flakiness/avatar unsafe**: accettare soltanto una rappresentazione visuale già
  validata/iniettata, rendere deterministico il fallback e non leggere metadata o rete
  in TASK-012.
- **Nome/app bar lungo**: provare brand lungo, quattro locale e testo 200% anche nel
  viewport landscape compatto.
- **Leak/staging writes**: nessuna mutazione remota e nessun valore locale nelle
  evidence.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Planning pronto**: CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION
- **Autorizzazione USER_APPROVER**: ricevuta e applicata dal prompt end-to-end il
  2026-07-30
- **Transizione**: PLANNING -> EXECUTION
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Execution — `CODEX_EXECUTOR`

Autorizzata. L'implementazione tecnica non è ancora iniziata.

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

Non iniziata.

## Fix — `CODEX_FIXER`

Non iniziato.

## Chiusura

- **Conferma utente**: condizionata già ricevuta; non ancora applicabile
- **Merge autorizzato da USER_APPROVER**: sì, soltanto dopo review finale approvata,
  CI e PR milestone
- **Follow-up candidate**: TASK-020, senza attivazione nel closeout TASK-012
- **Riepilogo finale**: non disponibile
- **Data completamento**: non disponibile
