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
      'La fondazione del negozio è pronta. Il catalogo pubblico verrà collegato in un task successivo.';

  @override
  String get catalogTitle => 'Catalogo';

  @override
  String get catalogFoundationMessage =>
      'Il catalogo non è ancora collegato. Qui appariranno soltanto prodotti pubblicati.';

  @override
  String get cartTitle => 'Carrello';

  @override
  String get cartFoundationMessage =>
      'Il carrello verrà implementato dopo il contratto pubblico di prezzi e disponibilità.';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountFoundationMessage =>
      'Il profilo cliente e l\'accesso sicuro verranno implementati in task successivi.';
}
