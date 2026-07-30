# Audit product e brand — TASK-002

Audit read-only eseguito il 2026-07-30. Nessun repository esterno è stato modificato e
nessun valore di configurazione o dato reale è stato letto.

## Fonti

| Repository | Ref auditata | Stato iniziale sintetico | Fonte rilevante |
|---|---|---|---|
| ClientMerchandiseControl | `f6bd88263fe8369c9ececa38367f629f3d1a929f` | clean | `AppBrand.technicalDisplayName`, seed teal |
| MerchandiseControlSplitView | `c21de310c0a717f481a79d938888cbb99e8f930c` | un log non tracciato preesistente | launcher name localizzato, icona Android generica |
| iOSMerchandiseControl | `c1b7b706c5f05cd7e8dda74cea1122f6483df7ec` | scheme modificato preesistente | target/bundle tecnici, AppIcon vuota |
| merchandise-control-admin-web | `710ff981f7bb0381159724ec02bbfec39a27eedf` | clean | console tecnica e `shop_name` runtime |
| Win7POS | `81acd479c187469fe0dc31f9b0fb3a162312c1cc` | modifiche preesistenti | nome tecnico e shop name runtime |

## Risultato

- Nome progetto: `ClientMerchandiseControl`, tecnico.
- Package Dart: `client_merchandise_control`, tecnico.
- Technical display name: `Client Merchandise Control`, centralizzato.
- Public brand name: `UNVERIFIED / PROVISIONAL`.
- Legal entity: non disponibile nel repository.
- Store display name: futuro dato shop-scoped, non brand globale.
- Tagline: non definita.
- Logo/wordmark: nessuna fonte autorevole.
- App/store icon: asset Flutter generici; identità definitiva fuori scope.
- Palette: seed client `#245C55` senza provenance marketing, mantenuto come provvisorio.
- Font: sistema; nessun font di brand verificato.

## Conflitti osservati

- Android interno localizza il nome operativo come `Controllo Merci`, `Merchandise
  Control`, `Control de Mercancía` e `货物管理`.
- iOS usa `iOSMerchandiseControl` come target/product tecnico e non contiene un display
  brand esplicito.
- Admin usa `MerchandiseControl Admin Web`, `Admin Console` e il monogramma tecnico `MC`;
  `shop_name` è dinamico e non ha un valore business versionato.
- POS usa `Win7POS` e visualizza uno shop name runtime; il fallback tecnico non è fonte
  di brand.
- Palette esterne viola, slate/emerald e colori di sistema non sono coerenti né
  approvati come brand cliente.

## Decisione di Planning

Non selezionare arbitrariamente nessuno dei nomi o asset sopra. Il client conserva il
technical display name come fallback centralizzato, espone lo stato provisional e rinvia
public brand, legal name, logo, icon e marketing visual a TASK-038.
