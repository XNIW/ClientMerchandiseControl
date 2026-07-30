# Design system foundation

## Obiettivo

Fornire una base semantica minima, accessibile e sostituibile che la shell esistente usa
davvero. Non è una libreria di componenti completa e non anticipa le UI data-backed.

## Strati

1. `tokens/`: valori primitivi di spacing, radii, size, breakpoint e duration.
2. `theme/`: `ColorScheme`, `TextTheme` di sistema e colori Storefront semantici.
3. `widgets/`: composizioni foundation usate dalla shell e dai placeholder.
4. `AppTheme`: unico composition root light/dark.

Le feature consumano token, `Theme.of(context).colorScheme` e
`StorefrontSemanticColors`; non introducono raw color o scale locali.

## Token

- spacing su griglia 4 px, inclusi i valori necessari a layout correnti;
- radii per control, card e pill;
- target minimo 48, icon size e larghezza contenuto massima 960;
- breakpoint ordinati con layout wide da 720;
- motion short/medium/long, ridotta a zero quando il sistema disabilita le animazioni.

I breakpoint descrivono lo spazio disponibile al widget, non il modello di device.

## Colori

Material `ColorScheme.fromSeed` usa il seed teal provvisorio `#245C55`. La
`StorefrontSemanticColors` aggiunge soltanto significati non coperti direttamente:

- information, success e warning con foreground/container;
- promotion con foreground/container;
- current/original price;
- availability positive/limited/unavailable.

Ogni coppia testo/sfondo deve mantenere contrasto verificabile in light e dark. Lo stato
deve avere anche testo, icona o semantica; il colore non è mai l'unico segnale.

## Tipografia

Il font è quello di sistema. I widget usano i ruoli Material (`headlineSmall`,
`bodyLarge`, `labelLarge` e altri quando necessari) e rispettano il text scaling. Non
vengono fissati font size nelle feature.

## Componenti foundation

- `StorefrontPage`: scroll verticale, padding responsive, centering e max width.
- `FeaturePlaceholder`: card reale della shell, heading semantico e icona decorativa.
- `StorefrontStatusBanner`: stato inline accessibile, live region e nessuna action finta.

Non vengono creati componenti senza consumer. TASK-012 potrà estendere la libreria
insieme alla shell prodotto.

## Invarianti

- Material 3, light/dark e `ThemeMode.system`;
- quattro route e `StatefulShellRoute.indexedStack` invariati;
- `SafeArea`, back verso Home e persistenza tab invariati;
- zero nuove dipendenze;
- nessun colore semantico raw o metrica di layout nelle feature;
- target 48×48, text scale 200% e motion preference rispettati.
