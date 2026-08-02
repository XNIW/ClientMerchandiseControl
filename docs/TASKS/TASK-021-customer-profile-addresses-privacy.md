# TASK-021 — Profilo cliente, indirizzi, privacy e cancellazione account

## Informazioni generali

- **Task ID**: TASK-021
- **Titolo**: Profilo cliente, indirizzi, privacy e cancellazione account
- **File task**: `docs/TASKS/TASK-021-customer-profile-addresses-privacy.md`
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-02
- **Ultimo aggiornamento**: 2026-08-02
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-021/`
- **Handoff**: CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW

## Dipendenze

- **Dipende da**: TASK-020
- **Checkpoint consumati**: foundation autenticata TASK-020; Milestone 3 TASK-013..019
- **Sblocca**: TASK-022, TASK-026, TASK-036, TASK-038
- **Repository writer**: Admin/Supabase per schema/RLS/RPC, poi Client Flutter; un
  solo writer alla volta

## Scope

- creare `customer_profiles` owner-scoped con user UUID, nome pubblico opzionale,
  lingua, preferenze essenziali, consent version/timestamp e lifecycle timestamps;
- creare `customer_addresses` owner-scoped con identificatore opaco, label, campi
  postali allow-listed, istruzioni bounded, indirizzo predefinito e ordinamento;
- non usare email come primary key e non memorizzare credential/token Google;
- garantire un solo indirizzo default per cliente con transazione/constraint sicura;
- aggiungere contratti server idempotenti per richiesta cancellazione account e
  richiesta/esportazione dati, senza eseguire cancellazioni production in questo task;
- applicare RLS owner-only e negare lettura/scrittura cross-user e anon;
- aggiungere repository/controller/UI Flutter per profilo, lingua, consenso, lista e
  form indirizzi, export e account deletion request;
- localizzare es-CL primaria, it, en e zh-Hans con fallback es e stati
  loading/empty/error/offline/retry;
- produrre migration replay, pgTAP/RLS, unit/widget/integration e smoke staging
  autenticato headless, mantenendo production invariata.

## Non incluso

- registrazione device/push token, di competenza TASK-022;
- carrello, checkout, zone e validazione fulfillment, di competenza TASK-023/TASK-026;
- cancellazione immediata o distruttiva dell'utente Auth e dei dati production;
- geocoding/provider indirizzi, dati fiscali, documenti identità o profili marketing
  estesi;
- memorizzazione di access token, refresh token, OAuth code, password o client secret;
- modifica production, invio email reale o workflow legale non verificato.

## File coinvolti

- Admin: migration, test pgTAP, contract/RPC e workflow staging canonici;
- Client: `lib/features/account/`, nuovo dominio customer profile/address, repository,
  controller, schermate/form e localizzazioni;
- test unit/widget/integration, boundary/security e smoke Android/iOS;
- task, evidence, Master Plan, checkpoint, manifest e worklog.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Profile/address usano `auth.users.id` UUID e mai email come identità primaria | SQL/SECURITY |
| CA-02 | RLS owner-only nega anon e cross-user per read/write/delete | PGTAP/INTEGRATION |
| CA-03 | Owner può creare, leggere, aggiornare ed eliminare profilo/indirizzi consentiti | PGTAP/INTEGRATION |
| CA-04 | Esiste al massimo un indirizzo default per user e la transizione è atomica | SQL/CONCURRENCY |
| CA-05 | Validazione fail-closed rifiuta indirizzi/campi/locale/consent non validi | UNIT/PGTAP |
| CA-06 | Nessuna credential Google, token o PII eccessiva entra in DB/log/client | SECURITY |
| CA-07 | Export contract restituisce soltanto dati owner allow-listed e risponde idempotentemente | INTEGRATION/SECURITY |
| CA-08 | Account deletion request è autenticata, idempotente, auditabile e revocabile secondo contratto | INTEGRATION |
| CA-09 | UI account/address gestisce CRUD, default, consenso, export e deletion request | WIDGET/INTEGRATION |
| CA-10 | es-CL/it/en/zh-Hans, fallback es, dark e text scale 200% non producono overflow critico | WIDGET/A11Y |
| CA-11 | Offline/error/retry non perdono modifiche né mostrano esito autorevole non confermato | UNIT/WIDGET |
| CA-12 | Gate completi, CI e smoke staging autenticato sono verdi sul revision set candidato | CI/BUILD/SMOKE |
| CA-13 | Production resta invariata e nessun secret/artifact locale è versionato | SECURITY/GIT |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-02 | PGTAP | owner success e anon/cross-user denial per ogni operazione |
| T-02 | CA-03, CA-04 | PGTAP/CONCURRENCY | CRUD e due richieste concorrenti di default address |
| T-03 | CA-05 | UNIT/PGTAP | address vuoto/oversize, locale non supportato, consent incoerente, ID malevolo |
| T-04 | CA-06 | STATIC/SECURITY | scan schema/payload/log per email key, credential/token e campi vietati |
| T-05 | CA-07 | INTEGRATION | export owner, cross-user denial, payload allow-list e retry idempotente |
| T-06 | CA-08 | INTEGRATION | create/retry/revoke deletion request e audit senza cancellazione dati |
| T-07 | CA-09, CA-11 | UNIT/WIDGET | CRUD/default/consent/export/delete con success, timeout, offline e retry |
| T-08 | CA-10 | WIDGET/A11Y | quattro locale, fallback, theme, 200%, compact/tablet/landscape e Semantics |
| T-09 | CA-12 | ANDROID_EMU/IOS_SIM | login test esistente, profile/address flow e session restore headless |
| T-10 | CA-12, CA-13 | CI/GIT | gate Client/Admin/Supabase, CI exact SHA, secret scan e production unchanged |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | `auth.users.id` UUID è l'identità owner; email resta attributo non-key e non duplicato se non necessario | Email è mutabile e non è un boundary autorizzativo | ATTIVA |
| D-02 | Profile/address sono dominio Storefront separato da inventory/POS | Mantiene il confine pubblico e il least privilege | ATTIVA |
| D-03 | Account deletion è una request state machine, non una delete client-side | Consente audit, retention e cancellazione server-side controllata | ATTIVA |
| D-04 | Export è generato server-side da un contratto allow-listed versionato | Evita query client arbitrarie e leakage cross-user | ATTIVA |
| D-05 | Consenso registra versione, timestamp e stato, senza dark pattern o opt-in implicito | Rende il consenso verificabile e revocabile | ATTIVA |
| D-06 | Planning ed Execution sono autorizzati dal prompt USER_APPROVER del 2026-08-02 | Consente continuità headless del release train | ATTIVA |
| D-07 | Profilo, indirizzi e privacy sono risorse globali dell'owner e non contengono una dimensione shop | Evita un criterio cross-shop non presente nel contratto approvato; lo shop scope resta nei domini commerciali successivi | ATTIVA |
| D-08 | La CI Client `30763287350` resta `BLOCKED` per billing GitHub prima dell'avvio dei runner; non viene trasformata in `PASS` e il gate tecnico è attestato localmente sullo SHA esatto | Applica il principio USER_APPROVER non bloccante senza falsificare il risultato esterno | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Fornire il primo dominio cliente owner-scoped della Storefront v1, con profilo,
indirizzi e operazioni privacy sicure, riusabile dal checkout senza accoppiare Auth,
inventory o provider esterni.

### Analisi

- TASK-020 offre PKCE Google, session restore e logout, ma nessuna tabella customer;
- l'account screen corrente è una superficie minima e non possiede repository dati;
- il checkout futuro richiede indirizzi stabili, ma zone/fee/fulfillment restano TASK-026;
- RLS e RPC devono essere canonici nel repository Admin/Supabase, mentre il Client
  consuma soltanto contratti versionati e non decide autorizzazione;
- deletion/export richiedono request idempotenti e audit, non operazioni distruttive
  direttamente dall'app.

### Approccio autorizzato

1. audit dei contratti Auth, pattern migration/RLS e account UI esistenti;
2. migration additiva per profile/address/privacy request e RPC owner-scoped;
3. pgTAP owner/cross-user/concurrency/validation e replay locale;
4. apply guarded e smoke autenticato su staging sintetico con cleanup;
5. model/repository/controller Flutter strict e failure taxonomy sanitizzata;
6. UI profilo/indirizzi/privacy responsive, accessibile e localizzata;
7. test unit/widget/integration, smoke Android/iOS, gate completi e CI;
8. evidence e checkpoint; TASK-022 si attiva soltanto se tutti i gate obbligatori sono
   `PASS`.

### Rischi

- cross-user leakage: FORCE RLS, owner derivato da `auth.uid()` e negative pgTAP;
- race default address: indice/locking e singola funzione transazionale;
- PII nei log: error mapping sanitizzato e scan log/payload;
- delete irreversibile: solo request/revoke in staging, nessuna eliminazione Auth;
- scope creep checkout: address model non calcola zone, fee o disponibilità;
- staging condiviso: fixture user/shop namespaced, cleanup idempotente e zero residui.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: ricevuta nel prompt release train 2026-08-02

## Execution — `CODEX_EXECUTOR`

### Modifiche completate

- migration additiva Admin/Supabase `20260802181823` con `customer_profiles`,
  `customer_addresses` e `customer_account_deletion_requests`, tutte con FORCE RLS,
  grant espliciti e policy owner-only;
- RPC consent, default address atomico, deletion request/cancel idempotenti ed export
  owner allow-listed; funzioni `SECURITY DEFINER` con `search_path` vuoto e revoke
  `PUBLIC` dove applicabile;
- repository Flutter strict con query allow-listed, failure taxonomy sanitizzata,
  timeout, validazione UUID e contract parser export fail-closed;
- controller Riverpod session-aware con single-flight, retry idempotente e invalidazione
  corretta quando l'identità cambia durante un'operazione;
- UI Account data-backed per profilo, lingua, CRUD/default indirizzi, consenso, export e
  deletion request/cancel, con stati loading/offline/error/retry;
- localizzazione es-CL, it, en e zh-Hans, fallback es, dark mode, text scale 200%,
  Semantics e target touch di almeno 48 logical pixel;
- integration flow headless installato ed eseguito su Android Emulator e iOS Simulator.

### Gate eseguiti

- Admin/Supabase SHA `27770dbe76da3066cdddb5a821b01c144a9ae607`, PR #67 draft:
  migration replay `PASS`; pgTAP TASK-021 64/64 e suite completa 26 file/1.582 test
  `PASS` in 44,84 s; race due default writer `PASS`; `npm run verify` exit 0 in
  20,74 s; foundation 793 test (791 pass, 2 skip) e security scan `PASS`;
- staging migration `20260802181823` applicata dalla run `30761578366`, job
  `91532997593`, `PASS`; postverify 64/64, tre tabelle FORCE RLS, nove policy e nessuna
  colonna sensibile; artifact `8837628074`, SHA-256
  `93eaae9856fcee4217d272b171135e174bdd5ff173a1520d6f3db9d14fd3f98e`;
- Admin CI `30761579498`, Cloudflare `30761579496` e regressione performance
  `30761578384` sullo SHA esatto: `PASS`;
- Client SHA `4f25b539248c642351e50667a53d6fcb95840c41`, PR #5 draft:
  `scripts/check.sh` exit 0 in 100,41 s; analyze/format/security/governance/architecture,
  371 test, coverage 5.743/7.098 (80,91%), benchmark separato 1/1, Android debug e iOS
  Simulator debug `PASS`;
- integrazione Account reale Android Emulator API 35: 1/1 `PASS`, exit 0 in 78,31 s;
  iPhone 17 Pro Simulator iOS 26.1: 1/1 `PASS`, exit 0 in 35,21 s;
- CI Client `30763287350`: `BLOCKED`, tre job con zero step/runner e annotazione billing
  GitHub; nessun failure di codice o retry cieco dichiarato;
- security scan Client su 445 file tracciati `PASS`; production non è stata invocata,
  i flag production restano OFF e nessun secret/artifact è versionato.

### Matrici

CA-01..CA-11 e CA-13: `PASS`. CA-12: gate tecnici, staging e smoke `PASS`; solo il
sottogate GitHub-hosted Client CI è `BLOCKED` esterno. T-01..T-09: `PASS`; T-10:
security/Git/production unchanged `PASS`, Client CI `BLOCKED`. Le evidence riproducibili
sono in `docs/TASKS/EVIDENCE/TASK-021/README.md`.

### Handoff

`CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`. Nessuna review formale è stata
eseguita e TASK-021 non è `DONE`.

## Checkpoint release train — `CODEX_EXECUTOR`

TASK-021 è `VALIDATED_PENDING_INTEGRATED_REVIEW` sul revision set Client/Admin
registrato. Il blocker CI Client è esclusivamente esterno e resta esplicitamente
`BLOCKED`; production è invariata. Il task successivo autorizzato è TASK-022.

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

Riservata alla review integrata finale.

## Fix — `CODEX_FIXER`

Riservato all'eventuale ciclo Fix integrato.

## Chiusura

- **Conferma utente**: ricevuta in forma condizionata dal release train
- **Merge autorizzato da USER_APPROVER**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: TASK-022 attivato dal checkpoint tecnico
- **Riepilogo finale**: validato tecnicamente, in attesa della review integrata
- **Data completamento**: non ancora
