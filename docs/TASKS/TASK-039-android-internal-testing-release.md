# TASK-039 — Android Internal Testing release

## Informazioni generali

- **Task ID**: TASK-039
- **Titolo**: Android Internal Testing release
- **File task**: `docs/TASKS/TASK-039-android-internal-testing-release.md`
- **Stato**: ACTIVE
- **Fase**: REVIEW
- **Responsabile**: USER_APPROVER
- **Data creazione**: 2026-08-17
- **Ultimo aggiornamento**: 2026-08-17
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-039/`
- **Handoff**: CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION

## Dipendenze

- **Dipende da**: TASK-033, TASK-034, TASK-035, TASK-036, TASK-037, TASK-038
- **Sblocca**: TASK-041
- **Writer**: Client; Admin e gli altri repository read-only

## Scope

- produrre un AAB release pulito con configurazione production-like fail-closed;
- validare signing boundary, minify/R8/resource shrink, ABI, manifest, permission,
  exported component, App Link, network security, Maps, notification, OAuth,
  crash/analytics e versione;
- ispezionare AAB/APK per debug flag, localhost, staging value, secret, service role,
  test fixture, cleartext e capability non configurate abilitate;
- generare SHA-256 e release candidate riproducibile senza versionare artifact;
- caricare soltanto su Play Internal Testing se account, signing e policy repository
  risultano realmente disponibili; mai promuovere production.

## Non incluso

- produzione Play, staged rollout pubblico, acquisti, billing o key provisioning;
- invenzione/commit di keystore, alias, password, service account o console identity;
- modifica Supabase/production, provider payment, Maps billing o legal owner value;
- iOS/TestFlight, governato da TASK-040.

## Criteri di accettazione

| CA | Descrizione | Tipo |
|---|---|---|
| CA-01 | Release config e signing validator falliscono chiusi senza stampare secret | STATIC/SECURITY |
| CA-02 | AAB release pulito è generato e identificato con SHA-256/version/package | BUILD |
| CA-03 | Minify, R8, resource shrink, ABI e manifest sono coerenti col release target | BUILD/STATIC |
| CA-04 | Permission, exported component, App Link e cleartext policy sono least-privilege | SECURITY |
| CA-05 | Nessun debug/local/staging/secret/service-role/test fixture è nell'artifact | SECURITY |
| CA-06 | Maps/OAuth/notification/telemetry restano fail-closed senza config esterna | STATIC/TEST |
| CA-07 | Internal Testing è uploaded se autorizzazioni reali esistono, altrimenti il confine esterno è esatto | RELEASE |
| CA-08 | Review indipendente, exact-SHA CI e zero P0/P1/P2 sono reali | REVIEW/CI |

## Test case

| Test | Criteri | Procedura attesa |
|---|---|---|
| T-01 | CA-01/06 | validator environment/signing/provider con fixture negative e output redatto |
| T-02 | CA-02/03 | clean `flutter build appbundle --release` e inspection bundletool/aapt/apksigner |
| T-03 | CA-04/05 | manifest/artifact scan su permission, exported, link, cleartext, debug e stringhe vietate |
| T-04 | CA-07 | probe read-only di credenziali/policy; upload Internal soltanto se tutti i prerequisiti sono presenti |
| T-05 | CA-08 | check canonico, security review diff-scoped, review distinta, PR/main CI e hygiene |

## Decisioni

| # | Decisione | Motivazione | Stato |
|---|---|---|---|
| D-01 | Release unsigned/unuploadable non è dichiarata pubblicata | Evidence reale, nessun falso PASS | ATTIVA |
| D-02 | Nessun keystore o valore Play viene generato/inventato | Credenziali e ownership sono gate esterni | ATTIVA |
| D-03 | Production-like senza secret deve avviarsi o fallire chiusa, mai degradare a staging | Separazione ambiente | ATTIVA |
| D-04 | Il mandato 2026-08-16 autorizza Planning→Execution | ADR-015 | ATTIVA |

## Planning — `CODEX_PLANNER`

1. inventariare Gradle/signing/manifest/provider/tooling e soli nomi dei secret;
2. definire validator e matrice artifact con failure classificate;
3. implementare il minimo necessario per build release riproducibile e fail-closed;
4. costruire AAB/APK derivato, ispezionare package/version/signature/config/security;
5. provare Internal Testing capability senza mutazioni fuori confine;
6. produrre evidence, review indipendente e closeout exact-SHA.

### Rischi

- signing assente: produrre RC verificato e classificare external credential blocker;
- release config non operativa: fail-closed è accettabile, fallback staging no;
- shrinker rimuove entrypoint/plugin: smoke release su emulator e regressione;
- artifact espone config: scanner fail-closed e nessun upload;
- Play access ambiguo: nessuna chiamata di upload senza account/track/policy verificati.

### Handoff a Execution

- **Autorizzazione USER_APPROVER**: mandato 2026-08-16 e ADR-015
- **Handoff**: CODEX_PLANNING_APPROVED_TO_EXECUTION

## Execution — `CODEX_EXECUTOR`

- release signing configurabile soltanto all-or-none da secret store o
  `android/key.properties` ignorato; nessun fallback al debug certificate;
- R8/obfuscation/optimization e resource shrinking abilitati, con mapping e
  metadata R8 inclusi nel bundle;
- overlay release con cleartext vietato e sole CA di sistema;
- template production-like pubblico: environment production, OAuth e Maps
  spenti, backend/callback/shop assenti e bootstrap fail-closed;
- validator source/artifact e CI release gate aggiunti; package, versione, ABI,
  manifest, exported boundary, provider, signature e SHA-256 verificati;
- clean AAB e APK generati sullo SHA `6b878f35aebfe0e98fa305c624747711fd81f1b0`;
- AAB `67.773.321` byte, SHA-256
  `6c321e2fcafcf4cd3a7044f366ebaa5c1c2d0e41e2a84c425e931a1b76a84718`;
- APK di ispezione `70.137.338` byte, SHA-256
  `82ee832fb88d64eef3d04e0a8f4a5a7f4ddcaf0a2fb13efcfea82bfee81b91ce`;
- artifact unsigned: install emulator respinta correttamente con
  `INSTALL_PARSE_FAILED_NO_CERTIFICATES`; nessuno smoke release inventato;
- nessun keystore, secret/variable GitHub, service account o config Play
  disponibile; `--require-upload-ready` fallisce con
  `PLAY_INTERNAL_REQUIRES_SIGNED_AAB`; upload `NOT_RUN`;
- App Link HTTPS production resta chiuso finché non esistono dominio posseduto,
  association file e fingerprint release; OAuth production resta vietato.

Gate executor:

- `scripts/check.sh`: PASS;
- security source/artifact: 666 file source, 132 file artifact, zero valori
  vietati; fixture security 41/41 negative e 4/4 positive;
- suite non-performance 772/772, resilience repeat 70/70, performance 10/10;
- format 292/0, analyze zero issue, metadata/governance/architecture PASS;
- Android debug build e iOS Simulator debug build PASS;
- clean AAB/APK release e validator PASS.

`CODEX_EXECUTION_COMPLETE_TO_REVIEW`.

## Review — `CODEX_REVIEWER`

- exact SHA `2f1987ea02fe67b3f537a2de6527c705771516df`, reviewer
  read-only distinto, worktree pulito;
- esito combinato `CHANGES_REQUIRED`: 0 P0, 0 P1, 4 P2, 1 P3;
- `F-039-R01` P2: `jarsigner` applicato all'APK rifiuta un APK valido
  firmato v2-only;
- `F-039-R02` P2: la readiness accetta un signer non confrontato con un
  fingerprint approvato e un path credenziale non-file/non-JSON;
- `F-039-R03` P2: package/version/manifest sono verificati soltanto sull'APK,
  non direttamente sull'AAB destinato a Play;
- `F-039-R04` P3: il resolver `apkanalyzer` contiene un path workstation
  hardcoded e non usa i boundary SDK portabili;
- `F-039-R05` P2, review security diff-scoped: l'AAB è passato allo scanner artifact ma non
  decompresso, quindi una fixture secret-shaped compressa produce un falso
  negativo; classificato P2 tecnico sul gate release.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Security Fix 2 — `CODEX_FIXER`

- `F-039-SR01`: AAB verificato con `jarsigner -strict`; entry non firmate,
  severe warning diverse dalla chain self-signed e più signature block/certificati
  falliscono chiusi. Le regressioni reali coprono post-sign e multi-signer;
- `F-039-SR02`: il release validator impone `.aab`/`.apk`, mentre lo scanner
  riconosce ZIP dal magic content anche per `.bundle`, `.AAB` e file senza
  estensione;
- `F-039-SR03`: entry names e commento ZIP partecipano allo scanner tramite un
  metadata stream redatto con limite 4 MiB;
- `F-039-SR04`: il manifest AAB richiede esattamente tre `uses-permission`, la
  permission dinamica signature-scoped e i soli exported `MainActivity` e
  `ProfileInstallReceiver` protetto da `DUMP`;
- `F-039-SR05`: conteggio iniziale corretto a quattro P2 più un P3,
  `F-039-R05` e tutte le closure hanno ID stabile.

Gate fixer sullo SHA tecnico
`35a60a0bcbc2649c960cc9674cb93725eaa1a210`: clean release AAB/APK,
validator reale unsigned e fixture firma avversariale `PASS`; scanner source
671 e artifact 283; fixture security 47/47 negative e 5/5 positive; validator
mirati 12/12; `scripts/check.sh` con 781 test non-performance, 10 performance,
repeat 70/70, analyze, format 296/0 e build debug Android/iOS tutti `PASS`.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

## Fix — `CODEX_FIXER`

- `F-039-R01`: firma AAB verificata con `jarsigner`, APK con `apksigner`;
  una regressione reale genera un APK v2-only e lo accetta con signer AAB/APK
  identico;
- `F-039-R02`: upload preflight richiede fingerprint SHA-256 approvato e
  service-account regular JSON con email/progetto attesi; `/dev/null`, JSON
  malformato, account e signer diversi falliscono chiusi;
- `F-039-R03`: parser protobuf bounded valida direttamente package/version/SDK,
  application policy, Maps, deep link e receiver nell'AAB; i `libapp.so` delle
  tre ABI devono coincidere tra AAB e APK;
- `F-039-R04`: resolver portabile usa PATH valido, `ANDROID_HOME` o
  `ANDROID_SDK_ROOT`, senza path workstation;
- scanner artifact esteso a `.aab` con fixture DEFLATED negativa/positiva;
  l'artifact reale passa da 132 blob/file apparenti a 281 file effettivamente
  ispezionati.

Gate fixer sullo SHA tecnico
`6b4a79d76ea48649add220f7889ce9121b3e1b49`: clean AAB/APK release,
validator unsigned reale, fixture v2-only e input Play, `scripts/check.sh`,
779 test non-performance, 10 performance, repeat 70/70, analyze, format 296/0,
build Android debug e iOS Simulator debug tutti `PASS`.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

## Security re-review — `CODEX_RE_REVIEWER`

- exact SHA `7951945ed5bd1c928913785ee6461c614cc8d4d8`, range completo
  `2f1987e…7951945`, reviewer read-only distinto e report security finalizzato;
- esito `CHANGES_REQUIRED`: 0 P0, 0 P1, 4 P2 e 1 P3 governance;
- `F-039-SR01` P2: la verifica non-strict accetta entry AAB post-sign e un
  archivio multi-signer attribuito al primo fingerprint;
- `F-039-SR02` P2: il riconoscimento archive dipende dal suffisso e un AAB
  rinominato `.bundle` con marker DEFLATED supera il gate completo;
- `F-039-SR03` P2: nomi entry e commento ZIP non partecipano allo scanner
  secret-shaped;
- `F-039-SR04` P2: l'allowlist manifest non rifiuta `READ_SMS` o un service
  aggiuntivo `exported=true` non protetto;
- `F-039-SR05` P3: review e worklog iniziali contavano tre P2 pur
  documentandone quattro e il finding scanner non aveva un ID stabile.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Security Fix 2 re-review — `CODEX_RE_REVIEWER`

- exact SHA `8edcfa063a4d46762e45c22ed3acb30687b5eb97`, reviewer security e
  reviewer prodotto read-only distinti, worktree pulito;
- esito combinato `CHANGES_REQUIRED`: 0 P0, 0 P1, 3 P2 e 1 P3;
- `F-039-SR01` P2: il conteggio dei signature block AAB era case-sensitive,
  mentre `jarsigner` accetta anche estensioni `.rsa`/mixed-case, consentendo a
  un secondo signer di non partecipare al confronto;
- `F-039-SR03` P2: lo scanner includeva entry names e solo il commento globale,
  non i commenti ZIP per-entry;
- `F-039-SR04` P2: il parser raccoglieva soltanto `uses-permission`, ignorando
  `uses-permission-sdk-23` e `uses-permission-sdk-m`;
- `F-039-SR06` P3: conteggio e dimensione ZIP erano verificati dopo
  materializzazione, senza limiti preventivi su numero entry, espansione e
  rapporto di compressione;
- `F-039-SR02` e `F-039-SR05` restano chiusi; report security finalizzato in
  `/private/tmp` e nessun artifact o dato sensibile versionato.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Security Fix 3 — `CODEX_FIXER`

- `F-039-SR01`: signature block AAB conteggiati case-insensitive; la fixture
  rinomina il secondo block `.RSA` in `.rSa` e il gate lo respinge come set
  multi-signer;
- `F-039-SR03`: central directory verbose bounded comprende commenti per-entry
  ed extra field; il container ZIP raw partecipa inoltre allo scanner;
- `F-039-SR04`: ogni elemento manifest con prefisso `uses-permission` diverso
  dall'elemento canonico fallisce chiuso; regressioni coprono gli alias
  `uses-permission-sdk-23` e `uses-permission-sdk-m`;
- `F-039-SR06`: preflight prima dell'estrazione impone al massimo 2.048 entry,
  512 MiB compressi/non compressi e rapporto di espansione 200×; fixture
  entry-count e compression bomb vengono respinte.

Gate fixer sullo SHA tecnico
`4f2e6867649374f4b93b581475560c2a6ae5de50`: clean AAB/APK release e
validator reale `PASS`, scanner source/artifact 671/285, fixture security 50/50
negative e 5/5 positive, fixture firma avversariale `PASS`; `scripts/check.sh`
exit 0 con 782/782 test non-performance, 10/10 performance, repeat 70/70,
format 296/0, analyze e build debug Android/iOS `PASS`. Artifact unsigned e
SHA-256 byte-identici al candidato precedente.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

## Security Fix 3 re-review — `CODEX_RE_REVIEWER`

- exact SHA `09d2207c7d7409cf933b3783e75d7765e99e1e9c`, due reviewer
  read-only distinti e worktree pulito;
- review prodotto `APPROVED`; security re-review `CHANGES_REQUIRED` con
  0 P0, 0 P1, 0 P2 e 1 P3;
- `F-039-SR01`, `F-039-SR03` e `F-039-SR04` chiusi; `F-039-SR02` e
  `F-039-SR05` restano chiusi;
- `F-039-SR06` P3 riaperto: il preflight usa size ZIP dichiarate
  falsificabili. Un PoC da 16.453 byte dichiara 2.000.000 byte/rapporto 123×,
  emette realmente 16.777.216 byte e il full scanner termina exit 0;
- fix richiesto: contatore streaming dei byte effettivamente decompressi con
  abort alle soglie e regressione su size local/central falsificate.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Security Fix 4 — `CODEX_FIXER`

- `F-039-SR06`: lo stream aggregato viene decompresso prima
  dell'estrazione tramite `unzip -p | head`, con cap effettivo 512 MiB e
  `pipefail`; i byte realmente emessi devono coincidere con la size dichiarata
  e rispettare il rapporto 200×;
- la regressione crea 16 MiB reali, falsifica local header e central directory
  a 2.000.000 byte e verifica il rifiuto `payload archivio incoerente` prima
  della materializzazione;
- lo stream bounded viene riusato per scansionare anche entry duplicate, senza
  una seconda decompressione non controllata.

Gate fixer sullo SHA tecnico
`e7cb2d970cb987267a2cce9f23a187e2bc712f25`: fixture security 51/51 negative
e 5/5 positive, PoC forged-header indipendente e artifact reale 671/285
`PASS`; `scripts/check.sh` exit 0 con 782/782 non-performance, 10/10
performance, repeat 70/70, format 296/0, analyze e build Android/iOS `PASS`;
validator release e fixture firma avversariale `PASS`. Artifact unsigned e
SHA-256 invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

## Security Fix 4 re-review — `CODEX_RE_REVIEWER`

- exact SHA `7ddd6f720c23964866cf741bd1351645b6fa9c62`, reviewer prodotto e
  security read-only distinti, worktree pulito;
- esito `CHANGES_REQUIRED`: 0 P0, 0 P1, 0 P2 e 1 P3;
- `F-039-SR06`: cap 512 MiB, actual==declared uncompressed e ordine
  pre-extraction chiudono il PoC precedente, ma il rapporto usa ancora la
  compressed size dichiarata;
- PoC: archive fisico 16.453 byte, compressed size local/central gonfiata,
  output reale 16.777.216 byte; `unzip -p/-tqq` e full scanner exit 0;
- fix richiesto: dimensione fisica container come denominatore autorevole,
  rifiuto `declared compressed > physical container` e regressione dedicata;
- finalizer security invocato una volta ma exit 2 per manifest preparatorio
  assente; validation/attack-path evidence preservate, nessun report sealed
  dichiarato né retry improprio.

`CODEX_REVIEW_CHANGES_REQUIRED_TO_FIX`.

## Security Fix 5 — `CODEX_FIXER`

- `F-039-SR06`: dimensione fisica del container letta con `wc -c`, bounded a
  512 MiB e usata come denominatore autorevole del rapporto 200×;
- `compressed size` dichiarata maggiore del container fisico fallisce chiusa;
  il controllo metadata resta un preflight rapido, mentre actual/physical è il
  gate non falsificabile;
- regressione dedicata gonfia entrambe le compressed size local/central a
  100.000 byte su un file fisico da 16.457 byte che emette 16.777.216 byte e
  verifica il rifiuto prima dello streaming.

Gate fixer sullo SHA tecnico
`0ec1184f5e1413567c32c10cdcc2e0717594234b`: fixture security 52/52 negative
e 5/5 positive, PoC forged compressed-size e artifact reale 671/285 `PASS`;
`scripts/check.sh` exit 0 con 782/782 non-performance, 10/10 performance,
repeat 70/70, format 296/0, analyze e build Android/iOS `PASS`; validator
release e fixture firma avversariale `PASS`. Artifact unsigned e SHA invariati.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`.

