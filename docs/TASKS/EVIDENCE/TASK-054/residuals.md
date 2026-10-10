# TASK-054 — Registro unico dei residui operativi

## Stato corrente — attivazione TEST, mandato8da5e50f (10 ottobre)

Questo overlay prevale sulle fotografie storiche. Codice DB revisionato, esperimento
iOS terminale; release TEST source revisionata, unsignedf513 PASS; Quality8fc PASS1095/1SKIP+11performance,23step terminali. Unica richiesta owner già inviata, riferimenti
nel manifest protetto `task054-activation-20261008/operator-reference-manifest.prepared.json`.
CA e autenticazione Cloudflare recuperate; dataset/pilota generabili da Codex.
Review distinta dell’attivazione **BLOCKED / CODEX_REVIEW_BLOCKED**, zero finding
aperti; [verbale](next-integration/activation-integrated-rereview.md). I gate
obbligatori del registro restano non superati; nessun APPROVED o merge inferito.

Rollout POS esterno verificato sourceacb3e4ac/PR133/run38083172469→Workerfdfb3a7e
servito100%. Catalogo20:49:33UTC:history158, tre nuove versioni POS; prefisso155
version/name e ultimo statement coincidono, senza confronto di tutti i dati/statement.
Le quattro canoniche Client restano assenti; nuovo postapply atteso162 se invariato.
[Provenienza](next-integration/activation-external-worker-source.json),
[readback](next-integration/activation-external-worker-readback.json),
[lineage](next-integration/activation-external-worker-lineage.json).

| Residuo / stato | Causa concreta | Lavoro preparato e dipendenze pertinenti | Singolo prossimo intervento / owner |
|---|---|---|---|
| Connessione PG readonly / NOT_RUN | Endpoint Session pooler ufficiale e auth protetta assenti; nessun handshake tentato | Trasporto0cec105 APPROVED_SOURCE_CODE_ONLY,30 test; CA ufficiale e service pronti | Owner riferisce host da Connect e passfile del ruolo readonly; root genera metadata target-bound ed esegue connection-only |
| Procedura apply TEST / BLOCKED | MCP postgres metadata disponibile, ma apply_migration non espone le quattro versioni canoniche; serve il distinto canale PG operatore | Quattro SQL esatti, recovery popolata PASS; driver825ae0 e batchdb17d17 approvati R2 scoped, commit SQL/history separati e pending durevole | Owner indica endpoint ufficiale e service/passfile PostgreSQL operatore autorizzato, separato dal readonly; root esegue verifier e prepara recovery/finestra effettive |
| Finestra/snapshot/cron / NOT_RUN | Nessuna finestra corrente: fotografia22:55 non prova esclusione | Job1/2/3 pertinenti;4 escluso senza interferenza; snapshot di recovery da rinnovare; nessuna pausa app globale | Root+W fissano inizio/fine e writer reali, coordinano eventuali dispatcher concreti rilevati, poi pause/drain/restore dei soli cron pertinenti |
| Schema finale / FAIL | Delta atteso32/57,1/2,history158 dopo3DDL POS;25 RPC+4 canoniche+1 indice assenti | Confronto delta atteso PASS, nessun drift inatteso nel contratto;57/2/162 richiesti dopoapply se nessun altro cambio; recovery/profilo da rinnovare | Root riconcilia baseline158 e recuperabilità corrente, applica quattro canoniche attraverso canale qualificato e verifica manifest+RLS/helper/ledger completo |
| Worker TEST / BLOCKED per candidato Client | Rollout POS acb3e4ac→fdfb3a7e sostituisce pin22107a6f; candidato96758b89 non distribuito | Provenienza CI/versione servita PASS scoped; evento secret distinto; vecchio piano/bundle/rollback restano storici, MiniC04 non qualificato | Owner Worker+root/W riconciliano nuova baseline e preservano delta POS prima di un futuro upload; richiedono schema pertinente e finestra reale, nessun rollback storico automatico |
| Recensione/journal/smoke iOS / BLOCKED; buildlocale FAIL | Hosted26.5 postbootinventoryFAIL124; locale3f8 PrepareheadlessPASS ma SDK27 minimum15 confligge target14 primaapp | Runner3f8 sourceAPPROVED/50test; wrapper20reviewchecks; native68.059s, cleanupPASS,6dependentNOT_RUN/0PNG, fidelity26+13PASS | Owner indica Mac/runner esistente autorizzato con SDK compatibile con14 e runtime26.5; nessun target14 rialzato o retry invariato |
| Percorso Client base / BLOCKED | Riferimento Google TEST A, hostHTTPS controllato e accesso operatore pilota assenti | Config pubblico recuperato; Codex genera pilota cmc054r-20261008-pilot/dataset minimo nel TEST già autorizzato | Owner fornisce riferimenti A/domain/accesso; root completa config e primo percorso disponibile, senza attendere B o provider facoltativi |
| Isolamento A→B→A / NOT_RUN | Identità Google TEST B assente | Fence/race locali acquisiti; B non blocca il primo percorso A | Owner rende disponibile B quando si attraversa l'isolamento reale |
| R04/R25 e R13/R14 / BLOCKED | Backend/sessione/config per commitserver-rispostapersa mancanti | Journal indirizzi Android locale PASS; checkout recovery separato, nessun PASS reciproco | Root esegue indirizzo e ordine distinti sul Client autenticato, stesso intento/oggetto e nuovo PID |
| R24 Android / NOT_RUN | N riferisce SaveA locale;1riga/2prezzi remoti al readback00:28:52UTC, OwnHTTPACK non provato e peerA0; pilota/Client e catena completa da qualificare | N riferisce mainbbbda83, CI1250/7SKIP, APK74e75 installato preservando dati | N qualifica write-authority/scope e convergenza proprio candidato; poi nuova catena correlata fino al Client, nessuna ricerca ACK storico |
| R24 iOS / NOT_RUN | NCloudconnected; Retry500/STATEMENT_TIMEOUT; primoSaveB locale riferitoPASS/3pending senza lastAttempt, remotoB assente al solo00:28:52UTC; ACK/Client da qualificare | Nmainb869c9b/Proper2cb5de; catalogoreadonly23:40 confirma page→scoped_rows/marker→checkpoint, defaults8s, noRPC/piano inferito | N qualifica recovery/writeauthority e nuova catena separata; dipendenza backend distinta dalle4canonicheStorefront |
| Preflight distribuzione / PASS source scoped; unsignedPASS; Quality8fc PASS | Mismatch production-only riprodotto e corretto; due P2 chiusi da re-review | Nuovo --test, marker9chiavi, AAB/APK e callback verificati nei test; defaultproduction preservato; run38001393798 terminale1095/1SKIP+11performance | ArtifactTEST firmato e hosted association restano prove distinte; il delta runner3f8 ha review+50test propri |
| Firma/installazione Android / NOT_RUN | Riferimento signer/canale/destinazione Client assente | PreflightTEST APPROVED source; buildunsignedf513 PASS | Owner riferisce firma protetta e canale/destinatario Android; avanzare indipendentemente da iOS |
| Firma/installazione iOS / NOT_RUN | Team/profilo/canale/destinazione Client assenti | Preparazione TEST distinta da simulatore e installazione gestionale N | Owner riferisce canale/signing protetti iOS; non è gate per DB/Worker |
| Tracking base R17 / BLOCKED | Ordine TEST, owner e timeline non qualificati | Fallback/stale locali PASS; provider OFF non impedisce il percorso base | Root verifica lettura tracking e isolamento owner sul primo ordine TEST disponibile |
| Provider R05/17/26/27/28 / NOT_RUN | Mappe/GPS/FCM/APNs/online provider OFF | Manuale, fallback testuale, payAtPickup/cashOnDelivery restano percorso base | Collegare solo l'input necessario alla specifica prova provider; nessuna dipendenza universale |
| AT/UX/profiling reale R30 / NOT_RUN | Superficie/sessione finale non disponibile | Android f326 delta73Flutter+4OS reviewscoped;64riusi storici; host11benchmark e500→5/5→5/20→20 | Eseguire AT/focus/200% e tap/frame/memoria sulla prima superficie Client disponibile |
| Notifiche orfane / FAIL integrità | Due notifiche/otto riferimenti mancanti già diagnosticati | Migration e list/markread PASS locale; orphan non impediscono schema; repair separato | Owner autorizza soltanto eventuale repair con provenienza e snapshot; nessun repair ora |

