import 'dart:async';

import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/orders/application/customer_order_controller.dart';
import 'package:client_merchandise_control/features/orders/application/customer_order_providers.dart';
import 'package:client_merchandise_control/features/orders/domain/customer_order_failure.dart';
import 'package:client_merchandise_control/features/orders/domain/customer_order_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../customer_order_test_support.dart';

void main() {
  test(
    'deep link cold conserva la selezione durante il bootstrap cache/lista',
    () async {
      final repository = FakeCustomerOrderRepository();
      final container = _container(repository: repository);
      addTearDown(container.dispose);

      container.read(customerOrderControllerProvider);
      final open = container
          .read(customerOrderControllerProvider.notifier)
          .openOrder(orderTestOrder);
      await open;
      final state = await _waitFor(
        container,
        (state) =>
            state.status == CustomerOrdersStatus.ready &&
            state.selectedOrder?.id == orderTestOrder,
      );

      expect(state.selectedOrderId, orderTestOrder);
      expect(state.selectedOrder?.cancellation.allowed, isTrue);
      expect(repository.detailRequests, hasLength(1));
    },
  );

  test('cache-first resta leggibile offline per lista e dettaglio', () async {
    final repository = FakeCustomerOrderRepository()
      ..listOutcomes.add(customerOrderOffline)
      ..detailOutcomes.add(customerOrderOffline);
    final store = MemoryCustomerOrderCacheStore()..snapshot = orderTestCache();
    final container = _container(repository: repository, store: store);
    addTearDown(container.dispose);

    var state = await _waitFor(
      container,
      (state) => state.status == CustomerOrdersStatus.offline,
    );
    expect(state.orders.single.id, orderTestOrder);
    expect(state.failure, CustomerOrderFailureKind.offline);

    await container
        .read(customerOrderControllerProvider.notifier)
        .openOrder(orderTestOrder);
    state = container.read(customerOrderControllerProvider);
    expect(state.status, CustomerOrdersStatus.offline);
    expect(state.selectedOrder?.id, orderTestOrder);
    expect(state.selectedOrder?.totalClp, 2400);
  });

  test(
    'refresh online sostituisce cache e conserva solo detail visibili',
    () async {
      final repository = FakeCustomerOrderRepository();
      final store = MemoryCustomerOrderCacheStore()
        ..snapshot = orderTestCache(
          orders: [
            orderTestCard(
              id: orderTestOlderOrder,
              code: 'MC-1123456789ABCDEF0123',
              placedAt: orderTestNow.subtract(const Duration(hours: 1)),
            ),
          ],
          details: {
            orderTestOlderOrder: orderTestDetail(
              id: orderTestOlderOrder,
              code: 'MC-1123456789ABCDEF0123',
            ),
          },
        );
      final container = _container(repository: repository, store: store);
      addTearDown(container.dispose);

      final state = await _waitFor(
        container,
        (state) => state.status == CustomerOrdersStatus.ready,
      );
      expect(state.orders.single.id, orderTestOrder);
      expect(store.snapshot?.orders.single.id, orderTestOrder);
      expect(store.snapshot?.details, isEmpty);
    },
  );

  test('load more deduplica il confine e mantiene ordine stabile', () async {
    final cursor = CustomerOrderCursor(
      beforePlacedAt: orderTestNow.subtract(const Duration(minutes: 2)),
      beforeOrderId: orderTestOrder,
    );
    final repository = FakeCustomerOrderRepository()
      ..listOutcomes.add(orderTestPage(nextCursor: cursor))
      ..listOutcomes.add(
        orderTestPage(
          orders: [
            orderTestCard(),
            orderTestCard(
              id: orderTestOlderOrder,
              code: 'MC-1123456789ABCDEF0123',
              placedAt: orderTestNow.subtract(const Duration(hours: 1)),
            ),
          ],
        ),
      );
    final container = _container(repository: repository);
    addTearDown(container.dispose);
    await _waitFor(
      container,
      (state) => state.status == CustomerOrdersStatus.ready,
    );

    await container.read(customerOrderControllerProvider.notifier).loadMore();
    final state = container.read(customerOrderControllerProvider);
    expect(state.orders.map((order) => order.id), [
      orderTestOrder,
      orderTestOlderOrder,
    ]);
    expect(state.hasMore, isFalse);
    expect(repository.listRequests, hasLength(2));
    expect(repository.listRequests.last.cursor?.beforeOrderId, orderTestOrder);
  });

  test('timeout cancel conserva e riusa la stessa chiave al retry', () async {
    final repository = FakeCustomerOrderRepository()
      ..cancelOutcomes.addAll([
        customerOrderTimeout,
        orderTestCancelledDetail(idempotent: true),
      ]);
    final store = MemoryCustomerOrderCacheStore();
    final container = _container(repository: repository, store: store);
    addTearDown(container.dispose);
    await _readyAndOpen(container);

    final controller = container.read(customerOrderControllerProvider.notifier);
    await controller.cancelSelectedOrder();
    var state = container.read(customerOrderControllerProvider);
    expect(state.failure, CustomerOrderFailureKind.timeout);
    expect(state.notice, CustomerOrdersNotice.cancellationFailed);
    expect(store.snapshot?.pendingCancellation?.idempotencyKey, orderTestKey);

    controller.clearNotice();
    await controller.cancelSelectedOrder();
    state = container.read(customerOrderControllerProvider);
    expect(state.selectedOrder?.status, CustomerOrderStatus.cancelled);
    expect(state.notice, CustomerOrdersNotice.cancelled);
    expect(store.snapshot?.pendingCancellation, isNull);
    expect(repository.cancelRequests, hasLength(2));
    expect(
      repository.cancelRequests
          .map((request) => request.idempotencyKey)
          .toSet(),
      {orderTestKey},
    );
    expect(
      repository.cancelRequests.map((request) => request.expectedStatusVersion),
      everyElement(1),
    );
  });

  test('doppio tap serializzato crea una sola cancellazione', () async {
    final barrier = Completer<CustomerOrderDetail>();
    final repository = FakeCustomerOrderRepository()
      ..cancelOutcomes.add(barrier.future);
    final container = _container(repository: repository);
    addTearDown(container.dispose);
    await _readyAndOpen(container);

    final controller = container.read(customerOrderControllerProvider.notifier);
    final first = controller.cancelSelectedOrder();
    final second = controller.cancelSelectedOrder();
    await Future<void>.delayed(Duration.zero);
    expect(repository.cancelRequests, hasLength(1));
    expect(
      container.read(customerOrderControllerProvider).isCancelling,
      isTrue,
    );

    barrier.complete(orderTestCancelledDetail());
    await Future.wait([first, second]);
    expect(repository.cancelRequests, hasLength(1));
    expect(
      container.read(customerOrderControllerProvider).selectedOrder?.status,
      CustomerOrderStatus.cancelled,
    );
  });

  test(
    'conflitto deterministico riconcilia dettaglio e disabilita CTA stale',
    () async {
      final repository = FakeCustomerOrderRepository()
        ..detailOutcomes.addAll([orderTestDetail(), orderTestCancelledDetail()])
        ..cancelOutcomes.add(
          const CustomerOrderRepositoryException(
            CustomerOrderFailureKind.versionConflict,
          ),
        );
      final store = MemoryCustomerOrderCacheStore();
      final container = _container(repository: repository, store: store);
      addTearDown(container.dispose);
      await _readyAndOpen(container);

      await container
          .read(customerOrderControllerProvider.notifier)
          .cancelSelectedOrder();
      final state = container.read(customerOrderControllerProvider);
      expect(state.failure, CustomerOrderFailureKind.versionConflict);
      expect(state.selectedOrder?.status, CustomerOrderStatus.cancelled);
      expect(state.selectedOrder?.cancellation.allowed, isFalse);
      expect(store.snapshot?.pendingCancellation, isNull);
      expect(repository.detailRequests, hasLength(2));
    },
  );

  test('errore persistenza prima del mutating RPC fallisce chiuso', () async {
    final repository = FakeCustomerOrderRepository();
    final store = MemoryCustomerOrderCacheStore()
      ..saveError = StateError('disk');
    final container = _container(repository: repository, store: store);
    addTearDown(container.dispose);
    await _readyAndOpen(container);

    await container
        .read(customerOrderControllerProvider.notifier)
        .cancelSelectedOrder();
    final state = container.read(customerOrderControllerProvider);
    expect(state.failure, CustomerOrderFailureKind.unexpected);
    expect(state.notice, CustomerOrdersNotice.cancellationFailed);
    expect(repository.cancelRequests, isEmpty);
  });
}

