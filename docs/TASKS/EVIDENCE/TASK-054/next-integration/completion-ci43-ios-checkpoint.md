# TASK-054 — checkpoint iOS CI43

La run **37839967964**, attempt1, ha due esiti iOS indipendenti: journal **FAIL124 prima dell’app**; Simulator con build/security/prepare e smoke **PASS**, visual **FAIL della fixture** seguito da **cancellazione per budget del job**. Questi risultati appartengono al checkpoint43fd e non approvano il candidato successivo, l’accettazione autenticata TEST o la distribuzione.

## Provenienza verificata

Checkout effettivo e APIhead: `43fd7afc806404e667573734b2c4b3b3ffe8cc29`. Il log Checkout conferma HEAD43fd; il workflow usa il PRhead. La receipt del journal conserva invece `ownerContext.GITHUB_SHA=3f0c525cba08a4f7d76ebbb9e51589ce31919d5a`, contesto event/merge. Non è stata riscritta. Parents merge: `bfbfc0b6a7122f29b8d8f6e2c2263d77b252749c` e43fd; entrambi i commit hanno tree `3ea5a6f3e0407f4c99825e6e60298938b2c07aff`. Le due identità sono conservate come tali.

Run: https://github.com/XNIW/ClientMerchandiseControl/actions/runs/37839967964 . Job journal113526562134, runner1000004438; job Simulator113526561762, runner1000004433. Stesso checkout/toolchain e runner distinti: la variabilità del prepare è osservata, non una spiegazione certa del fault.

## Journal: FAIL prima dell’app

Prepare20:32:41→20:37:08. Bootstatus risulta Finished alle20:36:06; l’inventario globale postboot parte20:36:17.684621 e termina in errore timeout nominale30s alle20:36:51.184164, exit124. Il probe del gruppo registra EPERM1. Nessun journal applicativo, attachVM o controllo Keychain è stato eseguito: **NOT_RUN**, dipendenza prepare non superata.

L’artifact journal11576634805 contiene la receipt reale: due tentativi cleanup registrati PASS/resourcePASS; step finale cleanup SUCCESS con exit0. `processCleanupFailed=false` significa che non è stato registrato un failure dal wrapper: non costituisce da solo una traccia indipendente di quiescenza dell’intero gruppo. L’owner UUID eraB0ABC41B-1E31-48D0-A110-51C8FA0273F0. Capsula precedente del journal e raw sono preservati; il timeout e i limiti non sono stati modificati.

## Simulator: smoke PASS, visual FAIL, budget separato

| Step | Risultato effettivo | Durata wall da API |
|---|---|---:|
| Build Simulator |PASS|217s|
| Bundle security |PASS|101s|
| Prepare owner defaultset |PASS|227s|
| Smoke nativo |PASS|410s|
| Visual |FAIL test; step CANCELLED|728s|
| Cleanup owner |Step SUCCESS|9s|
| Upload artifact |PASS|5s|

OwnerD9C74CD3-43DA-47C0-865D-2416F3866D17, iPhone17/modello iPhone18,3, iOS26.5 build23F77. Non è un runtime iOS14: il target compilato14.0 non attesta la prova del minimo sistema operativo.

Smoke: Xcode interno195.4s; VM/DDS disponibili20:48:39, device test connesso20:48:41; test `smoke reale della shell development su device` terminato con `+1 All tests passed` alle20:48:58. Questo prova l’avvio/interazione sintetica della shell sul simulatore di proprietà del job; non prova autenticazione, staging, VoiceOver o distribuzione.

Visual: Xcode interno149.1s completato20:52:21; driver connesso20:52:49. La suite procede fino a+87, poi il test `recensione submit busy failure retry edit conserva commento` fallisce. A934, dopo `enterText` e `showKeyboard`933, `_reveal`1418 attende un TextField hit-testable sotto AlertDialog e trova0 anziché1. Viene anche riportato un RenderFlex overflow bottom24px, verticale/start/min/stretch, vincoli e size240×123. RenderFlex è DISPOSED e creatorchain interamente DEFUNCT: il raw non preserva una riga Column applicativa. La successiva eccezione WidgetInspector è emessa mentre descrive l’altro errore, non identifica la causa primaria.

Fixture es_CL/light, viewport logico320×568, scala testo2. `_compactViewport` centra il box e conserva gli inset ereditati: la causa tra proiezione del viewport del test e dialogo produzione resta da verificare. Nel log non compaiono physicalSize, DPR, viewInsets o viewPadding numerici. La geometria errata del wrapper è stata riprodotta separatamente dal writer UX con un RED e controfattuali, senza attribuirle automaticamente l’overflow nativo24px.

