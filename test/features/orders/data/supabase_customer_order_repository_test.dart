import 'dart:async';
import 'dart:io';

import 'package:client_merchandise_control/features/orders/data/supabase_customer_order_repository.dart';
import 'package:client_merchandise_control/features/orders/domain/customer_order_failure.dart';
import 'package:client_merchandise_control/features/orders/domain/customer_order_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../customer_order_test_support.dart';

void main() {
  late FakeCustomerOrderPort port;
  late SupabaseCustomerOrderRepository repository;

  setUp(() {
    port = FakeCustomerOrderPort()..response = orderTestListPayload();
    repository = SupabaseCustomerOrderRepository(port: port);
  });

  test('lista usa slug e keyset pubblico con limite bounded', () async {
    final cursor = CustomerOrderCursor(
      beforePlacedAt: orderTestNow.subtract(const Duration(hours: 1)),
      beforeOrderId: orderTestOlderOrder,
    );

    final page = await repository.listOrders(
      shopSlug: orderTestShop,
      cursor: cursor,
      limit: 20,
    );

    expect(page.orders.single.id, orderTestOrder);
    expect(page.orders.single.primaryItemName, 'Café público');
    expect(page.orders.single.timeZone, 'America/Santiago');
    expect(port.function, 'customer_order_list_v1');
    expect(port.parameters, {
      'p_shop_slug': orderTestShop,
      'p_limit': 20,
      'p_before_placed_at': cursor.beforePlacedAt.toIso8601String(),
      'p_before_order_id': orderTestOlderOrder,
    });
    expect(
      port.parameters!.keys,
      isNot(contains(anyOf('shopId', 'ownerUserId', 'email', 'totalClp'))),
    );
  });

  test(
    'timezone atomica è validata e aggiornata tra lista e dettaglio',
    () async {
      final page = await repository.listOrders(shopSlug: orderTestShop);
      port.response = {...orderTestDetailPayload(), 'timeZone': 'UTC'};
      final detail = await repository.loadOrder(
        shopSlug: orderTestShop,
        orderId: orderTestOrder,
      );

      expect(page.orders.single.timeZone, 'America/Santiago');
      expect(detail.timeZone, 'UTC');
      expect(port.calls, 2);

      final invalidPort = FakeCustomerOrderPort()
        ..response = {...orderTestListPayload(), 'timeZone': 'Mars/Olympus'};
      await expectLater(
        SupabaseCustomerOrderRepository(
          port: invalidPort,
        ).listOrders(shopSlug: orderTestShop),
        throwsA(_failure(CustomerOrderFailureKind.unexpected)),
      );
    },
  );

  test(
    'letture concorrenti mantengono timezone del proprio snapshot',
    () async {
      final firstResponse = Completer<Object?>();
      final secondResponse = Completer<Object?>();
      port.responseSequence.addAll([
        firstResponse.future,
        secondResponse.future,
      ]);

      final first = repository.listOrders(shopSlug: orderTestShop);
      final second = repository.listOrders(shopSlug: orderTestShop);
      await Future<void>.delayed(Duration.zero);
      expect(port.calls, 2);
      secondResponse.complete({...orderTestListPayload(), 'timeZone': 'UTC'});
      firstResponse.complete(orderTestListPayload());

      final pages = await Future.wait([first, second]);
      expect(pages.map((page) => page.orders.single.timeZone), [
        'America/Santiago',
        'UTC',
      ]);
      expect(port.calls, 2);
    },
  );

  test(
    'paginazione verifica ordine deterministico e identità cursor',
    () async {
      final newer = orderTestCardPayload();
      final older = orderTestCardPayload(
        id: orderTestOlderOrder,
        code: 'MC-1123456789ABCDEF0123',
        placedAt: orderTestNow.subtract(const Duration(hours: 1)),
      );
      port.response = orderTestListPayload(
        orders: [newer, older],
        hasMore: true,
      );

      final page = await repository.listOrders(shopSlug: orderTestShop);
      expect(page.orders.map((order) => order.id), [
        orderTestOrder,
        orderTestOlderOrder,
      ]);
      expect(page.nextCursor?.beforeOrderId, orderTestOlderOrder);

      port.response = {
        ...orderTestListPayload(orders: [newer, older], hasMore: true),
        'nextCursor': {
          'beforePlacedAt': newer['placedAt'],
          'beforeOrderId': orderTestOrder,
        },
      };
      await expectLater(
        repository.listOrders(shopSlug: orderTestShop),
        throwsA(_failure(CustomerOrderFailureKind.unexpected)),
      );
    },
  );

  test('detail valida snapshot, timeline e fulfillment pubblici', () async {
    port.response = orderTestDetailPayload();

    final detail = await repository.loadOrder(
      shopSlug: orderTestShop,
      orderId: orderTestOrder,
    );

    expect(port.function, 'customer_order_detail_v1');
    expect(port.parameters, {
      'p_shop_slug': orderTestShop,
      'p_order_id': orderTestOrder,
    });
    expect(detail.code, orderTestCode);
    expect(detail.totalClp, 2400);
    expect(detail.items.single.publicName, 'Café público');
    expect(detail.timeline.single.status, CustomerOrderStatus.confirmed);
    expect(detail.fulfillment.destinationTitle, 'Tienda Centro');
  });

  test(
    'cancel invia versione e chiave idempotente senza totale client',
    () async {
      port.response = orderTestDetailPayload(
        status: 'cancelled',
        version: 2,
        cancellationAllowed: false,
        idempotent: true,
      );

      final detail = await repository.cancelOrder(
        shopSlug: orderTestShop,
        orderId: orderTestOrder,
        expectedStatusVersion: 1,
        idempotencyKey: orderTestKey,
      );

      expect(detail.status, CustomerOrderStatus.cancelled);
      expect(detail.idempotent, isTrue);
      expect(port.function, 'customer_order_cancel_v1');
      expect(port.parameters, {
        'p_shop_slug': orderTestShop,
        'p_order_id': orderTestOrder,
        'p_expected_status_version': 1,
        'p_idempotency_key': orderTestKey,
      });
      expect(
        port.parameters!.keys,
        isNot(contains(anyOf('priceClp', 'discountClp', 'totalClp', 'shopId'))),
      );
    },
  );

  test('stati remoti minimali mappano i failure di dominio', () async {
    for (final entry in const {
      'not_found': CustomerOrderFailureKind.notFound,
      'not_cancellable': CustomerOrderFailureKind.notCancellable,
      'version_conflict': CustomerOrderFailureKind.versionConflict,
      'idempotency_conflict': CustomerOrderFailureKind.idempotencyConflict,
      'unavailable': CustomerOrderFailureKind.unavailable,
    }.entries) {
      port.response = {
        'apiVersion': 'customer-order-detail.v1',
        'status': entry.key,
        'idempotent': false,
        'orderId': orderTestOrder,
        'serverTime': orderTestNow.toIso8601String(),
      };
      await expectLater(
        repository.loadOrder(shopSlug: orderTestShop, orderId: orderTestOrder),
        throwsA(_failure(entry.value)),
        reason: entry.key,
      );
    }
  });

  test(
    'payload con dato interno o identità cross-shop fallisce chiuso',
    () async {
      for (final payload in [
        {...orderTestDetailPayload(), 'sourceProductId': orderTestPublication},
        {...orderTestDetailPayload(), 'shopSlug': 'other-shop'},
        {
          ...orderTestDetailPayload(),
          'items': [
            {
              ...(orderTestDetailPayload()['items']! as List).single
                  as Map<String, Object?>,
              'supplier': 'internal',
            },
          ],
        },
        {...orderTestDetailPayload(), 'totalClp': 1},
      ]) {
        port.response = payload;
        await expectLater(
          repository.loadOrder(
            shopSlug: orderTestShop,
            orderId: orderTestOrder,
          ),
          throwsA(_failure(CustomerOrderFailureKind.unexpected)),
        );
      }
    },
  );

  test('input invalido non raggiunge la porta', () async {
    await expectLater(
      repository.loadOrder(shopSlug: '../internal', orderId: orderTestOrder),
      throwsA(_failure(CustomerOrderFailureKind.invalid)),
    );
    await expectLater(
      repository.cancelOrder(
        shopSlug: orderTestShop,
        orderId: orderTestOrder,
        expectedStatusVersion: 0,
        idempotencyKey: orderTestKey,
      ),
      throwsA(_failure(CustomerOrderFailureKind.invalid)),
    );
    await expectLater(
      repository.listOrders(shopSlug: orderTestShop, limit: 51),
      throwsA(_failure(CustomerOrderFailureKind.invalid)),
    );
    expect(port.calls, 0);
  });

  test('offline e timeout vengono classificati senza crash', () async {
    port.error = const SocketException('offline');
    await expectLater(
      repository.listOrders(shopSlug: orderTestShop),
      throwsA(_failure(CustomerOrderFailureKind.offline)),
    );

    final never = Completer<Object?>();
    final slowPort = _CompleterPort(never.future);
    final fastTimeout = SupabaseCustomerOrderRepository(
      port: slowPort,
      requestTimeout: const Duration(milliseconds: 1),
    );
    await expectLater(
      fastTimeout.listOrders(shopSlug: orderTestShop),
      throwsA(_failure(CustomerOrderFailureKind.timeout)),
    );
  });
}

Matcher _failure(CustomerOrderFailureKind kind) =>
    isA<CustomerOrderRepositoryException>().having(
      (error) => error.kind,
      'kind',
      kind,
    );

final class _CompleterPort implements CustomerOrderPort {
  const _CompleterPort(this.result);

  final Future<Object?> result;

  @override
  Future<Object?> invoke(String function, Map<String, Object?> parameters) =>
      result;
}
