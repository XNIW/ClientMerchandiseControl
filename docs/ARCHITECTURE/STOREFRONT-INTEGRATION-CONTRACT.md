# Storefront integration contract

## Metadati

| Voce | Valore |
|---|---|
| Contract ID | `CMC-STOREFRONT-LOGICAL` |
| Versione | `1.0.0` |
| Stato | baseline normativa target; nessuna disponibilità runtime implicita |
| Task di origine | TASK-003 |
| Logical contract owner | repository `ClientMerchandiseControl` |
| Server contract owner | repository `merchandise-control-admin-web`, quando TASK-010 introdurrà il contratto machine-readable |
| Business decision owner | ruoli business autorizzati definiti per dominio |
| Control plane | Admin Console |
| Writer/enforcer | Admin server writer; Supabase runtime/enforcement |
| Consumer | `ClientMerchandiseControl` |
| Change authority | task esplicito approvato, con i domain owner impattati |
| Decisione di ownership | [ADR-010](../DECISIONS/ADR-010-storefront-contract-ownership.md) |

Questo documento è la fonte del contratto logico fra il client pubblico e il futuro
dominio Storefront. Il futuro contratto server machine-readable appartiene al repository
Admin: i due livelli **MUST** restare coerenti e nessuno dei due **MUST** correggere
silenziosamente l'altro. I nomi delle risorse descrivono concetti di business: non sono
nomi di tabelle, view, endpoint, funzioni, bucket, DTO o payload.

La versione `1.0.0` fissa gli invarianti da rispettare nelle implementazioni future, ma
non prova che schema, API, dati o networking Storefront esistano già. Supabase è la
piattaforma futura di persistenza ed enforcement; non è il business decision owner.

## Linguaggio normativo

I termini in maiuscolo hanno valore normativo:

- **MUST**: requisito obbligatorio per la conformità;
- **MUST NOT**: comportamento vietato;
- **SHOULD**: requisito atteso, derogabile soltanto con motivazione e decisione
  tracciata;
- **SHOULD NOT**: comportamento da evitare, derogabile con la stessa disciplina;
- **MAY**: opzione permessa, non una capability già disponibile.

Una capability nominata al futuro non è autorizzata né implementata finché il task
proprietario non ne completa specifiche, enforcement, test ed evidence.

## Vocabolario

| Termine | Significato logico |
|---|---|
| Storefront | confine customer-facing separato dal dominio inventory operativo |
| Risorsa | informazione o stato di business identificabile, indipendente dalla sua futura rappresentazione fisica |
| Capability | operazione permessa a un attore su una classe di risorse, entro uno shop scope esplicito |
| Proiezione | rappresentazione Storefront prodotta da fonti operative tramite regole di pubblicazione controllate |
| Intento | richiesta del client che il server può validare, rifiutare o accettare; non è un fatto autorevole |
| Commercial truth | prezzo, promozione, disponibilità, costo accessorio o condizione di fulfillment pubblicati o rivalidati dal server |
| Guest | persona senza identità cliente autenticata |
| Customer | persona con identità cliente autenticata e capability limitate alle proprie risorse |
| Staff | operatore autorizzato tramite superfici Admin/POS separate dal client pubblico |
| Server | confine fidato che applica pubblicazione, autorizzazione, rivalidazione, idempotenza e audit |
| Ordine cliente | stato Storefront customer-facing creato soltanto dopo accettazione autorevole del server |
| Vendita fiscale | evento operativo/fiscale originato e governato dal POS, distinto dall'ordine cliente |

## Layer del contratto

I layer separano responsabilità e fonti di verità. Non sostituiscono le dipendenze del
Master Plan e non autorizzano task concorrenti: resta valido un solo task `ACTIVE`.

