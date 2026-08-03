# Storefront v1 — Release manifest

## Identità del train

- Release train: `STOREFRONT_V1`
- Governance: `ADR-011`
- Stato: `EXECUTION`
- Baseline Client: `6a50b421057a09d4152653a78512d268a7fa4d69`
- Review integrata: `NOT_RUN`
- Production modificata: `no`

## Revisioni coordinate

| Repository | Branch | SHA revisionato | PR | Versione schema | Versione API | Deployment staging | Feature flag | Ultimo gate | Prossimo checkpoint | Rollback |
|---|---|---|---|---|---|---|---|---|---|---|
| ClientMerchandiseControl | `integration/storefront-v1` | `1855100f34a3563787b1ac71eafb4af60a1b72e6` | `#5 DRAFT` | local cache v4 + checkout draft v2 + order cache v1 | `storefront.v1`, `customer.v1`, `customer-cart.v1`, reservation hold v1, checkout fulfillment v1, customer-order/history v1 | 526 test + benchmark 1/77,31%; history integration 1/1 Android/iOS e artifact smoke `PASS`; CI `30787721420` `BLOCKED` billing prima dei runner | production Storefront/orders/reservations/delivery/push/payment `OFF` | TASK-028 Client `PASS` tecnico | TASK-030 nessun Client writer previsto | revert commit/branch; feature flag OFF |
| merchandise-control-admin-web | `integration/storefront-v1` | `23bfab60b91ef192dbb726bde454287cea144c8f` | `#67 DRAFT` | `20260803053000` | `storefront.v1`, `customer.v1`, `customer-cart.v1`, availability/hold/checkout v1, customer-order/history/admin-orders v1 | CI `30798108711`; Cloudflare build `30798108767`; deploy `30796888108`; acceptance `30798109969`, tutti `PASS` | production `OFF`; cancellation/POS consumer default OFF | TASK-029 34/34, race e staging queue/transizione | TASK-030 POS claim/ack | migration additiva + consumer flag OFF |
| Win7POS | `integration/storefront-v1` | baseline `41cf4b8dddd86ed51a49c0b670c81eabe9700405` | `NOT_RUN` | n/a | POS handoff `NOT_RUN` | harness `NOT_RUN` | handoff `OFF` | release worktree fast-forward e pulito; checkout root dirty preservato | TASK-030 ACTIVE | disabilitare consumer e replay queue |
| MerchandiseControlSplitView | non creato; solo se modificato | `NOT_RUN` | `NOT_RUN` | n/a | n/a | n/a | n/a | checkout dirty preservato | nessuno corrente | nessuna modifica prevista |
| iOSMerchandiseControl | non clonato; solo se modificato | `NOT_RUN` | `NOT_RUN` | n/a | n/a | n/a | n/a | checkout assente | nessuno corrente | nessuna modifica prevista |

## Prelude authenticated foundation

- PR Client: `#4`, `MERGED`
- Merge SHA: `b2d70b5c32d9481749f985bb4179c00a02d9f822`
- Closeout SHA: `6a50b421057a09d4152653a78512d268a7fa4d69`
- CI closeout main: run `30714350425`, `PASS`, 3/3 job, annotation 0/0/0
- Redirect staging: `PASS`, callback canonica aggiunta senza rimuovere redirect
- OAuth live Android/iOS, restore, logout, relogin: `PASS`
- Production: invariata

## Feature flag production iniziali

| Flag | Stato |
|---|---|
| storefront_enabled | OFF |
| orders_enabled | OFF |
| reservations_enabled | OFF |
| delivery_enabled | OFF |
| push_enabled | OFF |
| online_payments_enabled | OFF |

I valori sono una policy di rollout, non attestano ancora l'esistenza dei flag nel
backend production.

## 2026-08-02 — Checkpoint interno TASK-024 e attivazione TASK-025

- **Agente**: `CODEX_EXECUTOR`; nessuna review formale intermedia.
- **TASK-024**: `VALIDATED_PENDING_INTEGRATED_REVIEW`; sei stati availability,
  freshness/ingest monotono, fallback fail-closed, Admin preview read-only e cache/cart
  Client coerenti senza quantità inventory pubblica.
- **Revision set Admin/Supabase**:
  `9d457ee4b278864a25e4f612bbfdea138e3df6d6`, PR #67 draft; migration additiva
  `20260802220000_storefront_v1_public_availability`.
