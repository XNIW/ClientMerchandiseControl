# Manifest screenshot sanitizzati — TASK-004 Fix

## Provenance

- Commit runtime:
  `bccb6f55a9ceaf46d946c95fc79b5b7d3ae02055`
- Profilo: development senza `--dart-define`
- Contenuto: Home e banner offline dopo avvio reale
- Ispezione: visiva, completata su entrambi i PNG
- Dati personali o configurazione: assenti

## Artifact

| File | Target sanitizzato | Dimensioni | Byte | SHA-256 |
|---|---|---:|---:|---|
| `android-development-home.png` | Android Emulator API 35 | 1080 × 2400 | 127790 | `517db01157b09f6de88d7fc4e1ea935312736e75dba2513f39493f84d9c41e4e` |
| `ios-development-home.png` | iPhone 17 Pro Simulator iOS 26.5 | 1206 × 2622 | 145444 | `646a2d9b7f4b7320f7a785ad11533a711f3ed9453026e15c56b90ca870f75e63` |

## Sanitizzazione

Le schermate mostrano soltanto:

- chrome di sistema del simulatore;
- banner tecnico «backend non configurato / development offline»;
- shell Home e quattro destinazioni;
- copy localizzata placeholder, senza dati commerciali.

Non compaiono URL, publishable key, callback raw, token, cookie, account Google, user ID,
notifiche personali, percorso locale o dato cliente.
