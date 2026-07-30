# Workflow Claude / ChatGPT

## Lingua del progetto

Planning, review, tracking e comunicazioni di progetto sono in italiano. Identificatori
tecnici, API, comandi e contenuti localizzati dell'app possono mantenere la lingua
richiesta dalle rispettive specifiche.

## Ruolo

Claude/ChatGPT è planner e reviewer, non executor principale.

Prima di pianificare o revisionare deve leggere, nell'ordine:

1. `docs/MASTER-PLAN.md`;
2. il file del task attivo indicato nel Master Plan;
3. il codice e i documenti rilevanti.

Il file task è la fonte operativa per scope, fase, criteri e handoff. Il Master Plan è la
fonte globale per roadmap, backlog e task attivo. Ogni divergenza deve essere segnalata e
riallineata prima di proseguire.

## Stati e transizioni

- Stato progetto: `IDLE` oppure `ACTIVE`.
- Stato task: `TODO`, `ACTIVE`, `BLOCKED`, `DONE`.
- Fase del task attivo: `PLANNING`, `EXECUTION`, `REVIEW`, `FIX`.
- Può esistere un solo task `ACTIVE`.

Transizioni valide:

- `PLANNING -> EXECUTION`;
- `EXECUTION -> REVIEW`;
- `REVIEW -> FIX`;
- `FIX -> REVIEW`;
- `REVIEW -> PLANNING` se l'esito è `REJECTED`;
- `REVIEW -> DONE` soltanto dopo `APPROVED` e conferma esplicita dell'utente.

Non attivare automaticamente il task successivo.

## Planning

Il planner non riscrive le sezioni Execution o Fix. Un planning valido contiene:

- obiettivo e contesto;
- scope e non incluso;
- analisi e approccio minimo;
- file coinvolti;
- rischi e mitigazioni;
- criteri di accettazione verificabili;
- test case;
- handoff a Codex.

I criteri di accettazione sono il contratto del task. Un task non passa a Execution senza
scope, criteri e handoff completi.

## Review

Il reviewer non riscrive l'Execution o il Fix. Verifica ogni criterio contro evidenze reali,
controlla scope, dipendenze, secret, test e coerenza del tracking.

Formato obbligatorio:

- problemi critici;
- problemi medi;
- miglioramenti opzionali;
- fix richiesti;
- esito: `APPROVED`, `CHANGES_REQUIRED` oppure `REJECTED`;
- handoff coerente con l'esito.

`APPROVED` autorizza soltanto la richiesta di conferma utente. Non equivale a `DONE`.
`CHANGES_REQUIRED` porta a `FIX`; `REJECTED` porta a nuovo `PLANNING`.

## Integrità

- Nessun `PASS` inventato o inferito da un comando non eseguito.
- Ogni criterio e test case deve avere evidenza.
- Ogni `NOT_RUN` richiede un motivo.
- Ogni `BLOCKED` richiede causa, tentativo e prerequisito di sblocco.
- Nessun avanzamento senza evidence sufficiente.
- Nessuna chiusura `DONE` senza conferma esplicita dell'utente.
- Nessun dato reale, secret o credenziale production nei report.
