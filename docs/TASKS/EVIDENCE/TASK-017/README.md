# Evidence TASK-017

Snapshot di handoff:
`VALIDATED_PENDING_INTEGRATED_REVIEW / VALIDATED_PENDING_INTEGRATED_REVIEW / CODEX_EXECUTION_VALIDATED_PENDING_INTEGRATED_REVIEW`.

- Planning: `PASS` — scope, criteri, test, decisioni e rischi registrati.
- Dependency audit: `PASS` — Drift `2.34.3`, drift_flutter `0.3.1`, sqlite3 `3.5.0`
  e drift_dev `2.34.5` MIT; `build_runner 2.15.1` massimo risolvibile con Flutter.
- Dipendenze: `PASS` — TASK-010 e TASK-014 validati; TASK-013..016 checkpoint verdi.
- Implementazione: `PASS` — Drift schema v1 pubblico/shop-scoped, SWR, invalidazione
  transazionale, search offline, recovery e cleanup bounded sullo SHA
  `e5f4bd8d14da08e9e8f43284944d8257c0b02693`.
- Gate locale completo: `PASS` — exit 0 in 74,17 s; 303 test; coverage 3.872/4.747
  (81,57%); security 402 file; governance 8/8; architecture 7/7; Android/iOS build.
- Suite cache: `PASS` — 19/19 in 3,00 s; 25.000 righe; open 247 ms, write 20k
  444 ms, catalog p50/p95/p99 601/1.195/7.528 µs, search 3.166/3.824/6.482 µs.
- CI: `PASS` — run `30737515662`, Quality 4m02s, iOS 4m15s, Android 8m49s,
  annotation 0/0/0 sullo SHA esatto.
- Staging offline/reconnect smoke: `PASS` — Android finale 1/1 in 45,98 s; iOS
  finale 1/1 in 27,09 s; staging seed/reconnect reali e perdita rete controllata al
  boundary readiness, con app root dispose/reopen e file SQLite device reale.
- Harness attempts: `FAIL` — Android card fuori viewport e route offline non attesa;
  iOS Sliver non materializzato e finder Scrollable ambiguo. Cause distinte corrette
  con scroll verticale deterministico e attesa route; rerun finali entrambi `PASS`.
- Artifact: `PASS` — APK SHA-256 `a5730cc2…f09b`; Runner executable SHA-256
  `9b57b6dd…7448`.
- Review integrata: `NOT_RUN`.
- Production write: `NOT_RUN` — vietata prima dei gate finali.
