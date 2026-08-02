# TASK-015 — Ricerca, filtri e ordinamento Storefront

## Informazioni generali

- **Task ID**: TASK-015
- **Titolo**: Ricerca, filtri e ordinamento
- **File task**: `docs/TASKS/TASK-015-search-filters-sorting.md`
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-02
- **Ultimo aggiornamento**: 2026-08-02
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-015/`
- **Handoff**: CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW

## Dipendenze

- **Dipende da**: TASK-010, TASK-014
- **Checkpoint consumati**: TASK-013 e TASK-014
- **Sblocca**: TASK-016, TASK-019

## Scope

- estendere il data layer con il solo RPC pubblico `storefront_search_v1`;
- abilitare ricerca reale con debounce, cancellation e query normalizzata bounded;
- usare i filtri pubblici già contrattuali di `storefront_catalog_v1`: categoria,
  disponibilità commerciale e sconto;
- abilitare ordinamento catalogo, nome, prezzo crescente e prezzo decrescente;
- mantenere cursor keyset separati per query/filter/sort e scartare risultati stale;
- offrire clear query, empty state, retry e tastiera/accessibilità corretti;
- mantenere catalogo guest, nessun accesso inventory e nessun dato mock;
- verificare search/filter/sort reali su staging Android/iOS.

## Non incluso

- ricerca offline persistente, che appartiene a TASK-017;
- suggerimenti server distinti o motore esterno;
- dettaglio prodotto TASK-016;
- preferiti e deep link TASK-018;
- tuning finale dataset esteso TASK-019;
- write backend o production.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Il client allowlista solo Search/Catalog pubblici e non interroga dati interni | STATIC/SECURITY |
| CA-02 | DTO Search strict rifiuta shape, query/cursor/versione e sort incoerenti | UNIT |
| CA-03 | Query è bounded, debounced e cancellabile; risposte stale non aggiornano la UI | UNIT/WIDGET |
| CA-04 | Search reale espone loading, result, empty, error, retry e clear accessibili | WIDGET/INTEGRATION |
| CA-05 | Categoria/disponibilità/sconto sono applicati server-side e componibili | UNIT/WIDGET |
| CA-06 | Quattro ordinamenti usano keyset deterministico e reset pagina | UNIT/WIDGET |
| CA-07 | Cambio query/filter/sort non duplica o mescola pagine/cursor | UNIT |
| CA-08 | Tastiera, focus, Semantics, dark, 200% e quattro locale restano verdi | WIDGET |
| CA-09 | CI, build e smoke staging Android/iOS sono PASS sullo SHA candidato | CI/BUILD/MANUAL |

## Test case

| Test | Criteri | Procedura attesa |
|---|---|---|
| T-01 | CA-01, CA-02 | payload Search valido/malevolo e allowlist RPC |
| T-02 | CA-03, CA-07 | debounce, cancel, stale result e query clear |
| T-03 | CA-04 | loading/result/empty/offline/error/retry |
| T-04 | CA-05 | categoria + availability + discounted composti server-side |
| T-05 | CA-06, CA-07 | sort e keyset per prima/seconda pagina |
| T-06 | CA-08 | Semantics, keyboard, focus, dark, 200%, locale/device matrix |
| T-07 | CA-09 | gate completo e smoke search/filter/sort staging Android/iOS |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Debounce client 300 ms e query minima due caratteri | Riduce richieste senza rendere lenta la discovery | ATTIVA |
| D-02 | Ogni combinazione query/filter/sort invalida il cursor precedente | Un cursor appartiene a una sequenza server specifica | ATTIVA |
| D-03 | Search usa `storefront_search_v1`; filtri/sort usano `storefront_catalog_v1` | Riusa il contratto pubblico misurato senza motore esterno | ATTIVA |
| D-04 | Filtri avanzati restano espliciti e resettabili | Evita stato nascosto e risultati non spiegabili | ATTIVA |
| D-05 | Nessuna history persistente prima di TASK-017 | Mantiene lo storage locale nel task proprietario | ATTIVA |

## Planning — `CODEX_PLANNER`

### Analisi

- TASK-014 ha già repository, controller e griglia keyset con categoria;
- il backend staging espone `storefront_search_v1` con query normalizzata e cursor
  opaco; `storefront_catalog_v1` espone availability, discounted e quattro sort;
- la SearchBar è deliberatamente disabilitata fino a questo task;
- filtri e sort devono entrare nello stesso state/generation boundary del catalogo;
- cache/search offline resta esclusa fino a TASK-017.

### Approccio autorizzato

1. aggiungere model/DTO/repository Search strict e parametri filter Catalog;
2. estendere `CatalogState` con discovery query/filter/sort e sequenza corrente;
3. implementare debounce/cancellation e pagination distinta Search/Catalog;
4. abilitare SearchBar, clear, pannello filtri e sort accessibili;
5. aggiungere test unit/widget/security e matrice regressione;
6. eseguire gate completo e smoke staging live Android/iOS;
7. consegnare a `VALIDATED_PENDING_INTEGRATED_REVIEW` solo con checkpoint verde.

### Rischi

- cursor riusato dopo cambio criterio: reset atomico e sequence key;
- query stale: timer cancellato più generation/cancellation guard;
- request storm: debounce 300 ms e single-flight;
- filtri contraddittori: modello typed e reset esplicito;
- accessibilità tastiera: focus order, submit/clear e target 48 dp;
- scope creep cache: nessuna persistenza o search index locale.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: prompt release train 2026-08-01

## Execution — `CODEX_EXECUTOR`

### Modifiche completate

- model/DTO/repository strict per `storefront_search_v1`, con query/cursor/versione,
  relevance bounded e allowlist payload fail-closed;
- controller discovery unico con debounce 300 ms, cancellation/generation guard,
  cursor separati, stale response discard, retry e reset atomico;
- filtri categoria/disponibilità/sconto e quattro sort inoltrati server-side al solo
  `storefront_catalog_v1`; categoria componibile con Search;
- SearchBar, clear, disponibilità, sconto e sort accessibili e localizzati; i filtri
  non supportati dal contratto Search sono disabilitati esplicitamente;
- smoke staging guest Search/availability/discounted/price sort su Android/iOS.

### Difetti corretti durante Execution

- eliminato l'hang del test dropdown sostituendo l'interazione overlay non bounded con
  callback widget deterministica;
- retry Search conserva la catalog version nota, evitando reload categorie spurio e
  mantenendo il vero recovery `catalog_changed`;
- controllo raw della query blocca control character prima della normalizzazione;
- form sort viene ricreato sul valore server-state, così il reset è visibile e coerente.

### Gate eseguiti

- revision set Client `6739bf663cca2dcad4dcd2ef11ee2415b238daeb`, PR `#5` draft;
- `scripts/check.sh`: security 379 file, governance 8/8, architecture 7/7, l10n,
  format, analyze, 266 test, coverage 2.878/3.460 linee (83,18%), Android debug e iOS
  Simulator debug: `PASS`;
