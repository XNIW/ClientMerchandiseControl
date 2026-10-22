# TASK054 — ultimo esperimento iOS con device set proprio

La run [37840621912](https://github.com/XNIW/ClientMerchandiseControl/actions/runs/37840621912), job `113528756147`, è terminale **FAIL**, exit `124`, sul sorgente esatto `6ab7e9a7c70b5ff5c02c1f83914ce05060a8cb72`, branch `codex/task054-ios-preflight-measured`. Il job dura 1m17s. È un esperimento separato dal candidato PR29 `43fd7af`: nessun commit UUID/device-set è stato importato nel candidato applicativo e nessuna patch canonica è stata applicata.

## Ipotesi, ownership e confine autorizzato

La seconda misura `37838207516` ha riprodotto l'inventario post-boot in timeout anche con filtro UUID documentato. L'ultima ipotesi strutturale autorizzata era evitare il set predefinito tramite `simctl --set <path>` per l'intera ricetta. La CLI installata delle run precedenti documenta l'opzione; questa run ne verifica l'esecuzione senza assumere la funzionalità dal solo help precedente.

Lo script acquisisce una directory esclusiva 0700 e la receipt `device-set-owner.json` 0600, registrando UID, filesystem device e inode. Prima di ogni simctl verifica questa identità e i permessi, poi inserisce sempre lo stesso `--set` per help, inventory, runtimes, create, boot, bootstatus, shutdown e delete. La directory osservata ha UID501/device16777229/inode2949352. Il percorso registrato è relativo alla working directory del checkout, `build/task054/ios-measured/device-set`; non si è modificato il default set. Shape dell'inventario, UUID, nome nonce, runtime, disponibilità, unicità e stato restano verifiche chiuse. Timeout invariati: inventario/help/create30s, boot60s, bootstatus300s, ps2s, cleanup gruppo5s per fase.

Ricetta dichiarata headless, GUI **NOT_RUN**, native transport **BLOCKED**. `--keep-ready` è rifiutato per questo modo; il workflow diagnostico non contiene journal, smoke, visual o setup Flutter. L'artifact include soltanto JSON/JSONL/TXT della receipt e trace, escludendo i contenuti del device set.

## Source review prima del push

Review distinta finale **APPROVED / SOURCE_CODE_ONLY**, 34 verifiche autonome PASS exit0; writer26 test PASS, action pins, security951 file e diffcheck PASS. Nessuna build/simulatore locale. La prima review ha dimostrato P2: senza device receipt, un errore precedente del cleanup processi poteva essere seguito da falso cleanupPASS del set. RED conservato, guard sticky aggiunta e PoC indipendente passato. P3: un readback tentato e fallito era ancora NOT_RUN nel sottostato; RED conservato, stato FAIL all'ingresso del cleanup, BLOCKED soltanto per prerequisito già negativo e PASS solo dopo rimozione verificata. Entrambi i finding sono chiusi dalla re-review; questi test non qualificano runtime nativi.

## Risultato reale: prima di create/boot

Il primo `xcrun simctl --set … help` supera 30s. Non viene eseguito alcun comando create o boot, né l'inventario iniziale ordinario della ricetta. Questo **non** riproduce il timeout post-boot: è un confine CLI precedente. Il file `simctl-help.txt` di questa run non viene prodotto, perché il primo help non restituisce output completo; gli help raw precedenti restano conservati con la loro esatta run.

| Comando | PID/PGID proprio | Popen interno | communicate timeout interno | evento spawn→timeout |
| --- | --- | --- | --- | --- |
| help con set proprio |1857|0.003731916s|30.003138000s|30.007656917s|
| inventory del set, nel cleanup |2474|0.024756458s|30.002419875s|30.027409875s|

Entrambi i leader sono vivi alla scadenza; stdout zero byte, output incompleto. Pipe ereditate **non dimostrate**. Le durate interne e l'intervallo fra eventi sono misure differenti, non timeout ampliati. La causa interna del provider/host resta non dimostrata; l'opzione documentata non ha prodotto un trasporto funzionante nel budget mantenuto.

## Cleanup separato e processi terminali

Per help1857: TERM al solo gruppo proprio riuscito, probe ps valida classifica `Z<` zombie_only, leader reaped exit `-15` in0.000031666s; i probe successivi lo vedono assente. Per inventory2474: dopo TERM i probe ps validi mostrano `S<s` vivo per il budget originale5s; KILL al solo gruppo proprio riesce, probe kernel segnale0 restituisce EPERM1, quindi ps valida classifica `Z<` zombie_only; leader reaped exit `-9` in0.000016709s. I probe ps di questa run completano nel loro budget2s. Tutti i leader delle sessioni proprie risultano reaped nella trace. **Process cleanup PASS** secondo le verifiche canoniche, senza dedurre quiescenza dal solo leader o da EPERM.

Il readback vuoto del set invece non è riuscito: `list devices --json` è andato in timeout. **Resource cleanup FAIL**, contenuto/assenza dei dispositivi nel set **non verificati**, directory conservata. Nessun comando create/boot è stato eseguito; ciò non viene trasformato nell'affermazione che il set contenga zero dispositivi o zero contenuti. Cleanup complessivo **FAIL**, setcleanup **FAIL**, exit primaria124 conservata. Non esiste owner.json del dispositivo perché prepare non è stato raggiunto; è presente la receipt di ownership della directory.

## Evidenza persistente e azione residua

Raw, review e sorgenti esatti sono fuori Git in `/Users/minxiang/.codex/outputs/task054-completion-20261008/ios`, directory0700/file0600. La capsula JSON omonima contiene hash dei raw e metadati artifact. Percorsi principali: `raw/device-set-preflight-{hosted.log,terminal.json,job.json,annotations.json,artifacts.json,watch.log}`, `raw/device-set-hosted-artifact/{result.json,device-set-owner.json,processes.jsonl}`, `raw/review/device-set-experiment/`, `source/6ab7e9a7c70b5ff5c02c1f83914ce05060a8cb72/`. Mapping e hash SHA256 nel manifest radice.

Artifact `11576919325`,16057 byte,digest `sha256:70e170ac492d0daf87651dbadcd379f1fc44a8287150093dfecf0c00e5989a0b`. Annotazioni: failure exit124, warning dell'action pinned Node20 forzata24, notice capacità macOS arm64. Le due run storiche37817219242/37822118836 e i due esperimenti precedenti rimangono preservati con i loro FAIL, compreso processcleanupFAIL della run UUID.

Nessun ulteriore esperimento, rerun o patch canonica. Restano da leggere soltanto i due job iOS della CI finale già avviata37839967964 su checkout43fd7af. Journal, smoke, visual e discovery Flutter non sono qualificati dal device set. La mappatura read-only SDK/caller, separata dalla prova runtime, documenta eventuali invocazioni nel set predefinito; nessuna modifica a SDK, factory simctl globale, app o entitlement.
