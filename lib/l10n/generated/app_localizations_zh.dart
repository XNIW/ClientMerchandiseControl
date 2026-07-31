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
  String get catalogSearchLabel => 'Buscar en el catálogo';

  @override
  String get catalogSearchHint => 'Busca productos o categorías';

  @override
  String get catalogFilterLabel => 'Filtrar';

  @override
  String get catalogSortLabel => 'Ordenar';

  @override
  String get catalogControlsUnavailable =>
      'Los filtros y el orden estarán disponibles con el catálogo.';

  @override
  String get catalogConnectingTitle => 'Preparando el catálogo';

  @override
  String get catalogConnectingMessage =>
      'Estamos comprobando si la tienda está disponible.';

  @override
  String get catalogEmptyTitle => 'Catálogo público aún no conectado';

  @override
  String get catalogEmptyMessage =>
      'Podrás explorar productos cuando la tienda publique su catálogo.';

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
  String accountAvatarLabel(String name) {
    return 'Avatar de $name';
  }

  @override
  String get storefrontComingSoonLabel => 'Próximamente';
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
  String get catalogSearchLabel => '搜索商品目录';

  @override
  String get catalogSearchHint => '搜索商品或类别';

  @override
  String get catalogFilterLabel => '筛选';

  @override
  String get catalogSortLabel => '排序';

  @override
  String get catalogControlsUnavailable => '筛选和排序功能将随商品目录一起开放。';

  @override
  String get catalogConnectingTitle => '正在准备商品目录';

  @override
  String get catalogConnectingMessage => '我们正在检查商店是否可用。';

  @override
  String get catalogEmptyTitle => '公开商品目录尚未连接';

  @override
  String get catalogEmptyMessage => '商店发布商品目录后，你就可以浏览商品。';

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
  String accountAvatarLabel(String name) {
    return '$name的头像';
  }

  @override
  String get storefrontComingSoonLabel => '即将推出';
}
