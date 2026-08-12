# TASK-026 — Checkout con ritiro e consegna

## Informazioni generali

- **Task ID**: TASK-026
- **Titolo**: Checkout con ritiro e consegna
- **File task**: `docs/TASKS/TASK-026-checkout-pickup-delivery.md`
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-02
- **Ultimo aggiornamento**: 2026-08-02
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-026/`
- **Handoff**: CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW

## Dipendenze

- **Dipende da**: TASK-021, TASK-023, TASK-025
- **Checkpoint consumati**: profilo/indirizzi; cart/revalidation; reservation hold
- **Sblocca**: TASK-027, TASK-036
- **Repository writer**: Admin/Supabase, poi Client; nessun writer POS

## Scope

- definire configurazione fulfillment shop-scoped per `pickup`, `reservation` e
  `delivery`, mantenendo disabilitata ogni modalità non configurata;
- modellare pickup point, delivery zone, slot/capacity e fee con contratti pubblici
  bounded e dati operativi privati;
- validare server-side customer, shop, cart version, pubblicazione, prezzo, promozione,
  quantità, hold, indirizzo, zona, slot, fee e totale prima della conferma checkout;
- produrre una quote autorevole, versionata, idempotente e con scadenza; il totale
  inviato dal client è ignorato e non diventa mai autorità;
- gestire price changed, promotion expired, unavailable, hold expired, invalid address,
  unsupported zone, slot unavailable, timeout ambiguo e retry senza doppio effetto;
- integrare un flusso Client progressivo: modalità, indirizzo/ritiro, fascia, riepilogo,
  conferma, con autenticazione Google richiesta soltanto al momento del checkout;
- mostrare differenze di prezzo/fee/disponibilità in modo esplicito e accessibile,
  mantenendo guest browsing e guest cart;
- aggiungere nell'Admin i controlli strettamente necessari per configurare modalità,
  pickup point, zone, slot e fee, con RBAC e audit;
- produrre replay, pgTAP/RLS, concurrency, staging E2E quote, Playwright, Flutter
  unit/widget/integration Android/iOS, build e smoke headless;
- mantenere production e tutti i feature flag invariati/OFF.

## Non incluso

- creazione dell'ordine, item snapshot, status event e outbox, di competenza TASK-027;
- gestione/accettazione ordini Admin, di competenza TASK-029;
- handoff POS o vendita fiscale, di competenza TASK-030;
- push, pagamento online o rollout production;
- geocoding/provider map, ottimizzazione route o credenziali merchant;
- fiducia in prezzo, sconto, fee, totale, shop, customer o clock forniti dal client;
- migrazioni distruttive o dipendenza da GUI/dispositivo fisico.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Solo modalità abilitate/configurate sono selezionabili e il contratto è shop-scoped | CONTRACT/PGTAP |
| CA-02 | Pickup point, zone, slot e fee sono validati server-side con RLS/RBAC e audit | SECURITY/PGTAP |
| CA-03 | Quote rilegge cart, catalogo, prezzi, promo, availability e hold autorevoli | CONTRACT/PGTAP |
| CA-04 | Totale/sconto/fee malevoli dal client sono ignorati o rifiutati senza alterare la quote | SECURITY |
| CA-05 | Idempotency e scadenza rendono sicuri timeout, retry e doppio tap | CONCURRENCY/INTEGRATION |
| CA-06 | Address/zone/slot invalidi, capacity race e delivery disabilitata falliscono chiuso | PGTAP/CONCURRENCY |
| CA-07 | Client offre cinque step chiari, back/restore e variazioni esplicite senza perdere il cart | WIDGET/INTEGRATION |
| CA-08 | Guest browsing resta libero; checkout richiede identity e address owner-scoped quando necessario | AUTH/INTEGRATION |
| CA-09 | UI/Admin sono accessibili, localizzati, responsive e coerenti col design system esistente | A11Y/PLAYWRIGHT |
| CA-10 | Gate Admin/Supabase/Client, staging e smoke headless passano sul revision set | CI/BUILD/SMOKE |
| CA-11 | Production resta invariata e nessun secret/config/artifact è versionato | SECURITY/GIT |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-02 | PGTAP/RBAC | modalità, zone, slot e fee shop-scoped; anon/cross-shop denial |
| T-02 | CA-03, CA-04 | PGTAP/SECURITY | repricing/promo/stock/hold e input totale/sconto/fee malevoli |
| T-03 | CA-05 | CONCURRENCY | stessa idempotency key, key conflicting, doppio tap e timeout ambiguo |
| T-04 | CA-06 | PGTAP/CONCURRENCY | address/zone/slot invalidi e due clienti sull'ultimo slot |
| T-05 | CA-07, CA-08 | UNIT/WIDGET | cinque step, back/restore, auth gate e cart preservato |
| T-06 | CA-09 | WIDGET/A11Y | compact/tablet, dark, 200%, quattro lingue, Semantics e focus |
| T-07 | CA-09 | PLAYWRIGHT | Admin configura fulfillment con RBAC/audit e preview responsive |
| T-08 | CA-10 | ANDROID_EMU/IOS_SIM | cart -> auth -> quote/reprice -> conferma checkout headless |
| T-09 | CA-10, CA-11 | CI/GIT | replay, staging exact SHA, gate, secret scan e production unchanged |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | La quote server è l'unica autorità economica del checkout | Impedisce total/discount/fee tampering | ATTIVA |
| D-02 | Modalità, zone, slot e fee non configurati falliscono chiuso | Evita promesse di fulfillment non supportate | ATTIVA |
| D-03 | La quote non crea ancora un ordine | Mantiene atomicità ordine e snapshot in TASK-027 | ATTIVA |
| D-04 | Guest browsing/cart restano disponibili; identity è richiesta al checkout | Conserva il requisito storefront senza login | ATTIVA |
| D-05 | Nessun provider map/geocoding viene inventato | Evita dipendenze e credenziali speculative | ATTIVA |
| D-06 | UI usa shell, token e componenti Material 3 esistenti | Mantiene continuità col pass UI hardening | ATTIVA |
| D-07 | Planning ed Execution sono autorizzati dal prompt USER_APPROVER del 2026-08-02 | Mantiene il release train headless continuo | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Costruire un checkout progressivo e server-authoritative per ritiro, prenotazione e
consegna configurabile, pronto a essere consumato dall'ordine idempotente TASK-027.

### Analisi

- TASK-021 fornisce identity e indirizzi owner-scoped, ma non zone o fulfillment;
- TASK-023 fornisce cart versionato e revalidation, ma il totale client non è fidato;
- TASK-025 fornisce hold attivo/scadibile, ma non indirizzo, slot o fee;
- prima di scegliere lo schema occorre auditare configurazione shop, tabelle customer,
  cart RPC, reservation hold, promozioni e pattern Admin/RBAC/audit correnti;
- quote e slot richiedono idempotency, clock server e lock order coerente per evitare
  capacity oversubscription e retry duplicati.

### Approccio autorizzato

1. audit read-only di fulfillment/config esistente, address/cart/hold RPC, pricing,
   promotion, RBAC/audit Admin e contratti pubblici;
2. definizione delle invarianti quote/zone/slot/fee e dell'ordine dei lock;
3. migration additiva minima con FORCE RLS, grant strict, RPC quote/version/idempotency
   e audit, soltanto dove il contratto corrente non copre i criteri;
4. pgTAP e concorrenza per cross-shop, malicious totals, repricing, slot race, expiry e
   retry ambiguo;
5. apply guarded e staging smoke con fixture sintetiche e cleanup a zero;
6. Admin configuration/RBAC/Playwright strettamente necessaria;
7. flow Client a cinque step, restore/auth gate/a11y/l10n e integration Android/iOS;
8. gate completi, evidence/checkpoint e attivazione TASK-027 soltanto con verde tecnico.

### Rischi e mitigazioni

- total tampering: ricalcolo completo server-side e response allow-list;
- slot oversubscription: lock/capacity mutation nella stessa transazione della quote;
- quote stale: versione cart/catalogo e expiry server-side, conferma con revalidation;
- cross-shop/address leakage: owner auth, shop binding, FORCE RLS e test negativi;
- timeout ambiguo: ledger idempotency e stato recuperabile per key;
- UI lunga/fragile: step piccoli, stato persistito e CTA SafeArea usando componenti
  esistenti;
- scope creep ordine/payment: nessun order/outbox/payment side effect nel task.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: prompt headless Storefront v1 2026-08-02

## Execution — `CODEX_EXECUTOR`

Execution completata sul revision set Admin/Supabase
`86088dc739c59725735533c64133678e96641a9a` e Client
`9406df7d5b5d5a69a0edc033359be38f3bdf656f`.

- l'audit ha confermato che address, cart/version, pricing/promotion e reservation hold
  esistenti potevano essere composti senza introdurre un secondo dominio economico;
- le migration additive `20260803020000_storefront_v1_checkout_fulfillment` e
  `20260803021500_storefront_v1_checkout_admin` introducono configurazione shop-scoped,
  pickup point, delivery zone, slot/capacity, quote e ledger idempotente privati, FORCE
  RLS, grant minimi, audit Admin ed expiry cron bounded;
- quattro RPC customer strict espongono discovery pubblica e quote owner-scoped;
  ricalcolano cart, publication, prezzo, promozione, availability, hold, address, zona,
  slot, fee e totale, ignorando ogni totale/sconto/fee client;
- la race a due customer sull'ultimo slot produce una sola quote attiva, chiude lo slot
  pubblico e lascia invariato lo stock on-hand; retry e doppio tap riusano la stessa
  idempotency key;
- l'Admin aggiunge configurazione fulfillment e anteprima con RBAC, audit, filtri,
  responsive table e Playwright desktop/tablet senza nuovo framework UI;
- il Client aggiunge repository/parser fail-closed, draft/pending operation owner-scoped,
  controller Riverpod e checkout Material 3 in cinque step per pickup, reservation e
  delivery, con auth gate soltanto al checkout, restore, timeout ambiguo, repricing e
  CTA SafeArea;
- quattro localizzazioni, Semantics, dark mode, text scale 200%, golden canonico e flow
  integration Android/iOS coprono UI e resilienza; il contratto pubblico live staging è
  stato letto attraverso il vero adapter anonimo;
- il security scanner artifact è stato irrobustito per estrarre senza prompt e verificare
  anche entry ZIP duplicate, con regressione negativa/positiva dedicata.

Comandi, conteggi, CI, staging, matrici CA/Test e limiti sono registrati in
`docs/TASKS/EVIDENCE/TASK-026/README.md`. Production non è stata invocata e tutti i
flag restano OFF.

## Checkpoint release train — `CODEX_EXECUTOR`

### Gate pertinenti eseguiti

- Admin/Supabase: replay completo, 56/56 pgTAP TASK-026, suite database 31 file/
  1.892 test, race multi-session, foundation/lint/typecheck/security/build e Playwright
  desktop/tablet: `PASS`;
- CI Admin `30779607356`, Cloudflare `30779607377` e staging exact-SHA
  `30779605562`, job `91581524589`: `PASS`; artifact `8843215328`, digest
  `56a17798853cd59c185317230acef2f1910043d6c76a06ff20e77f114efce128`;
- Client: gate canonico `scripts/check.sh`, 489 test, coverage 9.254/12.002
  (77,10%), benchmark cache 25.000 righe, build Android/iOS e security: `PASS`;
- integration checkout Android API 35 e iPhone 17 Pro iOS 26.5: 1/1 per piattaforma;
  live public staging Android 1/1; smoke CLI, screenshot e artifact scan: `PASS`;
- CI Client exact-SHA `30781669519`: `BLOCKED` esterna perché Quality/Android/iOS
  hanno zero runner e zero step per billing/spending limit; non è dichiarata `PASS`.

### Compatibilità e staging

Lo staging ha applicato entrambe le migration additive e ha verificato ledger esatto,
sei tabelle private, FORCE RLS, owner policy, boundary mobile/service role, quattro RPC
customer, due RPC Admin, `search_path`, discovery anonima, checkout autenticato e cron
expiry. La fixture transazionale è stata rimossa; la fixture pubblica persistente
espone correttamente CLP e tre modalità, ma nessuna destinazione/slot fittizia.

### Handoff al task successivo

- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Review outcome**: NOT_RUN
- **Prossimo task**: TASK-027
- **Handoff**: STOREFRONT_V1_MILESTONE_CHECKPOINT_VALIDATED

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.

## Chiusura

- **Conferma utente**: ricevuta in forma condizionata dal release train
- **Merge autorizzato**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: TASK-027 attivato dal checkpoint tecnico
- **Riepilogo finale**: validato tecnicamente, in attesa della review integrata
- **Data completamento**: non ancora
