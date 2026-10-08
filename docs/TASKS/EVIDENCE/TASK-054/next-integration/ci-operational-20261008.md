# TASK-054 — CI candidata del 2026-10-08

**FAIL complessivo: cinque job PASS, un job FAIL.** Run [37817219242](https://github.com/XNIW/ClientMerchandiseControl/actions/runs/37817219242), tentativo 1, candidato `62980d29327c1bd09d07ecbd0116570f1df4b94f`. Tutti i sei checkout sono confermati dai log. Sopra source `bb53892393710d3ed6d2574053fe1206561b87f0` ci sono soltanto documenti. Il branch evidence successivo non cambia questa associazione.

| Job | Esito | Evidenza terminale |
| --- | --- | --- |
| Quality | PASS | 1043 test PASS + 1 golden skipped su Linux; 2 golden PASS nel job macOS; 11 performance host PASS (10 canonici + inbox). |
| Android debug | PASS | APK/JVM/security; 76 test native PASS; 113 PNG Flutter + 4 frame OS; cleanup PASS. |
| Android release | PASS | AAB/inspection APK e confine firma v2-only. |
| iOS release | PASS | Archive unsigned e 89/89 fixture avversarie; distribuzione NOT_RUN. |
| Android address journal restart | PASS | Seed PID 4242 → recover PID 4453, UID 10209 e APK immutati, arresto verificato, recupero/cleanup PASS. |
| iOS Simulator debug | FAIL | Boot/build/launch riusciti; attesa servizio VM fino timeout 900s, exit 124; nessun test eseguito. |

Il blocco iOS è successivo al boot: preparazione in 150s, build smoke 87,1s, `simctl launch` restituisce PID 31543 alle 17:43:24 UTC. Il tool rimane in `Waiting for VM Service port to be available...` per 719s, poi registra `No tests ran`. Non è il precedente timeout CI5 DataMigration; non dimostra da solo un difetto applicativo. La causa esclusiva engine/VM versus discovery unified log resta indeterminata. Cleanup del simulatore proprio PASS al primo tentativo, `processCleanupFailed=false`; visual skipped, **0/113 PNG Flutter e 0/4 frame OS iOS**.

Android: artifact 11569040559 contiene 113 PNG Flutter + 4 OS validati/hash coerenti; tutti 113+4 hanno ricevuto una prima ispezione pixel (83 nella lane autrice, 30+4 da child readonly). Tastiera OS realmente visibile 4/4; avviso CREATE incerto e Chiudi/Verifica leggibili in 8/8 combinazioni `es-CL/it/en/zh-Hans × light/dark`. Nessuna stripe RenderFlex osservata. Posizioni scorse e contenuto fuori viewport non sono da sole prova di irraggiungibilità. La review critica distinta è gestita separatamente nella capsule `native-visual-review-20261008`; questa capsule non approva il proprio harness.

Journal Android: artifact 11567687819, APK `4fef2fdb6fd597491ea6464051e902d61d2e8cf86cd13a514feb1caa138e6b1f`, processRestartRead PASS sullo stesso APK/UID, cleanup PASS. È persistenza di fixture su API35 x86_64 dopo force-stop, non recovery backend/Auth, power-loss o device fisico.

Ispezionati job, step, annotation, checkout e log: 1 failure (exit 124), 3 warning Node20→24, 6 notice capacità macOS/migrazione Ubuntu. I riferimenti, hash e conteggi esatti sono nella [capsule JSON](ci-operational-20261008.json). Raw log e immagini restano in `build/task054/ci-20261008-37817219242/`. Un download log iOS ha avuto TLS handshake timeout ed è stato ripetuto read-only; nessuna CI è stata rilanciata/cancellata. Tutti i comandi locali sono terminali.

Il confronto statico SDK 3.44.8 conferma che lo smoke trova l'URI tramite unified log. La prossima prova journal iOS con stdout/stderr privati e attestazione PID/URI bounded può discriminare il blocco senza patch presunte ad app/entitlements o aumento dei budget. Nessun nuovo runner è stato eseguito da questa lane.

**Restano separati:** iOS native/visual BLOCKED, journal iOS NOT_RUN nel candidato 62980d2, TalkBack/VoiceOver NOT_RUN, benchmark profile device NOT_RUN e backend/staging autenticato NOT_RUN. I PASS build/fixture non chiudono l'accettazione operativa globale.
