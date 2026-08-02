# Evidence TASK-023

Snapshot di handoff:
`VALIDATED_PENDING_INTEGRATED_REVIEW / EXECUTION /
CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`.

## Revision set

- Client runtime: `e8d71d38ea87ab61693ecec80614c11d676e47f5`, branch
  `integration/storefront-v1`, PR #5 draft.
- Admin/Supabase: `80556a90bba87712e4f42530b9e500b9d2d485ef`, branch
  `integration/storefront-v1`, PR #67 draft.
- Migration staging: `20260802210000_storefront_v1_customer_cart` e
  `20260802213000_storefront_v1_customer_cart_public_slug`.
- API: `customer-cart.v1`, quattro RPC pubbliche slug-based; motore UUID privato.
- Production: nessun comando di write/deploy; Storefront/orders/reservations/delivery/
  push/payment restano OFF.

## Comandi e risultati

| Gate | Comando/evidence | Exit | Durata/risultato | Stato |
|---|---|---:|---|---|
| Admin migration replay | runner locale canonico | 0 | 28 migration; 27 s | PASS |
| pgTAP TASK-023 | `storefront_v1_customer_cart.sql` | 0 | 98/98 | PASS |
| pgTAP completo | runner locale canonico | 0 | 28 file, 1.738/1.738; 45 s | PASS |
| Cart concurrency | `npm run test:storefront:customer-cart-concurrency` | 0 | version conflict, retry e cleanup fixture | PASS |
| Admin foundation | suite `node --test` | 0 | 808 totali, 806 pass, 2 skip, 0 fail | PASS |
| Admin verify/security | `npm run verify` e scanner repository | 0 | lint/type/build/foundation/security | PASS |
| Admin CI | run `30768157319` | 0 | Database migrations/pgTAP + Verify | PASS |
| Cloudflare | run `30768157310` | 0 | build; deploy staging/production skipped per delta DB-only | PASS |
| Staging exact SHA | run `30768155279`, job `91550476086` | 0 | 58 s; apply/postverify/cleanup cart | PASS |
| Client dependencies | `flutter pub get --enforce-lockfile` | 0 | 1,01 s; lock invariato | PASS |
| Client l10n | `flutter gen-l10n` | 0 | 0,65 s; bundle generati coerenti | PASS |
| Client format | `dart format --output=none --set-exit-if-changed .` | 0 | 189 file, 0 changed; 0,75 s | PASS |
| Client analyze | `flutter analyze` | 0 | zero issue; 3,0 s | PASS |
| Client test + coverage | `flutter test --coverage --exclude-tags performance` | 0 | 428/428; 17,77 s; 7.296/9.172 = 79,55% | PASS |
| Client performance | `flutter test --tags performance --concurrency=1` | 0 | 1/1; 25,92 s | PASS |
| Client security | `check-client-security.sh` dopo stage | 0 | 481 file; zero secret/config/artifact | PASS |
| Governance/architecture | script canonici e fixture negative | 0 | governance coerente; architecture 7/7 | PASS |
| Android integration | `flutter test ... -d emulator-5554` | 0 | 1/1; Android 15 API 35; 15,04 s | PASS |
| iOS integration | `flutter test ... -d 240F...` | 0 | 1/1; iPhone 17 Pro iOS 26.5; 26,71 s | PASS |
| Android debug | `flutter build apk --debug` | 0 | 11,22 s | PASS |
| Android release compile | `flutter build apk --release` | 0 | 35,06 s; 65,5 MB | PASS |
| Android artifact scan | scanner su volume APFS case-sensitive | 0 | 374 file; zero secret privilegiati | PASS |
| Android smoke | `adb install/start/uiautomator/dumpsys` | 0 | cold launch 2.303 ms; activity resumed | PASS |
| iOS Simulator debug | `flutter build ios --simulator --debug` | 0 | 20,71 s | PASS |
| iOS release compile | `flutter build ios --release --no-codesign` | 0 | 36,56 s; 22,1 MB | PASS |
| iOS artifact scan | scanner `Runner.app` | 0 | 64 file; zero secret privilegiati | PASS |
| iOS smoke | `simctl install/launch/io screenshot` | 0 | PID 62384; Home renderizzata 1.206x2.622 | PASS |
| iOS Simulator release | `flutter build ios --simulator --release` | 1 | modalità non supportata da Flutter; sostituita da release device no-codesign | NOT_RUN |
| Client CI exact SHA | run `30770239675` | n/a | 3 job, zero step; billing/spending limit GitHub | BLOCKED |
| Integrated review | freeze futuro | n/a | non ancora raggiunto | NOT_RUN |