R01–R30 e25 E2E storici restano invariati; R24 ha due origini. Il rapporto corrente
[CLIENT_TASK054_NEXT_INTEGRATION_RESULT](CLIENT_TASK054_NEXT_INTEGRATION_RESULT.md)
contiene la matrice per requisito e i limiti delle prove. Nessun DONE, merge Client,
produzione o task successivo.


Mandato successivo del 2026-09-28; stato iniziale PR27 0990c80. Le prove storiche
sono in README/validation/backend-reconciliation; qui si registrano solo le azioni
successive. PASS richiede comando/output/exit e revisione identificata.

| Requisito | Evidenza iniziale | Causa | Azione | Dipendenze | Test | Risultato | Owner |
|---|---|---|---|---|---|---|---|
| Backend55 RPC | 32 presenti/23 assenti storico | due migration mancanti | metadata fresco, recovery, apply condizionato e ruoli | recovery accessibile, finestra senza writer | gate + pgTAP + staging sintetico | recovery combinata PASS:147→150→147, ACL/dati fixture identici, Storage API cleanup; apply condiviso BLOCKED finestra writer | root/backend reviewer |
| Notifiche hold | collisione riprodotta dal reviewer su VALUES | indice nuovo perde identità hold | migration correttiva canonica e regressione | Admin isolato; conteggio collisioni remoto | due hold/same owner + permessi | PASS locale41/41 dopo fix; test41 FAIL prima | root |
| Typegen Admin | patch SHA123242ea, compilazione precedente parziale | null semantici non coperti | integra tipi mirati + test nullable | coordinamento TASK159 | tsc positivo/negativo + foundation | PASS tsc/nullable; PR117 merged6d5, review distinta APPROVED e CI PR/main verde; mainf213 ancestry verificata | root |
| OAuth attivabile | hard refusal e binding assenti | config sentinel-only | config validata, callback native, gate e test | dominio/allow-list approvati per live | positivi/negativi, session race | PASS112 config/auth/address; live NOT_RUN | root; owner dominio per live |
| Provider indirizzi | tre adapter NotConfigured | implementazione mancante | adapter concreti con gate e fallback | configurazione provider approvata per live | transport e widget | PASS12 provider/editor mirati; native map live NOT_RUN | root |
| Lifecycle analoghi | account/order/search ipotesi precise | generation incompleta | riproduci e correggi delta minimo | nessuna esterna | Completer, A-B-A, dispose | PASS 23/23 mirati; tre FAIL prima | root |
| Editor indirizzo | pin vecchio dopo edit testo | metadata conservati | invalida geografia modificata | nessuna | widget sintetico | PASS nel gruppo12 provider/editor | root |
| Golden | 6/18 pixel anche baseline, tracking Linux return | raster e falso pass | baseline mirata dichiarata e confronto richiesto | runner riproducibile | ispezione diff + real compare | PASS2 confronti macOS27 e2 su macOS26 CIecba981; CI4c3e71b in corso | root/reviewer Client |
| iOS14 / Android smoke | Xcode27 incompatible; Gradle timeout storico | toolchain | ambiente/config supportata e smoke entrambi | toolchain/device disponibili | build e interazione separate | Android build+smoke PASS; CIecba981 iOS build PASS/smoke timeout; fix runner4c3e71b e5negative reviewer PASS; nuova CI in corso | root |
| Acceptance nuova | ID storici senza definizioni | provenance irrecuperabile | E2E-054-R con fonti e subflussi | review; staging/provider per live | matrice + assert reali |30 casi R01–R30 definiti e revisionati come piano; end-to-end NOT_RUN | root/reviewer |
| Gate/benchmark/release | CI0990 storica verde | nuovo candidato necessario | focused poi gate completi, review, merge normale | gate applicabili verdi | CI SHA, benchmark10, main ancestry | benchmark10/resilience70 PASS; re-review133test e13gate PASS; CI finale in corso | root/reviewer |
| Dispositivi/distribuzione | guest smoke simulatore soltanto | prerequisiti esterni | verifica riferimenti già approvati e azioni condizionate | firma/canale/device approvati | ricevuta/installazione/ambiente | iPhone e1identità rilevati; runtime/firma/canale approvati non attestati, NOT_RUN | root/owner |

Production: **NOT_ACTIVATED**. Nessun PASS locale equivale a staging/provider live.


Fix della review distinta: C-01 probe mappa nativo, C-02 epoch inbox su revoca,
C-03 purge/epoch delivery preview/select, B-04 migration e indici obbligatori nel gate.
Tutti chiusi sui test indipendenti del runtime ecba981; nessun nuovo P0/P1/P2 rilevato.
CI/merge correnti e dipendenze esterne con parametri/owner sono nel README canonico.


