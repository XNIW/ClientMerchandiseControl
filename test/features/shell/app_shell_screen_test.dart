import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
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
      message:
          'La base de la tienda está lista. '
          'El catálogo público se conectará en una tarea posterior.',
    ),
    (
      key: 'nav-catalog',
      message:
          'El catálogo todavía no está conectado. '
          'Aquí se mostrarán solo productos publicados.',
    ),
    (
      key: 'nav-cart',
      message:
          'El carrito se implementará cuando exista el contrato público '
          'de precios y disponibilidad.',
    ),
    (
      key: 'nav-account',
      message:
          'El perfil del cliente y el acceso seguro se implementarán '
          'en tareas posteriores.',
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

  testWidgets('resta usabile a 320px con testo al 200%', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text(destinations[0].message), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adatta il padding alle larghezze compatta ed estesa', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final testCase in [
      (size: const Size(390, 844), horizontalPadding: 20.0),
      (size: const Size(1000, 844), horizontalPadding: 32.0),
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
          vertical: 24,
        ),
      );
    }
  });
}
