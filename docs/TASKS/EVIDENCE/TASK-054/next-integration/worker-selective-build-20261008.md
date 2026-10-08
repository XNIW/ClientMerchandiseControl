# Worker commerce selettivo — capsule locale 2026-10-08

Build source `96758b899aac2ccde1a70aeda4bbe7983007fb18`, tree `b75fe609cda8f53067cfe1cf1cb7782a9dba757b`. Baseline W congelato
con snapshot nuovo `f401fc3d`; tale snapshot non è il commit storico del deploy.
Fonte canonica commerce `82af13ef`: 14 file selezionati, 13 esatti; ShopShell conserva
soltanto le due icone. Le 38 dipendenze applicative risultano risolte; lo scanner è
una dipendenza di gate aggiuntiva. Nessun package/lock, migration o flag modificato.

| Gate | Risultato | Evidenza |
| --- | --- | --- |
| Primo verify su `34ed0c50` | FAIL | Exit 1, 29,073 s; lint/typegen/tsc PASS, 12 coppie RPC non allowlisted |
| Correzione minima e review distinta | PASS | Due hunks canonici, +27 righe, sette nomi RPC; `APPROVED` |
| Verify (eslint/typegen/tsc/security/Next) | PASS | Exit 0, 35,364 s |
| OpenNext | PASS | Exit 0, 26,929 s; entrambe le nuove route commerce compilate |
| Smoke Cloudflare locale | PASS | Exit 0, 4,570 s; 29 probe HTTP reali, guard/header e input malformati |
| Cleanup | PASS | Porta 8794 chiusa, nessun preview candidato, source pulito, handler ripristinato |
| Deploy / SQL apply TEST | NOT_RUN | Fuori dal lease locale autorizzato |
| Commerce autenticato TEST | NOT_RUN | Richiede finestra, backend coerente e sessione autentica |

Esecuzione UTC `2026-10-08T17:48:55.424235+00:00` → `2026-10-08T17:50:02.466673+00:00`.
Node 22.23.3, Next 16.2.12, OpenNext 1.20.2, Wrangler 4.123.0, TypeScript 5.9.3.
Dipendenze copiate APFS nel candidato; nessun symlink verso W. HEAD/diff W invariati.

Artifact `.open-next`: 2012 file, 40142604 byte.
Manifest SHA256 `c905fde55da03cfc0dca100ee6c8313b0a689e41b1f65ad87c204eda4a208b64`; ogni file ha dimensione e SHA256
nella receipt completa. Worker SHA256 `d05223bf4d44c84108a102ab62aa3bc9c5568f0c3ac2064c37be5cc65c64bc45`;
handler SHA256 `6aa3dff35b2b80352c8d36555d5e7ef226d397bbe55105fbb4584d327c6a6345`.

Configurazione pubblica TEST conservata fuori Git, modo 0600, due sole variabili.
Il bundle browser include l'URL TEST in un asset. Nessun valore è riportato in
questa capsule o nei log sanitizzati; nessuna credenziale privilegiata è stata letta.
La configurazione del build non attesta pilot Client o autorizzazione runtime.

Receipt completa `worker-build-runner-receipt.json`; log `worker-verify.log`,
`worker-opennext.log`, `worker-local-smoke.log`; RED preservato con suffisso
`34ed0c50-red`. Hash dei file di evidence nella capsule JSON associata.

Restano distinti: versioni/runtime remoti osservati in precedenza, identità sorgenti
storiche del deploy non verificata byte per byte, finestra condivisa e cron, integrità
backend e accettazione autenticata. Il lease heavy è stato rilasciato al termine.

Readback finale remoto in sola lettura, exit 0, alle 17:52:53 UTC: versione
`22107a6f-f515-44c4-8392-a8e5653ff0b8` ancora al 100%, deployment
`f726de06-fb79-46f5-a1b3-1d35fdc9de69` invariato. Non è stato eseguito deploy.

Review distinta delle receipt e artifact: `APPROVED`, zero finding. Il reviewer
ha ricalcolato in sola lettura le 2.012 impronte e il manifest, verificato i dieci
file di evidence, la redazione dei log, il cleanup e il readback finale. Nessun
rerun o build è stato avviato dalla review.

Worktree candidato pulito al commit di sole evidence
`a771cee43b0c43ec844e60282ea764646905996e` (tree
`0bbfa93f961d72de2f4c547269afd6c641e10294`). Il source compilato resta
`96758b89`: diff dei file esterni a `docs/` vuoto, exit 0. Il runner originale
resta conservato e vincolato a tale SHA; nessun rerun dopo l’aggiornamento documentale.

Locator completo receipt/manifest:
`/Users/minxiang/.codex/outputs/task054-address-create-20261008/worker-build-runner-receipt.json`.
Tutti i log e receipt originali risiedono nella stessa directory; la capsule JSON
riporta nomi e hash. Artifact locali sotto il worktree candidato
`/Users/minxiang/.codex/worktrees/task054-worker-commerce-candidate/merchandise-control-admin-web/.open-next`.
