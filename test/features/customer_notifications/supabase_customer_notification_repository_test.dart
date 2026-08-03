import 'dart:async';

import 'package:client_merchandise_control/features/customer_notifications/data/supabase_customer_notification_repository.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_failure.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _shop = 'storefront-test';
const _routeToken = 'f1000000-0000-4000-8000-000000031001';
const _orderId = '88000000-0000-4000-8000-000000028101';

void main() {
  test('risolve ordine owner-scoped con RPC e contract esatto', () async {
    final port = _Port(
      response: const {
        'apiVersion': 'customer-notification-route.v1',
        'status': 'ok',
        'target': 'order',
        'orderId': _orderId,
        'event': 'ready',
        'eventVersion': 4,
      },
    );
    final repository = SupabaseCustomerNotificationRepository(port: port);

    final destination = await repository.resolveRoute(
      shopSlug: _shop,
      routeToken: _routeToken,
    );

    expect(
      destination,
      isA<CustomerNotificationOrderDestination>()
          .having((value) => value.orderId, 'orderId', _orderId)
          .having(
            (value) => value.event,
            'event',
            CustomerNotificationEvent.ready,
          )
          .having((value) => value.eventVersion, 'eventVersion', 4),
    );
    expect(port.function, 'customer_notification_route_v1');
    expect(port.parameters, {
      'p_shop_slug': _shop,
      'p_route_token': _routeToken,
    });
  });

  test('reservation expiring risolve il carrello senza internal ID', () async {
    final repository = SupabaseCustomerNotificationRepository(
      port: _Port(
        response: const {
          'apiVersion': 'customer-notification-route.v1',
          'status': 'ok',
          'target': 'cart',
          'event': 'reservation_expiring',
          'eventVersion': 1,
        },
      ),
    );

    final destination = await repository.resolveRoute(
      shopSlug: _shop,
      routeToken: _routeToken,
    );

    expect(destination, isA<CustomerNotificationCartDestination>());
    expect(destination.event, CustomerNotificationEvent.reservationExpiring);
  });

  test('not found e input invalido falliscono tipizzati e minimali', () async {
    final port = _Port(
      response: const {
        'apiVersion': 'customer-notification-route.v1',
        'status': 'not_found',
      },
    );
    final repository = SupabaseCustomerNotificationRepository(port: port);

    await expectLater(
      repository.resolveRoute(shopSlug: _shop, routeToken: _routeToken),
      throwsA(
        isA<CustomerNotificationRepositoryException>().having(
          (error) => error.kind,
          'kind',
          CustomerNotificationFailureKind.notFound,
        ),
      ),
    );
    await expectLater(
      repository.resolveRoute(shopSlug: '../inventory', routeToken: _orderId),
      throwsA(
        isA<CustomerNotificationRepositoryException>().having(
          (error) => error.kind,
          'kind',
          CustomerNotificationFailureKind.invalid,
        ),
      ),
    );
    expect(port.calls, 1);
  });

  test('payload inatteso, ID nel cart e timeout falliscono chiusi', () async {
    for (final response in const [
      {
        'apiVersion': 'customer-notification-route.v1',
        'status': 'ok',
        'target': 'cart',
        'orderId': _orderId,
        'event': 'reservation_expiring',
        'eventVersion': 1,
      },
      {
        'apiVersion': 'customer-notification-route.v1',
        'status': 'ok',
        'target': 'order',
        'orderId': _orderId,
        'event': 'ready',
        'eventVersion': 4,
        'ownerUserId': '00000000-0000-4000-8000-000000031001',
      },
    ]) {
      final repository = SupabaseCustomerNotificationRepository(
        port: _Port(response: response),
      );
      await expectLater(
        repository.resolveRoute(shopSlug: _shop, routeToken: _routeToken),
        throwsA(
          isA<CustomerNotificationRepositoryException>().having(
            (error) => error.kind,
            'kind',
            CustomerNotificationFailureKind.unexpected,
          ),
        ),
      );
    }

    final timeout = SupabaseCustomerNotificationRepository(
      port: _Port(operation: Completer<Object?>().future),
      requestTimeout: const Duration(milliseconds: 5),
    );
    await expectLater(
      timeout.resolveRoute(shopSlug: _shop, routeToken: _routeToken),
      throwsA(
        isA<CustomerNotificationRepositoryException>().having(
          (error) => error.kind,
          'kind',
          CustomerNotificationFailureKind.timeout,
        ),
      ),
    );
  });
}

final class _Port implements CustomerNotificationPort {
  _Port({this.response, this.operation});

  final Object? response;
  final Future<Object?>? operation;
  String? function;
  Map<String, Object?>? parameters;
  var calls = 0;

  @override
  Future<Object?> invoke(
    String function,
    Map<String, Object?> parameters,
  ) async {
    calls++;
    this.function = function;
    this.parameters = parameters;
    return operation == null ? response : await operation;
  }
}
