# TASK-002 — Product Scope, Branding Foundation, UX Principles e Design Tokens

## Informazioni generali

- **Task ID**: TASK-002
- **Titolo**: Product scope definitivo, branding foundation, UX principles e design
  tokens
- **File task**: `docs/TASKS/TASK-002-product-scope-branding-design-system.md`
- **Stato**: ACTIVE
- **Fase**: FIX
- **Responsabile**: CODEX_FIXER
- **Data creazione**: 2026-07-30
- **Ultimo aggiornamento**: 2026-07-30
- **Ultimo agente**: CODEX_REVIEWER
- **DONE**: NO
- **Merge**: NO
- **User approval**: GRANTED_BY_END_TO_END_PROMPT
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-002/`
- **Handoff**: CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX

## Dipendenze

- **Dipende da**: TASK-001 `DONE`, PR #1 merged con commit
  `f6bd88263fe8369c9ececa38367f629f3d1a929f`
- **Sblocca**: TASK-003; fornisce foundation a TASK-012 e input non definitivo a TASK-038

## Scope

- product vision, problema, valore cliente/negozio, mercato Cile e single-store iniziale;
- target users, jobs-to-be-done e journey futuri di alto livello;
- MVP, post-MVP, non-obiettivi e tracciabilità con TASK-003–TASK-042;
- principi UX, commercial truth, accessibilità, resilienza e privacy by default;
- architettura brand con separazione tra project/package/technical/public/legal/store;
- tono di voce e regole di contenuto/localizzazione per es, it, en e zh-Hans;
- design token per spacing, radii, sizes, breakpoint, motion e semantic colors;
- Material 3 con light/dark theme, font di sistema e `ThemeExtension` semantica;
- componenti foundation minimi e realmente usati dalla shell esistente;
- refactor di shell, placeholder, layout responsive e banner development per usare i token;
- test unit/widget, build Android/iOS Simulator, smoke reali, evidence, ADR e review;
- chiusura e merge soltanto alle condizioni già autorizzate da `USER_APPROVER`.

## Contesto

ClientMerchandiseControl è il client Flutter pubblico dell'ecosistema Merchandise
Control. Il futuro client consuma soltanto il dominio Storefront controllato da Admin
Console; non accede all'inventory operativo e non decide pubblicazione, prezzi, stock o
fulfillment.

L'audit non ha trovato un public brand, logo, palette o legal entity autorevoli. I nomi
presenti negli altri prodotti sono identità tecniche o operative non coerenti tra loro.
TASK-002 formalizza quindi una foundation sostituibile e onesta, senza inventare un
marchio. Il seed teal esistente resta una palette provvisoria accessibile; marketing
visual, launcher/store icon e identità definitiva restano di TASK-038.

## Non incluso

- Supabase, migrazioni, schema Storefront, RLS, grant, query, RPC o networking;
- prodotti, categorie, prezzi, sconti, immagini o disponibilità reali o simulati;
- autenticazione, profilo, preferiti persistenti, carrello, checkout, prenotazioni,
  ordini, consegne, notifiche o pagamenti;
- contratti cross-repo di TASK-003 o environment strategy di TASK-004;
- productizzazione data-backed della shell, health state live e acceptance estesa di
  TASK-012;
- logo, public brand approvato, legal name, font custom, store icon, release metadata o
  pubblicazione store di TASK-038;
- analytics, crash reporting, telemetria, tablet layout finale o redesign di feature future;
- dipendenze nuove speculative, aggiornamento Flutter o upgrade automatico dei package;
- modifiche a repository esterni.

## File coinvolti

- `docs/PRODUCT/`, `docs/ARCHITECTURE/`, `docs/DECISIONS/`;
- `docs/MASTER-PLAN.md`, `docs/AI_WORKLOG.md`, questo task e relative evidence;
- `lib/app/branding/`, `lib/app/design_system/`, `lib/app/theme/`;
- shell, widget condivisi, screen placeholder e localizzazioni esistenti;
- test unit/widget pertinenti;
- nessun file backend o repository esterno.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | TASK-001 è `DONE` e PR #1 è merged prima dell'attivazione | GIT/STATIC |
| CA-02 | Planning, scope, non-scope, dipendenze, criteri e test case sono completi | STATIC |
| CA-03 | PRODUCT-SCOPE definisce prodotto, mercato, utenti, valore e confini | STATIC |
| CA-04 | MVP-SCOPE è coerente con TASK-003–TASK-042 e non implementa task futuri | STATIC |
| CA-05 | Target users e jobs sono definiti senza stereotipi o dati inventati | STATIC |
| CA-06 | I principali user journey futuri, inclusi failure path, sono documentati | STATIC |
| CA-07 | I principi UX includono prezzi, disponibilità, accessibilità e connessione debole | STATIC |
| CA-08 | Nome tecnico, nome pubblico e marketing asset sono separati | STATIC/UNIT |
| CA-09 | Un marchio è usato soltanto con fonte autorevole verificata | STATIC/GIT |
| CA-10 | Nome/logo non definitivi restano configurazione provvisoria, non invenzione | STATIC/UNIT |
| CA-11 | Tono e localizzazione per es, it, en e zh-Hans sono documentati e coerenti | STATIC/WIDGET |
| CA-12 | Esiste un design system semanticamente strutturato e realmente consumato | STATIC/UNIT/WIDGET |
| CA-13 | Spacing, radii, size, breakpoint e duration sono centralizzati | UNIT/STATIC |
| CA-14 | ColorScheme e ThemeExtension gestiscono light e dark mode | UNIT/WIDGET |
| CA-15 | Nessun colore semanticamente rilevante resta hardcoded nei feature widget | STATIC |
| CA-16 | Shell e placeholder usano realmente i token | STATIC/WIDGET |
| CA-17 | Quattro destinazioni, route, stato tab e back non regrediscono | WIDGET/ANDROID_EMU/IOS_SIM |
| CA-18 | La UI funziona con text scale 200% | WIDGET/ANDROID_EMU/IOS_SIM |
| CA-19 | Nessun overflow evidente in portrait, landscape o finestra ampia | WIDGET/ANDROID_EMU/IOS_SIM |
| CA-20 | Touch target e Semantics restano accessibili e lo stato non dipende solo dal colore | UNIT/WIDGET/ANDROID_EMU/IOS_SIM |
| CA-21 | Nessun prodotto, prezzo o stock finto viene introdotto | STATIC/WIDGET/ANDROID_EMU/IOS_SIM |
| CA-22 | Nessuna chiamata Supabase o richiesta di rete viene aggiunta | STATIC/UNIT/ANDROID_EMU/IOS_SIM |
| CA-23 | Nessun secret, dato reale o URL production viene introdotto | SECURITY/GIT |
| CA-24 | Nessuna dipendenza speculativa viene introdotta | STATIC/GIT |
| CA-25 | Format, analyze, script e tutti i test sono `PASS` | FORMAT/ANALYZE/UNIT/WIDGET |
| CA-26 | Android debug build è `PASS` | BUILD_ANDROID |
| CA-27 | iOS Simulator debug build è `PASS` | BUILD_IOS |
| CA-28 | Android Emulator smoke è `PASS` | ANDROID_EMU |
| CA-29 | iOS Simulator smoke è `PASS` | IOS_SIM |
| CA-30 | Light e dark theme sono verificati con widget test e smoke visivo | WIDGET/ANDROID_EMU/IOS_SIM |
| CA-31 | Review indipendente senza P0, P1 o P2 aperti | STATIC/MANUAL |
| CA-32 | CI sullo SHA finale è `PASS`, con job/step/annotation ispezionati | CI |
| CA-33 | Documentazione, evidence, worklog e Master Plan sono coerenti | STATIC/GIT |
| CA-34 | `DONE` segue review `APPROVED` e autorizzazione del prompt end-to-end | STATIC/GIT |
| CA-35 | Dopo il merge, PR merged e `main` locale coincide con `origin/main` | GIT |
| CA-36 | TASK-003 resta `TODO`, nessun altro task è attivato e il progetto torna `IDLE` | STATIC/GIT |
| CA-37 | I quattro repository esterni conservano ref e dirty state iniziali; zero write | GIT |
| CA-38 | Package, bundle identifier e soli target Android/iOS restano invariati | STATIC/GIT |

CA-32 viene attestato esternamente dopo il push del commit di closeout, per evitare il
ciclo evidence -> commit -> CI. CA-35 è un controllo terminale post-merge e viene
registrato nel report finale; nessuno dei due può essere pre-dichiarato `PASS`.

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01 | GIT | Verificare PR #1 merged e merge commit presente su `main` prima del branch |
| T-02 | CA-02 | STATIC | Verificare completezza e autorizzazione del Planning |
| T-03 | CA-03, CA-04 | STATIC | Verificare product/MVP scope e tracciabilità backlog |
| T-04 | CA-05 | STATIC | Verificare profili, jobs, vincoli e assenza di stereotipi |
| T-05 | CA-06 | STATIC | Verificare journey nominali, errori e commercial revalidation |
| T-06 | CA-07 | STATIC | Applicare checklist UX/commercial truth/accessibilità/resilienza |
| T-07 | CA-08, CA-09, CA-10 | STATIC/GIT/UNIT | Verificare registry brand, fonti/ref e fallback provvisorio |
| T-08 | CA-11 | STATIC/WIDGET | Verificare parità ARB, quattro locale e fallback es/es-CL |
| T-09 | CA-12, CA-13 | UNIT/STATIC | Verificare invarianti e ordine di tutti i token |
| T-10 | CA-12, CA-14, CA-30 | UNIT/WIDGET | Verificare Material 3, ThemeExtension, copyWith, lerp, light/dark |
| T-11 | CA-14, CA-20, CA-30 | UNIT | Verificare contrasto ragionevole delle coppie semantiche |
| T-12 | CA-15, CA-16 | STATIC | Eseguire scan colori, EdgeInsets e BorderRadius con allowlist motivata |
| T-13 | CA-16, CA-20 | WIDGET | Verificare consumo token e Semantics dei componenti foundation |
| T-14 | CA-17 | WIDGET | Navigare quattro tab, ritorno, persistenza branch e back verso Home |
| T-15 | CA-18, CA-19 | WIDGET | Provare 320px/200%, landscape/200% e finestra ampia su tutte le tab |
| T-16 | CA-20 | WIDGET | Misurare touch target e verificare heading, label e live region |
| T-17 | CA-21 | STATIC/WIDGET | Cercare e verificare assenza di prodotto/prezzo/stock finto |
| T-18 | CA-22 | STATIC/UNIT/ANDROID_EMU/IOS_SIM | Verificare zero networking nuovo, offline boot e log runtime |
| T-19 | CA-23 | SECURITY/GIT | Eseguire secret/prod URL/artifact scan mirato al diff e repository |
| T-20 | CA-24 | STATIC/GIT | Confrontare pubspec/lock e ispezionare `pub deps/outdated` |
| T-21 | CA-25 | FORMAT/ANALYZE/UNIT/WIDGET | Eseguire tutti i quality gate e script |
| T-22 | CA-26, CA-27 | BUILD_ANDROID/BUILD_IOS | Eseguire build APK debug e iOS Simulator debug |
| T-23 | CA-28, CA-30 | ANDROID_EMU | Installare, avviare, navigare e verificare light/dark/layout/log |
| T-24 | CA-29, CA-30 | IOS_SIM | Installare, avviare, navigare e verificare light/dark/layout/log |
| T-25 | CA-31 | MANUAL/STATIC | Eseguire review indipendenti product, Flutter, a11y e Git/security |
| T-26 | CA-32 | CI | Ispezionare run, job, step, annotation e SHA del closeout |
| T-27 | CA-33, CA-34, CA-36 | STATIC/GIT | Verificare tracking, autorizzazione, `DONE` e nessun task successivo |
| T-28 | CA-35, CA-36 | GIT | Dopo merge verificare PR, SHA, branch, main e worktree |
| T-29 | CA-37 | GIT | Confrontare HEAD e fingerprint di stato iniziali/finali dei repository esterni |
| T-30 | CA-38 | STATIC/GIT | Confrontare target, package Dart, applicationId e bundle identifier con la baseline |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | User-approved end-to-end execution override: il prompt corrente autorizza Planning, Execution, Review, Fix, re-review, `DONE` e merge di TASK-002 solo con gate reali `PASS` e zero P0/P1/P2 aperti. | Registrare l'autorità limitata a TASK-002 | ATTIVA |
| D-02 | `technicalDisplayName` resta centralizzato; public brand, legal entity, store display name, tagline, logo e marketing asset sono `PROVISIONAL/UNVERIFIED`. | Nessuna fonte cross-repo autorizza un'identità cliente definitiva | ATTIVA |
| D-03 | Il seed teal `#245C55` resta palette provvisoria; Material `ColorScheme` è la base e una sola ThemeExtension copre colori semantici non espressi dal framework. | Preservare continuità e accessibilità senza inventare il brand | ATTIVA |
| D-04 | TASK-002 applica la foundation alla shell placeholder esistente; TASK-012 resta owner della productizzazione data-backed e dell'acceptance estesa. | Evitare sovrapposizione e scope creep | ATTIVA |
| D-05 | Font di sistema e zero nuove dipendenze sono la scelta prevista. | Flutter SDK copre la foundation richiesta | ATTIVA |
| D-06 | Le letture cross-repo sono read-only e referenziate per SHA; dirty state preesistenti non vengono corretti. | Preservare confini e lavoro esterno | ATTIVA |
| D-07 | L'emendamento recovery del `USER_APPROVER` richiede backup non distruttivo e smoke automatico reale Android/iOS. È ammessa soltanto la dev dependency `integration_test` fornita dal Flutter SDK; restano vietate nuove dipendenze runtime o esterne. I tipi generici `SMOKE` sono normalizzati in `ANDROID_EMU` e `IOS_SIM`. | Colmare CA-28/CA-29 senza dipendere dalla GUI e riallineare i test alla tassonomia del protocollo | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Definire in modo verificabile il prodotto cliente, una brand foundation onesta e
sostituibile, principi UX/content e un design system semantico minimo applicato alla
shell Flutter già esistente, senza anticipare funzionalità commerciali o backend.

