# Fix evidence — TASK-012

## Revisione verificata

- Baseline review:
  `8e57ad9195fafe11892c9413328963fda24634d9`
- Commit tecnico FIX:
  `3acbc42d9abd5bffe0230d3b9bca27baf345cfea`
- Finding autorizzati: `T012-REV-UI-001`, `T012-REV-SEC-001`,
  `T012-REV-SEC-002`, `T012-REV-GOV-003`
- Scope aggiuntivo: nessuno

## Correzioni

| Finding | Esito del Fix | Correzione | Regressione |
|---|---|---|---|
| `T012-REV-UI-001` | PASS | Ricerca Catalogo resa container Semantics autonomo; spiegazione esplicita e sibling rispetto a Filter/Sort. | `catalog_screen_test.dart` verifica label/hint, flag text field disabilitato, spiegazione separata e assenza dei sibling tra i discendenti. Dump Android nativo verifica quattro bounds distinti. |
| `T012-REV-SEC-001` | PASS | `AccountView.guest` e `AccountView.authenticated` sono API separate; la seconda richiede `VoidCallback onLogout` non-null per tipo e lo conserva non-null internamente. | Widget test invoca il logout; nessun costruttore authenticated generico/assert-dependent resta disponibile. |
| `T012-REV-SEC-002` | PASS | Avatar limitato a copia locale `Uint8List` da 1 a 512 KiB, renderizzata con `Image.memory`, decode 192×192 e fallback su bytes corrotti. | Test per bytes validi/corrotti/oversize, copia difensiva e `HttpOverrides` con zero client HTTP creati; scan Account senza `NetworkImage`, `ImageProvider`, URI o sink HTTP. |
| `T012-REV-GOV-003` | PASS | `execution-evidence.md` contiene 39 righe CA e 34 righe T singole, con esito ed evidence puntuale; i due `NOT_RUN` per review/CI hanno motivazione. | `task012_evidence_matrix_test.dart` verifica numero, presenza, unicità e vocabolario degli esiti. |

La chiusura dei finding è un claim del Fixer e resta soggetta a re-review
indipendente.

## Gate sul commit tecnico

| Verifica | Esito | Evidenza |
|---|---|---|
| format | PASS | 61 file, 0 modificati, exit 0 |
| analyze | PASS | zero issue, exit 0 |
| suite completa | PASS | 141/141, exit 0 |
| governance evidence | PASS | 39/39 CA e 34/34 T univoci, exit 0 |
| `scripts/check.sh` | PASS | governance, 5/5 fixture negative, analyze, 141/141 e build dual-platform, exit 0 |
| build Android debug | PASS | APK generato, exit 0 |
| build iOS Simulator debug | PASS | Runner.app generata, exit 0 |
| smoke Android | PASS | `app_guest_flow_test.dart`, 1/1, exit 0 |
| smoke iOS | PASS | `app_guest_flow_test.dart`, 1/1, exit 0 |
| `git diff --check` | PASS | exit 0 |

Tutti i comandi sono terminati; nessun processo di verifica resta attivo.

## Verifica Semantics Android

La normal app development offline del commit tecnico è stata installata su Android
15/API 35. Il dump UIAutomator dopo l'apertura del Catalogo mostra:

- ricerca `EditText` disabilitata: bounds `[105,347][975,473]`;
- Filter: bounds `[105,515][364,641]`;
- Sort: bounds `[395,515][639,641]`;
- spiegazione accessibile separata: bounds `[105,672][975,714]`.

Filter, Sort e spiegazione sono sibling della ricerca e non suoi discendenti. Il formato
XML di UIAutomator non serializza `AccessibilityNodeInfo.hintText`: il Semantics test
verifica label/hint esatti e il bridge Android della toolchain Flutter 3.44.8 inoltra
label e hint del text field tramite `setHintText`.

## Security e confinement

- runtime TASK-012 ancora guest e Google fail-closed;
- zero OAuth, sessione, token, storage o callback introdotti;
- zero query/RPC/Storage/Functions o dati commerciali;
- zero dipendenze e target nativi modificati;
- zero scritture Supabase o repository esterni;
- zero secret/config locale nelle modifiche o evidence;
- build, coverage, dump e log locali non sono candidati a Git.

## Handoff

- Transizione: `FIX -> REVIEW`
- Prossimo ruolo: `CODEX_RE_REVIEWER`
- Target: commit tecnico FIX più commit evidence/handoff
- Review outcome: resta `CHANGES_REQUIRED` fino alla re-review indipendente
- Indicatore: `CODEX_FIX_COMPLETE_TO_RE_REVIEW`
