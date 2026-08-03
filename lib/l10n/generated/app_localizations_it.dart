// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get backendNotConfigured =>
      'Backend non configurato: modalità development offline.';

  @override
  String get backendChecking => 'Verifica della connessione al negozio…';

  @override
  String get backendOffline =>
      'Connessione assente. Puoi continuare a esplorare e riprovare.';

  @override
  String get backendUnavailable => 'Il negozio non è disponibile al momento.';

  @override
  String get backendAuthenticationRequired =>
      'Accedi da Account per continuare.';

  @override
  String get backendRetry => 'Riprova';

  @override
  String storefrontCacheFresh(String date) {
    return 'Copia salvata aggiornata il $date.';
  }

  @override
  String storefrontCacheStale(String date) {
    return 'Copia salvata del $date. Prezzi e disponibilità potrebbero essere cambiati.';
  }

  @override
  String get storefrontCacheRefreshing => 'Aggiornamento in background…';

  @override
  String get navigationHome => 'Home';

  @override
  String get navigationCatalog => 'Catalogo';

  @override
  String get navigationCart => 'Carrello';

  @override
  String get navigationAccount => 'Account';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeFoundationMessage =>
      'Presto potrai scoprire qui le novità del negozio.';

  @override
  String get catalogTitle => 'Catalogo';

  @override
  String get catalogFoundationMessage =>
      'Il catalogo sarà presto disponibile qui.';

  @override
  String get cartTitle => 'Carrello';

  @override
  String get cartFoundationMessage =>
      'Il carrello sarà disponibile quando potrai scegliere i prodotti.';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountFoundationMessage =>
      'Potrai accedere al tuo account quando questa funzione sarà disponibile.';

  @override
  String get homeWelcomeTitle => 'Tutto pronto per iniziare a esplorare';

  @override
  String get homeWelcomeMessage =>
      'Scopri le sezioni del negozio mentre prepariamo il catalogo.';

  @override
  String get homeSearchLabel => 'Cerca nel negozio';

  @override
  String get homeSearchHint => 'Cosa stai cercando?';

  @override
  String get homeCategoriesTitle => 'Esplora per categoria';

  @override
  String get homeCategoriesMessage =>
      'Le categorie appariranno quando il catalogo sarà disponibile.';

  @override
  String get homeExploreCategories => 'Vedi categorie';

  @override
  String get homeOffersTitle => 'Offerte';

  @override
  String get homeOffersEmptyTitle => 'Offerte, prossimamente';

  @override
  String get homeOffersEmptyMessage =>
      'Qui mostreremo offerte reali quando saranno disponibili.';

  @override
  String get homeFeaturedTitle => 'Prodotti in evidenza';

  @override
  String get homeFeaturedEmptyTitle => 'In evidenza, prossimamente';

  @override
  String get homeFeaturedEmptyMessage =>
      'Questa sezione mostrerà prodotti reali quando il catalogo sarà disponibile.';

  @override
  String get homeExploreCatalog => 'Esplora catalogo';

  @override
  String get homeLoadingTitle => 'Caricamento del negozio';

  @override
  String get homeLoadingMessage =>
      'Stiamo preparando categorie, offerte e prodotti in evidenza.';

  @override
  String get homeLoadErrorTitle => 'Non è stato possibile caricare il negozio';

  @override
  String get homeLoadErrorMessage => 'Controlla la connessione e riprova.';

  @override
  String get homeUnavailableTitle => 'Il negozio non è disponibile';

  @override
  String get homeUnavailableMessage =>
      'Il catalogo pubblico non è disponibile in questo momento.';

  @override
  String get homeImageUnavailable => 'Immagine non disponibile';

  @override
  String homePreviousPrice(String price) {
    return 'Prima $price';
  }

  @override
  String homeDiscountPercent(String percent) {
    return 'Sconto del $percent%';
  }

  @override
  String get catalogSearchLabel => 'Cerca nel catalogo';

  @override
  String get catalogSearchHint => 'Cerca prodotti o categorie';

  @override
  String get catalogSearchMinimum =>
      'Inserisci almeno 2 caratteri per cercare.';

  @override
  String get catalogClearSearch => 'Cancella ricerca';

  @override
  String get catalogFilterLabel => 'Filtra';

  @override
  String get catalogSortLabel => 'Ordina';

  @override
  String get catalogControlsUnavailable =>
      'Ricerca, filtri e ordinamento saranno disponibili nel prossimo passaggio.';

  @override
  String get catalogFiltersLabel => 'Filtri del catalogo';

  @override
  String catalogLoadedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prodotti caricati',
      one: '1 prodotto caricato',
      zero: 'Nessun prodotto caricato',
    );
    return '$_temp0';
  }

  @override
  String get catalogShowFilters => 'Mostra filtri';

  @override
  String get catalogHideFilters => 'Nascondi filtri';

  @override
  String get catalogFiltersUnavailableDuringSearch =>
      'Durante la ricerca puoi filtrare per categoria. Cancella la ricerca per usare disponibilità, sconti o ordinamento.';

  @override
  String get catalogAvailabilityLabel => 'Disponibilità';

  @override
  String get catalogAvailabilityAll => 'Tutta';

  @override
  String get catalogAvailabilityAvailable => 'Disponibile';

  @override
  String get catalogAvailabilityLowStock => 'Poche unità';

  @override
  String get catalogAvailabilityUnavailable => 'Non disponibile';

  @override
  String get catalogAvailabilityReservationOnly => 'Solo prenotazione';

  @override
  String get catalogAvailabilityPickupOnly => 'Solo ritiro';

  @override
  String get catalogAvailabilityDeliveryOnly => 'Solo consegna';

  @override
  String get catalogDiscountedOnly => 'Solo con sconto';

  @override
  String get catalogSortCatalog => 'Ordine del catalogo';

  @override
  String get catalogSortName => 'Nome';

  @override
  String get catalogSortPriceAscending => 'Prezzo: dal più basso';

  @override
  String get catalogSortPriceDescending => 'Prezzo: dal più alto';

  @override
  String get catalogResetFilters => 'Reimposta filtri';

  @override
  String get productDetailTitle => 'Dettaglio prodotto';

  @override
  String get productDetailLoading => 'Caricamento prodotto';

  @override
  String get productDetailUnavailableTitle => 'Prodotto non disponibile';

  @override
  String get productDetailUnavailableMessage =>
      'Questo prodotto non è pubblicato o non è più disponibile.';

  @override
  String get productDetailOfflineTitle => 'Sei offline';

  @override
  String get productDetailOfflineMessage =>
      'Connettiti a internet per caricare il dettaglio aggiornato.';

  @override
  String get productDetailErrorTitle =>
      'Non è stato possibile caricare il prodotto';

  @override
  String get productDetailErrorMessage =>
      'Riprova. Non sono stati mostrati dati incompleti.';

  @override
  String get productDetailDescriptionLabel => 'Descrizione';

  @override
  String get productDetailNoDescription =>
      'Non è disponibile una descrizione pubblica.';

  @override
  String get productDetailCategoryLabel => 'Categoria';

  @override
  String get productDetailBrandLabel => 'Marca';

  @override
  String get productDetailPriceLabel => 'Prezzo';

  @override
  String productDetailSavings(String amount) {
    return 'Risparmi $amount';
  }

  @override
  String productDetailImagePosition(int current, int total) {
    return 'Immagine $current di $total';
  }

  @override
  String get productDetailAvailabilityLabel => 'Disponibilità commerciale';

  @override
  String get productDetailFulfillmentLabel => 'Opzioni di acquisto';

  @override
  String get productDetailPickup => 'Ritiro in negozio';

  @override
  String get productDetailDelivery => 'Consegna';

  @override
  String get productDetailReservation => 'Prenotazione';

  @override
  String get productDetailPromotionLabel => 'Promozione attiva';

  @override
  String get catalogCategoriesLabel => 'Categorie';

  @override
  String get catalogAllCategories => 'Tutti';

  @override
  String get catalogLoadingMore => 'Caricamento di altri prodotti';

  @override
  String get catalogLoadMoreError =>
      'Non è stato possibile caricare altri prodotti';

  @override
  String get catalogConnectingTitle => 'Preparazione del catalogo';

  @override
  String get catalogConnectingMessage =>
      'Stiamo verificando se il negozio è disponibile.';

  @override
  String get catalogEmptyTitle => 'Nessun prodotto pubblicato';

  @override
  String get catalogEmptyMessage =>
      'Prova un\'altra categoria o torna più tardi.';

  @override
  String get catalogOfflineTitle => 'Sei offline';

  @override
  String get catalogOfflineMessage =>
      'Controlla la connessione e riprova. Il resto dell\'app rimane disponibile.';

  @override
  String get catalogUnavailableTitle => 'Il negozio non è disponibile';

  @override
  String get catalogUnavailableMessage =>
      'Al momento non possiamo preparare il catalogo pubblico.';

  @override
  String get catalogRetryTitle => 'Non è stato possibile verificare il negozio';

  @override
  String get catalogRetryMessage =>
      'Riprova. Puoi anche continuare a esplorare le altre sezioni.';

  @override
  String get cartEmptyTitle => 'Il carrello è vuoto';

  @override
  String get cartEmptyMessage =>
      'Quando il catalogo sarà disponibile, potrai aggiungere qui i prodotti.';

  @override
  String get cartExploreCatalog => 'Esplora catalogo';

  @override
  String get accountGuestTitle => 'Il tuo account';

  @override
  String get accountGuestBenefit =>
      'Accedi per usare le funzioni personali. Puoi continuare a esplorare senza account.';

  @override
  String get accountContinueWithGoogle => 'Continua con Google';

  @override
  String get accountGoogleComingSoon =>
      'L\'accesso con Google sarà disponibile prossimamente.';

  @override
  String get accountBrowseAsGuest => 'Continua come ospite';

  @override
  String get accountAuthenticatedTitle => 'Accesso effettuato';

  @override
  String get accountNameFallback => 'Cliente';

  @override
  String get accountEmailFallback => 'Email non disponibile';

  @override
  String get accountSessionActive => 'La sessione è attiva.';

  @override
  String get accountLogout => 'Esci';

  @override
  String get accountSigningInTitle => 'Apertura dell\'accesso sicuro';

  @override
  String get accountSigningInMessage =>
      'Completa l\'accesso nel browser e torna all\'app.';

  @override
  String get accountCancelSignIn => 'Annulla accesso';

  @override
  String get accountCancellingTitle => 'Annullamento dell\'accesso';

  @override
  String get accountCancellingMessage =>
      'Stiamo chiudendo in sicurezza questo tentativo di accesso.';

  @override
  String get accountCancelledTitle => 'Accesso annullato';

  @override
  String get accountCancelledMessage =>
      'Il tuo account non è stato modificato. Puoi riprovare.';

  @override
  String get accountRetry => 'Riprova';

  @override
  String get accountAuthErrorTitle => 'Accesso non riuscito';

  @override
  String get accountConfigurationErrorTitle => 'Accesso non disponibile';

  @override
  String get accountSigningOut => 'Uscita in corso…';

  @override
  String get accountAuthOffline => 'Controlla la connessione e riprova.';

  @override
  String get accountAuthProviderUnavailable =>
      'Google non è disponibile al momento. Riprova più tardi.';

  @override
  String get accountAuthBrowserLaunchFailed =>
      'Non è stato possibile aprire il browser.';

  @override
  String get accountAuthInvalidCallback =>
      'Il ritorno di accesso non era valido. Avvia un nuovo tentativo.';

  @override
  String get accountAuthSessionExpired =>
      'La sessione è terminata. Puoi accedere di nuovo.';

  @override
  String get accountAuthSecureStorageUnavailable =>
      'Questo dispositivo non può proteggere la sessione in modo sicuro.';

  @override
  String get accountAuthConfiguration =>
      'L\'accesso Google non è configurato per questo ambiente.';

  @override
  String get accountAuthUnexpected =>
      'Si è verificato un problema inatteso. Puoi riprovare.';

  @override
  String accountAvatarLabel(String name) {
    return 'Avatar di $name';
  }

  @override
  String get storefrontComingSoonLabel => 'Prossimamente';

  @override
  String get favoritesTitle => 'Preferiti';

  @override
  String get favoritesOpen => 'Vedi preferiti';

  @override
  String get favoritesEmptyTitle => 'Non hai ancora preferiti';

  @override
  String get favoritesEmptyMessage =>
      'Salva i prodotti per ritrovarli rapidamente, anche offline.';

  @override
  String get favoritesErrorTitle => 'Impossibile aprire i preferiti';

  @override
  String get favoritesErrorMessage =>
      'Riprova. Le selezioni restano su questo dispositivo.';

  @override
  String get favoriteAdd => 'Aggiungi ai preferiti';

  @override
  String get favoriteRemove => 'Rimuovi dai preferiti';

  @override
  String get favoriteAdded => 'Prodotto aggiunto ai preferiti.';

  @override
  String get favoriteRemoved => 'Prodotto rimosso dai preferiti.';

  @override
  String get favoriteUnavailableTitle => 'Prodotto non disponibile';

  @override
  String get favoriteUnavailableMessage =>
      'Puoi conservare questo preferito o rimuoverlo dalla lista.';

  @override
  String get productShare => 'Condividi prodotto';

  @override
  String productShareText(String name, String uri) {
    return 'Guarda $name su Merchandise Control:\n$uri';
  }

  @override
  String get productShareError =>
      'Impossibile aprire le opzioni di condivisione.';

  @override
  String get customerAccountLoading => 'Caricamento dei dati dell\'account';

  @override
  String get customerAccountRetry => 'Riprova';

  @override
  String get customerAccountOffline =>
      'Sei offline. I dati già caricati restano visibili; riconnettiti prima di salvare modifiche.';

  @override
  String get customerAccountUnauthorized =>
      'La sessione non consente più questa operazione. Accedi di nuovo.';

  @override
  String get customerAccountInvalid =>
      'Controlla i dati inseriti prima di continuare.';

  @override
  String get customerAccountConflict =>
      'I dati sono cambiati altrove. Aggiorna e riprova.';

  @override
  String get customerAccountTimeout =>
      'L\'operazione ha impiegato troppo tempo. Puoi riprovare senza duplicarla.';

  @override
  String get customerAccountUnavailable =>
      'I dati dell\'account non sono disponibili al momento.';

  @override
  String get customerAccountUnexpected =>
      'Impossibile completare l\'operazione. Le modifiche non vengono mostrate come confermate.';

  @override
  String get customerProfileTitle => 'Profilo';

  @override
  String get customerProfileDescription =>
      'Scegli come apparire e la lingua usata dall\'app.';

  @override
  String get customerProfileNameLabel => 'Nome visualizzato';

  @override
  String get customerProfileNameHint => 'Facoltativo';

  @override
  String get customerProfileLanguageLabel => 'Lingua';

  @override
  String get customerProfileLanguageEsCl => 'Español (Chile)';

  @override
  String get customerProfileLanguageIt => 'Italiano';

  @override
  String get customerProfileLanguageEn => 'English';

  @override
  String get customerProfileLanguageZhHans => '简体中文';

  @override
  String get customerProfileSave => 'Salva profilo';

  @override
  String get customerProfileSaved => 'Profilo salvato.';

  @override
  String get customerProfileDeleted =>
      'I dati pubblici del profilo sono stati reimpostati.';

  @override
  String get customerProfileResetTitle => 'Reimposta profilo';

  @override
  String get customerProfileResetMessage =>
      'Verranno rimossi nome, lingua e consenso salvati nel profilo. Indirizzi e accesso resteranno invariati.';

  @override
  String get customerProfileResetAction => 'Reimposta';

  @override
  String get customerAddressesTitle => 'Indirizzi';

  @override
  String get customerAddressesDescription =>
      'Salva i dati postali per usarli in seguito. La disponibilità della consegna viene verificata al checkout.';

  @override
  String get customerAddressesEmptyTitle => 'Nessun indirizzo salvato';

  @override
  String get customerAddressesEmptyMessage =>
      'Aggiungi un indirizzo quando vuoi preparare una consegna.';

  @override
  String get customerAddressAdd => 'Aggiungi indirizzo';

  @override
  String get customerAddressEdit => 'Modifica indirizzo';

  @override
  String get customerAddressDeleteTitle => 'Elimina indirizzo';

  @override
  String customerAddressDeleteMessage(String label) {
    return 'Eliminare l\'indirizzo “$label”?';
  }

  @override
  String get customerAddressDeleteAction => 'Elimina';

  @override
  String get customerAddressSaved => 'Indirizzo salvato.';

  @override
  String get customerAddressDeleted => 'Indirizzo eliminato.';

  @override
  String get customerAddressDefault => 'Predefinito';

  @override
  String get customerAddressSetDefault => 'Imposta come predefinito';

  @override
  String get customerAddressDefaultChanged =>
      'Indirizzo predefinito aggiornato.';

  @override
  String get customerAddressLabel => 'Etichetta';

  @override
  String get customerAddressRecipient => 'Nome del destinatario';

  @override
  String get customerAddressLine1 => 'Indirizzo';

  @override
  String get customerAddressLine2 =>
      'Interno, ufficio o riferimento (facoltativo)';

  @override
  String get customerAddressCommune => 'Comune';

  @override
  String get customerAddressRegion => 'Regione';

  @override
  String get customerAddressPostalCode => 'Codice postale (facoltativo)';

  @override
  String get customerAddressCountryCode => 'Codice paese';

  @override
  String get customerAddressInstructions =>
      'Istruzioni di consegna (facoltative)';

  @override
  String customerAddressSemantics(
    String label,
    String address,
    String commune,
  ) {
    return 'Indirizzo $label: $address, $commune';
  }

  @override
  String get customerPrivacyTitle => 'Privacy e dati';

  @override
  String get customerPrivacyDescription =>
      'Gestisci il consenso e consulta una copia dei dati Storefront associati al tuo account.';

  @override
  String get customerPrivacyConsentTitle => 'Consenso privacy';

  @override
  String get customerPrivacyConsentDescription =>
      'Registra o revoca l\'accettazione della versione attuale. Non viene mai attivato implicitamente.';

  @override
  String get customerPrivacyConsentUpdated => 'Preferenza privacy aggiornata.';

  @override
  String get customerDataExportAction =>
      'Visualizza l\'esportazione dei miei dati';

  @override
  String get customerDataExportTitle => 'I tuoi dati Storefront';

  @override
  String get customerDeletionTitle => 'Eliminazione account';

  @override
  String get customerDeletionDescription =>
      'Puoi inviare una richiesta di eliminazione verificabile. L\'app non cancella subito l\'account.';

  @override
  String get customerDeletionPending =>
      'La richiesta è in attesa e verrà gestita secondo la politica di conservazione.';

  @override
  String get customerDeletionConfirmTitle => 'Richiedi eliminazione account';

  @override
  String get customerDeletionConfirmMessage =>
      'La richiesta verrà registrata per la revisione. La sessione resterà aperta e i dati non saranno eliminati subito.';

  @override
  String get customerDeletionRequestAction => 'Richiedi eliminazione';

  @override
  String get customerDeletionCancelAction => 'Annulla richiesta';

  @override
  String get customerDeletionRequested =>
      'Richiesta di eliminazione registrata.';

  @override
  String get customerDeletionCancelled =>
      'Richiesta di eliminazione annullata.';

  @override
  String get customerDialogCancel => 'Annulla';

  @override
  String get customerDialogSave => 'Salva';

  @override
  String get customerDialogClose => 'Chiudi';

  @override
  String get customerFieldRequired => 'Campo obbligatorio.';

  @override
  String get customerFieldInvalid => 'Controlla formato e lunghezza del campo.';

  @override
  String get customerNotificationsTitle => 'Notifiche';

  @override
  String get customerNotificationsDescription =>
      'Scegli se ricevere aggiornamenti essenziali su ordini e prenotazioni. Il permesso di sistema viene richiesto separatamente.';

  @override
  String get customerNotificationsLoading =>
      'Caricamento delle impostazioni di notifica';

  @override
  String get customerNotificationsProviderUnavailable =>
      'Le notifiche push non sono configurate in questa build. Nessun token è stato registrato e nessun permesso è stato simulato.';

  @override
  String get customerNotificationsActive =>
      'Notifiche attive e confermate dal server.';

  @override
  String get customerNotificationsNotRequested =>
      'Non hai ancora scelto se ricevere notifiche.';

  @override
  String get customerNotificationsDenied =>
      'Hai scelto di non ricevere notifiche. Puoi cambiare preferenza in qualsiasi momento.';

  @override
  String get customerNotificationsRevoked =>
      'Le notifiche sono revocate per questa installazione.';

  @override
  String get customerNotificationsPending =>
      'La modifica è salvata sul dispositivo, ma non è ancora confermata dal server.';

  @override
  String get customerNotificationsOffline =>
      'Non possiamo confermare la modifica mentre sei offline. Riprova quando torna la connessione.';

  @override
  String get customerNotificationsTimeout =>
      'Il server ha impiegato troppo tempo. Puoi riprovare senza duplicare l’operazione idempotente.';

  @override
  String get customerNotificationsUnauthorized =>
      'La sessione non consente più di aggiornare le notifiche.';

  @override
  String get customerNotificationsInvalid =>
      'La configurazione delle notifiche non è valida.';

  @override
  String get customerNotificationsConflict =>
      'L’operazione idempotente non corrisponde alla richiesta precedente. Aggiorna e riprova.';

  @override
  String get customerNotificationsUnavailable =>
      'Non è stato possibile aggiornare le notifiche. La modifica non risulta confermata.';

  @override
  String get customerNotificationsEnable => 'Attiva';

  @override
  String get customerNotificationsNotNow => 'Non ora';

  @override
  String get customerNotificationsRevoke => 'Revoca';

  @override
  String get customerNotificationsRetry => 'Riprova';

  @override
  String reservationHoldCreateAction(int quantity) {
    return 'Prenota $quantity per 15 min';
  }

  @override
  String get reservationHoldSignInAction => 'Accedi per prenotare';

  @override
  String get reservationHoldLoading =>
      'Conferma della prenotazione con il negozio';

  @override
  String get reservationHoldActive => 'Prenotazione attiva';

  @override
  String get reservationHoldExpiring => 'La prenotazione scade a breve';

  @override
  String reservationHoldRemaining(String time) {
    return 'Restano $time';
  }

  @override
  String get reservationHoldExpired =>
      'La prenotazione è scaduta e la disponibilità è tornata al negozio.';

  @override
  String get reservationHoldReleased => 'Prenotazione rilasciata.';

  @override
  String get reservationHoldConsumed =>
      'La prenotazione è già stata utilizzata.';

  @override
  String get reservationHoldReleaseAction => 'Rilascia prenotazione';

  @override
  String get reservationHoldRetryAction => 'Riprova in sicurezza';

  @override
  String get reservationHoldDismissAction => 'Chiudi stato';

  @override
  String get reservationHoldPendingRetry =>
      'L’operazione pendente conserva la stessa chiave idempotente.';

  @override
  String get reservationHoldOfflineError =>
      'Sei offline. Una nuova prenotazione non viene mostrata come confermata.';

  @override
  String get reservationHoldTimeoutError =>
      'L’esito è ambiguo. Riprova in sicurezza per conoscere lo stato autorevole.';

  @override
  String get reservationHoldUnauthorizedError =>
      'Accedi di nuovo per gestire la prenotazione.';

  @override
  String get reservationHoldInvalidError =>
      'La richiesta di prenotazione non è valida.';

  @override
  String get reservationHoldConflictError =>
      'La chiave idempotente appartiene a un’altra richiesta. Crea nuovamente la prenotazione.';

  @override
  String get reservationHoldUnavailableError =>
      'Il negozio non può più prenotare questa quantità.';

  @override
  String get reservationHoldLimitError =>
      'Hai raggiunto il limite di prenotazioni attive.';

  @override
  String get reservationHoldNotFoundError =>
      'La prenotazione non esiste più o non appartiene a questo account.';

  @override
  String get reservationHoldUnexpectedError =>
      'Non è stato possibile verificare la prenotazione. Riprova.';

  @override
  String get cartAddAction => 'Aggiungi al carrello';

  @override
  String get cartAddedNotice => 'Prodotto aggiunto al carrello.';

  @override
  String get cartGuestSyncMessage =>
      'Il carrello è salvato su questo dispositivo e funziona offline.';

  @override
  String get cartAccountSyncMessage =>
      'Il carrello è associato al tuo account e validato con il negozio.';

  @override
  String cartIndicativeSubtotal(String price) {
    return 'Subtotale stimato: $price';
  }

  @override
  String cartConfirmedSubtotal(String price) {
    return 'Subtotale validato: $price';
  }

  @override
  String get cartRevalidateAction => 'Valida carrello';

  @override
  String get cartEstimatedLabel => 'Stimato';

  @override
  String get cartValidatedLabel => 'Validato';

  @override
  String get cartRetryAction => 'Riprova';

  @override
  String get cartClearAction => 'Svuota carrello';

  @override
  String get cartClearTitle => 'Svuotare il carrello?';

  @override
  String get cartClearMessage =>
      'Tutti i prodotti verranno rimossi da questo carrello.';

  @override
  String get cartRemoveAction => 'Rimuovi';

  @override
  String cartQuantityLabel(int quantity) {
    return 'Quantità: $quantity';
  }

  @override
  String get cartDecreaseQuantity => 'Riduci quantità';

  @override
  String get cartIncreaseQuantity => 'Aumenta quantità';

  @override
  String get cartUnavailableLine => 'Questo prodotto non è più disponibile.';

  @override
  String get cartPriceChangedLine =>
      'Il prezzo è cambiato. Controlla il valore attuale.';

  @override
  String get cartPromotionChangedLine =>
      'La promozione è cambiata. Controlla il valore attuale.';

  @override
  String get cartMergedNotice =>
      'Il carrello del dispositivo è stato sincronizzato con l’account.';

  @override
  String get cartPartialMergeNotice =>
      'I prodotti disponibili sono stati sincronizzati; gli altri restano visibili per la verifica.';

  @override
  String get cartRevalidatedNotice =>
      'Prezzi e disponibilità validati dal negozio.';

  @override
  String get cartUpdatedNotice => 'Quantità aggiornata.';

  @override
  String get cartRemovedNotice => 'Prodotto rimosso dal carrello.';

  @override
  String get cartClearedNotice => 'Carrello svuotato.';

  @override
  String get cartOfflineError =>
      'Sei offline. Il carrello locale resta disponibile.';

  @override
  String get cartTimeoutError =>
      'Il negozio ha impiegato troppo tempo. Riprova senza duplicare l’operazione.';

  @override
  String get cartUnauthorizedError =>
      'Accedi di nuovo per sincronizzare il carrello.';

  @override
  String get cartConflictError =>
      'Il carrello è cambiato altrove. Aggiorna e riprova.';

  @override
  String get cartUnavailableError =>
      'Non possiamo aggiornare il carrello in questo momento.';

  @override
  String get cartInvalidError => 'La richiesta del carrello non è valida.';

  @override
  String get cartLimitReached =>
      'Il carrello ha raggiunto il numero massimo di prodotti distinti.';

  @override
  String get cartProductUnavailable =>
      'Questo prodotto non può più essere aggiunto.';

  @override
  String get cartSignInAction => 'Accedi';

  @override
  String get cartPendingRetry =>
      'Un’operazione in sospeso può essere ripetuta in sicurezza.';

  @override
  String get cartPriceDisclaimer =>
      'Prezzi e disponibilità saranno confermati di nuovo prima della creazione dell’ordine.';

  @override
  String cartLineSemantics(String name, int quantity, String price) {
    return '$name, quantità $quantity, $price';
  }

  @override
  String get cartCheckoutAction => 'Vai al checkout';

  @override
  String get cartSignInCheckoutAction => 'Accedi e continua';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get checkoutStepMode => 'Modalità';

  @override
  String get checkoutStepDestination => 'Destinazione';

  @override
  String get checkoutStepSlot => 'Fascia oraria';

  @override
  String get checkoutStepReview => 'Riepilogo';

  @override
  String get checkoutStepConfirmation => 'Conferma';

  @override
  String checkoutStepProgress(int current, int total, String title) {
    return 'Passaggio $current di $total: $title';
  }

  @override
  String get checkoutAuthTitle => 'Accedi per confermare';

  @override
  String get checkoutAuthMessage =>
      'Puoi esplorare e conservare il carrello senza un account. Per validare indirizzo, prezzi e disponibilità serve la tua sessione cliente.';

  @override
  String get checkoutContinueBrowsing => 'Torna al carrello';

  @override
  String get checkoutUnavailableTitle => 'Checkout non disponibile';

  @override
  String get checkoutRetryAction => 'Riprova in sicurezza';

  @override
  String get checkoutContinueAction => 'Continua';

  @override
  String get checkoutBackAction => 'Indietro';

  @override
  String get checkoutBackToCart => 'Torna al carrello';

  @override
  String get checkoutRestartAction => 'Ricomincia';

  @override
  String get checkoutModeTitle => 'Come vuoi ricevere il tuo acquisto?';

  @override
  String get checkoutModeMessage =>
      'Mostriamo solo le modalità configurate e disponibili per questo negozio.';

  @override
  String get checkoutModePickup => 'Ritiro';

  @override
  String get checkoutModePickupDescription =>
      'Ritira l’acquisto presso un punto disponibile.';

  @override
  String get checkoutModeReservation => 'Prenotazione';

  @override
  String get checkoutModeReservationDescription =>
      'Conferma una prenotazione attiva e ritirala in negozio.';

  @override
  String get checkoutModeDelivery => 'Consegna';

  @override
  String get checkoutModeDeliveryDescription =>
      'Ricevi l’acquisto a un indirizzo in una zona di consegna attiva.';

  @override
  String get checkoutDeliveryAddressTitle => 'Indirizzo di consegna';

  @override
  String get checkoutDeliveryAddressMessage =>
      'Il negozio valida sul server indirizzo, zona e tariffa.';

  @override
  String get checkoutNoAddresses =>
      'Aggiungi un indirizzo al tuo account prima di scegliere la consegna.';

  @override
  String get checkoutManageAddresses => 'Gestisci indirizzi';

  @override
  String get checkoutUnsupportedAddress => 'Fuori dalle zone disponibili';

  @override
  String get checkoutPickupPointTitle => 'Punto di ritiro';

  @override
  String get checkoutPickupPointMessage =>
      'Scegli una sede pubblica disponibile per questa modalità.';

  @override
  String get checkoutSlotTitle => 'Fascia oraria disponibile';

  @override
  String get checkoutSlotMessage =>
      'La capacità viene verificata di nuovo durante la validazione del checkout.';

  @override
  String get checkoutNoSlots =>
      'Non ci sono più fasce disponibili per questa selezione.';

  @override
  String get checkoutReviewTitle => 'Controlla la selezione';

  @override
  String get checkoutReviewMessage =>
      'Questo totale è ancora stimato. Il negozio rileggerà carrello, promozioni e disponibilità.';

  @override
  String get checkoutPaymentTitle => 'Metodo di pagamento';

  @override
  String get checkoutPaymentMessage =>
      'Scegli un metodo disponibile per questa modalità. Il negozio lo verificherà di nuovo alla creazione dell\'ordine.';

  @override
  String get checkoutPaymentPayAtPickup => 'Paga al ritiro';

  @override
  String get checkoutPaymentPayAtPickupDescription =>
      'Paga in negozio al ritiro o alla conferma della prenotazione.';

  @override
  String get checkoutPaymentCashOnDelivery => 'Pagamento alla consegna';

  @override
  String get checkoutPaymentCashOnDeliveryDescription =>
      'Paga alla ricezione dell\'ordine, solo nelle zone abilitate.';

  @override
  String get checkoutPaymentOnline => 'Pagamento online';

  @override
  String get checkoutPaymentOnlineUnavailable =>
      'Non configurato per Storefront v1.';

  @override
  String get checkoutPaymentRequired =>
      'Seleziona un metodo di pagamento disponibile per creare l\'ordine.';

  @override
  String get checkoutPaymentUnavailable =>
      'Nessun metodo di pagamento è disponibile per questa modalità.';

  @override
  String get checkoutPaymentMethodLabel => 'Metodo di pagamento';

  @override
  String get checkoutPaymentStatusLabel => 'Stato pagamento';

  @override
  String get checkoutPaymentStatusDueAtFulfillment =>
      'Da pagare alla consegna o al ritiro';

  @override
  String get checkoutPaymentStatusPendingProvider => 'In attesa del provider';

  @override
  String get checkoutPaymentStatusProcessing => 'In elaborazione';

  @override
  String get checkoutPaymentStatusAuthorized => 'Autorizzato';

  @override
  String get checkoutPaymentStatusCollected => 'Incassato';

  @override
  String get checkoutPaymentStatusFailed => 'Non riuscito';

  @override
  String get checkoutPaymentStatusCancelled => 'Annullato';

  @override
  String get checkoutPaymentStatusRefundPending => 'Rimborso in attesa';

  @override
  String get checkoutPaymentStatusRefundFailed => 'Rimborso non riuscito';

  @override
  String get checkoutPaymentStatusRefunded => 'Rimborsato';

  @override
  String get checkoutServerValidationNotice =>
      'Il server calcola prezzi, sconti, tariffa e totale. L’app non invia un totale autorevole.';

  @override
  String get checkoutSubtotalLabel => 'Subtotale';

  @override
  String get checkoutDeliveryFeeLabel => 'Tariffa di consegna';

  @override
  String get checkoutEstimatedTotalLabel => 'Totale stimato';

  @override
  String get checkoutAuthoritativeTotalLabel => 'Totale validato';

  @override
  String get checkoutValidateAction => 'Valida prezzi e disponibilità';

  @override
  String get checkoutConfirmationTitle => 'Conferma checkout';

  @override
  String get checkoutQuoteReadyMessage =>
      'Il negozio ha validato questo riepilogo. Confermalo prima della scadenza.';

  @override
  String get checkoutReviewChangesMessage =>
      'Sono state rilevate modifiche. Controllale e accettale esplicitamente per continuare.';

  @override
  String get checkoutConfirmedMessage => 'Riepilogo confermato dal negozio.';

  @override
  String get checkoutExpiredMessage =>
      'Questo riepilogo è scaduto. Validalo di nuovo prima di continuare.';

  @override
  String checkoutQuoteRemaining(String time) {
    return 'Questo riepilogo scade tra $time';
  }

  @override
  String get checkoutChangesTitle => 'Modifiche da controllare';

  @override
  String get checkoutConfirmAction => 'Conferma riepilogo';

  @override
  String get checkoutAcceptChangesAction => 'Accetta le modifiche e conferma';

  @override
  String get checkoutOrderDeferredNotice =>
      'Prima di creare l’ordine, il negozio rivaliderà prezzo, promozione, disponibilità e fascia oraria.';

  @override
  String get checkoutCreateOrderAction => 'Crea ordine';

  @override
  String get checkoutOrderReceiptTitle => 'Ordine confermato';

  @override
  String get checkoutOrderReceiptMessage =>
      'Abbiamo salvato l’ordine con prezzo e modalità confermati dal negozio.';

  @override
  String get checkoutOrderCodeLabel => 'Codice ordine';

  @override
  String checkoutOrderCodeSemantics(String code) {
    return 'Codice ordine $code';
  }

  @override
  String checkoutOrderConfirmedMessage(String code) {
    return 'Ordine $code confermato.';
  }

  @override
  String get checkoutOrderStatusLabel => 'Stato';

  @override
  String get checkoutOrderPlacedAtLabel => 'Creato';

  @override
  String get checkoutOrderAuthoritativeNotice =>
      'Il server ha calcolato e confermato il totale di questa ricevuta. L’ordine cliente non è una vendita fiscale.';

  @override
  String get checkoutOrderConfirmedNotice =>
      'Ordine creato e confermato dal negozio.';

  @override
  String get checkoutContinueShoppingAction => 'Continua gli acquisti';

  @override
  String get checkoutOrderStatusConfirmed => 'Confermato';

  @override
  String get checkoutOrderStatusAccepted => 'Accettato';

  @override
  String get checkoutOrderStatusRejected => 'Rifiutato';

  @override
  String get checkoutOrderStatusPreparing => 'In preparazione';

  @override
  String get checkoutOrderStatusReady => 'Pronto';

  @override
  String get checkoutOrderStatusOutForDelivery => 'In consegna';

  @override
  String get checkoutOrderStatusCompleted => 'Completato';

  @override
  String get checkoutOrderStatusCancelled => 'Annullato';

  @override
  String get checkoutRestoredNotice =>
      'Il tuo avanzamento nel checkout è stato ripristinato.';

  @override
  String get checkoutQuoteChangedNotice =>
      'Il negozio ha aggiornato il riepilogo. Controlla le modifiche.';

  @override
  String get checkoutConfirmedNotice => 'Checkout confermato.';

  @override
  String get checkoutPriceChanged => 'Il prezzo di un prodotto è cambiato.';

  @override
  String get checkoutPromotionChanged =>
      'Una promozione è cambiata o terminata.';

  @override
  String get checkoutProductUnavailable => 'Un prodotto non è più disponibile.';

  @override
  String get checkoutHoldRequired =>
      'Questa prenotazione richiede una disponibilità riservata attiva.';

  @override
  String get checkoutOfflineError =>
      'Sei offline. Conserviamo carrello e avanzamento, ma non confermiamo un nuovo checkout.';

  @override
  String get checkoutTimeoutError =>
      'La risposta è ambigua. Riprova con la stessa operazione per recuperare il risultato effettivo.';

  @override
  String get checkoutUnauthorizedError =>
      'La sessione non consente più di confermare il checkout. Accedi di nuovo.';

  @override
  String get checkoutInvalidError => 'La selezione del checkout non è valida.';

  @override
  String get checkoutUnavailableError =>
      'Il negozio non può offrire il checkout in questo momento.';

  @override
  String get checkoutConflictError =>
      'Questa operazione non corrisponde al tentativo precedente. Avvia una nuova validazione.';

  @override
  String get checkoutStaleCartError =>
      'Il carrello è cambiato. Lo aggiorniamo prima di validare di nuovo.';

  @override
  String get checkoutInvalidAddressError =>
      'L’indirizzo non esiste o non appartiene a questo account.';

  @override
  String get checkoutUnsupportedZoneError =>
      'L’indirizzo è fuori dalla zona di consegna selezionata.';

  @override
  String get checkoutSlotUnavailableError =>
      'La fascia oraria o la modalità non sono più disponibili.';

  @override
  String get checkoutPaymentUnavailableError =>
      'Il metodo di pagamento non è più disponibile. Scegli un\'opzione abilitata e riprova.';

  @override
  String get checkoutCartUnavailableError =>
      'Controlla il carrello: è vuoto o contiene prodotti non disponibili.';

  @override
  String get checkoutExpiredError =>
      'Il riepilogo è scaduto e deve essere validato di nuovo.';

  @override
  String get checkoutNotFoundError =>
      'Il riepilogo non esiste più o non appartiene a questo account.';

  @override
  String get checkoutUnexpectedError =>
      'Non è stato possibile verificare il checkout. Non mostriamo prezzi o conferme dedotte.';

  @override
  String get ordersAccountTitle => 'I miei ordini';

  @override
  String get ordersAccountDescription =>
      'Consulta stati, dettagli e ritiri o consegne dei tuoi ordini.';

  @override
  String get ordersAccountAction => 'Vedi ordini';

  @override
  String get ordersTitle => 'I miei ordini';

  @override
  String get ordersRefreshTooltip => 'Aggiorna ordini';

  @override
  String get ordersLoading => 'Caricamento ordini…';

  @override
  String get ordersOffline =>
      'Sei offline. Mostriamo una copia in sola lettura salvata su questo dispositivo.';

  @override
  String get ordersEmptyTitle => 'Non hai ancora ordini';

  @override
  String get ordersEmptyMessage =>
      'Dopo aver confermato un acquisto potrai seguirlo da qui.';

  @override
  String get ordersError => 'Non è stato possibile caricare gli ordini.';

  @override
  String get ordersRetry => 'Riprova';

  @override
  String get ordersLoadMore => 'Carica altro';

  @override
  String ordersItemCount(int count) {
    return '$count prodotti';
  }

  @override
  String ordersCardSemantics(String code, String status, String total) {
    return 'Ordine $code, stato $status, totale $total.';
  }

  @override
  String ordersPlacedAt(String date) {
    return 'Creato $date';
  }

  @override
  String ordersUpdatedAt(String date) {
    return 'Aggiornato $date';
  }

  @override
  String ordersCachedAt(String date) {
    return 'Copia salvata $date';
  }

  @override
  String get ordersTotalLabel => 'Totale';

  @override
  String get ordersDetailTitle => 'Dettaglio ordine';

  @override
  String get ordersProductsTitle => 'Prodotti';

  @override
  String get ordersFulfillmentTitle => 'Modalità e fascia';

  @override
  String get ordersTimelineTitle => 'Stato dell’ordine';

  @override
  String get ordersCancelAction => 'Annulla ordine';

  @override
  String get ordersCancelConfirmTitle => 'Annullare questo ordine?';

  @override
  String get ordersCancelConfirmMessage =>
      'Il negozio verificherà nuovamente stato e termine prima di annullare. Questa azione non crea né annulla una vendita fiscale.';

  @override
  String get ordersCancelSuccess =>
      'Ordine annullato. La disponibilità riservata è stata liberata.';

  @override
  String get ordersCancelNotAllowed =>
      'Questo ordine non può più essere annullato.';

  @override
  String get ordersCancelVersionConflict =>
      'Lo stato è cambiato. Aggiorna l’ordine prima di riprovare.';

  @override
  String get ordersCancelAmbiguous =>
      'La risposta è ambigua. Conserviamo lo stesso tentativo per verificarlo in sicurezza al prossimo retry.';

  @override
  String get ordersUnauthorized =>
      'Accedi di nuovo per consultare i tuoi ordini.';

  @override
  String get ordersNotFound =>
      'L’ordine non esiste in questo negozio o non appartiene a questo account.';

  @override
  String get ordersUnexpected =>
      'Non è stato possibile verificare l’ordine. La copia salvata resta in sola lettura.';

  @override
  String ordersCancellationDeadline(String date) {
    return 'Puoi annullare entro $date';
  }

  @override
  String get ordersDetailRefresh => 'Aggiorna dettaglio';

  @override
  String get ordersBackToOrders => 'Torna ai miei ordini';
}
