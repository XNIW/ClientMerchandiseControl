# Sicurezza

## Client mobile

Il client può usare soltanto una Supabase publishable key. Non deve contenere service role,
secret key, token amministrativi, password, certificati o credenziali production.

La sicurezza dei dati dipende da RLS, grant minimi e validazione server-side. Il client non
è un confine di autorizzazione.

## Confine Storefront

I dati pubblici Storefront devono essere separati dai dati operativi interni. Il client non
deve leggere direttamente tabelle inventory interne né esporre costi di acquisto,
fornitori, cronologia operativa o metadata di sincronizzazione.

## Segnalazioni

Segnalare vulnerabilità privatamente ai maintainer del repository. Non aprire issue
pubbliche contenenti exploit, credenziali o dati personali.

## Report ed evidenze

Redigere output, screenshot e log. Non includere credenziali production o dati cliente.
Ogni sospetto secret va rimosso dalla history prima di pubblicare il branch.
