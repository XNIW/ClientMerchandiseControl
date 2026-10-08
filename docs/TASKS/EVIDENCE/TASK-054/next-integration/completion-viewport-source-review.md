# Review fix viewport — SOURCE_CODE_ONLY / HARNESS

**APPROVED** sul commit `bf9be0591621f2540a1c10a053e835e6dd0e6b88`, base `9fe418a95defd0a5b595e4c2b5604d5c70ac509f`. Nessun nuovo finding. Reviewer distinto dal writer, checkout congelato `/private/tmp/task054-viewport-review-checkout-20261008` e pulito; nessuna modifica ai sorgenti.

Il fix proietta `viewInsets` e `viewPadding` globali nel rettangolo centrato effettivo, ricostruisce il `padding` locale e conserva scala2. Il clamp alla larghezza/altezza rappresenta l'intersezione, inclusa l'occlusione totale; non crea spazio utile. Un vero fullscreen piccolo conserva l'intero inset. Il helper è verificato nel caller attuale `MaterialApp.builder` a pieno schermo: non è un contratto generale per ancestor traslati o una SafeArea esterna.

## Verifiche autonome

| Lane candidato | Risultato | Exit |
| --- | --- | --- |
| Geometrie permanenti |8 PASS |0 |
| PoC DPR1/3, portrait/landscape, quattro bordi asimmetrici, occlusione totale |6 PASS |0 |
| Mirror host: editor indirizzo, journal8, assistenza8, recensione |18 PASS |0 |
| Analyze3file, format3file, diff check, checkout pulito |PASS |0 |

Acceptance host: **32 PASS /0 FAIL**. Mirror generato dal commit congelato tramite generatorev2 verificato, con locator assoluti, Roboto fissato, display320×640/DPR1 e capture disabilitate. Nessun PNG, processo nativo o accesso remoto.

## Diagnostica separata con helper reale

I quattro casi usano il vecchio wrapper byte-esatto dalla base e, per la proiezione, `Task054CompactViewport` reale del candidato. Terminano **2 PASS /2 FAIL, exit1 atteso**, distinti dai32test di acceptance:

| Caso sintetico | Inset locale / dialog | Esito |
| --- | --- | --- |
| Parent400×900, vecchio wrapper, raw397 |397 /123 |RED: overflow29, input irraggiungibile |
| Stesso parent, helper reale |231 /289 |PASS: input/CTA raggiungibili, bozza conservata |
| Fullscreen320×568, raw397, helper reale |397 /123 |FAIL diagnostico conservato: overflow29 |
| Fullscreen320×568, raw300, helper reale |300 /220 |PASS: input/CTA raggiungibili, bozza conservata |

`397` deriva da `568−48−123`: **non è una misura IME iOS**. Lo stress fullscreen è conservato come limite diagnostico sintetico preesistente, senza nuovo finding app in questa review del solo harness. I29px host non certificano la causa dei24px iOS, che resta **NOT_VERIFIED**.

## Logger e invarianti

Verificati staticamente e nei due eventi runtime: solo stage costante, dimensioni/insets/rect numerici, piattaforma e famiglia font. Nessuna lettura di testo, controller, identità, errore applicativo, URI o secret. Una seconda lettura indipendente del diff conferma lo stesso esito.

Sequenza delle29callsite `captureVisual` byteidentica;11callsite `testWidgets`,251`await`,4`Duration` e0`skip` invariati. Il logger è sincrono dentro i pump già presenti del solo primo focus recensione. Alberi `lib`, `.github`, `android` e `ios` byteidentici. Contratto137capture invariato; nessuna nuova interazione, attesa o cattura.

Native CI/pixel dopo il fix, IME, AT, profilo fisico, AUTH_TEST e live restano **NOT_RUN**. Questa approvazione è limitata al sorgente harness e non chiudeTASK-054 o il gate pixel del badge.

Comandi terminali, hash sorgenti/PoC/log e dati diagnostici sono nel [receipt](/Users/minxiang/.codex/outputs/task054-completion-20261008/client/native-review/viewport-source-review.json); la [diagnostica precedente](/Users/minxiang/.codex/outputs/task054-completion-20261008/client/native-review/viewport-projection/result.md) è preservata.
