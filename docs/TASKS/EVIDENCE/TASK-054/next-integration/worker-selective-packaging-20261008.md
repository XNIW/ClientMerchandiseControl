# Worker selettivo — append packaging e symlink, 2026-10-08

Il packaging locale Wrangler è **PASS**, con review distinta **APPROVED**.
Non è una nuova build Next/OpenNext, uno smoke funzionale o un upload remoto.
Restano source `96758b899aac2ccde1a70aeda4bbe7983007fb18`, tree
`b75fe609cda8f53067cfe1cf1cb7782a9dba757b` e commit di sole evidence
`a771cee43b0c43ec844e60282ea764646905996e`; candidato pulito e non modificato.

Il manifest precedente descrive esattamente 2.012 file regolari. L'inventario
`lstat/readlink` completa separatamente i quattro symlink dentro
`.open-next/server-functions/default/.next/node_modules`:

| Link | Target relativo | Stato | File regolari del target nel manifest | Input Wrangler / parte multipart |
| --- | --- | --- | --- | --- |
| `read-excel-file-442857d11c22bfb7` | `../../node_modules/read-excel-file` | Directory interna valida | 50 | No / No |
| `write-excel-file-6e348ba6e49c728e` | `../../node_modules/write-excel-file` | Directory interna valida | 80 | No / No |
| `unzipper-esm-58d57714355aaea9` | `../../node_modules/unzipper-esm` | Directory interna valida | 18 | No / No |
| `sharp-20c6a5da84e2135f` | `../../node_modules/sharp` | Target interno assente | 0 | No / No |

Nessun link è stato eliminato o corretto. Il mapping di sharp è già incorporato
nell'handler compilato: il solo link dangling non riproduce un difetto runtime.

Un unico `wrangler deploy --dry-run --env staging --minify --keep-vars` ha prodotto
outdir, metafile e multipart, usando Node 22.23.3 e Wrangler 4.123.0. Config esplicita,
autoconfig disattivato, nessun comando build custom o container. Il processo e i figli
sono stati eseguiti dal sandbox macOS con `deny network*`; metriche disabilitate.
Exit **0**, **1,689 s**, marker terminale `--dry-run: exiting now.`. Il lease è
stato rilasciato subito al termine, senza server avviato o comandi ancora attivi.

Il codice Wrangler installato conferma che dry-run salta autenticazione, controlli
remoti pre-upload, sync degli asset e deploy/trigger. Costruisce localmente il form.
Il metafile ha **42 input**: **11 file** già presenti e verificati nel manifest
originale più **31 wrapper virtuali** `node-built-in-modules:*`. Nessuno dei quattro
link o delle loro directory target è un input separato del packaging Wrangler.

Il multipart locale contiene soltanto `metadata` e `worker.js`. Quest'ultimo è
byte-identico al bundle emesso: **11.307.949 byte**, SHA256
`e1b2f30e3e1413e0404543cf2ddf21bb14157b9aa339121d8b3ba47d01542997`.
Multipart: **11.310.643 byte**, SHA256
`a3139836a17bc3be15e8269a8e3f8a5daabee0bf31be6d5afb9e2c5069da60a6`.
La sourcemap emessa resta un artifact diagnostico locale, assente dalle parti del
multipart. Gli asset sono validati separatamente: **53 file e 5 directory**; il log
Wrangler conta 58 percorsi prima di escludere le directory. Nessun asset è caricato;
il token di upload asset è assente, come previsto nel dry-run. Questo form non
attesta il futuro payload remoto o i suoi binding riservati.

Il bundle conserva cinque riferimenti esterni a package: `read-excel-file`,
`write-excel-file`, `@opentelemetry/api`, `@img/sharp-libvips-dev/include` e
`@img/sharp-libvips-dev/cplusplus`. Non sono moduli multipart separati. Raggiungibilità
e supporto dei relativi percorsi runtime restano **NOT_RUN**: il successo del
packaging e il precedente smoke non li qualificano. Nessun guasto runtime è dedotto.

Tutti i 2.012 file originali sono invariati, senza aggiunte/rimozioni; anche i quattro
link, lockfile, configurazione e handler sono invariati. Le impronte distinte sono:

| Oggetto | SHA256 |
| --- | --- |
| Handler OpenNext compilato, `.open-next/server-functions/default/handler.mjs` | `6aa3dff35b2b80352c8d36555d5e7ef226d397bbe55105fbb4584d327c6a6345` |
| Dipendenza ripristinata, `node_modules/@opennextjs/aws/dist/core/requestHandler.js` | `d9d67f62e82d9f51c9afc22cbe74750a5933e06dfb02a748c1d4db0522bf04a7` |

Originali protetti fuori Git:
`/Users/minxiang/.codex/outputs/task054-address-create-20261008/worker-packaging-96758b89/`.
`receipt.json` conserva comando/exit/pre-post; `stdout.log` è sanitizzato;
`esbuild-metafile.json`, `worker-upload.multipart`, `closure.json` e `deny-network.sb`
completano la prova. Hash e locator sono nel JSON associato. Il reviewer distinto
ha verificato multipart, input, asset, symlink e tutti i file originali senza rerun.
Deploy, SQL, autenticazione TEST e accettazione runtime restano **NOT_RUN**.
