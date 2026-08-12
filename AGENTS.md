# Istruzioni operative Codex

`AGENTS.md` è l'unico file di istruzioni operativo alla radice del repository. Il
protocollo dettagliato è `docs/CODEX-WORKFLOW-PROTOCOL.md`.

## Lingua e contesto

Codex comunica, pianifica, documenta e produce gli handoff in italiano. Restano in
inglese soltanto identificatori tecnici, API, comandi, nomi imposti dagli strumenti e
testi applicativi richiesti dalle specifiche di localizzazione.

ClientMerchandiseControl è il client Flutter Android/iOS pubblico dell'ecosistema
Merchandise Control. Consuma esclusivamente il futuro dominio Storefront: non accede
direttamente all'inventory operativo e non governa pubblicazione, prezzi o fulfillment.
La codebase è Flutter feature-first MVVM con Riverpod e go_router; Supabase è un confine
remoto futuro protetto server-side.

## Fonti di verità e ordine di lettura

Prima di pianificare, modificare o revisionare, leggere nell'ordine:

1. `docs/MASTER-PLAN.md`;
2. il file del task `ACTIVE` indicato dal Master Plan;
3. `docs/CODEX-WORKFLOW-PROTOCOL.md`;
4. codice, test, evidence e documenti pertinenti.

Il Master Plan governa roadmap, backlog e task attivo. Il file task governa scope, fase,
criteri, decisioni e handoff. Una divergenza va segnalata e riallineata prima di
proseguire. Può esistere un solo task `ACTIVE`; Codex non attiva autonomamente un task
successivo e non modifica task futuri, priorità o backlog senza autorizzazione
dell'utente.

## Deroga autorizzata — Storefront v1 release train

Per il solo release train `STOREFRONT_V1`, l'istruzione utente del 2026-08-01 è
un'autorizzazione esplicita e persistente a pianificare ed eseguire in continuità i task
elencati nel relativo manifest, senza una nuova conferma fra task o milestone. La deroga
è governata da `ADR-011` e termina con il closeout del release train.

- resta consentito un solo task `ACTIVE / EXECUTION` alla volta;
- più task completati tecnicamente possono essere
  `VALIDATED_PENDING_INTEGRATED_REVIEW`;
- il checkpoint di milestone esegue gate tecnici, ma non è una review e non assegna
  `APPROVED`;
- nessun task del train diventa `DONE` prima della review integrata finale;
- le Pull Request coordinate restano draft e non merged durante l'Execution;
- la review integrata e l'eventuale re-review sono svolte da reviewer read-only distinti
  dall'unico writer;
- l'autorizzazione utente già ricevuta copre il passaggio finale a `DONE` e i merge
  normali soltanto dopo review integrata `APPROVED`, CI e gate reali verdi;
- blocker esterni e gate non eseguiti restano `BLOCKED` o `NOT_RUN`, mai `PASS`.

Questa deroga non autorizza force push, modifiche production anticipate, rollout oltre
il 5%, spesa, accordi legali, dati reali nelle evidence o qualunque azione fuori dallo
scope Storefront v1.

## Ruoli logici

I ruoli sono svolti dallo stesso prodotto Codex, ma hanno responsabilità separate e,
per review e re-review, preferibilmente sessioni distinte.

### `CODEX_PLANNER`

- opera soltanto in `PLANNING`;
- definisce obiettivo, scope, non incluso, criteri di accettazione, test, rischi e piano;
- non implementa e non dichiara risultati;
- registra `CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION` e attende l'utente.

### `CODEX_EXECUTOR`

- opera soltanto in `EXECUTION` su planning approvato;
- implementa senza cambiare scope, criteri o priorità;
- esegue i gate applicabili e produce evidence reale;
- consegna a `REVIEW` con `CODEX_EXECUTION_COMPLETE_TO_REVIEW`;
- non approva il proprio lavoro e non marca `DONE`.

### `CODEX_REVIEWER`

- opera soltanto in `REVIEW`, preferibilmente in una nuova sessione;
- non assume corretti i `PASS` dell'executor: confronta intent, criteri, diff, evidence e
  comportamento reale ed esegue verifiche autonome;