| Layer | Responsabilità | Owner di implementazione |
|---|---|---|
| L0 — dominio e trust | invarianti, attori, shop scope, commercial truth, confine ordine/vendita, policy di failure e versioning | TASK-003 |
| L1 — ambiente | selezione esplicita dell'ambiente e configurazione fail-closed, senza fallback fra ambienti | TASK-004 |
| L2 — persistenza ed enforcement | rappresentazione fisica, migration ownership, grant espliciti, RLS e operazioni server-side | TASK-005 |
| L3 — proiezione e pubblicazione | origine, proiezione, visibilità, prezzi, promozioni e media pubblici | TASK-006–TASK-009 |
| L4 — interfaccia consumer | contratti fisici di query, errori, ricerca, paginazione, fixture e contract test | TASK-010 |
| L5 — trasporto e readiness | connessione staging, stato di salute e failure di bootstrap/rete | TASK-011 |
| L6 — esperienza e identità | UI pubblica, cache, autenticazione, profilo e consenso | TASK-012–TASK-022 |
| L7 — commercio e operazioni | carrello, hold, fulfillment, ordini, handoff POS, eventi e pagamenti | TASK-023–TASK-032 |
| L8 — assurance e rilascio | security, resilienza, osservabilità, acceptance e operatività | TASK-033–TASK-042 |

Ogni layer successivo **MUST** preservare gli invarianti di L0. Un dettaglio fisico
**MUST NOT** ampliare una capability, cambiare il business owner o indebolire un
controllo definito in questo documento. In caso di conflitto prevale il layer logico
finché un cambio versionato e autorizzato non aggiorna esplicitamente il contratto.

## Shop scope e identità della risorsa

1. Ogni risorsa, lettura, intento, stato derivato, riferimento e cache Storefront
   **MUST** essere associato esattamente a uno `shop_id`.
2. `shop_id` **MUST** essere un UUID valido e **MUST** essere trattato come identificatore
   opaco. Il suo valore **MUST NOT** codificare o autorizzare ruolo, ambiente, cliente o
   capability.
3. L'implementazione iniziale single-store **MUST NOT** usare assenza, valore nullo,
   “primo shop”, “ultimo shop” o altro default implicito come shop scope.
4. Uno `shop_id` ricevuto, memorizzato o scelto dal client **MUST** essere considerato
   non fidato. Il server **MUST** risolvere e validare lo scope per ogni accesso.
5. Una route, un deep link, una preferenza, una cache key o un valore UI contenente
   `shop_id` **MUST NOT** concedere accesso.
6. Una risorsa **MUST NOT** essere letta, correlata, spostata o mutata attraverso shop
   differenti senza una capability server-side separata e versionata. Questa baseline
   non concede capability cross-shop.
7. Il client **MUST NOT** ripiegare su un altro shop quando lo scope richiesto è
   mancante, invalido, non disponibile o vietato.

La forma di serializzazione, il trasporto e l'eventuale discovery di `shop_id`
appartengono al layer L4 e non sono definiti qui. Questo contratto non richiede un
nuovo flag compile-time per lo shop in TASK-004.

## Attori e confine di fiducia

Il dispositivo mobile e tutto il suo stato locale sono non fidati. La UI può guidare
l'utente, ma non costituisce un controllo di sicurezza.

- Una publishable key **MUST** identificare soltanto l'applicazione/progetto pubblico;
  **MUST NOT** essere interpretata come identità utente o autorizzazione.
- Una sessione valida **MUST** autenticare un soggetto, ma **MUST NOT** concedere
  automaticamente ogni capability.
- L'autorizzazione **MUST** essere applicata server-side per attore, risorsa, azione e
  `shop_id`.
- UI, route, deep link, email, cache, stato locale, `shop_id` e `user_metadata`
  **MUST NOT** essere fonti di autorizzazione.
- Una chiave privilegiata, inclusi secret o service role, **MUST NOT** essere inclusa,
  registrata o utilizzata dal client.
- Ogni superficie Storefront fisicamente esposta **MUST** avere grant espliciti e RLS
  coerente; grant e RLS sono controlli distinti e nessuno dei due **MUST** sostituire
  l'altro. L'esposizione predefinita della Data API **MUST NOT** essere assunta.
