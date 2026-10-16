# TASK-054 — Addendum carrello e consegna

## Diagnostica visual — 16 ottobre, freeze source intermedio

I due FAIL visual9d hanno ancora domande causali nello scope. Il nuovo delta
osserva VM/lifecycle/PID/APK Android e PID/stack/UUID durante readiness iOS,
senza modificare il prodotto o indebolire gate, budget e cleanup. Il [piano e
le review](next-integration/client-visual-diagnostic-plan-20261016.json) conservano
5finding iOS privati e1Android, relativi fix e tutte le primarie negative.
Source re-review distinta APPROVED scoped su iOSV3/3616909a e AndroidV2/1f475cab;
nessuna approvazione globale. Applicazione composita WT:9suite Python/178testPASS,
exit0. NoveunitDart, formatter e analyze NOT_RUN a questo freeze: saranno
eseguiti nel focused esteso esistente, senza nativi. Dopo receipt/formatter
revisionati, il solo commit finale ordinario avvierà la CI7job completa, con
una esecuzione strumentata per domanda e nessun dispatch visual duplicato.

Il precedente Quality2e9/run38845283993 è terminalePASS1243/1SKIP+11performance,
14metadata,format409/0,analyze0; QUALITY-RR-02 chiuso scoped. I native9d restano
propri4SUCCESS/3FAIL. Il nuovo osservatore può perturbare il timing: nessuna
causa o stabilità da un eventuale verde. installed_fixture:null resta un
controllo postdriver non attraversato. Maps/TEST/live/AT/firma sono gate distinti.
Tutti i FAIL e cutoff sottostanti restano storici. Nessun SDK/UI Mac, nuovo
branch/worktree, merge/deploy, accesso persistente o operazione Asus.


## Ripresa 16 ottobre — QUALITY-RR-02

CI38841333617 su9d4fe2f terminale4SUCCESS/3FAIL, tutti job nuovi sullo stesso
SHA. Journal indirizzi Android e iOS PASS su due processi, stesso binario e
contenitori/UID, publisher SDK terminale e cleanupPASS; backendNOT_RUN.
Release unsigned Android e iOS PASS. Visual AndroidFAIL nel resume del driver
(Sentinel Collected), prima del corpo suite; iOSFAIL readinesslaunchctl dopo
bootstatusPASS. Entrambi zero nuove catture e cleanupPASS.

Quality1242PASS/1FAIL/1SKIP: il test recupero allegati lostFile=false osserva
[1,2] invece di[1,2,3]. Format409/0 e analyze0,14metadataPASS; performance e
whitespace NOT_RUN dopoFAIL. Review distinta QUALITY-RR-02/P2: manca una
barriera terminale nel test, che attende100ms mentre il flusso legge file
reali. La causa esatta del vecchio snapshot resta non dimostrata dal solo log.

[Fix test-only](next-integration/client-quality-rr02-recovery-barrier.json):
attendere l'operazione reale, gate controllato terzo upload e assertion
originali preservate. Scope limitato al test; nessun cambiamento prodotto.
Focused38844478084/280:497PASS/1SKIP, analyze0; entrambe varianti con
gate controllato PASS. Formatter400/1 solo test applicato esattamente,
re-review source/host/formatter APPROVED scoped. Full Quality del freeze
finale NOT_RUN al cutoff; ricevuta successiva nel proprio run/SHA e PR29.
Runner focused e Quality esistenti, nessun nuovo slot Mac. Le prove native
restano associate a9d; nessun PASS trasferito al nuovo head per inferenza.


## Ripresa 15 ottobre — CI corrente e diagnosi mirata

PR29 draft, branch esistente codex/task054-next-integration, baseline8f17774;
main bfbfc0b6 distinto. [CI38324733546/attempt2](https://github.com/XNIW/ClientMerchandiseControl/actions/runs/38324733546/attempts/2)
terminale:5SUCCESS/2FAIL, quattro successi ereditati attempt1 sul medesimoSHA.
QUALITY-RR-01 chiuso scoped:1243PASS/1SKIP,11performance,format409/0,analyze0.
Visual iOS fallisce bootstatus300s/Data Migration, journal iOS inventory30s prima
di create; entrambi cleanup correntePASS. Sono due worker hosted distinti
macos-26, immagine20260907.0351.1; non una diagnosi sul Mac locale. Xcode
selezionato26.6 e runtime visual26.5 restano distinti. Android visual nuovoPASS
body/driver; in questa ripresa indice/JSON qualificati, pixel PNG non revisionati.

[Profilo diagnostico](next-integration/client-ios-cold-preflight-20261015.json):
canonical cold nel workflow misurato esistente, prima di Flutter/app/GUI,
prepare headless/descriptor canonico, nessun inventario aggiuntivo. Ownerhelper,
tracer e budget invariati;9 nuovi test e12 trasporto/legacy PASS, review distinta
APPROVED soltanto sul diff. Prova hosted NOT_RUN al freeze, singolo dispatch
autorizzato dopo pubblicazione; nessun retry identico né acceptance inferita.

Maps: metadata GitHub correnti secrets/vars/environments vuoti; injection native
assenti nel candidato e nessuna proprietà Maps nel local.properties originale
(verificati solo i nomi). Console Maps disponibile senza progetto/selector o
contenuto centrale qualificabile, anche dopo navigazione credenziali. Nessuna
chiave approvata recuperata; producer esistente Courier Mode web foreground,
ordine/sessione e configurazione TEST ancora BLOCKED. Nessun nuovo provider,
accesso, billing o writer esterno. I cutoff sotto restano storici.

La prima prova [38840611837](https://github.com/XNIW/ClientMerchandiseControl/actions/runs/38840611837)
ha prodotto FAIL2 nel guard diagnostico: Xcode26.6/build17F113 espone SDKsim26.5.
Nessuna query simctl/receipt/device; cleanupNOT_RUN. IOS-COLD-RR-01 è stato
riprodotto RED e corretto con fixture reale:9cold+12trasporto/legacy PASS,
re-review distinta source/mock APPROVED. La prova corretta è NOT_RUN al
freeze del fix; risultati nel proprio run/SHA e nella sezione corrente PR29.
Nessuna conclusione sulla causa dei timeout precedenti prima della traversata.

## Candidato dopo QUALITY-RR-01

Snapshot prima del nuovo fast-forward PR29: `BLOCKED / REVIEW / CODEX_REVIEW_BLOCKED`.
La CI [38320490620](https://github.com/XNIW/ClientMerchandiseControl/actions/runs/38320490620)
sullo head eb0dc221 è terminale: quattro job riusciti e tre falliti. Il FAIL Quality
è causale: il validatore release iOS rifiutava il selettore hosted autorizzato.
[Capsula dei sette job](next-integration/client-cart-tracking-ci-eb0dc221.json):
16 annotation ispezionate, cinque artifact ZIP con digest verificato.
[Finding P2](next-integration/client-cart-tracking-quality-finding.json) preservato;
[fix source/focused](next-integration/client-cart-tracking-quality-fix-host.json)
su ec40596 con formatter esatto21a: 497 PASS, 1 SKIP, analyze0. Review distinta
del validator e dei sette mutanti; tutti13test precedenti conservati.
Il finding attende Quality completo sul nuovo head PR. Questo snapshot non
anticipa i Checks successivi, che avranno ricevuta e SHA propri.

| Capacità / gate | Prova nuova e risultato | Residuo |
|---|---|---|
| Quality eb0 | 1241 PASS/1 FAIL/1 SKIP, exit1; format409/0 e analyze0 PASS | Performance NOT_RUN dopo FAIL; negativo conservato |
| Fix QUALITY-RR-01 | Focused38323150416,497 PASS/1 SKIP/analyze0; format400/1 adottato esattamente in21a | Quality canonico nuovo PRhead NOT_RUN al cutoff |
| Journal Android eb0 | Due PID4178→4278, stesso APK/UID10209, publisher SDK terminale | PASS storage/restart/cleanup; backend NOT_RUN |
| Corpus Android eb0 | 93 body e driver PASS;137Flutter+4OS decodificati, hash installato/prebuilt uguali,cleanup PASS | Pixel/IME/AT/Google/backend separati |
| Visual iOS eb0 | Probe owned timeout/exit124 prima app;0PNG,smoke/body/driver NOT_RUN | Cleanup FAIL1: resource finale rimosso, quiescenza processi non provata |
| Journal iOS eb0 | Prepare/readiness PASS, app installata/PID23663; publisher SDK terminale FAIL durante seed | Seed acceptance FAIL; restart/recover NOT_RUN; causa specifica non conservata; process/log/owner cleanup PASS distinti |
| Release unsigned eb0 | Android12 fixture firma e iOS89/89 fixture validator PASS, hash/seal/attestazioni verificati | Firma/distribuzione TEST, push/Universal Links e upload production non qualificati |
| Maps/TEST/AT/firma | Prerequisiti e gate reali restano aperti | Owner e condizioni di chiusura nel registro residui |

App lib/native/config/deps e test delle feature sono invariati rispetto07649.
Le sole superfici nuove sono il test governance e il target focused che lo esegue.
Ledger37,26digest source e negativi storici restano preservati. Le sezioni seguenti
mantengono il cutoff e le revisioni precedenti, senza ereditare risultati fra SHA.

## Esito e revisioni

Checkpoint terminale del12ottobre2026, prima dell'aggiornamento della PR29:
**CODEX_REVIEW_BLOCKED**, dopo handoff Fix bloccato e re-review distinta.
[Verbale](next-integration/client-cart-tracking-re-review.json):cutoff23:02:57UTC,
zero nuovi finding applicativi/evidence; source/widget APPROVED scoped;
review integrata **BLOCKED**, PR29 draft, nessun DONE/merge. Tutti i tentativi
elencati sono terminali. Le ricevute degli eventuali gate della PR sono associate
allo SHA effettivo nei Checks: questo checkpoint non ne anticipa il risultato.

App/lib/test/native/config/dependency freeze
`07649a1253db705091b915adf98b4a7b6028af90`. Fixture cart153646d più formatter hosted
ec0452e; helper4b47376 e promozione CI1fb6aec. Il diff delle superfici app sopra è
vuoto rispetto076. La nuova fixture conserva la lista SDK screenshots; non cambia
il comportamento dell'app.26digest associati alle review sono verificati.
Runner GitHub separati, nessun SDK/input nelle app native del Mac; originale
8423c868 con supabase/ non tracciato preservato. Log/PNG/artifact completi privati.

## Comportamento corretto

- Add restituisce un esito per richiesta, generazione, account e shop: guest
  salvato localmente, account confermato soltanto da ACK qualificato. Rifiuti,
  timeout ambigui, doppio tap e completamenti tardivi non annunciano successo.
- Mutation/merge/revalidate leggono lo stato server prima di liberare pending
  storici o persi; add incrementale ricalcolato dopo conflitto, setQuantity assoluta,
  limite99. Nessuna nuova mutazione mentre il pending resta da riconciliare.
- Draft checkout v5 scoped, senza erase/eviction di altri owner/shop. Intent ordine
  prima di cart/discovery/account, stessa key/quote/payment/cartVersion anche con
  snapshot nullo/guest. Receipt prima discovery, UTC esplicito senza fuso qualificato,
  Retry raggiungibile senza cart. Nuovo acquisto conserva le righe successive.
- Tracking: ETA server assente/scaduta/aggiornata senza minuti inventati; mappa
  espansa nello stesso adapter, camera manuale/recenter/reduced motion; fallback,
  retry, stale/terminal/lifecycle. Cold cache senza coordinate precise finché il
  readback autorizzato non la qualifica; purge serial/tombstone/quarantine.

Il percorso continuo pickup/delivery usa controller produzione e autorità sintetica,
ricrea container nella stessa sessione e comprende merge/reprice/unavailable,
ACK perso/readback/ritorno/secondo acquisto. Il guest native usa invece due processi
con SQLite reale. Journal indirizzi, intent ordine e R13/R14 autenticati sono
capacità distinte: nessuna prova viene trasferita automaticamente.

## Matrice capacità → fonte → prova → residuo

| Capacità | Fonte/configurazione | SHA/run/piattaforma e risultato | Residuo |
|---|---|---|---|
| Feedback add/scoping | CartController/AddToCartButton | App076; host483PASS/1SKIP, review source distinta | ACK account TEST NOT_RUN |
| Pending/merge/revalidate/conflitto | RPC/idempotenza esistenti, stessi scope | RED causali nelledger37; source/host PASS | Non promette coda account offline durabile |
| Intent ordine prima cart/discovery | CheckoutController/draft v5 | RED38303669829:24PASS/7FAIL; fix source/host PASS | R13/R14 ordine TEST tra due processi BLOCKED |
| Receipt UTC e Retry nullable | CheckoutScreen, quattro scenari | RR02 RED460/2→GREEN462/1SKIP; RR03 RED9/3→GREEN483/1SKIP | Nessuna nuova quote/create nel recupero; business TEST separato |
| Guest restart Android | SQLite/CartController/CartScreen | 076/38309453440:4152→4363,UID10209,stessoAPK; PASS storage/UI/cleanup | Backend/live/AT NOT_RUN |
| Guest restart iOS | Bundle/container propri, SDK terminal file, guardv2 | 4b/38315958950:19700→21193,14checks,stessi bundle/binary/container; PASS | Runner cleanupNOT_RUN delegato a owner finale1PASS, non riscritto |
| Journal indirizzi Android | Plugin reale, due processi/file SDK | 076/38309453984:4289→4396,stessoAPK/UID; PASS native/restart/cleanup | Non prova intent ordine o RPC indirizzi TEST |
| Journal indirizzi iOS | Keychain/file SDK, guardv2 | 1fb/38317759498 e38318672682:precreate runtimes30s/124; BLOCKED | Device null/creationStartedfalse,Keychain/seed/recoverNOT_RUN,cleanup2PASS senza risorsa |
| Visual Android | Stesso target/define, prebuilt primaAVD | 4b/38316402128:93body+driver,137Flutter+4OS,hashprebuilt=installed/UID10209,cleanup; PASS | Pixel/IME/AT/Google/backend separati |
| Visual iOS | Aggregatore sintetico, ricetta/guardv2 | 076:93body+driverPASS ma133/137corpusFAIL; 1fb/38317752110:postbootspawn30s/124,BLOCKED | Nuovo137iOS NOT_RUN;0PNG/cleanupPASS nel tentativo1fb |
| UI tracking/ETA/camera | DTO/feed esistenti, Google OFF | 16cardhost4locale×2tema×200%,reducedmotion,QA distinta; PASS scoped | Native expanded/fallback/4×2×200 eAT BLOCKED |
| QA nativa | 18originali Android4b +18iOS076, source scrollabile | PASS solo contenuto visibile, senza tofu CJK osservatoAndroid115 | Retry/nome lungo/footer/timestamp parziali o fuori viewport; gesto scroll/AT non qualificati |
| Quality | CI canonica076 e focused153+preparationec | 1242PASS/1SKIP,11performance,analyze0/format409/0; focused483/1SKIP,analyze0 | Golden Linux saltato;2requiredmacOSPASS. CurrentPRheadCI da leggere separatamente |
| Release | Config production-like e ricette unsigned | 076/38309453984:Android12signature/iOS89validatorfixture,2releasePASS | Firma/distribuzione/TESTactivation NOT_RUN |
| Backend tracking | Metadata18:34:49UTC,Admin6d2bcf1,ledger20:29:30UTC | RPC e6relazioniRLS presenti,ledger161/trackingmigration presente; PASS metadata | Grant/policy/FORCERLS/publication/assignment/runtime NOT_RUN |
| Google Maps/R17 reale | Nessuna configurazione approvata recuperata | Ricerca bounded27registries/GitHub/console; BLOCKED | Chiavi nativeTESTristrette,ordineownerassegnato,producer autorizzato e catena reale mancanti |
| Route/ETA dinamica/background | Fonte server/native producer assente | Proposta owner versionata e bounded pronta,NOT_RUN | Nessuna activation/spesa/deploy o modalità staff Client |
| Auth,R24,C04,AT/fisico | Owner/superfici già registrati | BLOCKED/NOT_RUN nei gate specifici | Fixture,save locale,build e screenshot non sostituiscono acceptance |

## Causalità, negativi e associazioni

[Ledger37run](next-integration/client-cart-tracking-host-run-ledger.json):29righe
iniziali immutate più8;9provider success,25failure,3cancelled. Due cancellazioni
parziali di causa non confermata, una writer-cancelled prima del test. Comandi,
conteggi, restore e hash preservati; RR02/Retry3/Retry4 hanno test byte-identici
fra RED/GREEN. Ultimo sourcefocused38314876090:483PASS/1SKIP/analyze0,400file
formattati/1changed; unica reason spezzata, integrata esattamente in ec0452e.
Questo comando non esegue la fixture native.

Il precedente P1 Auth è WITHDRAWN: baseline3/3PASS mascherata da cart.loading.
Il RED profile dello stesso owner38301237763:3PASS/1FAIL prova il difetto distinto
corretto con subjectId e guard Auth raw. CART-RR-01 e CHECKOUT-RR-01/02/03 chiusi
source/widget da reviewer read-only distinti. Non è approvazione globale.

CI076 [38309453984](https://github.com/XNIW/ClientMerchandiseControl/actions/runs/38309453984)
terminale5SUCCESS/2FAIL provider; l'inventario aggiunge FAIL completezza iOS133/137.
Cart reportData cancellava01–04account/address già raccolti: patch spread+assert
identità/cardinalità, review distinta49mockPASS e corpus Android137 ripristinato.
Il gate137 è immutato. CIddba3SUCCESS/4FAIL preservata: feedback guest atteso account,
regressione basezh3copyCJK, golden0.67%, driver Android e journaliOSURI. La base
tecnica app_zh resta ES come da l10n.yaml; zh-Hans resta CJK. Golden2204px:2192expand,
12recenter antialias; header/timeline invariati,ETAfuoriframe,reference distinta.

Readiness iOS: inventorypostboot30s/124 e getenvUDIDmismatch2 precedenti restano
FAIL. Descriptor observation7a85 prova UUID/nome/runtime/deviceType e pin FD;
non deduce Booted dallo state3. V1spawn host/usr/bin/true38314239143 FAIL124/dyld
haveiOS-simulator/needmacOS,appNOT_RUN. V2spawn launchctl list dal PATH device,
budget30s/FD/context/nonce/default/cleanup invariati:16root+13FD+9environment e
50lifecyclepeerPASS, review source distinta, GCRnative38315958950PASS. Promozione
CI2 soltanto dopo questa receipt. Visual1fb fallisce ancora nel probe dopo boot;
journal1fb e repeat falliscono prima creazione nel runtimes inventory. Sono cause
separate, nessun fix Flutter/target/entitlements o aumento timeout.

Android prebuild: admission host/Git/KVM prima build, APK congelato e attestazione
UID/hash installati, keep-app-running fino al cleanup.28+8root/peerPASS;13address
fixturePASS dopo mockpreflight mancante, negativi originali preservati. Prima run
153 sdk-install ZipFileunknownarchive,nessunAVD/0PNG/cleanupPASS; nuovo host4b
stessaimmagine/toolchain supera il gate. Nessun OOM dimostrato dai vecchi offline.

[Associazione review e digest](next-integration/client-cart-tracking-review-association.json)
lega source/widget695+preparation076, publisher address-file8root/peerPASS,
golden/trackingpixel, i18frame nativi e capsule SDK/runtime terminali separate.
Gli80capsule e13consumerdigest precedenti,30caseR e due originiR24 sono preservati.

## Configurazione owner e limiti

La ricerca autorizzata non ha trovato chiavi/restrizioni Maps TEST riusabili.
Console autenticata: voce cached recente,selector fallito e credenziali senza
progetto qualificato; non prova accesso/IAM,billing/API o configurazione corrente.
Nessuna chiave mostrata o inventata,nessun nuovo provider o attivazione a pagamento.
R17 richiede stessoordine/owner,assignment/sessione e producer autorizzato; nessun
aggiornamento SQL manuale sostitutivo. La richiesta unica è già stata preparata;
la risposta utente autorizza il recupero, non trasferisce autorità Admin/SQL/deploy.

Ledger161 non qualifica il catalogo attuale né chiude le quattro canoniche assenti;
32/57RPC e1/2indici restano fotografia10ottobre. Metadata tracking presenti non
provano RLS/grant/publication o risultato business. Courier Mode web source6d2bcf1
è foreground con consenso/Start/throttling/pausa; ETA manualeAdmin, non dinamica.
[Proposta owner](CLIENT_TASK054_TRACKING_OWNER_PROPOSAL.md): route/ETA server con
versione stabile distinta da feed.version,TTL/privacy/payload/timeout/quota/budget;
background nella superficie courier con consenso/revoca/Stop/lifecycle/energia.
Sono criteri proposti,non capacità implementate. Nessun SQL/cron/Worker/N/input
esterno,nessun merge/DONE. Handoff con gate obbligatori esposti:REVIEW/BLOCKED.
