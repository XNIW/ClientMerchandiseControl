# TASK-034 — Matrice canonica di resilienza

## Legenda

- `PROTECTED`: il comportamento è implementato e collegato a test eseguiti;
- `GAP`: comportamento assente o non deterministico da correggere;
- `EXTERNAL`: richiede capability esterna, con fallback verificabile;
- `UNTESTED`: nessuna evidence ancora eseguita; nessun critical può restare tale;
- esiti finali ammessi nelle evidence: `PASS`, `FAIL`, `NOT_RUN`, `BLOCKED`.

Evidence condivise:

- `CLIENT-314`: suite mirata Auth/Storefront cache/immagini/Catalogo/Carrello/Hold/
  Checkout/Ordini/notification routing/deep link/tracking, 314 test, exit `0`;
- `DB-483`: 10 file pgTAP commerce/tracking, 483 assertion, exit `0`;
- `DB-RACE-11`: 11 harness concorrenti Storefront/Admin/POS, tutti `PASS`/exit `0`;
- `REPEAT-90`: 10 iterazioni per 9 race client critiche, 90 esecuzioni, exit `0`.

Ogni riga registra authority, chiave idempotente, versione attesa quando applicabile,
retry, riconciliazione, test ed esito. `PASS` indica comando reale verde sulla revisione
TASK-034, non sola ispezione statica.

