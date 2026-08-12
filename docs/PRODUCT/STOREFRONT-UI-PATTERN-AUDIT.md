# Storefront v1 — UI pattern audit

## Obiettivo e perimetro

Questo audit bounded orienta il work package `STOREFRONT-V1-UI-HARDENING` senza
replicare il trade dress di altri retailer. Confronta pattern generali già documentati
da fonti ufficiali con le superfici reali Client e Admin al checkpoint del 2 agosto
2026. Non incorpora screenshot, logo, palette, asset, icone o wording proprietari.

La valutazione riguarda:

- Client Flutter: Home, Catalogo, product card, Product Detail, Carrello vuoto e
  Account guest;
- Admin Console: catalogo Storefront, editor pubblicazione, anteprima mobile,
  promozioni, immagini pubbliche e audit;
- gerarchia commerciale, navigazione, resilienza, accessibilità e adattamento dei
  layout;
- direzione di implementazione per TASK-019, con mappatura esplicita dei flussi futuri
  ai task che ne possiedono il contratto.

Carrello pieno, checkout, profilo completo, ordini e order queue non vengono simulati:
sono rispettivamente di competenza di TASK-023, TASK-026, TASK-021, TASK-028 e
TASK-029.

## Metodo ed evidence

L'inventario corrente è stato catturato esclusivamente con strumenti headless e dati
staging/local reali o fixture sintetiche dichiarate:

- Client `af32bd72c139b4dd08ef8e108eb3838ef7d66e99`, Android Emulator
  `1080×2400`, density `420`: sei schermate catturate via `adb`, aperte e ispezionate a
  risoluzione originale;
- Admin `a9036f0bda741d686afbdac13d3d08ef897f059b`, Chromium `1440×900`:
  catalogo, editor, preview, promozioni, immagini e audit catturati durante il test E2E
  locale con cleanup; comando Playwright exit `0`, `1/1` test, durata reale `10,66 s`;
- gli artifact di cattura sono rimasti temporanei fuori repository; nessun contenuto
  di terzi o dato production è stato versionato;
- la baseline CI Client sullo stesso SHA documentale è il run `30751841542`, con
  Quality, Android debug e iOS Simulator debug tutti riusciti.

Il controllo competitivo è stato limitato alle pagine ufficiali elencate sotto e ai
soli pattern funzionali. Non è stata eseguita una copia visuale o pixel-perfect.

## Fonti e pattern generali

