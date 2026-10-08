# TASK-054 — QA operativa, 8 ottobre 2026

I gate host sono **PASS**: matrice indirizzi **9/9**, harness completo **75/75**,
contratti runner visuale **27/27** e analyze mirato. Comandi, exit code, impronte
source e log locali sono nel [JSON associato](qa-operational-20261008.json).
Le quattro sorgenti indirizzo registrate sono identiche a inizio/fine del run 75.
L'associazione al commit finale resta `NOT_RUN` fino al freeze gestito dal root;
non include automaticamente un eventuale fix controller Auth ABA successivo.

| Gate | Esito | Livello |
| --- | --- | --- |
| UPDATE immediato/differito e terzo retry; CREATE unknown in quattro locali/light-dark | PASS 9, exit0 | UI/controller produzione, repository sintetici, host |
| Harness visuale completo | PASS 75, exit0 | Host; nessun PNG nativo prodotto |
| Runner visuale Android dopo estrazione lifecycle e count113 | PASS 27, exit0 | Contratti del runner |
| Analyze harness | PASS, exit0 | Source |
| Runner journal, review indipendente di altra lane | PASS 13 unit + 11 prove negative, exit0; APPROVED nello scope source | [Ricevuta separata](native-journal-review-20261008.json), non esecuzione ci_native |
| Catture Android/iOS, IME reale, TalkBack/VoiceOver, profile fisico, journal nativo | NOT_RUN | Restano gate nativi distinti |

La matrice usa es-CL, it, en, zh-Hans: in light verifica l'intent nella route
ancora aperta, in dark chiude e riapre prima della verifica. Il caso UPDATE
controlla tastiera/focus prima degli invii immediato e differito, conservazione
bozza e identità, raggiungibilità del messaggio completo e di ogni CTA, quindi
ACK al terzo tentativo. Il probe host usa Roboto pinned, display 320x640,
contenitore 320x568, testo 200% e inset sintetico 240 che segue la perdita di focus.
Questo non è evidenza di tastiera di sistema.

Sulla baseline `3962414` la raggiungibilità con scroll è **PASS 1 / exit 0**:
il precedente errore bottom 1458 / viewport 400 riguardava soltanto la visibilità
senza scroll. È distinto da **NI054-32**, riprodotto sia sulla baseline sia sul
source `56883610`: dopo errore differito l'opener `_AddressSection` era smontato,
mentre editor, snapshot e CTA restavano attivi; il terzo tentativo non arrivava
al repository. La key stabile conserva l'opener. I guard di identità e mounted
restano presenti; UPDATE completo e Verify diretto passano nel run finale.
Il precedente overflow transitorio 20 px nel busy è eliminato con feedback
scrollabile; tutte le verifiche finali conservano testo e azioni raggiungibili.

L'adapter host ha avuto due problemi propri, conservati nei log: iniziale errore
di compilazione del solo campo `reportData` e 73 PASS / 2 FAIL sugli allegati reali.
La diagnosi ha confermato identità coerente e AuthController non istanziato;
`File.readAsBytes` restava in attesa sotto FakeAsync. Un drain host limitato a
20 turni runAsync 20 ms + pump porta gli upload da 0 a 3 e mantiene le asserzioni
originali. Nessun guard applicativo è stato disattivato. Il successivo harness
è 75 PASS. Log completi, mirror e generatori restano in
`build/task054/qa-20261008/`, non versionati.

Il contratto nativo è **113 PNG Flutter + 4 frame OS per piattaforma**, tutti
`NOT_RUN`: 105 catture precedenti conservate più 8 stati CREATE unknown.
I marker aggiunti sono `address-create-unknown-compact200-<locale>-<brightness>`;
`address-editor-focus-compact200` conserva il frame OS previsto. Il solo nome
file o un inset Flutter non attesta tastiera reale né qualità dei pixel.

CI5 `37369690043` resta storica e fallita: Android debug build/security PASS,
poi shutdown del runner durante assembleDebug, senza test/PNG/cleanup attestato;
causa esclusiva sconosciuta. iOS debug fallisce prima di Flutter, exit 124 dopo
bootstatus 300 in `com.apple.locationd.migrator`; smoke/catture NOT_RUN, cleanup
own attestato. Quality e Android release non ottengono runner; iOS release
unsigned e 89 fixture PASS. Il controllo ufficiale hosted dell'8 ottobre
15:14UTC osserva servizio operativo e nessun incidente aperto
([GitHub Status](https://www.githubstatus.com/),
[incidente del 5 ottobre](https://www.githubstatus.com/incidents/3q1yb5m7ltvb)).
L'immagine CI resta 20260907.0351.1 / Xcode 26.6 / iOS 26.5, uguale a CI5:
la disponibilità del servizio è cambiata, la readiness iOS va ancora provata.

La toolchain locale resta **BLOCKED** per target 14: unica Xcode 27.0 / SDK 27,
minimumDeploymentTarget 15, Simulator.app assente nella Developer selezionata.
Non è stato lanciato un build né dichiarato un compiler failure. Non sono state
usate o modificate risorse delle lane N.

La sequenza candidata è un solo nuovo run dopo freeze/review, attivato dal push
ordinario PR, con controllo SHA/job/step/annotation e ricevute terminali.
Budget visual Android 25 / iOS 30, boot 300, drive 900 e iOS 14 restano invariati;
il journal Android ha job separato 25 con stessi pin. Non ripetere CI5 stale o
un fallimento infrastrutturale invariato. Il JSON riporta i comandi own per
Android/iOS e profile; quest'ultimo richiede device fisico e configurazione TEST
approvati. I 10 benchmark canonici, più quello inbox aggiuntivo, sono misure
host e non sostituiscono profile o accessibilità assistiva reali.
