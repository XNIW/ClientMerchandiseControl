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
| ClientMerchandiseControl | `integration/storefront-v1` | TASK-018 candidate `a0e139a6365dc4639ba66c110c91dcc2720feee5` | `#5 DRAFT` | local cache v2 | `storefront.v1` | Favorite/deep link/share Android e XCTest iOS `PASS`; CI `30751191932` 3/3 `PASS` | production Storefront/orders/push/payment `OFF` | TASK-018 checkpoint `PASS` | TASK-019 UI hardening/performance | revert commit/branch; feature flag OFF |
| merchandise-control-admin-web | `integration/storefront-v1` | `a9036f0bda741d686afbdac13d3d08ef897f059b` | `#67 DRAFT` | `20260802033000` | `storefront.v1` | deploy `30731372117`; fixture/acceptance `30731760038`, CI `30731757331`, tutti `PASS` | production `OFF` | Detail live Client `PASS` | TASK-019 UI hardening Admin | migration additive + feature flag OFF |
| Win7POS | `integration/storefront-v1` | baseline `41cf4b8dddd86ed51a49c0b670c81eabe9700405` | `NOT_RUN` | n/a | POS handoff `NOT_RUN` | harness `NOT_RUN` | handoff `OFF` | release worktree fast-forward e pulito; checkout root dirty preservato | TASK-030 | disabilitare consumer e replay queue |
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
