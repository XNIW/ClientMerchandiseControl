# Security e diff scan — TASK-004

## Confinamento

Il diff tecnico `57b4a50…9ecffdf` contiene:

- 11 file autorizzati;
- 2 file runtime config/bootstrap;
- 2 file test;
- 2 file config example;
- README e 4 documenti architettura/decisioni/gate.

Non contiene file Android/iOS, `pubspec*`, workflow, integration test, backend remoto o
repository esterno.

## Scan

| Controllo | Esito |
|---|---|
| URL progetto Supabase completo in diff tracked/untracked | PASS |
| publishable key reale o JWT reale | PASS |
| secret key, service-role, private key o client secret reale | PASS |
| config production, `.env`, certificato, provisioning o keystore | PASS |
| file locale in index/diff | PASS |
| coverage/build artifact in Git | PASS |
| callback diversa da quella canonica in config versionata | PASS |
| readiness, OAuth, deep link nativo, sessione o query dati | PASS |
| `shop_id`, inventory o dato commerciale | PASS |
| repository esterni/Supabase zero-write | PASS |
| `git diff --check` | PASS |

Le stringhe secret/service-role presenti nei test e nei documenti sono esclusivamente
negative fixture o divieti normativi, non valori utilizzabili. I soli URL aggiunti nei
documenti puntano alla documentazione pubblica Supabase; gli URL di test usano domini
`.invalid`.

## Stato remoto read-only

Il controllo finale tramite connettore ha osservato un solo progetto:
`merchandisecontrol-dev`, regione `sa-east-1`, stato `ACTIVE_HEALTHY`, ref sanitizzata
`jpgo…kyvm`; branch `main` in stato `FUNCTIONS_DEPLOYED`. TASK-004 non ha invocato
alcun tool di scrittura.