## Overlay funzionale e UX — 2026-10-01

[Rapporto corrente](functional-ux-operational-result.md) e
[preflight fresco](metadata-preflight-20261001.json) governano la nuova run.
Runtime32/55RPC,1/2indici ehistory147 invariati; applyBLOCKED e gateTLSexit2.
Fix riprodotti: reflow recensioni/badge, motivo/dropdown assistenza, delivery/pickup,
filtro non letteR18, heading inbox e CTA Cart offline che propagava eccezione.
Android nativo fixture41test/55PNG exit0; quattro locale12accessibilitàPASS.
CI/review/newmerge al freezeNOT_RUN; snapshot storici non riscritti.
Tutti25ID E2E storici e30casi compositi R conservati; nessun PASSlive inferito.

## Overlay NI054 — mandato del 2026-10-04

Baseline sviluppo Client `bfbfc0b6`, PR28 integrata. Questo è l'unico backlog del
mandato corrente; R01–R30 e i 25 E2E storici conservano definizioni e provenance.
Le lane native N e Mini W restano owner dei rispettivi fix; nessuna seconda patch.

| ID / requisito | Classificazione | Impatto / causa o ipotesi | Repository / owner | Dipendenze | Intervento minimo / prova di chiusura | Esito corrente |
|---|---|---|---|---|---|---|
| NI054-01 / R18 | Difetto riprodotto | Filtro vuoto riusa “nessuna notifica” mentre il server ha unread in pagine successive; cache offline incompleta | Client / root | Nessuna esterna | Titolo e messaggio parziali, CTA pagina conservata; cursor/dedup/cache e4locale200% | PASS test mirati; live NOT_RUN |
| NI054-02 / R18 | Difetto riprodotto | Errore transitorio loadMore conservava ready e non mostrava feedback; il tap sembrava senza effetto | Client / root | Nessuna esterna | Banner errore, retry stessa pagina; dati/filtro/cursor conservati | FAIL iniziale, PASS40test inbox; live NOT_RUN |
| NI054-03 / R30 | Difetto riprodotto | Badge fulfillment dettaglio prodotto320/200%: Row con label non flessibile, overflow ES/IT/EN | Client / root | Harness visuale separato | Reflow della sola etichetta,4locale light/dark e dettaglio | Baseline6FAIL/2PASS; dopo8PASS e19testprodotto PASS; native finale pendente, nessun beforePNG ricostruito |
| NI054-04 / R01–R30 | Configurazione/attivazione TEST mancante | Metadata fresco:32/55RPC,1/2indici,registry155; source canonica158 | Admin/Supabase / backend owner | Recuperabilità corrente DB+Storage ed esclusione writer/cron | Sole3canoniche in ordine, package hash-bound; poi apply e ruoli reali | Package16check/1035SQLassertion/recovery sinteticaPASS; metadataFAIL; applyBLOCKED |
| NI054-05 / R24 | Implementazione presente ma prova mancante | Authoring/camera/galleria/publish implementati; nuovo recovery N ancora FIX | Android/iOS / N; Admin + Client | Candidato N stabile, pilota/shop TEST e runtime verde | Ricetta e mapping sourceProductId→publicationId; ricevute separate authoring/consumo | Contratto PASS lettura; catena NOT_RUN |
| NI054-06 / R02–R04 | Configurazione TEST mancante | Google attivo/17redirect; manca host HTTPS verificato nel contratto corrente e configshop pilota | Auth/domain + mobile release | Riferimenti già approvati, AASA/assetlinks e allow-list | Config esterna validata, cold/warm/login/revoca su entrambe le piattaforme | Parser respinge config legacy; AUTH_LIVE NOT_RUN |
| NI054-07 / R18/R21/R22/R30 | Implementazione presente ma prova mancante | Stati reviews mutation, inbox pagina/offline/revoca, tracking OFF/stale e4superfici200% non attestati | Client / visual_harness | Runtime native proprio/CI | Harness su controller/UI produzione con fixture; capture e interazioni separate |22surface+2focus hostPASS;67native/105PNG+4OS attesi, primoCIFAIL conservato; stagingNOT_RUN |
| NI054-08 / R29–R30 | Dipendenza esterna | Servizio readonlyTLS/runtime/firma/canale Client assenti; iPhone oraavailable via rete5ottobre, Android fisico assente | Backend/release/device owner/N | CMC_BACKEND_PGSERVICE, configartifact/input signing approvati e finestra | Gate live, artifact→firma→upload→install→smoke con ricevute distinte | Gate exit2BLOCKED; niente install/upload/smokeClient; deviceprep04 storico |
| NI054-09 / Admin staging | Implementazione presente ma prova mancante | WorkerTEST annotationGitTREE1f0679b2; settefilecommerceAdmin main82af assenti | Admin/release owner W/TASK159 | Ricevuta autorizzata commit→build→versione→TEST | Release selettiva concordata, preservando5staged; no deploy tutta main | Worker/versione/backend confermati; commercecorrenteNOT_RUN, richiestaownerinoltrata |
| NI054-10 / R04/R30 | Difetto riprodotto C-NI054-04/P2 | Editor account perde draft su errore remoto | Client / visual_harness | Re-review + CI del nuovo freeze | Editor async/busy/errore/retry e fence owner | ReproFAIL conservata; fix e101test account/deliveryPASS; review distinta APPROVED104/source; liveNOT_RUN |
| NI054-11 / R30 | Difetto riprodotto BECI-01/P2 | Cleanup Android lascia discendente proprio resistente aTERM | Client / android_ci_capture | Nuova CI/receipt | Verifica PGID intero e errore probe, primario preservato | PoCFAIL iniziale; re-review fixPASS23test/processreale; aggregata pendente |
| NI054-12 / R04 | Difetto riprodotto C-NI054-05/P2 | Edit ACKversion7→8 seguito da reloadFAIL consente retryversion7 | Client / visual_harness | Re-review distinta | ACK mutation distinto da refresh; nessun secondo update | PoCFAIL iniziale; a4bcba6 e regressionePASS |
| NI054-13 / R04/R06/R26 | Difetto riprodotto C-NI054-06/P2 | Tre ingressi delivery chiudono prima di write e perdono draft | Client / visual_harness | Re-review distinta | Callback ACK, draft e fonte preservati, fence owner/shop | PoCFAIL iniziale; b82108b e14screen/101account+deliveryPASS |
| NI054-14 / R30 | Difetto riprodotto BECI-02/P2 | FirmaPNG più1byte produce framePASS ma file non decodificabile | Client / android_ci_capture | Re-review runner | Validazione contenuto PNG e negative, senza package aggiunti | PoCFAIL/exit1 conservata; BECI-02 chiuso con re-review PNG31/corpus26 su39d180d |
| NI054-15 / R30 | Difetto riprodotto BECI-03/P2 | Primo segnale durante cleanupOS lascia discendente proprio | Client / android_ci_capture | Re-review runner | Deferire segnale fino a quiescenza, preservare143/130 o primario7 | PoCFAIL/exit1 conservata; BECI-03 chiuso con63scenari e PoC indipendenti su df1d26a |
| NI054-16 / R30 | Difetto riprodotto BECI-04/P2 | CallsiteAndroid/visual non pulisce PGID su uscita normale del leader | Client / android_ci_capture | Re-review runner | Finalmente verificare gruppo proprio su exit0/7 e segnali | PoCFAIL/exit1 conservata; BECI-04 chiuso con63scenari e PoC indipendenti su df1d26a |
| NI054-17 / CI | Difetto riprodotto BECI-05/P2, solo test | Fixture iOS scrive ownerContextnull ma load confronta envCI valorizzato | Client / native_chain | CI composta | Scope fixture coerente, guard production invariato | FAIL/2ERROR conservato; fix28d74aa,33CI-like/negative3PASS autonomi, findingchiuso |
| NI054-18 / R30 | Difetto riprodotto BECI-06/P2 | Cleanup iOS iniziale FAIL perso nella receipt dopo always riuscito | Client / native_chain | Re-review distinta | Persistenza failure dopo ownership valida, primario124 preservato | PoC e residuo incompleto FAIL conservati; fix9eec464/0203ce0,37CI-like e reopen PASS; re-review distinta FIXED_VALIDATED; CI3 conserva FAIL storico |
| NI054-19 / R21/R30 | Difetto riprodotto nel harness native | Tastiera/metriche riscrollano il composer e il picker non è montato al tap | Client / visual_harness | Fixture native e reviewer Client | Sincronizzazione minima e bozza intatta, nessun nuovo skip/timeout | Android d9fc un FAIL e103PNG conservati; d9da3c5 host24/2assistenza/4reflow/sentinel PASS; native da verificare |
| NI054-20 / R22/R30 | Difetto UI riprodotto C-NI054-07/P2 | Errore recensione nello Snackbar dietro il modal, non leggibile al cliente | Client / review_feedback_fix | Reviewer Client distinto | Errore locale persistente/accessibile nel dialogo; draft/rating/retry e busy invariati | PNG91/93 e PoC widget autonoma FAIL/exit1 conservati; d0e93b9 recensioni31PASS reviewer, finding chiuso; after native NOT_RUN |
| NI054-21 / R03/R22 | Difetto riprodotto C-NI054-08/P2 | Dialog recensione conserva bozza ownerA dopo expiry o signedInB e mostra failure tardiva | Client / review_feedback_fix | Re-review distinta e nuova CI | Lifecycle del solo dialog owner-scoped, regressioni sul router/AuthController reali; no refactor router | Due PoC publicroute e residui pre-mount FAIL conservati; owner/ABA feda59370PASS reviewer; cleanup P3 prima FAIL,1bf2e98 intento e subscription chiusi; reviewer72PASS/APPROVED SOURCE_CODE_ONLY; CI composta pendente |
| NI054-22 / CI/R30 | Failure runner riprodotto; correzione locale in verifica | CI4 psProbe TimeoutExpired2 prima di bootstatus e in cleanup; la prova locale identifica ps superfluo per PGID proprio già assente, non dimostra retroattivamente lo stato dei PGID CI | Client / review_feedback_fix, reviewer backend/CI distinto | Delta minimo e nuova CI exact-SHA | Kernel signal0 per assenza, ps strict2 invariato per gruppi presenti, errori failclosed e history sticky | CI4FAIL conservato;37baseline/47writerPASS,53reviewerPASS e sourceAPPROVED559/36f; CI5 boot/open e cleanupPASS; nuovo bootstatus300/124 primaFlutter, nativeNOT_RUN |
| NI054-23 / R30 | Failure harness native riprodotto | fulfillment informativo hitTestable0 esCL/it/en compatto200%; Roboto reale pinned riproduce3FAIL mentre host senza font passa | Client / visual_harness, reviewer Client distinto | Rettangoli/viewport e semantica del finder | Reveal minimo dei badge leggibili, no weakening delle azioni interattive;67casi/105Flutter/4OS invariati | AndroidCI4 64PASS/3FAIL,102Flutter/4OS parziali; effb/0c09 fix71reviewerPASS/sourceAPPROVED, nativeCI5NOT_RUN per shutdownrunner prima test/PNG |
| NI054-24 / R22/R30 | Difetto UI riprodotto C-NI054-09/P2 | Errore edit immediato conserva focus/IME; messaggio120px contro viewport60px al200%, source/hostcontrastivi e PNG90 corroborante, nessuna perdita draft | Client / root writer, reviewerClient distinto | Re-review source50a e nuova CI exact-SHA | Rilascia focus del campo solo dialog mounted/currentowner; draft/rating/CTA/retry/lateownerfocus preservati | Prima canonicoRobotoFocusTRUE FAIL1;59reviewsPASS incl30feedback; analyze/format374/security874PASS; re-review distinta APPROVED62PASS; nativeafterCI5 NOT_RUN su entrambe le piattaforme per limiti runtime/runner |
| NI054-25 / CA-N5 e QA R30 | Dipendenza esterna CI/runtime | CI5 hosted runner non acquisito per Quality/releaseAndroid; shutdown Android durante drive; iOS locationd Data Migration nonterminal al300s | GitHub/CI/release owner, reviewer distinto | Allocazione hosted stabile e toolchain/ricetta compatibile14 propria | Nessuna patch app inferita: conservare44step/3checkout+2NOT_RUN/cleanup iOSPASS e runtimecause; dopo sblocco verifica exact-SHA105Flutter/4OS | CI5terminalFAIL, re-reviewBLOCKED; locale986PASS non sostituisce native/CI; PR29draft, mergeNOT_RUN |


