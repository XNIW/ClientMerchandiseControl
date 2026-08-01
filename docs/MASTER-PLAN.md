# Master Plan — ClientMerchandiseControl

## Stato globale

- **Progetto**: ClientMerchandiseControl
- **Obiettivo**: app clienti Android/iOS per il dominio pubblico Storefront di Merchandise Control
- **Stato globale**: ACTIVE
- **Task attivo**: TASK-020
- **File task**: `docs/TASKS/TASK-020-supabase-auth-deep-link-session-lifecycle.md`
- **Stato task**: BLOCKED
- **Fase**: REVIEW
- **Responsabile**: CODEX_RE_REVIEWER
- **Indicatore**: CODEX_REVIEW_BLOCKED
- **Prossima azione autorizzata**: attendere login/MFA Supabase o rinnovo del token
  CLI e ripristino billing/spending GitHub, quindi rieseguire i gate impattati;
  nessun `APPROVED`, `DONE` o merge finché i gate esterni restano aperti

## Repository coinvolti

- `XNIW/ClientMerchandiseControl` — repository corrente e unico writer del client.
- `XNIW/merchandise-control-admin-web` — control plane e migration/server contract
  authority candidata, auditata in sola lettura.
- `XNIW/MerchandiseControlSplitView` — fonte operativa Android, sola lettura.
- `XNIW/iOSMerchandiseControl` — fonte operativa iOS, sola lettura.
- `XNIW/Win7POS` — POS e stock operativo, sola lettura.
- Supabase non-production esistente — metadata auditati in sola lettura; nessuna
  modifica di schema, Auth, Storage, branch o configurazione.
- Workspace Supabase storico non-Git — sola provenance, nessuna authority o scrittura.

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
| TASK-001 | Repository governance, Flutter foundation, CI e dual-platform smoke | DONE | nessuna | Client | Fondazione compilabile, verificata e pronta a review |
| TASK-002 | Product scope definitivo, branding, UX principles e design tokens | DONE | TASK-001 | Client | Identità e principi UX approvati |
| TASK-003 | Cross-repo ownership e Storefront integration contract | DONE | TASK-001, TASK-002 | Client, Admin, Android, iOS, POS | Contratto di ownership senza ambiguità |
| TASK-004 | Environment strategy development/staging/production e configuration contract | DONE | TASK-001, TASK-003 | Client, Admin | Strategia ambienti e config verificabile |
| TASK-005 | Supabase Storefront schema, RLS, grants e migration ownership | TODO | TASK-003, TASK-004 | Admin, Supabase, Client | Schema pubblico protetto e ownership migration |
| TASK-006 | Storefront catalog projection e aggiornamento dal dominio operativo | TODO | TASK-005 | Admin, Supabase, Android, iOS, POS | Proiezione catalogo pubblica affidabile |
| TASK-007 | Admin Console: pubblicazione e gestione visibilità prodotti | TODO | TASK-005, TASK-006 | Admin, Supabase | Controlli di pubblicazione shop-scoped |
| TASK-008 | Admin Console: prezzi pubblici, sconti e promozioni programmate | TODO | TASK-005, TASK-006, TASK-007 | Admin, Supabase | Gestione commerciale pubblica |
| TASK-009 | Pipeline immagini pubbliche Storefront | TODO | TASK-005, TASK-007 | Admin, Supabase | Immagini pubbliche sicure e versionate |
| TASK-010 | Catalog query contract, search, pagination, fixtures e contract test | TODO | TASK-005, TASK-006, TASK-008, TASK-009 | Client, Admin, Supabase | Contratto query catalogo testabile |
| TASK-011 | Connessione Flutter allo staging e backend health state | DONE | TASK-004 | Client, Supabase | Connessione staging fail-closed |
| TASK-012 | App shell, design system, localizzazione, CLP e accessibility baseline | DONE | TASK-002, TASK-011 | Client | Shell prodotto e baseline accessibile |
| TASK-013 | Home e prodotti/promozioni in evidenza | TODO | TASK-010, TASK-011, TASK-012 | Client, Admin, Supabase | Home Storefront data-backed |
| TASK-014 | Categorie e griglia catalogo con caricamento immagini | TODO | TASK-010, TASK-011, TASK-012 | Client, Supabase | Browsing catalogo completo |
| TASK-015 | Ricerca, filtri e ordinamento | TODO | TASK-010, TASK-014 | Client, Supabase | Discovery catalogo efficiente |
| TASK-016 | Dettaglio prodotto e disponibilità commerciale | TODO | TASK-010, TASK-014 | Client, Supabase | Dettaglio pubblico coerente |
| TASK-017 | Cache catalogo offline, refresh e invalidazione | TODO | TASK-010, TASK-014 | Client | Catalogo resiliente offline |
| TASK-018 | Preferiti, condivisione e deep link prodotto | TODO | TASK-012, TASK-016, TASK-017 | Client | Ritorno e condivisione prodotto |
| TASK-019 | Catalog performance e acceptance su dataset esteso | TODO | TASK-010, TASK-014, TASK-015, TASK-017 | Client, Supabase | Budget prestazioni misurato |
| TASK-020 | Supabase Auth, deep link e session lifecycle | BLOCKED | TASK-004, TASK-011, TASK-012 | Client, Supabase | Sessioni cliente sicure |
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

