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

  /// No description provided for @storefrontCacheFresh.
  ///
  /// In es, this message translates to:
  /// **'Copia guardada actualizada el {date}.'**
  String storefrontCacheFresh(String date);

  /// No description provided for @storefrontCacheStale.
  ///
  /// In es, this message translates to:
  /// **'Copia guardada del {date}. Los precios y la disponibilidad pueden haber cambiado.'**
  String storefrontCacheStale(String date);

  /// No description provided for @storefrontCacheRefreshing.
  ///
  /// In es, this message translates to:
  /// **'Actualizando en segundo plano…'**
  String get storefrontCacheRefreshing;

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

  /// No description provided for @homeLoadingTitle.
  ///
  /// In es, this message translates to:
  /// **'Cargando la tienda'**
  String get homeLoadingTitle;

  /// No description provided for @homeLoadingMessage.
  ///
  /// In es, this message translates to:
  /// **'Estamos preparando categorías, ofertas y productos destacados.'**
  String get homeLoadingMessage;

  /// No description provided for @homeLoadErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar la tienda'**
  String get homeLoadErrorTitle;

  /// No description provided for @homeLoadErrorMessage.
  ///
  /// In es, this message translates to:
  /// **'Comprueba tu conexión y vuelve a intentarlo.'**
  String get homeLoadErrorMessage;

  /// No description provided for @homeUnavailableTitle.
  ///
  /// In es, this message translates to:
  /// **'La tienda no está disponible'**
  String get homeUnavailableTitle;

  /// No description provided for @homeUnavailableMessage.
  ///
  /// In es, this message translates to:
  /// **'El catálogo público no está disponible por el momento.'**
  String get homeUnavailableMessage;

  /// No description provided for @homeImageUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Imagen no disponible'**
  String get homeImageUnavailable;

  /// No description provided for @homePreviousPrice.
  ///
  /// In es, this message translates to:
  /// **'Antes {price}'**
  String homePreviousPrice(String price);

  /// No description provided for @homeDiscountPercent.
  ///
  /// In es, this message translates to:
  /// **'{percent}% de descuento'**
  String homeDiscountPercent(String percent);

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

  /// No description provided for @catalogSearchMinimum.
  ///
  /// In es, this message translates to:
  /// **'Escribe al menos 2 caracteres para buscar.'**
  String get catalogSearchMinimum;

  /// No description provided for @catalogClearSearch.
  ///
  /// In es, this message translates to:
  /// **'Borrar búsqueda'**
  String get catalogClearSearch;

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
  /// **'La búsqueda, los filtros y el orden estarán disponibles en el siguiente paso.'**
  String get catalogControlsUnavailable;

  /// No description provided for @catalogFiltersLabel.
  ///
  /// In es, this message translates to:
  /// **'Filtros del catálogo'**
  String get catalogFiltersLabel;

  /// No description provided for @catalogFiltersUnavailableDuringSearch.
  ///
  /// In es, this message translates to:
  /// **'Durante la búsqueda puedes filtrar por categoría. Borra la búsqueda para usar disponibilidad, descuentos u orden.'**
  String get catalogFiltersUnavailableDuringSearch;

  /// No description provided for @catalogAvailabilityLabel.
  ///
  /// In es, this message translates to:
  /// **'Disponibilidad'**
  String get catalogAvailabilityLabel;

  /// No description provided for @catalogAvailabilityAll.
  ///
  /// In es, this message translates to:
  /// **'Toda'**
  String get catalogAvailabilityAll;

  /// No description provided for @catalogAvailabilityAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get catalogAvailabilityAvailable;

  /// No description provided for @catalogAvailabilityLowStock.
  ///
  /// In es, this message translates to:
  /// **'Pocas unidades'**
  String get catalogAvailabilityLowStock;

  /// No description provided for @catalogAvailabilityUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No disponible'**
  String get catalogAvailabilityUnavailable;

  /// No description provided for @catalogAvailabilityReservationOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo reserva'**
  String get catalogAvailabilityReservationOnly;

  /// No description provided for @catalogAvailabilityPickupOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo retiro'**
  String get catalogAvailabilityPickupOnly;

  /// No description provided for @catalogAvailabilityDeliveryOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo entrega'**
  String get catalogAvailabilityDeliveryOnly;

  /// No description provided for @catalogDiscountedOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo con descuento'**
  String get catalogDiscountedOnly;

  /// No description provided for @catalogSortCatalog.
  ///
  /// In es, this message translates to:
  /// **'Orden del catálogo'**
  String get catalogSortCatalog;

  /// No description provided for @catalogSortName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get catalogSortName;

  /// No description provided for @catalogSortPriceAscending.
  ///
  /// In es, this message translates to:
  /// **'Precio: menor a mayor'**
  String get catalogSortPriceAscending;

  /// No description provided for @catalogSortPriceDescending.
  ///
  /// In es, this message translates to:
  /// **'Precio: mayor a menor'**
  String get catalogSortPriceDescending;

  /// No description provided for @catalogResetFilters.
  ///
  /// In es, this message translates to:
  /// **'Restablecer filtros'**
  String get catalogResetFilters;

  /// No description provided for @productDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle del producto'**
  String get productDetailTitle;

  /// No description provided for @productDetailLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando el producto'**
  String get productDetailLoading;

  /// No description provided for @productDetailUnavailableTitle.
  ///
  /// In es, this message translates to:
  /// **'Producto no disponible'**
  String get productDetailUnavailableTitle;

  /// No description provided for @productDetailUnavailableMessage.
  ///
  /// In es, this message translates to:
  /// **'Este producto no está publicado o ya no está disponible.'**
  String get productDetailUnavailableMessage;

  /// No description provided for @productDetailOfflineTitle.
  ///
  /// In es, this message translates to:
  /// **'Estás sin conexión'**
  String get productDetailOfflineTitle;

  /// No description provided for @productDetailOfflineMessage.
  ///
  /// In es, this message translates to:
  /// **'Conéctate a internet para cargar el detalle actualizado.'**
  String get productDetailOfflineMessage;

  /// No description provided for @productDetailErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar el producto'**
  String get productDetailErrorTitle;

  /// No description provided for @productDetailErrorMessage.
  ///
  /// In es, this message translates to:
  /// **'Inténtalo de nuevo. No se mostraron datos incompletos.'**
  String get productDetailErrorMessage;

  /// No description provided for @productDetailDescriptionLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get productDetailDescriptionLabel;

  /// No description provided for @productDetailNoDescription.
  ///
  /// In es, this message translates to:
  /// **'No hay una descripción pública disponible.'**
  String get productDetailNoDescription;

  /// No description provided for @productDetailCategoryLabel.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get productDetailCategoryLabel;

  /// No description provided for @productDetailBrandLabel.
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get productDetailBrandLabel;

  /// No description provided for @productDetailPriceLabel.
  ///
  /// In es, this message translates to:
  /// **'Precio'**
  String get productDetailPriceLabel;

  /// No description provided for @productDetailAvailabilityLabel.
  ///
  /// In es, this message translates to:
  /// **'Disponibilidad comercial'**
  String get productDetailAvailabilityLabel;

  /// No description provided for @productDetailFulfillmentLabel.
  ///
  /// In es, this message translates to:
  /// **'Opciones de compra'**
  String get productDetailFulfillmentLabel;

  /// No description provided for @productDetailPickup.
  ///
  /// In es, this message translates to:
  /// **'Retiro en tienda'**
  String get productDetailPickup;

  /// No description provided for @productDetailDelivery.
  ///
  /// In es, this message translates to:
  /// **'Entrega'**
  String get productDetailDelivery;

  /// No description provided for @productDetailReservation.
  ///
  /// In es, this message translates to:
  /// **'Reserva'**
  String get productDetailReservation;

  /// No description provided for @productDetailPromotionLabel.
  ///
  /// In es, this message translates to:
  /// **'Promoción activa'**
  String get productDetailPromotionLabel;

  /// Título accesible del selector de categorías públicas.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get catalogCategoriesLabel;

  /// Opción del catálogo que elimina el filtro de categoría.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get catalogAllCategories;

  /// Estado accesible mientras se carga otra página keyset.
  ///
  /// In es, this message translates to:
  /// **'Cargando más productos'**
  String get catalogLoadingMore;

  /// Título del error incremental sin eliminar productos visibles.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar más productos'**
  String get catalogLoadMoreError;

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
  /// **'No hay productos publicados'**
  String get catalogEmptyTitle;

  /// Mensaje del catálogo vacío.
  ///
  /// In es, this message translates to:
  /// **'Prueba otra categoría o vuelve más tarde.'**
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

  /// Título mientras se inicia el acceso con Google.
  ///
  /// In es, this message translates to:
  /// **'Abriendo el acceso seguro'**
  String get accountSigningInTitle;

  /// Instrucción segura durante el flujo OAuth externo.
  ///
  /// In es, this message translates to:
  /// **'Completa el acceso en el navegador y vuelve a la aplicación.'**
  String get accountSigningInMessage;

  /// Acción para cancelar el flujo OAuth pendiente.
  ///
  /// In es, this message translates to:
  /// **'Cancelar acceso'**
  String get accountCancelSignIn;

  /// Título mientras se limpia un flujo OAuth cancelado.
  ///
  /// In es, this message translates to:
  /// **'Cancelando el acceso'**
  String get accountCancellingTitle;

  /// Mensaje durante la cancelación del flujo OAuth.
  ///
  /// In es, this message translates to:
  /// **'Estamos cerrando este intento de acceso de forma segura.'**
  String get accountCancellingMessage;

  /// Título de cancelación no crítica del acceso.
  ///
  /// In es, this message translates to:
  /// **'Acceso cancelado'**
  String get accountCancelledTitle;

  /// Mensaje de cancelación recuperable.
  ///
  /// In es, this message translates to:
  /// **'No se hizo ningún cambio en tu cuenta. Puedes intentarlo de nuevo.'**
  String get accountCancelledMessage;

  /// Acción manual para reintentar el acceso.
  ///
  /// In es, this message translates to:
  /// **'Intentar de nuevo'**
  String get accountRetry;

  /// Título genérico de error recuperable de autenticación.
  ///
  /// In es, this message translates to:
  /// **'No pudimos iniciar sesión'**
  String get accountAuthErrorTitle;

  /// Título de error de configuración o almacenamiento seguro.
  ///
  /// In es, this message translates to:
  /// **'Acceso no disponible'**
  String get accountConfigurationErrorTitle;

  /// Estado mientras se elimina la sesión local.
  ///
  /// In es, this message translates to:
  /// **'Cerrando sesión…'**
  String get accountSigningOut;

  /// Error de autenticación sin conexión.
  ///
  /// In es, this message translates to:
  /// **'Comprueba tu conexión y vuelve a intentarlo.'**
  String get accountAuthOffline;

  /// Error temporal del proveedor OAuth.
  ///
  /// In es, this message translates to:
  /// **'Google no está disponible por el momento. Inténtalo más tarde.'**
  String get accountAuthProviderUnavailable;

  /// Error al abrir el navegador externo.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir el navegador para continuar.'**
  String get accountAuthBrowserLaunchFailed;

  /// Error seguro para un callback OAuth rechazado.
  ///
  /// In es, this message translates to:
  /// **'El retorno de acceso no era válido. Inicia un intento nuevo.'**
  String get accountAuthInvalidCallback;

  /// Aviso cuando una sesión expira o es revocada.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión terminó. Inicia sesión de nuevo cuando quieras.'**
  String get accountAuthSessionExpired;

  /// Error cerrado de almacenamiento seguro.
  ///
  /// In es, this message translates to:
  /// **'Este dispositivo no puede proteger la sesión de forma segura.'**
  String get accountAuthSecureStorageUnavailable;

  /// Error seguro de configuración OAuth.
  ///
  /// In es, this message translates to:
  /// **'El acceso con Google no está configurado para este entorno.'**
  String get accountAuthConfiguration;

  /// Error de autenticación inesperado sin detalles técnicos.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un problema inesperado. Puedes intentarlo de nuevo.'**
  String get accountAuthUnexpected;

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

  /// No description provided for @favoritesTitle.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get favoritesTitle;

  /// No description provided for @favoritesOpen.
  ///
  /// In es, this message translates to:
  /// **'Ver favoritos'**
  String get favoritesOpen;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes favoritos'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Guarda productos para encontrarlos rápidamente, incluso sin conexión.'**
  String get favoritesEmptyMessage;

  /// No description provided for @favoritesErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir tus favoritos'**
  String get favoritesErrorTitle;

  /// No description provided for @favoritesErrorMessage.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a intentarlo. Tus selecciones permanecen en este dispositivo.'**
  String get favoritesErrorMessage;

  /// No description provided for @favoriteAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar a favoritos'**
  String get favoriteAdd;

  /// No description provided for @favoriteRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar de favoritos'**
  String get favoriteRemove;

  /// No description provided for @favoriteAdded.
  ///
  /// In es, this message translates to:
  /// **'Producto agregado a favoritos.'**
  String get favoriteAdded;

  /// No description provided for @favoriteRemoved.
  ///
  /// In es, this message translates to:
  /// **'Producto quitado de favoritos.'**
  String get favoriteRemoved;

  /// No description provided for @favoriteUnavailableTitle.
  ///
  /// In es, this message translates to:
  /// **'Producto no disponible'**
  String get favoriteUnavailableTitle;

  /// No description provided for @favoriteUnavailableMessage.
  ///
  /// In es, this message translates to:
  /// **'Puedes conservar este favorito o quitarlo de la lista.'**
  String get favoriteUnavailableMessage;

  /// No description provided for @productShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir producto'**
  String get productShare;

  /// Texto público enviado al diálogo nativo de compartir.
  ///
  /// In es, this message translates to:
  /// **'Mira {name} en Merchandise Control:\n{uri}'**
  String productShareText(String name, String uri);

  /// No description provided for @productShareError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir las opciones para compartir.'**
  String get productShareError;
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
