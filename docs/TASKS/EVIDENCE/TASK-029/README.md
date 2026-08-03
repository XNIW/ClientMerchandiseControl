# Evidence TASK-029

Snapshot di handoff:
`VALIDATED_PENDING_INTEGRATED_REVIEW / EXECUTION / CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`.

## Revision set

- Admin/Supabase finale: `23bfab60b91ef192dbb726bde454287cea144c8f`;
- applicazione deployata staging: `1a50fcd1e16107c381bf0cf8ed47991b7c8afd73`;
- Client runtime invariato: `1855100f34a3563787b1ac71eafb4af60a1b72e6`;
- migration: `20260803053000_storefront_v1_admin_orders`;
- PR: Admin #67 draft, Client #5 draft.

## Risultati riproducibili

| Gate | Comando/run | Exit/durata | Risultato |
|---|---|---|---|
| Replay locale | `supabase db reset` | 0 / 27,18 s | PASS |
| pgTAP dedicato | `supabase test db supabase/tests/storefront_v1_admin_orders.sql` | 0 / 1,60 s / 34 su 34 | PASS |
| Race | `scripts/testing/storefront-v1-admin-order-concurrency.sh` | 0 / 1,33 s | PASS |
| Foundation | `node --test tests/foundation/*.test.mjs` | 0 / 11,39 s / 856 pass + 2 skip | PASS |
| Verify | `WIN7POS_REPO_PATH=... REQUIRE_WIN7POS_REPO=1 npm run verify` | 0 / 21,27 s | PASS |
| Playwright locale | spec Admin orders, desktop+tablet | 0 / 8,66 s / 2 su 2 | PASS |
| CI finale | run `30798108711` sullo SHA esatto | 2m52s + 3m6s | PASS |
| Cloudflare build | run `30798108767` | 3m34s | PASS |
| Migration staging | run `30791945888` | exit 0 | PASS |
| Deploy staging | run `30796888108` | 6m55s complessivi | PASS |
| Acceptance finale | run `30798109969` | 3m15s / 2 su 2 | PASS |
| Production deploy | job production delle run Cloudflare | skipped | NOT_RUN |
| Review integrata | freeze Milestone 5 non ancora raggiunto | non eseguita | NOT_RUN |

Artifact sanitizzati:

- migration `8847378085`, digest
  `sha256:0791420eb645f90d3bd3dd58b5472cf332f92351023ce848d885ae6dc32e755b`;
- verification `8847396310`, digest
  `sha256:347f6dd964f64bd9a1572069ce8ac9337f1f525e38ca2db7eb1bd74b0cf61e4f`;
- fixture `8849757536`, digest
  `sha256:c2b596c2bdbfc827ac3def9889565a1dc53ac0f48bc694e4bb5d8022d6c454e5`.

## Copertura

- Audit Admin/RBAC/order/event/outbox/audit: `PASS`.
- Queue/detail/state-machine/mutation idempotente: `PASS`.
- RBAC personale/POS Admin, anon/cross-shop denial: `PASS`.
- Event, audit, outbox e ledger atomici: `PASS`.
- Fiscal boundary e zero `pos_sales`: `PASS`.
- UI responsive/accessibile e Playwright: `PASS`.
- Staging publish/fulfillment/order/fixture/cleanup: `PASS`.
- Secret/dependency/artifact scan: `PASS`; 660 package, 0 vulnerabilità.
- Production write: `NOT_RUN` — invariata per policy del train.

Warning non bloccanti: deprecazioni Node 20 delle action GitHub e warning SQL storici
già presenti; nessun finding tecnico P0/P1/P2 prodotto prima della review integrata.
