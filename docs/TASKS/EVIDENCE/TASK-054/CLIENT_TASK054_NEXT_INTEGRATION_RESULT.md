# CLIENT_TASK054_NEXT_INTEGRATION_RESULT

Ricevuta del mandato del 2026-10-04. TASK-054 resta aperta; TASK-055 e production
non attivate. Il delta di sviluppo viene valutato separatamente dall'accettazione
live obbligatoria. Stato di questa ricevuta: candidato BLOCKED/REVIEW, review del delta e CI
correnti da completare; nessun merge anticipato.

## Provenance e ownership

Baseline Client main `bfbfc0b6a7122f29b8d8f6e2c2263d77b252749c`, PR28 già
integrata. CI main36946491646 verificata sullo SHA esatto: cinque job e73step
riusciti, attempt2; è baseline e non prova del nuovo candidato.
Worktree writer `task054-next-integration`, branch `codex/task054-next-integration`.
Il checkout originario resta `8423c868` con `supabase/` untracked preservato.
Owner N governa TASK143/144 e le nuove patch recovery; owner W governa Mini/Worker
TASK159. I loro checkout dirty/staged e dispositivi autenticati non sono stati usati.
Le lane locali pesanti restano sotto coordinamento N. Review Client e review
backend/CI sono assegnate a sessioni read-only distinte dai writer.

Fonti durevoli: [backlog unico](residuals.md), [acceptance invariata](acceptance-revision.md),
[backend](next-integration/backend.json), [package minimo](next-integration/canonical-delta.json),
[catalog parity](next-integration/catalog-parity.json), [SQL](next-integration/sql-validation.json),
[recovery locale](next-integration/local-recovery.json), [config](next-integration/config-distribution.json),
[Auth e backup](next-integration/auth-recovery.json), [Worker](next-integration/worker-runtime.json),
[main native](next-integration/native-main.json).
Log completi, package SQL e artifact locali restano fuori Git in `build/task054/`;
le tre sorgenti SQL canoniche rimangono nella main Admin indicata sotto.

## Delta funzionale riprodotto e corretto

- Inbox: lo stato vuoto del filtro non lette distingue pagine ancora da caricare,
  cache offline e risultato esaustivo. Indica il prossimo passo con testi nelle quattro
  lingue. Errore di una pagina mentre la lista è pronta: banner visibile e retry,
  con stesso cursor, dedup e cache completi. Nessun auto-fetch o cambio contratto.
- Prodotto: badge fulfillment consentono reflow a320px/200%, mantenendo le etichette
  complete. Il test corretto sulla baseline riproduce6FAIL/2PASS; dopo fix8/8PASS.
- Harness di produzione con repository sintetici: Home/catalogo/prodotto/carrello
  compatti nelle quattro lingue, inbox paginata/cache/denial, recensioni con busy,
  errore/retry/modifica/cancel e tracking testuale fresco/stale con GoogleMaps OFF.
  Nuovi22casi host PASS/exit0 sul delta completo, verificati autonomamente dal
  reviewer; sette casi impattati PASS nella lane writer distinta.
  Assistenza esercita tre allegati, submitbusy/timeout/draft/retry con stessa chiave
  e upload parziale; focus recensione è una prova Flutter. Aggregate65casi/103PNG
  attesi: catture native da associare al freeze; nessun pickerOS/IME dichiarato.

| Comando / tipo | Risultato reale | Limite |
|---|---|---|
| `flutter test` suite inbox | PASS,40,exit0 | Widget/controller con repository sintetici |
| `flutter test` fulfillment + product screen | PASS,19,exit0 | Quattro lingue, light/dark,320px/200%; warning di tap in test preesistenti conservati |
| `flutter test build/task054/next/host_next_integration_test.dart` | PASS,22,exit0 | Host widget; warning plugin integration non rilevato, non native |
| `flutter analyze` | PASS,exit0 | Analisi del sorgente corrente; due filename info dei helper locali corretti, nessuna esclusione |
| `bash scripts/check-governance-state.sh` | PASS,exit0 | Iniziale FAIL5 per snapshot README/worklog incompleto, corretto |
| Gate completi / benchmark / CI nuovo candidato | NOT_RUN | Run remoto sul candidato congelato in preparazione |

