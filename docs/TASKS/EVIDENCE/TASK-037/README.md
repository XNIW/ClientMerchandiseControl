# Evidence TASK-037

Snapshot di handoff:
`ACTIVE / EXECUTION / CODEX_PLANNING_APPROVED_TO_EXECUTION`.

## Provenance

- baseline Client: `96a9359c052a98fb0df7fd8562e648b9a485a2f0`;
- baseline Admin: `59668348e4c728b44b998c80f1aded61e6114a3f`;
- TASK-036 PR Client #14/Admin #93, review indipendente `APPROVED` e CI PR/main
  exact-SHA verdi;
- migration timezone applicata staging con run `31983967203` dopo dry-run
  `31983931437`;
- delivery tracking staging 60/60 e cleanup verdi con run `31984019280`;
- production non modificata, physical device/manual screen reader restano gate
  esterni distinti e non mascherano i gate automatici;
- budget TASK-037 congelati nel file task prima di nuove ottimizzazioni.

## Execution

### Ambiente e metodo

- runtime Client di partenza: `b0c3457606f45c8e32a038608b5551b07a2b7744`
  (closeout TASK-036 sopra `origin/main` `96a9359c`);
- Flutter 3.44.8, Dart 3.12.2, macOS 26.6.1; Android Emulator arm64 API 35;
- benchmark locali: 5 warm-up, 30 campioni e p50/p95/p99, ripetuti cinque volte;
- device launch: cinque cold con force-stop e cinque warm bring-to-front via
  `adb am start -W`; memoria da `dumpsys meminfo` su build profile;
- staging: solo fixture `task010-load`, deterministic ID, guard exact-SHA,
  allowlist project, trap di cleanup e nessun dato cliente/production.

### Baseline prima del fix

Cinque run del precedente benchmark 25k:

| Metrica | Range baseline |
|---|---:|
| open | 296–479 ms |
| write 20k | 480–510 ms |
| catalog p95 | 1.226–1.290 us |
| search p95 | 3.836–4.592 us |

Il tempo query era già verde. Il finding reale `F-037-E01` era la retention:
`StorefrontVerifiedImageLoader` aveva una `Map<String, Uint8List>` senza cap e
accettava fino a 5 MiB per ogni payload. Anche richieste concorrenti dello stesso
digest avviavano download distinti. Non esisteva quindi un massimo di memoria
dimostrabile al crescere delle immagini viste nel processo.

### Fix e regressioni

- LRU content-addressed: massimo 64 entry e 24 MiB, doppio guard, copie isolate;
- single-flight per digest e retry dopo failure;
- stress 256 immagini con finestra 16 entry/16 KiB: MRU resta cached, la prima
  entry viene riscaricata dopo eviction;
- request concorrenti stesso digest: 2 consumer / 1 request;
- update location v5: rebuild presente per `_DeliveryTrackingSection`, assente
  per order state/body/header/items/timeline;
- repeat valido: `10 x 2 = 20/20`. Una serie precedente con `--plain-name` usato
  come regex non ha selezionato test ed è esclusa dall'evidence.

### Dataset e metriche finali locali

Cinque run finali, tutti `PASS`:

| Profilo | Righe/categorie | open | write | catalog p95 | search p95 |
|---|---:|---:|---:|---:|---:|
| small | 1.000/250 | 295–460 ms | 82–84 ms | 0,991–1,224 ms | 1,069–1,335 ms |
| medium | 10.000/250 | 1 ms | 248–259 ms | 0,596–0,684 ms | 1,815–2,151 ms |
| extreme | 25.000/250 | 1 ms | 513–545 ms | 0,559–0,714 ms | 4,124–4,603 ms |

| Commerce locale | Dataset | p95 finale | Budget | Esito |
|---|---:|---:|---:|---|
| cart warm read | 100 linee | 0,522–0,682 ms | 250 ms | PASS |
| cart mutation | 100 linee | 0,804–0,962 ms | 50 ms harness | PASS |
| order cache write | 50 card, 17.105 byte | 0,833–1,133 ms | 100 ms | PASS |
| order cache read | 50 card | 1,539–1,647 ms | 50 ms | PASS |
| order selector/filter | 500 ordini | 0,154–0,167 ms | 5 ms | PASS |

I database in-memory sono chiusi in `finally`/tearDown; il cap catalogo resta
25.000 e quello cart 100, senza alterare limiti server canonici.

### Android profile reale

Artifact locale non versionato: `build/app/outputs/flutter-apk/app-profile.apk`,
96,0 MB universale profile. L'app è stata installata e avviata realmente in
development fail-closed, senza credenziali o dati remoti.

