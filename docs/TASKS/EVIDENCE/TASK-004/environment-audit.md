# Environment audit sanitizzato — TASK-004

## Metodo

Audit in sola lettura tramite connettore Supabase e Management API autenticata. Nessun
valore sensibile è stato stampato o persistito. La sessione browser in-app non era
autenticata e l'estensione Chrome non era disponibile: non sono usate come evidence.

Un primo probe Management API con il valore Keychain ancora codificato ha restituito
`401`; dopo decodifica esclusivamente in memoria, il retry read-only è riuscito. Token
e risposta completa non sono stati registrati.

## Risultati sanitizzati

| Controllo | Stato osservato |
|---|---|
| Progetti accessibili | uno |
| Nome progetto non-production | `merchandisecontrol-dev` |
| Project ref | `jpgo…kyvm` |
| Regione | `sa-east-1` |
| Stato progetto | `ACTIVE_HEALTHY` |
| Branch default | `main` |
| URL staging | presente, non riportato |
| Publishable key moderna | presente, non riportata |
| Provider Google | abilitato |
| Google client ID | configurato, non riportato |
| Google client secret | configurato, non riportato |
| Redirect registrati | 16 |
| Callback mobile richiesta | assente |
| Modifiche Supabase | zero |
| Modifiche repository esterni | zero |

## Decisione di fase

TASK-004 crea una configurazione locale fail-closed con la callback esatta e Google
disabilitato. TASK-011 userà la tuple staging per la connessione/readiness. TASK-020
aggiungerà la callback alla allow-list, configurerà i deep link nativi e abiliterà OAuth
soltanto dopo verifica reale. Nessuna mutazione remota è autorizzata in TASK-004.