- produce finding riproducibili con severità, impatto, correzione e test di regressione;
- dichiara soltanto `APPROVED`, `CHANGES_REQUIRED`, `REJECTED` o `BLOCKED`;
- non modifica l'implementazione durante la review, non marca `DONE` e non esegue merge.

### `CODEX_FIXER`

- opera soltanto in `FIX`;
- corregge esclusivamente finding approvati o problemi già dentro lo scope;
- aggiunge test di regressione quando necessari e aggiorna le evidence;
- riconsegna sempre a `REVIEW` con `CODEX_FIX_COMPLETE_TO_RE_REVIEW`;
- non approva autonomamente i propri fix.

### `CODEX_RE_REVIEWER`

- opera in `REVIEW` dopo un ciclo di `FIX`, preferibilmente in una sessione distinta dal
  fixer;
- verifica la risoluzione di ogni finding e riesegue i gate impattati e quelli obbligatori;
- applica le stesse regole e gli stessi esiti di `CODEX_REVIEWER`;
- non corregge il proprio finding, non marca `DONE` e non esegue merge.

### `USER_APPROVER`

Soltanto l'utente può autorizzare una modifica sostanziale dello scope, il passaggio
finale a `DONE`, il merge della Pull Request e l'attivazione del task successivo.
Per `STOREFRONT_V1` tale autorizzazione è già registrata dal prompt del 2026-08-01 ed è
condizionata ai gate reali e alla review integrata `APPROVED` descritti in `ADR-011`.

La separazione tra autore e reviewer è almeno logica: chi ha operato come executor o
fixer non può approvare nello stesso ruolo il proprio lavoro. Se non è possibile ottenere
una sessione distinta, la review deve dichiararlo come limite e restare basata su
verifiche indipendenti, mai sui claim precedenti.

## Stati, transizioni e handoff

- Stato progetto: `IDLE` o `ACTIVE`.
- Stato task ordinario: `TODO`, `ACTIVE`, `BLOCKED` o `DONE`.
- Stato task aggiuntivo, soltanto per `STOREFRONT_V1`:
  `VALIDATED_PENDING_INTEGRATED_REVIEW`.
- Fase ordinaria: `PLANNING`, `EXECUTION`, `REVIEW` o `FIX`.
- Fase aggiuntiva, soltanto per `STOREFRONT_V1`: `INTEGRATED_REVIEW`.

Transizioni valide:

- `PLANNING -> EXECUTION`, soltanto dopo autorizzazione utente;
- `EXECUTION -> REVIEW`;
- `REVIEW -> FIX` con `CHANGES_REQUIRED`;
- `FIX -> REVIEW`;
- `REVIEW -> PLANNING` con `REJECTED`;
- `REVIEW -> DONE` soltanto con review `APPROVED` e conferma esplicita dell'utente.

Gli handoff operativi sono:

