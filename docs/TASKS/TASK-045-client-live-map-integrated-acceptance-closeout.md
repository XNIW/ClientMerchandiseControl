# TASK-045 — Client live map, integrated acceptance and closeout

## Informazioni generali

- **Task ID**: TASK-045
- **Titolo**: Client live map, integrated acceptance and closeout
- **Stato**: ACTIVE
- **Fase**: REVIEW
- **Responsabile**: CODEX_RE_REVIEWER
- **Data creazione**: 2026-08-16
- **Ultimo aggiornamento**: 2026-08-16
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-045/`
- **Handoff**: CODEX_FIX_COMPLETE_TO_RE_REVIEW

## Dipendenze

- **Dipende da**: TASK-043, TASK-044, TASK-026, TASK-028, TASK-031, TASK-033
- **Sblocca**: closeout del train; TASK-034 torna prossimo ma resta `TODO`
- **Writer**: Client Flutter. Admin/Supabase resta authority già integrata; modifiche
  addizionali richiedono un contratto realmente necessario.

## Scope

- integrare `google_maps_flutter` dietro `DeliveryMapAdapter`, con fake deterministico,
  feature flag e configurazione Android/iOS fail-closed senza chiavi in Git;
- mostrare la mappa nel dettaglio ordine solo per delivery `liveCourier`, sessione
  attiva, ordine compatibile, owner autenticato e posizione fresca;
- mostrare tre marker bounded, recenter, last updated/freshness comprensibile e
  alternativa testuale sempre presente, senza polyline o ETA Client;
- preservare timeline e cache durante stale/offline/reconnect; nascondere coordinate
  e mappa su terminale, logout, account/order change o provider failure;
- collegare Home e Orders al dettaglio con CTA reale quando tracking disponibile,
  senza posizione nelle liste;
- verificare accessibilità, localizzazione, reduced motion, rotazione, dark mode,
  performance marker isolata e matrice visuale bounded;
- eseguire acceptance integrata contract -> snapshot -> Client -> terminal redaction,
  review/fix/re-review, CI, merge, main CI e closeout `IDLE`.

## Non incluso

- activation production, chiavi provider, billing, pubblicazione store o rollout;
- background tracking garantito, companion courier o modalità staff nel Client;
- route/polyline, distanza o minuti stimati non forniti dal server;
- geocoding, Places, telemetria mappe applicativa, coordinate in log/analytics/push;
- dati demo nel production path o modifiche a inventory, POS e vendita fiscale.

## Criteri di accettazione

| CA | Descrizione | Tipo |
|---|---|---|
| CA-01 | La mappa appare solo con fulfillment delivery, mode live, sessione attiva, stato compatibile, owner e location fresca | UNIT/WIDGET |
| CA-02 | confirmed/accepted/preparing/ready mostrano timeline e copy futuro, mai marker live statico | WIDGET |
| CA-03 | completed/cancelled/rejected nascondono mappa e coordinate e mantengono timeline | UNIT/WIDGET/PRIVACY |
| CA-04 | Detail mostra stato, finestra ETA server-side, tre marker, last updated, recenter e fallback testuale | WIDGET |
| CA-05 | stale/offline/reconnect preservano l'ultimo contesto senza muovere o interpolare il marker | UNIT/WIDGET |
| CA-06 | statusOnly ed externalCarrier non istanziano il provider; URL esterno resta validato | UNIT/WIDGET/SECURITY |
| CA-07 | Home e Orders espongono CTA/indicatore reale senza coordinate nelle card | UNIT/WIDGET |
| CA-08 | Provider flag off, chiave assente o exception degradano fail-closed senza rete nei test | UNIT/BUILD |
| CA-09 | Android/iOS ricevono chiavi distinte fuori Git e ristrette per ambiente; nessun secret è versionato | STATIC/SECURITY |
| CA-10 | Screen reader, focus, target 48×48, contrasto, text scale, reduced motion, dark e rotazione sono verificati | A11Y/VISUAL |
| CA-11 | Un update location ricostruisce soltanto la superficie mappa; dispose e cambio route/account chiudono runtime | UNIT/WIDGET/PERF |
| CA-12 | Tutte le stringhe passano da gen_l10n in es-CL, it, en e zh-Hans; CLP/date restano localizzati | STATIC/UNIT |
| CA-13 | Acceptance sintetica prova mode, owner boundary consumato, live update, stale e terminal redaction | INTEGRATION |
| CA-14 | Gate canonici, review, PR CI, merge normale e main CI exact-SHA sono verdi | COMMAND/CI |

## Test case

| Test | Criteri | Procedura |
|---|---|---|
| T-01 | CA-01/02/03 | matrice pura di eligibility per fulfillment/mode/session/status/freshness/auth |
| T-02 | CA-04/05 | widget detail live, marker update, stale, offline/reconnect e recenter |
| T-03 | CA-06/08 | statusOnly, external, flag off, missing key, provider exception e dispose |
| T-04 | CA-07 | Home active order e Orders in-delivery aprono il dettaglio senza mostrare coordinate |
| T-05 | CA-09 | scan target nativi/config/bundle per chiavi e activation fail-closed |
| T-06 | CA-10/12 | semantics e matrice viewport/locale/theme/text scale/reduced motion/rotazione |
| T-07 | CA-11 | contatori rebuild, coalescing marker e lifecycle route/account/order |
| T-08 | CA-13 | integration fake contract -> live snapshot -> stale -> terminale redatto |
| T-09 | CA-14 | format, analyze, coverage, APK, iOS Simulator e `scripts/check.sh` |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | ADR-014 governa Google Maps nativo dietro adapter e fake. | Copertura Cile, supporto Flutter e testabilità | ATTIVA |
| D-02 | Production resta OFF senza attestazione separata di chiavi, restrizioni, billing e device. | Mandato e fail-closed | ATTIVA |
| D-03 | La mappa non è fonte di stato: timeline, ETA e freshness restano testuali/server-authoritative. | Accessibilità e verità operativa | ATTIVA |
| D-04 | Il writer web resta foreground; nessun claim background viene aggiunto. | Limiti browser/OS reali | ATTIVA |
| D-05 | L'autorizzazione USER_APPROVER del 2026-08-16 copre review, fix, PR, merge e closeout condizionati. | Train sequenziale autorizzato | ATTIVA |

## Planning — `CODEX_PLANNER`

### Analisi e approccio

1. consolidare il presenter/adattatore introdotto in TASK-044 e separare eligibility,
   rendering provider e contenuto testuale;
2. introdurre configurazione nativa compile-time separata per Android/iOS e un factory
   fail-closed che non istanzia Google Maps senza tutti i gate;
3. comporre la card tracking nel dettaglio ordine con subtree mappa isolato e fallback;
4. collegare le CTA data-backed Home/Orders senza creare nuove subscription globali;
5. completare l10n, accessibility/golden matrix, integration ed evidence;
6. eseguire review indipendente, fix/re-review e gate/CI sullo SHA finale.

### Rischi e mitigazioni

- chiave in bundle/Git: injection nativa fuori Git, scan sorgente e artifact;
- mappa visibile su dato stale/terminale: eligibility pura, terminal precedence e test;
- rebuild/perdita risorse: subtree consumer ristretto, controller/presenter dispose e
  contatori test;
- test dipendente dalla rete: fake adapter/widget, nessuna istanza Google in CI;
- accessibilità insufficiente del canvas: summary testuale completo e controlli labelled.

### Handoff a Execution

- **Handoff planning**: CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION
- **Autorizzazione**: già ricevuta nel prompt del 2026-08-16
- **Transizione applicata**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Execution — `CODEX_EXECUTOR`

- **Revision set**: `fd044d4b9b7a7bd4c4d3ccf71b977a01bc39563f` →
  `9d8d0ebc86c03f194276ed5c3d26214a4e7df7bb`.
- Aggiunti adapter Google Maps e fake, eligibility owner/live/fresh, tre marker bounded,
  recenter accessibile e subtree isolato; nessuna route o ETA calcolata nel Client.
- Integrati dettaglio ordine, fallback testuale, CTA Home/Orders, localizzazioni,
  configurazioni native fail-closed e golden deterministico 390×844 es-CL.
- La suite completa iniziale ha superato 611 test con coverage; `flutter analyze`, APK
  debug e iOS Simulator debug erano verdi. L'acceptance fake ha provato owner, live,
  stale e redazione terminale senza rete provider.
- **Handoff Execution**: `CODEX_EXECUTION_COMPLETE_TO_REVIEW`.

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

### Review iniziale

- **Esito**: `CHANGES_REQUIRED` sullo SHA `9d8d0eb`.
- **T045-REV-RT-001 / P2**: polling RPC permanente anche con Realtime sano.
- **T045-REV-NATIVE-002 / P2**: il flag Dart poteva attestare una chiave mentre il
  bundle nativo conteneva ancora `NOT_CONFIGURED`.
- **T045-REV-PROVIDER-003 / P2**: errori asincroni di controller/initial camera fit
  restavano fuori dal boundary fail-closed.
- La security diff review sul range completo non ha rilevato finding reportable;
  owner/auth/cache/terminal redaction e assenza di coordinate in Home/Orders sono
  risultate integre. Evidence governance incompleta è stata rilevata e viene colmata
  da questo handoff.
- **Handoff Review**: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

### Re-review

Il primo ciclo sul delta `9d8d0eb..f188a32` ha chiuso polling, handshake nativo e
initial fit, ma ha restituito `CHANGES_REQUIRED` per:

- **T045-RR-TEARDOWN-004 / P2**: `dispose` fallibile durante replace/late callback
  poteva ancora propagare un errore asincrono e saltare la chiusura degli stream;
- **T045-RR-FRESHNESS-005 / P2**: resume foreground/route con snapshot RPC duplicato
  non riarmava il timer freshness cancellato durante la pausa;
- **T045-RR-A11Y-006 / P3**: Home annunciava due volte la CTA perché la label aggregata
  manteneva anche le semantics figlie.

La seconda re-review è in corso sul delta `f188a32..3c8564b`; l'esito non è inferito
dai test del fixer.

## Fix — `CODEX_FIXER`

- **SHA fix**: `f188a3230e4608a27c031d4b2e58e690a53eb8c6`.
- `T045-REV-RT-001`: polling attivato soltanto su failure/chiusura Realtime e fermato
  al primo evento valido; freshness separata in un timer locale senza RPC.
- `T045-REV-NATIVE-002`: handshake Android/iOS verifica la chiave effettiva prima del
  factory senza restituire segreti; missing channel/sentinel falliscono chiusi.
- `T045-REV-PROVIDER-003`: runtime state `ready/failed`, camera port iniettabile,
  initial fit catturato, timeout bounded, teardown idempotente e superficie coperta/non
  interattiva fino al ready.
- Hardening accessibilità nello stesso scope: le semantics aggregate di Home e Orders
  annunciano esplicitamente indicatore e CTA della consegna.
- Gate fix eseguiti: analyze mirato `PASS`; 47 test runtime/UI `PASS`; 19 test
  Home/Orders `PASS`; integration Android 1/1 `PASS`; APK debug e iOS Simulator debug
  `PASS`. I gate canonici completi verranno registrati sul candidato di re-review.
- **Handoff Fix**: `CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

### Fix ciclo 2

- **SHA fix**: `3c8564b62e255136bf9579df82d91bf678bad6f8`.
- `T045-RR-TEARDOWN-004`: attach/replace/dispose/late callback sono tutti racchiusi
  nel boundary non-throwing; stream e notifier chiudono in `finally` e il nuovo
  controller viene disposto anche quando fallisce il precedente.
- `T045-RR-FRESHNESS-005`: il ramo duplicate/non-newer riapplica la freshness locale e
  riarmata la deadline dopo resume; test foreground e route provano lo stale senza
  polling.
- `T045-RR-A11Y-006`: Home usa una sola semantics aggregata, include prodotto e CTA e
  verifica una sola occorrenza localizzata.
- Gate mirati: analyze `PASS`; controller/map/Home 30/30 e adapter teardown 6/6
  `PASS`; `git diff --check` `PASS`.
- **Handoff Fix ciclo 2**: `CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

## Chiusura

- **Conferma utente**: pre-autorizzata e condizionata a review/CI reali verdi
- **Merge**: normale, senza bypass
- **Data completamento**:
