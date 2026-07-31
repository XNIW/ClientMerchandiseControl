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
  String get catalogSearchLabel => 'Search the catalog';

  @override
  String get catalogSearchHint => 'Search products or categories';

  @override
  String get catalogFilterLabel => 'Filter';

  @override
  String get catalogSortLabel => 'Sort';

  @override
  String get catalogControlsUnavailable =>
      'Filters and sorting will be available with the catalog.';

  @override
  String get catalogConnectingTitle => 'Preparing the catalog';

  @override
  String get catalogConnectingMessage =>
      'We\'re checking whether the store is available.';

  @override
  String get catalogEmptyTitle => 'Public catalog not connected yet';

  @override
  String get catalogEmptyMessage =>
      'You can explore products when the store publishes its catalog.';

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
}
