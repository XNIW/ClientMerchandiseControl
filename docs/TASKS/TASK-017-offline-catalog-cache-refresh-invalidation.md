# TASK-017 — Cache catalogo offline, refresh e invalidazione

## Informazioni generali

- **Task ID**: TASK-017
- **Titolo**: Cache catalogo offline, refresh e invalidazione
- **File task**: `docs/TASKS/TASK-017-offline-catalog-cache-refresh-invalidation.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-02
- **Ultimo aggiornamento**: 2026-08-02
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-017/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Dipendenze

- **Dipende da**: TASK-010, TASK-014
- **Checkpoint consumati**: TASK-013, TASK-014, TASK-015 e TASK-016
- **Sblocca**: TASK-018, TASK-019, TASK-023, TASK-034, TASK-037

## Scope

- adottare Drift/SQLite soltanto per dati Storefront pubblici e stato locale non secret;
- persistere per shop categorie, catalog item, dettaglio, catalog version, freshness,
  image reference e metadata di sequenza/refresh;
- implementare stale-while-revalidate su Home, Catalog, Search e Product Detail;
- mostrare cache offline con indicazione di freshness/stale, senza inventare prezzi o
  disponibilità correnti;
- invalidare atomicamente cache/sequence quando cambia `catalogVersion`;
- supportare ricerca offline normalizzata sui soli item pubblici cached;
- aggiungere schema version, migration test, transazioni, deduplica e recovery da DB
  corrotto/incompatibile senza fallback plaintext o crash loop;
- imporre limiti di righe/dimensione e cleanup LRU/version-aware;
- misurare open, read warm, search e write/rebuild su fixture 20.000 prodotti;
- verificare cold/offline/reconnect/app-kill su Android e iOS staging.

## Non incluso

- token/sessione OAuth, push token, indirizzi, profilo o dati customer nel database;
- download o persistenza dei byte immagine: si salvano soltanto URL/version/digest
  pubblici, mentre la cache HTTP resta del loader immagine;
- preferiti e relativo merge login, appartenenti a TASK-018;
- carrello e mutazioni customer, appartenenti a TASK-023;
- modifica dei contratti Supabase, backend o production.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Drift è compatibile/licenziato/manutenuto e dipendenze/generator sono lockati | STATIC/BUILD |
| CA-02 | Schema contiene solo dati pubblici shop-scoped e nessun token/PII/internal field | SECURITY/UNIT |
| CA-03 | Home/Catalog/Detail rendono cache subito e revalidano senza mescolare versioni | UNIT/WIDGET |
| CA-04 | Offline usa cache onesta con freshness; cache assente mostra stato offline | UNIT/WIDGET |
| CA-05 | Search offline è accent-insensitive, bounded e non espone relevance interna | UNIT/PERF |
| CA-06 | Migration, downgrade/corruption e write interrotta falliscono chiusi e recuperano | UNIT/INTEGRATION |
| CA-07 | Limiti/cleanup mantengono DB bounded e preservano dataset utile più recente | UNIT/PERF |
| CA-08 | Reconnect/catalogVersion nuovo invalida e sostituisce atomicamente dati stale | UNIT/INTEGRATION |
| CA-09 | Warm read e offline startup rispettano i budget documentati su 20.000 item | PERF |
| CA-10 | Gate, CI e smoke offline/reconnect Android/iOS sono PASS sullo SHA candidato | CI/BUILD/INTEGRATION |

## Test case

| Test | Criteri | Procedura attesa |
|---|---|---|
| T-01 | CA-01, CA-02 | dependency/license audit, schema inspection e secret/PII negative |
| T-02 | CA-03, CA-04 | cache hit fresh/stale/empty e SWR remote success/failure |
| T-03 | CA-05 | search offline es/zh, accenti, query bounded e ordering deterministico |
| T-04 | CA-06 | schema v1 migration/reopen, DB incompatibile/corrotto e transazione abortita |
| T-05 | CA-07 | 20k item, cap/cleanup LRU e riferimenti immagini orfani |
| T-06 | CA-08 | catalog version increment, app kill durante refresh e reconnect |
| T-07 | CA-09 | benchmark open/read/search/write p50/p95/p99 |
| T-08 | CA-10 | smoke staging online→offline→kill→offline→reconnect Android/iOS |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Drift `2.34.3` + `drift_flutter` `0.3.1` | MIT, Android/iOS, Dart >=3.10 e release recenti; il progetto usa Dart 3.12.2 | ATTIVA |
| D-02 | `drift_dev` resta dev-only e output generato è versionato/verificato | Build riproducibile senza generator a runtime | ATTIVA |
| D-03 | Database per installazione con ogni riga namespace `shopSlug` | Evita contaminazione cross-shop e consente cleanup selettivo | ATTIVA |
| D-04 | TTL freshness 15 min; max stale consultabile 30 giorni con etichetta | Reattività e resilienza senza presentare cache come verità corrente | ATTIVA |
| D-05 | Cap iniziale 64 MiB / 25.000 item / 500 detail, misurato e testato | Copre il dataset acceptance lasciando il DB bounded | ATTIVA |
| D-06 | Nessun blob immagine, token, email o dato customer in Drift | Minimizzazione, memoria e separazione secure storage | ATTIVA |
| D-07 | `catalogVersion` maggiore avvia sostituzione transazionale per scope | Impedisce pagine miste e rende il refresh crash-safe | ATTIVA |

## Planning — `CODEX_PLANNER`

### Audit dipendenza

- il catalogo ufficiale pub.dev del 2026-08-02 riporta Drift `2.34.3`, MIT, Dart
  minimo 3.10, Android/iOS e pubblicazione recente;
- `drift_flutter` `0.3.1`, MIT, fornisce apertura nativa Android/iOS e usa la directory
  documenti applicativa; `drift_dev` `2.34.5` è il generator dev-only;
- la codebase usa Dart `^3.12.2` e già dipende da `path_provider`, quindi la matrice è
  compatibile; l'overhead aggiunto è SQLite nativo più code generation, da misurare nei
  build e negli artifact del checkpoint;
- fonti: `https://pub.dev/packages/drift`, `https://pub.dev/packages/drift_flutter`,
  `https://pub.dev/packages/drift_dev` e documentazione ufficiale Drift.

### Approccio autorizzato

1. aggiungere dipendenze lockate, database Drift e schema pubblico v1;
2. creare boundary cache astratto, adapter Drift e in-memory test double;
3. integrare SWR/freshness in Home, Catalog/Search e Detail senza cambiare RPC;
4. implementare version invalidation, transazioni, cap e cleanup;
5. aggiungere search offline e test migration/corruption/reconnect;
6. eseguire fixture/benchmark 20k, gate completo e smoke Android/iOS;
7. consegnare a `VALIDATED_PENDING_INTEGRATED_REVIEW` soltanto con checkpoint verde.

### Rischi

- codegen/build overhead: generazione deterministica, builder ristretto e misura build;
- DB corruption/downgrade: apertura fail-closed, backup non sensibile o ricreazione
  controllata della sola cache ricostruibile;
- dati commerciali stale: freshness visibile e mai usata per checkout autoritativo;
- cross-shop bleed: chiavi composte e test negativo per ogni read/write;
- refresh interrotto: staging generation e commit transazionale;
- file troppo grande: row/byte cap e cleanup dopo commit, non durante read critica.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: prompt release train 2026-08-01

## Execution — `CODEX_EXECUTOR`

In avvio.

## Checkpoint release train — `CODEX_EXECUTOR`

Da compilare dopo i gate TASK-017. Nessuna review formale intermedia.

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.
