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
}