Le proposte UX del mandato restano da valutare, non finding presunti. Provider
indirizzi, mappe, pagamento online e push restano OFF; nessun requisito cancellato.

NI054-01–03: fix e regressioni mirate PASS; review source APPROVED, CI5 terminale nonverde e integrazione BLOCKED.
NI054-07: harness esteso67test/105PNG più4OS attesi, hostPASS; catture native, OSIME,
VoiceOver/TalkBack e contrasto globale ancoraNOT_RUN. Le restanti risorse
NI054-04–06/08–09 restanoBLOCKED/NOT_RUN secondo la ricevuta unica.


## Overlay completamento operativo — 2026-10-08

Il mandato corrente conserva tutte le definizioni R01–R30 ed E2E-01…25.
Le righe sotto aggiornano i residui pertinenti senza sostituire gli esiti storici.

| ID / requisito | Classificazione | Impatto / causa verificata o ipotesi | Owner | Intervento minimo e prova di chiusura | Stato osservato |
|---|---|---|---|---|---|
| NI054-26 / R04, R14, R25 | Difetto riprodotto | Creazione indirizzo senza identità durevole: commit con risposta persa e retry crea due righe; chiamate concorrenti non condividono risultato | Client indirizzi + Admin SQL | Nuova create/reconcile RPC, intent account-bound persistito cifrato prima invio, risposta canonica e conflitto payload; sei scenari del mandato | RED Flutter exit1; 99 test account PASS; finding indipendenti chiusi, re-review SOURCE_CODE_ONLY APPROVED; Android native restart PASS su629; iOS journal non attraversato per prepare/cleanup, live NOT_RUN |
| NI054-27 / R18, R30 | Miglioramento misurato | visibleItems.map costruisce l'intera lista; costo dopo20pagine da misurare a viewport/dataset fissi | Client inbox | Baseline25/500righe,5campioni e budget lavoro dichiarato prima fix; lazy soltanto se dimostrato | Baseline25/500config,5build; dopo lazy5config/5build entrambi,5campioni;49testPASS, performance fisica distinta |
| NI054-28 / R03, R18 | Difetto riprodotto | Tap attende markRead; mounted potrebbe non distinguere owner cambiato sullo stesso screen | Client inbox | Risposta markRead lenta, switch owner, assenza navigazione stale e destinazione accessibile | 7navigationFAIL prima;8PASS dopo push immediato senza callback navigazione tardiva; suite49PASS |
| NI054-04 / R01–R30 | Configurazione/distribuzione incompleta | Snapshot iniziale TEST155receipt e32/55RPC conformi,23assenti;3canoniche e indice assenti. Manifest nuovo57 include altre2RPCv3 e migration20261008151018 non applicate | Backend readiness | Export corrente protetto dati/history; restore applicabile, finestra writer/cron; delta canonico e gate readonlyTLS | Snapshot gate FAIL1; recovery corrente scoped quattro delta PASS, history155→158→159→158→155 e ledger v3 vuoto; integrità preesistente FAIL; live gate BLOCKED2 per riferimenti assenti; apply condiviso NOT_RUN |
| NI054-09 / Admin,R21,R22,R24 | Runtime incompleto | Worker TEST versione22107a6f invariata; sorgente commerce assente dal tree1f0679b2 distribuito | Admin worker_candidate, coordinamento W | Candidato selettivo sorgente/build/versione/TEST, nessun deploy globale; review distinta | Source96758b89, review W e verify/Next/OpenNext/29smoke PASS; packaging locale con rete negata PASS, quattro symlink qualificati e cinque riferimenti runtime NOT_RUN; Worker22107a6f invariato, deploy/live NOT_RUN |
| NI054-25 / CI,R30 | Prerequisito hosted cambiato | Actions operativo dopo incidente5ott; CI5 conservata con cause precedenti | QA CI | Un nuovo tentativo sul candidato finale, job/step/annotation e artifact reali | CI37817219242 su629:5jobPASS/1FAIL attesa VM iOS dopo build/launch; Android113+4 e journal PASS. Unica nuova CI37822118836 su e7:5PASS/2FAIL pre-app; prova direct-console non attraversata per prepare |
| NI054-29 / R03, R20, R25 | Difetto riprodotto | Sheet riordino usa mounted senza invalidazione owner/sessione; preview e risultato sopravvivono a logout/cambio account | Client flow_coverage | Tre PoC con AuthController/router reali; fence minimo e review distinta | 3 FAIL/exit1 prima; fix commit386e4b3, 7 regression scope PASS; review distinta PASS (49 verifiche aggregate) |
| NI054-30 / R03, R21, R25 | Difetto riprodotto | Form assistenza conserva stato locale/Future righe dopo invalidazione del controller | Client flow_coverage | Due PoC owner/revoca con bozza e risposta tardiva; invalidazione del solo form | 2 FAIL/exit1 prima; 7 regression scope PASS, suite65PASS prima guardmounted espliciti; review distinta PASS (49 verifiche aggregate) |
| NI054-31 / R03, R25 | Difetto riprodotto P1 | Export privato di A resta visibile dopo cambio B fra push e mount | Client account, reviewer distinto | Monitor owner prima del push, invalidazione persistente e cleanup; conferme sensibili protette dalla stessa causa | PoC reale FAIL/exit1; fix confirm/export e 7 casi realAuth dentro98account PASS; re-review distinta PASS (49 verifiche aggregate) |
| NI054-32 / R04, R30 | Difetto riprodotto P2 | La notice busy ricrea la sezione indirizzi priva di key; il guard sul vecchio opener blocca retry/Verify pur mantenendo aperto il dialogo | Client account + QA | Key stabile della sola sezione, preservando mounted/owner; UPDATE immediato→differito→successo e Verify ripetuto nella stessa route | Baseline396 e candidato568 riproducono FAIL; 2 RED permanenti→98account PASS, targeted completo e matrice9 PASS su eab76f7 |
| NI054-33 / R03, R04, R25 | Difetto riprodotto P2 | Auth reale A→B→A durante create viene coalesciata dalla identity derivata e il vecchio ACK pubblica addressSaved | Client account + reviewer distinto | Invalidazione immediata generation dal flusso Auth; nessuna invalidazione per refresh dello stesso owner; journal preservato e Verify esplicito | PoC indipendente FAIL exit1; fix edfec536, 99 account PASS con recupero stesso intent e una creazione; re-review distinta APPROVED, 36 PASS |
| NI054-34 / R30 | Difetto contratto locale | Quattro stringhe nuove cinesi nel bundle tecnico zh violano il fallback es richiesto; zh_Hans è corretto | Client l10n | Ripristinare quattro valori spagnoli e rigenerare l10n senza cambiare contratto o zh_Hans | Suite globale1042PASS/2FAIL include RED del contratto; fix bb538923, 9 writer e 9 reviewer PASS |
| NI054-35 / CI | Test del runner non allineato | Il test conta cinque job dopo l’aggiunta del sesto gate journal dedicato | Root CI | Atteso6 in bb538923 e7 in e7b194c, conservando il controllo exact-SHA per ogni checkout e i budget esistenti | Secondo FAIL globale; modifica di una riga bb538923, 9 writer e 9 reviewer PASS |
| NI054-36 / CI | Difetto riprodotto P2 nel nuovo runner | Errore inventario iOS trattato come app assente; possibile install dopo comando fallito | Client native_journal_gate, reviewer backend | Inventario riuscito e conversione plist prima di decidere l'assenza | Fix e7b194c, re-review21test+8PoC PASS; nessun finding source aperto |
| NI054-37 / CI | Difetti riprodotti P2 nel nuovo runner | Trasporto cleanup incoerente per owner; errore diagnostico maschera exit primaria | Client native_journal_gate, reviewer backend | Unico trasporto di processo; exit7/137/143 conservata anche con diagnostica fallita | Due fix e7b194c, stessa re-review21+8 PASS; nove hash associati indipendentemente al commit |
| NI054-38 / CI,R04,R30 | Verifica nativa bloccata, causa app non dimostrata | CI629: VM Service non scoperta dopo launch; CIe7 journal: postboot inventory timeout30s e probe cleanup EPERM/timeout dopo boot riuscito | QA CI, host Actions | Prova direct-console pronta; mantenere separati journal non attraversato, risorse eliminate e cleanup processi fallito | iOS journal NOT_RUN in CIe7, nessuna patch app/entitlement o aumento budget dedotto; cinque altri job PASS, compresa release iOS unsigned |