- Il personale **MUST NOT** ottenere capability staff attraverso il client pubblico.
  Admin Console e POS restano superfici separate con autenticazione e autorizzazione
  proprie.
- Android/iOS operativi e Win7POS **MUST NOT** diventare API runtime dirette del client
  pubblico.

## Matrice risorse e capability

La matrice è una allowlist logica. Tutto ciò che non è concesso esplicitamente è
**default-deny**.

| Area logica | Guest | Customer | Staff | Server |
|---|---|---|---|---|
| Contesto pubblico dello shop e catalogo pubblicato | **MUST** poter leggere senza login | **MUST** avere la capability pubblica equivalente, concessa esplicitamente | gestisce soltanto dalla superficie autorizzata | proietta, filtra e autorizza |
| Prezzi, promozioni, disponibilità e condizioni pubblicate | legge soltanto commercial truth pubblica | legge la capability pubblica equivalente, concessa esplicitamente | propone/governa dal control plane | decide validità e produce il valore autorevole |
| Media Storefront pubblicati | legge soltanto rendition/riferimenti pubblici | legge la capability pubblica equivalente, concessa esplicitamente | gestisce le sorgenti fuori dal client pubblico | pubblica e separa gli asset pubblici dalle superfici interne |
| Selezioni locali, inclusi preferiti o carrello non confermato | **MAY** crearle sul dispositivo | **MAY** crearle sul dispositivo o sincronizzarle quando una capability futura lo consente | nessuna capability implicita | non le tratta come commercial truth |
| Identità, profilo, indirizzi e consensi cliente | nessun accesso remoto | accede soltanto alle proprie risorse con capability esplicita | nessun accesso implicito; eventuali necessità operative richiedono scope separato | applica ownership, privacy e audit |
| Intenti commerciali remoti, inclusi hold, checkout e ordine | nessuna capability remota in questa baseline | **MAY** richiederli soltanto quando il task proprietario li abilita; non decide l'esito | opera soltanto nei workflow autorizzati | rivalida, rende idempotente, accetta o rifiuta |
| Storico, stato ed eventi dell'ordine cliente | nessun accesso | legge soltanto i propri ordini nello shop autorizzato | usa la superficie operativa autorizzata | controlla visibilità e transizioni |
| Pubblicazione, configurazione commerciale e policy | nessun accesso | nessun accesso | opera tramite Admin Console entro capability esplicite | applica regole e audit |
| Inventory operativo, costi, processi interni e vendita fiscale | nessun accesso | nessun accesso | soltanto nei sistemi operativi autorizzati | non li espone come risorse Storefront pubbliche |

Una capability guest aggiuntiva, anche se apparentemente innocua, **MUST** essere
introdotta come estensione versionata, protetta server-side e assegnata a un task.
L'esistenza di un'operazione fisica raggiungibile **MUST NOT** essere considerata prova
che la capability sia autorizzata.

Le capability guest e customer **MUST** essere dichiarate e concesse separatamente:
l'autenticazione **MUST NOT** essere interpretata come ereditarietà implicita delle
capability guest.

## Catalogo pubblico guest

Il catalogo pubblico è una capability minima di Storefront e **MUST** restare separato
da identità e dati cliente.

### Allowlist pubblicabile

Quando pubblicati e validi per lo shop, il guest **MAY** ricevere soltanto:

- presentazione pubblica del negozio;
- tassonomia, contenuto e attributi customer-facing dei prodotti pubblicati;
- prezzo cliente corrente, promozione applicabile e relative condizioni pubbliche;
- disponibilità commerciale qualitativa;
- opzioni e condizioni di fulfillment rese pubbliche dal negozio;
- media e riferimenti media esplicitamente pubblicati.

La lista descrive categorie logiche, non campi di un payload. Il server **MUST** filtrare
pubblicazione, validità e `shop_id` prima di rendere leggibile una risorsa.

### Denylist

Il client pubblico **MUST NOT** ricevere né interrogare:

