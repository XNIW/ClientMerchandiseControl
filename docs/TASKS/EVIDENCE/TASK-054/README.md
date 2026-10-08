# TASK-054 — Completamento operativo

Snapshot di handoff:
`ACTIVE / FIX / CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

Il mandato successivo autorizza implementazione, review distinte, PR coordinate, merge
di sviluppo condizionato e apply staging dopo recovery/finestra. TASK-054 resta aperta.
Stato corrente nel [registro residui](residuals.md), prove nuove in
[validation](validation.md#ripresa-operativa--candidato-successivo-a0990c80),
[acceptance R01–R30](acceptance-revision.md), [recovery](backend-reconciliation.md).

## Completamento successivo — 8 ottobre 2026

Il [rapporto corrente](CLIENT_TASK054_NEXT_INTEGRATION_RESULT.md#completamento-successivo--8-ottobre-2026)
e l'ultimo [overlay del registro unico](residuals.md#overlay-completamento-successivo--2026-10-08-mandato-fdab4373)
prevalgono sui checkpoint storici. Il freeze applicativo f9a61d5 integra journal
illeggibile e assistenza missing/retry, entrambi APPROVED SOURCE_CODE_ONLY dopo
regressioni RED. Nuova matrice host16casi PASS; fixture137 con sole24catture nuove.
Suite globale finale1049PASS, formato e analyze PASS; 35/35gate locali PASS nella
[capsula finale](next-integration/completion-final-gates.json). Native finale ancora in verifica, nessun PASS integrato dedotto.

[Recovery popolata](next-integration/completion-backend.json) e
[review distinta](next-integration/completion-backend-review.md) PASS locale;
readback TEST32/57RPC conformi,25assenti,quattro migration assenti,1/2indici,
history155. Service verify-full preparato dal coordinatore; TLS BLOCKED per
accesso protetto/trust/runner IPv6. Apply NOT_RUN, nessun cron pausato.
[Worker](next-integration/completion-worker.md) esatto qualificato in workerd e
packaging no-bundle PASS, review distinta APPROVED locale; versione TEST22107a6f
invariata, deploy NOT_RUN per backend/finestra. Config/fixture Client parziali
preparate fuori Git; pilot/account/callback/firma/canali assenti. Una sola richiesta
sui riferimenti protetti è pendente. R01–R30 e25E2E conservano ID e prove mancanti.

## Gate journal iOS aggiuntivo — 8 ottobre 2026

Il [gate iOS dedicato](next-integration/ios-journal-source-20261008.md) riusa la
fixture Android e mantiene app/entitlement invariati. Review distinta APPROVED
SOURCE_CODE_ONLY con 21 test e otto PoC e nove hash associati a e7b194c.
Il runtime journal resta NOT_RUN: nella CI hosted la preparazione fallisce
dopo il boot, prima della fixture; nessun difetto Keychain dedotto.

## Checkpoint precedente — 8 ottobre 2026, PR29 e7b194c

Il [rapporto corrente](CLIENT_TASK054_NEXT_INTEGRATION_RESULT.md#checkpoint-storico-precedente--8-ottobre-2026-pr29-e7b194c)
 e il [registro unico](residuals.md#overlay-completamento-operativo--2026-10-08)
 governano il candidato operativo. La [review sorgente distinta](next-integration/client-source-review-20261008.md)
 è APPROVED SOURCE_CODE_ONLY su bb538923 dopo re-review dei contratti;
 suite globale e CI sono gate separati.
 Il [backend corrente](next-integration/backend-operational-readiness-20261008.md)
 documenta history155, recovery scoped delle tre canoniche PASS e integrità
 preesistente FAIL. Il manifest nuovo ha57RPC: alle23 assenti sullo snapshot
 iniziale55 si aggiungono2RPCv3 e una migration additiva distinta non applicata.
 La [recovery corrente con delta v3](next-integration/backend-v3-recovery-20261008.md)
 è PASS nel clone con history 155→158→159→158→155 e ledger vuoto;
 l'integrità preesistente resta FAIL. Finestra writer/cron, TLS/config/pilot
 approvati e accettazione autenticata restano prerequisiti; nessun PASS live dedotto.

La CI `37817219242` su `62980d2` termina con cinque job PASS e smoke iOS
 FAIL: build e lancio riusciti, timeout in attesa della VM Service senza test.
 Android produce 113 PNG Flutter e quattro frame OS;
 [review pixel distinta](next-integration/native-visual-review-20261008.md)
 approvata sul campione critico di 27 immagini. iOS capture NOT_RUN.
 La [build Worker selettiva](next-integration/worker-selective-build-20261008.md)
 è PASS con 29 smoke locali, mentre il runtime TEST distribuito resta invariato.

La [CI finale](next-integration/ci-ios-journal-20261008.md) `37822118836`
su `e7b194c` termina con cinque job PASS e due FAIL nella preparazione/cleanup
iOS. Anche release iOS unsigned PASS. La
[review Android finale](next-integration/native-visual-association-e7b194c-20261008.md)
associa 109 PNG identici e ispeziona gli otto mutati senza finding. Il
[packaging Worker](next-integration/worker-selective-packaging-20261008.md)
è PASS locale con rete negata; upload/deploy e cinque reference runtime NOT_RUN.

Le sezioni del4/5ottobre e le risorse elencate sotto sono snapshot storici,
 inclusi147receipt/55RPC/c796. Non sostituiscono la readiness corrente.

## Prossima integrazione NI054 — 2026-10-04

Baseline main bfbfc0b6, PR28 già MERGED. Source NI054 e review scoped completate;
CI5 terminale nonverde, REVIEW/BLOCKED e PR29 draft. Evidence finale su branch
codex/task054-next-evidence-ci5, candidato c796526 immutabile nel worktree isolato;
registro unico residuals.md. Le ricevute sotto restano snapshot storici. Il risultato unico è
[CLIENT_TASK054_NEXT_INTEGRATION_RESULT.md](CLIENT_TASK054_NEXT_INTEGRATION_RESULT.md),
con snapshot storici, refresh5ottobre e gate del nuovo candidato distinti.

## Mandato funzionale e UX precedente

[CLIENT_TASK054_FUNCTIONAL_UX_OPERATIONAL_RESULT](functional-ux-operational-result.md)
è la ricevuta storica sulla main Client12f03c7 e Admin4532831b. Preflight di quel ciclo:
32/55RPC,1/2indici,history147; applyBLOCKED senza finestra/recoveryremota.
Correzioni UI, filtro non lette e mutazioni carrello completate; review del nuovo candidato e CI
sono separate dalle ricevute storiche. Le capability live restano NOT_RUN/BLOCKED.

## Snapshot storico PR27 — 2026-10-01

Revision set: Client runtime `ecba981c42bb80b125927478dc02c07210039407`,
Admin PR117 `d4fbf49ce274b7a97f7c34fa5519a0b8a088b9d5`, merged
con `6d5f3768bcc7e7bef2a5c539742cce0a99ef58ee`; main ora `f21339bb`.
C-01/C-02/C-03/B-04 chiusi tramite re-review distinta; nessun P0/P1/P2 aperto nel
delta verificato. Approvazione finale di integrazione in attesa delle CI applicabili.
Il fix del runner iOS4c3e71b è verificato: smoke reale1PASS/exit0,5casi watchdog
indipendenti PASS. Runtime prodotto ecba981 invariato; target iOS14 preservato.
Le ricevute CI/merge prodotte dopo questo freeze sono associate allo SHA esatto
nella [PR27](https://github.com/XNIW/ClientMerchandiseControl/pull/27) e nel rapporto
locale finale del mandato; nessuno stato live viene promosso per il solo merge.

| Livello | Stato | Evidence / limite |
|---|---|---|
| CODE | PASS verifiche concluse; CI finale NOT_RUN al freeze |4c3e71b:866 test PASS/1skip,10benchmark PASS,2golden macOS e smoke iOS1PASS; Android debug/release PASS; release iOS e ricevuta finale separati |
| BACKEND_RUNTIME | FAIL |metadata fresco32/55 RPC,1/2 indici richiesti,3 migration assenti; recovery locale combinata PASS; apply BLOCKED finestra writer |
| STAGING_E2E | NOT_RUN |nuova acceptance30casi revisionata come piano; nessuna fixture business condivisa creata |
| AUTH_LIVE | NOT_RUN |codice configurabile e testato; dominio/provider e associazioni native approvati assenti |
| ADDRESS_PROVIDER_LIVE | NOT_RUN |adapter Photon/map/GPS e fallback implementati; endpoint e chiavi approvati non configurati |
| PHYSICAL_DEVICES | NOT_RUN |iPhone rilevato, ma runtime/firma approvati per questo bundle non attestati; Android emulator smoke PASS |
| DISTRIBUTION | BLOCKED |preflight richiede runtime, firma/destinazione e backend compatibile; nessun upload |
| MAIN_INTEGRATION | PASS Admin; NOT_RUN Client al freeze |Admin117 merged6d5, CI PR/main PASS; Client27 merge condizionato a CI/review esatte, ricevuta finale nella PR |
| PRODUCTION | NOT_ACTIVATED |nessuna modifica o attivazione |

## Risorse registrate nel precedente snapshot

| Owner / risorsa | Controllo eseguito e azione minima | Configurazione e verifica successiva |
|---|---|---|
| Backend owner / recovery e finestra |dump schema fresco ripristinato, inverse/cataloghi/ACL/dati fixture e147receipt identici; Storage API stessoDB PASS; backups null/PITR false. Concordare finestra writer e ripetere preflight corrente |recovery-hash in operational-provenance.json; apply canonico3file solo dopo preflight, readback history/55RPC/2indici, RLS e fixture sintetiche owner/shop con cleanup |
| Backend/release owner / servizio readonly |gate live tentato, manca servizio approvato; predisporre connessione readonly TLS al ref autorizzato |CMC_BACKEND_PGSERVICE e config artifact esterna; check-backend-compatibility.py --live --app-config PATH; snapshot non abilita upload |
| Auth/domain owner / dominio |nessun dominio approvato nei riferimenti; indicare riferimento già autorizzato e associazioni esatte |AUTH_CALLBACK_VERIFIED_HOST e AUTH_REDIRECT_URI nel JSON staging esterno; allow-list Supabase TEST, assetlinks/AASA; R02/R03 cold/warm/login/logout/revoca |
| Address owner / endpoint e Maps |adapter implementati, nessun endpoint implicito; fornire solo riferimento al servizio approvato e chiavi native ristrette già disponibili |ADDRESS_PHOTON_ORIGIN/ADDRESS_PROVIDER_APPROVED/ADDRESS_SEARCH_ENABLED; ADDRESS_MAPS_ENABLED e probe nativo; ADR014 e R05/R26 |
| Mobile/release owner / firma e canale |inventario rileva iPhone e1identità, ma input dedicati assenti; associare configurazione approvata al bundle com.xniw.clientmerchandisecontrol senza creare nuove credenziali |IOS_EXPECTED_TEAM_ID,IOS_EXPECTED_SIGNING_CERT_SHA256,IOS_RELEASE_RUNTIME_CONFIG_PATH e riferimenti App Store Connect; equivalenti Android nel runbook. Preflight, ricevuta upload e smoke fisico restano prove distinte |

L'autorizzazione all'apply e al merge è già nel mandato: i limiti qui sono prerequisiti
tecnici o risorse esterne, non nuove richieste generiche di consenso. Il runbook
distribuzione attuale richiede inoltre un backend conforme; non si indebolisce il gate
per caricare un artifact. Online payment e push restano con adapter non configurati
secondo le decisioni precedenti; nessuna attivazione implicita.

## Registro storico del primo audit (superato dal mandato operativo)

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
della fixture storica nel test di governance e l'aspettativa della fixture firma
Android rispetto al nuovo preflight; il runtime resta quello di6353c9b. Baseline493c2c9;
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

La run36462598679 ha poi rilevato un'aspettativa obsoleta della fixture Android:
firma e input Play sintetici validi non bastano più a emettere la ricevuta di upload.
Il preflight rifiutava correttamente ANDROID_RUNTIME_CONFIG_MISSING. La fixture ora
verifica firma v2-only/SIGNED, rifiuto esatto e assenza della ricevuta upload; conserva
tutti i casi avversariali precedenti. Sintassi shell PASS; prova artifact nella CI finale.

Review distinta NOT_RUN: nessun reviewer inventato né approvazione dell'autore.
Il task è BLOCKED in EXECUTION perché manca acceptance runtime e una review distinta;
non viene consegnato come review-ready e non passa a DONE. I prerequisiti sopra e le
due prove golden locali restano aperti anche se la CI di build risulta verde.

Evidence completa locale non versionata: `~/.codex/outputs/client-functional-audit/`.
Il manifest locale associa log sanitizzati ai file con SHA256; il candidato typegen
Admin rimane separato e non applicato. Nessun processo locale di verifica irrisolto.

Ricevuta unica del mandato corrente: [CLIENT_TASK054_NEXT_INTEGRATION_RESULT.md](CLIENT_TASK054_NEXT_INTEGRATION_RESULT.md).
