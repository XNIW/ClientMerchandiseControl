# TASK-054 — Audit operativo riaperto

Snapshot di handoff:
`BLOCKED / EXECUTION / CODEX_PLANNING_APPROVED_TO_EXECUTION`.

Il prompt del2026-09-28 autorizza sviluppo/audit/fix. Non rinnova gli apply staging,
merge o distribuzione dei task storici. Nessun DONE e nessuna auto-approvazione.

- [Inventario completo e finding prima/dopo](functional-audit.md)
- [Manifest55 RPC](../../../contracts/client-backend-rpc-manifest.json)
- [Riconciliazione migration, preflight e recovery](backend-reconciliation.md)
- [Gate, benchmark prima/dopo ed E2E-01…25](validation.md)

## Stato operativo

| Livello | Stato | Evidence / limite |
|---|---|---|
| CODE | BLOCKED per acceptance completa |11 difetti corretti con regressioni;843 test PASS e2 golden FAIL,39 focused finali,70 race,10 benchmark PASS; due golden macOS 27 falliscono anche a baseline; review distinta da ottenere |
| BACKEND_RUNTIME | FAIL |staging32/55 RPC;23 mancanti; due migration assenti;1034 assertion SQL locali PASS |
| STAGING_E2E | BLOCKED |25 ID originali preservati; descrizioni originali non recuperate; apply/login/mandato specifico assenti |
| PHYSICAL_DEVICES | BLOCKED |nessuna installazione o smoke su telefono; fixture/account/dispositivi autorizzati necessari |
| DISTRIBUTION | BLOCKED |nessuna build firmata/upload; dominio/provider, backend compatibile e review mancanti |
| PRODUCTION | NOT_ACTIVATED |nessuna modifica o attivazione |

## Dipendenze esterne concrete

| Owner | Azione necessaria | Come verificare |
|---|---|---|
| Utente/backend owner |autorizzare esplicitamente le due migration hash-bound sul solo ref indicato, attestando backup/PITR e finestra |readback history,55 RPC,grants/RLS,fixture autorizzate e recovery secondo piano |
| Product/Auth owner |indicare dominio HTTPS posseduto/verificato e callback canonica; approvare configurazione Google/Supabase e associazioni native |App/Universal Links su cold/warm start,PKCE,logout/refresh sul vero provider |
| Product/address owner |decidere provider di ricerca/reverse/pin e condizioni di caching/quote, senza riutilizzare chiavi tracking |adapter reale + offline/GPS/permessi/zona non servita + fallback manuale |
| QA/product owner |recuperare la definizione originale E2E-01…25 |mapping a criteri originali senza sostituzioni |
| Reviewer distinto |revisionare Client/backend candidate e coordinare P3 Admin |finding riproducibili e re-review; niente approvazione dell'autore |
| Mobile/release owner |toolchain compatibile col deployment target iOS 14, Gradle 9.1 verificato, poi device/config/signing approvati |build canoniche,smoke emulatori e fisici separati,preflight e upload distinti |
| Admin writer/reviewer |integrare candidato typegen commerce dopo coordinamento con TASK-159 |typecheck/foundation/diff schema; restante drift schema-wide resta aperto |

Push reale e online payment/refund richiedono decisioni/configurazioni proprie;
ADR-012 abilita soltanto i due metodi offline, ADR-014 soltanto la mappa tracking.
Non si attivano provider o dashboard esterni in questa run.

## Git, CI e review

Branch `codex/client-functional-audit`; PR [27](https://github.com/XNIW/ClientMerchandiseControl/pull/27)
OPEN/DRAFT, nessun merge. Commit implementazione447d2a89ef37e175dfdd592507307bb528c12314;
fix finale6353c9bd02162cc858f0d1a2b9459c8ee92f48e2. Push confermato dal remote.
Le revisioni successive aggiornano evidence/governance e correggono la selezione
della fixture storica nel test di governance; il runtime resta quello di6353c9b. Baseline493c2c9;
checkout originari e modifiche utente preservati. Database/emulatori creati per la run
sono stati fermati, senza eliminare altri ambienti o dati.

La CI valida cinque job sul commit della PR: Quality, Android debug, Android release
unsigned AAB/APK, iOS simulator, iOS release unsigned/archive e validator avversariali.
La run36459656662 di447d2a8 è stata cancellata dalla normale concurrency al push del fix;
non è un PASS del candidato. Le ricevute finali, con SHA/job/step/annotation, devono
corrispondere ai [check della PR](https://github.com/XNIW/ClientMerchandiseControl/pull/27/checks).
Nessuna CI precedente sostituisce i check del nuovo head; esito finale riportato
nell'handoff al termine delle run, senza alterare il revision set implementativo.

La run36461675459 ha rilevato una regressione nel harness di governance: cercando
l'ultima transizione BLOCKED selezionava TASK-054 al posto di TASK-040. La selezione
ora usa l'identità del task storico e ne verifica lo stato; 101/101 fixture locali
PASS dopo il fix. La CI finale deve includere questa correzione.

Review distinta NOT_RUN: nessun reviewer inventato né approvazione dell'autore.
Il task è BLOCKED in EXECUTION perché manca acceptance runtime e una review distinta;
non viene consegnato come review-ready e non passa a DONE. I prerequisiti sopra e le
due prove golden locali restano aperti anche se la CI di build risulta verde.

Evidence completa locale non versionata: `~/.codex/outputs/client-functional-audit/`.
Il manifest locale associa log sanitizzati ai file con SHA256; il candidato typegen
Admin rimane separato e non applicato. Nessun processo locale di verifica irrisolto.
