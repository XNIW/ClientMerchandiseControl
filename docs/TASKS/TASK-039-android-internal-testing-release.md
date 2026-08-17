# TASK-039 — Android Internal Testing release

## Informazioni generali

- **Task ID**: TASK-039
- **Titolo**: Android Internal Testing release
- **File task**: `docs/TASKS/TASK-039-android-internal-testing-release.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-17
- **Ultimo aggiornamento**: 2026-08-17
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-039/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Dipendenze

- **Dipende da**: TASK-033, TASK-034, TASK-035, TASK-036, TASK-037, TASK-038
- **Sblocca**: TASK-041
- **Writer**: Client; Admin e gli altri repository read-only

## Scope

- produrre un AAB release pulito con configurazione production-like fail-closed;
- validare signing boundary, minify/R8/resource shrink, ABI, manifest, permission,
  exported component, App Link, network security, Maps, notification, OAuth,
  crash/analytics e versione;
- ispezionare AAB/APK per debug flag, localhost, staging value, secret, service role,
  test fixture, cleartext e capability non configurate abilitate;
- generare SHA-256 e release candidate riproducibile senza versionare artifact;
- caricare soltanto su Play Internal Testing se account, signing e policy repository
  risultano realmente disponibili; mai promuovere production.

## Non incluso

- produzione Play, staged rollout pubblico, acquisti, billing o key provisioning;
- invenzione/commit di keystore, alias, password, service account o console identity;
- modifica Supabase/production, provider payment, Maps billing o legal owner value;
- iOS/TestFlight, governato da TASK-040.

## Criteri di accettazione

| CA | Descrizione | Tipo |
|---|---|---|
| CA-01 | Release config e signing validator falliscono chiusi senza stampare secret | STATIC/SECURITY |
| CA-02 | AAB release pulito è generato e identificato con SHA-256/version/package | BUILD |
| CA-03 | Minify, R8, resource shrink, ABI e manifest sono coerenti col release target | BUILD/STATIC |
| CA-04 | Permission, exported component, App Link e cleartext policy sono least-privilege | SECURITY |
| CA-05 | Nessun debug/local/staging/secret/service-role/test fixture è nell'artifact | SECURITY |
| CA-06 | Maps/OAuth/notification/telemetry restano fail-closed senza config esterna | STATIC/TEST |
| CA-07 | Internal Testing è uploaded se autorizzazioni reali esistono, altrimenti il confine esterno è esatto | RELEASE |
| CA-08 | Review indipendente, exact-SHA CI e zero P0/P1/P2 sono reali | REVIEW/CI |

## Test case

| Test | Criteri | Procedura attesa |
|---|---|---|
| T-01 | CA-01/06 | validator environment/signing/provider con fixture negative e output redatto |
| T-02 | CA-02/03 | clean `flutter build appbundle --release` e inspection bundletool/aapt/apksigner |
| T-03 | CA-04/05 | manifest/artifact scan su permission, exported, link, cleartext, debug e stringhe vietate |
| T-04 | CA-07 | probe read-only di credenziali/policy; upload Internal soltanto se tutti i prerequisiti sono presenti |
| T-05 | CA-08 | check canonico, security review diff-scoped, review distinta, PR/main CI e hygiene |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Release unsigned/unuploadable non è dichiarata pubblicata | Evidence reale, nessun falso PASS | ATTIVA |
| D-02 | Nessun keystore o valore Play viene generato/inventato | Credenziali e ownership sono gate esterni | ATTIVA |
| D-03 | Production-like senza secret deve avviarsi o fallire chiusa, mai degradare a staging | Separazione ambiente | ATTIVA |
| D-04 | Il mandato 2026-08-16 autorizza Planning→Execution | ADR-015 | ATTIVA |

## Planning — `CODEX_PLANNER`

1. inventariare Gradle/signing/manifest/provider/tooling e soli nomi dei secret;
2. definire validator e matrice artifact con failure classificate;
3. implementare il minimo necessario per build release riproducibile e fail-closed;
4. costruire AAB/APK derivato, ispezionare package/version/signature/config/security;
5. provare Internal Testing capability senza mutazioni fuori confine;
6. produrre evidence, review indipendente e closeout exact-SHA.

### Rischi

- signing assente: produrre RC verificato e classificare external credential blocker;
- release config non operativa: fail-closed è accettabile, fallback staging no;
- shrinker rimuove entrypoint/plugin: smoke release su emulator e regressione;
- artifact espone config: scanner fail-closed e nessun upload;
- Play access ambiguo: nessuna chiamata di upload senza account/track/policy verificati.

### Handoff a Execution

- **Autorizzazione USER_APPROVER**: mandato 2026-08-16 e ADR-015
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Execution — `CODEX_EXECUTOR`

In corso.

## Review — `CODEX_REVIEWER`

`NOT_RUN`.

## Chiusura

- **Classificazione target**: `DONE_INTERNAL_RELEASE_PUBLISHED` oppure
  `TECHNICALLY_COMPLETE_EXTERNAL_CREDENTIAL_REQUIRED`
- **Production Play**: vietata
- **Data completamento**: non ancora
