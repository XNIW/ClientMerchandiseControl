# Evidence TASK-006

Snapshot di handoff:
`VALIDATED_PENDING_INTEGRATED_REVIEW / INTEGRATED_REVIEW /
STOREFRONT_V1_MILESTONE_CHECKPOINT_VALIDATED`.

## Stato

- Planning: `PASS` — scope projection e test definiti nel task.
- Autorizzazione: `PASS` — prompt Storefront v1 del 2026-08-01.
- Execution: `PASS` — revision set Admin
  `a2a45ef84b19e39d21e42673c31e2e8fc90e88f4`.
- Review integrata: `NOT_RUN`.
- Production write: `NOT_RUN` — vietata prima dei gate finali.

## Gate sintetici

| Gate | Esito | Risultato reale |
|---|---|---|
| Migration replay | PASS | 102 migration, exit 0 |
| pgTAP completo | PASS | 20 file / 1378 test, exit 0, 44.99 s |
| pgTAP TASK-005+006 | PASS | 96/96, exit 0 |
| Concurrency | PASS | 2 writer, 2 prodotti, zero deadlock, fingerprint esatto |
| Lint/typecheck/build | PASS | exit 0; build 9.17 s |
| Dependency audit | PASS | 0 vulnerability |
| Admin CI | PASS | run `30719303538`, SHA esatto |
| Cloudflare build/smoke | PASS | run `30719303536`, SHA esatto |
| Dry-run ACL repair | PASS | run `30719307636` |
| Apply staging | PASS | run `30719348489`, SHA esatto |
| Postverify staging | PASS | digest `74d323682c7545b45a95c02db5108fd11f8ef7b92c9f07451671aa4d626af796` |
| Smoke staging | PASS | publish/promo/pause/version; rollback verificato; fixture residue 0 |
| Production | NOT_RUN | invariata per policy release train |

## Deviazione risolta

Il primo apply projection `30719195758` ha installato la migration ma ha fallito il
postverify perché la default ACL del progetto cloud concedeva DML a `service_role`.
Non è classificato `PASS`. La correzione è la migration additiva
`20260801213500_storefront_v1_catalog_projection_grants.sql`; dry-run, apply e
postverify successivi sono verdi.

Il primo harness a due writer ha inoltre rilevato un deadlock causato dalla riscrittura
della versione nelle righe authoring. Il design è stato corretto rendendo projection e
version table autoritative per la versione pubblica; il test di regressione concorrente
è poi risultato `PASS`.

Le evidence tecniche resteranno sintetiche e sanitizzate; log completi e artifact sono
conservati fuori repository o nei run CI con retention limitata.
