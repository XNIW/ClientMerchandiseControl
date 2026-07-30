# Protocollo workflow Codex

Questo documento dettaglia il workflow operativo definito in `AGENTS.md`. Non è una
seconda fonte di istruzioni root: in caso di divergenza si sospende il lavoro e si
riallineano Master Plan, task attivo e protocollo prima di proseguire.

## Fonti e precedenza

1. Istruzione esplicita dell'utente e relativi emendamenti registrati.
2. `AGENTS.md`.
3. `docs/MASTER-PLAN.md`.
4. File del task `ACTIVE`.
5. Questo protocollo.
6. Evidence e documenti tecnici.

Può esistere un solo task `ACTIVE`. Master Plan e task devono concordare su stato, fase,
responsabile, indicatore e prossima azione.

## Ruoli e proprietà delle sezioni

| Ruolo | Fase | Può aggiornare | Non può fare |
|---|---|---|---|
| `CODEX_PLANNER` | `PLANNING` | Planning, criteri, test, rischi, decisioni e handoff | Implementare o dichiarare gate |
| `CODEX_EXECUTOR` | `EXECUTION` | Execution, evidence e handoff | Cambiare planning o approvare il proprio lavoro |
| `CODEX_REVIEWER` | `REVIEW` | Review, finding ed evidence indipendenti | Correggere durante la review, marcare `DONE` o fare merge |
| `CODEX_FIXER` | `FIX` | Fix, regression test, evidence e handoff | Ampliare scope o approvare i propri fix |
| `CODEX_RE_REVIEWER` | `REVIEW` dopo `FIX` | Re-review e chiusura finding | Correggere durante la re-review, marcare `DONE` o fare merge |
| `USER_APPROVER` | conferma | Scope sostanziale, `DONE`, merge e task successivo | Non applicabile |

Lo stesso prodotto Codex può assumere ruoli diversi, ma autore e reviewer restano
separati almeno logicamente. Review e re-review si svolgono preferibilmente in una nuova
sessione e non ereditano come fatti i claim dell'autore.

## Stati

- Progetto: `IDLE`, `ACTIVE`.
- Task: `TODO`, `ACTIVE`, `BLOCKED`, `DONE`.
- Fase del task attivo: `PLANNING`, `EXECUTION`, `REVIEW`, `FIX`.
- Esito review: `APPROVED`, `CHANGES_REQUIRED`, `REJECTED`, `BLOCKED`.
- Esito verifica: `PASS`, `FAIL`, `NOT_RUN`, `BLOCKED`.

`BLOCKED` non è un sinonimo di failure del prodotto: registra un impedimento verificato,
il tentativo eseguito e il prerequisito di sblocco. Quando il blocco viene rimosso, il
task riprende nella fase e con il ruolo che erano autorizzati.

## Transizioni deterministiche

| Da | Condizione | A | Responsabile successivo | Handoff |
|---|---|---|---|---|
| `PLANNING` | piano completo | attesa autorizzazione | `USER_APPROVER` | `CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION` |
| `PLANNING` | autorizzazione utente | `EXECUTION` | `CODEX_EXECUTOR` | `CODEX_PLANNING_APPROVED_TO_EXECUTION` |
| `EXECUTION` | gate obbligatori soddisfatti | `REVIEW` | `CODEX_REVIEWER` | `CODEX_EXECUTION_COMPLETE_TO_REVIEW` |
| `REVIEW` | `CHANGES_REQUIRED` | `FIX` | `CODEX_FIXER` | `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX` |
| `FIX` | fix e verifiche completati | `REVIEW` | `CODEX_RE_REVIEWER` | `CODEX_FIX_COMPLETE_TO_RE_REVIEW` |
| `FIX` | gate obbligatorio non superabile | `REVIEW`, task `BLOCKED` | `CODEX_RE_REVIEWER` | `CODEX_FIX_BLOCKED_TO_RE_REVIEW` |
| `REVIEW` | `REJECTED` | `PLANNING` | `CODEX_PLANNER` | `CODEX_REVIEW_REJECTED_TO_PLANNING` |
| `REVIEW` | `BLOCKED` | `REVIEW`, task `BLOCKED` | `CODEX_REVIEWER` | `CODEX_REVIEW_BLOCKED` |
| `REVIEW` | `APPROVED` | `REVIEW`, task `ACTIVE` | `USER_APPROVER` | `CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION` |
| `REVIEW` | `APPROVED` e conferma utente | `DONE` | `USER_APPROVER` | `USER_APPROVED_DONE` |

La conferma utente per `DONE` non implica automaticamente autorizzazione al merge o
attivazione del task successivo: le azioni devono essere esplicite. Codex non esegue mai
merge o auto-merge autonomamente.

## Planning

Un planning valido contiene:

- obiettivo e contesto;
- scope, non incluso e file coinvolti;
- approccio minimo e dipendenze;
- rischi e mitigazioni;
- criteri di accettazione verificabili;
- test case e tipi di verifica;
- handoff a Execution.

Il planner non implementa. Dopo avere registrato il piano si ferma in attesa
dell'autorizzazione dell'utente.

## Execution

L'executor:

