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
}
