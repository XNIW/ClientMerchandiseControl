import 'dart:async';

import 'package:client_merchandise_control/app/router/app_routes.dart';
import 'package:client_merchandise_control/features/orders/domain/customer_order_models.dart';
import 'package:client_merchandise_control/features/orders/domain/customer_order_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/customer_session_route_fixture.dart';
import 'customer_order_test_support.dart';

const _privatePreview = 'Riga privata riordino owner A';

void main() {
  testWidgets('stesso owner conserva preview e conferma riordino', (
    tester,
  ) async {
    final repository = _ReorderRepository();
    final rig = await openCustomerSessionRoute(
      tester,
      location: AppRoutes.orderLocation(orderTestOrder),
      orderRepository: repository,
    );
    await _openPreview(tester);
    rig.auth.signIn(routeFixtureOwnerA);
    await _paint(tester);
    expect(find.text(_privatePreview), findsOneWidget);
    expect(
      find.byKey(const ValueKey('customer-order-reorder-apply')).hitTestable(),
      findsOneWidget,
    );
    expect(repository.applyCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la revoca chiude la preview riordino già aperta', (
    tester,
  ) async {
    final repository = _ReorderRepository();
    final rig = await openCustomerSessionRoute(
      tester,
      location: AppRoutes.orderLocation(orderTestOrder),
      orderRepository: repository,
    );
    await _openPreview(tester);
    expect(find.text(_privatePreview), findsOneWidget);

    rig.auth.expire();
    await _paint(tester);

    expect(find.text(_privatePreview), findsNothing);
    expect(
      find.byKey(const ValueKey('customer-order-reorder-apply')),
      findsNothing,
    );
    expect(repository.applyCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('apply riordino tardivo A non pubblica la ricevuta per B', (
    tester,
  ) async {
    final repository = _ReorderRepository()..deferApply = true;
    final rig = await openCustomerSessionRoute(
      tester,
      location: AppRoutes.orderLocation(orderTestOrder),
      orderRepository: repository,
    );
    await _openPreview(tester);
    await tester.tap(
      find.byKey(const ValueKey('customer-order-reorder-apply')),
    );
    await tester.pump();
    expect(repository.applyCalls, 1);

    rig.auth.signIn(routeFixtureOwnerB);
    await tester.pump();
    repository.pendingApply.complete(_result());
    await _paint(tester);

    expect(find.text(_privatePreview), findsNothing);
    expect(
      find.byKey(const ValueKey('customer-order-reorder-open-cart')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening riordino A-B-A viene invalidato prima del primo paint', (
    tester,
  ) async {
    final repository = _ReorderRepository();
    final rig = await openCustomerSessionRoute(
      tester,
      location: AppRoutes.orderLocation(orderTestOrder),
      orderRepository: repository,
    );
    final action = find.byKey(const ValueKey('customer-order-reorder'));
    await tester.scrollUntilVisible(action, 300);
    await tester.ensureVisible(action);
    await _paint(tester);
    expect(action.hitTestable(), findsOneWidget);
    await tester.tap(action);
    await tester.idle();
    rig.auth.signIn(routeFixtureOwnerB);
    rig.auth.signIn(routeFixtureOwnerA);
    await tester.idle();
    await _paint(tester);

    expect(find.text(_privatePreview), findsNothing);
    expect(repository.applyCalls, 0);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openPreview(WidgetTester tester) async {
  final action = find.byKey(const ValueKey('customer-order-reorder'));
  await tester.scrollUntilVisible(action, 300);
  await tester.ensureVisible(action);
  await _paint(tester);
  expect(action.hitTestable(), findsOneWidget);
  await tester.tap(action);
  await _paint(tester);
}

CustomerReorderResult _result() => CustomerReorderResult(
  orderId: orderTestOrder,
  cartId: '86000000-0000-4000-8000-000000000001',
  cartVersion: 2,
  added: const [
    CustomerReorderAppliedLine(
      orderItemId: '85000000-0000-4000-8000-000000000001',
      publicationId: orderTestPublication,
      name: _privatePreview,
      quantity: 1,
      currentPriceClp: 1200,
      reason: null,
    ),
  ],
  skipped: const [],
  idempotent: false,
  serverTime: orderTestNow,
);

final class _ReorderRepository implements CustomerOrderRepository {
  final _delegate = FakeCustomerOrderRepository();
  final pendingApply = Completer<CustomerReorderResult>();
  var deferApply = false;
  var applyCalls = 0;

  @override
  Future<CustomerOrderPage> listOrders({
    required String shopSlug,
    CustomerOrderCursor? cursor,
    int limit = 20,
  }) => _delegate.listOrders(shopSlug: shopSlug, cursor: cursor, limit: limit);
  @override
  Future<CustomerOrderDetail> loadOrder({
    required String shopSlug,
    required String orderId,
  }) async => orderTestDetail(
    status: CustomerOrderStatus.cancelled,
    cancellationAllowed: false,
  );
  @override
  Future<CustomerOrderDetail> cancelOrder({
    required String shopSlug,
    required String orderId,
    required int expectedStatusVersion,
    required String idempotencyKey,
  }) => _delegate.cancelOrder(
    shopSlug: shopSlug,
    orderId: orderId,
    expectedStatusVersion: expectedStatusVersion,
    idempotencyKey: idempotencyKey,
  );
  @override
  Future<CustomerReorderPreview> previewReorder(String orderId) async =>
      CustomerReorderPreview(
        orderId: orderId,
        shopId: '20000000-0000-4000-8000-000000000001',
        items: const [
          CustomerReorderItem(
            orderItemId: '85000000-0000-4000-8000-000000000001',
            publicationId: orderTestPublication,
            name: _privatePreview,
            requestedQuantity: 1,
            allowedQuantity: 1,
            availability: CustomerReorderAvailability.available,
            historicalPriceClp: 1100,
            currentPriceClp: 1200,
            currentCompareAtPriceClp: null,
            currentPromotionName: null,
            priceDifferenceClp: 100,
          ),
        ],
        serverTime: orderTestNow,
      );
  @override
  Future<CustomerReorderResult> applyReorder({
    required String orderId,
    required String idempotencyKey,
  }) async {
    applyCalls++;
    return deferApply ? pendingApply.future : _result();
  }
}

Future<void> _paint(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}
