# ADR-002 — Storefront data boundary

- Stato: ACCETTATA
- Data: 2026-07-29
- Task: TASK-001

## Decisione

Il client consumerà un dominio/read model Storefront separato e non le tabelle inventory
operative.

## Conseguenze

La proiezione pubblica, RLS e i grant devono essere progettati prima del collegamento live.
TASK-001 non crea schema né query.
