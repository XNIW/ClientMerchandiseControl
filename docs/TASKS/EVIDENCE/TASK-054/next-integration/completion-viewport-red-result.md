# TASK-054 — proiezione del viewport, diagnostica sintetica

Candidato letto: `9fe418a95defd0a5b595e4c2b5604d5c70ac509f`. Nessuna modifica ai sorgenti Git.

## Esiti

- Probe geometrico Flutter host: **4 PASS / 1 FAIL**, exit **1** atteso. Il FAIL dimostra che il mirror esatto del wrapper copia inset globali nella superficie centrata.
- Parent 400×900 e inset inferiore 300: viewport reale `(40,166)-(360,734)`; tastiera sintetica occupa y600…900; intersezione locale **134**, MediaQuery originale **300**. Le safe zone globali 30/44/16/34 non intersecano il viewport, ma vengono conservate erroneamente.
- Contrafattuale: inset locale134, viewPadding/padding0; **PASS**.
- Fullscreen320×568 con inset300: originale e contrafattuale mantengono300 e le safe zone; **PASS**, nessuna riduzione della tastiera reale.
- Occlusione totale nel parent400×900 con inset800: intera superficie568 coperta; **PASS**, nessuno spazio utile inventato. La limitazione numerica alla dimensione del rettangolo rappresenta soltanto l'intersezione fisica.

## Dialog recensioni di produzione

Probe host con es-CL, testo200%, Roboto e piattaforma tema Android, apertura del dialog prima dell'inset sintetico:

| Geometria | Inset globale → locale | Flex esterno | Risultato | Input dopo reveal | CTA / bozza |
|---|---|---|---|---|---|
| Parent400×900, mirror originale | 397→397 | 240×123 | FAIL overflow29px | non raggiungibile | CTA raggiungibile / conservata |
| Parent400×900, contrafattuale | 397→231 | 240×289 | PASS | raggiungibile | raggiungibile ≥48 / conservata |
| Fullscreen320×568, proiezione corretta | 397→397 | 240×123 | FAIL overflow29px | non raggiungibile | CTA raggiungibile / conservata |
| Fullscreen320×568, proiezione corretta | 300→300 | 240×220 | PASS | raggiungibile | raggiungibile ≥48 / conservata |

Esito della seconda invocazione valida: **2 PASS / 2 FAIL**, exit **1**. Il valore397 è costruito esclusivamente per ottenere123 (`568−48−123`), mai una misura iOS. Un primo probe esplorativo applicava l'inset prima dell'apertura e falliva per CTA non montata: log conservato, setup corretto, risultato escluso dal RED prodotto.

## Proposta minima e confine

Correggere il solo wrapper fixture: calcolare dimensione/offset reali del rettangolo centrato, proiettare viewInsets e viewPadding su ciascun bordo, ricostruire padding dalla differenza fra valori locali, conservare text scale2. Un fullscreen piccolo deve mantenere gli inset originali. Aggiungere regressioni permanenti geometriche e verifiche mirate input/CTA/draft.

Il difetto geometrico del wrapper è dimostrato. Il native log registra overflow24px su240×123 e input non hit-testable, ma non IME o DPR: il probe host29px non certifica la stessa causa nativa. Rimane una seconda limitazione app sotto vera occlusione locale sintetica397/fullscreen320×568; segnalarla separatamente prima di qualunque app fix. Nessuna app patch eseguita.

Tutte le invocazioni proprie sono terminali; nessuna suite globale, superficie nativa, chiamata remota o accesso live. Source, log e receipt sono locali fuori Git.
