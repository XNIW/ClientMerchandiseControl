# Environment audit — TASK-020

## Toolchain

| Controllo | Esito | Dettaglio sanitizzato |
|---|---|---|
| Flutter | PASS | stable 3.44.8 |
| Dart | PASS | 3.12.2 |
| Xcode | PASS | 26.6 |
| Java | PASS | OpenJDK 21 |
| Supabase CLI | PASS | 2.110.0, accesso remoto solo read-only; zero write |
| Android application ID | PASS | `com.xniw.clientmerchandisecontrol` |
| iOS bundle ID | PASS | `com.xniw.clientmerchandisecontrol` |
| Branch | PASS | `milestone/011-012-020-authenticated-storefront-foundation` |

## Dipendenze Auth bloccate

| Package | Versione | Stato |
|---|---:|---|
| `supabase_flutter` | 2.16.0 | direct |
| `supabase` | 2.14.0 | transitive |
| `gotrue` | 2.26.0 | transitive |
| `app_links` | 7.2.1 | direct |
| `shared_preferences` | 2.5.5 | direct; già transitiva nella baseline, solo marker booleani non sensibili |
| `flutter_secure_storage` | 10.3.1 | direct |
| `path_provider` | 2.1.6 | direct; già risolta transitivamente, promossa per il solo path del journal non sensibile Application Support |

Compatibilità verificata: Flutter/Dart correnti, Android API minima Flutter e iOS
deployment target 13 soddisfano i requisiti di `flutter_secure_storage 10.3.1` e
`path_provider 2.1.6`.

## Supabase staging

| Controllo | Esito | Dettaglio sanitizzato |
|---|---|---|
| Progetti disponibili | PASS | uno solo, non-production canonico |
| Stato progetto | PASS | `ACTIVE_HEALTHY` |
| Regione | PASS | Sud America |
| Health Auth TASK-011 | PASS | endpoint ufficiale, data-free |
| Provider Google TASK-011 | PASS | configurato, non modificato |
| Provider Google corrente | PASS | settings Auth pubblici: Google attivo; due provider esterni attivi |
| Authorize Google corrente | PASS | risposta 302 verso il dominio Google; redirect non seguito |
| Redirect mobile TASK-011 | PASS | risultava assente e riservato a TASK-020 |
| Redirect mobile corrente | BLOCKED | dashboard fermata da MFA; connector senza Auth config |
| Write remoto TASK-020 | NOT_RUN | nessun point-update sicuro disponibile; zero modifiche remote |
| Production | NOT_RUN | fuori scope e non ispezionata/modificata |

Il connector Supabase è stato usato soltanto per discovery read-only e documentazione.
Nessun project ref, URL, key, token, provider client ID o secret è persistito.

## Config locale staging

Controllo deterministico sul file ignorato:

- object con esattamente i cinque input contrattuali: `PASS`;
- `APP_ENV=staging`: `PASS`;
- URL e publishable key presenti, senza stamparli: `PASS`;
- callback esatta: `PASS`;
- `GOOGLE_AUTH_ENABLED=false`: `PASS`;
- `git check-ignore`: `PASS`;
- assenza da `git ls-files`: `PASS`.

Il flag resta `false`: la verifica/addizione allow-list non è stata possibile. Il file
resta locale, ignorato e non entra in stage, diff o evidence.

## Limiti osservati

- Il Dashboard richiede un nuovo login GitHub/MFA e la Management API restituisce
  HTTP 401 dal token CLI in Keychain; non sono stati inseriti o stampati fattori,
  password, OTP, token o altre credenziali.
- Il connector Supabase espone discovery/database ma non Auth config o redirect
  allow-list; il CLI non offre un point-update sicuro equivalente.
- Il simulatore iOS ha consegnato il callback warm canonico in CMD-P01: harness
  1/1 `PASS`, exit 0. OAuth live resta distinto e non è inferito.
- La CI TASK-020 run `30632938353` sullo SHA `0676826` ha tre job
  senza step, `runner_id=0` e una annotation/job per billing/spending GitHub;
  resta `BLOCKED / CI_EXTERNAL`.

Matrice CA/T e comandi canonici:
`commands-and-results.md`, CMD-X01/X02/CMD-Z01/Z02/Z04/CMD-R01/CMD-P01/P02/P03,
CA-01/03/04/11…CA-13/35…CA-39 e T-01…T-04/26…T-36.
