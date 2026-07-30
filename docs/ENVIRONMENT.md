# Ambiente

## Inventario iniziale sanitizzato

- Workspace iniziale: vuoto, senza `.git`.
- Sistema: macOS 26.6, arm64.
- Xcode: 26.6 (build 17F113).
- Git: 2.50.1.
- GitHub CLI: 2.96.0, autenticato come `XNIW`.
- Java: OpenJDK 21.0.10.
- Android Studio: presente.
- Android SDK: presente in directory utente; platform 31, 34, 35 e 36 rilevate.
- Android AVD: due configurazioni esistenti, inclusa API 35 arm64.
- iOS Simulator: runtime 26.1, 26.2, 26.4 e 26.5 presenti.
- Flutter iniziale: non installato.
- CocoaPods iniziale: non installato.

## Toolchain TASK-001

Flutter stable viene installato dal bundle ufficiale macOS arm64, con verifica SHA-256.
Versioni e risultato finale di `flutter doctor -v` saranno riportati nelle evidence.

Nessun path personale completo deve essere copiato negli artefatti di evidence.
