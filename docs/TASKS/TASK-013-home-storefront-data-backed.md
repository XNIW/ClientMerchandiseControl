# TASK-013 — Home Storefront data-backed

## Informazioni generali

- **Task ID**: TASK-013
- **Titolo**: Home e prodotti/promozioni in evidenza
- **File task**: `docs/TASKS/TASK-013-home-storefront-data-backed.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-02
- **Ultimo aggiornamento**: 2026-08-02
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-013/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Dipendenze

- **Dipende da**: TASK-009, TASK-010, TASK-011, TASK-012
- **Sblocca**: TASK-014, TASK-019

## Scope

- aggiungere lo slug Storefront pubblico come configurazione compile-time validata e
  sanitizzata, senza valori reali versionati;
- creare il primo data layer Flutter Storefront con repository astratto, implementazione
  Supabase RPC-only, DTO mapping allow-listed, failure mapping, timeout e cancellazione;
- consumare esclusivamente `storefront_home_v1`/API `storefront.v1`, mai tabelle
  inventory, authoring o storage interno;
- modellare settings, categorie, featured, offerte, prezzi CLP, sconti, fulfillment e
  riferimenti immagine pubblici;
- rendere Home anonima data-backed con loading/skeleton, retry, offline/unavailable,
  empty state e CTA catalogo;
- preparare una fixture staging pubblica, deterministica e priva di dati personali per
  smoke Android/iOS reale, mantenendo production invariata;
- aggiungere unit/widget/integration test per mapping, failure, cancellazione, stati UI,
  localizzazioni, dark mode, text scale e staging live.

## Contesto

Milestone 1 espone `storefront_home_v1` con contratto minimizzato e Milestone 2 pubblica
prodotti, promozioni e immagini. La Home corrente è una shell statica: TASK-013 crea il
primo consumer mobile reale e il confine repository che i task catalogo successivi
estenderanno senza introdurre query dirette alle tabelle operative.

## Non incluso

- griglia/infinite pagination completa TASK-014;
- ricerca e filtri TASK-015;
- dettaglio prodotto TASK-016;
- cache SQLite/offline persistente TASK-017;
- preferiti/deep link TASK-018;
- modifiche production o service role nel client.

## File coinvolti

- `lib/core/config/`, esempi config e documentazione environment;
- `lib/features/storefront/` per domain/data/application condivisi;
- `lib/features/home/` per controller e presentazione;
- `lib/l10n/` e relativi generated output;
- test unit/widget/integration e security/architecture boundary;
- fixture/workflow staging nel repository Admin canonico, se necessaria;
- manifest, checkpoint, Master Plan, worklog ed evidence.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Il client usa soltanto `storefront_home_v1` e non accede a inventory/authoring/bucket interno | STATIC/SECURITY |
| CA-02 | Config shop slug è compile-time, validata, fail-closed e non contiene valori reali versionati | UNIT/SECURITY |
| CA-03 | Mapping rifiuta status/API/schema/tipi/CLP/URL non validi senza accettazione parziale | UNIT |
| CA-04 | Repository applica timeout, cancellazione e failure taxonomy deterministica | UNIT |
| CA-05 | Home mostra categorie, featured e offerte reali con prezzi/sconti/immagini pubbliche | WIDGET/IOS_SIM/ANDROID_EMU |
| CA-06 | Loading, retry, offline, unavailable ed empty state sono accessibili e localizzati | WIDGET |
| CA-07 | Guest Home funziona senza sessione e non espone dati interni o identificatori tecnici | UNIT/INTEGRATION/SECURITY |
| CA-08 | Test a text scale 200%, dark mode ed es/it/en/zh-Hans non introducono overflow | WIDGET |
| CA-09 | CI, build Android/iOS e smoke staging reale sono PASS sullo SHA candidato | CI/BUILD_ANDROID/BUILD_IOS/ANDROID_EMU/IOS_SIM |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-03 | UNIT/STATIC | payload valido e payload malevoli/interni/API mismatch |
| T-02 | CA-02 | UNIT/SECURITY | slug valido, missing, uppercase, wildcard, path/query e diagnostics |
| T-03 | CA-04 | UNIT | success, PostgREST/Auth/network/timeout e cancellazione stale |
| T-04 | CA-05, CA-06 | WIDGET | loading -> data/empty/error -> retry con repository fake |
| T-05 | CA-07 | INTEGRATION/SECURITY | avvio guest e fetch Home senza sessione/token/log sensibili |
| T-06 | CA-08 | WIDGET | locale/theme/text scale/device matrix minima |
| T-07 | CA-09 | BUILD/CI/MANUAL | analyze/test/build e smoke Android/iOS con fixture staging |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Un solo RPC Home versionato per il primo render | Evita waterfall e query a tabelle interne | ATTIVA |
| D-02 | DTO strict allow-list separati dai model di dominio | Fail-closed su drift e nessuna propagazione metadata | ATTIVA |
| D-03 | Nessuna cache persistente prima di TASK-017 | Evita storage locale parziale/speculativo | ATTIVA |
| D-04 | Fixture staging deterministica in un tenant pubblico dedicato | Smoke ripetibile senza dati personali o production | ATTIVA |
| D-05 | Slug shop compile-time e non inferito dall inventory | L app pubblica deve avere tenant esplicito e verificabile | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Sostituire la Home mock con il primo catalogo pubblico reale e stabilire un data boundary
Flutter rigoroso, riusabile dai task 014–019.

### Analisi

- `HomeScreen` espone oggi soltanto contenuto statico ed empty state;
- `AppConfig` non contiene ancora l identificatore Storefront richiesto dal RPC;
- Supabase è inizializzato in staging con PKCE e publishable key, ma nessun repository
  catalogo usa ancora `SupabaseClient.rpc`;
- il contratto Home restituisce `apiVersion`, `catalogVersion`, settings, categorie,
  featured e offerte con soli campi pubblici;
- il dataset load da 20k è effimero per design, quindi serve una fixture staging
  persistente e dedicata per gli smoke mobile.

### Approccio

1. estendere config/validator/documentazione con `STOREFRONT_SHOP_SLUG`;
2. introdurre model/DTO/failure/repository Home e provider Riverpod cancellabile;
3. implementare controller Home con generation guard e retry;
4. costruire card/sezioni accessibili usando prezzi CLP e URL pubblici versionati;
5. creare/applicare fixture staging guarded e verificare anon RPC;
6. eseguire unit/widget/security, build e smoke Android/iOS;
7. registrare evidence e portare TASK-013 a
   `VALIDATED_PENDING_INTEGRATED_REVIEW` soltanto con checkpoint verde.

### Rischi

- drift payload: decoder strict e test contract fixture;
- risposta stale dopo retry/navigation: cancellation token e generation guard;
- slug errato: config fail-closed e stato unavailable senza fallback tenant;
- URL immagini malevoli: HTTPS/host/path validation e placeholder sicuro;
- staging senza catalogo stabile: fixture idempotente, tenant dedicato e cleanup/runbook;
- scope creep cache/catalog: repository Home minimo, estendibile nei task dedicati.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: ricevuta nel prompt release train 2026-08-01

## Execution — `CODEX_EXECUTOR`

In avvio.

## Checkpoint release train — `CODEX_EXECUTOR`

Da compilare dopo i gate TASK-013. Nessuna review formale intermedia.

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

Riservata alla review integrata finale.

## Fix — `CODEX_FIXER`

Riservato all eventuale ciclo Fix integrato.

## Chiusura

- **Conferma utente**: ricevuta in forma condizionata dal release train
- **Merge autorizzato da USER_APPROVER**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: TASK-014
- **Riepilogo finale**: in esecuzione
- **Data completamento**: non ancora
