# Production launch runbook

## Confine

Questo runbook prepara un lancio controllato ma non lo esegue durante TASK-041. Ogni
azione esterna richiede l'owner reale e un activation record redatto. Production,
billing e store restano invariati finché il gate activation non è `READY`.

## A. Preflight

1. fissare Client/Admin SHA, version/build e candidato store senza rigenerarlo se il
   runtime non è cambiato;
2. eseguire `scripts/check-production-readiness.sh --mode technical`;
3. eseguire `scripts/check-production-readiness.sh --mode activation` e fermarsi se
   qualsiasi requisito è `MISSING` o `UNVERIFIABLE_EXTERNAL`;
4. confermare production project, shop slug/timezone, dominio, provider, store,
   monitoring, owner legale e supporto;
5. confermare zero incidenti SEV-0/1 aperti e una rollback authority nominata come
   `NEEDS_OWNER_VALUE` nell'activation record, non in Git.

## B. Backup

1. l'owner database crea o verifica un backup production immediatamente precedente;
2. registra ID, timestamp, retention e checksum/metodo di verifica senza dati o URL;
3. conferma restore target, RTO/RPO e accesso dell'operatore;
4. se backup o restore plan non sono verificabili, il lancio si ferma.

## C. Migration order

1. confrontare la history production con l'inventory Git Admin senza applicare file
   fuori lineage;
2. applicare soltanto tramite la pipeline Admin approvata, in ordine filename:
   Storefront schema/RLS, catalog projection/public API, publication/promotions/images,
   profiles/devices/cart, availability/holds/checkout/orders, notifications/payments,
   delivery tracking e shop timezone;
3. dopo ogni gruppo verificare migration history, schema, RLS, grants e test read-only;
4. non modificare direttamente `auth`, `storage` o `realtime` schema; arrestare su
   divergenza, timeout o assertion fallita;
5. una migration dati irreversibile richiede prima forward-fix e restore decision.

## D. Backend activation

1. mantenere publication, payment, notification, tracking e provider flag OFF;
2. verificare health, RPC guest, owner-scoped account/orders e cleanup schedule;
3. verificare RLS/grants, Realtime policy, retention e shop timezone;
4. attivare il solo Storefront core necessario, poi capability una alla volta;
5. non usare il client come confine di autorizzazione.

## E. Provider activation

Ordine: Auth e dominio; observability destination; notifiche; Maps; pagamenti. Per ogni
provider verificare environment, account, allowlist/restriction, quota, consent,
rotation, kill switch e fallback prima di abilitarlo. Payment, push, Maps e telemetry
restano indipendenti: il fallimento di uno non deve disabilitare catalogo, account o
storico ordini.

## F. Store release activation

1. confermare listing, privacy/legal, support, account deletion e screenshot;
2. verificare candidate TASK-039/040, signing e console access senza stampare input;
3. selezionare i build attestati e impedire promozioni automatiche;
4. iniziare con tester/internal/TestFlight o staged release autorizzata; nessun upload
   o release è parte di TASK-041;
5. registrare store release ID, version/build e stato, mai credenziali.

## G. Canary

1. mantenere il rollout iniziale al massimo al 5%;
2. usare account e ordini sintetici, nessuna transazione reale non autorizzata;
3. lasciare capability non essenziali OFF nella prima finestra;
4. valutare almeno backend, auth, catalogo, checkout, order ambiguity, crash e privacy;
5. promuovere soltanto con owner release e operations concordi.

## H. Smoke test

Eseguire cold start, guest catalog/search/detail, account/sessione, cart revalidation,
checkout con metodo non-online o provider sandbox esplicitamente approvato, order
receipt/history, status-only tracking, support/privacy/account deletion entrypoint e
deep link. Se attivi, verificare separatamente Maps attribution, push test e payment
synthetic. Evidence solo aggregate e redatte.

## I. Monitoring iniziale

Osservare health, latency/error rate, auth failure, catalog RPC, checkout/order/payment,
push, tracking/Reatime, Maps, crash-free sessions, version adoption, cleanup e account
deletion. L'alert destination e gli owner devono essere reali prima del live; nessun
payload contiene email, telefono, indirizzo, coordinate, token, order ID o cart detail.

## J. Rollback decision

- SEV-0: arresto immediato della capability interessata e incident response;
- SEV-1: stop rollout, payment/checkout/order switch OFF e valutazione rollback;
- SEV-2: isolare provider con il kill switch, mantenendo core disponibile;
- SEV-3: non aumentare rollout; fix nel ciclo ordinario.

Usare `PRODUCTION-ROLLBACK-RUNBOOK.md`; l'owner decide fra kill switch, store halt,
backend rollback, forward-fix o restore sulla base dell'integrità dati.

## K. Rollback execution

1. congelare rollout e cambi concorrenti;
2. disabilitare la capability minima coinvolta;
3. revocare/ruotare credential solo in caso di leak o compromissione;
4. ripristinare release precedente solo se compatibile con schema e API correnti;
5. preferire forward-fix per migration applicate; restore richiede decisione SEV-0/1;
6. mantenere ledger/evidence di ordini e pagamenti, senza cancellazioni correttive.

## L. Recovery verification

Ripetere preflight tecnico, health e synthetic smoke; riconciliare ordini, pagamenti,
notification retry e cleanup; confermare version adoption e assenza di errori nuovi;
verificare che i kill switch restino nello stato deciso. Chiudere l'incidente solo con
owner, timeline, evidence redatta, follow-up e postmortem.
