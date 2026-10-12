# CI f326 — handoff dei due job runtime iOS

**BLOCKED per QA nativa finale**: entrambi i job assegnati sono terminali **FAIL124 prima dell’app**, nello stesso inventario globale dopo il boot su due runner distinti. Smoke, cattura e verifica del journal Keychain non sono stati eseguiti. Gli artifact sono stati letti e verificati: contengono **zero PNG**, non le137+4 immagini richieste. Nessun nuovo retry, dispatch o source patch è stato eseguito dopo questi risultati.

## Revisione e ownership

Run **37848510649**, attempt **1**, checkout effettivo **f326faa19af29399d54c8e7de2867e86ee6ebecb**, confermato indipendentemente dai log di entrambi i job. Source candidato **d4a7e97ff4ef9f05b7932019e10813eddfd046de**, freeze app **16e46817d9da5f4a5ce0fbca89137f2652f52b56**.

Entrambe le receipt conservano `GITHUB_SHA` event/merge **ae5a8d9282c75d994f1a407c0a1b15d26b7ffcea**, distinto dal checkout. API commit: parent **bfbfc0b6a7122f29b8d8f6e2c2263d77b252749c** e **f326faa19af29399d54c8e7de2867e86ee6ebecb**. Tree merge e checkout identici **9247cde201471e57c5c188dcf3bd8ead303ff8ca**. Questa associazione non modifica né corregge retroattivamente il contesto ownership registrato.

Toolchain dichiarata Flutter3.44.8/Xcode26.6; entrambi i device propri hanno runtime receipt iOS26.5. Il target minimo14 resta invariato: un runtime recente non attesta esecuzione reale su iOS14. Non sono stati usati simulatori, build o dispositivi locali del MacN.

## Esiti reali separati

| Job / runner | Build e bundle | Prepare | Gate app | Cleanup |
|---|---|---|---|---|
| journal113555309631 /1000004460 | build non prevista prima del Prepare; toolchain e unit PASS | FAIL124 postboot inventory globale | Keychain tra due processi NOT_RUN | due receipt resourcePASS e stepPASS |
| debug113555309494 /1000004459 | Simulator buildPASS, bundle securityPASS | FAIL124 postboot inventory globale | smokeNOT_RUN, captureNOT_RUN | due receipt resourcePASS e stepPASS |

Il primo journal è conservato in `ci-f326-journal-first-capsule.{md,json}`, review distinta **APPROVED_EVIDENCE_FIDELITY** con55 controlli autonomi PASS. Il suo intervallo comando stampato→FAIL è47.041052s wall-clock; non è una misura della sola wait interna. Non è stato eseguito retry del journal.

Nel debug, il job parte alle **21:41:25Z**. Build termina21:48:48Z, bundle security21:50:58Z; Prepare dura21:50:58→21:56:17Z. Il solo device proprio è **24143C63-D712-43E8-9AD5-9B4E63120F92**. Dopo create e inventario iniziale, boot viene richiesto21:51:03.833242Z. `bootstatus -b` parte21:51:34.106484Z e stampa **Finished21:55:06.699028Z**. Il successivo globale `xcrun simctl list devices --json` è visualizzato21:55:16.788788Z. Alle21:55:54.516894Z compare `PermissionError`, errno1, operazione `kernelGroupProbe`, PGID proprio31889; alle21:55:55.959478Z compare **FAIL: timeout dopo30s**. Prepare termina exit124 alle21:56:17.183756Z.

L’intervallo comando stampato→FAIL nel debug è **39.170690s wall-clock**. Il limite inventario resta30s; la wait interna monotonic non è registrata. Non è disponibile trace indipendente sufficiente per classificare leader attivo/terminato, pipe ereditate, EPERM contro zombie o quiescenza dei discendenti. La causa precisa del blocco CoreSimulator/process wrapper resta **NOT_VERIFIED**; la fase fallita è dimostrata. Entrambi i fallimenti avvengono prima di Flutter/app, non provano regressione app/engine/auth/entitlement.

Il job debug termina in circa15minuti, entro il cap35minuti. Le annotation riportano exit124, oltre ai warning Node20→24 e capacity macOS; **nessuna annotation di limite budget job**. Il precedente limite30minuti della CI43 rimane distinto e non è la causa di questo fallimento.

