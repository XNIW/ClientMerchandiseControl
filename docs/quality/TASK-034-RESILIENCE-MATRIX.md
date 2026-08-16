# TASK-034 — Matrice canonica di resilienza

## Legenda

- `PROTECTED`: il comportamento è implementato e deve essere collegato a test eseguiti;
- `GAP`: comportamento assente o non deterministico da correggere;
- `EXTERNAL`: richiede capability esterna, con fallback verificabile;
- `UNTESTED`: nessuna evidence ancora eseguita; nessun critical può restare tale;
- esiti finali ammessi nelle evidence: `PASS`, `FAIL`, `NOT_RUN`, `BLOCKED`.

Ogni riga deve registrare authority, chiave idempotente, versione attesa quando
applicabile, retry, riconciliazione, test ed esito. La classificazione iniziale resta
`UNTESTED` fino all'audit del codice e all'esecuzione reale.

| Area | Caso | Criticità | Authority/idempotency/version | Retry e riconciliazione attesi | Test/evidence | Stato |
|---|---|---|---|---|---|---|
| Auth | cold start offline con sessione cached | critical | sessione server; nessuna mutazione | UI bounded/offline, refresh alla reconnessione | da assegnare | UNTESTED |
| Auth | token scaduto e refresh concorrente | critical | Supabase Auth; single-flight | una refresh, failure chiusa | da assegnare | UNTESTED |
| Auth | logout con request in corso / cancellazione | critical | account generation | risposta vecchia ignorata e cache pulita | da assegnare | UNTESTED |
| Auth | cambio account con cache/realtime | critical | owner UID | teardown e nessun cross-account state | da assegnare | UNTESTED |
| Auth | callback/deep link prima, durante, dopo auth o duplicato | high | OAuth state/callback | route pendente consumata una volta | da assegnare | UNTESTED |
| Catalogo | cache cold/warm/stale, offline e reconnect | high | Storefront read-only/versione catalogo | SWR bounded e refresh autorevole | da assegnare | UNTESTED |
| Catalogo | refresh/pagination multipli concorrenti | high | cursor server | single-flight/merge deterministico | da assegnare | UNTESTED |
| Catalogo | query o category/filter precedente completa dopo nuova | high | generation query | stale completion ignorata | da assegnare | UNTESTED |
| Catalogo | immagini lente/fallite | medium | URL pubblico bounded | placeholder/retry senza bloccare lista | da assegnare | UNTESTED |
| Catalogo | catalog version change | high | versione server/cache | invalidazione controllata | da assegnare | UNTESTED |
| Carrello | add/remove/update concorrenti e doppio tap | critical | server; idempotency key/expected version | serializzazione, rebase o errore esplicito | da assegnare | UNTESTED |
| Carrello | restart, account merge e isolamento account | critical | cart owner/server | pending persistente, merge deterministico | da assegnare | UNTESTED |
| Carrello | offline mutation e reconnect | critical | server authority | coda bounded, stessa key, revalidation | da assegnare | UNTESTED |
| Carrello | reprice, unavailable, hold expiry, quantity conflict | critical | quote/availability server | stato esplicito e riconciliazione | da assegnare | UNTESTED |
| Carrello | duplicate key o stale response | critical | idempotency/expected version | replay senza side effect; generation guard | da assegnare | UNTESTED |
| Checkout | doppio submit | critical | create-order RPC/idempotency | stessa key e un solo ordine | da assegnare | UNTESTED |
| Checkout | timeout ambiguo o risposta persa | critical | server order lookup/key | recovery prima di retry | da assegnare | UNTESTED |
| Checkout | resume/restart con submit pending | critical | pending draft/key | resume deterministico | da assegnare | UNTESTED |
| Checkout | price/stock/address/slot change | critical | quote/hold server/versione | revalidation ed errore actionable | da assegnare | UNTESTED |
| Checkout | payment pending/callback-webhook duplicato | critical | provider/server payment intent | evento idempotente, ordine unico | da assegnare | UNTESTED |
| Checkout | order già creato | critical | server lookup | mostra receipt, non risottomette | da assegnare | UNTESTED |
| Ordini | list/detail refresh e pagination race | high | server/cursor/generation | completion vecchia ignorata | da assegnare | UNTESTED |
| Ordini | cancellation duplicate/timeout ambiguo | critical | cancel RPC/key/versione | recover/replay senza doppio effetto | da assegnare | UNTESTED |
| Ordini | status event fuori ordine/stale | critical | server event/versione | monotonicità | da assegnare | UNTESTED |
| Ordini | push/deep link duplicati | high | route intent dedup | destinazione unica/idempotente | da assegnare | UNTESTED |
| Ordini | detail cached offline/reconnect | high | cache owner-scoped | cache read-only poi refresh | da assegnare | UNTESTED |
| Tracking | realtime disconnect/reconnect e polling fallback | critical | snapshot server | backoff bounded, una subscription | da assegnare | UNTESTED |
| Tracking | snapshot duplicate/out-of-order/stale | critical | sequence/observed-at server | monotonicità e freshness controllata | da assegnare | UNTESTED |
| Tracking | terminal event race e redaction | critical | lifecycle RPC | posizione non riappare | da assegnare | UNTESTED |
| Tracking | courier reassignment/session expiry | critical | assignment/session server | vecchio writer rifiutato | da assegnare | UNTESTED |
| Tracking | logout/account switch/background/foreground | critical | auth generation/lifecycle | teardown, cache owner-scoped, rearm | da assegnare | UNTESTED |
| Tracking | map failure/external carrier URL failure | high | adapter/allowlist | fail-closed e fallback testuale | da assegnare | UNTESTED |
| Admin/POS | transition concurrency/duplicate/stale version | critical | RPC/key/expected version | un solo event/audit/outbox | da assegnare | UNTESTED |
| Admin/POS | POS handoff retry o timeout dopo commit | critical | inbox/key/lease | replay/ack deterministico | da assegnare | UNTESTED |
| Admin/POS | reservation release duplicate | critical | release RPC/key | una sola compensazione | da assegnare | UNTESTED |
| Admin/POS | terminal status replay | critical | state machine/versione | no regressione di stato | da assegnare | UNTESTED |

## Repeat/stress

Le race critiche verranno ripetute con `Completer`, clock/scheduler controllato o
primitive database concorrenti. Nessun test finale userà una soglia wall-clock come
asserzione funzionale.
