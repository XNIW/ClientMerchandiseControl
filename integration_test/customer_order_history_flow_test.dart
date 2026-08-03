import 'package:client_merchandise_control/app/router/app_routes.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/orders/application/customer_order_providers.dart';
import 'package:client_merchandise_control/features/orders/presentation/order_detail_screen.dart';
import 'package:client_merchandise_control/features/orders/presentation/orders_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import '../test/features/orders/customer_order_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('history → detail → cancellazione idempotente', (tester) async {
    final repository = FakeCustomerOrderRepository()
      ..cancelOutcomes.add(orderTestCancelledDetail());
    final router = GoRouter(
      initialLocation: AppRoutes.ordersLocation,
      routes: [
        GoRoute(
          path: AppRoutes.accountLocation,
          builder: (context, state) => const Scaffold(body: Text('account')),
        ),
        GoRoute(
          path: AppRoutes.ordersLocation,
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: AppRoutes.orderPattern,
          builder: (context, state) =>
              OrderDetailScreen(orderId: state.pathParameters['orderId'] ?? ''),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerOrderIdentityProvider.overrideWithValue(_identity()),
          customerOrderShopSlugProvider.overrideWithValue(orderTestShop),
          customerOrderRepositoryProvider.overrideWithValue(repository),
          customerOrderCacheStoreProvider.overrideWithValue(
            MemoryCustomerOrderCacheStore(),
          ),
          customerOrderClockProvider.overrideWithValue(() => orderTestNow),
          customerOrderIdempotencyKeyFactoryProvider.overrideWithValue(
            () => orderTestKey,
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          locale: const Locale('es', 'CL'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('order-card-$orderTestOrder')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.orderLocation(orderTestOrder));
    expect(find.byKey(const ValueKey('order-detail-header')), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('order-detail-scroll')),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('order-cancel-button')));
    await tester.pumpAndSettle();
    expect(repository.cancelRequests, isEmpty);

    await tester.tap(find.byKey(const ValueKey('order-cancel-confirm')));
    await tester.pumpAndSettle();
    expect(repository.cancelRequests, hasLength(1));
    expect(repository.cancelRequests.single.idempotencyKey, orderTestKey);
    expect(find.byKey(const ValueKey('order-cancellation-card')), findsNothing);
    expect(find.text('Cancelado'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

AuthenticatedCustomer _identity() =>
    AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: orderTestOwner,
      email: 'customer@example.invalid',
      metadata: const {'name': 'Cliente Uno'},
    );
