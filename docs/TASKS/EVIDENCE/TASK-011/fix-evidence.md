# Fix evidence — TASK-011

## Revisioni

- Review con finding:
  `b4b2234f889df91ea422b769153f662c942dadf3`
- Transizione a Fix:
  `71fbb7b2237d556d32b2044b13f0644f9e0de0a5`
- Commit tecnico Fix:
  `8621606d03d06b70f2a421c985c63b96ee3ef47a`
- Branch:
  `milestone/011-012-020-authenticated-storefront-foundation`
- Scope: esclusivamente `T011-REV-001`–`006`

## Risoluzione finding

| Finding | Esito Fix | Evidenza |
|---|---|---|
| `T011-REV-001` P2 | PASS | test auto-check senza chiamata manuale, exactly-one e assenza auto-retry; mutation RED |
| `T011-REV-002` P2 | PASS | widget `recoverableError` con shell/copy/Semantics/48 px/tap/singola call; mutation RED |
| `T011-REV-003` P2 | PASS | smoke via `bootstrap()`, `initializing`, `ready` e tap Catalogo |
| `T011-REV-004` P2 | PASS | rerun Android/iOS, comandi/output completi, PNG e manifest SHA-256 |
| `T011-REV-005` P2 | PASS | identità `GoTrue` esatta; altri nomi -> `invalidResponse` |
| `T011-REV-006` P3 | PASS | limite 8 KiB, abort/cancel stream e overflow mai `healthy` |

## Gate eseguiti

| Comando/verifica | Esito | Risultato |
|---|---|---|
| regressioni pre-fix/mutation | PASS | due RED riproducibili, ripristinate prima dei gate |
| test health | PASS | exit 0, 10/10 |
| test backend completo | PASS | exit 0, 34/34 |
| backend più banner | PASS | exit 0, 41/41 |
| `flutter analyze` | PASS | exit 0, nessuna issue |
| `flutter test --coverage` | PASS | exit 0, 108/108 |
| `bash scripts/check.sh` | PASS | exit 0; governance, boundary, 108/108, build Android/iOS |
| build APK staging | PASS | exit 0 |
| build iOS Simulator staging | PASS | exit 0 |
| smoke Android staging | PASS | exit 0, 1/1 |
| smoke iOS staging | PASS | exit 0, 1/1 |
| ispezione screenshot | PASS | Catalogo Android/Home iOS, nessun dato o config |
| manifest screenshot | PASS | due PNG, dimensioni/byte/digest ricalcolati |
| log/secret/config scan | PASS | processi app puliti; config ignorata e non tracciata |
| CI Fix `30599648372` | PASS | SHA esatto, 3/3 job, tutti gli step, annotation 0/0/0 |

## Output pertinente

- suite completa: `+108: All tests passed!`;
- analyze: `No issues found!`;
- Android smoke: `00:15 +1: All tests passed!`;
- iOS smoke: `00:30 +1: All tests passed!`;
- build staging: APK debug e Runner Simulator completate;
- CI: Quality 2m14s, Android 7m59s, iOS 3m54s.

## Deviazioni

- Il primo smoke Android del nuovo test, prima del commit tecnico, falliva perché il
  finder del titolo Catalogo includeva anche la label NavigationBar. Il finder è stato
  ristretto al descendant della schermata; il rerun finale e il dual-platform sullo SHA
  tecnico sono 1/1 `PASS`.
- I primi screenshot acquisiti dopo la chiusura degli integration runner mostravano le
  Home dei simulatori. Sono stati rifiutati, sovrascritti dopo un lancio persistente e
  non sono presenti nelle evidence.
- Lo scan log Android globale trovava tre marker `refresh_token` di un servizio di
  sistema con PID diverso. Lo scan sul PID app è `PASS`; nessun valore è stato stampato.
- Sette package hanno release più recenti incompatibili con i constraint; nessun
  aggiornamento opportunistico è stato applicato.

## Sicurezza e scope

- nessun valore della config staging è stato stampato o versionato;
- nessun OAuth, callback nativo, session lifecycle o write remoto introdotto dal task;
- nessuna query/RPC/Storage o dato Storefront/inventory;
- screenshot e log senza URL, key, token, account o dato personale;
- client e azioni Codex TASK-011 rimasti zero-write; il traffico Admin esterno
  concorrente del progetto condiviso è documentato separatamente e non attribuito.

## Matrice CA

| CA | Esito | Evidenza |
|---|---|---|
| CA-06 | PASS | Identità GoTrue stretta e regressione servizio diverso. |
| CA-12, CA-15 | PASS | Health valido/invalid/overflow mappati fail-closed. |
| CA-17 | PASS | Auto-check exactly-one e nessun auto-retry. |
| CA-20–CA-22 | PASS | Shell, recoverable retry e sanitizzazione. |
| CA-25 | PASS | Regression sensibili per tutti i finding. |
| CA-27–CA-28 | PASS | Bootstrap/navigation dual-platform con evidence. |
| CA-29–CA-30 | PASS | Gate completi e confinement. |
| CA-31 | NOT_RUN | Appartiene alla re-review indipendente. |
| CA-32 | NOT_RUN | CI Fix verde; CI sullo SHA finale successiva. |

## Matrice test

| Test | Esito | Evidenza |
|---|---|---|
| T-07 | PASS | Altro servizio e overflow rifiutati. |
| T-12 | PASS | Auto-check e assenza auto-retry. |
| T-16–T-17 | PASS | `recoverableError`, Semantics, target e retry. |
| T-20 | PASS | Artifact/digest/log/config scan. |
| T-23–T-24 | PASS | Smoke bootstrap Android/iOS. |
| T-25–T-27 | PASS | Build e check completi. |
| T-28 | NOT_RUN | Re-review successiva. |
| T-29 | NOT_RUN | CI finale successiva. |

## Handoff

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`
