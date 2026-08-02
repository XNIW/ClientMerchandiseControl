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
| ClientMerchandiseControl | `integration/storefront-v1` | `e8d71d38ea87ab61693ecec80614c11d676e47f5` | `#5 DRAFT` | local cache v3 | `storefront.v1`, `customer.v1`, `customer-cart.v1` | 429 test/79,55%; cart integration e artifact smoke Android/iOS `PASS`; CI `30770239675` `BLOCKED` billing prima dei runner | production Storefront/orders/reservations/delivery/push/payment `OFF` | TASK-023 Client `PASS` tecnico | TASK-024 availability Client | revert commit/branch; feature flag OFF |
| merchandise-control-admin-web | `integration/storefront-v1` | `80556a90bba87712e4f42530b9e500b9d2d485ef` | `#67 DRAFT` | `20260802213000` | `storefront.v1`, `customer.v1`, `customer-cart.v1` | CI `30768157319`; Cloudflare `30768157310`; staging `30768155279`, tutti `PASS` | production `OFF` | TASK-023 98/98, suite 1.738 test | TASK-024 availability audit/contract | migration additive solo se necessaria + feature flag OFF |
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
