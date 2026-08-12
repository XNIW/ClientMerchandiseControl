# TASK-016 — Dettaglio prodotto e disponibilità commerciale

## Informazioni generali

- **Task ID**: TASK-016
- **Titolo**: Dettaglio prodotto e disponibilità commerciale
- **File task**: `docs/TASKS/TASK-016-product-detail-commercial-availability.md`
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-02
- **Ultimo aggiornamento**: 2026-08-02
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-016/`
- **Handoff**: CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW

## Dipendenze

- **Dipende da**: TASK-010, TASK-014
- **Checkpoint consumati**: TASK-013, TASK-014 e TASK-015
- **Sblocca**: TASK-018, TASK-023

## Scope

- consumare esclusivamente il RPC pubblico `storefront_product_detail_v1`;
- aggiungere DTO/repository/controller strict per publication UUID e catalog version;
- creare route prodotto guest raggiungibile da Home, Catalogo e risultati Search;
- mostrare nome, descrizione, categoria, marca pubblica, immagine `detail`, prezzo CLP,
  compare-at, sconto, promozione e disponibilità commerciale;
- mostrare capability ritiro/consegna/prenotazione senza quantità stock precise;
- gestire loading, unpublished/unavailable, offline, payload invalido e retry;
- mantenere navigazione back, focus, Semantics, dark mode, 200% e device matrix;
- verificare dettaglio reale e prodotto non pubblicato su staging Android/iOS.

## Non incluso

- stock preciso o accesso inventory operativo;
- preferiti, condivisione e deep link esterno di TASK-018;
- carrello e quantità di TASK-023;
- nuova proiezione disponibilità di TASK-024;
- cache SQLite/offline persistente di TASK-017;
- write backend o production.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Il client usa solo Product Detail v1 e nessun dato interno/Storage diretto | STATIC/SECURITY |
| CA-02 | UUID, status, API/catalog version e item sono validati strict e fail-closed | UNIT |
| CA-03 | Card Home/Catalog/Search aprono la stessa route prodotto pubblica | WIDGET/INTEGRATION |
| CA-04 | Nome, descrizione, categoria, marca, prezzi/sconto/promo e immagine detail sono reali | WIDGET/INTEGRATION |
| CA-05 | Disponibilità e capability fulfillment sono commerciali, senza stock preciso | UNIT/WIDGET |
| CA-06 | Loading, unavailable/unpublished, offline, invalid payload e retry sono onesti | UNIT/WIDGET |
| CA-07 | Risposte stale/dispose e catalog version incoerenti non aggiornano la UI | UNIT |
| CA-08 | Back/focus/Semantics/dark/200%/locale/device matrix restano verdi | WIDGET |
| CA-09 | CI, build e smoke staging Android/iOS sono PASS sullo SHA candidato | CI/BUILD/INTEGRATION |

## Test case

| Test | Criteri | Procedura attesa |
|---|---|---|
| T-01 | CA-01, CA-02 | payload detail valido/malevolo, UUID e allowlist RPC |
| T-02 | CA-03 | tap card da Home/Catalog/Search e back route |
| T-03 | CA-04, CA-05 | rendering completo con promo, immagini e sei availability |
| T-04 | CA-06 | loading, offline, unavailable, malformed e retry |
| T-05 | CA-07 | risposta stale, dispose e catalog version mismatch |
| T-06 | CA-08 | Semantics, focus, dark, 200%, locale e viewport matrix |
| T-07 | CA-09 | gate completo e smoke detail published/unpublished staging Android/iOS |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Route usa publication UUID opaco | È l'identificatore pubblico già contrattuale, non il prodotto inventory | ATTIVA |
| D-02 | Un solo controller detail per route | Isola lifecycle/cancellation e impedisce stato condiviso stale | ATTIVA |
| D-03 | La UI usa variante immagine `detail` pubblica | Qualità adeguata senza esporre bucket interno | ATTIVA |
| D-04 | Availability resta enum commerciale senza quantità | Mantiene il confine Storefront minimizzato | ATTIVA |
| D-05 | Azioni favorite/share/cart restano ai task proprietari | Evita placeholder o mutazioni premature | ATTIVA |

## Planning — `CODEX_PLANNER`

### Analisi

- TASK-010 espone già `storefront_product_detail_v1(shop_slug, publication_id)` con
  status/version/item e grant anon/auth;
- il payload item riusa la shape pubblica già validata dalla Home/Catalog DTO;
- le card non hanno ancora affordance/tap e il router contiene solo le quattro branch;
- unavailable copre shop o pubblicazione non visibile senza rivelarne l'esistenza;
- cache persistente, favorite/share e cart appartengono ai task successivi.

### Approccio autorizzato

1. aggiungere model/DTO/repository detail con UUID bounded e query/version check;
2. creare controller family auto-dispose con cancellation e stati fail-closed;
3. aggiungere route annidata prodotto e navigazione da ogni card;
4. costruire detail screen accessibile con immagine, pricing e fulfillment pubblico;
5. aggiungere unit/widget/router/security e smoke staging published/unpublished;
6. eseguire gate completo, CI e smoke Android/iOS sullo stesso SHA;
7. consegnare a `VALIDATED_PENDING_INTEGRATED_REVIEW` soltanto con checkpoint verde.

### Rischi

- ID interno esposto: accettare soltanto publication UUID già presente nel contratto;
- route non valida: fail-closed senza RPC;
- prodotto paused/unpublished: stesso stato unavailable, nessuna enumerazione;
- risposta stale: cancellation e request generation route-scoped;
- immagine/memoria: `detail` versionata con decode bounded e placeholder;
- scope creep: nessuna azione favorite/share/cart prima dei task proprietari.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: prompt release train 2026-08-01

## Execution — `CODEX_EXECUTOR`

### Modifiche completate

- DTO/repository strict e unico RPC allowlisted `storefront_product_detail_v1`, con
  UUID bounded, catalog version e identità response/request fail-closed;
- controller family auto-dispose con readiness, cancellation, generation guard, retry
  e unavailable non enumerabile;
- route guest `/product/:publicationId` raggiungibile dalla card condivisa di
  Home/Catalog/Search e navigazione back verificata;
- dettaglio localizzato con dati pubblici, immagine `detail` bounded, prezzi CLP,
  promozione, sei availability commerciali e capability fulfillment senza quantità;
- smoke reale published/unpublished guest su Android Emulator e iOS Simulator.

### Difetti corretti durante Execution

- stato verticale reso scrollabile e bounded per evitare overflow a testo 200% in
  compact landscape;
- live harness corretto con `ensureVisible` dopo il primo tentativo Android, che aveva
  individuato la card fixture fuori viewport e non aveva aperto la route;
- risposta con publication ID differente e route UUID invalida bloccate prima di
  pubblicare dati o fare rete rispettivamente.

### Gate eseguiti

- revision set Client `242e631805b569a49a0217c4129b1586e8ad1dbf`, PR `#5` draft;
- `scripts/check.sh`: security 388 file, governance 8/8, architecture 7/7, l10n,
  format, analyze, 282 test, coverage 3.147/3.814 linee (82,51%), Android debug e iOS
  Simulator debug: `PASS`;
