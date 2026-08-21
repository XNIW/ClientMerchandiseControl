# TASK-040 Fix 42 — blocker di isolamento cleanup

## Esito

`BLOCKED`: il contratto corrente include un processo repository-controlled non
cooperativo con lo stesso UID del validator. Le API filesystem macOS/POSIX
unprivileged disponibili al job non possono rendere atomici insieme quota,
stabilita terminale del namespace e distruzione identity-bound.

Non e stata introdotta un'altra sequenza di re-check temporali: sposterebbe
soltanto la finestra TOCTOU gia riprodotta nella re-review Fix 41.

## Evidenza del blocker

- `flock` e advisory e non vincola un writer non cooperativo;
- directory mode `0700`, nomi casuali e ACL possedute dallo stesso UID non
  impediscono rename, write, chmod o creazione da quel writer;
- macOS non espone in questo confine una directory anonima equivalente a
  `O_TMPFILE`, una rimozione fd-bound equivalente ad `AT_EMPTY_PATH` o lock
  filesystem obbligatori utilizzabili dal validator;
- un numero finito di scansioni/count non garantisce una proprieta dopo
  l'ultimo controllo;
- `unlink` o `rmdir` su un nome mutabile non possono essere legati all'inode
  descriptor-bound verificato.

I probe Fix 41 hanno quindi ottenuto, sullo SHA esatto revisionato:

- cleanup riuscito con retained file sostituito e payload nonzero;
- cleanup riuscito con child nonzero aggiunto allo stesso inode directory;
- record valido con due entry reali e cap configurato a uno;
- cancellazione di una directory-vittima vuota sostituita al confine
  `rmdir`.

Hardlink dentro `ftruncate`, backup bounded, FIFO e oracle `LOCK_EX` sono
invece chiusi e non appartengono al blocker residuo.

## Confine richiesto

Il Fix 42 diventa implementabile soltanto con almeno uno dei seguenti confini:

1. supervisor con UID distinto che possiede un pool fisso di slot e termina o
   attende tutti i processi repository-controlled prima del garbage collector;
2. sandbox o ACL realmente enforceable che renda pool e quarantine non
   modificabili dal worker;
3. runner o VM effimera distrutta integralmente dopo il job, mantenendo il GC
   in-job `NOT_RUN`;
4. decisione esplicita del `USER_APPROVER` che restringa il threat model ai
   soli writer cooperativi sotto `LOCK_EX`.

Un process group cooperativo, un altro `wait` o un lock nello stesso UID non
costituiscono il confine richiesto.

## Oracle obbligatori dopo lo sblocco

- pool fisso di `N` slot identity-bound: `N+1` fallisce prima di creare una
  root e nessun cap deriva da count del namespace mutabile;
- swap/delete/recreate di uno slot non pubblica una capability verso un inode
  sostituito;
- quarantine dell'intera root con singolo rename esclusivo e identity check;
- stato terminale `QUARANTINED_PENDING_TEARDOWN`, senza claim payload-zero;
- zero `ftruncate`, `unlink`, `rmdir` o delete ricorsivi nel worker durante la
  fase untrusted;
- writer detached vivo impedisce il GC; dopo teardown attestato il supervisor
  elimina soltanto gli slot identity-bound;
- crash recovery, teardown idempotente e zero slot occupati dopo GC trusted.

## Boundary invariati

- candidate reviewer: `686/207`, `VALID/UNSIGNED`;
- fixture iOS reviewer: 86/86 `PASS` in 739 s;
- upload-ready: exit 1 esatto
  `TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE`;
- Apple Distribution, provisioning, App Store Connect, TestFlight, physical
  iOS e production: `NOT_RUN` o `BLOCKED` come gia documentato;
- nessun signing, upload, push o mutazione production eseguiti.