1. legge il planning approvato senza reinterpretarne priorità o scope;
2. implementa soltanto quanto autorizzato;
3. esegue i gate in ordine di dipendenza;
4. registra comandi, exit code, warning e risultati;
5. aggiorna matrici, task, Master Plan, worklog ed evidence;
6. consegna a Review senza auto-approvarsi.

Un problema fuori scope viene registrato come rischio o follow-up candidato, non corretto
opportunisticamente. Un file nuovo deve avere responsabilità concreta.

## Review e re-review

Il reviewer parte da intent, criteri, diff e comportamento reale. Verifica direttamente:

- baseline Git, branch, commit, PR e stato di `main`;
- rispetto di scope, architettura e dipendenze;
- ogni CA e T-NN contro evidence appartenenti al commit revisionato;
- test, build, smoke, CI e security applicabili;
- assenza di secret, dati reali e modifiche a repository esterni;
- coerenza di task, Master Plan, worklog e handoff.

Ogni finding contiene almeno ID, severità, stato, posizione, descrizione, evidenza,
impatto, correzione richiesta e regression test. Gli esiti significano:

- `APPROVED`: criteri soddisfatti; attesa della conferma utente, mai `DONE` automatico;
- `CHANGES_REQUIRED`: finding correggibili nello scope; transizione a `FIX`;
- `REJECTED`: intent o planning sostanzialmente inadeguati; ritorno a `PLANNING`;
- `BLOCKED`: verifica obbligatoria impossibile dopo tentativi documentati.

La re-review non verifica soltanto il diff del fix: chiude ogni finding, controlla
regressioni e riesegue tutti i gate obbligatori che potrebbero essere diventati obsoleti.

## Fix

Il fixer applica i finding approvati senza alterare scope o backlog, aggiunge i test di
regressione necessari, aggiorna lo stato di risoluzione e riesegue i gate impattati.
Qualunque sia la qualità percepita del fix, la transizione successiva è sempre `REVIEW`.

## Tipi di verifica

| Tipo | Significato |
|---|---|
| `STATIC` | Lettura, scansione o confronto statico |
| `FORMAT` | Formattazione verificata |
| `ANALYZE` | Analisi statica Flutter/Dart |
| `UNIT` | Unit test |
| `WIDGET` | Widget test |
| `BUILD_ANDROID` | Build Android reale |
| `BUILD_IOS` | Build iOS Simulator reale |
| `ANDROID_EMU` | Verifica su Android Emulator avviato |
| `IOS_SIM` | Verifica su iOS Simulator avviato |
| `SECURITY` | Controllo mirato di secret, dipendenze e artifact |
| `CI` | GitHub Actions sul commit verificato |
| `GIT` | Stato, diff, branch, commit, remote o PR |
| `MANUAL` | Giudizio o interazione manuale dichiarata |

## Stati delle verifiche

Gli unici valori ammessi sono:

- `PASS`: comando o verifica realmente eseguiti con risultato conforme;
- `FAIL`: verifica eseguita e requisito non soddisfatto;
- `NOT_RUN`: verifica non eseguita, con motivo preciso;
- `BLOCKED`: verifica tentata ma impedita, con causa e prerequisito di sblocco.

Eseguito non significa inferito. Nessuna build è `PASS` senza comando ed exit code reali;
nessuno smoke è `PASS` senza avvio reale e interazione. Uno screenshot è diagnostica,
non prova sufficiente da solo. Un job CI verde va associato al commit corretto e
ispezionato per job, step e annotation.

Dopo un `FAIL` non si eseguono verifiche dipendenti; quelle indipendenti possono
proseguire. I comandi ancora attivi vanno attesi prima dell'handoff. Se non possono
terminare, il loro stato è `BLOCKED` o `NOT_RUN`, mai `PASS`.

## Evidence e handoff minimo

Ogni CA ha una riga CA -> evidence e ogni T-NN una riga T-NN -> risultato. Le evidence
sono concise, sanitizzate, tracciabili al codice verificato e non contengono secret, dati
personali, path utente non necessari o log integrali.

L'handoff contiene:

- file e responsabilità toccati;
- comandi e verifiche con exit code;
- warning nuovi e comandi falliti;
- matrici CA -> evidence e T-NN -> risultato;
- scope confermato o deviazioni;
- rischi residui;
- stato di branch, worktree, commit, PR e CI;
- prossima fase, ruolo e azione.

Prima dell'handoff si aggiornano task, Master Plan e `docs/AI_WORKLOG.md`. Il worktree
deve essere pulito; se modifiche altrui o un impedimento lo rendono impossibile, non si
cancellano e si registra il blocco.

## Sicurezza, Git e stop condition

Non versionare secret, credenziali privilegiate, dati cliente, configurazioni production,
file locali, coverage o build artifact. Non modificare repository di riferimento.
Vietati force push, reset distruttivi, amend remoto, merge e auto-merge.

L'Execution non passa a Review quando un gate obbligatorio è `FAIL`, `NOT_RUN` o
`BLOCKED`. Dopo `FIX` resta obbligatoria la transizione a Review: il fixer registra il
gate non superato e il re-reviewer assegna l'esito coerente. Al termine della fase
autorizzata Codex registra l'handoff e si ferma: non cambia autonomamente scope, non
attiva il task successivo e non imposta `DONE`.
