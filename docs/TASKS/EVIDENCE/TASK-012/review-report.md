# Review report — TASK-012

## Revision set

- Commit tecnico:
  `14cdc5175b9a596c8a4237e6796fefe3e7beda63`
- Handoff ed evidence:
  `c4dc7af4df2e96a487d4e9c2e07ed4eab5428b23`
- CI handoff: `30605208014`, 3/3 job `success`, tutti gli step `success`,
  annotation 0/0/0
- Reviewer: due shard read-only indipendenti, UI/a11y e
  architettura/security/governance

## Finding

### T012-REV-UI-001 — P2 — Semantics Catalogo aggregata erroneamente

- **Stato**: OPEN
- **Posizione**: `lib/features/catalog/presentation/catalog_screen.dart:48`
- **Riproduzione**: nel dump UIAutomator Android 15 il solo `EditText` disabilitato ha
  `content-desc=""`, bounds `[53,294][1028,767]` e ingloba Filter e Sort; la copy
  `catalogControlsUnavailable` è assente.
- **Impatto**: TalkBack non riceve label/hint ricerca e spiegazione come nodi autonomi;
  CA-13, CA-30 e T-23 non passano.
- **Correzione richiesta**: confine Semantics autonomo per ricerca e spiegazione
  sibling accessibile.
- **Regressione**: Semantics tree più nuovo dump Android con ricerca, spiegazione,
  Filter e Sort separati.

### T012-REV-SEC-001 — P2 — Logout non garantito in release

- **Stato**: OPEN
- **Posizione**: `lib/features/account/presentation/account_screen.dart:21`
- **Riproduzione**: `AccountView.authenticated` accetta `onLogout == null` quando gli
  assert sono rimossi e presenta sessione attiva con pulsante disabilitato.
- **Impatto**: il contratto destinato a TASK-020 può impedire la terminazione della
  sessione; CA-21 non passa.
- **Correzione richiesta**: rendere il logout obbligatorio per tipo o con controllo
  runtime non eliminabile; callback interna non-null.
- **Regressione**: authenticated senza logout non costruibile/rifiutato anche senza
  assert; logout sempre abilitato e invocato.

### T012-REV-SEC-002 — P2 — Avatar port abilita networking

- **Stato**: OPEN
- **Posizione**:
  `lib/features/account/presentation/account_presentation_model.dart:14`;
  `lib/features/account/presentation/account_screen.dart:300`
- **Riproduzione**: il tipo `ImageProvider<Object>` accetta `NetworkImage`; il widget
  `Image` ne risolve il provider e può effettuare HTTP.
- **Impatto**: il port non garantisce presentazione locale/zero I/O; CA-22 e CA-34 non
  passano.
- **Correzione richiesta**: input locale ristretto e bounded, ad esempio bytes
  validati convertiti internamente in `MemoryImage`.
- **Regressione**: `NetworkImage` non accettabile e prova zero-request; fallback per
  bytes invalidi conservato.

### T012-REV-GOV-003 — P2 — Matrici evidence aggregate

- **Stato**: OPEN
- **Posizione**: `docs/TASKS/EVIDENCE/TASK-012/execution-evidence.md:29`
- **Riproduzione**: CA-01–CA-06 e T-01–T-25 sono intervalli in una singola riga.
- **Impatto**: manca la tracciabilità one-to-one richiesta dal protocollo tra ogni
  criterio/test ed evidence/comando/esito.
- **Correzione richiesta**: 39 righe CA e 34 righe T con evidence puntuale e motivo
  per ogni `NOT_RUN`.
- **Regressione**: controllo presenza/unicità di CA-01…CA-39 e T-01…T-34.

## Conteggio

| Severità | Aperti |
|---|---:|
| P0 | 0 |
| P1 | 0 |
| P2 | 4 |
| P3 | 0 |

## Verifiche indipendenti

- `flutter analyze`: `PASS`, exit 0;
- `flutter test --coverage`: `PASS`, 139/139;
- suite UI/l10n/a11y mirate: `PASS`;
- smoke Android e iOS: `PASS`, 1/1 per piattaforma;
- es-CL/it/en/zh-Hans, 48 dp, 200%, quattro viewport, SafeArea, light/dark,
  tab/back e UI data-safe: `PASS`;
- governance, diff, dipendenze/native invariati, query/Auth/session/secret/config e
  originalità: `PASS`;
- worktree revisionato: pulito e allineato.

Uno shard ausiliario CodeRabbit, non usato per l'esito, è stato `BLOCKED` da rate limit
esterno. I due reviewer principali hanno completato le verifiche. La traversata manuale
completa VoiceOver/TalkBack non è stata eseguita; il dump Android nativo ha comunque
reso riproducibile il finding UI.

