# Master Plan — ClientMerchandiseControl

## Stato globale

- **Progetto**: ClientMerchandiseControl
- **Obiettivo**: app clienti Android/iOS per il dominio pubblico Storefront di Merchandise Control
- **Stato globale**: IDLE
- **Task attivo**: nessuno
- **File task**: nessuno
- **Stato task**: nessuno
- **Fase**: REVIEW
- **Responsabile**: USER_APPROVER
- **Indicatore**: MOBILE_STOREFRONT_PRODUCT_CONTROL_COMPLETE
- **Release train**: MOBILE_STOREFRONT_PRODUCT_CONTROL
- **Stato release train**: COMPLETE
- **Review integrata**: APPROVED — P0/P1/P2 0, P3 1 accepted residual risk
- **Prossima azione autorizzata**: nessuna; public store release resta owner activation

## Repository coinvolti

- `XNIW/ClientMerchandiseControl` — repository corrente e unico writer del client.
- `XNIW/merchandise-control-admin-web` — control plane e migration/server contract
  authority canonica verificata; branch integration e PR draft coordinata.
- `XNIW/MerchandiseControlSplitView` — fonte operativa Android, sola lettura.
- `XNIW/iOSMerchandiseControl` — fonte operativa iOS, sola lettura.
- `XNIW/Win7POS` — POS e stock operativo; TASK-030 validato nel worktree release
  train, nessun writer corrente per TASK-031 e checkout originale dirty preservato.
- Supabase staging esistente — Auth e Milestone 1 TASK-005/TASK-006/TASK-010
  applicati e verificati; production non modificata.
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
6. Commerce UX e delivery tracking (`TASK-043`–`TASK-045`), variazione di prodotto
   esplicitamente autorizzata il 2026-08-16 e sequenziale rispetto al backlog storico.
7. Mobile Storefront product control (`TASK-046`–`TASK-049`), train esplicitamente
   autorizzato il 2026-08-21 con Client coordinator e activation guardata.

## Backlog completo

