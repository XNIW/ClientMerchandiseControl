# Evidence TASK-009

Snapshot di checkpoint:
`VALIDATED_PENDING_INTEGRATED_REVIEW / EXECUTION`.

## Revision set

- Repository: `XNIW/merchandise-control-admin-web`.
- Branch: `integration/storefront-v1`.
- SHA: `429c9ca88818c2f3c68a53cd4663843ae172cb8b`.
- PR: `#67`, draft.
- Schema staging: `20260802023000`.

## Gate

| Gate | Esito | Evidence sintetica |
|---|---|---|
| migration replay | PASS | 107 migrazioni da zero |
| pgTAP completo | PASS | 24 file / 1.504 test; immagini 32/32 |
| foundation immagini | PASS | 10/10 sul revision set finale |
| lint/typecheck/security/build | PASS | exit 0 |
| dependency audit | PASS | 0 vulnerabilità |
| E2E locale | PASS | 1/1 in 5,4 s; publish/replacement/rollback |
| CI Admin | PASS | run `30729546565`, SHA esatto |
| Cloudflare PR build | PASS | run `30729546558`, SHA esatto |
| staging migration | PASS | dry `30728407955`; apply/postverify `30728431358` |
| staging deploy/smoke | PASS | run `30729642919`, SHA esatto |
| staging acceptance | PASS | run `30729785520`, E2E + cleanup in 1m46s |
| production write | NOT_RUN | vietata prima dei gate finali; production invariata |

## Copertura

- CA-01..CA-09 e T-01..T-06: `PASS`.
- Separazione bucket, source-ready, WebP bounded, metadata stripping, signed upload
  exact-origin, verifica server, idempotenza, immutable cache, replacement, rollback,
  cleanup, RBAC, RLS, audit e public/internal boundary coperti.
- Il primo failure staging ha trovato e fatto correggere il binding a configurazione
  build-time; il secondo ha trovato il budget test globale inadeguato. Entrambi hanno
  regression test e acceptance finale verde.
- Nessun secret, path bucket interno, account, fixture ID, URL staging o log completo è
  versionato. Review integrata: `NOT_RUN`.
