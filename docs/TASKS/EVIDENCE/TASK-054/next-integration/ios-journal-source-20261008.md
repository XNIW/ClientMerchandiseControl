# TASK-054 — Gate journal iOS, 8 ottobre 2026

Il candidato deriva da `62980d29327c1bd09d07ecbd0116570f1df4b94f` e completa
il test mancante della persistenza Keychain entro il mandato operativo corrente.
App, entitlement, target iOS 14, versioni e sei budget CI esistenti sono invariati.
Nessuna build o operazione su Simulator locale è stata eseguita.

La fixture e il driver sono condivisi con Android. Il nuovo orchestratore riusa
`IosOwnedRunner` per validare la receipt privata, il contesto run/job/SHA e il
simulatore pronto; riusa il trasporto dei processi già verificato. Il job separato
ha 30 minuti, come il job iOS debug, e conserva macOS 26/Xcode 26.6.

La verifica prevista esegue una build e una installazione. Confronta il bundle
installato con la build, associa il PID al suo executable e valida la ricevuta
seed con l’UUID della run. `simctl terminate` opera sul solo bundle/UDID attestato;
una probe bounded deve confermare la cessazione del processo. Recover usa lo
stesso bundle/container e un PID diverso; legge il journal originale e ne verifica
la cancellazione finale. Non sono previsti reinstallazione o erase fra gli avvii.

Le URI VM sono lette da file temporanei privati, non pubblicati come artifact;
il driver si collega all’app esistente. I timeout e i gruppi propri sono gestiti
dal lifecycle già esistente. La receipt del runner distingue cleanup dei processi,
file privati e cleanup Simulator demandato allo step `always`, con receipt separata.

| Verifica | Esito | Limite |
|---|---|---|
| Runner iOS writer finale | PASS, 21 test, exit 0 | Unit con processi/Simulator simulati |
| Runner Android invariato | PASS, 13 test, exit 0 | Non ripete il runtime Android della CI precedente |
| Action pins | PASS, exit 0 | Pin dei sette job |
| Governance | Primo FAIL, poi PASS, exit 0 | Corretti snapshot e heading, nessun criterio cambiato |
| Review distinta | APPROVED SOURCE_CODE_ONLY | 21 test autonomi + 8 PoC, exit 0; tre P2 chiusi |
| Build/restart iOS | NOT_RUN | Da eseguire hosted sul candidato integrato |
| Backend/Auth/device fisico | NOT_RUN | Fuori da questa fixture |

Le ricevute e gli hash dei file sono nel [JSON](ios-journal-source-20261008.json).
Il README di `flutter_secure_storage_darwin` 0.3.2 richiede Keychain Sharing;
il test deve prima osservare il comportamento corrente, senza aggiungere capability
per ipotesi. Un eventuale difetto nativo richiede riproduzione e fix separati.

La review indipendente ha riprodotto tre P2, corretti senza cambiare i criteri:
assenza app ora attestata da inventario `listapps` e conversione plist riusciti;
trasporto owner coerente con il cleanup dei segnali; errori della diagnostica non
mascherano il codice driver. Le regressioni includono inventario sconosciuto,
cancellazione durante cleanup e codici 7/137/143 conservati con log illeggibili.
Una prima regressione signal è fallita per firma errata del mock; corretta la
fixture, la suite finale conta 21 PASS. I 16 PASS iniziali restano sul checkpoint
precedente e non sostituiscono la nuova verifica.

La receipt diagnostica distingue processo vivo/assente, executable corretto,
URI VM trovata/assente/ambigua e contatori/marker stderr. Nessun contenuto o URI
è pubblicato. Un PID assente non viene etichettato come crash provato.

La re-review distinta di `/root/backend_readiness` approva il checkpoint
SOURCE_CODE_ONLY: 21 test e otto PoC autonomi PASS, exit 0, tutti e tre i P2 chiusi.
Gli hash verificati e la receipt sono nel JSON; occorre associarli al commit finale.
Questo esito non dichiara PASS Keychain, CI hosted o approvazione globale del task.

Handoff: `CODEX_FIX_BLOCKED_TO_RE_REVIEW`. TASK-054 resta aperta, senza merge,
nuova CI, attivazione production o modifiche alle risorse N da questa lane.
