# Evidence TASK-018

Snapshot di handoff:
`VALIDATED_PENDING_INTEGRATED_REVIEW / VALIDATED_PENDING_INTEGRATED_REVIEW / CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`.

- Planning: `PASS` — scope, criteri, test, decisioni e rischi registrati.
- Dipendenze: `PASS` — TASK-012 e checkpoint TASK-016/TASK-017 disponibili.
- Implementazione: `PASS` — Drift v2 favorites, repository boundary, controller/UI,
  `ShareRequest`/`ShareResult`/service/link builder, `share_plus 13.2.1`, codec/router
  strict e source `app_links` unico sullo SHA tecnico `a0e139a6365dc4639ba66c110c91dcc2720feee5`.
- Gate locale completo: `PASS` — `scripts/check.sh`, exit 0 in 79,66 s; 329 test;
  coverage 4.249/5.199 (81,73%); security
  415 file; fixture security 32/32 negative e 2/2 positive; governance 8/8;
  architecture 7/7; analyze e build Android/iOS.
- CI: `PASS` — run `30751191932`, Quality 4m23s, iOS 3m38s e Android 8m41s,
  tutti gli step applicabili `success`, annotation 0/0/0 sullo SHA esatto.
- Favorite live staging: `PASS` — Android 1/1 in 23 s; iOS 1/1 in 6 s; persistito
  dopo dispose/reopen e ripulito senza write customer server-side.
- Deep link/Share Android: `PASS` — product cold, category warm e altro shop ignorato;
  sul build staging esatto il tap accessibility apre un solo chooser `ACTION_SEND`
  `text/plain`, con subject/testo/URL pubblici; cancel ritorna all'app, PID `26527`
  invariato e doppio tap produce un solo record chooser.
- Deep link iOS: `PASS` — product cold, category warm e altro shop ignorato.
- Share iOS XCTest: `PASS` — `xcodebuild test` su iPad (A16), iOS Simulator 26.5,
  exit 0; `xcresulttool get test-results summary` exit 0, 3/3 test in 13,54 s. Un vero
  `UIActivityViewController` viene creato e presentato su host/window attivi; item,
  URL, dati vietati, main thread, presentation context, popover iPad, cancel/completion,
  single-flight e background/resume sono asseriti.
- Share iOS visuale manuale: `NOT_RUN` — sostituito dalla decisione USER_APPROVER
  D-08 con gate XCTest nativo più forte e riproducibile; non è un blocker.
- Log live: `PASS` — zero match Android/iOS per access/refresh token, bearer o OAuth
  code.
- Artifact candidato: `PASS` — build staging APK exit 0 in 8,15 s, SHA-256
  `5bd05d1e4a923ee7a62d8533321d6315513c6dd6754559a58e3aa41efa4be54e`; Runner
  Simulator executable SHA-256
  `3f19e6660670e6d1221c313cd9ba247e7f8c0515d3c42c9322aa81e52803d6f0`.
- Tentativi corretti: `FAIL` — fixture UUID non discriminante, overflow/Semantics a
  200%, queue router pre-init, race bootstrap categoria, shop harness Android errato,
  lifecycle/dismiss/parallelismo XCTest e un lint del nuovo test; cause corrette e
  rerun finali pertinenti `PASS`.
- Review integrata: `NOT_RUN`.
- Production write: `NOT_RUN` — vietata prima dei gate finali.

## Comandi headless finali

- Flutter: `bash scripts/check.sh` — exit 0, 79,66 s, 329/329 test e coverage
  4.249/5.199; il primo run exit 1 in 34,33 s sul lint poi corretto non è occultato.
- iOS: `xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner -destination
  'platform=iOS Simulator,name=iPad (A16),OS=26.5' -resultBundlePath
  /tmp/storefront-task018-ios-stable.egWvZY/RunnerTests.xcresult` — exit 0;
  `xcrun xcresulttool get test-results summary --path
  /tmp/storefront-task018-ios-stable.egWvZY/RunnerTests.xcresult --format json` —
  exit 0, 3 passed/0 failed/0 skipped.
- Android build: `flutter build apk --debug
  --dart-define-from-file=config/app_config.staging.local.json` — exit 0, 8,15 s.
- Android runtime: `adb install -r`, `adb shell am start -W -a android.intent.action.VIEW
  -d <URI-pubblico>`, accessibility dump/tap Share, `dumpsys activity activities`,
  cancel e doppio tap — tutti exit 0; focus chooser reale, record chooser 1 e PID
  applicazione invariato. L'URI completo è pubblico e registrato nel task, non contiene
  credenziali o ID inventory.
