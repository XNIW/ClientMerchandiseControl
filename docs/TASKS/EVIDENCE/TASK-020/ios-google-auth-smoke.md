# iOS Google Auth smoke — TASK-020

## Target

- iPhone 17 Pro Simulator `240F400E-5EFA-486A-9137-FFBBE70F604D`, iOS 26.5;
- revision set tecnico Fix 3 `5740c835a116af16ab2e7ca6c55c927d180ece90`;
- ripresa Prelude verificata sullo SHA `06768266fdba498011a65102472c66d482c2f8b6`;
- bundle ID canonico;
- staging locale ignorato con kill switch `false`;
- nessun signing o provisioning production.

## Gate eseguiti

| Verifica | Esito | Risultato |
|---|---|---|
| iOS Simulator debug development | PASS | CMD-X01, exit 0 |
| iOS Simulator debug staging | PASS | CMD-X05, exit 0 |
| Plist compilato | PASS | CMD-X01; un solo scheme, handler Flutter off, SceneDelegate risolto |
| Guest flow | PASS | CMD-X09, exit 0 |
| Callback flow fake | PASS | CMD-X09; login, callback, Account, restore, logout, invalido |
| Backend readiness staging | PASS | CMD-X10; health Auth data-free |
| Scheme/host/path validator | PASS | CMD-X01; iOS filtra scheme, Dart rifiuta host/path |
| LaunchServices canonical | PASS | CMD-X11; `simctl` exit 0 e dialogo OS mostrato dal bundle |
| Callback warm nativo `app_links` | PASS | CMD-P01; `simctl` exit 0, harness exit 0, 1/1 |
| Crash deterministico | PASS | CMD-X09/X10/P01; nessun crash, processo vivo |

La build contiene forwarding manuale convergente a `AppLinks.shared` in
`AppDelegate` e `SceneDelegate`, con auto-handling plugin disabilitato. Il log di
sistema storico mostrava che LaunchServices trovava il bundle ma il dialogo locale
non era accettabile con il Mac locked. Nella ripresa del 2026-08-01 il Simulator ha
consegnato realmente il callback warm allo stesso processo: validazione canonica,
zero exchange, processo vivo e test 1/1 `PASS`. Nessuno screenshot è versionato.

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
| 10 | Accetta conferma custom scheme nel flusso live | NOT_RUN |
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
`commands-and-results.md`, CMD-X01/X05/X09/X10/X11/CMD-P01/CMD-R01, CA-10/27/29/31 e
T-07/22/23/24/31/33.
