# TASK-001 — Repository Governance, Flutter Foundation, CI e Dual-Platform Smoke

## Informazioni generali

- **Task ID**: TASK-001
- **Titolo**: Repository Governance, Flutter Foundation, CI e Dual-Platform Smoke
- **File task**: `docs/TASKS/TASK-001-bootstrap-foundation.md`
- **Stato**: ACTIVE
- **Fase**: FIX
- **Responsabile**: CODEX_FIXER
- **Data creazione**: 2026-07-29
- **Ultimo aggiornamento**: 2026-07-30
- **Ultimo agente**: CODEX_REVIEWER
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-001/`
- **Handoff**: CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX

## Dipendenze

- **Dipende da**: nessuno
- **Sblocca**: TASK-002, TASK-003 e l'intera roadmap

## Scope

- governance, Master Plan, ADR e worklog;
- repository Git/GitHub, branch e Pull Request;
- progetto Flutter con soli target Android/iOS;
- configurazione compile-time senza secret;
- struttura feature-first MVVM, shell e localizzazioni;
- formatter CLP;
- unit/widget test e quality gate;
- Android build, iOS Simulator build e smoke reali su entrambe le piattaforme;
- GitHub Actions ed evidence.
- migrazione della governance operativa a un workflow esclusivamente Codex, con ruoli
  separati per planning, execution, review, fix e re-review.

## Contesto

Il progetto è la nuova app clienti dell'ecosistema Merchandise Control. TASK-001 deve
creare una fondazione reale e compilabile senza collegare backend o dati production.

## Non incluso

- tabelle, migrazioni o query Supabase;
- credenziali o dati reali;
- catalogo, login, immagini, carrello, prenotazioni, ordini, notifiche o pagamenti reali;
- modifiche ad Admin Console, app interne o Win7POS;
- pubblicazione store, bundle registration o signing production;
- deep security scan cross-repo.

## File coinvolti

- governance e documentazione root/`docs/`;
- `pubspec.yaml`, `analysis_options.yaml`, `l10n.yaml`, `config/`;
- `lib/`, `test/`, `android/`, `ios/`;
- `.github/`, `scripts/`, `.gitignore`.

## Criteri di accettazione

| CA | Descrizione | Tipo previsto |
|---|---|---|
| CA-01 | Audit read-only della governance precedente completato e documentato | STATIC |
| CA-02 | File governance richiesti presenti e coerenti | STATIC |
| CA-03 | Master Plan contiene TASK-001–TASK-042, un solo task attivo e nessun task futuro attivo | STATIC |
| CA-04 | Flutter è nella root con soli target Android/iOS | STATIC |
| CA-05 | Identificatori nativi e package Dart sono quelli approvati | STATIC/BUILD |
| CA-06 | Feature-first MVVM, Riverpod, go_router e Supabase Flutter senza dipendenze speculative | STATIC/ANALYZE |
| CA-07 | Config usa APP_ENV, SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY senza valori reali | UNIT/SECURITY |
| CA-08 | Development non configurato si avvia offline senza richieste di rete | UNIT/WIDGET/ANDROID_EMU/IOS_SIM |
| CA-09 | Material 3, ThemeMode.system, responsive UI e l10n es/it/en/zh con fallback spagnolo | WIDGET/STATIC |
| CA-10 | Formatter CLP centralizzato senza decimali; 47100 -> $47.100 | UNIT |
| CA-11 | Shell reale, nessun counter demo, quattro destinazioni localizzate | WIDGET/ANDROID_EMU/IOS_SIM |
| CA-12 | Format, analyze, unit e widget test PASS | FORMAT/ANALYZE/UNIT/WIDGET |
| CA-13 | Android debug build PASS | BUILD_ANDROID |
| CA-14 | iOS Simulator debug build PASS | BUILD_IOS |
| CA-15 | Android Emulator smoke e navigazione con screenshot PASS | ANDROID_EMU |
| CA-16 | iOS Simulator smoke e navigazione con screenshot PASS | IOS_SIM |
| CA-17 | CI esegue quality, Android e iOS Simulator build | CI/STATIC |
| CA-18 | Nessun secret o file locale sensibile versionato | SECURITY/GIT |
| CA-19 | Repository privato, branch, commit e PR esistono | GIT |
| CA-20 | Gli altri repository non sono stati modificati | GIT |
| CA-21 | Task e Master Plan terminano ACTIVE / REVIEW / READY_FOR_REVIEW, mai DONE | STATIC/GIT |
| CA-22 | Governance operativa esclusivamente Codex, senza dipendenze attive da reviewer o agenti esterni | STATIC/GIT |

## Test case

| Test | Criteri | Tipo | Procedura attesa |
|---|---|---|---|
| T-01 | CA-01, CA-20 | STATIC/GIT | Verificare audit, ref e assenza di write esterni |
| T-02 | CA-02, CA-03 | STATIC | Verificare file e un solo `ACTIVE` |
| T-03 | CA-04, CA-05 | STATIC | Verificare target, package e bundle ID |
| T-04 | CA-06 | STATIC/ANALYZE | Verificare struttura e dipendenze |
| T-05 | CA-07 | UNIT | Development senza config |
| T-06 | CA-07 | UNIT | Staging/production validi |
| T-07 | CA-07 | UNIT | Production incompleta rifiutata |
| T-08 | CA-07 | UNIT | URL non valido rifiutato |
| T-09 | CA-10 | UNIT | Formattare 47100, negativi e null |
| T-10 | CA-08, CA-09 | WIDGET | Avviare app senza backend in spagnolo |
| T-11 | CA-11 | WIDGET | Verificare quattro destinazioni e assenza counter |
| T-12 | CA-11 | WIDGET | Navigare tra destinazioni preservando la shell |
| T-13 | CA-12 | FORMAT | Eseguire format check |
| T-14 | CA-12 | ANALYZE | Eseguire `flutter analyze` |
| T-15 | CA-12 | UNIT/WIDGET | Eseguire `flutter test --coverage` |
| T-16 | CA-13 | BUILD_ANDROID | Eseguire build APK debug |
| T-17 | CA-14 | BUILD_IOS | Eseguire build iOS Simulator debug |
| T-18 | CA-15 | ANDROID_EMU | Avvio, home, navigazione e screenshot Android |
| T-19 | CA-16 | IOS_SIM | Avvio, home, navigazione e screenshot iOS |
| T-20 | CA-17 | CI | Validare ed eseguire GitHub Actions |
| T-21 | CA-18 | SECURITY | Secret/artifact scan mirato |
| T-22 | CA-19, CA-21 | GIT | Verificare remote privato, branch, commit, PR e tracking |
| T-23 | CA-22 | STATIC/GIT | Verificare ruoli Codex, stati, handoff e assenza di riferimenti operativi attivi a sistemi esterni |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | User-approved bootstrap override: il prompt iniziale contiene il planning completo e autorizza Codex a trascriverlo ed eseguire TASK-001. L'override non si applica ai task successivi. | Consentire il primo bootstrap senza violare la governance futura | ATTIVA |
| D-02 | Flutter stable, una codebase e soli target Android/iOS | Vincolo architetturale approvato | ATTIVA |
| D-03 | Development senza backend resta offline; production incompleta fallisce | Evitare fallback e rete accidentale | ATTIVA |
| D-04 | Nessun layer vuoto o package speculativo | Fondazione minima e mantenibile | ATTIVA |
| D-05 | L'emendamento utente del 2026-07-30 autorizza la review indipendente completa di TASK-001, la migrazione della governance a un workflow Codex-only e la correzione dei finding P0–P2 e dei P3 semplici in scope. | Rendere esplicito l'override approvato per questa revisione senza modificare backlog, priorità o task futuri | ATTIVA |

## Planning — user override trascritto

### Obiettivo

Creare repository, governance, app Flutter compilabile, configurazione sicura, shell
localizzata, test, CI e smoke reali Android/iOS; consegnare in Review, mai Done.

### Analisi

Il repository parte vuoto e Flutter non era installato. Xcode, Android Studio, Android SDK,
AVD e Simulator iOS sono disponibili. GitHub è autenticato come `XNIW` e il repository
target non esisteva. I repository di riferimento forniscono regole di governance ma non
devono essere modificati.

### Approccio

1. Preflight e audit read-only.
2. Seed sicuro di `main` e branch TASK-001.
3. Installazione Flutter stable ufficiale e doctor.
4. Governance e documentazione.
5. Generazione Flutter e implementazione minima.
6. Test, build, smoke, security e CI.
7. Evidence, tracking, commit, push e PR.

### Rischi

- download/toolchain lenti: usare tentativi limitati e documentare;
- incompatibilità CocoaPods/Xcode: correggere soltanto senza password o major upgrade;
- emulator/simulator instabile: avvio deterministico, boot check e stop-on-failure;
- CI esterna: distinguere failure introdotta da quota/policy.

### Handoff a Execution

- **Prossima fase**: EXECUTION
- **Prossimo agente**: CODEX_EXECUTOR (ruolo normalizzato dall'emendamento Codex-only)
- **Azione**: eseguire il piano approvato e produrre evidence per CA-01–CA-21.

## Execution — Codex

### Obiettivo compreso

Costruire e verificare la fondazione concreta senza backend o dati reali, mantenendo un
unico writer e consegnando TASK-001 in Review.

### File controllati

- prompt bootstrap completo;
- ref governance elencati nell'audit;
- inventario ambiente, repository locale e stato GitHub.

### Piano minimo

In esecuzione secondo l'Approccio approvato.

### Modifiche fatte

- Creati repository privato, seed `main` e branch TASK-001.
- Create governance, Master Plan, ADR, documentazione prodotto/architettura e task.
- Installata Flutter stable 3.44.8 e completata la toolchain Android/iOS.
- Generata una sola app Flutter con target Android/iOS e identificatori approvati.
- Implementate configurazione compile-time fail-closed, bootstrap Supabase offline,
  shell Riverpod/go_router, Material 3, tema di sistema e localizzazioni es/it/en/zh.
- Implementati formatter CLP, unit/widget test, script di verifica e CI.
- Eseguiti build e smoke reali su Android Emulator e iOS Simulator.
- Creati evidence, commit, push e PR; nessun merge o auto-merge.

### Check eseguiti

`flutter doctor -v`, format, analyze, 16 test, build Android, build iOS Simulator,
smoke Android/iOS, security scan e tre job GitHub Actions sono `PASS`. I risultati
sanitizzati sono consolidati in
`docs/TASKS/EVIDENCE/TASK-001/commands-and-results.md`.

### Matrice CA -> evidence

Tutti i criteri CA-01–CA-21 risultano `PASS`; vedere
`docs/TASKS/EVIDENCE/TASK-001/README.md`.

### Matrice T-NN -> risultato

Tutti i test case T-01–T-22 risultano `PASS`; vedere
`docs/TASKS/EVIDENCE/TASK-001/README.md`.

### Rischi rimasti

Branding e design definitivi, contratto Storefront, ambienti reali e backend restano
fuori scope e sono assegnati ai task futuri. Nessun blocker di TASK-001 è attivo.

### Handoff a Review

- **Prossima fase**: REVIEW
- **Prossimo agente storico**: reviewer indipendente previsto dalla governance precedente;
  riferimento conservato a fini cronologici e non più operativo
- **Azione**: verificare CA-01–CA-21 e T-01–T-22 contro le evidence; non attivare TASK-002.

## Review — Codex reviewer indipendente

### Esito iniziale

- **Data**: 2026-07-30
- **Agente**: CODEX_REVIEWER
- **Verdetto**: CHANGES_REQUIRED
- **Finding**: 0 P0, 3 P1, 8 P2 e 3 P3.
- **Evidence**:
  `docs/TASKS/EVIDENCE/TASK-001/review-baseline.md`,
  `docs/TASKS/EVIDENCE/TASK-001/review-report.md`,
  `docs/TASKS/EVIDENCE/TASK-001/review-security-check.md` e
  `docs/TASKS/EVIDENCE/TASK-001/review-commands-and-results.md`.

La baseline dichiarata dall'Execution è stata rieseguita con esito `PASS`, inclusi i
build Android e iOS Simulator. La review statica e di sicurezza ha però rilevato gap
funzionali, di fail-closed, accessibilità, riproducibilità CI e governance. I finding
sono registrati prima di qualsiasi correzione.

### Handoff a Fix

- **Prossima fase**: FIX
- **Prossimo agente**: CODEX_FIXER
- **Azione**: correggere tutti i finding P1/P2 e i P3 semplici in scope, aggiungere test
  di regressione e restituire TASK-001 a una nuova review indipendente.

## Fix — Codex

- **Stato**: IN_PROGRESS
- **Data avvio**: 2026-07-30
- **Agente**: CODEX_FIXER
- **Scope**: esclusivamente finding e migrazione governance autorizzati dalla review di
  TASK-001; nessuna attivazione di TASK-002.

## Chiusura

- **Conferma utente**: non ancora ricevuta
- **Follow-up candidate**: TASK-002, non attivato
- **Riepilogo finale**: fondazione Flutter e governance consegnate a review con gate locali,
  smoke dual-platform e CI superati
- **Data completamento**: non applicabile
