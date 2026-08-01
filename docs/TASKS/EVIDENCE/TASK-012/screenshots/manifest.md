# Manifest screenshot sanitizzati — TASK-012

## Provenance

- Commit runtime:
  `14cdc5175b9a596c8a4237e6796fefe3e7beda63`
- Profilo: development offline
- Acquisizione: normal app debug successiva agli smoke integration
- Ispezione: visiva, completata su tutti i PNG
- Dati personali o configurazione: assenti

## Artifact

| File | Target/scenario | Dimensioni | Byte | SHA-256 |
|---|---|---:|---:|---|
| `android-home-dark-landscape-200.png` | Android 15 API 35, Home, dark, landscape, testo 200% | 2400 × 1080 | 153691 | `82931c8237fe9c767afec418a45fdf2a63985b42f727a69b76b21239decc5cb2` |
| `android-account-dark-landscape-200.png` | Android 15 API 35, Account guest, dark, landscape, testo 200% | 2400 × 1080 | 71144 | `90ec79548bc8ce5405925de3a0b2007aaa05d2e91074fd9b6074960f55afffa6` |
| `ios-home-light.png` | iPhone 17 Pro iOS 26.5, Home, light, portrait, locale it | 1206 × 2622 | 252992 | `9e092a289221d67ba00f11480ed0e9ffd25d1ff354b0dfa8d56d49f8a269eb83` |

## Sanitizzazione

Le immagini mostrano soltanto chrome dei simulatori, shell cliente, copy localizzata,
stati futuri onesti e navigazione. Non compaiono URL, publishable key, callback, token,
cookie, account Google, email, user ID, notifiche, percorsi locali o dati commerciali.

## Matrice

| Criterio/test | Esito | Evidenza |
|---|---|---|
| CA-29, CA-32, CA-33 | PASS | Android dimostra 200%, landscape, full-width e contenuto scrollabile. |
| CA-36 | PASS | Artifact reali e sanitizzati su Android/iOS. |
| T-30, T-31 | PASS | Dimensioni, byte, digest e ispezione sopra. |
