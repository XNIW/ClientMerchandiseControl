# Master Plan — ClientMerchandiseControl

## Stato globale

- **Progetto**: ClientMerchandiseControl
- **Obiettivo**: app clienti Android/iOS per il dominio pubblico Storefront di Merchandise Control
- **Stato globale**: ACTIVE
- **Task attivo**: TASK-001
- **File task**: `docs/TASKS/TASK-001-bootstrap-foundation.md`
- **Stato task**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX
- **Indicatore**: IN_PROGRESS
- **Prossima azione autorizzata**: completare esclusivamente l'Execution di TASK-001

## Repository coinvolti

- `XNIW/ClientMerchandiseControl` — repository corrente e unico writer di TASK-001.
- `XNIW/merchandise-control-admin-web` — futuro control plane Storefront.
- `XNIW/MerchandiseControlSplitView` — fonte operativa Android, sola lettura in TASK-001.
- `XNIW/iOSMerchandiseControl` — fonte operativa iOS, sola lettura in TASK-001.
- `XNIW/Win7POS` — POS e stock operativo, sola lettura in TASK-001.
- Supabase esistente — backend futuro; nessuna modifica in TASK-001.

## Principi architetturali

- Una codebase Flutter stable, soli target Android e iOS.
- Feature-first MVVM con Riverpod e go_router, senza layer vuoti.
- Dati cliente separati dal dominio inventory operativo.
- Admin Console come control plane di pubblicazione.
- Mutazioni sensibili validate server-side con RLS, idempotenza e audit.
- Configurazione compile-time, nessun secret nel client.
- Un solo task attivo; nessun avanzamento senza evidence.

## Roadmap

1. Foundation e contratto (`TASK-001`–`TASK-010`).
2. Connessione e catalogo mobile (`TASK-011`–`TASK-019`).
3. Cliente e profilo (`TASK-020`–`TASK-022`).
4. Carrello, prenotazioni e ordini (`TASK-023`–`TASK-032`).
5. Hardening e rilascio (`TASK-033`–`TASK-042`).

## Backlog completo