| ID | Titolo | Stato | Dipendenze | Repository interessati | Risultato atteso |
|---|---|---|---|---|---|
| TASK-001 | Repository governance, Flutter foundation, CI e dual-platform smoke | DONE | nessuna | Client | Fondazione compilabile, verificata e pronta a review |
| TASK-002 | Product scope definitivo, branding, UX principles e design tokens | DONE | TASK-001 | Client | Identità e principi UX approvati |
| TASK-003 | Cross-repo ownership e Storefront integration contract | DONE | TASK-001, TASK-002 | Client, Admin, Android, iOS, POS | Contratto di ownership senza ambiguità |
| TASK-004 | Environment strategy development/staging/production e configuration contract | DONE | TASK-001, TASK-003 | Client, Admin | Strategia ambienti e config verificabile |
| TASK-005 | Supabase Storefront schema, RLS, grants e migration ownership | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-003, TASK-004 | Admin, Supabase, Client | Schema pubblico protetto e ownership migration |
| TASK-006 | Storefront catalog projection e aggiornamento dal dominio operativo | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-005 | Admin, Supabase, Android, iOS, POS | Proiezione catalogo pubblica affidabile |
| TASK-007 | Admin Console: pubblicazione e gestione visibilità prodotti | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-005, TASK-006 | Admin, Supabase | Controlli di pubblicazione shop-scoped |
| TASK-008 | Admin Console: prezzi pubblici, sconti e promozioni programmate | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-005, TASK-006, TASK-007 | Admin, Supabase | Gestione commerciale pubblica |
| TASK-009 | Pipeline immagini pubbliche Storefront | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-005, TASK-007 | Admin, Supabase | Immagini pubbliche sicure e versionate |
| TASK-010 | Catalog query contract, search, pagination, fixtures e contract test | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-005, TASK-006 | Client, Admin, Supabase | Contratto query catalogo testabile |
| TASK-011 | Connessione Flutter allo staging e backend health state | DONE | TASK-004 | Client, Supabase | Connessione staging fail-closed |
| TASK-012 | App shell, design system, localizzazione, CLP e accessibility baseline | DONE | TASK-002, TASK-011 | Client | Shell prodotto e baseline accessibile |
| TASK-013 | Home e prodotti/promozioni in evidenza | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-010, TASK-011, TASK-012 | Client, Admin, Supabase | Home Storefront data-backed |
| TASK-014 | Categorie e griglia catalogo con caricamento immagini | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-010, TASK-011, TASK-012 | Client, Supabase | Browsing catalogo completo |
| TASK-015 | Ricerca, filtri e ordinamento | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-010, TASK-014 | Client, Supabase | Discovery catalogo efficiente |
| TASK-016 | Dettaglio prodotto e disponibilità commerciale | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-010, TASK-014 | Client, Supabase | Dettaglio pubblico coerente |
| TASK-017 | Cache catalogo offline, refresh e invalidazione | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-010, TASK-014 | Client | Catalogo resiliente offline |
| TASK-018 | Preferiti, condivisione e deep link prodotto | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-012, TASK-016, TASK-017 | Client | Ritorno e condivisione prodotto |
| TASK-019 | Catalog performance e acceptance su dataset esteso | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-010, TASK-014, TASK-015, TASK-017, TASK-018 | Client, Admin, Supabase | UI hardening e budget prestazioni misurato |
| TASK-020 | Supabase Auth, deep link e session lifecycle | DONE | TASK-004, TASK-011, TASK-012 | Client, Supabase | Sessioni cliente sicure |
| TASK-021 | Profilo cliente, indirizzi, privacy e cancellazione account | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-020 | Client, Supabase, Admin | Profilo privacy-safe |
| TASK-022 | Registrazione device, consenso notifiche e token lifecycle | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-020, TASK-021 | Client, Supabase | Consenso e token gestiti |
| TASK-023 | Carrello persistente e price revalidation | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-012, TASK-016, TASK-017 | Client, Supabase | Carrello coerente e rivalidato |
| TASK-024 | Proiezione disponibilità e stock pubblico | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-005, TASK-006, TASK-010 | Admin, Supabase, POS, Client | Disponibilità pubblica controllata |
| TASK-025 | Reservation hold atomico e scadenza | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-023, TASK-024 | Supabase, Admin, Client | Hold concorrente e scadibile |
| TASK-026 | Checkout con ritiro e consegna | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-021, TASK-023, TASK-025 | Client, Admin, Supabase | Fulfillment validato |
| TASK-027 | Creazione ordine idempotente e price snapshot | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-005, TASK-020, TASK-023, TASK-025, TASK-026 | Client, Admin, Supabase | Ordine atomico e idempotente |
| TASK-028 | Storico, dettaglio e stato ordine | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-027 | Client, Admin, Supabase | Tracking ordine cliente |
| TASK-029 | Admin Console: gestione e preparazione ordini | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-007, TASK-027 | Admin, Supabase | Workflow preparazione ordini |
| TASK-030 | Win7POS handoff, stock reservation release e confine vendita fiscale | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-006, TASK-024, TASK-027, TASK-029 | POS, Admin, Supabase | Handoff operativo senza fusione eventi |
| TASK-031 | Notifiche push e order status events | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-022, TASK-027, TASK-028, TASK-029 | Client, Admin, Supabase | Eventi e notifiche affidabili |
| TASK-032 | Decisione provider e integrazione pagamenti | VALIDATED_PENDING_INTEGRATED_REVIEW | TASK-027 | Client, Admin, Supabase | Pagamento selezionato e integrato |
| TASK-033 | Threat model, RLS abuse testing, rate limit e security hardening | DONE | TASK-005, TASK-020, TASK-025, TASK-027, TASK-032 | Client, Admin, Supabase | Confini attaccabili testati |
| TASK-034 | Offline/reconnect/concorrenza/idempotenza test matrix | DONE | TASK-017, TASK-023, TASK-025, TASK-027, TASK-030 | Client, Admin, Supabase, POS | Matrice resilienza superata |
| TASK-035 | Observability, crash reporting e analytics privacy-safe | DONE | TASK-011, TASK-020, TASK-027, TASK-031 | Client, Admin | Telemetria privacy-safe |
| TASK-036 | Accessibility, localizzazione e device matrix | DONE | TASK-012, TASK-018, TASK-021, TASK-026, TASK-028, TASK-031 | Client | Acceptance accessibilità e lingue |
| TASK-037 | Performance, immagini, cache e load testing | DONE | TASK-009, TASK-017, TASK-019, TASK-027 | Client, Admin, Supabase | Budget performance end-to-end |
| TASK-038 | Store assets, privacy policy, legal e release metadata | DONE | TASK-002, TASK-021, TASK-032, TASK-033, TASK-036 | Client, Admin | Materiale release conforme |
| TASK-039 | Android internal testing release | DONE | TASK-033, TASK-034, TASK-035, TASK-036, TASK-037, TASK-038 | Client | Build Android internal test |
| TASK-040 | iOS TestFlight release | DONE | TASK-033, TASK-034, TASK-035, TASK-036, TASK-037, TASK-038 | Client | Build iOS TestFlight |
| TASK-041 | Production launch, rollback e runbook | DONE | TASK-039, TASK-040 | Client, Admin, Supabase, POS | Lancio controllato e reversibile |
| TASK-042 | Post-launch monitoring, supporto e manutenzione | DONE | TASK-041 | Tutti | Operatività post-lancio |
| TASK-043 | Storefront commerce information architecture and UX refresh | DONE | TASK-033 | Client | Shell a cinque destinazioni e superfici commerce moderne, data-backed e accessibili |
| TASK-044 | Delivery tracking contract, privacy boundary and operational writer | DONE | TASK-043 | Client, Admin, Supabase | Contratto tracking owner-scoped e writer courier foreground reale |
| TASK-045 | Client live map, integrated acceptance and closeout | DONE | TASK-044 | Client, Admin, Supabase | Mappa fail-closed, acceptance integrata e closeout del train |
| TASK-046 | Mobile Storefront authoring contract and UX | DONE | TASK-005–TASK-010 | Client, Admin, Android, iOS | Contratto unico, UX editor e piano cross-repo bounded |
| TASK-047 | Android/iOS Storefront authoring integration | DONE | TASK-046 | Android, iOS, Admin | Editor unificati e parita mobile |
| TASK-048 | Cross-surface staging E2E and release candidate | DONE | TASK-047 | Client, Admin, Android, iOS | E2E-01…14 e candidate verificati |
| TASK-049 | Testing channels and production activation closeout | DONE | TASK-048 | Client, Admin, Android, iOS | Internal/TestFlight, preflight guardato e stato terminale |

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
- `TASK-020` — Re-review 6 `APPROVED`, 0 P0/P1/P2/P3, CI finale
  `30713857455` 3/3 `PASS`; PR #4 merged normalmente con commit
  `b2d70b5c32d9481749f985bb4179c00a02d9f822`.

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
step applicabili `success` e annotation 0/0/0. La precedente attestazione di TASK-020
bloccato è storia superata: TASK-020 è `DONE` e PR #4 è merged. Il release train
`STOREFRONT_V1` ha completato i checkpoint Milestone 1 e Milestone 2 con
TASK-005/TASK-006/TASK-007/TASK-008/TASK-009/TASK-010 in
`VALIDATED_PENDING_INTEGRATED_REVIEW`; TASK-013 ha completato Home reale, fixture,
CI e smoke Android/iOS ed è anch'esso `VALIDATED_PENDING_INTEGRATED_REVIEW`.
TASK-014 ha completato categorie, keyset grid, immagini, CI e smoke Android/iOS ed è
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-015 ha completato ricerca, filtri, sort,
CI e smoke Android/iOS ed è `VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-016 ha
completato dettaglio pubblico, CI e smoke Android/iOS ed è
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-017 ha completato cache Drift, SWR,
invalidazione, benchmark e smoke offline/reconnect Android/iOS ed è
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-018 e TASK-019 hanno completato share,
UI hardening, dataset esteso e budget performance e sono anch'essi
`VALIDATED_PENDING_INTEGRATED_REVIEW`; Milestone 3 è `PASS`. TASK-021 ha completato
profilo/indirizzi/privacy owner-scoped ed è `VALIDATED_PENDING_INTEGRATED_REVIEW`;
TASK-022 ha completato registro device, consenso/token lifecycle, revoke/logout e
staging ed è `VALIDATED_PENDING_INTEGRATED_REVIEW`; TASK-023 ha completato cart guest/
account, merge idempotente e revalidation ed è anch'esso
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-024 ha completato i sei stati commerciali,
freshness/ingest, Admin preview e cache/cart Client ed è
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-025 ha completato hold atomici,
idempotency, expiry/cleanup, race ultimo pezzo e integrazione Client ed è
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-026 ha completato fulfillment, quote
server-authoritative, UI checkout e staging ed è anch'esso
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-027 ha completato order aggregate,
snapshot/event/outbox atomici, replay, Client receipt e staging ed è anch'esso
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-028 ha completato list/detail/timeline,
cancel idempotente, cache offline, deep link, Client UI e staging ed è anch'esso
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-029 ha completato queue/detail, state
machine e transition Admin ed è `VALIDATED_PENDING_INTEGRATED_REVIEW`; TASK-030 ha
completato claim/lease/ack, inbox durevole Win7POS, replay/offline e confine fiscale ed
è `VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-031 ha completato event/delivery/receipt,
dispatcher idempotente, payload privacy-safe e route notifiche Android/iOS ed è
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-032 ha completato payment offline,
provider/webhook dormant e il checkpoint Milestone 4 629/629 ed è
`VALIDATED_PENDING_INTEGRATED_REVIEW`. TASK-033 è `DONE / REVIEW /
USER_APPROVED_DONE` dopo remediation 18/18, re-review `APPROVED` e CI pubblica
`31646041242` 3/3 `SUCCESS`; i task successivi restano `TODO` e nessuno è attivo. La
dipendenza TASK-010 è
stata riallineata all'ordine esplicitamente autorizzato del Milestone 1: pubblicazione,
promozioni e immagini Admin restano consumer successivi del contratto, non prerequisiti
circolari della sua definizione.

