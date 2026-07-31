# Security review executor — TASK-020

## Controlli implementati

- OAuth Google tramite Supabase, browser esterno, Authorization Code + PKCE.
- Callback canonico, parser a cardinalità stretta e validazione
  scheme/host/path/payload prima dell'exchange.
- Flutter deep linking, `detectSessionInUri` e auto-handling iOS del plugin
  disabilitati; un solo consumer Dart.
- Sessione e verifier nello stesso adapter Keychain/Keystore fail-closed; nessun
  fallback plaintext.
- Android backup disabilitato; iOS Keychain non sincronizzato e this-device con
  first-install cleanup mirato.
- Controller eager, queue bounded, single-flight, generation token, replay cache
  bounded e soppressione dei risultati tardivi.
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
- redirect allow-list e live OAuth restano `BLOCKED` da MFA;
- la conferma OS iOS del custom scheme resta `BLOCKED` mentre il Mac è locked.

Nessun `PASS` remoto o live è inferito.
