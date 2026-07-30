# Storefront data boundary

## Regola

Il client non interroga direttamente `inventory_products`, `inventory_product_prices` o
altre tabelle operative.

## Dati pubblicabili

Il futuro read model Storefront può esporre soltanto attributi approvati, ad esempio:

- nome e descrizione pubblici;
- immagine pubblica;
- prezzo cliente e sconto valido;
- disponibilità commerciale;
- opzioni ritiro, consegna o prenotazione;
- evidenza promozionale.

## Dati vietati

- costi di acquisto;
- fornitori e note interne;
- cronologia operativa;
- metadata di sincronizzazione;
- credenziali o identificatori privilegiati;
- stock grezzo non filtrato.

Admin Console controlla la pubblicazione. RLS, grant e validazione server-side devono
proteggere il confine anche contro client modificati. TASK-001 documenta il confine senza
creare schema o migrazioni.
