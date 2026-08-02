# Evidence TASK-022

Snapshot di handoff:
`VALIDATED_PENDING_INTEGRATED_REVIEW / EXECUTION /
CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`.

## Revision set

- Client runtime: `b113f44a1c7b150e9b07e770aa8a7c158a2b8111`, branch
  `integration/storefront-v1`, PR #5 draft.
- Admin/Supabase: `c8f4048f5f442726bec1693e808e19fe6dd40fc4`, branch
  `integration/storefront-v1`, PR #67 draft.
- Migration staging: `20260802194500_storefront_v1_customer_devices`.
- Production: nessun comando di write o deploy invocato; flag Storefront/orders/
  reservations/delivery/push/payment invariati OFF.

## Comandi e risultati

| Gate | Comando/evidence | Exit | Durata/risultato | Stato |
|---|---|---:|---|---|
| Client completo | `bash scripts/check.sh` | 0 | 119 s; 403 test; coverage 6.329/7.851 = 80,61%; benchmark 1/1 | PASS |
| Client security | `bash scripts/check-client-security.sh` | 0 | 465 file, zero secret/config/artifact vietati | PASS |
| Client governance/architecture | gate inclusi in `scripts/check.sh` | 0 | governance 8/8; architecture negative 7/7 | PASS |
| Android integration | `flutter test -d emulator-5554 integration_test/customer_device_flow_test.dart` | 0 | 23 s; 1/1; Android 15 API 35 | PASS |
| iOS integration | `flutter test -d 240F400E-5EFA-486A-9137-FFBBE70F604D integration_test/customer_device_flow_test.dart` | 0 | 33 s; 1/1; iPhone 17 Pro iOS 26.5 | PASS |
| Android artifact smoke | install APK normale + `am start -W` + screenshot/accessibility tree | 0 | 7 s; cold launch 2.327 ms; PID 4694; zero crash | PASS |
| iOS artifact smoke | install app normale + `simctl launch` + screenshot | 0 | 4 s; processo avviato, Home offline renderizzata | PASS |
| Admin verify | `npm run verify` | 0 | verify/foundation/security | PASS |
| Migration replay | runner locale canonico | 0 | replay completo | PASS |
| pgTAP TASK-022 | `supabase/tests/storefront_v1_customer_devices.sql` | 0 | 58/58 | PASS |
| pgTAP completo | runner locale canonico | 0 | 27 file, 1.640/1.640 | PASS |
| Token concurrency | due sessioni concorrenti register/rotation | 0/0 | una sola associazione attiva, cleanup 0 | PASS |
| Staging apply/postverify | run `30764930029`, job `91541826190` | 0 | exact SHA; device contract + cleanup | PASS |
| Admin CI | run `30764931962` | 0 | Database migrations/pgTAP + Verify | PASS |
| Cloudflare | run `30764931964` | 0 | build; deploy staging/production correttamente skipped | PASS |
| Client CI | run `30766494620` | n/a | 3 job, 0 step, 0 runner; billing/spending limit GitHub | BLOCKED |
| Push reale | provider APNs/FCM non configurato in TASK-022 | n/a | lifecycle verificato; invio appartiene a TASK-031 | NOT_RUN |
| Integrated review | freeze futuro | n/a | non ancora raggiunto nella sequenza del train | NOT_RUN |

Artifact staging: ID `8838637043`, SHA-256
`ec7764abe27e019d95ecbcb7df3378445565bd2c951fd54a47fdf35395771d6f`.

Il primo tentativo di smoke post-integration mostrava il test runner perché i comandi
`flutter test` avevano sostituito gli artifact in `build/`; non era un crash prodotto.
Gli artifact normali sono stati ricostruiti, reinstallati e avviati prima del risultato
candidato. Il primo tentativo di storage unit test falliva perché
`SharedPreferencesAsyncPlatform` non era iniettata; il boundary è stato reso testabile
e la regressione è inclusa. Il test Account ha inoltre rilevato logout fuori viewport
dopo il nuovo pannello: il controllo è stato riportato vicino alla sessione e la suite
è tornata verde.

## Matrice CA

| CA | Evidence | Stato |
|---|---|---|
| CA-01 | UUID v4 `Random.secure`, storage port testabile e nessun hardware/PII identifier | PASS |
| CA-02 | token escluso da response/log/storage locale; hash/dedup e scan statico | PASS |
| CA-03 | FORCE RLS, owner success e anon/cross-user denial pgTAP | PASS |
| CA-04 | register/refresh idempotenti, unique owner-installation/token hash e race test | PASS |
| CA-05 | state machine e widget separano decisione consenso e permission OS | PASS |
| CA-06 | rotation/revoke/logout cleanup Android/iOS e unit integration | PASS |
| CA-07 | platform/locale bounded e last-seen server-side, input forged rifiutati | PASS |
| CA-08 | owner decision scoped, logout/login altro owner non riassocia implicitamente | PASS |
| CA-09 | offline/timeout/retry conserva intent e non mostra conferma server falsa | PASS |
| CA-10 | quattro locale/fallback, dark, 200%, compact/landscape, Semantics/48 | PASS |
| CA-11 | gate tecnici/staging/smoke verdi; GitHub-hosted Client CI separato | BLOCKED |
| CA-12 | security/Git clean; nessun target production invocato | PASS |

## Matrice test

| Test | Risultato | Stato |
|---|---|---|
| T-01 | UUID casuale persistente; scan hardware ID/token response/log | PASS |
| T-02 | owner lifecycle e anon/cross-user denial | PASS |
| T-03 | duplicate register e rotation concorrente convergono | PASS |
| T-04 | grant/deny/revoke e permission OS distinta | PASS |
| T-05 | refresh, logout revoke/cleanup e retry idempotente | PASS |
| T-06 | platform/locale/last-seen invalidi o forged rifiutati | PASS |
| T-07 | account switch non eredita owner/token | PASS |
| T-08 | offline/timeout/resume/retry senza falso successo | PASS |
| T-09 | quattro locale, fallback, theme, 200%, compact/landscape e Semantics | PASS |
| T-10 | gate/security/Git/staging `PASS`; Client CI esterna | BLOCKED |

Il blocker Client CI è esterno e riproducibile nelle tre annotazioni della run: i job
non sono stati avviati per pagamento/spending limit. Non è dichiarato `PASS` e non è un
failure di codice. APNs/FCM live è onestamente `NOT_RUN`: non era scope di TASK-022 e
nessuna credenziale è stata inventata. La review integrata resta `NOT_RUN` fino al
freeze multi-repository.
