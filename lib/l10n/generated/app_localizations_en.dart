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
      'The storefront foundation is ready. The public catalog will be connected in a later task.';

  @override
  String get catalogTitle => 'Catalog';

  @override
  String get catalogFoundationMessage =>
      'The catalog is not connected yet. Only published products will appear here.';

  @override
  String get cartTitle => 'Cart';

  @override
  String get cartFoundationMessage =>
      'The cart will be implemented after the public price and availability contract.';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountFoundationMessage =>
      'Customer profiles and secure access will be implemented in later tasks.';
}
