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
}
