# TASK-054 — Probe mirato del contrasto, READONLY

**PASS** — 6 test host, exit `0`, 48 rapporti verificati: inbox 30, fulfillment 16, errore indirizzo 2. Ricalcolo Python dei 48 rapporti con canali sRGBA float: exit `0`, delta massimo `0.0`. Nessun finding di contrasto insufficiente nello scope misurato.

Revisione richiesta: `28d74aadee21f98605366e6f12e6477cfdfbc012`. WT host: `682be045934618d3b46be4a0b96f309f93cb1999`. `git diff --name-only HEAD 28d74aadee21f98605366e6f12e6477cfdfbc012 -- lib/` vuoto; albero Git `lib` identico `5ced448f53ed308a39038f3abbc19484e328500f`. Nessuna modifica tracciata o commit generato.

## Metodo e ambito

Widget/controller di produzione, Theme canoniche `AppTheme.light()/dark()`, Material 3, locale `en`, scala testo `1`. Il probe legge colore/stile effettivi del `RenderParagraph` e sfondo dalle superfici render `RenderPhysicalShape`, `RenderPhysicalModel`, `BoxDecoration` e `ColoredBox`, compone gli alpha fino allo sfondo opaco e calcola la luminanza relativa sRGB. La coppia del badge dettaglio usa surface Scaffold; la coppia Card usa surfaceContainer con CardTheme canonico, corrispondenti ai parent di produzione. Il dialogo indirizzo usa lo sfondo render M3 surfaceContainerHigh.

Formula: canale `c <= 0.04045 ? c/12.92 : ((c+0.055)/1.055)^2.4`; `L = 0.2126 R + 0.7152 G + 0.0722 B`; rapporto `(Lmax+0.05)/(Lmin+0.05)`. Il confronto usa i valori float senza arrotondamento. Il testo normale richiede `4.5:1`; testo almeno 24 px o 18.6667 px bold richiede `3:1`. In questa run anche il titolo 22/w400 resta testo normale. [WCAG 2.2, contrasto testo](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html). Le icone informative compact richiedono `3:1`. [WCAG 2.2, contrasto non testuale](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html).

Le famiglie font sotto sono dichiarate nello stile applicato al RenderParagraph; non certificano la risoluzione del font su un OS. Gli hex sono ARGB e solo la rappresentazione quantizzata dei colori: per riprodurre luminanza/alpha usare i canali float `foregroundSrgba`, `foregroundEffectiveSrgba` e `backgroundSrgba` nel JSON, non il solo hex serializzato.

| Superficie/stato | Font / dimensione logica / peso | FG → BG light | Rapporto light | FG → BG dark | Rapporto dark | Soglia |
|---|---|---|---:|---|---:|---:|
| Filtro All selezionato | Roboto 14 / 500 | `#FF324B47` → `#FFCCE8E3` | 7.263343 | `#FFCCE8E3` → `#FF324B47` | 7.263343 | 4.5 |
| Filtri non selezionati | Roboto 14 / 500 | `#FF161D1C` → `#FFF4FBF8` | 16.305631 | `#FFDDE4E1` → `#FF0E1513` | 14.320830 | 4.5 |
| Etichetta unreadOnly | Roboto 16 / 400 | `#FF161D1C` → `#FFF4FBF8` | 16.305631 | `#FFDDE4E1` → `#FF0E1513` | 14.320830 | 4.5 |
| Titolo/message empty parziale, completo, cache | Roboto 22 / 400 e 16 / 400 | `#FF161D1C` → `#FFE9EFED` | 14.702260 | `#FFDDE4E1` → `#FF1A2120` | 12.679375 | 4.5 |
| Banner update failure + Retry, hint e offline | Roboto 14 / 400 e 500 | `#FF001E30` → `#FFCDE5FF` | 13.226712 | `#FFCDE5FF` → `#FF004B70` | 7.252072 | 4.5 |
| Badge testo su surface | Roboto 11 / 500 | `#FF161D1C` → `#FFF4FBF8` | 16.305631 | `#FFDDE4E1` → `#FF0E1513` | 14.320830 | 4.5 |
| Badge testo su Card | Roboto 11 / 500 | `#FF161D1C` → `#FFE9EFED` | 14.702260 | `#FFDDE4E1` → `#FF1A2120` | 12.679375 | 4.5 |
| Badge icone compact | MaterialIcons 15 | `#DD000000` → `#FFE9EFED` | 14.044635 | `#FFFFFFFF` → `#FF1A2120` | 16.376543 | 3.0 |
| Errore editor indirizzo | Roboto 14 / 400 | `#FFBA1A1A` → `#FFE3EAE7` | 5.288183 | `#FFFFB4AB` → `#FF252B2A` | 8.485289 | 4.5 |

