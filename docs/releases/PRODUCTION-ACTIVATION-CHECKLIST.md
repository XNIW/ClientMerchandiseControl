# Production activation checklist

## Confine e classificazione

Questa checklist certifica la readiness tecnica prima del go-live; non dichiara che
production, App Store o Play siano attivi. I soli stati persistenti usati qui sono:

- `READY`: evidence tecnica o controllo locale presente;
- `MISSING_EXTERNAL`: console, credenziale, billing, provider o attestazione esterna;
- `OWNER_VALUE_REQUIRED`: valore legale, supporto o approvazione di un owner;
- `NOT_APPLICABLE`: capability esplicitamente mantenuta OFF e non richiesta al go-live.

I valori esterni non sono salvati nel repository. L'activation record deve contenere
soltanto esito, owner, timestamp, release/versione e riferimenti redatti. Prima del
go-live eseguire entrambi i comandi; il secondo deve risultare `READY`:

```bash
scripts/check-production-readiness.sh --mode technical
scripts/check-production-readiness.sh --mode activation
```

## Baseline tecnica

- Client `origin/main` iniziale: `fdb1fa7962fa7a8eea7ecb0505adc812571fb1db`;
- Admin authority read-only: `59668348e4c728b44b998c80f1aded61e6114a3f`;
- TASK-039 Android e TASK-040 iOS: `DONE`, candidate tecnici attestati;
- migration Storefront inventory: file canonici Admin da
  `20260801195852_storefront_v1_schema_rls.sql` a
  `20260816232752_storefront_customer_timezone_v1.sql`, ordinati da Git;
- production, billing, store e provider: non modificati da TASK-041.

## SUPABASE

| Requisito | Stato corrente | Owner | Sorgente/evidence attesa |
|---|---|---|---|
| Production project identificato | MISSING_EXTERNAL | Backend owner | project reference e environment ownership redatti |
| URL HTTPS production | MISSING_EXTERNAL | Backend owner | release secret store; mai nel repository |
| Publishable key | MISSING_EXTERNAL | Backend owner | release secret store; mai valore completo nei log |
| Service role assente dalle app | READY | Security owner | client scanner e configuration contract |
| Migration inventory | READY | Database owner | Admin `supabase/migrations`, ordine Git canonico |
| Backup verificabile | MISSING_EXTERNAL | Database owner | backup ID e timestamp redatti |
| Restore plan | MISSING_EXTERNAL | Database owner | restore drill o procedura owner-approved |
| RLS | MISSING_EXTERNAL | Database/security owner | post-deploy advisor e test owner/anon redatti |
| Grants | MISSING_EXTERNAL | Database/security owner | grant inventory e pgTAP production-safe read-only |
| Realtime | MISSING_EXTERNAL | Backend owner | publication/channel policy e quota |
| Scheduled cleanup | MISSING_EXTERNAL | Database owner | schedule, last run e failure alert |
| Payment webhook | MISSING_EXTERNAL | Payment owner | endpoint e signature verification attestati |
| Notification pipeline | MISSING_EXTERNAL | Notification owner | sender, retry e dead-letter attestati |
| Delivery tracking | MISSING_EXTERNAL | Operations owner | migration, RLS, retention e shop mode |
| Shop timezone | MISSING_EXTERNAL | Product/backend owner | timezone IANA owner-approved |
| Rollback o forward-fix | READY | Release/database owner | rollback runbook e decision matrix |

## AUTH

| Requisito | Stato corrente | Owner | Sorgente/evidence attesa |
|---|---|---|---|
| Provider production | MISSING_EXTERNAL | Identity owner | provider console e tenant production |
| Redirect HTTPS | MISSING_EXTERNAL | Identity/web owner | URI esatta e dominio posseduto |
| Android App Links | MISSING_EXTERNAL | Android/web owner | `assetlinks.json` e fingerprint release |
| iOS Universal Links | MISSING_EXTERNAL | iOS/web owner | AASA e associated domain |
| Callback allowlist | MISSING_EXTERNAL | Identity owner | allowlist esatta, senza wildcard |
| Logout/revoke | READY | Identity owner | TASK-020 lifecycle e test precedenti |
| Session lifecycle | READY | Identity owner | restore/logout/account-switch fail-closed |

## ANDROID

| Requisito | Stato corrente | Owner | Sorgente/evidence attesa |
|---|---|---|---|
| Release candidate TASK-039 | READY | Android release owner | evidence TASK-039 e PR #18 |
| Application ID | READY | Android release owner | `com.xniw.clientmerchandisecontrol` |
| Version code/name | READY | Android release owner | `1` / `0.1.0`; nuovo code se già usato |
| Signing | MISSING_EXTERNAL | Android release owner | upload key e fingerprint approvati |
| Play Console access | MISSING_EXTERNAL | Store owner | accesso least-privilege all'app |
| Internal track state | MISSING_EXTERNAL | Store owner | release ID e stato track redatti |
| App Links | MISSING_EXTERNAL | Android/web owner | dominio e association file |
| FCM | MISSING_EXTERNAL | Notification owner | progetto/app/sender production |
| Maps key restriction | MISSING_EXTERNAL | Maps owner | package e signing fingerprint |
| Privacy/store metadata | OWNER_VALUE_REQUIRED | Privacy/store owner | Data safety e listing approvate |

## IOS

