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
