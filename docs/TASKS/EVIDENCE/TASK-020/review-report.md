# Review report — TASK-020

## Revision set

- Commit tecnico:
  `82439dd3fdbbc2920f27e4606dceadb412f0a6e7`
- Handoff ed evidence:
  `2f25f3f74537856204fa42e9ea5d024f9c848332`
- Branch:
  `milestone/011-012-020-authenticated-storefront-foundation`
- Worktree e tracking durante la review: puliti e allineati allo SHA di handoff
- CI osservata sullo SHA di handoff: run `30614374801` e `30614438284`, entrambi
  `BLOCKED / CI_EXTERNAL`; tre job senza step e una annotation billing/spending per
  job

## Reviewer indipendenti

| Reviewer | Specializzazione | Esito |
|---|---|---|
| A | intent, CA e governance | CHANGES_REQUIRED |
| B | lifecycle Auth, race e test | CHANGES_REQUIRED |
| C | sicurezza, storage, callback e threat model | CHANGES_REQUIRED |
| D | UI, l10n, accessibilità e runtime nativo | CHANGES_REQUIRED |
| E | evidence, Git, CI e scope | CHANGES_REQUIRED |

I cinque reviewer hanno operato read-only sul medesimo revision set. I finding
duplicati tra shard sono consolidati una sola volta sotto.

## Finding consolidati

### T020-REV-001 — P1 — Cancel durante exchange lascia una sessione

- **Stato**: OPEN
- **Posizione**: `lib/features/auth/application/auth_controller.dart:118`;
  `lib/features/auth/application/auth_controller.dart:303`;
  `lib/features/auth/data/supabase_auth_repository.dart:77`
- **Impatto**: GoTrue può salvare e persistere la sessione dopo Cancel mentre il
  controller resta `AuthCancelled`; un restart può quindi riaprire Account
  authenticated. Un completamento stale può inoltre eliminare il verifier del flow
  successivo.
- **Correzione richiesta**: serializzare l'exchange, impedire retry fino alla
  compensazione, eseguire sign-out/purge dopo un successo cancellato e vietare side
  effect storage da generation stale.
- **Regressione**: exchange controllato con successo/errore dopo Cancel, side effect
  SDK simulato, cold restore guest e verifier del flow nuovo preservato.

### Finding P2

