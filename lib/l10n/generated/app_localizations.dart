import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_it.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('it'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ];

  /// Diagnóstico visible solo en builds debug de development sin backend configurado.
  ///
  /// In es, this message translates to:
  /// **'Backend no configurado: modo de desarrollo sin conexión.'**
  String get backendNotConfigured;

  /// No description provided for @backendChecking.
  ///
  /// In es, this message translates to:
  /// **'Comprobando la conexión de la tienda…'**
  String get backendChecking;

  /// No description provided for @backendOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Puedes seguir explorando y volver a intentarlo.'**
  String get backendOffline;

  /// No description provided for @backendUnavailable.
  ///
  /// In es, this message translates to:
  /// **'La tienda no está disponible por el momento.'**
  String get backendUnavailable;

  /// No description provided for @backendAuthenticationRequired.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión desde Cuenta para continuar.'**
  String get backendAuthenticationRequired;

  /// No description provided for @backendRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get backendRetry;

  /// Etiqueta de la navegación hacia Inicio.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navigationHome;

  /// Etiqueta de la navegación hacia el catálogo.
  ///
  /// In es, this message translates to:
  /// **'Catálogo'**
  String get navigationCatalog;

  /// Etiqueta de la navegación hacia el carrito.
  ///
  /// In es, this message translates to:
  /// **'Carrito'**
  String get navigationCart;

  /// Etiqueta de la navegación hacia la cuenta.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get navigationAccount;

  /// Título de la pantalla Inicio.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get homeTitle;

  /// Estado temporal de Inicio mientras no hay contenido público.
  ///
  /// In es, this message translates to:
  /// **'Pronto podrás descubrir aquí las novedades de la tienda.'**
  String get homeFoundationMessage;

  /// Título de la pantalla Catálogo.
  ///
  /// In es, this message translates to:
  /// **'Catálogo'**
  String get catalogTitle;

  /// Estado temporal del catálogo antes de su conexión.
  ///
  /// In es, this message translates to:
  /// **'El catálogo estará disponible aquí próximamente.'**
  String get catalogFoundationMessage;

  /// Título de la pantalla Carrito.
  ///
  /// In es, this message translates to:
  /// **'Carrito'**
  String get cartTitle;

  /// Estado temporal del carrito antes de que existan productos.
  ///
  /// In es, this message translates to:
  /// **'Tu carrito estará disponible cuando puedas elegir productos.'**
  String get cartFoundationMessage;

  /// Título de la pantalla Cuenta.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get accountTitle;

  /// Estado temporal de la cuenta antes de habilitar el acceso.
  ///
  /// In es, this message translates to:
  /// **'Podrás acceder a tu cuenta cuando esta función esté disponible.'**
  String get accountFoundationMessage;

  /// Título de bienvenida de Inicio.
  ///
  /// In es, this message translates to:
  /// **'Todo listo para empezar a explorar'**
  String get homeWelcomeTitle;

  /// Mensaje de bienvenida honesto mientras el catálogo aún no contiene datos.
  ///
  /// In es, this message translates to:
  /// **'Recorre las secciones de la tienda mientras preparamos el catálogo.'**
  String get homeWelcomeMessage;

  /// Etiqueta accesible del acceso a búsqueda en Inicio.
  ///
  /// In es, this message translates to:
  /// **'Buscar en la tienda'**
  String get homeSearchLabel;

  /// Texto orientativo del acceso a búsqueda en Inicio.
  ///
  /// In es, this message translates to:
  /// **'¿Qué estás buscando?'**
  String get homeSearchHint;

  /// Título de la sección de categorías de Inicio.
  ///
  /// In es, this message translates to:
  /// **'Explora por categoría'**
  String get homeCategoriesTitle;

  /// Estado vacío de categorías sin inventar contenido comercial.
  ///
  /// In es, this message translates to:
  /// **'Las categorías aparecerán cuando el catálogo esté disponible.'**
  String get homeCategoriesMessage;

  /// Acción para abrir la vista de categorías del catálogo.
  ///
  /// In es, this message translates to:
  /// **'Ver categorías'**
  String get homeExploreCategories;

  /// Título de la futura sección de ofertas.
  ///
  /// In es, this message translates to:
  /// **'Ofertas'**
  String get homeOffersTitle;

  /// Título del estado vacío de ofertas.
  ///
  /// In es, this message translates to:
  /// **'Ofertas, próximamente'**
  String get homeOffersEmptyTitle;

  /// Mensaje del estado vacío de ofertas, sin promociones ficticias.
  ///
  /// In es, this message translates to:
  /// **'Aquí mostraremos ofertas reales cuando estén disponibles.'**
  String get homeOffersEmptyMessage;

  /// Título de la futura sección de productos destacados.
  ///
  /// In es, this message translates to:
  /// **'Productos destacados'**
  String get homeFeaturedTitle;

  /// Título del estado vacío de productos destacados.
  ///
  /// In es, this message translates to:
  /// **'Destacados, próximamente'**
  String get homeFeaturedEmptyTitle;

  /// Mensaje del estado vacío de destacados, sin productos ficticios.
  ///
  /// In es, this message translates to:
  /// **'Esta sección mostrará productos reales cuando el catálogo esté disponible.'**
  String get homeFeaturedEmptyMessage;

  /// Acción principal para abrir el catálogo.
  ///
  /// In es, this message translates to:
  /// **'Explorar catálogo'**
  String get homeExploreCatalog;

  /// Etiqueta accesible del control de búsqueda del catálogo.
  ///
  /// In es, this message translates to:
  /// **'Buscar en el catálogo'**
  String get catalogSearchLabel;

  /// Texto orientativo del control de búsqueda del catálogo.
  ///
  /// In es, this message translates to:
  /// **'Busca productos o categorías'**
  String get catalogSearchHint;

  /// Etiqueta del futuro control de filtros.
  ///
  /// In es, this message translates to:
  /// **'Filtrar'**
  String get catalogFilterLabel;

  /// Etiqueta del futuro control de orden.
  ///
  /// In es, this message translates to:
  /// **'Ordenar'**
  String get catalogSortLabel;

  /// Explica por qué los controles futuros aún no están habilitados.
  ///
  /// In es, this message translates to:
  /// **'Los filtros y el orden estarán disponibles con el catálogo.'**
  String get catalogControlsUnavailable;

  /// Título del estado de conexión del catálogo.
  ///
  /// In es, this message translates to:
  /// **'Preparando el catálogo'**
  String get catalogConnectingTitle;

  /// Mensaje del estado de conexión del catálogo.
  ///
  /// In es, this message translates to:
  /// **'Estamos comprobando si la tienda está disponible.'**
  String get catalogConnectingMessage;

  /// Título del catálogo vacío.
  ///
  /// In es, this message translates to:
  /// **'Catálogo público aún no conectado'**
  String get catalogEmptyTitle;

  /// Mensaje del catálogo vacío.
  ///
  /// In es, this message translates to:
  /// **'Podrás explorar productos cuando la tienda publique su catálogo.'**
  String get catalogEmptyMessage;

  /// Título del estado sin conexión del catálogo.
  ///
  /// In es, this message translates to:
  /// **'Estás sin conexión'**
  String get catalogOfflineTitle;

  /// Mensaje recuperable del catálogo sin conexión.
  ///
  /// In es, this message translates to:
  /// **'Comprueba tu conexión y vuelve a intentarlo. El resto de la app sigue disponible.'**
  String get catalogOfflineMessage;

  /// Título del estado de servicio no disponible.
  ///
  /// In es, this message translates to:
  /// **'La tienda no está disponible'**
  String get catalogUnavailableTitle;

  /// Mensaje temporal de servicio no disponible.
  ///
  /// In es, this message translates to:
  /// **'No podemos preparar el catálogo público por el momento.'**
  String get catalogUnavailableMessage;

  /// Título del estado de error recuperable.
  ///
  /// In es, this message translates to:
  /// **'No pudimos comprobar la tienda'**
  String get catalogRetryTitle;

  /// Mensaje del estado de error recuperable.
  ///
  /// In es, this message translates to:
  /// **'Inténtalo de nuevo. También puedes seguir explorando otras secciones.'**
  String get catalogRetryMessage;

  /// Título del carrito vacío.
  ///
  /// In es, this message translates to:
  /// **'Tu carrito está vacío'**
  String get cartEmptyTitle;

  /// Mensaje del carrito vacío sin prometer precios ni disponibilidad.
  ///
  /// In es, this message translates to:
  /// **'Cuando el catálogo esté disponible, podrás agregar productos aquí.'**
  String get cartEmptyMessage;

  /// Acción del carrito vacío para abrir el catálogo.
  ///
  /// In es, this message translates to:
  /// **'Explorar catálogo'**
  String get cartExploreCatalog;

  /// Título de Cuenta para una persona invitada.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta'**
  String get accountGuestTitle;

  /// Explica el beneficio del acceso sin bloquear la navegación invitada.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para acceder a funciones personales. Puedes seguir explorando sin una cuenta.'**
  String get accountGuestBenefit;

  /// Acción de autenticación con Google.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get accountContinueWithGoogle;

  /// Aviso honesto cuando la autenticación aún no está habilitada.
  ///
  /// In es, this message translates to:
  /// **'El acceso con Google estará disponible próximamente.'**
  String get accountGoogleComingSoon;

  /// Acción para continuar la navegación pública sin iniciar sesión.
  ///
  /// In es, this message translates to:
  /// **'Seguir explorando como invitado'**
  String get accountBrowseAsGuest;

  /// Título de Cuenta para una sesión autenticada.
  ///
  /// In es, this message translates to:
  /// **'Sesión iniciada'**
  String get accountAuthenticatedTitle;

  /// Nombre seguro cuando el perfil autenticado no incluye uno.
  ///
  /// In es, this message translates to:
  /// **'Cliente'**
  String get accountNameFallback;

  /// Texto seguro cuando la sesión no incluye correo.
  ///
  /// In es, this message translates to:
  /// **'Correo no disponible'**
  String get accountEmailFallback;

  /// Confirmación breve de sesión autenticada.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión está activa.'**
  String get accountSessionActive;

  /// Acción para cerrar la sesión.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get accountLogout;

  /// Etiqueta accesible del avatar de la cuenta.
  ///
  /// In es, this message translates to:
  /// **'Avatar de {name}'**
  String accountAvatarLabel(String name);

  /// Etiqueta breve para funciones futuras no habilitadas.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get storefrontComingSoonLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'it', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'it':
      return AppLocalizationsIt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
