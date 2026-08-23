# TASK-052 — Notification inbox and reorder

- **Release train**: `CLIENT_COMMERCE_JOURNEY_COMPLETION`
- **Stato**: TODO
- **Dipende da**: TASK-051
- **Planning**: usa esclusivamente architecture/file map di TASK-050

## Scope

Creare `/notifications` con badge reale, filtri, read/read-all, pagination, cache
read-only/offline e deep link allow-listed, estendendo il ledger notifiche esistente.
Aggiungere preview/apply di “Riacquista” server-validati, owner/shop-scoped,
idempotenti e senza prezzo o disponibilità storici.

## Criteri e test

Owner/cross-owner, dedup, destinazioni sicure, account cleanup, prezzi correnti,
unavailable/hidden/partial apply e nessuna creazione ordine automatica.
