# TASK-023 — Carrello persistente e price revalidation

## Informazioni generali

- **Task ID**: TASK-023
- **Titolo**: Carrello persistente e price revalidation
- **File task**: `docs/TASKS/TASK-023-persistent-cart-price-revalidation.md`
- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Fase**: EXECUTION
- **Responsabile**: CODEX_EXECUTOR
- **Data creazione**: 2026-08-02
- **Ultimo aggiornamento**: 2026-08-02
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-023/`
- **Handoff**: CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW

## Dipendenze

- **Dipende da**: TASK-012, TASK-016, TASK-017
- **Checkpoint consumati**: shell/design system; product publication/detail pubblico;
  cache Drift/offline; Auth TASK-020 disponibile per il merge owner
- **Sblocca**: TASK-025, TASK-026, TASK-027, TASK-034
- **Repository writer**: Admin/Supabase per schema/RPC, poi Client Flutter; un solo
  writer alla volta

## Scope

- sostituire il placeholder Cart con dominio, repository, controller e UI reali;
- offrire un carrello guest locale, shop-scoped, persistente, bounded, utilizzabile
  offline e ripristinato dopo restart/app kill;
- supportare add da Product Detail e Favorites, incremento/decremento quantità,
  rimozione, clear e stato empty/unavailable senza bloccare il browsing guest;
- memorizzare localmente soltanto publication ID pubblico, quantità e snapshot pubblico
  minimo; prezzo, promo, totale e stock locali restano indicativi;
- creare carrello owner-scoped autenticato e item con FORCE RLS, versionamento
  ottimistico, mutation idempotency e owner derivato da `auth.uid()`;
- implementare merge guest/account deterministico per `(shop_id, publication_id)`:
  quantità massima tra le due copie, bounded dal limite commerciale; il guest locale
  viene rimosso soltanto dopo conferma server;
- aggiungere RPC server-side di read/mutate/merge/revalidate che rileggono la
  pubblicazione corrente e restituiscono linee accepted/adjusted/unavailable, prezzo
  pubblico corrente, promo e quote/totale server con versione e scadenza;
- gestire login/logout/account switch, conflitto versione, request duplicata, timeout
  ambiguo, retry, prodotto unpublished, prezzo cambiato, promo scaduta e offline;
- realizzare UI moderna con righe prodotto, thumbnail, quantità, remove, risparmio,
  unavailable state, subtotal/quote non autorevole, CTA sticky e restore;
- localizzare es-CL/it/en/zh-Hans con CLP corretto, dark, text scale 200%, Semantics e
  target di almeno 48 logical pixel;
- produrre migration replay, pgTAP/RLS/concurrency, unit/widget/integration, smoke
  Android/iOS e staging headless, mantenendo production invariata.

## Non incluso

- proiezione di stock commerciale e relative policy, di competenza TASK-024;
- reservation hold, di competenza TASK-025;
- indirizzo, zone, slot, fee e fulfillment checkout, di competenza TASK-026;
- creazione ordine o prezzo finale autorevole, di competenza TASK-027;
- coupon manuali, gift card, wishlist remota o inventory quantity interna;
- accesso client diretto all'inventory operativo, service role o totale client
  autorevole;
- modifica production o dipendenza da GUI/interazione manuale.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Guest cart è shop-scoped, persistente, bounded e ripristinabile offline/restart | UNIT/INTEGRATION |
| CA-02 | Add/update/remove/clear sono deterministici, single-flight e non duplicano item | UNIT/WIDGET |
| CA-03 | Product Detail e Favorites aggiungono publication pubbliche senza ID inventory interni | WIDGET/SECURITY |
| CA-04 | Cart autenticato usa owner UUID, FORCE RLS e nega anon/cross-user | PGTAP |
| CA-05 | Merge guest/account è idempotente, non perde il guest su failure e applica la policy quantità massima bounded | PGTAP/INTEGRATION |
| CA-06 | Versione ottimistica rileva conflitti e retry/idempotency non applicano due volte una mutation | PGTAP/CONCURRENCY |
| CA-07 | Revalidation rilegge prezzo/promo/pubblicazione server-side e ignora prezzo/totale malevoli client | PGTAP/SECURITY |
| CA-08 | Price changed, promo expired e unpublished producono adjusted/unavailable espliciti | UNIT/INTEGRATION |
| CA-09 | Offline/timeout ambiguo preservano intent e non mostrano quote server non confermate | UNIT/WIDGET |
| CA-10 | UI Cart moderna gestisce linee, quantità, remove, subtotal indicativo, restore, empty e CTA sticky | WIDGET/INTEGRATION |
| CA-11 | Quattro locale/fallback, CLP, dark, 200%, compact/tablet/landscape e Semantics sono conformi | WIDGET/A11Y |
| CA-12 | Cache/migrazione sono bounded, fail-closed e non conservano PII/token/secret | UNIT/SECURITY |
| CA-13 | Gate Client/Admin/Supabase, staging e smoke headless passano sul revision set | CI/BUILD/SMOKE |
| CA-14 | Production resta invariata e nessun secret/config/artifact è versionato | SECURITY/GIT |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-02 | UNIT | add/update/remove/clear, duplicate tap, limiti item/quantity, restart e shop isolation |
| T-02 | CA-03 | WIDGET/STATIC | CTA Detail/Favorites usa publication ID pubblico e payload allow-listed |
| T-03 | CA-04 | PGTAP | owner success; anon/cross-user read/write/merge denial |
| T-04 | CA-05 | PGTAP/INTEGRATION | merge empty/overlap/retry/offline con max bounded e cleanup guest solo dopo ack |
| T-05 | CA-06 | PGTAP/CONCURRENCY | due writer su stessa versione; conflict esplicito e retry stessa key idempotente |
| T-06 | CA-07, CA-08 | PGTAP | prezzo/totale/sconto malevoli ignorati; price changed/promo expired/unpublished |
| T-07 | CA-09 | UNIT/WIDGET | offline, timeout ambiguo, resume e retry senza falso totale o perdita intent |
| T-08 | CA-10 | WIDGET | righe, quantità, rimozione, unavailable, subtotal, sticky CTA, empty/restore |
| T-09 | CA-11 | WIDGET/A11Y | locale/theme/200%/viewport matrix, CLP, Semantics, focus e target 48 |
| T-10 | CA-12 | UNIT/SECURITY | migration cache, corruzione/recovery, eviction e scan PII/token/internal ID |
| T-11 | CA-13 | ANDROID_EMU/IOS_SIM | guest restart, login merge, revalidation e account switch headless |
| T-12 | CA-13, CA-14 | CI/GIT | gate completi, staging exact SHA, secret scan e production unchanged |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Il client conserva una richiesta di quantità e snapshot pubblico; server price/quote è sempre autorevole | Evita manipolazione e prezzi obsoleti trasformati in ordine | ATTIVA |
| D-02 | La chiave linea è `(shop_id, publication_id)` e non un ID inventory/source | Mantiene il confine Storefront pubblico e l'isolamento negozio | ATTIVA |
| D-03 | Il merge overlap sceglie `max(guest, account)` entro il cap, non la somma | Evita duplicazione involontaria al login mantenendo l'intento più forte | ATTIVA |
| D-04 | Il guest cart viene cancellato solo dopo ack server idempotente | Un timeout ambiguo non deve perdere il carrello locale | ATTIVA |
| D-05 | Cart version + idempotency key governano le mutazioni autenticate | Rende conflitti e retry espliciti senza doppia applicazione | ATTIVA |
| D-06 | Availability precisa/hold/checkout restano TASK-024/025/026 | Evita scope creep e accesso all'inventory operativo | ATTIVA |
| D-07 | Planning ed Execution sono autorizzati dal prompt USER_APPROVER del 2026-08-02 | Mantiene il release train headless continuo | ATTIVA |

## Planning — `CODEX_PLANNER`

### Obiettivo

Fornire un carrello guest e autenticato resiliente, con merge idempotente e
revalidation server-side, pronto per availability, hold e checkout senza rendere il
client fonte di prezzo, stock o autorizzazione.

### Analisi

- il Cart corrente è soltanto un empty placeholder e non possiede domain/data layer;
- Product Detail e Favorites espongono publication pubbliche e sono i punti di add;
- Drift già fornisce una cache locale versionata ma non contiene schema cart;
- Auth/session owner e account switch sono disponibili dai checkpoint TASK-020/021;
- la proiezione Storefront espone prezzi/promozioni pubblici, mentre stock preciso e
  reservation non vanno anticipati;
- timeout e login merge richiedono ack idempotente prima di eliminare lo stato guest.

### Approccio autorizzato

1. audit read-only di Cart placeholder, Detail/Favorites, cache Drift, Auth identity e
   contratti prezzo/RLS esistenti;
2. migration additiva per cart/item/mutation ledger, FORCE RLS e RPC strict di
   read/mutate/merge/revalidate;
3. pgTAP owner/cross-user, mutation retry, version conflict, merge e malicious price;
4. apply guarded e staging smoke sintetico con cleanup;
5. domain/store/repository/controller Flutter, cache migration e owner transition;
6. CTA Detail/Favorites e UI Cart moderna responsive/accessibile/localizzata;
7. unit/widget/integration, restart/offline/account-switch Android/iOS, gate completi;
8. evidence/checkpoint e attivazione TASK-024 soltanto con checkpoint tecnico verde.

### Rischi e mitigazioni

- totale manipolato: RPC ignora importi client e rilegge la proiezione pubblica;
- duplicazione merge: idempotency ledger e policy `max` deterministica;
- update perso: optimistic version conflict e reload/retry espliciti;
- perdita guest su timeout: cleanup locale solo dopo ack server verificato;
- cache senza limiti: cap item/quantity, schema versionato e recovery testata;
- cross-shop/cross-user: composite key shop/publication, FORCE RLS e negative pgTAP;
- scope creep stock/checkout: stato unavailable deriva solo dal contratto pubblico
  corrente; nessun hold o ordine in TASK-023.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo ruolo**: CODEX_EXECUTOR
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION
- **Autorizzazione USER_APPROVER**: prompt headless Storefront v1 2026-08-02

## Execution — `CODEX_EXECUTOR`

Execution completata sul revision set Client
`e8d71d38ea87ab61693ecec80614c11d676e47f5` e Admin/Supabase
`80556a90bba87712e4f42530b9e500b9d2d485ef`.

- aggiunte le migration additive `20260802210000` e `20260802213000` con cart, item,
  mutation ledger, FORCE RLS e quattro RPC pubbliche slug-based; il motore UUID resta
  privato e non eseguibile dai ruoli mobile;
- implementato guest cart Drift v3 shop-scoped, bounded e persistente, senza PII o ID
  inventory, preservato da refresh/invalidation catalogo;
- implementati repository/controller autenticati con merge `max` bounded, cleanup
  guest solo dopo ack, cart version, idempotency e retry di timeout/conflitto;
- sostituito il placeholder Cart con righe, thumbnail, quantità, remove/clear,
  subtotal indicativo, stati adjusted/unavailable, CTA sticky e add da Detail/Favorites;
- completate localizzazioni es-CL/it/en/zh-Hans, CLP, dark, text scale 200%, viewport
  compact/landscape/tablet, Semantics e target 48;
- corretta la regressione iniziale dello shell eliminando lo Scaffold annidato; il test
  device ha inoltre reso esplicito che le asserzioni del fake vanno verificate fuori
  dall'adapter, per non essere mappate come failure remota applicativa.

I gate dettagliati e le matrici sono in
`docs/TASKS/EVIDENCE/TASK-023/README.md`. La CI Client exact-SHA
`30770239675` è `BLOCKED` esterna: i tre job hanno zero step perché GitHub rifiuta
l'avvio per billing/spending limit; non è un failure di codice. Production non è stata
invocata.

## Checkpoint release train — `CODEX_EXECUTOR`

### Gate pertinenti eseguiti

- Admin/Supabase: replay 28 migration, pgTAP TASK-023 98/98, suite 1.738/1.738,
  concorrenza/idempotenza, foundation/verify/security, CI `30768157319`, Cloudflare
  `30768157310` e staging `30768155279`: `PASS`;
- Client: pub get/l10n/format/analyze, 429 test complessivi, coverage 79,55%, security
  481 file, governance/architecture, Android debug/release e iOS debug/release compile:
  `PASS`;
- flow cart device-native Android 15 e iOS 26.5: 1/1 per piattaforma, con SQLite reale,
  restart guest, merge login, revalidation e logout isolation: `PASS`;
- smoke artifact: Android cold launch/accessibility tree e iOS launch/screenshot
  headless: `PASS`; CI Client hosted: `BLOCKED` esterna.

### Compatibilità e smoke staging

Le RPC staging accettano soltanto slug pubblico, derivano owner da `auth.uid()`,
ignorano prezzo/totale client e restituiscono quote/linee rivalidate. Le fixture sono
state ripulite. Android Emulator API 35 e iPhone 17 Pro Simulator iOS 26.5 hanno
completato il flow senza GUI o interazione manuale.

### Security scan mirato

Source/index/worktree e bundle Android/iOS non contengono secret privilegiati,
config locali o artifact vietati. Il release APK è stato estratto su volume temporaneo
APFS case-sensitive per preservare tutte le resource Android con nomi case-colliding.

### Stato manifest/checkpoint

TASK-023 è `VALIDATED_PENDING_INTEGRATED_REVIEW`; PR Client #5 e Admin #67 restano
draft; production e flag restano invariati/OFF. Nessuna review formale intermedia è
stata eseguita.

### Handoff al task successivo

- **Stato**: VALIDATED_PENDING_INTEGRATED_REVIEW
- **Review outcome**: NOT_RUN
- **Prossimo task**: TASK-024
- **Handoff**: STOREFRONT_V1_MILESTONE_CHECKPOINT_VALIDATED

## Review / Fix

Riservati alla review integrata finale e all'eventuale ciclo Fix coordinato.

## Chiusura

- **Conferma utente**: ricevuta in forma condizionata dal release train
- **Merge autorizzato**: sì, soltanto dopo review integrata APPROVED
- **Follow-up candidate**: TASK-024 attivato dal checkpoint tecnico
- **Riepilogo finale**: validato tecnicamente, in attesa della review integrata
- **Data completamento**: non ancora
