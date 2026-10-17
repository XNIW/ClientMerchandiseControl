import 'dart:async';

import 'package:client_merchandise_control/app/router/app_router.dart';
import 'package:client_merchandise_control/app/router/app_routes.dart';
import 'package:client_merchandise_control/features/after_sales/application/customer_after_sales_controller.dart';
import 'package:client_merchandise_control/features/after_sales/domain/customer_after_sales_models.dart';
import 'package:client_merchandise_control/features/after_sales/domain/customer_after_sales_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/customer_session_route_fixture.dart';
import '../orders/customer_order_test_support.dart';

const _orderB = '80000000-0000-4000-8000-000000028002';
const _lineA = '85000000-0000-4000-8000-000000000001';
const _lineB = '85000000-0000-4000-8000-000000000002';
const _nameA = 'Riga ordine A';
const _nameB = 'Riga ordine B';
const _noteA = 'Nota soltanto per ordine A';

void main() {
  testWidgets('query ordine mantiene A-A e separa il nuovo form B', (tester) async {
    final repository = _OrderQueryRepository();
    final rig = await openCustomerSessionRoute(
      tester,
      location: AppRoutes.afterSalesCreateLocation(orderTestOrder),
      overrides: [
        customerAfterSalesRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final router = rig.container.read(appRouterProvider);
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.enterText(find.byType(TextField), _noteA);
    router.go(AppRoutes.afterSalesCreateLocation(orderTestOrder));
    await tester.pumpAndSettle();
    expect(repository.lineRequests, [orderTestOrder]);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, _noteA);

    router.go(AppRoutes.afterSalesCreateLocation(_orderB));
    await tester.pumpAndSettle();
    expect(repository.lineRequests, [orderTestOrder, _orderB]);
    expect(find.text(_nameA), findsNothing);
    expect(find.text(_nameB), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);

    final submit = find.byKey(const ValueKey('after-sales-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(repository.drafts, isEmpty);
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(repository.drafts, hasLength(1));
    expect(repository.drafts.single.orderId, _orderB);
    expect(repository.drafts.single.lines.single.orderItemId, _lineB);
    expect(repository.drafts.single.note, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('risposta ordine A tardiva non entra nel form B o nella lista',
      (tester) async {
    final repository = _OrderQueryRepository(deferA: true);
    addTearDown(() {
      if (!repository.pendingA.isCompleted) {
        repository.pendingA.complete(_lines(orderTestOrder));
      }
    });
    final rig = await openCustomerSessionRoute(
      tester,
      location: AppRoutes.afterSalesCreateLocation(orderTestOrder),
      overrides: [
        customerAfterSalesRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final router = rig.container.read(appRouterProvider);
    router.go(AppRoutes.afterSalesCreateLocation(_orderB));
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(repository.lineRequests, [orderTestOrder, _orderB]);
    expect(find.text(_nameB), findsOneWidget);
    expect(find.text(_nameA), findsNothing);

    repository.pendingA.complete(_lines(orderTestOrder));
    await tester.pumpAndSettle();
    expect(find.text(_nameA), findsNothing);
    expect(find.text(_nameB), findsOneWidget);
    router.go(AppRoutes.afterSalesBaseLocation);
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byKey(const ValueKey('after-sales-submit')), findsNothing);
    expect(find.text(_nameA), findsNothing);
    expect(find.text(_nameB), findsNothing);
    expect(repository.drafts, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

CustomerAfterSalesOrderLines _lines(String orderId) => CustomerAfterSalesOrderLines(
  orderId: orderId,
  shopSlug: orderTestShop,
  items: [
    CustomerAfterSalesOrderLine(
      orderItemId: orderId == orderTestOrder ? _lineA : _lineB,
      name: orderId == orderTestOrder ? _nameA : _nameB,
      orderedQuantity: 1,
      existingOpenQuantity: 0,
      maximumRequestQuantity: 1,
    ),
  ],
  serverTime: orderTestNow,
);

final class _OrderQueryRepository implements CustomerAfterSalesRepository {
  _OrderQueryRepository({this.deferA = false});

  final bool deferA;
  final pendingA = Completer<CustomerAfterSalesOrderLines>();
  final lineRequests = <String>[];
  final drafts = <CustomerAfterSalesDraft>[];

  @override
  Future<List<CustomerAfterSalesCase>> list({required String shopSlug}) async => [];

  @override
  Future<CustomerAfterSalesOrderLines> listOrderLines(String orderId) async {
    lineRequests.add(orderId);
    if (deferA && orderId == orderTestOrder) return pendingA.future;
    return _lines(orderId);
  }

  @override
  Future<CustomerAfterSalesCase> create({
    required CustomerAfterSalesDraft draft,
    required String idempotencyKey,
  }) async {
    drafts.add(draft);
    throw const CustomerAfterSalesException('unavailable');
  }

  @override
  Future<CustomerAfterSalesCase> cancel({
    required String caseId,
    required int expectedVersion,
  }) async => throw const CustomerAfterSalesException('unavailable');

  @override
  Future<String> uploadEvidence({
    required String caseId,
    required CustomerAfterSalesEvidenceInput input,
  }) async => throw const CustomerAfterSalesException('unavailable');
}
