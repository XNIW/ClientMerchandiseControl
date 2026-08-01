# iOS Google Auth smoke — TASK-020

## Target

- iPhone 17 Pro Simulator `240F400E-5EFA-486A-9137-FFBBE70F604D`, iOS 26.5;
- revision set tecnico Fix 3 `5740c835a116af16ab2e7ca6c55c927d180ece90`;
- revision set live `671494f83aecf423075348d2efa10da835295984`;
- bundle ID canonico;
- staging locale ignorato con kill switch `true` soltanto durante lo smoke e poi
  riportato a `false`;
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
| 2 | Verifica allow-list before | PASS |
| 3 | Append callback esatta | PASS |
| 4 | Verifica allow-list after e reload | PASS |
| 5 | Abilita kill switch locale ignorato | PASS |
| 6 | Installazione pulita | PASS |
| 7 | Avvio guest | PASS |
| 8 | Tap Google una volta | PASS |
| 9 | Browser/account test già presente | PASS |
| 10 | Accetta conferma custom scheme nel flusso live | PASS |
| 11 | Ritorno callback reale warm | PASS |
| 12 | Account authenticated | PASS |
| 13 | Terminate/relaunch e restore | PASS |
| 14 | Logout locale | PASS |
| 15 | Verifica guest e nuovo login | PASS |
| 16 | Background/resume e callback cold a processo terminato | PASS |
| 17 | Crash/log sanitizzati live | PASS |

Build Simulator staging completata in 24,0 s e installazione pulita exit 0. Il flusso
Google reale ha completato callback warm, Account authenticated, background/resume,
terminate/relaunch restore e logout. Dopo un nuovo login, il processo client è stato
terminato mentre il callback custom-scheme era pendente: il tap `Apri` ha avviato
l'app cold e Account è risultato authenticated. Il logout finale ha lasciato il guest.

La scansione dei log `Runner` live rileva zero access token, refresh token, bearer,
JWT e callback con code. Log e screenshot grezzi non sono stati versionati e sono stati
spostati nel Cestino. Non sono stati inseriti password, MFA, OTP, CAPTCHA o nuove
credenziali e non è stato modificato signing/provisioning production.

Matrice CA/T e comandi canonici:
`commands-and-results.md`, CMD-X01/X05/X09/X10/X11/CMD-P01/P08/P09/P11/P12, CA-10/27/29/31 e
T-07/22/23/24/31/33.
