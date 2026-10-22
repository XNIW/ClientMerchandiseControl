# TASK054 — inventario iOS UUID, esperimento diagnostico

La run [37838207516](https://github.com/XNIW/ClientMerchandiseControl/actions/runs/37838207516), job `113520593989`, è terminale **FAIL**, exit `124`, sul sorgente esatto `6b5a34ea427cd67b055fa0e0dbfb5855c4e1124c`, branch `codex/task054-ios-preflight-measured`. Il candidato PR29 finale è distinto: questo commit sperimentale non è stato importato nel candidato applicativo. Non sono stati eseguiti app, journal, smoke, visual, modifiche entitlement, simulatori o build locali. Tutte le durate qui indicate provengono dalla trace monotonic della run; il confronto storico non è una diagnosi retroattiva.

## Ipotesi e prerequisiti verificati

Dopo il primo esperimento globale `37836564977`, il solo cambiamento runtime investigato è stato il filtro UUID documentato dalla CLI installata: `xcrun simctl list devices --json <UUID proprio>`. La query pre-boot ha restituito una riga positiva del dispositivo proprio; il runner ha continuato a verificare identità UUID, nome nonce, runtime, disponibilità, stato e unicità. Sono rimasti invariati timeout `30s` dell'inventario e `2s` del probe `ps`, process group propri e owner canonico. L'help di `list` è stato raccolto da stdout e stderr, correggendo il falso indicatore di supporto assente della prima raccolta. L'help installato documenta sia il filtro sia `--set <path>`.

Source review distinta **APPROVED / SOURCE_CODE_ONLY**, 25 verifiche autonome PASS; writer 17 test PASS. Le prove RED dell'help emesso su stderr e del filtro vuoto non verificato sono conservate. Queste verifiche autorizzavano un esperimento; non provavano la risoluzione del timeout hosted.

## Risultato e tempi

Inventory iniziale **PASS**, create e verifica ownership **PASS**, boot e bootstatus **PASS**. L'inventario UUID dopo il boot ha superato la scadenza mantenuta a 30 secondi.

| Misura | Esito osservato |
| --- | --- |
| PID/PGID proprio dell'inventario | `2668` |
| Popen interno | `6.111200833s` |
| communicate interno, nominale 30s | `30.474575292s` |
| da evento spawn-start a evento timeout | `36.938054125s` |
| Leader alla scadenza | vivo; returncode nullo |
| Output | zero byte stdout; incompleto |
| Pipe ereditate | non dimostrate |

Il tempo interno di `communicate` e l'intervallo fra eventi non sono intercambiabili: l'inviluppo include spawn e intervalli dell'osservatore/scheduler. Nemmeno questa run riproduce l'intervallo storico di circa 113 secondi. Il filtro UUID non ha rimosso il confine; non è dimostrato se il provider filtri prima o dopo enumerazione globale.

## Cleanup: risorsa e processi separati

Il segnale TERM al solo gruppo proprio è riuscito. Il probe kernel di esistenza ha restituito successo; il fallback `ps` è stato effettivamente eseguito ma ha superato la sua scadenza nominale di 2 secondi.

| Misura del probe `ps`, PID 2931 | Osservato |
| --- | --- |
| Popen interno | `0.925146458s` |
| communicate fino al timeout | `2.213944916s` |
| da evento spawn-start a timeout | `3.186153375s` |
| Leader alla scadenza | vivo, output zero byte |
| Kill/reap del solo leader ps | SIGKILL, exit `-9`, reap `0.150974125s` |

Il successivo SIGKILL del gruppo simctl `2668` ha restituito `EPERM`, errno `1`. Il wrapper canonico è uscito da questo percorso prima di un `wait/reap` osservabile sul leader simctl. **Process cleanup FAIL**, quiescenza del gruppo **non verificata**, classificazione zombie **non verificata**. Né `EPERM` né il ritorno del runner dimostrano da soli assenza o sopravvivenza del gruppo. Le pipe ereditate non sono state dimostrate da nessuno dei due timeout. La run/job hosted è terminale; non è disponibile un readback esterno del runner dopo la sua conclusione.

Shutdown, delete e successivo readback di assenza del dispositivo proprio sono **PASS**. La receipt conserva `processCleanupFailed=true` e cleanup complessivo **FAIL**. Non si è trasformato il successo della risorsa in un PASS dei processi.

## Evidenze persistenti

Raw e receipt sono fuori Git in `/Users/minxiang/.codex/outputs/task054-completion-20261008/ios/raw/`: `uuid-preflight-hosted.log`, `uuid-preflight-job.json`, `uuid-preflight-terminal.json`, `uuid-preflight-annotations.json`, `uuid-preflight-artifacts.json`, `uuid-hosted-artifact/ios-measured/{owner.json,result.json,processes.jsonl,simctl-help.txt}` e `review/uuid-experiment/`. Directory 0700, file 0600; mapping e SHA256 nel manifest radice. Snapshot esatto workflow/run/trace/test/owner sotto `ios/source/6b5a34ea427cd67b055fa0e0dbfb5855c4e1124c/`. Hash puntuali e metadati artifact nella capsula JSON omonima.

Artifact hosted `11576423029`, 8039 byte, digest `sha256:76c4cebbaab2f4e7e98f7b0e47174b9c77ea9d119130a42b39885d4e866fd99f`. Annotazioni: failure exit124; warning Node20 forzato Node24 nell'action già pinned; notice capacità runner macOS arm64. Nessuna annotazione cambia il confine osservato.

## Azione residua autorizzata e limiti

Un solo ultimo esperimento, separato dalla candidata PR29, usa un device set privato sempre passato con `--set` a inventory, runtime, create, boot, bootstatus, shutdown e delete. Directory esclusiva 0700 e UID/inode/device verificati prima di ogni comando; nessuna mutazione del set predefinito. Ricetta headless dichiarata: GUI **NOT_RUN**, trasporto app **BLOCKED**, esportazione `--keep-ready` vietata. Timeout invariati e review distinta richiesta prima del lancio. Non sono autorizzate ulteriori run dopo questo esperimento né patch canoniche senza un PASS pertinente.

Anche un PASS CLI del set isolato non proverebbe che Flutter/Simulator.app e i caller journal/smoke/visual lo possano scoprire. La sorgente locale Flutter 3.44.8 consultata read-only invoca `simctl list devices booted iOS --json` e altre operazioni senza `--set`; non è una prova runtime di eventuali variabili ambientali supportate da CoreSimulator. I gate app restano autonomi e non promossi per inferenza. Le due run storiche `37817219242` e `37822118836`, e la prima misura `37836564977`, restano conservate con i rispettivi esiti negativi.
