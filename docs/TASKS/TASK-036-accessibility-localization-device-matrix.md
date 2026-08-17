# TASK-036 — Accessibility, localizzazione e device matrix

## Informazioni generali

- **Task ID**: TASK-036
- **Titolo**: Accessibility, localizzazione e device matrix
- **File task**: `docs/TASKS/TASK-036-accessibility-localization-device-matrix.md`
- **Stato**: ACTIVE
- **Fase**: REVIEW
- **Responsabile**: CODEX_RE_REVIEWER
- **Data creazione**: 2026-08-16
- **Ultimo aggiornamento**: 2026-08-16
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-036/`
- **Handoff**: CODEX_FIX_COMPLETE_TO_RE_REVIEW

## Dipendenze

- **Dipende da**: TASK-012, TASK-018, TASK-021, TASK-026, TASK-028, TASK-031,
  TASK-043, TASK-044, TASK-045
- **Sblocca**: TASK-038, TASK-039, TASK-040

## Scope

- eseguire acceptance sistematica dell'app completa nelle lingue es-CL, it, en,
  zh-Hans e fallback, senza stringhe user-facing hardcoded;
- verificare pluralizzazione, date/timezone, CLP/numeri, error/empty copy, checkout,
  ordini, notifiche/deep link, tracking/mappa e privacy/legal;
- verificare semantics, heading, reading order, focus, selected state, badge/live
  region, error association, label form, target minimo, contrasto, stato non solo
  colore, reduced motion, large text, landscape, keyboard e fallback mappa;
- coprire automaticamente viewport 320x568, 360x800, 390x844, 430x932,
  768x1024, 1024x768 e compact landscape, text scale 1.0/1.3/2.0, light/dark;
- eseguire smoke Android/iOS su simulatori/emulatori/device già disponibili e
  classificare separatamente manual screen reader e physical device validation;
- correggere overflow, clipping, focus trap, semantics duplicate e CTA invisibili.

## Non incluso

- dichiarare VoiceOver/TalkBack manuale `PASS` senza averlo realmente esercitato;
- acquistare device, account, SaaS o capability esterne;
- cambiare design system o architettura per ragioni cosmetiche;
- modificare repository esterni senza regressione cross-repo riproducibile;
- confondere build, test widget, smoke simulator e test fisico.

## Criteri di accettazione

| CA | Descrizione | Tipo |
|---|---|---|
| CA-01 | Quattro locale e fallback hanno chiavi/placeholder completi e zero stringhe user-facing hardcoded | STATIC/UNIT |
| CA-02 | Plurali, date/timezone, CLP/numeri e copy commerce/tracking/privacy sono corretti | UNIT/WIDGET |
| CA-03 | Semantics, heading, order, focus, selected/badge/live region, label/error association e map fallback sono verificati | WIDGET/REVIEW |
| CA-04 | Target almeno 48x48, contrasto, stato non solo colore e reduced motion sono verificati | STATIC/WIDGET |
| CA-05 | Matrice viewport, text scale e tema completa non produce overflow/clipping/CTA irraggiungibili | WIDGET/STRESS |
| CA-06 | Landscape compact, tablet e keyboard/focus non hanno trap o ordine incoerente | WIDGET/SMOKE |
| CA-07 | Android e iOS automatici sono distinti da screen reader/manuale e physical device | SMOKE/EVIDENCE |
| CA-08 | Gate canonico, review indipendente, CI exact-SHA e zero P0/P1/P2 sono reali | CI/REVIEW |

## Test case

| Test | Criteri | Procedura attesa |
|---|---|---|
| T-01 | CA-01/02 | Parità ARB/placeholder, scan hardcoded e rendering dei flussi nei quattro locale più fallback |
| T-02 | CA-03/04 | Semantics tree, focus/order, target, contrasto e reduced motion con negative fixture |
| T-03 | CA-05 | Matrice 7 viewport x 3 scale x 2 temi sulle superfici complete e assertion overflow |
| T-04 | CA-06 | Compact landscape/tablet, traversal keyboard e reachability CTA/scroll-to-end |
| T-05 | CA-07 | Inventario device, smoke emulator/simulator e classificazione onesta VoiceOver/TalkBack/physical |
| T-06 | CA-08 | Gate aggregato, review distinta, PR/main CI exact-SHA e hygiene |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Riutilizzare design system e harness TASK-012 prima di aggiungere nuove astrazioni | Evita refactor cosmetici | ATTIVA |
| D-02 | Automatizzare la matrice con test parametrici e controllable binding | Riduce omissioni e flake | ATTIVA |
| D-03 | Manual screen reader e physical device sono gate separati e mai inferiti | Evidence onesta | ATTIVA |
| D-04 | Il mandato 2026-08-16 autorizza Planning→Execution | ADR-015 | ATTIVA |

## Planning — `CODEX_PLANNER`

### Approccio

1. inventariare locale, stringhe, formatter, semantics, focus, motion e harness device;
2. costruire matrici canoniche locale/superficie e viewport/scale/theme;
3. eseguire scan/test esistenti e classificare gap prima di modificare UI;
4. aggiungere test parametrici e negative fixture soltanto dove manca prova;
5. correggere ogni regressione riproducibile con scope minimo;
6. eseguire device discovery, smoke disponibili, gate canonico e security diff mirata;
7. consegnare a review indipendente con distinzione automated/manual/physical.

### Rischi

- matrice combinatoria eccessiva: usare superfici rappresentative complete e casi
  boundary per layout, mantenendo copertura esplicita di ogni dimensione;
- test widget che non equivalgono a screen reader: classificare separatamente;
- font/rendering platform-specific: eseguire build/smoke dual-platform disponibili;
- string scan rumoroso: allowlist solo per identificatori tecnici documentati.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: mandato 2026-08-16 e ADR-015

## Execution — `CODEX_EXECUTOR`

### Implementazione

- matrice shell parametrica estesa a 7 viewport x 3 text scale x 2 temi x 2
  target platform: 84 celle Android/iOS, più contrasto/semantics e traversal
  tastiera/attivazione su entrambe le piattaforme;
- scanner fail-closed delle stringhe user-facing integrato in `scripts/check.sh`,
  con fixture positiva e negativa multilinea;
- contratti ARB verificati su 499 chiavi per es-CL, it, en, zh-Hans e fallback
  tecnico, inclusi placeholder, plurali 0/1/2 e copy commerce/tracking/privacy;
- corretta una regressione cross-repository: checkout, ordini e tracking ordine
  formattavano date business con il fuso del device. Il client ora usa il fuso
  IANA canonico del negozio, esplicito nella UI, con conversione DST e cache
  concorrente deduplicata;
- Admin è diventato writer limitatamente al contratto canonico necessario:
  migration `storefront_time_zone_v1`, payload minimale, grant anon/authenticated,
  definer con `search_path` vuoto e timeout 2s, più 10 assertion pgTAP;
- cache ordini migrata da schema 1 a 2, invalidando fail-closed snapshot privi di
  timezone; golden delivery aggiornato dopo ispezione visiva.

### Device e accessibility

- Android Emulator API 35: cold launch, navigazione, guest Auth fail-closed,
  text scale 200%, dark/light, portrait/landscape e semantics `PASS`;
- iOS Simulator 26.2: lo stesso smoke integration reale `PASS`; smoke visivo
  aggiuntivo con dark mode e Dynamic Type accessibility-extra-extra-large, processo
  vivo, contenuto scrollabile e label complete nel semantics tree;
- physical Android: `NOT_RUN_NO_CONNECTED_DEVICE`;
- physical iOS: `NOT_RUN_DEVICE_OFFLINE` (device rilevato ma non raggiungibile);
- TalkBack/VoiceOver manuale: `NOT_RUN_PHYSICAL_MANUAL_SESSION_UNAVAILABLE`;
  automated semantics resta distinto e `PASS`.

### Gate eseguiti

| Gate | Esito | Evidence |
|---|---|---|
| Matrice automatica | PASS | 88/88: 84 celle + 2 tema/contrasto + 2 focus |
| Locale/timezone mirati | PASS | ARB 6/6, timezone contract 3/3, formatter 6/6 |
| Client canonico | PASS | `scripts/check.sh` su `a2bb8b2`, 853/853 test, coverage, repeat 70/70, analyze/build Android/iOS |
| Android device smoke | PASS | `integration_test/app_shell_smoke_test.dart`, emulator API 35 |
| iOS device smoke | PASS | stesso test, iPhone 17 Simulator iOS 26.2 |
| Admin migration reset | PASS | 139 migration applicate localmente da zero |
| Admin database | PASS | 47 file, 2532 assertion; lint `public` zero error |
| Admin canonico | PASS | `npm run verify`; foundation 982 pass, 2 skip, 0 fail con path Win7POS read-only corretto |
| Production/staging write | NOT_RUN | nessuna scrittura remota prima di review/merge |

Il primo tentativo foundation Admin ha rilevato un checkout storico Win7POS incompleto
nel path predefinito (`974 pass / 2 fail / 8 skip`). Il rerun con
`WIN7POS_REPO_PATH` puntato al checkout read-only canonico del train ha chiuso il
blocker ambientale (`982 pass / 0 fail / 2 skip`); nessun file Win7POS è stato
modificato.

### Handoff

- **Revision Client**: `a2bb8b28426e5dab45950451dfaa31ebbcf55cf8`
- **Revision Admin**: `7ca6d32f4403edd29a996cd61e789ec267e68cbd`
- **Worktree**: entrambi puliti; primary checkout preservati
- **Handoff**: `CODEX_EXECUTION_COMPLETE_TO_REVIEW`

## Review — `CODEX_REVIEWER`

### Esito

`CHANGES_REQUIRED` sul revision set Client `cfa9194` / Admin `7ca6d32`:
zero P0, zero P1, un P2, zero P3.

- `F-036-R01` (`P2`, CA-02/CA-08, T-01): checkout e ordini associavano al
  payload commerce il risultato di una seconda RPC e conservavano il timezone per
  tutta la vita del repository. Una modifica `catalog_time_zone` o un interleaving
  fra le due RPC poteva quindi produrre uno snapshot stale/non atomico.
- Gate autonomi reviewer: Client `853/853`, mirati `151/151`, analyze, Android
  Emulator e iOS Simulator verdi; Admin 47 file/2532 assertion, TASK-036 10/10,
  lint zero e grant verificati; worktree puliti.

**Handoff**: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Fix — `CODEX_FIXER`

### F-036-R01

- le RPC pubbliche fulfillment/list/detail/cancel includono ora `timeZone` nello
  stesso payload server-authoritative;
- le implementazioni precedenti sono delegate in `app_private` e non sono
  eseguibili da `anon`, `authenticated` o `service_role`; i wrapper pubblici
  conservano firma, volatility, timeout e grant minimi;
- le letture `STABLE` condividono lo snapshot della chiamata; la cancellazione
  `VOLATILE` blocca in share la riga setting durante la mutazione;
- il client elimina RPC separata, cache process-lifetime e deduplica correlata,
  validando il valore IANA bounded direttamente nel payload;
- regressioni coprono cambio America/Santiago→UTC e richieste concorrenti completate
  fuori ordine, mantenendo il timezone del rispettivo snapshot.

### Gate Fix completi

- Client technical SHA `e5a2f2b4a9000c7ad773a417c7ca01b615bcd639`;
- Admin technical SHA `c8dd7080`;
- reset locale da zero 139 migration: `PASS`;
- pgTAP specifico 13/13 e mirati timezone/checkout/order 3 file/100
  assertion: `PASS`;
- suite DB completa 47 file/2536 assertion: `PASS`;
- DB lint `public` error-level: zero result;
- Admin `npm run verify` `PASS`; foundation 982 pass, 2 skip, 0 fail;
- Client formatter/checkout/order/tracking: 150/150, `PASS`;
- Client suite completa: 755/755; `scripts/check.sh` sul technical SHA
  `PASS`, inclusi 754 test non-performance con coverage, repeat 70/70,
  performance 25k e build Android/iOS Simulator.

**Handoff**: `CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

## Chiusura

- **Conferma utente**: ricevuta e condizionata a review/gate reali
- **Merge autorizzato**: dopo review `APPROVED` e CI exact-SHA verde
- **Follow-up candidate**: TASK-037
- **Data completamento**: non ancora
