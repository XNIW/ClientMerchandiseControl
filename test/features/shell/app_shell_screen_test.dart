import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/app/design_system/tokens/app_sizes.dart';
import 'package:client_merchandise_control/app/design_system/tokens/app_spacing.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/presentation/account_screen.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/cart/presentation/cart_screen.dart';
import 'package:client_merchandise_control/features/catalog/presentation/catalog_screen.dart';
import 'package:client_merchandise_control/features/delivery_tracking/application/delivery_tracking_controller.dart';
import 'package:client_merchandise_control/features/delivery_tracking/application/delivery_tracking_providers.dart';
import 'package:client_merchandise_control/features/home/presentation/home_screen.dart';
import 'package:client_merchandise_control/features/shell/presentation/app_shell_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../delivery_tracking/delivery_tracking_test_support.dart';

void main() {
  Widget buildApp() {
    return ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(AppConfig.fromValues())],
      child: const ClientMerchandiseControlApp(locale: Locale('es')),
    );
  }

  const destinations = <({String key, Type screen, int index})>[
    (key: 'nav-home', screen: HomeScreen, index: 0),
    (key: 'nav-catalog', screen: CatalogScreen, index: 1),
    (key: 'nav-cart', screen: CartScreen, index: 3),
    (key: 'nav-account', screen: AccountScreen, index: 4),
  ];

  testWidgets('presenta le cinque destinazioni localizzate', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Pedidos'), findsOneWidget);
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

      expect(find.byType(destination.screen), findsOneWidget);
      expect(_selectedDestinationIndex(tester), destination.index);
      for (final other in destinations.where(
        (candidate) => candidate != destination,
      )) {
        expect(find.byType(other.screen), findsNothing);
      }
    }

    expect(
      find.byType(NavigationBar).evaluate().length +
          find.byType(NavigationRail).evaluate().length,
      1,
    );
  });

  testWidgets('Ordini guest devia ad Account senza perdere il browsing', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-orders')));
    await tester.pumpAndSettle();

    expect(find.byType(AccountScreen), findsOneWidget);
    expect(_selectedDestinationIndex(tester), 4);
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
    expect(find.byType(destinations[3].screen), findsOneWidget);
    expect(
      tester.widget<PopScope<void>>(find.byType(PopScope<void>)).canPop,
      isFalse,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(destinations[0].screen), findsOneWidget);
    expect(_selectedDestinationIndex(tester), 0);
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

  testWidgets('espone un solo titolo route per la destinazione corrente', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final routeTitles = tester.widgetList<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.header == true &&
            widget.properties.namesRoute == true,
      ),
    );

    expect(routeTitles, hasLength(1));
    expect(find.byKey(const ValueKey('shell-title-0')), findsOneWidget);
  });

  testWidgets('resta usabile su tutte le tab a testo 200%', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final size in const [
      Size(320, 568),
      Size(568, 320),
      Size(390, 844),
      Size(1024, 768),
    ]) {
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
        expect(find.byType(destinations[index].screen), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$size tab $index');
      }
    }
  });

  testWidgets('resta usabile su tutte le tab a testo 130%', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.binding.setSurfaceSize(const Size(390, 844));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    for (var index = 0; index < destinations.length; index++) {
      if (index != 0) {
        await tester.tap(find.byKey(ValueKey(destinations[index].key)));
        await tester.pumpAndSettle();
      }
      expect(find.byType(destinations[index].screen), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'tab $index');
    }
  });

  testWidgets('adatta il padding alle larghezze compatta ed estesa', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in const [Size(390, 844), Size(1024, 768)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final scrollView = tester.widget<SingleChildScrollView>(
        find.descendant(
          of: find.byType(HomeScreen),
          matching: find.byType(SingleChildScrollView),
        ),
      );
      final pageWidth = tester.getSize(find.byType(HomeScreen)).width;
      final horizontalPadding = pageWidth >= 720
          ? AppSpacing.xxl
          : pageWidth <= 360
          ? AppSpacing.md
          : AppSpacing.lg;
      expect(
        scrollView.padding,
        EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: AppSpacing.xl,
        ),
      );
    }
  });

  testWidgets('usa NavigationRail su tablet ampio e mantiene la navigazione', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1024, 768);
    tester.platformDispatcher.textScaleFactorTestValue = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.selectedIndex, 0);

    rail.onDestinationSelected!(1);
    await tester.pumpAndSettle();

    expect(find.byType(CatalogScreen), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      1,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('le destinazioni rispettano target e label accessibili', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    for (final destination in [
      ...destinations,
      (key: 'nav-orders', screen: AccountScreen, index: 2),
    ]) {
      final size = tester.getSize(find.byKey(ValueKey(destination.key)));
      expect(size.width, greaterThanOrEqualTo(AppSizes.minimumTouchTarget));
      expect(size.height, greaterThanOrEqualTo(AppSizes.minimumTouchTarget));
    }

    expect(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(tester, meetsGuideline(androidTapTargetGuideline));
    expect(tester, meetsGuideline(iOSTapTargetGuideline));
  });

  testWidgets(
    'navigazione programmatica sospende e riprende il tracking Orders',
    (tester) async {
      final repository = FakeDeliveryTrackingRepository();
      final customer = AuthenticatedCustomer.fromUntrustedIdentity(
        subjectId: trackingTestOwner,
        email: 'customer@example.invalid',
        metadata: const {'name': 'Customer Test'},
      );
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.fromValues()),
          deliveryTrackingIdentityProvider.overrideWithValue(customer),
          deliveryTrackingShopSlugProvider.overrideWithValue(trackingTestShop),
          deliveryTrackingRepositoryProvider.overrideWithValue(repository),
          deliveryTrackingCacheProvider.overrideWithValue(
            MemoryDeliveryTrackingCache(),
          ),
          deliveryTrackingClockProvider.overrideWithValue(
            () => trackingTestNow,
          ),
          deliveryTrackingPollIntervalProvider.overrideWithValue(
            const Duration(hours: 1),
          ),
        ],
      );
      final router = GoRouter(
        initialLocation: '/orders/detail',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                AppShellScreen(navigationShell: navigationShell),
            branches: [
              _testShellBranch('/home', 'home'),
              _testShellBranch('/catalog', 'catalog'),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/orders',
                    builder: (context, state) => const Text('orders'),
                    routes: [
                      GoRoute(
                        path: 'detail',
                        builder: (context, state) => const Text('detail'),
                      ),
                    ],
                  ),
                ],
              ),
              _testShellBranch('/cart', 'cart'),
              _testShellBranch('/account', 'account'),
            ],
          ),
        ],
      );
      addTearDown(() async {
        router.dispose();
        container.dispose();
        await repository.stream.close();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('es', 'CL'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final controller = container.read(
        deliveryTrackingControllerProvider.notifier,
      );
      await controller.open(trackingTestOrder);
      expect(repository.watchCalls, 1);

      router.go('/catalog');
      await tester.pumpAndSettle();
      expect(repository.watchCancelCalls, 1);

      router.go('/orders/detail');
      await tester.pumpAndSettle();
      expect(repository.watchCalls, 2);

      await controller.close();
    },
  );
}

StatefulShellBranch _testShellBranch(String path, String label) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (context, state) => Text(label))],
  );
}

int _selectedDestinationIndex(WidgetTester tester) {
  final navigationBar = find.byType(NavigationBar);
  if (navigationBar.evaluate().isNotEmpty) {
    return tester.widget<NavigationBar>(navigationBar).selectedIndex;
  }
  return tester
          .widget<NavigationRail>(find.byType(NavigationRail))
          .selectedIndex ??
      -1;
}
