# TASK-053 — After-sales, verified reviews and search assist

- **Release train**: `CLIENT_COMMERCE_JOURNEY_COMPLETION`
- **Stato**: TODO
- **Dipende da**: TASK-052
- **Planning**: usa esclusivamente architecture/file map di TASK-050

## Scope

Introdurre after-sales bounded con righe, quantità, reason enum, note e massimo tre
evidence private; timeline e cancellazione autorizzata. Introdurre recensioni
verificate per order-line completed, moderazione e aggregate server-side. Estendere la
ricerca esistente con ultime dieci query locali e suggerimenti pubblicati cancellabili,
senza AI o associazione all’identità.

## Criteri e test

Owner/shop/RBAC/refund authority/evidence private, duplicate review denied,
moderation/aggregate e search debounce/cancel/history/clear/offline.

