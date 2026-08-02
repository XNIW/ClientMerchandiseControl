import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/app/branding/app_brand.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({Locale? locale}) {
    return ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(AppConfig.fromValues())],
      child: ClientMerchandiseControlApp(locale: locale),
    );
  }

  test('espone soltanto es, it, en e cinese semplificato', () {
    expect(appSupportedLocales, const [
      Locale('es', 'CL'),
      Locale('it'),
      Locale('en'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    ]);
    expect(appFallbackLocale, const Locale('es', 'CL'));
    expect(appSupportedLocales, isNot(contains(const Locale('zh'))));
    expect(appSupportedLocales, isNot(contains(const Locale('es'))));
  });

  test('mappa soltanto la preferenza locale owner salvata dal profilo', () {
    expect(customerLocaleFromTag('es-CL'), appFallbackLocale);
    expect(customerLocaleFromTag('it'), const Locale('it'));
    expect(customerLocaleFromTag('en'), const Locale('en'));
    expect(
      customerLocaleFromTag('zh-Hans'),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    );
    expect(customerLocaleFromTag('fr'), isNull);
    expect(customerLocaleFromTag(null), isNull);
  });

  test('scorre tutte le preferenze e seleziona la prima supportata', () {
    expect(
      resolveAppLocale(const [Locale('de'), Locale('it')], appSupportedLocales),
      const Locale('it'),
    );
    expect(
      resolveAppLocale(const [
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        Locale('en'),
      ], appSupportedLocales),
      const Locale('en'),
    );
  });

  test('usa lo spagnolo per lista nulla o vuota e per es-CL', () {
    expect(resolveAppLocale(null, appSupportedLocales), appFallbackLocale);
    expect(resolveAppLocale(const [], appSupportedLocales), appFallbackLocale);
    expect(
      resolveAppLocale(const [Locale('es', 'CL')], appSupportedLocales),
      appFallbackLocale,
    );
    expect(
      resolveAppLocale(const [Locale('es', 'MX')], appSupportedLocales),
      appFallbackLocale,
    );
  });

  test(
    'riconosce solo il cinese semplificato e altrimenti usa lo spagnolo',
    () {
      const simplified = Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
      );

      expect(
        resolveAppLocale(const [simplified], appSupportedLocales),
        simplified,
      );
      expect(
        resolveAppLocale(const [Locale('zh', 'CN')], appSupportedLocales),
        simplified,
      );
      expect(
        resolveAppLocale(const [Locale('zh', 'SG')], appSupportedLocales),
        simplified,
      );
      expect(
        resolveAppLocale(const [
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ], appSupportedLocales),
        appFallbackLocale,
      );
      expect(
        resolveAppLocale(const [Locale('zh')], appSupportedLocales),
        appFallbackLocale,
      );
      for (final region in const ['TW', 'HK', 'MO']) {
        expect(
          resolveAppLocale([
            Locale.fromSubtags(languageCode: 'zh', countryCode: region),
          ], appSupportedLocales),
          appFallbackLocale,
        );
      }
    },
  );

  final localizedHomeMessages = <Locale, String>{
    appFallbackLocale:
        'Recorre las secciones de la tienda mientras preparamos el catálogo.',
    const Locale('it'):
        'Scopri le sezioni del negozio mentre prepariamo il catalogo.',
    const Locale('en'):
        'Browse the store sections while we prepare the catalog.',
    const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'):
        '我们正在准备商品目录，你可以先浏览商店的各个部分。',
  };

  for (final entry in localizedHomeMessages.entries) {
    testWidgets('carica il contenuto Home per ${entry.key}', (tester) async {
      await tester.pumpWidget(buildApp(locale: entry.key));
      await tester.pumpAndSettle();

      expect(find.text(entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('renderizza shell e destinazioni nei quattro locale', (
    tester,
  ) async {
    final cases = <Locale, List<String>>{
      appFallbackLocale: const ['Inicio', 'Catálogo', 'Carrito', 'Cuenta'],
      const Locale('it'): const ['Home', 'Catalogo', 'Carrello', 'Account'],
      const Locale('en'): const ['Home', 'Catalog', 'Cart', 'Account'],
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'): const [
        '首页',
        '商品目录',
        '购物车',
        '账户',
      ],
    };

    for (final entry in cases.entries) {
      await tester.pumpWidget(buildApp(locale: entry.key));
      await tester.pumpAndSettle();

      for (final label in entry.value) {
        expect(find.text(label), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('si avvia offline e senza il counter demo', (tester) async {
    await tester.pumpWidget(buildApp(locale: appFallbackLocale));
    await tester.pumpAndSettle();

    expect(
      find.text('Backend no configurado: modo de desarrollo sin conexión.'),
      findsOneWidget,
    );
    expect(find.text('0'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('usa la seconda preferenza supportata del dispositivo', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [
      Locale('de'),
      Locale('it'),
    ];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Scopri le sezioni del negozio mentre prepariamo il catalogo.'),
      findsOneWidget,
    );
  });

  testWidgets('usa lo spagnolo per de, zh-Hant e zh generico', (tester) async {
    for (final locale in [
      const Locale('de'),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      const Locale('zh'),
    ]) {
      await tester.pumpWidget(buildApp(locale: locale));
      await tester.pumpAndSettle();

      expect(
        Localizations.localeOf(tester.element(find.byType(Scaffold))),
        appFallbackLocale,
      );
      expect(
        find.text(
          'Recorre las secciones de la tienda mientras preparamos el catálogo.',
        ),
        findsOneWidget,
      );
      expect(find.text('我们正在准备商品目录，你可以先浏览商店的各个部分。'), findsNothing);
    }
  });

  testWidgets('usa il nome brand risolto come titolo applicativo', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(locale: appFallbackLocale));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      app.onGenerateTitle?.call(tester.element(find.byType(MaterialApp))),
      AppBrand.effectiveDisplayName,
    );
  });

  testWidgets('segue il tema scuro di sistema', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(buildApp(locale: appFallbackLocale));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
