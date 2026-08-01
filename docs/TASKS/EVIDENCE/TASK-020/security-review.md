# Security review — TASK-020

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
| Client security scanner | PASS | CMD-Z02, 336 file Git, index e worktree correnti, zero violazioni |
| Fixture scanner | PASS | CMD-Z01/Z02, 32/32 negative respinte e 2/2 positive accettate |
| JWT customer semantic probe | PASS | CMD-Z02, `role=authenticated` e ogni ruolo diverso dall'unico letterale scalare `anon` respinti; zero JWT nel Git corrente |
| Bundle staging ricostruiti | PASS | CMD-Z04/Z05, 548 file APK + 81 file Runner = 629, zero secret privilegiati; digest before/after invariati |
| Symlink, snapshot Git e failure operative | PASS | CMD-Z02, blob/index/worktree `120000`, enumerazione parziale, read/decode/parser failure respinti fail-closed |
| PEM ed estensioni sensibili | PASS | CMD-Z02/Z05, label standard/DSA/encrypted e denylist case-insensitive |

La Re-review 4 ha rieseguito lo scanner su 336 file, 32/32 fixture negative,
2/2 positive e 21/21 probe avversari senza trovare bypass o JWT letterali.
T020-RR3-C-001 e T020-REV-015 sono `CLOSED`; 0 finding P0–P3 restano aperti.

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
- redirect allow-list e live OAuth restano `BLOCKED` da login/MFA Supabase;
- la callback warm iOS è stata consegnata e validata in CMD-P01; questa prova non
  sostituisce OAuth live, restore e logout reali.
- lo scanner tratta conservativamente come non pubblicabile qualunque JWT che non
  contenga un JSON object con un solo ruolo scalare letterale `anon`; escape Unicode
  e campi `role` annidati/duplicati sono respinti anche se innocui, con possibile
  falso positivo ma senza allargare il confine pubblicabile;
- Cancel attende un exchange SDK non cancellabile prima di consentire Retry: preserva
  l'invariante di sicurezza contro sessioni tardive, ma un trasporto che non completa
  può mantenere lo stato `cancelling`; un hardening richiede cancellazione reale al
  port HTTP o quarantena persistente, non un semplice `Future.timeout`.

Nessun `PASS` remoto o live è inferito.

Matrice CA/T e comandi canonici:
`commands-and-results.md`, CMD-X01/X03/CMD-Z01/Z02/Z05/CMD-W01/W02/CMD-P01/CMD-R01,
CA-03/05/08/21/22/24/33/36
e T-02/05/15/17/25/26.
