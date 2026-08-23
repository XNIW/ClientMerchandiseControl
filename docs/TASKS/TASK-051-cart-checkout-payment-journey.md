# TASK-051 — Cart, checkout and payment journey completion

- **Release train**: `CLIENT_COMMERCE_JOURNEY_COMPLETION`
- **Stato**: DONE
- **Dipende da**: TASK-050 e contract Admin/Supabase del train
- **Planning**: usa esclusivamente architecture/file map di TASK-050

## Scope

Estendere header e summary del Cart senza riscrivere `CartController`; collegare il
destination step al delivery context; aggiungere `/checkout/payment`, metodi
server-enabled, recovery idempotente e ricevuta completa. Online resta
`notConfigured` senza successo simulato; importo, stato e refund restano server-side.

## Criteri e test

- context stale/unsupported blocca la CTA e quote rivalida address/context version;
- pay-at-pickup/COD/online disabled e payment timeout/replay sono coperti;
- order snapshot conserva destinatario, telefono mascherabile, indirizzo e istruzioni;
- test unit/widget, regression checkout/order e gate canonici sul final candidate.

## Closeout

Cart, checkout, `/checkout/payment`, metodi server-enabled, recovery idempotente e
ricevuta sono integrati nel main Client. Pay-at-pickup e COD rispettano il contratto;
online payment resta fail-closed `notConfigured`, senza successo simulato. Review
integrata `APPROVED`, P0/P1/P2 zero.
