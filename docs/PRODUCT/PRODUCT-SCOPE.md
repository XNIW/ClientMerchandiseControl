# Product scope

ClientMerchandiseControl è l'app clienti dell'ecosistema Merchandise Control.

## Obiettivo

Consentire ai clienti di consultare l'offerta pubblica di un negozio e, nei task futuri,
gestire preferiti, carrello, prenotazioni, ritiro/consegna, ordini e notifiche.

## Principi

- Catalogo e prezzi pubblici sono una proiezione Storefront controllata.
- L'Admin Console decide cosa pubblicare e con quali attributi commerciali.
- Stock operativo, costi, fornitori e metadata interni non sono dati cliente.
- Ordini sensibili e disponibilità sono validati server-side.
- Ordine cliente e vendita fiscale restano eventi distinti fino alla conferma.
- Una sola codebase Flutter serve Android e iOS.

TASK-001 crea esclusivamente la fondazione compilabile e non collega dati reali.
