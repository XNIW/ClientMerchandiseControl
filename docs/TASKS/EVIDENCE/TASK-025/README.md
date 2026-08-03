# Evidence TASK-025

Snapshot di handoff:
`VALIDATED_PENDING_INTEGRATED_REVIEW / EXECUTION /
CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`.

## Revision set

- Client runtime: `fe85ce910313843c00c83760b67563f7ea6ef2e7`, branch
  `integration/storefront-v1`, PR #5 draft.
- Admin/Supabase: `448a778cc57ed1a441b87a71bb93be4315374d08`, branch
  `integration/storefront-v1`, PR #67 draft.
- Migration engine: `20260803000951_storefront_v1_reservation_holds`.
- Migration eligibility: `20260803003855_storefront_v1_reservation_hold_eligibility`.
- Staging exact SHA: run `30776745250`, job `91573566539`, artifact
  `storefront-v1-staging-migration-30776745250-1`, ID `8842295233`.
- Production: nessun comando write/deploy; Storefront/orders/reservations/delivery/
  push/payment restano OFF.

## Contratto implementato

- `inventory_products.stock_quantity` resta l'autorità privata on-hand; gli hold attivi
  e non scaduti vengono sottratti da ATP sotto lo stesso lock del prodotto;
- hold e mutation ledger sono privati, FORCE RLS, senza accesso tabellare mobile;
  `authenticated` usa soltanto tre RPC strict e `service_role` conserva il boundary
  operativo esplicito;
- owner viene sempre da `auth.uid()`, shop/publication sono verificati server-side,
  TTL è 15 minuti e il limite è 25 hold attivi per customer/shop;
- la publication e lo shop devono entrambi consentire reservation; prodotti draft,
  paused, unpublished o privi di capacità falliscono chiuso;
- create/release/read sono idempotenti; key con stesso payload replaya, payload diverso
  confligge, release/expiry/consume non resuscitano uno stato terminale;
- il cleanup cron esegue ogni minuto batch massimi di 400 righe e resta sicuro con
  worker concorrenti;
- il Client persiste prima l'intent pending, riusa la stessa idempotency key dopo timeout,
  rilegge sempre lo stato autorevole dopo create e mantiene isolamento per account;
- UI Product Detail e Cart espongono soltanto stato, scadenza e riferimenti pubblici,
  mai quantità stock, internal ID, owner, costo, supplier o path operativi.

## Comandi e risultati

| Gate | Comando/evidence | Exit | Durata/risultato | Stato |
|---|---|---:|---|---|
| Migration replay isolato | PostgreSQL 17 + migration chain TASK-025 | 0 | 196 assertion | PASS |
| pgTAP TASK-025 | suite reservation hold | 0 | 54/54 | PASS |
| Race ultimo pezzo | due sessioni/customer concorrenti | 0 | 1 `ok`, 1 `unavailable`, 1 hold attivo, stock invariato | PASS |
| Load cleanup locale | `scripts/storefront-task-025-load.sh` | 0 | 1.200 hold; p50/p95/p99 92,688/94,619/94,790 ms; 237,250 ms totali | PASS |
| Admin foundation | `WIN7POS_REPO_PATH=... npm run test:foundation` | 0 | 826 totali, 824 pass, 2 skip; 11,717 s | PASS |
| Admin typecheck/lint/security | gate repository | 0/0/0 | zero error; zero secret | PASS |
| Admin CI | run `30776746985` | 0 | DB 166 s; Verify 168 s | PASS |
| Cloudflare build | run `30776746979` | 0 | 161 s; deploy staging/production skipped | PASS |
| Staging exact SHA | run `30776745250`, job `91573566539` | 0 | 58 s; apply/postverify/pgTAP/race/load | PASS |
| Client dependencies/l10n | `flutter pub get`; `flutter gen-l10n` | 0/0 | lock e output coerenti | PASS |
| Client format | `dart format --output=none --set-exit-if-changed lib test integration_test` | 0 | 205 file, 0 changed | PASS |
| Client analyze | `flutter analyze` | 0 | zero issue | PASS |
| Client test + coverage | `flutter test --coverage --reporter compact` | 0 | 461/461; ~16 s; 8.063/10.202 = 79,03% | PASS |
| Client mirati hold/UI | unit/widget/repository/controller/cart/detail | 0 | 43/43 | PASS |
| Client performance | `flutter test --tags performance --concurrency=1` | 0 | 1/1; 29,34 s | PASS |
| Android integration | reservation flow su API 35 | 0 | 2/2 | PASS |
| iOS integration | stesso flow su iPhone 17 Pro iOS 26.5 | 0 | 2/2 | PASS |
| Android debug/release | `flutter build apk --debug/--release` | 0/0 | 11,48/23,64 s; release 65,9 MB | PASS |
| iOS debug/release compile | simulator debug + `--release --no-codesign` | 0/0 | 21,35/32,70 s; release 22,2 MB | PASS |
| Android artifact smoke | install/start/uiautomator/dumpsys/screenshot | 0 | cold launch 2.160 ms; Activity resumed | PASS |
| iOS artifact smoke | install/launch/screenshot/launchctl | 0 | PID 68468; Home stabile dopo transizione | PASS |
| Client security/artifact scan | repository/APK/Runner.app | 0 | 501/553/90 file; zero credential privilegiata | PASS |
| Client CI exact SHA | run `30776491402` | n/a | tre job, zero runner/step; billing/spending limit | BLOCKED |
| Integrated review | freeze futuro | n/a | non ancora raggiunto | NOT_RUN |

