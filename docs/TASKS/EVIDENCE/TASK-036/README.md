# Evidence TASK-036

Snapshot di handoff:
`ACTIVE / REVIEW / CODEX_EXECUTION_COMPLETE_TO_REVIEW`.

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
