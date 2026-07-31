# Development findings — TASK-012

Questi sono failure osservati durante Execution, non finding formali di Review. Sono
registrati per evitare che il solo run finale nasconda il percorso di verifica.

| ID | Tipo | Impatto osservato | Correzione | Regressione | Stato |
|---|---|---|---|---|---|
| DEV-01 | UI/A11Y | Il pulsante Google disabilitato non formava un nodo Semantics autonomo sul device | `Semantics.container` sul wrapper e proprietà enabled/button esplicite | unit test disabled più smoke Android/iOS | RISOLTO |
| DEV-02 | UI/STATE | Il banner esterno a Home cambiava l'altezza dell'indexed stack e clampava lo scroll offstage di 76 px | banner spostato nello scroll Home; shell con viewport branch stabile | asserzioni subtree/offset nell'integration test | RISOLTO |
| DEV-03 | TEST | Il secondo `ensureVisible` modificava lo stesso offset poi confrontato col valore precedente | confronto prima della manipolazione e baseline aggiornata dopo i check | smoke finale | RISOLTO |
| DEV-04 | TEST | Flutter 3.44 segnalava un `SemanticsHandle` ancora attivo a fine test | dispose esplicito nel corpo del test | smoke finale | RISOLTO |
| DEV-05 | LAYOUT | Prime iterazioni widget producevano overflow banner/app bar e Semantics duplicate a 200% | banner compact, titolo orizzontalmente raggiungibile, route semantics unica e viewport feature-specifico | 4 viewport, light/dark, 60 test mirati | RISOLTO |

Esito finale:

- `flutter analyze`: `PASS`;
- `flutter test --coverage`: `PASS`, 139/139;
- Android integration: `PASS`, 1/1;
- iOS integration: `PASS`, 1/1;
- finding di sviluppo aperti: zero.
