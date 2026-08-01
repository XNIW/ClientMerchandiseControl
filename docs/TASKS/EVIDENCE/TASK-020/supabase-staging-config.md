# Supabase staging config — TASK-020

## Mutazione Auth staging verificata

| Controllo | Esito | Evidence sanitizzata |
|---|---|---|
| Discovery progetti | PASS | un solo progetto canonico non-production |
| Project ref | PASS | mascherato come `jpgo…yvm` |
| Stato | PASS | `ACTIVE_HEALTHY` |
| Config locale | PASS | cinque chiavi esatte; file ignorato e non tracciato |
| Callback locale | PASS | URI canonico esatto |
| Site URL before/after | PASS | invariato; valore reale non persistito |
| Redirect allow-list before | PASS | 16 URL; callback mobile esatta assente |
| Append callback | PASS | aggiunta una sola callback canonica dal Dashboard autenticato |
| Redirect allow-list after | PASS | 17 URL; callback esatta presente e le 16 precedenti preservate |
| Persistenza dopo reload | PASS | callback ancora presente dopo reload e `networkidle` |
| Provider Google | PASS | Dashboard corrente: `Google Enabled` |
| Configurazione production | PASS | zero navigazioni o mutazioni production |
| Kill switch post-smoke | PASS | riportato a `GOOGLE_AUTH_ENABLED=false` nel file locale ignorato |

## Evidence operativa sanitizzata

La sessione Dashboard sbloccata dall'utente è stata usata per un solo write Auth staging.
Il confronto prima/dopo ha verificato cardinalità `16 -> 17`, presenza dell'URI esatto,
uguaglianza dell'insieme dei 16 redirect precedenti e Site URL invariato. Il reload ha
confermato la persistenza. I log Auth mostrano il reload della configurazione alle
`2026-08-01T18:25:15Z`; nessun payload grezzo è versionato.

Nessun progetto, provider, secret, wildcard, redirect preesistente o configurazione
production è stato creato o modificato. Il kill switch è stato `true` soltanto nel file
staging locale ignorato durante gli smoke ed è stato riportato a `false` subito dopo.
Il piano FREE mostra un rischio quota egress, non un errore corrente; nessun upgrade,
billing o accordo è stato accettato.

Questa evidence non contiene URL, key, client ID/secret, token, callback con query,
account o dati personali.

Matrice CA/T e comandi canonici:
`commands-and-results.md`, CMD-P08/P10/P11/P12, CA-11/12/13/30/31/32 e
T-04/32/33/34.
