# Environment audit — TASK-020

## Toolchain

| Controllo | Esito | Dettaglio sanitizzato |
|---|---|---|
| Flutter | PASS | stable 3.44.8 |
| Dart | PASS | 3.12.2 |
| Xcode | PASS | 26.6 |
| Java | PASS | OpenJDK 21 |
| Supabase CLI | PASS | 2.110.0, accesso remoto non usato per write in Planning |
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

Compatibilità verificata: Flutter/Dart correnti, Android API minima Flutter e iOS
deployment target 13 soddisfano i requisiti di `flutter_secure_storage 10.3.1`.

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
| Write remoto Execution | NOT_RUN | nessun point-update sicuro disponibile; zero modifiche remote |
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

- La dashboard ha raggiunto il controllo MFA; non sono stati inseriti fattori,
  password, OTP o altre credenziali.
- Il connector Supabase espone discovery/database ma non Auth config o redirect
  allow-list; il CLI non offre un point-update sicuro equivalente.
- Il simulatore iOS richiede conferma OS per aprire il custom scheme e il Mac locked
  impedisce l'interazione locale.
- La CI closeout TASK-012 ha fallito prima del runner per billing/spending GitHub;
  TASK-020 dovrà tentare CI reale e registrare `BLOCKED / CI_EXTERNAL` se il limite
  persiste.