| Area | Caso | Criticità | Authority/idempotency/version | Retry e riconciliazione attesi | Test/evidence | Stato |
|---|---|---|---|---|---|---|
| Auth | cold start offline con sessione cached | critical | sessione Supabase persistita; nessuna mutazione client | restore bounded; sessione scaduta non espone identità | `CLIENT-314`: auth controller/repository restore + expiry | PASS |
| Auth | token scaduto e refresh concorrente | critical | Supabase Auth; persistenza serializzata | eventi pubblicati solo dopo storage; ultimo refresh prevale | `CLIENT-314`: `supabase_auth_repository_test.dart` | PASS |
| Auth | logout con request in corso / cancellazione | critical | account generation e compensazione sign-out | completion vecchia ignorata, sessione purgata | `CLIENT-314`, `REPEAT-90`: auth controller | PASS |
| Auth | cambio account con cache/realtime | critical | owner subject + generation | cleanup prima del cambio; nessuno stato cross-account | `CLIENT-314`: auth/cart/checkout/orders/tracking | PASS |
| Auth | callback/deep link prima, durante, dopo auth o duplicato | high | callback PKCE canonico e flow token | cold fuori flow ignorato; duplicato consumato una volta; expiry 5 min | `CLIENT-314`, `REPEAT-90`; scheduler manuale | PASS |
| Catalogo | cache cold/warm/stale, offline e reconnect | high | Storefront read-only + catalog version | stale-while-revalidate bounded e refresh manuale autorevole | `CLIENT-314`: `storefront_cache_*_test.dart` | PASS |
| Catalogo | refresh/pagination multipli concorrenti | high | cursor keyset server + generation | append single-flight e merge deduplicato | `CLIENT-314`: catalog controller | PASS |
| Catalogo | query o category/filter precedente completa dopo nuova | high | generation per query/filter | completion precedente ignorata | `CLIENT-314`, `REPEAT-90`: catalog controller | PASS |
| Catalogo | immagini lente/fallite | medium | URL, MIME, digest e byte budget allow-listed | placeholder/fallback; stream oversized interrotto | `CLIENT-314`: verified image loader + widget | PASS |
| Catalogo | catalog version change | high | catalog version server/cache | write atomica e invalidazione di versioni incoerenti | `CLIENT-314`: Drift/cache recovery | PASS |
| Carrello | add/remove/update concorrenti e doppio tap | critical | RPC server; idempotency key + expected version | coda seriale, un solo side effect, conflict esplicito | `CLIENT-314`, `DB-483`, `DB-RACE-11`, `REPEAT-90` | PASS |
| Carrello | restart, account merge e isolamento account | critical | owner/server; guest snapshot pubblico | merge elimina guest solo dopo ack; namespace isolato | `CLIENT-314`: cart controller/Drift | PASS |
| Carrello | offline mutation e reconnect | critical | server authority; intent persistito prima dell'RPC | stessa key al retry e revalidation esplicita | `CLIENT-314`, `DB-483`: cart/hold | PASS |
| Carrello | reprice, unavailable, hold expiry, quantity conflict | critical | availability/hold/quote server | sei stati commerciali tipizzati, release una volta | `CLIENT-314`, `DB-483`, `DB-RACE-11` | PASS |
| Carrello | duplicate key o stale response | critical | idempotency + expected version/generation | replay senza side effect; risposta account vecchio scartata | `CLIENT-314`, `DB-RACE-11`, `REPEAT-90` | PASS |
| Checkout | doppio submit | critical | create-order RPC/idempotency | richiesta in-flight condivisa; un solo ordine | `CLIENT-314`, `DB-483`, `DB-RACE-11`, `REPEAT-90` | PASS |
| Checkout | timeout ambiguo o risposta persa | critical | lookup ordine + medesima key/versione | recovery server prima di nuova create | `CLIENT-314`: checkout controller/repository | PASS |
| Checkout | resume/restart con submit pending | critical | draft scoped con intent idempotente | resume e receipt deterministici, record corrotto eliminato | `CLIENT-314`: checkout draft/controller | PASS |
| Checkout | price/stock/address/slot change | critical | quote/hold/slot server + expected version | revalidation ed errore typed/actionable | `CLIENT-314`, `DB-483`, `DB-RACE-11` | PASS |
| Checkout | payment pending/callback-webhook duplicato | critical | payment intent/server mutation idempotente | replay restituisce stesso payment/order, nessun fiscale duplicato | `DB-483`, `DB-RACE-11` | PASS |
| Checkout | order già creato | critical | read owner-scoped per idempotency/order ID | receipt recuperata, submit non ripetuto | `CLIENT-314`, `DB-483` | PASS |
| Ordini | list/detail refresh e pagination race | high | cursor server + request generation | refresh serializzato; boundary deduplicato | `CLIENT-314`: order controller | PASS |
| Ordini | cancellation duplicate/timeout ambiguo | critical | cancel RPC/key/expected status version | stessa key al retry; release/outbox una volta | `CLIENT-314`, `DB-483`, `DB-RACE-11`, `REPEAT-90` | PASS |
| Ordini | status event fuori ordine/stale | critical | status version/event ledger server | state machine monotona, stale writer perde | `DB-483`, `DB-RACE-11`: customer/admin order | PASS |
| Ordini | push/deep link duplicati | high | route resolver owner-scoped + cache bounded | coalescing duplicate; cold/warm intent non duplica navigazione | `CLIENT-314`: notification route + deep link | PASS |
| Ordini | detail cached offline/reconnect | high | cache owner/shop-scoped read-only | dettaglio resta leggibile e poi viene sostituito dal server | `CLIENT-314`: order cache/controller/widget | PASS |
| Tracking | realtime disconnect/reconnect e polling fallback | critical | snapshot owner-scoped server | una subscription; polling bounded; Realtime sano arresta fallback | `CLIENT-314`: scheduler manuale tracking | PASS |
| Tracking | snapshot duplicate/out-of-order/stale | critical | sequence/version + observed-at server | monotonicità; freshness esatta a deadline (`>=`) | `CLIENT-314`: tracking controller/repository | PASS |
| Tracking | terminal event race e redaction | critical | lifecycle RPC/state machine | terminale prevale e la posizione non riappare | `CLIENT-314`, `DB-483`, `REPEAT-90` | PASS |
| Tracking | courier reassignment/session expiry | critical | assignment/session/version server | writer precedente rifiutato; sessione scaduta redatta | `DB-483`: 60 assertion delivery tracking | PASS |
| Tracking | logout/account switch/background/foreground | critical | auth generation + route lifecycle | teardown/cache purge; resume rearma una sola runtime | `CLIENT-314`, Fix tracking `19/19`, `REPEAT-90`: A→null/A→B/dispose con fallback attivo e zero task residui | PASS |
| Tracking | map failure/external carrier URL failure | high | adapter fail-closed + URL HTTPS pubblica allow-listed | fallback testuale/accessibile, nessun marker non verificato | `CLIENT-314`: map adapter/live map/repository | PASS |
| Admin/POS | transition concurrency/duplicate/stale version | critical | RPC/key/expected version | un solo event/audit/outbox/receipt | `DB-483`, `DB-RACE-11`: admin order | PASS |
| Admin/POS | POS handoff retry o timeout dopo commit | critical | inbox/key/lease/ack | claim/reclaim e ack replay deterministici | `DB-483`, `DB-RACE-11`: POS handoff | PASS |
| Admin/POS | reservation release duplicate | critical | release RPC/idempotency ledger | una sola compensazione ATP/slot | `CLIENT-314`, `DB-483`, `DB-RACE-11` | PASS |
| Admin/POS | terminal status replay | critical | state machine + status version | replay identico; transizione regressiva rifiutata | `DB-483`, `DB-RACE-11` | PASS |

## Repeat/stress

Le nove race client critiche sono state ripetute 10 volte (`REPEAT-90`) con `Completer`,
`ManualAppScheduler` o generation guard; le race server sono state eseguite da 11
harness con writer realmente concorrenti (`DB-RACE-11`). Nessuna asserzione funzionale
aggiunta da TASK-034 dipende da `sleep` o da una soglia wall-clock.