| ID | Posizione | Impatto e correzione richiesta |
|---|---|---|
| T020-REV-002 | `supabase_auth_repository.dart:58`; `auth_controller.dart:208` | Una sessione scaduta è esposta come authenticated e gli errori refresh vengono ignorati. Filtrare `Session.isExpired`, degradare a guest quando non più valida e testare restore/expiry offline. |
| T020-REV-003 | `auth_controller.dart:83`; `auth_controller.dart:188` | Login avviato mentre termina un restore valido apre comunque OAuth. Ricontrollare sessione/stato dopo initialization; test con factory ritardata. |
| T020-REV-004 | `auth_controller.dart:118`; `auth_controller.dart:196` | Cancel prima della repository salta il cleanup PKCE. Attendere initialization in modo generation-safe e chiudere il cleanup prima di `AuthCancelled`. |
| T020-REV-005 | `auth_controller.dart:64`; `auth_controller.dart:244`; `auth_controller.dart:378` | Errori callback/session lasciano `_oauthFlowActive=true`, quindi Retry è un no-op. Terminare e pulire il flow prima dell'errore recuperabile. |
| T020-REV-006 | `secure_supabase_auth_storage.dart:160`; SDK `supabase_auth.dart:183`; `auth_controller.dart:312` | Supabase Flutter inghiotte errori di persistenza post-auth. Rendere osservabili le failure, confermare la persistenza prima di authenticated e fallire chiuso anche sul refresh. |
| T020-REV-007 | `supabase_auth_repository.dart:194`; `secure_supabase_auth_storage.dart:233` | Un delete fallito impedisce l'altro cleanup e può consentire restore successivo. Tentare sessione/verifier indipendentemente e usare marker non sensibili per ritentare il purge al bootstrap. |
| T020-REV-008 | `commands-and-results.md:57`; `commands-and-results.md:97`; `auth_callback_flow_test.dart:52` | CA-18/T-13 confondono remount fake con terminate/relaunch e secure restore. Aggiungere prove reali o riclassificare i subset live `BLOCKED`. |
| T020-REV-009 | `commands-and-results.md:50`; `supabase-staging-config.md:14` | Provider attivo e 302 non provano l'accettazione del callback Supabase lato Google. Riclassificare CA-11 `BLOCKED` finché MFA impedisce la verifica. |
| T020-REV-010 | diff PR #4; `TASK-020...md:164` | La PR include tre file TASK-003/004 non ammessi dal confinement letterale. Rimuoverli dal diff con commit normale, senza rebase o force push. |
| T020-REV-011 | `integration_test/auth_callback_flow_test.dart:31` | Account è già selezionato prima del callback, quindi il ritorno automatico non è provato. Passare a Home e verificare route/indice Account dopo callback. |
| T020-REV-012 | `integration_test/auth_callback_flow_test.dart:76` | Il browsing guest non è provato durante authenticating, cancelling e offline. Aggiungere interleaving deterministici su Home/Catalogo/Carrello. |
| T020-REV-013 | `test/features/account/account_auth_states_test.dart:204` | La matrice Auth/a11y dichiarata copre un solo stato/tema/viewport. Coprire stati, light/dark, 200%, portrait/landscape/large, Semantics e target 48 dp. |
| T020-REV-014 | `commands-and-results.md:38`; `commands-and-results.md:83` | Le 40/38 righe omettono la colonna obbligatoria `Tipo`. Aggiungerla e introdurre un parser di cardinalità/unicità/stato/tipo. |
| T020-REV-015 | `.github/workflows/ci.yml:31` | La CI non esegue lo scan secret/config/artifact richiesto. Aggiungere script sanitizzato, fixture negativa e step Quality. |
| T020-REV-016 | `ci-status.md:6`; `git-state.md:10`; `commands-and-results.md:77` | Evidence CI/PR stale rispetto ai run e alla draft PR reali. Registrare SHA, run/job/step/annotation, causa, prerequisito e tracking. |
| T020-REV-017 | `environment-audit.md:24`; `pubspec.yaml:20` | `shared_preferences` è direct, non transitive. Correggere classificazione e motivare il solo marker non sensibile. |
| T020-REV-018 | `commands-and-results.md:5`; smoke e security evidence | Vari PASS/BLOCKED non hanno comando/tentativo, output redatto, exit o prerequisito. Centralizzare command ID riproducibili e referenziarli. |
| T020-REV-019 | `docs/ARCHITECTURE/AUTH-BOUNDARY.md:299` | Il divieto generico di URL/key nel bundle contraddice la publishable config attesa. Distinguere origin/publishable key pubblici dai secret vietati e mantenere i valori raw fuori da log/evidence. |

### Finding P3

| ID | Posizione | Correzione richiesta |
|---|---|---|
| T020-REV-020 | `secure_supabase_auth_storage.dart:123` | Azzerare la Future initialization dopo un errore transitorio, preservando single-flight; test failure poi retry. |
| T020-REV-021 | task/worklog TASK-020 | Allineare `Ultimo aggiornamento` e intestazioni operative alla data locale reale 2026-07-31. |

## Verifiche indipendenti positive

- governance, action pins, architecture boundaries e 5/5 fixture negative: `PASS`;
- analyze e suite mirate Auth/Account/native/l10n: `PASS`;
- integration fake Android/iOS: `PASS`;
- routing e callback warm Android: `PASS`;
- callback warm iOS: `BLOCKED`, `simctl openurl` exit 0 e test timeout per dialogo
  OS non accettabile con Mac locked;
