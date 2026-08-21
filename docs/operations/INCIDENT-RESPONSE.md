# Incident response

## Stato prelaunch

Il processo è pronto per drill sintetici; non attesta incidenti production osservati.
Incident commander, canale di escalation e contatti restano `NEEDS_OWNER_VALUE`.

## Ciclo comune

1. detect e deduplica con fingerprint/correlation safe;
2. assegna severity e incident ID non derivato da dati cliente;
3. nomina owner e incident commander;
4. contiene con il kill switch più stretto;
5. comunica con template approvato e placeholder owner-provided;
6. recupera e verifica con health/synthetic smoke;
7. preserva evidence redatta e completa postmortem bounded.

## Severity

### SEV-0

- **Detection**: esposizione dati, compromissione Auth/payment o corruzione ordini
  confermata/plausibile.
- **Owner**: incident commander, security/privacy owner e capability owner,
  tutti `NEEDS_OWNER_VALUE`.
- **Containment**: arresto immediato della capability interessata; preservare catalogo,
  account e storico quando non coinvolti.
- **Kill switch**: telemetry OFF per leakage; payment OFF per compromissione; Auth
  fail-closed; tracking/Maps/notification OFF se sono la superficie.
- **Recovery**: rotazione/revoke esterni, fix o restore/forward-fix autorizzato,
  RLS/grants e smoke/reconciliation verificati.
- **Communication template**: `[INCIDENT_ID] servizio interessato sospeso; indagine in
  corso; prossimo aggiornamento [NEEDS_OWNER_VALUE]`.
- **Evidence**: timeline UTC, release, capability, safe fingerprint, decisioni e gate;
  mai secret, PII, coordinate, payload o credenziali.
- **Postmortem**: obbligatorio con root cause, impatto bounded, detection gap, action
  owner e regression test; distribuzione `NEEDS_OWNER_VALUE`.

### SEV-1

- **Detection**: checkout/pagamento indisponibile, ordini non confermabili, ambiguità
  ordine/pagamento, grave rischio cross-shop o retry flood.
- **Owner**: incident commander e owner checkout/payment/orders/backend,
  `NEEDS_OWNER_VALUE`.
- **Containment**: impedire nuovi submit, payment OFF, notification OFF se flood,
  bloccare il writer ambiguo senza alterare storico ordini.
- **Kill switch**: capability payment/notification/writer specifica; store halt per bad
  release soltanto con owner esterno.
- **Recovery**: idempotency/reconciliation, health, ordine sintetico non reale e smoke
  release; nessuna transazione reale in prelaunch.
- **Communication template**: `[INCIDENT_ID] checkout o conferma ordine degradati;
  evitare nuovi tentativi; aggiornamento [NEEDS_OWNER_VALUE]`.
- **Evidence**: conteggi aggregati, status enum, release, correlation safe e decisioni.
- **Postmortem**: richiesto; include ambiguity window, reconciliation e test di replay.

### SEV-2

- **Detection**: catalogo degradato, push indisponibile, tracking stale/degradato,
  Realtime reconnect o Maps provider indisponibile.
- **Owner**: capability owner e support owner `NEEDS_OWNER_VALUE`.
- **Containment**: Maps/tracking/push/promotions OFF in modo separato; usare cache,
  timeline ordine o status-only.
- **Kill switch**: soltanto la capability degradata, mai catalogo/account/storico per
  un outage provider non essenziale.
- **Recovery**: probe sintetico, freshness/reconnect normalizzati e fallback verificato.
- **Communication template**: `[INCIDENT_ID] funzione accessoria degradata; funzioni
  principali disponibili; aggiornamento [NEEDS_OWNER_VALUE]`.
- **Evidence**: rate/bucket aggregato, release, provider class e safe fingerprint.
- **Postmortem**: richiesto se ricorrente, prolungato o promosso di severity.

### SEV-3

- **Detection**: problema visuale, singolo device o comportamento non bloccante senza
  perdita dati o impatto transazionale.
- **Owner**: mobile/support owner `NEEDS_OWNER_VALUE`.
- **Containment**: workaround documentato; nessun kill switch globale salvo regressione.
- **Kill switch**: `NOT_APPLICABLE` se la capability resta sicura; altrimenti il flag
  specifico già esistente.
- **Recovery**: riproduzione su fixture/device, fix nella release successiva e smoke.
- **Communication template**: `[CASE_ID] problema non bloccante registrato; workaround
  [NEEDS_OWNER_VALUE]`.
- **Evidence**: platform, release, screen enum e outcome; niente screenshot sensibili.
- **Postmortem**: facoltativo; maintenance note obbligatoria con owner e scadenza.

## Escalation e handoff

- ogni cambio severity registra autore/owner role, motivo e timestamp UTC;
- il cambio turno usa incident ID, stato, decisioni, next action e safe evidence;
- legal, store, provider e communication owner restano owner-provided;
- nessun dato cliente o secret viene incollato in chat, issue, PR o evidence.

## Closure

Un incidente è `RECOVERED_PENDING_OBSERVATION` dopo health e synthetic smoke verdi;
diventa chiuso soltanto dopo la finestra owner-approved, reconciliation applicabile,
support update e action item assegnati. In prelaunch si chiude soltanto il drill, non un
incidente production.
