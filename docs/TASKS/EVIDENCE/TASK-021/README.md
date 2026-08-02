# Evidence TASK-021

Snapshot di handoff:
`VALIDATED_PENDING_INTEGRATED_REVIEW / EXECUTION /
CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`.

## Revision set

- Client: `4f25b539248c642351e50667a53d6fcb95840c41`, branch
  `integration/storefront-v1`, PR #5 draft.
- Admin/Supabase: `27770dbe76da3066cdddb5a821b01c144a9ae607`, branch
  `integration/storefront-v1`, PR #67 draft.
- Migration staging: `20260802181823_storefront_v1_customer_profiles_addresses`.
- Production: nessun comando di write o deploy invocato; flag Storefront/orders/push/
  payment invariati OFF.

## Comandi e risultati

| Gate | Comando/evidence | Exit | Durata/risultato | Stato |
|---|---|---:|---|---|
| Client completo | `bash scripts/check.sh` | 0 | 100,41 s; 371 test; coverage 5.743/7.098 = 80,91%; benchmark 1/1 | PASS |
| Client security | `bash scripts/check-client-security.sh` | 0 | 445 file, zero secret/config/artifact vietati | PASS |
| Android integration | `flutter test -d emulator-5554 integration_test/customer_account_flow_test.dart` | 0 | 78,31 s; 1/1; Android 15 API 35 | PASS |
| iOS integration | `flutter test -d BE85CF9D-3983-400B-8ABD-31539C056B97 integration_test/customer_account_flow_test.dart` | 0 | 35,21 s; 1/1; iPhone 17 Pro iOS 26.1 | PASS |
| Admin verify | `npm run verify` | 0 | 20,74 s | PASS |
| Migration replay | runner locale canonico | 0 | replay completo | PASS |
| pgTAP TASK-021 | `supabase/tests/storefront_v1_customer_profiles_addresses.sql` | 0 | 64/64 | PASS |
| pgTAP completo | runner locale canonico | 0 | 26 file, 1.582/1.582 in 44,84 s | PASS |
| Default concurrency | due sessioni concorrenti | 0/0 | un solo default finale, cleanup 0 | PASS |
| Foundation | runner cross-repository con POS release train | 0 | 793 test: 791 pass, 2 skip | PASS |
| Staging apply | GitHub run `30761578366`, job `91532997593` | 0 | migration/postverify 64/64 | PASS |
| Admin CI | run `30761579498` | 0 | Verify + Database pgTAP | PASS |
| Cloudflare | run `30761579496` | 0 | build | PASS |
| Performance regression | run `30761578384` | 0 | shared staging workflow exact SHA | PASS |
| Client CI | run `30763287350` | n/a | 3 job, 0 step, 0 runner; billing/spending limit GitHub | BLOCKED |
| Integrated review | freeze futuro | n/a | non ancora autorizzata dalla sequenza del train | NOT_RUN |

Artifact staging: ID `8837628074`, SHA-256
`93eaae9856fcee4217d272b171135e174bdd5ff173a1520d6f3db9d14fd3f98e`.

## Matrice CA

| CA | Evidence | Stato |
|---|---|---|
| CA-01 | PK/FK UUID `auth.users.id`; email assente dalle tre tabelle | PASS |
| CA-02 | FORCE RLS e pgTAP anon/cross-user negative | PASS |
| CA-03 | CRUD profilo/indirizzi pgTAP + Client integration | PASS |
| CA-04 | indice/lock e due writer concorrenti, esattamente un default | PASS |
| CA-05 | constraint SQL e unit test input/locale/consent/UUID/export strict | PASS |
| CA-06 | scan schema, payload, log e repository; zero credential/token | PASS |
| CA-07 | RPC export owner exact-shape, max 256 KiB e nested type validation | PASS |
| CA-08 | deletion state machine idempotente e revocabile | PASS |
| CA-09 | flow UI profilo/indirizzi/consent/export/deletion Android+iOS | PASS |
| CA-10 | quattro locale, fallback, dark, 200%, Semantics e target 48 | PASS |
| CA-11 | offline/error/retry, double tap e cambio owner concorrente | PASS |
| CA-12 | Gate locali/staging/smoke verdi; GitHub-hosted Client CI separato | BLOCKED |
| CA-13 | security/Git clean; nessun target production invocato | PASS |

## Matrice test

| Test | Risultato | Stato |
|---|---|---|
| T-01 | owner success e anon/cross-user denied | PASS |
| T-02 | CRUD + default concorrente | PASS |
| T-03 | input, locale, consent e ID malevoli rifiutati | PASS |
| T-04 | campi sensibili assenti, errori sanitizzati | PASS |
| T-05 | export owner allow-listed e cross-user denial | PASS |
| T-06 | deletion request/retry/cancel auditabile | PASS |
| T-07 | unit/widget success/offline/timeout/retry | PASS |
| T-08 | locale/theme/200%/compact/Semantics | PASS |
| T-09 | integration reale Android/iOS + staging authenticated pgTAP | PASS |
| T-10 | gate/security/Git `PASS`; Client CI esterna | BLOCKED |

Il blocker Client CI è esterno e riproducibile nelle tre annotazioni della run: i job
non sono stati avviati per pagamento/spending limit. Non è dichiarato `PASS` e non è un
failure di codice. La review integrata resta `NOT_RUN` fino al freeze multi-repository.
