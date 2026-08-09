# Evidence TASK-033

Snapshot di handoff:
`BLOCKED / EXECUTION / BLOCKED_SECURITY_SCAN_TOOL_PERMISSION_PROFILE`.

Classificazione del blocco: `BLOCKED_EXTERNAL / BLOCKED_ENVIRONMENT`; non è un
finding del repository.

## Target e precheck

- repository: `XNIW/ClientMerchandiseControl`;
- SHA richiesto e verificato: `ec74166ea20786b8deaa9965cac103984c927820`;
- branch coordinato/PR: `integration/storefront-v1`, PR #5 draft, head remoto sullo
  stesso SHA;
- worktree di scansione: nuovo checkout detached sotto la directory temporanea di
  sistema, 564 file tracciati, zero modifiche tracked/untracked/ignored;
- Admin verificato in sola lettura:
  `e0406834af09173902e2f64948dd5834f4a9fac5`, PR #67 draft;
- nessuna modifica a Client/Admin, Supabase, Storage, production o infrastruttura.

## Tentativo precedente — sola evidenza storica

- manifest:
  `/private/var/folders/nf/85_c2pqj60v6q0r7v8ktzkpw0000gn/T/codex-security-scans-I70DTh/storefront-v1/unversioned_20260803T145131Z_dvvd5ju2/artifacts/deep_discovery/coordinator-manifest.json`;
- mtime: `2026-08-03T13:57:58-0400`;
- stato/cause: `failed`, usage limit con retry indicato dopo il 2026-08-07 23:52;
- disposizione: non accettato, non copiato nel nuovo contesto e non usato per
  candidate, finding o assenza di finding.

## Nuovo preflight 2026-08-08

- profile: `deep_security_scan`;
- helper exit code: 0;
- risultato: `ready`;
- `goal_tools` e `features.goals`: `pass`;
- skill richieste presenti nella sessione: `threat-model`, `validation`,
  `attack-path-analysis` e `deep-security-scan`;
- Python 3.9 è stato eseguito tramite ambiente temporaneo isolato con `tomli==2.2.1`;
  nessuna dipendenza o configurazione persistente è stata modificata.

## Nuova chiamata Deep Security Scan

È stata effettuata una sola chiamata repository-wide con scope `.` sul nuovo worktree.
La discovery non è stata avviata né riagganciata. Errore terminale esatto:

```text
Deep Scan cannot safely start a read-only worker: the parent must provide a managed filesystem permission profile.
```

Il tool non ha fornito `scanId`, `manifestPath` o un nuovo failure-manifest. Non è stato
effettuato un secondo tentativo nella stessa esecuzione.

| Fase | Stato | Evidenza |
|---|---|---|
| Preflight | PASS | exit 0, `ready` |
| Discovery | BLOCKED | managed filesystem permission profile assente |
| Manifest acceptance | NOT_RUN | nessun manifest terminale |
| Candidate/review-item pagination | NOT_RUN | discovery non avviata |
| Canonical threat model | NOT_RUN | discovery non avviata |
| Validation | NOT_RUN | fase dipendente |
| Attack-path analysis | NOT_RUN | fase dipendente |
| Draft/completion/report.md | NOT_RUN | fase dipendente |
| Integrated review/closeout/merge | NOT_RUN | stop condition obbligatoria |

## Prerequisito di sblocco

Avviare una nuova esecuzione in un host/sessione che esponga al plugin Codex Security un
managed filesystem permission profile per il worker read-only; rieseguire il preflight
e una sola nuova Deep Security Scan sul medesimo SHA. Il tentativo corrente e quello
storico non sono riprendibili come scan valide.

La verifica di remediation successiva ha confermato che il preflight non propone patch
configurative applicabili e che la tool surface corrente non espone un setter per il
permission profile. Il parent dichiara `permission_profile: disabled`: lo sblocco
richiede quindi una nuova sessione/host configurata prima della chiamata, non una
modifica al repository o a `config.toml` inventata dall'agente.

## Residual audit remoto 2026-08-08

- nessuna Deep Security Scan è stata ritentata durante il residual audit;
- il target resta immutato e raggiungibile da `integration/storefront-v1`,
  `origin/integration/storefront-v1`, PR Client `#5` e dal worktree detached pulito;
- un unico rerun della CI Client `30824651949`, attempt `2`, è stato richiesto sullo
  SHA esatto; `Quality`, `Android debug build` e `iOS Simulator debug build` sono
  terminati `failure` con zero step eseguiti e la stessa annotazione esterna
  billing/spending limit;
- il drift README/checker sul nuovo stato `BLOCKED` è stato corretto soltanto nel
  worktree documentale: `bash -n` `PASS`, governance corrente `PASS`, fixture
  `9/9 PASS` e `git diff --check` `PASS`;
- nessun secondo rerun, merge, deploy o modifica production è stato eseguito; il batch
  documentazione/governance è isolato su un branch post-target e resta fuori dal ref
  da scansionare.

## Handoff deterministico per la sessione locale

1. Target: `XNIW/ClientMerchandiseControl` allo SHA
   `ec74166ea20786b8deaa9965cac103984c927820`.
2. Usare il worktree detached pulito già presente, oppure crearne uno nuovo dallo
   stesso SHA; aspettativa: HEAD esatto e working tree senza tracked/untracked/ignored.
3. TASK-032 resta `VALIDATED_PENDING_INTEGRATED_REVIEW`; TASK-033 resta
   `BLOCKED / EXECUTION` fino alla completion reale.
4. In una sessione con managed filesystem permission profile, eseguire il preflight
   ufficiale e avviare una sola nuova Deep Security Scan repository-wide, scope `.`.
5. Non riutilizzare i due tentativi terminali precedenti e non includere eventuali
   commit successivi al target.
6. Avviare la review integrata solo dopo completion riuscita, `report.md` presente,
   coverage `full` e assenza di finding release-blocking.
