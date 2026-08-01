# Supabase staging config — TASK-020

## Verifica read-only

| Controllo | Esito | Evidence sanitizzata |
|---|---|---|
| Discovery progetti | PASS | un solo progetto canonico non-production |
| Project ref | PASS | mascherato come `jpgo…yvm` |
| Stato | PASS | `ACTIVE_HEALTHY` |
| Config locale | PASS | cinque chiavi esatte; file ignorato e non tracciato |
| Callback locale | PASS | URI canonico esatto |
| Kill switch | PASS | `GOOGLE_AUTH_ENABLED=false` |
| Auth settings | PASS | endpoint raggiungibile |
| Provider Google | PASS | attivo |
| Provider esterni | PASS | due attivi; nessuna configurazione modificata |
| Authorize probe PKCE | PASS | HTTP 302 verso `accounts.google.com`; redirect non seguito |
| Redirect allow-list before | BLOCKED | Dashboard richiede login; Management API HTTP 401 |
| Append callback | NOT_RUN | nessun point-update sicuro disponibile |
| Redirect allow-list after | BLOCKED | dipende dal write non eseguito |
| Production | NOT_RUN | fuori scope |

## Decisione fail-closed

Il connector disponibile non espone Auth config/redirect. La ripresa del 2026-08-01 ha
esaurito due percorsi indipendenti: il Dashboard ha richiesto un nuovo login GitHub e la
Management API ufficiale ha risposto HTTP 401 usando il token CLI scaduto/non valido
letto dal Keychain e mai stampato. La push CLI ampia non è stata usata. Codex non
inserisce password, passkey, fattori o credenziali.

Nessun progetto, Site URL, provider, secret, wildcard, redirect preesistente o
configurazione production è stato creato o modificato. Il kill switch resta `false`;
gli smoke Google live sono conseguentemente `BLOCKED`.

Questa evidence non contiene URL, key, client ID/secret, token, callback con query,
account o dati personali.

Matrice CA/T e comandi canonici:
`commands-and-results.md`, CMD-R01/CMD-R02/CMD-P02, CA-11/12/13/30/31/32 e
T-04/32/33/34.