- **Gate Admin/staging**: replay completo; pgTAP TASK-024 243/243 e suite
  1.782/1.782; concurrency; foundation/verify/security; CI `30772550353`, Cloudflare
  `30772550354` e staging `30772549228`, tutti `PASS`; artifact `8840991592`.
- **Revision set Client runtime**:
  `b34211f0b294703e3124b42f1b008ea32c454ffd`, PR #5 draft; Drift v4 e regressioni
  card/detail/cart/migration/device sui sei stati.
- **Gate Client**: pub get/l10n/format/analyze; 433 test, coverage 7.333/9.176
  (79,91%); benchmark 25.000 righe; security 483 file; governance/architecture;
  Android debug/release e iOS debug/release compile `PASS`.
- **Integration/smoke**: refresh availability/prezzo preserva quantità/favorite e
  attraversa restart/merge/logout su Android API 35 e iOS 26.5, 1/1 per piattaforma;
  artifact normali installati/avviati e accessibility/screenshot/secret scan `PASS`.
- **CI Client**: run `30773126667` `BLOCKED` esterna: tre job, zero step/runner e
  annotazione billing/spending limit; nessun failure di codice dichiarato.
- **Performance**: server p95 catalog/search/detail 11,002/178,422/1,019 ms; cache p95
  catalog/search 1.205/3.920 µs; cleanup fixture zero.
- **Sicurezza/production**: zero quantità/costo/supplier/owner/ID inventory pubblici;
  nessun write/deploy production, flag production OFF.
- **Transizione**: TASK-025 è l'unico task `ACTIVE / EXECUTION`; planning autorizzato
  per hold atomico, ultimo pezzo concorrente, idempotency, expiry/release e cleanup,
  con writer Admin/Supabase -> Client.

## 2026-08-02 — Checkpoint interno TASK-025 e attivazione TASK-026

- **Agente**: `CODEX_EXECUTOR`; nessuna review formale intermedia.
- **TASK-025**: `VALIDATED_PENDING_INTEGRATED_REVIEW`; hold atomico/idempotente,
  expiry/release/consume monotoni, cleanup bounded e UI Client resiliente completati.
- **Revision set Admin/Supabase**:
  `448a778cc57ed1a441b87a71bb93be4315374d08`, PR #67 draft; migration additive
  `20260803000951_storefront_v1_reservation_holds` e
  `20260803003855_storefront_v1_reservation_hold_eligibility`.
- **Gate Admin/staging**: 54/54 pgTAP dedicati, 196 assertion isolate, race due
  sessioni, foundation 826 test, security/typecheck/lint; CI `30776746985`, Cloudflare
  `30776746979` e staging `30776745250`, tutti `PASS`; artifact `8842295233`.
- **Load staging**: 1.200 hold rollback-only; 1.000 expired processati in tre batch,
  max 400, p50/p95/p99 498,463/502,698/503,075 ms; residui 0 e stock invariato.
- **Revision set Client runtime**:
  `fe85ce910313843c00c83760b67563f7ea6ef2e7`, PR #5 draft; repository/storage/
  coordinator/controller/UI reservation, cart/logout/account/reconnect integrati.
- **Gate Client**: pub get/l10n/format/analyze; 461 test, coverage 8.063/10.202
  (79,03%); benchmark 25.000 righe; security/artifact scan; Android debug/release e
  iOS debug/release compile `PASS`.
- **Integration/smoke**: create/read/release/retry/expiry Android API 35 e iOS 26.5,
  2/2 per piattaforma; artifact installati/avviati e screenshot/a11y/secret scan `PASS`.
- **CI Client**: run `30776491402` `BLOCKED` esterna: Quality/Android/iOS hanno zero
  runner/step per billing/spending limit; nessun failure di codice dichiarato.
- **Sicurezza/production**: nessun dato inventory preciso/internal ID/credential nelle
  response, UI o artifact; nessun write/deploy production, flag production OFF.
- **Transizione**: TASK-026 è l'unico task `ACTIVE / EXECUTION`; planning autorizzato
  per fulfillment, zone/slot/fee, quote server-authoritative e checkout progressivo,
  con writer Admin/Supabase -> Client.

## 2026-08-02 — Checkpoint interno TASK-026 e attivazione TASK-027

- **Agente**: `CODEX_EXECUTOR`, seguito da `CODEX_PLANNER` per il planning del task
  successivo già autorizzato; nessuna review formale intermedia.
- **TASK-026**: `VALIDATED_PENDING_INTEGRATED_REVIEW`; fulfillment shop-scoped,
  quote server-authoritative/idempotente, Admin configuration e checkout Client in
  cinque step completati.
