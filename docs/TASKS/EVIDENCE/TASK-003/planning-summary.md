# TASK-003 — Planning summary

## Autorità e prerequisiti

- TASK-001 e TASK-002 sono `DONE` e merged.
- Il prompt end-to-end autorizza l'intero ciclo, ma ogni transizione resta esplicita e
  subordinata a evidence reale.
- Un solo task è attivo: TASK-003.

## Audit preliminare

Sono state lette in sola lettura fonti a ref fisse nei repository Client, Admin,
Android, iOS e POS. È stato inoltre distinto il workspace Supabase storico non-Git dal
repository Admin collegato all'unico progetto non-production accessibile.

Risultati che governano il piano:

- nessun dominio Storefront pubblico esiste oggi;
- le superfici operative contengono costo, stock, storico, sessioni, device e dati POS;
- Admin è il candidato verificabile a migration/server contract authority;
- il client pubblico resta consumer di una futura proiezione separata;
- autenticazione e catalogo possono avanzare come workstream distinti dopo TASK-004.

Nessun URL, project ref completo, key, token o dato reale è registrato.

## Deliverable e stop condition

Il task produce esclusivamente documenti, ADR, governance ed evidence. Non crea schema,
API, config o codice runtime. Dopo Execution passa a review indipendente; TASK-004 non
può essere attivato finché TASK-003 non è `APPROVED` e chiuso con l'autorizzazione già
concessa.
