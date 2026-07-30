# Content e localizzazione

## Locale supportati

| Locale applicativo | Uso |
|---|---|
| `es` | lingua sorgente, spagnolo cileno-neutrale e fallback |
| `it` | italiano |
| `en` | inglese |
| `zh-Hans` | cinese semplificato |

`es-CL` risolve a `es`. `zh-Hans`, `zh-CN` e `zh-SG` risolvono a `zh-Hans`; `zh`
generico, `zh-Hant`, `zh-TW`, `zh-HK` e `zh-MO` non vengono esposti come cinese
semplificato e passano alla preferenza successiva o a `es`.

`app_zh.arb` è un bundle tecnico richiesto da `gen_l10n`: contiene intenzionalmente la
base spagnola e non è un locale supportato dall'app. Non deve essere tradotto né
aggiunto a `supportedLocales`.

Il `developmentRegion` iOS è allineato a `es`; le localizzazioni native dichiarate
restano `en`, `es`, `it` e `zh-Hans`.

## Regole di scrittura

- Una chiave ARB per messaggio; nessuna concatenazione di frasi.
- Il template spagnolo contiene descrizione e, per i placeholder futuri, tipo ed esempio.
- CTA nel formato verbo + oggetto.
- Niente `backend`, `task`, `contract`, stack trace o codici nel copy cliente.
- La diagnostica debug è separata, localizzata e non contiene URL o credenziali.
- Errori: cosa è successo, cosa è rimasto intatto, come proseguire.
- Conferme: risultato verificato e prossimo passo.
- Evitare colpa, ironia, superlativi, urgenza e formule promozionali non dimostrate.
- Usare ICU plural/select e placeholder nominati per contenuto variabile.

## Glossario

| Concetto | es | it | en | zh-Hans |
|---|---|---|---|---|
| Catalog | catálogo | catalogo | catalog | 商品目录 |
| Cart | carrito | carrello | cart | 购物车 |
| Account | cuenta | account | account | 账户 |
| Favorite | favorito | preferito | favorite | 收藏 |
| Pickup | retiro | ritiro | pickup | 到店取货 |
| Delivery | entrega | consegna | delivery | 配送 |
| Reservation | reserva | prenotazione | reservation | 预留 |
| Order | pedido | ordine | order | 订单 |
| Current price | precio actual | prezzo attuale | current price | 当前价格 |
| Original price | precio original | prezzo originale | original price | 原价 |
| Promotion | promoción | promozione | promotion | 促销 |

Gli stati ordine non vengono definiti qui: lifecycle ed eventi appartengono ai task
TASK-027, TASK-028 e TASK-031.

## Numeri, denaro e tempo

- CLP usa valori interi e formattazione locale; aggiungere `CLP` quando `$` è ambiguo.
- Un valore assente o invalido produce uno stato localizzato, non `0` o `-` come prezzo.
- Date e orari sono localizzati, non ambigui e associati alla timezone del negozio.
- Percentuali o risparmi sono mostrati solo se calcolati da dati server validi.

## Verifica

- parità di chiavi ARB e `flutter gen-l10n`;
- resolver per lista nulla/vuota, ordine preferenze, `es-CL` e varianti cinesi;
- rendering di shell, destinazioni, banner e placeholder nei quattro locale;
- 200% text scale e viewport compatte/landscape;
- revisione umana futura del copy commerciale prima del rilascio.
