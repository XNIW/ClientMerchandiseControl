# Release configuration matrix

Fonte machine-readable: `config/release_configuration_matrix.json`.

## Regole comuni

- nessun secret, token, certificato, DSN, key Maps o valore production è conservato in
  Git;
- `required` significa che l'ambiente non deve avviarsi o la capability non deve
  attivarsi quando la validazione fallisce;
- `optional` significa che l'assenza mantiene il fallback dichiarato, senza capability
  parzialmente attiva;
- `forbidden` significa che un valore presente è un errore di configurazione;
- i flag client non sono un confine di autorizzazione: publication, RLS e provider
  server-side restano autoritativi;
- `APP_ENV` seleziona development, staging o production. Un valore sconosciuto è
  rifiutato.

## Matrice sintetica

| Capability | Development | Staging | Production | Fallback production |
|---|---|---|---|---|
| Supabase URL/public key | forbidden | required | required | startup fail-closed |
| OAuth | forbidden | forbidden nell'attuale boundary | forbidden nell'attuale boundary | guest storefront |
| callback | forbidden | required | required | startup fail-closed |
| Maps | optional | optional | optional | tracking status-only |
| payment | optional | optional | optional | online payment disabled |
| notifications | optional | optional | optional | provider unconfigured, no token/prompt |
| analytics | optional | optional | optional | no-op adapter |
| crash reporting | optional | optional | optional | no-op adapter |
| tracking | optional | optional | optional | status-only |
| shop slug | forbidden | required | required | startup fail-closed |
| external carrier | optional | optional | optional | CTA absent |
| logging level | required/derived | required/derived | required/derived | no remote/debug logging |

## Injection e ownership

Le define runtime correnti sono `APP_ENV`, `SUPABASE_URL`,
`SUPABASE_PUBLISHABLE_KEY`, `AUTH_REDIRECT_URI`, `GOOGLE_AUTH_ENABLED`,
`STOREFRONT_SHOP_SLUG`, `DELIVERY_MAPS_ENABLED` e
`DELIVERY_MAPS_NATIVE_CONFIGURED`; production richiede inoltre
`RELEASE_CONFIG_SHA256`, digest non secret del file esterno fornito allo stesso build.
Android riceve la key Maps esclusivamente da
`ANDROID_GOOGLE_MAPS_API_KEY`/`local.properties`; iOS da una xcconfig non versionata che
sovrascrive il valore fail-closed `NOT_CONFIGURED`.

Payment, tracking mode, external carrier e relativi enable switch arrivano da dati
server-authoritative owner-scoped. Analytics, crash e push usano adapter no-op finché
un composition root revisionato non inietta un provider. La matrice non introduce
nuovi secret o bypass: descrive i prerequisiti che TASK-039/040/041 devono validare.

## Production activation gate

Prima di generare un binary production-like, il validator TASK-039/040 deve confermare:

1. valori required presenti nel secret store e valori forbidden assenti;
2. package/bundle e callback identici alle console provider;
3. capability optional disabilitate quando manca anche un solo prerequisito;
4. nessun `NOT_CONFIGURED`, localhost, fixture, service role o debug flag abilita una
   feature;
5. output diagnostico booleano/sanitizzato, mai il valore delle credenziali.