I fallimenti iniziali di compile e harness sono conservati nei log locali: variabile
in scope errato, tap sotto AppBar/viewport e teardown semantics tardivo sono stati
corretti e rieseguiti; non sono presentati come difetti di produzione. Nessuno skip,
aumento di timeout/target iOS o rigenerazione golden per ottenere verde.

RunnerAndroid aggiunto nel job debug esistente: API35/x86_64/KVM, AVD isolato,
readiness e cleanup bounded; conserva5job/25min/drive900, security e checkoutSHA.
14regressioni Android e11visual runner PASS/exit0. Conta103PNG completi; artifact
parziale non attesta successo. TempoCI da misurare; nessuna inflation di budget.

## Backend TEST e package minimo

Target `jpgoimipbothfgkokyvm`, PostgreSQL17; snapshot readonly del 2026-10-04
19:11–19:27UTC. History155, latest`20261002180757`:32/55RPC compatibili,1/2indici.
Il gate metadata è **FAIL/exit1** per23RPC, tre migrazioni e indice safe-dedup
assenti; le32RPC presenti non mostrano altro drift nei campi verificati. Non è
un gate autenticato PostgREST o PostgreSQL TLS del Client.

Fonte Admin main`82af13ef0005ecfb767809bd362327e91692b5ba`,158sorgenti.
Package minimo byte-identico, ordine:

1. `20260823023037_client_commerce_journey_v1.sql` — SHA256`741faa0f2d5480e9a38e29216555c182043234a3d8aec784f642e716e5da66cc`.
2. `20260823150000_customer_after_sales_order_lines_v1.sql` — SHA256`18fbab7904dcecd901e9237b03164db7dd84f9e3e67619eeb19eccc2a2b55467`.
3. `20260928200000_customer_notification_hold_dedup.sql` — SHA256`818d6d98976da46676ab2bfff20759cea50666d932d950346e324af630256b8e`.

Package16check PASS/exit0 e negativa bytechange respinta/exit1. Indice riconcilia
154versioni dirette più alias TASK142. Mapping prezzi sorgente`20261002002517`
→ receipt`20261002005414` PASS: renameR100, byte identici, SHA256
`54bc73e0dcbd4bd1d4323989b3bce6dc1c528117fe45509c35b5301243d8474a` e
MD5receipt`866a0d5e0e794e929ece2b0fcac1b447`. Non rinominare sorgenti applicate,
non replayare history e non applicare tutta main. Otto receipt storiche con rawMD5
diverso e130receipt multi-statement restano NOT_RUN per equivalenza del contenuto
remoto; i16check del package non attestano il contenuto di tutte155migration.

Clone locale schema-only più otto delta: otto fingerprint uguali allo staging
corrente (615funzioni,120tabelle,1616colonne,1014constraint,458indici,155trigger,
86policy,5view). È una verifica metadata, senza dati remoti. Nel clone:
23suite/1035assertion PASS; manifest55RPC/2indici/history158 PASS snapshot-only;
recovery155→158→155 PASS con155receipt **sintetiche** e sei digest di righe
sintetiche identici. Due negative atomiche respinte/exit3; Storage SQLDELETE
respinto/exit3, cleanup API200 e readback400/body404, zero bucket/oggetti.
Dry-run CLI locale propone esattamente tre migration/exit0.

Apply condiviso **BLOCKED**: quattro cron commerce attivi, nessuna finestra writer
attestata, backup remoto null/PITRfalse e servizioPGTLS assente. Nessuna scrittura
remota eseguita. Due container propri rimossi/exit0, nessun processo pendente.
La prima migrazione crea un indice ampio: collision scan iniziale zero gruppi va
ripetuto nella finestra, prima dell'apply; snapshot19:26 non esclude writer successivi.

