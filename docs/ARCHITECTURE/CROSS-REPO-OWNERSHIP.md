# Cross-repo ownership

## Scopo

Questo documento assegna responsabilità univoche ai sistemi dell'ecosistema
Merchandise Control. È normativo per il confine architetturale, non crea schema, API,
migration o accesso runtime. La provenance osservata è registrata in
`docs/TASKS/EVIDENCE/TASK-003/source-audit.md`; l'integrità zero-write delle fonti è in
`docs/TASKS/EVIDENCE/TASK-003/external-integrity.md`.

Nessun repository Android, iOS o POS è una API runtime del client pubblico. Nessuna
tabella operativa esistente diventa Storefront per il solo fatto di essere leggibile con
una key o un ruolo database.

## Vocabolario dei ruoli

| Ruolo | Significato |
|---|---|
| **Domain owner** | Sistema accountable per significato, invarianti e lifecycle del dominio. |
| **Decision owner** | Ruolo che decide la policy di business; non coincide automaticamente con il database che la persiste. |
| **Writer** | Runtime autorizzato a originare o applicare una mutazione nel proprio confine. |
| **Projector** | Componente server-side che traduce dati operativi in una proiezione Storefront pubblicabile. |
| **Consumer** | Sistema che legge un contratto senza acquisirne ownership o capacità di pubblicazione. |
| **Contract owner** | Repository canonico dell'artifact server-facing versionato e dei relativi test di conformità. |
| **Change owner** | Repository/ruolo che apre e coordina il task di cambio, compatibilità, rollout e deprecation. |

Supabase è una piattaforma di persistenza ed enforcement. Non è un `decision owner`:
RLS, grant, trigger o funzioni applicano decisioni definite e versionate altrove.

## Ownership per sistema

| Sistema | Responsabilità e writer autorizzati | Projector / consumer | Contract e change ownership | Non-responsabilità |
|---|---|---|---|---|
| `ClientMerchandiseControl` | UI cliente, auth client, cache cliente, deep link e notifiche client; in futuro possiede carrello locale e presentazione degli ordini. Può scrivere soltanto stato locale e richieste customer-scoped previste dal contratto. | Consumer della futura proiezione Storefront e delle future API customer. Non proietta né pubblica dati commerciali. | Owner del consumer Flutter, dei suoi adapter e test di conformità. Partecipa ai cambi server-facing, ma non li definisce unilateralmente. | Inventory, costo, stock grezzo, pubblicazione, prezzo autoritativo, autorizzazione, migration, fulfillment e vendita fiscale. |
| `merchandise-control-admin-web` | Control plane Master/Admin/POS e server boundary. Possiede pubblicazione prodotti, prezzi pubblici, promozioni, ordine di visualizzazione, gestione ordini e configurazione consegne, oltre all'accesso privilegiato server-only. È il writer canonico di migration, RLS, grant, RPC e futuri componenti server Storefront. | Projector designato dall'operational domain alla futura proiezione Storefront; consumer dei domini operativi e POS necessari al control plane. | Contract owner dei futuri artifact server-facing Storefront e change owner principale per schema/API. Ogni cambio cross-repo richiede task coordinato e prove consumer. | Rendering mobile cliente e stato/cache locale del client. |
| `MerchandiseControlSplitView` | Client Android operativo offline-first. Possiede workflow e dati operativi interni, immagini sorgente, inventory, catalogo interno e prezzi operativi nel perimetro staff/shop autorizzato. | Consumer e writer del contratto inventory operativo. Non è projector Storefront. | Owner del proprio adapter/replica; i cambi al contratto condiviso sono coordinati dall'Admin contract owner. | API pubblica, pubblicazione commerciale, profilo cliente, ordine cliente e vendita fiscale. |
| `iOSMerchandiseControl` | Client iOS operativo offline-first. Possiede workflow e dati operativi interni, immagini sorgente, inventory, catalogo interno e prezzi operativi nel perimetro staff/shop autorizzato. | Consumer e writer del contratto inventory operativo. Non è projector Storefront. | Owner del proprio adapter/replica; i cambi al contratto condiviso sono coordinati dall'Admin contract owner. | API pubblica, pubblicazione commerciale, profilo cliente, ordine cliente e vendita fiscale. |
| `Win7POS` | POS offline-first. Possiede stock operativo, vendita fiscale e scarico stock confermato; origina righe vendita e movimenti stock e, quando integrato, supporta preparazione/ritiro. Mantiene cache catalogo e outbox e scrive online soltanto tramite Admin Web HTTPS. | Consumer del contratto POS catalog pull e producer dei contratti sales/catalog import. Non è projector Storefront. | Owner dell'implementazione POS; Admin possiede il contratto server POS e coordina i cambi con fixture/versioni replicate. | Accesso Supabase diretto, pubblicazione Storefront, prezzo cliente autoritativo e ordine cliente. |
| Supabase canonico non-production | Persistenza condivisa, Auth, Storage, dominio Storefront futuro, ordini, prenotazioni, proiezioni pubbliche, RLS, grant, trigger, RPC e funzioni server-side. Le write privilegiate avvengono tramite componenti server autorizzati. | Ospita future proiezioni, ma non decide cosa sia pubblicabile né il significato commerciale. | Gli artifact sono versionati nel repository Admin; il progetto remoto non è un repository né un change owner. | Business ownership, autorizzazione delegata alla UI, schema inventato dal client o fallback impliciti. |
| `MerchandiseControlSupabase` storico | Provenance genealogica e documentazione Room-first. Non è un writer autorizzato del progetto collegato. | Nessun projector o consumer runtime approvato. | Nessuna contract/change ownership: directory non-Git e non riproducibile a ref. | Migration authority, prova dello stato live, apply remoto o fonte canonica per nuove funzioni. |

