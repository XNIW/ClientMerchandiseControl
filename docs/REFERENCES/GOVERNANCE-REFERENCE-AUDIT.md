# Audit governance di riferimento

Data audit: 2026-07-29. Metodo: GitHub API/CLI in sola lettura sui ref indicati.

I checkout locali Android e Win7POS contenevano modifiche non riconosciute e non sono stati
usati come fonti. Nessun repository di riferimento è stato modificato.

> Nota storica non operativa: i nomi di file e strumenti nella tabella seguente
> descrivono esattamente i ref consultati il 2026-07-29. Non sono istruzioni per il
> repository corrente. Dal 2026-07-30 la governance attiva è esclusivamente
> `AGENTS.md` con `docs/CODEX-WORKFLOW-PROTOCOL.md`.

| Repository | Ref letto | File pertinenti |
|---|---|---|
| `XNIW/iOSMerchandiseControl` | `c1b7b706c5f05cd7e8dda74cea1122f6483df7ec` | `AGENTS.md`, `CLAUDE.md`, `docs/MASTER-PLAN.md`, `docs/TASKS/TASK-TEMPLATE.md`, `docs/CODEX-EXECUTION-PROTOCOL.md` |
| `XNIW/MerchandiseControlSplitView` | `4b2b4a93dd5d4db7d1cfb83e897aa5cbac40366e` | `AGENTS.md`, `CLAUDE.md`, `docs/MASTER-PLAN.md`, `docs/CODEX-EXECUTION-PROTOCOL.md` |
| `XNIW/merchandise-control-admin-web` | `e1783f57509c8011902c1f076d3b1f5ee2e56309` | `AGENTS.md`, `CLAUDE.md`, `docs/MASTER-PLAN.md`, `docs/TASKS/TASK-TEMPLATE.md`, `docs/CODEX-EXECUTION-PROTOCOL.md`, authorization/domain/sync architecture |
| `XNIW/Win7POS` | `f34308b24fd30d0b85845429f1ece97cc5106c6d` | `AGENTS.md`, struttura di `docs/AI_WORKLOG.md`, catalog/POS sync architecture |

`docs/TASKS/TASK-TEMPLATE.md` non esiste nel ref Android consultato (GitHub API 404);
questa assenza è stata registrata, non sostituita con contenuto inventato.

## Regole estratte

- Planner/reviewer e executor/fixer hanno proprietà di sezioni distinte.
- Un solo task può essere attivo.
- Master Plan e file task sono fonti di verità complementari e devono restare coerenti.
- Scope, criteri verificabili e handoff sono prerequisiti di fase.
- Execution e Fix devono produrre evidence reale; non esistono PASS inferiti.
- `NOT_RUN` e `BLOCKED` richiedono motivazioni verificabili.
- Il loop è `PLANNING -> EXECUTION -> REVIEW -> FIX -> REVIEW`.
- `DONE` richiede review approvata e conferma esplicita dell'utente.
- Il worklog è cronologico e sintetico, senza copiare log completi.
- Branch, commit e handoff devono essere tracciabili; nessuno scope creep.
- Secret e dati reali non entrano in client, report o screenshot.

## Adattamento al nuovo progetto

La governance è stata riscritta da zero per Flutter e parte da TASK-001. Non sono stati
copiati backlog, task, risultati storici, directory specifiche o vecchi claim `PASS`.
