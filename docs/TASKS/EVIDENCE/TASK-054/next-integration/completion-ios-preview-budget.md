# TASK-054 — preview iOS e budget misurato

Delta source **APPROVED_SOURCE_CODE_ONLY** sul commit `7e7ecd2c9fe073665025cd88220648ca538bb7eb`, baseline `16e46817d9da5f4a5ce0fbca89137f2652f52b56`, branch locale `codex/task054-ios-preview-budget`. Il worktree dedicato è clean. Nessun push, dispatch, retry o modifica applicativa è stato eseguito dal writer iOS. Il branch sperimentale remoto6ab resta preservato e distinto.

## Problema e modifica

Il checkpoint CI43 ha caricato un artifact iOS raw da25,44MB, ma due letture locali si sono fermate senza ottenere una ZIP verificata: gh oltre10min e tentativo seriale limitato a120s con soli2MiB. Il raw remoto non viene sostituito o trasformato. La patch aggiunge un artifact separato di anteprime QA per rendere praticabile la review visiva; i dettagli critici richiedono ancora letture bounded degli originali.

Quattro file modificati: `.github/workflows/ci.yml`, `scripts/check.sh`, `scripts/create-task054-ios-preview.py`, `scripts/test-task054-ios-preview.py`. Il numero di sette job è preservato. Trigger e blocco di upload raw sono byte-identici alla baseline; cambiano i test Quality e i due nuovi step preview. Soltanto il budget del job `ios-build` passa da30 a35min. App, fixture, target14.0, toolchain, ownership device e timeout dei comandi simctl/app/VM/drive non sono modificati.

Dopo cleanup e upload raw, lo script trasforma soltanto i PNG già presenti in visual e os-visual. `sips` macOS produce PNG sull’intero frame, senza crop o formati lossy, con lato massimo1000px; i file già piccoli restano byte-identici e non vengono ingranditi. Il resampling cambia i pixel dell’anteprima: non è una sostituzione delle catture originali o un’approvazione UX.

Il manifest contiene checkoutGit effettivo, path relativi, SHA256 e dimensioni/byte raw e preview, trasformazione e assenza di crop. Il programma verifica PNG, proporzioni, limite dimensionale e immutabilità dei raw dopo ogni trasformazione. Non riusa directory di output esistenti, rifiuta symlink/file non validi e rimuove i PNG incompleti prima dell’upload. Con nessun raw scrive NOT_RUN, senza inventare PASS; il numero di file trasformati non attesta da solo la completezza della suite o la qualità dei pixel.

I tool sono processi con sessione/PGID propri e usano il cleanup canonico condiviso, preservando gli esiti primario e cleanup distinti. Ogni attesa tool ha limite5s; preview globale45s nominali e step GitHub1min. Il nuovo artifact si chiama `task054-ios-visual-previews`; l’originale `task054-ios-visual-fixtures` conserva nome, contenuti e configurazione di upload.

## Budget e limiti

Misura CI43/job113526561762: prima del visual1097s; budget invariato del comando visual900s. La somma1997s supera il vecchio job1800s ancora prima di cleanup/upload. Il nuovo cap2100s lascia103s nominali oltre questa somma; cleanup/upload/post del checkpoint hanno impiegato circa22s. La preview è limitata a45s nominali e allo step di1min.

35min è un cap finito fondato sulla timeline osservata e sulle misure del nuovo lavoro. Non è una somma matematica di tutti i massimi possibili di spawn, cleanup e rete, né una garanzia di PASS su un host futuro. Il limite di900s non viene aumentato. Il FAIL recensioni a43, precedente alla cancellazione, rimane un risultato distinto: la nuova fixture corretta deve ancora passare nativamente. L’aumento del job non risolve l’errore UI.

## Verifiche eseguite e review distinta

Writer:16 test preview,31 validatorPNG e6 lifecycle processi PASS; scan sicurezza992 file tracciati/zero secret, actionpins, sintassi shell e diff check PASS. I test coprono raw immutabili, hash e dimensioni, frame verticali/orizzontali, piccoli file byte-identici, niente upscale/crop, input corrotti, output non conformi, symlink, directory foreign, budget, timeout e cleanup separati. Tutti i comandi sono terminali.

Benchmark sullo script finale:141 PNG **generati sintetici**1206×2622,27.149.832B raw→1.585.122B preview in6,921s,141 resampling reali con sips. È solo una misura locale di trasformazione/performance. Gli Android43 disponibili erano già320×640:141 copie byte-identiche in0,152s; non vengono presentate come un benchmark di ridimensionamento. La dimensione del futuro artifact iOS non è verificata o garantita.

Reviewer read-only distinto:53 test autonomi PASS e5 PoC indipendenti PASS; source, diff, sette job, trigger/raw upload, pins, sintassi, security e worktree freeze verificati. Un secondo benchmark reale ha trasformato141 PNG sintetici in7,417s,3,076MB→1,321MB; hash, dimensioni, manifest e full-frame verificati, senza modificare raw o sentinella. Il resampling è dichiarato, con variazione ai corner entro4/255. Zero finding P0/P1/P2/P3.

Review `review/preview-budget/review.json`, SHA256 `9789bb6944e106155f434c43098d4ad1254fd277336545b31f404a3f1f0f0284`. I benchmark sintetici non sono PNG nativi iOS o approvazione visiva. Il full check locale con build iOS non è stato eseguito: delta CI/scripts validato con gate mirati; toolchain locale27/min14 non è una superficie autorizzata.

## Handoff e residuo

`CODEX_FIX_COMPLETE_TO_RE_REVIEW` per il delta CI/scripts; review source distinta completata. Il coordinatore può cherry-pickare7e sul candidato con i fix badge e geometria viewport già reviewati e avviare una sola nuovaCI legittima. Nessun retry CI43 è stato eseguito. La nuovaCI deve ancora verificare journal applicativo, visual, cleanup e artifact effettivi; soltanto dopo137PNG e4OS completi è possibile concludere la review pixel iOS.

Native iOS14runtime, autenticazione TEST, VoiceOver/IME, distribuzione e accettazione integrata restano NOT_RUN/BLOCKED nelle rispettive lane. Le capsule precedenti FAIL sono preservate. Source esatto dei quattro file in `source/7e7ecd2c9fe073665025cd88220648ca538bb7eb/`; raw/test/benchmark e review rimangono privati fuoriGit, directory0700/file0600.
