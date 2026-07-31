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

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('flusso guest reale della storefront development', (
    tester,
  ) async {
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
    await _setOrientation(
      tester,
      DeviceOrientation.portraitUp,
      expected: Orientation.portrait,
    );

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(StorefrontStatusBanner), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      MediaQuery.orientationOf(tester.element(find.byType(HomeScreen))),
      Orientation.portrait,
    );

    final homeContext = tester.element(find.byType(HomeScreen));
    final l10n = AppLocalizations.of(homeContext);
    expect(find.text(l10n.homeWelcomeTitle), findsOneWidget);
    expect(find.text(l10n.homeWelcomeMessage), findsOneWidget);
    expect(find.text(l10n.homeCategoriesTitle), findsOneWidget);
    expect(find.text(l10n.homeOffersTitle), findsOneWidget);
    expect(find.text(l10n.homeFeaturedTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('home-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-open-catalog')), findsOneWidget);
    _expectNoFakeCommercialData(tester);
    _expectNoFrameworkException(tester, 'cold launch Home');

    final homeFinder = find.byType(HomeScreen, skipOffstage: false);
    final homeElement = tester.element(homeFinder);

    await tester.tap(find.byKey(const ValueKey('home-search')));
    await tester.pumpAndSettle();
    _expectSelectedDestination<CatalogScreen>(tester, 1);
    _expectNoFakeCommercialData(tester);
    _expectNoFrameworkException(tester, 'ricerca Home → Catalogo');

    await tester.tap(find.byKey(const ValueKey('nav-home')));
    await tester.pumpAndSettle();
    expect(tester.element(homeFinder), same(homeElement));

    final homeCatalogAction = find.byKey(const ValueKey('home-open-catalog'));
    await tester.ensureVisible(homeCatalogAction);
    await tester.pumpAndSettle();
    final homeScrollState = Scrollable.of(tester.element(homeCatalogAction));
    final preservedHomeOffset = homeScrollState.position.pixels;
    expect(preservedHomeOffset, greaterThan(0));
    await tester.tap(homeCatalogAction);
    await tester.pumpAndSettle();
    _expectSelectedDestination<CatalogScreen>(tester, 1);

    await tester.tap(find.byKey(const ValueKey('nav-cart')));
    await tester.pumpAndSettle();
    _expectSelectedDestination<CartScreen>(tester, 2);
    expect(find.text(l10n.cartEmptyTitle), findsOneWidget);
    expect(find.text(l10n.cartEmptyMessage), findsOneWidget);
    final cartCatalogAction = find.byKey(
      const ValueKey('cart-explore-catalog'),
    );
    await tester.ensureVisible(cartCatalogAction);
    await tester.pumpAndSettle();
    expect(find.text(l10n.cartExploreCatalog), findsOneWidget);
    _expectNoFakeCommercialData(tester);
    _expectNoFrameworkException(tester, 'Carrello guest');

    await tester.tap(cartCatalogAction);
    await tester.pumpAndSettle();
    _expectSelectedDestination<CatalogScreen>(tester, 1);

    await tester.tap(find.byKey(const ValueKey('nav-cart')));
    await tester.pumpAndSettle();
    _expectSelectedDestination<CartScreen>(tester, 2);
    await tester.tap(find.byKey(const ValueKey('nav-account')));
    await tester.pumpAndSettle();
    _expectSelectedDestination<AccountScreen>(tester, 3);

    expect(find.text(l10n.accountGuestTitle), findsOneWidget);
    expect(find.text(l10n.accountGuestBenefit), findsOneWidget);
    expect(find.text(l10n.accountGoogleComingSoon), findsOneWidget);
    final googleAction = find.byKey(const ValueKey('account-google-button'));
    await tester.ensureVisible(googleAction);
    await tester.pumpAndSettle();
    expect(find.text(l10n.accountContinueWithGoogle), findsOneWidget);
    expect(tester.widget<FilledButton>(googleAction).onPressed, isNull);
    expect(find.byKey(const ValueKey('account-browse-button')), findsNothing);
    expect(find.byType(Form), findsNothing);
    _expectNoFakeCommercialData(tester);
    _expectNoFrameworkException(tester, 'Account guest fail-closed');

    expect(
      homeScrollState.position.pixels,
      closeTo(preservedHomeOffset, 1),
      reason: 'La branch Home deve preservare la posizione mentre è offstage.',
    );
    await _verifyPrimarySemanticsAndTargets(tester, l10n);
    semantics.dispose();
    final homeOffsetAfterSemanticsChecks = homeScrollState.position.pixels;

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    _expectSelectedDestination<HomeScreen>(tester, 0);
    expect(tester.element(homeFinder), same(homeElement));
    expect(
      homeScrollState.position.pixels,
      closeTo(homeOffsetAfterSemanticsChecks, 1),
      reason: 'Il back deve preservare l’ultimo offset Home verificato.',
    );

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(HomeScreen))).brightness,
      Brightness.light,
    );
    _expectNoFrameworkException(tester, 'tema chiaro');

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(HomeScreen))).brightness,
      Brightness.dark,
    );
    _expectNoFrameworkException(tester, 'tema scuro');

    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpAndSettle();
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.byType(HomeScreen)),
      ).scale(10),
      20,
    );
    await _visitAllDestinations(tester, l10n);

    await _setOrientation(
      tester,
      DeviceOrientation.landscapeLeft,
      expected: Orientation.landscape,
    );
    await _visitAllDestinations(tester, l10n);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      MediaQuery.orientationOf(tester.element(find.byType(Scaffold).first)),
      Orientation.landscape,
    );
    _expectNoFrameworkException(tester, 'processo vivo a fine flusso');

    binding.reportData = <String, Object?>{
      'coldLaunch': 'PASS',
      'polishedHome': 'PASS',
      'homeSearchAndCta': 'PASS',
      'guestNavigation': 'PASS',
      'cartCta': 'PASS',
      'accountGuestFailClosed': 'PASS',
      'tabStateAndBack': 'PASS',
      'lightDark': 'PASS',
      'textScale200': 'PASS',
      'portraitLandscape': 'PASS',
      'semanticsAndTargets': 'PASS',
      'noFakeCommercialData': 'PASS',
      'developmentOffline': 'PASS',
      'processAlive': 'PASS',
    };
  });
}

