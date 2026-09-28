# Contratti e riconciliazione backend

## Osservazione remota, sola lettura

Target riconfermato: `merchandisecontrol-dev`, ref `jpgoimipbothfgkokyvm`,
ACTIVE_HEALTHY, PostgreSQL 17.6.1.104. È un database condiviso, non sacrificabile.
Metadata: 145 migration registrate, comprese modifiche WeChat successive fino a
`20260926164349`. Nessuna query dati cliente, mutation, fixture o DDL eseguita qui.

Il [manifest consumer](../../../contracts/client-backend-rpc-manifest.json) contiene
**55 RPC**: schema, nome, firma identitaria, parametri con default/tipi, ritorno,
SECURITY DEFINER, search_path/timeout, grants anon/authenticated, hash definizione SQL,
file consumer e loro SHA256, migration canonica/SHA256, versioni payload attese nei parser.
Le liste payload sono riferite al file consumer: alcuni parser condividono più RPC.
Non si afferma che la firma SQL da sola verifichi il payload restituito.

32 RPC esistenti coincidono con schema locale canonico in firme, default, grants,
settings e hash del corpo SQL. `customer_order_create_v2` e `customer_order_read_v2`
sono presenti. Le 23 assenti sono elencate nella tabella sotto. Anche la storia
migration manca delle due versioni commerce. `customer_addresses` ha solo le colonne
v1; i nove nuovi oggetti commerce controllati sono assenti: nessuna installazione
parziale di questi oggetti è stata rilevata. Questo non equivale a un audit completo
su ogni oggetto o contenuto dello staging.

| Gruppo | RPC assenti |
|---|---|
| Address v2 | customer_address_delete_v2, customer_address_upsert_v2, customer_addresses_read_v2 |
| Delivery context/checkout | customer_delivery_context_read_v1, customer_delivery_context_select_v1, storefront_delivery_context_preview_v1, customer_checkout_quote_create_v2 |
| Inbox | customer_notification_mark_read_v1, customer_notifications_list_v1, customer_notifications_mark_all_read_v1 |
| Riordino | customer_order_reorder_apply_v1, customer_order_reorder_preview_v1 |
| Assistenza | customer_after_sales_cancel_v1, customer_after_sales_create_v1, customer_after_sales_evidence_register_v1, customer_after_sales_evidence_upload_ticket_v1, customer_after_sales_list_v1, customer_after_sales_order_lines_v1 |
| Recensioni | customer_review_submit_v1, customer_review_update_v1, customer_reviews_list_v1, storefront_product_reviews_v1 |
| Ricerca | storefront_search_suggestions_v1 |

## Migration canoniche da applicare, in ordine

Autorità: Admin `fe4907adc51ff842720e1c7eb36aa05e0fa53cb8`, directory
`supabase/migrations/`. Non si introducono copie né modifiche retroattive.

1. `20260823023037_client_commerce_journey_v1.sql`
   SHA256 `741faa0f2d5480e9a38e29216555c182043234a3d8aec784f642e716e5da66cc`.
   Transazione propria, colonne address additive, dominio delivery context,
   inbox/riordino/assistenza/reviews, constraints/RLS/grants, RPC e refresh schema.
   Include modifiche ai privilegi di lettura indirizzi: la compatibilità con i client
   esistenti va verificata tramite RPC e suite, non assumendo accesso diretto invariato.
2. `20260823150000_customer_after_sales_order_lines_v1.sql`
   SHA256 `18fbab7904dcecd901e9237b03164db7dd84f9e3e67619eeb19eccc2a2b55467`.
   Read model storico owner-scoped e correzione della creazione del caso rispetto alla
   quantità residua. Richiede la prima; usare runner migration transazionale perché il
   file non contiene un proprio BEGIN/COMMIT.

Non applicare in blocco tutte le migration Admin né usare `db reset` sul progetto
condiviso. I nuovi timestamp WeChat registrati non sostituiscono queste due versioni.

## Validazione isolata realmente eseguita

Container `cmc-functional-audit-20260928`, immagine PostgreSQL Supabase17.6.1.158,
`--network none`, zero porte esposte. DB dedicato `cmc_verified`.
Il bootstrap usa solo lo schema, **senza dati**, da un ambiente locale predecessore
fermo alle migration precedenti. Ripristinati extensions e grant canonici; applicate
in ordine tutte le 21 migration successive, incluse le due candidate.
Le altre migration sono servite solo a ricostruire localmente l'HEAD Admin.
Non è un reset CLI integrale da zero e non è un apply remoto.

Comandi rappresentativi effettivamente usati:

```bash
docker exec -i cmc-functional-audit-20260928 \
  psql -U postgres -d cmc_verified -v ON_ERROR_STOP=1 < migration-canonica.sql
docker exec -i cmc-functional-audit-20260928 \
  psql -U postgres -d cmc_verified -v ON_ERROR_STOP=1 -At < test-canonico.sql
```

