import 'package:client_merchandise_control/app/router/app_routes.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/after_sales/presentation/customer_after_sales_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/commerce_surface_fixtures.dart';

void main() {
  testWidgets(
    'caso assistenza mancante spiega destinazione e permette proseguire',
    (tester) async {
      final fixture = Task054VisualFixtures(state: Task054VisualState.empty);
      final router = _router();
      addTearDown(router.dispose);
      await tester.pumpWidget(fixture.wrap(_app(router)));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('after-sales-destination-unavailable')),
        findsOneWidget,
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(CustomerAfterSalesScreen)),
      );
      expect(find.text(l10n.afterSalesFailure), findsNothing);
      await tester.tap(find.byKey(const ValueKey('after-sales-back-to-list')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.afterSalesBaseLocation);
      expect(find.text(l10n.afterSalesEmpty), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('errore temporaneo dettaglio assistenza offre retry reale', (
    tester,
  ) async {
    final fixture = Task054VisualFixtures(state: Task054VisualState.error);
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(fixture.wrap(_app(router)));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('after-sales-destination-unavailable')),
      findsNothing,
    );
    final retry = find.byKey(const ValueKey('after-sales-detail-retry'));
    expect(retry, findsOneWidget);
    fixture.afterSales.state = Task054VisualState.loaded;
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.text(task054AfterSalesCase().caseCode), findsOneWidget);
    expect(
      router.state.uri.path,
      AppRoutes.afterSalesLocation(task054VisualCase),
    );
    expect(tester.takeException(), isNull);
  });
}

GoRouter _router() => GoRouter(
  initialLocation: AppRoutes.afterSalesLocation(task054VisualCase),
  routes: [
    GoRoute(
      path: AppRoutes.afterSalesBaseLocation,
      builder: (_, _) => const CustomerAfterSalesScreen(),
    ),
    GoRoute(
      path: AppRoutes.afterSalesPattern,
      builder: (_, state) =>
          CustomerAfterSalesScreen(caseId: state.pathParameters['caseId']),
    ),
  ],
);

Widget _app(GoRouter router) => MaterialApp.router(
  routerConfig: router,
  theme: AppTheme.light(),
  locale: const Locale('es', 'CL'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
);