- tabelle, record o quantità grezze dell'inventory operativa;
- costi di acquisto, margini, fornitori, note o workflow interni;
- regole commerciali interne non destinate alla presentazione cliente;
- draft, metadata di sincronizzazione, tombstone operativi, sessioni o dati device
  interni;
- API di management immagini, sorgenti private, percorsi di storage amministrativi o
  URL firmati destinati a superfici interne;
- chiavi privilegiate, claim amministrativi o metadata usati come scorciatoia
  autorizzativa;
- risorse di un altro shop, dati privati di altri clienti o registri della vendita
  fiscale POS.

Un dato non presente nell'allowlist **MUST** restare non pubblico anche se una
configurazione legacy, un grant o una superficie tecnica lo rendesse accidentalmente
raggiungibile.

### Comportamento guest

- La consultazione pubblica **MUST NOT** richiedere account, sessione fittizia o login
  preventivo.
- L'assenza di identità cliente **MUST NOT** ampliare l'accesso oltre l'allowlist
  pubblica.
- Una risorsa non pubblicata, ritirata o fuori validità **MUST NOT** essere recuperata
  dall'inventory o da uno shop alternativo.
- La cache guest di TASK-017 **MAY** contenere soltanto dati pubblici shop-scoped e
  **MUST** dichiararne la freschezza. La preferenza favorite di TASK-018 conserva solo
  shop/publication/timestamp: non rende autoritativo il prodotto cached e un orphan
  resta unavailable.
- Ricerca, paginazione, ordinamento, payload ed error code restano di TASK-010.

## Commercial truth

1. Pubblicazione, prezzo, promozione, disponibilità commerciale, costi accessori e
   fulfillment sono server-authoritative.
2. Il client **MUST** mostrare soltanto valori Storefront pubblicati o una cache
   esplicitamente marcata come non corrente. **MUST NOT** inventare, ricostruire,
   correggere o completare un valore commerciale mancante.
3. Il client **MUST NOT** derivare disponibilità pubblica da quantità operative né
   presentarla come promessa di stock. La disponibilità pubblica è una proiezione
   qualitativa, non l'inventory.
4. Una promozione scaduta, incoerente o non verificabile **MUST NOT** essere applicata
   localmente. Il client può mostrare soltanto il prezzo autorevole disponibile oppure
   uno stato non acquistabile/da aggiornare.
5. Prima di hold, ordine o pagamento, il server **MUST** rivalidare tutte le condizioni
   commerciali pertinenti. Una selezione locale o una risposta precedente **MUST NOT**
   vincolare il server.
6. Quando prezzo, disponibilità, costo o fulfillment cambiano, il client **MUST**
   presentare il cambiamento e richiedere una nuova conferma ove l'azione commerciale
   prosegua. **MUST NOT** creare successo, addebito o ordine implicito.
7. Una cache **MAY** sostenere la sola consultazione, ma **MUST NOT** essere usata come
   commercial truth per un'azione irreversibile.
8. Ogni mutazione futura **MUST** essere autorizzata, validata, idempotente e
   auditabile server-side. Il client può esprimere un intento; **MUST NOT** attestare
   autonomamente l'esito.

## Immagini pubbliche

- Una sorgente media amministrativa e la sua rappresentazione Storefront pubblicata
  **MUST** restare separata.
- Il client **MUST** usare soltanto riferimenti o rendition esplicitamente pubblici e
  shop-scoped.
- Il client **MUST NOT** chiamare management API, enumerare storage amministrativo o
  ricevere credenziali e URL firmati destinati a workflow interni.
- La rimozione o mancata disponibilità di un'immagine **MUST NOT** rendere autorevole
  una copia privata o impedire la presentazione testuale essenziale.

Pipeline, storage policy, trasformazioni, invalidazione e formato dei riferimenti
appartengono a TASK-009/TASK-010.

## Ordine cliente e vendita fiscale

Ordine cliente e vendita fiscale sono entità ed eventi distinti. Una correlazione futura
non li rende intercambiabili.