Checkpoint native Android CI629 per NI054-03/07/19/20/21/32: 76 test nativi,
113 PNG Flutter e quattro frame OS. Review distinta di25PNG+2OS senza finding
bloccanti; errori recensione/indirizzo e azioni leggibili, IME realmente visibile.
La matrice finale e7 conferma76/113+4:109PNG Flutter identici, quattro Flutter
e quattro OS mutati ispezionati nuovamente senza finding; IME visibile4/4OS.
Questa chiusura riguarda fixture e pixel Android; iOS, TalkBack/VoiceOver manuali,
provider e sessione TEST autentica mantengono i rispettivi esiti mancanti.

P2/P3/P6: riferimenti approvati per config artifact TEST, readonly TLS, fixture
sintetiche, OAuth e distribuzione ancora da confermare. Domanda mirata sui soli
riferimenti inviata all'utente; nessuna richiesta di credenziali in chat.

Correzioni/review del nuovo candidato: la prima probe host indirizzo osserva
il messaggio fuori dal viewport (bottom1458 contro400 disponibili), ma da sola
non dimostra che il cliente non possa raggiungerlo. La verifica contrastiva con focus/IME coerenti e scroll reale passa sulla baseline: nessun difetto di raggiungibilità UPDATE attribuito al codice precedente. Il nuovo feedback sending aveva invece overflow20px durante la chiusura animata IME, corretto portandolo nella zona scrollabile; matrice9 PASS. Successiva CI629: frame OS Android62 ispezionato con IME visibile, errore e azioni leggibili; prova OS iOS NOT_RUN. Gli stress con inset mantenuto dopo blur sono conservati come tali. C-OC-01/P2: ACK indirizzo malformato generava
invalidInput nel parser e cancellazione journal; PoC2FAIL. C-OC-02/P1: cambio
owner/shop/A-B-A fra tap e primo mount lasciava la bozza precedente visibile;
PoC3FAIL. Writer99GREEN dopo i fix; review autonoma chiude questi finding. Il P2 Auth in-flight corretto in edfec536 supera la re-review distinta di 36 verifiche.

