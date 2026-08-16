import 'dart:ui' as ui;

import 'package:client_merchandise_control/app/design_system/tokens/app_sizes.dart';
import 'package:client_merchandise_control/app/design_system/widgets/storefront_status_banner.dart';
import 'package:client_merchandise_control/features/account/presentation/account_screen.dart';
import 'package:client_merchandise_control/features/cart/presentation/cart_screen.dart';
import 'package:client_merchandise_control/features/catalog/presentation/catalog_screen.dart';
import 'package:client_merchandise_control/features/home/presentation/home_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:client_merchandise_control/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smoke reale della shell development su device', (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(() async {
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await SystemChrome.setPreferredOrientations(<DeviceOrientation>[]);
    });

    await _setOrientation(
      tester,
      DeviceOrientation.portraitUp,
      expected: Orientation.portrait,
      beforeLaunch: true,
    );
    await app.main();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(StorefrontStatusBanner), findsOneWidget);
    expect(
      MediaQuery.orientationOf(tester.element(find.byType(Scaffold))),
      Orientation.portrait,
    );
    expect(
      () => Supabase.instance,
      throwsA(isA<AssertionError>()),
      reason: 'development non configurato non deve inizializzare Supabase',
    );
    expect(tester.takeException(), isNull);

    final shellContext = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(shellContext);
    final destinations = <({String key, Type screen, String label})>[
      (key: 'nav-home', screen: HomeScreen, label: l10n.navigationHome),
      (
        key: 'nav-catalog',
        screen: CatalogScreen,
        label: l10n.navigationCatalog,
      ),
      (key: 'nav-orders', screen: AccountScreen, label: l10n.navigationOrders),
      (key: 'nav-cart', screen: CartScreen, label: l10n.navigationCart),
      (
        key: 'nav-account',
        screen: AccountScreen,
        label: l10n.navigationAccount,
      ),
    ];

    for (var index = 0; index < destinations.length; index++) {
      final destination = destinations[index];
      final destinationFinder = find.byKey(ValueKey(destination.key));
      final destinationSemantics = tester
          .getSemantics(destinationFinder)
          .getSemanticsData();

      expect(destinationSemantics.label, contains(destination.label));
      expect(destinationSemantics.hasAction(ui.SemanticsAction.tap), isTrue);
      expect(
        destinationSemantics.flagsCollection.isSelected,
        index == 0 ? ui.Tristate.isTrue : ui.Tristate.isFalse,
      );

      final destinationSize = tester.getSize(destinationFinder);
      expect(
        destinationSize.width,
        greaterThanOrEqualTo(AppSizes.minimumTouchTarget),
      );
      expect(
        destinationSize.height,
        greaterThanOrEqualTo(AppSizes.minimumTouchTarget),
      );
    }
    semantics.dispose();

    final homeElement = tester.element(
      find.byType(HomeScreen, skipOffstage: false),
    );
    await _visitAllDestinations(tester, destinations);
    await tester.tap(find.byKey(const ValueKey('nav-home')));
    await tester.pumpAndSettle();
    expect(
      tester.element(find.byType(HomeScreen, skipOffstage: false)),
      same(homeElement),
    );

    await tester.tap(find.byKey(const ValueKey('nav-account')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.light,
    );

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );

    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpAndSettle();
    expect(
      MediaQuery.textScalerOf(tester.element(find.byType(Scaffold))).scale(10),
      20,
    );
    await _visitAllDestinations(tester, destinations);

    await _setOrientation(
      tester,
      DeviceOrientation.landscapeLeft,
      expected: Orientation.landscape,
    );
    await _visitAllDestinations(tester, destinations);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
    binding.reportData = <String, Object?>{
      'coldLaunch': 'PASS',
      'navigation': 'PASS',
      'backAndTabState': 'PASS',
      'lightDark': 'PASS',
      'textScale200': 'PASS',
      'portraitLandscape': 'PASS',
      'semantics': 'PASS',
      'developmentNetworkingDisabled': 'PASS',
      'noFakeCommercialData': 'PASS',
      'processAlive': 'PASS',
    };
  });
}

Future<void> _visitAllDestinations(
  WidgetTester tester,
  List<({String key, Type screen, String label})> destinations,
) async {
  const expectedIndexes = <String, int>{
    'nav-home': 0,
    'nav-catalog': 1,
    'nav-orders': 4,
    'nav-cart': 3,
    'nav-account': 4,
  };
  for (final destination in destinations) {
    await tester.tap(find.byKey(ValueKey(destination.key)));
    await tester.pumpAndSettle();

    expect(find.byType(destination.screen), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      expectedIndexes[destination.key],
    );
    _expectNoFakeCommercialData(tester);
    expect(tester.takeException(), isNull, reason: destination.key);
  }
}

void _expectNoFakeCommercialData(WidgetTester tester) {
  final visibleText = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .join(' ');
  final commercialValue = RegExp(
    r'(?:CLP\s*\d|\$\s*\d|stock\s*[:=]?\s*\d)',
    caseSensitive: false,
  );

  expect(commercialValue.hasMatch(visibleText), isFalse);
  expect(find.byType(Image), findsNothing);
}

Future<void> _setOrientation(
  WidgetTester tester,
  DeviceOrientation orientation, {
  required Orientation expected,
  bool beforeLaunch = false,
}) async {
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[orientation]);
  if (beforeLaunch) {
    return;
  }

  for (var attempt = 0; attempt < 40; attempt++) {
    final scaffold = find.byType(Scaffold);
    if (scaffold.evaluate().isNotEmpty) {
      final context = tester.element(scaffold);
      if (context.mounted && MediaQuery.orientationOf(context) == expected) {
        return;
      }
    }
    await tester.pump(const Duration(milliseconds: 250));
  }

  fail('Il device non ha raggiunto l’orientamento ${expected.name}.');
}
