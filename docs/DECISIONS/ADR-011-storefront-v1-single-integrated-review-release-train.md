# ADR-011 — Release Train con Review Integrata Unica

- Stato: ACCETTATA
- Data: 2026-08-01
- Task: STOREFRONT_V1 / TASK-005–TASK-010, TASK-013–TASK-019, TASK-021–TASK-042

## Contesto

Storefront v1 attraversa Client Flutter, Admin/Supabase e Win7POS. Il workflow ordinario
chiude e revisiona un task alla volta; applicarlo letteralmente al train produrrebbe
review repository-wide ripetute, revision set incompatibili e deploy staging frammentati.

Il prompt utente del 2026-08-01 autorizza un'esecuzione continua e riprendibile, una
sola review formale multi-repository, un solo ciclo Fix/re-review e il merge coordinato
soltanto a gate finali verdi. L'autorizzazione non riduce security, test, evidence o
separazione autore/reviewer.

## Decisione

Per il solo release train `STOREFRONT_V1` adottiamo queste transizioni:

```text
TODO
  -> ACTIVE / PLANNING
  -> ACTIVE / EXECUTION
  -> VALIDATED_PENDING_INTEGRATED_REVIEW
  -> INTEGRATED_REVIEW
  -> FIX
  -> INTEGRATED_REVIEW
  -> DONE
```

- un solo task può essere `ACTIVE / EXECUTION`;
- più task possono attendere in `VALIDATED_PENDING_INTEGRATED_REVIEW`;
- un checkpoint verde prova soltanto i gate pertinenti allo SHA corrente;
- nessun checkpoint è una review e nessun task diventa `DONE` prima della review
  integrata;
- nessun task successivo viene implementato prima del checkpoint verde del precedente;
- le branch coordinate sono `integration/storefront-v1` e le PR restano draft durante
  l'Execution;
- il manifest di release e il checkpoint persistente registrano revisioni, deploy,
  gate, rollback e comando successivo;
- al freeze, nove reviewer read-only distinti coprono le superfici richieste dal prompt;
- un solo writer consolida i finding e applica gli eventuali fix;
- P0/P1/P2 aperti implicano `CHANGES_REQUIRED`; la sola re-review verifica finding,
  regressioni, flusso cross-repo, security, manifest, SHA e CI;
- `DONE`, merge normale e deploy/rollout sono ammessi soltanto dopo outcome integrato
  `APPROVED`, zero P0/P1/P2 e gate reali sul revision set finale.

`USER_APPROVER` è già autorizzato dal prompt del release train per le transizioni
interne, il closeout e i merge condizionati. L'autorizzazione non può essere usata per
inventare `PASS`, accettare spesa o accordi, modificare production prima dei gate,
eseguire migrazioni distruttive, fare force push o superare il rollout del 5%.

## Checkpoint

Ogni milestone esegue soltanto test/build pertinenti, smoke staging, security scan
mirato, backward compatibility e aggiornamento del manifest. Deep security scan e
review repository-wide avvengono una volta sul candidato integrato. Le modifiche solo
documentali usano validator governance, link check, `git diff --check` e test
documentali pertinenti.

## Ripresa e recovery

`docs/releases/STOREFRONT-V1-CHECKPOINT.md` è il punto di ripresa dopo compattazione o
interruzione. Un blocker esterno deve lasciare processi terminati, branch/commit/PR
preservati, evidence sanitizzate e un solo intervento umano preciso. Nessun blocker
esterno converte un gate in `PASS`.

## Conseguenze

- La storia dei task e la numerazione TASK-001–TASK-042 restano immutate.
- La nuova condizione è riconoscibile e verificabile dal validator soltanto quando il
  Master Plan dichiara `Release train: STOREFRONT_V1`.
- Il train può avanzare senza conferme intermedie dopo checkpoint verdi.
- Il rischio di auto-review è ridotto dal freeze e dai reviewer read-only distinti.
- Alla chiusura, la governance ordinaria torna a essere il default; l'ADR resta come
  provenance della deroga usata.

## Alternative considerate

- Review completa dopo ogni task: scartata per duplicazione e revision set divergenti.
- Un unico task monolitico senza stati intermedi: scartato perché impedisce checkpoint,
  ownership e tracciabilità dei criteri.
- Più task `ACTIVE / EXECUTION`: scartata perché crea writer concorrenti e ambiguità.
- Merge progressivi durante l'Execution: scartato perché rompe il freeze coordinato e
  rende non atomica la review finale.
