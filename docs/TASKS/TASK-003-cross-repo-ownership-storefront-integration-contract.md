# TASK-003 — Cross-repo ownership e Storefront integration contract

## Informazioni generali

- **Task ID**: TASK-003
- **Titolo**: Cross-repo ownership e Storefront integration contract
- **File task**: `docs/TASKS/TASK-003-cross-repo-ownership-storefront-integration-contract.md`
- **Stato**: ACTIVE
- **Fase**: REVIEW
- **Responsabile**: CODEX_REVIEWER
- **Data creazione**: 2026-07-30
- **Ultimo aggiornamento**: 2026-07-30
- **Ultimo agente**: CODEX_EXECUTOR
- **Review outcome**: non ancora eseguita
- **Reviewer**: sessioni indipendenti da assegnare
- **Approver**: USER_APPROVER
- **Indicatore**: CODEX_EXECUTION_COMPLETE_TO_REVIEW
- **DONE**: NO
- **Merge**: NO
- **User approval**: GRANTED_BY_END_TO_END_PROMPT, da applicare con transizione esplicita
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-003/`
- **Handoff**: CODEX_EXECUTION_COMPLETE_TO_REVIEW

## Dipendenze

- **Dipende da**: TASK-001 e TASK-002 `DONE` e merged; PR #2 merged con commit
  `46686ace3b4670f207147f12110d8133ced01e8e`
- **Sblocca**: TASK-004; definisce i confini per TASK-005–TASK-011 e TASK-020

## Scope

- audit read-only a ref fisse di Client, Admin, Android operativo, iOS operativo,
  Win7POS, workspace Supabase storico e progetto Supabase non-production canonico;
- matrice univoca di domain owner, decision owner, writer, projector, consumer,
  contract owner e change owner;
- ownership esplicita di migrations, RLS/grant/RPC, Edge Functions e contratti API;
- contratto logico Storefront shop-scoped, con termini normativi, allowlist/denylist,
  commercial truth, error policy e trust boundaries;
- separazione fra catalogo operativo, proiezione Storefront e UI cliente;
- separazione guest/customer/staff/server e autenticazione/autorizzazione;
- confini immagini, prezzi, disponibilità, ordini cliente e vendita fiscale;
- identificatore shop futuro, compatibilità, deprecation e breaking changes;
- ottimizzazione della roadmap in due workstream catalogo/auth senza rinumerare,
  eliminare o attivare task futuri;
- ADR su workstream paralleli e ADR su ownership/change protocol Storefront;
- allineamento dei documenti architetturali esistenti, Master Plan, README, quality
  gates, task, worklog ed evidence.

## Contesto

Il client Flutter pubblico non può usare le superfici operative già consumate da Android,
iOS o POS. L'audit preliminare conferma che i client operativi gestiscono dati contenenti
costo, prezzo operativo, stock, tombstone, sessioni, device e storico; Win7POS origina
vendite fiscali e movimenti stock. Nessuno di questi repository contiene oggi un dominio
Storefront pubblico.

L'unico progetto Supabase accessibile è un ambiente non-production condiviso, denominato
`merchandisecontrol-dev`, attivo e collegato al repository Admin. Il ledger remoto e il
repository Admin contengono 96 migrations con un remap di versione già documentato;
non risultano Edge Functions. Il workspace storico `MerchandiseControlSupabase` è
non-Git, preparatorio e non prova dello stato live. Il repository Admin è quindi il
candidato verificabile per la migration authority corrente, senza che TASK-003 applichi
DDL o modifichi sistemi esterni.

Il grafo del Master Plan blocca artificialmente TASK-011 e TASK-020 dietro il catalogo.
Il prompt end-to-end autorizza l'ottimizzazione in due workstream, mantenendo un solo
task `ACTIVE` e tutti i task catalogo obbligatori.

## Non incluso

- schema, migrations, SQL, RLS, grant, view, trigger, RPC, Edge Function o Storage;
- modifiche al progetto Supabase, provider Auth, allow-list o configurazione remota;
- URL, chiavi, project ref completi, token, secret o dati commerciali reali;
- environment strategy e implementazione `AppConfig` di TASK-004;
- networking, health probe, repository backend o readiness state di TASK-011;
- shell prodotto e acceptance UI di TASK-012;
- OAuth, deep link, session lifecycle, secure storage o profilo di TASK-020/TASK-021;
- DTO, query, pagination, search, fixture o contract test runtime di TASK-010;
- implementazione catalogo, prezzi, immagini, carrello, ordine o fulfillment;
- modifiche, fetch, commit o pulizia dei repository esterni;
- rinumerazione, eliminazione, attivazione o modifica di scope dei task futuri.

## File coinvolti

- `docs/ARCHITECTURE/CROSS-REPO-OWNERSHIP.md`;
- `docs/ARCHITECTURE/STOREFRONT-INTEGRATION-CONTRACT.md`;
- `docs/ARCHITECTURE/AUTH-BOUNDARY.md`;
- `docs/ARCHITECTURE/STOREFRONT-DATA-BOUNDARY.md`;
- `docs/ARCHITECTURE/SYSTEM-CONTEXT.md`;
- `docs/ARCHITECTURE/MOBILE-ARCHITECTURE.md`;
- `docs/DECISIONS/ADR-009-parallel-catalog-authentication-workstreams.md`;
- `docs/DECISIONS/ADR-010-storefront-contract-ownership.md`;
- `docs/MASTER-PLAN.md`, `docs/QUALITY-GATES.md`, `README.md`,
  `docs/AI_WORKLOG.md`;
- questo task e `docs/TASKS/EVIDENCE/TASK-003/`;
- nessun file in `lib/`, `test/`, `integration_test/`, `config/`, Android, iOS o
  `pubspec*`.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | TASK-001 e TASK-002 sono `DONE` e merged prima dell'attivazione | GIT/STATIC |
| CA-02 | TASK-003 è l'unico task `ACTIVE` e il Planning è completo | STATIC/GIT |
| CA-03 | Le fonti Client/Admin/Android/iOS/POS sono auditate a ref fisse e zero-write | GIT/STATIC |
| CA-04 | Workspace storico e progetto Supabase canonico sono distinti e sanitizzati | STATIC/SECURITY |
| CA-05 | Ogni sistema ha responsabilità, non-responsabilità e flussi vietati espliciti | STATIC |
| CA-06 | Ogni dominio ha owner, writer, projector, consumer, contract e change owner | STATIC |
| CA-07 | Client possiede UI, intenti, cache e deep link, mai inventory o commercial truth | STATIC |
| CA-08 | Admin possiede control plane, migrations/RLS/RPC e futuri contract server-side | STATIC |
| CA-09 | Android/iOS/POS restano domini operativi e non API runtime del client pubblico | STATIC |
| CA-10 | Supabase è runtime/enforcement platform, non business decision owner | STATIC |
| CA-11 | Il contratto Storefront ha vocabolario normativo, versione e ownership | STATIC |
| CA-12 | Ogni risorsa Storefront è shop-scoped con `shop_id` UUID non fidato dal client | STATIC |
| CA-13 | Catalogo pubblico guest è separato da identità e dati cliente | STATIC |
| CA-14 | Dati pubblicabili e superfici operative vietate sono elencati senza ambiguità | STATIC |
| CA-15 | Prezzi, promozioni e disponibilità sono server-authoritative e rivalidabili | STATIC |
| CA-16 | Immagini pubblicate sono separate da management API, bucket e signed URL interni | STATIC |
| CA-17 | Ordine cliente e vendita fiscale POS sono entità/eventi distinti | STATIC |
| CA-18 | Mutazioni future richiedono autorizzazione, idempotenza, audit e fail-closed | STATIC |
| CA-19 | Publishable key, session identity e authorization sono concetti distinti | STATIC/SECURITY |
| CA-20 | Guest, customer, staff e server hanno capability separate | STATIC/SECURITY |
| CA-21 | UI, route, cache, email, `shop_id` e `user_metadata` non autorizzano accessi | STATIC/SECURITY |
| CA-22 | Grants e RLS sono entrambi obbligatori; nessun default Data API è assunto | STATIC/SECURITY |
| CA-23 | Compatibilità distingue additive, deprecation, breaking e migration window | STATIC |
| CA-24 | ADR-009 definisce workstream catalogo/auth paralleli con un solo task attivo | STATIC |
| CA-25 | Master modifica solo le dipendenze necessarie di TASK-010, TASK-011 e TASK-020 | STATIC/GIT |
| CA-26 | Il grafo ha 42 nodi, zero cicli e reachability coerente con i due workstream | STATIC |
| CA-27 | TASK-005–010 e TASK-013+ restano presenti, invariati nello scope e `TODO` | STATIC/GIT |
| CA-28 | Nessun file runtime, dipendenza, config locale o backend viene modificato | GIT |
| CA-29 | Nessun secret, URL production, dato reale o artifact entra nel repository | SECURITY/GIT |
| CA-30 | Gate documentali, governance, diff e quality gate aggregato sono `PASS` | STATIC/FORMAT/ANALYZE/UNIT/BUILD_ANDROID/BUILD_IOS/GIT |
| CA-31 | Review indipendente termina senza finding P0, P1 o P2 aperti | MANUAL/STATIC |
| CA-32 | CI sullo SHA finale completa job, step e annotation con esito `PASS` | CI |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-02 | GIT/STATIC | Verificare merge TASK-002, task unico e governance |
| T-02 | CA-03 | GIT | Confrontare ref, dirty state e fingerprint iniziali/finali |
| T-03 | CA-04 | STATIC/SECURITY | Verificare provenance senza ref, URL o key completi |
| T-04 | CA-05, CA-06 | STATIC | Controllare completezza e unicità della matrice ownership |
| T-05 | CA-07, CA-08, CA-09, CA-10 | STATIC | Validare responsabilità e forbidden flow per sistema |
| T-06 | CA-11, CA-23 | STATIC | Verificare versione, change protocol e compatibility window |
| T-07 | CA-12 | STATIC | Verificare shop scope e UUID contro metadata schema read-only |
| T-08 | CA-13, CA-14 | STATIC | Validare allowlist/denylist e guest catalog boundary |
| T-09 | CA-15 | STATIC | Applicare checklist commercial truth e revalidation |
| T-10 | CA-16 | STATIC | Verificare image source/published projection/cache boundary |
| T-11 | CA-17, CA-18 | STATIC | Verificare ordine, vendita fiscale, idempotenza e audit |
| T-12 | CA-19, CA-20, CA-21, CA-22 | STATIC/SECURITY | Applicare capability e auth-boundary checklist |
| T-13 | CA-24, CA-25 | STATIC/GIT | Diff allowlist delle tre celle dipendenze e ADR |
| T-14 | CA-26 | STATIC | Eseguire parser DAG/reachability su tutti i 42 task |
| T-15 | CA-27 | STATIC/GIT | Confrontare titoli, scope, risultati e stati dei task futuri |
| T-16 | CA-28 | GIT | Verificare diff confinement fuori runtime/config/pubspec |
| T-17 | CA-29 | SECURITY/GIT | Scan mirato secret, URL production, config locale e artifact |
| T-18 | CA-30 | STATIC/GIT | Eseguire governance script, link scan e `git diff --check` |
| T-19 | CA-30 | FORMAT/ANALYZE/UNIT/BUILD_ANDROID/BUILD_IOS | Eseguire `bash scripts/check.sh` |
| T-20 | CA-31 | MANUAL/STATIC | Review indipendenti governance, architecture e security |
| T-21 | CA-32 | CI | Ispezionare SHA, job, step e annotation del run finale |
| T-22 | CA-03, CA-28, CA-29 | GIT/SECURITY | Verificare worktree esterni, Client e Supabase zero-write |

## Decisioni

Le decisioni superate restano visibili con stato `OBSOLETA`.

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Il prompt end-to-end autorizza Planning, Execution, Review, Fix, `DONE`, PR batch e merge soltanto con gate reali e zero P0/P1/P2. | Registrare l'autorità limitata al workflow richiesto | ATTIVA |
| D-02 | TASK-003 resta documentale/decisionale; non modifica runtime o backend. | Il contratto deve precedere schema e connessione | ATTIVA |
| D-03 | Il branch è condiviso con TASK-004, ma task, commit, evidence e review restano sequenziali e separati. | Preservare un solo task `ACTIVE` | ATTIVA |
| D-04 | ADR-009 governa la roadmap; ADR-010 governa ownership e change protocol Storefront. | Evitare di fondere due decisioni indipendenti | ATTIVA |
| D-05 | Le fonti dirty esterne sono lette senza pulizia e citate a ref fisse; nessun claim dipende da file dirty non verificati. | Preservare il lavoro dell'utente e la riproducibilità | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Eliminare le ambiguità di ownership fra i sistemi dell'ecosistema e definire il contratto
logico, versionato e fail-closed che il client pubblico consumerà in futuro, senza creare
ancora schema, API o networking. Contestualmente rimuovere le dipendenze artificiali che
bloccano l'autenticazione dietro il catalogo.

### Analisi

- TASK-002 è presente su `main` con merge commit `46686ac`.
- Client non esegue query: inizializza soltanto Supabase con URL e publishable key; in
  development può restare offline.
- Android e iOS sono repliche operative offline-first con writer locali reali su
  inventory, prezzi e stock; le tabelle `inventory_*` contengono dati non pubblici.
- Win7POS origina vendite fiscali e movimenti stock, usa Admin HTTPS e non possiede un
  client Supabase.
- Admin è il server boundary Git-tracciato con 96 migrations, pgTAP, pipeline staging,
  API POS/immagini e client privilegiato server-only; non esiste ancora Storefront.
- Il progetto non-production collegato ha 96 versioni remote, zero Edge Functions e
  `shop_id` UUID; alcune tabelle legacy hanno grant `anon`, quindi il divieto client
  deve essere contrattuale oltre che tecnico.
- Il workspace Supabase storico è non-Git, contiene 18 migration e nessuna Edge
  Function; non è migration authority né prova live.
- Il grafo richiede tre correzioni minime: TASK-010 aggiunge TASK-008; TASK-011 dipende
  soltanto da TASK-004; TASK-020 rimuove TASK-005.

### Approccio

1. Versionare audit sanitizzato, refs e fingerprint zero-write.
2. Espandere la matrice ownership separando dominio, implementazione e cambio.
3. Scrivere contratto Storefront e auth boundary con regole normative.
4. Riallineare data boundary, system context e mobile architecture.
5. Registrare ADR-009 e ADR-010.
6. Applicare le sole tre correzioni al grafo e verificarne reachability/aciclicità.
7. Eseguire scan statici, governance, gate aggregato e fingerprint finali.
8. Consegnare un commit Execution separato a reviewer read-only indipendenti.

### Rischi

- **Authority imposta senza provenance**: ancorare ogni scelta a ref e fonti; distinguere
  stato osservato da decisione futura.
- **Storefront confuso con tabelle legacy pubblicamente leggibili**: denylist esplicita
  e nessun fallback operativo.
- **Supabase trattato come business owner**: separare enforcement platform da decision
  owner Admin/POS.
- **Parallelismo interpretato come task simultanei**: ribadire un solo task `ACTIVE`.
- **Contract drift**: definire owner machine-readable, consumer conformance e change
  protocol.
- **Workspace storico assunto live**: classificarlo soltanto come provenance.
- **Dirty state esterno alterato**: ref/fingerprint prima e dopo, zero write.
- **Overdesign**: limitarsi a contratto logico; schema e API fisici restano TASK-005/010.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION
- **Autorizzazione USER_APPROVER**: già concessa in forma condizionata dal prompt
  end-to-end; deve essere applicata con una transizione esplicita senza cambiare scope

## Execution — `CODEX_EXECUTOR`

### Obiettivo compreso

Produrre soltanto i deliverable documentali e di governance approvati nel Planning,
senza modificare runtime, configurazione, backend o repository esterni.

### File controllati

- dodici deliverable architetturali, ADR, governance e provenance nel commit tecnico
  `e2ad429f25341f9009c3087673c36746e23bf059`;
- task, evidence index, `README.md`, Master Plan e worklog per il solo handoff;
- nessun file `lib/`, `test/`, `integration_test/`, `config/`, Android, iOS,
  `pubspec*` o repository esterno.

### Piano minimo

1. consolidare audit e integrità esterna;
2. scrivere ownership, integration contract e auth boundary;
3. registrare ADR-009/ADR-010 e riallineare l'architettura;
4. correggere soltanto le tre dipendenze autorizzate;
5. verificare contratto, DAG, security, gate e handoff.

### Modifiche fatte

- definita una matrice univoca di ownership e flussi vietati tra Client, Admin,
  Android, iOS, POS e Supabase;
- introdotto il contratto logico versionato `CMC-STOREFRONT-LOGICAL` 1.0.0 con shop
  scope, allowlist/denylist, commercial truth, immagini, ordine e compatibility;
- separati autenticazione, identità di sessione e autorizzazione per
  guest/customer/staff/server;
- riallineati data boundary, system context e mobile architecture;
- registrati ADR-009 per i workstream catalogo/auth e ADR-010 per contract/change
  ownership;
- corrette esclusivamente le dipendenze di TASK-010, TASK-011 e TASK-020;
- versionati audit sanitizzato, 57 riferimenti a ref fisse e procedura di fingerprint
  zero-write.

### Check eseguiti

| Verifica | Esito | Evidenza |
|---|---|---|
| Governance e DAG | `PASS` | governance exit 0; 42 nodi, zero cicli, un solo `ACTIVE` |
| Fonti e link | `PASS` | 57/57 citazioni valide; link locali zero mancanti |
| Security e confinement | `PASS` | zero pattern sensibili; 12 documenti, zero runtime/config/backend |
| Repository esterni | `PASS` | quattro fingerprint Git e manifest storico invariati |
| Toolchain e dipendenze | `PASS` | doctor, shell syntax, `pub deps` e `pub outdated` exit 0 |
| Gate aggregato | `PASS` | `scripts/check.sh`: format, analyze, 59/59 test, Android/iOS build |
| CI Execution | `PASS` | run `30580693884`, SHA `e2ad429f`, 3/3 job, step success, 0 annotation |

Ricevute complete e warning sono in
`docs/TASKS/EVIDENCE/TASK-003/execution-evidence.md`.

### Matrice CA -> evidence

La matrice canonica di 32 righe è in
`docs/TASKS/EVIDENCE/TASK-003/README.md`. `CA-01`–`CA-30` e `CA-32` hanno evidence
Execution `PASS`; `CA-31` è correttamente `NOT_RUN` perché coincide con la review
indipendente che questo handoff abilita.

### Matrice T-NN -> risultato

La matrice canonica di 22 righe è in
`docs/TASKS/EVIDENCE/TASK-003/README.md`. `T-01`–`T-19`, `T-21` e `T-22` sono
`PASS`; `T-20` è assegnato ai reviewer indipendenti.

### Rischi rimasti

- contratto Storefront, schema, API e health non sono ancora implementati;
- i grant `anon` legacy osservati richiedono verifica/hardening in TASK-005 e non sono
  usati dal Client;
- il workspace Supabase storico resta provenance non-Git e non authority;
- upgrade package disponibili restano fuori scope;
- il closeout richiede nuova CI sul proprio SHA conclusivo.

### Handoff a Review

- **Transizione**: `EXECUTION -> REVIEW`
- **Esito Executor**: `CODEX_EXECUTION_COMPLETE_TO_REVIEW`
- **Commit tecnico**: `e2ad429f25341f9009c3087673c36746e23bf059`
- **Prossimo ruolo**: `CODEX_REVIEWER`
- **Review richiesta**: intent, 32 CA, 22 test, diff, provenance, architettura,
  security, governance, CI e integrità esterna con verifiche autonome
- **Finding aperti dichiarati dall'Executor**: nessuno; il reviewer non assume corretto
  questo claim
- **Merge**: vietato; TASK-004 resta `TODO`
- **Timestamp**: `2026-07-30T20:55:02Z`

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

Pronta per sessioni read-only indipendenti dall'Execution; non ancora avviata.

## Fix — `CODEX_FIXER`

Non avviato. Sarà usato soltanto per finding approvati nello scope.

## Chiusura

- **Conferma utente**: condizionata nel prompt end-to-end
- **Merge autorizzato da USER_APPROVER**: sì, solo nella PR batch dopo TASK-004 e CI
  finale verde
- **Follow-up candidate**: eventuale riconciliazione di artifact Supabase storici in
  TASK-005; nessun apply da questo task
- **Riepilogo finale**: non ancora disponibile
- **Data completamento**: non ancora
