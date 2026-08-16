# Evidence TASK-034

Snapshot di handoff:
`ACTIVE / REVIEW / CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

## Provenance iniziale

- Client `origin/main`: `e5a1384e7526e288f7657c32bff42f1ab957633e`;
- Admin `origin/main`: `2e8ec07e1609b7bfa7b1a5210f232fc60bbf5412`;
- linked worktree writer puliti da `origin/main`; checkout primari preservati;
- repository read-only: SplitView `0406264c`, iOS legacy `53396a57`, Win7POS
  `fea70fa7`, WeChat `f305447c`; dirty state preesistente SplitView/Win7POS preservato;
- PR aperte al preflight: zero nei sei repository;
- CI `main` Client run `31953305239` e Admin run `31940653715`: job/step pertinenti
  osservati `SUCCESS` sugli SHA iniziali;
- Supabase staging healthy: migration delivery tracking `20260816072836` assente dalla
  history osservata; production non identificata e non modificata;
- device fisici Android assenti; device Apple fisici offline; simulatori/emulatori
  disponibili.

## Matrice canonica

Completata in `docs/quality/TASK-034-RESILIENCE-MATRIX.md`: 36 celle classificate,
zero critical `UNTESTED`. Ogni `PASS` collega authority, idempotency/version, retry,
reconciliation e un comando realmente eseguito.

## Execution

### Client

- `flutter analyze`: `PASS`, exit `0`;
- suite mirata Auth/Storefront cache e immagini/Catalogo/Carrello/Hold/Checkout/
  Ordini/notification routing/deep link/tracking: `314/314 PASS`, exit `0`;
- `bash scripts/test-task034-resilience-repeat.sh 10`: sei race per dieci iterazioni,
  `60/60 PASS`, exit `0`;
- `bash scripts/check.sh`: `PASS`, exit `0`; format 273 file, analyze zero issue,
  suite non-performance `627/627` con coverage, repeat 30/30, benchmark Drift/cache 25k,
  APK debug e iOS Simulator debug;
- benchmark 25k: `open_ms=476`, `write_20k_ms=474`, catalog p50/p95/max
  `599/1217/8440 µs`, search `3163/3817/6788 µs`, 25.000 righe.

### Database/Admin/POS locale

- `npx supabase db reset`: `PASS`, exit `0`, migration fino a
  `20260816072836_storefront_delivery_tracking_v1`;
- dieci file pgTAP commerce/tracking: `483/483 PASS`;
- undici harness concorrenti: projection, availability, cart, holds, slot, customer
  order, cancel, admin order, POS handoff, notification e payment tutti `PASS`;
- Admin Foundation finale: `982 PASS`, `2 SKIP`, `0 FAIL`; `npm run verify`: `PASS`.

### Staging canonico

- primo workflow migration `31966422454`: `FAIL` sicuro prima dell'apply; il default
  manuale predecessor obsoleto è stato corretto e reviewato;
- Admin PR #90, head `4b48150d`, merge `9aaeb0c1`; PR/main CI e Cloudflare verdi;
- dry-run `31967227338`: sola migration `20260816072836` pending;
- apply `31967270575`: `PASS`, migration applicata esclusivamente a staging;
- Admin PR #91, head `27443680`, merge `69791e6f`: workflow smoke guarded integrato;
- run `31968559199`: `FAIL` workflow, ma pgTAP remoto `60/60 PASS`; il gate ha
  rilevato correttamente parser summary e cleanup JSON difettosi, poi corretti;
- Admin PR #92, head `1b9636e5`, merge `6fea61bb`; review finale `APPROVED`, CI PR e
  main exact-SHA verdi;
- run finale `31969351269` sullo SHA `6fea61bb`: `PASS`; `Files=1, Tests=60`,
  `Result: PASS`, sanitizer `true`, migration ledger `true`, fixture cleanup `true`;
- il test transazionale usa dati sintetici e `ROLLBACK`: admin start, courier start,
  location, owner read, cross-customer deny, terminal redaction e cleanup;
- production non identificata e mai modificata; nessun dato reale usato.

### Finding corretti

- OAuth in-flight senza callback poteva lasciare `authenticating` indefinitamente;
- freshness tracking a uguaglianza della deadline restava `fresh` per il confronto
  stretto `>`;
- workflow staging aveva default manuale non single-migration-safe;
- primo smoke workflow poteva caricare output raw sul failure path e non fissava il
  piano pgTAP; dopo il primo run reale sono stati corretti summary parser e stdin
  Docker del cleanup. Ogni fix ha regressione e re-review distinta.

## Review iniziale e Fix Client

- review indipendente su `d59883f`: `CHANGES_REQUIRED`, 0 P0/P1, 1 P2, 0 P3;
- `TASK034-R-001`: mancava una regressione diretta del cambio identità/logout con
  fallback tracking attivo e del teardown completo di timer/subscription;
- il Fix mantiene il notifier durante le transizioni di identity, serializza stop e
  purge owner-scoped, cattura il cache store prima di attese async e impedisce letture
  del provider dopo dispose;
- regressioni Fix: tracking `19/19 PASS`; repeat `10 x 9 = 90 PASS`, con A→null,
  A→B e dispose dopo Realtime failure, vecchio stream avanzato e scheduler a zero;
- gate canonico Fix sul commit `0dccca810e309c849c290a857bd1975bb4fd797b`:
  `scripts/check.sh` `PASS`, 609 file security scan, 41/41 negative e 4/4 positive,
  governance 9/9, architecture negative 7/7, format 273, analyze zero issue, 630 test
  non-performance con coverage, repeat `5 x 9 = 45`, benchmark 25k
  (`open_ms=460`, `write_20k_ms=466`, catalog `594/1252/7618 µs`, search
  `3175/3748/6597 µs`), APK debug e iOS Simulator debug;
- re-review Client indipendente e CI/merge Client: `NOT_RUN`, prossima fase. Le review
  Admin dei fix staging sono concluse con `APPROVED` e zero P0/P1/P2/P3 residui.

### Re-review 1 e Fix 2

- re-review su Fix `0dccca8` ed evidence `68f1f6a`: `CHANGES_REQUIRED`, 0 P0/P1,
  1 P2, 0 P3; l'unsubscribe production può attendere `removeChannel()`, lasciando un
  interleaving dispose prima del successivo `ref.read` del cache store;
- Fix 2: i tre call site identity, close con purge e unauthorized catturano il cache
  store prima del primo `await` e lo passano al cleanup serializzato;
- regressioni con unsubscribe bloccato da `Completer`: tracking `22/22 PASS`; identity,
  close e unauthorized completano il purge anche se il container viene disposed
  durante la cancellazione; repeat `10 x 12 = 120 PASS`;
- gate canonico sullo SHA Fix 2 `c514f388607fe93cc25e17a0622e705b6be1dd58`:
  `scripts/check.sh` `PASS`, scan 609 file, negative security 41/41, positive 4/4,
  governance 9/9, architecture negative 7/7, format 273, analyze zero issue, 633 test
  non-performance con coverage, repeat `5 x 12 = 60`, benchmark 25k
  (`open_ms=454`, `write_20k_ms=487`, catalog `620/1260/7898 µs`, search
  `3366/4771/6720 µs`), APK debug e iOS Simulator debug;
- nuova re-review e CI/merge Client: `NOT_RUN`, prossima fase.