- CI Client `30735374419`: Quality 3m26s, iOS 3m08s, Android 7m44s, 3/3 `PASS`;
- Product Detail Android Emulator live: primo tentativo `FAIL` per tap harness fuori
  viewport; regressione corretta; candidato finale 1/1 `PASS` in 17 s;
- Product Detail iOS Simulator live: 1/1 `PASS` in 3 s;
- APK staging SHA-256
  `53ade17f1c971277bba087078da2c4ea2ac138f1f3014cabfb322615752bc180`;
- Runner staging executable SHA-256
  `940451bc707093f789901c1cf705140b7a50a548ff2f19f8cb0aeb6f9d1e488b`;
- production write: `NOT_RUN`; production invariata.

### Matrici

CA-01..CA-09 e T-01..T-07: `PASS`. Evidence sintetica:
`docs/TASKS/EVIDENCE/TASK-016/README.md`.

### Handoff

`CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`. Nessuna review formale è stata
eseguita e TASK-016 non è `DONE`.

## Checkpoint release train — `CODEX_EXECUTOR`

TASK-016 è `VALIDATED_PENDING_INTEGRATED_REVIEW`: implementazione, gate completo, CI e
smoke staging Android/iOS sono verdi sul revision set registrato. Production è
invariata; nessuna review formale intermedia è stata eseguita. Il task successivo
autorizzato è TASK-017.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.
