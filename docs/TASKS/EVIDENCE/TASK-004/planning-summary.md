# Planning summary — TASK-004

## Obiettivo

Definire e implementare un contratto compile-time minimo per development, staging e
production, con development offline per costruzione, staging esplicito e production
fail-closed.

## Confine approvato

- cinque input e nessun altro flag;
- callback client unica ed esatta;
- configurazione e bootstrap locale soltanto;
- esempi versionati e file staging locale ignorato;
- diagnostica sanitizzata;
- test, build e smoke development dual-platform;
- nessun networking di readiness, OAuth, deep link nativo o write remoto.

## Sequenza

1. transizione esplicita `PLANNING -> EXECUTION`;
2. implementazione e gate;
3. handoff a review indipendente;
4. eventuale Fix e re-review;
5. closeout e CI finale;
6. PR batch TASK-003/TASK-004 e merge soltanto a gate verdi.

## Stato Planning

- **Handoff**: `CODEX_PLAN_READY_AWAITING_USER_AUTHORIZATION`
- **Autorizzazione condizionata**: presente nel prompt end-to-end
- **Gate Execution**: `NOT_RUN`
- **Blocker**: nessuno