### Analisi

- TASK-001 è merged e la baseline Flutter 3.44.8 è pulita.
- Product/MVP scope attuali sono corretti ma troppo sintetici per mercato, attori,
  journey, non-goal, metriche e tracciabilità.
- Il brand audit non trova public name/logo/palette/font ufficiali. Nomi e colori degli
  altri prodotti sono tecnici, operativi o conflittuali.
- La UI corrente ha hardcoding limitato a spacing/radius/size e può essere tokenizzata
  senza redesign.
- `StatefulShellRoute.indexedStack`, quattro route, back verso Home, l10n e bootstrap
  offline sono invarianti da preservare.
- Il copy placeholder contiene gergo di delivery (`task`, `contract`, `foundation`) da
  sostituire con testo cliente semplice; il banner backend resta tecnico e debug-only.
- TASK-012 e TASK-038 mantengono ownership rispettivamente di shell data-backed e asset/
  identità release definitive.

### Approccio

1. Espandere documentazione prodotto, utenti/jobs, journey, UX, brand e content/l10n.
2. Accettare ADR-007 e ADR-008, aggiornare l'architettura mobile.
3. Centralizzare token dimensionali/motion e semantic colors light/dark.
4. Mantenere `AppTheme` come composition root e applicare token a layout, placeholder,
   card, navigation e banner accessibile.