Nuova causa backend:2notifiche TEST correnti hanno riferimenti mancanti; recupero
fedele del dato e integrità relazionale sono verifiche distinte. Nessuna riga
riparata o parent inventato per ottenere un PASS; export solo protetto fuori Git.


## Overlay completamento successivo — 2026-10-08, mandato fdab4373

Prevale sui checkpoint sopra, senza cancellarne FAIL o provenance. È lo stesso
registro; gli ID esistenti sono aggiornati. Candidato composto5a40488, freeze
applicativo f9a61d5; source approvate separatamente, review integrata non dedotta.

| ID / requisito | Causa o risultato osservato | Dipendenza concreta / owner | Preparazione e singola azione di chiusura | Esito corrente |
|---|---|---|---|---|
| NI054-04 / R01–R30 | TEST readonly19:59UTC32/57RPC conformi,25assenti, quattro migration assenti,1/2indici,history155 | DB diretto AAAA, Mac IPv4; accesso protetto/trust/apply e finestra writer/cron mancanti / backend+operatore TEST | Quattro byte canonici, manifest, recovery popolata e service verify-full pronti; collegare pacchetto accesso su runner IPv6 e concordare finestra prima del readback/apply | FAIL schema; TLS BLOCKED exit2; apply NOT_RUN |
| NI054-04 / recovery v3 | Export un indirizzo/due intenti incluso tombstone; digest/identità/replay/mismatch/owner/deleted conformi | Parent Auth sintetici equivalenti già presenti; nessun restore globale Auth necessario per procedura scoped / backend |33casi54comandi PASS, review distinta50controlli39comandi APPROVED locale; inverse specifico ledger popolato rifiuta e preserva dati/schema/history | PASS locale, non sessione Client/live |
| NI054-04 / integrità notifiche | Namespace payment concurrency harness verificato; due righe/otto riferimenti mancanti. Cleanup replica che omette notification_* è meccanismo coerente, esecuzione originaria non attestata | Decisione data owner TEST per sole fixture orfane | Migrazioni PASS conservando righe; lista/mark-read/replay RPC separati PASS locale, order detail not_found; repair scoped proposto, nessun parent inventato | FAIL integrità; AUTH_LIVE NOT_RUN; repair NOT_RUN |
| NI054-06 / R02–R04 | File pubblico Worker e Client Supabase coincidono; config Client parziale non attivabile, pilot/sessioniA/B/callback mancanti | Auth/shop/domain owner | Config e fixture preparati0700/0600; indicare riferimenti approvati per validazione/cold-warm/revoca/cambio account | BLOCKED; nessuna sessione forzata |
| NI054-08 / R29–R30 |14envref assenti, zero GHsecrets/vars/environments; firma/canali/associazioni native non disponibili | Mobile release owner | Manifest operator refs pronto; collegare pacchetto release TEST per build→firma→upload→install→smoke | BLOCKED; firma/upload/installClient NOT_RUN |
| NI054-09 / R21–R24 | Bundle esatto e1b2f30e avviato in workerd;9HTTPprobe, reader Inspector/template4fogli, writer route PASS; OTel fallback e sharp unreachable qualificati | Backend verde e finestra W / Worker+W |2.012artifact invariati, no-bundle multipart identico,23binding/rollback verificati; distribuire selezione96758b89 quando prerequisiti verdi | PASS locale/review scoped; deploy/live NOT_RUN, prerequisito BLOCKED |
| NI054-09 / stato remoto | Versione22107a6f al100%, deploymentf726de06 invariati; Mini auth/catalog mutations già true | Preservare binding/stato corrente / W | Piano keep-vars/keep_bindings e readback pronti; attestare versione/asset/binding dopo deploy effettivo | Nessuna activation/deploy eseguita |
| NI054-05 / R24 Android | N main9d5c270b, APK installato con dati preservati; signedIn e lettura locale durante update osservate da N, quattro ACK storici non sono nuova catena | Pilot/backend/Worker+N/Admin/Client | Ricetta IDs pronta; eseguire prodotto+immagine→ACK→Admin→pubblicazione/prezzo→Client con ricevute correlate | NOT_RUN catena, separata da install/sessione |
| NI054-05 / R24 iOS | N PR21/3212799e:1524unitPASS36skip,14UIpass2FAIL; nuovo Proper preparato non integrato/installato | Diagnosi CI N + pilot/backend/Worker | N sole writer/device owner; completare diagnosi e catena separata per origine iOS | NOT_RUN catena; CI nativa N FAIL |
| NI054-25/38 / iOS Client journal | CI43 journal prepareFAIL124, app/Keychain NOT_RUN; tre esperimenti CLI terminali senza alternativa qualificata | Runtime hosted/CoreSimulator / QA iOS | Trace+brief pronti; nuovaCI37848510649 su f326 canonica, nessun altro esperimento UUID/set o retry43 | CI43 journal FAIL/cleanupPASS; nuovaCI in corso, esito NOT_RUN fino terminale |
| NI054-39 / R04,R30 | Journal illeggibile impediva anche lettura sicura account;3RED causali prima fix | Nessuna esterna per source; runtime finale per accettazione / Client+reviewer |2ea8fa1 conserva snapshot, sospende create, retry storage senza erase;102accountPASS,69reviewerPASS,8hostmatrixPASS; catturare soli8nuovi stati | PASS source/local e review APPROVED scoped; native/live NOT_RUN |
| NI054-40 / R18,R21,R30 | Dettaglio assistenza assente senza spiegazione/lista e failure transitoria senza retry;2RED causali | Runtime finale e backend/Worker per live / Client+reviewer |f9a61d5 feedback neutro/CTA lista/retry vero;30miratiPASS,41reviewerPASS+3baselineRED;8hostmatrixPASS,16PNGnuove attese | PASS source/local e review APPROVED scoped; native/live NOT_RUN |
| NI054-07 / R30 | Nuova fixture137catture=113pregresse+24nuove;16casi host4lingue2temi320×568200%PASS | CI candidato composto e reviewer pixel / QA |4c3abf9 count137 e trace nei gate, review50testautonomiPASS; eseguire/interagire e ispezionare delta nativo | Nuove catture NOT_RUN; storico113+4 preservato |
| NI054-27 / R30 E | Inbox acquisita500→5configurati,5→5costruiti,20→20request;11benchmarkhost acquisiti | Device fisico Client/config/dataset/sessioni autorizzati / QA performance+Nfinestra | Budget/benchmark esistenti; misurare tap→destinazione/frame/memoria/cicli nelle stesse condizioni | PASS host, profiling fisico NOT_RUN |
| R05/17/26/27/28 | Provider indirizzi/mappe/online/push OFF; metodi payAtPickup/cashOnDelivery distinti da assenza rete | Owner provider/release, input sandbox/FCM/APNs/domain/device | Manuale/fallback testuale/gate coerenti; collegare provider autorizzato prima della prova specifica | NOT_RUN provider live, requisito conservato |

