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

  /// No description provided for @catalogLoadedCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{No hay productos cargados} =1{1 producto cargado} other{{count} productos cargados}}'**
  String catalogLoadedCount(int count);

  /// No description provided for @catalogShowFilters.
  ///
  /// In es, this message translates to:
  /// **'Mostrar filtros'**
  String get catalogShowFilters;

  /// No description provided for @catalogHideFilters.
  ///
  /// In es, this message translates to:
  /// **'Ocultar filtros'**
  String get catalogHideFilters;

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

  /// No description provided for @productDetailSavings.
  ///
  /// In es, this message translates to:
  /// **'Ahorras {amount}'**
  String productDetailSavings(String amount);

  /// No description provided for @productDetailImagePosition.
  ///
  /// In es, this message translates to:
  /// **'Imagen {current} de {total}'**
  String productDetailImagePosition(int current, int total);

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

  /// No description provided for @customerAccountLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando tus datos de cuenta'**
  String get customerAccountLoading;

  /// No description provided for @customerAccountRetry.
  ///
  /// In es, this message translates to:
  /// **'Volver a intentar'**
  String get customerAccountRetry;

  /// No description provided for @customerAccountOffline.
  ///
  /// In es, this message translates to:
  /// **'Estás sin conexión. Conservamos los datos ya cargados; vuelve a intentar antes de guardar cambios.'**
  String get customerAccountOffline;

  /// No description provided for @customerAccountUnauthorized.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión ya no permite esta operación. Vuelve a iniciar sesión.'**
  String get customerAccountUnauthorized;

  /// No description provided for @customerAccountInvalid.
  ///
  /// In es, this message translates to:
  /// **'Revisa los datos ingresados antes de continuar.'**
  String get customerAccountInvalid;

  /// No description provided for @customerAccountConflict.
  ///
  /// In es, this message translates to:
  /// **'Los datos cambiaron en otro lugar. Actualiza e inténtalo de nuevo.'**
  String get customerAccountConflict;

  /// No description provided for @customerAccountTimeout.
  ///
  /// In es, this message translates to:
  /// **'La operación tardó demasiado. Puedes reintentar sin duplicarla.'**
  String get customerAccountTimeout;

  /// No description provided for @customerAccountUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Los datos de tu cuenta no están disponibles por el momento.'**
  String get customerAccountUnavailable;

  /// No description provided for @customerAccountUnexpected.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar la operación. Tus cambios no se muestran como confirmados.'**
  String get customerAccountUnexpected;

  /// No description provided for @customerProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get customerProfileTitle;

  /// No description provided for @customerProfileDescription.
  ///
  /// In es, this message translates to:
  /// **'Elige cómo quieres aparecer y el idioma de la aplicación.'**
  String get customerProfileDescription;

  /// No description provided for @customerProfileNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre visible'**
  String get customerProfileNameLabel;

  /// No description provided for @customerProfileNameHint.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get customerProfileNameHint;

  /// No description provided for @customerProfileLanguageLabel.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get customerProfileLanguageLabel;

  /// No description provided for @customerProfileLanguageEsCl.
  ///
  /// In es, this message translates to:
  /// **'Español (Chile)'**
  String get customerProfileLanguageEsCl;

  /// No description provided for @customerProfileLanguageIt.
  ///
  /// In es, this message translates to:
  /// **'Italiano'**
  String get customerProfileLanguageIt;

  /// No description provided for @customerProfileLanguageEn.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get customerProfileLanguageEn;

  /// No description provided for @customerProfileLanguageZhHans.
  ///
  /// In es, this message translates to:
  /// **'简体中文'**
  String get customerProfileLanguageZhHans;

  /// No description provided for @customerProfileSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar perfil'**
  String get customerProfileSave;

  /// No description provided for @customerProfileSaved.
  ///
  /// In es, this message translates to:
  /// **'Perfil guardado.'**
  String get customerProfileSaved;

  /// No description provided for @customerProfileDeleted.
  ///
  /// In es, this message translates to:
  /// **'Los datos públicos del perfil se restablecieron.'**
  String get customerProfileDeleted;

  /// No description provided for @customerProfileResetTitle.
  ///
  /// In es, this message translates to:
  /// **'Restablecer perfil'**
  String get customerProfileResetTitle;

  /// No description provided for @customerProfileResetMessage.
  ///
  /// In es, this message translates to:
  /// **'Se eliminarán el nombre, el idioma guardado y el consentimiento del perfil. Tus direcciones y tu acceso permanecerán sin cambios.'**
  String get customerProfileResetMessage;

  /// No description provided for @customerProfileResetAction.
  ///
  /// In es, this message translates to:
  /// **'Restablecer'**
  String get customerProfileResetAction;

  /// No description provided for @customerAddressesTitle.
  ///
  /// In es, this message translates to:
  /// **'Direcciones'**
  String get customerAddressesTitle;

  /// No description provided for @customerAddressesDescription.
  ///
  /// In es, this message translates to:
  /// **'Guarda datos postales para usarlos más adelante. La disponibilidad de entrega se valida en el checkout.'**
  String get customerAddressesDescription;

  /// No description provided for @customerAddressesEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes direcciones'**
  String get customerAddressesEmptyTitle;

  /// No description provided for @customerAddressesEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Agrega una dirección cuando quieras preparar una entrega.'**
  String get customerAddressesEmptyMessage;

  /// No description provided for @customerAddressAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar dirección'**
  String get customerAddressAdd;

  /// No description provided for @customerAddressEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar dirección'**
  String get customerAddressEdit;

  /// No description provided for @customerAddressDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar dirección'**
  String get customerAddressDeleteTitle;

  /// No description provided for @customerAddressDeleteMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar la dirección “{label}”?'**
  String customerAddressDeleteMessage(String label);

  /// No description provided for @customerAddressDeleteAction.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get customerAddressDeleteAction;

  /// No description provided for @customerAddressSaved.
  ///
  /// In es, this message translates to:
  /// **'Dirección guardada.'**
  String get customerAddressSaved;

  /// No description provided for @customerAddressDeleted.
  ///
  /// In es, this message translates to:
  /// **'Dirección eliminada.'**
  String get customerAddressDeleted;

  /// No description provided for @customerAddressDefault.
  ///
  /// In es, this message translates to:
  /// **'Predeterminada'**
  String get customerAddressDefault;

  /// No description provided for @customerAddressSetDefault.
  ///
  /// In es, this message translates to:
  /// **'Usar como predeterminada'**
  String get customerAddressSetDefault;

  /// No description provided for @customerAddressDefaultChanged.
  ///
  /// In es, this message translates to:
  /// **'Dirección predeterminada actualizada.'**
  String get customerAddressDefaultChanged;

  /// No description provided for @customerAddressLabel.
  ///
  /// In es, this message translates to:
  /// **'Etiqueta'**
  String get customerAddressLabel;

  /// No description provided for @customerAddressRecipient.
  ///
  /// In es, this message translates to:
  /// **'Nombre de quien recibe'**
  String get customerAddressRecipient;

  /// No description provided for @customerAddressLine1.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get customerAddressLine1;

  /// No description provided for @customerAddressLine2.
  ///
  /// In es, this message translates to:
  /// **'Depto., oficina u otra referencia (opcional)'**
  String get customerAddressLine2;

  /// No description provided for @customerAddressCommune.
  ///
  /// In es, this message translates to:
  /// **'Comuna'**
  String get customerAddressCommune;

  /// No description provided for @customerAddressRegion.
  ///
  /// In es, this message translates to:
  /// **'Región'**
  String get customerAddressRegion;

  /// No description provided for @customerAddressPostalCode.
  ///
  /// In es, this message translates to:
  /// **'Código postal (opcional)'**
  String get customerAddressPostalCode;

  /// No description provided for @customerAddressCountryCode.
  ///
  /// In es, this message translates to:
  /// **'Código de país'**
  String get customerAddressCountryCode;

  /// No description provided for @customerAddressInstructions.
  ///
  /// In es, this message translates to:
  /// **'Indicaciones de entrega (opcional)'**
  String get customerAddressInstructions;

  /// No description provided for @customerAddressSemantics.
  ///
  /// In es, this message translates to:
  /// **'Dirección {label}: {address}, {commune}'**
  String customerAddressSemantics(String label, String address, String commune);

  /// No description provided for @customerPrivacyTitle.
  ///
  /// In es, this message translates to:
  /// **'Privacidad y datos'**
  String get customerPrivacyTitle;

  /// No description provided for @customerPrivacyDescription.
  ///
  /// In es, this message translates to:
  /// **'Tú decides el consentimiento y puedes consultar una copia de los datos Storefront asociados a tu cuenta.'**
  String get customerPrivacyDescription;

  /// No description provided for @customerPrivacyConsentTitle.
  ///
  /// In es, this message translates to:
  /// **'Consentimiento de privacidad'**
  String get customerPrivacyConsentTitle;

  /// No description provided for @customerPrivacyConsentDescription.
  ///
  /// In es, this message translates to:
  /// **'Registra o revoca tu aceptación de la versión vigente. No se activa de forma implícita.'**
  String get customerPrivacyConsentDescription;

  /// No description provided for @customerPrivacyConsentUpdated.
  ///
  /// In es, this message translates to:
  /// **'Preferencia de privacidad actualizada.'**
  String get customerPrivacyConsentUpdated;

  /// No description provided for @customerDataExportAction.
  ///
  /// In es, this message translates to:
  /// **'Ver mi exportación de datos'**
  String get customerDataExportAction;

  /// No description provided for @customerDataExportTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus datos Storefront'**
  String get customerDataExportTitle;

  /// No description provided for @customerDeletionTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminación de cuenta'**
  String get customerDeletionTitle;

  /// No description provided for @customerDeletionDescription.
  ///
  /// In es, this message translates to:
  /// **'Puedes solicitar una eliminación revisable. La app no borra tu cuenta de inmediato.'**
  String get customerDeletionDescription;

  /// No description provided for @customerDeletionPending.
  ///
  /// In es, this message translates to:
  /// **'Tu solicitud está pendiente y será procesada según la política de retención.'**
  String get customerDeletionPending;

  /// No description provided for @customerDeletionConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Solicitar eliminación de cuenta'**
  String get customerDeletionConfirmTitle;

  /// No description provided for @customerDeletionConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'La solicitud se registrará para revisión. No se cerrará tu sesión ni se borrarán datos de inmediato.'**
  String get customerDeletionConfirmMessage;

  /// No description provided for @customerDeletionRequestAction.
  ///
  /// In es, this message translates to:
  /// **'Solicitar eliminación'**
  String get customerDeletionRequestAction;

  /// No description provided for @customerDeletionCancelAction.
  ///
  /// In es, this message translates to:
  /// **'Cancelar solicitud'**
  String get customerDeletionCancelAction;

  /// No description provided for @customerDeletionRequested.
  ///
  /// In es, this message translates to:
  /// **'Solicitud de eliminación registrada.'**
  String get customerDeletionRequested;

  /// No description provided for @customerDeletionCancelled.
  ///
  /// In es, this message translates to:
  /// **'Solicitud de eliminación cancelada.'**
  String get customerDeletionCancelled;

  /// No description provided for @customerDialogCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get customerDialogCancel;

  /// No description provided for @customerDialogSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get customerDialogSave;

  /// No description provided for @customerDialogClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get customerDialogClose;

  /// No description provided for @customerFieldRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio.'**
  String get customerFieldRequired;

  /// No description provided for @customerFieldInvalid.
  ///
  /// In es, this message translates to:
  /// **'Revisa el formato y la longitud de este campo.'**
  String get customerFieldInvalid;

  /// No description provided for @customerNotificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get customerNotificationsTitle;

  /// No description provided for @customerNotificationsDescription.
  ///
  /// In es, this message translates to:
  /// **'Elige si quieres recibir novedades esenciales sobre pedidos y reservas. El permiso del sistema se solicita por separado.'**
  String get customerNotificationsDescription;

  /// No description provided for @customerNotificationsLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando la configuración de notificaciones'**
  String get customerNotificationsLoading;

  /// No description provided for @customerNotificationsProviderUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Las notificaciones push no están configuradas en esta compilación. No se registró ningún token ni se activó un permiso ficticio.'**
  String get customerNotificationsProviderUnavailable;

  /// No description provided for @customerNotificationsActive.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones activas y confirmadas por el servidor.'**
  String get customerNotificationsActive;

  /// No description provided for @customerNotificationsNotRequested.
  ///
  /// In es, this message translates to:
  /// **'Todavía no elegiste si quieres recibir notificaciones.'**
  String get customerNotificationsNotRequested;

  /// No description provided for @customerNotificationsDenied.
  ///
  /// In es, this message translates to:
  /// **'Elegiste no recibir notificaciones. Puedes cambiar esta preferencia cuando quieras.'**
  String get customerNotificationsDenied;

  /// No description provided for @customerNotificationsRevoked.
  ///
  /// In es, this message translates to:
  /// **'Las notificaciones están revocadas para esta instalación.'**
  String get customerNotificationsRevoked;

  /// No description provided for @customerNotificationsPending.
  ///
  /// In es, this message translates to:
  /// **'El cambio está guardado en este dispositivo, pero aún no fue confirmado por el servidor.'**
  String get customerNotificationsPending;

  /// No description provided for @customerNotificationsOffline.
  ///
  /// In es, this message translates to:
  /// **'No pudimos confirmar el cambio porque estás sin conexión. Reintenta cuando recuperes la red.'**
  String get customerNotificationsOffline;

  /// No description provided for @customerNotificationsTimeout.
  ///
  /// In es, this message translates to:
  /// **'El servidor tardó demasiado. Reintenta: la misma operación idempotente no se duplicará.'**
  String get customerNotificationsTimeout;

  /// No description provided for @customerNotificationsUnauthorized.
  ///
  /// In es, this message translates to:
  /// **'La sesión ya no permite actualizar las notificaciones.'**
  String get customerNotificationsUnauthorized;

  /// No description provided for @customerNotificationsInvalid.
  ///
  /// In es, this message translates to:
  /// **'La configuración de notificaciones no es válida.'**
  String get customerNotificationsInvalid;

  /// No description provided for @customerNotificationsConflict.
  ///
  /// In es, this message translates to:
  /// **'La operación idempotente no coincide con la solicitud anterior. Actualiza y vuelve a intentar.'**
  String get customerNotificationsConflict;

  /// No description provided for @customerNotificationsUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No pudimos actualizar las notificaciones. El cambio no se muestra como confirmado.'**
  String get customerNotificationsUnavailable;

  /// No description provided for @customerNotificationsEnable.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get customerNotificationsEnable;

  /// No description provided for @customerNotificationsNotNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get customerNotificationsNotNow;

  /// No description provided for @customerNotificationsRevoke.
  ///
  /// In es, this message translates to:
  /// **'Revocar'**
  String get customerNotificationsRevoke;

  /// No description provided for @customerNotificationsRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get customerNotificationsRetry;
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
