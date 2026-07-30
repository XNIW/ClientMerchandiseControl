# TASK-003 — Review report

## Esito

- **Revisione**:
  `769a30fc6c465c663ed5a9491dd099a830ce2128`
- **Ruolo**: `CODEX_REVIEWER`
- **Modalità**: tre sessioni read-only indipendenti dall'Executor
- **Esito**: `CHANGES_REQUIRED`
- **Finding**: 0 P0, 0 P1, 2 P2, 1 P3
- **Handoff**: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`

Gli shard hanno verificato separatamente architettura/contratto,
governance/evidence/CI e security/provenance. Il finding sul binding shop è stato
rilevato indipendentemente da due shard ed è consolidato una sola volta.

## Finding

### T003-REV-001 — P2 — OPEN — Ownership logica resa temporanea

- **Posizione**: `docs/ARCHITECTURE/CROSS-REPO-OWNERSHIP.md:47`
- **Descrizione**: la matrice assegna il contratto ad Admin e mantiene il contratto
  logico nel Client soltanto «finché TASK-010» pubblicherà l'artifact fisico.
- **Evidenza**:
  `docs/ARCHITECTURE/STOREFRONT-INTEGRATION-CONTRACT.md:11-20` e
  `docs/DECISIONS/ADR-010-storefront-contract-ownership.md:34-36,55-58` definiscono
  invece uno split permanente: contratto logico Client, artifact server
  machine-readable Admin.
- **Impatto**: dopo TASK-010 l'authority logica diventa ambigua, violando CA-06/CA-11
  e consentendo drift nel change protocol.
- **Correzione richiesta**: dichiarare lo split permanente Client-logical /
  Admin-machine-readable e la conformance bidirezionale obbligatoria.
- **Regression check**: confrontare riga ownership, metadata del contratto e ADR-010;
  nessun testo deve subordinare a TASK-010 l'ownership logica Client.

### T003-REV-002 — P2 — OPEN — Shop binding assegnato fuori scope a TASK-004

- **Posizione**:
  `docs/ARCHITECTURE/STOREFRONT-INTEGRATION-CONTRACT.md:397`
- **Descrizione**: il mapping assegna a TASK-004 il «binding fail-closed del singolo
  shop».
- **Evidenza**: le righe 100-102 dello stesso contratto assegnano serializzazione,
  trasporto e discovery di `shop_id` a L4/TASK-010 ed escludono un nuovo flag
  compile-time in TASK-004. Il Master Plan limita TASK-004 ad ambienti e configuration
  contract.
- **Impatto**: induce scope creep immediato in TASK-004 e rende ambiguo il confine che
  il contratto dovrebbe proteggere.
- **Correzione richiesta**: limitare TASK-004 ad environment strategy, callback e
  configurazione fail-closed senza fallback cross-environment; lasciare
  discovery/binding shop a L4/TASK-010 con validazione server-side.
- **Regression check**: eseguire
  `git grep -n -E 'TASK-004.*shop|shop.*TASK-004|binding fail-closed'` e confrontare
  L1/L4, mapping, Master Plan e non-scope.

### T003-REV-003 — P3 — OPEN — Locator di provenance migliorabili

- **Posizioni**:
  `docs/TASKS/EVIDENCE/TASK-003/source-audit.md:85-87,98-100,250-251`
- **Descrizione**: i claim sono corretti, ma i range adiacenti non provano
  direttamente il conteggio di 96 migration, la privatezza del bucket e l'unicità del
  trasporto POS.
- **Impatto**: sola navigabilità e riproducibilità dell'evidence; nessun errore
  architetturale o rischio runtime.
- **Correzione richiesta**: aggiungere locator diretti già verificati o restringere i
  qualificatori; includere il contract immagini Admin e l'architettura POS.
- **Regression check**: rieseguire il validator file/range e il controllo semantico
  mirato dei tre claim.

## Gate autonomi

| Verifica | Esito | Risultato |
|---|---|---|
| Governance | PASS | `ACTIVE / REVIEW / CODEX_EXECUTION_COMPLETE_TO_REVIEW` |
| DAG/backlog | PASS | 42 nodi, zero cicli, un solo `ACTIVE`, sole tre dipendenze autorizzate |
| Matrici | PASS | 32/32 CA e 22/22 test presenti, univoci e ordinati |
| Citazioni | PASS | 57/57 locator risolti e claim semanticamente coerenti |
| Integrità esterna | PASS | quattro fingerprint Git e manifest storico ricreati e identici |
| Security/confinement | PASS | zero secret/URL/ref completo/artifact; zero runtime/config/backend |
| Supabase read-only | PASS | un progetto dev, branch `main`, 96 migration, 0 Edge Functions, UUID e grant/RLS confermati |
| Diff/link | PASS | `git diff --check` e link locali; worktree pulito |
| CI Execution | PASS | run `30580693884`, SHA `e2ad429f`, 3/3 job e 0 annotation |
| CI revisione | PASS | run `30581659849`, SHA `769a30f`, 3/3 job, tutti gli step success e 0 annotation |

Un primo comando `rg` dello shard architetturale è fallito per quoting dei backtick; è
stato corretto e ripetuto con exit 0. Non ha invalidato né saltato alcuna verifica.

## Valutazione criteri e test

- `CA-06`, `CA-11` e `CA-27`: `FAIL` per i due P2.
- `CA-31`: `FAIL`, perché restano due P2 aperti.
- `T-04`, `T-06`, `T-15` e `T-20`: `FAIL`.
- Gli altri criteri e test mantengono l'evidence `PASS` registrata dall'Execution e
  verificata autonomamente.
- Il P3 non bloccherebbe da solo CA-31, ma viene consegnato al Fixer perché è
  riproducibile e nello scope documentale.

## Handoff a Fix

- **Transizione**: `REVIEW -> FIX`
- **Prossimo ruolo**: `CODEX_FIXER`
- **Scope Fix**: esclusivamente `T003-REV-001`–`T003-REV-003`, regression check e
  aggiornamento evidence
- **Re-review obbligatoria**: sì, in una nuova sessione
- **Merge e TASK-004**: vietati finché il Fix non torna a Review e la re-review non è
  `APPROVED`
