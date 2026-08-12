# Evidence TASK-007

Snapshot di checkpoint:
`VALIDATED_PENDING_INTEGRATED_REVIEW / EXECUTION`.

## Revision set

- Repository: `XNIW/merchandise-control-admin-web`.
- Branch: `integration/storefront-v1`.
- SHA: `25f858931bf0ffe09213186a6b8b124df0311c97`.
- PR: `#67`, draft.
- Schema staging: `20260802001000`.

## Gate

| Gate | Esito | Evidence sintetica |
|---|---|---|
| migration replay | PASS | 105 migration da zero |
| pgTAP completo | PASS | 22 file, 1.449 test, 45 s; TASK-007 21/21 |
| lint/typecheck/security/build | PASS | exit 0 sul revision set |
| E2E locale | PASS | 1/1 publish, public RPC, audit, pause; residue 0 |
| CI Admin | PASS | run `30723885377`, SHA esatto |
| Cloudflare PR build | PASS | run `30723885380`, SHA esatto |
| staging migration | PASS | dry-run `30723453301`, apply/postverify `30723486727` |
| staging deploy/smoke | PASS | run `30723988967`, Worker e route smoke |
| staging acceptance | PASS | run `30724135568`, 1/1 in 1m19s, cleanup eseguito |
| production write | NOT_RUN | vietata prima dei gate finali; production invariata |

## Copertura

- CA-01..CA-09: `PASS`.
- T-01..T-07: `PASS`.
- RBAC negativo, shop scope, validazione server, idempotenza, audit e boundary API
  pubblica sono inclusi nei test SQL/foundation/E2E.
- Nessun secret, account, URL, ID fixture o log completo è versionato.
- Review integrata: `NOT_RUN`.
