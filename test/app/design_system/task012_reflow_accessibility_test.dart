import 'dart:math' as math;

import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/app/design_system/tokens/app_breakpoints.dart';
import 'package:client_merchandise_control/app/design_system/tokens/app_sizes.dart';
import 'package:client_merchandise_control/app/design_system/tokens/app_spacing.dart';
import 'package:client_merchandise_control/app/design_system/widgets/storefront_page.dart';
import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/presentation/account_screen.dart';
import 'package:client_merchandise_control/features/cart/presentation/cart_screen.dart';
import 'package:client_merchandise_control/features/catalog/presentation/catalog_screen.dart';
import 'package:client_merchandise_control/features/home/presentation/home_screen.dart';
import 'package:client_merchandise_control/features/shell/presentation/app_shell_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const safeAreaInsets = FakeViewPadding(top: 24, bottom: 16);
  const viewportCases = <Size>[
    Size(320, 568),
    Size(360, 800),
    Size(390, 844),
    Size(430, 932),
    Size(768, 1024),
    Size(1024, 768),
    Size(568, 320),
  ];

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.fromValues()),
        backendHealthServiceProvider.overrideWithValue(
          const _UnexpectedBackendHealthService(),
        ),
      ],
      child: const ClientMerchandiseControlApp(locale: Locale('es', 'CL')),
    );
  }

  Future<void> configureViewport(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    await tester.binding.setSurfaceSize(size);
    tester.view.viewPadding = safeAreaInsets;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
  }

  void restoreViewport(WidgetTester tester) {
    tester.view.resetViewPadding();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.binding.setSurfaceSize(null);
  }

  for (final viewport in viewportCases) {
    testWidgets('shell completa rifluisce a testo 200% su '
        '${viewport.width}x${viewport.height} con SafeArea', (tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(() => restoreViewport(tester));
      await configureViewport(tester, viewport);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final shellContext = tester.element(find.byType(AppShellScreen));
      final mediaQuery = MediaQuery.of(shellContext);
      expect(mediaQuery.viewPadding.top, safeAreaInsets.top);
      expect(mediaQuery.viewPadding.bottom, safeAreaInsets.bottom);
      expect(mediaQuery.textScaler.scale(1), 2);

      _expectCurrentPageUsesAvailableWidth(tester);
      await _expectActionIsFullyReachable(
        tester,
        key: const ValueKey('home-search'),
      );
      expect(find.byType(CatalogScreen), findsOneWidget);
      _expectCurrentPageUsesAvailableWidth(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('nav-cart')));
      await tester.pumpAndSettle();
      expect(find.byType(CartScreen), findsOneWidget);
      _expectCurrentPageUsesAvailableWidth(tester);
      await _expectActionIsFullyReachable(
        tester,
        key: const ValueKey('cart-explore-catalog'),
      );
      expect(find.byType(CatalogScreen), findsOneWidget);
      _expectCurrentPageUsesAvailableWidth(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('nav-account')));
      await tester.pumpAndSettle();
      expect(find.byType(AccountScreen), findsOneWidget);
      _expectCurrentPageUsesAvailableWidth(tester);
      await _scrollFullyIntoView(
        tester,
        find.byKey(const ValueKey('account-google-button')),
      );
      final googleButton = find.byKey(const ValueKey('account-google-button'));
      _expectRectInside(
        tester.getRect(googleButton),
        tester.getRect(_currentPageScrollView()),
      );
      expect(
        tester.getSize(googleButton).height,
        greaterThanOrEqualTo(AppSizes.minimumTouchTarget),
      );
      expect(
        tester
            .getSemantics(googleButton)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      _expectCurrentPageUsesAvailableWidth(tester);

      for (final key in const [
        ValueKey('nav-home'),
        ValueKey('nav-catalog'),
        ValueKey('nav-orders'),
        ValueKey('nav-cart'),
        ValueKey('nav-account'),
      ]) {
        final destination = find.byKey(key);
        final targetSize = tester.getSize(destination);
        expect(
          targetSize.width,
          greaterThanOrEqualTo(AppSizes.minimumTouchTarget),
        );
        expect(
          targetSize.height,
          greaterThanOrEqualTo(AppSizes.minimumTouchTarget),
        );
      }

      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets(
      'shell completa applica tema ${brightness.name} con Semantics principali',
      (tester) async {
        final semantics = tester.ensureSemantics();
        addTearDown(() => restoreViewport(tester));
        await configureViewport(tester, const Size(390, 844));
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(HomeScreen));
        final l10n = AppLocalizations.of(context);
        expect(Theme.of(context).brightness, brightness);

        final search = find.byKey(const ValueKey('home-search'));
        final searchSemantics = tester.getSemantics(search).getSemanticsData();
        expect(searchSemantics.label, l10n.homeSearchLabel);
        expect(searchSemantics.hasAction(SemanticsAction.tap), isTrue);
        expect(
          tester.getSize(search).height,
          greaterThanOrEqualTo(AppSizes.minimumTouchTarget),
        );

        final routeTitleSemantics = tester.widgetList<Semantics>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.header == true &&
                widget.properties.namesRoute == true,
          ),
        );
        expect(routeTitleSemantics, hasLength(1));
        expect(tester, meetsGuideline(labeledTapTargetGuideline));
        expect(tester, meetsGuideline(androidTapTargetGuideline));
        expect(tester, meetsGuideline(iOSTapTargetGuideline));
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}

