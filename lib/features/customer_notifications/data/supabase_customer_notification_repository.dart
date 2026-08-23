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
  Future<CustomerNotificationPage> list({
    required String shopSlug,
    CustomerNotificationCategory? category,
    CustomerNotificationCursor? before,
    int pageSize = 25,
  }) {
    return _guard(() async {
      if (!_shopSlug.hasMatch(shopSlug) ||
          pageSize < 1 ||
          pageSize > 50 ||
          (before != null && !_uuid.hasMatch(before.id))) {
        throw const CustomerNotificationRepositoryException(
          CustomerNotificationFailureKind.invalid,
        );
      }
      final raw = await port.invoke('customer_notifications_list_v1', {
        'p_shop_slug': shopSlug,
        'p_category': category == CustomerNotificationCategory.system
            ? null
            : category?.name,
        'p_before_created_at': before?.createdAt.toUtc().toIso8601String(),
        'p_before_id': before?.id,
        'p_page_size': pageSize,
      });
      return _parsePage(raw, shopSlug: shopSlug, pageSize: pageSize);
    });
  }

  @override
  Future<DateTime> markRead(String notificationId) {
    return _guard(() async {
      if (!_uuid.hasMatch(notificationId)) {
        throw const CustomerNotificationRepositoryException(
          CustomerNotificationFailureKind.invalid,
        );
      }
      final payload = _map(
        await port.invoke('customer_notification_mark_read_v1', {
          'p_notification_id': notificationId,
        }),
      );
      _requireInboxEnvelope(payload);
      if (payload['status'] == 'not_found') {
        throw const CustomerNotificationRepositoryException(
          CustomerNotificationFailureKind.notFound,
        );
      }
      if (payload['status'] != 'ok') {
        throw const CustomerNotificationRepositoryException(
          CustomerNotificationFailureKind.unavailable,
        );
      }
      return _date(payload, 'readAt');
    });
  }

  @override
  Future<int> markAllRead(String shopSlug) {
    return _guard(() async {
      if (!_shopSlug.hasMatch(shopSlug)) {
        throw const CustomerNotificationRepositoryException(
          CustomerNotificationFailureKind.invalid,
        );
      }
      final payload = _map(
        await port.invoke('customer_notifications_mark_all_read_v1', {
          'p_shop_slug': shopSlug,
        }),
      );
      _requireInboxEnvelope(payload);
      final count = payload['updatedCount'];
      if (payload['status'] != 'ok' || count is! int || count < 0) {
        throw const CustomerNotificationRepositoryException(
          CustomerNotificationFailureKind.unavailable,
        );
      }
      return count;
    });
  }

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

  CustomerNotificationPage _parsePage(
    Object? raw, {
    required String shopSlug,
    required int pageSize,
  }) {
    final payload = _map(raw);
    _requireInboxEnvelope(payload);
    if (payload['status'] != 'ok') {
      throw CustomerNotificationRepositoryException(
        payload['status'] == 'invalid'
            ? CustomerNotificationFailureKind.invalid
            : CustomerNotificationFailureKind.unavailable,
      );
    }
    const allowed = {
      'apiVersion',
      'status',
      'items',
      'unreadCount',
      'serverTime',
    };
    if (payload.keys.any((key) => !allowed.contains(key)) ||
        payload['items'] is! List) {
      throw const FormatException('notification_inbox_shape');
    }
    final rawItems = payload['items'] as List;
    if (rawItems.length > pageSize) {
      throw const FormatException('notification_inbox_page_size');
    }
    final items = rawItems
        .map((item) => _parseNotification(item, expectedShopSlug: shopSlug))
        .toList(growable: false);
    if (items.map((item) => item.id).toSet().length != items.length) {
      throw const FormatException('notification_inbox_duplicate');
    }
    final unread = payload['unreadCount'];
    if (unread is! int || unread < 0) {
      throw const FormatException('notification_inbox_unread');
    }
    final next = items.length == pageSize && items.isNotEmpty
        ? CustomerNotificationCursor(
            createdAt: items.last.createdAt,
            id: items.last.id,
          )
        : null;
    return CustomerNotificationPage(
      items: items,
      unreadCount: unread,
      serverTime: _date(payload, 'serverTime'),
      nextCursor: next,
    );
  }

  CustomerNotification _parseNotification(
    Object? raw, {
    required String expectedShopSlug,
  }) {
    final map = _map(raw);
    const allowed = {
      'id',
      'shopSlug',
      'category',
      'event',
      'eventVersion',
      'titleKey',
      'bodyKey',
      'safeArguments',
      'destinationType',
      'destinationId',
      'createdAt',
      'readAt',
      'expiresAt',
    };
    if (map.keys.any((key) => !allowed.contains(key))) {
      throw const FormatException('notification_inbox_item_keys');
    }
    final id = _requiredString(map, 'id');
    final itemShop = _requiredString(map, 'shopSlug');
    if (!_uuid.hasMatch(id) || itemShop != expectedShopSlug) {
      throw const FormatException('notification_inbox_identity');
    }
    final category = switch (map['category']) {
      'order' => CustomerNotificationCategory.order,
      'payment' => CustomerNotificationCategory.payment,
      'afterSales' => CustomerNotificationCategory.afterSales,
      'system' => CustomerNotificationCategory.system,
      _ => throw const FormatException('notification_inbox_category'),
    };
    final destination = switch (map['destinationType']) {
      'order' => CustomerNotificationDestinationType.order,
      'after_sales' => CustomerNotificationDestinationType.afterSales,
      'product' => CustomerNotificationDestinationType.product,
      'notifications' => CustomerNotificationDestinationType.notifications,
      _ => throw const FormatException('notification_inbox_destination'),
    };
    final destinationId = map['destinationId'];
    if ((destination == CustomerNotificationDestinationType.notifications &&
            destinationId != null) ||
        (destination != CustomerNotificationDestinationType.notifications &&
            (destinationId is! String || !_uuid.hasMatch(destinationId)))) {
      throw const FormatException('notification_inbox_destination_id');
    }
    final event = _boundedKey(map, 'event');
    final titleKey = _boundedKey(map, 'titleKey');
    final bodyKey = _boundedKey(map, 'bodyKey');
    final version = map['eventVersion'];
    if (version is! int || version < 1) {
      throw const FormatException('notification_inbox_event_version');
    }
    final argumentsRaw = map['safeArguments'];
    if (argumentsRaw is! Map) {
      throw const FormatException('notification_inbox_arguments');
    }
    final arguments = <String, String>{};
    for (final entry in argumentsRaw.entries) {
      if (entry.key is! String ||
          !const {'orderCode', 'caseCode'}.contains(entry.key) ||
          entry.value is! String ||
          (entry.value as String).runes.length > 40 ||
          (entry.value as String).runes.any((rune) => rune < 0x20)) {
        throw const FormatException('notification_inbox_safe_arguments');
      }
      arguments[entry.key as String] = entry.value as String;
    }
    return CustomerNotification(
      id: id,
      shopSlug: itemShop,
      category: category,
      event: event,
      eventVersion: version,
      titleKey: titleKey,
      bodyKey: bodyKey,
      safeArguments: arguments,
      destinationType: destination,
      destinationId: destinationId as String?,
      createdAt: _date(map, 'createdAt'),
      readAt: _optionalDate(map, 'readAt'),
      expiresAt: _optionalDate(map, 'expiresAt'),
    );
  }

  static Map<String, Object?> _map(Object? raw) {
    if (raw is! Map) throw const FormatException('notification_inbox_map');
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  static void _requireInboxEnvelope(Map<String, Object?> payload) {
    if (payload['apiVersion'] != 'customer-notifications.v1') {
      throw const FormatException('notification_inbox_version');
    }
  }

  static String _requiredString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! String || value.isEmpty || value != value.trim()) {
      throw const FormatException('notification_inbox_string');
    }
    return value;
  }

  static String _boundedKey(Map<String, Object?> map, String key) {
    final value = _requiredString(map, key);
    if (!RegExp(r'^[a-z][a-zA-Z0-9_.]{1,119}$').hasMatch(value)) {
      throw const FormatException('notification_inbox_key');
    }
    return value;
  }

  static DateTime _date(Map<String, Object?> map, String key) {
    final value = _requiredString(map, key);
    final parsed = DateTime.tryParse(value)?.toUtc();
    if (parsed == null) throw const FormatException('notification_inbox_date');
    return parsed;
  }

  static DateTime? _optionalDate(Map<String, Object?> map, String key) =>
      map[key] == null ? null : _date(map, key);
}