- worktree, tracking, diff check, dipendenze e scan evidence: `PASS`;
- zero advisory OSV noto sui package lockati secondo la review security.

Il bundle tecnico `app_zh.arb` in spagnolo e il null assertion del redirect sono stati
respinti come falsi positivi: la policy locale e gli invarianti AppConfig sono
espliciti e testati.

## Conteggio

| Severità | Aperti |
|---|---:|
| P0 | 0 |
| P1 | 1 |
| P2 | 18 |
| P3 | 2 |

## Esito

`CHANGES_REQUIRED`

Handoff: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Re-review 1 del Fix

### Revision set

- Commit tecnico Fix:
  `408f14d242e9d35bfcefbebd10858dcb9e38d028`
- Handoff pubblicato:
  `0ddd26abd9d6c7a5eaa70aaba2481cfe0b05bfa7`
- Branch e upstream: allineati allo SHA di handoff; worktree pulito
- PR #4: `OPEN/DRAFT`, base `main`, head `0ddd26a`, 143 path e zero path
  TASK-003/004
- CI: run `30619705565`, tre job senza runner o step e una annotation
  billing/spending per job; esito `BLOCKED / CI_EXTERNAL`

### Reviewer indipendenti

| Reviewer | Specializzazione | Verifiche autonome | Esito |
|---|---|---|---|
| A | intent, CA, governance ed evidence | 23/23 test mirati, Git/PR/scope | CHANGES_REQUIRED |
| B | lifecycle Auth, race e restore | 45/45 test mirati, analyze | CHANGES_REQUIRED |
| C | sicurezza, storage e callback | 56/56 test mirati, Android callback fake | CHANGES_REQUIRED |
| D | UI, native, l10n e accessibilità | 41/41 + 6/6, callback fake duale e warm Android | CHANGES_REQUIRED |
| E | evidence, Git, PR e CI | matrici 40/38, 12 evidence e run/job/annotation | CHANGES_REQUIRED |

Tutti i reviewer hanno operato read-only sul medesimo revision set.

### Chiusura dei finding originari

| ID | Stato re-review | Evidence |
|---|---|---|
| T020-REV-001 | CLOSED | compensazione Cancel/exchange e sessione tardiva; regressione controller |
| T020-REV-002 | CLOSED | expiry/missing expiry filtrati e recovery SDK retryable testata |
| T020-REV-003 | OPEN — P2 | restore durante `clearPendingOAuth` può ancora precedere il launch browser |
| T020-REV-004 | CLOSED | Cancel pre-factory attende initialization e cleanup |
| T020-REV-005 | CLOSED | errori terminano il flow e Retry rilancia |
| T020-REV-006 | CLOSED | persistenza esplicita e storage failure fail-closed |
| T020-REV-007 | OPEN — P2 | doppia failure marker/delete può lasciare una sessione senza tombstone persistente |
| T020-REV-008 | CLOSED | restore live correttamente distinto e riclassificato `BLOCKED` |
| T020-REV-009 | CLOSED | callback provider non inferita dal 302; CA-11 `BLOCKED` |
| T020-REV-010 | CLOSED | zero path TASK-003/004 nel diff locale e remoto |
| T020-REV-011 | CLOSED | callback fake parte da Home e ritorna ad Account |
| T020-REV-012 | CLOSED | browsing guest interleaved durante gli stati Auth |
| T020-REV-013 | CLOSED | matrice Account completa di stato/tema/viewport/a11y |
| T020-REV-014 | CLOSED | matrici con `Tipo` e parser cardinalità/unicità/stato |
| T020-REV-015 | OPEN — P2 | scanner aggirabile per secret Google/JWT e path annidati/non NUL-safe |
| T020-REV-016 | OPEN — P2 | snapshot Git/CI versionato precedente a push e run corrente |
| T020-REV-017 | CLOSED | `shared_preferences` direct e limitata a marker non sensibili |
| T020-REV-018 | OPEN — P2 | bundle scan e insieme esatto delle 12 evidence non hanno prova completa |
| T020-REV-019 | CLOSED | publishable config distinta dai secret privilegiati |
| T020-REV-020 | CLOSED | initialization azzerata dopo failure e retry testato |
| T020-REV-021 | CLOSED | data locale e intestazioni operative allineate |

