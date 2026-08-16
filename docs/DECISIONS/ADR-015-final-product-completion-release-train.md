# ADR-015 — Final product completion come release train sequenziale

- Stato: ACCETTATA
- Data: 2026-08-16
- Task: TASK-034–TASK-042

## Contesto

TASK-043, TASK-044 e TASK-045 sono stati integrati e chiusi. Il backlog storico
TASK-034–TASK-042 resta tecnicamente da eseguire. Il `USER_APPROVER` ha autorizzato il
2026-08-16 il completamento autonomo dell'intero backlog residuo, con review
indipendente, CI exact-SHA, merge normale e verifica post-merge per ciascun task.

## Decisione

Si apre il train `CLIENT_FINAL_PRODUCT_COMPLETION`, composto in ordine da TASK-034,
TASK-035, TASK-036, TASK-037, TASK-038, TASK-039, TASK-040, TASK-041 e TASK-042.

Per questi task il mandato corrente sostituisce la precedente previsione di una sola
review integrata contenuta in ADR-011: resta attivo un solo task alla volta e ciascun
task attraversa Planning, Execution, Review, eventuale Fix, re-review, CI exact-SHA,
merge normale e CI `main`. Dopo il completamento sequenziale viene comunque svolta una
review integrata finale del train, senza riaprire TASK-043–TASK-045 in assenza di una
regressione riproducibile.

Il Client è il writer principale. L'Admin diventa writer soltanto per contratti
Storefront, migration, test database, operatività o configurazioni richiesti dal task;
gli altri repository restano read-only salvo regressione cross-repository reale.

Le migration e gli smoke autorizzati riguardano lo staging canonico con dati sintetici.
Produzione resta invariata: nessuna migration, promozione store, attivazione a pagamento
o go-live viene eseguita in assenza di tutti gli activation gate esterni. Le release
TASK-039/TASK-040 e le readiness TASK-041/TASK-042 usano stati precisi anche quando
credenziali, firma, legal owner value o device fisici non sono disponibili.

## Conseguenze

- l'autorizzazione USER_APPROVER corrente copre attivazione sequenziale, `DONE` e merge
  soltanto dopo review `APPROVED`, gate reali verdi e assenza di P0/P1/P2;
- staging può essere modificato tramite workflow guarded e verifiche sintetiche;
- production deve fallire closed e resta `PENDING_OWNER_ACTIVATION` finché ogni gate
  esterno non è realmente soddisfatto;
- i blocker esterni non arrestano lavoro tecnico indipendente e non vengono classificati
  come bug o `PASS`;
- i checkout primari e ogni dirty state preesistente vengono preservati.

## Alternative considerate

- riaprire TASK-043–TASK-045: scartato senza regressioni reali;
- un'unica PR per TASK-034–TASK-042: scartata perché impedirebbe i checkpoint exact-SHA
  e i merge sequenziali richiesti;
- attivare production per completare i gate esterni: scartato perché il mandato lo vieta
  esplicitamente.
