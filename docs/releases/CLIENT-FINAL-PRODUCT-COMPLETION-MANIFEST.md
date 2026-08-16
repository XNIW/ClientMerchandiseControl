# Client final product completion — Release manifest

## Identità e stato

- Release train: `CLIENT_FINAL_PRODUCT_COMPLETION`
- Governance: `ADR-015`
- Stato: `EXECUTION`
- Task corrente: `TASK-034`
- Review integrata finale: `NOT_RUN`
- Production modificata: `no`

## Baseline remota verificata

| Repository | `origin/main` iniziale | Ruolo | Stato checkout primario |
|---|---|---|---|
| `ClientMerchandiseControl` | `e5a1384e7526e288f7657c32bff42f1ab957633e` | writer | pulito, preservato |
| `merchandise-control-admin-web` | `2e8ec07e1609b7bfa7b1a5210f232fc60bbf5412` | writer quando richiesto | pulito, preservato |
| `MerchandiseControlSplitView` | `0406264c7299766b05419f306c320032e427ca2b` | read-only | dirty preesistente, preservato |
| `iOSMerchandiseControl` | `53396a5731ef2ae0544965325845cfceb2d56dea` | read-only | pulito, preservato |
| `Win7POS` | `fea70fa7c52d60f6b3e855efb0c275ad1d1be692` | read-only | dirty preesistente, preservato |
| `MerchandiseControlWeChatMiniProgram` | `f305447cb19f21430dbff8cd50bac1db6eb73f88` | read-only | pulito, preservato |

Al preflight: zero PR aperte nei sei repository; le CI `main` più recenti Client e
Admin sono verdi sui rispettivi SHA iniziali. I linked worktree del train partono da
`origin/main`; nessun checkout primario viene usato come writer.

## Ambiente e activation boundary

- Supabase staging: progetto non-production healthy; migration history verificata.
- Delivery tracking staging: migration `20260816072836_storefront_delivery_tracking_v1`
  non ancora applicata al preflight; deployment guarded e smoke sintetico sono scope di
  TASK-034.
- Supabase production: progetto non identificato; nessuna scrittura autorizzata.
- Device: simulatori iOS ed emulatori Android disponibili; device fisici Android
  assenti e device fisici Apple rilevati offline al preflight.
- Store, signing, Maps billing/key e legal owner value: da validare nei task dedicati;
  nessun valore sensibile viene registrato nel manifest.

## Sequenza e revision set

| Task | Stato | Client revision | Admin revision | PR/merge | Gate |
|---|---|---|---|---|---|
| TASK-034 | ACTIVE / EXECUTION | in lavorazione | baseline/readiness staging | NOT_RUN | NOT_RUN |
| TASK-035 | TODO | n/a | n/a | NOT_RUN | NOT_RUN |
| TASK-036 | TODO | n/a | n/a | NOT_RUN | NOT_RUN |
| TASK-037 | TODO | n/a | n/a | NOT_RUN | NOT_RUN |
| TASK-038 | TODO | n/a | n/a | NOT_RUN | NOT_RUN |
| TASK-039 | TODO | n/a | n/a | NOT_RUN | NOT_RUN |
| TASK-040 | TODO | n/a | n/a | NOT_RUN | NOT_RUN |
| TASK-041 | TODO | n/a | n/a | NOT_RUN | NOT_RUN |
| TASK-042 | TODO | n/a | n/a | NOT_RUN | NOT_RUN |

Il manifest viene aggiornato soltanto con revisioni, workflow e risultati realmente
osservati. `NOT_RUN`, `BLOCKED` e gate esterni non vengono convertiti in `PASS`.