### Finding nuovi consolidati

#### T020-RR-001 — P1 — Logout concorrente con exchange lascia una sessione

- **Stato**: OPEN
- **Posizione**: `lib/features/auth/application/auth_controller.dart:293`;
  `test/features/auth/application/auth_controller_test.dart:282`
- **Evidence**: Logout esegue un solo purge senza attendere `_exchangeOperation`;
  il test concorrente controlla soltanto la UI e non abilita il side effect sessione.
- **Impatto**: un exchange tardivo può ripersistire la sessione dopo Logout e un cold
  restore può riaprire Account authenticated.
- **Correzione richiesta**: attendere/quarantenare l'exchange e applicare un secondo
  purge compensativo prima di consentire un nuovo login.
- **Regressione**: exchange controllato con side effect sessione, Logout concorrente,
  successo/errore e storage failure; sessione finale assente e restore guest.

#### T020-RR-002 — P2 — Cancellazione provider non termina l'epoca OAuth

- **Stato**: OPEN
- **Posizione**: `lib/features/auth/application/auth_controller.dart:420`
- **Evidence**: `access_denied` imposta `AuthCancelled` senza purge né guard; un code
  canonico successivo può ancora essere scambiato.
- **Impatto**: la UI mostra cancellazione, ma un callback tardivo può autenticare.
- **Correzione richiesta**: instradare cancellation/failure provider nella terminazione
  serializzata e ignorare callback fino a un nuovo login.
- **Regressione**: `access_denied`, cleanup post-evento, code tardivo, zero exchange e
  restore guest.

#### T020-RR-003 — P3 — Range task ambiguo nel README

- **Stato**: OPEN
- **Posizione**: `README.md:159`
- **Correzione richiesta**: distinguere TASK-013–TASK-019 da TASK-021 in avanti,
  senza includere implicitamente TASK-020.

#### T020-RR-004 — P3 — Formula temporale ambigua nell'architettura

- **Stato**: OPEN
- **Posizione**: `docs/ARCHITECTURE/MOBILE-ARCHITECTURE.md:82`
- **Correzione richiesta**: sostituire “Fino a TASK-020” con una formula che descriva
  correttamente la funzionalità introdotta da TASK-020.

#### T020-RR-005 — P3 — Descrizione marker storage incompleta

- **Stato**: OPEN
- **Posizione**: `docs/ARCHITECTURE/AUTH-BOUNDARY.md:277`
- **Correzione richiesta**: documentare marker installazione e tombstone non sensibili,
  inclusa la copia sicura ridondante richiesta dal Fix.

### Conteggio re-review

| Severità | Aperti |
|---|---:|
| P0 | 0 |
| P1 | 1 |
| P2 | 6 |
| P3 | 3 |

Sedici finding originari sono `CLOSED`; cinque originari e cinque nuovi restano
`OPEN`.

### Esito re-review 1

`CHANGES_REQUIRED`

Handoff: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Re-review 2 del Fix

### Revision set

- Commit tecnico finale Fix 2:
  `036dcd1be047d49d6b53738d06e5e58caf608f34`
- Handoff/evidence:
  `7b4bf152b496f7429b506c053f0e8ec5cf436b83`
- Branch, upstream e PR head: allineati allo SHA handoff; worktree pulito
- PR #4: `OPEN/DRAFT`, base `main`, 143 path, zero TASK-003/004
- CI handoff: run `30624825908`, tre job senza runner/step e una annotation
  billing/spending per job; `BLOCKED / CI_EXTERNAL`

### Reviewer indipendenti

