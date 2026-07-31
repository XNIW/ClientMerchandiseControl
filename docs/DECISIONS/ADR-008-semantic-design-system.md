# ADR-008 — Design system semantico e Material 3

- Stato: ACCETTATA
- Data: 2026-07-30
- Task: TASK-002

## Contesto

La shell Material 3 funziona ma contiene misure locali e non dispone di colori semantici
Storefront light/dark. Una libreria ampia o nuove dipendenze sarebbero speculative.

## Decisione

- Mantenere `AppTheme` come unico composition root.
- Centralizzare spacing, radii, size, breakpoint e duration in token piccoli e tipizzati.
- Usare `ColorScheme.fromSeed` e una sola `ThemeExtension`,
  `StorefrontSemanticColors`, per i significati non coperti da Material.
- Usare font di sistema, target minimo 48 e rispetto della preferenza motion.
- Implementare soltanto componenti già consumati: pagina responsive, placeholder e
  status banner.
- Vietare raw color semantici e scale di layout parallele nelle feature.

## Conseguenze

Light e dark mode condividono la stessa tassonomia; il brand futuro può sostituire il
tema senza riscrivere le feature. I test coprono invarianti, contrasto, `copyWith`,
`lerp`, Semantics e layout. TASK-012 estenderà il sistema insieme alla shell
guest/data-safe e alla presentazione degli stati readiness.
