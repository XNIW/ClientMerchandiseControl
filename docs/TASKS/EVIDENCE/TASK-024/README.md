# Evidence TASK-024

Snapshot di handoff:
`VALIDATED_PENDING_INTEGRATED_REVIEW / EXECUTION / CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`.

## Revision set

- Client runtime: `b34211f0b294703e3124b42f1b008ea32c454ffd`, branch
  `integration/storefront-v1`, PR #5 draft.
- Admin/Supabase: `9d457ee4b278864a25e4f612bbfdea138e3df6d6`, branch
  `integration/storefront-v1`, PR #67 draft.
- Runtime Admin: `81ecd19ae11692e04135298d08f1b02db8ad46b9`; il commit successivo
  isola i workflow staging già congelati senza modificare il contratto.
- Migration staging: `20260802220000_storefront_v1_public_availability`.
- Production: nessun comando di write/deploy; Storefront/orders/reservations/delivery/
  push/payment restano OFF.

## Contratto implementato

- sei stati bounded: `available`, `low_stock`, `unavailable`, `reservation_only`,
  `pickup_only`, `delivery_only`;
- segnale operativo privato con freshness finita, source version monotona e ingest
  idempotente, serializzato sul prodotto inventory senza quantità pubblica;
- missing, future, stale, unpublished, nessun fulfillment o segnale unavailable
  convergono in modo fail-closed su `unavailable`;
- Home, Catalog, Search, Detail, cart source e Admin preview consumano soltanto lo stato
  commerciale e non espongono quantità, costo, supplier, owner o ID inventory;
- cache Client Drift v4 aggiorna atomicamente lo snapshot pubblico del guest cart a
  ogni product upsert, preservando quantità e favorite e isolando shop/publication.

## Comandi e risultati

| Gate | Comando/evidence | Exit | Durata/risultato | Stato |
|---|---|---:|---|---|
| Admin migration replay | `supabase db reset --local` | 0 | replay completo; 27,67 s | PASS |
| pgTAP TASK-024 | suite availability/projection/cart | 0 | 4 file, 243/243; 2,05 s | PASS |
| pgTAP completo | runner locale canonico | 0 | 29 file, 1.782/1.782; 59,77 s | PASS |
| Availability concurrency | due writer stessa source/version | 0 | uno applied, uno duplicate, finale v2; 1,28 s | PASS |
| Admin foundation | `node --test` | 0 | 817 totali, 815 pass, 2 skip; 11,97 s | PASS |
| Admin type/lint/security | typecheck, lint, security scan | 0 | 2,20/8,72/0,38 s | PASS |
| Admin verify/build | `npm run verify` | 0 | build production incluso; 19,96 s | PASS |
| Admin Playwright | preview locale headless | 0 | 1/1; 11,13 s | PASS |
| SQL lint | `supabase db lint --local` | 0 | soli warning preesistenti; 1,81 s | PASS |
| npm audit | `npm audit --omit=dev --audit-level=high` | 0 | 0 vulnerabilità; 0,52 s | PASS |
| Admin CI | run `30772550353` | 0 | Database migrations/pgTAP + Verify | PASS |
| Cloudflare | run `30772550354` | 0 | build; deploy staging/production correttamente skipped | PASS |
| Staging exact SHA | run `30772549228`, job `91562107007` | 0 | 54 s; apply/postverify/44 pgTAP/concurrency | PASS |
| Client dependencies | `flutter pub get` | 0 | lock invariato; 0,77 s | PASS |
| Client l10n | `flutter gen-l10n` | 0 | output invariato; 0,49 s | PASS |
| Client format | `dart format --output=none --set-exit-if-changed .` | 0 | 190 file, 0 changed; 0,97 s | PASS |
| Client analyze | `flutter analyze` | 0 | zero issue; 4,10 s | PASS |
| Client test + coverage | `flutter test --coverage --exclude-tags performance` | 0 | 433/433; 17,51 s; 7.333/9.176 = 79,91% | PASS |
| Client performance | `flutter test --tags performance --concurrency=1` | 0 | 1/1; 27,84 s | PASS |
| Client security | scanner staged/repository | 0 | 483 file; zero secret/config/artifact vietati | PASS |
| Governance/architecture | validator + fixture | 0 | governance 8/8; architecture 7/7 | PASS |
| Android integration | `customer_cart_flow_test.dart` su API 35 | 0 | 1/1; 17,46 s | PASS |
| iOS integration | stesso flow su iPhone 17 Pro iOS 26.5 | 0 | 1/1; 25,70 s | PASS |
| Android debug/release | `flutter build apk` debug e release | 0/0 | 9,58/23,38 s; release 65,5 MB | PASS |
| iOS debug/release compile | Simulator debug + device `--no-codesign` | 0/0 | 18,34/32,63 s; release 22,1 MB | PASS |
| Android artifact smoke | install/start/uiautomator/dumpsys/screenshot | 0 | cold launch 2.694 ms; Activity resumed | PASS |
| iOS artifact smoke | install/launch/screenshot + `launchctl list` | 0 | PID 355; Home renderizzata | PASS |
| Artifact secret scan | APK stream + Runner.app | 0 | 64 file iOS; zero chiavi privilegiate | PASS |
| Client CI exact SHA | run `30773126667` | n/a | 3 job, zero step/runner; billing/spending limit | BLOCKED |
| Integrated review | freeze futuro | n/a | non ancora raggiunto | NOT_RUN |