| Aspetto | Ordine cliente | Vendita fiscale |
|---|---|---|
| Business owner | Storefront/Admin | Win7POS |
| Origine autorevole | accettazione server-side di un intento cliente rivalidato | workflow fiscale/operativo POS autorizzato |
| Visibilità client | customer-facing e limitata al proprietario/shop | non è una risorsa pubblica del client |
| Identità e lifecycle | propri, definiti da TASK-027/TASK-028 | propri, definiti dal dominio POS |
| Effetto implicito | non prova emissione fiscale, pagamento o movimento stock definitivo | non riscrive implicitamente la storia dell'ordine |
| Collegamento | handoff esplicito, idempotente e auditabile | ricezione ed esito operativo riconciliati |

- Un intento cliente **MUST NOT** diventare ordine prima della conferma autorevole del
  server.
- Un ordine accettato **MUST NOT** essere presentato come vendita fiscale, pagamento
  riuscito o stock definitivamente movimentato.
- Soltanto il dominio POS autorizzato **MAY** originare la vendita fiscale.
- L'handoff **MUST** conservare identità, stato ed eventi separati e **MUST** rendere
  riconciliabile ogni esito ambiguo.
- Retry, timeout o reconnect **MUST NOT** duplicare ordine, vendita, hold, rilascio stock
  o pagamento.
- Il client **MUST NOT** dedurre uno stato POS da un proprio stato locale o da una
  transizione dell'ordine.

Stati, identificatori di correlazione, protocollo di handoff e regole di compensazione
restano di TASK-027–TASK-030.

## Failure policy e fallback

Storefront fallisce in modo chiuso. Un failure **MUST NOT** ampliare accessi, cambiare
ambiente/shop o trasformare un dato non verificato in commercial truth.

| Classe logica | Comportamento richiesto | Fallback vietato |
|---|---|---|
| Configurazione o ambiente invalido | bloccare la connessione commerciale e rendere lo stato esplicito | backend casuale, ambiente differente, URL o chiave hardcoded |
| `shop_id` assente, invalido o non autorizzato | rifiutare l'operazione senza selezione implicita | primo/ultimo shop, shop di cache o shop di un'altra sessione |
| Identità assente o sessione scaduta | mantenere disponibile il solo catalogo guest e negare capability customer | email, route, stato UI o metadata come prova di identità |
| Capability vietata o cross-shop | negare server-side senza esporre dati ulteriori | query diretta, grant legacy o risorsa operativa |
| Risorsa assente, ritirata o non pubblicata | mostrare uno stato assente/non disponibile recuperabile | copia operativa, draft, altro shop o dato inventato |
| Cache stale o commercial truth cambiata | dichiarare la non attualità, aggiornare e rivalidare prima della conferma | accettazione silenziosa del valore precedente |
| Offline, timeout o server indisponibile | preservare input e contesto; consentire retry sicuro o sola lettura cache marcata | finto successo, dati demo production o accesso inventory |
| Esito di mutazione ambiguo | riconciliare usando la stessa identità idempotente prima di ogni nuova azione | retry cieco, nuova identità di richiesta o duplicazione dell'intento |
| Errore interno | negare l'azione sensibile e fornire recovery non ingannevole | successo locale o autorizzazione permissiva |

I messaggi **SHOULD** spiegare cosa è stato conservato e quale azione sicura è
disponibile, senza rivelare dettagli sensibili. Quando distinguere “vietato” da
“inesistente” esporrebbe l'esistenza di una risorsa, il server **MUST** privilegiare la
non divulgazione.

### Ordine dei fallback di lettura

Per contenuto pubblico e non sensibile, il client **MAY** usare soltanto:

1. risposta Storefront corrente e validata;
2. cache dello stesso `shop_id`, marcata con freschezza e usata in sola lettura;
3. stato vuoto/offline con retry esplicito.

Il client **MUST NOT** usare come fallback inventory operativa, tabelle legacy,
repository Android/iOS/POS, un altro ambiente, un altro shop, fixture in produzione,
dati privati di una sessione precedente o calcoli locali di prezzo/disponibilità.