Future<void> _verifyPrimarySemanticsAndTargets(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  final destinations = <({String key, String label})>[
    (key: 'nav-home', label: l10n.navigationHome),
    (key: 'nav-catalog', label: l10n.navigationCatalog),
    (key: 'nav-cart', label: l10n.navigationCart),
    (key: 'nav-account', label: l10n.navigationAccount),
  ];

  for (final destination in destinations) {
    final finder = find.byKey(ValueKey(destination.key));
    final data = tester.getSemantics(finder).getSemanticsData();
    _expectMinimumTouchTarget(tester, finder, destination.key);
    expect(data.label, contains(destination.label));
    expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
  }

  await tester.tap(find.byKey(const ValueKey('nav-home')));
  await tester.pumpAndSettle();
  final homeSearch = find.byKey(const ValueKey('home-search'));
  _expectMinimumTouchTarget(tester, homeSearch, 'home-search');
  final homeSearchData = tester.getSemantics(homeSearch).getSemanticsData();
  expect(homeSearchData.label, l10n.homeSearchLabel);
  expect(homeSearchData.hasAction(ui.SemanticsAction.tap), isTrue);

  final homeCatalog = find.byKey(const ValueKey('home-open-catalog'));
  await tester.ensureVisible(homeCatalog);
  await tester.pumpAndSettle();
  _expectMinimumTouchTarget(tester, homeCatalog, 'home-open-catalog');
  expect(
    tester
        .getSemantics(homeCatalog)
        .getSemanticsData()
        .hasAction(ui.SemanticsAction.tap),
    isTrue,
  );

  await tester.tap(find.byKey(const ValueKey('nav-cart')));
  await tester.pumpAndSettle();
  final cartCatalog = find.byKey(const ValueKey('cart-explore-catalog'));
  await tester.ensureVisible(cartCatalog);
  await tester.pumpAndSettle();
  _expectMinimumTouchTarget(tester, cartCatalog, 'cart-explore-catalog');
  expect(
    tester
        .getSemantics(cartCatalog)
        .getSemanticsData()
        .hasAction(ui.SemanticsAction.tap),
    isTrue,
  );

  await tester.tap(find.byKey(const ValueKey('nav-account')));
  await tester.pumpAndSettle();
  final google = find.byKey(const ValueKey('account-google-button'));
  await tester.ensureVisible(google);
  await tester.pumpAndSettle();
  _expectMinimumTouchTarget(tester, google, 'account-google-button');
  expect(find.bySemanticsLabel(l10n.accountContinueWithGoogle), findsOneWidget);
  expect(tester.widget<FilledButton>(google).onPressed, isNull);
}

