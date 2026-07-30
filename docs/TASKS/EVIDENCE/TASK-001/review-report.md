# Report della review indipendente iniziale — TASK-001

## Esito

- **Verdetto**: `CHANGES_REQUIRED`
- **Distribuzione**: 0 P0, 3 P1, 8 P2, 3 P3.
- **Commit revisionato**: `83b855728f5cf3192f7f1daa1e37b787440423a9`.
- **Regola**: ogni finding resta aperto fino a correzione verificata e re-review.

## Catalogo finding

### REV-001 — P1 — Governance Codex-only assente

- **Stato**: OPEN
- **Posizione**: `AGENTS.md`, `CLAUDE.md`, `docs/MASTER-PLAN.md`,
  `docs/CODEX-EXECUTION-PROTOCOL.md` e documenti collegati.
- **Evidenza**: responsabilità operative assegnate a Claude/ChatGPT, file
  `CLAUDE.md` attivo, ruoli Codex incompleti e assenza di CA-22/T-23.
- **Impatto**: handoff non deterministico e dipendenza da agenti esterni al workflow
  approvato.
- **Correzione richiesta**: consolidare una governance esclusivamente Codex, migrare il
  protocollo, aggiornare riferimenti e aggiungere controlli di regressione statici.
- **Test di regressione**: T-23 e ricerca dei riferimenti operativi vietati.
- **Commit di risoluzione**: da registrare.

### REV-002 — P1 — Contratto zh-Hans e risoluzione locale errati

- **Stato**: OPEN
- **Posizione**: `lib/l10n/app_zh.arb`,
  `lib/app/client_merchandise_control_app.dart`, `ios/Runner/Info.plist`,
  `ios/Runner.xcodeproj/project.pbxproj`.
- **Evidenza**: il cinese semplificato è dichiarato come `zh`; la risoluzione considera
  soltanto la lingua e i metadata iOS non dichiarano le localizzazioni supportate.
- **Impatto**: utenti zh-Hant possono ricevere testi semplificati e iOS non espone
  correttamente le lingue.
- **Correzione richiesta**: usare `zh-Hans`, matching script-aware e metadata nativi
  coerenti.
- **Test di regressione**: zh-Hans supportato; zh-Hant non mappato a semplificato;
  fallback spagnolo verificato.
- **Commit di risoluzione**: da registrare.

### REV-003 — P1 — Chiavi Supabase privilegiate o arbitrarie accettate

- **Stato**: OPEN
- **Posizione**: `lib/core/config/app_config.dart`,
  `lib/core/bootstrap/supabase_bootstrap.dart`.
- **Evidenza**: qualunque stringa non vuota può essere trattata come publishable key.
- **Impatto**: una configurazione errata può incorporare nel client una chiave
  `service_role`, `sb_secret_` o non classificata.
- **Correzione richiesta**: allowlist di `sb_publishable_` e JWT con ruolo `anon`;
  rifiutare fail-closed ogni formato privilegiato o sconosciuto.
- **Test di regressione**: casi publishable/anon validi e secret/service-role/arbitrari
  rifiutati.
- **Commit di risoluzione**: da registrare.

### REV-004 — P2 — La risoluzione locale ignora le preferenze successive

- **Stato**: OPEN
- **Posizione**: `lib/app/client_merchandise_control_app.dart`.
- **Evidenza**: la callback usa soltanto la prima locale preferita.
- **Impatto**: una lista come `[de, it]` ricade in spagnolo invece di selezionare
  l'italiano supportato.
- **Correzione richiesta**: scorrere tutte le preferenze in ordine.
- **Test di regressione**: lista multi-locale con prima voce non supportata.
- **Commit di risoluzione**: da registrare.

### REV-005 — P2 — Parsing configurazione non sufficientemente fail-closed

- **Stato**: OPEN
- **Posizione**: `lib/core/config/app_config.dart`,
  `lib/core/config/app_environment.dart`.
- **Evidenza**: URL con userinfo, query, fragment o path sono accettati; `APP_ENV`
  esplicitamente vuoto equivale a development.
- **Impatto**: configurazioni ambigue o non canoniche possono raggiungere il bootstrap.
- **Correzione richiesta**: accettare soltanto origin HTTPS canoniche e distinguere
  default assente da valore esplicitamente vuoto.
- **Test di regressione**: matrice URL e ambiente vuoto.
- **Commit di risoluzione**: da registrare.

### REV-006 — P2 — Test offline non dimostra l'assenza di inizializzazione rete

- **Stato**: OPEN
- **Posizione**: `lib/core/bootstrap/supabase_bootstrap.dart`,
  `test/core/bootstrap/supabase_bootstrap_test.dart`.
- **Evidenza**: il test controlla soltanto l'enum restituito.
- **Impatto**: una regressione potrebbe inizializzare Supabase anche in modalità offline.
- **Correzione richiesta**: introdurre una seam d'inizializzazione e verificare zero
  chiamate offline, una chiamata con argomenti esatti quando configurato.
- **Test di regressione**: spy deterministico senza rete.
- **Commit di risoluzione**: da registrare.

