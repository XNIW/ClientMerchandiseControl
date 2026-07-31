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
}