## Matrice CA review

| CA | Esito review | Evidenza |
|---|---|---|
| CA-01 | PASS | Governance e baseline Git. |
| CA-02 | PASS | Audit originalità e asset. |
| CA-03 | PASS | Token/theme scan e widget test. |
| CA-04 | PASS | Test brand centralizzato. |
| CA-05 | PASS | Shell e quattro destinazioni. |
| CA-06 | PASS | Tab state, scroll e back. |
| CA-07 | PASS | Guest browsing nei test e smoke. |
| CA-08 | PASS | Home app bar/gerarchia/ricerca. |
| CA-09 | PASS | CTA Home senza query. |
| CA-10 | PASS | Categorie future oneste. |
| CA-11 | PASS | Offerte/featured future state. |
| CA-12 | PASS | Scan assenza dati finti. |
| CA-13 | FAIL | T012-REV-UI-001 aperto. |
| CA-14 | PASS | Stati Catalogo distinti. |
| CA-15 | PASS | Retry single-flight ereditato. |
| CA-16 | PASS | Zero query/RPC/Storage. |
| CA-17 | PASS | Carrello vuoto e CTA. |
| CA-18 | PASS | Zero checkout/totali. |
| CA-19 | PASS | Account guest customer-safe. |
| CA-20 | PASS | Google port fail-closed. |
| CA-21 | FAIL | T012-REV-SEC-001 aperto. |
| CA-22 | FAIL | T012-REV-SEC-002 aperto. |
| CA-23 | PASS | Nessun profilo/form fuori scope. |
| CA-24 | PASS | Runtime guest e zero sessioni. |
| CA-25 | PASS | Parità ARB e resolver locale. |
| CA-26 | PASS | Scan stringhe customer-facing. |
| CA-27 | PASS | Formatter CLP invariato. |
| CA-28 | PASS | Light/dark e semantic colors. |
| CA-29 | PASS | Text scale 200%. |
| CA-30 | FAIL | T012-REV-UI-001 aperto. |
| CA-31 | PASS | Target 48 dp. |
| CA-32 | PASS | SafeArea e viewport. |
| CA-33 | PASS | Full-width, bounds e scroll. |
| CA-34 | FAIL | T012-REV-SEC-002 aperto. |
| CA-35 | PASS | Gate, test e build. |
| CA-36 | PASS | Smoke e screenshot dual-platform. |
| CA-37 | FAIL | T012-REV-GOV-003 aperto. |
| CA-38 | FAIL | Quattro P2 aperti. |
| CA-39 | NOT_RUN | Riservato allo SHA finale dopo re-review. |

## Matrice test review

| Test | Esito review | Evidenza |
|---|---|---|
| T-01 | PASS | Governance/Git. |
| T-02 | PASS | Originalità e data safety. |
| T-03 | PASS | Token/theme. |
| T-04 | PASS | Brand. |
| T-05 | PASS | Tab state/back. |
| T-06 | PASS | Guest readiness. |
| T-07 | PASS | Home/CTA. |
| T-08 | PASS | Future state. |
| T-09 | FAIL | T012-REV-UI-001. |
| T-10 | PASS | Stati Catalogo. |
| T-11 | PASS | Retry. |
| T-12 | PASS | Zero I/O/query. |
| T-13 | PASS | Cart data-safe. |
| T-14 | PASS | Cart CTA. |
| T-15 | PASS | Account guest/Google. |
| T-16 | FAIL | T012-REV-SEC-001. |
| T-17 | FAIL | T012-REV-SEC-002. |
| T-18 | PASS | Runtime guest. |
| T-19 | PASS | L10n. |
| T-20 | PASS | CLP. |
| T-21 | PASS | Tema. |
| T-22 | PASS | Reflow 200%. |
| T-23 | FAIL | T012-REV-UI-001. |
| T-24 | PASS | Target. |
| T-25 | PASS | SafeArea/bounds. |
| T-26 | PASS | Integration dual-platform. |
| T-27 | PASS | Gate locali. |
| T-28 | PASS | Build Android. |
| T-29 | PASS | Build iOS. |
| T-30 | PASS | Smoke/screenshot Android. |
| T-31 | PASS | Smoke/screenshot iOS. |
| T-32 | FAIL | T012-REV-GOV-003 e SEC-002. |
| T-33 | FAIL | Review con P2 aperti. |
| T-34 | NOT_RUN | Riservato allo SHA finale. |

## Esito

`CHANGES_REQUIRED`

Handoff: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.