### REV-007 — P2 — Back di sistema esce da una destinazione secondaria

- **Stato**: OPEN
- **Posizione**: `lib/features/shell/presentation/app_shell_screen.dart`.
- **Evidenza**: la shell non intercetta il back quando è selezionata una tab secondaria.
- **Impatto**: comportamento inatteso e rischio di uscita accidentale dall'app.
- **Correzione richiesta**: il primo back deve tornare alla Home; soltanto dalla Home
  può propagarsi.
- **Test di regressione**: navigazione secondaria e `handlePopRoute`.
- **Commit di risoluzione**: da registrare.

### REV-008 — P2 — Semantica duplicata nell'header

- **Stato**: OPEN
- **Posizione**: `lib/features/shell/presentation/feature_placeholder.dart`.
- **Evidenza**: icona e testo espongono entrambi lo stesso titolo semantico.
- **Impatto**: screen reader può annunciare due volte il nome della schermata.
- **Correzione richiesta**: rendere decorativa l'icona e mantenere una sola etichetta.
- **Test di regressione**: conteggio dei nodi semantici per il titolo.
- **Commit di risoluzione**: da registrare.

### REV-009 — P2 — Copertura widget incompleta e un'asserzione falsamente positiva

- **Stato**: OPEN
- **Posizione**: `test/app/client_merchandise_control_app_test.dart`,
  `test/features/shell/app_shell_screen_test.dart`.
- **Evidenza**: `Cuenta` è sempre visibile nella navigation bar; mancano test per tutte
  le destinazioni, lingue, tema scuro, text scale, layout e fallback.
- **Impatto**: regressioni UI/localizzazione possono superare la suite.
- **Correzione richiesta**: asserire il contenuto della destinazione e ampliare la
  matrice widget/accessibilità.
- **Test di regressione**: suite dedicata ai casi elencati.
- **Commit di risoluzione**: da registrare.

### REV-010 — P2 — Dipendenze GitHub Actions mutabili

- **Stato**: OPEN
- **Posizione**: `.github/workflows/ci.yml`.
- **Evidenza**: `actions/checkout@v7` è un tag mutabile; l'action Flutter pin-nata attiva
  internamente `actions/cache@v5` quando `cache: true`.
- **Impatto**: il codice eseguito in CI può cambiare senza una modifica revisionabile.
- **Correzione richiesta**: SHA completo per checkout e disattivare il percorso cache
  transitivo mutabile; aggiungere una verifica preventiva.
- **Test di regressione**: controllo statico dei riferimenti `uses:`.
- **Commit di risoluzione**: da registrare.

### REV-011 — P2 — Riproducibilità toolchain e quality gate incompleti

- **Stato**: OPEN
- **Posizione**: `.github/workflows/ci.yml`, `scripts/check.sh`,
  `scripts/doctor.sh`.
- **Evidenza**: niente `--enforce-lockfile`, nessun controllo del diff dopo l10n,
  risoluzione Flutter non condivisa e assenza di verifica versione/revisione.
- **Impatto**: build locali e CI possono usare dipendenze o SDK differenti.
- **Correzione richiesta**: resolver Flutter comune, lockfile enforced, l10n diff,
  shell syntax e `git diff --check`.
- **Test di regressione**: esecuzione reale degli script e controllo CI statico.
- **Commit di risoluzione**: da registrare.

### REV-012 — P3 — Il formatter CLP può produrre `-$0`

- **Stato**: OPEN
- **Posizione**: `lib/shared/formatters/clp_currency_formatter.dart`.
- **Evidenza**: il segno è deciso prima dell'arrotondamento.
- **Impatto**: valori negativi con modulo minore di 0,5 mostrano zero negativo.
- **Correzione richiesta**: determinare il segno dopo l'arrotondamento.
- **Test di regressione**: `-0.4` produce `$0`.
- **Commit di risoluzione**: da registrare.

### REV-013 — P3 — Label launcher Android tecnica

- **Stato**: OPEN
- **Posizione**: `android/app/src/main/AndroidManifest.xml`.
- **Evidenza**: label `client_merchandise_control` in snake_case.
- **Impatto**: nome non presentabile nel launcher e task switcher.
- **Correzione richiesta**: risorsa stringa leggibile.
- **Test di regressione**: verifica statica manifest/risorsa.
- **Commit di risoluzione**: da registrare.

### REV-014 — P3 — Hardening nativo e ignore sensibili incompleti

- **Stato**: OPEN
- **Posizione**: `android/gradle/wrapper/gradle-wrapper.properties`,
  `android/app/build.gradle.kts`, `.gitignore`.
- **Evidenza**: manca checksum Gradle; release usa firma debug; ignore non copre comuni
  certificati e file di configurazione mobile.
- **Impatto**: integrità download meno verificabile e rischio di packaging/config locale
  accidentale.
- **Correzione richiesta**: checksum ufficiale, nessuna firma debug per release e ignore
  mirati con eccezioni documentate.
- **Test di regressione**: verifica statica e build debug.
- **Commit di risoluzione**: da registrare.