| Reviewer | Specializzazione | Verifiche autonome | Esito |
|---|---|---|---|
| A | intent, CA, governance e scope | 39/39 mirati, scanner e PR scope | BLOCKED |
| B | lifecycle Auth, race e restore | 53/53 mirati e probe URI | APPROVED |
| C | storage, scanner e threat model | storage 13/13, scanner/fixture/bundle | CHANGES_REQUIRED |
| D | UI, native, l10n e accessibilità | 40/40 mirati e artifact iOS | BLOCKED |
| E | evidence, Git, PR e CI | parser 1/1, refs/run/annotation, bundle rerun | CHANGES_REQUIRED |

Tutti gli shard hanno operato read-only sul medesimo revision set.

### Chiusura dei dieci finding della re-review 1

| ID | Stato re-review 2 | Evidence |
|---|---|---|
| T020-REV-003 | CLOSED | ricontrollo post-cleanup e regressione restore concorrente |
| T020-REV-007 | OPEN | resta T020-RR2-002 sul caso simultaneo di tutti i canali persistenti |
| T020-REV-015 | OPEN | resta T020-RR2-001 sui due path scanner esclusi |
| T020-REV-016 | OPEN | resta T020-RR2-003 sulla provenance handoff/CI |
| T020-REV-018 | OPEN | resta T020-RR2-004 su digest, conteggio e comandi esatti |
| T020-RR-001 | CLOSED | purge prima/dopo exchange Logout e side effect testato |
| T020-RR-002 | CLOSED | terminazione provider e dedup code-only dopo Retry |
| T020-RR-003 | CLOSED | range task README corretto |
| T020-RR-004 | CLOSED | formula temporale architetturale corretta |
| T020-RR-005 | CLOSED | marker installazione/tombstone ridondanti documentati |

### T020-RR2-001 — P2 — Path scanner esclusi integralmente

- **Stato**: OPEN
- **Posizione**: `scripts/check-client-security.sh`; script fixture scanner
- **Evidence**: i due script vengono saltati prima dello scan dei valori e il file
  fixture contiene shape sintetiche complete.
- **Impatto**: un valore reale inserito in quei path può superare la CI.
- **Correzione richiesta**: eliminare le esclusioni, comporre le fixture da
  frammenti non secret-shaped e aggiungere regressioni sui due path.

### T020-RR2-002 — P2 — Nessun tombstone dopo failure simultanee

- **Stato**: OPEN
- **Posizione**: `secure_supabase_auth_storage.dart`, cleanup marker/delete
- **Evidence**: se falliscono entrambe le scritture SharedPreferences, il tombstone
  sicuro e il delete sessione, al restart entrambi i marker possono risultare assenti.
- **Impatto**: una sessione stale può tornare leggibile dopo recovery dei driver.
- **Correzione richiesta**: strategia fail-closed persistente addizionale oppure
  rischio esplicito con decisione utente; regressione restart sull'interleaving.

### T020-RR2-003 — P2 — Provenance Git/CI ferma allo SHA tecnico

- **Stato**: OPEN
- **Posizione**: `git-state.md`, `ci-status.md`, matrice canonica
- **Evidence**: lo snapshot versionato registra `036dcd1`/`30624421347`, mentre la
  re-review usa `7b4bf15`/`30624825908`.
- **Impatto**: CA/T Git/CI non sono attestati sul vero handoff.
- **Correzione richiesta**: registrare SHA, PR, run/job/step/annotation e command ID
  del revision set corrente.

### T020-RR2-004 — P2 — Bundle evidence non riproducibile

- **Stato**: OPEN
- **Posizione**: `commands-and-results.md` e riferimenti security/task/worklog
- **Evidence**: il rerun conta 627 file contro 629 documentati; nessun digest lega
  APK/Runner.app allo SHA e header/comandi contengono revisioni o placeholder stale.
- **Impatto**: CA-22/34/35/36 e T-26/27 non hanno provenance integra.
- **Correzione richiesta**: build esatta, digest sanitizzati, conteggio coerente,
  header corrente e comandi realmente eseguiti.

