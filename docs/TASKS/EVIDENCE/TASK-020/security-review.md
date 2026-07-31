# Security review executor — TASK-020

## Controlli implementati

- OAuth Google tramite Supabase, browser esterno, Authorization Code + PKCE.
- Callback canonico, parser a cardinalità stretta e validazione
  scheme/host/path/payload prima dell'exchange.
- Flutter deep linking, `detectSessionInUri` e auto-handling iOS del plugin
  disabilitati; un solo consumer Dart.
- Sessione e verifier nello stesso adapter Keychain/Keystore fail-closed; persistenza
  esplicita prima di authenticated, failure osservabili e nessun fallback plaintext.
- Android backup disabilitato; iOS Keychain non sincronizzato e this-device con
  first-install cleanup e tre tombstone non sensibili per purge pendenti:
  SharedPreferences, secure store e journal file Application Support scritto per
  primo.
- Controller eager, queue bounded, single-flight, generation token, replay cache
  bounded, exchange cancel compensato e sessioni scadute rifiutate.
- Error mapping chiuso, `debug:false`, identity bounded e metadata non
  autorizzativi; nessun avatar remoto.

## Scan

| Verifica | Esito | Risultato |
|---|---|---|
| Secret-shaped value in APK | PASS | zero |
| Secret-shaped value in iOS app | PASS | zero |
| PEM effettivo | PASS | soli delimitatori parser di dipendenza; zero payload contiguo |
| Auth runtime log call | PASS | zero |
| Config locale/artifact tracciato | PASS | zero |
| Config locale/artifact in status | PASS | zero |
| Service role/secret applicativo | PASS | nessun valore; sole denylist di rifiuto dove applicabile |
| Production config/cert/provisioning | PASS | assenti dal diff |
| `git diff --check` | PASS | exit 0 |
| Client security scanner | PASS | CMD-X04, 336 file Git, index e worktree correnti, zero violazioni |
| Fixture scanner | PASS | CMD-X04, 22/22 negative respinte e 1/1 positiva accettata |
| Bundle staging ricostruiti | PASS | CMD-B01, 548 file APK + 81 file Runner = 629, zero secret privilegiati; digest before/after invariati |
| Symlink, snapshot Git e failure operative | PASS | CMD-X04, blob/index/worktree `120000`, enumerazione parziale, read e decode failure respinti fail-closed |
| PEM ed estensioni sensibili | PASS | CMD-X04/CMD-B01, label standard/DSA/encrypted e denylist case-insensitive |

I delimitatori PEM nel `kernel_blob` iOS provengono dal parser della dipendenza
transitiva: tre coppie begin/end sono adiacenti e il quarto marker non ha payload
base64 nelle successive 200 stringhe. Non costituiscono una chiave incorporata.

## Threat model e rischio residuo

`docs/SECURITY/GOOGLE-OAUTH-THREAT-MODEL.md` contiene TM-01…TM-30 e copre CSRF/state,
PKCE, collisione custom scheme, leakage, replay/fixation, callback corrotti, logout,
metadata, screenshot, resume, account switching e cancellation.

Rischi residui:

- il custom scheme non prova ownership; PKCE mitiga l'uso del code ma non il DoS;
- un device rooted/jailbroken, OS o browser compromesso resta fuori dal trust boundary;
- logout locale offline non garantisce revoca globale;
- se falliscono simultaneamente delete e tutte le mutazioni dei tre canali
  persistenti, un processo successivo non può distinguere l'intento di logout da
  uno stato precedente; il processo corrente resta `configurationError`. Il journal
  file chiude l'interleaving riproducibile in cui falliscono i due marker precedenti;
- redirect allow-list e live OAuth restano `BLOCKED` da MFA;
- la conferma OS iOS del custom scheme resta `BLOCKED` mentre il Mac è locked.
- Cancel attende un exchange SDK non cancellabile prima di consentire Retry: preserva
  l'invariante di sicurezza contro sessioni tardive, ma un trasporto che non completa
  può mantenere lo stato `cancelling`; un hardening richiede cancellazione reale al
  port HTTP o quarantena persistente, non un semplice `Future.timeout`.

Nessun `PASS` remoto o live è inferito.

Matrice CA/T e comandi canonici:
`commands-and-results.md`, CMD-X01/X03/X04/CMD-B01/CMD-R01,
CA-03/05/08/21/22/24/33/36
e T-02/05/15/17/25/26.