5. Aggiornare copy ARB senza introdurre dati o feature simulati.
6. Aggiungere test deterministici per brand, token, tema, contrasto, componenti,
   navigazione, localizzazione, text scale, landscape e Semantics.
7. Eseguire gate, build e smoke reali; produrre evidence concise.
8. Pubblicare una PR reviewable, effettuare review indipendenti, correggere P0–P2 e
   chiudere soltanto con CI finale verde.

### Rischi

- **Brand non verificato**: mitigato con campi nullable/provisional e rinvio a TASK-038.
- **Sovrapposizione TASK-012**: mitigata limitando l'applicazione alla shell placeholder.
- **Contrasto semantic colors**: mitigato con test ratio light/dark e verifica visiva.
- **Text scale/landscape**: mitigato con widget test su tutte le tab e smoke reali.
- **Gergo tecnico cliente**: mitigato con riscrittura ARB e content review.
- **CI/build/emulator instabili**: retry limitati e stato `BLOCKED` solo per cause esterne.
- **Evidence post-CI/post-merge non versionabile nello stesso SHA**: attestazione esterna
  GitHub e report finale, senza inventare `PASS` nel commit.

### Handoff a Execution

- **Planning pronto**: CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION
- **Autorizzazione USER_APPROVER**: ricevuta dal prompt end-to-end il 2026-07-30
- **Transizione**: PLANNING -> EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Timestamp**: 2026-07-30T12:54:08-04:00

