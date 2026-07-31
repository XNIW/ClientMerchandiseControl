# ADR-010 — Storefront contract ownership e change protocol

- Stato: ACCETTATA
- Data: 2026-07-30
- Task: TASK-003

## Contesto

Il client Flutter pubblico deve consumare un dominio Storefront separato dalle superfici
operative di inventory, Admin e POS. L'audit TASK-003 osserva che il repository Admin è
l'unico confine server Git-tracciato con migration, RLS, grant, RPC, test database e
pipeline di apply non-production; non contiene ancora un contratto Storefront
machine-readable né Edge Functions Storefront.

Il repository Client contiene invece il contratto logico del prodotto pubblico, i trust
boundary e, nei task futuri, conterrà adapter, cache e test di conformità consumer. Il
workspace Supabase storico, i documenti precedenti, gli artifact locali e lo stato remoto
osservato sono provenance utile, ma non sono una fonte modificabile e revisionabile del
contratto futuro.

Senza un'authority esplicita, schema remoto, documentazione Client e implementazioni
consumer potrebbero divergere. Un apply manuale potrebbe inoltre rendere il ledger
remoto più recente del codice revisionato.

## Decisione

L'ownership è separata per responsabilità:

| Superficie | Authority | Responsabilità |
|---|---|---|
| Business decision owner | ruoli business autorizzati definiti per dominio | decidono pubblicazione, copy, prezzi pubblici, promozioni, disponibilità commerciale e fulfillment secondo policy e task owner |
| Control plane | Admin Console | raccoglie e rende operative le decisioni autorizzate; non decide autonomamente |
| Writer/enforcer | Admin server writer; Supabase runtime/enforcement | applica, persiste e protegge la decisione versionata senza acquisirne business ownership |
| Migration, RLS, grant, view, trigger e RPC | repository Admin | possiede source, review, test database, provenance e apply controllato |
| Edge Functions Storefront future | repository Admin | possiede source, deploy contract, secret server-side e test; l'assenza attuale non ne autorizza l'introduzione in TASK-003 |
| Contratto server machine-readable | repository Admin | possiede versione, schema wire, errori, capability, fixture canoniche, checksum e compatibility metadata |
| Contratto logico del client pubblico | repository Client | possiede trust boundary, capability ammesse/vietate, semantica consumer e invarianti di prodotto |
| Adapter e test consumer | repository Client | possiede DTO/adattamento, parsing fail-closed, cache e conformance test contro una versione server fissata |
| Runtime ed enforcement | Supabase | esegue Auth, Data API, Storage, RLS e funzioni configurate; non decide semantica business o pubblicazione |
| Dati e client operativi | Android operativo, iOS operativo e POS | restano fonti/consumer dei domini assegnati; non sono authority del contratto Storefront pubblico |

Il formato machine-readable concreto sarà scelto nel task che implementa il query
contract. Può essere OpenAPI, JSON Schema o un equivalente verificabile, ma deve vivere
nel repository Admin sotto un path stabile e includere almeno:

- contract ID e versione;
- schema di request, response ed error envelope;
- capability e regole di compatibilità;
- fixture positive e negative sanitizzate;
- checksum o altro identificatore immutabile dell'artifact;
- matrice delle versioni consumer supportate.

Un eventuale mirror nel repository Client è una copia generata o pin-nata per test,
etichettata `NON_AUTHORITATIVE`: non viene modificata manualmente e deve dichiarare
versione, revisione Admin e checksum d'origine.

Il contratto logico Client e quello machine-readable Admin governano livelli diversi.
Nessuno dei due può correggere silenziosamente l'altro. Se wire behavior, allowlist,
trust boundary o semantica commerciale divergono, il cambiamento fallisce chiuso fino
alla riconciliazione revisionata nei due repository.

## Regola repo-first e apply controllato

Ogni modifica a schema, policy, grant, RPC, Edge Function o contratto server:

1. nasce come change revisionabile nel repository Admin;
2. include migration o source server, artifact del contratto, fixture e test pertinenti;
3. verifica separatamente grant Data API e RLS per ogni superficie esposta;
4. non usa service role, secret key o credenziali privilegiate nel Client;
5. viene validata localmente o in un ambiente isolato prima di qualunque apply remoto;
6. viene applicata soltanto dalla revisione Git autorizzata, verso un target allowlisted,
   con dry-run/delta, backup o piano di recupero, post-check e audit;
