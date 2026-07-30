# Cross-repo ownership

| Repository | Responsabilità | Non appartiene al client |
|---|---|---|
| `ClientMerchandiseControl` | UX cliente, stato locale, query Storefront pubbliche, flusso ordine cliente | inventory interna, fiscalità POS |
| `merchandise-control-admin-web` | Control plane, pubblicazione, configurazione commerciale, preparazione ordini | rendering mobile cliente |
| `MerchandiseControlSplitView` | Inventory e workflow Android interni | esperienza Storefront |
| `iOSMerchandiseControl` | Inventory e workflow iOS interni | esperienza Storefront |
| `Win7POS` | Stock operativo, vendita fiscale, handoff ordine | accesso diretto del client |
| Supabase | Persistenza, RLS, proiezioni e funzioni server-side | autorizzazione affidata alla UI |

Le modifiche cross-repo richiedono task espliciti. TASK-001 modifica soltanto questo
repository.
