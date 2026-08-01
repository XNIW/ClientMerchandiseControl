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
| Redirect mobile before | PASS | 16 redirect; callback esatta assente |
| Write remoto TASK-020 | PASS | append singolo dal Dashboard autenticato |
| Redirect mobile after | PASS | 17 redirect; callback esatta presente, precedenti preservati |
| Provider Google corrente | PASS | `Google Enabled` nel Dashboard Auth |
| Production | PASS | zero navigazioni o mutazioni production |

Il connector Supabase è stato usato per discovery/log read-only; il solo write è stato
l'append autorizzato dal Dashboard staging. Nessun project ref completo, URL, key,
token, provider client ID o secret è persistito.

## Config locale staging

Controllo deterministico sul file ignorato:

- object con esattamente i cinque input contrattuali: `PASS`;
- `APP_ENV=staging`: `PASS`;
- URL e publishable key presenti, senza stamparli: `PASS`;
- callback esatta: `PASS`;
- `GOOGLE_AUTH_ENABLED=false`: `PASS`;
- `git check-ignore`: `PASS`;
- assenza da `git ls-files`: `PASS`.

Il flag è stato portato temporaneamente a `true` dopo la persistenza della allow-list,
usato per build/smoke reali e riportato a `false`. Il file resta locale, ignorato e non
entra in stage, diff o evidence.

## Limiti osservati

- Il piano FREE mostra grace period concluso ed egress 3,78/5 GB: rischio quota da
  monitorare, senza upgrade o modifica billing autorizzata.
- Android Emulator API 35 e iPhone 17 Pro Simulator iOS 26.5 hanno completato OAuth,
  restore, logout e nuovo login reali; callback iOS warm e cold entrambe `PASS`.
- La CI TASK-020 run `30709395137` sullo SHA `671494f` è `PASS`: Android,
  iOS e Quality 3/3, tutti gli step applicabili `success` e zero annotation.

Matrice CA/T e comandi canonici:
`commands-and-results.md`, CMD-X01/X02/CMD-Z01/Z02/Z04/CMD-P01/P08/P09/P10/P11/P12/P13,
CA-01/03/04/11…CA-13/35…CA-39 e T-01…T-04/26…T-36.
