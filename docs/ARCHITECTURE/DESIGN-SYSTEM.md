# Design system foundation

## Obiettivo

Fornire una base semantica minima, accessibile e sostituibile che la shell esistente usa
davvero. Non è una libreria di componenti completa e non anticipa le UI data-backed.

## Strati

1. `tokens/`: valori primitivi di spacing, radii, size, breakpoint e duration.
2. `theme/`: `ColorScheme`, `TextTheme` di sistema e colori Storefront semantici.
3. `widgets/`: composizioni foundation usate dalla shell e dalle feature cliente.
4. `AppTheme`: unico composition root light/dark.

Le feature consumano token, `Theme.of(context).colorScheme` e
`StorefrontSemanticColors`; non introducono raw color o scale locali.

## Token

- spacing su griglia 4 px, inclusi i valori necessari a layout correnti;
- radii per control, card e pill;
- target minimo 48, icon/avatar size, altezza app bar e larghezza contenuto massima
  960;
- breakpoint ordinati con layout wide da 720;
- motion short/medium/long e curve standard/enfatizzata, con durata ridotta a zero
  quando il sistema disabilita le animazioni.

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

| Contenuto | Ruolo Material previsto |
|---|---|
| Display/editoriale raro | `displaySmall` |
| Heading pagina o sezione | `headlineSmall` |
| Titolo elemento | `titleLarge` / `titleMedium` |
| Testo principale | `bodyLarge` |
| Label e CTA | `labelLarge` |
| Prezzo principale futuro | `headlineSmall` + semantic color `price` |
| Prezzo originale futuro | `bodyMedium` + `originalPrice` e semantica testuale |
| Badge futuro | `labelMedium` |
| Supporto/metadato | `bodySmall` |

I ruoli prezzo e badge sono contratti per i task commerciali futuri, non componenti o
dati introdotti da TASK-002.

## Componenti foundation

- `StorefrontPage`: scroll verticale, padding responsive, larghezza piena entro il
  max-width e centering.
- `StorefrontSection`: heading di sezione semantico con contenuto esplicito.
- `StorefrontEmptyState`: stato vuoto accessibile senza azioni o dati impliciti.
- `StorefrontSearchLauncher`: accesso semantico alla ricerca con target minimo e
  callback reale.
- `StorefrontStatusBanner`: stato inline accessibile e live region; l'azione appare
  soltanto con callback reale e diventa compatta nei viewport con altezza o testo
  critici.

Non vengono creati componenti senza consumer. `FeaturePlaceholder` è stato rimosso
quando le quattro feature hanno acquisito una responsabilità concreta.

## Invarianti

- Material 3, light/dark e `ThemeMode.system`;
- quattro route e `StatefulShellRoute.indexedStack` invariati;
- `SafeArea`, back verso Home e persistenza tab invariati;
- app bar e contenuto raggiungibili anche con brand e localizzazioni lunghi;
- zero nuove dipendenze;
- nessun colore semantico raw o metrica di layout nelle feature;
- target 48×48, text scale 200% e motion preference rispettati.