I codici di errore, la retry policy di trasporto e i dettagli di health/readiness sono
definiti rispettivamente da TASK-010, TASK-011 e TASK-034.

## Compatibilità e versionamento

La versione del contratto segue `MAJOR.MINOR.PATCH`. Ogni implementazione e ogni
evidence di conformità **MUST** dichiarare la versione logica supportata; il meccanismo
fisico di negoziazione resta di TASK-010.

### Patch

Un incremento `PATCH` **MAY** correggere refusi, riferimenti o formulazioni senza
cambiare significato osservabile, capability, requisito o failure policy. Una modifica
semanticamente rilevante **MUST NOT** essere classificata come patch.

### Cambio additive

Un cambio è additive soltanto se:

- aggiunge una risorsa, capability o semantica logica opzionale;
- non cambia il significato né i pre-requisiti di quanto già conforme;
- resta shop-scoped e default-deny;
- può essere ignorato in sicurezza dai consumer precedenti;
- non amplia implicitamente l'accesso di guest, customer o staff.

Un cambio additive **MUST** incrementare `MINOR`. “Additive” **MUST NOT** significare
“automaticamente autorizzato”: task, enforcement e test restano obbligatori.

### Breaking change

È breaking qualunque modifica che:

- rimuove, rinomina o cambia il significato di una risorsa/capability esistente;
- introduce un nuovo requisito obbligatorio per un consumer già conforme;
- cambia tipo o semantica di `shop_id`, shop scope o isolamento cross-shop;
- modifica attori, autorizzazione, trust boundary o allowlist/denylist;
- indebolisce o cambia commercial truth, rivalidazione, failure o fallback;
- fonde ordine cliente, vendita fiscale, pagamento o movimento stock;
- rende non più sicuro ignorare un'estensione.

Un breaking change **MUST** incrementare `MAJOR`, avere un task esplicito, analisi
d'impatto e migration window. Nessun consumer **MUST** dipendere da comportamento
breaking non versionato.

### Deprecation e migration window

La sequenza ammessa è `ACTIVE -> DEPRECATED -> REMOVED`.

Una deprecation **MUST** dichiarare:

- versione di introduzione e versione di deprecazione;
- risorsa/capability e attori impattati;
- sostituzione conforme e owner della migrazione;
- condizione iniziale e finale della migration window;
- prima versione nella quale la rimozione può avvenire;
- evidence che server e consumer supportino la transizione.

La durata della migration window **MUST** essere esplicita e approvata nel task che
introduce il cambio; **MUST NOT** essere inventata o inferita da questo documento.
Per una deprecation ordinaria la finestra **MUST NOT** essere zero e **MUST** includere
almeno una versione distribuita che segnali la deprecation. Durante la finestra, la
compatibilità **MUST** essere verificata con contract test e **MUST NOT** mantenere un
accesso insicuro.

La rimozione è breaking e **MUST** avvenire soltanto dopo migrazione dei consumer
supportati ed evidence di conformità. Una correzione urgente di sicurezza **MAY**
chiudere immediatamente un accesso non autorizzato: la sicurezza fail-closed prevale
sulla compatibilità vulnerabile, ma il cambio e l'impatto **MUST** essere registrati.

### Protocollo di cambio

Ogni cambio al contratto **MUST**:

1. avere un task autorizzato e un change owner;
2. identificare risorse, capability, attori, shop scope e consumer impattati;
3. essere classificato come patch, additive o breaking;
4. aggiornare versione, mapping dei task e, quando cambia ownership o trust boundary,
   una ADR;
5. essere implementato nei layer proprietari senza modifiche cross-repo implicite;
6. avere evidence e contract test adeguati prima della rimozione di una semantica
   precedente.

## Mapping ai task

Questa tabella assegna responsabilità di raffinamento e verifica; non modifica scope,
stato o dipendenze del Master Plan.

