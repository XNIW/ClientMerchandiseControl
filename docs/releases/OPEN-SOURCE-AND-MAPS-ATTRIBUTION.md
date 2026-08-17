# Open-source licenses and Maps attribution

## Runtime disclosure

L'Account screen espone `Licenze open source` / `Open-source licenses` tramite il
`LicensePage` Flutter. Il registry include le notices fornite dall'SDK e dai package
linkati; va verificato nel binary release dopo ogni dependency update.

Inventario diretto corrente:

| Dependency | Version constraint/resolved family | License |
|---|---|---|
| app_links | ^7.2.1 | Apache-2.0 |
| crypto, http, intl, path, path_provider, shared_preferences, timezone | lockfile corrente | BSD-3-Clause |
| drift, drift_flutter, flutter_riverpod, sqlite3, supabase_flutter | lockfile corrente | MIT |
| flutter_secure_storage | ^10.3.1 | BSD-3-Clause |
| go_router | ^17.3.0 | BSD-3-Clause |
| google_maps_flutter | ^2.18.0 | BSD-3-Clause |
| share_plus | 13.2.1 | BSD-3-Clause |
| Flutter/Dart SDK components | Flutter 3.44.8 / Dart lock | BSD-3-Clause e notices SDK |

La UI di disclosure non sostituisce eventuali obblighi commerciali dei provider o la
review legale. Non sono stati trovati package diretti GPL/AGPL nel lock corrente.

## Google Maps

- la mappa usa il widget ufficiale Google Maps e deve lasciare sempre visibili logo,
  attribution e controlli richiesti dal provider;
- nessun overlay, crop o screenshot marketing deve rimuovere attribution;
- le key native non sono committate e devono essere limitate a package/bundle e
  certificati autorizzati;
- con key, billing, quota o adapter mancanti la UI fallisce chiusa su status-only;
- una release che aggiorna `google_maps_flutter` deve riesaminare license, privacy
  manifest, Maps Platform Terms e store privacy declarations;
- una leak response deve disabilitare il map switch, revocare/ruotare la key, verificare
  usage/quota e conservare solo incident evidence sanitizzata.

## Verification cadence

TASK-039/040 devono aprire il LicensePage nel release candidate, controllare il binary
per notices e confermare che la mappa non copra attribution. Ogni cambio dependency o
provider riapre questo audit bounded.