Il primo comando Admin foundation senza `WIN7POS_REPO_PATH` ha prodotto due failure
perché il checkout POS atteso non esisteva nel path root; la stessa suite con il
worktree release train esplicito è 824 pass/2 skip. La prima staging run del load gate
ha trovato `node: command not found` nell'immagine `postgres:17`; le assertion sono
state rese SQL-only, riprodotte nello stesso container e poi verificate dalla run
staging candidata. Il primo smoke Android non trovava `adb` nel `PATH`; è stato usato
l'SDK path reale. Lo screenshot iOS immediato mostrava la transizione del launcher;
dopo stabilizzazione ha mostrato la Home senza overflow. Nessun retry cieco è stato
usato.

## Load staging

Il gate rollback-only ha creato 1.200 hold sintetici: 1.000 expired eleggibili e 200
futuri attivi. Tre cleanup bounded hanno processato 1.000/1.000 righe, batch massimo
400, p50/p95/p99 498,463/502,698/503,075 ms e 1.257,153 ms totali. Residui expired:
0; stock on-hand finale: 5.000, invariato. Postverify: 3 RPC, 2 tabelle private,
8 policy, 2 FORCE RLS, cron attivo e boundary mobile/service role coerenti.

Digest evidence staging:

- load JSON: `2a4783566035345a0249d0ea9f5b976db24b45abb062dccaa5974a80647eb13c`;
- pgTAP: `acb8dbf4c2ab11093ce189cfd47fb31c4efeed1bdd8f96e2c9a345ffb16ccf59`;
- concurrency: `e1ed62ac476a2e73c0e1db0a71d13a0af786aea0a62246ccc60aa0465b266e15`;
- postverify: `2649c4c3d091c6de799fd0a0aa7366cec71a105c2ea5c70b7cd3007d5eb868a7`.

## Artifact locali non versionati

- debug APK SHA-256
  `debb61a411b9fdbcf09db860e714400c7711ba1bd9e1689c360b165514b67d4e`;
- release APK SHA-256
  `4a4d156d0ab223b47ad5d7fc69930fcf2de29af2c66ff48d2e609997ee45c084`;
- digest aggregato Runner.app Simulator
  `23082af0197430536c693f487a9bef10146eb3668e966ba1c9f57e0df592545d`.

## Matrice CA

| CA | Evidence | Stato |
|---|---|---|
| CA-01 | schema hold/ledger, TTL e limite server-side | PASS |
| CA-02 | owner auth, FORCE RLS, grant e negative anon/cross-user/cross-shop | PASS |
| CA-03 | race due sessioni sull'ultimo pezzo | PASS |
| CA-04 | ledger replay/conflict e retry client stessa key | PASS |
| CA-05 | release/expiry/consume monotoni e cleanup | PASS |
| CA-06 | lock inventory privato e response allow-list | PASS |
| CA-07 | cart/logout/switch/restart/timeout/offline/reconnect | PASS |
| CA-08 | panel accessibile, quattro lingue, theme/200%/compact | PASS |
| CA-09 | cleanup batch max 400 e load 1.200 hold | PASS |
| CA-10 | gate locali/staging/smoke verdi; CI hosted Client separata | BLOCKED |
| CA-11 | scan Git/artifact verde; production non invocata | PASS |

## Matrice test

| Test | Risultato | Stato |
|---|---|---|
| T-01 | owner create/read/release e denial RLS | PASS |
| T-02 | uno success, uno unavailable sull'ultimo pezzo | PASS |
| T-03 | replay/conflict/timeout ambiguo | PASS |
| T-04 | expiry/release/cleanup senza doppio ritorno capacità | PASS |
| T-05 | input/output strict e nessun internal field | PASS |
| T-06 | cart change, restart, logout/switch, offline/reconnect | PASS |
| T-07 | stato/countdown/locale/theme/200%/Semantics | PASS |
| T-08 | load cleanup bounded con lag e residui misurati | PASS |
| T-09 | Android/iOS 2/2 sul processo Simulator/Emulator | PASS |
| T-10 | replay/staging/mobile/security/Git verdi; CI hosted esterna | BLOCKED |

TASK-025 è tecnicamente `VALIDATED_PENDING_INTEGRATED_REVIEW`. Il blocker hosted è
esterno, resta `BLOCKED` e non interrompe il release train autorizzato. Production e
feature flag restano invariati/OFF; la review integrata è `NOT_RUN`.
