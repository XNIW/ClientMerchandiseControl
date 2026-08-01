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
| ClientMerchandiseControl | `integration/storefront-v1` | governance/PR `4fd560af7e7eea70ff8fe786b084846cd932d5d6` | `#5 DRAFT` | n/a | `CMC-STOREFRONT-LOGICAL 1.0.0` | Auth staging `PASS`; Storefront `NOT_RUN` | production Storefront/orders/push/payment `OFF` | Governance CI `30715196235` `PASS` | TASK-005 | revert commit/branch; nessuna write backend |
| merchandise-control-admin-web | `integration/storefront-v1` | baseline `f259e3e049bc31bce9a57afe466142109b081eec` | `NOT_RUN` | ledger staging attraverso TASK-150 | server contract `NOT_RUN` | Worker staging baseline run `30713577326` `PASS`; Storefront `NOT_RUN` | production `OFF` | ownership canonica e baseline staging `PASS` | TASK-005 schema/RLS/API | migration additive + feature flag OFF |
| Win7POS | `integration/storefront-v1` da creare quando TASK-030 inizia | `NOT_RUN` | `NOT_RUN` | n/a | POS handoff `NOT_RUN` | harness `NOT_RUN` | handoff `OFF` | checkout root dirty preservato | TASK-030 | disabilitare consumer e replay queue |
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
