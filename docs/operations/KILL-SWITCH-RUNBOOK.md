# Kill-switch runbook

## Principi

- usare il kill switch più stretto;
- default OFF/fail-closed in assenza di configurazione;
- non disabilitare catalogo, account o storico ordini per un provider accessorio;
- nessun pannello Admin o servizio remoto viene creato da TASK-042;
- ogni attivazione reale richiede owner e audit esterni `NEEDS_OWNER_VALUE`.

## Maps

- **Boundary**: doppio gate compile-time in `DeliveryMapAdapter` e adapter Google;
- **Trigger**: quota, key leakage/restriction, provider outage o rendering failure;
- **Execute**: release/config autorizzata con Maps OFF; nessuna key viene stampata;
- **Fallback**: tracking `statusOnly`, timeline e testo stato;
- **Verify**: mappa assente, nessuna chiamata provider, storico ordine disponibile;
- **Recovery**: restriction/quota/rotation esterna, probe sintetico, nuova release se
  necessaria; owner `NEEDS_OWNER_VALUE`.

## Live courier tracking

- **Boundary**: server mode `liveCourier`; Client accetta solo payload validato;
- **Trigger**: stale rate, coordinate/provider failure, privacy o reconnect loop;
- **Execute**: writer/config server-side autorizzato passa a `statusOnly`;
- **Fallback**: stato e timeline ordine senza coordinate;
- **Verify**: nessuna subscription live, cache sensibile rimossa dal lifecycle previsto;
- **Recovery**: freshness, RLS/retention e synthetic tracking verificati.

## External carrier tracking

- **Boundary**: server mode `externalCarrier` separato da `liveCourier`;
- **Trigger**: carrier outage, URL invalido/leak, redirect non approvato;
- **Execute**: rimuovere/disabilitare il mode esterno tramite owner backend autorizzato;
- **Fallback**: `statusOnly` e storico ordine;
- **Verify**: nessun URL carrier esposto o loggato;
- **Recovery**: allowlist/redirect e probe sintetico verificati.

## Payments

- **Boundary**: online payment resta `OnlinePaymentConfiguration.notConfigured` e il
  repository rifiuta l'opzione non abilitata;
- **Trigger**: provider/webhook indisponibile, mismatch, compromissione o ambiguità;
- **Execute**: payment OFF lato provider/backend; bloccare nuovi submit interessati;
- **Fallback**: nessuna transazione inventata; mostrare pagamento non disponibile;
- **Verify**: submit fail-closed, idempotency preservata, reconciliation completata;
- **Recovery**: webhook signature/retry, merchant e reconcile verificati dall'owner.

## Notifications

- **Boundary**: `UnconfiguredPushTokenProvider` e disponibilità `notConfigured`;
- **Trigger**: FCM/APNs outage, credential leak, retry flood o consenso non valido;
- **Execute**: dispatcher/push OFF senza cambiare lo stato ordine;
- **Fallback**: storico e dettaglio ordine in-app;
- **Verify**: nessun token registrato/inviato, retry bounded, dead-letter stabile;
- **Recovery**: credenziali/consenso/retry verificati con fake prima del live.

## Non-essential telemetry

- **Boundary**: staging/production non configurati usano `NoopObservabilityPort`;
- **Trigger**: leakage sospetto, exporter outage, consenso revocato o rate anomalo;
- **Execute**: analytics/crash exporter OFF o consent `none`;
- **Fallback**: dominio applicativo invariato; diagnostica sintetica locale redatta;
- **Verify**: zero export, buffer in-memory non persistente, app funzionale;
- **Recovery**: redactor/schema regressions, consent e destination approvati.

## Non-essential promotions

- **Boundary**: publication/promotion server-authoritative lato Admin;
- **Trigger**: contenuto malformato, schedule/timezone errato o prezzo ambiguo;
- **Execute**: sospendere la promotion/publication interessata, non l'intero catalogo;
- **Fallback**: prezzo/catalogo valido non promozionale o prodotto unavailable;
- **Verify**: nessun prezzo inventato, cache aggiornata e browse sintetico valido;
- **Recovery**: fixture valida ripubblicata dall'owner e cache invalidata.

## Decision e recovery log

Per ogni switch registrare incident ID, capability, reason enum, stato precedente/nuovo,
timestamp UTC, owner role, verifica fallback e criterio di recovery. Non registrare
secret, endpoint completo, coordinate, identità, payload o dati carrello.

La riattivazione richiede causa rimossa, test sintetico verde, privacy verificata,
monitoring destination pronta e approvazione owner. In prelaunch si esegue soltanto il
drill con fixture/no-op; nessuna capability production viene mutata.
