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
}