| Requisito | Stato corrente | Owner | Sorgente/evidence attesa |
|---|---|---|---|
| Release candidate TASK-040 | READY | iOS release owner | evidence TASK-040 e PR #19 |
| Bundle ID | READY | iOS release owner | `com.xniw.clientmerchandisecontrol` |
| Version/build | READY | iOS release owner | `0.1.0 (1)`; nuovo build se già usato |
| Apple Distribution | MISSING_EXTERNAL | iOS release owner | identity e fingerprint approvati |
| Provisioning | MISSING_EXTERNAL | iOS release owner | App Store profile owner-approved |
| App Store Connect | MISSING_EXTERNAL | Store owner | record, role e API key least-privilege |
| Universal Links | MISSING_EXTERNAL | iOS/web owner | AASA e associated domain |
| APNs | MISSING_EXTERNAL | Notification owner | entitlement, key e sender production |
| Maps key restriction | MISSING_EXTERNAL | Maps owner | bundle-restricted key |
| Privacy manifest | READY | Privacy/iOS owner | manifest TASK-038/040 validato |
| TestFlight status | MISSING_EXTERNAL | Store owner | build processato e gruppo autorizzato |

## MAPS

| Requisito | Stato corrente | Owner | Sorgente/evidence attesa |
|---|---|---|---|
| Billing approval | MISSING_EXTERNAL | Maps/billing owner | account billing owner-approved |
| Quota | MISSING_EXTERNAL | Maps owner | quota e alert definiti |
| Android restricted key | MISSING_EXTERNAL | Maps owner | package e certificate restriction |
| iOS restricted key | MISSING_EXTERNAL | Maps owner | bundle restriction |
| Package/bundle restriction | MISSING_EXTERNAL | Maps owner | console evidence redatta |
| Usage monitoring | MISSING_EXTERNAL | Maps/operations owner | dashboard/alert destination |
| Rotation procedure | READY | Security/Maps owner | rollback runbook, leak response |
| Leak response | READY | Security/Maps owner | disable, revoke, rotate, inspect quota |
| Kill switch | READY | Operations owner | doppio gate Maps OFF di default |

## PAYMENTS

| Requisito | Stato corrente | Owner | Sorgente/evidence attesa |
|---|---|---|---|
| Provider production | MISSING_EXTERNAL | Payment owner | provider/account approvato |
| Merchant/account | MISSING_EXTERNAL | Payment owner | identity redatta e ownership |
| Webhook endpoint | MISSING_EXTERNAL | Payment/backend owner | endpoint HTTPS production |
| Signature secret | MISSING_EXTERNAL | Payment/security owner | secret store e rotation |
| Retry/idempotency | READY | Backend/payment owner | TASK-032 contract, no real charge |
| Reconciliation | MISSING_EXTERNAL | Finance/payment owner | cadence e mismatch alert |
| Refund/cancel procedure | MISSING_EXTERNAL | Payment/support owner | procedura provider-specific |
| Kill switch | READY | Operations/payment owner | online payment server-authoritative OFF |

## NOTIFICATIONS

| Requisito | Stato corrente | Owner | Sorgente/evidence attesa |
|---|---|---|---|
| FCM | MISSING_EXTERNAL | Notification owner | progetto/app Android production |
| APNs | MISSING_EXTERNAL | Notification owner | key/topic/environment production |
| Production credentials | MISSING_EXTERNAL | Notification/security owner | secret store e rotation |
| Device registration | READY | Backend/mobile owner | TASK-022 registration/revoke lifecycle |
| Consent | OWNER_VALUE_REQUIRED | Privacy/product owner | disclosure e prompt approvati |
| Retry/dead-letter | READY | Backend/operations owner | TASK-031 ledger e dispatcher contract |
| Kill switch | READY | Operations owner | provider unconfigured/no token/no prompt |

## OBSERVABILITY

| Requisito | Stato corrente | Owner | Sorgente/evidence attesa |
|---|---|---|---|
| Crash reporting adapter | MISSING_EXTERNAL | Operations/privacy owner | reviewed production adapter |
| Analytics adapter | NOT_APPLICABLE | Product/privacy owner | mantenere no-op se non approvato |
| Privacy consent | OWNER_VALUE_REQUIRED | Privacy/product owner | consent policy e sampling |
| PII redaction | READY | Security/privacy owner | typed schema e privacy scanner |
| Alert destination | MISSING_EXTERNAL | Operations owner | destination e escalation owner |
| Release version | READY | Release owner | version/build nei candidate |
| Environment separation | READY | Operations/security owner | production no-op, config attested |

## LEGAL/STORE

| Requisito | Stato corrente | Owner | Sorgente/evidence attesa |
|---|---|---|---|
| Owner-provided legal values | OWNER_VALUE_REQUIRED | Legal owner | entity, address, copyright, trader status |
| Privacy URL | OWNER_VALUE_REQUIRED | Privacy/web owner | URL HTTPS pubblica |
| Support URL/contact | OWNER_VALUE_REQUIRED | Support owner | URL, contatto ed escalation reali |
| Account deletion | OWNER_VALUE_REQUIRED | Identity/privacy owner | URL e workflow end-to-end |
| Store questionnaires | OWNER_VALUE_REQUIRED | Privacy/store owner | App Privacy e Data safety approvate |
| Descriptions | OWNER_VALUE_REQUIRED | Product/brand owner | draft tecnico approvato |
| Screenshots | OWNER_VALUE_REQUIRED | Brand/store owner | fixture sanitizzate e signed RC |
| Open-source attribution | READY | Legal/release owner | LicensePage e attribution document |

## Gate di attivazione

Il go-live è vietato finché `--mode activation` non conclude `READY`, l'owner di
release non ha registrato gli SHA dei candidate e non sono verdi backup, migration,
provider, store e monitoring. Un requisito opzionale può essere `NOT_APPLICABLE` solo
se il relativo kill switch resta OFF e il fallback è stato verificato.
