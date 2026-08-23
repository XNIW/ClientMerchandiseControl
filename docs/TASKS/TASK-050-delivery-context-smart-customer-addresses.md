# TASK-050 — Delivery context and smart customer addresses

## Informazioni generali

- **Release train**: `CLIENT_COMMERCE_JOURNEY_COMPLETION`
- **Stato**: ACTIVE
- **Fase**: REVIEW
- **Responsabile**: CODEX_RE_REVIEWER
- **Data creazione**: 2026-08-22
- **Handoff**: CODEX_FIX_COMPLETE_TO_RE_REVIEW
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-050/`

## Obiettivo e scope

Completare il contesto cliente `delivery`/`pickup`, Address V2, serviceability
server-authoritative e la superficie `/delivery-context`, riusando account,
fulfillment e `DeliveryMapAdapter`. Il contesto deve essere visibile in Home, Cart e
Checkout; guest locale ed effimero, authenticated owner/shop-scoped e invalidato allo
switch.

Non include provider mappe aggiuntivi, background location, cronologia posizione,
calcoli client di zona/fee/ETA, dati reali, production o repository gestionali/POS.

## Architecture map unica del train

```text
Client Flutter
  Address V2 + local guest context + Material 3 UI
        │ public/owner RPC, opaque IDs, context version
        ▼
Admin/Supabase Storefront authority
  address validation ─ serviceability/fee/slot ─ checkout/order snapshot
  payment aggregate ─ notification ledger ─ reorder validation
  after-sales/refund authority ─ verified review/moderation/aggregate
        │
        └─ inventory/POS/fiscal domains restano invariati e fuori dal Client
```

## File map unica del train

| Area | File/superfici principali |
|---|---|
| Router/Home | `lib/app/router/`, `lib/features/home/presentation/home_screen.dart` |
| Address/Delivery | `lib/features/account/`, nuovo `lib/features/delivery_context/` |
| Cart/Checkout/Payment | `lib/features/cart/`, `lib/features/checkout/` |
| Inbox/Reorder | `lib/features/customer_notifications/`, `lib/features/orders/` |
| After-sales/Reviews | nuovi `lib/features/after_sales/`, `lib/features/reviews/` |
| Search | `lib/features/catalog/`, cache locale bounded |
| Shared UX | `lib/l10n/`, test unit/widget/integration bounded |
| Admin authority | una migration additiva, pgTAP, order/payment/notification/after-sales/review modules e due route Shop Admin bounded |

## Criteri di accettazione

1. Address V2 valida E.164, coordinate bounded/opzionali, source, version e legacy.
2. `/delivery-context` riusa un solo editor e offre permission-on-tap, fake, provider
   configurato e fallback manuale fail-closed.
3. Preview/salvataggio delivery context derivano owner/shop e riusano zone, punti,
   slot, fee e timezone server-side.
4. Home, Cart e Checkout mostrano lo stesso contesto e non calcolano valori autorevoli.
5. Account/shop switch, offline/reconnect e privacy log sono coperti da regressioni.

## Test e rischi

- pgTAP owner/cross-owner/legacy/version/coordinates/phone/default/delete/context;
- unit/widget per permission denied, not-configured, fallback testuale e serviceability;
- rischio PII mitigato con payload allowlist, nessun log e telefono mascherato;
- rischio stale context mitigato con `version`, `serverTime` e rivalidazione quote.

## Decisioni

- Il mandato USER_APPROVER del 2026-08-22 autorizza planning unico, execution
  sequenziale, review/fix bounded, PR/CI/merge normali, staging e closeout.
- Le activation esterne mancanti sono classificate, non simulate e non bloccano il
  lavoro tecnico indipendente.
- TASK-051–054 consumano questa architecture/file map senza produrre un secondo piano.

## Handoff planning

`CODEX_PLANNING_APPROVED_TO_EXECUTION` — autorizzazione già ricevuta; primo writer
Admin/Supabase, quindi Client.

## Execution checkpoint

- Address V2, delivery context, posizione foreground tap-only e fallback manuale
  fail-closed implementati senza nuovo SDK mappe.
- Home, Cart e Checkout consumano lo stesso contesto e mantengono fee/fascia/totale
  server-authoritative.
- Le superfici TASK-051–053 sono incluse nello stesso candidate Client bounded, come
  autorizzato dal train, senza attivare task concorrenti nella governance.
- Analisi statica estesa: `PASS`; suite feature-scoped pre-review: `287/287 PASS`.
- Handoff: `CODEX_EXECUTION_COMPLETE_TO_REVIEW`; TASK-050 resta l'unico `ACTIVE`
  finché la review indipendente non assegna l'esito.

## Review indipendente

- Esito: `CHANGES_REQUIRED`; P0 0, P1 0, P2 4, P3 1.
- P2: risposta after-sales stale dopo account/shop switch; idempotency reorder non
  stabile dopo timeout; recensioni prodotto troncate alla prima pagina; selezione
  post-create basata su indirizzo euristico anziché sull'ID restituito.
- P3: quattro task documentali con newline finale incoerente.
- Verifica autonoma reviewer: `91/91 PASS`; artifact esterno sanitizzato in
  `/tmp/codex-security-scans/client-commerce/review.md`.

## Fix batch unico

- Fence owner/shop/generation per le mutation after-sales e idempotency key stabile
  attraverso timeout/retry.
- Reorder conserva la stessa idempotency key fino a risposta autorevole.
- Reviews usa keyset cursor composto, merge deduplicato e CTA accessibile per pagine
  successive, con regressione widget e repository.
- Address create propaga e seleziona l'ID server esatto; niente euristica su linee
  duplicate.
- Fallback inbox/reviews fail-closed nei test senza backend; permission foreground e
  privacy metadata mobile riallineati; bundle tecnico `zh` ripristinato al fallback
  spagnolo canonico.
- Verifiche final candidate: analyze `PASS`; targeted fix `PASS`; test completi
  `839/839 PASS`; APK debug e iOS Simulator debug `PASS`; nessun secret o PII nei
  gate eseguiti. Aggregato `scripts/check.sh` `PASS`: test non-performance `829/829`,
  resilience repeat `5 x 14`, performance `10/10`, fixture security `61/61 + 7/7`,
  governance `101/101`, architecture negative `17/17` e build debug dual-platform.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.
