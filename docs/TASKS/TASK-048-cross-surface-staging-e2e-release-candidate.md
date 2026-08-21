# TASK-048 — Cross-surface staging E2E and release candidate

## Stato

- **Task ID**: TASK-048
- **Titolo**: Cross-surface staging E2E and release candidate
- **File task**: `docs/TASKS/TASK-048-cross-surface-staging-e2e-release-candidate.md`
- **Stato**: DONE
- **Fase**: REVIEW
- **Release train**: MOBILE_STOREFRONT_PRODUCT_CONTROL
- **Responsabile**: USER_APPROVER
- **Data creazione**: 2026-08-21
- **Ultimo aggiornamento**: 2026-08-21
- **Ultimo agente**: Codex
- **Evidence directory**: `docs/TASKS/EVIDENCE/TASK-048/`
- **Handoff**: USER_APPROVED_DONE

## Scope

- Validare sul solo staging e con fixture sintetiche E2E-01…E2E-14.
- Confermare propagation e identità unica Admin/Android/iOS → Client.
- Eseguire una review cross-repo bounded e generare soltanto i release candidate
  Android/iOS operativi realmente impattati.
- Non modificare il Client Flutter se i compatibility test confermano il public
  projection corrente; nessuna migration production o store rollout pubblico.

## Gate

- Migration history, pgTAP/RLS e dataset sintetico staging verificati.
- E2E-01…14 con `PASS` o finding tecnico corretto prima del closeout.
- Candidate con version/build, commit e SHA-256 quando appropriato.
- Un solo task Client ACTIVE durante l'esecuzione; TASK-049 governa il closeout.

## Risultato

- Supabase staging `jpgoimipbothfgkokyvm`: migration history esatta, pgTAP/RLS
  `56/56 PASS`, nessuna migration production.
- Run integrata `32531575267`: E2E-01…E2E-14 `PASS`, dataset esclusivamente
  sintetico e cleanup `PASS`.
- Acceptance cross-repository: `APPROVED`, P0/P1/P2 zero; un P3 di sola
  attribuzione Android/iOS accettato come rischio residuo perché una correzione forte
  richiede attestation per-sessione fuori scope. Actor, sessione, shop e permessi
  restano server-verificati e nessuna autorizzazione dipende dalla source.
- Android RC staging `1.0 (1)` sul commit `d7c4953c`: debug APK e release APK/AAB
  generati; release non firmata, quindi nessun upload.
- iOS RC Simulator Release `1.0 (1)` sul commit `30d226d0`: build, install e launch
  `PASS`; archive/TestFlight non eseguiti senza Distribution/provisioning/ASC.
