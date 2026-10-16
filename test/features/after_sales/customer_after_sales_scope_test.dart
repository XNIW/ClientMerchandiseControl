import 'dart:async';
import 'dart:typed_data';
import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_repository.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import '../../support/commerce_surface_fixtures.dart';

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
  for (final change in ['A-B-A', 'shop', 'expiry']) {
    testWidgets(
      'batch allegati scarta lettura tardiva con Auth reale $change',
      (tester) async {
        final repository = _EvidenceSequenceRepository();
        final config = StateProvider<AppConfig>(
          (ref) => AppConfig.authFlowTest(),
        );
        final rig = await openCustomerSessionRoute(
          tester,
          location: AppRoutes.afterSalesCreateLocation(orderTestOrder),
          overrides: [
            appConfigProvider.overrideWith((ref) => ref.watch(config)),
            backendReadinessRepositoryProvider.overrideWithValue(
              const _NoNetworkReadiness(),
            ),
            customerAfterSalesRepositoryProvider.overrideWithValue(repository),
          ],
        );
        final reader = Completer<Uint8List>();
        final controller = rig.container.read(
          customerAfterSalesControllerProvider.notifier,
        );
        final pending = controller.submitWithEvidence(
          draft: CustomerAfterSalesDraft(
            orderId: orderTestOrder,
            type: CustomerAfterSalesType.orderProblem,
            reason: CustomerAfterSalesReason.damaged,
            note: _privateNote,
            lines: const [
              CustomerAfterSalesLineDraft(
                orderItemId: task054VisualOrderItem,
                quantity: 1,
              ),
            ],
          ),
          attachments: [
            CustomerAfterSalesLocalAttachment(
              name: 'privato-A.png',
              extension: 'png',
              mimeType: 'image/png',
              readBytes: () => reader.future,
            ),
          ],
          canContinue: () => true,
        );
        await tester.pump();
        expect(repository.creates, 1);
        if (change == 'A-B-A') {
          rig.auth.signIn(routeFixtureOwnerB);
          rig.auth.signIn(routeFixtureOwnerA);
        } else if (change == 'shop') {
          rig.container.read(config.notifier).state = AppConfig.authFlowTest(
            storefrontShopSlug: 'other-test-shop',
          );
        } else {
          rig.auth.expire();
        }
        await tester.pump();
        reader.complete(Uint8List.fromList([1]));
        await tester.pumpAndSettle();
        expect(await pending, isNull);
        expect(repository.uploads, 0);
        expect(controller.attachmentsFor(task054VisualCase), isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
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

class _EvidenceSequenceRepository implements CustomerAfterSalesRepository {
  var creates = 0, uploads = 0;
  @override
  Future<List<CustomerAfterSalesCase>> list({required String shopSlug}) async =>
      [];
  @override
  Future<CustomerAfterSalesOrderLines> listOrderLines(String orderId) =>
      _AfterSalesRepository().listOrderLines(orderId);
  @override
  Future<CustomerAfterSalesCase> create({
    required CustomerAfterSalesDraft draft,
    required String idempotencyKey,
  }) async {
    creates++;
    final value = task054AfterSalesCase();
    return CustomerAfterSalesCase(
      id: value.id,
      caseCode: value.caseCode,
      orderId: draft.orderId,
      type: value.type,
      status: value.status,
      reason: value.reason,
      note: draft.note,
      version: value.version,
      submittedAt: value.submittedAt,
      updatedAt: value.updatedAt,
      lines: value.lines,
      evidence: value.evidence,
      timeline: value.timeline,
    );
  }

  @override
  Future<CustomerAfterSalesCase> cancel({
    required String caseId,
    required int expectedVersion,
  }) async => task054AfterSalesCase();
  @override
  Future<String> uploadEvidence({
    required String caseId,
    required CustomerAfterSalesEvidenceInput input,
  }) async {
    uploads++;
    return '89000000-0000-4000-8000-000000000001';
  }
}

// Il cambio shop può ricostruire Home: questa fixture verifica solo il fence
// assistenza/Auth e non deve avviare il probe remoto estraneo alla prova.
class _NoNetworkReadiness implements BackendReadinessRepository {
  const _NoNetworkReadiness();
  @override
  BackendReadinessState get initialState => BackendReadinessState.offline;
  @override
  bool get canCheck => false;
  @override
  Future<BackendReadinessState> check({
    required BackendProbeCancellation cancellation,
  }) async => BackendReadinessState.offline;
}
