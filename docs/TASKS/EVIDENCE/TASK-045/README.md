# Evidence TASK-045

Snapshot di handoff:
`ACTIVE / REVIEW / CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION`.

## Provenance

- Client base: `fd044d4b9b7a7bd4c4d3ccf71b977a01bc39563f`;
- branch: `codex/task-045-client-live-map-20260816`;
- worktree: linked e pulito da `origin/main`; checkout primario preservato;
- Admin/Supabase authority: main `2e8ec07e1609b7bfa7b1a5210f232fc60bbf5412`,
  contratto TASK-044 già integrato e verificato;
- production, billing e provider key: non acceduti, activation `OFF`.

## Planning

- ADR-014 governa provider, adapter, fake, chiavi native separate e fail-closed;
- UI e test riusano Material 3, token, localizzazioni e contratti reali esistenti;
- nessun ETA, route, marker o movimento viene inventato dal Client.

## Execution

### Revisioni

- implementazione: `9d8d0ebc86c03f194276ed5c3d26214a4e7df7bb`;
- review iniziale: `CHANGES_REQUIRED`, tre finding P2 distinti;
- fix ciclo 1: `f188a3230e4608a27c031d4b2e58e690a53eb8c6`;
- fix ciclo 2: `3c8564b62e255136bf9579df82d91bf678bad6f8`;
- candidato secondo ciclo: `f403a92657885b3895874e48a2505931c4c83b0d`;
- fix ciclo 3 e candidato finale:
  `5e0f1c66594ca3748d7d66a4df04249eea382420`;
- re-review finale: `APPROVED` sul delta esatto `f403a92..5e0f1c6`, con due
  verifiche indipendenti e zero finding P0/P1/P2/P3 aperti.

### Matrice CA

| CA | Evidence corrente | Esito |
|---|---|---|
| CA-01/02/03 | eligibility pura, widget detail, stale e terminal redaction | PASS |
| CA-04/05/06 | tre marker, fallback testuale, cache/stale, mode non-live | PASS |
| CA-07 | CTA Home/Orders senza coordinate, semantics aggregate | PASS |
| CA-08/09 | handshake nativo, sentinel, runtime failure/timeout, scan no key raw | PASS |
| CA-10 | 48 dp, screen-reader labels, reduced motion, matrix viewport/theme/scale | PASS |
| CA-11 | marker subtree, commit monotono, route/account dispose, polling fallback | PASS |
| CA-12 | es-CL/it/en/zh-Hans via gen_l10n e formati esistenti | PASS |
| CA-13 | integration Android contract → live → stale → terminal redaction | PASS |
| CA-14 | re-review approvata; gate canonici finali, CI PR/main e merge | NOT_RUN |

### Comandi già eseguiti sul fix

| Comando | Risultato |
|---|---|
| `flutter analyze` mirato ai file tracking/Home/Orders e test | PASS, exit 0 |
| test adapter/native/live/controller/Orders/Home | PASS, 47 test, exit 0 |
| test Home data + Orders | PASS, 19 test, exit 0 |
| `flutter test integration_test/customer_delivery_tracking_flow_test.dart` | PASS Android, 1/1, exit 0 |
| `flutter build apk --debug` | PASS, exit 0 |
| `flutter build ios --simulator --debug` | PASS, exit 0; warning SPM plugin noto |
| `git diff --check` | PASS, exit 0 |

Il primo `scripts/check.sh` sul commit di evidence `d2113a3` ha correttamente fallito
al gate governance prima dei test: il root `README.md` riportava ancora fase/indicatore
di Execution. Il metadata viene riallineato nel candidato corrente e il gate completo
deve essere rieseguito; quel tentativo resta `FAIL`, non `PASS`.

Due invocazioni di test ad hoc sono fallite prima di eseguire prodotto: la prima
mescolava unit e integration test nello stesso comando; la seconda indicava un path
Home inesistente. Entrambe sono state corrette con invocazioni separate/canoniche e
non vengono riclassificate come PASS.

### Privacy/security

- nessuna chiave, service role, UUID operativo o dato production è stato aggiunto;
- il method channel restituisce soltanto un booleano di readiness;
- coordinate presenti esclusivamente in fixture sintetiche e nel subtree runtime;
- nessuna posizione in log, analytics, push o card Home/Orders;
- scan security completo su `fd044d4..9d8d0eb`: zero finding reportable; entrambi i
  delta fix e il fix finale sono stati verificati con re-review mirate; zero finding
  P0/P1/P2/P3 restano aperti.