Filtri non selezionati: Orders/Payments/Support hanno la stessa coppia misurata. Empty: titolo e message parziale/completo/cache hanno la stessa coppia misurata. Banner: update failure, Retry, hint e offline hanno la stessa coppia misurata. Badge testo: tutti e tre i label pickup/delivery/reservation sono stati letti; compact: entrambe le icone visibili sono state lette. Minimo complessivo testo: errore indirizzo light `5.288182881100233`, maggiore di `4.5`.

**Limiti:** metodo sui colori applicati, senza ispezione/sampling di PNG o antialias. Nessuna build app, device, tastiera OS, VoiceOver/TalkBack o conformità globale WCAG. Non misura stati hover/pressed/disabled/focus, bordi decorativi, icone non compact, span annidati, shader, Opacity, gradienti o sfondi immagine; questi ultimi non sono presenti nei target plain Text/Icon misurati. La run scala1 non prova layout/font al200%. Le fixture sono sintetiche e non provano staging/autenticazione/remoto.

## Riproduzione e identità

```sh
source scripts/resolve-flutter.sh
flutter test --no-pub build/task054/contrast_probe_test.dart --reporter expanded
python3 build/task054/contrast_recalculate.py
```

Flutter `3.44.8`, revisione `058e0af2c2b57e369d905a03ac9748b0ebf543c6`. Probe, JSON e log sono soltanto file ignorati sotto `build/task054/`; nessun source/test permanente. I log di sviluppo `contrast-probe-28d74aa.compile-fail.log` e `contrast-probe-28d74aa.fixture-sequence-fail.log` conservano errori del probe prima della correzione della compilazione/sequenza fixture e non sono finding di prodotto.

| File fonte | Git blob SHA-1 alla revisione richiesta |
|---|---|
| `lib/app/theme/app_theme.dart` | `37460bee3655acb89977919ee727228d38a5e2b8` |
| `lib/app/design_system/theme/storefront_semantic_colors.dart` | `1f1bdaf1ed739c8a935afdee1bc040961aaa42a4` |
| `lib/app/design_system/widgets/storefront_empty_state.dart` | `75902a2e9662cf1616c5e23396495a89b4a1e78b` |
| `lib/app/design_system/widgets/storefront_status_banner.dart` | `c30dbbc7df0729abb313e6f91112eefb2ac05233` |
| `lib/features/customer_notifications/presentation/customer_notification_inbox_screen.dart` | `85f4868161729503baa4ca8a26ed6948da66b26e` |
| `lib/features/storefront/presentation/storefront_product_metadata.dart` | `dc711daf08d41644a8e452b3cc70669ab9111545` |
| `lib/features/account/presentation/customer_account_panel.dart` | `c69db6ecc6cf7ab5b1c582216e78019d2fe92c15` |

| Artifact ignorato | SHA-256 |
|---|---|
| `contrast_probe_test.dart` | `2b688429a346a2832f6907619940e47dca35fa9f251fad95954a66eab4469ac4` |
| `contrast-probe-28d74aa.json` | `b85e18a4d4ad9b96e158cb9c4e03775772d51055be8ccebca244f088d80b39f6` |
| `contrast-probe-28d74aa.log` | `a5c7495523e0d3a9cdc09d8c0cfed267a553d8c6018a4e35c559fed4a6603b83` |
| `contrast_recalculate.py` | `774d559b75f4bdaa44ca412d029bd245f85a2d0ce444e24abb9a93f0498171bb` |
| `contrast-recalculate-28d74aa.log` | `8645dcd66a014172273ae1489cc2bde492c9c8d0c89f96e5fc4bc3f9b6c37254` |