| Task | Responsabilità rispetto al contratto |
|---|---|
| TASK-003 | baseline logica, ownership, attori, shop scope, trust e change protocol |
| TASK-004 | environment strategy, callback e configurazione fail-closed, senza fallback cross-environment |
| TASK-005 | schema fisico, migration ownership, grant, RLS e operazioni server-side conformi |
| TASK-006 | proiezione Storefront dal dominio operativo senza accesso runtime diretto del client |
| TASK-007 | pubblicazione e visibilità shop-scoped |
| TASK-008 | prezzo cliente, promozioni, validità e commercial truth |
| TASK-009 | sorgenti, rendition, pubblicazione e invalidazione delle immagini |
| TASK-010 | query/API fisica, discovery e binding di `shop_id` con validazione server-side, search, pagination, error contract, fixture, version negotiation e contract test |
| TASK-011 | connessione staging, health/readiness e failure di trasporto |
| TASK-012–TASK-019 | presentazione pubblica, discovery, cache/freshness e performance del catalogo |
| TASK-020 | identità, session lifecycle e deep link senza scorciatoie autorizzative |
| TASK-021–TASK-022 | risorse cliente private, privacy, consensi e device lifecycle |
| TASK-023 | carrello persistente e rivalidazione prezzo |
| TASK-024 | proiezione di disponibilità pubblica distinta dallo stock operativo |
| TASK-025 | hold atomico, scadenza e concorrenza |
| TASK-026 | fulfillment configurato e rivalidato |
| TASK-027 | ordine idempotente e price snapshot autorevole |
| TASK-028 | ownership, storico e stato dell'ordine cliente |
| TASK-029 | capability staff per gestione e preparazione ordine |
| TASK-030 | handoff POS, rilascio reservation e confine della vendita fiscale |
| TASK-031 | eventi e notifiche di stato autorevoli |
| TASK-032 | decisione provider, pagamento e riconciliazione degli esiti |
| TASK-033 | threat model e verifica di RLS, grant, rate limit e trust boundary |
| TASK-034 | test offline, reconnect, concorrenza e idempotenza |
| TASK-035 | osservabilità e analytics privacy-safe senza dati o secret non ammessi |
| TASK-036–TASK-042 | acceptance, release e operatività senza indebolire il contratto |

## Elementi deliberatamente non definiti

Questa baseline **MUST NOT** essere usata come specifica fisica per:

- nomi o struttura di schema, tabelle, view, indici, policy, grant o migrations;
- endpoint, path, metodi, RPC, Edge Functions, canali realtime o Storage;
- campi, payload, DTO, enum di stato o codici di errore;
- URL, project ref, chiavi, ambienti o dati commerciali reali;
- provider Auth, token, claim affidabili, persistenza della sessione o deep link;
- formule prezzo, soglie stock, lifecycle dettagliato di hold/ordine/vendita o provider
  di pagamento;
- tempi di cache, retry, deprecation o supporto release non ancora decisi.

Questi elementi appartengono ai task mappati e **MUST** essere specificati senza
contraddire gli invarianti di questo contratto.

## Checklist minima di conformità

Un'implementazione può dichiararsi conforme a `CMC-STOREFRONT-LOGICAL 1.0.0` soltanto
se esiste evidence che:

- ogni risorsa e capability sia legata a un `shop_id` UUID validato server-side;
- il catalogo pubblicato sia leggibile da guest senza esporre identità o dati cliente;
- allowlist, denylist e separazione guest/customer/staff/server siano applicate;
- commercial truth e mutazioni sensibili restino server-authoritative;
- il client non acceda direttamente a inventory, superfici operative o credenziali
  privilegiate;
- grant e RLS siano entrambi espliciti sulle superfici Storefront esposte;
- ordine cliente e vendita fiscale restino distinti e riconciliabili;
- errori, cache, retry e fallback falliscano in modo chiuso;
- la versione e ogni deprecation/additive/breaking change siano tracciati;
- i test del layer proprietario verifichino comportamento nominale, denial e failure.
