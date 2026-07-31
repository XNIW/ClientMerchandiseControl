# Local config attestation — TASK-004

Il contenuto del file locale non è riportato.

| Controllo | Esito | Evidenza sanitizzata |
|---|---|---|
| File `config/app_config.staging.local.json` presente | PASS | verifica di esistenza exit 0 |
| JSON e cinque chiavi contrattuali | PASS | `jq` booleano exit 0, nessun valore stampato |
| Ambiente staging | PASS | assert booleano exit 0 |
| URL HTTPS presente | PASS | assert di classe/presenza, valore non riportato |
| Publishable key moderna presente | PASS | assert di classe/presenza, valore non riportato |
| Callback canonica presente | PASS | confronto booleano exit 0 |
| Kill switch Google `false` | PASS | confronto booleano exit 0 |
| Ignore | PASS | `git check-ignore -q`, exit 0 |
| Tracking | PASS | `git ls-files` vuoto |
| Diff/status | PASS | file assente da diff e status normale |
| Compile-time parsing | PASS | test mirato 1/1, exit 0 |
| Build Android/iOS | PASS | entrambi exit 0 con il file locale |

Il file è stato scritto con `apply_patch` tramite un flusso locale che ha mantenuto URL
e key in memoria. Nessun valore è transitato in task, evidence, Git, CI o output.