## Ultimo task completato — TASK-020

La Re-review 6 sullo SHA `671494f` ha chiuso tutti i blocker esterni: redirect
allow-list staging aggiunta e persistente (`16 -> 17`) con provider Google attivo,
Site URL/redirect precedenti/production invariati; OAuth Google reale Android/iOS,
restore, logout e nuovo login `PASS`; callback iOS warm e cold `PASS`; log live senza
token/code. La CI run `30709395137` è 3/3 `PASS`, tutti gli step applicabili
`success`, annotation 0/0/0. Finding aperti: 0 P0/P1/P2/P3. PR #4 è
è stata resa non draft; la CI closeout `30713857455` sullo SHA `3aaef8c` è 3/3
`PASS` con annotation 0/0/0. PR #4 è `MERGED` con merge commit `b2d70b5`; branch
remoto eliminato, main locale/remoto allineate e worktree pulito. TASK-020 è `DONE`.

## Ultimo checkpoint interno — TASK-013

Il revision set Client `2aefa17f901652bf2f1fceafb2649422c6b8fb4f` ha superato
240 test con coverage 81,17%, gate security/governance/architecture, build Android/iOS,
smoke Home reale Android/iOS e CI `30732213362` 3/3 `PASS`. La fixture staging Admin
è attestata dalla run `30731760038` sullo SHA `a9036f0b`; production è invariata.
TASK-013 non è `DONE`: attende la review integrata finale.

