# TASK-054 — qualifica Worker del candidato selettivo

La qualifica locale del bundle è conclusa senza modificare sorgente, dipendenze,
artifact o symlink. Deploy e accettazione autenticata TEST restano bloccati dal
backend e dalla finestra coordinata, distinti dalle prove locali.

Sorgente `96758b899aac2ccde1a70aeda4bbe7983007fb18`; HEAD di sole evidence
`a771cee43b0c43ec844e60282ea764646905996e`; manifest dei 2.012 file
`c905fde55da03cfc0dca100ee6c8313b0a689e41b1f65ad87c204eda4a208b64`.
Bundle packaged qualificato `e1b2f30e3e1413e0404543cf2ddf21bb14157b9aa339121d8b3ba47d01542997`.

| Prova | Esito | Limite e risultato concreto |
| --- | --- | --- |
| Avvio bundle packaged | PASS | Wrangler 4.123.0 / workerd, `--no-bundle --local`; stessa compatibilità del TEST; rete OS solo loopback |
| Caricamento after-sales/reviews | PASS | Due route 200 con superficie di guardia; nessuna sessione autenticata |
| Writer Excel | PASS | Route reale template: XLSX 5.181 byte, `no-store`; invoca `write-excel-file/node` incorporato |
| Reader Excel | PASS | Inspector sul bundle invariato: `read-excel-file/node` incorporato legge il template sintetico corrente, quattro fogli con una riga ciascuno; distinta dal flusso import autenticato |
| Guard HTTP | PASS | Upload 415, export 400, Mini challenge 400; nove risposte nel runner finale, incluse warmup e richiesta Inspector 404 |
| Cinque external specifier (analisi statica) | PASS | Due root Excel sono branch inutilizzati dei dispatcher; import reali `/node` incorporati; OTel facoltativo; due riferimenti sharp sono helper build senza caller applicativo |
| OTel facoltativo | PASS | Import diretto nel medesimo workerd rifiutato, catch restituisce `null`; non invoca il helper Supabase e non abilita tracing |
| Helper sharp include/cplusplus (analisi statica) | PASS | Definizioni lazy usate da `binding.gyp`, zero caller nel bundle; rimangono non inizializzate dopo le route osservate; nessuna invocazione applicativa da qualificare |
| Copertura precisa Inspector | BLOCKED | CLI/runtime restituisce `Profiler is not enabled`; sostituita dalla prova Debugger mirata, nessun claim di call-count coverage |
| Cleanup | PASS | Gruppo proprio terminato; porte 8795/9231 chiuse, processo assente nella review autonoma |
| Artifact originali | PASS | Review autonoma: 2.012/2.012 hash e insieme esatto, più package/handler/metafile/multipart/map; nessuna modifica sorgente |
| Pacchetto deploy esatto | PASS | Dry-run con rete OS negata, exit 0, 1,664 s; `--no-bundle`, worker multipart byte-identico, nessuna ricompilazione |
| Readback TEST / rollback | PASS | Versione precedente disponibile; 23 binding e runtime verificati senza registrarne i valori riservati |
| Deploy / commerce autenticato TEST | BLOCKED | Backend TEST non pronto; finestra W proposta ma non confermata; nessuna mutazione remota eseguita |

Il runner finale salva il template nel warmup prima del reader e asserisce status,
risultato del reader, assenza di eccezioni e chiusura delle porte. Il processo finale
termina exit 0. Le diagnostiche precedenti del solo harness sono preservate: sintassi
sandbox, inizializzazione lazy, contesto Inspector e supporto Profiler. Non riproducono
difetti applicativi. Il sorgente visto dall'Inspector contiene integralmente il bundle
originale, con il solo commento `sourceURL` aggiunto dal runtime.

Il readback corrente mantiene versione `22107a6f-f515-44c4-8392-a8e5653ff0b8`
al 100%, deployment `f726de06-fb79-46f5-a1b3-1d35fdc9de69`, descriptor binding
SHA256 `094461fcb7df732f0dafbd1e94e48c8e5b93d2d519921d9785f2c537d140812b`.
URL pubblico e self-reference coincidono con TEST. Mini auth e catalog mutations sono
già `true`; Android/iOS/linking/web/enrollment sono `false`. Next disabilita gli span
fetch tramite valore `1`; upstream tracing Mini è disabilitato tramite `true`.
Nessun flag è stato cambiato. W deve confermare lo stato corrente nella finestra.

`deployment-plan.json` contiene comandi concreti di deploy selettivo e rollback,
prerequisiti e post-verifiche. Il nuovo multipart conserva 21 variabili/segreti tramite
`keep_bindings` e dichiara esplicitamente i due binding strutturali ASSETS e
self-reference TEST. Tutti i 53 asset restano quelli del manifest originale.

Evidence principali: `runtime-receipt.json`, `external-reachability.json`,
`remote-readback.json`, `exact-package-receipt.json`, `exact-package-closure.json`,
`deployment-plan.json`, `external-runtime-review.json` e `final-readonly-review.json`.
Il debug Inspector verboso è stato eliminato dalle evidence e sostituito da
impronta/dimensione; restano ricevute concise. Nessun documento Client condiviso è
stato modificato; il coordinatore integra questa capsule nel registro unico.

Riferimento primario per il perimetro locale workerd:
https://developers.cloudflare.com/workers/local-development/
e per gli strumenti DevTools:
https://developers.cloudflare.com/workers/observability/dev-tools/