## Config, Admin runtime e authoring

Config storica originale esiste ma viene respinta dal parser corrente (1testPASS):
shop/host verificato assenti e GoogleOFF; file preservato. Nessun riferimento
corrente a config artifact TEST, pilota/shop o servizio `CMC_BACKEND_PGSERVICE`
readonly con TLSverify-full. Gate `--live` reale **BLOCKED/exit2**. ManagementAPI
Auth GET PASS200: Google attivo e17redirect, ma callback HTTPS approvata,
AASA/assetlinks e pilota non referenziati; **AUTH_LIVE NOT_RUN**.

Worker TEST versione`22107a6f-f515-44c4-8392-a8e5653ff0b8`,100%, deployment
`f726de06-fb79-46f5-a1b3-1d35fdc9de69`,2ottobre16:44UTC, backend TEST corretto.
Annotation`1f0679b261dde089800a3bdef7888c1f7a7b8014` è un **tree Git**, non un
commit: corrisponde al tree selettivo della lane W, base`22158297`, non main82af.
`step="any"` già presente. Mancano sette file commerce della main:
`shop/after-sales/actions.ts,page.tsx`, `shop/reviews/actions.ts,page.tsx` e i tre
server `customer-commerce-evidence.ts`, `customer-commerce-mutations.ts`,
`customer-commerce-read-model.ts`. CI main37176343496 buildPASS, deploySKIPPED.
Legame byte build→Worker **NOT_RUN**: owner W deve consegnare ricevuta e delta
selettivo concordato, senza deploy implicito di tutta main o toccare i cinque staged.

Authoring Android/iOS e immagini hanno implementazione; R24 live **NOT_RUN**.
Main Androidfe0927c3 e iOS433e7daf verificati autonomamente con CI, job/step e
hash:1127PASS/7SKIP e1442PASS/36SKIP rispettivamente. Non attestano la nuova
patch recovery di N. Primario iOS corrente è Desktop/iOSMerchandiseControl;
Projects/iOSMerchandiseControl è storico. Catena da eseguire in entrambe:
create/edit prodotto → camera/galleria → compressione/upload/adopt → publish →
Admin pubblico → Client stesso `publicationId`, prezzi/stato/immagini, replace/remove,
retry/idempotency. Correlare localID→sourceProductIdUUID→publicationId=Clientproduct.id,
con versioni separate. Non equiparare ID inventario e ID pubblicazione.

## Acceptance R01–R30 preservata

Tutti i casi seguenti mantengono titoli, setup/teardown e criteri della revisione
[acceptance-revision](acceptance-revision.md). Ogni **NOT_RUN** indica E2E completo;
prove deterministiche e native fixture sono separate. L'audit E2E-01…25 originale
rimane invariato e non viene ricostruito dalla nuova matrice.

