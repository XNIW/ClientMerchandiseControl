# TASK-054 — CI con journal iOS del 2026-10-08

**FAIL complessivo: cinque job PASS, due job FAIL.** La run [37822118836](https://github.com/XNIW/ClientMerchandiseControl/actions/runs/37822118836), tentativo 1, verifica il commit `e7b194cea8bb53b23d3e994268d5cd47e67d085e`. Tutti i sette checkout sono attestati dai log. La precedente [CI629](ci-operational-20261008.md) resta storia separata.

| Job | Esito | Evidenza terminale |
| --- | --- | --- |
| Quality | PASS | 1043 test PASS + 1 golden skipped su Linux; 11 performance host PASS, inclusi 10 canonici e inbox. |
| Android debug | PASS | APK/JVM/security; 76 test native PASS; 113 PNG Flutter + 4 frame OS; cleanup PASS. |
| Android release | PASS | AAB/inspection APK e confine firma v2-only. |
| Android address journal restart | PASS | PID 4439 → 4557, stesso UID 10209 e APK; seed terminato, recupero e cleanup PASS. |
| iOS release | PASS | Archive unsigned e 89/89 fixture avversarie PASS; distribuzione NOT_RUN. |
| iOS Simulator debug | FAIL | Boot PASS; inventory post-boot timeout 30s; prepare 124 e cleanup 1. Smoke e visual NOT_RUN. |
| iOS address journal restart | FAIL | 21 unit test PASS; boot PASS; stesso blocco inventory/process probe. Keychain e console VM NOT_RUN. |

Nei due job iOS il boot termina: 108s nel journal e 242s nel debug secondo `bootstatus`. Il successivo `xcrun simctl list devices --json` supera il proprio budget 30s. Entrambi registrano `kernelGroupProbe: PermissionError, errno 1` e `psProbe: TimeoutExpired, timeoutSeconds 2`, quindi `prepare` esce 124. Shutdown/delete del simulatore proprio riescono: **resourceCleanup PASS**. La quiescenza del gruppo di processi non è verificata: **processCleanup FAIL**, conservato nei due tentativi di cleanup, il secondo con exit 1. Questo non dimostra processi superstiti.

Le receipt iOS hanno `processCleanupFailed=true`, nessun `ready=true`; il runner journal, lo smoke e le catture non vengono avviati. I soli artifact iOS sono receipt di ownership/esito: **0 PNG Flutter e 0 frame OS**. La run non fornisce una nuova prova sul timeout VM di 629 e non dimostra un errore Keychain o applicativo. La causa esclusiva del timeout/probe resta indeterminata.

L'helper `scripts/run-task054-ios-owned.py` è identico a 629, SHA256 `5784f4db204b58d4cbc925e3a1366088d42b47906923eb34fcdb815113599d8f`. I sei job preesistenti, i tree `lib/ios/android` e i file del harness visuale sono invariati; il delta introduce il gate journal iOS. Le associazioni e gli hash sono nella [capsule JSON](ci-ios-journal-20261008.json).

Android: artifact 11570931734 contiene 113 + 4 frame. **109/113 PNG Flutter sono identici byte per byte** alla run 629. Il reviewer ha confrontato le 4 immagini Flutter mutate e i 4 frame OS mutati con gli originali: timestamp cache, cursore/viewport e clock/IME; nessun finding. La tastiera è visibile e le azioni critiche restano sopra di essa. La [review di associazione](native-visual-association-e7b194c-20261008.md) è APPROVED soltanto per il campione precedente più gli 8 frame mutati, non per l'accettazione globale.

Journal Android: artifact 11569558964, seed PID 4439 e recover PID 4557, UID 10209, APK `0d587d4e01cf0608bc0a0384bbdf422e686e39322a476306f9c2d87517a0c978`. Le receipt separate e aggregate coincidono; stesso runID, arresto del seed verificato, recupero e cleanup PASS. È una prova di fixture su API35 x86_64 dopo force-stop; backend/Auth, power-loss e device fisico restano fuori da questa evidenza.

Ispezionati sette job, tutti gli step, annotation, checkout, log e quattro artifact. La capsule conserva quattro annotation failure (due exit 124 e due exit 1), quattro warning Node20→24 e sette notice dei runner. I raw log e le immagini restano in `build/task054/ci-20261008-37822118836/`. Il primo download dell'artifact Android è fallito nel trasporto; la sola lettura ripetuta è riuscita. Nessun rerun/cancel CI, test pesante locale, dispositivo o source modificato da questa lane; tutti i comandi sono terminali.

**Restano separati:** runtime iOS BLOCKED; journal Keychain, visual iOS, TalkBack/VoiceOver, benchmark profile/device e staging autenticato NOT_RUN. Nessun incremento dei budget o ulteriore tentativo invariato è stato effettuato.
