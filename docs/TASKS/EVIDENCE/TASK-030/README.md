# Evidence TASK-030

Snapshot di handoff:
`VALIDATED_PENDING_INTEGRATED_REVIEW / EXECUTION / CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`.

## Revision set

- Admin/Supabase: `64ef3170f5830e044ac130b127c94149d25ee1fc`, PR #67 draft;
- API Admin deployata staging: `bc5c9c92f844ce089c45819f5f80d10f6b949c84`;
- Win7POS: `6c2eb9c8a0b6666f5dd59a2a132e616f5a8d5474`, PR #88 draft;
- Client runtime invariato: `1855100f34a3563787b1ac71eafb4af60a1b72e6`, PR #5 draft;
- migration: `20260803060000_storefront_v1_pos_order_handoff`;
- production/feature flag/consumer: invariati e OFF.

## Risultati riproducibili

| Gate | Comando/run | Exit/durata/test | Risultato |
|---|---|---|---|
| pgTAP dedicato | `supabase test db supabase/tests/storefront_v1_pos_order_handoff.sql` | 0 / 40 su 40 | PASS |
| Race claim/lease/ack | `scripts/testing/storefront-v1-pos-order-handoff-concurrency.sh` | 0 / 0,74 s | PASS |
| Foundation Admin | `WIN7POS_REPO_PATH=... REQUIRE_WIN7POS_REPO=1 npm run test:foundation` | 0 / 11,456 s / 863 pass + 2 skip | PASS |
| Admin lint/type/security | `npm run lint`, `npm run typecheck`, `npm run security:scan` | 0 | PASS |
| Admin CI finale | run `30805402075`, SHA `64ef3170` | Verify 3m07s; DB 2m51s | PASS |
| Cloudflare build finale | run `30805402072`, SHA `64ef3170` | 2m53s | PASS |
| Migration staging apply | run `30801335746`, job `91646346920` | 0 / 2m14s job | PASS |
| Migration staging verify | run `30801747388` | 0 / 2m38s run | PASS |
| Deploy Admin staging | run `30804781883`, SHA `bc5c9c92` | 0 / 4m20s | PASS |
| E2E POS staging | run `30805397611`, SHA harness `64ef3170` | 0 / 42 s; contract 16.996 ms | PASS |
| Win7POS test mirati | Core/Data handoff + migration | 0 / 7,81 s / 66 su 66 | PASS |
| Win7POS gate statici | `scripts/check-required-gates.ps1` | 0 / 23,35 s / 46 su 46 | PASS |
| Win7POS CI Windows | run `30804008501`, SHA `6c2eb9c8` | 0 / 12m46s / 878 su 878 | PASS |
| Win7POS Security | run `30804007997`, SHA `6c2eb9c8` | 0 / 6m17s | PASS |
| Windows 7 fisico | dispositivo/runner reale non disponibile | esterno | BLOCKED |
| Review integrata | freeze Milestone 5 non ancora raggiunto | non eseguita | NOT_RUN |
| Production deploy/write | vietato prima della review integrata | non eseguito | NOT_RUN |

## Prova staging sanitizzata

Run `30805397611`:

- auth invalida: denial uniforme;
- claim: un handoff `customer_order.accepted.v1`, snapshot privacy-safe;
- claim replay: stesso handoff, lease token e attempt;
- ack accepted + replay: idempotente;
- stale prepared: `version_conflict`;
- prepared: ordine `ready`, version 4;
- bogus fiscal sale: `fiscal_sale_mismatch`;
- completed senza vendita: ordine `completed`, version 5;
- claim terminale: zero self-event;
- DB proof: outbox accepted `delivered`, receipt `accepted/prepared/completed`,
  `posSaleCount=0`, `fiscalReferenceCount=0`;
- cleanup: zero session/device/credential/staff attivi e shop archiviato;
- `productionWriteRequested=false`.

Artifact `8852546826`,
`sha256:cadd41e159f94eb2dcdc71566902945c53e3be38fff0bbeab136edfd9e92ee0c`.

## Artifact e supply chain

- migration staging `8851114722`,
  `sha256:d23e6aafcf4c9b5a351df38ffcb2d952b039a4db3920e713992b5c381621ef4f`;
- verifica TASK-030 `8851131186`,
  `sha256:22d21718dc9c9495baac8516a9d0ce949cbf112d22cd174e68c65cda4f5a63b4`;
- Win7POS test TRX `8852297572`,
  `sha256:4377863255dbfe7b1fd75f3f72b6366f5a6ea74a531eabb2af450b6d22b7fc2e`;
- CodeQL `8852145917`,
  `sha256:ce8fc0cace0fe2aa8b14cf6e8deac7b2af23ebdad5af9e5d4a885ce362c3163e`;
- supply chain `8852051074`,
  `sha256:20fab5a3d6b1e5d436dc4f31c9b7da3537cfd7744420c45335b90562d80aa98c`.

## Diagnostica non candidata

- suite completa macOS Win7POS: `FAIL`, 838/876 pass e 38 failure baseline dovute a
  path temporanei/reparse e fixture vendorizzata; non è il gate Windows/net48;
- build WPF locale macOS: `FAIL` sulla reference ZXing Windows-only; CI Windows x86
  sullo stesso SHA è `PASS`;
- `dotnet format` globale: `FAIL` su whitespace preesistente fuori diff; verifica dei
  file Core/Data/test modificati `PASS`;
- E2E run `30805164370`: `FAIL` su publication fixture 23514; corretta separando lo
  snapshot ordine dal gate di pubblicazione;
- E2E run `30805288594`: `FAIL` solo nella cleanup proof 42703; corretta la PK
  `pos_device_credential_id`;
- il run finale `30805397611` è verde e include entrambe le regressioni.

Warning non bloccante: GitHub forza Node 24 per action ancora dichiarate Node 20.
Nessun finding tecnico P0/P1/P2 è stato prodotto prima della review integrata.