Il dump schema-only non contiene righe di configurazione cron/storage/publication.
I primi tentativi hanno rilevato extension/default-grants e seed mancanti. Corretto
esclusivamente il bootstrap locale: extension canoniche, default grants col ruolo
proprietario, tre schedule cron, bucket immagini pubblico e pubblicazione realtime
previsti dalle migration. Non sono stati indeboliti test o RLS. I log completi e i
fallimenti iniziali restano locali; la tabella finale registra solo le riesecuzioni
concluse e controllate per `not ok`, oltre all'exit code psql.

23 suite / **1.034 assertion pgTAP PASS**, exit0; zero `not ok`, piano di ogni suite
coincidente con il conteggio. Journey55 include assenza accesso cross-owner/shop,
quantità residua assistenza, acquisto verificato, idempotenza e boundary privilegiati.
Le suite preesistenti verificano anche compatibilità del checkout reservation v1 e
order/payment v2, quote, carrello, RLS, pubblicazione e confine fiscale POS.
Il registro [validation.md](validation.md) riporta tutti i conteggi.

Lo snapshot positivo locale del nuovo gate unisce metadata realmente letti da pg_proc
alle versioni della ricostruzione canonica: è `snapshot_only`, non una ricevuta di
migration history CLI. I test negativi distinguono firme, overload, grant/body drift e
migration mancante. Lo snapshot remoto reale fallisce con 23 RPC e 2 migration mancanti.

## Preflight, recovery e verifiche da eseguire dopo il mandato

**Stato apply condiviso: BLOCKED.** Il prompt corrente richiede un mandato specifico
per target/azione e non rinnova i due tentativi storici esauriti. Anche backup/PITR e
finestra operativa devono essere attestati dal proprietario del database. Owner:
utente/responsabile Supabase; reviewer backend distinto dal writer.

Prima della scrittura:

1. Riconfermare ref, SHA Admin/Client, hash esatti dei due file, 145 versioni/hash della
   history e assenza dei nuovi oggetti; interrompere su variazioni o apply parziale.
2. Ottenere e verificare backup ripristinabile/PITR con timestamp e owner; acquisire
   definizioni/grants/policy/constraint e history antecedenti in archivio protetto locale.
3. Verificare spazio, lock, compatibilità client ancora in uso e nessuna mutation
   concorrente nella finestra; determinare timeout e limite di tentativi esplicito.
4. Review del piano/diff SQL e restore rehearsal in database isolato. Il test locale
   già svolto prova apply/contratti; **restore remoto/PITR non è stato provato**.

Apply: primo file, readback e ricevuta history, poi secondo file transazionale. Nessun
reset/truncate, repair history fittizio, broad grant o bypass di RLS. Su failure del
primo file verificare rollback effettivo; su failure del secondo preservare la prima
migration e il suo receipt, interrompere e diagnosticare prima di altro tentativo.

Dopo ogni apply: rileggere history/versioni/hash e oggetti; dopo entrambi eseguire il
gate live55, confrontare definizioni/grants/settings, FORCE RLS e policy; verificare
che le vecchie ricevute non cambino. Eseguire test con fixture sintetiche approvate
owner A/B e shop A/B, anon/auth/service, versioni obsolete, replay e v1 preesistenti;
readback business e cleanup identificato. SQL locale non abilita queste scritture.

Recovery: in caso di degrado sospendere il percorso nuovo e conservare schema/ledger
additivi; niente DROP dei nuovi oggetti se contengono dati. Ripristino definizioni/ACL
o fix forward solo dopo review e nuova verifica dei vincoli; PITR esclusivamente
nell'ambiente/finestra approvati. Attestare nuovamente i client vecchi e le funzioni
preesistenti. Nessuna recovery production o modifica WeChat compresa nel mandato.

## Gate ripetibile nel Client

```bash
python3 scripts/check-backend-compatibility.py --source-only
PYTHONDONTWRITEBYTECODE=1 python3 scripts/test-backend-compatibility.py
python3 scripts/check-backend-compatibility.py --emit-sql
python3 scripts/check-backend-compatibility.py --snapshot /percorso/metadata.json
CMC_BACKEND_PGSERVICE=servizio_readonly \
  bash scripts/check.sh --backend-config /percorso/config-validata.json
```

`--source-only` è incluso in CI e check.sh; dichiara runtime NOT_RUN. `--snapshot`
è diagnostico e non abilita upload. Il gate integrato esplicito e i preflight upload
Android/iOS richiedono una connessione live autorizzata. Le credenziali rimangono nel
meccanismo pg_service/pgpass approvato; non vengono richieste o stampate in chat.
Il target è derivato dalla configurazione dell'artifact, connessione diretta al ref,
porta5432/database postgres, TLS verify-full e transazione READ ONLY. Connessioni
pooler/custom-domain non sono attualmente supportate: falliscono chiuse.

Android verifica prima la firma/configurazione e il marker della stessa configurazione
in tutti e tre i libapp.so dell'AAB; la verifica preesistente confronta anche payload
APK/AAB. iOS conserva l'attestation runtime/native/sealed-app già esistente. Poi entrambi
richiedono compatibilità backend prima di `UPLOAD_INPUTS_VALIDATED`. Non hanno effettuato
upload. Un esito live_schema PASS proverebbe struttura/definizioni/history, lasciando
sempre payload, owner/shop E2E e device come gate distinti.
