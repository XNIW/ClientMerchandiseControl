# Inbox — regressioni e lavoro widget, 8 ottobre 2026

Ricevuta del **sourcefreeze locale `3962414` + quattro file inbox**, eseguito nel
checkout isolato `/tmp/cmc-inbox-20261008`. I quattro SHA-256 riportati nel JSON
coincidono con le copie verificate e con il worktree root al momento della ricevuta.
La suite inbox ha **49 PASS**, exit 0; questo risultato non qualifica il candidato
integrato finale né i dieci benchmark canonici globali.

## Riproduzione e correzione

Il comando RED ha prodotto **8 FAIL e 1 PASS**, exit 1: tre destinazioni aspettavano
`markRead`; account, shop e A→B→A potevano ricevere una navigazione vecchia all'ACK;
un errore tardivo poteva riaprire la destinazione. Logout era già protetto.
La misura su 500 righe superava il budget di configurazioni widget.

L'apertura avviene ora al tap; `markRead` conserva il controller esistente e i suoi
confini owner/generation. Non esiste una navigazione differita all'ACK.
`ListView.builder` costruisce le configurazioni delle righe richieste dal viewport,
con filtri/stati/paginazione preservati e senza modifica del controller/backend.

## Budget e confronto

Obiettivo registrato **prima del fix**: al massimo 20 configurazioni e 20 build per
rebuild, crescita ≤2× passando da 25 a 500 righe. Il margine copre oltre due viewport
390×844 con le righe correnti e la cache del viewport; non è una soglia di latenza.
Nessun budget canonico preesistente è stato cambiato.

Misura su host Flutter widget/debug, locale es-CL, tema chiaro, testo 100%, fixture
interamente unread, pagine da 25 e cache/repository in memoria. Dopo caricamento di
tutte le pagine e stabilizzazione, cinque rebuild alternano il filtro unread senza
cambiare le righe. Condizioni e dataset sono uguali prima/dopo.

| Righe / pagine | Configurazioni prima, 5 campioni | Dopo, 5 campioni | Build prima/dopo | Richieste prima/dopo |
|---|---|---|---|---|
| 25 / 1 | 25,25,25,25,25 | 5,5,5,5,5 | 5 per campione | 1 / 1 |
| 500 / 20 | 500,500,500,500,500 | 5,5,5,5,5 | 5 per campione | 20 / 20 |

Dispersione zero nei campioni deterministici. La lista precedente disponeva già i
render object in modo lazy: il miglioramento verificato è **500→5 configurazioni
trattenute**, non una riduzione dei build, rimasti 5. Non si misurano frame time,
allocazioni complessive, memoria RSS, CPU o prestazioni del telefono; nessun percentile
viene ricavato da questi campioni.

## Comandi e log

I log locali sono estratti dagli stdout originali già registrati dai tool. La creazione
di questa ricevuta non ha rieseguito test, build o gate; la sessione completa non è
stata copiata. Hash, timestamp UTC e chunk di origine sono nel JSON associato.
I log integrali rimangono fuori Git.

| Verifica | Comando | Exit / risultato | Log locale |
|---|---|---|---|
| RED | `flutter test test/features/customer_notifications/customer_notification_inbox_navigation_test.dart test/features/customer_notifications/customer_notification_inbox_work_budget_test.dart --reporter expanded --concurrency=1` | 1 / FAIL, riproduzione | `/tmp/cmc-inbox-evidence-20261008/red.log` |
| GREEN | `flutter test test/features/customer_notifications --reporter expanded --concurrency=1` | 0 / PASS, 49 test | `/tmp/cmc-inbox-evidence-20261008/green.log` |
| Analyze | `flutter analyze` sui quattro file elencati nel JSON, `--no-pub` | 0 / PASS | `/tmp/cmc-inbox-evidence-20261008/analyze.log` |
| Format | `dart format` sui quattro file elencati nel JSON | 0 / PASS | `/tmp/cmc-inbox-evidence-20261008/format.log` |
| Diff | `git diff --check` nel checkout isolato | 0 / PASS | `/tmp/cmc-inbox-evidence-20261008/diff_check.log` |
| Byte equality | `shasum -a 256` sui quattro file, root e checkout isolato | 0 / PASS entrambi | `/tmp/cmc-inbox-evidence-20261008/hashes_root.log`, `hashes_isolated.log` |

Il JSON riporta i comandi completi e i quattro hash della sorgente testata.
Le regressioni di navigazione sono 8; il nuovo controllo di lavoro widget è 1 ed è
marcato `performance`, supplementare ai benchmark esistenti.

## Confine di accettazione

- Suite inbox di questo sourcefreeze: **PASS**.
- Benchmark globali sul candidato integrato finale: **NOT_RUN in questa ricevuta**;
  richiedono il freeze finale e l'esecuzione coordinata dal root.
- Profile/release su dispositivo fisico, TalkBack/VoiceOver, auth/backend live:
  **NOT_RUN in questa lane**; nessun risultato fixture ne costituisce prova.
- Nessun processo di verifica pendente. Nessuna modifica ad altri file di codice,
  contratti, budget o governance durante la produzione di questa ricevuta.