La prima assertion notifiche era errata: attendeva troppi failure nel batch e
falliva; il23503 osservato riguarda il secondo UPDATE nella stessa transazione.
Il normale trasporto RPC con transazioni separate e replay passa. Esiti negativi
conservati nella capsula; non attribuiti impropriamente all'endpoint ordinario.

Il service readonly è stato costruito autonomamente dai campi verificati.
PGPASSFILE/PGSSLROOTCERT e runner IPv6 rimangono input esterni, non l'alias.
La finestra20:15–20:45UTC è solo proposta non confermata; nessun cron pausato.
Una richiesta circoscritta sui percorsi protetti è pendente dopo preparazione e
inventari; nessuna credenziale richiesta in chat. Dispositivi N e lavoro W
preservati; production e TASK-055 non attivati.

Fonti correnti: [rapporto](CLIENT_TASK054_NEXT_INTEGRATION_RESULT.md),
[capsula backend](next-integration/completion-backend.json),
[Worker](next-integration/completion-worker.json),
[Client](next-integration/completion-client-ux.json),
[config](next-integration/completion-config-preparation-receipt.json),
[service](next-integration/completion-pgservice-preparation.json),
[coord](next-integration/completion-coordination-completion-receipt.json).


Aggiornamento checkpoint candidato: PR29 `43fd7af` pubblicato normalmente,
CI `37839967964` in corso sui sette job. Appfreeze f9a61d5 invariato rispetto
5a40488;35/35gate locali PASS e review distinta della capsula senza finding.
La run UUID37838207516/6b5a34e riproduce inventory postboot30s timeout,
leader vivo, stdout0;36,938s envelope. ps2s timeout e SIGKILL gruppoEPERM
impediscono attestationreap/quiescenza simctl. Risorse cleanupPASS, processiFAIL.
Nessuna patch canonica derivata; esperimento --set soltanto CLI in preparazione.
Le ipotesi sperimentali restano su branch separato, non modificano la PR43fd.


