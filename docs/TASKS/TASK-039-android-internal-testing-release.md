# TASK-039 — Android Internal Testing release

## Informazioni generali

- **Task ID**: TASK-039
- **Titolo**: Android Internal Testing release
- **File task**: `docs/TASKS/TASK-039-android-internal-testing-release.md`
- **Stato**: ACTIVE
- **Fase**: REVIEW
- **Responsabile**: CODEX_REVIEWER
- **Data creazione**: 2026-08-17
- **Ultimo aggiornamento**: 2026-08-17
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-039/`
- **Handoff**: CODEX_EXECUTION_COMPLETE_TO_REVIEW

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

- release signing configurabile soltanto all-or-none da secret store o
  `android/key.properties` ignorato; nessun fallback al debug certificate;
- R8/obfuscation/optimization e resource shrinking abilitati, con mapping e
  metadata R8 inclusi nel bundle;
- overlay release con cleartext vietato e sole CA di sistema;
- template production-like pubblico: environment production, OAuth e Maps
  spenti, backend/callback/shop assenti e bootstrap fail-closed;
- validator source/artifact e CI release gate aggiunti; package, versione, ABI,
  manifest, exported boundary, provider, signature e SHA-256 verificati;
- clean AAB e APK generati sullo SHA `6b878f35aebfe0e98fa305c624747711fd81f1b0`;
- AAB `67.773.321` byte, SHA-256
  `6c321e2fcafcf4cd3a7044f366ebaa5c1c2d0e41e2a84c425e931a1b76a84718`;
- APK di ispezione `70.137.338` byte, SHA-256
  `82ee832fb88d64eef3d04e0a8f4a5a7f4ddcaf0a2fb13efcfea82bfee81b91ce`;
- artifact unsigned: install emulator respinta correttamente con
  `INSTALL_PARSE_FAILED_NO_CERTIFICATES`; nessuno smoke release inventato;
- nessun keystore, secret/variable GitHub, service account o config Play
  disponibile; `--require-upload-ready` fallisce con
  `PLAY_INTERNAL_REQUIRES_SIGNED_AAB`; upload `NOT_RUN`;
- App Link HTTPS production resta chiuso finché non esistono dominio posseduto,
  association file e fingerprint release; OAuth production resta vietato.

Gate executor:

- `scripts/check.sh`: PASS;
- security source/artifact: 666 file source, 132 file artifact, zero valori
  vietati; fixture security 41/41 negative e 4/4 positive;
- suite non-performance 772/772, resilience repeat 70/70, performance 10/10;
- format 292/0, analyze zero issue, metadata/governance/architecture PASS;
- Android debug build e iOS Simulator debug build PASS;
- clean AAB/APK release e validator PASS.

`CODEX_EXECUTION_COMPLETE_TO_REVIEW`.

## Review — `CODEX_REVIEWER`

`NOT_RUN`.

## Chiusura

- **Classificazione target**: `DONE_INTERNAL_RELEASE_PUBLISHED` oppure
  `TECHNICALLY_COMPLETE_EXTERNAL_CREDENTIAL_REQUIRED`
- **Production Play**: vietata
- **Data completamento**: non ancora
