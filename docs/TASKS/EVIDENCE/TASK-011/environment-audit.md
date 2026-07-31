# TASK-011 — Environment audit

## Supabase staging

| Controllo | Esito | Evidenza sanitizzata |
|---|---|---|
| Progetto canonico unico | PASS | Un solo progetto non-production visibile al connettore autenticato. |
| Stato progetto | PASS | `ACTIVE_HEALTHY`. |
| Regione | PASS | Regione non-production attesa. |
| Nuovo progetto creato | PASS | No. |
| Config locale | PASS | Presente, cinque input validi, kill switch Google `false`. |
| Ignore/tracking | PASS | Ignorata e non tracciata. |
| Provider Google | PASS | Configurato; nessuna modifica. |
| Callback mobile allow-list | PASS | Assente come atteso; modifica riservata a TASK-020. |
| Health Auth data-free | PASS | HTTP 200 e schema GoTrue valido. |
| Write remoto | PASS | Zero. |

Project ref, URL e key non sono riportati. La ref abbreviata verrà registrata solo nelle
evidence TASK-020 quando avverrà la modifica autorizzata della redirect allow-list.

## Matrice CA

| CA | Tipo | Esito | Evidenza |
|---|---|---|---|
| CA-02 | MANUAL/SECURITY | PASS | Progetto esistente identificato senza creazioni. |
| CA-03 | GIT/SECURITY | PASS | Config valida, ignorata e non tracciata. |
| CA-04 | MANUAL/SECURITY | PASS | Operazioni remote esclusivamente read-only. |
| CA-26 | INTEGRATION | PASS | Health ufficiale raggiungibile con risposta valida. |

## Matrice test

| Test | Tipo | Esito | Evidenza |
|---|---|---|---|
| T-02 | MANUAL/GIT/SECURITY | PASS | Audit Supabase e file locale completato. |
| T-22 | INTEGRATION | PASS | Probe host data-free con timeout completato. |
