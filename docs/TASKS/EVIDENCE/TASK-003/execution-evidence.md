# TASK-003 — Execution evidence

## Identità della revisione

- **Branch**: `milestone/003-004-storefront-contract-environments`
- **Baseline Execution**:
  `f3905caf3a4abf7b2682b5dcd9ed491dba019ea0`
- **Commit tecnico verificato**:
  `e2ad429f25341f9009c3087673c36746e23bf059`
- **Base milestone**:
  `46686ace3b4670f207147f12110d8133ced01e8e`
- **Data gate finali**: 2026-07-30
- **Tipo**: documentale, architetturale e governance; nessun runtime o backend

Il commit tecnico contiene esclusivamente dodici file documentali autorizzati. Le
evidence di handoff successive descrivono quel commit senza modificarne il contratto.

## Deliverable

| Area | File | Responsabilità |
|---|---|---|
| Ownership | `docs/ARCHITECTURE/CROSS-REPO-OWNERSHIP.md` | owner, writer, projector, consumer, contract owner, change owner e forbidden flow |
| Contratto | `docs/ARCHITECTURE/STOREFRONT-INTEGRATION-CONTRACT.md` | contratto logico `CMC-STOREFRONT-LOGICAL` 1.0.0, shop scope, commercial truth e compatibility |
| Auth | `docs/ARCHITECTURE/AUTH-BOUNDARY.md` | guest/customer/staff/server, credenziali, RLS/grant e fail-closed |
| Data boundary | `docs/ARCHITECTURE/STOREFRONT-DATA-BOUNDARY.md` | allowlist/denylist, immagini, ordini e superfici operative vietate |
| Contesto mobile | `docs/ARCHITECTURE/SYSTEM-CONTEXT.md`, `docs/ARCHITECTURE/MOBILE-ARCHITECTURE.md` | flussi consentiti e adapter futuri |
| Decisioni | `docs/DECISIONS/ADR-009-parallel-catalog-authentication-workstreams.md`, `docs/DECISIONS/ADR-010-storefront-contract-ownership.md` | workstream e change protocol |
| Governance | `docs/MASTER-PLAN.md`, `docs/QUALITY-GATES.md` | tre dipendenze corrette e gate contrattuali |
| Provenance | `source-audit.md`, `external-integrity.md` | 57 fonti a ref fisse e fingerprint zero-write |

`README.md`, task, evidence index e worklog sono aggiornati soltanto nel commit di
handoff per riflettere la transizione `EXECUTION -> REVIEW`.

## Risultati dei gate

| Gate/comando | Exit | Esito | Risultato pertinente |
|---|---:|---|---|
| `bash scripts/check-governance-state.sh` | 0 | PASS | `TASK-003 / ACTIVE / EXECUTION / CODEX_PLANNING_APPROVED_TO_EXECUTION` prima dell'handoff |
| parser DAG/reachability Node read-only | 0 | PASS | 42 nodi, un solo `ACTIVE`, zero cicli, dipendenze TASK-010/011/020 esatte |
| confronto Master con merge TASK-002 | 0 | PASS | task futuri conservati; soltanto le tre celle dipendenze autorizzate cambiano |
| validator citazioni a ref fisse | 0 | PASS | 57/57 riferimenti risolti; Client 5, Admin 12, Android 17, iOS 10, POS 8, storico 5 |
| validator link Markdown locali | 0 | PASS | 12 file verificati, un link locale valido, zero mancanti |
| scan secret/URL sensibili sul diff tecnico | 0 | PASS | 12 file, zero key, JWT, private key, URL Supabase completo o token |
| `git diff --check f3905ca..e2ad429` | 0 | PASS | zero whitespace error |
| `bash -n scripts/*.sh` | 0 | PASS | sintassi di tutti gli script valida |
| `bash scripts/doctor.sh` | 0 | PASS | Flutter 3.44.8, Android e Xcode disponibili; doctor senza issue |
| `flutter pub deps --style=compact` | 0 | PASS | grafo risolto, nessuna dipendenza aggiunta |
| `flutter pub outdated` | 0 | PASS | solo aggiornamenti disponibili; nessuna modifica autorizzata |
| `bash scripts/check.sh` | 0 | PASS | 40 file formattati, analyze pulito, 59/59 test, build Android e iOS |
| fingerprint esterne finali | 0 | PASS | quattro repository Git e workspace storico invariati |
| CI run `30580693884` | 0 | PASS | SHA `e2ad429f…`, 3/3 job e tutti gli step `success`, zero annotation |

### Gate Flutter locale

`bash scripts/check.sh` ha prodotto:

- Flutter `3.44.8` verificato;
- action pin e governance verificati;
- `dart format`: 40 file, 0 modificati;
- `flutter analyze`: nessuna issue;
- `flutter test`: 59 test, tutti superati;
- `flutter build apk --debug`: artifact costruito;
- `flutter build ios --simulator --debug`: artifact costruito.

Build artifact, coverage e log completi restano locali e non sono versionati. Gli smoke
Android Emulator e iOS Simulator sono `NOT_RUN` perché TASK-003 modifica soltanto
documenti e governance e non introduce comportamento runtime; non sono gate previsti dai
22 test del task. Le due build reali restano verifiche distinte e sono `PASS`.

### Dependency audit

`flutter pub outdated` ha segnalato versioni più recenti, incluse major di Riverpod, ma
non vulnerabilità né risoluzioni rotte. `pubspec.yaml` e `pubspec.lock` non cambiano:
un upgrade sarebbe fuori scope e non viene applicato.

## Integrità esterna

Ricalcolo read-only finale:

| Fonte | Stato finale |
|---|---|
| Android | status `22b76cb8…`, content `663126bab…`, invariati |
| iOS | status `38a40f3a…`, content `5523e8b9…`, invariati |
| Admin | status `76d58e31…`, content `c991533c…`, invariati |
| Win7POS | status `a8ba743e…`, content `4aeda6ea…`, invariati |
| Supabase storico | manifest `73885069…`, 425 file, 18 migration, 0 function file, invariato |

I valori completi, l'algoritmo e i dirty record preesistenti sono in
`external-integrity.md`. Le sole operazioni Supabase remote sono state list e
introspection sanitizzate; nessun apply, deploy, SQL mutativo, branch change o modifica
Auth/Storage.

## CI Execution

Il workflow manuale `CI` run `30580693884` è stato eseguito sul commit tecnico esatto
`e2ad429f25341f9009c3087673c36746e23bf059`:

| Job | Durata | Esito | Annotation |
|---|---:|---|---:|
| Quality | 2m04s | PASS | 0 |
| Android debug build | 7m25s | PASS | 0 |
| iOS Simulator debug build | 4m06s | PASS | 0 |

Tutti gli step dei tre job risultano `completed/success`. Il closeout dovrà comunque
eseguire una nuova CI sul proprio SHA conclusivo prima di considerare soddisfatto il gate
finale del task.

## Warning e rischi residui

- Il dominio Storefront è un contratto logico, non uno schema o un'API implementata.
- I grant `anon` legacy osservati su superfici operative non costituiscono una
  autorizzazione; hardening e verifica fisica restano in TASK-005.
- Il workspace Supabase storico non-Git resta sola provenance e contiene un basename
  migration non ricorrente nell'Admin; un confronto semantico futuro è fuori scope.
- La readiness backend, il health probe e la configurazione ambienti restano
  rispettivamente in TASK-011 e TASK-004.
- Le versioni package più recenti disponibili non vengono introdotte in un task
  documentale.

Nessun warning rende incompleto un gate Execution. La review indipendente resta
obbligatoria e non deve assumere corretti i claim dell'Executor.
