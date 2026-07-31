# Android Google Auth smoke — TASK-020

## Target

- Android Emulator `emulator-5554`;
- application ID canonico;
- staging locale ignorato con kill switch `false`;
- nessun account, code, token, callback completo o dato personale persistito.

## Gate eseguiti

| Verifica | Esito | Risultato |
|---|---|---|
| APK debug development | PASS | build reale, exit 0 |
| APK debug staging | PASS | build reale, exit 0 |
| Manifest merged | PASS | backup off; handler Flutter off; un solo filter esatto |
| Routing URI canonico | PASS | `MainActivity` risolta; processo vivo |
| Routing host/path errati | PASS | Activity non risolta |
| Guest flow | PASS | integration test device |
| Callback flow fake | PASS | login, callback, restore, logout, invalido |
| Backend readiness staging | PASS | health Auth data-free |
| Callback warm nativo `app_links` | PASS | ADB delivery, validazione canonica, zero exchange |
| Crash/ANR deterministico | PASS | nessun crash; processo vivo |

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