### Conteggio re-review 2

| Severità | Aperti |
|---|---:|
| P0 | 0 |
| P1 | 0 |
| P2 | 4 |
| P3 | 0 |

### Esito re-review 2

`CHANGES_REQUIRED`

Handoff: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Re-review 3 del Fix

### Revision set

- Commit tecnico Fix 3:
  `5740c835a116af16ab2e7ca6c55c927d180ece90`
- Handoff/evidence:
  `891f96124f706c8a53168937ec701709301b3855`
- Branch, upstream e PR head: allineati allo SHA handoff; worktree pulito
- PR #4: `OPEN/DRAFT`, base `main`, 143 path, zero TASK-003/004
- CI handoff: run `30628616615`, tre job senza runner/step e una annotation
  billing/spending per job; `BLOCKED / CI_EXTERNAL`

### Reviewer indipendenti

| Reviewer | Specializzazione | Verifiche autonome | Esito |
|---|---|---|---|
| A | intent, CA, governance e scope | revision set, matrici, scope e blocker | CHANGES_REQUIRED |
| B | lifecycle Auth, race e storage | suite mirata 33/33 e review journal | APPROVED |
| C | scanner, threat model e dipendenze | scanner/fixture/boundary e probe JWT | CHANGES_REQUIRED |
| D | UI, native, l10n e accessibilità | provenance smoke e configurazione invariata | BLOCKED |
| E | evidence, Git, PR e CI | parser, digest/count, scope e tre run CI | CHANGES_REQUIRED |

Tutti gli shard hanno operato read-only sul medesimo revision set. Lo shard E non ha
trovato un finding proprio, ma assegna l'esito complessivo coerente con il P2 dello
shard C.

### Chiusura dei finding della re-review 2

| ID | Stato re-review 3 | Evidence |
|---|---|---|
| T020-RR2-001 | CLOSED | propri path, index/worktree, stage e symlink verificati |
| T020-RR2-002 | CLOSED | journal pre-marker, restart e read fail-closed verificati |
| T020-RR2-003 | CLOSED | handoff `891f961`, PR e run `30628616615` verificati e registrati qui |
| T020-RR2-004 | CLOSED | 548 + 81 = 629 e digest riprodotti; 12/40/38 validati |
| T020-REV-007 | CLOSED | cleanup a tre canali e regressione restart |
| T020-REV-015 | OPEN | resta T020-RR3-C-001 sul JWT customer |
| T020-REV-016 | CLOSED | provenance handoff/CI corrente |
| T020-REV-018 | CLOSED | bundle e command evidence riproducibili |

### T020-RR3-C-001 — P2 — JWT customer non rilevato

- **Stato**: OPEN
- **Posizione**: `scripts/check-client-security.sh`, decode semantico JWT
- **Evidence**: un JWT sintetico valido con `role=authenticated`, fornito come
  artifact, è accettato con exit 0; il codice rifiuta soltanto `service_role`.
- **Impatto**: un customer access token può superare source/index/worktree/bundle
  scan; CA-22, CA-36 e T-26 diventano `FAIL`. Nel Git corrente non è presente
  alcun JWT letterale.
- **Correzione richiesta**: consentire soltanto il legacy JWT pubblicabile con
  `role=anon`; rifiutare `authenticated`, `service_role` e ruoli non pubblicabili.
  Aggiungere fixture negative per source/index/worktree/artifact e una positiva
  `anon`.

### T020-RR3-A-001 — P3 — Path host non redatto

- **Stato**: OPEN
- **Posizione**: `commands-and-results.md`, CMD-X08
- **Evidence**: il comando persiste il prefisso assoluto della home nel path ADB.
- **Impatto**: disclosure non necessaria di un path macchina nell'evidence
  versionata.
- **Correzione richiesta**: redigere soltanto il prefisso host, mantenendo comando,
  exit e risultato reali.