| Caso originale | Piattaforma | E2E completo | Prerequisito / motivo |
|---|---|---|---|
| E2E-054-R01 — Ingresso guest e capacità effettive | Android e iOS | NOT_RUN | P1 + P2 |
| E2E-054-R02 — Sessione e callback del provider | Android e iOS | NOT_RUN | P1 + P2 + P3 |
| E2E-054-R03 — Logout, revoca e A→B→A con richieste in volo | Android e iOS | NOT_RUN | P1 + P2 + P3 |
| E2E-054-R04 — CRUD indirizzo e default | Android e iOS | NOT_RUN | P1 + P2 + P3 |
| E2E-054-R05 — Ricerca, resolve, reverse e pin | Android e iOS | NOT_RUN | P1 + P2 + P3 (provider già approvato) |
| E2E-054-R06 — Delivery/pickup e concorrenza contesto | Android e iOS | NOT_RUN | P1 + P2 |
| E2E-054-R07 — Zona, slot, costo e contesto stale | Android e iOS | NOT_RUN | P1 + P2 |
| E2E-054-R08 — Carrello guest persistente e merge | Android e iOS | NOT_RUN | P1 + P2 + P3 |
| E2E-054-R09 — Prezzi, disponibilità e rimozioni | Android e iOS | NOT_RUN | P1 + P2 |
| E2E-054-R10 — Checkout pickup v2 | Android e iOS | NOT_RUN | P1 + P2 + P4 |
| E2E-054-R11 — Checkout delivery v2 | Android e iOS | NOT_RUN | P1 + P2 + P4 |
| E2E-054-R12 — Hold concorrenti, scadenza e notifiche | Android e iOS | NOT_RUN | P1 + P2 |
| E2E-054-R13 — Idempotenza ordine e risposta persa | Android e iOS | NOT_RUN | P1 + P2 |
| E2E-054-R14 — Kill/restart e ambiguità | Android e iOS | NOT_RUN | P1 + P2 |
| E2E-054-R15 — Metodi pagamento previsti e OFF | Android e iOS | NOT_RUN | P1 + P2 |
| E2E-054-R16 — Ordini, stati, timeline e cancellazione | Android e iOS | NOT_RUN | P1 + P2 + P4 |
| E2E-054-R17 — Tracking e indisponibilità provider | Android e iOS | NOT_RUN | P1 + P2 |
| E2E-054-R18 — Inbox, filtri e paginazione | Android e iOS | NOT_RUN | P1 + P2 |
| E2E-054-R19 — Consenso e deep link proprietario | Android e iOS | NOT_RUN | P1 + P2 + P3 |
| E2E-054-R20 — Riordino e conferma differenze | Android e iOS | NOT_RUN | P1 + P2 |
| E2E-054-R21 — Assistenza righe ordine e Admin | Android e iOS | NOT_RUN | P1 + P2 + P4 |
| E2E-054-R22 — Recensioni verificate e moderazione | Android e iOS | NOT_RUN | P1 + P2 + P4 |
| E2E-054-R23 — Ricerca assistita e deep link | Android e iOS | NOT_RUN | P1 + P2 |
| E2E-054-R24 — Authoring operativo e visibilità pubblica | Android e iOS | NOT_RUN | P1 + P2 + P4 + P5 |
| E2E-054-R25 — Reconnect e isolamento trasversale | Android e iOS | NOT_RUN | P1 + P2 + P3 |
| E2E-054-R26 — Fallback indirizzo e GPS | Android e iOS | NOT_RUN | P1 + P2 + P3 (provider già approvato) |
| E2E-054-R27 — Pagamento provider sandbox | Android e iOS | NOT_RUN | P3; provider OFF resta OFF, nessuna nuova attivazione |
| E2E-054-R28 — Push provider e cold/warm link | Android e iOS | NOT_RUN | P3; provider OFF resta OFF, nessuna nuova attivazione |
| E2E-054-R29 — Artifact, firma e ambiente distribuito | Android e iOS | NOT_RUN | P6 |
| E2E-054-R30 — Smoke nativo e superfici visuali | Android e iOS | NOT_RUN | P7; native fixture separata dal live |

| Codice | Risorsa minima / owner |
|---|---|
| P1 | Backend/release e AdminTASK159: recovery fresca DB/Storage e finestra senza writer/cron; poi apply delle sole tre canoniche e verifica55/2/history158 |
| P2 | Owner Client: config artifact TEST corrente e fixture shop/owner sintetici autorizzati, manifest ID/run e cleanup |
| P3 | Owner Auth/provider: HTTPS callback approvata, AASA/assetlinks, allow-list e pilota; riferimenti, senza segreti nelle evidence |
| P4 | W/AdminTASK159: sorgente e ricevuta build del Worker selettivo con commerce Admin e operator fixture |
| P5 | N: artifact native corrente e finestra coordinata, recovery terminale/continuità provate, authoring e immagini live |
| P6 | Release owner: Team/certificati/config firmati, canale interno e API già approvati; dispositivi utilizzabili |
| P7 | CI fixture Android/iOS per capture; OSIME, TalkBack/VoiceOver e contrasto completo richiedono esecuzione dedicata |

