# Runtime smoke — TASK-011

## Probe host staging

- Endpoint: Auth health ufficiale, senza URL persistito.
- Metodo: `GET`, header publishable `apikey`, timeout.
- Esito: `PASS`, HTTP 200 e schema health valido.
- Dati: nessuna query o risposta commerciale.

## Android Emulator

- Target: emulator già avviato.
- Comando: `flutter test integration_test/backend_readiness_smoke_test.dart -d …`
  con config staging locale ignorata.
- Esito: `PASS`, exit 0, 1/1.
- Osservato: readiness `ready`, sessione nulla e shell guest visibile.

## iOS Simulator

- Target: iPhone Simulator già avviato.
- Comando: lo stesso integration smoke con config staging locale ignorata.
- Esito: `PASS`, exit 0, 1/1.
- Osservato: readiness `ready`, sessione nulla e shell guest visibile.

Nessun URL, key, payload, token, project ref completo o dato personale è persistito.

## Matrice CA

| CA | Esito | Evidenza |
|---|---|---|
| CA-20 | PASS | La shell è rimasta renderizzata durante la readiness. |
| CA-22 | PASS | Output ed evidence sanitizzati. |
| CA-26 | PASS | Probe host reale health valido. |
| CA-27 | PASS | Android 1/1 e stato `ready`. |
| CA-28 | PASS | iOS 1/1 e stato `ready`. |

## Matrice test

| Test | Esito | Evidenza |
|---|---|---|
| T-22 | PASS | Probe host staging data-free. |
| T-23 | PASS | Smoke Android Emulator. |
| T-24 | PASS | Smoke iOS Simulator. |