## Security Fix 5 re-review — `CODEX_RE_REVIEWER`

- exact SHA `15e3c4bd78a6cee6ca85cbde75b5fec7068f8596`, reviewer prodotto e
  security read-only distinti, worktree pulito;
- esito combinato `APPROVED`: 0 P0, 0 P1, 0 P2 e 0 P3;
- `F-039-SR06` chiuso: container fisico bounded, declared compressed non
  superiore al fisico, actual uguale al declared uncompressed e rapporto
  autorevole actual/physical entro 200×;
- PoC forged-uncompressed, forged-compressed e stream effettivo 513 MiB tutti
  respinti prima dell'estrazione; fixture 52/52 negative e 5/5 positive;
- artifact reali 671/285, signature fixture, manifest 5/5, release validator
  unsigned, governance 9/9, bash syntax e diff check `PASS`;
- finalizer security exit 0 alla prima invocazione e report-format validator
  `PASS`, report locale SHA-256
  `014aef5a14c15e059b77e64c47269ce7e82c21cddeb5e5b028b55eaf01ef85de`.

`CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION`. La conferma persistente
del train autorizza PR exact-SHA e merge normale solo dopo CI verde.

## CI Fix 1 — `CODEX_FIXER`

- `F-039-CI01` P2: PR #18, head `9bf4e857`, run `32009738614` attempt 1 e
  rerun attempt 2 riproducono exit 1 nello step `Validate Android v2-only
  signature boundary`;
