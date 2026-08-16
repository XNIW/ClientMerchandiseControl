# TASK-045 — Client live map, integrated acceptance and closeout

## Informazioni generali

- **Task ID**: TASK-045
- **Titolo**: Client live map, integrated acceptance and closeout
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-16
- **Ultimo aggiornamento**: 2026-08-16
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-045/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

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

Da compilare con implementazione ed evidence reali.

## Review — `CODEX_REVIEWER` / `CODEX_RE_REVIEWER`

Da compilare da reviewer read-only sul revision set candidato.

## Fix — `CODEX_FIXER`

Da compilare soltanto in presenza di finding approvati.

## Chiusura

- **Conferma utente**: pre-autorizzata e condizionata a review/CI reali verdi
- **Merge**: normale, senza bypass
- **Data completamento**:
