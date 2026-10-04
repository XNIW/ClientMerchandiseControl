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
| NI054-03 / R30 | Difetto riprodotto | Badge fulfillment dettaglio prodotto320/200%: Row con label non flessibile, overflow ES/IT/EN | Client / root | Harness visuale separato | Reflow della sola etichetta,4locale light/dark e dettaglio; native prima/dopo separata | Riprodotto; fix/test in corso |
| NI054-04 / R01–R30 | Configurazione/attivazione TEST mancante | Metadata fresco:32/55RPC,1/2indici,registry155; source canonica158 | Admin/Supabase / backend owner | Recuperabilità corrente DB+Storage ed esclusione writer/cron | Sole3canoniche in ordine, package hash-bound; poi apply e ruoli reali | Package/preflight in corso; apply BLOCKED |
| NI054-05 / R24 | Implementazione presente ma prova mancante | Authoring/camera/galleria/publish implementati; nuovo recovery N ancora FIX | Android/iOS / N; Admin + Client | Candidato N stabile, pilota/shop TEST e runtime verde | Ricetta e mapping sourceProductId→publicationId; ricevute separate authoring/consumo | Contratto PASS lettura; catena NOT_RUN |
| NI054-06 / R02–R04 | Configurazione TEST mancante | Google attivo/17redirect; manca host HTTPS verificato nel contratto corrente e configshop pilota | Auth/domain + mobile release | Riferimenti già approvati, AASA/assetlinks e allow-list | Config esterna validata, cold/warm/login/revoca su entrambe le piattaforme | Parser respinge config legacy; AUTH_LIVE NOT_RUN |
| NI054-07 / R18/R21/R22/R30 | Implementazione presente ma prova mancante | Stati reviews mutation, inbox pagina/offline/revoca, tracking OFF/stale e4superfici200% non attestati | Client / visual_harness | Worktree distinto; runtime native proprio/CI | Harness su controller/UI produzione con fixture; capture e interazioni separate | Patch20test in corso; staging NOT_RUN |
| NI054-08 / R29–R30 | Dipendenza esterna | Servizio readonlyTLS/runtime/firma/canale Client assenti; iPhone unavailable=-27,Android fisico assente | Backend/release/device owner | CMC_BACKEND_PGSERVICE, configartifact e input signing approvati | Gate live, artifact→firma→upload→install→smoke con ricevute distinte | Gate exit2 BLOCKED; nessun upload |
| NI054-09 / Admin staging | Implementazione presente ma prova mancante | SHA main non prova versione Worker distribuita; release selettiva da riconfermare | Admin/release owner | Ricevuta autorizzata commit→build→versione→TEST | Read-only deployment corrente; eventuale deploy solo delta approvato | Verifica in corso |

Le proposte UX del mandato restano da valutare, non finding presunti. Provider
indirizzi, mappe, pagamento online e push restano OFF; nessun requisito cancellato.

NI054-01–03: fix e regressioni mirate PASS; review/CI finale pendenti.
NI054-07: harness esteso65test/103PNG attesi, hostPASS; catture native, OSIME,
VoiceOver/TalkBack e contrasto globale ancoraNOT_RUN. Le restanti risorse
NI054-04–06/08–09 restanoBLOCKED/NOT_RUN secondo la ricevuta unica.

| NI054-10 | C-NI054-04/P2 BUG_CONFIRMED | Editor indirizzo perde draft su errore remoto sintetico | WriterharnessFIX; regressioneerror→draft→retry/lifecycle e reviewCI |
| NI054-11 | BECI-01/P2 BUG_CONFIRMED | CleanupAndroid lascia discendente proprio che ignoraTERM | WriterrunnerFIX; processreale/cleanupbounded e re-review |