## Ultimo checkpoint interno — TASK-014

Il revision set Client `61d8781c58b0c4acb41a80c1eab1f32412c037a8` ha superato
254 test con coverage 82,42%, gate security/governance/architecture, build Android/iOS,
smoke Catalogo reale Android/iOS e CI `30733287396` 3/3 `PASS`. Production è
invariata. TASK-014 non è `DONE`: attende la review integrata finale.

## Ultimo checkpoint interno — TASK-015

Il revision set Client `6739bf663cca2dcad4dcd2ef11ee2415b238daeb` ha superato
266 test con coverage 83,18%, gate security/governance/architecture, build Android/iOS,
smoke Search/filtri/sort reali Android/iOS e CI `30734363845` 3/3 `PASS`.
Production è invariata. TASK-015 non è `DONE`: attende la review integrata finale.

Handoff:
## Ultimo checkpoint interno — TASK-016

Il revision set Client `242e631805b569a49a0217c4129b1586e8ad1dbf` ha superato
282 test con coverage 82,51%, gate security/governance/architecture, build Android/iOS,
smoke Product Detail published/unpublished reale Android/iOS e CI `30735374419` 3/3
`PASS`. Il primo tentativo Android ha correttamente registrato `FAIL` per un tap harness
fuori viewport; la regressione è stata corretta e il candidato finale è verde.
Production è invariata. TASK-016 non è `DONE`: attende la review integrata finale.

Handoff:
`CODEX_PLANNING_APPROVED_TO_EXECUTION` per TASK-017.

## Ultimo checkpoint interno — TASK-017

Il revision set Client `e5f4bd8d14da08e9e8f43284944d8257c0b02693` ha superato
303 test con coverage 81,57%, gate security/governance/architecture, build Android/iOS,
benchmark 25.000 righe, smoke cache offline/reconnect Android/iOS e CI `30737515662`
3/3 `PASS`. I tentativi harness falliti per viewport/route restano registrati e sono
stati corretti con regressioni. Production è invariata. TASK-017 non è `DONE`: attende
la review integrata finale.

Handoff:
`CODEX_PLANNING_APPROVED_TO_EXECUTION` per TASK-018.

## Ultimo checkpoint interno — TASK-018

Il revision set Client `a0e139a6365dc4639ba66c110c91dcc2720feee5` ha superato
329 test con coverage 81,73%, gate security/governance/architecture, build Android/iOS,
chooser Android reale e XCTest iOS con vera `UIActivityViewController` 3/3. La CI
`30751191932` è 3/3 `PASS`, tutti gli step applicabili `success`, annotation 0/0/0.
La decisione USER_APPROVER D-08 sostituisce il controllo manuale del foglio con il gate
nativo riproducibile; production è invariata. TASK-018 non è `DONE`: attende la review
integrata finale.

Handoff:
`CODEX_PLANNING_APPROVED_TO_EXECUTION` per TASK-019, iniziando dal work package
`STOREFRONT-V1-UI-HARDENING` autorizzato.

## Ultimo checkpoint interno — TASK-019 / Milestone 3

