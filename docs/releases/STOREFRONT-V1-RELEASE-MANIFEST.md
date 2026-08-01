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
| ClientMerchandiseControl | `integration/storefront-v1` | pre-transition `857f098b124c00bbfd072194d048173d44671151` | `#5 DRAFT` | n/a | `CMC-STOREFRONT-LOGICAL 1.0.0` | TASK-007 staging `PASS` | production Storefront/orders/push/payment `OFF` | TASK-007 checkpoint `PASS` | TASK-008 | revert commit/branch; feature flag OFF |
| merchandise-control-admin-web | `integration/storefront-v1` | `25f858931bf0ffe09213186a6b8b124df0311c97` | `#67 DRAFT` | `20260802001000` | `storefront.v1` | deploy `30723988967`; acceptance `30724135568`, both `PASS` | production `OFF` | TASK-007 CI/deploy/staging `PASS` | TASK-008 promotions | migration additive + feature flag OFF |
| Win7POS | `integration/storefront-v1` | baseline `7c46bfa7402087a0ef558d73dddc0b5a01f64066` | `NOT_RUN` | n/a | POS handoff `NOT_RUN` | harness `NOT_RUN` | handoff `OFF` | release worktree pulito; checkout root dirty preservato | TASK-030 | disabilitare consumer e replay queue |
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
