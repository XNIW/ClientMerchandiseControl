# Evidence TASK-028

Snapshot di handoff:
`VALIDATED_PENDING_INTEGRATED_REVIEW / EXECUTION /
CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`.

## Revision set

- Admin/Supabase: `119169375fa477995b41c34b3766deca32fec056`, branch
  `integration/storefront-v1`, PR #67 draft.
- Client runtime: `1855100f34a3563787b1ac71eafb4af60a1b72e6`, branch
  `integration/storefront-v1`, PR #5 draft.
- Migration: `20260803050000_storefront_v1_customer_order_history`.
- Staging exact SHA: run `30787890770`, 1 min 32 s; migration artifact
  `storefront-v1-staging-migration-30787890770-1`, ID `8845914762`, SHA-256
  `4d6abb98931d6d431e1fb7bdd9478e53402104ca30065165b4f9d3699c11b29f`;
  verification artifact `task-028-customer-order-history-1`, ID `8845928446`,
  SHA-256 `ce89e37b17a078468db259158e9c00f7b950146bc20ee78aa75378ea20edf748`.
- Production: nessun comando write/deploy; Storefront/orders/reservations/delivery/
  push/payment restano OFF.

## Contratto implementato

- list/detail/timeline sono RPC strict owner/shop-scoped, autenticate, bounded e
  paginate con cursor stabile `(placed_at,id)`; anon, identità anonima, cross-user e
  cross-shop falliscono chiuso senza rivelare esistenza;
- card e detail espongono snapshot order immutabili e timeline pubblica ordinata;
  tenant, owner, stock preciso, costo, token, path interni, metadata event/POS e dati
  fiscali non entrano nella response o nella UI;
- cancellation è disabilitata per default, controllata da finestra server e valida
  stato/versione sotto lock; event, outbox POS-neutral, ledger e rilascio ATP/slot sono
  atomici e un retry con la stessa key restituisce lo stesso risultato;
- il Client usa repository allow-list, cache bounded read-only owner/shop-scoped,
  pending cancel persistita, recovery timeout/offline, refresh e identity purge;
- lista, detail, timeline, empty/error/offline, cancellazione e deep link autenticato
  sono localizzati in es-CL/it/en/zh-Hans e verificati su compact/tablet, light/dark e
  text scale 200%; nessuna regola client decide stato o cancellabilità.

## Comandi e risultati

| Gate | Comando/evidence | Exit | Durata/risultato | Stato |
|---|---|---:|---|---|
| Admin install | `npm ci` | 0 | 8,68 s; 0 vulnerability | PASS |
| Admin migration replay | `supabase db reset` | 0 | 27,47 s; tutte le migration applicate | PASS |
| pgTAP TASK-028 locale | `supabase test db supabase/tests/storefront_v1_customer_order_history.sql` | 0 | 30/30; 1,26 s | PASS |
| Concurrency cancel locale | `storefront-v1-customer-order-cancel-concurrency.sh` | 0 | un winner/un loser fail-closed; 1,20 s | PASS |
| Admin foundation | worktree POS esplicito + `npm run test:foundation` | 0 | 845 pass, 2 skip; 12,09 s | PASS |
| Admin verify | `npm run verify` | 0 | lint/typecheck/security/build; 22,85 s | PASS |
| Supabase lint | `supabase db lint --local --level warning` | 0 | 1,65 s; soli warning storici fuori TASK-028 | PASS |
| Admin CI | run `30787892745` | 0 | Verify + migration/pgTAP sullo SHA esatto | PASS |
| Cloudflare build | run `30787892757` | 0 | build e smoke sullo SHA esatto | PASS |
| Staging exact SHA | run `30787890770` | 0 | 1 min 32 s; apply/postverify/30 pgTAP/race/cleanup | PASS |
| Client gate canonico | `bash scripts/check.sh` | 0 | format 240/0, analyze 0 issue, build Android/iOS | PASS |
| Client unit/widget + coverage | gate canonico | 0 | 526/526; 11.123/14.388 = 77,31% | PASS |
| Client performance | tag performance, concurrency 1 | 0 | 1/1; cache 25.000 righe | PASS |
| Android integration | `customer_order_history_flow_test.dart`, API 35 | 0 | 1/1; build/install/tap history/detail/cancel; 20,17 s | PASS |
| iOS integration | stesso flow, iPhone 17 Pro iOS 26.5 | 0 | 1/1; build/install/tap; 29,92 s | PASS |
| Android debug + smoke | build/install/launch/log scan | 0 | cold launch 1.675 ms, PID 13994, zero fatal | PASS |
| iOS debug + smoke | build/simctl install/launch/process check | 0 | PID 41760, zero crash | PASS |
| Security source | Client/Admin scan | 0 | 542 file Client; zero secret/config/artifact vietati | PASS |
| Client CI exact SHA | run `30787721420` | n/a | tre job, zero runner/step; billing/spending limit | BLOCKED |
| ShellCheck script race | `shellcheck ...` | 127 | tool non installato; `bash -n` exit 0 | NOT_RUN |
| Integrated review | freeze futuro | n/a | non ancora raggiunto | NOT_RUN |

## Matrice CA -> evidence

| Criterio | Evidence | Stato |
|---|---|---|
| CA-01 | RPC owner/shop, keyset e response allow-list pgTAP | PASS |
| CA-02 | event append-only, version monotona e timeline ordinata | PASS |
| CA-03 | cache bounded, identity purge, offline/restart/reconnect | PASS |
| CA-04 | parser/deep link strict, auth queue e cross-owner fail-closed | PASS |
| CA-05 | policy, stale version, replay/conflict e race due sessioni | PASS |
| CA-06 | widget e integration lista/detail/timeline/refresh/cancel | PASS |
| CA-07 | quattro locale, CLP, dark, 200%, compact/tablet e Semantics | PASS |
| CA-08 | gate locali, CI Admin, staging e smoke mobile headless | PASS |
| CA-09 | scan sorgente; production non invocata e flag OFF | PASS |

## Matrice T-NN -> risultato

| Test | Risultato | Stato |
|---|---|---|
| T-01 | owner ammesso; anon/cross-user/cross-shop negati | PASS |
| T-02 | keyset deterministico, limite 50 e zero field interno | PASS |
| T-03 | online seed, offline read, restart e reconnect refresh | PASS |
| T-04 | deep link valido/invalido, auth, logout e identity switch | PASS |
| T-05 | cancel disabled/allowed, stale, replay, conflict e race | PASS |
| T-06 | matrix widget/a11y/l10n senza overflow | PASS |
| T-07 | Android/iOS flow con tap, build, install e launch | PASS |
| T-08 | staging exact-SHA, cleanup, CI e production unchanged | PASS |

Il run staging `30787391157` fu cancellato prima di ogni step dalla coda migration.
Il run `30787708864` diagnosticò un delta misto: predecessor già applicato e sola
migration TASK-028 pending. Il workflow è stato corretto per provare il delta reale e
il run finale `30787890770` è integralmente verde. Nessun retry cieco, GUI, dato cliente
o write production è stato usato.
