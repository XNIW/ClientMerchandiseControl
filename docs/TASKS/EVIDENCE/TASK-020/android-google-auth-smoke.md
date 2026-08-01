# Android Google Auth smoke — TASK-020

## Target

- Android Emulator `emulator-5554`;
- revision set live `671494f83aecf423075348d2efa10da835295984`;
- application ID canonico;
- staging locale ignorato con kill switch `true` soltanto durante lo smoke e poi
  riportato a `false`;
- nessun account, code, token, callback completo o dato personale persistito.

## Gate eseguiti

| Verifica | Esito | Risultato |
|---|---|---|
| APK debug development | PASS | CMD-X01, exit 0 |
| APK debug staging | PASS | CMD-X05, exit 0 |
| Manifest merged | PASS | CMD-X01; backup off, handler Flutter off, un solo filter esatto |
| Routing URI canonico | PASS | CMD-X08; `MainActivity` risolta, processo vivo |
| Routing host/path errati | PASS | suite nativa CMD-X01; Activity non risolta |
| Guest flow | PASS | CMD-X06, exit 0 |
| Callback flow fake | PASS | CMD-X06; login, callback, Account, restore, logout, invalido |
| Backend readiness staging | PASS | CMD-X07; health Auth data-free |
| Callback warm nativo `app_links` | PASS | CMD-X08; ADB SDK esplicito, evento/validator, zero exchange |
| Crash/ANR deterministico | PASS | CMD-X06/X07/X08; nessun crash, processo vivo |

## Smoke Google live in 17 passi

| # | Passo | Esito |
|---:|---|---|
| 1 | Verifica progetto/provider e build staging | PASS |
| 2 | Verifica allow-list before | PASS |
| 3 | Append callback esatta | PASS |
| 4 | Verifica allow-list after e reload | PASS |
| 5 | Abilita kill switch locale ignorato | PASS |
| 6 | Installazione pulita | PASS |
| 7 | Avvio guest | PASS |
| 8 | Tap Google una volta | PASS |
| 9 | Browser/account test già presente | PASS |
| 10 | Ritorno callback reale | PASS |
| 11 | Account authenticated | PASS |
| 12 | Terminate/relaunch e restore | PASS |
| 13 | Logout locale | PASS |
| 14 | Verifica guest post-logout | PASS |
| 15 | Relogin | PASS |
| 16 | Error/offline/background matrix live | PASS |
| 17 | Crash/ANR/log sanitizzati live | PASS |

APK staging costruito in 43,5 s, installazione pulita exit 0. Supabase ha registrato
authorize/callback e token exchange PKCE HTTP 200; la UI Account è diventata
authenticated. Force-stop/relaunch e background/resume hanno preservato la sessione;
logout ha reso guest e il relogin ha autenticato di nuovo. Il probe logout con
`airplane_mode=1` è rimasto guest fail-closed e la rete è stata ripristinata; un
callback provider cancellato non ha autenticato. I casi double tap, config mancante,
URI invalido e ritorno senza sessione sono completati dalle suite device già eseguite.

La scansione del logcat live rileva zero access token, refresh token, bearer, JWT e
callback con code. Log e screenshot grezzi sono rimasti fuori dal repository e sono
stati spostati nel Cestino dopo la verifica. Il primo comando storico con `adb` assente
dal `PATH` resta `FAIL` diagnostico CMD-D07; il gate conforme usa il path SDK esplicito.

Matrice CA/T e comandi canonici:
`commands-and-results.md`, CMD-X01/X05/X06/X07/X08/CMD-D07/CMD-P08/P09/P10/P12,
CA-09/27/29/30 e
T-06/22/23/24/30/32.