## Cleanup, artifact e preview

Il debug esegue cleanup inline: inventario, shutdown del solo UUID proprio, delete dello stesso UUID e inventario finale. Il successivo cleanup esplicito termina SUCCESS21:56:18Z. La receipt artifact registra due tentativi `result=PASS`, `resourceCleanup=PASS`, `processCleanupFailed=false`, aggregato `cleanup=PASS`. I due journal cleanup hanno gli stessi esiti registrati. Il flag false significa nessun fallimento process cleanup registrato; **non è prova indipendente della quiescenza dei gruppi**. Non si promuove il diagnostico EPERM a prova di zombie o processo attivo.

- Raw artifact **11581797444**, `task054-ios-visual-fixtures`: ZIP808byte, SHA256 **dffe5da84d9b6a5b56013722769f9bbb78f946d8198f03598d28c2afeda06b67**. Download completo exit0; hash locale identico a metadata/upload e CRC dell’intero ZIP PASS. Esattamente2memberJSON: `ios-owned-receipt.json` e `ios-visual-step-result.json`; quest’ultimo registra `visualStepOutcome=skipped`. **Zero PNG**.
- Preview artifact **11580689097**, `task054-ios-visual-previews`: ZIP478byte, SHA256 **d1775317639688500590bf3b229388367df4d4fca32b4486be3c221eaab6c643**. Download completo exit0, digest e CRC ZIP PASS. Un solo member `manifest.json`; `sourceCheckout=f326faa...`, `status=NOT_RUN`, reason=`nessuna cattura raw disponibile`, `files=[]`, rawCounts visual0/os0 e previewCounts visual0/os0. Log `IOS_PREVIEW_RESULT=NOT_RUN` coerente.

Lo step di packaging/upload termina SUCCESS perché conserva onestamente il manifest NOINPUT. Non ha eseguito resampling né convalidato rendering. La review source del preview resta **APPROVED_SOURCE_CODE_ONLY**, scope trasporto; i benchmark sintetici precedenti non sono pixel nativi. **Review pixel137+4 NOT_RUN**, reviewer riservato rilasciato senza inventare immagini o riusare screenshot Android.

Il primo tentativo locale di leggere il log debug è stato rifiutato dal filtro escape ANSI del CLI, exit1; conservato come lettura locale, non gateCI. La lettura privata con `gh api --allow-escape-sequences` termina exit0 in3.598141s,87842byte. Raw immutato e copia separata senza ANSI/BOM persistiti. Non sono stati stampati token o redirect firmati; gli artifact piccoli sono stati acquisiti senza utility selettiva.

## Limiti storici e utility privata

La CI43 rimane un checkpoint precedente: smoke realePASS ma test recensione UIFAIL e cancellazione budget distinti. L’overflow24px esiste nel raw storico; la sua causa precisa sul device storico resta **NOT_VERIFIED**. Il difetto geometrico del fixture helper è stato riprodotto e corretto con test separati; il geometry logger e il comportamento corretto sul nativo finale sono **NOT_RUN**, perché questa CI si ferma prima dell’app. Nessun risultato sintetico viene promosso a conferma nativa di quella causalità.

La utility privata fuoriGit `tools/artifact_range_reader.py` non è mai stata usata su GitHub, token reale o artifact reale.38 unit locali PASS, ma review distinta **CHANGES_REQUIRED_SOURCE_CODE_ONLY** rileva **ARR-SECONDARY-001/P2**: SIGTERM del reader può lasciare vivo il subprocess auth sintetico proprio, in sessione separata. PoCRED conservato, cleanup dei processi propri PASS per reviewer. Utility ritirata dall’uso; nessun fix fuori scope è necessario per questa consegna senzaPNG. Il finding non riguarda il source preview approvato né il codice canonico/CI. Nessuna autenticazione reale o disclosure è affermata.

## Prerequisito e chiusura operativa

Il coordinatore ha deciso **nessun rerun invariato**: due host finali mostrano lo stesso confine postboot inventory e i tre esperimenti CLI autorizzati sono già terminali e preservati. Il prerequisito di QA è un host hosted che completi realmente il Prepare canonico con identità e ownership verificate, seguito su un candidato congelato dallo smoke app, dalla cattura completa137fixture+4OS e review pixel iOS, e dalla verifica journal Keychain attraverso due processi. Timeout, target minimo14 e ownership restano invariati. Un nuovo tentativo richiede istruzione/coordinamento espliciti, non un retry automatico di questa capsula.

