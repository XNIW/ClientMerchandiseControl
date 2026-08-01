# Re-review report — TASK-011, ciclo 1

## Target e reviewer

- Target:
  `3c830b6c2708c491ee26fd8e7c7f3b0bc7e79a8e`
- Commit tecnico Fix:
  `8621606d03d06b70f2a421c985c63b96ee3ef47a`
- Shard indipendenti: runtime, platform/evidence, security
- Worktree reviewer: pulito e allineato a origin

## Chiusura finding originali

| Finding | Esito | Verifica indipendente |
|---|---|---|
| `T011-REV-001` P2 | CLOSED | mutation auto-check RED; test reale exactly-one/no auto-retry |
| `T011-REV-002` P2 | CLOSED | mutation recoverable action RED; widget completo |
| `T011-REV-003` P2 | CLOSED | bootstrap reale, initializing, ready e tap Catalogo Android/iOS |
| `T011-REV-004` P2 | CLOSED | comandi/target/output, due PNG e digest verificati |
| `T011-REV-005` P2 | CLOSED | identità `GoTrue` esatta e regressione altri servizi |
| `T011-REV-006` P3 | CLOSED | limite 8 KiB, abort/cancel e overflow fail-closed |

## Nuovo finding

### T011-REREV-SEC-001 — P2 — OPEN

Le evidence usano in più punti «Supabase rimasto zero-write» come claim globale. I log
read-only mostrano invece due finestre di traffico Auth Admin concorrente durante il
task. La provenance lo attribuisce a una sorgente Admin staging privilegiata esterna;
il client e le azioni Codex TASK-011 mostrano soltanto health GET e non possono eseguire
quelle operazioni.

Impatto: nessun difetto runtime, leak o write del client, ma `CA-04` non è tracciato in
modo preciso finché l'evidence non separa task/client da attività globale concorrente.

Fix richiesto, senza cambiare il criterio:

> Zero write del client e delle azioni Codex TASK-011; osservato traffico Admin esterno
> concorrente, non attribuito al task e fuori scope.

Non devono essere persistiti email, IP, UUID, project ref completo o altri identificatori.

## Gate indipendenti

| Gate | Esito | Evidenza |
|---|---|---|
| mutation auto-check/recoverable | PASS | entrambe RED |
| runtime mirato | PASS | 23/23 |
| health/repository | PASS | 23/23 |
| backend completo | PASS | 34/34 |
| suite completa | PASS | 108/108 |
| analyze | PASS | zero issue |
| smoke Android/iOS | PASS | 1/1 per piattaforma |
| screenshot/digest | PASS | dimensioni, byte e SHA-256 coincidenti |
| scan client query/write/admin | PASS | zero path mutanti/Admin |
| secret/config/artifact scan | PASS | nessun valore reale tracciato |
| CI `30600113945` | PASS | SHA esatto, 3/3 job, step verdi, annotation 0/0/0 |

## Matrice CA

| CA | Esito | Evidenza |
|---|---|---|
| CA-01–CA-03 | PASS | Governance, progetto e config verificati. |
| CA-04 | FAIL | Evidence zero-write formulata in modo globale e non supportato. |
| CA-05–CA-30 | PASS | Finding originali chiusi e gate rieseguiti. |
| CA-31 | FAIL | Un P2 documentale aperto. |
| CA-32 | NOT_RUN | CI sullo SHA finale successiva. |

## Matrice test

| Test | Esito | Evidenza |
|---|---|---|
| T-01 | PASS | Governance e target. |
| T-02 | FAIL | Provenance zero-write da precisare. |
| T-03–T-27 | PASS | Gate tecnici e runtime rieseguiti. |
| T-28 | FAIL | Re-review `CHANGES_REQUIRED`. |
| T-29 | NOT_RUN | CI finale successiva. |

## Esito

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`
