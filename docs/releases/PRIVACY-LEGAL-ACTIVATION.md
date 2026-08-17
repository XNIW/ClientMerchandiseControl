# Privacy, legal and support activation checklist

Nessun campo seguente è stato inventato. Tutti i valori `NEEDS_OWNER_VALUE` bloccano
la submission o activation production indicata, ma non il release-candidate tecnico.

| Owner | Campo/azione esatta | Stato | Blocca RC | Blocca production/store |
|---|---|---|---|---|
| Product/brand owner | approvare public name, store name, icon e feature graphic | NEEDS_OWNER_VALUE | no | sì |
| Legal owner | legal entity, legal address, copyright e trader/DSA status | NEEDS_OWNER_VALUE | no | sì |
| Privacy owner/controller | controller identity, contact, lawful basis, retention e deletion wording | NEEDS_OWNER_VALUE | no | sì |
| Privacy/web owner | pubblicare privacy policy HTTPS e fornire URL stabile | NEEDS_OWNER_VALUE | no | sì |
| Support owner | support URL con contact info reale, email e canale escalation | NEEDS_OWNER_VALUE | no | sì |
| Legal/product owner | termini commerciali, rimborsi, garanzie e policy fulfillment | NEEDS_OWNER_VALUE | no | sì se applicabili |
| Identity owner | pubblicare external account-deletion URL e verificare end-to-end il workflow | NEEDS_OWNER_VALUE | no | sì |
| Store owner | Apple review contact, demo account/procedura e notes finali | NEEDS_OWNER_VALUE | no | sì iOS |
| Store owner | Google category, tags, content rating, target audience e app access | NEEDS_OWNER_VALUE | no | sì Android |
| Privacy owner | approvare App Privacy e Data safety contro provider attivi | NEEDS_OWNER_VALUE | no | sì |
| Maps/billing owner | approvare billing, quota, key restrictions e legal attribution | NEEDS_OWNER_VALUE | no | sì per Maps live |

## Permission rationale

- Internet: necessaria per catalogo, auth, checkout, ordini e tracking remoti.
- Location: non richiesta dal client. La posizione visualizzata appartiene al corriere e
  arriva owner-scoped dal backend; aggiungere permission sarebbe una sovra-dichiarazione.
- Notifications: non richiesta finché APNs/FCM resta unconfigured. Quando si abilita il
  provider, il prompt deve essere contestuale, localizzato e preceduto dalla disclosure
  approvata.
- Maps API key: è configurazione native, non una permission utente; se assente il
  comportamento resta status-only.

## Account deletion activation

1. pubblicare una pagina HTTPS owner-controlled che spieghi come richiedere la
   cancellazione senza reinstallare l'app;
2. collegare quella pagina nelle store listing e nella privacy policy;
3. provare con account sintetico richiesta, autenticazione, status, completamento,
   retention eccezionale approvata e revoca device/sessione;
4. conservare evidence sanitizzata, mai dati dell'utente;
5. non dichiarare cancellazione immediata se il processo resta una richiesta soggetta
   a verifica.