| Fonte ufficiale | Pattern generale rilevante | Applicazione originale ammessa |
|---|---|---|
| [Amazon Shopping app](https://www.aboutamazon.com/news/retail/amazon-shopping-app) | Ricerca sempre raggiungibile, ricerca visuale come estensione, stato ordine consultabile a colpo d'occhio | Search prominente e persistente; stato ordine sintetico, senza replicare struttura o linguaggio Amazon |
| [Mercado Libre Chile app](https://www.mercadolibre.cl/l/app) | Offerte distinguibili, notifiche utili e tracking spedizione | Sezione promozioni data-backed e timeline ordine, con identità e copy ClientMerchandiseControl |
| [Falabella — despacho y retiro](https://www.falabella.com/falabella-cl/page/despachoretiro-condiciones) | Opzioni e costi di consegna/ritiro resi visibili prima dell'acquisto | Destinazione e modalità fulfillment chiare prima della conferma, mai implicite |
| [Falabella — estado del pedido](https://www.falabella.com/falabella-cl/page/despachoretiro-preguntas-frecuentes) | Stati progressivi dell'ordine e comunicazione degli avanzamenti | Timeline leggibile, testo più icona, deep link dalla notifica |
| [Shop — customer experience](https://help.shopify.com/en/manual/online-sales-channels/shop/customer-experience) | Discovery per ricerca/categoria/filtri, preferiti, tracking e continuità del carrello | Browsing guest, categorie rapide, filtri bounded e stato locale esplicito |
| [Shop — browsing sul web](https://help.shop.app/en/shop/shopping/shop-on-the-web) | Esplorazione senza autenticazione; account per sincronizzazione e funzioni personali | Catalogo sempre guest; login richiesto soltanto dove porta un beneficio comprensibile |
| [Shop — prodotti salvati](https://help.shop.app/en/shop/shopping/discover/save-products-and-follow-stores) | Salvataggio prodotto come gesto secondario e reversibile | Preferito accessibile su card/detail, con stato e persistenza locali |
| [Shop — order tracking](https://help.shop.app/en/shop/delivery-tracking/track-orders) | Tracking centralizzato e recuperabile | Lista ordini, dettaglio e timeline coerenti, con cache offline read-only |
| [Alibaba catalog](https://www.alibaba.com/catalogs/) | Categorie, filtri, ordinamento e segnali di consegna/protezione come strumenti di scansione | Solo gerarchia generale di ricerca/filtro; nessun pattern B2B, badge o trust claim copiato |

I pattern trasversali utili sono quindi: ricerca prominente, categorie rapide, prezzo
con gerarchia esplicita, navigazione persistente, CTA primaria unica, checkout a step,
tracking progressivo, recupero degli errori, immagini progressive e browsing senza
account. Nessuna fonte autorizza falsa urgenza, scarsità non verificata o totale
calcolato dal client come verità commerciale.

## Baseline Client

### Punti di forza

- Navigazione inferiore persistente, route Home/Catalogo/Preferiti/Account e browsing
  guest sono già coerenti con l'architettura.
- Ricerca, filtri, preferito, share, deep link, loading/error/offline e retry hanno
  callback reali; share e favorite espongono target e Semantics.
- Il formato CLP e i dati pubblici provengono dai contratti Storefront; gli
  identificatori interni non compaiono nella UI osservata.
- Gli stati vuoti spiegano l'esito e propongono una sola azione recuperabile.

### Home

La ricerca è visibile e la navigazione è stabile, ma titolo e copy occupano troppo
spazio rispetto al contenuto commerciale. Un'immagine/placeholder molto alto domina il
primo viewport e lascia deboli la gerarchia di destinazione, categorie, offerte e
prodotti. La Home deve diventare una sequenza data-backed compatta:

1. destinazione o modalità fulfillment, solo quando configurata;
2. ricerca prominente;
3. hero promozionale sobrio, solo con promozione reale;
4. categorie rapide;
5. offerte e prodotti in evidenza con “Vedi tutti”;
6. recentemente visualizzati locali, soltanto se disponibili;
7. skeleton, empty, offline e retry nello stesso layout stabile.

### Catalogo e filtri

Nel primo viewport la superficie filtri è più alta del contenuto utile. I chip di
disponibilità scorrono con l'ultimo valore parzialmente tagliato, manca un conteggio
risultati vicino all'ordinamento e la categoria è isolata in una card pesante. Il
prodotto appare solo al limite inferiore dello schermo.

La direzione è una search sticky, categorie orizzontali leggere, filtri progressivi,
conteggio e ordinamento nello stesso header e griglia adattiva. Il layout wide aumenta
le colonne e può usare `NavigationRail`; il compatto preserva almeno una card completa
o una parte sostanziale del primo risultato senza nascondere i filtri disponibili.

### Product card

La card osservata è leggibile ma sovradimensionata e a bassa densità: immagine molto
alta, ampio spazio vuoto, assenza di preferito, disponibilità/fulfillment, sconto e
gerarchia prezzo corrente/prezzo precedente. L'intera card resta il target primario;
favorite è l'unica azione secondaria indipendente. Nome limitato a tre righe, prezzo
corrente dominante, prezzo precedente e sconto solo quando server-validi, badge
qualitativi bounded e immagine con ratio stabile.

### Product Detail

Nome, categoria, brand, prezzo, share e favorite sono presenti, ma il placeholder
visuale domina e non esistono ancora indicatore gallery, risparmio, modalità
fulfillment, quantità o CTA sticky. Il redesign deve introdurre questi elementi senza
anticipare l'autorità di carrello/checkout: la CTA resta collegata al capability reale,
rispetta `SafeArea` e non appare quando il prodotto è unavailable o non pubblicato.

### Account e Carrello

L'Account guest comunica correttamente che il browsing non richiede login, ma il
pulsante Google osservato era disabilitato e indicava una disponibilità futura: va
verificata la coerenza tra feature flag/runtime e la configurazione OAuth già validata.
Il Carrello mostra un empty state chiaro e una CTA al Catalogo; righe, quantità,
subtotal e restore verranno implementati solo con il contratto di TASK-023.

## Baseline Admin Console

### Punti di forza

- La sezione Storefront è top-level, separata dal catalogo operativo e protetta da
  permission server-side.
- Ricerca, filtri, azioni bulk, status chip, editor di pubblicazione, preview,
  promozioni, immagini versionate e audit sono già collegati a operazioni reali.
- La preview usa `storefront_home_v1`, cioè lo stesso payload pubblico consumato dal
  Client; la pipeline immagini esplicita isolamento e versionamento.

### Problemi osservati

- Catalogo ed editor sono leggibili a `1440×900`, ma l'editor inline trasforma ogni
  riga in un form molto lungo e perde il contesto della lista. Il target è una split
  view list/editor con preview smartphone persistente quando lo spazio lo consente.
- I sette tab Storefront competono sullo stesso livello e dipendono dallo scroll
  orizzontale nei viewport stretti; serve una gerarchia responsive, senza aggiungere un
  nuovo framework.
- La preview è fedele al contratto ma troppo vuota per valutare gerarchia, badge e
  densità; deve mostrare immagine, prezzo/promozione e stato con skeleton/empty/error
  espliciti.
- Il form promozione espone correttamente regola, periodo, timezone e inclusioni, ma
  richiede una gerarchia calendario/stato più scansionabile e validazione inline.
- L'area immagini è chiara ma non presenta una miniatura della sorgente pronta né un
  confronto immediato tra versione corrente e precedente.
- Nell'audit, gli `eventKey` lunghi si sovrappongono visivamente alla colonna Attore;
  timestamp non localizzati e righe dense riducono scansione e accessibilità. La tabella
  deve consentire wrap/break sicuro, formato data localizzato e dettaglio progressivo.
- La lingua selezionata era inglese mentre gran parte della superficie Storefront era
  in italiano: il pass deve distinguere copy volutamente non localizzato da un vero
  drift di localizzazione.

## Direzione visuale originale

Il prodotto mantiene Material 3, font di sistema e seed teal già approvato. La
personalità nasce da superfici calme, alta leggibilità e informazioni commerciali
trasparenti, non da imitazione di palette o componenti altrui.

- griglia spacing da 4 px, con densità maggiore nelle liste e respiro solo tra sezioni;
- radius differenziati per control, card e pill; elevation bassa e riservata a elementi
  che cambiano livello;
- prezzo corrente con ruolo tipografico forte, precedente annunciato semanticamente e
  barrato, risparmio solo se valido;
- colori semantici Storefront per promozione, disponibilità, warning, success e stato
  ordine, sempre accompagnati da testo o icona;
- immagini progressive con aspect ratio stabile e fallback non dominante;
- motion breve e funzionale, azzerata con reduced motion;
- target almeno `48×48`, content max width centralizzato e breakpoints basati sullo
  spazio disponibile.

## Architettura delle superfici

| Superficie | Gerarchia proposta | Stato e resilienza |
|---|---|---|
| Home | destination, search, promo, categorie, offerte, featured, recenti | skeleton per sezione; empty/offline con contenuto cached e retry |
| Catalogo | sticky search, categorie, risultati/sort, filtri, adaptive grid | debounce/cancel; pagination deterministica; refresh senza perdere scroll |
| Product card | immagine, nome, availability, prezzo, promo, fulfillment, favorite | ratio stabile; unavailable esplicito; intera card cliccabile |
| Detail | gallery, nome, prezzo, promo, availability, fulfillment, descrizione, quantity, sticky CTA | non pubblicato/offline/error; CTA fail-closed |
| Carrello | righe, quantità, stato disponibilità, subtotal non autorevole, modalità e CTA | restore; repricing dichiarato; offline mutation queue bounded |
| Checkout | modalità, indirizzo/ritiro, slot, riepilogo, conferma | variazioni prezzo/stock; retry idempotente; errore per step |
| Account | stato guest o identity bounded, preferenze e collegamenti | login non blocca browsing; logout e revoke chiari |
| Ordini | card, stato, totale, data, fulfillment; detail con timeline | cache read-only, retry e deep link notifica |
| Admin Storefront | riepilogo, filtri persistenti, list/bulk, editor+preview, audit | loading/error/empty; keyboard focus; RBAC server-side |

## Accessibilità e visual QA

Il pass di implementazione deve verificare senza GUI manuale:

- viewport `320×568`, `360×800`, `390×844`, `430×932`, `768×1024` e
  `1024×768`, inclusi portrait e landscape;
- text scale `1,0`, `1,3` e `2,0`; light/dark; `es-CL`, `it`, `en`, `zh-Hans` e
  fallback spagnolo;
- nessun overflow, testo critico troncato, CTA fuori viewport o focus invisibile;
- target almeno 48 logical pixel, ordine lettura/focus coerente, heading, label, stato
  selezionato e prezzo/promozione annunciati senza dipendere dal colore;
- contrasto minimo 4,5:1 per testo normale e 3:1 per testo grande o componenti
  essenziali;
- pochi snapshot canonici deterministici, mentre la matrice completa resta
  parametrizzata per evitare repository bloat.

I test automatici e l'accessibility tree sono gate riproducibili; non vengono descritti
come equivalenti a una valutazione con persone o a un test fisico non eseguito.

## Priorità di esecuzione e mappatura

1. **TASK-019** — token/componenti condivisi, Home/Catalogo/Card/Detail e Admin
   Storefront corrente; matrice layout e performance catalogo.
2. **TASK-029** — order queue, order detail e azioni Admin con la stessa gerarchia e
   split view.
3. **TASK-036** — matrice finale accessibility/localization, accessibility tree e
   reduced motion.
4. **TASK-037** — benchmark finale delle superfici e dei flussi commerce.
5. **TASK-038** — coerenza branding, privacy, legal e store metadata senza identità
   inventata.

Le correzioni immediate con più valore sono: ridurre il peso verticale dei filtri
Catalogo, introdurre la card prodotto riusabile e compatta, dare alla Detail una
gerarchia commerciale e una CTA sicura, rendere la Home una composizione di sezioni
reali e correggere il wrapping dell'audit Admin. Il lavoro resta originale, data-backed
e vincolato ai capability effettivamente disponibili.
