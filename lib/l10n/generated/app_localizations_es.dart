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