Il revision set Client `8f6c67dd3372ee9a6421f7071e58f4c0808f11b1` ha superato
344 test, coverage 82,74%, gate security/governance/architecture, build Android/iOS,
smoke live e CI `30759482376` 3/3 `PASS`. Il revision set Admin/Supabase
`1f1ba507bbdde96197276738aacd7e290c20f8fe` ha superato CI `30757513891`, build
Cloudflare `30757513885`, Playwright e staging performance `30757512517` attempt 3.
Il dataset sintetico ha 22.000 prodotti, 100 categorie e 69.200 righe equivalenti;
p95 catalog/search/detail 30,114/599,739/4,923 ms, cleanup 0. First usable Flutter è
139 ms; i cold process emulator 5x restano una baseline separata p95 4.565 ms per
TASK-037. Production è invariata. TASK-019 non è `DONE`: attende la review integrata.

Handoff:
`CODEX_PLANNING_APPROVED_TO_EXECUTION` per TASK-021, con writer Admin/Supabase e poi
Client.

## Ultimo checkpoint interno — TASK-021

Il revision set Admin/Supabase `27770dbe76da3066cdddb5a821b01c144a9ae607`
ha applicato in staging la migration `20260802181823`: tre tabelle FORCE RLS, nove
policy, cinque RPC, pgTAP TASK-021 64/64 e suite 26 file/1.582 test `PASS`; CI
`30761579498`, Cloudflare `30761579496`, staging `30761578366` e regressione
`30761578384` sono `PASS`. Il revision set Client
`4f25b539248c642351e50667a53d6fcb95840c41` ha superato 371 test, coverage 80,91%,
build Android/iOS e integration flow Account Android/iOS. La CI Client
`30763287350` resta `BLOCKED` esterna per billing GitHub: i tre job non hanno runner o
step; non è dichiarata `PASS`. Production è invariata. TASK-021 non è `DONE`: attende
la review integrata finale.

Handoff:
`CODEX_PLANNING_APPROVED_TO_EXECUTION` per TASK-022, con writer Admin/Supabase e poi
Client.

## Ultimo checkpoint interno — TASK-022

Il revision set Admin/Supabase `c8f4048f5f442726bec1693e808e19fe6dd40fc4`
ha applicato in staging la migration `20260802194500`: `customer_devices` FORCE RLS,
RPC register/revoke/status, dedup token/installazione, pgTAP 58/58 e suite 27 file/
1.640 test `PASS`; CI `30764931962`, Cloudflare `30764931964` e staging
`30764930029` sono `PASS`. Il revision set Client
`b113f44a1c7b150e9b07e770aa8a7c158a2b8111` ha superato 403 test, coverage 80,61%,
build Android/iOS, integration lifecycle device Android/iOS e smoke degli artifact
normali. La CI Client `30766494620` resta `BLOCKED` esterna per billing GitHub: i tre
job non hanno runner o step; non è dichiarata `PASS`. Il provider push live resta
onestamente non configurato fino a TASK-031; production è invariata. TASK-022 non è
`DONE`: attende la review integrata finale.

Handoff:
`CODEX_PLANNING_APPROVED_TO_EXECUTION` per TASK-023, con writer Admin/Supabase e poi
Client.

## Ultimo checkpoint interno — TASK-023

Il revision set Admin/Supabase `80556a90bba87712e4f42530b9e500b9d2d485ef`
ha applicato in staging le migration `20260802210000` e `20260802213000`: tre tabelle
FORCE RLS, quattro RPC pubbliche slug-based, motore UUID privato, pgTAP 98/98 e suite
28 file/1.738 test `PASS`; CI `30768157319`, Cloudflare `30768157310` e staging
`30768155279` sono `PASS`. Il revision set Client
`e8d71d38ea87ab61693ecec80614c11d676e47f5` ha superato 429 test, coverage 79,55%,
build Android debug/release e iOS debug/release compile, integration cart Android/iOS
e smoke artifact headless. La CI Client `30770239675` resta `BLOCKED` esterna per
billing GitHub: i tre job non hanno runner o step; non è dichiarata `PASS`.
Production è invariata. TASK-023 non è `DONE`: attende la review integrata finale.

Handoff:
`CODEX_PLANNING_APPROVED_TO_EXECUTION` per TASK-024, con writer Admin/Supabase e poi
Client.

## Ultimo checkpoint interno — TASK-024

Il revision set Admin/Supabase `9d457ee4b278864a25e4f612bbfdea138e3df6d6`
ha applicato in staging la migration `20260802220000`: segnale availability privato,
freshness bounded, ingest monotono/idempotente e sei stati pubblici fail-closed; pgTAP
TASK-024 243/243 e suite 1.782/1.782 `PASS`; CI `30772550353`, Cloudflare
`30772550354` e staging `30772549228` sono `PASS`. Il revision set Client
`b34211f0b294703e3124b42f1b008ea32c454ffd` ha superato 433 test, coverage 79,91%,
cache benchmark 25.000 righe, build Android/iOS, integration cart/cache Android/iOS e
smoke artifact headless. La cache Drift v4 aggiorna availability/prezzo del guest cart
senza perdere quantità o favorite. La CI Client `30773126667` resta `BLOCKED` esterna
per billing GitHub: tre job senza runner o step, non dichiarati `PASS`. Production è
invariata. TASK-024 non è `DONE`: attende la review integrata finale.

