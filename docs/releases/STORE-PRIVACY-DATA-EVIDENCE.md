# Store privacy and data-safety evidence

Questo documento è evidence tecnica, non una risposta legale definitiva. Le console
store devono riflettere il binary, la configurazione e i provider effettivamente
attivati. Owner privacy/legal deve approvare le risposte prima della submission.

## Capability → data mapping

| Data/capability | Raccolta/uso tecnico | Link/tracking | Stato disclosure |
|---|---|---|---|
| email, nome profilo, subject/account ID | autenticazione, profilo e ownership server-side | linked; no advertising tracking | disclose Account management / App functionality |
| indirizzo, destinatario e istruzioni consegna | fulfillment scelto dall'utente | linked; no advertising tracking | disclose App functionality |
| contenuto carrello e selezioni checkout | carrello, revalidation e creazione ordine | linked quando autenticato | disclose App functionality |
| storico acquisti/ordini, importi e stato pagamento | ricevuta, supporto e reconciliation | linked; no advertising tracking | disclose Purchases / App functionality |
| forma di pagamento scelta in app (`pay_at_pickup` / cash on delivery quando abilitato) | creazione ordine e fulfillment server-authoritative | linked; no advertising tracking | disclose Financial info / Payment info / App functionality |
| dettagli carta, CVV, payment secret | il client non li raccoglie né li conserva | not collected by this binary | riesaminare se un SDK/provider payment viene aggiunto |
| coordinate corriere | ricevute owner-scoped per mostrare tracking live | linked all'ordine/corriere; no ads | disclose Location/App functionality se live tracking è attivo |
| posizione dispositivo cliente | nessuna permission o lettura native nel client | not collected | non dichiararla come raccolta del client |
| external carrier URL | aperto come link server-issued validato; non inviato a telemetry | linked al flow ordine | privacy review del carrier prima dell'activation |
| push/device token e installation ID | provider corrente unconfigured, nessun token; backend boundary predisposto | linked quando attivato | disclosure condizionale obbligatoria prima di APNs/FCM |
| preferenze e draft locali | continuità UI, locale, checkout e cache | on-device | dichiarare solo se store/provider policy lo richiede |
| analytics/crash | production/staging no-op; adapter typed, bounded e redacted predisposto | no active remote collection | aggiornare disclosure/consent prima di iniettare exporter |

## Privacy controls verificati

- telemetry vieta nome, email, telefono, indirizzo, coordinate, tracking URL, token,
  OAuth code, payment secret, raw query, UUID interni non necessari, push token e
  contenuto completo del carrello;
- auth e dati commerce restano owner-scoped tramite backend/RLS; il client non è il
  confine di autorizzazione;
- cache e secure auth storage hanno lifecycle/logout/account-switch coperti dai task
  resilience precedenti;
- account UI espone privacy e richiesta di cancellazione; l'esecuzione finale dipende
  dal workflow backend e dai termini/retention approvati;
- non esistono `NSLocation*UsageDescription` o permission Android location perché il
  client non legge la posizione del cliente;
- il provider push fail-closed non presenta prompt e non genera token finché non è
  configurato.

## iOS privacy manifest e SDK

`ios/Runner/PrivacyInfo.xcprivacy` dichiara i tipi raccolti direttamente dal target app:
nome, email, indirizzo fisico, user ID, storico acquisti, Payment Info per la forma di
pagamento scelta, storico ricerche e altro contenuto utente (istruzioni di consegna).
Sono tutti linked, usati per App Functionality e non usati per tracking. Payment Info
non implica che il client raccolga dettagli carta, CVV o payment secret: dichiara la
forma di pagamento scelta in-app e inviata al backend. Il target app non dichiara
direttamente Required Reason API né tracking domains. Le risposte App Privacy devono
comunque riconciliare questa baseline con i provider e i third-party partners realmente
attivi.

Il manifest del plugin Google Maps incluso nella dependency graph dichiara Required
Reason API per Disk Space, File Timestamp, System Boot Time e User Defaults, oltre a
tipi SDK per crash, device ID, performance, product interaction e user ID. Prima della
submission owner deve riconciliare queste dichiarazioni con la versione SDK realmente
linkata, le impostazioni provider e le risposte App Privacy. Nessun tipo viene omesso
solo perché l'adapter Maps è fail-closed.

## Store questionnaires — draft status

- Apple App Privacy: `NEEDS_OWNER_VALUE: privacy owner approval, retention and active
  provider reconciliation`.
- Google Data safety: `NEEDS_OWNER_VALUE: privacy owner approval, encryption/deletion
  statements and active provider reconciliation`.
- Privacy policy URL: `NEEDS_OWNER_VALUE`.
- Account deletion web URL required by store policy: `NEEDS_OWNER_VALUE`.
- Retention periods and lawful basis: `NEEDS_OWNER_VALUE`; never infer from code alone.

## Fonti policy

- Apple App Privacy include third-party partners:
  <https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy>
- Apple privacy details definitions:
  <https://developer.apple.com/app-store/app-privacy-details/>
- Google Data safety requirements:
  <https://support.google.com/googleplay/android-developer/answer/10787469?hl=en>
- Google account deletion requirements:
  <https://support.google.com/googleplay/android-developer/answer/13327111?hl=en-EN>
