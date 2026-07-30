# TASK-002 — Integrità repository esterni

Confronto finale read-only: `2026-07-30T19:04:34Z`.

Metodologia ripetuta identica tra baseline e verifica finale, senza fetch e con
`GIT_OPTIONAL_LOCKS=0`:

- `STATUS_SHA256`: output raw `git status --porcelain=v2 -z`;
- `CONTENT_FINGERPRINT_V1`: stato, diff binario da `HEAD` e digest dei blob untracked
  non ignorati.

| Repository | HEAD e branch | STATUS SHA-256 | CONTENT SHA-256 | Esito |
|---|---|---|---|---|
| `MerchandiseControlSplitView` | `c21de310c0a717f481a79d938888cbb99e8f930c`, `integrate/mac-final-android-20260717T150455Z` | `22b76cb8ac3be8dec3ae7d179d91ce7540eb236b5636f739fac508b689c6b124` | `663126bab110a1d34ae84785be3f5fa5d8ba575426e94c040d424de0fc0ccac6` | `PASS`, 1 record dirty invariato |
| `iOSMerchandiseControl` | `c1b7b706c5f05cd7e8dda74cea1122f6483df7ec`, `main` | `38a40f3a4f4431537fff8b08260b601979e964ba6a4163dacc9f2bd0bc2467fc` | `5523e8b90907ab030e0cda11a46957f0a75e6b56a7ad6c8351a2696fa7cfa32c` | `PASS`, 1 record dirty invariato |
| `merchandise-control-admin-web` | `710ff981f7bb0381159724ec02bbfec39a27eedf`, `main` | `76d58e31e7ebff589411e454be56796ddcdd504314e6797dcbb7fb0004626d0e` | `c991533cf159f0c068e02a6f09eeeed7fbfe6b62ab2d802b38b5839f29529db4` | `PASS`, clean invariato |
| `Win7POS` | `81acd479c187469fe0dc31f9b0fb3a162312c1cc`, `backup/win7pos-dirty-20260722-81acd479` | `a8ba743eb2358a9ca4ea09c5215517d116ba4d771fd36e4dd2fa6a4fdaf0b822` | `4aeda6ea6c50367bc0988667caea0258b9dcc76bee0e5f0a78a31d361733f5bc` | `PASS`, 13 record dirty invariati |

Risultato globale: `PASS` zero-write 4/4. Nessun repository esterno è stato modificato.
