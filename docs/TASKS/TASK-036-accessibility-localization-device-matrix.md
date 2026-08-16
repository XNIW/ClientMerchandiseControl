# TASK-036 — Accessibility, localizzazione e device matrix

## Informazioni generali

- **Task ID**: TASK-036
- **Titolo**: Accessibility, localizzazione e device matrix
- **File task**: `docs/TASKS/TASK-036-accessibility-localization-device-matrix.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-16
- **Ultimo aggiornamento**: 2026-08-16
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-036/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

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

Da compilare esclusivamente con modifiche e gate realmente eseguiti.

## Review — `CODEX_REVIEWER`

`NOT_RUN`.

## Chiusura

- **Conferma utente**: ricevuta e condizionata a review/gate reali
- **Merge autorizzato**: dopo review `APPROVED` e CI exact-SHA verde
- **Follow-up candidate**: TASK-037
- **Data completamento**: non ancora