Handoff:
`CODEX_PLANNING_APPROVED_TO_EXECUTION` per TASK-025, con writer Admin/Supabase e poi
Client.

## Ultimo checkpoint interno — TASK-025

Il revision set Admin/Supabase `448a778cc57ed1a441b87a71bb93be4315374d08`
ha applicato in staging le migration `20260803000951` e `20260803003855`: hold e
ledger privati FORCE RLS, tre RPC strict, TTL/limiti server-side, cleanup cron bounded
e eligibility shop/publication. pgTAP TASK-025 54/54, race reale ultimo pezzo e load
1.200 hold sono `PASS`; CI `30776746985`, Cloudflare `30776746979` e staging
`30776745250` sono `PASS`. Il revision set Client
`fe85ce910313843c00c83760b67563f7ea6ef2e7` ha superato 461 test, coverage 79,03%,
build Android/iOS, integration reservation Android/iOS 2/2 e smoke artifact headless.
La CI Client `30776491402` resta `BLOCKED` esterna per billing GitHub: tre job senza
runner o step, non dichiarati `PASS`. Production è invariata. TASK-025 non è `DONE`:
attende la review integrata finale.

Handoff:
`CODEX_PLANNING_APPROVED_TO_EXECUTION` per TASK-026, con writer Admin/Supabase e poi
Client.

## Ultimo checkpoint interno — TASK-026

Il revision set Admin/Supabase `86088dc739c59725735533c64133678e96641a9a`
ha applicato in staging le migration `20260803020000` e `20260803021500`:
configurazione fulfillment, point/zone/slot/fee, quote/ledger privati FORCE RLS,
quattro RPC customer e due RPC Admin strict. pgTAP TASK-026 56/56, suite database
31 file/1.892 test e race ultimo slot sono `PASS`; CI `30779607356`, Cloudflare
`30779607377` e staging `30779605562` sono `PASS`. Il revision set Client
`9406df7d5b5d5a69a0edc033359be38f3bdf656f` ha superato 489 test, coverage 77,10%,
build Android/iOS, integration checkout Android/iOS 1/1, live adapter staging e smoke
artifact headless. La CI Client `30781669519` resta `BLOCKED` esterna per billing:
tre job senza runner o step, non dichiarati `PASS`. Production è invariata. TASK-026
non è `DONE`: attende la review integrata finale.

Handoff:
`CODEX_PLANNING_APPROVED_TO_EXECUTION` per TASK-027, con writer Admin/Supabase e poi
Client.

## Ultimo checkpoint interno — TASK-027

Il revision set Admin/Supabase `599511c03cb502b9b76561ff320cfdbb4073b1ee`
ha applicato in staging le migration `20260803033000` e `20260803034500`: cinque
tabelle customer-order FORCE RLS, create/read RPC strict, snapshot/event/outbox
immutabili e aggregate atomico distinto da `pos_sales`. pgTAP TASK-027 35/35 e race
duplicate/replay sono `PASS`; CI `30783886282`, Cloudflare `30783886269` e staging
`30783882947` attempt 2 sono `PASS`. Il revision set Client
`64c8f711547f8d5c5dc18650a03a9d5345bb71b7` ha superato 497 test, coverage 76,39%,
benchmark 1/1, build Android/iOS, integration ordine Android/iOS 1/1 e smoke artifact
headless. La CI Client `30784085502` resta `BLOCKED` esterna per billing: tre job
senza runner o step, non dichiarati `PASS`. Production è invariata. TASK-027 non è
`DONE`: attende la review integrata finale.

Handoff:
`CODEX_PLANNING_APPROVED_TO_EXECUTION` per TASK-028, con writer Admin/Supabase e poi
Client.

## Ultimo checkpoint interno — TASK-028

Il revision set Admin/Supabase `119169375fa477995b41c34b3766deca32fec056`
ha applicato in staging la migration `20260803050000`: list/detail/timeline RPC strict,
keyset stabile e cancel server-authoritative/idempotente con event/outbox/ledger e
rilascio ATP/capacità atomici. pgTAP TASK-028 30/30 e race cancel due sessioni sono
`PASS`; CI `30787892745`, Cloudflare `30787892757` e staging `30787890770` sono
`PASS`. Il revision set Client `1855100f34a3563787b1ac71eafb4af60a1b72e6` ha
superato 526 test funzionali, benchmark 1/1, coverage 77,31%, build Android/iOS,
integration history Android/iOS 1/1 e smoke artifact headless. La CI Client
`30787721420` resta `BLOCKED` esterna per billing GitHub: tre job senza runner o step,
non dichiarati `PASS`. Production è invariata e cancellation resta fail-closed/OFF.
TASK-028 non è `DONE`: attende la review integrata finale.