final class _UnexpectedBackendHealthService implements BackendHealthService {
  const _UnexpectedBackendHealthService();

  @override
  Future<BackendHealthResult> check({
    required Uri origin,
    required String publishableKey,
    required BackendProbeCancellation cancellation,
  }) {
    throw StateError('Development must not contact the backend.');
  }

  @override
  void close() {}
}

void _expectCurrentPageUsesAvailableWidth(WidgetTester tester) {
  final catalog = find.byType(CatalogScreen);
  if (catalog.evaluate().isNotEmpty) {
    expect(catalog, findsOneWidget);
    final scrollView = find.descendant(
      of: catalog,
      matching: find.byType(CustomScrollView),
    );
    expect(scrollView, findsOneWidget);

    final pageWidth = tester.getSize(catalog).width;
    expect(tester.getSize(scrollView).width, closeTo(pageWidth, 0.01));
    final basePadding = pageWidth >= AppBreakpoints.wide
        ? AppSpacing.xxl
        : pageWidth <= AppBreakpoints.narrow
        ? AppSpacing.md
        : AppSpacing.lg;
    final expectedPadding =
        basePadding +
        math.max(0, (pageWidth - AppSizes.catalogContentMaxWidth) / 2);
    final firstPadding = tester.widget<SliverPadding>(
      find.descendant(of: catalog, matching: find.byType(SliverPadding)).first,
    );
    final resolved = firstPadding.padding.resolve(TextDirection.ltr);
    expect(resolved.left, closeTo(expectedPadding, 0.01));
    expect(resolved.right, closeTo(expectedPadding, 0.01));
    expect(
      pageWidth - resolved.horizontal,
      lessThanOrEqualTo(AppSizes.catalogContentMaxWidth),
    );
    return;
  }

  final pageFinder = find.byType(StorefrontPage);
  expect(pageFinder, findsOneWidget);

  final page = tester.widget<StorefrontPage>(pageFinder);
  final pageWidth = tester.getSize(pageFinder).width;
  final horizontalPadding = pageWidth >= AppBreakpoints.wide
      ? AppSpacing.xxl
      : pageWidth <= AppBreakpoints.narrow
      ? AppSpacing.md
      : AppSpacing.lg;
  final expectedContentWidth = math.min(
    page.maxWidth,
    pageWidth - (horizontalPadding * 2),
  );

  final contentBox = find.descendant(
    of: pageFinder,
    matching: find.byWidgetPredicate(
      (widget) => widget is SizedBox && widget.width == double.infinity,
    ),
  );
  expect(contentBox, findsOneWidget);
  expect(tester.getSize(contentBox).width, closeTo(expectedContentWidth, 0.01));
  expect(tester.getSize(contentBox).width, lessThanOrEqualTo(page.maxWidth));
}

Future<void> _expectActionIsFullyReachable(
  WidgetTester tester, {
  required ValueKey<String> key,
}) async {
  final action = find.byKey(key);
  await _scrollFullyIntoView(tester, action);

  final scrollView = _currentPageScrollView();
  _expectRectInside(tester.getRect(action), tester.getRect(scrollView));
  final actionSize = tester.getSize(action);
  expect(actionSize.width, greaterThanOrEqualTo(AppSizes.minimumTouchTarget));
  expect(actionSize.height, greaterThanOrEqualTo(AppSizes.minimumTouchTarget));
  expect(action.hitTestable(), findsOneWidget);

  final semantics = tester.getSemantics(action).getSemanticsData();
  expect(semantics.hasAction(SemanticsAction.tap), isTrue);

  await tester.tap(action);
  await tester.pumpAndSettle();
}

Future<void> _scrollFullyIntoView(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  await Scrollable.ensureVisible(
    tester.element(target),
    alignment: 0.5,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
}

Finder _currentPageScrollView() {
  return find.byKey(StorefrontPage.scrollViewKey);
}

void _expectRectInside(Rect inner, Rect outer) {
  const tolerance = 0.01;
  expect(inner.left, greaterThanOrEqualTo(outer.left - tolerance));
  expect(inner.top, greaterThanOrEqualTo(outer.top - tolerance));
  expect(inner.right, lessThanOrEqualTo(outer.right + tolerance));
  expect(inner.bottom, lessThanOrEqualTo(outer.bottom + tolerance));
}
