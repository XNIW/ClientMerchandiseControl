# Associazione della review visual Android — e7b194c

**APPROVED**, limitatamente all’associazione del campione Android già revisionato
e agli otto PNG modificati, sul commit `e7b194cea8bb53b23d3e994268d5cd47e67d085e`.
Run [37822118836](https://github.com/XNIW/ClientMerchandiseControl/actions/runs/37822118836),
artifact `11570931734`. Nessun finding visivo bloccante; accettazione globale
**BLOCKED**. La [review precedente](native-visual-review-20261008.md) resta immutata
e associata al proprio commit `62980d2`.

Il confronto autonomo dei 117 originali conferma **109/113 PNG Flutter byte-identici**,
quattro Flutter modificati e quattro OS modificati; nessun percorso aggiunto o rimosso.
I 25 Flutter del campione precedente sono tutti identici. I due OS precedentemente
revisionati sono stati aperti di nuovo, insieme agli altri sei frame cambiati:
**8 nuovi PNG e 8 precedenti** visti singolarmente con `view_image(detail=original)`.
Il JSON conserva hash del campione ereditato, vecchi/nuovi hash dei mutati,
associazione dei sidecar e impronte della prova precedente.

| Frame cambiati | Osservazione diretta |
| --- | --- |
| Flutter54/55/56 | Timestamp cache da 16:44 a 17:23; avvisi e azioni restano leggibili. |
| Flutter71 | Cursore visibile e più contenuto nel viewport, incluso stato senza prodotti e filtri. Non equivale al viewport OS con tastiera. |
| OS62 | Tastiera Android realmente visibile; errore, Cerrar e Guardar completi sopra l’IME. |
| OS71 | Tastiera realmente visibile; ricerca, cursore, suggerimenti e categorie leggibili sopra l’IME. Il contenuto Flutter inferiore non è simultaneamente visibile. |
| OS97 | Tastiera realmente visibile; Cancelar ed Enviar a moderación completi sopra l’IME. Commento parzialmente fuori dal viewport scrollato. |
| OS104 | Nota sintetica leggibile sopra la tastiera; clock da 5:46 a 6:26. Il frame non mostra l’intero modulo o l’azione finale. |

Il confronto Git autonomo conferma invariati i tree `lib`, `ios`, `android` e i
file del harness/runner visual elencati nel JSON. La receipt Android del nuovo
artifact riporta 113 catture, exit 0 e cleanup PASS; i quattro sidecar OS coincidono
con il nuovo head e con gli hash dei PNG. Nessun nome o flag sostituisce
l’ispezione dei pixel. I restanti 84 Flutter identici non ricevono una nuova
approvazione indipendente da questo reviewer per effetto del solo confronto hash.

**Limiti:** nessun test/build/device rieseguito e nessuna interazione manuale.
TalkBack/VoiceOver, composizione CJK, altre tastiere, device fisico e backend
Autenticato `NOT_RUN`. iOS nativo/visual `NOT_RUN`: i due job si fermano nella
prepare/post-boot inventory con cleanup complessivo FAIL, prima di test o PNG.
Il percorso VM/Keychain non è attraversato; non si deduce un difetto app.
La diagnosi iOS resta nella review distinta delle receipt.

Creati soltanto questa sintesi e
[native-visual-association-e7b194c-20261008.json](native-visual-association-e7b194c-20261008.json).
Nessuna modifica alla review precedente, al source, alla governance o agli artifact.
