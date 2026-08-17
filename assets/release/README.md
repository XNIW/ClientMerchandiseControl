# Release artwork provenance

## Launcher icon master

- committed source: `assets/release/app-icon-master.png`;
- size: 1024×1024, opaque PNG;
- SHA-256 at creation:
  `726cd88e7b94c51ffdc2cd9e4bdef25e74b13868aef365bd3326cfbdaa96be48`;
- status: neutral release-candidate artwork, pending public-brand owner approval;
- generated source retained outside Git by Codex at
  `/Users/minxiang/.codex/generated_images/01a00bdd-eef6-7743-99b5-c056996febbf/exec-0df037cb-72c6-4218-92d6-924ba4366a18.png`.

Prompt:

> Use case: logo-brand. Asset type: 1024x1024 mobile app launcher icon master
> for Android and iOS. Primary request: create an original neutral storefront
> commerce app icon, with a simple shopping bag silhouette whose handle and
> front shape subtly suggest a trustworthy check mark. Style/medium: flat
> geometric 2D icon, vector-friendly edges, premium but restrained, highly
> legible at 48 px. Composition/framing: one centered symbol, balanced negative
> space, generous adaptive-icon safe margin, full-bleed square canvas. Color
> palette: solid deep teal background inspired by #245C55; warm white and very
> pale mint symbol, minimal tonal variation. Constraints: completely opaque
> square background; no transparency; no text; no letters or initials; no
> currency symbols; no map pin; no gradients that reduce small-size clarity; no
> mockup, border, rounded-square mask, shadow outside the symbol, watermark,
> trademark, or existing brand resemblance. Avoid: Flutter logo, Google/Apple
> imagery, photorealism, shopping cart clichés, fine detail.

`google-play-icon-512.png`, le icone legacy Android e l'AppIcon set iOS sono
resize deterministici del master. Android adaptive/monochrome e
`LaunchMark.svg` usano una variante vettoriale semplificata per rispettare safe
zone, themed icons e launch-screen compositing.

Un tentativo imagegen di creare un launch mark trasparente è stato rifiutato e non
versionato perché il risultato incorporava un checkerboard opaco. Nessun asset
scartato è nel repository.