- **Revision set Admin/Supabase**:
  `86088dc739c59725735533c64133678e96641a9a`, PR #67 draft; migration additive
  `20260803020000_storefront_v1_checkout_fulfillment` e
  `20260803021500_storefront_v1_checkout_admin`.
- **Gate Admin/staging**: 56/56 pgTAP dedicati, suite 31 file/1.892 test, race due
  customer sull'ultimo slot, foundation/lint/typecheck/security/build e Playwright;
  CI `30779607356`, Cloudflare `30779607377` e staging `30779605562`, tutti `PASS`;
  artifact `8843215328`, digest
  `56a17798853cd59c185317230acef2f1910043d6c76a06ff20e77f114efce128`.
- **Revision set Client runtime**:
  `9406df7d5b5d5a69a0edc033359be38f3bdf656f`, PR #5 draft; repository/parser strict,
  draft pending, controller, flow cinque step, quattro l10n e golden canonico.
- **Gate Client**: gate canonico exit 0; 489 test, coverage 9.254/12.002 (77,10%),
  benchmark 25.000 righe, security/artifact scan, Android debug/release e iOS debug/
  release compile `PASS`.
- **Integration/smoke**: checkout Android API 35 e iOS 26.5 1/1 per piattaforma, live
  public adapter staging 1/1, artifact CLI install/launch/interazione/screenshot `PASS`.
- **CI Client**: run `30781669519` `BLOCKED` esterna: Quality/Android/iOS hanno zero
  runner/step e annotazione billing/spending limit; nessun failure di codice dichiarato.
- **Sicurezza/production**: nessun input economico client autorevole, internal ID o
  credential nelle response/UI/artifact; nessun write/deploy production, flag OFF.
- **Transizione**: TASK-027 è l'unico task `ACTIVE / EXECUTION`; planning autorizzato
  per order, item snapshot, status event, outbox e consume hold atomici/idempotenti,
  con writer Admin/Supabase -> Client.

## 2026-08-03 — Checkpoint interno TASK-027 e attivazione TASK-028

- **Agente**: `CODEX_EXECUTOR`, seguito da `CODEX_PLANNER` per il planning del task
  successivo già autorizzato; nessuna review formale intermedia.
- **TASK-027**: `VALIDATED_PENDING_INTEGRATED_REVIEW`; order aggregate, item snapshot,
  first status event, outbox, consume quote/hold/cart e idempotency atomici completati.
- **Revision set Admin/Supabase**:
  `599511c03cb502b9b76561ff320cfdbb4073b1ee`, PR #67 draft; migration additive
  `20260803033000_storefront_v1_customer_orders` e
  `20260803034500_storefront_v1_customer_order_capacity`.
- **Gate Admin/staging**: replay completo; pgTAP 35/35, duplicate/replay concurrency,
  foundation 845 pass + 2 skip, lint/typecheck/build/security; CI `30783886282`,
  Cloudflare `30783886269` e staging `30783882947` attempt 2, tutti `PASS`; artifact
  `8844663559`, digest
  `ea8ae759e6af6fc1a194f8a0f9b168164fd0e19003bfaf046298c3f092e5ece3`.
- **Revision set Client runtime**:
  `64c8f711547f8d5c5dc18650a03a9d5345bb71b7`, PR #5 draft; parser strict,
  pending/order persistence v2, recovery timeout/restart e receipt localizzata.
- **Gate Client**: gate canonico exit 0; 497 test, coverage 9.531/12.477 (76,39%),
  benchmark 1/1, security/governance/architecture, build Android/iOS, integration order
  Android/iOS 1/1 e artifact smoke headless `PASS`.
- **CI Client**: run `30784085502` `BLOCKED` esterna: Quality/Android/iOS hanno zero
  runner/step e annotazione billing/spending limit; nessun failure codice dichiarato.
- **Tentativi diagnostici non candidati**: staging attempt 1 cancellato senza step per
  concurrency queue; smoke Android iniziale senza `adb` nel PATH. Attempt 2 e path SDK
  esplicito sono `PASS`, senza retry cieco.
- **Sicurezza/production**: snapshot/response allow-list, zero internal ID economici,
  secret o artifact versionati; nessun write/deploy production, flag OFF.
- **Transizione**: TASK-028 è l'unico task `ACTIVE / EXECUTION`; planning autorizzato
  per order list/detail/timeline, cache read-only offline, deep link e cancellazione
  server-authoritative, con writer Admin/Supabase -> Client.

