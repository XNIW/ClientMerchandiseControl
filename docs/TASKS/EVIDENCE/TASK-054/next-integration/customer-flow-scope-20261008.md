# TASK-054 — Isolamento riordino e assistenza, 8 ottobre 2026

Due difetti **P1** riprodotti e corretti dal writer; review indipendente ancora
`NOT_RUN`. Questa ricevuta riguarda verifiche host con fixture dichiarate.
I dettagli dei comandi, exit code e hash sono nella
[ricevuta JSON](customer-flow-scope-20261008.json).

| Finding / residuo | Requisito | Difetto osservato e correzione |
|---|---|---|
| C-OC-FLOW-01 / NI054-29 | R20; isolamento R03/R25 | Il modal riordino conserva la preview A dopo revoca, mostra la risposta apply A a B e sopravvive all’apertura A→B→A prima del paint. Monitor installato prima della preview, latch owner/shop, route propria rimossa e callback tardive scartate. |
| C-OC-FLOW-02 / NI054-30 | R21; isolamento R03/R25 | Il form assistenza conserva la bozza A dopo B e mostra righe A restituite dopo revoca. Scope del form invalidato, buffer e focus propri puliti, callback picker/file/upload e navigazione protette. |

## Prove e qualificazione

| Verifica | Risultato | Limite |
|---|---|---|
| Tre preparazioni harness | FAIL, exit1 ciascuna | Prima: tap fuori viewport e un falso positivo ABA. Seconda: pumpAndSettle bloccato dall’indicatore continuo sotto il modal. Terza: un tap Apply durante l’animazione. Non sono cinque failure prodotto valide per ogni run. |
| RED funzionale corretto | **5 FAIL, exit1** | Tre casi riordino e due assistenza; tutte le assertion riguardano contenuto A ancora visibile. Nessun tap mancato o timeout. |
| GREEN iniziale | **7 PASS, exit0** | Cinque regressioni e due controlli positivi sullo stesso owner. |
| Suite orders + after_sales | **65 PASS, exit0** | Prima dei guard `mounted` espliciti; non attribuita ai byte finali. |
| Analyze iniziale | FAIL, exit1 | Quattro lint `use_build_context_synchronously`: il getter di scope non dimostra `mounted` all’analizzatore. Nessuna regola disabilitata. |
| Analyze finale | **PASS, exit0**, zero issue | Cinque file finali, dopo guard `mounted` espliciti. |
| GREEN finale | **7 PASS, exit0** | Hash finali verificati; controlli positivi preservano la bozza/preview nello stesso account. |
| Diff check | **PASS, exit0** | Output vuoto. |

Comando RED funzionale e GREEN finale:

```sh
flutter test --no-pub --concurrency=1 --reporter expanded test/features/orders/customer_reorder_scope_test.dart test/features/after_sales/customer_after_sales_scope_test.dart
```

Suite mirata precedente ai guard espliciti:

```sh
flutter test --no-pub --concurrency=1 --reporter expanded test/features/orders test/features/after_sales
```

La sincronizzazione harness usa un primo frame e un avanzamento bounded di 350 ms
per completare l’animazione; non cambia i budget CI, non introduce skip e mantiene
le assertion di interazione. Il warning Drift delle prime fixture è stato rimosso
usando un database in-memory proprio. Log completi e copie source restano locali,
non versionati; i loro digest sono conservati nel JSON.

## Source e limiti

I cinque file finali comprendono due schermate, due test di scope e un supporto
condiviso che monta `AuthController`, `appRouter` e `ClientMerchandiseControlApp`
reali. I soli confini remoti usano repository sintetici. Gli eventi sessione sono
asincroni; non si forza la rivalutazione di identity tra A→B→A.

I due file produzione prima dei fix sono stati copiati e hashati. L’harness RED
è stato corretto dopo i tre errori iniziali; gli hash dei test finali comprendono
due controlli positivi successivi e non sono attribuiti retroattivamente al RED.
Nessuna modifica a router, controller, contratti, dipendenze o localizzazioni.

Review indipendente e suite globale del candidato finale restano a carico del
coordinatore. TEST autenticato, runtime Admin, device fisici, interazioni OS native,
provider e VoiceOver/TalkBack sono **NOT_RUN** in questa lane. R20/R21 non diventano
PASS live; R17 resta il caso tracking. Gli E2E-01…25 storici restano invariati.
Nessun processo proprio pendente; nessun commit effettuato dalla lane.