Future<void> _visitAllDestinations(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  final destinations = <({String key, Type screen})>[
    (key: 'nav-home', screen: HomeScreen),
    (key: 'nav-catalog', screen: CatalogScreen),
    (key: 'nav-cart', screen: CartScreen),
    (key: 'nav-account', screen: AccountScreen),
  ];

  for (var index = 0; index < destinations.length; index++) {
    final destination = destinations[index];
    await tester.tap(find.byKey(ValueKey(destination.key)));
    await tester.pumpAndSettle();
    _expectSelectedDestination(tester, index, destination.screen);

    switch (index) {
      case 0:
        await tester.ensureVisible(
          find.byKey(const ValueKey('home-open-catalog')),
        );
        break;
      case 1:
        await tester.ensureVisible(
          find.byKey(const ValueKey('catalog-search')),
        );
        break;
      case 2:
        await tester.ensureVisible(
          find.byKey(const ValueKey('cart-explore-catalog')),
        );
        break;
      case 3:
        await tester.ensureVisible(
          find.byKey(const ValueKey('account-google-button')),
        );
        expect(find.text(l10n.accountGuestTitle), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('account-google-button')),
              )
              .onPressed,
          isNull,
        );
        break;
    }
    await tester.pumpAndSettle();

    _expectNoFakeCommercialData(tester);
    _expectNoFrameworkException(
      tester,
      '${destination.key} a scala/orientamento corrente',
    );
  }
}

void _expectSelectedDestination<T extends Widget>(
  WidgetTester tester,
  int index, [
  Type? runtimeType,
]) {
  final screenFinder = runtimeType == null
      ? find.byType(T)
      : find.byType(runtimeType);
  expect(screenFinder, findsOneWidget);
  expect(
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
    index,
  );
}

void _expectMinimumTouchTarget(
  WidgetTester tester,
  Finder finder,
  String description,
) {
  final size = tester.getSize(finder);
  expect(
    size.width,
    greaterThanOrEqualTo(AppSizes.minimumTouchTarget),
    reason: '$description deve essere largo almeno 48 dp.',
  );
  expect(
    size.height,
    greaterThanOrEqualTo(AppSizes.minimumTouchTarget),
    reason: '$description deve essere alto almeno 48 dp.',
  );
}

void _expectNoFakeCommercialData(WidgetTester tester) {
  final visibleText = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .join(' ');
  final fakeCommercialValue = RegExp(
    r'(?:CLP\s*\d|\$\s*\d|'
    r'(?:stock|existencias?|precio|price|prezzo)\s*[:=]?\s*(?:CLP|\$)?\s*\d|'
    r'(?:producto|product|prodotto|商品)\s*#?\d+)',
    caseSensitive: false,
  );

  expect(
    fakeCommercialValue.hasMatch(visibleText),
    isFalse,
    reason: 'La shell guest non deve inventare prodotti, prezzi o stock.',
  );
  expect(find.byType(Image), findsNothing);
}

void _expectNoFrameworkException(WidgetTester tester, String step) {
  expect(tester.takeException(), isNull, reason: step);
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
      final context = tester.element(scaffold.first);
      if (context.mounted && MediaQuery.orientationOf(context) == expected) {
        return;
      }
    }
    await tester.pump(const Duration(milliseconds: 250));
  }

  fail('Il device non ha raggiunto l’orientamento ${expected.name}.');
}
