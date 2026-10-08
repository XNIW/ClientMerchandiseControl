# TASK-054 — Registro unico dei residui operativi

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
| NI054-26 / R04, R14, R25 | Difetto riprodotto | Creazione indirizzo senza identità durevole: commit con risposta persa e retry crea due righe; chiamate concorrenti non condividono risultato | Client indirizzi + Admin SQL | Nuova create/reconcile RPC, intent account-bound persistito cifrato prima invio, risposta canonica e conflitto payload; sei scenari del mandato | RED Flutter exit1; 99 test account PASS; finding indipendenti chiusi, re-review SOURCE_CODE_ONLY APPROVED; native restart e live NOT_RUN |
| NI054-27 / R18, R30 | Miglioramento misurato | visibleItems.map costruisce l'intera lista; costo dopo20pagine da misurare a viewport/dataset fissi | Client inbox | Baseline25/500righe,5campioni e budget lavoro dichiarato prima fix; lazy soltanto se dimostrato | Baseline25/500config,5build; dopo lazy5config/5build entrambi,5campioni;49testPASS, performance fisica distinta |
| NI054-28 / R03, R18 | Difetto riprodotto | Tap attende markRead; mounted potrebbe non distinguere owner cambiato sullo stesso screen | Client inbox | Risposta markRead lenta, switch owner, assenza navigazione stale e destinazione accessibile | 7navigationFAIL prima;8PASS dopo push immediato senza callback navigazione tardiva; suite49PASS |
| NI054-04 / R01–R30 | Configurazione/distribuzione incompleta | Snapshot iniziale TEST155receipt e32/55RPC conformi,23assenti;3canoniche e indice assenti. Manifest nuovo57 include altre2RPCv3 e migration20261008151018 non applicate | Backend readiness | Export corrente protetto dati/history; restore applicabile, finestra writer/cron; delta canonico e gate readonlyTLS | Snapshot gate FAIL1; recovery corrente scoped PASS e integrità preesistente FAIL; live gate BLOCKED2 per riferimenti assenti; apply condiviso NOT_RUN |
| NI054-09 / Admin,R21,R22,R24 | Runtime incompleto | Worker TEST versione22107a6f invariata; sorgente commerce assente dal tree1f0679b2 distribuito | Admin worker_candidate, coordinamento W | Candidato selettivo sorgente/build/versione/TEST, nessun deploy globale; review distinta | Candidato selettivo34ed0c50 e review W PASS; config pubblica TEST0600 pronta, build/runtime commerce NOT_RUN |
| NI054-25 / CI,R30 | Prerequisito hosted cambiato | Actions operativo dopo incidente5ott; CI5 conservata con cause precedenti | QA CI | Un nuovo tentativo sul candidato finale, job/step/annotation e artifact reali | NOT_RUN nuova CI; niente rerun stale |
| NI054-29 / R03, R20, R25 | Difetto riprodotto | Sheet riordino usa mounted senza invalidazione owner/sessione; preview e risultato sopravvivono a logout/cambio account | Client flow_coverage | Tre PoC con AuthController/router reali; fence minimo e review distinta | 3 FAIL/exit1 prima; fix commit386e4b3, 7 regression scope PASS; review distinta PASS (49 verifiche aggregate) |
| NI054-30 / R03, R21, R25 | Difetto riprodotto | Form assistenza conserva stato locale/Future righe dopo invalidazione del controller | Client flow_coverage | Due PoC owner/revoca con bozza e risposta tardiva; invalidazione del solo form | 2 FAIL/exit1 prima; 7 regression scope PASS, suite65PASS prima guardmounted espliciti; review distinta PASS (49 verifiche aggregate) |
| NI054-31 / R03, R25 | Difetto riprodotto P1 | Export privato di A resta visibile dopo cambio B fra push e mount | Client account, reviewer distinto | Monitor owner prima del push, invalidazione persistente e cleanup; conferme sensibili protette dalla stessa causa | PoC reale FAIL/exit1; fix confirm/export e 7 casi realAuth dentro98account PASS; re-review distinta PASS (49 verifiche aggregate) |
| NI054-32 / R04, R30 | Difetto riprodotto P2 | La notice busy ricrea la sezione indirizzi priva di key; il guard sul vecchio opener blocca retry/Verify pur mantenendo aperto il dialogo | Client account + QA | Key stabile della sola sezione, preservando mounted/owner; UPDATE immediato→differito→successo e Verify ripetuto nella stessa route | Baseline396 e candidato568 riproducono FAIL; 2 RED permanenti→98account PASS, targeted completo e matrice9 PASS su eab76f7 |
| NI054-33 / R03, R04, R25 | Difetto riprodotto P2 | Auth reale A→B→A durante create viene coalesciata dalla identity derivata e il vecchio ACK pubblica addressSaved | Client account + reviewer distinto | Invalidazione immediata generation dal flusso Auth; nessuna invalidazione per refresh dello stesso owner; journal preservato e Verify esplicito | PoC indipendente FAIL exit1; fix edfec536, 99 account PASS con recupero stesso intent e una creazione; re-review distinta APPROVED, 36 PASS |
| NI054-34 / R30 | Difetto contratto locale | Quattro stringhe nuove cinesi nel bundle tecnico zh violano il fallback es richiesto; zh_Hans è corretto | Client l10n | Ripristinare quattro valori spagnoli e rigenerare l10n senza cambiare contratto o zh_Hans | Suite globale1042PASS/2FAIL include RED del contratto; fix bb538923, 9 writer e 9 reviewer PASS |
| NI054-35 / CI | Test del runner non allineato | Il test conta cinque job dopo l’aggiunta del sesto gate journal dedicato | Root CI | Atteso6, conservando il controllo exact-SHA per ogni checkout e i budget esistenti | Secondo FAIL globale; modifica di una riga bb538923, 9 writer e 9 reviewer PASS |

P2/P3/P6: riferimenti approvati per config artifact TEST, readonly TLS, fixture
sintetiche, OAuth e distribuzione ancora da confermare. Domanda mirata sui soli
riferimenti inviata all'utente; nessuna richiesta di credenziali in chat.

Correzioni/review del nuovo candidato: la prima probe host indirizzo osserva
il messaggio fuori dal viewport (bottom1458 contro400 disponibili), ma da sola
non dimostra che il cliente non possa raggiungerlo. La verifica contrastiva con focus/IME coerenti e scroll reale passa sulla baseline: nessun difetto di raggiungibilità UPDATE attribuito al codice precedente. Il nuovo feedback sending aveva invece overflow20px durante la chiusura animata IME, corretto portandolo nella zona scrollabile; matrice9 PASS. Prova OS ancora NOT_RUN. Gli stress con inset mantenuto dopo blur sono conservati come tali. C-OC-01/P2: ACK indirizzo malformato generava
invalidInput nel parser e cancellazione journal; PoC2FAIL. C-OC-02/P1: cambio
owner/shop/A-B-A fra tap e primo mount lasciava la bozza precedente visibile;
PoC3FAIL. Writer99GREEN dopo i fix; review autonoma chiude questi finding. Il P2 Auth in-flight corretto in edfec536 supera la re-review distinta di 36 verifiche.

Nuova causa backend:2notifiche TEST correnti hanno riferimenti mancanti; recupero
fedele del dato e integrità relazionale sono verifiche distinte. Nessuna riga
riparata o parent inventato per ottenere un PASS; export solo protetto fuori Git.
