# TASK-002 — Screenshot manifest

Gli screenshot sono diagnostica visuale, non sostituiscono test, build o smoke.

- Produzione UI catturata dal commit `fd091d18d012d56ecf4e7a38f8a202439acd6204`.
- Tra `fd091d1` ed `ec599758` non cambia alcun file runtime sotto `lib/`, `android/` o
  `ios/`; cambiano soltanto test e dependency di test.
- Android: `Medium_Phone_API_35`, Android 15/API 35, 1080×2400 o 2400×1080.
- iOS: iPhone 17 Pro Simulator 26.5, 1206×2622.
- Metodo: screenshot di piattaforma; il transcript grezzo di acquisizione non è
  conservato.
- Ispezione visuale: nessun dato cliente, secret, URL production o prodotto/prezzo/stock
  simulato.

| File | Scenario | Dimensioni | SHA-256 |
|---|---|---:|---|
| `screenshots/android-task002-home-light.png` | Home, light, portrait | 1080×2400 | `23e1e33c2462607ca6a970853dce54591fc6e88781889f0df980a4ac881b12dd` |
| `screenshots/android-task002-catalog-light.png` | Catalog placeholder, light | 1080×2400 | `4dfd2b6a8a4aaa2775ba9fbdba635af39cc0481c384d8b73e10223bd726245f5` |
| `screenshots/android-task002-account-light.png` | Account placeholder, light | 1080×2400 | `ea717d926d74b7c5c10a47a392cc74e44dd9b54c9474860692d0cf730432e639` |
| `screenshots/android-task002-home-dark.png` | Home, dark, portrait | 1080×2400 | `fe5ebcec694f55035b9a3016ad4bbc948d8f03cb65400c622e5475e2ba157012` |
| `screenshots/android-task002-home-dark-landscape.png` | Home, dark, landscape | 2400×1080 | `342aeaaf90bb1c9d5c4fa4ee0254e9d4f9fdf135de49a8d6d421371de7b65062` |
| `screenshots/android-task002-home-dark-text-200.png` | Home, dark, text 200% | 1080×2400 | `a2e6e74c5bf2410c4e005b8020929d6c138571c9f5c7bca11599a05812ff687d` |
| `screenshots/ios-task002-home-light.png` | Home italiana, light | 1206×2622 | `a8e043a1b49d25f1303faf1deb482481801d18143c6dfc071903ccbec78cc59a` |
| `screenshots/ios-task002-home-dark.png` | Home italiana, dark | 1206×2622 | `ccd6b50ee32c83974c7db69564ca2a7014f37de679c9f1c8da855b1f7e63ffa7` |
| `screenshots/ios-task002-home-dark-accessibility-text.png` | Home italiana, dark, dynamic type accessibility | 1206×2622 | `6c7a28f91ad9412a8a1b8f7b01a1451e7e950cfd6393c30624ea6ba89b4bfedd` |

Il test automatico copre anche Cart, back, persistenza, tutte le tab a 200% e landscape
su entrambe le piattaforme, scenari che non vengono inferiti da questa galleria.
