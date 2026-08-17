# TASK-040 — iOS TestFlight release

## Informazioni generali

- **Task ID**: TASK-040
- **Titolo**: iOS TestFlight release
- **File task**: `docs/TASKS/TASK-040-ios-testflight-release.md`
- **Stato**: ACTIVE
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-17
- **Ultimo aggiornamento**: 2026-08-17
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-040/`
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Dipendenze

- **Dipende da**: TASK-033, TASK-034, TASK-035, TASK-036, TASK-037, TASK-038
- **Sblocca**: TASK-041
- **Writer**: Client; Admin e repository operativi read-only

## Obiettivo

Produrre e verificare un release candidate iOS production-like, incluso archive
quando tecnicamente possibile, con configuration/signing/entitlement/privacy boundary
fail-closed. Caricare soltanto su TestFlight se certificato, provisioning, App Store
Connect credential e autorizzazione di upload risultano realmente presenti.

## Scope

- inventario Xcode/Flutter, scheme/configuration, bundle/version/build e signing;
- release build `--no-codesign` e archive non firmato quando supportato;
- validator source/app/archive per Info.plist, entitlements, privacy manifest, dSYM,
  framework, debug/staging/secret/dev callback e provider fail-closed;
- Universal Links, push entitlement, Maps native setup, account deletion,
  accessibility e store metadata boundary;
- preflight App Store Connect read-only e upload TestFlight solo con gate completo;
- gate locali, CI release, review/security diff-scoped, PR, merge e main CI.

## Non incluso

- pubblicazione App Store production o public rollout;
- creazione di certificati, profili, App Store Connect key o account;
- attivazione Maps billing/key, OAuth production, push production o backend;
- acquisti reali, dati cliente, valori legali inventati o modifiche production.

## Criteri di accettazione

| CA | Criterio | Evidence attesa |
|---|---|---|
| CA-01 | release config e signing sono completi oppure falliscono chiusi | STATIC/TEST |
| CA-02 | bundle/version/build, scheme e deployment target sono verificati | BUILD/STATIC |
| CA-03 | release app/archive e dSYM sono prodotti e identificati con SHA-256 | BUILD |
| CA-04 | Info.plist, entitlement, URL scheme/Universal Links e push sono least-privilege | SECURITY |
| CA-05 | privacy manifest app/SDK e store metadata sono presenti e coerenti | STATIC/TEST |
| CA-06 | nessun debug, localhost, staging value, secret, test fixture o dev callback è nell'artifact | SECURITY |
| CA-07 | Maps/OAuth/push/telemetry restano fail-closed senza configurazione esterna | STATIC/TEST |
| CA-08 | symbol, architecture e embedded framework sono validati | BUILD/STATIC |
| CA-09 | TestFlight è uploaded solo con prerequisiti reali; altrimenti il blocker esterno è esatto | RELEASE |
| CA-10 | review indipendente, exact-SHA CI e zero P0/P1/P2 sono reali | REVIEW/CI |

## Test case

| Test | Copertura | Procedura attesa |
|---|---|---|
| T-01 | CA-01/02 | source validator e negative fixture per config/signing/version |
| T-02 | CA-03/08 | clean Flutter release no-codesign, xcodebuild archive e artifact inspection |
| T-03 | CA-04/05 | plist/entitlement/privacy manifest validator e fixture negative |
| T-04 | CA-06/07 | security scan source/artifact, strings/config/provider fail-closed |
| T-05 | CA-09 | probe credential/signing read-only; upload solo con gate completo |
| T-06 | device | iOS Simulator smoke release se installabile; physical iOS separato |
| T-07 | CA-10 | check canonico, security diff-scoped, review distinta, PR/main CI e hygiene |

## Planning — `CODEX_PLANNER`

1. inventariare Xcode, scheme, build setting, entitlement, signing identity, profile e
   soli nomi degli input App Store Connect;
2. definire validator e matrice release/source/app/archive con output redatto;
3. implementare il minimo per un build/archive riproducibile senza fallback debug o
   staging;
4. ispezionare bundle, privacy manifest, symbol, framework, architecture e config;
5. provare simulator/device e TestFlight capability senza mutazioni fuori confine;
6. produrre evidence, review indipendente e closeout exact-SHA.

### Rischi e mitigazioni

- signing/profile assenti: RC no-codesign verificato e blocker esterno preciso;
- archive no-codesign non esportabile: conservare archive verificabile e non
  dichiararlo upload-ready;
- entitlement aggiunto impropriamente: derive-and-compare fail-closed, nessun push/
  associated-domain inventato;
- provider non configurato: sentinel/flag restano OFF, nessun fallback staging;
- tool Xcode nondeterministico: comandi canonici, DerivedData isolato e artifact hash;
- TestFlight ambiguity: nessun upload senza identity, credential, bundle access e
  gate esplicito tutti presenti.

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | archive/build no-codesign non equivale a TestFlight upload | Evidence reale | ATTIVA |
| D-02 | nessun certificato/profile/App Store key viene generato o inventato | Gate esterno | ATTIVA |
| D-03 | production-like incompleta fallisce chiusa, mai verso staging | Separazione ambienti | ATTIVA |
| D-04 | mandato 2026-08-16 autorizza Planning→Execution | ADR-015 | ATTIVA |

### Handoff a Execution

- **Autorizzazione USER_APPROVER**: mandato 2026-08-16 e ADR-015
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Execution — `CODEX_EXECUTOR`

In corso.

## Review

`NOT_RUN`.

## Chiusura

- **Classificazione target**: `DONE_TESTFLIGHT_UPLOADED` oppure
  `TECHNICALLY_COMPLETE_EXTERNAL_CREDENTIAL_REQUIRED`
- **Production App Store**: vietata
- **Data completamento**: non ancora
