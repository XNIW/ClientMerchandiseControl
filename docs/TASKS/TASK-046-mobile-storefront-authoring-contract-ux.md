# TASK-046 — Mobile Storefront authoring contract and UX

## Informazioni generali

- **Task ID**: TASK-046
- **Release train**: `MOBILE_STOREFRONT_PRODUCT_CONTROL`
- **Stato**: DONE
- **Fase**: REVIEW
- **Responsabile**: CODEX_REVIEWER
- **Data creazione**: 2026-08-21
- **Handoff**: USER_APPROVED_DONE

## Scope e vincoli

Questo e l'unico planning iniziale del train. L'autorizzazione `USER_APPROVER` del
2026-08-21 copre execution, review indipendenti, fix bounded, PR, CI, merge normale,
staging sintetico e closeout condizionato ai gate reali.

- Android, iOS e Admin scrivono una sola Storefront publication authority server-side.
- Il prodotto operativo, la pubblicazione Storefront e il read model pubblico Client
  restano domini distinti; barcode non e identita canonica.
- Il Client Flutter resta read-only e cambia soltanto per incompatibilita reale del
  contratto pubblico.
- Nessun apply production o rilascio pubblico store e implicito nel task.
- I task coordinati successivi sono TASK-047, TASK-048 e TASK-049; un solo task Client
  resta ACTIVE alla volta.

## Architecture map

```text
Android ProductRemoteRef ─┐
                          ├─ Storefront authoring RPC/API ─ publication/version/audit
iOS stable remote id ─────┤                              └─ public projection ─ Client
Admin Console ────────────┘
```

- `OPERATIONAL PRODUCT`: inventory e prezzo interno, proprieta dei gestionali.
- `STOREFRONT PUBLICATION`: dati pubblici, prezzo pubblico, stato, immagini, versione e
  audit; unica authority Admin/Supabase.
- `CLIENT PUBLIC READ MODEL`: projection allowlisted senza costo, margine, fornitore,
  stock esatto, note, audit o identita staff.

## File map

| Repository | File/superfici da estendere |
|---|---|
| Admin | migration e pgTAP Storefront; `src/server/shop-admin/storefront-mutations.ts`, permissions/read model, route/service immagini e tipi Supabase |
| Android | `DatabaseScreen*`, `EditProductDialog.kt`, `DatabaseViewModel.kt`, `InventoryRepository.kt`, `ProductRemoteRef*`, catalog transport, coordinatori sync e pipeline `productimage/` esistente |
| iOS | `DatabaseView`, `EditProductView`, ViewModel/repository Database, trasporto Supabase, remote product identity, image service e localization esistenti |
| Client | repository/DTO/cache Storefront e test contrattuali soltanto se il payload pubblico cambia; manifest release nel primo commit Client utile |

## Contract map

| Boundary | Decisione |
|---|---|
| Identita | `source_product_id`/remote UUID shop-scoped; prodotto locale non riconciliato non pubblicabile |
| Stati | riuso degli stati reali `draft`, `scheduled`, `published`, `paused`, `ended`; UI espone unpublished/hidden/archived senza ampliare la state machine |
| Comandi | read, save draft, publish, schedule, hide, archive e preview; mutazioni con expected version e idempotency key |
| Versione | `storefront_product_publications.catalog_version` diventa la revisione ottimistica della singola pubblicazione |
| Source | `admin`, `android`, `ios`, `system`, derivata server-side da identita/headers trusted e mai accettata liberamente dal payload |
| Permessi | view, edit, publish, pricing, images, promotions separati; bulk resta Admin-only |
| Audit | actor bounded, shop, product/publication, azione/source, versioni, changed fields, outcome, timestamp/correlation id safe |
| Prezzo | CLP intero, prezzo operativo e pubblico indipendenti; allineamento solo esplicito |
| Immagini | pipeline esistente: source operativa validata, generazione server-side delle varianti WebP con `sharp`, intent/finalize e ownership correnti |
| Offline/conflitto | read cache/draft locale; publish/hide/schedule/price/image richiedono rete; stale version restituisce snapshot server senza overwrite |
| Import/delete | import operativo non muta Storefront; published/scheduled richiedono hide/archive prima della delete operativa |

## Criteri e gate del train

- Migration additive e backwards-compatible, RLS/RBAC/idempotency/version/audit pgTAP.
- Parita Android/iOS per read, draft, publish, schedule, hide, archive, preview,
  align, permissions, conflict, offline/retry e account/shop switch.
- E2E-01…E2E-14 su staging con sole fixture sintetiche e public-payload denylist.
- Review security diff-scoped sul boundary privilegiato; P0/P1/P2 aperti pari a zero.
- PR/CI/merge nell'ordine Admin, Android, iOS, Client soltanto se necessario.
- Release candidate post-E2E; Internal/TestFlight/device classificati come requisiti
  esterni quando le credenziali o l'hardware non sono presenti.

## Decisioni

- Nessun sottotitolo o nuovo campo dominio viene aggiunto se non supportato dal modello
  corrente; nessuna duplicazione dell'editor prodotto o del repository inventory.
- La projection pubblica corrente resta invariata finche i contract test ne confermano
  la compatibilita.
- Il limite di retry provider/GitHub e due; un gate non eseguito non diventa PASS.

## Handoff planning

- **Planning**: architecture map + file map + contract map completati.
- **Autorizzazione**: ricevuta esplicitamente nel prompt del 2026-08-21.
- **Transizione**: `CODEX_PLANNING_APPROVED_TO_EXECUTION`.

## Execution

- Contratto Admin/Supabase backwards-compatible integrato in `main` e applicato
  soltanto allo staging; projection pubblica Client invariata.
- UX editor unico implementata su Android/iOS con identity remota stabile, prezzo
  pubblico separato, immagini esistenti, offline draft e conflitto versionato.
- Revisioni integrate: Admin `a787331a`, Android `d7c4953c`, iOS `30d226d0`.

## Review / Fix

- Review indipendenti bounded concluse: Admin, Android e iOS `APPROVED`, con
  `P0=P1=P2=P3=0` dopo un unico batch fix/re-review per repository.
- Il Client resta read-only: nessun DTO, API admin o contratto pubblico modificato.
- **Handoff**: `USER_APPROVED_DONE` nel train autorizzato.
