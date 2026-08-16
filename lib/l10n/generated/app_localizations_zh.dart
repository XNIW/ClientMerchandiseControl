// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

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
  String storefrontCacheFresh(String date) {
    return 'Copia guardada actualizada el $date.';
  }

  @override
  String storefrontCacheStale(String date) {
    return 'Copia guardada del $date. Los precios y la disponibilidad pueden haber cambiado.';
  }

  @override
  String get storefrontCacheRefreshing => 'Actualizando en segundo plano…';

  @override
  String get navigationHome => 'Inicio';

  @override
  String get navigationCatalog => 'Catálogo';

  @override
  String get navigationOrders => 'Pedidos';

  @override
  String navigationCartBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Carrito, $count productos',
      one: 'Carrito, 1 producto',
      zero: 'Carrito, sin productos',
    );
    return '$_temp0';
  }

  @override
  String navigationOrdersBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pedidos, $count pedidos activos',
      one: 'Pedidos, 1 pedido activo',
      zero: 'Pedidos, sin pedidos activos',
    );
    return '$_temp0';
  }

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

  @override
  String get homeWelcomeTitle => 'Todo listo para empezar a explorar';

  @override
  String get homeWelcomeMessage =>
      'Recorre las secciones de la tienda mientras preparamos el catálogo.';

  @override
  String get homeSearchLabel => 'Buscar en la tienda';

  @override
  String get homeSearchHint => '¿Qué estás buscando?';

  @override
  String get homeSelectedStore => 'Tienda seleccionada';

  @override
  String get homeDeliveryDestination => 'Destino de entrega';

  @override
  String get homeStoreContextFallback =>
      'Disponibilidad confirmada por la tienda';

  @override
  String get homeActiveOrderTitle => 'Pedido activo';

  @override
  String homeActiveOrderSemantics(String code, String status) {
    return 'Pedido activo $code, estado $status';
  }

  @override
  String get homeCategoriesTitle => 'Explora por categoría';

  @override
  String get homeCategoriesMessage =>
      'Las categorías aparecerán cuando el catálogo esté disponible.';

  @override
  String get homeExploreCategories => 'Ver categorías';

  @override
  String get homeOffersTitle => 'Ofertas';

  @override
  String get homeOffersEmptyTitle => 'Ofertas, próximamente';

  @override
  String get homeOffersEmptyMessage =>
      'Aquí mostraremos ofertas reales cuando estén disponibles.';

  @override
  String get homeFeaturedTitle => 'Productos destacados';

  @override
  String get homeFeaturedEmptyTitle => 'Destacados, próximamente';

  @override
  String get homeFeaturedEmptyMessage =>
      'Esta sección mostrará productos reales cuando el catálogo esté disponible.';

  @override
  String get homeExploreCatalog => 'Explorar catálogo';

  @override
  String get homeLoadingTitle => 'Cargando la tienda';

  @override
  String get homeLoadingMessage =>
      'Estamos preparando categorías, ofertas y productos destacados.';

  @override
  String get homeLoadErrorTitle => 'No pudimos cargar la tienda';

  @override
  String get homeLoadErrorMessage =>
      'Comprueba tu conexión y vuelve a intentarlo.';

  @override
  String get homeUnavailableTitle => 'La tienda no está disponible';

  @override
  String get homeUnavailableMessage =>
      'El catálogo público no está disponible por el momento.';

  @override
  String get homeImageUnavailable => 'Imagen no disponible';

  @override
  String homePreviousPrice(String price) {
    return 'Antes $price';
  }

  @override
  String homeDiscountPercent(String percent) {
    return '$percent% de descuento';
  }

  @override
  String get catalogSearchLabel => 'Buscar en el catálogo';

  @override
  String get catalogSearchHint => 'Busca productos o categorías';

  @override
  String get catalogSearchMinimum =>
      'Escribe al menos 2 caracteres para buscar.';

  @override
  String get catalogClearSearch => 'Borrar búsqueda';

  @override
  String get catalogFilterLabel => 'Filtrar';

  @override
  String get catalogSortLabel => 'Ordenar';

  @override
  String get catalogControlsUnavailable =>
      'La búsqueda, los filtros y el orden estarán disponibles en el siguiente paso.';

  @override
  String get catalogFiltersLabel => 'Filtros del catálogo';

  @override
  String catalogLoadedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count productos cargados',
      one: '1 producto cargado',
      zero: 'No hay productos cargados',
    );
    return '$_temp0';
  }

  @override
  String get catalogShowFilters => 'Mostrar filtros';

  @override
  String get catalogHideFilters => 'Ocultar filtros';

  @override
  String get catalogFiltersUnavailableDuringSearch =>
      'Durante la búsqueda puedes filtrar por categoría. Borra la búsqueda para usar disponibilidad, descuentos u orden.';

  @override
  String get catalogAvailabilityLabel => 'Disponibilidad';

  @override
  String get catalogAvailabilityAll => 'Toda';

  @override
  String get catalogAvailabilityAvailable => 'Disponible';

  @override
  String get catalogAvailabilityLowStock => 'Pocas unidades';

  @override
  String get catalogAvailabilityUnavailable => 'No disponible';

  @override
  String get catalogAvailabilityReservationOnly => 'Solo reserva';

  @override
  String get catalogAvailabilityPickupOnly => 'Solo retiro';

  @override
  String get catalogAvailabilityDeliveryOnly => 'Solo entrega';

  @override
  String get catalogDiscountedOnly => 'Solo con descuento';

  @override
  String get catalogSortCatalog => 'Orden del catálogo';

  @override
  String get catalogSortName => 'Nombre';

  @override
  String get catalogSortPriceAscending => 'Precio: menor a mayor';

  @override
  String get catalogSortPriceDescending => 'Precio: mayor a menor';

  @override
  String get catalogResetFilters => 'Restablecer filtros';

  @override
  String get productDetailTitle => 'Detalle del producto';

  @override
  String get productDetailLoading => 'Cargando el producto';

  @override
  String get productDetailUnavailableTitle => 'Producto no disponible';

  @override
  String get productDetailUnavailableMessage =>
      'Este producto no está publicado o ya no está disponible.';

  @override
  String get productDetailOfflineTitle => 'Estás sin conexión';

  @override
  String get productDetailOfflineMessage =>
      'Conéctate a internet para cargar el detalle actualizado.';

  @override
  String get productDetailErrorTitle => 'No pudimos cargar el producto';

  @override
  String get productDetailErrorMessage =>
      'Inténtalo de nuevo. No se mostraron datos incompletos.';

  @override
  String get productDetailDescriptionLabel => 'Descripción';

  @override
  String get productDetailNoDescription =>
      'No hay una descripción pública disponible.';

  @override
  String get productDetailCategoryLabel => 'Categoría';

  @override
  String get productDetailBrandLabel => 'Marca';

  @override
  String get productDetailPriceLabel => 'Precio';

  @override
  String productDetailSavings(String amount) {
    return 'Ahorras $amount';
  }

  @override
  String productDetailImagePosition(int current, int total) {
    return 'Imagen $current de $total';
  }

  @override
  String get productDetailAvailabilityLabel => 'Disponibilidad comercial';

  @override
  String get productDetailFulfillmentLabel => 'Opciones de compra';

  @override
  String get productDetailPickup => 'Retiro en tienda';

  @override
  String get productDetailDelivery => 'Entrega';

  @override
  String get productDetailReservation => 'Reserva';

  @override
  String get productDetailPromotionLabel => 'Promoción activa';

  @override
  String get catalogCategoriesLabel => 'Categorías';

  @override
  String get catalogAllCategories => 'Todos';

  @override
  String get catalogLoadingMore => 'Cargando más productos';

  @override
  String get catalogLoadMoreError => 'No pudimos cargar más productos';

  @override
  String get catalogConnectingTitle => 'Preparando el catálogo';

  @override
  String get catalogConnectingMessage =>
      'Estamos comprobando si la tienda está disponible.';

  @override
  String get catalogEmptyTitle => 'No hay productos publicados';

  @override
  String get catalogEmptyMessage => 'Prueba otra categoría o vuelve más tarde.';

  @override
  String get catalogOfflineTitle => 'Estás sin conexión';

  @override
  String get catalogOfflineMessage =>
      'Comprueba tu conexión y vuelve a intentarlo. El resto de la app sigue disponible.';

  @override
  String get catalogUnavailableTitle => 'La tienda no está disponible';

  @override
  String get catalogUnavailableMessage =>
      'No podemos preparar el catálogo público por el momento.';

  @override
  String get catalogRetryTitle => 'No pudimos comprobar la tienda';

  @override
  String get catalogRetryMessage =>
      'Inténtalo de nuevo. También puedes seguir explorando otras secciones.';

  @override
  String get cartEmptyTitle => 'Tu carrito está vacío';

  @override
  String get cartEmptyMessage =>
      'Cuando el catálogo esté disponible, podrás agregar productos aquí.';

  @override
  String get cartExploreCatalog => 'Explorar catálogo';

  @override
  String get accountGuestTitle => 'Tu cuenta';

  @override
  String get accountGuestBenefit =>
      'Inicia sesión para acceder a funciones personales. Puedes seguir explorando sin una cuenta.';

  @override
  String get accountContinueWithGoogle => 'Continuar con Google';

  @override
  String get accountGoogleComingSoon =>
      'El acceso con Google estará disponible próximamente.';

  @override
  String get accountBrowseAsGuest => 'Seguir explorando como invitado';

  @override
  String get accountAuthenticatedTitle => 'Sesión iniciada';

  @override
  String get accountNameFallback => 'Cliente';

  @override
  String get accountEmailFallback => 'Correo no disponible';

  @override
  String get accountSessionActive => 'Tu sesión está activa.';

  @override
  String get accountLogout => 'Cerrar sesión';

  @override
  String get accountPersonalSettingsTitle => 'Perfil, direcciones y privacidad';

  @override
  String get accountPersonalSettingsDescription =>
      'Gestiona tu identidad, idioma, direcciones y datos Storefront.';

  @override
  String get accountNotificationsDescription =>
      'Elige cómo recibir novedades reales de tus pedidos.';

  @override
  String get accountSigningInTitle => 'Abriendo el acceso seguro';

  @override
  String get accountSigningInMessage =>
      'Completa el acceso en el navegador y vuelve a la aplicación.';

  @override
  String get accountCancelSignIn => 'Cancelar acceso';

  @override
  String get accountCancellingTitle => 'Cancelando el acceso';

  @override
  String get accountCancellingMessage =>
      'Estamos cerrando este intento de acceso de forma segura.';

  @override
  String get accountCancelledTitle => 'Acceso cancelado';

  @override
  String get accountCancelledMessage =>
      'No se hizo ningún cambio en tu cuenta. Puedes intentarlo de nuevo.';

  @override
  String get accountRetry => 'Intentar de nuevo';

  @override
  String get accountAuthErrorTitle => 'No pudimos iniciar sesión';

  @override
  String get accountConfigurationErrorTitle => 'Acceso no disponible';

  @override
  String get accountSigningOut => 'Cerrando sesión…';

  @override
  String get accountAuthOffline =>
      'Comprueba tu conexión y vuelve a intentarlo.';

  @override
  String get accountAuthProviderUnavailable =>
      'Google no está disponible por el momento. Inténtalo más tarde.';

  @override
  String get accountAuthBrowserLaunchFailed =>
      'No pudimos abrir el navegador para continuar.';

  @override
  String get accountAuthInvalidCallback =>
      'El retorno de acceso no era válido. Inicia un intento nuevo.';

  @override
  String get accountAuthSessionExpired =>
      'Tu sesión terminó. Inicia sesión de nuevo cuando quieras.';

  @override
  String get accountAuthSecureStorageUnavailable =>
      'Este dispositivo no puede proteger la sesión de forma segura.';

  @override
  String get accountAuthConfiguration =>
      'El acceso con Google no está configurado para este entorno.';

  @override
  String get accountAuthUnexpected =>
      'Ocurrió un problema inesperado. Puedes intentarlo de nuevo.';

  @override
  String accountAvatarLabel(String name) {
    return 'Avatar de $name';
  }

  @override
  String get storefrontComingSoonLabel => 'Próximamente';

  @override
  String get favoritesTitle => 'Favoritos';

  @override
  String get favoritesOpen => 'Ver favoritos';

  @override
  String get favoritesEmptyTitle => 'Aún no tienes favoritos';

  @override
  String get favoritesEmptyMessage =>
      'Guarda productos para encontrarlos rápidamente, incluso sin conexión.';

  @override
  String get favoritesErrorTitle => 'No pudimos abrir tus favoritos';

  @override
  String get favoritesErrorMessage =>
      'Vuelve a intentarlo. Tus selecciones permanecen en este dispositivo.';

  @override
  String get favoriteAdd => 'Agregar a favoritos';

  @override
  String get favoriteRemove => 'Quitar de favoritos';

  @override
  String get favoriteAdded => 'Producto agregado a favoritos.';

  @override
  String get favoriteRemoved => 'Producto quitado de favoritos.';

  @override
  String get favoriteUnavailableTitle => 'Producto no disponible';

  @override
  String get favoriteUnavailableMessage =>
      'Puedes conservar este favorito o quitarlo de la lista.';

  @override
  String get productShare => 'Compartir producto';

  @override
  String productShareText(String name, String uri) {
    return 'Mira $name en Merchandise Control:\n$uri';
  }

  @override
  String get productShareError =>
      'No pudimos abrir las opciones para compartir.';

  @override
  String get customerAccountLoading => 'Cargando tus datos de cuenta';

  @override
  String get customerAccountRetry => 'Volver a intentar';

  @override
  String get customerAccountOffline =>
      'Estás sin conexión. Conservamos los datos ya cargados; vuelve a intentar antes de guardar cambios.';

  @override
  String get customerAccountUnauthorized =>
      'Tu sesión ya no permite esta operación. Vuelve a iniciar sesión.';

  @override
  String get customerAccountInvalid =>
      'Revisa los datos ingresados antes de continuar.';

  @override
  String get customerAccountConflict =>
      'Los datos cambiaron en otro lugar. Actualiza e inténtalo de nuevo.';

  @override
  String get customerAccountTimeout =>
      'La operación tardó demasiado. Puedes reintentar sin duplicarla.';

  @override
  String get customerAccountUnavailable =>
      'Los datos de tu cuenta no están disponibles por el momento.';

  @override
  String get customerAccountUnexpected =>
      'No pudimos completar la operación. Tus cambios no se muestran como confirmados.';

  @override
  String get customerProfileTitle => 'Perfil';

  @override
  String get customerProfileDescription =>
      'Elige cómo quieres aparecer y el idioma de la aplicación.';

  @override
  String get customerProfileNameLabel => 'Nombre visible';

  @override
  String get customerProfileNameHint => 'Opcional';

  @override
  String get customerProfileLanguageLabel => 'Idioma';

  @override
  String get customerProfileLanguageEsCl => 'Español (Chile)';

  @override
  String get customerProfileLanguageIt => 'Italiano';

  @override
  String get customerProfileLanguageEn => 'English';

  @override
  String get customerProfileLanguageZhHans => '简体中文';

  @override
  String get customerProfileSave => 'Guardar perfil';

  @override
  String get customerProfileSaved => 'Perfil guardado.';

  @override
  String get customerProfileDeleted =>
      'Los datos públicos del perfil se restablecieron.';

  @override
  String get customerProfileResetTitle => 'Restablecer perfil';

  @override
  String get customerProfileResetMessage =>
      'Se eliminarán el nombre, el idioma guardado y el consentimiento del perfil. Tus direcciones y tu acceso permanecerán sin cambios.';

  @override
  String get customerProfileResetAction => 'Restablecer';

  @override
  String get customerAddressesTitle => 'Direcciones';

  @override
  String get customerAddressesDescription =>
      'Guarda datos postales para usarlos más adelante. La disponibilidad de entrega se valida en el checkout.';

  @override
  String get customerAddressesEmptyTitle => 'Aún no tienes direcciones';

  @override
  String get customerAddressesEmptyMessage =>
      'Agrega una dirección cuando quieras preparar una entrega.';

  @override
  String get customerAddressAdd => 'Agregar dirección';

  @override
  String get customerAddressEdit => 'Editar dirección';

  @override
  String get customerAddressDeleteTitle => 'Eliminar dirección';

  @override
  String customerAddressDeleteMessage(String label) {
    return '¿Eliminar la dirección “$label”?';
  }

  @override
  String get customerAddressDeleteAction => 'Eliminar';

  @override
  String get customerAddressSaved => 'Dirección guardada.';

  @override
  String get customerAddressDeleted => 'Dirección eliminada.';

  @override
  String get customerAddressDefault => 'Predeterminada';

  @override
  String get customerAddressSetDefault => 'Usar como predeterminada';

  @override
  String get customerAddressDefaultChanged =>
      'Dirección predeterminada actualizada.';

  @override
  String get customerAddressLabel => 'Etiqueta';

  @override
  String get customerAddressRecipient => 'Nombre de quien recibe';

  @override
  String get customerAddressLine1 => 'Dirección';

  @override
  String get customerAddressLine2 =>
      'Depto., oficina u otra referencia (opcional)';

  @override
  String get customerAddressCommune => 'Comuna';

  @override
  String get customerAddressRegion => 'Región';

  @override
  String get customerAddressPostalCode => 'Código postal (opcional)';

  @override
  String get customerAddressCountryCode => 'Código de país';

  @override
  String get customerAddressInstructions =>
      'Indicaciones de entrega (opcional)';

  @override
  String customerAddressSemantics(
    String label,
    String address,
    String commune,
  ) {
    return 'Dirección $label: $address, $commune';
  }

  @override
  String get customerPrivacyTitle => 'Privacidad y datos';

  @override
  String get customerPrivacyDescription =>
      'Tú decides el consentimiento y puedes consultar una copia de los datos Storefront asociados a tu cuenta.';

  @override
  String get customerPrivacyConsentTitle => 'Consentimiento de privacidad';

  @override
  String get customerPrivacyConsentDescription =>
      'Registra o revoca tu aceptación de la versión vigente. No se activa de forma implícita.';

  @override
  String get customerPrivacyConsentUpdated =>
      'Preferencia de privacidad actualizada.';

  @override
  String get customerDataExportAction => 'Ver mi exportación de datos';

  @override
  String get customerDataExportTitle => 'Tus datos Storefront';

  @override
  String get customerDeletionTitle => 'Eliminación de cuenta';

  @override
  String get customerDeletionDescription =>
      'Puedes solicitar una eliminación revisable. La app no borra tu cuenta de inmediato.';

  @override
  String get customerDeletionPending =>
      'Tu solicitud está pendiente y será procesada según la política de retención.';

  @override
  String get customerDeletionConfirmTitle => 'Solicitar eliminación de cuenta';

  @override
  String get customerDeletionConfirmMessage =>
      'La solicitud se registrará para revisión. No se cerrará tu sesión ni se borrarán datos de inmediato.';

  @override
  String get customerDeletionRequestAction => 'Solicitar eliminación';

  @override
  String get customerDeletionCancelAction => 'Cancelar solicitud';

  @override
  String get customerDeletionRequested =>
      'Solicitud de eliminación registrada.';

  @override
  String get customerDeletionCancelled => 'Solicitud de eliminación cancelada.';

  @override
  String get customerDialogCancel => 'Cancelar';

  @override
  String get customerDialogSave => 'Guardar';

  @override
  String get customerDialogClose => 'Cerrar';

  @override
  String get customerFieldRequired => 'Este campo es obligatorio.';

  @override
  String get customerFieldInvalid =>
      'Revisa el formato y la longitud de este campo.';

  @override
  String get customerNotificationsTitle => 'Notificaciones';

  @override
  String get customerNotificationsDescription =>
      'Elige si quieres recibir novedades esenciales sobre pedidos y reservas. El permiso del sistema se solicita por separado.';

  @override
  String get customerNotificationsLoading =>
      'Cargando la configuración de notificaciones';

  @override
  String get customerNotificationsProviderUnavailable =>
      'Las notificaciones push no están configuradas en esta compilación. No se registró ningún token ni se activó un permiso ficticio.';

  @override
  String get customerNotificationsActive =>
      'Notificaciones activas y confirmadas por el servidor.';

  @override
  String get customerNotificationsNotRequested =>
      'Todavía no elegiste si quieres recibir notificaciones.';

  @override
  String get customerNotificationsDenied =>
      'Elegiste no recibir notificaciones. Puedes cambiar esta preferencia cuando quieras.';

  @override
  String get customerNotificationsRevoked =>
      'Las notificaciones están revocadas para esta instalación.';

  @override
  String get customerNotificationsPending =>
      'El cambio está guardado en este dispositivo, pero aún no fue confirmado por el servidor.';

  @override
  String get customerNotificationsOffline =>
      'No pudimos confirmar el cambio porque estás sin conexión. Reintenta cuando recuperes la red.';

  @override
  String get customerNotificationsTimeout =>
      'El servidor tardó demasiado. Reintenta: la misma operación idempotente no se duplicará.';

  @override
  String get customerNotificationsUnauthorized =>
      'La sesión ya no permite actualizar las notificaciones.';

  @override
  String get customerNotificationsInvalid =>
      'La configuración de notificaciones no es válida.';

  @override
  String get customerNotificationsConflict =>
      'La operación idempotente no coincide con la solicitud anterior. Actualiza y vuelve a intentar.';

  @override
  String get customerNotificationsUnavailable =>
      'No pudimos actualizar las notificaciones. El cambio no se muestra como confirmado.';

  @override
  String get customerNotificationsEnable => 'Activar';

  @override
  String get customerNotificationsNotNow => 'Ahora no';

  @override
  String get customerNotificationsRevoke => 'Revocar';

  @override
  String get customerNotificationsRetry => 'Reintentar';

  @override
  String reservationHoldCreateAction(int quantity) {
    return 'Reservar $quantity por 15 min';
  }

  @override
  String get reservationHoldSignInAction => 'Inicia sesión para reservar';

  @override
  String get reservationHoldLoading => 'Confirmando la reserva con la tienda';

  @override
  String get reservationHoldActive => 'Reserva activa';

  @override
  String get reservationHoldExpiring => 'La reserva vence pronto';

  @override
  String reservationHoldRemaining(String time) {
    return 'Quedan $time';
  }

  @override
  String get reservationHoldExpired =>
      'La reserva venció y la capacidad volvió a la tienda.';

  @override
  String get reservationHoldReleased => 'Reserva liberada.';

  @override
  String get reservationHoldConsumed => 'La reserva ya fue utilizada.';

  @override
  String get reservationHoldReleaseAction => 'Liberar reserva';

  @override
  String get reservationHoldRetryAction => 'Reintentar de forma segura';

  @override
  String get reservationHoldDismissAction => 'Cerrar estado';

  @override
  String get reservationHoldPendingRetry =>
      'La operación pendiente conserva la misma clave idempotente.';

  @override
  String get reservationHoldOfflineError =>
      'Estás sin conexión. No mostramos una reserva nueva como confirmada.';

  @override
  String get reservationHoldTimeoutError =>
      'La respuesta fue ambigua. Reintenta de forma segura para conocer el estado real.';

  @override
  String get reservationHoldUnauthorizedError =>
      'Inicia sesión nuevamente para administrar la reserva.';

  @override
  String get reservationHoldInvalidError =>
      'La solicitud de reserva no es válida.';

  @override
  String get reservationHoldConflictError =>
      'La clave idempotente pertenece a otra solicitud. Vuelve a crear la reserva.';

  @override
  String get reservationHoldUnavailableError =>
      'La tienda ya no puede reservar esta cantidad.';

  @override
  String get reservationHoldLimitError =>
      'Alcanzaste el límite de reservas activas.';

  @override
  String get reservationHoldNotFoundError =>
      'La reserva ya no existe o no pertenece a esta cuenta.';

  @override
  String get reservationHoldUnexpectedError =>
      'No pudimos verificar la reserva. Inténtalo nuevamente.';

  @override
  String get cartAddAction => 'Agregar al carrito';

  @override
  String cartAddQuantityAction(int quantity) {
    return 'Agregar $quantity al carrito';
  }

  @override
  String get cartAddedNotice => 'Producto agregado al carrito.';

  @override
  String get cartGuestSyncMessage =>
      'Tu carrito se guarda en este dispositivo y funciona sin conexión.';

  @override
  String get cartAccountSyncMessage =>
      'Tu carrito está asociado a tu cuenta y se valida con la tienda.';

  @override
  String cartIndicativeSubtotal(String price) {
    return 'Subtotal estimado: $price';
  }

  @override
  String cartConfirmedSubtotal(String price) {
    return 'Subtotal validado: $price';
  }

  @override
  String get cartRevalidateAction => 'Validar carrito';

  @override
  String get cartEstimatedLabel => 'Estimado';

  @override
  String get cartValidatedLabel => 'Validado';

  @override
  String get cartRetryAction => 'Reintentar';

  @override
  String get cartClearAction => 'Vaciar carrito';

  @override
  String get cartClearTitle => '¿Vaciar el carrito?';

  @override
  String get cartClearMessage =>
      'Se eliminarán todos los productos de este carrito.';

  @override
  String get cartRemoveAction => 'Eliminar';

  @override
  String cartQuantityLabel(int quantity) {
    return 'Cantidad: $quantity';
  }

  @override
  String get cartDecreaseQuantity => 'Reducir cantidad';

  @override
  String get cartIncreaseQuantity => 'Aumentar cantidad';

  @override
  String get cartUnavailableLine => 'Este producto ya no está disponible.';

  @override
  String get cartPriceChangedLine =>
      'El precio cambió. Revisa el valor actual.';

  @override
  String get cartPromotionChangedLine =>
      'La promoción cambió. Revisa el valor actual.';

  @override
  String get cartMergedNotice =>
      'El carrito de este dispositivo se sincronizó con tu cuenta.';

  @override
  String get cartPartialMergeNotice =>
      'Sincronizamos los productos disponibles; conserva los demás para que puedas revisarlos.';

  @override
  String get cartRevalidatedNotice =>
      'Precios y disponibilidad validados por la tienda.';

  @override
  String get cartUpdatedNotice => 'Cantidad actualizada.';

  @override
  String get cartRemovedNotice => 'Producto eliminado del carrito.';

  @override
  String get cartClearedNotice => 'Carrito vaciado.';

  @override
  String get cartOfflineError =>
      'Estás sin conexión. Tu carrito local sigue disponible.';

  @override
  String get cartTimeoutError =>
      'La tienda tardó demasiado. Reintenta sin duplicar la operación.';

  @override
  String get cartUnauthorizedError =>
      'Inicia sesión nuevamente para sincronizar el carrito.';

  @override
  String get cartConflictError =>
      'El carrito cambió en otro lugar. Actualiza y vuelve a intentarlo.';

  @override
  String get cartUnavailableError =>
      'No pudimos actualizar el carrito por el momento.';

  @override
  String get cartInvalidError => 'La solicitud del carrito no es válida.';

  @override
  String get cartLimitReached =>
      'El carrito alcanzó el máximo de productos distintos.';

  @override
  String get cartProductUnavailable => 'El producto ya no se puede agregar.';

  @override
  String get cartSignInAction => 'Iniciar sesión';

  @override
  String get cartPendingRetry =>
      'Hay una operación pendiente que puede reintentarse de forma segura.';

  @override
  String get cartPriceDisclaimer =>
      'Los precios y la disponibilidad se confirmarán nuevamente antes de crear el pedido.';

  @override
  String cartLineSemantics(String name, int quantity, String price) {
    return '$name, cantidad $quantity, $price';
  }

  @override
  String get cartCheckoutAction => 'Ir al checkout';

  @override
  String get cartSignInCheckoutAction => 'Inicia sesión y continúa';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get checkoutStepMode => 'Modalidad';

  @override
  String get checkoutStepDestination => 'Destino';

  @override
  String get checkoutStepSlot => 'Horario';

  @override
  String get checkoutStepReview => 'Resumen';

  @override
  String get checkoutStepConfirmation => 'Confirmación';

  @override
  String checkoutStepProgress(int current, int total, String title) {
    return 'Paso $current de $total: $title';
  }

  @override
  String get checkoutAuthTitle => 'Inicia sesión para confirmar';

  @override
  String get checkoutAuthMessage =>
      'Puedes explorar y conservar el carrito sin una cuenta. Para validar dirección, precios y disponibilidad necesitamos tu sesión de cliente.';

  @override
  String get checkoutContinueBrowsing => 'Volver al carrito';

  @override
  String get checkoutUnavailableTitle => 'Checkout no disponible';

  @override
  String get checkoutRetryAction => 'Reintentar de forma segura';

  @override
  String get checkoutContinueAction => 'Continuar';

  @override
  String get checkoutBackAction => 'Atrás';

  @override
  String get checkoutBackToCart => 'Volver al carrito';

  @override
  String get checkoutRestartAction => 'Comenzar de nuevo';

  @override
  String get checkoutModeTitle => '¿Cómo quieres recibir tu compra?';

  @override
  String get checkoutModeMessage =>
      'Solo mostramos modalidades configuradas y disponibles en la tienda.';

  @override
  String get checkoutModePickup => 'Retiro';

  @override
  String get checkoutModePickupDescription =>
      'Retira tu compra en un punto habilitado.';

  @override
  String get checkoutModeReservation => 'Reserva';

  @override
  String get checkoutModeReservationDescription =>
      'Confirma una reserva vigente y retírala en tienda.';

  @override
  String get checkoutModeDelivery => 'Entrega';

  @override
  String get checkoutModeDeliveryDescription =>
      'Recibe la compra en una dirección dentro de la zona activa.';

  @override
  String get checkoutDeliveryAddressTitle => 'Dirección de entrega';

  @override
  String get checkoutDeliveryAddressMessage =>
      'La tienda validará la dirección, la zona y la tarifa en el servidor.';

  @override
  String get checkoutNoAddresses =>
      'Agrega una dirección a tu cuenta antes de elegir entrega.';

  @override
  String get checkoutManageAddresses => 'Gestionar direcciones';

  @override
  String get checkoutUnsupportedAddress => 'Fuera de las zonas disponibles';

  @override
  String get checkoutPickupPointTitle => 'Punto de retiro';

  @override
  String get checkoutPickupPointMessage =>
      'Elige una sede pública disponible para esta modalidad.';

  @override
  String get checkoutSlotTitle => 'Horario disponible';

  @override
  String get checkoutSlotMessage =>
      'La capacidad se confirma nuevamente al validar el checkout.';

  @override
  String get checkoutNoSlots =>
      'Ya no hay horarios disponibles para esta selección.';

  @override
  String get checkoutReviewTitle => 'Revisa tu selección';

  @override
  String get checkoutReviewMessage =>
      'Este total todavía es estimado. La tienda volverá a leer el carrito, las promociones y la disponibilidad.';

  @override
  String get checkoutPaymentTitle => 'Método de pago';

  @override
  String get checkoutPaymentMessage =>
      'Elige un método habilitado para esta modalidad. La tienda lo validará nuevamente al crear el pedido.';

  @override
  String get checkoutPaymentPayAtPickup => 'Pagar al retirar';

  @override
  String get checkoutPaymentPayAtPickupDescription =>
      'Paga en la tienda cuando retires o confirmes la reserva.';

  @override
  String get checkoutPaymentCashOnDelivery => 'Pago contra entrega';

  @override
  String get checkoutPaymentCashOnDeliveryDescription =>
      'Paga al recibir el pedido, solo en zonas habilitadas.';

  @override
  String get checkoutPaymentOnline => 'Pago en línea';

  @override
  String get checkoutPaymentOnlineUnavailable =>
      'No configurado para Storefront v1.';

  @override
  String get checkoutPaymentRequired =>
      'Selecciona un método de pago disponible para crear el pedido.';

  @override
  String get checkoutPaymentUnavailable =>
      'No hay un método de pago disponible para esta modalidad.';

  @override
  String get checkoutPaymentMethodLabel => 'Método de pago';

  @override
  String get checkoutPaymentStatusLabel => 'Estado del pago';

  @override
  String get checkoutPaymentStatusDueAtFulfillment =>
      'Pendiente al momento de la entrega o retiro';

  @override
  String get checkoutPaymentStatusPendingProvider => 'Pendiente del proveedor';

  @override
  String get checkoutPaymentStatusProcessing => 'Procesando';

  @override
  String get checkoutPaymentStatusAuthorized => 'Autorizado';

  @override
  String get checkoutPaymentStatusCollected => 'Cobrado';

  @override
  String get checkoutPaymentStatusFailed => 'Fallido';

  @override
  String get checkoutPaymentStatusCancelled => 'Cancelado';

  @override
  String get checkoutPaymentStatusRefundPending => 'Reembolso pendiente';

  @override
  String get checkoutPaymentStatusRefundFailed => 'Error de reembolso';

  @override
  String get checkoutPaymentStatusRefunded => 'Reembolsado';

  @override
  String get checkoutServerValidationNotice =>
      'El servidor calculará precios, descuentos, tarifa y total. La app no envía un total autorizado.';

  @override
  String get checkoutSubtotalLabel => 'Subtotal';

  @override
  String get checkoutDeliveryFeeLabel => 'Tarifa de entrega';

  @override
  String get checkoutEstimatedTotalLabel => 'Total estimado';

  @override
  String get checkoutAuthoritativeTotalLabel => 'Total validado';

  @override
  String get checkoutValidateAction => 'Validar precios y disponibilidad';

  @override
  String get checkoutConfirmationTitle => 'Confirmación del checkout';

  @override
  String get checkoutQuoteReadyMessage =>
      'La tienda validó este resumen. Confírmalo antes de que venza.';

  @override
  String get checkoutReviewChangesMessage =>
      'Detectamos cambios. Revísalos y acéptalos explícitamente para continuar.';

  @override
  String get checkoutConfirmedMessage => 'Resumen confirmado por la tienda.';

  @override
  String get checkoutExpiredMessage =>
      'Este resumen venció. Vuelve a validar antes de continuar.';

  @override
  String checkoutQuoteRemaining(String time) {
    return 'Este resumen vence en $time';
  }

  @override
  String get checkoutChangesTitle => 'Cambios que debes revisar';

  @override
  String get checkoutConfirmAction => 'Confirmar resumen';

  @override
  String get checkoutAcceptChangesAction => 'Aceptar cambios y confirmar';

  @override
  String get checkoutOrderDeferredNotice =>
      'Antes de crear el pedido, la tienda volverá a validar precio, promoción, disponibilidad y horario.';

  @override
  String get checkoutCreateOrderAction => 'Crear pedido';

  @override
  String get checkoutOrderReceiptTitle => 'Pedido confirmado';

  @override
  String get checkoutOrderReceiptMessage =>
      'Guardamos el pedido con el precio y la modalidad confirmados por la tienda.';

  @override
  String get checkoutOrderCodeLabel => 'Código de pedido';

  @override
  String checkoutOrderCodeSemantics(String code) {
    return 'Código de pedido $code';
  }

  @override
  String checkoutOrderConfirmedMessage(String code) {
    return 'Pedido $code confirmado.';
  }

  @override
  String get checkoutOrderStatusLabel => 'Estado';

  @override
  String get checkoutOrderPlacedAtLabel => 'Creado';

  @override
  String get checkoutOrderAuthoritativeNotice =>
      'El total de este comprobante fue calculado y confirmado por el servidor. El pedido no es una venta fiscal.';

  @override
  String get checkoutOrderConfirmedNotice =>
      'Pedido creado y confirmado por la tienda.';

  @override
  String get checkoutContinueShoppingAction => 'Seguir comprando';

  @override
  String get checkoutOrderStatusConfirmed => 'Confirmado';

  @override
  String get checkoutOrderStatusAccepted => 'Aceptado';

  @override
  String get checkoutOrderStatusRejected => 'Rechazado';

  @override
  String get checkoutOrderStatusPreparing => 'En preparación';

  @override
  String get checkoutOrderStatusReady => 'Listo';

  @override
  String get checkoutOrderStatusOutForDelivery => 'En reparto';

  @override
  String get checkoutOrderStatusCompleted => 'Completado';

  @override
  String get checkoutOrderStatusCancelled => 'Cancelado';

  @override
  String get checkoutRestoredNotice => 'Restauramos tu progreso de checkout.';

  @override
  String get checkoutQuoteChangedNotice =>
      'La tienda actualizó el resumen. Revisa los cambios.';

  @override
  String get checkoutConfirmedNotice => 'Checkout confirmado.';

  @override
  String get checkoutPriceChanged => 'Cambió el precio de un producto.';

  @override
  String get checkoutPromotionChanged => 'Cambió o terminó una promoción.';

  @override
  String get checkoutProductUnavailable => 'Un producto ya no está disponible.';

  @override
  String get checkoutHoldRequired =>
      'Esta reserva necesita una retención vigente.';

  @override
  String get checkoutOfflineError =>
      'Estás sin conexión. Conservamos tu carrito y tu progreso, pero no confirmamos un checkout nuevo.';

  @override
  String get checkoutTimeoutError =>
      'La respuesta fue ambigua. Reintenta con la misma operación para conocer el resultado real.';

  @override
  String get checkoutUnauthorizedError =>
      'Tu sesión ya no permite confirmar el checkout. Inicia sesión nuevamente.';

  @override
  String get checkoutInvalidError => 'La selección del checkout no es válida.';

  @override
  String get checkoutUnavailableError =>
      'La tienda no puede ofrecer checkout por el momento.';

  @override
  String get checkoutConflictError =>
      'Esta operación no coincide con el intento anterior. Inicia una validación nueva.';

  @override
  String get checkoutStaleCartError =>
      'El carrito cambió. Lo estamos actualizando antes de volver a validar.';

  @override
  String get checkoutInvalidAddressError =>
      'La dirección no existe o no pertenece a esta cuenta.';

  @override
  String get checkoutUnsupportedZoneError =>
      'La dirección quedó fuera de la zona de entrega seleccionada.';

  @override
  String get checkoutSlotUnavailableError =>
      'El horario o la modalidad ya no están disponibles.';

  @override
  String get checkoutPaymentUnavailableError =>
      'El método de pago ya no está disponible. Elige una opción habilitada y vuelve a intentarlo.';

  @override
  String get checkoutCartUnavailableError =>
      'Revisa el carrito: está vacío o contiene productos no disponibles.';

  @override
  String get checkoutExpiredError =>
      'El resumen venció y debe validarse nuevamente.';

  @override
  String get checkoutNotFoundError =>
      'El resumen ya no existe o no pertenece a esta cuenta.';

  @override
  String get checkoutUnexpectedError =>
      'No pudimos verificar el checkout. No mostramos precios ni confirmaciones inferidas.';

  @override
  String get ordersAccountTitle => 'Mis pedidos';

  @override
  String get ordersAccountDescription =>
      'Consulta estados, detalles y retiros o entregas de tus pedidos.';

  @override
  String get ordersAccountAction => 'Ver pedidos';

  @override
  String get ordersTitle => 'Mis pedidos';

  @override
  String get ordersFiltersLabel => 'Filtrar pedidos';

  @override
  String get ordersFilterAll => 'Todos';

  @override
  String get ordersFilterActive => 'Activos';

  @override
  String get ordersFilterCompleted => 'Completados';

  @override
  String get ordersFilterCancelled => 'Cancelados';

  @override
  String get ordersFilterEmptyTitle => 'No hay pedidos en este estado';

  @override
  String get ordersFilterEmptyMessage =>
      'Elige otro filtro o actualiza para comprobar cambios.';

  @override
  String get ordersActiveOrder => 'Pedido activo';

  @override
  String get ordersRefreshTooltip => 'Actualizar pedidos';

  @override
  String get ordersLoading => 'Cargando tus pedidos…';

  @override
  String get ordersOffline =>
      'Sin conexión. Mostramos una copia de solo lectura guardada en este dispositivo.';

  @override
  String get ordersEmptyTitle => 'Aún no tienes pedidos';

  @override
  String get ordersEmptyMessage =>
      'Cuando confirmes una compra, podrás seguirla desde aquí.';

  @override
  String get ordersError => 'No pudimos cargar los pedidos.';

  @override
  String get ordersRetry => 'Reintentar';

  @override
  String get ordersLoadMore => 'Cargar más';

  @override
  String ordersItemCount(int count) {
    return '$count productos';
  }

  @override
  String ordersCardSemantics(String code, String status, String total) {
    return 'Pedido $code, estado $status, total $total.';
  }

  @override
  String ordersPlacedAt(String date) {
    return 'Creado $date';
  }

  @override
  String ordersUpdatedAt(String date) {
    return 'Actualizado $date';
  }

  @override
  String ordersCachedAt(String date) {
    return 'Copia guardada $date';
  }

  @override
  String get ordersTotalLabel => 'Total';

  @override
  String get ordersDetailTitle => 'Detalle del pedido';

  @override
  String get ordersProductsTitle => 'Productos';

  @override
  String get ordersFulfillmentTitle => 'Modalidad y horario';

  @override
  String get ordersTimelineTitle => 'Estado del pedido';

  @override
  String get ordersCancelAction => 'Cancelar pedido';

  @override
  String get ordersCancelConfirmTitle => '¿Cancelar este pedido?';

  @override
  String get ordersCancelConfirmMessage =>
      'La tienda validará nuevamente el estado y el plazo antes de cancelar. Esta acción no crea ni anula una venta fiscal.';

  @override
  String get ordersCancelSuccess =>
      'Pedido cancelado. Liberamos la disponibilidad reservada.';

  @override
  String get ordersCancelNotAllowed => 'Este pedido ya no admite cancelación.';

  @override
  String get ordersCancelVersionConflict =>
      'El estado cambió. Actualiza el pedido antes de volver a intentarlo.';

  @override
  String get ordersCancelAmbiguous =>
      'La respuesta fue ambigua. Conservamos el mismo intento para consultarlo de forma segura al reintentar.';

  @override
  String get ordersUnauthorized =>
      'Inicia sesión nuevamente para consultar tus pedidos.';

  @override
  String get ordersNotFound =>
      'El pedido no existe en esta tienda o no pertenece a esta cuenta.';

  @override
  String get ordersUnexpected =>
      'No pudimos verificar el pedido. La copia guardada permanece en modo de solo lectura.';

  @override
  String ordersCancellationDeadline(String date) {
    return 'Puedes cancelar hasta $date';
  }

  @override
  String get ordersDetailRefresh => 'Actualizar detalle';

  @override
  String get ordersBackToOrders => 'Volver a mis pedidos';

  @override
  String get deliveryTrackingTitle => 'Seguimiento de la entrega';

  @override
  String get deliveryTrackingLoading => 'Cargando novedades de la entrega…';

  @override
  String get deliveryTrackingUnavailable =>
      'El seguimiento de la entrega no está disponible en este momento. La cronología del pedido sigue vigente.';

  @override
  String get deliveryTrackingRetry => 'Actualizar estado de entrega';

  @override
  String get deliveryTrackingModeStatusOnly => 'Actualizaciones de estado';

  @override
  String get deliveryTrackingModeExternalCarrier =>
      'Empresa de transporte externa';

  @override
  String get deliveryTrackingModeLiveCourier => 'Repartidor en vivo';

  @override
  String deliveryTrackingWindow(String start, String end) {
    return 'Entrega prevista entre $start y $end';
  }

  @override
  String deliveryTrackingLastUpdated(String date) {
    return 'Última actualización de ubicación: $date';
  }

  @override
  String get deliveryTrackingLiveWaiting =>
      'La ubicación en vivo aparecerá cuando el repartidor inicie la entrega.';

  @override
  String get deliveryTrackingFresh => 'La ubicación se está actualizando';

  @override
  String get deliveryTrackingStale => 'La ubicación no se está actualizando';

  @override
  String get deliveryTrackingEnded => 'La ubicación dejó de compartirse';

  @override
  String deliveryTrackingCourierLabel(String label) {
    return 'Repartidor: $label';
  }

  @override
  String deliveryTrackingExternalCode(String code) {
    return 'Referencia $code';
  }

  @override
  String get deliveryTrackingPollingFallback =>
      'Las actualizaciones en vivo se están reconectando. Revisamos periódicamente el estado de la entrega.';

  @override
  String get deliveryTrackingOfflineCached =>
      'Mostramos la última copia cifrada guardada en este dispositivo.';

  @override
  String deliveryTrackingMapSemantics(String status, String updated) {
    return 'Mapa de la entrega. $status. $updated';
  }

  @override
  String get deliveryTrackingMapRecenter =>
      'Volver a centrar el mapa de la entrega';

  @override
  String get deliveryTrackingMapLoading => 'Cargando el mapa de la entrega';

  @override
  String get deliveryTrackingMapStoreMarker => 'Tienda';

  @override
  String get deliveryTrackingMapDestinationMarker => 'Destino de entrega';

  @override
  String get deliveryTrackingMapCourierMarker => 'Repartidor';

  @override
  String get deliveryTrackingFollowAction => 'Seguir entrega';

  @override
  String get deliveryTrackingInDeliveryIndicator => 'Entrega en curso';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get backendNotConfigured => '后端尚未配置：当前为离线开发模式。';

  @override
  String get backendChecking => '正在检查商店连接…';

  @override
  String get backendOffline => '当前无网络连接。你可以继续浏览并重试。';

  @override
  String get backendUnavailable => '商店暂时不可用。';

  @override
  String get backendAuthenticationRequired => '请从“账户”登录以继续。';

  @override
  String get backendRetry => '重试';

  @override
  String storefrontCacheFresh(String date) {
    return '已保存的副本更新于 $date。';
  }

  @override
  String storefrontCacheStale(String date) {
    return '这是 $date 保存的副本，价格和库存状态可能已变化。';
  }

  @override
  String get storefrontCacheRefreshing => '正在后台更新…';

  @override
  String get navigationHome => '首页';

  @override
  String get navigationCatalog => '商品目录';

  @override
  String get navigationOrders => '订单';

  @override
  String navigationCartBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '购物车，$count 件商品',
      zero: '购物车，无商品',
    );
    return '$_temp0';
  }

  @override
  String navigationOrdersBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '订单，$count 个进行中订单',
      zero: '订单，无进行中订单',
    );
    return '$_temp0';
  }

  @override
  String get navigationCart => '购物车';

  @override
  String get navigationAccount => '账户';

  @override
  String get homeTitle => '首页';

  @override
  String get homeFoundationMessage => '你很快就能在这里发现商店的最新内容。';

  @override
  String get catalogTitle => '商品目录';

  @override
  String get catalogFoundationMessage => '商品目录即将在这里开放。';

  @override
  String get cartTitle => '购物车';

  @override
  String get cartFoundationMessage => '可以选择商品后，你就能使用购物车。';

  @override
  String get accountTitle => '账户';

  @override
  String get accountFoundationMessage => '此功能开放后，你就能访问自己的账户。';

  @override
  String get homeWelcomeTitle => '准备好开始探索';

  @override
  String get homeWelcomeMessage => '我们正在准备商品目录，你可以先浏览商店的各个部分。';

  @override
  String get homeSearchLabel => '搜索商店';

  @override
  String get homeSearchHint => '你想找什么？';

  @override
  String get homeSelectedStore => '已选门店';

  @override
  String get homeDeliveryDestination => '配送目的地';

  @override
  String get homeStoreContextFallback => '供应情况由门店确认';

  @override
  String get homeActiveOrderTitle => '进行中的订单';

  @override
  String homeActiveOrderSemantics(String code, String status) {
    return '进行中的订单 $code，状态 $status';
  }

  @override
  String get homeCategoriesTitle => '按类别探索';

  @override
  String get homeCategoriesMessage => '商品目录开放后，类别将显示在这里。';

  @override
  String get homeExploreCategories => '查看类别';

  @override
  String get homeOffersTitle => '优惠';

  @override
  String get homeOffersEmptyTitle => '优惠即将推出';

  @override
  String get homeOffersEmptyMessage => '有真实优惠时，我们会在这里展示。';

  @override
  String get homeFeaturedTitle => '精选商品';

  @override
  String get homeFeaturedEmptyTitle => '精选商品即将推出';

  @override
  String get homeFeaturedEmptyMessage => '商品目录开放后，这里将展示真实商品。';

  @override
  String get homeExploreCatalog => '浏览商品目录';

  @override
  String get homeLoadingTitle => '正在加载商店';

  @override
  String get homeLoadingMessage => '正在准备类别、优惠和精选商品。';

  @override
  String get homeLoadErrorTitle => '无法加载商店';

  @override
  String get homeLoadErrorMessage => '请检查网络连接并重试。';

  @override
  String get homeUnavailableTitle => '商店暂不可用';

  @override
  String get homeUnavailableMessage => '公共商品目录目前不可用。';

  @override
  String get homeImageUnavailable => '图片不可用';

  @override
  String homePreviousPrice(String price) {
    return '原价 $price';
  }

  @override
  String homeDiscountPercent(String percent) {
    return '优惠 $percent%';
  }

  @override
  String get catalogSearchLabel => '搜索商品目录';

  @override
  String get catalogSearchHint => '搜索商品或类别';

  @override
  String get catalogSearchMinimum => '请输入至少 2 个字符进行搜索。';

  @override
  String get catalogClearSearch => '清除搜索';

  @override
  String get catalogFilterLabel => '筛选';

  @override
  String get catalogSortLabel => '排序';

  @override
  String get catalogControlsUnavailable => '搜索、筛选和排序将在下一步开放。';

  @override
  String get catalogFiltersLabel => '商品目录筛选';

  @override
  String catalogLoadedCount(int count) {
    return '已加载 $count 件商品';
  }

  @override
  String get catalogShowFilters => '显示筛选条件';

  @override
  String get catalogHideFilters => '隐藏筛选条件';

  @override
  String get catalogFiltersUnavailableDuringSearch =>
      '搜索时可以按类别筛选。清除搜索后可使用库存状态、折扣或排序。';

  @override
  String get catalogAvailabilityLabel => '库存状态';

  @override
  String get catalogAvailabilityAll => '全部';

  @override
  String get catalogAvailabilityAvailable => '有货';

  @override
  String get catalogAvailabilityLowStock => '库存不多';

  @override
  String get catalogAvailabilityUnavailable => '无货';

  @override
  String get catalogAvailabilityReservationOnly => '仅可预订';

  @override
  String get catalogAvailabilityPickupOnly => '仅可自提';

  @override
  String get catalogAvailabilityDeliveryOnly => '仅可配送';

  @override
  String get catalogDiscountedOnly => '仅显示折扣商品';

  @override
  String get catalogSortCatalog => '商品目录顺序';

  @override
  String get catalogSortName => '名称';

  @override
  String get catalogSortPriceAscending => '价格：从低到高';

  @override
  String get catalogSortPriceDescending => '价格：从高到低';

  @override
  String get catalogResetFilters => '重置筛选';

  @override
  String get productDetailTitle => '商品详情';

  @override
  String get productDetailLoading => '正在加载商品';

  @override
  String get productDetailUnavailableTitle => '商品不可用';

  @override
  String get productDetailUnavailableMessage => '该商品未发布或已不可用。';

  @override
  String get productDetailOfflineTitle => '你当前处于离线状态';

  @override
  String get productDetailOfflineMessage => '请连接网络以加载最新商品详情。';

  @override
  String get productDetailErrorTitle => '无法加载商品';

  @override
  String get productDetailErrorMessage => '请重试。未显示不完整的数据。';

  @override
  String get productDetailDescriptionLabel => '描述';

  @override
  String get productDetailNoDescription => '暂无公开描述。';

  @override
  String get productDetailCategoryLabel => '类别';

  @override
  String get productDetailBrandLabel => '品牌';

  @override
  String get productDetailPriceLabel => '价格';

  @override
  String productDetailSavings(String amount) {
    return '节省 $amount';
  }

  @override
  String productDetailImagePosition(int current, int total) {
    return '第 $current 张，共 $total 张';
  }

  @override
  String get productDetailAvailabilityLabel => '商业库存状态';

  @override
  String get productDetailFulfillmentLabel => '购买方式';

  @override
  String get productDetailPickup => '到店自提';

  @override
  String get productDetailDelivery => '配送';

  @override
  String get productDetailReservation => '预订';

  @override
  String get productDetailPromotionLabel => '当前促销';

  @override
  String get catalogCategoriesLabel => '类别';

  @override
  String get catalogAllCategories => '全部';

  @override
  String get catalogLoadingMore => '正在加载更多商品';

  @override
  String get catalogLoadMoreError => '无法加载更多商品';

  @override
  String get catalogConnectingTitle => '正在准备商品目录';

  @override
  String get catalogConnectingMessage => '我们正在检查商店是否可用。';

  @override
  String get catalogEmptyTitle => '暂无已发布商品';

  @override
  String get catalogEmptyMessage => '请尝试其他类别或稍后再来。';

  @override
  String get catalogOfflineTitle => '你当前处于离线状态';

  @override
  String get catalogOfflineMessage => '请检查网络连接并重试。应用的其他部分仍可使用。';

  @override
  String get catalogUnavailableTitle => '商店暂时不可用';

  @override
  String get catalogUnavailableMessage => '目前无法准备公开商品目录。';

  @override
  String get catalogRetryTitle => '无法检查商店状态';

  @override
  String get catalogRetryMessage => '请重试。你也可以继续浏览其他页面。';

  @override
  String get cartEmptyTitle => '购物车是空的';

  @override
  String get cartEmptyMessage => '商品目录开放后，你可以在这里添加商品。';

  @override
  String get cartExploreCatalog => '浏览商品目录';

  @override
  String get accountGuestTitle => '你的账户';

  @override
  String get accountGuestBenefit => '登录后可使用个人功能。无需账户也可以继续浏览。';

  @override
  String get accountContinueWithGoogle => '使用 Google 继续';

  @override
  String get accountGoogleComingSoon => 'Google 登录功能即将开放。';

  @override
  String get accountBrowseAsGuest => '以访客身份继续浏览';

  @override
  String get accountAuthenticatedTitle => '已登录';

  @override
  String get accountNameFallback => '顾客';

  @override
  String get accountEmailFallback => '邮箱不可用';

  @override
  String get accountSessionActive => '你的会话处于活动状态。';

  @override
  String get accountLogout => '退出登录';

  @override
  String get accountPersonalSettingsTitle => '个人资料、地址与隐私';

  @override
  String get accountPersonalSettingsDescription => '管理身份、语言、地址和 Storefront 数据。';

  @override
  String get accountNotificationsDescription => '选择如何接收真实的订单更新。';

  @override
  String get accountSigningInTitle => '正在打开安全登录';

  @override
  String get accountSigningInMessage => '请在浏览器中完成登录，然后返回应用。';

  @override
  String get accountCancelSignIn => '取消登录';

  @override
  String get accountCancellingTitle => '正在取消登录';

  @override
  String get accountCancellingMessage => '正在安全地关闭本次登录尝试。';

  @override
  String get accountCancelledTitle => '登录已取消';

  @override
  String get accountCancelledMessage => '你的账户没有发生更改，可以重新尝试。';

  @override
  String get accountRetry => '重试';

  @override
  String get accountAuthErrorTitle => '无法登录';

  @override
  String get accountConfigurationErrorTitle => '登录不可用';

  @override
  String get accountSigningOut => '正在退出…';

  @override
  String get accountAuthOffline => '请检查网络连接后重试。';

  @override
  String get accountAuthProviderUnavailable => 'Google 暂时不可用，请稍后重试。';

  @override
  String get accountAuthBrowserLaunchFailed => '无法打开浏览器以继续。';

  @override
  String get accountAuthInvalidCallback => '登录返回无效，请重新发起登录。';

  @override
  String get accountAuthSessionExpired => '你的会话已结束，可以重新登录。';

  @override
  String get accountAuthSecureStorageUnavailable => '此设备无法安全保护会话。';

  @override
  String get accountAuthConfiguration => '当前环境尚未配置 Google 登录。';

  @override
  String get accountAuthUnexpected => '出现意外问题，你可以重试。';

  @override
  String accountAvatarLabel(String name) {
    return '$name的头像';
  }

  @override
  String get storefrontComingSoonLabel => '即将推出';

  @override
  String get favoritesTitle => '收藏';

  @override
  String get favoritesOpen => '查看收藏';

  @override
  String get favoritesEmptyTitle => '还没有收藏商品';

  @override
  String get favoritesEmptyMessage => '收藏商品后，即使离线也能快速找到它们。';

  @override
  String get favoritesErrorTitle => '无法打开收藏';

  @override
  String get favoritesErrorMessage => '请重试。你的选择会保留在此设备上。';

  @override
  String get favoriteAdd => '添加到收藏';

  @override
  String get favoriteRemove => '从收藏中移除';

  @override
  String get favoriteAdded => '商品已添加到收藏。';

  @override
  String get favoriteRemoved => '商品已从收藏中移除。';

  @override
  String get favoriteUnavailableTitle => '商品暂不可用';

  @override
  String get favoriteUnavailableMessage => '你可以保留此收藏，也可以将它从列表中移除。';

  @override
  String get productShare => '分享商品';

  @override
  String productShareText(String name, String uri) {
    return '在 Merchandise Control 查看$name：\n$uri';
  }

  @override
  String get productShareError => '无法打开分享选项。';

  @override
  String get customerAccountLoading => '正在加载账户数据';

  @override
  String get customerAccountRetry => '重试';

  @override
  String get customerAccountOffline => '你当前处于离线状态。已加载的数据会保留；请联网后再保存更改。';

  @override
  String get customerAccountUnauthorized => '当前会话不再允许此操作，请重新登录。';

  @override
  String get customerAccountInvalid => '请检查填写的信息后再继续。';

  @override
  String get customerAccountConflict => '这些数据已在其他位置更改，请刷新后重试。';

  @override
  String get customerAccountTimeout => '操作超时。你可以安全重试，不会重复提交。';

  @override
  String get customerAccountUnavailable => '账户数据暂时不可用。';

  @override
  String get customerAccountUnexpected => '无法完成操作。更改不会显示为已确认。';

  @override
  String get customerProfileTitle => '个人资料';

  @override
  String get customerProfileDescription => '选择显示名称和应用语言。';

  @override
  String get customerProfileNameLabel => '显示名称';

  @override
  String get customerProfileNameHint => '可选';

  @override
  String get customerProfileLanguageLabel => '语言';

  @override
  String get customerProfileLanguageEsCl => 'Español (Chile)';

  @override
  String get customerProfileLanguageIt => 'Italiano';

  @override
  String get customerProfileLanguageEn => 'English';

  @override
  String get customerProfileLanguageZhHans => '简体中文';

  @override
  String get customerProfileSave => '保存个人资料';

  @override
  String get customerProfileSaved => '个人资料已保存。';

  @override
  String get customerProfileDeleted => '公开个人资料数据已重置。';

  @override
  String get customerProfileResetTitle => '重置个人资料';

  @override
  String get customerProfileResetMessage => '这会移除个人资料中的名称、语言和隐私同意。地址和登录状态保持不变。';

  @override
  String get customerProfileResetAction => '重置';

  @override
  String get customerAddressesTitle => '地址';

  @override
  String get customerAddressesDescription => '保存邮寄信息以便以后使用。配送可用性会在结账时验证。';

  @override
  String get customerAddressesEmptyTitle => '尚未保存地址';

  @override
  String get customerAddressesEmptyMessage => '需要准备配送时，可随时添加地址。';

  @override
  String get customerAddressAdd => '添加地址';

  @override
  String get customerAddressEdit => '编辑地址';

  @override
  String get customerAddressDeleteTitle => '删除地址';

  @override
  String customerAddressDeleteMessage(String label) {
    return '要删除地址“$label”吗？';
  }

  @override
  String get customerAddressDeleteAction => '删除';

  @override
  String get customerAddressSaved => '地址已保存。';

  @override
  String get customerAddressDeleted => '地址已删除。';

  @override
  String get customerAddressDefault => '默认';

  @override
  String get customerAddressSetDefault => '设为默认地址';

  @override
  String get customerAddressDefaultChanged => '默认地址已更新。';

  @override
  String get customerAddressLabel => '标签';

  @override
  String get customerAddressRecipient => '收件人姓名';

  @override
  String get customerAddressLine1 => '地址';

  @override
  String get customerAddressLine2 => '公寓、办公室或其他说明（可选）';

  @override
  String get customerAddressCommune => '区或市镇';

  @override
  String get customerAddressRegion => '地区';

  @override
  String get customerAddressPostalCode => '邮政编码（可选）';

  @override
  String get customerAddressCountryCode => '国家代码';

  @override
  String get customerAddressInstructions => '配送说明（可选）';

  @override
  String customerAddressSemantics(
    String label,
    String address,
    String commune,
  ) {
    return '地址 $label：$address，$commune';
  }

  @override
  String get customerPrivacyTitle => '隐私与数据';

  @override
  String get customerPrivacyDescription =>
      '你可以管理隐私同意，并查看与账户关联的 Storefront 数据副本。';

  @override
  String get customerPrivacyConsentTitle => '隐私同意';

  @override
  String get customerPrivacyConsentDescription => '记录或撤回对当前版本的同意。系统不会默认开启。';

  @override
  String get customerPrivacyConsentUpdated => '隐私偏好已更新。';

  @override
  String get customerDataExportAction => '查看我的数据导出';

  @override
  String get customerDataExportTitle => '你的 Storefront 数据';

  @override
  String get customerDeletionTitle => '删除账户';

  @override
  String get customerDeletionDescription => '你可以提交可审核的删除请求。应用不会立即删除账户。';

  @override
  String get customerDeletionPending => '请求正在等待处理，并将按照数据保留政策执行。';

  @override
  String get customerDeletionConfirmTitle => '请求删除账户';

  @override
  String get customerDeletionConfirmMessage => '请求会被记录以供审核。会话不会关闭，数据也不会立即删除。';

  @override
  String get customerDeletionRequestAction => '请求删除';

  @override
  String get customerDeletionCancelAction => '取消请求';

  @override
  String get customerDeletionRequested => '删除请求已记录。';

  @override
  String get customerDeletionCancelled => '删除请求已取消。';

  @override
  String get customerDialogCancel => '取消';

  @override
  String get customerDialogSave => '保存';

  @override
  String get customerDialogClose => '关闭';

  @override
  String get customerFieldRequired => '此字段为必填项。';

  @override
  String get customerFieldInvalid => '请检查此字段的格式和长度。';

  @override
  String get customerNotificationsTitle => '通知';

  @override
  String get customerNotificationsDescription => '选择是否接收订单和预订的重要更新。系统权限将单独请求。';

  @override
  String get customerNotificationsLoading => '正在加载通知设置';

  @override
  String get customerNotificationsProviderUnavailable =>
      '此版本尚未配置推送通知。未注册任何令牌，也未模拟任何权限。';

  @override
  String get customerNotificationsActive => '通知已启用并由服务器确认。';

  @override
  String get customerNotificationsNotRequested => '你尚未选择是否接收通知。';

  @override
  String get customerNotificationsDenied => '你已选择不接收通知，可随时更改此偏好。';

  @override
  String get customerNotificationsRevoked => '此安装的通知已撤销。';

  @override
  String get customerNotificationsPending => '更改已保存在此设备上，但尚未由服务器确认。';

  @override
  String get customerNotificationsOffline => '离线时无法确认更改。网络恢复后请重试。';

  @override
  String get customerNotificationsTimeout => '服务器响应超时。你可以重试，同一幂等操作不会重复执行。';

  @override
  String get customerNotificationsUnauthorized => '当前会话已无法更新通知设置。';

  @override
  String get customerNotificationsInvalid => '通知配置无效。';

  @override
  String get customerNotificationsConflict => '此幂等操作与之前的请求不一致。请刷新后重试。';

  @override
  String get customerNotificationsUnavailable => '无法更新通知。此更改不会显示为已确认。';

  @override
  String get customerNotificationsEnable => '启用';

  @override
  String get customerNotificationsNotNow => '暂不';

  @override
  String get customerNotificationsRevoke => '撤销';

  @override
  String get customerNotificationsRetry => '重试';

  @override
  String reservationHoldCreateAction(int quantity) {
    return '保留 $quantity 件商品 15 分钟';
  }

  @override
  String get reservationHoldSignInAction => '登录后保留商品';

  @override
  String get reservationHoldLoading => '正在向商店确认保留状态';

  @override
  String get reservationHoldActive => '商品保留中';

  @override
  String get reservationHoldExpiring => '保留即将到期';

  @override
  String reservationHoldRemaining(String time) {
    return '剩余 $time';
  }

  @override
  String get reservationHoldExpired => '保留已到期，库存名额已返还商店。';

  @override
  String get reservationHoldReleased => '保留已释放。';

  @override
  String get reservationHoldConsumed => '此保留已使用。';

  @override
  String get reservationHoldReleaseAction => '释放保留';

  @override
  String get reservationHoldRetryAction => '安全重试';

  @override
  String get reservationHoldDismissAction => '关闭状态';

  @override
  String get reservationHoldPendingRetry => '待处理操作将继续使用同一幂等键。';

  @override
  String get reservationHoldOfflineError => '当前离线。新的保留不会显示为已确认。';

  @override
  String get reservationHoldTimeoutError => '结果尚不明确。请安全重试以获取服务器状态。';

  @override
  String get reservationHoldUnauthorizedError => '请重新登录以管理保留。';

  @override
  String get reservationHoldInvalidError => '保留请求无效。';

  @override
  String get reservationHoldConflictError => '幂等键属于其他请求。请重新创建保留。';

  @override
  String get reservationHoldUnavailableError => '商店已无法保留此数量。';

  @override
  String get reservationHoldLimitError => '已达到有效保留数量上限。';

  @override
  String get reservationHoldNotFoundError => '保留已不存在或不属于此账户。';

  @override
  String get reservationHoldUnexpectedError => '无法验证保留，请重试。';

  @override
  String get cartAddAction => '加入购物车';

  @override
  String cartAddQuantityAction(int quantity) {
    return '将 $quantity 件加入购物车';
  }

  @override
  String get cartAddedNotice => '商品已加入购物车。';

  @override
  String get cartGuestSyncMessage => '购物车保存在此设备上，并可离线使用。';

  @override
  String get cartAccountSyncMessage => '购物车已关联账户，并由商店验证。';

  @override
  String cartIndicativeSubtotal(String price) {
    return '预计小计：$price';
  }

  @override
  String cartConfirmedSubtotal(String price) {
    return '已验证小计：$price';
  }

  @override
  String get cartRevalidateAction => '验证购物车';

  @override
  String get cartEstimatedLabel => '预计';

  @override
  String get cartValidatedLabel => '已验证';

  @override
  String get cartRetryAction => '重试';

  @override
  String get cartClearAction => '清空购物车';

  @override
  String get cartClearTitle => '清空购物车？';

  @override
  String get cartClearMessage => '此购物车中的所有商品都将被移除。';

  @override
  String get cartRemoveAction => '移除';

  @override
  String cartQuantityLabel(int quantity) {
    return '数量：$quantity';
  }

  @override
  String get cartDecreaseQuantity => '减少数量';

  @override
  String get cartIncreaseQuantity => '增加数量';

  @override
  String get cartUnavailableLine => '此商品已不可用。';

  @override
  String get cartPriceChangedLine => '价格已变更，请查看当前金额。';

  @override
  String get cartPromotionChangedLine => '促销已变更，请查看当前金额。';

  @override
  String get cartMergedNotice => '此设备的购物车已与账户同步。';

  @override
  String get cartPartialMergeNotice => '可用商品已同步；其余商品保留以供查看。';

  @override
  String get cartRevalidatedNotice => '价格和库存已由商店验证。';

  @override
  String get cartUpdatedNotice => '数量已更新。';

  @override
  String get cartRemovedNotice => '商品已从购物车移除。';

  @override
  String get cartClearedNotice => '购物车已清空。';

  @override
  String get cartOfflineError => '当前离线，本地购物车仍可使用。';

  @override
  String get cartTimeoutError => '商店响应超时。重试不会重复执行该操作。';

  @override
  String get cartUnauthorizedError => '请重新登录以同步购物车。';

  @override
  String get cartConflictError => '购物车已在其他位置更改，请刷新后重试。';

  @override
  String get cartUnavailableError => '暂时无法更新购物车。';

  @override
  String get cartInvalidError => '购物车请求无效。';

  @override
  String get cartLimitReached => '购物车中的不同商品数量已达上限。';

  @override
  String get cartProductUnavailable => '此商品已无法加入购物车。';

  @override
  String get cartSignInAction => '登录';

  @override
  String get cartPendingRetry => '有一项待处理操作可以安全重试。';

  @override
  String get cartPriceDisclaimer => '创建订单前将再次确认价格和库存。';

  @override
  String cartLineSemantics(String name, int quantity, String price) {
    return '$name，数量 $quantity，$price';
  }

  @override
  String get cartCheckoutAction => '前往结账';

  @override
  String get cartSignInCheckoutAction => '登录并继续';

  @override
  String get checkoutTitle => '结账';

  @override
  String get checkoutStepMode => '方式';

  @override
  String get checkoutStepDestination => '目的地';

  @override
  String get checkoutStepSlot => '时段';

  @override
  String get checkoutStepReview => '核对';

  @override
  String get checkoutStepConfirmation => '确认';

  @override
  String checkoutStepProgress(int current, int total, String title) {
    return '第 $current 步，共 $total 步：$title';
  }

  @override
  String get checkoutAuthTitle => '登录后确认';

  @override
  String get checkoutAuthMessage => '无需账户即可浏览并保留购物车。验证地址、价格和库存时需要您的客户会话。';

  @override
  String get checkoutContinueBrowsing => '返回购物车';

  @override
  String get checkoutUnavailableTitle => '暂时无法结账';

  @override
  String get checkoutRetryAction => '安全重试';

  @override
  String get checkoutContinueAction => '继续';

  @override
  String get checkoutBackAction => '返回';

  @override
  String get checkoutBackToCart => '返回购物车';

  @override
  String get checkoutRestartAction => '重新开始';

  @override
  String get checkoutModeTitle => '您希望如何收取商品？';

  @override
  String get checkoutModeMessage => '仅显示此商店已配置且可用的方式。';

  @override
  String get checkoutModePickup => '自提';

  @override
  String get checkoutModePickupDescription => '前往可用的自提点领取商品。';

  @override
  String get checkoutModeReservation => '预订';

  @override
  String get checkoutModeReservationDescription => '确认有效预订后到店领取。';

  @override
  String get checkoutModeDelivery => '配送';

  @override
  String get checkoutModeDeliveryDescription => '配送至有效配送区域内的地址。';

  @override
  String get checkoutDeliveryAddressTitle => '配送地址';

  @override
  String get checkoutDeliveryAddressMessage => '商店将在服务器上验证地址、区域和费用。';

  @override
  String get checkoutNoAddresses => '选择配送前，请先向账户添加地址。';

  @override
  String get checkoutManageAddresses => '管理地址';

  @override
  String get checkoutUnsupportedAddress => '不在可用区域内';

  @override
  String get checkoutPickupPointTitle => '自提点';

  @override
  String get checkoutPickupPointMessage => '选择此方式可用的公开地点。';

  @override
  String get checkoutSlotTitle => '可用时段';

  @override
  String get checkoutSlotMessage => '验证结账时将再次确认容量。';

  @override
  String get checkoutNoSlots => '此选择已无可用时段。';

  @override
  String get checkoutReviewTitle => '核对您的选择';

  @override
  String get checkoutReviewMessage => '此总额仍为预估值。商店将重新读取购物车、促销和库存。';

  @override
  String get checkoutPaymentTitle => '付款方式';

  @override
  String get checkoutPaymentMessage => '请选择此履约方式支持的付款方式。创建订单时，商店会再次验证。';

  @override
  String get checkoutPaymentPayAtPickup => '取货时付款';

  @override
  String get checkoutPaymentPayAtPickupDescription => '取货或确认预订时在门店付款。';

  @override
  String get checkoutPaymentCashOnDelivery => '货到付款';

  @override
  String get checkoutPaymentCashOnDeliveryDescription =>
      '订单送达时付款，仅适用于已启用的配送区域。';

  @override
  String get checkoutPaymentOnline => '在线支付';

  @override
  String get checkoutPaymentOnlineUnavailable => 'Storefront v1 尚未配置。';

  @override
  String get checkoutPaymentRequired => '请选择可用的付款方式以创建订单。';

  @override
  String get checkoutPaymentUnavailable => '此履约方式暂无可用付款方式。';

  @override
  String get checkoutPaymentMethodLabel => '付款方式';

  @override
  String get checkoutPaymentStatusLabel => '付款状态';

  @override
  String get checkoutPaymentStatusDueAtFulfillment => '配送或取货时待付款';

  @override
  String get checkoutPaymentStatusPendingProvider => '等待支付服务商';

  @override
  String get checkoutPaymentStatusProcessing => '处理中';

  @override
  String get checkoutPaymentStatusAuthorized => '已授权';

  @override
  String get checkoutPaymentStatusCollected => '已收款';

  @override
  String get checkoutPaymentStatusFailed => '失败';

  @override
  String get checkoutPaymentStatusCancelled => '已取消';

  @override
  String get checkoutPaymentStatusRefundPending => '退款处理中';

  @override
  String get checkoutPaymentStatusRefundFailed => '退款失败';

  @override
  String get checkoutPaymentStatusRefunded => '已退款';

  @override
  String get checkoutServerValidationNotice => '价格、折扣、费用和总额均由服务器计算。应用不会发送权威总额。';

  @override
  String get checkoutSubtotalLabel => '小计';

  @override
  String get checkoutDeliveryFeeLabel => '配送费';

  @override
  String get checkoutEstimatedTotalLabel => '预估总额';

  @override
  String get checkoutAuthoritativeTotalLabel => '已验证总额';

  @override
  String get checkoutValidateAction => '验证价格和库存';

  @override
  String get checkoutConfirmationTitle => '结账确认';

  @override
  String get checkoutQuoteReadyMessage => '商店已验证此摘要，请在过期前确认。';

  @override
  String get checkoutReviewChangesMessage => '检测到变更。请查看并明确接受后再继续。';

  @override
  String get checkoutConfirmedMessage => '摘要已由商店确认。';

  @override
  String get checkoutExpiredMessage => '此摘要已过期，请重新验证后再继续。';

  @override
  String checkoutQuoteRemaining(String time) {
    return '此摘要将在 $time 后过期';
  }

  @override
  String get checkoutChangesTitle => '需要查看的变更';

  @override
  String get checkoutConfirmAction => '确认摘要';

  @override
  String get checkoutAcceptChangesAction => '接受变更并确认';

  @override
  String get checkoutOrderDeferredNotice => '创建订单前，商店将重新验证价格、优惠、库存和时间段。';

  @override
  String get checkoutCreateOrderAction => '创建订单';

  @override
  String get checkoutOrderReceiptTitle => '订单已确认';

  @override
  String get checkoutOrderReceiptMessage => '订单已按商店确认的价格和履约方式保存。';

  @override
  String get checkoutOrderCodeLabel => '订单编号';

  @override
  String checkoutOrderCodeSemantics(String code) {
    return '订单编号 $code';
  }

  @override
  String checkoutOrderConfirmedMessage(String code) {
    return '订单 $code 已确认。';
  }

  @override
  String get checkoutOrderStatusLabel => '状态';

  @override
  String get checkoutOrderPlacedAtLabel => '创建时间';

  @override
  String get checkoutOrderAuthoritativeNotice => '此凭证总额由服务器计算并确认。客户订单不是税务销售。';

  @override
  String get checkoutOrderConfirmedNotice => '订单已创建并由商店确认。';

  @override
  String get checkoutContinueShoppingAction => '继续购物';

  @override
  String get checkoutOrderStatusConfirmed => '已确认';

  @override
  String get checkoutOrderStatusAccepted => '已接受';

  @override
  String get checkoutOrderStatusRejected => '已拒绝';

  @override
  String get checkoutOrderStatusPreparing => '准备中';

  @override
  String get checkoutOrderStatusReady => '已备妥';

  @override
  String get checkoutOrderStatusOutForDelivery => '配送中';

  @override
  String get checkoutOrderStatusCompleted => '已完成';

  @override
  String get checkoutOrderStatusCancelled => '已取消';

  @override
  String get checkoutRestoredNotice => '已恢复您的结账进度。';

  @override
  String get checkoutQuoteChangedNotice => '商店已更新摘要，请查看变更。';

  @override
  String get checkoutConfirmedNotice => '结账已确认。';

  @override
  String get checkoutPriceChanged => '某件商品的价格已变更。';

  @override
  String get checkoutPromotionChanged => '某项促销已变更或结束。';

  @override
  String get checkoutProductUnavailable => '某件商品已不可用。';

  @override
  String get checkoutHoldRequired => '此预订需要有效的库存保留。';

  @override
  String get checkoutOfflineError => '当前离线。我们会保留购物车和进度，但无法确认新的结账。';

  @override
  String get checkoutTimeoutError => '响应结果不明确。请使用同一操作重试，以获取实际结果。';

  @override
  String get checkoutUnauthorizedError => '当前会话已无法确认结账，请重新登录。';

  @override
  String get checkoutInvalidError => '结账选择无效。';

  @override
  String get checkoutUnavailableError => '商店暂时无法提供结账服务。';

  @override
  String get checkoutConflictError => '此操作与上次尝试不一致，请开始新的验证。';

  @override
  String get checkoutStaleCartError => '购物车已变更。我们会先刷新，再重新验证。';

  @override
  String get checkoutInvalidAddressError => '该地址不存在或不属于此账户。';

  @override
  String get checkoutUnsupportedZoneError => '该地址不在所选配送区域内。';

  @override
  String get checkoutSlotUnavailableError => '所选时段或方式已不可用。';

  @override
  String get checkoutPaymentUnavailableError => '付款方式已不可用。请选择已启用的选项后重试。';

  @override
  String get checkoutCartUnavailableError => '请检查购物车：购物车为空或包含不可用商品。';

  @override
  String get checkoutExpiredError => '摘要已过期，必须重新验证。';

  @override
  String get checkoutNotFoundError => '摘要已不存在或不属于此账户。';

  @override
  String get checkoutUnexpectedError => '无法验证结账。不会显示推断的价格或确认状态。';

  @override
  String get ordersAccountTitle => '我的订单';

  @override
  String get ordersAccountDescription => '查看订单状态、详情以及自提或配送信息。';

  @override
  String get ordersAccountAction => '查看订单';

  @override
  String get ordersTitle => '我的订单';

  @override
  String get ordersFiltersLabel => '筛选订单';

  @override
  String get ordersFilterAll => '全部';

  @override
  String get ordersFilterActive => '进行中';

  @override
  String get ordersFilterCompleted => '已完成';

  @override
  String get ordersFilterCancelled => '已取消';

  @override
  String get ordersFilterEmptyTitle => '此状态下没有订单';

  @override
  String get ordersFilterEmptyMessage => '请选择其他筛选条件，或刷新查看变化。';

  @override
  String get ordersActiveOrder => '进行中的订单';

  @override
  String get ordersRefreshTooltip => '刷新订单';

  @override
  String get ordersLoading => '正在加载订单…';

  @override
  String get ordersOffline => '当前离线。这里显示的是保存在此设备上的只读副本。';

  @override
  String get ordersEmptyTitle => '暂无订单';

  @override
  String get ordersEmptyMessage => '确认购买后，你可以在这里跟踪订单。';

  @override
  String get ordersError => '无法加载订单。';

  @override
  String get ordersRetry => '重试';

  @override
  String get ordersLoadMore => '加载更多';

  @override
  String ordersItemCount(int count) {
    return '$count 件商品';
  }

  @override
  String ordersCardSemantics(String code, String status, String total) {
    return '订单 $code，状态 $status，总计 $total。';
  }

  @override
  String ordersPlacedAt(String date) {
    return '创建于 $date';
  }

  @override
  String ordersUpdatedAt(String date) {
    return '更新于 $date';
  }

  @override
  String ordersCachedAt(String date) {
    return '保存的副本 $date';
  }

  @override
  String get ordersTotalLabel => '总计';

  @override
  String get ordersDetailTitle => '订单详情';

  @override
  String get ordersProductsTitle => '商品';

  @override
  String get ordersFulfillmentTitle => '履约方式和时间';

  @override
  String get ordersTimelineTitle => '订单状态';

  @override
  String get ordersCancelAction => '取消订单';

  @override
  String get ordersCancelConfirmTitle => '取消此订单？';

  @override
  String get ordersCancelConfirmMessage =>
      '取消前，商店会重新检查状态和截止时间。此操作不会创建或撤销税务销售记录。';

  @override
  String get ordersCancelSuccess => '订单已取消，预留的可用量已释放。';

  @override
  String get ordersCancelNotAllowed => '此订单已不能取消。';

  @override
  String get ordersCancelVersionConflict => '订单状态已变化。请刷新后再试。';

  @override
  String get ordersCancelAmbiguous => '响应结果不明确。我们保留了同一次请求，以便重试时安全确认结果。';

  @override
  String get ordersUnauthorized => '请重新登录后查看订单。';

  @override
  String get ordersNotFound => '此订单不属于当前商店或当前账户。';

  @override
  String get ordersUnexpected => '无法验证此订单。保存的副本将保持只读。';

  @override
  String ordersCancellationDeadline(String date) {
    return '可在 $date 前取消';
  }

  @override
  String get ordersDetailRefresh => '刷新详情';

  @override
  String get ordersBackToOrders => '返回我的订单';

  @override
  String get deliveryTrackingTitle => '配送跟踪';

  @override
  String get deliveryTrackingLoading => '正在加载配送动态…';

  @override
  String get deliveryTrackingUnavailable => '配送跟踪目前不可用。订单时间线仍可查看。';

  @override
  String get deliveryTrackingRetry => '刷新配送状态';

  @override
  String get deliveryTrackingModeStatusOnly => '状态更新';

  @override
  String get deliveryTrackingModeExternalCarrier => '外部承运商';

  @override
  String get deliveryTrackingModeLiveCourier => '配送员实时位置';

  @override
  String deliveryTrackingWindow(String start, String end) {
    return '预计在 $start 至 $end 之间送达';
  }

  @override
  String deliveryTrackingLastUpdated(String date) {
    return '上次位置更新时间：$date';
  }

  @override
  String get deliveryTrackingLiveWaiting => '配送员开始配送后将显示实时位置。';

  @override
  String get deliveryTrackingFresh => '位置正在更新';

  @override
  String get deliveryTrackingStale => '位置暂未更新';

  @override
  String get deliveryTrackingEnded => '位置共享已结束';

  @override
  String deliveryTrackingCourierLabel(String label) {
    return '配送员：$label';
  }

  @override
  String deliveryTrackingExternalCode(String code) {
    return '参考编号 $code';
  }

  @override
  String get deliveryTrackingPollingFallback => '实时更新正在重新连接。系统会定期检查配送状态。';

  @override
  String get deliveryTrackingOfflineCached => '当前显示此设备上保存的最新加密副本。';

  @override
  String deliveryTrackingMapSemantics(String status, String updated) {
    return '配送地图。$status。$updated';
  }

  @override
  String get deliveryTrackingMapRecenter => '重新居中配送地图';

  @override
  String get deliveryTrackingMapLoading => '正在加载配送地图';

  @override
  String get deliveryTrackingMapStoreMarker => '商店';

  @override
  String get deliveryTrackingMapDestinationMarker => '配送目的地';

  @override
  String get deliveryTrackingMapCourierMarker => '配送员';

  @override
  String get deliveryTrackingFollowAction => '跟踪配送';

  @override
  String get deliveryTrackingInDeliveryIndicator => '配送中';
}
