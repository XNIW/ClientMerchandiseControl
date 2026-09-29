# TASK-054 — Registro unico dei residui operativi

Mandato successivo del 2026-09-28; stato iniziale PR27 0990c80. Le prove storiche
sono in README/validation/backend-reconciliation; qui si registrano solo le azioni
successive. PASS richiede comando/output/exit e revisione identificata.

| Requisito | Evidenza iniziale | Causa | Azione | Dipendenze | Test | Risultato | Owner |
|---|---|---|---|---|---|---|---|
| Backend55 RPC | 32 presenti/23 assenti storico | due migration mancanti | metadata fresco, recovery, apply condizionato e ruoli | recovery accessibile, finestra senza writer | gate + pgTAP + staging sintetico | schema restore/inverse PASS; apply condiviso BLOCKED finestra/Storage cleanup | root/backend reviewer |
| Notifiche hold | collisione riprodotta dal reviewer su VALUES | indice nuovo perde identità hold | migration correttiva canonica e regressione | Admin isolato; conteggio collisioni remoto | due hold/same owner + permessi | PASS locale41/41 dopo fix; test41 FAIL prima | root |
| Typegen Admin | patch SHA123242ea, compilazione precedente parziale | null semantici non coperti | integra tipi mirati + test nullable | coordinamento TASK159 | tsc positivo/negativo + foundation | PASS tsc nullable mirato e tsc intero, exit0 | root |
| OAuth attivabile | hard refusal e binding assenti | config sentinel-only | config validata, callback native, gate e test | dominio/allow-list approvati per live | positivi/negativi, session race | PASS112 config/auth/address; live NOT_RUN | root; owner dominio per live |
| Provider indirizzi | tre adapter NotConfigured | implementazione mancante | adapter concreti con gate e fallback | configurazione provider approvata per live | transport e widget | PASS12 provider/editor mirati; native map live NOT_RUN | root |
| Lifecycle analoghi | account/order/search ipotesi precise | generation incompleta | riproduci e correggi delta minimo | nessuna esterna | Completer, A-B-A, dispose | PASS 23/23 mirati; tre FAIL prima | root |
| Editor indirizzo | pin vecchio dopo edit testo | metadata conservati | invalida geografia modificata | nessuna | widget sintetico | PASS nel gruppo12 provider/editor | root |
| Golden | 6/18 pixel anche baseline, tracking Linux return | raster e falso pass | baseline mirata dichiarata e confronto richiesto | runner riproducibile | ispezione diff + real compare | PASS2 confronti macOS27; CI macOS26 da eseguire | root/reviewer Client |
| iOS14 / Android smoke | Xcode27 incompatible; Gradle timeout storico | toolchain | ambiente/config supportata e smoke entrambi | toolchain/device disponibili | build e interazione separate | Android build+smoke PASS; iOS CI in attesa | root |
| Acceptance nuova | ID storici senza definizioni | provenance irrecuperabile | E2E-054-R con fonti e subflussi | review; staging/provider per live | matrice + assert reali |30 casi R01–R30 definiti; review pendente | root/reviewer |
| Gate/benchmark/release | CI0990 storica verde | nuovo candidato necessario | focused poi gate completi, review, merge normale | gate applicabili verdi | CI SHA, benchmark10, main ancestry | NOT_RUN | root/reviewer |
| Dispositivi/distribuzione | guest smoke simulatore soltanto | prerequisiti esterni | verifica riferimenti già approvati e azioni condizionate | firma/canale/device approvati | ricevuta/installazione/ambiente | NOT_RUN | root/owner |

Production: **NOT_ACTIVATED**. Nessun PASS locale equivale a staging/provider live.
