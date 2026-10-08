L’account resta consultabile quando il journal indirizzi è temporaneamente illeggibile. La creazione resta sospesa e la UI offre un nuovo tentativo di lettura, senza richiedere cancellazione dei dati. Dopo il recupero viene riaperto lo stesso intento; le regressioni verificano il canonico già creato e nessuna seconda creazione. Profilo ed export non rimuovono la sospensione.

Una notifica con destinazione assistenza assente apre ora una spiegazione neutra e un’azione per consultare le altre richieste. Un errore transitorio nel caricamento del dettaglio offre un retry reale. Le fixture attraversano la seconda pagina della inbox, mark-read, destinazione assente, prosecuzione, errore e recupero.

| Delta | Commit | Review |
|---|---|---|
| Journal illeggibile e account consultabile | b820f826, base e7b194c | APPROVED SOURCE_CODE_ONLY, reviewer distinto, 69 test autonomi |
| Destinazione assistenza assente e retry | 26713a4294f3976236e8e83f983950b8f281c6fc, base b820f826 | APPROVED SOURCE_CODE_ONLY, reviewer distinto, 41 test autonomi e 3 PoC RED sulla baseline |

| Verifica writer | Esito | Limite |
|---|---|---|
| Tre regressioni journal prima del fix | FAIL, exit 1 | Riproduzione causale host |
| Account dopo il fix | PASS, 102 test, exit 0 | Host, sessione sintetica |
| Contratto l10n | PASS, 6 test, exit 0 | Quattro lingue e fallback tecnico zh uguale a es |
| Due regressioni assistenza prima del fix | FAIL, exit 1 | UUID assente e errore transitorio senza azione |
| After-sales, navigazione inbox e l10n | PASS, 30 test, exit 0 | Host |
| Matrice finale dei nuovi stati | PASS, 16 test, exit 0 | Quattro lingue, due temi, 320×568, testo 200%; nessuna PNG prodotta |
| Analisi dei due delta, format, localization e architettura | PASS, exit 0 | Gate mirati; gate globale unico affidato al coordinatore |

I log conservano anche due errori di preparazione: factory del test inizialmente inesistente e locator l10n errato. Sono stati corretti prima dei gate finali. La capsula JSON contiene comandi, exit code, hash dei log e SHA-256 dei 19 file del delta.

Le sole catture native aggiunte all’harness sono 24: otto journal, otto destinazione assistenza assente e otto retry assistenza. Il totale previsto del runner passa da 113 a 137; l’owner degli script aggiorna la cardinalità. Android/iOS del delta, CI finale, TalkBack/VoiceOver, autenticazione TEST, E2E integrati e profiling fisico sono NOT_RUN in questa lane e non sono dedotti dai test host. Nessun build nativo locale o dispositivo di N è stato usato.

Checkout, inbox, router e codec sono byte-identici al checkpoint in otto sorgenti attestate. I metodi payAtPickup/cashOnDelivery sono distinti dai messaggi di rete assente; nessuna correzione speculativa. Il codec continua a consentire product/category sullo schema privato e a fallire chiuso per order/notification; HTTPS sensibile non è un ingresso attualmente abilitato. Il rischio statico ABA del resolver dormiente non è un difetto runtime dimostrato e non è stato modificato.

Limite preesistente rilevato dal reviewer: la lista assistenza contiene al massimo 50 casi e non espone lookup/paginazione. Il nuovo testo dice “non disponibile”, senza inferire eliminazione o autorizzazione. Le due notifiche orfane reali e il relativo mark-read SQL restano evidenza della lane backend, separata dalle fixture UI.

Il branch codex/task054-journal-unreadable-ux è pulito al commit 26713a4. Nessun task, Master Plan, registro condiviso, script/CI o repository esterno è stato modificato dalla lane applicativa. Il coordinatore integra i due commit sul candidato composto, conserva le review e avvia una sola CI finale; nessun merge o DONE è dichiarato qui.