- Quality, Android debug e iOS Simulator sono `PASS`; il job release costruisce
  clean AAB/APK e il validator production-like passa prima della failure;
- il precedente uso di `set -e` con oracle `grep` silenziosi rendeva il token
  fail-closed non osservabile nel log GitHub;
- repliche indipendenti su macOS, Linux ARM/x64 e Java 17/21 attraversano la
  fixture, quindi nessun artifact o boundary release viene indebolito;
- ogni oracle ora emette uno stage bounded; i log negativi espongono soltanto
  l'enum `ANDROID_RELEASE_BLOCKED`, mai path credenziali, fingerprint o payload.
- il run diagnostico `32013833404` ha isolato il token reale:
  `SIGNING_FINGERPRINT_UNREADABLE` prima del controllo credenziale; il parser
  APK ora normalizza spazi, separatori e case come il parser AAB e distingue i
  due errori fail-closed;
- il run exact-head `32014928249` su `f7873128` conferma Quality, Android debug,
  iOS Simulator, clean AAB/APK e release validator tutti `PASS`, ma isola ancora
  `APK_SIGNING_FINGERPRINT_UNREADABLE`: il formato testuale del digest
  `apksigner` non è un contratto portabile tra runner/tool version;
- il Fix 2 non analizza più quella riga: `apksigner --print-certs-pem` fornisce
  il certificato già verificato, il validator impone un solo certificato APK e
  calcola il digest SHA-256 con lo stesso `keytool` usato per l'AAB. La fixture
  locale completa attraversa v2-only, signer AAB/APK, negative parziale/
  multi-signer/mixed-case e input Play coerenti;