ProviderContainer _container({
  required FakeCustomerOrderRepository repository,
  MemoryCustomerOrderCacheStore? store,
}) => ProviderContainer(
  overrides: [
    customerOrderIdentityProvider.overrideWithValue(_identity()),
    customerOrderShopSlugProvider.overrideWithValue(orderTestShop),
    customerOrderRepositoryProvider.overrideWithValue(repository),
    customerOrderCacheStoreProvider.overrideWithValue(
      store ?? MemoryCustomerOrderCacheStore(),
    ),
    customerOrderClockProvider.overrideWithValue(() => orderTestNow),
    customerOrderIdempotencyKeyFactoryProvider.overrideWithValue(
      () => orderTestKey,
    ),
  ],
);

Future<void> _readyAndOpen(ProviderContainer container) async {
  await _waitFor(
    container,
    (state) => state.status == CustomerOrdersStatus.ready,
  );
  await container
      .read(customerOrderControllerProvider.notifier)
      .openOrder(orderTestOrder);
}

Future<CustomerOrdersState> _waitFor(
  ProviderContainer container,
  bool Function(CustomerOrdersState state) predicate,
) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    final state = container.read(customerOrderControllerProvider);
    if (predicate(state)) return state;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  throw TestFailure(
    'Customer order state non raggiunto: '
    '${container.read(customerOrderControllerProvider).status}',
  );
}

AuthenticatedCustomer _identity() =>
    AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: orderTestOwner,
      email: 'customer@example.invalid',
      metadata: const {'name': 'Cliente Uno'},
    );
