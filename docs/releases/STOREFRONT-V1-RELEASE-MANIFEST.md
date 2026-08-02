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
| ClientMerchandiseControl | `integration/storefront-v1` | `4f25b539248c642351e50667a53d6fcb95840c41` | `#5 DRAFT` | local cache v2 | `storefront.v1`, `customer.v1` | gate 371 test/80,91%; Account integration Android/iOS `PASS`; CI `30763287350` `BLOCKED` billing prima dei runner | production Storefront/orders/push/payment `OFF` | TASK-021 client `PASS` tecnico | TASK-022 device/consent Client | revert commit/branch; feature flag OFF |
| merchandise-control-admin-web | `integration/storefront-v1` | `27770dbe76da3066cdddb5a821b01c144a9ae607` | `#67 DRAFT` | `20260802181823` | `storefront.v1`, `customer.v1` | CI `30761579498`; Cloudflare `30761579496`; staging `30761578366`; regressione `30761578384`, tutti `PASS` | production `OFF` | TASK-021 64/64, suite 1.582 test; artifact `8837628074` | TASK-022 schema/RLS/RPC | migration additive + feature flag OFF |
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
