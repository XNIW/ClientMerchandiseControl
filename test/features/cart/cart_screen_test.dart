import 'package:client_merchandise_control/app/design_system/tokens/app_sizes.dart';
import 'package:client_merchandise_control/app/router/app_router.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/cart/presentation/cart_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late GoRouter router;

  Widget buildApp({Locale locale = const Locale('es')}) {
    router = GoRouter(
      initialLocation: AppRoutes.cartLocation,
      routes: [
        GoRoute(
          path: AppRoutes.cartLocation,
          builder: (context, state) =>
              const Scaffold(body: SafeArea(child: CartScreen())),
        ),
        GoRoute(
          path: AppRoutes.catalogLocation,
          builder: (context, state) =>
              const Scaffold(body: Text('catalog-destination')),
        ),
      ],
    );
    addTearDown(router.dispose);

    return MaterialApp.router(
      theme: AppTheme.light(),
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  testWidgets('presenta uno stato vuoto onesto e raggiunge il catalogo', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(CartScreen));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.cartEmptyTitle), findsOneWidget);
    expect(find.text(l10n.cartEmptyMessage), findsOneWidget);
    expect(find.text(l10n.cartExploreCatalog), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    final visibleTexts = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .toSet();
    expect(visibleTexts, {
      l10n.cartEmptyTitle,
      l10n.cartEmptyMessage,
      l10n.cartExploreCatalog,
    });

    await tester.tap(find.byKey(const ValueKey('cart-explore-catalog')));
    await tester.pumpAndSettle();

    expect(find.text('catalog-destination'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/catalog');
  });

  testWidgets('espone titolo, icona decorativa e CTA accessibile da 48 px', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(CartScreen));
      final l10n = AppLocalizations.of(context);
      final decorativeIcon = find.descendant(
        of: find.byType(ExcludeSemantics),
        matching: find.byIcon(Icons.shopping_cart_outlined),
      );
      final header = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((widget) => widget.properties.header == true);
      final buttonFinder = find.byKey(const ValueKey('cart-explore-catalog'));
      final buttonSemantics = tester
          .getSemantics(buttonFinder)
          .getSemanticsData();

      expect(decorativeIcon, findsOneWidget);
      expect(tester.widget<Icon>(decorativeIcon).semanticLabel, isNull);
      expect(header, hasLength(1));
      expect(buttonSemantics.label, l10n.cartExploreCatalog);
      expect(buttonSemantics.hasAction(SemanticsAction.tap), isTrue);
      expect(
        tester.getSize(buttonFinder).height,
        greaterThanOrEqualTo(AppSizes.minimumTouchTarget),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('resta fruibile su viewport compatta con testo al 200%', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.binding.setSurfaceSize(const Size(320, 568));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('cart-explore-catalog')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cart-explore-catalog')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
