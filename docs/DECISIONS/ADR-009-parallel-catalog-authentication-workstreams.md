# ADR-009 — Parallel catalog and authentication workstreams

- Stato: ACCETTATA
- Data: 2026-07-30
- Task: TASK-003

## Contesto

La roadmap collegava TASK-011 sia al contratto ambienti sia allo schema e al query
contract del catalogo. Di conseguenza anche TASK-012 e TASK-020 ereditavano il
completamento di pubblicazione, immagini e altre capability commerciali non necessarie
per inizializzare Supabase staging, esporre uno stato di backend/auth readiness o gestire
il lifecycle della sessione cliente.

Questa catena confonde due dipendenze distinte. Il catalogo richiede schema Storefront,
proiezioni, control plane e query pubbliche; autenticazione e sessione richiedono invece
il contratto ambienti, una connessione staging fail-closed e la shell cliente. L'Auth
gestita da Supabase non dipende dal catalogo reale, dai prezzi o dall'Admin Console.

## Decisione

TASK-003 e TASK-004 restano la foundation comune. Da TASK-004 si separano due workstream:

- catalogo: TASK-005 → TASK-006 → TASK-007 → {TASK-008, TASK-009} → TASK-010,
  quindi i nodi TASK-013–TASK-019 secondo le rispettive dipendenze;
- autenticazione: TASK-011 → TASK-012 → TASK-020 → TASK-021 → TASK-022.

La tabella delle dipendenze applica tre modifiche circoscritte:

- TASK-010 aggiunge TASK-008 e conserva TASK-005, TASK-006 e TASK-009;
- TASK-011 dipende soltanto da TASK-004;
- TASK-020 rimuove TASK-005 e conserva TASK-004, TASK-011 e TASK-012.

TASK-011 verifica configurazione, connessione e backend/auth readiness. Non dichiara il
catalogo pronto e non introduce query verso dati commerciali. TASK-020 possiede OAuth,
deep link, session lifecycle e logout; profilo e dati cliente custom restano di TASK-021.
TASK-012 costruisce la shell guest/data-safe, gli stati readiness e la baseline
accessibile: non introduce catalogo reale, query commerciali o UI Storefront
data-backed, che restano di TASK-013/TASK-014 dopo TASK-010.

### Edge normativi sincronizzati con il Master Plan

<!-- CMC-WORKSTREAM-DEPENDENCIES:BEGIN -->
| Task | Dipendenze dirette |
|---|---|
| TASK-005 | TASK-003, TASK-004 |
| TASK-006 | TASK-005 |
| TASK-007 | TASK-005, TASK-006 |
| TASK-008 | TASK-005, TASK-006, TASK-007 |
| TASK-009 | TASK-005, TASK-007 |
| TASK-010 | TASK-005, TASK-006, TASK-008, TASK-009 |
| TASK-011 | TASK-004 |
| TASK-012 | TASK-002, TASK-011 |
| TASK-020 | TASK-004, TASK-011, TASK-012 |
| TASK-021 | TASK-020 |
| TASK-022 | TASK-020, TASK-021 |
<!-- CMC-WORKSTREAM-DEPENDENCIES:END -->

Questa tabella replica le dipendenze dirette normative del Master Plan per i due
workstream. Qualunque variazione richiede un emendamento esplicito in entrambe le fonti
e il validator architetturale deve fallire finché non sono nuovamente identiche.

Il parallelismo riguarda il grafo delle dipendenze. Non autorizza più task `ACTIVE`, più
writer o execution concorrenti nello stesso repository. TASK-005–TASK-010 restano
obbligatori per il workstream catalogo e non vengono eliminati, rinumerati, attivati o
modificati nello scope.

## Conseguenze

- La foundation auth può avanzare dopo TASK-004 senza attendere catalogo, prezzi,
  immagini o Admin Console.
- TASK-010 attende anche il contratto di prezzi e promozioni di TASK-008.
- TASK-013 e TASK-014 restano punti di convergenza: richiedono query catalogo,
  connessione e shell prima di introdurre UI data-backed.
- Le capability commerciali e i relativi confini server-side restano nei task catalogo
  esistenti.
- Il vincolo di un solo task `ACTIVE` continua a governare ogni transizione operativa.

## Alternative considerate

- Mantenere la catena TASK-005–TASK-010 → TASK-011: scartato perché rende
  l'autenticazione dipendente da capability commerciali non necessarie.
- Avviare TASK-011 prima di TASK-004: scartato perché configurazione, callback e
  separazione development/staging/production devono fallire in modo chiuso.
- Fondere TASK-011, TASK-012 e TASK-020: scartato perché mescola connessione, shell e
  session lifecycle e riduce la verificabilità degli handoff.
- Rinumerare o saltare TASK-005–TASK-010: scartato perché altera storia e scope del
  workstream catalogo.
