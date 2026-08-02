// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get backendNotConfigured =>
      'Backend not configured: offline development mode.';

  @override
  String get backendChecking => 'Checking the store connection…';

  @override
  String get backendOffline =>
      'You\'re offline. You can keep browsing and try again.';

  @override
  String get backendUnavailable => 'The store is temporarily unavailable.';

  @override
  String get backendAuthenticationRequired =>
      'Sign in from Account to continue.';

  @override
  String get backendRetry => 'Try again';

  @override
  String storefrontCacheFresh(String date) {
    return 'Saved copy updated $date.';
  }

  @override
  String storefrontCacheStale(String date) {
    return 'Saved copy from $date. Prices and availability may have changed.';
  }

  @override
  String get storefrontCacheRefreshing => 'Updating in the background…';

  @override
  String get navigationHome => 'Home';

  @override
  String get navigationCatalog => 'Catalog';

  @override
  String get navigationCart => 'Cart';

  @override
  String get navigationAccount => 'Account';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeFoundationMessage =>
      'You will soon be able to discover what\'s new at the store here.';

  @override
  String get catalogTitle => 'Catalog';

  @override
  String get catalogFoundationMessage =>
      'The catalog will be available here soon.';

  @override
  String get cartTitle => 'Cart';

  @override
  String get cartFoundationMessage =>
      'Your cart will be available when you can choose products.';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountFoundationMessage =>
      'You can access your account when this feature is available.';

  @override
  String get homeWelcomeTitle => 'Everything is ready to start exploring';

  @override
  String get homeWelcomeMessage =>
      'Browse the store sections while we prepare the catalog.';

  @override
  String get homeSearchLabel => 'Search the store';

  @override
  String get homeSearchHint => 'What are you looking for?';

  @override
  String get homeCategoriesTitle => 'Explore by category';

  @override
  String get homeCategoriesMessage =>
      'Categories will appear when the catalog is available.';

  @override
  String get homeExploreCategories => 'View categories';

  @override
  String get homeOffersTitle => 'Offers';

  @override
  String get homeOffersEmptyTitle => 'Offers, coming soon';

  @override
  String get homeOffersEmptyMessage =>
      'Real offers will appear here when they are available.';

  @override
  String get homeFeaturedTitle => 'Featured products';

  @override
  String get homeFeaturedEmptyTitle => 'Featured products, coming soon';

  @override
  String get homeFeaturedEmptyMessage =>
      'This section will show real products when the catalog is available.';

  @override
  String get homeExploreCatalog => 'Explore catalog';

  @override
  String get homeLoadingTitle => 'Loading the store';

  @override
  String get homeLoadingMessage =>
      'We are preparing categories, offers, and featured products.';

  @override
  String get homeLoadErrorTitle => 'We could not load the store';

  @override
  String get homeLoadErrorMessage => 'Check your connection and try again.';

  @override
  String get homeUnavailableTitle => 'The store is unavailable';

  @override
  String get homeUnavailableMessage =>
      'The public catalog is not available right now.';

  @override
  String get homeImageUnavailable => 'Image unavailable';

  @override
  String homePreviousPrice(String price) {
    return 'Previously $price';
  }

  @override
  String homeDiscountPercent(String percent) {
    return '$percent% off';
  }

  @override
  String get catalogSearchLabel => 'Search the catalog';

  @override
  String get catalogSearchHint => 'Search products or categories';

  @override
  String get catalogSearchMinimum => 'Enter at least 2 characters to search.';

  @override
  String get catalogClearSearch => 'Clear search';

  @override
  String get catalogFilterLabel => 'Filter';

  @override
  String get catalogSortLabel => 'Sort';

  @override
  String get catalogControlsUnavailable =>
      'Search, filters, and sorting will be available in the next step.';

  @override
  String get catalogFiltersLabel => 'Catalog filters';

  @override
  String get catalogFiltersUnavailableDuringSearch =>
      'While searching, you can filter by category. Clear the search to use availability, discounts, or sorting.';

  @override
  String get catalogAvailabilityLabel => 'Availability';

  @override
  String get catalogAvailabilityAll => 'All';

  @override
  String get catalogAvailabilityAvailable => 'Available';

  @override
  String get catalogAvailabilityLowStock => 'Low stock';

  @override
  String get catalogAvailabilityUnavailable => 'Unavailable';

  @override
  String get catalogAvailabilityReservationOnly => 'Reservation only';

  @override
  String get catalogAvailabilityPickupOnly => 'Pickup only';

  @override
  String get catalogAvailabilityDeliveryOnly => 'Delivery only';

  @override
  String get catalogDiscountedOnly => 'Discounted only';

  @override
  String get catalogSortCatalog => 'Catalog order';

  @override
  String get catalogSortName => 'Name';

  @override
  String get catalogSortPriceAscending => 'Price: low to high';

  @override
  String get catalogSortPriceDescending => 'Price: high to low';

  @override
  String get catalogResetFilters => 'Reset filters';

  @override
  String get productDetailTitle => 'Product details';

  @override
  String get productDetailLoading => 'Loading product';

  @override
  String get productDetailUnavailableTitle => 'Product unavailable';

  @override
  String get productDetailUnavailableMessage =>
      'This product is not published or is no longer available.';

  @override
  String get productDetailOfflineTitle => 'You\'re offline';

  @override
  String get productDetailOfflineMessage =>
      'Connect to the internet to load the latest product details.';

  @override
  String get productDetailErrorTitle => 'We couldn\'t load the product';

  @override
  String get productDetailErrorMessage =>
      'Try again. No incomplete data was shown.';

  @override
  String get productDetailDescriptionLabel => 'Description';

  @override
  String get productDetailNoDescription =>
      'No public description is available.';

  @override
  String get productDetailCategoryLabel => 'Category';

  @override
  String get productDetailBrandLabel => 'Brand';

  @override
  String get productDetailPriceLabel => 'Price';

  @override
  String get productDetailAvailabilityLabel => 'Commercial availability';

  @override
  String get productDetailFulfillmentLabel => 'Purchase options';

  @override
  String get productDetailPickup => 'Store pickup';

  @override
  String get productDetailDelivery => 'Delivery';

  @override
  String get productDetailReservation => 'Reservation';

  @override
  String get productDetailPromotionLabel => 'Active promotion';

  @override
  String get catalogCategoriesLabel => 'Categories';

  @override
  String get catalogAllCategories => 'All';

  @override
  String get catalogLoadingMore => 'Loading more products';

  @override
  String get catalogLoadMoreError => 'We couldn\'t load more products';

  @override
  String get catalogConnectingTitle => 'Preparing the catalog';

  @override
  String get catalogConnectingMessage =>
      'We\'re checking whether the store is available.';

  @override
  String get catalogEmptyTitle => 'No published products';

  @override
  String get catalogEmptyMessage => 'Try another category or come back later.';

  @override
  String get catalogOfflineTitle => 'You\'re offline';

  @override
  String get catalogOfflineMessage =>
      'Check your connection and try again. The rest of the app remains available.';

  @override
  String get catalogUnavailableTitle => 'The store is unavailable';

  @override
  String get catalogUnavailableMessage =>
      'We can\'t prepare the public catalog right now.';

  @override
  String get catalogRetryTitle => 'We couldn\'t check the store';

  @override
  String get catalogRetryMessage =>
      'Try again. You can also keep exploring other sections.';

  @override
  String get cartEmptyTitle => 'Your cart is empty';

  @override
  String get cartEmptyMessage =>
      'When the catalog is available, you\'ll be able to add products here.';

  @override
  String get cartExploreCatalog => 'Explore catalog';

  @override
  String get accountGuestTitle => 'Your account';

  @override
  String get accountGuestBenefit =>
      'Sign in to use personal features. You can keep browsing without an account.';

  @override
  String get accountContinueWithGoogle => 'Continue with Google';

  @override
  String get accountGoogleComingSoon =>
      'Google sign-in will be available soon.';

  @override
  String get accountBrowseAsGuest => 'Keep browsing as a guest';

  @override
  String get accountAuthenticatedTitle => 'Signed in';

  @override
  String get accountNameFallback => 'Customer';

  @override
  String get accountEmailFallback => 'Email unavailable';

  @override
  String get accountSessionActive => 'Your session is active.';

  @override
  String get accountLogout => 'Sign out';

  @override
  String get accountSigningInTitle => 'Opening secure sign-in';

  @override
  String get accountSigningInMessage =>
      'Complete sign-in in the browser, then return to the app.';

  @override
  String get accountCancelSignIn => 'Cancel sign-in';

  @override
  String get accountCancellingTitle => 'Cancelling sign-in';

  @override
  String get accountCancellingMessage =>
      'We\'re safely closing this sign-in attempt.';

  @override
  String get accountCancelledTitle => 'Sign-in cancelled';

  @override
  String get accountCancelledMessage =>
      'No changes were made to your account. You can try again.';

  @override
  String get accountRetry => 'Try again';

  @override
  String get accountAuthErrorTitle => 'We couldn\'t sign you in';

  @override
  String get accountConfigurationErrorTitle => 'Sign-in unavailable';

  @override
  String get accountSigningOut => 'Signing out…';

  @override
  String get accountAuthOffline => 'Check your connection and try again.';

  @override
  String get accountAuthProviderUnavailable =>
      'Google is temporarily unavailable. Try again later.';

  @override
  String get accountAuthBrowserLaunchFailed =>
      'We couldn\'t open the browser to continue.';

  @override
  String get accountAuthInvalidCallback =>
      'The sign-in return was invalid. Start a new attempt.';

  @override
  String get accountAuthSessionExpired =>
      'Your session ended. Sign in again whenever you\'re ready.';

  @override
  String get accountAuthSecureStorageUnavailable =>
      'This device can\'t protect the session securely.';

  @override
  String get accountAuthConfiguration =>
      'Google sign-in isn\'t configured for this environment.';

  @override
  String get accountAuthUnexpected =>
      'Something unexpected happened. You can try again.';

  @override
  String accountAvatarLabel(String name) {
    return 'Avatar for $name';
  }

  @override
  String get storefrontComingSoonLabel => 'Coming soon';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get favoritesOpen => 'View favorites';

  @override
  String get favoritesEmptyTitle => 'No favorites yet';

  @override
  String get favoritesEmptyMessage =>
      'Save products to find them quickly, even when offline.';

  @override
  String get favoritesErrorTitle => 'We couldn\'t open your favorites';

  @override
  String get favoritesErrorMessage =>
      'Try again. Your selections stay on this device.';

  @override
  String get favoriteAdd => 'Add to favorites';

  @override
  String get favoriteRemove => 'Remove from favorites';

  @override
  String get favoriteAdded => 'Product added to favorites.';

  @override
  String get favoriteRemoved => 'Product removed from favorites.';

  @override
  String get favoriteUnavailableTitle => 'Product unavailable';

  @override
  String get favoriteUnavailableMessage =>
      'You can keep this favorite or remove it from the list.';

  @override
  String get productShare => 'Share product';

  @override
  String productShareText(String name, String uri) {
    return 'See $name in Merchandise Control:\n$uri';
  }

  @override
  String get productShareError => 'We couldn\'t open the sharing options.';
}