Artifact locali non versionati:

- debug APK SHA-256 `2ad3d56bbdcfb138f46499b2b7e3ccf00e4a3238594ca3a0912d5c6da5164a1c`;
- release APK SHA-256 `256bd8992a8ea887cf8cf664ad38fe486b3a1c7f34303828fc29ba13cbbbd557`;
- digest aggregato release iOS app
  `5a9bcc2c4482a29e19e7b07b4f846a9d787b0ad972b9c85d41b8f64a0e3fd8b8`.

Benchmark cache 25.000 righe: open 319 ms, write 20k 419 ms, catalog
625/1.179/7.405 µs e search 2.845/3.831/6.613 µs. Il warning release su
`CupertinoIcons` non impedisce il build e non introduce una dipendenza nuova.

## Matrice CA

| CA | Evidence | Stato |
|---|---|---|
| CA-01 | Drift v3, file SQLite reale, restart e shop isolation | PASS |
| CA-02 | unit/controller/widget add-update-remove-clear e single-flight | PASS |
| CA-03 | CTA Detail/Favorites e allow-list publication pubblica | PASS |
| CA-04 | tre tabelle FORCE RLS, owner/anon/cross-user pgTAP | PASS |
| CA-05 | merge max bounded, partial reject e cleanup solo dopo ack | PASS |
| CA-06 | cart version, conflict concorrente e idempotency ledger | PASS |
| CA-07 | server rilegge publication/prezzo/promo e ignora importi client | PASS |
| CA-08 | price/promo/unpublished mappati adjusted/unavailable | PASS |
| CA-09 | offline/timeout conserva intent, stessa key al retry e quote indicativa | PASS |
| CA-10 | UI Cart linee/quantità/remove/subtotal/restore/empty/CTA | PASS |
| CA-11 | quattro locale, CLP, dark, 200%, viewport, Semantics/48 | PASS |
| CA-12 | schema bounded/fail-closed; scan PII/token/internal ID | PASS |
| CA-13 | gate locali, staging e smoke verdi; CI hosted separata | BLOCKED |
| CA-14 | Git/security verdi; production invariata | PASS |

## Matrice test

| Test | Risultato | Stato |
|---|---|---|
| T-01 | guest CRUD, cap, restart e shop isolation | PASS |
| T-02 | Detail/Favorites usano soltanto publication pubbliche | PASS |
| T-03 | owner success e anon/cross-user denial | PASS |
| T-04 | merge overlap/partial/retry e cleanup post-ack | PASS |
| T-05 | version conflict e retry idempotente concorrente | PASS |
| T-06 | prezzo/totale malevoli ignorati; price/promo/unpublished | PASS |
| T-07 | offline/timeout/resume/retry senza perdita intent | PASS |
| T-08 | Cart responsive con tutte le azioni/stati | PASS |
| T-09 | locale/theme/200%/viewport/Semantics | PASS |
| T-10 | migration/recovery/cache/security boundary | PASS |
| T-11 | Android/iOS native process: restart/merge/revalidate/logout | PASS |
| T-12 | staging/security/Git/production unchanged; CI hosted | BLOCKED |

Il blocker CI Client è esterno e riproducibile nelle tre annotazioni: nessun job ha
avviato un runner. Non è dichiarato `PASS`. I primi due tentativi Android del nuovo
integration test sono `FAIL`: le asserzioni nel fake venivano mappate dal controller
come errore remoto; spostate fuori dall'adapter, il candidato Android e quello iOS sono
`PASS`. Il primo scan release APK è `FAIL` su APFS case-insensitive per collisioni dei
nomi resource Android; il volume temporaneo case-sensitive preserva tutte le 374 entry
e il rerun è `PASS`. La review integrata resta `NOT_RUN`.
