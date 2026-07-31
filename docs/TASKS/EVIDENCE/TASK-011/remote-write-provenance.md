# Remote write provenance — TASK-011

## Scopo della correzione

Questa evidence chiude `T011-REREV-SEC-001` senza cambiare `CA-04`. «Zero-write
durante TASK-011» è verificato sul writer set sotto il controllo del task:

- client Flutter TASK-011;
- azioni Codex eseguite per TASK-011;
- repository esterni posti in scope read-only.

Non viene usato come claim di inattività globale del progetto staging condiviso.

## Evidenza client e azioni task

| Fonte | Metodo/operazione | Esito |
|---|---|---|
| Client/smoke | `GET /auth/v1/health`, user agent Dart mobile | PASS, HTTP 200 |
| Scan client | Data API/query/RPC/Storage/subscription | PASS, zero uso |
| Scan client | metodi mutanti e path Auth Admin | PASS, zero uso |
| Config client | publishable key soltanto; nessun secret/service role | PASS |
| Azioni Codex TASK-011 | metadata, config/log read-only e health GET | PASS, zero write |
| Repository esterni | sola lettura | PASS, zero write Codex |

## Traffico esterno concorrente osservato

Un controllo read-only dei log Auth globali ha mostrato attività non-client in due
finestre UTC:

- `2026-07-30T22:51:42Z`–`22:57:06Z`;
- `2026-07-31T02:08:50Z`–`02:14:16Z`.

Metodi/path sanitizzati osservati: `GET /admin/users`, `POST /admin/users`,
`POST /token` e `PUT /admin/users/<id>`, HTTP 200. La provenance è una sorgente Admin
staging privilegiata con fixture esterna. Tali operazioni:

- richiedono un confine server-side/privilegiato che il client non possiede;
- non usano lo user agent o il solo endpoint health del client;
- non sono attribuite al client o alle azioni Codex TASK-011;
- sono fuori dallo scope e non vengono presentate come inattività globale.

Nessun email, IP, UUID, request ID, URL completo o project ref è persistito.

## Interpretazione CA-04

`CA-04` è `PASS` perché nessun writer controllato da TASK-011 ha eseguito mutazioni.
L'attività Admin esterna concorrente è registrata come limite di osservabilità e non
come violazione del client/task. Questa interpretazione mantiene il criterio originale
e rimuove il precedente claim globale non supportato.

## Matrice CA

| CA | Esito | Evidenza |
|---|---|---|
| CA-02 | PASS | Unico staging canonico, log letti senza modifica. |
| CA-04 | PASS | Writer set client/Codex/repository esterni zero-write; traffico esterno separato. |
| CA-11 | PASS | Client senza Data API/query/RPC/Storage. |
| CA-22 | PASS | Provenance sanitizzata senza identificatori o segreti. |
| CA-30 | PASS | Scope e confini remoti espliciti. |
| CA-31 | NOT_RUN | Richiede seconda re-review indipendente. |

## Matrice test

| Test | Esito | Evidenza |
|---|---|---|
| T-02 | PASS | Provenance task-scoped e traffico esterno separati. |
| T-05 | PASS | Client limitato a health GET. |
| T-20 | PASS | Scan write/admin/query e sanitizzazione. |
| T-28 | NOT_RUN | Seconda re-review successiva. |

## Handoff

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`
