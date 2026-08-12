# Evidence TASK-008

Snapshot di checkpoint:
`VALIDATED_PENDING_INTEGRATED_REVIEW / EXECUTION`.

## Revision set

- Repository: `XNIW/merchandise-control-admin-web`.
- Branch: `integration/storefront-v1`.
- SHA: `0ec146b4379b8f0da13229fd3c807ac084d2858f`.
- PR: `#67`, draft.
- Schema staging: `20260802010000`.

## Gate

| Gate | Esito | Evidence sintetica |
|---|---|---|
| migration replay | PASS | 106 migration da zero, 27,5 s |
| pgTAP completo | PASS | 23 file, 1.472 test, 43 s; TASK-008 23/23 |
| lint/typecheck/security/build | PASS | exit 0 sul revision set |
| dependency audit | PASS | 0 vulnerabilità |
| secret scan delta | PASS | 87,32 KB, nessun secret |
| E2E locale | PASS | 1/1 in 5,0 s; promozione e prezzo pubblico inclusi |
| CI Admin | PASS | run `30725543266`, SHA esatto, 2/2 job |
| Cloudflare PR build | PASS | run `30725543260`, SHA esatto |
| staging migration | PASS | dry-run `30725661643`; apply/postverify `30725690931` |
| staging deploy/smoke | PASS | run `30725801242`, build e Worker staging |
| staging acceptance | PASS | run `30725925704`, 1/1 in 33,1 s, cleanup eseguito |
| production write | NOT_RUN | vietata prima dei gate finali; production invariata |

## Copertura

- CA-01..CA-09 e T-01..T-06: `PASS`.
- CLP integer, percentuale basis point, start/end, timezone, multi-prodotto,
  esclusioni, conflitti, scheduler, RBAC, audit e cross-shop deny sono coperti.
- Regola conflitti: `lowest_effective_price_then_priority_then_uuid`.
- Nessun secret, account, URL, ID fixture o log completo è versionato.
- Review integrata: `NOT_RUN`.
