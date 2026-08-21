# Post-launch operations runbook

## Stato e confine

Questo runbook prepara l'operatività prima del go-live. Non attesta che production sia
attiva, che una release sia pubblicata o che il monitoraggio live sia configurato.
L'outcome tecnico atteso è `POST_LAUNCH_OPERATIONS_READY_PRELAUNCH`.

I valori esterni non ancora assegnati usano `NEEDS_OWNER_VALUE`. La destination di
monitoring live resta `EXTERNAL_MONITORING_DESTINATION_REQUIRED`. Nessun owner, contatto,
provider o società viene inventato.

## Health check

1. confermare environment e release/build senza copiare configurazione raw;
2. usare `HttpBackendHealthService` esclusivamente per il probe Auth read-only
   `GET /auth/v1/health`; i risultati reali sono `healthy`, `offline`, `unauthorized`,
   `notFound`, `recoverableError`, `invalidResponse` e `cancelled`;
3. verificare separatamente la raggiungibilita Storefront con l'RPC bounded esistente
   `storefront_home_v1`, tramite il normale client anon/auth e una fixture shop
   sintetica autorizzata; non attribuire questo probe a `BackendHealthService`;
4. mappare il probe Auth allo stato runtime `ready`, `offline`, `misconfigured` o
   `recoverableError`; classificare l'RPC Storefront secondo `StorefrontFailureKind`,
   senza inventare un endpoint health aggiuntivo;
5. non usare service role e non modificare dati, RLS o publication;
6. aprire un incidente se due check consecutivi falliscono dopo una conferma da una
   seconda rete sintetica autorizzata.

Owner operativo: `NEEDS_OWNER_VALUE`. In prelaunch il check usa staging o fixture; il
primo check production reale richiede activation esplicita.

## Synthetic smoke

Lo smoke è read-only e usa un account sintetico autorizzato, mai dati cliente reali:

1. bootstrap e health;
2. callback Auth sintetico senza registrare code o token;
3. catalog browse con risultato bounded, senza query raw o product ID nei log;
4. cart e checkout fino al pre-submit, senza ordine o pagamento reale;
5. order history fixture e tracking `statusOnly`;
6. routing notification fake/no-op;
7. conferma che Maps, payment, push e telemetry disabilitati mostrino il fallback.

Lo smoke registra soltanto release/build, environment, outcome enum, duration bucket,
failure category e correlation ID safe. Production non viene toccata in TASK-042.

## Release version tracking

- la source of truth è la versione/build attestata nei candidate TASK-039/TASK-040;
- ogni alert include soltanto platform, release/build ed environment;
- l'adozione è aggregata per bucket, senza device ID, account ID o push token;
- una release precedente non viene forzata fuori servizio dal Client;
- rollback e halt seguono i runbook TASK-041, non un update silenzioso.

Owner release: `NEEDS_OWNER_VALUE`.

## Alert triage

1. validare environment, release e freshness dell'alert;
2. cercare duplicati per fingerprint/correlation safe, mai per identità cliente;
3. assegnare SEV secondo `INCIDENT-RESPONSE.md`;
4. scegliere il kill switch più stretto e preservare catalogo, account e storico ordini;
5. attivare il canale di escalation owner-provided;
6. registrare decisione, timestamp UTC, safe evidence e stato recovery;
7. chiudere soltanto dopo synthetic recovery e finestra di stabilità definita dall'owner.

## Incident ownership

| Ruolo | Valore prelaunch | Responsabilità |
|---|---|---|
| Incident commander | NEEDS_OWNER_VALUE | severity, containment, decision log |
| Backend owner | NEEDS_OWNER_VALUE | health, RPC, Realtime, cleanup |
| Mobile release owner | NEEDS_OWNER_VALUE | version, store halt, rollback client |
| Payment owner | NEEDS_OWNER_VALUE | provider, webhook, reconciliation |
| Privacy owner | NEEDS_OWNER_VALUE | leakage, request, deletion, retention |
| Support owner | NEEDS_OWNER_VALUE | intake e comunicazione approvata |

L'assenza del valore non blocca il codice; blocca l'activation dell'on-call reale.

## Support flow

1. ricevere ticket tramite canale owner-provided (`NEEDS_OWNER_VALUE`);
2. assegnare un case ID interno non derivato da email o account ID;
3. raccogliere platform, release/build, orario approssimato, schermata enum e outcome;
4. vietare screenshot con dati, token, indirizzi, coordinate o dettagli pagamento;
5. riprodurre con fixture/staging e associare solo fingerprint/correlation safe;
6. inviare template di stato approvato, senza promettere tempi inventati;
7. collegare incidente o maintenance item e applicare retention owner-approved.

## Privacy request

- l'intake usa il canale legale/support owner-provided `NEEDS_OWNER_VALUE`;
- l'identità viene verificata fuori da log, issue ed evidence tecniche;
- accesso, rettifica, opposizione e cancellazione seguono policy legale approvata;
- il Client non decide l'esito legale e non usa service role;
- le evidence tecniche registrano solo case ID safe, tipo richiesta, stato e timestamp;
- un sospetto leakage è SEV-0 e disabilita la sola export capability interessata.

## Account deletion

1. confermare che la richiesta provenga dal flusso owner-scoped TASK-021;
2. verificare stato `pending`/`completed` mediante il contratto server-side;
3. non cancellare localmente record backend né aggirare retention/audit obbligatori;
4. allertare su richieste oltre la soglia owner-approved;
5. verificare logout/revoke e rimozione del device registration applicabile;
6. comunicare l'esito tramite canale approvato, senza dati nel ticket tecnico.

