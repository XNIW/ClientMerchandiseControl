# TASK-011 — Planning summary

## Perimetro verificato

Il planning introduce soltanto connection/readiness staging. Non autorizza query,
schema, OAuth, deep link, allow-list, profilo, catalogo o produzione.

## Baseline

- PR #3 merged e branch milestone creato da main sincronizzato;
- un solo progetto non-production canonico, `ACTIVE_HEALTHY`, auditato read-only;
- file staging locale presente, shape valida, ignorato e non tracciato;
- health Auth ufficiale data-free: HTTP 200 e schema GoTrue valido;
- provider Google osservato come configurato, ma non modificato;
- callback mobile ancora assente dalla allow-list e riservata a TASK-020;
- Android main senza `INTERNET`; iOS HTTPS senza necessità di eccezioni ATS;
- stato runtime corrente nominale, senza timeout, abort, retry o mapping.

Nessun URL, key, project ref completo, payload, token o dato personale è registrato.

## Matrice CA

| CA | Tipo | Esito | Evidenza |
|---|---|---|---|
| CA-01 | GIT/STATIC | PASS | PR #3 merged; main sincronizzato prima del branch; solo TASK-011 attivato nel planning. |
| CA-02 | MANUAL/SECURITY | PASS | Connettore autenticato: unico progetto non-production canonico sano; nessun progetto creato. |
| CA-03 | GIT/SECURITY | PASS | Validazione shape, `git check-ignore` e `git ls-files` completate senza stampare contenuto. |
| CA-04 | MANUAL/SECURITY | PASS | Audit e probe solo lettura; nessuna mutazione remota. |
| CA-26 | INTEGRATION | PASS | Probe host ufficiale con timeout: HTTP 200, schema health valido, output sanitizzato. |
| CA-05–CA-25 | VARI | NOT_RUN | Implementazione non autorizzata nella fase Planning. |
| CA-27–CA-32 | VARI | NOT_RUN | Smoke, gate, review e CI appartengono alle fasi successive. |

## Matrice test

| Test | Tipo | Esito | Evidenza |
|---|---|---|---|
| T-01 | GIT/STATIC | PASS | Merge batch e branch verificati; transizione Master Plan preparata. |
| T-02 | MANUAL/GIT/SECURITY | PASS | Progetto/config/zero-write attestati con output sanitizzato. |
| T-22 | INTEGRATION | PASS | `GET /auth/v1/health`, HTTP 200 e schema valido; nessun dato interrogato. |
| T-03–T-21 | VARI | NOT_RUN | Richiedono implementazione. |
| T-23–T-29 | VARI | NOT_RUN | Richiedono smoke, gate, review e CI. |

## Esito Planning

`CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION`
