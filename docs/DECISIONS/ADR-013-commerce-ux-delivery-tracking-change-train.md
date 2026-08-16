# ADR-013 — Commerce UX e delivery tracking come change train sequenziale

- Stato: ACCETTATA
- Data: 2026-08-16
- Task: TASK-043, TASK-044, TASK-045

## Contesto

Il release train `STOREFRONT_V1` e TASK-033 sono stati chiusi il 2026-08-12. Il Master
Plan conservava una prossima azione ormai storica relativa alla PR #7, ma la PR risulta
merged nel commit `8423c868f345ee87eee7ed58ee9eb793d98412db` con CI reale verde. Il
`USER_APPROVER` ha richiesto il 2026-08-16 una variazione di prodotto bounded: refresh
dell'architettura commerce, tracking delivery end-to-end e mappa cliente, senza
alterare retroattivamente l'evidence TASK-001–TASK-033.

## Decisione

Si apre il train `CLIENT_STOREFRONT_UX_AND_DELIVERY_TRACKING`, composto in ordine da:

1. TASK-043 — architettura delle superfici Client e UX commerce;
2. TASK-044 — contratto delivery, privacy/RLS e writer operativo courier;
3. TASK-045 — consumer realtime, mappa Client, acceptance integrata e closeout.

Resta attivo un solo task alla volta. Ogni task attraversa Planning, Execution, Review,
eventuale Fix, re-review, CI exact-SHA, merge normale e verifica della CI `main`. Il
prompt USER_APPROVER del 2026-08-16 autorizza in anticipo queste transizioni e i merge
condizionati a review `APPROVED` e gate reali verdi; non autorizza force push, bypass,
production irreversibile, store release o attivazione di servizi a pagamento.

Il Client resta consumer esclusivo del dominio Storefront. L'Admin è authority delle
migration, RPC, RLS e del writer operativo. Il tracking delivery resta separato dagli
eventi fiscali e dall'inventory operativo. La prima capability courier è dichiarata
foreground; un eventuale requisito futuro di background continuo richiederà un nuovo
decision record e un'app dedicata, non una modalità staff nascosta nel Client.

## Conseguenze

- TASK-034–TASK-042 non vengono rinumerati o attivati; TASK-034 torna prossimo dopo il
  closeout di TASK-045.
- La CI o una review non eseguita resta `NOT_RUN`/`BLOCKED`, mai inferita.
- Le chiavi provider mancanti sono activation switch fail-closed, non motivo per
  introdurre dati demo nel percorso production.
- La review indipendente resta almeno logica e separata dal ruolo writer; il limite di
  una stessa sessione viene dichiarato nell'evidence.

## Alternative considerate

- Estendere retroattivamente `STOREFRONT_V1`: scartato perché ne altererebbe il closeout
  e l'evidence storica.
- Integrare tracking nel POS o nell'inventory: scartato perché confonde stato cliente ed
  eventi fiscali.
- Una sola PR multi-repository per l'intero train: scartata perché il mandato richiede
  CI e merge verificabili per ciascun task.
