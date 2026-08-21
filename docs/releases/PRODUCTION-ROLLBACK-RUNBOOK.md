# Production rollback runbook

## Scopo e principi

Il rollback riduce l'impatto preservando dati, audit e confini owner-scoped. Si applica
la misura più piccola efficace: kill switch capability, stop rollout, provider OFF,
release precedente compatibile, forward-fix e infine restore. Non si eseguono reset,
delete o migration inverse improvvisate.

## Decision matrix

| Segnale | Prima azione | Escalation | Recovery target |
|---|---|---|---|
| Esposizione dati o auth/payment compromise | capability OFF, stop rollout, revoke scoped credential | SEV-0, security/privacy owner | accesso contenuto e credenziali ruotate |
| Ordini corrotti o ambigui | checkout/payment OFF, preservare ledger | SEV-0/1, commerce/database owner | ordini riconciliati senza duplicati |
| Checkout/payment indisponibile | payment OFF, fallback consentito | SEV-1, payment owner | metodo sicuro o provider ristabilito |
| Backend/RPC incompatibile | stop rollout, core flag OFF se necessario | SEV-1, backend/database owner | API/schema compatibili |
| Maps, push, tracking o carrier degradato | solo capability interessata OFF | SEV-2, provider owner | fallback status-only/no-op |
| Crash o regressione client | stop staged rollout, selezionare build precedente | SEV-1/2, release owner | crash-free baseline recuperata |
| Cleanup/retention fallito | job OFF se distruttivo, preservare evidence | SEV-1/2, database/privacy owner | backlog bounded e retention verificata |

## Trigger e autorità

- detection source, timestamp, release/version e severity devono essere registrati;
- incident commander, database owner, store owner e communication owner restano
  `NEEDS_OWNER_VALUE` finché l'organizzazione non li assegna;
- SEV-0/1 autorizzano il contenimento immediato della capability, non cancellazioni o
  restore non verificati;
- se non è chiaro se i dati siano compatibili, bloccare la promozione e scegliere il
  fallback fail-closed.

## Kill switch order

1. Maps: `DELIVERY_MAPS_ENABLED=false` e native config non attiva;
2. live courier: shop tracking mode `status_only`;
3. external carrier: rimuovere/disabilitare la route server-issued;
4. online payment: provider/configuration server-side `notConfigured`;
5. notifications: sender/provider OFF, preservando retry ledger;
6. non-essential telemetry: `NoopObservabilityPort`;
7. promozioni non essenziali: sospendere publication/promozione lato Admin.

Catalogo base, account e storico ordini restano disponibili se integri. I flag client
non sostituiscono RLS, grants o controlli provider.

## Store e client rollback

1. fermare rollout o availability del build problematico;
2. non riusare `versionCode` o build number;
3. selezionare una release precedente solo se il suo contratto API/schema è ancora
   supportato;
4. se non compatibile, mantenere rollout fermo e distribuire una nuova build corretta;
5. verificare link, privacy metadata e provider configuration sulla release scelta.

## Backend e database recovery

1. congelare deploy e job concorrenti;
2. catturare migration history e health in forma redatta;
3. per change additive o dati già scritti, preferire forward-fix idempotente;
4. usare migration inverse solo se versionata, testata e owner-approved;
5. usare restore soltanto quando perdita/corruzione supera il costo di dati successivi,
   con RPO/RTO e reconciliation espliciti;
6. dopo restore riapplicare credenziali correnti, RLS, grants, Realtime e cleanup state.

## Provider recovery

- Auth: disabilitare provider compromesso, revocare sessioni secondo policy e
  mantenere guest Storefront se sicuro;
- Maps: switch OFF, revoca/rotazione key, ispezione quota e leak window;
- Payments: switch OFF, fermare retry non idempotenti, riconciliare webhook/ledger;
- Notifications: sender OFF, contenere retry flood, preservare dead-letter;
- Observability: exporter OFF se perde dati o invia PII, mantenere diagnostica no-op.

## Recovery verification

1. `scripts/check-production-readiness.sh --mode technical` deve restare `READY`;
2. health e synthetic smoke devono passare sul release/schema recuperati;
3. riconciliare order ambiguity, payment mismatch, notification backlog e cleanup;
4. verificare RLS/grants, session lifecycle e account deletion;
5. confermare che nessun log/evidence contenga PII o secret;
6. documentare owner, timeline, azioni, risultati, rischio residuo e postmortem.

La riattivazione avviene capability per capability e richiede nuovamente
`--mode activation` `READY`; un fallback funzionante non equivale a provider guarito.
