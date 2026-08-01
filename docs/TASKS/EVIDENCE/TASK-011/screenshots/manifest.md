# Manifest screenshot sanitizzati — TASK-011 Fix

## Provenance

- Commit runtime:
  `8621606d03d06b70f2a421c985c63b96ee3ef47a`
- Profilo: staging con file locale ignorato
- Acquisizione: app persistente dopo readiness, successiva agli smoke 1/1
- Ispezione: visiva, completata su entrambi i PNG
- Dati personali o configurazione: assenti

## Artifact

| File | Target/scenario | Dimensioni | Byte | SHA-256 |
|---|---|---:|---:|---|
| `android-staging-catalog.png` | Android 15 API 35, Catalogo, dark | 1080 × 2400 | 83494 | `6b851b597b0ecf4b98df750aa175f4ad71a1f54c0124007b68f95397d1343795` |
| `ios-staging-home.png` | iPhone 17 Pro iOS 26.5, Home, light | 1206 × 2622 | 121891 | `0a990aae8790392a0448d7e1d6b5f3a7fbdc2de8b2e42c139cf5baba24523f74` |

## Sanitizzazione

Le schermate mostrano soltanto:

- chrome di sistema dei simulatori;
- shell e destinazioni cliente;
- copy placeholder localizzata e data-safe;
- selezione Catalogo Android e Home iOS.

Non compaiono URL, publishable key, callback raw, token, cookie, account Google, email,
user ID, notifica personale, percorso locale o dato commerciale.

## Matrice CA

| CA | Esito | Evidenza |
|---|---|---|
| CA-22 | PASS | Ispezione visiva senza valori o dati sensibili. |
| CA-27 | PASS | Screenshot Android sul commit Fix. |
| CA-28 | PASS | Screenshot iOS sul commit Fix. |

## Matrice test

| Test | Esito | Evidenza |
|---|---|---|
| T-20 | PASS | Artifact e digest verificati. |
| T-23 | PASS | Android runtime visualmente attestato. |
| T-24 | PASS | iOS runtime visualmente attestato. |
