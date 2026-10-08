# Benchmark finali TASK-054 — 8 ottobre 2026

**PASS, 11 test, exit0**, su `bb538923`: dieci canonici e una misura
 aggiuntiva del lavoro inbox. I nove file dei dieci benchmark canonici sono
 byte-identici alla baseline3962414: budget, warmup e campioni non modificati.
 [Ricevuta con comandi, hash e output delle misure](performance-operational-20261008.json).

| Caso | Risultato p95 host | Esito |
|---|---|---|
| Home warm cache |1,815ms;1 lettura cache / 1 fetch|PASS|
| Cache catalogo small / medium / 25k |read2,308/1,719/1,049ms; search2,771/4,063/12,811ms|PASS|
| Decode immagine 480px |12,144ms|PASS|
| Pubblicazione tracking |1,307ms;1 RPC / 1 subscription|PASS|
| Append catalogo 24 item |0,461ms|PASS|
| Render dettaglio prodotto |67,817ms;1 RPC per navigazione|PASS|
| Navigazione checkout |15,734ms;0 letture aggiuntive|PASS|
| Carrello guest 100 righe |read1,109ms;mutation2,297ms|PASS|
| Cache 50 ordini |write21,873ms;read18,378ms;17105byte|PASS|
| Selector 500 ordini |0,642ms|PASS|
| Lavoro inbox 25 / 500 righe |5 configurazioni / 5 build in ciascuno dei 5 campioni; 1 / 20 richieste|PASS|

I tempi sono misure `flutter_test_host` con dati sintetici. Non rappresentano
 frame time, CPU, memoria, avvio o latenza autenticata su telefono fisico.
 La misura inbox è un conteggio del lavoro widget, non una durata. Profile
 fisico e accettazione prestazionale live restano NOT_RUN.
