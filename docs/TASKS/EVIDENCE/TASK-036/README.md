# Evidence TASK-036

Snapshot finale:
`DONE / REVIEW / USER_APPROVED_DONE`.

## Provenance

- baseline Client: `ddb8cc8fad8156c032b1aa6e2011d0cc589d480b`;
- TASK-035 PR #13 head `2d81f6f0b6e9bf0e7c64d58cd5f2ffbad32dab47`;
- CI PR `31978060753` e main `31978389972`: 3/3 job `SUCCESS`, tutti gli
  step applicabili `success`, annotation 0/0/0;
- branch TASK-035 remoto e locale eliminati; primary checkout preservato;
- production non modificata.

## Planning

- task creato dal backlog e dallo scope USER_APPROVER senza cambiare ordine;
- matrici richieste: locale/superficie e viewport/scale/theme/platform;
- automated accessibility, manual screen reader, simulator/emulator e physical device
  restano classificazioni indipendenti;
- nessun esito `PASS` è ancora dichiarato per TASK-036.

## Execution

### Revisioni e writer boundary

- Client technical SHA: `a2bb8b28426e5dab45950451dfaa31ebbcf55cf8`;
- Admin technical SHA: `7ca6d32f4403edd29a996cd61e789ec267e68cbd`;
- Admin è stato elevato a writer soltanto perché checkout/order non esponevano il
  fuso canonico del negozio e il contratto server-authoritative era necessario per
  correggere una regressione cross-repo reale;
- SplitView, iOS legacy, Win7POS e WeChat restano read-only e immutati;
- worktree Client/Admin puliti; primary checkout e dirty state preesistenti
  preservati; production e staging non modificati in questa fase.

### Finding e fix

Il baseline usava `DateTime.toLocal()` per slot checkout, ordine, timeline e tracking:
un cliente con device fuori dal fuso del negozio vedeva orari business errati. Il fix:

- espone `storefront_time_zone_v1(text)` con payload pubblico minimale e timezone
  IANA validata da PostgreSQL;
- valida strict schema/version/shop identity sul client;
- usa `timezone 0.11.1` con database IANA e DST, aggiungendo il nome zona alla copy;
- deduplica le prime letture concorrenti per shop e conserva solo il valore pubblico;
- propaga la zona a cache, liste, dettaglio, ricevuta, ETA e timeline;
- invalida fail-closed la cache ordini v1.

### Localization e accessibility evidence

- 5 bundle, 499 chiavi ciascuno, stessa parità e placeholder;
- es-CL, it, en, zh-Hans e fallback verificati; plurali 0/1/2 distinti;
- scan hardcoded multilinea `PASS`, fixture `2/2`;
- 84/84 celle layout: 7 viewport x 3 scale x 2 temi x Android/iOS;
- 2/2 theme/semantics/contrast e 2/2 keyboard focus/activation;
- nessun framework overflow, CTA irraggiungibile, focus trap o target sotto 48x48;
- TalkBack/VoiceOver manuale `NOT_RUN`, non inferito dai semantics test.

### Device evidence

| Classe | Stato | Evidence |
|---|---|---|
| EMULATOR Android | PASS | API 35, integration smoke cold start/navigation/theme/200%/rotation/semantics |
| SIMULATOR iOS | PASS | iPhone 17 iOS 26.2, stesso integration smoke; visual extreme Dynamic Type |
| PHYSICAL_ANDROID | NOT_RUN | nessun device in `adb devices -l` |
| PHYSICAL_IOS | NOT_RUN | iPhone rilevato offline da `xctrace` |
| SCREEN_READER_MANUAL | NOT_RUN | nessuna sessione TalkBack/VoiceOver realmente esercitabile |

### Gate Client

- `scripts/check.sh` su `a2bb8b2`: exit 0;
- security source 629 file, fixture 41/41 negative e 4/4 positive;
- telemetry privacy e localization scan `PASS`;
- format 285/0, analyze zero issue;
- Flutter test 853/853, skip 0, coverage generata;
- TASK-034 repeat 5 x 14 = 70/70;
- cache benchmark 25k: open 509 ms, write 498 ms, catalog 674/1317/7971 us,
  search 3553/4351/7878 us;
- APK debug e iOS Simulator debug build `PASS`.

### Gate Admin/Supabase locale

- `supabase db reset --local --no-seed`: 139 migration `PASS`;
- `supabase test db --local`: 47 file, 2532 assertion, `PASS`;
- `supabase db lint --local --schema public --level error --fail-on error`:
  zero result;