Handoff:
`CODEX_PLANNING_APPROVED_TO_EXECUTION` per TASK-029, con writer Admin/Supabase.

## Ultimo checkpoint interno — TASK-029

Il revision set Admin/Supabase `23bfab60b91ef192dbb726bde454287cea144c8f`
ha applicato in staging la migration `20260803053000`: permessi orders, queue/detail
strict, state machine, ledger FORCE RLS e transition idempotente/versionata con event,
audit e outbox atomici. pgTAP 34/34, race due operatori, foundation 856 pass + 2 skip,
CI `30798108711`, build Cloudflare `30798108767`, deploy `30796888108` e acceptance
`30798109969` sono `PASS`. Queue/transizione staging 1/1, predecessor publish 1/1,
fixture persistente e cleanup sono verdi; nessuna riga `pos_sales` è stata creata.
Production è invariata. TASK-029 non è `DONE`: attende la review integrata finale.

Handoff:
`CODEX_PLANNING_APPROVED_TO_EXECUTION` per TASK-030, con writer Admin/Supabase e poi
Win7POS.

## Ultimo checkpoint interno — TASK-030

Il revision set Admin/Supabase `64ef3170f5830e044ac130b127c94149d25ee1fc`
ha applicato in staging la migration `20260803060000`: receipt privato `FORCE RLS`,
claim bounded con lease e ack versionato/idempotente service-only. pgTAP 40/40, race
due consumer, CI `30805402075`, Cloudflare `30805402072`, deploy `30804781883` ed E2E
`30805397611` sono `PASS`. Il revision set Win7POS
`6c2eb9c8a0b6666f5dd59a2a132e616f5a8d5474` aggiunge inbox SQLite durevole,
consumer supervisionato e confine fiscale; CI Windows `30804008501` è 878/878 e
Security/SBOM/CodeQL `30804007997` è `PASS`. Lo staging ha completato l'ordine a
versione 5 con tre receipt e zero vendita/riferimento fiscale, poi cleanup a zero.
Windows 7 fisico resta `BLOCKED` esterno; production e consumer flag restano OFF.
TASK-030 non è `DONE`: attende la review integrata finale.

Handoff:
`CODEX_PLANNING_APPROVED_TO_EXECUTION` per TASK-031, con writer Admin/Supabase e poi
Client.

## Ultimo checkpoint interno — TASK-031

Il revision set Admin/Supabase `e9bcbc8c98a7dc1d0fdcfdbd549d7968a2fdbb19`
ha applicato in staging la migration `20260803104431`: tre ledger privati `FORCE RLS`,
claim/ack service-only, recipient generation fence, retry/replay e route owner-scoped.
pgTAP TASK-031 40/40, dispatcher 7/7, CI `30811750153`, Cloudflare
`30811750080` e staging `30811747216` sono `PASS`; l'artifact E2E prova payload
localizzato/opaco, due messaggi recording, una delivery terminale, flag/revoke/rotation
fail-closed, cleanup zero e nessuna credential provider. Il revision set Client
`ed2f8a5c95f70ce057860027408d9f61314d6f4e` ha superato 538 test, coverage
77,45%, build Android/iOS, 19/19 test mirati, Android JVM 1/1, XCTest 4/4 e smoke
notification route headless Android/iOS. La CI Client `30811578997` resta `BLOCKED`
esterna per billing, con tre job senza runner/step. Il delivery APNs/FCM reale resta
`BLOCKED` esterno per assenza di credential; production e push flag sono invariati/OFF.
TASK-031 non è `DONE`: attende la review integrata finale.

Handoff:
`CODEX_PLANNING_APPROVED_TO_EXECUTION` per TASK-032, con writer Admin/Supabase e poi
Client; online payment resta fail-closed/OFF salvo credential sandbox già esistenti.

## Ultimo checkpoint interno — TASK-032 / Milestone 4

Il revision set Admin/Supabase
`e0406834af09173902e2f64948dd5834f4a9fac5` include la migration additiva finale
`20260803143000`, il workflow staging serializzato e fixture isolate. La run aggregata
`30822286720` ha superato 13 suite/629 assertion su 629, incluse 40 assertion sullo
stesso ordine da publish a complete con Admin, POS, notification, history e payment;
post-verifica migration/RLS/flag/rollback/production è interamente verde. CI Admin
`30822290788`, Cloudflare `30822292394` e i run specifici TASK-027 `30822288899`,
TASK-028 `30822288363`, TASK-029 `30822288362` attempt 2 sono `PASS` sullo SHA esatto.
Client runtime resta `72f98eea574300f77d42e96e09557f0dd55ac2d5` con i gate TASK-032
già verdi; Win7POS resta `6c2eb9c8a0b6666f5dd59a2a132e616f5a8d5474`. Production è
invariata e i flag Storefront/orders/POS/push/online-payment restano OFF. TASK-032 non
è `DONE`: attende la review integrata finale.

