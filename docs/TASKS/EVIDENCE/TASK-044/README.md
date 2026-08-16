# Evidence TASK-044

Snapshot finale:
`DONE / REVIEW / USER_APPROVED_DONE`.

## Provenance

- Client base e branch: `e9bd0306b07b105f3fb46da783ab2fd24ef44246` /
  `codex/task-044-delivery-tracking-20260816`;
- Admin base e branch: `5cf73e4f6de4cfcc36e56514ec77c0cc9cb970e3` /
  `codex/task-044-delivery-tracking-20260816`;
- checkout primari e dirty state preesistenti: preservati;
- TASK-151/WECHAT-006 Admin: review esterna preservata, nessuna evidence riscritta.

## Gate pre-review

- Client `scripts/check.sh`: `PASS`, exit 0; 586 test più performance e build
  Android/iOS incluse;
- Admin `npm run verify`: `PASS`, build inclusa; foundation `978 PASS`, `2 SKIP`;
- Supabase reset: `PASS`; pgTAP tracking `55/55 PASS`;
- revision set esatto: Client `e9bd0306..aa24851a`, Admin `5cf73e4f..c94e4711`.

## Review mirata

- esito: `CHANGES_REQUIRED`;
- finding aperti: sei P2 e due P3; zero P0/P1;
- ambiti: monotonicità/cache/runtime Client, lifecycle foreground courier,
  retention feed, rate limit server-side, URL esterno e branch visibility;
- i fix devono essere seguiti da regression test e re-review read-only sui nuovi SHA.

## Fix candidate

- Client `61cd16bee70a925c1110645c708551de58ac3427`: monotonicità/cache,
  unauthorized fail-closed, terminal redaction, visibilità route programmatica,
  freshness temporale e dispose mappa concorrente;
- Admin `663a292a626adc25230bad7c1917f930f94f5dca`: lifecycle Courier Mode,
  cleanup/feed redaction, rate limit assoluto, validazione hostname e shell courier;
- Client mirati: `flutter analyze` e 48 test `PASS`;
- Admin mirati: reset `PASS`, pgTAP `60/60`, foundation `9/9`, typecheck/lint `PASS`;
- re-review parziale: finding runtime Client, Courier Mode e database `CLOSED`; i due
  reviewer Client finali verificano il secondo ciclo in sola lettura.

## Re-review finale e gate candidate PR

- tutti i sei P2 e due P3 iniziali: `CLOSED`; freshness temporale e race
  presenter/dispose aggiuntive: `CLOSED`;
- Client finali: `61cd16b` per controller/map e `1801347` per route boundary;
- Client `scripts/check.sh`: `PASS`; 598 test con coverage, performance 1/1, APK
  debug e iOS Simulator debug;
- Admin `npm run verify`: `PASS`; foundation 980 pass, 2 skip, 0 fail;
- Admin DB: reset `PASS`, pgTAP tracking 60/60 `PASS`;
- esito: `APPROVED`, zero P0/P1/P2/P3 aperti; PR e CI exact-SHA restano da
  registrare prima del merge autorizzato.

## CI, merge e main

- Client PR #9, head `0e84801e3e362d489b00d43f6074b804de8fe713`, run
  `31939920494`: Quality, Android e iOS 3/3 `SUCCESS`, annotation 0/0/0;
- Client merge normale `fd044d4b9b7a7bd4c4d3ccf71b977a01bc39563f`; main run
  `31940810780` 3/3 `SUCCESS`, annotation 0/0/0;
- Admin PR #89: il primo run `31939911807` ha fallito correttamente pgTAP per una
  regressione lockout e test 43/45; il fix `0ce56bf5` è stato re-reviewato
  `APPROVED`, reset locale e 2.522/2.522 pgTAP `PASS`;
- Admin run `31940278489` e Cloudflare `31940278463`: `SUCCESS`; merge normale
  `2e8ec07e1609b7bfa7b1a5210f232fc60bbf5412`; main run `31940653715` e
  `31940653742`: `SUCCESS`;
- le sole annotation Admin sono warning infrastrutturali GitHub Actions Node 20 ->
  Node 24, non failure del prodotto; deploy staging/production sono rimasti skipped;
- branch remoti e worktree TASK-044 eliminati dopo verifica di ancestry; checkout
  primari non modificati dal batch.
