# Planning summary — TASK-020

## Autorità e baseline

- TASK-004, TASK-011 e TASK-012: `DONE`.
- Stato iniziale: repository `IDLE`, worktree pulito, branch milestone allineato a
  origin sul commit `9ab32c9`.
- Autorità: prompt end-to-end `USER_APPROVER`, da applicare con transizioni e commit
  distinti.
- Fonti: Master Plan, protocollo, quality gates, Definition of Done, template,
  TASK-004/011/012, richiesta allegata, codice/test/evidence pertinenti, sorgenti
  package bloccati, changelog e documentazione Supabase corrente.
- Audit: tre shard read-only indipendenti hanno verificato API/storage, configurazione
  nativa e architettura; un quarto shard ha costruito la matrice 40 CA / 38 test e un
  quinto ha preparato il threat model target-scoped.

## Gap verificati

- `SupabaseBootstrap` usa oggi `autoRefreshToken:false`,
  `detectSessionInUri:false`, `EmptyLocalStorage` e PKCE storage no-op.
- `supabase_flutter 2.16.0` usa SharedPreferences per sessione e verifier PKCE quando
  non riceve storage custom.
- Il deep-link handler SDK non verifica scheme/host/path e può elaborare token
  implicit; non può essere il confine di callback di TASK-020.
- Android e iOS non registrano ancora lo scheme; Flutter deep linking non è ancora
  disabilitato a livello nativo.
- `AccountScreen` è guest statico; Auth non ha repository, controller, stream,
  lifecycle o wiring eager.
- Il callback config è già canonico e production resta fail-closed.
- L'avatar TASK-012 accetta soltanto bytes locali; `avatar_url` non può essere
  collegato direttamente.
- Il file staging locale è ignorato, ha shape valida e flag Google ancora `false`.
- Il progetto staging canonico è sano; provider/allow-list correnti devono essere
  riconfermati prima del write.

## Decisioni tecniche

1. Supabase OAuth Google + PKCE + `LaunchMode.externalApplication`.
2. Nessun `google_sign_in`.
3. `detectSessionInUri:false`; un solo `AppLinks` coordinator valida callback e
   inoltra esclusivamente il code PKCE.
4. `flutter_secure_storage 10.3.1` protegge sessione e verifier; nessun fallback
   plaintext.
5. `app_links 7.2.1` diventa dipendenza diretta.
6. Feature `auth` con dominio/repository/controller Riverpod; Account non importa
   Supabase.
7. Controller eager, single-flight, generation-safe e lifecycle-aware.
8. Navigazione ad Account soltanto dopo callback autenticata, non dopo cold restore.
9. Metadata bounded/presentazionali, ID interno, avatar fallback locale.
10. Un solo append esatto alla allow-list staging con before/after sanitizzato.

## Confini

- Nessuna query, tabella, RPC, Storage, schema, migration o RLS.
- Nessun profilo TASK-021, catalogo data-backed, ordine o pagamento.
- Nessuna produzione, Universal Link, signing o store release.
- Nessun nuovo account, password, MFA, secret o credenziale privilegiata.
- Nessun task futuro o repository esterno modificato.

## Baseline eseguita

| Gate | Esito | Evidence |
|---|---|---|
| Git/worktree/origin | PASS | branch milestone pulito e allineato su `9ab32c9`, exit 0 |
| Config staging locale | PASS | cinque chiavi, callback esatta, flag Google false, file ignorato/non tracciato, exit 0 |
| Supabase project discovery | PASS | un solo progetto non-production canonico `ACTIVE_HEALTHY`; output non persistito |
| API/package audit | PASS | 2.16.0/2.14.0/2.26.0/7.2.1 e firme reali verificate |
| `flutter analyze` | PASS | zero issue, exit 0 |
| `flutter test --reporter compact` | PASS | 141/141, exit 0 |
| Secret/artifact tracked scan | PASS | nessun match, exit 0 |
| Dashboard Auth corrente | BLOCKED | browser in-app non autenticato; Chrome connector non disponibile |
| Implementazione | NOT_RUN | fase Execution non ancora applicata |
| Build/smoke/review/CI | NOT_RUN | dipendono dallo SHA tecnico |

## Rischi esterni

- CI GitHub può restare `BLOCKED / CI_EXTERNAL` per billing/spending prima del runner.
- Provider/redirect staging richiedono accesso dashboard o Management API
  autenticato.
- OAuth live richiede un account Google test già autenticato; password, MFA, CAPTCHA
  o nuova registrazione non sono autorizzati.

## Handoff

`CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION`
