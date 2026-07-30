# ADR-001 — Flutter single codebase

- Stato: ACCETTATA
- Data: 2026-07-29
- Task: TASK-001

## Decisione

Usare Flutter stable con una sola codebase e soli target Android/iOS, Kotlin e Swift per i
progetti nativi.

## Conseguenze

UI e logica condivise riducono drift; le integrazioni native restano possibili. Web,
desktop, add-to-app e framework alternativi sono esclusi.