Il failure precede la prima capture recensione `review-comment-focus-compact200`943; il controllo di flusso salta potenzialmente le sette catture di quel test. Questo **non è un conteggio reale dell’artifact**. La suite continua con assistenza/tracking: `+91 -1 Some tests failed`21:00:15, FailureDetails21:00:46, cancellazione21:01:06.

La stampa FailureDetails nel SDK segue già i callback screenshot e `driver.close`; dopo resta il callback custom, che drena stream/jobOS e codifica/scrive la response, poi exit1. Il punto preciso attivo al cancel non è attestato. Non è dimostrato un hang di compilazione, discovery, VM o teardown. Exit finale del wrapper e quiescenza dei processi visual: **NOT_VERIFIED**. Lo step cleanup risulta SUCCESS dopo list/shutdown/delete/list; receipt Simulator finale non esaminata per il blocco download.

## Limite budget e artifact

Annotation reale: `The job has exceeded the maximum execution time of 30m0s`. Prima del visual trascorrono1097s, residuo nominale703s su1800; il comando ammette900s, oltre a cleanup.1097+900=1997s prima del cleanup: incompatibilità misurata dei budget. Non stima il tempo che sarebbe servito a questa run. Il FAIL UI è precedente e distinto; nessuna patch timeout è stata applicata.

Artifact remoto `task054-ios-visual-fixtures`, ID11578996266,25.441.913bytes, SHA256 `e95966898114bce36245df575323689676b51ec7fc9da98f25fa213099bd51b6`, upload completato. Console:138file e3markerOS_FRAME_RESULT=PASS. Questi dati non sono cardinalità PNG né review pixel.

Lettura locale **BLOCKED**: primo `gh run download` senza estrazione dopo oltre10min, solo downloader verificatoPID/PGID1236 terminato TERM/exit143. Tentativo seriale API→blob con timeout socket20s e limite esterno120s:2MiB part incompleto, solo downloaderPID/PGID6794 terminato TERM/exit143. SASredirect e autorizzazione sono rimasti in memoria, non in argv, log o receipt. Il file part è privato, non estratto e non valido come ZIP verificata. Entrambi i download sono terminali; nessun processo hosted o test attivo è stato interrotto.

Cardinalità software137 eOS4 attese; cardinalità reale, metricheOS e reviewpixel: **NOT_VERIFIED/NOT_RUN**, causa download bloccato. Non sono state dichiarate130immagini o3OSframe sulla sola previsione del controllo di flusso. Il prerequisito di sblocco è la lettura dell’artifact completo oppure le nuove catture sulla nuova SHA dopo fix/review.

## Residuo e limiti

Nessun retry del journal43, nessun fullrerun, nessuna ulteriore runCLI, nessuna patch app o timeout del writer iOS. Le tre runCLI precedenti FAIL e relative cleanup restano preservate in capsule separate, senza promozione al candidato canonico. Il branch sperimentale è clean/tracked a6ab7e9a; UUID eprivateset restano separati dalla PR29.

Il coordinatore compone i fix badge e proiezione viewport solo dopo review distinta e avvia una nuovaCI legittima. Il visual dovrà passare e produrre137PNG+4OS completi prima della review pixel iOS. iOS14runtime, TEST autenticato, verificaVoiceOver/IME e distribuzione restano NOT_RUN. Il checkpoint43 non viene riusato come accettazione finale di source modificata.

Raw/source/receipt/review privati in `outputs/task054-completion-20261008/ios`, directory0700/file0600. Metadati e hash puntuali nel JSON affiancato e nel mappingSHA256; log completi, PNG e part non vanno versionati.

## Hash delle fonti principali

- `raw/final-ci-smoke-hosted.log`: 3379797B; SHA256 `23de29d36553838d9a845d3da548a8d764274fd3effe78bb674d62a330913889`.
- `raw/final-ci-journal-hosted.log`: 59419B; SHA256 `8d40f7cf89ed7c342f9404d559c43b212b5797b1c43beff1ac0872dac07ddc48`.
- `raw/checkpoint43-fixture-source.dart`: 60390B; SHA256 `18e3d20e1bbde38af14d1ba448f70256fbc09fc72b213c4b8410977b839ac658`.
- `raw/ci43-review-ui-failure-exact.log`: 22211B; SHA256 `5035c29c9812daf177052ec95ef3e564091d8dfc4256afd5db184b68235e9fbc`.
- `raw/visual-artifact-outer-budget-receipt.json`: 521B; SHA256 `1420b3759a0c7799d8db06de925f88e994759c9bf51317b3d1139056e9183223`.
