# Protocollo di esecuzione Codex

## Tipi di verifica

| Tipo | Significato |
|---|---|
| `STATIC` | Lettura o scansione statica |
| `FORMAT` | Formattazione verificata |
| `ANALYZE` | Analisi statica Flutter/Dart |
| `UNIT` | Unit test |
| `WIDGET` | Widget test |
| `BUILD_ANDROID` | Build Android reale |
| `BUILD_IOS` | Build iOS Simulator reale |
| `ANDROID_EMU` | Verifica su Android Emulator |
| `IOS_SIM` | Verifica su iOS Simulator |
| `SECURITY` | Controllo mirato di secret e artifact |
| `CI` | GitHub Actions |
| `GIT` | Stato, diff, branch, commit o PR |
| `MANUAL` | Giudizio o interazione manuale |

Stati ammessi: `PASS`, `FAIL`, `NOT_RUN`, `BLOCKED`.

## Regole di integrità

- Eseguito non significa inferito.
- Nessun build `PASS` senza comando e exit code reali.
- Nessuno smoke `PASS` senza avvio reale.
- Uno screenshot è diagnostica, non prova sufficiente di successo.
- Ogni `NOT_RUN` richiede un motivo preciso.
- Ogni `BLOCKED` richiede causa, tentativo effettuato e prerequisito di sblocco.
- Ogni CA deve avere una riga CA -> evidence.
- Ogni T-NN deve avere una riga T-NN -> risultato.
- Dopo un failure, non eseguire verifiche dipendenti; test indipendenti possono proseguire.
- Log e screenshot non devono contenere secret o dati personali.
- Le evidenze persistenti devono essere concise e sanitizzate.

## Handoff minimo

L'handoff contiene:

- file e responsabilità toccati;
- comandi con exit code;
- warning nuovi;
- tabella CA -> evidence;
- tabella T-NN -> risultato;
- conferma scope o deviazioni;
- rischi residui;
- prossima fase, agente e azione.

Se un smoke obbligatorio è `FAIL`, `NOT_RUN` o `BLOCKED`, TASK-001 resta
`BLOCKED / EXECUTION`.
