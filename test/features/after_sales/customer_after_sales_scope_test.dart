import 'dart:async';

import 'package:client_merchandise_control/app/router/app_routes.dart';
import 'package:client_merchandise_control/features/after_sales/application/customer_after_sales_controller.dart';
import 'package:client_merchandise_control/features/after_sales/domain/customer_after_sales_models.dart';
import 'package:client_merchandise_control/features/after_sales/domain/customer_after_sales_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/customer_session_route_fixture.dart';
import '../orders/customer_order_test_support.dart';

const _privateLine = 'Riga privata assistenza owner A';
const _privateNote = 'Bozza privata assistenza owner A';

void main() {
  testWidgets('stesso owner conserva la bozza assistenza', (tester) async {
    final repository = _AfterSalesRepository();
    final rig = await openCustomerSessionRoute(
      tester,
      location: AppRoutes.afterSalesCreateLocation(orderTestOrder),
      overrides: [
        customerAfterSalesRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final note = find.byType(TextField);
    await tester.ensureVisible(note);
    await tester.enterText(note, _privateNote);
    rig.auth.signIn(routeFixtureOwnerA);
    await tester.pumpAndSettle();
    expect(find.text(_privateNote), findsOneWidget);
    expect(repository.createCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cambio owner rimuove righe e bozza assistenza dalla route reale',
    (tester) async {
      final repository = _AfterSalesRepository();
      final rig = await openCustomerSessionRoute(
        tester,
        location: AppRoutes.afterSalesCreateLocation(orderTestOrder),
        overrides: [
          customerAfterSalesRepositoryProvider.overrideWithValue(repository),
        ],
      );
      final note = find.byType(TextField);
      await tester.ensureVisible(note);
      await tester.enterText(note, _privateNote);
      expect(find.text(_privateNote), findsOneWidget);

      rig.auth.signIn(routeFixtureOwnerB);
      await tester.pumpAndSettle();

      expect(find.text(_privateNote), findsNothing);
      expect(find.text(_privateLine), findsNothing);
      expect(repository.createCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'righe ordine tardive dopo revoca non compaiono nel form assistenza',
    (tester) async {
      final repository = _AfterSalesRepository()..deferLines = true;
      final rig = await openCustomerSessionRoute(
        tester,
        location: AppRoutes.afterSalesCreateLocation(orderTestOrder),
        overrides: [
          customerAfterSalesRepositoryProvider.overrideWithValue(repository),
        ],
      );
      rig.auth.expire();
      await tester.pump();
      repository.pendingLines.complete(_lines());
      await tester.pumpAndSettle();

      expect(find.text(_privateLine), findsNothing);
      expect(find.byKey(const ValueKey('after-sales-submit')), findsNothing);
      expect(repository.createCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );
}

CustomerAfterSalesOrderLines _lines() => CustomerAfterSalesOrderLines(
  orderId: orderTestOrder,
  shopSlug: orderTestShop,
  items: const [
    CustomerAfterSalesOrderLine(
      orderItemId: '85000000-0000-4000-8000-000000000001',
      name: _privateLine,
      orderedQuantity: 1,
      existingOpenQuantity: 0,
      maximumRequestQuantity: 1,
    ),
  ],
  serverTime: orderTestNow,
);

final class _AfterSalesRepository implements CustomerAfterSalesRepository {
  var deferLines = false;
  var createCalls = 0;
  final pendingLines = Completer<CustomerAfterSalesOrderLines>();
  @override
  Future<List<CustomerAfterSalesCase>> list({required String shopSlug}) async =>
      [];
  @override
  Future<CustomerAfterSalesOrderLines> listOrderLines(String orderId) async =>
      deferLines ? pendingLines.future : _lines();
  @override
  Future<CustomerAfterSalesCase> create({
    required CustomerAfterSalesDraft draft,
    required String idempotencyKey,
  }) async {
    createCalls++;
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