| ID | Titolo | Stato | Dipendenze | Repository interessati | Risultato atteso |
|---|---|---|---|---|---|
| TASK-001 | Repository governance, Flutter foundation, CI e dual-platform smoke | ACTIVE | nessuna | Client | Fondazione compilabile, verificata e pronta a review |
| TASK-002 | Product scope definitivo, branding, UX principles e design tokens | TODO | TASK-001 | Client | Identità e principi UX approvati |
| TASK-003 | Cross-repo ownership e Storefront integration contract | TODO | TASK-001, TASK-002 | Client, Admin, Android, iOS, POS | Contratto di ownership senza ambiguità |
| TASK-004 | Environment strategy development/staging/production e configuration contract | TODO | TASK-001, TASK-003 | Client, Admin | Strategia ambienti e config verificabile |
| TASK-005 | Supabase Storefront schema, RLS, grants e migration ownership | TODO | TASK-003, TASK-004 | Admin, Supabase, Client | Schema pubblico protetto e ownership migration |
| TASK-006 | Storefront catalog projection e aggiornamento dal dominio operativo | TODO | TASK-005 | Admin, Supabase, Android, iOS, POS | Proiezione catalogo pubblica affidabile |
| TASK-007 | Admin Console: pubblicazione e gestione visibilità prodotti | TODO | TASK-005, TASK-006 | Admin, Supabase | Controlli di pubblicazione shop-scoped |
| TASK-008 | Admin Console: prezzi pubblici, sconti e promozioni programmate | TODO | TASK-005, TASK-006, TASK-007 | Admin, Supabase | Gestione commerciale pubblica |
| TASK-009 | Pipeline immagini pubbliche Storefront | TODO | TASK-005, TASK-007 | Admin, Supabase | Immagini pubbliche sicure e versionate |
| TASK-010 | Catalog query contract, search, pagination, fixtures e contract test | TODO | TASK-005, TASK-006, TASK-009 | Client, Admin, Supabase | Contratto query catalogo testabile |
| TASK-011 | Connessione Flutter allo staging e backend health state | TODO | TASK-004, TASK-005, TASK-010 | Client, Supabase | Connessione staging fail-closed |
| TASK-012 | App shell, design system, localizzazione, CLP e accessibility baseline | TODO | TASK-002, TASK-011 | Client | Shell prodotto e baseline accessibile |
| TASK-013 | Home e prodotti/promozioni in evidenza | TODO | TASK-010, TASK-011, TASK-012 | Client, Admin, Supabase | Home Storefront data-backed |
| TASK-014 | Categorie e griglia catalogo con caricamento immagini | TODO | TASK-010, TASK-011, TASK-012 | Client, Supabase | Browsing catalogo completo |
| TASK-015 | Ricerca, filtri e ordinamento | TODO | TASK-010, TASK-014 | Client, Supabase | Discovery catalogo efficiente |
| TASK-016 | Dettaglio prodotto e disponibilità commerciale | TODO | TASK-010, TASK-014 | Client, Supabase | Dettaglio pubblico coerente |
| TASK-017 | Cache catalogo offline, refresh e invalidazione | TODO | TASK-010, TASK-014 | Client | Catalogo resiliente offline |
| TASK-018 | Preferiti, condivisione e deep link prodotto | TODO | TASK-012, TASK-016, TASK-017 | Client | Ritorno e condivisione prodotto |
| TASK-019 | Catalog performance e acceptance su dataset esteso | TODO | TASK-010, TASK-014, TASK-015, TASK-017 | Client, Supabase | Budget prestazioni misurato |
| TASK-020 | Supabase Auth, deep link e session lifecycle | TODO | TASK-004, TASK-005, TASK-011, TASK-012 | Client, Supabase | Sessioni cliente sicure |
| TASK-021 | Profilo cliente, indirizzi, privacy e cancellazione account | TODO | TASK-020 | Client, Supabase, Admin | Profilo privacy-safe |
| TASK-022 | Registrazione device, consenso notifiche e token lifecycle | TODO | TASK-020, TASK-021 | Client, Supabase | Consenso e token gestiti |
| TASK-023 | Carrello persistente e price revalidation | TODO | TASK-012, TASK-016, TASK-017 | Client, Supabase | Carrello coerente e rivalidato |
| TASK-024 | Proiezione disponibilità e stock pubblico | TODO | TASK-005, TASK-006, TASK-010 | Admin, Supabase, POS, Client | Disponibilità pubblica controllata |
| TASK-025 | Reservation hold atomico e scadenza | TODO | TASK-023, TASK-024 | Supabase, Admin, Client | Hold concorrente e scadibile |
| TASK-026 | Checkout con ritiro e consegna | TODO | TASK-021, TASK-023, TASK-025 | Client, Admin, Supabase | Fulfillment validato |
| TASK-027 | Creazione ordine idempotente e price snapshot | TODO | TASK-005, TASK-020, TASK-023, TASK-025, TASK-026 | Client, Admin, Supabase | Ordine atomico e idempotente |
| TASK-028 | Storico, dettaglio e stato ordine | TODO | TASK-027 | Client, Admin, Supabase | Tracking ordine cliente |
| TASK-029 | Admin Console: gestione e preparazione ordini | TODO | TASK-007, TASK-027 | Admin, Supabase | Workflow preparazione ordini |
| TASK-030 | Win7POS handoff, stock reservation release e confine vendita fiscale | TODO | TASK-006, TASK-024, TASK-027, TASK-029 | POS, Admin, Supabase | Handoff operativo senza fusione eventi |
| TASK-031 | Notifiche push e order status events | TODO | TASK-022, TASK-027, TASK-028, TASK-029 | Client, Admin, Supabase | Eventi e notifiche affidabili |
| TASK-032 | Decisione provider e integrazione pagamenti | TODO | TASK-027 | Client, Admin, Supabase | Pagamento selezionato e integrato |
| TASK-033 | Threat model, RLS abuse testing, rate limit e security hardening | TODO | TASK-005, TASK-020, TASK-025, TASK-027, TASK-032 | Client, Admin, Supabase | Confini attaccabili testati |
| TASK-034 | Offline/reconnect/concorrenza/idempotenza test matrix | TODO | TASK-017, TASK-023, TASK-025, TASK-027, TASK-030 | Client, Admin, Supabase, POS | Matrice resilienza superata |
| TASK-035 | Observability, crash reporting e analytics privacy-safe | TODO | TASK-011, TASK-020, TASK-027, TASK-031 | Client, Admin | Telemetria privacy-safe |
| TASK-036 | Accessibility, localizzazione e device matrix | TODO | TASK-012, TASK-018, TASK-021, TASK-026, TASK-028, TASK-031 | Client | Acceptance accessibilità e lingue |
| TASK-037 | Performance, immagini, cache e load testing | TODO | TASK-009, TASK-017, TASK-019, TASK-027 | Client, Admin, Supabase | Budget performance end-to-end |
| TASK-038 | Store assets, privacy policy, legal e release metadata | TODO | TASK-002, TASK-021, TASK-032, TASK-033, TASK-036 | Client, Admin | Materiale release conforme |
| TASK-039 | Android internal testing release | TODO | TASK-033, TASK-034, TASK-035, TASK-036, TASK-037, TASK-038 | Client | Build Android internal test |
| TASK-040 | iOS TestFlight release | TODO | TASK-033, TASK-034, TASK-035, TASK-036, TASK-037, TASK-038 | Client | Build iOS TestFlight |
| TASK-041 | Production launch, rollback e runbook | TODO | TASK-039, TASK-040 | Client, Admin, Supabase, POS | Lancio controllato e reversibile |
| TASK-042 | Post-launch monitoring, supporto e manutenzione | TODO | TASK-041 | Tutti | Operatività post-lancio |

## Dipendenze e blocchi

Le dipendenze della tabella formano un grafo aciclico orientato verso task con ID maggiore.
Non risultano blocker di progetto attivi al bootstrap.

## Task completati

Nessuno. TASK-001 non può essere aggiunto qui prima di review `APPROVED` e conferma
esplicita dell'utente.