| Metrica | Campioni | p50 | p95 | p99/max | Budget | Esito |
|---|---:|---:|---:|---:|---:|---|
| cold process | 5 | 1.146 ms | 1.359 ms | 1.359 ms | 5.000 ms | PASS |
| warm foreground | 5 | 100 ms | 411 ms | 411 ms | 1.000 ms | PASS |
| PSS launch / post gesture | 2 | 124.473 KB | 131.292 KB | 131.292 KB | 200 MB | PASS |
| RSS launch / post gesture | 2 | 239.952 KB | 252.244 KB | 252.244 KB | 300 MB | PASS |

`dumpsys gfxinfo` ha osservato soltanto 7 frame del `ViewRoot` e non il flusso
Flutter `SurfaceView`: la relativa percentuale jank non è usata come metrica
candidata. Il nuovo journey `SchedulerBinding.addTimingsCallback` viene eseguito
separatamente durante la fixture committed staging.

### Staging backend reale

Run `31985297932`, exact Admin main
`59668348e4c728b44b998c80f1aded61e6114a3f`, `SUCCESS`:

- 22.000 prodotti, 22.000 pubblicazioni, 20.000 righe projection pubblicate,
  100 categorie, 5.000 promotion link, 91.200 righe equivalenti;
- catalog 30 campioni p50/p95/p99/max 44,347/50,608/53,501/53,983 ms;
- search 30 campioni 676,877/718,325/747,381/756,765 ms;
- detail 30 campioni 2,151/6,069/8,009/8,530 ms;
- planner: keyset e FTS index usati; cleanup `true`, residue `0`;
- migration timezone già applicata: apply step correttamente skipped, dry-run e
  boundary pubblici verdi; production non toccata.

Il run `31985724356` usa lo stesso SHA e una finestra committed di 180 s. Cinque
journey Android profile sul Client SHA `398bd05` sono `PASS`:

| Metrica end-to-end | 5 campioni | p50 | p95/max |
|---|---:|---:|---:|
| first usable | 22/28/24/23/23 ms | 23 ms | 28 ms |
| Home data-backed | 1.842/1.568/1.465/1.583/2.660 ms | 1.583 ms | 2.660 ms |
| backend ready | 2.575/2.300/2.316/2.198/2.693 ms | 2.316 ms | 2.693 ms |
| catalog | 1.232/1.100/749/1.633/882 ms | 1.100 ms | 1.633 ms |
| search | 888/967/697/716/694 ms | 716 ms | 967 ms |
| detail | 1.360/501/499/617/502 ms | 502 ms | 1.360 ms |
| favorite roundtrip | 1/6/2/1/2 ms | 2 ms | 6 ms |

- 2.657 frame complessivi; frame p95 per run 21,636–25,157 ms e p99
  33,457–49,255 ms;
- 39 frame >32 ms, 1 >100 ms e 0 >700 ms; ogni run rispetta p95 <=32 ms;
- immagini reali staging presenti nel primo prodotto; download/digest/cache e
  decode `cacheWidth` sono esercitati nel journey;
- reinstallazione dello stesso artifact profile/config: PSS 170.239 KB, RSS
  291.160 KB, swap 0. Il margine RSS rispetto ai 300 MiB è ridotto e resta
  osservabile, ma il budget non è superato.

I primi due tentativi hanno fallito chiusi prima della rete per nomi define non
canonici; un terzo, avviato prima del commit fixture, ha visto Home unavailable.
Sono failure di harness documentate e non entrano nei cinque campioni candidati.
Il run è terminato `SUCCESS`: backend catalog/search/detail p95
49,787/700,498/5,308 ms, keyset/FTS true, cleanup true, fixture residue 0,
connection material rimosso e artifact non-secret caricato.

### Dipendenze e debt

- `flutter pub outdated --no-dev-dependencies`: major Riverpod/secure storage e
  aggiornamenti Supabase non adottati perché richiedono migrazione o aumentano il
  rischio senza necessità release;
- `build_daemon 4.1.3` risultava ritirata; dry-run mostrava un delta singolo, quindi
  lock aggiornato a `4.1.5` senza altri package;
- scan `TODO/FIXME/HACK/print/skip`: nessun debt runtime; `debugPrint` resta solo
  negli harness metrici/integration e gli `ignore` generati non sono production;
- nessun package nuovo.

### Gate corrente

`scripts/check.sh` prima del lock update: exit 0, 760 test non-performance con
coverage, repeat TASK-034 `5 x 14 = 70/70`, 4 performance, 631 file security,
fixture 41/41+4/4, telemetry/localization/governance/architecture, format/analyze,
APK debug e iOS Simulator debug. Il gate finale sarà rieseguito sull'exact SHA dopo
staging e documentazione; nessun esito intermedio viene promosso a CI finale.
