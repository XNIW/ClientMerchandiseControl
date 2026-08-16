# Evidence TASK-044

Snapshot di handoff:
`ACTIVE / REVIEW / CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

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
