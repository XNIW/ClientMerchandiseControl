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
      'La base de la tienda está lista. El catálogo público se conectará en una tarea posterior.';

  @override
  String get catalogTitle => 'Catálogo';

  @override
  String get catalogFoundationMessage =>
      'El catálogo todavía no está conectado. Aquí se mostrarán solo productos publicados.';

  @override
  String get cartTitle => 'Carrito';

  @override
  String get cartFoundationMessage =>
      'El carrito se implementará cuando exista el contrato público de precios y disponibilidad.';

  @override
  String get accountTitle => 'Cuenta';

  @override
  String get accountFoundationMessage =>
      'El perfil del cliente y el acceso seguro se implementarán en tareas posteriores.';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get backendNotConfigured => '后端尚未配置：当前为离线开发模式。';

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
  String get homeFoundationMessage => '商店应用基础已就绪。公共商品目录将在后续任务中接入。';

  @override
  String get catalogTitle => '商品目录';

  @override
  String get catalogFoundationMessage => '商品目录尚未接入。此处未来只显示已发布的商品。';

  @override
  String get cartTitle => '购物车';

  @override
  String get cartFoundationMessage => '购物车将在公共价格与库存合同确定后实现。';

  @override
  String get accountTitle => '账户';

  @override
  String get accountFoundationMessage => '客户资料和安全登录将在后续任务中实现。';
}