Owner privacy e soglia: `NEEDS_OWNER_VALUE`.

## Backup/restore

- il backup production e il restore test sono activation requirement TASK-041;
- nessun backup o restore production viene eseguito da questo task;
- l'incidente registra backup ID redatto, timestamp, RPO/RTO owner-approved e decisione;
- restore avviene soltanto da database owner autorizzato, seguito da RLS/grants,
  publication, cleanup e smoke read-only;
- se restore non è sicuro, usare forward-fix secondo il runbook production.

## Retention

- osservabilità Client: buffer soltanto in memoria e bounded;
- audit operativo e retention backend restano server-side e owner-scoped;
- tracking, notification retry/dead-letter e account deletion hanno alert separati;
- nessun payload PII viene aggiunto per agevolare il debug;
- schedule, soglia, evidence di cleanup e legal hold richiedono `NEEDS_OWNER_VALUE`.

## Provider outage

- Maps: disabilitare Maps, mantenere tracking stato-only;
- live courier: passare a stato ordine/tracking status-only;
- external carrier: rimuovere il deep link/provider, mantenere timeline ordine;
- payment: mantenere `notConfigured`/disabilitato e impedire submit ambiguo;
- notifications: provider no-op, stato ordine disponibile in-app;
- telemetry: no-op, dominio funzionale invariato;
- Auth/backend: fail-closed, nessuna sessione o ordine inventato.

Ogni outage segue detection, severity, containment, recovery e communication template
definiti in `INCIDENT-RESPONSE.md`.

## Rollback

Il rollback usa `PRODUCTION-ROLLBACK-RUNBOOK.md`. Prima si applica il kill switch più
stretto; il database preferisce forward-fix salvo piano restore approvato. Store halt o
rollback richiedono owner e console esterni. Dopo ogni azione eseguire health, synthetic
smoke, reconciliation e verifica privacy redatta.

## Escalation

- SEV-0: escalation immediata a incident, security/privacy e capability owner;
- SEV-1: incident commander e owner checkout/payment/orders;
- SEV-2: owner della capability degradata e supporto;
- SEV-3: backlog manutenzione con owner e cadenza;
- destination, paging e contatti: `NEEDS_OWNER_VALUE`.

L'assenza del contatto è `OWNER_VALUE_REQUIRED`, non un CODE_BLOCKER; impedisce però
l'activation dell'on-call reale.

## Maintenance cadence

| Cadenza | Attività predefinita |
|---|---|
| Per release | version tracking, smoke sintetico, alert routing, kill switch |
| Giornaliera live | health, errori, webhook, retry, tracking stale, cleanup |
| Settimanale | reconciliation, trend crash-free, adoption, support aging |
| Mensile | restore drill, retention, owner roster, quota e key restriction |
| Trimestrale | incident drill, access review, rotation e runbook review |

Le cadenze diventano operative soltanto con owner e go-live reali.

## Drill sintetici prelaunch

I drill sono eseguiti localmente da `scripts/test-operations-readiness.sh` con input
bounded collegati a fixture, fake o contratti gia presenti. Un adapter operativo
deterministico produce il risultato atteso e il test confronta esattamente detection,
severity, kill switch, fallback, recovery e log safe. Ogni mapping alterato deve
fallire. Non sono usati rete, tempo reale o production.

| Drill | Scenario | Detection | Severity | Kill switch | Fallback utente | Recovery |
|---|---|---|---|---|---|---|
| D-01 | backend unavailable | health unavailable | SEV-1 | backend fail-closed | messaggio store unavailable | health e smoke verdi |
| D-02 | Maps unavailable | maps failure | SEV-2 | Maps OFF | tracking status-only | probe Maps e fallback |
| D-03 | payment provider unavailable | checkout payment unavailable | SEV-1 | payment OFF | nessun submit ambiguo | provider probe e reconciliation |
| D-04 | push unavailable | push degradation | SEV-2 | notifications OFF | stato ordine in-app | fake delivery e retry normalizzati |
| D-05 | stale delivery tracking | stale rate alert | SEV-2 | live tracking OFF | timeline status-only | freshness rientrata |
| D-06 | malformed catalog publication | invalid payload alert | SEV-2 | publication rollback | cache valida o unavailable | fixture valida ripubblicata |
| D-07 | bad release requiring rollback | crash/error regression | SEV-1 | store halt e capability OFF | release precedente supportata | smoke exact version verde |
| D-08 | notification retry flood | retry/dead-letter alert | SEV-1 | notifications OFF | stato ordine in-app | queue bounded e rate normale |
| D-09 | cleanup/retention failure | cleanup age alert | SEV-1 | writer cleanup OFF | nessun impatto client inventato | job sintetico e backlog verificati |
| D-10 | auth session expiry | unauthorized rate alert | SEV-2 | auth fail-closed | nuovo login senza loop | revoke e callback fixture verdi |

Ogni fixture include detection, classificazione, kill switch, fallback, recovery e un
log safe. Il record log completo e ammesso soltanto nella forma allowlisted
`component=<enum> outcome=failure category=<enum>`: qualunque chiave extra, identita di
dominio, contenuto carrello, email, telefono, coordinate, URL, token, indirizzo o secret
payment viene rifiutato.
