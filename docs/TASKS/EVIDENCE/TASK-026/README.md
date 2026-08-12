# Evidence TASK-026

Snapshot di handoff:
`VALIDATED_PENDING_INTEGRATED_REVIEW / EXECUTION /
CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`.

## Revision set

- Admin/Supabase: `86088dc739c59725735533c64133678e96641a9a`, branch
  `integration/storefront-v1`, PR #67 draft.
- Client runtime: `9406df7d5b5d5a69a0edc033359be38f3bdf656f`, branch
  `integration/storefront-v1`, PR #5 draft.
- Migration fulfillment: `20260803020000_storefront_v1_checkout_fulfillment`.
- Migration Admin: `20260803021500_storefront_v1_checkout_admin`.
- Staging exact SHA: run `30779605562`, job `91581524589`, artifact
  `storefront-v1-staging-migration-30779605562-1`, ID `8843215328`, SHA-256
  `56a17798853cd59c185317230acef2f1910043d6c76a06ff20e77f114efce128`.
- Production: nessun comando write/deploy; Storefront/orders/reservations/delivery/
  push/payment restano OFF.

## Contratto implementato

- fulfillment mode, pickup point, zone, slot/capacity, quote e mutation ledger sono
  shop-scoped e privati; le tabelle usano FORCE RLS e il mobile non ha accesso diretto;
- discovery anonima restituisce soltanto CLP, modalità abilitate, destinazioni e slot
  pubblici; response e parser sono allow-list e non espongono stock, costo, owner o ID
  operativi;
- quote create/confirm/read derivano owner da `auth.uid()`, usano clock server e
  ricalcolano cart, catalogo, prezzo, promozione, availability, hold, address, zona,
  slot, fee e totale; il client non invia un totale autorevole;
- stessa idempotency key/payload replaya; payload confliggente fallisce; timeout,
  restart e doppio tap mantengono una sola pending operation persistita per account;
- una quote che osserva variazioni prezzo/promo/availability richiede review esplicita;
  address, zone, slot, capacity e mode invalidi falliscono chiuso;
- la UI Client usa cinque step, back/restore, auth gate tardivo, CTA SafeArea e stati
  localizzati; cart guest e browsing non sono bloccati;
- l'Admin configura modalità, point/zone/slot/fee tramite RPC RBAC e audit, con preview
  responsive e senza accesso tabellare dal browser.

## Comandi e risultati

| Gate | Comando/evidence | Exit | Durata/risultato | Stato |
|---|---|---:|---|---|
| Admin foundation | `npm run test:foundation` con worktree POS esplicito | 0 | 836 pass, 2 skip | PASS |
| Admin lint/typecheck/unit/build/security | gate repository | 0 | zero error; audit npm zero vulnerabilità | PASS |
| Admin Playwright | Storefront fulfillment desktop + tablet | 0 | configurazione, audit e preview responsive | PASS |
| Migration replay | `supabase db reset` + suite | 0 | 31 file, 1.892 test | PASS |
| pgTAP TASK-026 | `storefront_v1_checkout_fulfillment.sql` | 0 | 56/56 | PASS |
| Race slot | due customer concorrenti | 0 | 1 quoted, 1 slot_unavailable, 1 quote attiva, stock invariato | PASS |
| Admin CI | run `30779607356` | 0 | 2 min 57 s | PASS |
| Cloudflare build | run `30779607377` | 0 | 2 min 56 s; deploy staging/production skipped | PASS |
| Staging exact SHA | run `30779605562` | 0 | 1 min 15 s; apply/postverify/pgTAP/race | PASS |
| Client dependencies/l10n/format/analyze | gate canonico | 0 | 221 file, 0 changed; zero issue | PASS |
| Client unit/widget + coverage | `flutter test --coverage` nel gate canonico | 0 | 489/489; 9.254/12.002 = 77,10% | PASS |
| Client performance | `flutter test --tags performance --concurrency=1` | 0 | 20k write 478 ms; cache catalog p95 1.347 us, search p95 3.934 us | PASS |
| Android integration | `customer_checkout_flow_test.dart` su API 35 | 0 | 1/1, tap reali | PASS |
| iOS integration | stesso flow su iPhone 17 Pro iOS 26.5 | 0 | 1/1, tap reali | PASS |
| Live staging adapter | `customer_checkout_live_smoke_test.dart` Android | 0 | 1/1; 2.041 ms; CLP, 3 mode, parser strict | PASS |
| Android debug/release | `flutter build apk --debug/--release` | 0/0 | 9,5/23,2 s; release 66,5 MB | PASS |
| iOS debug/release compile | simulator debug + device `--release --no-codesign` | 0/0 | 15,2/27,6 s; release 22,5 MB | PASS |
| Android artifact smoke | install/start/tap/uiautomator/screenshot | 0 | cold launch 2.241 ms; Cart accessibile | PASS |
| iOS artifact smoke | simctl install/launch/openurl/screenshot | 0 | Home renderizzata dopo stabilizzazione | PASS |
| Security source/artifact | scanner + regressioni | 0 | 521 tracked; 1.073 artifact; 32/32 negative e 2/2 positive | PASS |
| Client CI exact SHA | run `30781669519` | n/a | 3 job, zero runner/step; billing/spending limit | BLOCKED |
| Integrated review | freeze futuro | n/a | non ancora raggiunto | NOT_RUN |

