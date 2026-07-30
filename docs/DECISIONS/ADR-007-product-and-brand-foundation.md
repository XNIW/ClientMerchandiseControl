# ADR-007 — Product e brand foundation provvisoria

- Stato: ACCETTATA
- Data: 2026-07-30
- Task: TASK-002

## Contesto

Il client necessita di una direzione di prodotto e di un nome centralizzato, ma l'audit
dei repository non ha trovato un public brand, legal entity, logo, palette o asset
marketing autorevoli. Adottare uno dei nomi operativi esterni inventerebbe una decisione
commerciale.

## Decisione

- Definire il prodotto come client pubblico Storefront per il mercato iniziale cileno e
  per un singolo negozio.
- Separare project name, package, technical display name, public brand, store display
  name e legal entity.
- Conservare `Client Merchandise Control` soltanto come technical display name e
  fallback provvisorio.
- Lasciare public brand, legal, tagline, logo e store asset non verificati.
- Usare font di sistema e seed teal corrente come foundation provvisoria.
- Rinviare identità e asset release definitivi a TASK-038.

## Conseguenze

La shell dispone di un nome coerente senza presentarlo come brand approvato. Una futura
decisione autorevole può sostituire brand e asset centralmente. Package, bundle
identifier e target non cambiano implicitamente.