## Matrice per dominio

| Dominio | Domain owner | Decision owner | Writer autorizzati | Projector | Consumer | Contract owner | Change owner |
|---|---|---|---|---|---|---|---|
| Esperienza e stato locale cliente | `ClientMerchandiseControl` | Product owner Client | Client Flutter nel solo storage locale e negli intenti ammessi | Nessuno | Cliente | Client | Client |
| Contratto pubblico Storefront | Admin server boundary | Product owner + control plane Admin | Solo implementazioni server autorizzate | Admin server verso proiezione Supabase | Client guest/customer | Admin; questo repository mantiene il contratto logico finché TASK-010 non pubblica l'artifact fisico | Admin, con conformance Client obbligatoria |
| Catalogo inventory operativo | Dominio Merchandise Control, rappresentato online da Admin/Supabase | Shop owner/manager tramite control plane | Admin server, Android/iOS autorizzati; import POS solo via Admin | Futuro pipeline TASK-006 | Admin, Android, iOS e POS | Admin per il contratto condiviso | Admin con coordinamento mobile/POS |
| Visibilità e pubblicazione catalogo | Admin Console | Shop owner/manager autorizzato | Admin server | Admin server | Client Storefront | Admin | Admin |
| Prezzi pubblici e promozioni | Admin Console | Ruolo commerciale autorizzato | Admin server; mai il Client | Admin server, con validazione al momento d'uso | Client come display; checkout come revalidator | Admin | Admin |
| Disponibilità commerciale | Admin server boundary | Policy commerciale/fulfillment Admin | Eventi inventory/POS come input; solo server produce il valore pubblico | Admin server | Client come indicazione rivalidabile | Admin | Admin con coordinamento POS/inventory |
| Immagini prodotto pubblicate | Admin image service e record remoto finalizzato | Ruolo Admin autorizzato | Admin server; Android/iOS usano soltanto management flow autenticato | Futuro image publication pipeline TASK-009 | Client tramite riferimento pubblico approvato | Admin | Admin con fixture consumer |
| Hold e ordine cliente | Futuro dominio ordini server-side | Customer per l'intento; server/Admin per accettazione e policy | Client invia intento; solo server crea stato autoritativo | Server order read model | Client, Admin e futuro handoff POS | Admin | Admin con Client/POS coordinati |
| Vendita fiscale e movimenti POS | `Win7POS` per l'evento locale; ledger server per l'ack globale | Operatore/manager POS secondo policy | Win7POS local transaction/outbox; Admin server applica l'ack | Nessuna proiezione Storefront diretta | Admin/ledger e futuro handoff ordine | Admin per API POS, Win7POS per consumer implementation | Admin + Win7POS |
| Schema, migration, RLS, grant, RPC ed eventuali Edge Functions | Repository Admin come implementation authority | Security/architecture owner Admin | Pipeline/reviewer Admin; mai client mobile | N/A | Runtime Supabase e consumer approvati | Admin | Admin tramite task esplicito |

