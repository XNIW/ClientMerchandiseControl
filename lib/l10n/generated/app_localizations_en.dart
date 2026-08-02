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
  String catalogLoadedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products loaded',
      one: '1 product loaded',
      zero: 'No products loaded',
    );
    return '$_temp0';
  }

  @override
  String get catalogShowFilters => 'Show filters';

  @override
  String get catalogHideFilters => 'Hide filters';

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
  String productDetailSavings(String amount) {
    return 'You save $amount';
  }

  @override
  String productDetailImagePosition(int current, int total) {
    return 'Image $current of $total';
  }

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

  @override
  String get customerAccountLoading => 'Loading your account data';

  @override
  String get customerAccountRetry => 'Try again';

  @override
  String get customerAccountOffline =>
      'You\'re offline. We kept the data already loaded; reconnect before saving changes.';

  @override
  String get customerAccountUnauthorized =>
      'Your session no longer allows this action. Sign in again.';

  @override
  String get customerAccountInvalid =>
      'Review the information you entered before continuing.';

  @override
  String get customerAccountConflict =>
      'This data changed elsewhere. Refresh and try again.';

  @override
  String get customerAccountTimeout =>
      'The action took too long. You can retry without duplicating it.';

  @override
  String get customerAccountUnavailable =>
      'Your account data is temporarily unavailable.';

  @override
  String get customerAccountUnexpected =>
      'We couldn\'t complete the action. Your changes are not shown as confirmed.';

  @override
  String get customerProfileTitle => 'Profile';

  @override
  String get customerProfileDescription =>
      'Choose how you appear and the language used by the app.';

  @override
  String get customerProfileNameLabel => 'Display name';

  @override
  String get customerProfileNameHint => 'Optional';

  @override
  String get customerProfileLanguageLabel => 'Language';

  @override
  String get customerProfileLanguageEsCl => 'Español (Chile)';

  @override
  String get customerProfileLanguageIt => 'Italiano';

  @override
  String get customerProfileLanguageEn => 'English';

  @override
  String get customerProfileLanguageZhHans => '简体中文';

  @override
  String get customerProfileSave => 'Save profile';

  @override
  String get customerProfileSaved => 'Profile saved.';

  @override
  String get customerProfileDeleted => 'Your public profile data was reset.';

  @override
  String get customerProfileResetTitle => 'Reset profile';

  @override
  String get customerProfileResetMessage =>
      'This removes your saved name, language, and profile consent. Your addresses and sign-in stay unchanged.';

  @override
  String get customerProfileResetAction => 'Reset';

  @override
  String get customerAddressesTitle => 'Addresses';

  @override
  String get customerAddressesDescription =>
      'Save postal details for later. Delivery availability is checked during checkout.';

  @override
  String get customerAddressesEmptyTitle => 'No addresses yet';

  @override
  String get customerAddressesEmptyMessage =>
      'Add an address whenever you want to prepare a delivery.';

  @override
  String get customerAddressAdd => 'Add address';

  @override
  String get customerAddressEdit => 'Edit address';

  @override
  String get customerAddressDeleteTitle => 'Delete address';

  @override
  String customerAddressDeleteMessage(String label) {
    return 'Delete the address “$label”?';
  }

  @override
  String get customerAddressDeleteAction => 'Delete';

  @override
  String get customerAddressSaved => 'Address saved.';

  @override
  String get customerAddressDeleted => 'Address deleted.';

  @override
  String get customerAddressDefault => 'Default';

  @override
  String get customerAddressSetDefault => 'Set as default';

  @override
  String get customerAddressDefaultChanged => 'Default address updated.';

  @override
  String get customerAddressLabel => 'Label';

  @override
  String get customerAddressRecipient => 'Recipient name';

  @override
  String get customerAddressLine1 => 'Address';

  @override
  String get customerAddressLine2 =>
      'Apartment, office, or reference (optional)';

  @override
  String get customerAddressCommune => 'District or commune';

  @override
  String get customerAddressRegion => 'Region';

  @override
  String get customerAddressPostalCode => 'Postal code (optional)';

  @override
  String get customerAddressCountryCode => 'Country code';

  @override
  String get customerAddressInstructions => 'Delivery instructions (optional)';

  @override
  String customerAddressSemantics(
    String label,
    String address,
    String commune,
  ) {
    return 'Address $label: $address, $commune';
  }

  @override
  String get customerPrivacyTitle => 'Privacy and data';

  @override
  String get customerPrivacyDescription =>
      'You control consent and can view a copy of the Storefront data linked to your account.';

  @override
  String get customerPrivacyConsentTitle => 'Privacy consent';

  @override
  String get customerPrivacyConsentDescription =>
      'Record or withdraw acceptance of the current version. It is never enabled implicitly.';

  @override
  String get customerPrivacyConsentUpdated => 'Privacy preference updated.';

  @override
  String get customerDataExportAction => 'View my data export';

  @override
  String get customerDataExportTitle => 'Your Storefront data';

  @override
  String get customerDeletionTitle => 'Account deletion';

  @override
  String get customerDeletionDescription =>
      'You can submit a reviewable deletion request. The app does not erase your account immediately.';

  @override
  String get customerDeletionPending =>
      'Your request is pending and will be handled under the retention policy.';

  @override
  String get customerDeletionConfirmTitle => 'Request account deletion';

  @override
  String get customerDeletionConfirmMessage =>
      'The request will be recorded for review. Your session will stay open and data will not be erased immediately.';

  @override
  String get customerDeletionRequestAction => 'Request deletion';

  @override
  String get customerDeletionCancelAction => 'Cancel request';

  @override
  String get customerDeletionRequested => 'Deletion request recorded.';

  @override
  String get customerDeletionCancelled => 'Deletion request cancelled.';

  @override
  String get customerDialogCancel => 'Cancel';

  @override
  String get customerDialogSave => 'Save';

  @override
  String get customerDialogClose => 'Close';

  @override
  String get customerFieldRequired => 'This field is required.';

  @override
  String get customerFieldInvalid => 'Review this field\'s format and length.';

  @override
  String get customerNotificationsTitle => 'Notifications';

  @override
  String get customerNotificationsDescription =>
      'Choose whether to receive essential order and reservation updates. System permission is requested separately.';

  @override
  String get customerNotificationsLoading => 'Loading notification settings';

  @override
  String get customerNotificationsProviderUnavailable =>
      'Push notifications are not configured in this build. No token was registered and no permission was simulated.';

  @override
  String get customerNotificationsActive =>
      'Notifications are active and confirmed by the server.';

  @override
  String get customerNotificationsNotRequested =>
      'You have not chosen whether to receive notifications yet.';

  @override
  String get customerNotificationsDenied =>
      'You chose not to receive notifications. You can change this preference at any time.';

  @override
  String get customerNotificationsRevoked =>
      'Notifications are revoked for this installation.';

  @override
  String get customerNotificationsPending =>
      'The change is saved on this device but has not been confirmed by the server yet.';

  @override
  String get customerNotificationsOffline =>
      'We cannot confirm the change while you are offline. Retry when your connection returns.';

  @override
  String get customerNotificationsTimeout =>
      'The server took too long. You can retry without duplicating the idempotent operation.';

  @override
  String get customerNotificationsUnauthorized =>
      'Your session can no longer update notification settings.';

  @override
  String get customerNotificationsInvalid =>
      'The notification configuration is invalid.';

  @override
  String get customerNotificationsConflict =>
      'The idempotent operation does not match the earlier request. Refresh and retry.';

  @override
  String get customerNotificationsUnavailable =>
      'We could not update notifications. The change is not shown as confirmed.';

  @override
  String get customerNotificationsEnable => 'Enable';

  @override
  String get customerNotificationsNotNow => 'Not now';

  @override
  String get customerNotificationsRevoke => 'Revoke';

  @override
  String get customerNotificationsRetry => 'Retry';

  @override
  String get cartAddAction => 'Add to cart';

  @override
  String get cartAddedNotice => 'Product added to cart.';

  @override
  String get cartGuestSyncMessage =>
      'Your cart is saved on this device and works offline.';

  @override
  String get cartAccountSyncMessage =>
      'Your cart is linked to your account and validated with the store.';

  @override
  String cartIndicativeSubtotal(String price) {
    return 'Estimated subtotal: $price';
  }

  @override
  String cartConfirmedSubtotal(String price) {
    return 'Validated subtotal: $price';
  }

  @override
  String get cartRevalidateAction => 'Validate cart';

  @override
  String get cartEstimatedLabel => 'Estimated';

  @override
  String get cartValidatedLabel => 'Validated';

  @override
  String get cartRetryAction => 'Retry';

  @override
  String get cartClearAction => 'Clear cart';

  @override
  String get cartClearTitle => 'Clear the cart?';

  @override
  String get cartClearMessage => 'All products will be removed from this cart.';

  @override
  String get cartRemoveAction => 'Remove';

  @override
  String cartQuantityLabel(int quantity) {
    return 'Quantity: $quantity';
  }

  @override
  String get cartDecreaseQuantity => 'Decrease quantity';

  @override
  String get cartIncreaseQuantity => 'Increase quantity';

  @override
  String get cartUnavailableLine => 'This product is no longer available.';

  @override
  String get cartPriceChangedLine =>
      'The price changed. Review the current amount.';

  @override
  String get cartPromotionChangedLine =>
      'The promotion changed. Review the current amount.';

  @override
  String get cartMergedNotice =>
      'This device\'s cart was synced with your account.';

  @override
  String get cartPartialMergeNotice =>
      'Available products were synced; the others remain for your review.';

  @override
  String get cartRevalidatedNotice =>
      'Prices and availability validated by the store.';

  @override
  String get cartUpdatedNotice => 'Quantity updated.';

  @override
  String get cartRemovedNotice => 'Product removed from cart.';

  @override
  String get cartClearedNotice => 'Cart cleared.';

  @override
  String get cartOfflineError =>
      'You are offline. Your local cart is still available.';

  @override
  String get cartTimeoutError =>
      'The store took too long. Retry without duplicating the operation.';

  @override
  String get cartUnauthorizedError => 'Sign in again to sync the cart.';

  @override
  String get cartConflictError =>
      'The cart changed elsewhere. Refresh and try again.';

  @override
  String get cartUnavailableError => 'We cannot update the cart right now.';

  @override
  String get cartInvalidError => 'The cart request is invalid.';

  @override
  String get cartLimitReached =>
      'The cart reached its maximum number of distinct products.';

  @override
  String get cartProductUnavailable => 'This product can no longer be added.';

  @override
  String get cartSignInAction => 'Sign in';

  @override
  String get cartPendingRetry => 'A pending operation can be retried safely.';

  @override
  String get cartPriceDisclaimer =>
      'Prices and availability will be confirmed again before the order is created.';

  @override
  String cartLineSemantics(String name, int quantity, String price) {
    return '$name, quantity $quantity, $price';
  }
}
