# ADR-012 — Metodi di pagamento Storefront v1 e confine provider

- **Stato**: ACCEPTED
- **Data**: 2026-08-03
- **Task**: TASK-032
- **Decision owner**: USER_APPROVER / release train Storefront v1

## Contesto

Storefront v1 deve creare ordini realmente confermabili senza inventare un merchant
provider, credenziali o un pagamento online. Il totale resta un dato autorevole del
server; ordine cliente, stato dell'incasso e vendita fiscale POS sono aggregati
distinti. Retry dopo timeout, callback duplicate e webhook fuori ordine non possono
produrre doppio incasso o doppia vendita.

## Decisione

La v1 abilita due metodi offline, solo quando shop e fulfillment li consentono:

- `pay_at_pickup` per `pickup` e `reservation`;
- `cash_on_delivery` per `delivery`, con opt-in esplicito dello shop.

`online_payment` resta fail-closed e `not_configured`. Non viene scelto alcun provider
finché non esistono merchant contract, credential sandbox non interattive, ownership
operativa e webhook verificabile. Il Client riceve una allow-list server-side tramite
`storefront_payment_options_v1` e invia a `customer_order_create_v2` soltanto quote,
versione attesa, metodo e idempotency key: non invia importo, sconto, stato pagamento,
provider reference o totale autorevole.

Il backend crea atomicamente:

1. order e item snapshot server-authoritative;
2. payment snapshot con importo uguale al totale dell'ordine;
3. primo attempt idempotente;
4. evento append-only `payment_due`;
5. mutation receipt per il replay della stessa richiesta.

## State machine

Gli stati pubblici ammessi sono:

`due_at_fulfillment -> pending_provider -> processing -> authorized -> collected`

con rami controllati `failed`, `cancelled`, `refund_pending`, `refund_failed` e
`refunded`. Le transizioni sono monotone, versionate e service-only. Un evento di
pagamento non crea `pos_sales` né un fiscal reference; il POS registra la vendita
fiscale soltanto nel proprio flusso autorizzato.

## Provider e webhook

`PaymentProvider` è un'interfaccia server-side. L'adapter predefinito è disabled; il
recording adapter esiste soltanto per contract test. Il boundary webhook dormiente
richiede raw bytes, firma verificata da un adapter iniettato, timestamp limitato,
event ID deduplicato, payload bounded e hash delle reference. Nessun PAN, CVC, token,
raw body, provider reference o secret viene restituito al Client o scritto nei log.

## Idempotenza e timeout ambiguo

La chiave resta stabile per l'intero tentativo e include implicitamente il metodo nel
request hash. Un replay identico restituisce lo stesso order/payment; una chiave
riutilizzata con metodo o versione diversi fallisce con `idempotency_conflict`. Il
Client persiste metodo e chiave nel draft v3 e, dopo timeout/offline, consulta o ripete
lo stesso intento senza generare un nuovo addebito.

## RLS e autorizzazione

Le tabelle payment/attempt/event/mutation/webhook sono private, `FORCE ROW LEVEL
SECURITY` e senza policy client. Solo RPC con `search_path` vuoto espongono payload
pubblici allow-listed. La configurazione Admin è revision-bound, staff-lease-bound e
audited; tentare di abilitare online payment senza configurazione viene rifiutato.

## Attivazione futura dell'online payment

Richiede una nuova decisione e tutti i seguenti prerequisiti:

- provider e merchant identity verificati per il Cile;
- sandbox credential già disponibili via secret manager, mai nel repository;
- firma webhook documentata e testata con fixture ufficiali;
- reconciliation, refund, timeout, alerting e runbook operativi;
- privacy/legal/data-safety aggiornati;
- integrated review APPROVED e feature flag con rollout controllato.

## Rollback

Il rollback operativo mantiene schema e ledger additivi, disabilita i metodi nelle
settings e conserva `online_payment = false`. Non si eliminano eventi o ordini. Il
Client fallisce chiuso quando le options non sono disponibili e mantiene il carrello;
le funzioni v1 preesistenti restano intatte durante il rollout additivo.

## Conseguenze

- Storefront v1 può essere rilasciata con metodi reali senza dipendenza da un provider
  esterno.
- Un provider online resta un gate esterno esplicito, non un falso PASS.
- Il modello è pronto a un adapter futuro senza spostare autorità economica nel Client
  o confondere pagamento, ordine e vendita fiscale.