Il primo comando diagnostico iOS ha restituito exit 1 dopo launch e screenshot perché
cercava l'app nel dominio `launchctl system`; il controllo corretto `launchctl list`
ha trovato PID 355 con exit 0. Non è stato ripetuto ciecamente e il candidato app era
già avviato. La CI Client non contiene failure di codice: tutte e tre le annotation
dichiarano che il job non è partito per billing/spending limit.

## Benchmark

- dataset cache: 25.000 righe, write 20k 458 ms, open 303 ms;
- catalog cache p50/p95/p99: 604/1.205/7.400 µs;
- search cache p50/p95/p99: 2.868/3.920/6.643 µs;
- dataset server: 22.000 prodotti, 100 categorie, 91.200 righe equivalenti;
- catalog p50/p95/p99: 9,632/11,002/11,193 ms;
- search p50/p95/p99: 169,892/178,422/187,383 ms;
- detail p50/p95/p99: 0,209/1,019/1,077 ms;
- bulk publish/projection: 10.536,300 ms; promotion rebuild 3.150,867 ms;
  idempotent rebuild 927,045 ms; cleanup verificato a zero.

## Artifact locali non versionati

- debug APK SHA-256 `81d4c848424d146bc17d7b6e952e3417cdd00c1cf7d537914eacadd176e6d3f1`;
- release APK SHA-256 `ceffbc5198ab029f1d269ef03a42cdf5a3631a011cb064b833c571ebd162912c`;
- digest aggregato release iOS app
  `0fef8c04769eb126be41d10a820faab9ac305db6266605a9df3f26b8cdedc779`;
- artifact staging `storefront-v1-staging-migration-30772549228-1`, ID
  `8840991592`; evidence scaricata soltanto fuori repository.

## Matrice CA

| CA | Evidence | Stato |
|---|---|---|
| CA-01 | enum SQL/output e mapping Client/Admin sui sei valori | PASS |
| CA-02 | allow-list response, pgTAP negative e scan UI/artifact | PASS |
| CA-03 | source version, idempotency, advisory/product lock e race test | PASS |
| CA-04 | missing/stale/future/unpublished/no fulfillment fail-closed | PASS |
| CA-05 | Home/Catalog/Search/Detail/cart/card/detail UI sui sei stati | PASS |
| CA-06 | Drift v4 trigger, migration v1/v3, favorite/cart e device restart | PASS |
| CA-07 | Admin preview read-only, senza input o quantità inventory | PASS |
| CA-08 | gate locali/staging/smoke verdi; CI hosted Client separata | BLOCKED |
| CA-09 | scan Git/artifact verde; production non invocata | PASS |

## Matrice test

| Test | Risultato | Stato |
|---|---|---|
| T-01 | sei stati e negative internal fields | PASS |
| T-02 | duplicate/replay/out-of-order, cross-shop e race | PASS |
| T-03 | missing/stale/unpublished/no fulfillment -> unavailable | PASS |
| T-04 | card/detail/cart localizzati sui sei stati, zero quantità precisa | PASS |
| T-05 | refresh/cache v4 conserva favorite/quantity e aggiorna snapshot | PASS |
| T-06 | Admin Playwright responsive/read-only e contratto pubblico | PASS |
| T-07 | replay/staging/mobile/security/Git verdi; CI hosted esterna | BLOCKED |

TASK-024 è tecnicamente `VALIDATED_PENDING_INTEGRATED_REVIEW`. Il blocker hosted è
esterno, non viene trasformato in `PASS` e non interrompe il release train autorizzato.
Production e feature flag restano invariati/OFF; la review integrata resta `NOT_RUN`.
