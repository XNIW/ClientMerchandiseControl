# TASK-004 — Fix evidence

## Revisioni

- Review con finding:
  `48aa9cf83c7658693cacc210c108cf397eb322d1`
- Commit tecnico Fix:
  `bccb6f55a9ceaf46d946c95fc79b5b7d3ae02055`
- Branch:
  `milestone/003-004-storefront-contract-environments`
- Scope: esclusivamente `T004-REV-001`–`T004-REV-004`

## Risoluzione finding

| Finding | Esito Fix | Evidenza |
|---|---|---|
| `T004-REV-001` P2 | PASS | callback raw non trimmata; regressioni development/staging/production per leading, trailing, newline e whitespace-only |
| `T004-REV-002` P2 | PASS | bootstrap production solleva errore sanitizzato con zero initializer call; staging una chiamata, development zero |
| `T004-REV-003` P2 | PASS | rerun Android/iOS 1/1 sul commit tecnico; comandi/output in `runtime-smoke.md`; due PNG sanitizzati e manifest con SHA-256 |
| `T004-REV-004` P3 | PASS | intestazioni matrici rinominate «stato corrente» |

## Gate eseguiti

| Comando/verifica | Esito | Risultato |
|---|---|---|
| `flutter test test/core/config/app_config_test.dart test/core/backend/supabase_bootstrap_test.dart` | PASS | exit 0, 29/29 |
| `bash scripts/check.sh` | PASS | exit 0; governance, format, analyze, 72/72 test, APK e iOS Simulator build |
| test compile-time con staging local | PASS | exit 0, 1/1; nessun valore stampato |
| build APK con staging local | PASS | exit 0 |
| build iOS Simulator con staging local | PASS | exit 0 |
| smoke Android development | PASS | exit 0, 1/1 |
| smoke iOS development | PASS | exit 0, 1/1 |
| ispezione screenshot | PASS | Home/banner offline su entrambi; nessun dato o valore config |
| manifest screenshot | PASS | due PNG, dimensioni/byte e SHA-256 ricalcolati |
| diff/security/confinement | PASS | sette file allowlisted nel commit tecnico; zero native/pubspec/config locale/artifact build/credenziale |
| file staging locale | PASS | presente, ignorato e non tracciato; contenuto non stampato |
| CI Review `30590288028` | PASS | SHA `48aa9cf…`, Quality/Android/iOS success, annotation 0/0/0 |
| CI tecnica Fix `30590869991` | PASS | SHA esatto `bccb6f5…`, Quality/Android/iOS success, tutti gli step, annotation 0/0/0 |

## Output pertinente

- test mirati: `00:00 +29: All tests passed!`;
- suite completa: `00:02 +72: All tests passed!`;
- analyze: `No issues found!`;
- APK development e staging: build completate;
- Runner Simulator development e staging: build completate;
- Android smoke: `00:13 +1: All tests passed!`;
- iOS smoke: `00:09 +1: All tests passed!`.

## Deviazioni

Nel rerun Android, il primo install interno allo stesso comando ha esaurito lo spazio
del simulatore. Flutter ha rimosso automaticamente la versione precedente, reinstallato
lo stesso APK e completato lo smoke 1/1 con processo finale exit 0. Non è rimasto alcun
gate o processo pendente.

Sette package hanno versioni più recenti incompatibili con i constraint correnti:
warning informativo già noto, nessun aggiornamento autorizzato o applicato.

## Sicurezza e scope

- nessun valore del file staging locale è stato stampato o versionato;
- errori production e callback restano sanitizzati;
- screenshot ispezionati senza dati personali, account, URL, key o token;
- nessun OAuth, deep link nativo, readiness, query, `shop_id`, dipendenza o write
  remoto è stato introdotto;
- repository esterni e Supabase sono rimasti zero-write.
