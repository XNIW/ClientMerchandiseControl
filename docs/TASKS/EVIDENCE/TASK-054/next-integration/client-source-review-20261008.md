# TASK-054 — Review indipendente del sorgente Client, 2026-10-08

Esito **APPROVED**, limitato a **SOURCE_CODE_ONLY**, sul commit
`edfec536363e4c45a13a5efc2c6e2020408f45a3`, rispetto alla base
`39624143955f0329b3ac85e27a51d722a6884ad8`. Reviewer distinto dagli autori,
implementazione read-only e verifiche in copia isolata. Nessuna approvazione
integrata, transizione a DONE o autorizzazione di merge è implicita.

La [ricevuta JSON](client-source-review-20261008.json) conserva comandi, exit code,
hash delle sorgenti, test e log. I 24 file applicativi modificati nel perimetro
corrispondono byte per byte al commit. Log completi e copie locali restano fuori Git.

| Verifica autonoma | Revisione | Esito |
| --- | --- | --- |
| PoC Auth A→B→A durante create, prima del fix | `eab76f7` | FAIL, 1 test, exit 1 |
| ACK, opening, cleanup, coordinate, flush, dialoghi, retry, riordino, assistenza, inbox | `eab76f7` | PASS, 49 test, exit 0 |
| Re-review del fix Auth: PoC indipendenti, dialoghi realAuth, controller, retry flush | `edfec53` | PASS, 36 test, exit 0 |

Il PoC originario ora restituisce ACK nullo e non pubblica `addressSaved` dopo la
transizione A→B→A. Il controller conserva l'intent, torna READY senza busy residuo e
una nuova Verify riconcilia il canonico con una sola create. Il rinnovo della stessa
identità continua invece a restituire correttamente l'ACK. Il fix osserva la sorgente
Auth, invalida subito la generazione e attende l'operazione precedente prima del
caricamento per l'owner finale.

Sono chiusi i finding su ACK malformato, bozza visibile dopo cambio scope, cleanup
prima del mount, coordinate nulle sostituite da initial, export/conferme private,
terzo retry sulla stessa route (`NI054-32`), scope di riordino/assistenza (`R20/R21`)
e risposta in-flight dopo ABA. Non restano finding di sorgente aperti nel perimetro.

Il journal preserva la stessa identità dopo esito incerto. Storage e flush falliti
impediscono RPC, anche al retry. La chiave di lookup non espone l'owner raw; il payload
rimane cifrato. Il controllo del bridge e delle API native è statico e non dimostra
la persistenza dopo un kill reale.

L'inbox mantiene cinque configurazioni e cinque build di riga in ciascuno dei cinque
campioni sia con 25 sia con 500 notifiche; le richieste sono rispettivamente 1 e 20.
La prova misura lavoro widget, non latenza o frame su telefono. Le destinazioni inbox
sono stub; i test account, riordino e assistenza usano App/router/AuthController reali
con repository remoti sintetici. È presente un warning debug Drift nelle fixture
account per istanze ripetute con container distinti, senza failure o dati reali.

I 49 PASS appartengono alla revisione precedente: non sono dichiarati come nuovo run
integrale sul fix finale. La re-review di 36 test copre il controller modificato e i
percorsi impattati. I PASS del writer non sono stati usati come sostituto di queste
esecuzioni indipendenti.

| Lane distinta | Stato in questa review | Motivo |
| --- | --- | --- |
| Suite globale obbligatoria locale | NOT_RUN | Esecuzione e ricevuta separate del root |
| CI associata al candidato finale | NOT_RUN | Job, step e annotation non verificati qui |
| Android/iOS nativi e kill/restart | NOT_RUN | Nessun run autonomo su device o emulatore |
| TEST condiviso autenticato | NOT_RUN | Fixture e auth sintetica non provano login/RPC live |
| Accettazione integrata | NOT_RUN | Richiede decisione del root sui gate obbligatori |

Nessun processo di verifica è rimasto attivo. I due file di review sono le sole
scritture del reviewer nel repository; implementazione e governance non sono state
modificate.

## Associazione finale — bb53892, 2026-10-08

Esito **APPROVED — SOURCE_CODE_ONLY** sul successivo commit
`bb53892393710d3ed6d2574053fe1206561b87f0`. Il delta rispetto a `edfec536`
contiene esattamente tre file, 11 aggiunte e 9 rimozioni: quattro valori del
fallback tecnico `zh`, i relativi getter e l'attesa di sei job nel test CI.
I quattro valori ora coincidono con lo spagnolo. ARB `zh_Hans` e intera classe
cinese semplificata generata sono byte-identici; il loop di verifica checkout
per tutti i job resta invariato.

Verifica autonoma in nuova copia Git esatta:

```text
flutter test --no-pub --concurrency=1 test/l10n/app_localizations_contract_test.dart test/governance/ci_performance_gate_test.dart
```

**PASS 9, exit 0**: sei contratti di localizzazione e tre controlli CI. Hash delle
tre sorgenti e del log nella proprietà `final_association` del JSON. Nessun
finding residuo nel delta. Lo slot è stato rilasciato e non restano processi attivi.

I 36 PASS restano associati a `edfec536`, i 49 PASS a `eab76f7`; i 99 del writer e
UI75 sono evidence separate. Nessuno di questi risultati è presentato come nuovo
run sul commit finale. Suite globale, CI esatta, Android/iOS nativi e TEST
autenticato sono ancora `NOT_RUN` da questo reviewer e rimangono gate distinti
coordinati dal root.

La review documentale read-only ha chiuso le incongruenze rilevate: capsule con
esiti finali duplicati, riga NI054-33 fuori tabella e riferimenti non qualificati
al vecchio contratto55/history147. Gli entrypoint correnti distinguono il nuovo
manifest57, la migration v3 ancora da applicare, recovery scoped PASS e integrità
preesistente FAIL. Non è stata anticipata alcuna approvazione integrata.