Ogni run live usa namespace sintetico univoco, ownerA/B e shopS/T autorizzati,
manifest fuoriGit0600, timestamp, SHA/config/OS, payload/RPC, assert e cleanup
idempotente con rilettura zero residui e conteggi preesistenti invariati. Audit
append-only conserva retention autorizzata. Non usare record esistenti come pilota.

## Matrice CA → evidence / T → risultato del freeze

| CA / test | Evidence effettiva | Risultato / limite |
|---|---|---|
| CA-N1 / T-N1 | BaselinePR28/mainCI36946491646, native-main.json, Worker/config receipt e ownerN/W riconfermati | PASS riconciliazione; nuova patch N in esecuzione, non attestata |
| CA-N2 / T-N2 | backend.json, canonical-delta.json, catalog-parity.json, sql-validation.json, local-recovery.json | PASS package/metadata/locale; runtimeFAIL32/55,1/2; applyBLOCKED P1/PGTLS |
| CA-N3 / T-N3 | test customer_notification_unread_filter_test.dart e suite inbox40, quattro lingue200% | PASS widget; liveR18NOT_RUN P1/P2 |
| CA-N4 / T-N4 | task054_next_integration_surfaces_test.dart,22hostPASS;65native/103PNG attesi | PASS host; nativeNOT_RUN al freeze, OSIME/screenreaderNOT_RUN |
| CA-N5 / T-N5 | runner25PASS, analyze/security/governance; reviewer distinti e CI da associare | NOT_RUN finale: runCI/review sullo SHA congelato pendenti |
| CA-N6 / T-N6 | Matrice R01–30 invariata, backlogNI054 e questa ricevuta con risorseP1–P7 | PASS rendiconto; acceptance liveNOT_RUN, firma/fisiciBLOCKED |

## Livelli di prova e stop condition

| Livello | Esito corrente | Perché |
|---|---|---|
| CODE | PASS sui gate mirati; suite completa NOT_RUN | Fix e widget reali, candidato completo da CI/review |
| BACKEND_RUNTIME | FAIL metadata; apply BLOCKED |32/55RPC,1/2indici; clone non attesta runtimeTEST |
| STAGING_E2E | NOT_RUN | P1/P2 e prerequisiti per caso |
| AUTH_LIVE | NOT_RUN | P3; GoogleManagementGET non prova login |
| AUTHORING_CHAIN | NOT_RUN | P4/P5 e catena entrambe le piattaforme |
| ADMIN_STAGING | NOT_RUN per commerce corrente | Worker identificato ma versione selettiva incompleta |
| UI_VISUAL_QA | PASS widget22; capture nuovo candidato NOT_RUN | Fixture esplicite; OSIME/accessibilità globale NOT_RUN |
| PHYSICAL_DEVICES | BLOCKED | Android fisico assente; iOS deviceprep-27, disponibile0 |
| DISTRIBUTION | BLOCKED | Team/certificati/API/canali/config artifact non referenziati |
| MAIN_INTEGRATION | NOT_RUN nuovo delta | DraftPR, review e CI da completare |
| PRODUCTION | NOT_RUN | Fuori scope, non attivata |

Nessun account/provider nuovo, spesa o privilege expansion. I blocker dipendenti
non fermano i fix/harness/review di sviluppo. TASK054 non diventaDONE e non si
attivaTASK055. Prima dell'handoff finale: esito reviewer, CI exactSHA, receipt
capture/benchmark, merge autorizzato soltanto con gate verdi, stato worktree e
assenza processi pendenti. Gli eventuali risultati del freeze saranno aggiunti a
questa stessa ricevuta, conservando fallimenti e limiti già osservati.
