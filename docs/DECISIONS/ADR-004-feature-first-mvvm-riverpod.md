# ADR-004 — Feature-first MVVM con Riverpod

- Stato: ACCETTATA
- Data: 2026-07-29
- Task: TASK-001

## Decisione

Organizzare il codice per feature con View, ViewModel/controller, repository e service
soltanto quando necessari. Riverpod gestisce stato e dipendenze; go_router la navigazione.

## Conseguenze

Niente layer vuoti, code generation o dipendenze speculative nella fondazione.
