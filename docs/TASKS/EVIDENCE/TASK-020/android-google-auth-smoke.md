# Android Google Auth smoke — TASK-020

## Target

- Android Emulator `emulator-5554`;
- application ID canonico;
- staging locale ignorato con kill switch `false`;
- nessun account, code, token, callback completo o dato personale persistito.

## Gate eseguiti

| Verifica | Esito | Risultato |
|---|---|---|
| APK debug development | PASS | CMD-F01, exit 0 |
| APK debug staging | PASS | CMD-F03, exit 0 |
| Manifest merged | PASS | CMD-F01; backup off, handler Flutter off, un solo filter esatto |
| Routing URI canonico | PASS | CMD-F06; `MainActivity` risolta, processo vivo |
| Routing host/path errati | PASS | suite nativa CMD-F01; Activity non risolta |
| Guest flow | PASS | CMD-F04, exit 0 |
| Callback flow fake | PASS | CMD-F04; login, callback, Account, restore, logout, invalido |
| Backend readiness staging | PASS | CMD-F05; health Auth data-free |
| Callback warm nativo `app_links` | PASS | CMD-F06; ADB/event/validator, zero exchange |
| Crash/ANR deterministico | PASS | CMD-F04/F05/F06; nessun crash, processo vivo |

## Smoke Google live in 17 passi

| # | Passo | Esito |
|---:|---|---|
| 1 | Verifica progetto/provider e build staging | PASS |
| 2 | Verifica allow-list before | BLOCKED |
| 3 | Append callback esatta | NOT_RUN |
| 4 | Verifica allow-list after | NOT_RUN |
| 5 | Abilita kill switch locale | NOT_RUN |
| 6 | Installazione pulita | NOT_RUN |
| 7 | Avvio guest | NOT_RUN |
| 8 | Tap Google una volta | NOT_RUN |
| 9 | Browser/account test già presente | NOT_RUN |
| 10 | Ritorno callback reale | NOT_RUN |
| 11 | Account authenticated | NOT_RUN |
| 12 | Terminate/relaunch e restore | NOT_RUN |
| 13 | Logout locale | NOT_RUN |
| 14 | Verifica guest post-logout | NOT_RUN |
| 15 | Relogin | NOT_RUN |
| 16 | Error/offline/background matrix live | NOT_RUN |
| 17 | Crash/ANR/log sanitizzati live | NOT_RUN |

Il blocco è esterno e preciso: Supabase dashboard richiede MFA per leggere/applicare
l'allow-list e nessuna API point-update sicura è disponibile. Il flag è rimasto
`false`; nessuna credenziale è stata inserita e nessun write remoto è stato eseguito.

Matrice CA/T e comandi canonici:
`commands-and-results.md`, CMD-F01/F03/F04/F05/F06/CMD-R01, CA-09/27/29/30 e
T-06/22/23/24/30/32.
