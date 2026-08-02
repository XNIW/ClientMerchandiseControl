# TASK-019 — Catalog performance e acceptance su dataset esteso

## Informazioni generali

- **Task ID**: TASK-019
- **Titolo**: Catalog performance e acceptance su dataset esteso
- **File task**: `docs/TASKS/TASK-019-catalog-performance-extended-dataset.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-02
- **Ultimo aggiornamento**: 2026-08-02
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-019/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Dipendenze

- **Dipende da**: TASK-010, TASK-014, TASK-015, TASK-017, TASK-018
- **Checkpoint consumati**: TASK-013..TASK-018
- **Sblocca**: TASK-037 e checkpoint Milestone 3
- **Repository writer**: un solo writer alla volta, prima Client, poi Admin/Supabase
  soltanto per il work package e i gate autorizzati

## Scope

### Work package `STOREFRONT-V1-UI-HARDENING`

- produrre l'audit competitivo bounded
  `docs/PRODUCT/STOREFRONT-UI-PATTERN-AUDIT.md`, senza screenshot o asset proprietari;
- consolidare Material 3, spacing, radii, elevation, surface, semantic colors,
  typography/prezzi/promozioni/stati, motion, breakpoint, target e content max width;
- rendere originali, moderne, data-backed e accessibili le superfici Client già
  esistenti: shell, Home, Catalogo, product card, Product Detail, Preferiti e Account;
- modernizzare la superficie Storefront già esistente in Admin Console con ricerca,
  filtri, bulk/status, editor/preview responsive e stati loading/error/empty;
- aggiungere visual QA headless bounded per viewport, text scale, tema, locale e
  orientamento; versionare soltanto snapshot canonici con valore di regressione;
- registrare la mappatura del work package a TASK-019, TASK-029, TASK-036, TASK-037 e
  TASK-038; carrello, checkout, ordini e account completo restano implementati nei task
  proprietari quando i relativi contratti esistono.

### Performance e acceptance

- verificare o rigenerare in staging almeno 20.000 prodotti, 100 categorie e 65.000
  righe correlate con immagini, promozioni e mix published/draft/paused;
- misurare cold start, warm start, first usable content, Home, catalog page, search,
  detail, scroll frame time, image decoding, memory, cache cold/warm, offline startup,
  deep link, share e favorite;
- produrre p50/p95/p99 per API/query e benchmark applicativi con warm-up, numero di
  campioni, ambiente e limiti dichiarati;
- verificare SQL con `EXPLAIN (ANALYZE, BUFFERS)` e load test staging; correggere N+1,
  overfetch immagini, rebuild, cache non bounded, duplicati pagination, debounce,
  cancellation e query lente dentro lo scope;
- eseguire gate Client/Admin/Supabase applicabili, smoke headless Android/iOS e CI sul
  revision set candidato;
- mantenere production e feature flag production invariati.

## Non incluso

- dati finti presentati come reali, screenshot proprietari, copie pixel-perfect,
  wording/palette/logo/icone di altri retailer o dark pattern;
- implementazione anticipata di cart, checkout, order queue, notifiche o pagamenti
  prima dei rispettivi contratti TASK-023..TASK-032;
- modifica distruttiva di staging o qualsiasi write production;
- nuovi framework UI se Flutter Material 3 e lo stack Admin corrente sono sufficienti;
- dichiarare device fisico, store upload o rollout production.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Audit bounded documenta pattern generali e fonti senza materiale proprietario | DOC/SECURITY |
| CA-02 | Design system copre light/dark, CLP, quattro locale, breakpoints e target accessibili | UNIT/WIDGET |
| CA-03 | Home esistente è moderna, data-backed e gestisce skeleton/empty/offline/retry | WIDGET/INTEGRATION |
| CA-04 | Catalogo/card/detail hanno gerarchia moderna, griglia adattiva e nessun dato interno | WIDGET/SECURITY |
| CA-05 | Admin Storefront usa stack esistente, layout responsive, preview e keyboard navigation | UNIT/E2E |
| CA-06 | Matrice visual QA canonica non presenta overflow, CTA fuori viewport o testo critico tagliato | WIDGET/GOLDEN |
| CA-07 | Staging contiene almeno 20k prodotti, 100 categorie e 65k righe correlate con cleanup verificabile | INTEGRATION/LOAD |
| CA-08 | First usable content è <=3 s su staging/rete normale e cache warm <=1 s quando realistico | PERFORMANCE |
| CA-09 | Catalog API p95 <=500 ms, search p95 <=750 ms e detail p95 <=400 ms | PERFORMANCE |
| CA-10 | Pagination è deterministica, senza duplicati o salti sotto carico e cancellation | UNIT/LOAD |
| CA-11 | Scroll non ha jank grave; memory e image decoding rispettano un budget dichiarato senza OOM | PERFORMANCE |
| CA-12 | Cold/warm/offline/deep link/share/favorite restano funzionanti sul dataset esteso | INTEGRATION |
| CA-13 | Ogni metrica riporta campioni, p50/p95/p99, durata, comando, SHA ed exit code | EVIDENCE |
| CA-14 | Gate completi e CI applicabili sono PASS sul revision set candidato | CI/BUILD |
| CA-15 | Production è invariata e i flag Storefront/orders/push/payment restano OFF | SECURITY |

## Test case

| Test | Criteri | Procedura attesa |
|---|---|---|
| T-01 | CA-01 | audit read-only bounded e verifica assenza screenshot/asset proprietari |
| T-02 | CA-02, CA-06 | viewport 320×568, 360×800, 390×844, 430×932, 768×1024 e 1024×768; scale 1/1,3/2; light/dark; es-CL/it/en/zh-Hans; portrait/landscape |
| T-03 | CA-03, CA-04 | Home/Catalog/Card/Detail real data, loading/error/empty/offline, Semantics e target |
| T-04 | CA-05 | Admin Storefront responsive, focus/keyboard, bulk/status e preview smartphone in Playwright headless |
| T-05 | CA-07 | seed/load staging idempotente, cardinalità e cleanup residue zero |
| T-06 | CA-08 | cold/warm startup e first usable content tramite integration timing/VM service |
| T-07 | CA-09, CA-10 | load test RPC/API e SQL EXPLAIN con p50/p95/p99 e keyset concorrente |
| T-08 | CA-11 | Flutter timeline, frame timing, memory e image decode/cache bounded |
| T-09 | CA-12 | smoke Android/iOS headless con cache cold/warm/offline, deep link/share/favorite |
| T-10 | CA-13, CA-14, CA-15 | evidence, gate completi, CI esatta, secret scan e production invariata |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | `STOREFRONT-V1-UI-HARDENING` è un work package di TASK-019, non un nuovo task numerato | Rispetta la governance e la mappatura USER_APPROVER a TASK-019/029/036/037/038 | ATTIVA |
| D-02 | Pattern competitivi sono astratti e il risultato resta originale ClientMerchandiseControl | Evita copia di trade dress, asset, wording e dark pattern | ATTIVA |
| D-03 | Le superfici mostrano soltanto dati staging reali o stati esplicitamente vuoti | Nessun prodotto finto può sembrare reale | ATTIVA |
| D-04 | I target performance possono risultare FAIL e vanno corretti o documentati, mai reinterpretati | Un budget misurabile vale soltanto con evidence reale | ATTIVA |
| D-05 | Client, Admin e Supabase hanno writer sequenziali, mai concorrenti | Evita lock e revision set incoerenti | ATTIVA |
| D-06 | Planning ed Execution sono autorizzati dal prompt USER_APPROVER del 2026-08-02 | Consente continuità del release train senza nuova richiesta intermedia | ATTIVA |

## Planning — `CODEX_PLANNER`

### Analisi

- TASK-013..TASK-018 forniscono Home, Catalogo, ricerca, detail, cache, preferiti,
  share e deep link reali; il pass UI deve consolidarli senza sostituire i contratti;
- Admin possiede già Storefront publication/pricing/promotion/image flows e uno stack UI
  verificato; il pass deve riusarlo e restare separato dal futuro order workflow;
- TASK-010 ha già attestato il dataset minimo ma i target iniziali catalog/search non
  erano verdi sul piano NANO; TASK-019 deve rimisurare e correggere la causa primaria;
- la matrice completa non implica migliaia di golden: test parametrizzati coprono il
  reflow e pochi snapshot canonici coprono regressioni visive rilevanti;
- performance Client, RPC e SQL richiede una baseline congelata, campioni ripetibili e
  distinzione tra cache cold/warm e rete.

### Approccio autorizzato

1. audit read-only bounded e inventario visuale/funzionale Client/Admin;
2. token/componenti condivisi e UI Client esistente con test layout/Semantics;
3. UI Admin Storefront sequenziale e Playwright headless;
4. visual QA canonica Android/iOS/Admin e correzione overflow/contrasto/focus;
5. verifica dataset, benchmark baseline e profiling Client/API/SQL;
6. correzioni mirate con regressioni e rerun p50/p95/p99;
7. gate completi, smoke headless, CI, evidence e checkpoint Milestone 3.

### Rischi

- scope creep verso funzioni commerce future: ogni superficie non contrattualizzata
  resta mappata al task proprietario e non viene simulata;
- benchmark falsato da warm-up/cache/rete: ogni scenario separa cold/warm, campioni e
  condizioni;
- repository bloat da golden: snapshot limitati a schermate canoniche, altre matrici
  eseguite come test parametrizzati;
- staging condiviso: seed idempotente con namespace, cardinalità prima/dopo e cleanup;
- refactor opportunistico: modifiche limitate a UI, query e cache realmente misurate.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: prompt headless Storefront v1 2026-08-02

## Execution — `CODEX_EXECUTOR`

In corso. Il primo work package è `STOREFRONT-V1-UI-HARDENING`; nessun risultato o
gate performance è ancora dichiarato.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.