Dopo la foundation comune di TASK-003/TASK-004, il grafo separa un workstream catalogo
(TASK-005–TASK-010) e un workstream autenticazione (TASK-011, TASK-012, TASK-020–TASK-022).
Il parallelismo descrive dipendenze indipendenti, non execution concorrente: resta
vincolante un solo task `ACTIVE` alla volta.

## Task completati

- `TASK-001` — review `APPROVED`, conferma `USER_APPROVER` ricevuta il 2026-07-30,
  PR #1 merged con merge commit `f6bd88263fe8369c9ececa38367f629f3d1a929f`.
- `TASK-002` — re-review `APPROVED`, conferma condizionata `USER_APPROVER` applicata il
  2026-07-30; CI finale run `30577156105` `PASS` sullo SHA `3706127`, PR #2 merged
  con merge commit `46686ace3b4670f207147f12110d8133ced01e8e`.
- `TASK-003` — re-review `APPROVED`, conferma condizionata `USER_APPROVER` applicata il
  2026-07-30; 0 P0/P1/P2 aperti, CI finale run `30585880180` `PASS` sullo SHA
  `108b4f214a045dfc8157dd85eb87b9ce58c02d6b`.
- `TASK-004` — re-review `APPROVED`, conferma condizionata `USER_APPROVER` applicata il
  2026-07-30; 0 P0/P1/P2 aperti, CI closeout run `30592502472` `PASS` sullo SHA
  `0fc8d8bbd7d8fded9bb93e1e92ac069164ba58a9`; PR batch #3 merged con merge commit
  `40d118eebf78eeabea9e26747adb00053dd875bc`.
- `TASK-011` — re-review `APPROVED`, conferma condizionata `USER_APPROVER` applicata il
  2026-07-30; 0 P0/P1/P2 aperti, CI approvazione `30601758281` `PASS` sullo SHA
  `6cdfdd9987a278ff00189de72247fe1f689d9c24`; CI closeout `30602210469` `PASS`
  sullo SHA `2d6eb24df5c43c9f1bad576cc89161ba42111c4c`.

`TASK-002` è stato attivato soltanto dopo il merge effettivo di TASK-001 ed è stato
chiuso soltanto dopo Fix, re-review `APPROVED`, CI finale e merge effettivo.
`TASK-003` è `DONE` con re-review `APPROVED` e CI finale attestata.
`TASK-004` è `DONE` con re-review `APPROVED`.
La re-review integrata del batch TASK-003/TASK-004 è `APPROVED` sullo SHA
`211ad692010d7b54b8541c45cb7f6a38e3f7d5fe`: 0 P0/P1/P2 aperti, CI tecnica
`30595351101` 3/3 `PASS`. La PR #3 ha completato la CI pull request
`30596267634` sullo SHA `ee58f29c9402f286a038f7cc79f1043539ea0b25` e il merge
normale è stato verificato su main.

`TASK-011` è `DONE`: la terza re-review sullo SHA
`a1a2818479df7b5e432f10f426e80388bc317a65` ha chiuso tutti i finding P0–P2; CI
re-review `30601320650` e CI approvazione `30601758281` sono 3/3 `PASS`, con tutti
gli step `success` e annotation 0/0/0. CI closeout `30602210469` è `PASS` sullo SHA
esatto `2d6eb24df5c43c9f1bad576cc89161ba42111c4c`, 3/3 job e annotation 0/0/0.
`TASK-012` è `DONE` dopo re-review indipendente `APPROVED`; i quattro P2 sono chiusi.
CI handoff `30606916073` e CI approvazione `30607430241` sono 3/3 `PASS`, tutti gli
step applicabili `success` e annotation 0/0/0. TASK-020 resta l'unico task corrente ed
è `BLOCKED` in `REVIEW`; TASK-005–TASK-010 e TASK-013 in avanti restano invariati. La CI
closeout `30607868864` è `BLOCKED / CI_EXTERNAL`: due tentativi, zero runner e zero
step, con billing/spending GitHub come prerequisito esterno.

## Task attivo — TASK-020

La re-review 4 sul tecnico `9dbd535` e handoff `c0ebd75` ha chiuso
T020-RR3-C-001 e T020-RR3-A-001. Cinque shard A–E hanno riportato 0 P0, 0 P1,
0 P2 e 0 P3; scanner 336 file, fixture 32/32 negative + 2/2 positive, 21/21 probe
avversari, artifact 548 + 81 = 629 e suite app/native mirate sono `PASS`. La PR #4
resta `OPEN/DRAFT`, 143 path e zero TASK-003/004. La ripresa Prelude sullo SHA
`0676826` ha sbloccato la callback warm iOS (`1/1 PASS`, exit 0). L'esito complessivo
resta `BLOCKED`: run CI `30632938353` senza runner/step per billing/spending;
redirect allow-list e live OAuth bloccati da login/MFA Supabase o token CLI da
rinnovare. Nessun `APPROVED`, `DONE` o merge è autorizzato.

Handoff:
`CODEX_REVIEW_BLOCKED`.
