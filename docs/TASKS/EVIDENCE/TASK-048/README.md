# Evidence TASK-048

Snapshot di handoff:
`DONE / REVIEW / USER_APPROVED_DONE`.

## Provenance

- Client baseline `3a6e84d472eb438b2eb54e07eed78c06de06c4e0`;
- Admin merge `a787331a6e673b2daf93929b507aa18c6dc24e24`;
- Android merge `d7c4953c4ed6bc2a33cc5dbfd009eb862f70feac`;
- iOS merge `30d226d0fb9b8679a1dd034c6e82319645337f22`;
- solo staging e fixture sintetiche; production invariata.

## Gate finale

- Staging migration/RLS: run Admin `32510819913`, migration ledger esatto e
  pgTAP `56/56 PASS`.
- E2E cross-surface: run `32531575267` sul runner temporaneo discendente da Admin
  main; E2E-01…E2E-14 `PASS`, cleanup `PASS`, artifact sanitizzato SHA-256
  `33fabf5866b093c5c29fd5d5b2c284c9f1828586c0a418028a182c45f5befd59`.
- Dataset: due shop, due operatori, uno staff senza publish, due clienti e due
  prodotti, tutti sintetici.
- Acceptance: stesso product UUID/publication UUID, versione terminale 9, source
  audit `admin/android/ios`, public price/image/status coerenti e barcode escluso
  dall'identity.
- Security: P0 0, P1 0, P2 0; P3 1 `ACCEPTED_RESIDUAL_RISK` limitato alla scelta
  Android/iOS del primo session binding. Non influenza auth/RBAC/shop ownership e
  richiederebbe platform attestation fuori scope per essere eliminato correttamente.

## Release candidate

| Target | Commit/version | Artifact | SHA-256 | Esito |
|---|---|---|---|---|
| Android debug | `d7c4953c`, `1.0 (1)` | `app-debug.apk` | `b430baa42dcc17c522b2244a83a26a7817d276f775ca39985c52960540e9d696` | PASS, debug-signed |
| Android release | `d7c4953c`, `1.0 (1)` | `app-release-unsigned.apk` | `321c65e894510aec1c1e4fd2e1367458e8b6b26e552e9b82ce9650bc04c45b0f` | PASS, unsigned |
| Android bundle | `d7c4953c`, `1.0 (1)` | `app-release.aab` | `2b115b7592004aedcee8d8c2f44fd11526eb560debdff9fef559bbfc448d3f35` | PASS, unsigned |
| iOS Simulator Release | `30d226d0`, `1.0 (1)` | zipped `.app` | `8aa0e663d2fa433cc72bd2e93e071d8d091b6e599ba9f14986006f3415a47868` | PASS; install/launch PID osservato |

Il Client non è stato rigenerato: nessun codice Flutter o public contract è cambiato.
