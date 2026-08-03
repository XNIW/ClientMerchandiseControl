# Evidence TASK-027

Snapshot di handoff:
`VALIDATED_PENDING_INTEGRATED_REVIEW / EXECUTION /
CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`.

## Revision set

- Admin/Supabase: `599511c03cb502b9b76561ff320cfdbb4073b1ee`, branch
  `integration/storefront-v1`, PR #67 draft.
- Client runtime: `64c8f711547f8d5c5dc18650a03a9d5345bb71b7`, branch
  `integration/storefront-v1`, PR #5 draft.
- Migration aggregate: `20260803033000_storefront_v1_customer_orders`.
- Migration capacity: `20260803034500_storefront_v1_customer_order_capacity`.
- Staging exact SHA: run `30783882947`, attempt 2, job `91594158690`, artifact
  `storefront-v1-staging-migration-30783882947-2`, ID `8844663559`, SHA-256
  `ea8ae759e6af6fc1a194f8a0f9b168164fd0e19003bfaf046298c3f092e5ece3`.
- Production: nessun comando write/deploy; Storefront/orders/reservations/delivery/
  push/payment restano OFF.

## Contratto implementato

- aggregate customer order, item snapshot, first status event, outbox e mutation
  ledger sono privati, FORCE RLS e accessibili al mobile soltanto tramite RPC strict;
- create deriva owner/shop e tutti i valori economici dal server, rivalida quote,
  cart, catalogo, promozione, availability, hold e capacità sotto lock e committa una
  sola volta oppure non lascia aggregate parziali;
- un retry con la stessa key/payload restituisce lo stesso ordine; una key riusata con
  payload diverso confligge, mentre una nuova key sulla quote già consumata recupera
  l'ordine esistente;
- snapshot economico/fulfillment, item, status event e envelope outbox sono protetti
  da trigger immutabili/append-only; la response customer omette source product, hold,
  quote, cart, shop/user ID, costo, stock, token ed email;
- l'ordine cliente resta distinto dalla vendita fiscale: outbox POS-neutral e nessun
  insert in `pos_sales`;
- il Client persiste intent/idempotency/order ID, recupera receipt dopo timeout/restart,
  non svuota localmente il cart prima del successo e mostra totale server, codice,
  stato, fulfillment e righe in quattro locale.

## Comandi e risultati

| Gate | Comando/evidence | Exit | Durata/risultato | Stato |
|---|---|---:|---|---|
| Admin migration replay | `supabase db reset` | 0 | ~23 s; tutte le migration applicate | PASS |
| pgTAP TASK-027 | `supabase test db supabase/tests/storefront_v1_customer_orders.sql` | 0 | 35/35; 1,31 s | PASS |
| Concurrency order | `npm run test:storefront:customer-order-concurrency` | 0 | 1 fresh + 1 replay; 1,24 s | PASS |
| Admin foundation | worktree POS esplicito + `npm run test:foundation` | 0 | 845 pass, 2 skip; 11,93 s | PASS |
| Admin lint/typecheck/build/security | gate repository | 0 | 0 error; build 8,8 s | PASS |
| Supabase lint | `supabase db lint --local --level warning` | 0 | soli warning storici fuori TASK-027 | PASS |
| Admin CI | run `30783886282` | 0 | job eseguiti sullo SHA esatto | PASS |
| Cloudflare build | run `30783886269` | 0 | build sullo SHA esatto | PASS |
| Staging exact SHA | run `30783882947`, attempt 2 | 0 | 2 min 2 s; apply/postverify/pgTAP/race | PASS |
| Client gate canonico | `bash scripts/check.sh` | 0 | ~96 s; format 223/0, analyze 0 issue | PASS |
| Client unit/widget + coverage | gate canonico | 0 | 497/497; 9.531/12.477 = 76,39% | PASS |
| Client performance | tag performance, concurrency 1 | 0 | 1/1; cache 25.000 righe | PASS |
| Android integration | `customer_checkout_flow_test.dart`, API 35 | 0 | 1/1; tap order/replay/receipt | PASS |
| iOS integration | stesso flow, iPhone 17 Pro iOS 26.5 | 0 | 1/1; test body 10 s | PASS |
| Android debug + smoke | build/install/launch/uiautomator/logcat | 0 | PID 12528, MainActivity resumed, zero crash | PASS |
| iOS debug + smoke | build/simctl install/launch/log scan | 0 | PID 17376, zero crash | PASS |
| Security source | `scripts/check-client-security.sh` + Admin scan | 0 | 523 file Client; zero secret/config/artifact vietati | PASS |
| Client CI exact SHA | run `30784085502` | n/a | 3 job, zero runner/step; billing/spending limit | BLOCKED |
| Integrated review | freeze futuro | n/a | non ancora raggiunto | NOT_RUN |

## Matrice CA -> evidence

| Criterio | Evidence | Stato |
|---|---|---|
| CA-01 | quote confirmed owner-scoped e create/read RPC pgTAP | PASS |
| CA-02 | row/advisory lock, revalidation e ATP/capacity helper | PASS |
| CA-03 | aggregate/event/outbox/consume atomici e rollback negative | PASS |
| CA-04 | firma RPC senza input economici e malicious-response tests | PASS |
| CA-05 | replay, conflict e new-key consumed-quote recovery | PASS |
| CA-06 | due sessioni: un order/outbox/mutation e stock invariato | PASS |
| CA-07 | trigger immutabilità e response allow-list | PASS |
| CA-08 | unit/widget/integration Android/iOS e cart refresh post-success | PASS |
| CA-09 | FORCE RLS, anon/cross-user denied e mobile table grants assenti | PASS |
| CA-10 | gate locali, Admin CI, staging e smoke headless | PASS |
| CA-11 | scan sorgente; production non invocata e flag OFF | PASS |

## Matrice T-NN -> risultato

| Test | Risultato | Stato |
|---|---|---|
| T-01 | owner create/read; anon e cross-user negati | PASS |
| T-02 | server reprice e firma priva di totale/customer/shop | PASS |
| T-03 | order/item/event/outbox/consume nello stesso commit | PASS |
| T-04 | duplicate/retry/key conflict e un solo aggregate | PASS |
| T-05 | catalog change non riscrive snapshot; no leakage | PASS |
| T-06 | receipt, timeout/recovery, cart clear post-success | PASS |
| T-07 | Android/iOS tap reali fino alla receipt | PASS |
| T-08 | staging exact-SHA, replay, cleanup e artifact | PASS |
| T-09 | replay/security/Git; CI Client esterna | PASS |

Il primo attempt staging fu cancellato senza step dalla concurrency queue condivisa;
l'attempt 2 sullo stesso SHA è integralmente verde. Il primo smoke Android non trovava
`adb` nel `PATH`; il path SDK assoluto ha chiuso il gate. Nessun retry cieco, GUI o dato
production è stato usato.
