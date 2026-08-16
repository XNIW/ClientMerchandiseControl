# Evidence TASK-043

Snapshot di handoff:
`ACTIVE / REVIEW / CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION`.

## Provenance iniziale

- Client `origin/main`: `8423c868f345ee87eee7ed58ee9eb793d98412db`;
- branch: `codex/task-043-commerce-ux-refresh-20260816`;
- worktree: linked e pulito, creato da `origin/main`; checkout primario non modificato;
- Admin `origin/main`: `5cf73e4f6de4cfcc36e56514ec77c0cc9cb970e3`, sola lettura in TASK-043;
- PR Client #7: `MERGED`, merge commit `8423c868…`, CI run `31647228362` verde;
- PR aperte sui sei repository auditati: zero al preflight del 2026-08-16.

## Baseline visuale

Audit Android nativo su staging non-production con dati pubblici reali: Home, Catalogo,
Carrello vuoto/pieno, Account guest e Product Detail. Gli artifact completi sono locali,
sanitizzati e non versionati; nessun dato cliente o credenziale è stato acquisito.

## Execution verificata

- candidato tecnico: `b9c963b`; implementazione principale `1329075`;
- gate aggregato finale: `PASS`, exit 0; analyze, 571 test non-performance,
  performance 1/1, APK debug e iOS Simulator debug verdi sullo stesso working tree;
- totale 572 test `PASS`; test shell incluso 11/11 `PASS`;
- smoke Android development: shell/guest 2/2 e auth callback 1/1 `PASS`;
- visual runtime locale: 1080×2400 compact light e 1600×1200 tablet dark con rail;
  artifact sanitizzati conservati fuori Git;
- matrice automatizzata: 320×568, 360×800, 390×844, 430×932, 768×1024,
  1024×768 e 568×320; light/dark; scale 1.0/1.3/2.0; quattro locale;
- scanner client: 574 file, zero secret/config/artifact vietati; fixture negative
  32/32 e positive 2/2; boundary 7/7; governance 9/9;
- post-change staging data-backed: `BLOCKED_CONFIGURATION`, non `PASS`; il file locale
  storico manca del nuovo shop slug e usa callback non valida. Fail-closed osservato.

## Review

- revision set: `72f80ba`;
- esito: `CHANGES_REQUIRED`;
- finding: `T043-REV-NAV-001` P2 (back detail Orders) e
  `T043-REV-DATA-002` P2 (conteggio parziale presentato come totale);
- separazione reviewer/writer: logica nella stessa sessione.

## Fix verificato

- commit: `ec3cb4d`;
- `T043-REV-NAV-001`: back annidato Orders usa la capacità reale di pop e ha una
  regressione router dedicata;
- `T043-REV-DATA-002`: i conteggi non sono esposti quando `nextCursor` indica una
  pagina parziale; selettore regressione dedicato;
- `flutter analyze`: `PASS`, exit 0;
- test mirati router/shell/account/selectors: `PASS`, 25/25, exit 0.

## Re-review

- revision set: `f0e761d..e2a6475`;
- entrambi i finding P2: `CLOSED`;
- `bash scripts/check.sh`: `PASS`, exit 0; scanner 574 file, governance 9/9,
  boundary 7/7, format/analyze, 571 test non-performance, performance 1/1,
  Android debug e iOS Simulator debug;
- esito: `APPROVED`, 0 finding P0/P1/P2/P3 aperti;
- limite: separazione logica read-only nella stessa sessione, dichiarata.

CI PR, merge e main CI restano `NOT_RUN`.
