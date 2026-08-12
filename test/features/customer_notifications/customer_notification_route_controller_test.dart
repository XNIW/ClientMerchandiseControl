import 'dart:async';

import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/customer_notifications/application/customer_notification_providers.dart';
import 'package:client_merchandise_control/features/customer_notifications/application/customer_notification_route_controller.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_failure.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_models.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _shop = 'storefront-test';
const _routeA = 'f1000000-0000-4000-8000-000000031001';
const _routeB = 'f1000000-0000-4000-8000-000000031002';
const _orderA = '88000000-0000-4000-8000-000000028101';
const _orderB = '88000000-0000-4000-8000-000000028102';

void main() {
  test('coalesca duplicate e conserva una cache bounded', () async {
    final repository = _Repository();
    final completer = Completer<CustomerNotificationDestination>();
    repository.outcomes[_routeA] = completer.future;
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(
      customerNotificationRouteControllerProvider.notifier,
    );

    final first = controller.resolve(shopSlug: _shop, routeToken: _routeA);
    final duplicate = controller.resolve(shopSlug: _shop, routeToken: _routeA);
    expect(identical(first, duplicate), isTrue);
    completer.complete(_order(_orderA, CustomerNotificationEvent.ready, 3));
    expect(await first, isA<CustomerNotificationOrderDestination>());
    expect(repository.calls, [_routeA]);

    final cached = await controller.resolve(
      shopSlug: _shop,
      routeToken: _routeA,
    );
    expect((cached as CustomerNotificationOrderDestination).orderId, _orderA);
    expect(repository.calls, [_routeA]);

    for (var value = 2; value <= 33; value++) {
      final token =
          'f1000000-0000-4000-8000-${value.toString().padLeft(12, '0')}';
      await controller.resolve(shopSlug: _shop, routeToken: token);
    }
    expect(repository.calls, hasLength(33));
    await controller.resolve(shopSlug: _shop, routeToken: _routeA);
    expect(repository.calls.where((token) => token == _routeA), hasLength(2));
  });

  test(
    'risposte fuori ordine non fanno regredire lo stato osservabile',
    () async {
      final repository = _Repository();
      final firstCompleter = Completer<CustomerNotificationDestination>();
      final secondCompleter = Completer<CustomerNotificationDestination>();
      repository.outcomes[_routeA] = firstCompleter.future;
      repository.outcomes[_routeB] = secondCompleter.future;
      final container = _container(repository);
      addTearDown(container.dispose);
      final controller = container.read(
        customerNotificationRouteControllerProvider.notifier,
      );

      final first = controller.resolve(shopSlug: _shop, routeToken: _routeA);
      final second = controller.resolve(shopSlug: _shop, routeToken: _routeB);
      secondCompleter.complete(
        _order(_orderB, CustomerNotificationEvent.completed, 6),
      );
      await second;
      firstCompleter.complete(
        _order(_orderA, CustomerNotificationEvent.preparing, 2),
      );
      await first;

      final state = container.read(customerNotificationRouteControllerProvider);
      expect(state.status, CustomerNotificationRouteStatus.idle);
      expect(
        (state.lastDestination as CustomerNotificationOrderDestination).orderId,
        _orderB,
      );
    },
  );

  test(
    'cambio owner invalida request e cache del soggetto precedente',
    () async {
      final repository = _Repository();
      final pending = Completer<CustomerNotificationDestination>();
      repository.outcomes[_routeA] = pending.future;
      final identity = StateProvider<AuthenticatedCustomer?>(
        (ref) => _customer('00000000-0000-4000-8000-000000031001'),
      );
      final container = ProviderContainer(
        overrides: [
          customerNotificationIdentityProvider.overrideWith(
            (ref) => ref.watch(identity),
          ),
          customerNotificationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        customerNotificationRouteControllerProvider.notifier,
      );

      final previousOwner = controller.resolve(
        shopSlug: _shop,
        routeToken: _routeA,
      );
      container.read(identity.notifier).state = _customer(
        '00000000-0000-4000-8000-000000031002',
      );
      expect(
        container.read(customerNotificationRouteControllerProvider).status,
        CustomerNotificationRouteStatus.idle,
      );
      pending.complete(_order(_orderA, CustomerNotificationEvent.ready, 3));
      expect(await previousOwner, isNull);

      repository.outcomes[_routeA] = Future.value(
        _order(_orderB, CustomerNotificationEvent.completed, 4),
      );
      final currentOwner = await container
          .read(customerNotificationRouteControllerProvider.notifier)
          .resolve(shopSlug: _shop, routeToken: _routeA);
      expect(
        (currentOwner as CustomerNotificationOrderDestination).orderId,
        _orderB,
      );
      expect(repository.calls.where((token) => token == _routeA), hasLength(2));
    },
  );

  test('offline non naviga e resta failure riprovabile senza crash', () async {
    final repository = _Repository()
      ..outcomes[_routeA] = Future.error(
        const CustomerNotificationRepositoryException(
          CustomerNotificationFailureKind.offline,
        ),
      );
    final container = _container(repository);
    addTearDown(container.dispose);

    final destination = await container
        .read(customerNotificationRouteControllerProvider.notifier)
        .resolve(shopSlug: _shop, routeToken: _routeA);
    final state = container.read(customerNotificationRouteControllerProvider);

    expect(destination, isNull);
    expect(state.status, CustomerNotificationRouteStatus.failure);
    expect(state.failure, CustomerNotificationFailureKind.offline);
  });
}

ProviderContainer _container(_Repository repository) => ProviderContainer(
  overrides: [
    customerNotificationIdentityProvider.overrideWithValue(
      _customer('00000000-0000-4000-8000-000000031001'),
    ),
    customerNotificationRepositoryProvider.overrideWithValue(repository),
  ],
);

AuthenticatedCustomer _customer(String subjectId) =>
    AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: subjectId,
      email: 'owner@example.invalid',
      metadata: const {'name': 'Notification Owner'},
    );

CustomerNotificationOrderDestination _order(
  String orderId,
  CustomerNotificationEvent event,
  int version,
) => CustomerNotificationOrderDestination(
  orderId: orderId,
  event: event,
  eventVersion: version,
);

final class _Repository implements CustomerNotificationRepository {
  final Map<String, Future<CustomerNotificationDestination>> outcomes = {};
  final List<String> calls = [];

  @override
  Future<CustomerNotificationDestination> resolveRoute({
    required String shopSlug,
    required String routeToken,
  }) {
    calls.add(routeToken);
    return outcomes[routeToken] ??
        Future.value(_order(_orderA, CustomerNotificationEvent.confirmed, 1));
  }
}
