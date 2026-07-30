import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/app/design_system/tokens/app_sizes.dart';
import 'package:client_merchandise_control/app/design_system/tokens/app_spacing.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp() {
    return ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(AppConfig.fromValues())],
      child: const ClientMerchandiseControlApp(locale: Locale('es')),
    );
  }

  const destinations = <({String key, String message})>[
    (
      key: 'nav-home',
      message: 'Pronto podrás descubrir aquí las novedades de la tienda.',
    ),
    (
      key: 'nav-catalog',
      message: 'El catálogo estará disponible aquí próximamente.',
    ),
    (
      key: 'nav-cart',
      message: 'Tu carrito estará disponible cuando puedas elegir productos.',
    ),
    (
      key: 'nav-account',
      message:
          'Podrás acceder a tu cuenta cuando esta función esté disponible.',
    ),
  ];

  testWidgets('presenta le quattro destinazioni localizzate', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Carrito'), findsOneWidget);
    expect(find.text('Cuenta'), findsOneWidget);
  });

  testWidgets('mostra il contenuto reale di tutte le destinazioni', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    for (var index = 0; index < destinations.length; index++) {
      final destination = destinations[index];
      if (index != 0) {
        await tester.tap(find.byKey(ValueKey(destination.key)));
        await tester.pumpAndSettle();
      }

      expect(find.text(destination.message), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        index,
      );
      for (final other in destinations.where(
        (candidate) => candidate != destination,
      )) {
        expect(find.text(other.message), findsNothing);
      }
    }

    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('il back da una tab secondaria torna alla Home', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(
      tester.widget<PopScope<void>>(find.byType(PopScope<void>)).canPop,
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('nav-account')));
    await tester.pumpAndSettle();
    expect(find.text(destinations[3].message), findsOneWidget);
    expect(
      tester.widget<PopScope<void>>(find.byType(PopScope<void>)).canPop,
      isFalse,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text(destinations[0].message), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    expect(
      tester.widget<PopScope<void>>(find.byType(PopScope<void>)).canPop,
      isTrue,
    );
  });

  testWidgets('preserva il subtree Home dopo il cambio tab', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final homeFinder = find.byType(HomeScreen, skipOffstage: false);
    final initialHomeElement = tester.element(homeFinder);

    await tester.tap(find.byKey(const ValueKey('nav-account')));
    await tester.pumpAndSettle();
    expect(homeFinder, findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-home')));
    await tester.pumpAndSettle();

    expect(tester.element(homeFinder), same(initialHomeElement));
  });

  testWidgets('espone una sola semantica titolo nel contenuto', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final decorativeIcon = find.descendant(
      of: find.byType(ExcludeSemantics),
      matching: find.byIcon(Icons.storefront_outlined),
    );
    final semanticsInCard = tester.widgetList<Semantics>(
      find.descendant(of: find.byType(Card), matching: find.byType(Semantics)),
    );
    final titleSemantics = semanticsInCard.where(
      (semantics) => semantics.properties.header == true,
    );

    expect(decorativeIcon, findsOneWidget);
    expect(tester.widget<Icon>(decorativeIcon).semanticLabel, isNull);
    expect(titleSemantics, hasLength(1));
  });

  testWidgets('resta usabile su tutte le tab a testo 200%', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final size in const [Size(320, 568), Size(568, 320)]) {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      for (var index = 0; index < destinations.length; index++) {
        if (index != 0) {
          await tester.tap(find.byKey(ValueKey(destinations[index].key)));
          await tester.pumpAndSettle();
        }
        expect(find.text(destinations[index].message), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$size tab $index');
      }
    }
  });

  testWidgets('adatta il padding alle larghezze compatta ed estesa', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final testCase in [
      (size: const Size(390, 844), horizontalPadding: AppSpacing.lg),
      (size: const Size(1024, 768), horizontalPadding: AppSpacing.xxl),
    ]) {
      await tester.binding.setSurfaceSize(testCase.size);
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(
        scrollView.padding,
        EdgeInsets.symmetric(
          horizontal: testCase.horizontalPadding,
          vertical: AppSpacing.xl,
        ),
      );
    }
  });

  testWidgets('le destinazioni rispettano target e label accessibili', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    for (final destination in destinations) {
      final size = tester.getSize(find.byKey(ValueKey(destination.key)));
      expect(size.width, greaterThanOrEqualTo(AppSizes.minimumTouchTarget));
      expect(size.height, greaterThanOrEqualTo(AppSizes.minimumTouchTarget));
    }

    expect(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(tester, meetsGuideline(androidTapTargetGuideline));
    expect(tester, meetsGuideline(iOSTapTargetGuideline));
  });
}