7. aggiorna i consumer soltanto dopo che versione e compatibilità sono note.

Dashboard SQL, DDL manuale, migration remote-only e deploy da working tree non
revisionato non diventano authority. Se un intervento di emergenza crea drift remoto,
si sospendono apply successivi, si recuperano source e provenance, si confrontano ledger
e checksum e si riconcilia il repository Admin prima di proseguire. Lo stato remoto prova
che qualcosa è stato applicato; non sostituisce la source Git.

TASK-003 non autorizza apply, deploy, link a production o creazione di schema e funzioni.

## Versioning e change protocol

Il contratto server usa una versione esplicita `MAJOR.MINOR.PATCH`:

- `PATCH`: chiarimenti, fixture o correzioni che non cambiano wire shape, autorizzazione
  o semantica osservabile;
- `MINOR`: aggiunta backward-compatible di campi opzionali, capability negoziabili o
  nuovi error code che i consumer conformi possono ignorare o gestire fail-closed;
- `MAJOR`: rimozione o rinomina, cambio di tipo/cardinalità, nuova obbligatorietà,
  modifica incompatibile di semantica, scope, autorizzazione o comportamento degli
  errori.

Ogni change proposal registra owner, motivazione, classe, risorse coinvolte, impatto
auth/security, consumer interessati, fixture, piano di rollout e rollback. Il flusso è:

1. proposta e classificazione nel repository Admin;
2. aggiornamento atomico di artifact, server implementation e test;
3. review obbligatoria del Client owner per cambiamenti Storefront e degli owner
   operativi impattati;
4. conformance test consumer contro versione e checksum esatti;
5. deploy/apply non-production controllato e verifica di compatibilità;
6. finestra di migrazione documentata;
7. promozione o rimozione soltanto dopo evidence dei consumer richiesti.

Una deprecation deve dichiarare `deprecatedSince`, `removalNotBefore`, versioni ancora
supportate e strategia di dual-read, dual-response o adapter quando applicabile. La
finestra non può essere zero: una rimozione avviene solo con release `MAJOR`, dopo almeno
una versione distribuita che segnala la deprecation e dopo la conformità di tutti i
consumer obbligatori. Un consumer non aggiornato mantiene supporto oppure blocca la
rimozione; non viene forzato su una shape incompatibile.

I cambiamenti additivi non possono allargare implicitamente autorizzazioni o dati
pubblici. Un nuovo campo sensibile, un grant aggiuntivo o un cambio guest/customer è
trattato come security change anche quando la wire shape sarebbe tecnicamente additiva.

## Provenance storica

Sono evidence, non authority:

- il workspace Supabase storico non-Git;
- copie locali, bundle, screenshot, export e log;
- documenti o task superati;
- schema, dashboard e ledger remoti osservati;
- implementazioni Android, iOS e POS preesistenti.

Queste fonti possono motivare una proposta o verificare compatibilità. Non possono
originare migration, Edge Function o contract change senza essere trasformate in source
revisionata nel repository owner.

## Conseguenze

- Il Client non accede all'inventory operativo e non possiede commercial truth,
  autorizzazione o schema server.
- L'Admin mantiene nello stesso confine Git contratto eseguibile, enforcement e
  provenance di deployment.
- Supabase resta piattaforma di enforcement e non diventa decision owner.
- Contract drift e remote-only drift diventano blocker espliciti.
- Ogni breaking change ha owner, consumer gate e finestra di migrazione verificabili.
- TASK-005 e TASK-010 possono introdurre rispettivamente schema/enforcement e artifact
  machine-readable senza riaprire la decisione di ownership.

## Alternative considerate

- **Client come owner del contratto server**: scartata perché il client pubblico non
  possiede migration, RLS, funzioni o deploy server.
- **Supabase remoto come source of truth**: scartata perché il runtime non offre review,
  change intent e source completa; un ledger remoto è stato applicato, non un contratto
  governato.
- **Workspace storico come migration authority**: scartata perché non è Git, non prova
  lo stato live e non ha pipeline di conformance.
- **Duplicare manualmente il contratto in ogni repository**: scartata perché crea
  authority concorrenti e drift.
- **Repository contratti dedicato immediato**: rinviata; aggiungere un nuovo writer e una
  pipeline di release non è necessario finché il repository Admin può essere authority
  server e pubblicare artifact versionati.
