# Evidence TASK-049

Snapshot finale:
`DONE / REVIEW / USER_APPROVED_DONE`.

## Testing channels e device

- `ANDROID_INTERNAL_UPLOAD_EXTERNAL_CREDENTIAL_REQUIRED`: release APK/AAB non
  firmati, nessun keystore o Play credential locale/GitHub osservabile.
- `IOS_TESTFLIGHT_EXTERNAL_CREDENTIAL_REQUIRED`: Apple Development presente; Apple
  Distribution, provisioning e App Store Connect assenti.
- `PHYSICAL_VALIDATION_PENDING_DEVICE`: `adb devices -l` vuoto; iPhone fisici
  elencati offline da `xcrun xctrace list devices`.
- iOS Simulator Release: build, install e launch `PASS` sul commit `30d226d0`.

## Production preflight

| Gate | Risultato |
|---|---|
| `check-production-readiness --mode technical` | PASS, exit 0; 72 READY, 59 UNVERIFIABLE_EXTERNAL |
| `check-production-readiness --mode activation` | atteso MISSING, exit 1; 71 READY, 60 requisiti esterni mancanti |
| `check-operations-readiness --mode prelaunch` | PASS, exit 0; 86 READY, 4 UNVERIFIABLE_EXTERNAL |

Il production project non è identificato/attestato; backup, restore, RLS e grants
production non sono verificati. `PRODUCTION_BACKEND_ACTIVATION_PENDING_EXTERNAL_REQUIREMENT`:
nessuna migration production e nessuna modifica customer. Public store rollout
`NOT_RUN_BY_DESIGN`.

## CI finale main

- Admin `a787331a`: CI `32510805597`, staging migration `32510819913` e Cloudflare
  staging `32530174055` `SUCCESS`.
- Android `d7c4953c`: CI `32512999137` `SUCCESS`.
- iOS `30d226d0`: CI retry `32526432062` `SUCCESS`.
- Client `36de0062`: CI `32528895782` `SUCCESS`.
