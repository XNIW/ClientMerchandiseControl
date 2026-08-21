# Monitoring and alerts

## Boundary prelaunch

Il Client riusa `ObservabilityPort` di TASK-035. Development usa logger locale redatto;
test usa collector/fake esplicito; staging e production non configurati restano
`NoopObservabilityPort`. Non viene scelto, acquistato o configurato un nuovo SaaS.

La destinazione production è `EXTERNAL_MONITORING_DESTINATION_REQUIRED`; routing,
retention, pager e owner sono `NEEDS_OWNER_VALUE`. PRELAUNCH passa con questi valori
esplicitamente mancanti; LIVE fallisce chiuso.

## Payload redatto

Schema massimo: `environment`, `platform`, `release`, `event_name`, `component`,
`outcome`, `failure_category`, `duration_bucket`, `count_bucket`, `retryable`,
`safe_correlation_id` e `safe_fingerprint`.

Sono vietati coordinate, token, indirizzi, email, telefono, payment secret, push token,
tracking URL, query raw, dati carrello completi, UUID di dominio e identità non
necessarie. Il redactor opera prima di buffer/export e i caller non allegano mappe raw.

## Health e synthetic signal

- health: check read-only Auth e Storefront con timeout bounded;
- synthetic: bootstrap, Auth fixture, catalog browse, checkout pre-submit, order fixture,
  tracking status-only e provider fallback;
- nessun ordine, pagamento, push o dato production reale;
- ogni risultato porta release/build ed environment, senza configurazione raw.

## Catalogo minimo degli alert

| ID | Segnale | Detection e condizione | Owner | Severity iniziale | Containment/fallback |
|---|---|---|---|---|---|
| M-01 | backend availability | health non healthy confermato due volte | NEEDS_OWNER_VALUE | SEV-1 | backend fail-closed |
| M-02 | backend latency/error rate | duration/error bucket oltre soglia owner | NEEDS_OWNER_VALUE | SEV-2 | rate limit e degrade read-only |
| M-03 | auth failure rate | unauthorized/unavailable rate anomalo | NEEDS_OWNER_VALUE | SEV-1 | Auth fail-closed |
| M-04 | catalog RPC failure | catalog failure/invalid payload rate | NEEDS_OWNER_VALUE | SEV-2 | cache valida o unavailable |
| M-05 | checkout failure | checkout step failure rate | NEEDS_OWNER_VALUE | SEV-1 | bloccare submit specifico |
| M-06 | order creation ambiguity | pending/timeout dopo submit idempotente | NEEDS_OWNER_VALUE | SEV-1 | impedire retry cieco e reconcile |
| M-07 | payment webhook failure | signed webhook retry/dead-letter rate | NEEDS_OWNER_VALUE | SEV-1 | payment OFF |
| M-08 | payment reconciliation mismatch | mismatch aggregato non zero | NEEDS_OWNER_VALUE | SEV-0 | payment OFF e reconcile |
| M-09 | push notification degradation | delivery/error bucket oltre soglia | NEEDS_OWNER_VALUE | SEV-2 | notifications OFF; in-app status |
| M-10 | delivery tracking stale rate | freshness stale bucket oltre soglia | NEEDS_OWNER_VALUE | SEV-2 | live/external OFF; status-only |
| M-11 | Realtime reconnect failure | reconnect loop o failure bucket | NEEDS_OWNER_VALUE | SEV-2 | polling/refresh bounded |
| M-12 | Maps provider failure | map adapter failure/quota class | NEEDS_OWNER_VALUE | SEV-2 | Maps OFF; status-only |
| M-13 | crash-free sessions | crash aggregate sotto soglia owner | NEEDS_OWNER_VALUE | SEV-1 | store halt/capability OFF |
| M-14 | release version adoption | adoption bucket inatteso per release | NEEDS_OWNER_VALUE | SEV-3 | support prior release |
| M-15 | cleanup/retention failure | last success age oltre schedule | NEEDS_OWNER_VALUE | SEV-1 | stop affected writer; preserve audit |
| M-16 | account deletion failure | pending/error age oltre policy | NEEDS_OWNER_VALUE | SEV-1 | privacy escalation |

Le soglie numeriche, la finestra e l'owner sono valori esterni approvati. In loro assenza
il contratto e la severity sono pronti, ma nessun alert live viene dichiarato attivo.

## Alert triage

1. confermare release/environment e che il segnale non provenga da fixture;
2. verificare freshness e deduplicare per safe fingerprint;
3. applicare severity da `INCIDENT-RESPONSE.md`;
4. attivare il kill switch specifico da `KILL-SWITCH-RUNBOOK.md`;
5. aprire incident/support record senza PII;
6. verificare recovery mediante health, synthetic smoke e metrica rientrata.

## Environment separation

- development: log locale redatto, mai export remoto;
- test: fake/collector in-memory e fixture deterministiche;
- staging: no-op salvo adapter staging esplicitamente iniettato e consenso;
- production: no-op finché destination, exporter, consenso, owner e retention non sono
  approvati; nessun fallback automatico verso staging.

## Live activation requirements

Il gate LIVE richiede tutte le seguenti attestazioni esterne redatte:

- production attiva e identificata;
- monitoring destination configurata;
- provider production applicabili configurati o capability attestata OFF;
- release pubblicata e versione registrata.

Il checker verifica soltanto la presenza dell'attestazione booleana; non legge né stampa
endpoint, DSN, token, chiavi o credenziali.