## Execution — `CODEX_EXECUTOR`

### Implementazione

- ampliati product scope, MVP, utenti/jobs, journey, UX, brand e content/localization
  senza anticipare backend o funzionalità commerciali;
- accettati ADR-007 e ADR-008 e aggiornato il contratto architetturale;
- aggiunti brand registry, token dimensionali/motion e semantic colors light/dark;
- applicati i token a theme, shell, page, banner e placeholder;
- mantenuti `StatefulShellRoute.indexedStack`, quattro destinazioni, back e subtree;
- sostituito gergo tecnico nei placeholder con copy cliente es/it/en/zh-Hans;
- aggiunti test deterministici e smoke reale automatico su Android/iOS;
- applicato l'emendamento D-07 senza nuove dipendenze runtime o esterne.

Commit tecnico verificato:
`ec599758948a303b0862935fcf9ae9003a64aa00`.

### Gate ed evidence

| Gate | Esito | Evidence |
|---|---|---|
| `bash scripts/check.sh` | `PASS`, exit `0` | format, analyze, 59/59 test, build Android/iOS |
| Android Emulator | `PASS`, exit `0` | API 35, integration smoke 1/1 |
| iOS Simulator | `PASS`, exit `0` | iOS 26.5, integration smoke 1/1 |
| Security diff | `PASS` | scan `40f261c3-5a0d-4e50-8603-3c4ab42cc838`, 15/15, 0 finding |
| Dipendenze | `PASS` | `pub deps` e `pub outdated`; solo `integration_test` SDK dev-only |
| Static/Git | `PASS` | raw value, fake commerce, networking, secret, URL e identifier |
| Repository esterni | `PASS` | fingerprint iniziali/finali 4/4 identici |
| Backup recovery | `PASS` | bundle completo e patch branch verificati |