- CI Client `30734363845`: Quality 3m17s, iOS 4m11s, Android 8m23s, 3/3 `PASS`;
- Discovery Android Emulator live: 1/1 `PASS` in 20 s;
- Discovery iOS Simulator live: 1/1 `PASS` in 3 s;
- APK staging SHA-256
  `dcf56c4ccb89d58f75920cc97df3a4f45a6ce63887f8fdd0bc47fb5064b83d2e`;
- Runner staging executable SHA-256
  `6d3b55ad31a66efadad0880b9265d0c68ed8658168a16320838eed284f033d65`;
- production write: `NOT_RUN`; production invariata.

### Matrici

CA-01..CA-09 e T-01..T-07: `PASS`. Evidence sintetica:
`docs/TASKS/EVIDENCE/TASK-015/README.md`.

### Handoff

`CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`. Nessuna review formale è stata
eseguita e TASK-015 non è `DONE`.

## Checkpoint release train — `CODEX_EXECUTOR`

TASK-015 è `VALIDATED_PENDING_INTEGRATED_REVIEW`: implementazione, gate completo, CI e
smoke staging Android/iOS sono verdi sul revision set registrato. Production è
invariata; nessuna review formale intermedia è stata eseguita. Il task successivo
autorizzato è TASK-016.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.
