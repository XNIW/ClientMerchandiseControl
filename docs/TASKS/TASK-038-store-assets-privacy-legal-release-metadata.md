# TASK-038 — Store assets, privacy, legal e release metadata

## Informazioni generali

- **Task ID**: TASK-038
- **Titolo**: Store assets, privacy, legal e release metadata
- **File task**: `docs/TASKS/TASK-038-store-assets-privacy-legal-release-metadata.md`
- **Stato**: ACTIVE
- **Fase**: FIX
- **Responsabile**: CODEX_FIXER
- **Data creazione**: 2026-08-17
- **Ultimo aggiornamento**: 2026-08-17
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-038/`
- **Handoff**: CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX

## Dipendenze

- **Dipende da**: TASK-002, TASK-021, TASK-032, TASK-033, TASK-036, TASK-037
- **Sblocca**: TASK-039, TASK-040
- **Writer**: Client; Admin read-only salvo regressione cross-repo reale

## Scope

- auditare e correggere nome/display name, bundle/package, icon set, adaptive icon,
  splash/launch screen, versione/build, permission rationale e privacy manifest;
- preparare metadata Play internal testing, App Store/TestFlight, screenshot matrix,
  data-safety/app-privacy evidence, review notes, attribution e licenze OSS;
- documentare privacy policy, supporto, account deletion e legal URL con template
  `NEEDS_OWNER_VALUE` per identità o dichiarazioni non determinabili;
- creare una release configuration matrix development/staging/production con campi
  required/optional/forbidden/fallback/validation e comportamento fail-closed;
- verificare dipendenze/licenze e debt bounded senza upgrade indiscriminati;
- mantenere zero secret, zero dati reali e zero dichiarazioni legali inventate.

## Non incluso

- upload Play Console/TestFlight, firma release o store submission (TASK-039/040);
- acquisti, billing Maps, creazione di email/URL o identità societarie inesistenti;
- approvazione legale o compilazione falsa di data-safety/app-privacy;
- production migration, go-live o modifiche ai repository read-only.

## Criteri di accettazione

| CA | Descrizione | Tipo |
|---|---|---|
| CA-01 | Identità, versione, bundle/package, icon/adaptive icon e launch asset sono completi e validi | STATIC/BUILD |
| CA-02 | Permission rationale e privacy manifest native sono minimi, coerenti e fail-closed | STATIC/SECURITY |
| CA-03 | Metadata Android/iOS, screenshot matrix e review notes sono pronti per i valori determinabili | REVIEW |
| CA-04 | Privacy/data declarations derivano da capability e dipendenze reali, senza claim inventati | SECURITY/REVIEW |
| CA-05 | Policy/support/account deletion/legal URL distinguono valori reali da `NEEDS_OWNER_VALUE` | REVIEW |
| CA-06 | Licenze OSS e attribution Maps hanno provenance e obblighi verificati | STATIC/REVIEW |
| CA-07 | Matrice development/staging/production copre tutti i provider e fallisce chiusa | UNIT/STATIC |
| CA-08 | Audit dependency/debt bounded non lascia fixture/debug/helper nel release path | STATIC/TEST |
| CA-09 | Gate dual-platform, review indipendente, CI exact-SHA e zero P0/P1/P2 sono reali | CI/REVIEW |

## Test case

| Test | Criteri | Procedura attesa |
|---|---|---|
| T-01 | CA-01/02 | Ispezione manifest/plist/project, asset dimensions/alpha, build Android/iOS |
| T-02 | CA-03/04/05 | Validator metadata/template e mapping capability→declaration con negative fixture |
| T-03 | CA-06 | Inventario package/licenze/attribution e controllo obblighi/file mancanti |
| T-04 | CA-07 | Validator config sui tre ambienti, secret scanner e failure negative |
| T-05 | CA-08 | outdated bounded + scan TODO/FIXME/HACK/skip/debug/fixture production path |
| T-06 | CA-09 | check canonico, security diff, review distinta, PR/main CI e hygiene |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Sostituire l'icona Flutter predefinita con un mark originale e senza testo | Store readiness e leggibilità small-size | ATTIVA |
| D-02 | Conservare gli identificatori già integrati salvo incompatibilità provata | Evita rottura OAuth/link/signing | ATTIVA |
| D-03 | Ogni valore non verificabile è `NEEDS_OWNER_VALUE`, mai inventato | Integrità legal/privacy | ATTIVA |
| D-04 | Metadata e config hanno validator automatici con fixture negative | Evita readiness solo documentale | ATTIVA |
| D-05 | Il mandato 2026-08-16 autorizza Planning→Execution | ADR-015 | ATTIVA |

## Planning — `CODEX_PLANNER`

1. inventariare identità, asset, permission, capability, dipendenze e URL correnti;
2. classificare ogni campo come determinabile, owner value o task release successivo;
3. implementare asset/native privacy e documenti/validator con scope minimo;
4. eseguire build, test, scanner, audit dipendenze/licenze e asset inspection;
5. produrre evidence CA/T e consegnare a reviewer read-only distinto.

### Rischi

- branding proprietario non definito: mark neutro originale coerente con i design
  token, senza società o claim;
- usage description sovra-dichiarata: dichiarare solo capability native realmente
  invocate e motivazione prodotto verificata;
- licenze incomplete: ricavare inventory dal lockfile e separare obblighi da review
  counsel quando l'interpretazione non è tecnica;
- store claim prematuri: distinguere draft, validator PASS e owner approval.

### Handoff a Execution

- **Autorizzazione USER_APPROVER**: mandato 2026-08-16 e ADR-015
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Execution — `CODEX_EXECUTOR`

Completata sul candidate tecnico
`fe8c5824921508086d68fa43f5d658c72b80e2b4`:

- identità native, icone Android/iOS, adaptive/themed icon e launch asset reali;
- manifest privacy iOS app-owned con sette tipi linked, App Functionality e
  tracking disabilitato, incluso e verificato nel bundle Simulator;
- metadata store, screenshot matrix, privacy/data-safety evidence, TestFlight e
  internal-testing notes per tutti i valori determinabili;
- valori legal, support, policy e store-owner non inventabili classificati
  `NEEDS_OWNER_VALUE` con owner e activation gate;
- matrice release 12 capability × 3 ambienti e validator automatico con fixture
  negative, incluso il rifiuto di manifest privacy vuoti/incompleti;
- audit dipendenze/licenze/debt bounded, nessun upgrade indiscriminato;
- gate canonico completo, build dual-platform, scan artifact, smoke Emulator e
  Simulator verdi; device fisici iOS offline e nessun Android fisico disponibile.

La review security diff-scoped canonica `e8233586-d75a-4e1d-9bb7-cb356d544f77`
non ha finding security reportable. Tre problemi di release review emersi durante
l'Execution sono stati corretti prima dell'handoff: fixture secret-shaped nel gate,
privacy manifest app-owned vuoto e percorso workstation nella provenance asset.

**Handoff**: `CODEX_EXECUTION_COMPLETE_TO_REVIEW`.

## Review — `CODEX_REVIEWER`

Review indipendente read-only su
`c7af4ca37ec05e5caabee73906e1844793e430b4`: `CHANGES_REQUIRED`.

- `F-038-R01` — P2: checkout invia `p_payment_method` al backend, ma manifest,
  validator ed evidence omettono `NSPrivacyCollectedDataTypePaymentInfo`;
- impatto: CA-02, CA-04 e T-02 non soddisfatti; la scelta del metodo
  `pay_at_pickup` è una forma di pagamento raccolta in-app;
- riproduzione reviewer: checkout probe 1/1 prova il payload, `plutil` prova
  l'assenza del tipo e validator 4/4 prova il falso PASS;
- altri finding: zero P0/P1/P3; i tre gap pre-handoff sono chiusi.

**Handoff**: `CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Fix — `CODEX_FIXER`

In corso, limitato a `F-038-R01`.

## Chiusura

- **Conferma utente**: ricevuta e condizionata a review/gate reali
- **Merge autorizzato**: dopo review `APPROVED` e CI exact-SHA verde
- **Follow-up candidate**: TASK-039
- **Data completamento**: non ancora