- planning pronto: `CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION`;
- execution conclusa: `CODEX_EXECUTION_COMPLETE_TO_REVIEW`;
- review con fix: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`;
- fix concluso: `CODEX_FIX_COMPLETE_TO_RE_REVIEW`;
- fix con gate obbligatorio bloccato: `CODEX_FIX_BLOCKED_TO_RE_REVIEW`;
- review respinta: `CODEX_REVIEW_REJECTED_TO_PLANNING`;
- review bloccata: `CODEX_REVIEW_BLOCKED`;
- review approvata: `CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION`.

`APPROVED` non equivale a `DONE`. Nessun ruolo Codex effettua merge o auto-merge.
Per `STOREFRONT_V1` l'unico merge ammesso è quello normale del closeout coordinato dopo
review integrata `APPROVED`, secondo l'autorizzazione utente già registrata.

## Regole per fase

- Il planner modifica Planning, criteri, test e decisioni; non riscrive Execution, Review
  o Fix.
- L'executor modifica Execution e il relativo handoff; non riscrive Planning, Review o
  Decisioni.
- Il reviewer modifica Review e il relativo handoff; non riscrive Planning, Execution,
  Fix o Decisioni.
- Il fixer modifica Fix e il relativo handoff; non riscrive Planning o Review.
- Ogni ruolo aggiorna soltanto i campi globali, Master Plan, worklog e matrici necessari
  alla transizione valida che gli compete.
- Un emendamento dell'utente resta esplicito nelle Decisioni; non si alterano
  silenziosamente criteri per farli passare.
- Sono vietati scope creep, refactor opportunistici e dipendenze speculative. Ogni file
  aggiunto deve avere una responsabilità reale.

Gli override bootstrap ed emendamenti già autorizzati per `TASK-001` restano registrati
nelle Decisioni del task e non si estendono ai task successivi.

## Quality gate ed evidence

Usare tipi, stati e requisiti di handoff definiti in
`docs/CODEX-WORKFLOW-PROTOCOL.md`. Gli unici esiti ammessi sono `PASS`, `FAIL`,
`NOT_RUN` e `BLOCKED`.

- Eseguito non significa inferito: nessun `PASS` senza comando reale, output pertinente
  ed exit code.
- Build e smoke sono verifiche distinte; uno smoke richiede avvio reale e interazione.
- Ogni `NOT_RUN` deve avere un motivo; ogni `BLOCKED` causa, tentativo e prerequisito di
  sblocco.
- Dopo un `FAIL` non eseguire gate dipendenti; quelli indipendenti possono continuare.
- Attendere la conclusione di ogni comando ancora attivo prima dell'handoff o registrarlo
  onestamente come `BLOCKED`/`NOT_RUN`; non terminare lasciando processi di verifica
  irrisolti.
- Aggiornare le matrici CA -> evidence e T-NN -> risultato, indicando file, comandi,
  exit code, rischi, warning e deviazioni.
- L'Execution non è review-ready se un gate obbligatorio è `FAIL`, `BLOCKED` o
  `NOT_RUN`. Dopo `FIX` il task torna comunque a Review: il fixer espone il gate non
  superato e il re-reviewer assegna l'esito coerente, senza inventare `PASS`.

Le evidence persistenti devono essere concise, sanitizzate e appartenere alla revisione
del codice verificata. Log completi e artifact locali non vanno versionati.

## Sicurezza

- Nessun secret, service role, password, token amministrativo, certificato, provisioning
  profile o credenziale privilegiata nel client, nei log, negli screenshot o in Git.
- Nessun dato reale, dato cliente, URL production o migrazione production in task che non
  li autorizzano esplicitamente.
- Configurazione e autorizzazione falliscono in modo chiuso; il client non è un confine
  di autorizzazione.
- Nessuna modifica ai repository di riferimento o ad altri sistemi fuori scope.

## Git e GitHub

- Preservare le modifiche dell'utente e mantenere il lavoro limitato al branch del task.
- Usare stage selettivo e commit atomici e comprensibili.
- Vietati force push, reset distruttivi, amend remoto, merge e auto-merge.
- Non versionare file locali, coverage, build artifact o credenziali.
- Prima dell'handoff verificare diff, tracking, assenza di modifiche fuori scope e
  worktree pulito; se non lo è, documentare il blocco senza cancellare lavoro altrui.
- La Pull Request deve restare aperta finché `USER_APPROVER` non autorizza il merge.
- Le PR di `STOREFRONT_V1` restano draft durante l'Execution e diventano mergeabili
  soltanto nel closeout integrato approvato.
- Verificare job, step, annotation e commit associato alla CI; un colore verde non
  sostituisce l'ispezione e un limite esterno va riportato come `BLOCKED`.

## Stop condition

Codex si ferma al termine della fase autorizzata dopo avere aggiornato task, Master Plan,
`docs/AI_WORKLOG.md`, evidence e handoff. Non oltrepassa l'handoff, non attiva il task
successivo, non dichiara `DONE` e non esegue merge senza istruzione esplicita
di `USER_APPROVER`.

Nel solo `STOREFRONT_V1`, l'istruzione esplicita è già presente: Codex continua tra task
e milestone dopo ogni checkpoint verde. Si ferma soltanto a fine train o davanti a un
blocker esterno/pericoloso, preservando branch, PR, manifest, checkpoint ed evidence.
