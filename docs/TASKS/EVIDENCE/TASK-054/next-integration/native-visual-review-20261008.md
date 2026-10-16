# Review indipendente dei pixel Android — 2026-10-08

Esito **APPROVED**, limitato a `ANDROID_NATIVE_FIXTURE_PIXEL_SAMPLE` sul commit
`62980d29327c1bd09d07ecbd0116570f1df4b94f`, CI `37817219242`, artifact `11569040559`.
Nessun finding visivo bloccante nel campione esaminato. L’accettazione integrata
resta **BLOCKED**: questa review non chiude TASK-054.

Il reviewer distinto dal writer ha aperto con `view_image(detail=original)` **25 PNG
Flutter e 2 PNG OS originali**, senza ricavare l’esito da nomi, flag o contact sheet.
L’inventario dell’artifact contiene 113 PNG Flutter e 4 OS; le immagini restanti
sono oggetto della review separata di `ci_native`. Il JSON associato conserva
l’elenco esatto, dimensioni e SHA-256 di ciascun originale ispezionato.

| Ambito | Frame ispezionati | Risultato osservabile |
| --- | --- | --- |
| Recensioni C07/C09 | Flutter 97–103, OS97 | Errori 99/101 completi con retry e cancellazione visibili; 98 mostra lo stato disabilitato; 100/102/103 mostrano i readback del commento conservato, modificato e invariato dopo annullamento. |
| Indirizzo UPDATE | Flutter62, OS62 | Errore interamente leggibile, Cerrar e Guardar visibili. Nel frame OS la tastiera Android è realmente presente e non copre le azioni. |
| Indirizzo CREATE incerto | Flutter63–70 | Titolo, istruzione e chiusura/verifica leggibili in es-CL, it, en e zh-Hans, light e dark. In inglese le azioni si dispongono verticalmente senza taglio. |
| Inbox | Flutter92–96 | Cargar más leggibile; pagina 2 e indicatore non letto visibili; stato vuoto, avviso cache offline e stato indisponibile distinguibili. |
| Fulfillment | Flutter75/80/85/90 | Badge ritiro/consegna completi nelle quattro lingue; quantità e aggiunta al carrello visibili. |

Nei frame **OS62 e OS97** la tastiera è stata vista nei pixel. In OS97 anche
Cancelar ed Enviar a moderación restano sopra l’IME. I due hash corrispondono ai
sidecar e al commit candidato. Gli otto frame Flutter dell’esito incerto non
provano la presenza dell’IME nelle quattro lingue.

Le catture 97/101 e 92–94 sono viewport scorsi: parte del commento o del contenuto
iniziale è fuori vista; in 93 anche la fine della riga è sotto il viewport.
Il harness frozen usa `_reveal`/`ensureVisible`, confermando il posizionamento.
Non sono immagini dell’intera pagina e non dimostrano irraggiungibilità.
I badge e le azioni primarie osservati sono interamente visibili; non sono state
rilevate barre di overflow o sovrapposizioni che li rendano illeggibili.

La sola immagine non prova un tap. La correlazione separata con
`integration_test/task054_next_integration_surfaces_test.dart` frozen
(SHA-256 `cb8d1dae5c765a85ea441aad4d98c95caca70700304d02e8d8f3a48a4fae78b0`)
e con il log CI terminale `+76: All tests passed!`, exit 0, documenta interazioni
fixture, retry e readback. Il reviewer ha letto questa prova CI, senza rieseguire
Flutter, build o device e senza presentarla come interazione manuale autonoma.

**Limiti:** iOS `NOT_RUN` in questa review, senza qualificazione dell’esito iOS;
TalkBack/VoiceOver, ordine del focus, annunci, composizione CJK e altre tastiere,
misura quantitativa del contrasto, uso manuale su device fisico e flussi autenticati
live `NOT_RUN`. Leggibilità visiva e fixture native non sostituiscono tali gate.

Sono stati creati soltanto questa sintesi e
[native-visual-review-20261008.json](native-visual-review-20261008.json).
Nessun source, test o documento di governance modificato.
