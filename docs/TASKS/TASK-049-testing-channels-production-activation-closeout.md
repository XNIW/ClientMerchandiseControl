# TASK-049 — Testing channels and production activation closeout

## Stato

- **Task ID**: TASK-049
- **Titolo**: Testing channels and production activation closeout
- **Stato**: DONE
- **Fase**: REVIEW
- **Release train**: MOBILE_STOREFRONT_PRODUCT_CONTROL
- **Responsabile**: USER_APPROVER
- **Data creazione**: 2026-08-21
- **Ultimo aggiornamento**: 2026-08-21
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-049/`
- **Handoff**: USER_APPROVED_DONE

## Scope

- Verificare signing e accessi prima di Android Internal/iOS TestFlight.
- Eseguire device smoke solo se un device fisico è realmente online.
- Eseguire technical/activation/operations preflight senza inventare attestazioni.
- Applicare migration production soltanto con tutti i gate esterni contemporaneamente
  verificati; non pubblicare su store production.

## Risultato

- Android Internal: `EXTERNAL_CREDENTIAL_REQUIRED`; nessun keystore release o accesso
  Play Console disponibile, nessun upload.
- iOS TestFlight: `EXTERNAL_CREDENTIAL_REQUIRED`; soltanto Apple Development
  disponibile, senza Distribution, provisioning o App Store Connect, nessun upload.
- Physical: `PENDING_DEVICE`; nessun Android collegato e gli iPhone rilevati erano
  offline. Simulator iOS Release install/launch `PASS`.
- Production technical: `PASS`; operations prelaunch: `PASS`; activation:
  `MISSING` soltanto per requisiti/attestazioni esterni reali.
- Production backend: `PENDING_EXTERNAL_REQUIREMENT`; progetto production, backup,
  restore, RLS e grants production non attestati, quindi nessuna migration applicata.
- Public store release: `NOT_RUN_BY_DESIGN`.
- Verdict: `MOBILE_STOREFRONT_PRODUCT_CONTROL_COMPLETE / TEST_CHANNELS_PARTIALLY_EXTERNAL / PRODUCTION_BACKEND_PENDING_EXTERNAL_REQUIREMENT`.
