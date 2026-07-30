# TASK-003 evidence

Snapshot di handoff:
`ACTIVE / REVIEW / CODEX_EXECUTION_COMPLETE_TO_REVIEW`.

- Base milestone: merge TASK-002
  `46686ace3b4670f207147f12110d8133ced01e8e`
- Branch: `milestone/003-004-storefront-contract-environments`
- Commit tecnico verificato:
  `e2ad429f25341f9009c3087673c36746e23bf059`
- Tipo task: documentale, architetturale e governance
- Audit: read-only, 57/57 riferimenti a ref fisse, nessuna modifica esterna
- Planning: autorizzato dal prompt end-to-end senza variazioni di scope
- Gate Execution applicabili: tutti `PASS`
- CI Execution: run `30580693884` `PASS` sullo SHA `e2ad429f`, 3/3 job,
  tutti gli step completati e zero annotation
- Review indipendente: non ancora eseguita

Evidence:

- `planning-summary.md`
- `source-audit.md`
- `external-integrity.md`
- `execution-evidence.md`
- `review-report.md` da produrre in Review
- eventuali `fix-evidence.md` e `re-review-report.md`
- `closeout.md` da produrre dopo review `APPROVED`

## Criteri di accettazione

| CA | Tipo | Esito | Evidenza |
|---|---|---|---|
| CA-01 | GIT/STATIC | PASS | TASK-001/TASK-002 `DONE`; merge TASK-002 `46686ace3b4670f207147f12110d8133ced01e8e` |
| CA-02 | STATIC/GIT | PASS | task e Master coerenti; governance script exit 0; 32 CA e 22 test |
| CA-03 | GIT/STATIC | PASS | `source-audit.md`, `external-integrity.md`; 57/57 ref valide e fingerprint finali invariati |
| CA-04 | STATIC/SECURITY | PASS | progetto `merchandisecontrol-dev` sanitizzato e distinto dal workspace storico non-Git |
| CA-05 | STATIC | PASS | `CROSS-REPO-OWNERSHIP.md`, responsabilità, non-responsabilità e forbidden flow |
| CA-06 | STATIC | PASS | matrice domain owner/writer/projector/consumer/contract/change owner |
| CA-07 | STATIC | PASS | ownership Client in cross-repo, system context e mobile architecture |
| CA-08 | STATIC | PASS | ownership Admin e migration/server contract authority in ADR-010 |
| CA-09 | STATIC | PASS | Android/iOS/POS classificati operativi e vietati come API/fallback Storefront |
| CA-10 | STATIC | PASS | Supabase classificato runtime/enforcement, mai business decision owner |
| CA-11 | STATIC | PASS | `CMC-STOREFRONT-LOGICAL` 1.0.0, termini normativi e ownership |
| CA-12 | STATIC | PASS | shop scope obbligatorio; `shop_id` UUID verificato via metadata read-only |
| CA-13 | STATIC | PASS | catalogo guest separato da identità e dati customer |
| CA-14 | STATIC | PASS | allowlist/denylist Storefront esplicite e nessun fallback operativo |
| CA-15 | STATIC | PASS | prezzi, promozioni e availability server-authoritative e rivalidabili |
| CA-16 | STATIC | PASS | pipeline pubblicata separata da management API, bucket e signed URL operativi |
| CA-17 | STATIC | PASS | ordine cliente e vendita fiscale POS distinti nel contratto |
| CA-18 | STATIC | PASS | mutazioni future con autorizzazione, idempotenza, audit e fail-closed |
| CA-19 | STATIC/SECURITY | PASS | publishable key, session identity e authorization distinti |
| CA-20 | STATIC/SECURITY | PASS | capability matrix guest/customer/staff/server in `AUTH-BOUNDARY.md` |
| CA-21 | STATIC/SECURITY | PASS | UI, route, cache, email, `shop_id`, metadata e claim non autorizzano accesso |
| CA-22 | STATIC/SECURITY | PASS | grant e RLS entrambi obbligatori; nessun default Data API assunto |
| CA-23 | STATIC | PASS | compatibility additive/deprecated/breaking e migration window nel contratto/ADR-010 |
| CA-24 | STATIC | PASS | ADR-009: workstream indipendenti, execution seriale con un solo `ACTIVE` |
| CA-25 | STATIC/GIT | PASS | diff Master: cambiano soltanto dipendenze TASK-010, TASK-011 e TASK-020 |
| CA-26 | STATIC | PASS | parser: 42 nodi unici, zero cicli, reachability catalogo/auth conforme |
| CA-27 | STATIC/GIT | PASS | TASK-005–010 e TASK-013+ presenti, `TODO`, titoli/owner/risultati invariati |
| CA-28 | GIT | PASS | diff tecnico limitato a 12 file `docs/`; zero runtime/config/pubspec/backend |
| CA-29 | SECURITY/GIT | PASS | scan diff: zero secret, JWT, private key, URL Supabase completo, token o artifact |
| CA-30 | STATIC/FORMAT/ANALYZE/UNIT/BUILD_ANDROID/BUILD_IOS/GIT | PASS | gate statici e `scripts/check.sh` exit 0; 59/59 test e due build |
| CA-31 | MANUAL/STATIC | NOT_RUN | review indipendente non ancora avviata; criterio proprio della fase REVIEW |
| CA-32 | CI | PASS | run Execution `30580693884` sullo SHA tecnico `e2ad429f`: 3/3 job, step success, 0 annotation; refresh obbligatorio al closeout |