### Finding non consolidato

Lo shard A ha trattato la mancata presenza di `891f961` e della sua CI dentro il
commit `891f961` come provenance stale. Il rilievo non è un finding: genererebbe una
catena autoreferenziale infinita. Lo shard E ha verificato lo SHA e la run reali; il
reviewer li persiste in questa transizione, come previsto dall'handoff.

### Conteggio re-review 3

| Severità | Aperti |
|---|---:|
| P0 | 0 |
| P1 | 0 |
| P2 | 1 |
| P3 | 1 |

### Esito re-review 3

`CHANGES_REQUIRED`

Handoff: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Re-review 4 del Fix

### Revision set

- Commit tecnico Fix 4:
  `9dbd53532f7a49040d0bf94fcd1a28abf5a0d382`
- Handoff/evidence:
  `c0ebd750404207ac417faac4e0ff6c04af5940fd`
- Base:
  `40d118eebf78eeabea9e26747adb00053dd875bc`
- HEAD, upstream e PR head: allineati allo SHA handoff; worktree e index puliti
- PR #4: `OPEN/DRAFT`, base `main`, 143 path, zero TASK-003/004
- CI handoff: run `30631361964`, tre job senza runner/step e una annotation
  billing/spending per job; `BLOCKED / CI_EXTERNAL`

### Reviewer indipendenti

| Reviewer | Specializzazione | Verifiche autonome | Esito |
|---|---|---|---|
| A | intent, CA, governance e scope | revision set, diff, 12/40/38, sanitizzazione e handoff | BLOCKED |
| B | scanner JWT e fixture | syntax, 336 file, 32/32 + 2/2, 21 probe avversari e bundle | APPROVED |
| C | security, threat model e artifact | scan Git/bundle, digest, PII/config e CI handoff | BLOCKED |
| D | app, Auth, storage, UI e native | byte-identità Fix 3, analyze, 94/94 test e smoke provenance | BLOCKED |
| E | evidence, Git, PR e CI | scope remoto, parser, artifact e run/job/annotation | BLOCKED |

Tutti gli shard hanno operato read-only sul medesimo revision set. Gli esiti
`BLOCKED` di A/C/D/E non contengono finding tecnici: riflettono esclusivamente i
gate obbligatori esterni descritti sotto. Un controllo D supplementare, anch'esso
read-only, ha eseguito 117/117 test mirati con esito `PASS`.

L'ausilio opzionale CodeRabbit non ha prodotto una review per rate limit e repository
non collegato all'organizzazione; non è una fonte di finding né un gate prescritto.
La review A–E richiesta è stata comunque eseguita integralmente da cinque sessioni
indipendenti.

### Chiusura dei finding della re-review 3

| ID | Stato re-review 4 | Evidence |
|---|---|---|
| T020-RR3-C-001 | CLOSED | unico ruolo scalare letterale `anon`; 32/32 negative, 2/2 positive e 21/21 probe |
| T020-RR3-A-001 | CLOSED | CMD-X08 usa `<android-sdk>`; zero path host `/Users/` nell'evidence |
| T020-REV-015 | CLOSED | scanner/fixture/source/index/worktree/artifact e CI contract verificati |
| T020-REV-016 | CLOSED | SHA tecnico/handoff, PR e CI correlati senza auto-citazione circolare |
| T020-REV-018 | CLOSED | 548 + 81 = 629 file e digest APK/Runner riprodotti |

Il controllo semantico JWT è fail-closed:

- la pipeline base64url -> OpenSSL -> `JSON::PP` conserva NUL e fallisce chiusa;
- il payload deve essere un JSON object con un solo campo `role` top-level,
  scalare e letteralmente `anon`;
- customer, `service_role`, ruoli ignoti/mancanti/duplicati/escaped, tipi non
  scalari, JSON invalido, padding impossibile e failure operative sono respinti;
- index, worktree, symlink e artifact APK/directory sono verificati separatamente.

