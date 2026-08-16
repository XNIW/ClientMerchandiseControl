# Evidence TASK-044

Snapshot di handoff:
`ACTIVE / FIX / CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

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
