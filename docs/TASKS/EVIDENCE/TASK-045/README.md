# Evidence TASK-045

Snapshot di handoff:
`DONE / REVIEW / USER_APPROVED_DONE`.

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
- candidato PR iniziale: `26aaa04ea600d40d3867f99a94cb99718a80703f`;
- remediation scanner artifact finale:
  `9034627f0c747dedb76af63e4b64c271d9cb2619`;
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
| CA-14 | PR CI `31950880035`, merge `c013539`, main CI `31951215868` | PASS |

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

Sul commit finale di codice/security
`9034627f0c747dedb76af63e4b64c271d9cb2619`, `bash scripts/check.sh` ha completato
con exit `0`: security/config scan su 601 file, 41/41 fixture security negative, 4/4
positive, governance 9/9, boundary 7/7, format 271 file invariati, analyze zero issue,
`flutter test --coverage` 624/624, benchmark cache 25.000 righe, secondo loading scan,
APK debug e iOS Simulator debug tutti `PASS`. Gli scan artifact separati hanno
verificato 544 file APK e 232 file Runner.app. Resta soltanto il warning noto sul
supporto Swift Package Manager del plugin Google Maps iOS; non è un failure.

L'acceptance Android `customer_delivery_tracking_flow_test.dart` è inoltre `PASS`
1/1 sul codice finale `5e0f1c6`, includendo owner contract, update live, stale e
redazione terminale.

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

### CI PR e remediation artifact

- PR Client #10: `https://github.com/XNIW/ClientMerchandiseControl/pull/10`;
- prima run `31947744128`, SHA `26aaa04`: Quality `SUCCESS`, Android debug
  `SUCCESS`, iOS Simulator build completata ma step artifact security `FAIL`;
- root cause: identificatore pubblico interno del Google Maps iOS SDK, presente due
  volte nel dylib vendor con contesto stabile; `GoogleMapsAPIKey` app ancora
  `NOT_CONFIGURED`, nessuna chiave Merchandise Control nel bundle;
- `T045-CI-SCAN-001 / P2`: match sovrapposti — `CLOSED` con scansione zero-width;
- `T045-CI-SCAN-002 / P2`: PEM OpenSSL-valid con whitespace/rewrap — `CLOSED` con
  normalizzazione ASCII e validazione Base64 aggregata;
- `T045-CI-SCAN-003 / P2`: falso positivo sulle costanti kernel — `CLOSED` con parser
  bounded e fixture positiva;
- re-review finale `c11f64a..9034627`: `APPROVED`, fuzz 50 varianti, 37 parseable e
  37/37 rifiutate; zero finding P0/P1/P2/P3 aperti;
- CI PR sul nuovo SHA `3cab680b4ca42e4cd65e71302b335ac7975256a5`:
  run `31950880035`, Quality/Android/iOS 3/3 `SUCCESS`, step applicabili verdi,
  annotation 0/0/0;
- merge normale: `c013539bec35c938f376be70567492ac3304844a`;
- main CI exact merge-SHA: run `31951215868`, 3/3 `SUCCESS`, annotation 0/0/0;
- branch remoto `codex/task-045-client-live-map-20260816` eliminato dopo verifica
  ancestry; production e activation Maps rimaste `OFF`.

## Closeout

- TASK-043, TASK-044 e TASK-045: `DONE`;
- progetto: `IDLE`, nessun task attivo;
- release train: `COMPLETE`, review integrata `APPROVED`;
- prossimo task: TASK-034 `TODO`, non attivato;
- finding aperti: P0 0, P1 0, P2 0, P3 0;
- il checkout primario non è stato usato come writer e conserva lo SHA/stato iniziale.
