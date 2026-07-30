import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
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
      Locale('en'),
      Locale('es'),
      Locale('it'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    ]);
    expect(appSupportedLocales, isNot(contains(const Locale('zh'))));
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
        resolveAppLocale(const [
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ], appSupportedLocales),
        const Locale('es'),
      );
      expect(
        resolveAppLocale(const [Locale('zh')], appSupportedLocales),
        const Locale('es'),
      );
    },
  );

  final localizedHomeMessages = <Locale, String>{
    const Locale('es'):
        'La base de la tienda está lista. '
        'El catálogo público se conectará en una tarea posterior.',
    const Locale('it'):
        'La fondazione del negozio è pronta. '
        'Il catalogo pubblico verrà collegato in un task successivo.',
    const Locale('en'):
        'The storefront foundation is ready. '
        'The public catalog will be connected in a later task.',
    const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'):
        '商店应用基础已就绪。公共商品目录将在后续任务中接入。',
  };

  for (final entry in localizedHomeMessages.entries) {
    testWidgets('carica il contenuto Home per ${entry.key}', (tester) async {
      await tester.pumpWidget(buildApp(locale: entry.key));
      await tester.pumpAndSettle();

      expect(find.text(entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('si avvia offline e senza il counter demo', (tester) async {
    await tester.pumpWidget(buildApp(locale: const Locale('es')));
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
      find.text(
        'La fondazione del negozio è pronta. '
        'Il catalogo pubblico verrà collegato in un task successivo.',
      ),
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
        find.text(
          'La base de la tienda está lista. '
          'El catálogo público se conectará en una tarea posterior.',
        ),
        findsOneWidget,
      );
      expect(find.text('商店应用基础已就绪。公共商品目录将在后续任务中接入。'), findsNothing);
    }
  });

  testWidgets('segue il tema scuro di sistema', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(buildApp(locale: const Locale('es')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