Handoff:
`CODEX_PLANNING_APPROVED_TO_EXECUTION` per TASK-033, iniziando dalla Deep Security
Scan read-only multi-repository e proseguendo con hardening mirato dei soli finding
tecnici confermati.

## Blocco TASK-033 — nuova Deep Security Scan non avviata

Il 2026-08-08 il Client è stato isolato in un worktree detached pulito allo SHA
`ec74166ea20786b8deaa9965cac103984c927820`; lo SHA Admin/Supabase
`e0406834af09173902e2f64948dd5834f4a9fac5` è stato verificato senza modifiche. Il
preflight fresco `deep_security_scan` ha restituito `ready` con exit code 0. La singola
chiamata successiva a `start_codex_security_deep_scan`, tuttavia, non ha avviato né
riagganciato discovery perché il parent non espone un managed filesystem permission
profile al worker read-only. Nessun `scanId`, discovery manifest o nuovo
failure-manifest è stato prodotto; validation, attack-path, completion, report e review
integrata non sono stati eseguiti. Il precedente manifest fallito per usage limit resta
soltanto evidenza storica e non è stato riutilizzato.

Handoff:
`BLOCKED_SECURITY_SCAN_TOOL_PERMISSION_PROFILE`.

## Ultimo task completato — TASK-033

Il report canonico `da548633-6547-4157-a55f-8e8ab1b11f0d` sul candidato `0668ea7a`
ha prodotto 18 finding, tutti `FIXED_VALIDATED` sul runtime `ee0fcf7`: 0 P0, 0 P1,
0 P2, 0 P3 aperti, deferred 0 e finding nuovi 0. La validazione indipendente ha
confermato 20 file / 200 test mirati, test nativi Android/iOS e i sink corretti.

Il repository è stato reso `PUBLIC` con autorizzazione esplicita dopo un controllo
pre-public full-history privo di secret reali. Il rerun `31623828999` attempt 2 ha
avviato runner reali e isolato una differenza di rasterizzazione golden Linux; il fix
pixel-exact, senza tolleranze o rimozione di job, è validato dal gate locale completo
e dalla CI `31646041242`, con `Quality`, Android e iOS `SUCCESS`. Production non è
stata acceduta, Google OAuth resta fail-closed `OFF` e TASK-034 resta `TODO`.

Handoff:
`USER_APPROVED_DONE`.

## Ultimo task completato — TASK-044

Il Client è stato integrato dalla PR #9 con head
`0e84801e3e362d489b00d43f6074b804de8fe713` e merge commit
`fd044d4b9b7a7bd4c4d3ccf71b977a01bc39563f`; PR CI `31939920494` e main CI
`31940810780` hanno concluso Quality, Android e iOS 3/3 `SUCCESS`, annotation 0/0/0.
L'authority Admin/Supabase è stata integrata dalla PR #89 con head
`0ce56bf5bd3c6914b89b4defc90c8f74f26cdc16` e merge commit
`2e8ec07e1609b7bfa7b1a5210f232fc60bbf5412`; PR CI `31940278489` e Cloudflare
`31940278463`, oltre alle main CI `31940653715` e `31940653742`, sono `SUCCESS`.
Il primo pgTAP PR run `31939911807` aveva rilevato una regressione reale nel lockout
staff e aspettative obsolete 43/45; il fix è stato re-reviewato `APPROVED` e ha portato
la suite completa a 2.522/2.522. Branch remoti e worktree TASK-044 sono eliminati.

Handoff:
`CODEX_PLANNING_APPROVED_TO_EXECUTION` per TASK-045.

## Ultimo task completato — TASK-045

La PR Client #10 ha superato la CI exact-SHA `31950880035` sul commit
`3cab680b4ca42e4cd65e71302b335ac7975256a5` con Quality, Android e iOS 3/3
`SUCCESS`, tutti gli step applicabili verdi e annotation 0/0/0. Il merge normale
`c013539bec35c938f376be70567492ac3304844a` è contenuto in `main`; la CI post-merge
`31951215868` ha nuovamente concluso 3/3 `SUCCESS`, annotation 0/0/0.

Il release train `CLIENT_STOREFRONT_UX_AND_DELIVERY_TRACKING` è `COMPLETE`: TASK-043,
TASK-044 e TASK-045 sono `DONE`, review integrata `APPROVED`, finding P0/P1/P2/P3
aperti zero. Production, billing, store publishing e chiavi Maps non sono stati
attivati. Il progetto torna `IDLE`; TASK-034 resta il prossimo task `TODO`, non attivo.

Handoff:
`USER_APPROVED_DONE`.
