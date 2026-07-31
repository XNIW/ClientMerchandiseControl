# iOS Google Auth smoke — TASK-020

## Target

- iPhone 17 Pro Simulator, iOS 26.5;
- bundle ID canonico;
- staging locale ignorato con kill switch `false`;
- nessun signing o provisioning production.

## Gate eseguiti

| Verifica | Esito | Risultato |
|---|---|---|
| iOS Simulator debug development | PASS | CMD-F01, exit 0 |
| iOS Simulator debug staging | PASS | CMD-F03, exit 0 |
| Plist compilato | PASS | CMD-F01; un solo scheme, handler Flutter off, SceneDelegate risolto |
| Guest flow | PASS | CMD-F07, exit 0 |
| Callback flow fake | PASS | CMD-F07; login, callback, Account, restore, logout, invalido |
| Backend readiness staging | PASS | CMD-F08; health Auth data-free |
| Scheme/host/path validator | PASS | CMD-F01; iOS filtra scheme, Dart rifiuta host/path |
| LaunchServices canonical | PASS | CMD-F09; `simctl` exit 0 e bundle risolto |
| Callback warm nativo `app_links` | BLOCKED | CMD-F09; harness timeout 30 s, conferma OS pendente, Mac locked |
| Crash deterministico | PASS | CMD-F07/F08/F09; nessun crash, processo vivo |

La build contiene forwarding manuale convergente a `AppLinks.shared` in
`AppDelegate` e `SceneDelegate`, con auto-handling plugin disabilitato. Il log di
sistema mostra che LaunchServices trova il bundle, ma presenta il dialogo locale
“Vuoi aprire l'elemento…”; il controllo UI non può accettarlo perché il Mac è locked.

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
| 10 | Accetta conferma custom scheme | BLOCKED |
| 11 | Ritorno callback reale | NOT_RUN |
| 12 | Account authenticated | NOT_RUN |
| 13 | Terminate/relaunch e restore | NOT_RUN |
| 14 | Logout locale | NOT_RUN |
| 15 | Verifica guest post-logout | NOT_RUN |
| 16 | Error/offline/background matrix live | NOT_RUN |
| 17 | Crash/log sanitizzati live | NOT_RUN |

Non sono stati inseriti password, MFA, OTP, CAPTCHA o credenziali e non è stato
modificato alcun setting remoto.

Matrice CA/T e comandi canonici:
`commands-and-results.md`, CMD-F01/F03/F07/F08/F09/CMD-R01, CA-10/27/29/31 e
T-07/22/23/24/31/33.