Ultima ipotesi CLI iOS `37840621912/6ab7e9a` terminaleFAIL124: primo
`simctl --set help` e inventorycleanup timeout30s, prima di qualsiasi
comando create/boot. Processcleanup/reap PASS; risorse/setcontents non
verificati, directory non rimossa, cleanupcomplessivoFAIL. Nessuna patch
canonica né ulteriore tentativo di preparazione. Brief operatore pronto
fuoriGit: `outputs/task054-completion-20261008/ios-runner-issue.prepared.md`.
NI054-25/38: prossima azione ownerCI è fornire/diagnosticare superficie
CoreSimulator supportata dai trace, poi qualificare i gate canonici.
Il jobSmoke della CI43fd ha successivamente PreparePASS sul proprio runner;
il jobjournal su altro runner ha PrepareFAIL124/cleanupPASS, VerifyKeychain
NOT_RUN. È nuova evidenza di variabilitàhost, non esito app né causa dimostrata.
Le tre run CLI e i due job app conservano risultati distinti.


Finding pixel del candidato43fd — NI054-41 / R04,R30: il badge informativo
indirizzo predefinito si tronca al200% nello stato journal illeggibile.
Prova causale sul pannello/controller produzione con Roboto pinned,
320×568, quattro lingue/due temi:2FAIL es-CL light/dark,6PASS; testo naturale
200,230px contro190px disponibili, RawChip impone una riga/softWrap=false/fade.
Semantica completa, ma leggibilità visuale insufficiente. P3 in scope del
mandato UX; non blocca recovery o conservazione dei dati. Source43fd e catture
sono preservati. Owner Client UX; fix minimo del solo label reflow autorizzato
senza clamp, traduzioni o controller, con regressione geometria/semantica,
review distinta e nuovaCI del codice finale. Nessun retry invariato journal43.
La nuova CI è dovuta al difetto riprodotto, non ai tre esperimenti CLI.


NI054-41: fix9fe418a integrato localmente in16e4681; tre blob identici e
patch-id invariato. Re-review distinta APPROVED SOURCE_CODE_ONLY,59PASS
autonomi e dueREDbaseline distinti. NuovaCI/pixel finali NOT_RUN, nessunpush.

NI054-42 / R30 — difetto harness riprodotto: viewport320×568 centrata in
parent400×900 con viewInsets.bottom300 conserva erroneamente inset300,
mentre l'intersezione fisica IME è134px (sovrastima166px). Un RED causale
e quattro controfattuali PASS distinguono viewport centrata, fullsmallwindow
che conserva300, e occlusione totale che conserva568. Owner Client UX;
fix minimo della proiezione geometrica insets/safezones, test permanenti
e review distinta autorizzati, nessuna riduzione di interazione/count137.
Questo difetto non è ancora la causa certa del FAIL iOS43: campo recensione
nonhitTestable, overflow24px con creatorchainDEFUNCT e joblimit30m restano
evidenze distinte. Nessuna modifica preventiva alla UI recensioni.


NI054-42: bf9be05 integrato in2327948 dopo review distinta APPROVED
SOURCE_CODE_ONLY_HARNESS,32PASS autonomi (8geometrie,6PoC,18host),
analyze/format/diff PASS. Causa esatta24px iOS ancora NOT_VERIFIED.
Fixture finale SHAe468956971c99cf67457170dee75629523892e5652e7a96069b0d7c3c3f1a5f0,
conteggio137 invariato. La prossima CI qualificherà il composto; nativeafter
NOT_RUN. [Review](next-integration/completion-viewport-source-review.md).

Preview/budget iOS7e7ecd2 integrato in d4a7e97 dopo review distinta
APPROVED_SOURCE_CODE_ONLY (53test mirati+5PoC PASS). Artifact raw invariato,
preview separata full-frame con hash/dimensioni; job35min misurato, timeout
comandi invariati. NuovaCI del composto/pixel ancora NOT_RUN prima del push.
Questo delta non corregge per inferenza il FAIL UI né qualifica TEST/live.

### Candidato composto f326faa — checkpoint prima dei risultati CI

Tre fix sorgente separatamente APPROVED: badge16e4681 (NI054-41),
harness2327948 (NI054-42), preview/budgetd4a7e97. Manifest552path, review
associazione38PASS, nessun delta applicativo dopo16e. CI37848510649 in corso.
NI054-39/40 hanno catture Android43 acquisite, ma NI054-41 impone review
finale dei pixel successivi; non restano semplicemente «mai catturati».
NI054-07 separa debugiOS43 smokePASS/visual91PASS1FAIL e journalprepareFAIL.
Le ipotesi UUID e customset sono terminali, non prossime azioni. R14 riguarda
il checkout; restart del journal indirizzi non lo certifica. E resta prova
supplementare, non modifica dei criteri R30.

### Esito terminale f326faa — 2026-10-08, consegna a re-review

CI37848510649attempt1 terminale5PASS/2FAIL: runtimeiOSfallisceprimaapp
nel postbootinventory dopo bootPASS; cleanupPASSscoped,0PNG/0OSverificati.
Nessunrerun invariato. Android92fixture/137PNG+4OS e restartPID4492→4604
PASS; Quality1064PASS+1SKIP/11benchmark; unsignedAndroid/iOSPASS89fixture.
NI054-41 risolto nei8journalAndroid, review73Flutter+4OSfreshAPPROVEDscoped,
64riusiperhashconlimiti storici; nessun finding nuovo nei77delta. NI054-42
PASSsource/Androidfixture, causa24pxiOSstoricaNOT_VERIFIED. NI054-39/40
PASSsource/fixtureAndroiddelta; TESTauth/live ed iOS restanoNOT_RUN.

Backend21:58:32/57conformi,25assenti,4canonicheassenti,1/2indici/history155;
RLS/ACL59deltaattesi,4cronattivi invariati. TLS/input/IPv6/finestraBLOCKED.
Worker22:13:22107a6f100%,23binding/rollbackinvariati; deployNOT_RUN.
Firma/upload/installClientNOT_RUN. Config/fixture/service/runbook e package
restanopronti; una sola richiesta riferimenti protetti giàpendente.
Azioni/owner/dipendenze per ogni residuo nel rapporto corrente, stesso registro.
Handoff `CODEX_FIX_BLOCKED_TO_RE_REVIEW`, taskBLOCKED/REVIEW.

### Re-review distinta conclusiva — 2026-10-08

Esito **BLOCKED**, handoff `CODEX_REVIEW_BLOCKED`, reviewer read-only distinto
`/root/final_audit`.77 controlli autonomi PASS; i rilievi editoriali sono chiusi,
nessun nuovo finding prodotto nel perimetro verificato. Il verdetto non chiude
i residui esterni o le prove integrate mancanti. Cause, dipendenze, owner,
preparazione e azione singola restano nella tabella del rapporto corrente;
questo resta l'unico registro, senza nuovi ID o backlog paralleli.
[Verbale](next-integration/completion-integrated-rereview.md).
