# Preflight TEST — handoff operativo

Candidato `6461194f68cf7d18f011b22e15fa6269dca19eb5`, composto da `02d089d` + `6461194`, base `f326faa`. Review finale distinta **APPROVED / SOURCE_CODE_ONLY** sul candidato immutabile; entrambi i P2 risolti.

Il default production resta separato. Il flag esplicito `--test` richiede staging sul progetto TEST, Google ON, mappe OFF, callback HTTPS approvato e un digest delle nove chiavi. Il binario deve contenere il marker TEST calcolato dagli stessi define compilati; non basta nominare un file staging. Firma, autorizzazione di upload, credenziali di distribuzione e gate backend live restano obbligatori.

Due P2 della review iniziale sono riprodotti e corretti: callback APK non verificato; host AAB duplicato con path mancante. I controlli ora verificano AAB e readback APK e richiedono chiavi uniche. Le prove sono host/sorgente, senza artifact firmati reali.

Gate: 88 test mirati iniziali PASS; 34 sul primo freeze PASS; 32 per i fix P2 PASS; 21 mutazioni architetturali respinte; tre prove host compiled config PASS (match/mismatch/cross-environment); analyze8 + analyze3 PASS; cinque metodi Python PASS. Delta permanente: 31 test Flutter nuovi. Nessun conteggio di suite globale dichiarato. Il JSON registra provenienza, hash e tentativi intermedi FAIL. La re-review autonoma ha eseguito32 test sullo SHA finale e verificato i PoC e il guard reale. Tutti i processi sono terminali.

## Uso dopo gli input owner

1. Completare il JSON runtime TEST protetto con le nove chiavi validate; non includervi il digest. Callback/host e shop devono provenire dai riferimenti approvati degli input operativi.
2. Calcolare il digest con `dart --disable-dart-dev tool/check_ios_runtime_config.dart --config <JSON-protetto> --test`.
3. Nel build release della piattaforma autorizzata usare lo stesso JSON e `--dart-define=TEST_CONFIG_SHA256=<digest>`. Questa build non è stata eseguita qui.
4. Eseguire il preflight Android esistente con AAB/APK, tutti gli input Play già previsti, `ANDROID_RELEASE_RUNTIME_CONFIG_PATH` e `--require-upload-ready --test`; oppure il preflight iOS esistente con archivio/reference/seal/attestazioni, tutti gli input TestFlight già previsti, `IOS_RELEASE_RUNTIME_CONFIG_PATH` e `--require-upload-ready --test`.
5. I gate TEST validano una copia privata del JSON e la usano nel fresh backend live check. Il PASS dei preflight non esegue un upload e non prova l’autenticazione o la callback hosted.

L’app iOS firmata deve dichiarare esattamente `applinks:<host>`; il grant del profilo può essere esatto o wildcard (`*` scalare/array). Apple distingue claim e allowlist e non garantisce uno schema stabile del profilo: compatibilità del profilo reale NOT_VERIFIED. Restano da provare separatamente assetlinks/AASA, ownership e ritorno OAuth reale.

Nessun account/sessione, certificato, profilo reale, firma, provider, upload o dispositivo è stato usato. Nessuna modifica UI/controller, workflow generale o gate DB nel delta.

Limite qualificato del helper XML standalone: il byte-scan antiDTD non vede UTF-16 diretto. Il percorso effettivo di command substitution Bash + guard APK respinge entrambi gli input diagnostici (exit1), verificato dal peer. Nessun nuovo finding raggiungibile e nessuna patch speculativa.
