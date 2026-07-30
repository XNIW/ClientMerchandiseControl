# Brand foundation

## Stato

L'audit cross-repo di TASK-002 non ha trovato un nome pubblico, legal entity, logo,
wordmark, icona store, palette marketing, tagline o font ufficiali. La foundation è
quindi intenzionalmente `PROVISIONAL / UNVERIFIED`.

## Tassonomia vincolante

| Concetto | Valore corrente | Stato | Uso |
|---|---|---|---|
| Project name | `ClientMerchandiseControl` | tecnico | repository e documentazione |
| Dart package | `client_merchandise_control` | tecnico | import e tooling |
| Technical display name | `Client Merchandise Control` | tecnico/provvisorio | fallback centralizzato |
| Public brand name | assente | non verificato | non usare finché approvato |
| Store display name | futuro dato shop-scoped | non definito | contenuto Storefront, non brand globale |
| Legal entity | assente | non verificata | TASK-038 |
| Tagline | assente | non verificata | TASK-038 |
| Logo/wordmark | assente | non verificato | TASK-038 |
| App/store icon | placeholder tecnico | non definitivo | TASK-038 |
| Palette | seed teal `#245C55` | provvisoria | generazione `ColorScheme` |
| Font | font di sistema | approccio foundation | light/dark e scaling nativo |

Il resolver del nome pubblico usa il nome verificato solo quando esiste; altrimenti
restituisce il technical display name. Un valore runtime `shop_name` non viene promosso
automaticamente a brand.

## Provenienza

Le fonti, gli SHA e i conflitti sono registrati in
`docs/TASKS/EVIDENCE/TASK-002/product-and-brand-audit.md`. I nomi operativi Android/iOS,
Admin e POS e le rispettive palette non sono prove di una decisione commerciale.

## Principi di espressione

- semplice, affidabile, rispettoso e non promozionale senza evidenza;
- gerarchia chiara e spazio sufficiente prima della decorazione;
- informazioni commerciali esplicite, senza urgenza artificiale;
- sistema adattabile a un futuro brand senza riscrivere feature;
- nessun asset o nome “temporaneo” presentato come ufficiale.

## Tono di voce

- frasi brevi, dirette e orientate al compito;
- termini comprensibili al cliente, non al team di sviluppo;
- errori onesti: evento, contenuto conservato, prossimo passo;
- conferme concrete: esito e cosa accade ora;
- nessun superlativo, promessa, slang o falsa familiarità.

## Governance

TASK-038 potrà sostituire nome, legal, palette e asset solo con fonte autorevole e
approvazione esplicita. I cambiamenti dovranno aggiornare registry, asset, localizzazioni,
metadata nativi, test, privacy/legal e store listing senza modificare package o bundle
identifier implicitamente.
