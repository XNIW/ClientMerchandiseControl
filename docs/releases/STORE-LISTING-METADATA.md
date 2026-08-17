# Store listing metadata — release candidate

I testi sono draft tecnici verificabili. Non costituiscono approvazione del brand o
dichiarazione legale. I campi marcati `NEEDS_OWNER_VALUE` bloccano la submission store,
non la costruzione del release candidate.

## Identità comune

| Campo | Valore/stato |
|---|---|
| technical display name | `Client Merchandise Control` |
| public/store name | `NEEDS_OWNER_VALUE: verified public brand and store display name` |
| Android applicationId | `com.xniw.clientmerchandisecontrol` |
| iOS bundle identifier | `com.xniw.clientmerchandisecontrol` |
| version name / short version | `0.1.0` |
| build / version code | `1` |
| release numbering policy | semantic `major.minor.patch`; monotonically increasing integer build per upload |
| primary locale | `es-CL` product copy; store locale `es-CL` |
| additional locales | `en`, `it`, `zh-Hans` |

## Google Play draft — es-CL

- App name, max 30: `NEEDS_OWNER_VALUE` (technical fallback:
  `Client Merchandise Control`, 26 caratteri).
- Short description, max 80:
  `Compra productos y sigue tus pedidos en tu tienda.`
- Full description, max 4.000:

  > Explora el catálogo publicado por tu tienda, consulta productos y administra tu
  > carrito. Antes de confirmar, la aplicación vuelve a validar precios,
  > disponibilidad y opciones de entrega o retiro.
  >
  > Cuando la tienda lo habilita, puedes iniciar sesión, guardar direcciones,
  > completar el checkout, revisar tus pedidos y recibir actualizaciones. El
  > seguimiento de entrega puede mostrar solo el estado, abrir el sitio de un
  > transportista externo o mostrar el recorrido del repartidor, según la
  > configuración de la tienda.
  >
  > Desde Cuenta puedes revisar las opciones de privacidad, solicitar la eliminación
  > de tu cuenta y consultar las licencias de software de código abierto.

- Category proposal: `Shopping`; final category `NEEDS_OWNER_VALUE`.
- Tags/contact/trader declaration: `NEEDS_OWNER_VALUE`.
- Feature graphic: 1024×500, JPEG o PNG 24-bit senza alpha; produzione
  `PENDING_BRAND_OWNER_APPROVAL`, non generata con claim/brand inventati.
- Store icon: `assets/release/google-play-icon-512.png`, 512×512, opaque; neutral
  release-candidate artwork pending public-brand approval.
- Internal testing release name: `0.1.0 (1) — Storefront RC`.
- Internal testing notes:
  `Validar acceso guest, catálogo, carrito, checkout staging sin compra real, pedidos,
  deep links y tracking status-only. No usar datos personales reales.`

## App Store / TestFlight draft — es-CL

- Name, max 30: `NEEDS_OWNER_VALUE` (technical fallback:
  `Client Merchandise Control`).
- Subtitle, max 30: `Tus compras y pedidos`.
- Description: usare la full description Google Play sopra.
- Keywords, max 100 bytes:
  `compras,catálogo,carrito,pedidos,entrega,tienda`
- Promotional text: vuoto; nessuna promozione verificata.
- Primary/secondary category: `NEEDS_OWNER_VALUE` (proposal tecnica: Shopping).
- Support URL: `NEEDS_OWNER_VALUE`.
- Marketing URL: optional, `NEEDS_OWNER_VALUE` se usata.
- Privacy policy URL: `NEEDS_OWNER_VALUE`.
- Copyright/legal entity: `NEEDS_OWNER_VALUE`.
- App Review contact: `NEEDS_OWNER_VALUE`.
- Demo account o procedura review per aree autenticate: `NEEDS_OWNER_VALUE`; non
  inserire credenziali nel repository.
- Review notes:
  `The guest storefront is available without sign-in. Authenticated staging review
  requires owner-supplied review credentials. Online payment, push notifications and
  live Maps are fail-closed unless the corresponding reviewed provider configuration
  is enabled. Testers must not place a real purchase.`
- TestFlight notes:
  `Exercise guest catalog, cart revalidation, staging checkout without a real charge,
  order history, account privacy controls, deep links and status-only delivery
  tracking. Report the route, environment and app version; do not include personal
  data, tokens or coordinates.`

## Screenshot matrix

Usare solo fixture sintetiche o staging sanitizzato. Nessun nome, indirizzo, codice
ordine, coordinate, URL tracking o account reale. Le immagini finali sono
`PENDING_SIGNED_RC_AND_SANITIZED_STAGING_FIXTURE`.

| Store/device | Portrait target | Landscape target | Set minimo |
|---|---:|---:|---|
| Google Play phone | 1080×1920 | 1920×1080 optional | Home, Catalogo, Prodotto, Carrello, Ordine/tracking |
| Google Play tablet 7/10 inch | 1600×2560 | 2560×1600 | gli stessi 5 flow, layout large-screen |
| App Store iPhone 6.9 inch | 1320×2868 | 2868×1320 optional | gli stessi 5 flow |
| App Store iPad 13 inch | 2064×2752 | 2752×2064 | gli stessi 5 flow, split/large layout |

Checklist capture: locale `es-CL`, clock/network deterministici, stato permission
coerente, map attribution visibile quando una mappa è presente, contrasto e text scale
1.0, nessun debug banner, nessun overlay marketing che simuli capability inattive.

## Fonti store

- Google Play listing e limiti testo:
  <https://support.google.com/googleplay/android-developer/answer/9859152?hl=en>
- Google Play preview assets:
  <https://support.google.com/googleplay/android-developer/answer/9866151?hl=en>
- Apple app information:
  <https://developer.apple.com/help/app-store-connect/reference/app-information/app-information>
- Apple platform version information:
  <https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/>
- Apple screenshot specifications:
  <https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/>