## Test case

| Test | Tipo | Esito | Evidenza |
|---|---|---|---|
| T-01 | GIT/STATIC | PASS | merge TASK-002 e governance TASK-003 verificati |
| T-02 | GIT | PASS | ref, dirty state e fingerprint iniziali/finali confrontati |
| T-03 | STATIC/SECURITY | PASS | provenance canonica/storica distinta e sanitizzata |
| T-04 | STATIC | PASS | matrice ownership completa e senza owner impliciti |
| T-05 | STATIC | PASS | checklist responsabilità e forbidden flow per tutti i sistemi |
| T-06 | STATIC | PASS | versione, change protocol, deprecation e migration window |
| T-07 | STATIC | PASS | shop scope e UUID verificati contro metadata read-only |
| T-08 | STATIC | PASS | allowlist/denylist e guest catalog boundary verificati |
| T-09 | STATIC | PASS | commercial truth e revalidation checklist soddisfatte |
| T-10 | STATIC | PASS | image source/projection/cache boundary verificato |
| T-11 | STATIC | PASS | ordine/vendita, idempotenza e audit separati |
| T-12 | STATIC/SECURITY | PASS | capability e auth boundary checklist soddisfatte |
| T-13 | STATIC/GIT | PASS | allowlist delle tre celle dipendenze e ADR-009 verificata |
| T-14 | STATIC | PASS | parser DAG: 42 nodi, zero cicli e reachability conforme |
| T-15 | STATIC/GIT | PASS | confronto task futuri con merge TASK-002 conforme |
| T-16 | GIT | PASS | diff confinement: soltanto 12 documenti autorizzati |
| T-17 | SECURITY/GIT | PASS | scan secret/prod URL/config/artifact: zero pattern sensibile |
| T-18 | STATIC/GIT | PASS | governance, 57 ref, link locali e diff check exit 0 |
| T-19 | FORMAT/ANALYZE/UNIT/BUILD_ANDROID/BUILD_IOS | PASS | `bash scripts/check.sh`, exit 0 |
| T-20 | MANUAL/STATIC | NOT_RUN | assegnato a reviewer indipendenti nella fase REVIEW |
| T-21 | CI | PASS | run `30580693884`, SHA `e2ad429f`, tutti i job/step verdi e 0 annotation |
| T-22 | GIT/SECURITY | PASS | Client confinato; repository esterni e Supabase zero-write |

`CA-31`/`T-20` non sono gate Execution: sono la verifica indipendente che questo
handoff abilita. Nessun gate obbligatorio proprio dell'Execution è `FAIL`, `BLOCKED` o
`NOT_RUN`.
