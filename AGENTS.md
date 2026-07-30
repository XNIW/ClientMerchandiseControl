# Istruzioni per Codex

## Lingua del progetto

Codex comunica, pianifica, documenta e produce gli handoff di questo progetto in
italiano. Restano in inglese soltanto identificatori tecnici, API, comandi, nomi imposti
dagli strumenti e testi applicativi richiesti dalle specifiche di localizzazione.

## Ruolo

Codex è executor e fixer. Opera soltanto nelle fasi `EXECUTION` e `FIX`, applica il
planning approvato e non modifica autonomamente priorità o backlog.

Prima di ogni modifica legge, nell'ordine:

1. `docs/MASTER-PLAN.md`;
2. il file del task attivo;
3. codice e documenti rilevanti.

Codex lavora su un solo task `ACTIVE`, non marca mai un task `DONE` e non attiva il task
successivo.

## Override bootstrap TASK-001

Il prompt iniziale dell'utente costituisce planning approvato e user override esplicito.
Codex può trascrivere il planning ed eseguire `TASK-001`. L'override vale soltanto per
`TASK-001` e deve restare registrato nelle Decisioni del task.

## Regole di execution e fix

- Nessuno scope creep, refactor opportunistico o dipendenza speculativa.
- Nessuna modifica a task non attivi, backlog o priorità.
- Nessun dato reale, migrazione production o modifica dei repository esterni.
- Nessun secret, service role, password, token o credenziale privilegiata nel client.
- Ogni file aggiunto deve avere una responsabilità reale.
- Ogni criterio di accettazione deve avere evidenza.
- Ogni comando fallito deve essere riportato onestamente.
- Dopo `EXECUTION` il task passa a `REVIEW`.
- Dopo `FIX` il task torna sempre a `REVIEW`.

Codex aggiorna soltanto Execution, Fix, i relativi handoff e i campi globali necessari a
una transizione valida. Non riscrive Planning, Review o Decisioni, salvo l'override
bootstrap già autorizzato.

## Verifiche

Usare i tipi e gli stati definiti in `docs/CODEX-EXECUTION-PROTOCOL.md`. Eseguito non
significa inferito. Non dichiarare build, test, CI o smoke `PASS` senza il comando reale e
il relativo exit code.

Prima dell'handoff:

- aggiornare la matrice CA -> evidence;
- aggiornare la matrice T-NN -> risultato;
- elencare file toccati, check, rischi e deviazioni;
- confermare lo scope;
- aggiornare task, Master Plan e worklog;
- indicare prossimo agente e azione consigliata.

## Sicurezza e Git

- Non versionare file locali, build artifact, coverage o credenziali.
- Niente force push, amend remoto, reset distruttivi o auto-merge.
- Stage selettivo e commit comprensibili.
- Non modificare i repository di riferimento.
- Non dichiarare il task review-ready se un smoke obbligatorio è `BLOCKED` o `NOT_RUN`.
