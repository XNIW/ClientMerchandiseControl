# Evidence TASK-013

Snapshot di checkpoint:
`VALIDATED_PENDING_INTEGRATED_REVIEW / EXECUTION`.

## Revision set

- Client: `2aefa17f901652bf2f1fceafb2649422c6b8fb4f`, PR `#5` draft.
- Admin/fixture: `a9036f0bda741d686afbdac13d3d08ef897f059b`, PR `#67` draft.
- API/schema staging: `storefront.v1` / `20260802033000`.

## Gate

- Planning/dipendenze: `PASS`.
- Security scan: `PASS` — 370 file, 32/32 fixture negative, 2/2 positive.
- Architecture boundary: `PASS` — 7/7 fixture negative; un solo RPC Home e nessuna
  query inventory/authoring/storage interno.
- Analyze/format/l10n: `PASS`, exit 0.
- Test Client: `PASS` — 240 test; coverage 2.199/2.709 linee, 81,17%.
- Build locale: Android debug e iOS Simulator debug `PASS`.
- CI Client `30732213362`: `PASS` — Quality 3m05s, iOS 3m39s,
  Android 8m28s, SHA esatto Client.
- Fixture Admin `30731760038`: `PASS` — catalog version 2, 3 categorie,
  2 featured, 1 offerta e 9 immagini pubbliche; dati interni negati.
- Admin CI `30731757331` e deploy `30731372117`: `PASS`.
- Android readiness live: `PASS`, 1/1 in 3 s.
- Android Home live: `PASS`, 1/1 in 16 s.
- iOS Home live: `PASS`, 1/1 in 2 s.
- APK staging SHA-256:
  `005c29a1e762fc40b3e86f2bccf1ad213030b49eb0f96423776668439a3986a2`.
- Runner.app staging aggregate SHA-256:
  `fc92cabfd9e6070f20d577b967442322e2bc3abdb68275f62a4da1203d60a727`.
- Review integrata: `NOT_RUN`.
- Production write: `NOT_RUN` — production invariata.

## Deviazioni risolte

- lifecycle Riverpod `initializing -> ready` corretto con listener e regressione;
- regola category slug allineata al contratto backend (`te` valido);
- test shell isolato dalla rete dopo l'attivazione del fetch Home.

Nessun log completo, URL/key reale, token, account o artifact binario è versionato.