Evidence persistenti:

- `docs/TASKS/EVIDENCE/TASK-002/execution-evidence.md`;
- `docs/TASKS/EVIDENCE/TASK-002/runtime-smoke.md`;
- `docs/TASKS/EVIDENCE/TASK-002/security-diff-scan.md`;
- `docs/TASKS/EVIDENCE/TASK-002/external-repository-integrity.md`;
- `docs/TASKS/EVIDENCE/TASK-002/recovery-backup.md`;
- `docs/TASKS/EVIDENCE/TASK-002/screenshot-manifest.md`;
- matrici in `docs/TASKS/EVIDENCE/TASK-002/README.md`.

Log completi, coverage e artifact build restano locali e non versionati.

### Warning e deviazioni

- iterazioni pre-finali del nuovo integration test hanno rilevato e corretto verifica
  Semantics e teardown; i due run finali sono `PASS`;
- `simctl log erase` non è permesso sul runtime corrente: usato filtro temporale per
  processo, senza conservare log grezzi;
- `aapt2` non è nel `PATH`: controllo ripetuto con path SDK esplicito;
- package già vincolati hanno major più recenti disponibili; nessun upgrade rientra nello
  scope.

Nessun gate obbligatorio resta `FAIL`, `BLOCKED` o `NOT_RUN`. Nessun file backend,
feature commerciale, dato reale, secret o repository esterno è stato modificato.

### Handoff a Review

- **Transizione**: `EXECUTION -> REVIEW`
- **Esito Executor**: `CODEX_EXECUTION_COMPLETE_TO_REVIEW`
- **Prossimo ruolo**: `CODEX_REVIEWER`
- **Review richiesta**: intent/CA/diff/evidence/runtime/security/Git indipendenti
- **Finding aperti dichiarati dall'Executor**: nessuno; il Reviewer non deve assumere
  corretto questo claim
- **Merge**: vietato prima di review `APPROVED`, CI closeout `PASS` e conferma già
  condizionata del `USER_APPROVER`
- **Timestamp**: `2026-07-30T15:05:10-04:00`

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

Review indipendente read-only eseguita sulla revisione
`92d2697f0577cfb510d0a4bdd323195d6cfb42b2`.

- **Shard**: governance/evidence, Flutter/runtime/security, UI/accessibilità.
- **Gate autonomi**: `scripts/check.sh`, smoke Android/iOS e CI
  `30573839944` `PASS`.
- **Finding**: 0 P0, 0 P1, 2 P2, 4 P3.
- **P2 aperti**: stato operativo incoerente nel README root; algoritmo delle
  fingerprint esterne non riproducibile dalla evidence versionata.
- **Esito**: `CHANGES_REQUIRED`.
- **Report**: `docs/TASKS/EVIDENCE/TASK-002/review-report.md`.
- **Transizione**: `REVIEW -> FIX`.
- **Handoff**: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Fix — `CODEX_FIXER`

Non ancora applicati. Il Fix è limitato ai finding registrati nel report.

## Chiusura

- **Conferma utente**: già concessa in forma condizionata dal prompt end-to-end
- **Merge autorizzato da USER_APPROVER**: sì, soltanto dopo review APPROVED, gate
  obbligatori e CI finale `PASS`
- **Follow-up candidate**: TASK-003, non attivato
- **Riepilogo finale**: non disponibile prima di Execution e Review
- **Data completamento**: non applicabile
