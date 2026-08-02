# TASK-019 — Catalog performance e acceptance su dataset esteso

## Informazioni generali

- **Task ID**: TASK-019
- **Titolo**: Catalog performance e acceptance su dataset esteso
- **File task**: `docs/TASKS/TASK-019-catalog-performance-extended-dataset.md`
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-02
- **Ultimo aggiornamento**: 2026-08-02
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-019/`
- **Handoff**: CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW

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

### Modifiche completate

- audit competitivo bounded e originale, senza screenshot o asset proprietari;
- design system Material 3 consolidato e superfici Home, Catalogo, card, Detail,
  Preferiti, Account e shell rese responsive, accessibili e data-backed;
- Admin Storefront modernizzato sullo stack esistente con ricerca, filtri persistenti,
  bulk selection, status chip, editor/preview responsive e navigazione da tastiera;
- bootstrap guest disaccoppiato da Auth e diagnostica backend, trasporto pubblico
  allow-listed e Home resa disponibile prima della persistenza cache;
- reconnect/cache race eliminata e test live resi indipendenti dagli ID effimeri;
- migration additiva `20260802043000_storefront_v1_catalog_performance.sql` con
  indici keyset/FTS, hydration bounded e fixture/load test idempotente;
- dataset staging da 22.000 prodotti, 100 categorie, 22.000 pubblicazioni, 5.000 link
  promozionali e 69.200 righe equivalenti, con immagini pubbliche e cleanup a zero.

### Gate eseguiti

- Client runtime revision `8f6c67dd3372ee9a6421f7071e58f4c0808f11b1`, PR #5 draft:
  `scripts/check.sh` exit 0 in 98,32 s, 344 test Flutter, coverage
  4.689/5.667 (82,74%), analyze/format/security/governance/architecture e build
  Android debug/iOS Simulator debug `PASS`;
- CI Client `30759482376`: Quality 4m35s, iOS 3m26s, Android 9m01s, 3/3 `PASS`;
- smoke live Android sul runtime equivalente `fd5eb94`: Home, Catalogo, Detail e
  Preferiti 4/4 `PASS` in 2m49s; XCTest esatto `8f6c67d` su iPad (A16) iOS 26.2,
  vera `UIActivityViewController`, 3/3 `PASS`, exit 0 in 11,835 s;
- profilo Android staging: first usable 139 ms, Home data 3.257 ms, catalogo 875 ms,
  search 1.573 ms, detail/deep link 985 ms, favorite 54 ms; 439 frame, p50/p95/p99
  7.814/44.763/101.114 us, cinque frame >100 ms e zero frame >700 ms;
- startup processo Android release arm64, cinque campioni: cold p50/p95/p99
  4.105/4.565/4.565 ms e warm 427/519/519 ms. Il cold process emulator è una
  metrica distinta e supera 3 s; il criterio first usable misurato dal bootstrap
  applicativo resta 139 ms e non viene sostituito o nascosto;
- cache locale 25.000 righe: open 302 ms, write 20k 446 ms, catalog p50/p95/p99
  636/1.319/8.452 us e search 3.262/4.466/7.653 us;
- memoria release arm64 dopo Home: PSS 73.661 KB, RSS 189.492 KB, swap 0; budget
  dichiarato PSS <=200 MB/RSS <=300 MB, zero OOM;
- Admin revision `1f1ba507bbdde96197276738aacd7e290c20f8fe`, PR #67 draft:
  lint/typecheck/unit/integration/build/pgTAP e Playwright locale 1/1 `PASS`; CI
  `30757513891` e Cloudflare build `30757513885` `PASS`;
- staging run `30757512517`, attempt 3, exact Admin SHA, `PASS` in 18m09s:
  catalog p50/p95/p99 27,867/30,114/31,228 ms, search
  594,101/599,739/686,107 ms e detail 1,784/4,923/6,195 ms su 30 campioni;
  indici FTS/keyset osservati, cleanup fixture 0 e production non toccata.

### Tentativi non candidati e correzioni

- install profile iniziale `FAIL` per downgrade rispetto alla build release generata;
  package emulator isolato e rimosso senza modifiche al codice;
- un test profile con slug ordinario `FAIL` per mismatch configurazione; rilanciato
  esplicitamente sul tenant sintetico `task010-load` senza stampare config sensibile;
- il campionamento successivo al cleanup remoto `FAIL` con Home `unavailable`, come
  previsto dal fail-closed della fixture effimera; nessun dato fittizio è stato usato;
- due target iPhone del test Activity Sheet avevano `FAIL` sul requisito popover iPad;
  la causa adattiva è stata isolata e il gate obbligatorio è stato eseguito sul target
  iPad corretto con regressione lifecycle e 3/3 `PASS`.

### Matrici

CA-01..CA-15 e T-01..T-10: `PASS`. Comandi, campioni, percentile, SHA, exit code,
warning e artifact hash sono in `docs/TASKS/EVIDENCE/TASK-019/README.md`.

### Handoff

`CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`. Nessuna review formale è stata
eseguita e TASK-019 non è `DONE`.

## Checkpoint release train — `CODEX_EXECUTOR`

TASK-013..TASK-019 sono `VALIDATED_PENDING_INTEGRATED_REVIEW`; il checkpoint
Milestone 3 è `PASS` sul revision set Client/Admin registrato. Production e relativi
feature flag restano invariati/OFF. Il task successivo autorizzato è TASK-021.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.