## 2026-08-03 — Checkpoint interno TASK-028 e attivazione TASK-029

- **Agente**: `CODEX_EXECUTOR`, seguito da `CODEX_PLANNER` per il planning del task
  successivo già autorizzato; nessuna review formale intermedia.
- **TASK-028**: `VALIDATED_PENDING_INTEGRATED_REVIEW`; list/detail/timeline owner-
  scoped, cancellation idempotente, cache read-only offline, deep link e UI Client.
- **Revision set Admin/Supabase**:
  `119169375fa477995b41c34b3766deca32fec056`, PR #67 draft; migration additiva
  `20260803050000_storefront_v1_customer_order_history`.
- **Gate Admin/staging**: replay completo; pgTAP 30/30, race cancel due sessioni,
  foundation 845 pass + 2 skip, lint/typecheck/build/security; CI `30787892745`,
  Cloudflare `30787892757` e staging `30787890770`, tutti `PASS`; artifact migration
  `8845914762`, digest
  `4d6abb98931d6d431e1fb7bdd9478e53402104ca30065165b4f9d3699c11b29f`, artifact
  verify `8845928446`, digest
  `ce89e37b17a078468db259158e9c00f7b950146bc20ee78aa75378ea20edf748`.
- **Revision set Client runtime**:
  `1855100f34a3563787b1ac71eafb4af60a1b72e6`, PR #5 draft; adapter/cache/controller,
  Orders/Detail/timeline, recovery cancellation, logout purge e deep link auth-gated.
- **Gate Client**: gate canonico exit 0; 526 test funzionali, benchmark 1/1, coverage
  11.123/14.388 (77,31%), security/governance/architecture, build Android/iOS,
  integration history Android/iOS 1/1 e artifact smoke headless `PASS`.
- **CI Client**: run `30787721420` `BLOCKED` esterna: Quality/Android/iOS hanno zero
  runner/step e annotazione billing/spending limit; nessun failure codice dichiarato.
- **Tentativi diagnostici non candidati**: un run staging cancellato prima degli step;
  un run ha rilevato il predecessor già applicato e il workflow è stato corretto per
  provare il solo delta TASK-028. Il run finale è verde, senza retry cieco.
- **Sicurezza/production**: response/cache allow-list, zero internal ID/credential o
  artifact versionato; nessun write/deploy production, flag e cancellation OFF.
- **Transizione**: TASK-029 è l'unico task `ACTIVE / EXECUTION`; planning autorizzato
  per queue/detail Admin, RBAC, state machine e transition idempotenti con audit/event/
  outbox, con writer Admin/Supabase.

## 2026-08-03 — Checkpoint interno TASK-029 e attivazione TASK-030

- **Agente**: `CODEX_EXECUTOR`, seguito da `CODEX_PLANNER` per il planning del task
  successivo già autorizzato; nessuna review formale intermedia.
- **TASK-029**: `VALIDATED_PENDING_INTEGRATED_REVIEW`; queue/detail Admin, RBAC,
  state machine e transition idempotenti/versionate con event/audit/outbox atomici.
- **Admin/Supabase finale**:
  `23bfab60b91ef192dbb726bde454287cea144c8f`, PR #67 draft; migration additiva
  `20260803053000_storefront_v1_admin_orders`; SHA applicativo staging `1a50fcd1`.
- **Gate locali/CI**: replay 27,18 s; pgTAP 34/34; race due operatori; foundation
  856 pass + 2 skip; Playwright queue/detail 2/2; CI `30798108711` e Cloudflare build
  `30798108767` `PASS` sullo SHA finale.
- **Staging**: migration/verify `30791945888`, deploy `30796888108`, acceptance finale
  `30798109969`; publish 1/1, queue/transizione 1/1, cleanup 0 e fixture persistente
  `PASS`. Artifact `8847378085`, `8847396310`, `8849757536` con digest sanitizzati.
- **Sicurezza/production**: response/audit/outbox allow-list, fiscal status
  `not_created`, zero `pos_sales`, 0 vulnerabilità npm; nessun write/deploy production,
  flag e consumer OFF.
- **Transizione**: TASK-030 è l'unico task `ACTIVE / EXECUTION`; planning autorizzato
  per envelope, claim/lease/ack, inbox POS idempotente, offline/reconnect e confine
  fiscale, con writer Admin/Supabase -> Win7POS.
