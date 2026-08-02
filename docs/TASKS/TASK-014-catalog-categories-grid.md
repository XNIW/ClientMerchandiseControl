# TASK-014 — Categorie e griglia catalogo con immagini

## Informazioni generali

- **Task ID**: TASK-014
- **Titolo**: Categorie e griglia catalogo con caricamento immagini
- **File task**: `docs/TASKS/TASK-014-catalog-categories-grid.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-02
- **Ultimo aggiornamento**: 2026-08-02
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-014/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Dipendenze

- **Dipende da**: TASK-010, TASK-011, TASK-012
- **Checkpoint consumati**: TASK-009 e TASK-013
- **Sblocca**: TASK-015, TASK-016, TASK-017, TASK-019

## Scope

- estendere il data layer Storefront con categorie paginate e catalog page;
- consumare esclusivamente `storefront_categories_v1` e `storefront_catalog_v1`;
- modellare cursor opaco, catalog version, sort restituito e pagina immutabile;
- implementare griglia adattiva, keyset infinite scrolling e pull-to-refresh;
- permettere la selezione della categoria pubblica senza query interne;
- mostrare immagini `card` pubbliche con lazy loading, placeholder ed errore sicuro;
- preservare posizione scroll e selezione categoria quando si cambia tab;
- gestire initial load, load-more, empty, offline, unavailable, retry e catalog changed;
- coprire compact/landscape/large, dark mode, text scale 200%, Semantics e quattro locale;
- verificare guest catalog reale su staging Android e iOS.

## Non incluso

- ricerca, disponibilità/sconto e ordinamenti cliente completi di TASK-015;
- dettaglio prodotto e route dedicata TASK-016;
- cache SQLite persistente/offline-first TASK-017;
- preferiti e deep link TASK-018;
- tuning 20.000 prodotti e budget finale TASK-019;
- write backend o production.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Il client usa solo i due RPC pubblici versionati e nessuna tabella/bucket interno | STATIC/SECURITY |
| CA-02 | DTO rifiuta shape, status, cursor, versioni, CLP e URL incoerenti | UNIT |
| CA-03 | Repository applica keyset cursor, limit bounded, timeout e cancellazione | UNIT |
| CA-04 | Griglia adattiva mostra categorie e prodotti reali senza duplicati | WIDGET/INTEGRATION |
| CA-05 | Infinite scroll carica una pagina alla volta e gestisce fine/error/retry | UNIT/WIDGET |
| CA-06 | Pull-to-refresh e `catalog_changed` ricominciano atomicamente dalla prima pagina | UNIT/WIDGET |
| CA-07 | Selezione categoria filtra server-side e preserva scroll/stato per tab | WIDGET |
| CA-08 | Immagini pubbliche hanno lazy loading, placeholder/error e nessun path interno | WIDGET/SECURITY |
| CA-09 | Stati e griglia sono accessibili/localizzati senza overflow nella device matrix | WIDGET |
| CA-10 | CI, build e smoke staging Android/iOS sono PASS sullo SHA candidato | CI/BUILD/MANUAL |

## Test case

| Test | Criteri | Procedura attesa |
|---|---|---|
| T-01 | CA-01, CA-02 | payload valido/malevolo, unknown key, cursor/version mismatch |
| T-02 | CA-03, CA-05 | due pagine keyset, duplicate suppression, single-flight e cancel |
| T-03 | CA-06 | refresh, catalog changed e risposta stale dopo cambio categoria |
| T-04 | CA-04, CA-07 | categorie, griglia, selezione e ritorno tab con scroll preservato |
| T-05 | CA-08 | loading/success/error immagine e URL pubblico soltanto |
| T-06 | CA-09 | es/it/en/zh-Hans, dark, 200%, compact/landscape/large, Semantics |
| T-07 | CA-10 | gate completo e smoke guest staging Android/iOS |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Cursor resta opaco al client e viene restituito al server invariato | Evita offset o ricostruzioni client fragili | ATTIVA |
| D-02 | Prima pagina e load-more hanno stati/errori separati | Un errore incrementale non deve cancellare dati già visibili | ATTIVA |
| D-03 | `catalog_changed` invalida l'intera sequenza e riparte da pagina uno | Non mescolare versioni differenti del catalogo | ATTIVA |
| D-04 | Nessuna cache persistente prima di TASK-017 | Evita uno storage locale parziale fuori dal task dedicato | ATTIVA |
| D-05 | La card Home viene riusata solo dove semanticamente adatta | Riduce duplicazione senza imporre layout Home alla griglia | ATTIVA |

## Planning — `CODEX_PLANNER`

### Analisi

- `CatalogScreen` è una shell con controlli disabilitati e nessun data layer paginato;
- il backend staging espone già categorie e catalogo con cursor keyset e catalog version;
- `StatefulShellRoute.indexedStack` preserva il ramo Catalogo, ma serve uno scroll
  controller stabile per dimostrare il mantenimento della posizione;
- `StorefrontProductCard` copre CLP/sconto/immagine, ma la collection Home usa `Wrap`
  e non è adatta a 20.000 elementi;
- persistenza disco, ricerca e filtri avanzati restano nei task successivi.

### Approccio autorizzato

1. introdurre page model, DTO strict e metodi repository categories/catalog;
2. aggiungere controller Riverpod con request generation, cursor e single-flight;
3. sostituire la shell con CustomScrollView/Grid sliver e category selector;
4. implementare refresh, load-more threshold, retry incrementale e catalog reset;
5. riusare la card pubblica con chiavi catalogo e stati immagine testabili;
6. aggiungere unit/widget/security/device matrix e smoke staging live;
7. consegnare a `VALIDATED_PENDING_INTEGRATED_REVIEW` solo con checkpoint verde.

### Rischi

- doppio load-more: single-flight e cursor consumed una sola volta;
- risposta stale: generation guard per refresh/categoria/dispose;
- catalog version mutata: reset atomico senza concatenare pagine;
- nested scroll/jank: un solo CustomScrollView con SliverGrid;
- immagini e memoria: URL card versionato, lazy build e dimensionamento decode bounded;
- scope creep TASK-015/017: nessuna ricerca avanzata né DB locale.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: prompt release train 2026-08-01

## Execution — `CODEX_EXECUTOR`

In avvio.

## Checkpoint release train — `CODEX_EXECUTOR`

Da compilare dopo i gate TASK-014. Nessuna review formale intermedia.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.
