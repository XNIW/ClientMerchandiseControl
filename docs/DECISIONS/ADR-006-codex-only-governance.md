# ADR-006 — Governance operativa Codex-only

- Stato: ACCETTATA
- Data: 2026-07-30
- Task: TASK-001

## Contesto

La governance iniziale assegnava execution e fix a Codex, ma planning e review a
strumenti esterni tramite due file di istruzioni root. L'utente ha emendato esplicitamente
TASK-001: planning, execution, review e fix devono essere gestiti con Codex, mantenendo
separazione di responsabilità e controllo finale umano.

Il doppio ingresso operativo esponeva inoltre il repository a istruzioni divergenti e a
handoff dipendenti da prodotti non più usati.

## Decisione

Adottare `AGENTS.md` come unica istruzione operativa root e
`docs/CODEX-WORKFLOW-PROTOCOL.md` come unico protocollo dettagliato.

Il workflow distingue i ruoli logici `CODEX_PLANNER`, `CODEX_EXECUTOR`,
`CODEX_REVIEWER`, `CODEX_FIXER` e `CODEX_RE_REVIEWER`. Review e re-review devono essere
indipendenti almeno sul piano logico e, preferibilmente, svolte in una nuova sessione
Codex. `USER_APPROVER` resta l'unico ruolo autorizzato a modifiche sostanziali dello
scope, `DONE`, merge e attivazione del task successivo.

Gli stati, le transizioni e gli handoff sono deterministici. Una review `APPROVED`
mantiene il task `ACTIVE / REVIEW` fino alla conferma esplicita dell'utente.

Il precedente file root dedicato agli strumenti esterni viene rimosso dopo il
consolidamento delle sue regole ancora valide. I riferimenti a tali strumenti possono
restare soltanto come storia esplicitamente non operativa negli audit, nelle vecchie
entry del worklog e nella documentazione di questa migrazione.

## Conseguenze

- Una nuova sessione Codex trova in `AGENTS.md` contesto, ordine di lettura, ruoli,
  vincoli e stop condition.
- Planning, execution, review, fix e re-review hanno proprietà di sezione e handoff
  distinti senza dipendenze operative esterne.
- Nessun ruolo Codex può auto-approvare il proprio lavoro, marcare `DONE`, eseguire merge
  o attivare il task successivo.
- La rimozione del secondo file root elimina istruzioni concorrenti.
- Gli audit storici restano fedeli ai ref realmente consultati e sono classificati come
  non operativi.

## Alternative considerate

- Mantenere due file root con un redirect: scartato perché conserva due punti di ingresso
  e una dipendenza nominale non più valida.
- Assegnare tutti i poteri a un ruolo Codex unico: scartato perché annulla la separazione
  logica tra autore e reviewer.
- Imporre sempre sessioni tecnicamente distinte: non adottato come requisito assoluto
  perché non tutti gli ambienti lo garantiscono; resta l'opzione preferita e
  l'indipendenza delle verifiche è comunque obbligatoria.
