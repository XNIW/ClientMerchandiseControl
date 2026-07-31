// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get backendNotConfigured =>
      'Backend no configurado: modo de desarrollo sin conexión.';

  @override
  String get backendChecking => 'Comprobando la conexión de la tienda…';

  @override
  String get backendOffline =>
      'Sin conexión. Puedes seguir explorando y volver a intentarlo.';

  @override
  String get backendUnavailable =>
      'La tienda no está disponible por el momento.';

  @override
  String get backendAuthenticationRequired =>
      'Inicia sesión desde Cuenta para continuar.';

  @override
  String get backendRetry => 'Reintentar';

  @override
  String get navigationHome => 'Inicio';

  @override
  String get navigationCatalog => 'Catálogo';

  @override
  String get navigationCart => 'Carrito';

  @override
  String get navigationAccount => 'Cuenta';

  @override
  String get homeTitle => 'Inicio';

  @override
  String get homeFoundationMessage =>
      'Pronto podrás descubrir aquí las novedades de la tienda.';

  @override
  String get catalogTitle => 'Catálogo';

  @override
  String get catalogFoundationMessage =>
      'El catálogo estará disponible aquí próximamente.';

  @override
  String get cartTitle => 'Carrito';

  @override
  String get cartFoundationMessage =>
      'Tu carrito estará disponible cuando puedas elegir productos.';

  @override
  String get accountTitle => 'Cuenta';

  @override
  String get accountFoundationMessage =>
      'Podrás acceder a tu cuenta cuando esta función esté disponible.';
}
