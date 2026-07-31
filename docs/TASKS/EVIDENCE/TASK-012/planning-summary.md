# Planning summary — TASK-012

## Autorità e baseline

- TASK-002 e TASK-011: `DONE`.
- Stato iniziale: repository pulito, branch milestone allineato a origin, nessun task
  `ACTIVE`.
- Autorità: prompt end-to-end `USER_APPROVER`, da applicare con transizioni distinte.
- Fonti lette: Master Plan, TASK-002, protocollo, codice/test/evidence pertinenti e
  specifica allegata TASK-012.

## Gap verificati

- Le quattro destinazioni e l'indexed stack esistono e sono testati.
- Tema, semantic colors, token, localizzazione e readiness hanno una baseline reale.
- Home, Catalogo, Carrello e Account sono ancora lo stesso placeholder generico.
- Mancano ricerca, categorie, sezioni future oneste, CTA, stati Catalogo specifici,
  Carrello vuoto e contratto Account guest/authenticated.
- I P3 TASK-002 su scroll-to-end/bounds e larghezza cosmetica sono ancora aperti e
  vengono assorbiti nei criteri TASK-012.
- Tre audit read-only indipendenti hanno confermato i confini UI, qualità e governance;
  la baseline mirata l10n/theme/shell/CLP è 50/50 test `PASS`.
- I gap principali sono reachability reale a 200%, SafeArea con inset, parità
  automatica degli ARB, Semantics dell'albero completo e full-width coerente entro il
  max-width.

## Confini

- Nessun dato commerciale reale o fittizio.
- Nessuna query o mutazione Supabase.
- Nessun OAuth, callback, deep link, token, secure storage o session lifecycle.
- Runtime guest; authenticated è soltanto uno stato presentazionale iniettabile.
- Nessuna dipendenza runtime, asset o font nuovi.
- Nessuna modifica a task futuri o repository esterni.

## Strategia

1. Composizioni feature-specifiche e pochi widget condivisi con responsabilità reale.
2. CTA Home/Carrello verso la branch Catalogo.
3. Stati Catalogo derivati dalla readiness TASK-011 senza rete aggiuntiva.
4. Port Account fail-closed e customer-safe: pulsante Google visibile ma disabilitato
   fino al callback TASK-020; avatar soltanto presentazionale e senza metadata/rete.
5. Copy completa es-CL/it/en/zh-Hans e policy fallback spagnola esplicita.
6. Test unit/widget per stati, fallback, temi, Semantics, target, 200% e viewports.
7. Integration guest e smoke reali dual-platform.
8. Review indipendente UI/a11y e architettura/security.

## Stato dei gate

| Gate | Esito | Motivo |
|---|---|---|
| Audit baseline | PASS | codice, test ed evidence letti; baseline mirata 50/50 |
| Governance Planning | PASS | un solo task attivato e handoff coerente |
| Implementazione | NOT_RUN | fase non ancora autorizzata nel repository |
| Test/build/smoke | NOT_RUN | dipendono dall'implementazione |
| Review/CI | NOT_RUN | dipendono dallo SHA tecnico |

## Handoff

`CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION`
