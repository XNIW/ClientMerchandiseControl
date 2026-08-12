import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/customer_notification_failure.dart';
import '../domain/customer_notification_models.dart';
import '../domain/customer_notification_repository.dart';

abstract interface class CustomerNotificationPort {
  Future<Object?> invoke(String function, Map<String, Object?> parameters);
}

final class PlatformCustomerNotificationPort
    implements CustomerNotificationPort {
  PlatformCustomerNotificationPort(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> invoke(String function, Map<String, Object?> parameters) {
    return _client.rpc(function, params: parameters);
  }
}

final class SupabaseCustomerNotificationRepository
    implements CustomerNotificationRepository {
  const SupabaseCustomerNotificationRepository({
    required this.port,
    this.requestTimeout = const Duration(seconds: 8),
  });

  static final _shopSlug = RegExp(r'^[a-z0-9][a-z0-9-]{2,62}$');
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  final CustomerNotificationPort port;
  final Duration requestTimeout;

  @override
  Future<CustomerNotificationDestination> resolveRoute({
    required String shopSlug,
    required String routeToken,
  }) {
    return _guard(() async {
      if (!_shopSlug.hasMatch(shopSlug) || !_uuid.hasMatch(routeToken)) {
        throw const CustomerNotificationRepositoryException(
          CustomerNotificationFailureKind.invalid,
        );
      }
      return _parse(
        await port.invoke('customer_notification_route_v1', {
          'p_shop_slug': shopSlug,
          'p_route_token': routeToken,
        }),
      );
    });
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation().timeout(requestTimeout);
    } on CustomerNotificationRepositoryException {
      rethrow;
    } on TimeoutException {
      throw const CustomerNotificationRepositoryException(
        CustomerNotificationFailureKind.timeout,
      );
    } on SocketException {
      throw const CustomerNotificationRepositoryException(
        CustomerNotificationFailureKind.offline,
      );
    } on AuthException {
      throw const CustomerNotificationRepositoryException(
        CustomerNotificationFailureKind.unauthorized,
      );
    } on PostgrestException catch (error) {
      throw CustomerNotificationRepositoryException(switch (error.code) {
        '28000' ||
        '42501' ||
        'PGRST301' => CustomerNotificationFailureKind.unauthorized,
        '57014' => CustomerNotificationFailureKind.timeout,
        _ => CustomerNotificationFailureKind.unexpected,
      });
    } on FormatException {
      throw const CustomerNotificationRepositoryException(
        CustomerNotificationFailureKind.unexpected,
      );
    } on Object {
      throw const CustomerNotificationRepositoryException(
        CustomerNotificationFailureKind.unexpected,
      );
    }
  }

  CustomerNotificationDestination _parse(Object? raw) {
    if (raw is! Map) throw const FormatException('notification_route_map');
    final payload = raw.map((key, value) => MapEntry(key.toString(), value));
    const allowed = {
      'apiVersion',
      'status',
      'target',
      'orderId',
      'event',
      'eventVersion',
    };
    if (payload.keys.any((key) => !allowed.contains(key)) ||
        payload['apiVersion'] != 'customer-notification-route.v1') {
      throw const FormatException('notification_route_contract');
    }
    final status = payload['status'];
    if (status != 'ok') {
      if (payload.keys.any((key) => !{'apiVersion', 'status'}.contains(key))) {
        throw const FormatException('notification_route_failure_shape');
      }
      throw CustomerNotificationRepositoryException(switch (status) {
        'invalid' => CustomerNotificationFailureKind.invalid,
        'not_found' => CustomerNotificationFailureKind.notFound,
        'unavailable' => CustomerNotificationFailureKind.unavailable,
        _ => CustomerNotificationFailureKind.unexpected,
      });
    }
    if (!payload.keys.toSet().containsAll({
      'apiVersion',
      'status',
      'target',
      'event',
      'eventVersion',
    })) {
      throw const FormatException('notification_route_required');
    }
    final event = _event(payload['event']);
    final version = payload['eventVersion'];
    if (version is! int || version < 1) {
      throw const FormatException('notification_route_version');
    }
    return switch (payload['target']) {
      'order' => _order(payload, event, version),
      'cart' => _cart(payload, event, version),
      _ => throw const FormatException('notification_route_target'),
    };
  }

  CustomerNotificationDestination _order(
    Map<String, Object?> payload,
    CustomerNotificationEvent event,
    int version,
  ) {
    final orderId = payload['orderId'];
    if (orderId is! String || !_uuid.hasMatch(orderId)) {
      throw const FormatException('notification_route_order');
    }
    return CustomerNotificationOrderDestination(
      orderId: orderId,
      event: event,
      eventVersion: version,
    );
  }

  CustomerNotificationDestination _cart(
    Map<String, Object?> payload,
    CustomerNotificationEvent event,
    int version,
  ) {
    if (payload.containsKey('orderId') ||
        event != CustomerNotificationEvent.reservationExpiring) {
      throw const FormatException('notification_route_cart');
    }
    return CustomerNotificationCartDestination(
      event: event,
      eventVersion: version,
    );
  }

  CustomerNotificationEvent _event(Object? value) => switch (value) {
    'confirmed' => CustomerNotificationEvent.confirmed,
    'rejected' => CustomerNotificationEvent.rejected,
    'preparing' => CustomerNotificationEvent.preparing,
    'ready' => CustomerNotificationEvent.ready,
    'out_for_delivery' => CustomerNotificationEvent.outForDelivery,
    'completed' => CustomerNotificationEvent.completed,
    'cancelled' => CustomerNotificationEvent.cancelled,
    'reservation_expiring' => CustomerNotificationEvent.reservationExpiring,
    _ => throw const FormatException('notification_route_event'),
  };
}