I falsi positivi conservativi su escape Unicode, campi `role` annidati/duplicati o
sequenze testuali ambigue non allargano il confine pubblicabile e non sono finding
bloccanti.

### Gate indipendenti

- governance: `PASS`; tuple pre-consolidamento
  `TASK-020 / BLOCKED / REVIEW / CODEX_FIX_BLOCKED_TO_RE_REVIEW` e finale
  `TASK-020 / BLOCKED / REVIEW / CODEX_REVIEW_BLOCKED`;
- evidence: `PASS`; 12 file, 40 CA, 38 test e command ID validi;
- scanner: `PASS`; 336 file, 32/32 negative, 2/2 positive e 21/21 probe;
- artifact: `PASS`; APK 548 file e SHA-256
  `164225362dd64e859b3cab2688350e891f944a64cc55ece3f867189d9cc56e18`;
  Runner 81 file e tree SHA-256
  `6295cd692517d40e4b817f3c96fd1b5972062a789aa0a5940196c37aff471a3d`;
- app/native invariati: `PASS`; tree/blob `lib`, Android, iOS, test, integration
  test, dipendenze e workflow identici al Fix 3; analyze zero issue e 94/94 test;
- Git/PR: `PASS`; HEAD/upstream/PR `c0ebd75`, 143 path e zero TASK-003/004;
- CI: `BLOCKED`; run `30631361964`, Quality `91158230335`, iOS
  `91158230405` e Android `91158230451`, tutti `runner_id=0`, zero step e una
  annotation billing/spending.

### Blocker esterni

- redirect allow-list, callback provider e OAuth live: `BLOCKED` da MFA umano;
  kill switch `false`, zero write remoto;
- callback warm iOS: `BLOCKED`; `simctl` exit 0 non prova la delivery e il
  harness ha timeout finché il dialogo OS non viene accettato su Mac sbloccato;
- CI: `BLOCKED / CI_EXTERNAL`; il titolare deve ripristinare Billing & plans o
  spending limit prima che i runner eseguano codice.

### Conteggio re-review 4

| Severità | Aperti |
|---|---:|
| P0 | 0 |
| P1 | 0 |
| P2 | 0 |
| P3 | 0 |

### Esito re-review 4

`BLOCKED`

L'implementazione non presenta finding aperti, ma i gate obbligatori esterni non
sono stati eseguiti con successo. `APPROVED`, `DONE` e merge non sono autorizzati.

Handoff: `CODEX_REVIEW_BLOCKED`.

## Addendum Re-review 5 — ripresa Prelude 2026-08-01

Revision set: `06768266fdba498011a65102472c66d482c2f8b6`.

- `PASS`: callback warm iOS, CMD-P01, `simctl` exit 0, harness exit 0, 1/1;
- `BLOCKED`: Supabase allow-list, CMD-P02, Dashboard login richiesto e Management
  API HTTP 401, zero write;
- `BLOCKED`: CI run `30632938353`, tre job con `runner_id=0`, zero step e una
  annotation billing/spending ciascuno;
- `PASS`: governance, parser 12/40/38, scanner 336 file e `git diff --check`,
  CMD-P05, exit 0;
- 0 P0, 0 P1, 0 P2 e 0 P3 aperti.

Esito: `BLOCKED`. Il blocker iOS è chiuso; OAuth live e CI restano obbligatori.

Handoff: `CODEX_REVIEW_BLOCKED`.

### Addendum CI reale sul commit evidence

- `PASS`: run pull request `30708934520` sullo SHA `67adf5d`; Android
  `91392819779`, iOS `91392819807` e Quality `91392819830`, tutti gli step
  applicabili `success`, zero annotation;
- la CI non è più un blocker; l'esito resta `BLOCKED` esclusivamente per
  allow-list e matrice OAuth/session lifecycle live dipendenti dall'accesso
  autenticato a Supabase staging.

Handoff: `CODEX_REVIEW_BLOCKED`.
