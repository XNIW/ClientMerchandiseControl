# TASK-052 — Notification inbox and reorder

- **Release train**: `CLIENT_COMMERCE_JOURNEY_COMPLETION`
- **Stato**: DONE
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

## Closeout

Inbox persistente, badge, read/read-all, pagination, cache offline e deep link
allow-listed sono integrati. Il contratto `notifications` usa lo shop UUID bounded e
resta no-op nella navigazione; URL arbitrari e ID non UUID sono negati. Reorder usa
prezzo/disponibilità correnti e idempotency stabile. Review integrata `APPROVED`.
