# Evidence TASK-035

Snapshot di handoff:
`ACTIVE / FIX / CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Provenance

- baseline Client: `08221a6897e893ae9adb462d1cc32f0bf32bbb2e`;
- TASK-034 PR #12 head `0807c374e35e12fe224119b3bcc1d4987db46213`, merge
  `08221a6897e893ae9adb462d1cc32f0bf32bbb2e`;
- CI TASK-034 PR `31972218226` e `main` `31972595581`: 3/3 job `PASS`, ogni
  step applicabile `success`, zero annotation;
- branch TASK-034 remota e locale eliminate; checkout primario preservato;
- production non modificata.

## Planning

Il file TASK-035 non esisteva nella baseline: è stato creato dal backlog canonico del
Master Plan e dallo scope esplicito USER_APPROVER, senza alterare priorità o dipendenze.
Planning autorizzato tramite ADR-015; Execution attiva come unico task corrente.

## Execution

### Revision set e file

- baseline Client: `08221a6897e893ae9adb462d1cc32f0bf32bbb2e`;
- transition/planning: `e66f405bbd55c792c7044cc3f49bd31d0a706a48`;
- implementation ed handoff Review: `bd5e392`;
- implementation: `lib/core/observability/`, bootstrap, router e integrazioni bounded
  Auth/Catalog/Cart/Checkout/Orders/Tracking;
- verification: test core, collector feature, scanner telemetry e runbook;
- dipendenze: nessuna aggiunta o update; nessun provider SaaS configurato.

### Provider e privacy boundary

- `NoopObservabilityPort`: default test e staging/production non configurati;
- `StructuredLocalObservabilityPort`: diagnostica development su `dart:developer`;
- `ConfigurableProductionObservabilityPort`: exporter analytics/crash distinti,
  abilitazione esplicita, consent, sampling, rate limit e buffer bounded;
- eventi: 12 factory tipizzate, nessuna mappa arbitraria dai caller;
- crash: categoria/component/fingerprint SHA-256 troncato e breadcrumb bounded; exception
  message e stack non sono serializzati;
- correlation: 24 caratteri hex random, senza UUID di dominio;
- redazione centrale: email, auth, OAuth/payment/push/service secret, credenziali
  generiche, password/passphrase, authorization/cookie, private key, DSN, URL, UUID,
  coordinate e telefono; serializer limita profondità, elementi e lunghezza.

### Test privacy negativi

Il test core inietta nome, indirizzo, email, telefono, coordinate, tracking URL, bearer,
OAuth code, payment secret, push token, service role, password/passphrase,
authorization/cookie, private key, DSN, credential e UUID e cerca esplicitamente gli
stessi valori negli export. I test feature raccolgono gli eventi reali e verificano
assenza di query, publication/order/address/slot ID, nome prodotto/cliente, indirizzo,
coordinate e URL.

`scripts/check-telemetry-privacy.sh` è incluso in `scripts/check.sh` e ha riportato:
`12 eventi allowlisted, logger/export confinati, zero attributi sensibili`.

### Admin read-only audit

Revision set osservato: head tecnico `1b9636e5`, contenuto già integrato in
`origin/main` `6fea61bb`. `src/app/api/pos/_shared/pos-route-security.ts`:

- valida e limita client request ID, scartando forme token/credential;
- genera `serverRequestId` e restituisce errori JSON strutturati;
- conserva solo hash SHA-256 bounded dell'edge correlation;
- emette rejection audit strutturato, separato da analytics.

Comando autonomo Admin:
`node --test` sui foundation TASK-026/TASK-029/TASK-068: `14/14 PASS`, exit `0`.
Nessuna modifica Admin necessaria; service role resta confinata al server e ai test
esplicitamente privilegiati già esistenti.

### Gate Client

| Verifica | Esito |
|---|---|
| test observability + 5 controller | `87/87 PASS` |
| format / analyze / diff | `PASS`, zero issue |
| scanner tracked source | `621` file, zero secret/config/artifact |
| fixture scanner | `41/41` negative respinte; `4/4` positive accettate |
| governance / architecture | `9/9` e `7/7 PASS` |
| test non-performance coverage | `652/652 PASS` |
| repeat resilience | `5 x 14 = 70/70 PASS` |
| test performance cache 25k | `1/1 PASS` |
| Android debug | `app-debug.apk` costruito |
| iOS Simulator debug | `Runner.app` costruita |
| `scripts/check.sh` | `PASS`, exit `0` |

Warning osservati e non promossi a PASS: versioni package incompatibili più recenti,
warning drift multi-database già presente nei test router e futura adozione SPM del
plugin Maps iOS. Nessun warning è introdotto come nuova dipendenza dal task.

## Review e CI

- review indipendente sullo SHA `8201acd6c8c4779d5bbaa086eec87a2c13d9c809`:
  `CHANGES_REQUIRED`, 0 P0, 2 P1, 2 P2, 1 P3;
- Fix tecnico: `78bc06e40d6fc81c5962f67fb80bf20f5e38aadf`; governance
  riallineata sullo SHA `00455df75538df19e7d1542d872d378302762177`;
- regressioni: core/controller `122/122`, repeat `340/340 + 40/40`, tutti `PASS`;
- security diff review pre-fix: `PASS`, 15/15 file, zero finding reportabili o
  deferred; i gap di acceptance non-security sono stati comunque corretti;
- `scripts/check.sh` sullo SHA `00455df`: `PASS`, 659 test non-performance con
  coverage, repeat TASK-034 70/70, cache 25k, APK debug e iOS Simulator debug;
- re-review Fix 1 sullo SHA `46e1a87`: `CHANGES_REQUIRED`, 0 P0, 0 P1, 1 P2,
  0 P3; `F-035-R01/R02/R03/R05` chiusi, `F-035-R04` riaperto per credenziali
  generiche non coperte;
- Fix 2 tecnico: `741834bf09178cbb0cc2b31595fc56eeb3db6339`; classificatore
  exact/suffix, scanner con fixture inline di 13 alias e due regressioni negative;
- test Fix 2: serializer `17/17`, repeat `20 x 17 = 340/340`, scanner, analyze,
  format e diff `PASS`;
- primo `scripts/check.sh` Fix 2: `FAIL` prima della suite perché lo snapshot evidence
  era ancora in Review; snapshot riallineato, nessun gate successivo inferito;
- re-review Fix 2: `NOT_RUN`;
- PR exact-SHA CI: `NOT_RUN`;
- main post-merge CI: `NOT_RUN`;
- produzione e provider esterni: non modificati.