## Matrice CA -> evidence

| Criterio | Evidence | Stato |
|---|---|---|
| CA-01 | discovery/RPC strict, pgTAP modalità shop-scoped | PASS |
| CA-02 | FORCE RLS, RBAC/audit Admin, zone/slot/fee pgTAP | PASS |
| CA-03 | quote ricalcola cart/catalogo/prezzo/promo/availability/hold | PASS |
| CA-04 | pgTAP malicious economic input e firma RPC senza totale | PASS |
| CA-05 | ledger, retry/conflict, controller double tap/timeout | PASS |
| CA-06 | pgTAP negative e race ultimo slot | PASS |
| CA-07 | cinque step, restore/back, integration Android/iOS | PASS |
| CA-08 | auth callback checkout e address owner-scoped | PASS |
| CA-09 | widget/golden/a11y/l10n e Playwright responsive | PASS |
| CA-10 | gate locali, CI Admin, staging e smoke headless | PASS |
| CA-11 | security/artifact scan; production non invocata | PASS |

## Matrice T-NN -> risultato

| Test | Risultato | Stato |
|---|---|---|
| T-01 | modalità/zone/slot/fee shop-scoped e denial verificati | PASS |
| T-02 | repricing/promo/stock/hold e input economici malevoli verificati | PASS |
| T-03 | replay, conflict, doppio tap e timeout ambiguo verificati | PASS |
| T-04 | address/zone/slot invalidi e race due customer verificati | PASS |
| T-05 | flow cinque step, restore, auth gate e cart preservato | PASS |
| T-06 | compact/tablet, dark, 200%, quattro lingue, Semantics e golden | PASS |
| T-07 | Admin RBAC/audit e preview Playwright desktop/tablet | PASS |
| T-08 | integration Android/iOS e live adapter staging | PASS |
| T-09 | replay/staging exact SHA/security/Git; CI Client esterna | PASS |

Il primo staging candidate ha rilevato una collisione di versione nel ledger migration;
la causa è stata corretta con una migration di riconciliazione additiva e la run
`30779605562` ha applicato il revision set esatto. Il primo artifact scan APK ha
incontrato entry ZIP duplicate e avrebbe richiesto input: lo scanner ora usa estrazione
quiet/overwrite e scansiona anche lo stream aggregato; 34 fixture di regressione sono
verdi. Lo screenshot iOS immediato era ancora nella transizione di launch; dopo attesa
bounded la Home è renderizzata. Nessun retry cieco o interazione GUI è stato usato.

La fixture staging transazionale è stata ripulita. Il negozio pubblico persistente
espone tre modalità abilitate ma zero point/zone/slot: è una configurazione fail-closed,
non un falso fulfillment. TASK-027/Milestone 4 E2E provisionerà fixture sintetiche
controllate e le rimuoverà al termine.