- `npm run verify`: lint/typecheck/security/build `PASS`;
- foundation finale con checkout Win7POS read-only canonico: 982 pass, 0 fail,
  2 skip. Il primo tentativo sul path storico incompleto è registrato come diagnosi
  ambientale e non è stato occultato.

### Classificazioni residue

- physical validation: `PHYSICAL_VALIDATION_PENDING_DEVICE`;
- manual screen reader: `MANUAL_ACCESSIBILITY_VALIDATION_PENDING_DEVICE`;
- staging migration/smoke: intenzionalmente `NOT_RUN` prima di review, CI e merge;
- P0/P1/P2 noti all'handoff Execution: zero;
- prossima fase: review indipendente read-only Client/Admin.

## Review indipendente

- revision set: Client `cfa9194`, Admin `7ca6d32`, entrambi puliti;
- esito: `CHANGES_REQUIRED`, zero P0/P1, un P2, zero P3;
- `F-036-R01`: la RPC timezone separata e la cache process-lifetime rendevano
  possibile associare un fuso stale o non atomico agli snapshot checkout/order;
- reviewer gate: Client 853/853 e mirati 151/151; Android/iOS smoke 1/1 ciascuno;
  Admin 47 file/2532, task 10/10, lint e privilege probe verdi.

## Fix F-036-R01

- timezone integrato negli stessi payload pubblici
  `storefront_fulfillment_options_v1`, `customer_order_list_v1`,
  `customer_order_detail_v1` e `customer_order_cancel_v1`;
- implementazioni delegate spostate in `app_private`, grant API rimossi e wrapper
  con firme/timeout/volatility/least-authority preservati;
- rimosse seconda RPC e cache client; validazione IANA bounded sul campo atomico;
- regressioni cambio timezone e completion concorrente fuori ordine;
- technical SHA Client `e5a2f2b4a9000c7ad773a417c7ca01b615bcd639`;
  technical SHA Admin `c8dd7080`;
- reset locale 139 migration `PASS`; pgTAP specifico 13/13, mirati 3 file/100
  e suite completa 47 file/2536 `PASS`; lint DB zero;
- Admin verify `PASS`; foundation 982 pass, 2 skip, 0 fail;
- Client mirato 150/150 e suite completa 755/755 `PASS`;
- `scripts/check.sh` sul technical SHA: 754 test non-performance con coverage,
  repeat 70/70, benchmark cache 25k, APK debug e iOS Simulator debug `PASS`;
- handoff: `CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

## Re-review Fix

- exact revision: Client `4cfe809040834768b29f3c7e648207bbf606a60c`, Admin
  `c8dd708016b56b24b4d1402fe782028feb8e1487`;
- `F-036-R01` chiuso; nessuna seconda RPC/cache, correlazione payload/timezone,
  snapshot/lock SQL e privilege app_private verificati;
- Client 40/40 mirati e 755/755 completi, skipped/failure zero; Admin 3 file/100
  mirati e catalog probe `PASS`;
- zero finding P0/P1/P2/P3; worktree puliti; `APPROVED`.
- handoff: `CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION`.

## Closeout remoto e staging

- PR Admin #93: head esatto `c8dd708016b56b24b4d1402fe782028feb8e1487`;
  CI PR `31982974675` e Cloudflare `31982974682` verdi; merge normale
  `59668348e4c728b44b998c80f1aded61e6114a3f`;
- Admin main: CI `31983374103` (Verify + database migrations/pgTAP) e
  Cloudflare build `31983374123` verdi sul merge SHA; deploy staging/production
  Cloudflare correttamente non eseguiti;
- PR Client #14: head esatto `662e7bb0f71b5527b0922807b88e2f0badc20e25`;
  CI PR `31982980870` 3/3 verde; merge normale
  `96a9359c052a98fb0df7fd8562e648b9a485a2f0`;
- Client main: CI `31983526499` 3/3 verde sul merge SHA, inclusi test, APK
  debug, iOS Simulator debug e scanner dei bundle;
- staging timezone: guard/delta/dry-run `31983931437` e apply
  `31983967203` sullo SHA Admin main, entrambi `PASS`;
- staging delivery tracking dopo l'apply: run `31984019280`, pgTAP 60/60,
  RLS/lifecycle sintetico, ledger, sanitizzazione e cleanup `PASS`;
- branch remote TASK-036 eliminate; production invariata; finding aperti zero
  P0/P1/P2/P3.