- CI PR exact-head `32016169548` su `7a25585c145304fc992cc2ce2f032af3f32a4b14`:
  Quality, Android debug, iOS Simulator e Android release candidate `PASS`;
  tutti gli step release, inclusa la fixture completa v2-only, sono `PASS`.

`CODEX_FIX_COMPLETE_TO_RE_REVIEW`; `F-039-CI01` è candidate `CLOSED` e deve
essere confermato da reviewer read-only distinto.

## CI Fix 2 re-review — `CODEX_RE_REVIEWER`

- exact final SHA `ba950b755399d8294af5d8ebbe2c07a9dc7484c2`, technical
  fix `7a25585c145304fc992cc2ce2f032af3f32a4b14`, worktree pulito;
- reviewer prodotto e security read-only distinti: `APPROVED`, 0 P0, 0 P1,
  0 P2 e 0 P3; `F-039-CI01 CLOSED`;
- parser APK: PEM verificato da `apksigner`, cardinalità signer pari a uno,
  certificato e SHA-256 derivati con `keytool`, confronto AAB/APK fail-closed;
- probe indipendenti single/multi-signer e digest multipli, fixture completa,
  governance 9/9, validator/scanner 671/285 e no-leakage tutti `PASS`;
- security finalizer exit 0, report-format `PASS`, report SHA-256
  `aa1a6aaa283be5794712fd2f2743911f89cf52c17c087e902d8907aad8110e5c`;
- CI PR exact-head `32017859910` su `ba950b75`: quattro job e ogni step
  `success`, inclusa la fixture firma v2-only; nessun artifact pubblicato.

`CODEX_REVIEW_APPROVED_AWAITING_USER_CONFIRMATION`. La conferma persistente
del train autorizza il merge normale dopo CI exact-SHA del presente commit;
non autorizza upload Play o production.

## Chiusura

- **Classificazione target**: `DONE_INTERNAL_RELEASE_PUBLISHED` oppure
  `TECHNICALLY_COMPLETE_EXTERNAL_CREDENTIAL_REQUIRED`
- **Production Play**: vietata
- **Data completamento**: non ancora