Entrambi i job iOS assegnati sono terminali; non resta CI iOS pending. Il monitor read-only registra697.156714666s monotonic e i due stati terminali; il suo exit0 e la terminalità complessiva dei comandi locali sono **reported by executor** dai tool output, non attestati autonomamente dal solo monitor receipt. I sette receipt recenti di acquisizione presenti registrano esplicitamente `reaped=true`; il probe locale successivo trova assenti tutti quei sette PID propri. Questa verifica non estende il reap alle acquisizioni precedenti prive di receipt comando, già qualificate reported nella capsula journal. Il PoC utility è stato ripulito dal reviewer. Nessun processo app/simulatore locale è stato creato. Resta il limite già esposto: la quiescenza indipendente dei gruppi sul runner remoto non è provata dalle sole receipt canoniche.

QA finale iOS, runtime reale14, IME/AT e acceptance TEST autenticata restano lane separate non promosse. Nessuna modifica al repository o alla PR è stata fatta in questa raccolta read-only. Raw concisi sanitizzati perGit solo in questa capsula; log completi, ZIP e test privati restano fuoriGit0700/0600.

## Mapping della prova

- `raw/final-f326/simulator-hosted.raw` — 87842byte, SHA256 `8e0dfa36308bee4178f255a56a8fc4f1b665269ee2603a3684d649b87ab48bb4`.
- `raw/final-f326/simulator-hosted.log` — 87388byte, SHA256 `bfa32aec76ed3dd2b730a72d44e207ea4497bf655e21e8e5f0233edb90091ea6`.
- `raw/final-f326/simulator-status.json` — 4007byte, SHA256 `34975118b5076d4c1a062e1ae4ccb9065364c4a5154968954f6b82b43598ce5f`.
- `raw/final-f326/simulator-annotations.json` — 1246byte, SHA256 `21dbc3bd685802ece17cc306fcba3eabc5be537112356ba009764ff5d8c0c149`.
- `raw/final-f326/simulator-log-acquisition.json` — 301byte, SHA256 `e4a69cd9eb0f277624c3f1d15d4d1c48426cadafaaca4aba7531ff32af0fe209`.
- `raw/final-f326/visual-raw.zip` — 808byte, SHA256 `dffe5da84d9b6a5b56013722769f9bbb78f946d8198f03598d28c2afeda06b67`.
- `raw/final-f326/visual-raw-acquisition.json` — 472byte, SHA256 `f79200f30aa8d12c7399e242e73157ad97db9d95d0e8a9807d045528b17c035f`.
- `raw/final-f326/visual-raw-artifact/ios-owned-receipt.json` — 792byte, SHA256 `d756645313c639f3c9cbdb2b5f47dcda38bf51b487613d1c78f0aa30b0e1d88d`.
- `raw/final-f326/visual-raw-artifact/ios-visual-step-result.json` — 141byte, SHA256 `7ee9a1baa7db586d7f1c1e6e76cf35524a8af5da8f53931cdaab4ba26a0317b0`.
- `raw/final-f326/visual-preview.zip` — 478byte, SHA256 `d1775317639688500590bf3b229388367df4d4fca32b4486be3c221eaab6c643`.
- `raw/final-f326/visual-preview-acquisition.json` — 428byte, SHA256 `0d859678cf03f3583d53f96a06884d1ffba137b5563fab5ac584856484dd4650`.
- `raw/final-f326/visual-preview-artifact/manifest.json` — 551byte, SHA256 `c9c47702f48cba4a460ec3cfd585b4bfa04b188a17c2e4213795e4b01836edf4`.
- `raw/final-f326/event-merge-commit.json` — 2710byte, SHA256 `d6ae58c7019480823b75dad0e3415b1cbef8a03404f3e339351a5eba9636f8c5`.
- `raw/final-f326/monitor-terminal-receipt.json` — 1843byte, SHA256 `12b7516270a817d2459eebd4791f8072b95d16a710b9c4096bb738347d6878e3`.