`Domain owner` non significa “unico nodo che abbia mai scritto il dato”. Android, iOS e
POS possono essere fonti di eventi o mutazioni operative offline; la proiezione pubblica
rimane una responsabilità server-side separata.

## Flussi consentiti

1. Android/iOS autorizzati ↔ inventory operativo tramite contratti staff/shop protetti.
2. Win7POS ↔ Admin Web POS API tramite HTTPS, outbox e idempotenza.
3. Admin server ↔ Supabase tramite client e policy server-side appropriate.
4. Operational domain → projector Admin → proiezione Storefront versionata.
5. Client → proiezione pubblica per read guest; Client autenticato → API customer per
   intenti shop/customer-scoped.
6. Ordine cliente accettato server-side → workflow Admin → handoff POS esplicito,
   senza trasformare l'ordine nella vendita fiscale.

## Flussi vietati

- `ClientMerchandiseControl` → tabelle `inventory_*`,
  `inventory_product_prices`, `shared_sheet_sessions`, `sync_events`,
  `history_entries`, `product_price_summary` o tabelle POS/security/ledger.
- Client → Android, iOS o Win7POS come API, bridge locale o fallback in caso di errore
  Storefront.
- Client → management API `/api/shop/product-images/*`, bucket privato
  `product-images`, upload URL o signed URL operative persistite nel modello pubblico.
- Client → mutation commerciale autoritativa basata soltanto su valore mostrato,
  cache, route, email, `shop_id`, `user_metadata` o stato UI.
- Browser/client → `service_role`, password database, token amministrativi, RPC
  service-only o credenziali POS.
- Android/iOS/POS → scrittura diretta della proiezione pubblica o decisione implicita
  di pubblicazione.
- Win7POS → Supabase diretto.
- Supabase → decisione autonoma di prezzo, promozione, visibilità, disponibilità,
  fulfillment o autorizzazione di business.
- Workspace storico → `db push`, migration copy/apply o dichiarazione di parità live.
- Fallback da un errore Storefront a una tabella operativa “temporaneamente leggibile”.
  Il comportamento richiesto è fail-closed.

Un grant `anon` legacy o una policy permissiva non autorizza uno di questi flussi. Grant,
RLS e contratto applicativo sono controlli distinti e devono essere tutti conformi prima
del collegamento del client.

## Change protocol

1. Il change owner apre un task cross-repo con owner, versione, compatibility window,
   fixture e rollback.
2. L'Admin repository modifica per primo l'artifact server-facing e le prove di
   enforcement. Migrazioni, RLS, grant, RPC ed Edge Functions future vivono
   esclusivamente lì, salvo decisione esplicita per un backend dedicato.
3. I consumer aggiornano adapter e contract test senza duplicare il business contract.
4. Un cambio additivo mantiene sicuri i consumer precedenti; una deprecation dichiara
   una finestra misurabile; un breaking change usa una nuova versione e migrazione
   coordinata.
5. Nessun rollout precede i test di compatibilità dei consumer interessati. Nessuna
   migration storica non-Git viene copiata o applicata senza confronto semantico e task
   Admin dedicato.
6. I cambi al contratto logico richiedono aggiornamento di ADR, matrice ownership,
   artifact canonico e evidence. La piattaforma remota non è usata come luogo di
   editing manuale della decisione.

## Limiti della decisione

TASK-003 assegna ownership e flussi, ma non implementa il read model Storefront. TASK-005
possiede schema/enforcement, TASK-006 la proiezione catalogo, TASK-009 la pipeline
immagini e TASK-010 l'artifact query/fixture machine-readable. Availability, hold,
ordine e handoff POS restano nei rispettivi task futuri.
