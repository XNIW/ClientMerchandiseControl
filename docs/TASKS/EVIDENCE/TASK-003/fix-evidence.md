# Fix evidence — TASK-003

## Identità e scope

- **Revisione che ha aperto i finding**:
  `769a30fc6c465c663ed5a9491dd099a830ce2128`
- **Commit di transizione a Fix**:
  `54febf4`
- **Commit tecnico Fix verificato**:
  `f0e4aae8d4a24806707bd0b4f672d9c9a02a241d`
- **Scope**: esclusivamente `T003-REV-001`–`T003-REV-003`
- **Tipo**: documentale; nessuna modifica runtime, config, backend o sistema esterno

Il Fix non riscrive la Review e non approva le proprie correzioni. I finding restano
formalmente aperti fino alla re-review indipendente.

## Correzioni e regressioni

| Finding | Correzione | Regression check del Fix |
|---|---|---|
| `T003-REV-001` P2 | La matrice dichiara lo split permanente: Client owner del contratto logico, Admin owner dell'artifact machine-readable, con conformance bidirezionale obbligatoria. | Confronto fra matrice, metadata del contratto e ADR-010: `PASS`; nessun testo rende temporanea l'ownership logica Client. |
| `T003-REV-002` P2 | TASK-004 resta limitato a environment strategy, callback e configurazione fail-closed senza fallback cross-environment; discovery e binding di `shop_id`, con validazione server-side, appartengono a TASK-010. | Confronto L1/L4, mapping, Master Plan e non-scope: `PASS`; nessuna assegnazione di shop discovery/binding a TASK-004. |
| `T003-REV-003` P3 | Ristretto il claim sulla CI migration e aggiunti locator diretti per bucket privato e trasporto POS. | Validator file/range e controllo semantico mirato: `PASS`, 59/59 locator validi. |

Il diff tecnico è limitato a:

- `docs/ARCHITECTURE/CROSS-REPO-OWNERSHIP.md`;
- `docs/ARCHITECTURE/STOREFRONT-INTEGRATION-CONTRACT.md`;
- `docs/TASKS/EVIDENCE/TASK-003/source-audit.md`.

## Gate eseguiti

| Gate/comando | Exit | Esito | Risultato pertinente |
|---|---:|---|---|
| regression ownership/ADR | 0 | PASS | split permanente e conformance reciproca coerenti |
| regression TASK-004/TASK-010 | 0 | PASS | config ambientale separata da discovery/binding shop |
| validator provenance read-only | 0 | PASS | 59/59 locator; Client 5, Admin 13, Android 17, iOS 10, POS 9, storico 5 |
| controllo semantico dei tre claim P3 | 0 | PASS | CI migration, bucket privato e trasporto POS supportati dai locator |
| `git diff --check 54febf4..f0e4aae` | 0 | PASS | zero errore whitespace |
| scan secret/URL/config/artifact sul diff Fix | 0 | PASS | zero pattern sensibile e zero artifact |
| confinement del diff Fix | 0 | PASS | tre file documentali autorizzati; zero runtime/config/backend |
| fingerprint fonti esterne | 0 | PASS | quattro repository Git e manifest storico invariati |
| `bash scripts/check.sh` | 0 | PASS | format 40/40, analyze pulito, 59/59 test, build Android e iOS |
| CI run `30583398168` | 0 | PASS | SHA esatto `f0e4aae…`, 3/3 job, tutti gli step success, zero annotation |

Gli smoke Android/iOS sono `NOT_RUN`: il Fix cambia soltanto documenti e non introduce
comportamento runtime. Le build reali Android debug e iOS Simulator debug sono
verifiche distinte e risultano `PASS` sia localmente sia in CI.

## Deviazioni diagnostiche

- Il primo script di regressione ownership ha prodotto `FAIL` perché cercava
  l'etichetta italiana `Owner logico`, mentre il documento usa il metadata label
  inglese. Il controllo è stato corretto sull'etichetta reale e ripetuto con `PASS`;
  nessuna modifica prodotto è stata necessaria.
- Il primo controllo P3 del Fixer ha prodotto `FAIL` perché cercava i comandi Admin
  inesistenti `supabase db reset` e `pg_prove`. È stato corretto sui comandi realmente
  citati, `supabase start` e `supabase test db`, e ripetuto integralmente con `PASS`.

Entrambi i fallimenti erano difetti dei controlli diagnostici, non del deliverable; sono
registrati per non trasformare retroattivamente un comando eseguito in un `PASS`.

## CI del Fix

Il workflow `CI` run `30583398168` ha verificato il commit tecnico esatto
`f0e4aae8d4a24806707bd0b4f672d9c9a02a241d`:

| Job | Durata | Esito | Annotation |
|---|---:|---|---:|
| Quality | 1m55s | PASS | 0 |
| Android debug build | 9m38s | PASS | 0 |
| iOS Simulator debug build | 3m25s | PASS | 0 |

Tutti gli step risultano `completed/success`.

## Handoff

- **Transizione**: `FIX -> REVIEW`
- **Handoff**: `CODEX_FIX_COMPLETE_TO_RE_REVIEW`
- **Prossimo ruolo**: `CODEX_RE_REVIEWER`
- **Verifica richiesta**: chiusura autonoma di ciascun finding, riesecuzione dei gate
  impattati e controllo dell'intera matrice CA/test
- **Auto-approvazione**: vietata e non eseguita
- **Merge e TASK-004**: vietati fino a re-review `APPROVED`, applicazione esplicita
  dell'autorizzazione utente e closeout verde
