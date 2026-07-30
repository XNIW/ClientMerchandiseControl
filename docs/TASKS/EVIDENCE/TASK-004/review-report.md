# TASK-004 — Review indipendente

## Esito

- **Revisione verificata**:
  `fb9724da29e7222e886c047c24fa7d3cd360fca0`
- **Ruolo**: `CODEX_REVIEWER`
- **Modalità**: tre sessioni read-only indipendenti dall'Executor
- **Esito**: `CHANGES_REQUIRED`
- **Finding**: 0 P0, 0 P1, 3 P2, 1 P3
- **Handoff**: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`

Gli shard hanno verificato separatamente semantica di configurazione/bootstrap,
security/confinement e governance/evidence/CI. Lo shard security originario è stato
interrotto perché non terminava una verifica; nessun suo claim è stato usato. Una
sessione sostitutiva bounded ha rieseguito i controlli sullo stesso commit senza
modificare file o leggere la configurazione locale.

## Finding

### T004-REV-001 — P2 — OPEN — Callback non byte-esatta

- **Posizione**: `lib/core/config/app_config.dart:29`, `:194`
- **Descrizione**: `AUTH_REDIRECT_URI` attraversa `_normalize`, che applica `trim`
  prima del confronto con la callback consentita. Whitespace iniziale o finale viene
  quindi accettato nonostante il requisito di coincidenza esatta.
- **Riproduzione**: il test compile-time corrente con callback staging circondata da
  spazi termina exit 0.
- **Impatto**: la validazione non è fail-closed rispetto a CA-13.
- **Correzione richiesta**: validare il valore raw presente, distinguendo soltanto la
  stringa realmente vuota dall'URI valorizzato; non normalizzare la callback.
- **Regression check**: callback esatta `PASS`; leading/trailing/newline e
  whitespace-only `FAIL` in staging/production; ogni callback presente `FAIL` in
  development.

### T004-REV-002 — P2 — OPEN — Bootstrap production autorizzato

- **Posizione**: `lib/core/backend/supabase_bootstrap.dart:18-26`
- **Descrizione**: il guard esclude soltanto development. Una configurazione
  production completa chiama quindi l'initializer e ritorna `ready`, mentre la
  matrice TASK-004 ammette l'inizializzazione SDK esclusivamente in staging.
- **Impatto**: un build production può attraversare il confine remoto prima
  dell'autorizzazione, contraddicendo la baseline fail-closed.
- **Correzione richiesta**: consentire l'initializer soltanto in staging e fallire
  esplicitamente, con errore sanitizzato, in production.
- **Regression check**: production completa produce eccezione e zero chiamate;
  staging completa una chiamata; development zero chiamate.

### T004-REV-003 — P2 — OPEN — Smoke non riproducibile nelle evidence

- **Posizione**:
  `docs/TASKS/EVIDENCE/TASK-004/runtime-smoke.md:5-29`,
  `docs/TASKS/EVIDENCE/TASK-004/execution-evidence.md:37-38`
- **Descrizione**: i due smoke sono marcati `PASS`, ma le evidence non persistono
  comandi esatti, output pertinente riproducibile o screenshot/manifest.
- **Riproduzione**: la ricerca del comando
  `flutter test integration_test/app_shell_smoke_test.dart` e di screenshot/manifest
  nelle evidence TASK-004 restituisce zero match.
- **Impatto**: CA-26, T-21 e T-22 non distinguono i rerun TASK-004 dallo smoke
  preesistente; il gate runtime di `docs/QUALITY-GATES.md` non è provato.
- **Correzione richiesta**: rieseguire Android e iOS sul commit Fix; registrare
  comando esatto, target sanitizzato, risultato 1/1, output pertinente, exit 0,
  screenshot sanitizzati e manifest con digest.
- **Regression check**: lint dell'evidence e rerun dual-platform.

### T004-REV-004 — P3 — OPEN — Intestazioni di fase errate

- **Posizione**: `docs/TASKS/EVIDENCE/TASK-004/README.md:39`, `:72`
- **Descrizione**: le matrici sono intitolate «stato Planning», ma contengono risultati
  Execution e Review.
- **Impatto**: sola precisione della provenance di fase.
- **Correzione richiesta**: rinominare le intestazioni in modo coerente con lo
  snapshot attestato.

## Gate autonomi

| Verifica | Esito | Risultato |
|---|---|---|
| Governance | PASS | unico task `ACTIVE`; fase/handoff Review coerenti |
| Matrici | PASS | 28/28 CA e 27/27 test presenti, univoci e ordinati |
| Test mirati | PASS | config/bootstrap 27/27, exit 0 |
| Analyze/format/diff | PASS | analyze e format mirati; `git diff --check` exit 0 |
| Security/confinement | PASS | zero secret o config locale tracciata; zero OAuth/deep link/shop/query |
| CI tecnica | PASS | run `30588442946`, SHA `9ecffdf…`, 3/3 job, annotation 0/0/0 |
| CI handoff | PASS | run `30589127508`, SHA esatto `fb9724d…`, 3/3 job, tutti gli step success, annotation 0/0/0 |
| Smoke evidence | FAIL | comandi finali e screenshot/manifest non persistiti |

## Valutazione criteri e test

- `CA-10`, `CA-13`, `CA-24`, `CA-26` e `CA-27`: `FAIL`.
- `T-08`, `T-12`, `T-13`, `T-21`, `T-22` e `T-26`: `FAIL`.
- Gli altri criteri e test mantengono l'evidence `PASS` verificata autonomamente.
- `T004-REV-004` è non bloccante, ma è incluso nel Fix perché riproducibile e nello
  scope documentale.

## Handoff a Fix

- **Transizione**: `REVIEW -> FIX`
- **Prossimo ruolo**: `CODEX_FIXER`
- **Scope Fix**: esclusivamente `T004-REV-001`–`T004-REV-004`, test di regressione,
  smoke dual-platform ed evidence
- **Re-review obbligatoria**: sì, in nuove sessioni read-only
- **PR/merge**: vietati finché il Fix non torna a Review e la re-review non è
  `APPROVED`
