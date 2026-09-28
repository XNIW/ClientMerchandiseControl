# TASK-054 — Audit operativo riaperto

Snapshot di handoff:
`ACTIVE / EXECUTION / CODEX_PLANNING_APPROVED_TO_EXECUTION`.

Il prompt del2026-09-28 autorizza sviluppo/audit/fix. Non rinnova gli apply staging,
merge o distribuzione dei task storici. Nessun DONE e nessuna auto-approvazione.

- [Inventario completo e finding prima/dopo](functional-audit.md)
- [Manifest55 RPC](../../../contracts/client-backend-rpc-manifest.json)
- [Riconciliazione migration, preflight e recovery](backend-reconciliation.md)
- [Gate, benchmark prima/dopo ed E2E-01…25](validation.md)

## Stato operativo

| Livello | Stato | Evidence / limite |
|---|---|---|
| CODE | BLOCKED per acceptance completa |11 difetti corretti con regressioni;840 test funzionali,37 focused finali,70 race,10 benchmark PASS; due golden macOS27 falliscono anche a baseline; review distinta da ottenere |
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
| Mobile/release owner |toolchain compatibile col deployment target iOS14, Gradle9.1 verificato, poi device/config/signing approvati |build canoniche,smoke emulatori e fisici separati,preflight e upload distinti |
| Admin writer/reviewer |integrare candidato typegen commerce dopo coordinamento con TASK-159 |typecheck/foundation/diff schema; restante drift schema-wide resta aperto |

Push reale e online payment/refund richiedono decisioni/configurazioni proprie;
ADR-012 abilita soltanto i due metodi offline, ADR-014 soltanto la mappa tracking.
Non si attivano provider o dashboard esterni in questa run.

## Git, CI e review

Lavoro in checkout gestito `codex/client-functional-audit`, baseline Client493c2c9.
Checkout originali e lavori concorrenti preservati. Candidate e documenti sono in
preparazione per PR draft; le ricevute effettive sono aggiunte dopo conferma remota.
La CI storica32635780234 non è un gate del candidato. Merge NOT_RUN/non autorizzato.
Review distinta NOT_RUN; nessun reviewer inventato, nessuna approvazione autonoma.
