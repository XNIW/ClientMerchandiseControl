import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/customer_order_failure.dart';
import '../domain/customer_order_models.dart';
import '../domain/customer_order_repository.dart';

abstract interface class CustomerOrderPort {
  Future<Object?> invoke(String function, Map<String, Object?> parameters);
}

final class PlatformCustomerOrderPort implements CustomerOrderPort {
  PlatformCustomerOrderPort(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> invoke(String function, Map<String, Object?> parameters) {
    return _client.rpc(function, params: parameters);
  }
}

final class SupabaseCustomerOrderRepository implements CustomerOrderRepository {
  const SupabaseCustomerOrderRepository({
    required this.port,
    this.requestTimeout = const Duration(seconds: 12),
  });

  final CustomerOrderPort port;
  final Duration requestTimeout;

  @override
  Future<CustomerOrderPage> listOrders({
    required String shopSlug,
    CustomerOrderCursor? cursor,
    int limit = 20,
  }) {
    return _guard(() async {
      _requireInputShopSlug(shopSlug);
      if (limit < 1 || limit > customerOrderMaximumPageSize) {
        throw const CustomerOrderRepositoryException(
          CustomerOrderFailureKind.invalid,
        );
      }
      if (cursor != null) {
        _requireInputUuid(cursor.beforeOrderId);
        _requireInputDate(cursor.beforePlacedAt);
      }
      return _parseList(
        await port.invoke('customer_order_list_v1', {
          'p_shop_slug': shopSlug,
          'p_limit': limit,
          'p_before_placed_at': cursor?.beforePlacedAt
              .toUtc()
              .toIso8601String(),
          'p_before_order_id': cursor?.beforeOrderId,
        }),
        expectedShopSlug: shopSlug,
        maximum: limit,
      );
    });
  }

  @override
  Future<CustomerOrderDetail> loadOrder({
    required String shopSlug,
    required String orderId,
  }) {
    return _guard(() async {
      _requireInputShopSlug(shopSlug);
      _requireInputUuid(orderId);
      return _parseDetail(
        await port.invoke('customer_order_detail_v1', {
          'p_shop_slug': shopSlug,
          'p_order_id': orderId,
        }),
        expectedOrderId: orderId,
        expectedShopSlug: shopSlug,
      );
    });
  }

  @override
  Future<CustomerOrderDetail> cancelOrder({
    required String shopSlug,
    required String orderId,
    required int expectedStatusVersion,
    required String idempotencyKey,
  }) {
    return _guard(() async {
      _requireInputShopSlug(shopSlug);
      _requireInputUuid(orderId);
      _requireInputUuid(idempotencyKey);
      if (expectedStatusVersion < 1) {
        throw const CustomerOrderRepositoryException(
          CustomerOrderFailureKind.invalid,
        );
      }
      return _parseDetail(
        await port.invoke('customer_order_cancel_v1', {
          'p_shop_slug': shopSlug,
          'p_order_id': orderId,
          'p_expected_status_version': expectedStatusVersion,
          'p_idempotency_key': idempotencyKey,
        }),
        expectedOrderId: orderId,
        expectedShopSlug: shopSlug,
      );
    });
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation().timeout(requestTimeout);
    } on CustomerOrderRepositoryException {
      rethrow;
    } on TimeoutException {
      throw const CustomerOrderRepositoryException(
        CustomerOrderFailureKind.timeout,
      );
    } on SocketException {
      throw const CustomerOrderRepositoryException(
        CustomerOrderFailureKind.offline,
      );
    } on AuthException {
      throw const CustomerOrderRepositoryException(
        CustomerOrderFailureKind.unauthorized,
      );
    } on PostgrestException catch (error) {
      throw CustomerOrderRepositoryException(_postgrestFailure(error.code));
    } on FormatException {
      throw const CustomerOrderRepositoryException(
        CustomerOrderFailureKind.unexpected,
      );
    } on Object {
      throw const CustomerOrderRepositoryException(
        CustomerOrderFailureKind.unexpected,
      );
    }
  }
}

const _listRootKeys = <String>{
  'apiVersion',
  'status',
  'shopSlug',
  'orders',
  'hasMore',
  'nextCursor',
  'serverTime',
};

CustomerOrderPage _parseList(
  Object? raw, {
  required String expectedShopSlug,
  required int maximum,
}) {
  final payload = _payload(raw, _listRootKeys, 'customer_order_list');
  if (payload['apiVersion'] != 'customer-order-list.v1') {
    throw const FormatException('customer_order_list_version');
  }
  final status = _requiredString(payload, 'status');
  final serverTime = _requiredDate(payload, 'serverTime');
  if (status != 'ok') {
    const minimalKeys = {
      'apiVersion',
      'status',
      'orders',
      'hasMore',
      'serverTime',
    };
    if (payload.keys.toSet().difference(minimalKeys).isNotEmpty ||
        _list(payload, 'orders', maximum: 0).isNotEmpty ||
        payload['hasMore'] != false) {
      throw const FormatException('customer_order_list_minimal');
    }
    throw CustomerOrderRepositoryException(_remoteFailure(status));
  }
  const required = {
    'apiVersion',
    'status',
    'shopSlug',
    'orders',
    'hasMore',
    'serverTime',
  };
  if (!payload.keys.toSet().containsAll(required) ||
      _requiredString(payload, 'shopSlug') != expectedShopSlug ||
      payload['hasMore'] is! bool) {
    throw const FormatException('customer_order_list_identity');
  }
  final orders = _list(payload, 'orders', maximum: maximum)
      .map((value) => _parseCard(value, serverTime: serverTime))
      .toList(growable: false);
  _requireUnique(orders.map((order) => order.id), 'customer_order_list_ids');
  for (var index = 1; index < orders.length; index++) {
    final previous = orders[index - 1];
    final current = orders[index];
    if (current.placedAt.isAfter(previous.placedAt) ||
        (current.placedAt == previous.placedAt &&
            current.id.compareTo(previous.id) >= 0)) {
      throw const FormatException('customer_order_list_order');
    }
  }
  final hasMore = payload['hasMore'] as bool;
  CustomerOrderCursor? cursor;
  if (hasMore) {
    if (orders.isEmpty || !payload.containsKey('nextCursor')) {
      throw const FormatException('customer_order_list_cursor_missing');
    }
    final map = _strictMap(payload['nextCursor'], const {
      'beforePlacedAt',
      'beforeOrderId',
    }, 'customer_order_cursor');
    cursor = CustomerOrderCursor(
      beforePlacedAt: _requiredDate(map, 'beforePlacedAt'),
      beforeOrderId: _requiredUuid(map, 'beforeOrderId'),
    );
    final tail = orders.last;
    if (cursor.beforePlacedAt != tail.placedAt ||
        cursor.beforeOrderId != tail.id) {
      throw const FormatException('customer_order_list_cursor_identity');
    }
  } else if (payload.containsKey('nextCursor')) {
    throw const FormatException('customer_order_list_cursor_unexpected');
  }
  return CustomerOrderPage(
    shopSlug: expectedShopSlug,
    orders: orders,
    nextCursor: cursor,
    serverTime: serverTime,
  );
}

CustomerOrderCard _parseCard(Object? raw, {required DateTime serverTime}) {
  final map = _strictMap(raw, const {
    'orderId',
    'orderCode',
    'orderStatus',
    'orderVersion',
    'fulfillmentMode',
    'currencyCode',
    'totalClp',
    'itemCount',
    'primaryItemName',
    'cancellationAllowed',
    'placedAt',
    'updatedAt',
  }, 'customer_order_card');
  if (map['currencyCode'] != 'CLP') {
    throw const FormatException('customer_order_card_currency');
  }
  final version = _requiredInt(map, 'orderVersion');
  final itemCount = _requiredInt(map, 'itemCount');
  final placedAt = _requiredDate(map, 'placedAt');
  final updatedAt = _requiredDate(map, 'updatedAt');
  final cancellationAllowed = map['cancellationAllowed'];
  if (version < 1 ||
      itemCount < 1 ||
      itemCount > customerOrderMaximumLines ||
      cancellationAllowed is! bool ||
      updatedAt.isBefore(placedAt) ||
      placedAt.isAfter(serverTime.add(const Duration(minutes: 1)))) {
    throw const FormatException('customer_order_card_invariant');
  }
  return CustomerOrderCard(
    id: _requiredUuid(map, 'orderId'),
    code: _orderCode(map, 'orderCode'),
    status: _orderStatus(_requiredString(map, 'orderStatus')),
    version: version,
    fulfillmentMode: _mode(_requiredString(map, 'fulfillmentMode')),
    totalClp: _amount(map, 'totalClp'),
    itemCount: itemCount,
    primaryItemName: _safeRequiredText(map, 'primaryItemName', 200),
    cancellationAllowed: cancellationAllowed,
    placedAt: placedAt,
    updatedAt: updatedAt,
  );
}

const _detailRootKeys = <String>{
  'apiVersion',
  'status',
  'idempotent',
  'orderId',
  'orderCode',
  'orderStatus',
  'orderVersion',
  'shopSlug',
  'fulfillmentMode',
  'fulfillment',
  'currencyCode',
  'subtotalClp',
  'deliveryFeeClp',
  'totalClp',
  'items',
  'timeline',
  'cancellation',
  'placedAt',
  'updatedAt',
  'serverTime',
};

CustomerOrderDetail _parseDetail(
  Object? raw, {
  required String expectedOrderId,
  required String expectedShopSlug,
}) {
  final payload = _payload(raw, _detailRootKeys, 'customer_order_detail');
  if (payload['apiVersion'] != 'customer-order-detail.v1') {
    throw const FormatException('customer_order_detail_version');
  }
  final status = _requiredString(payload, 'status');
  final idempotent = payload['idempotent'];
  final serverTime = _requiredDate(payload, 'serverTime');
  if (idempotent is! bool) {
    throw const FormatException('customer_order_detail_idempotent');
  }
  if (status != 'ok') {
    const minimalKeys = {
      'apiVersion',
      'status',
      'idempotent',
      'orderId',
      'serverTime',
    };
    if (payload.keys.toSet().difference(minimalKeys).isNotEmpty) {
      throw const FormatException('customer_order_detail_minimal');
    }
    final returnedId = _optionalUuid(payload, 'orderId');
    if (returnedId != null && returnedId != expectedOrderId) {
      throw const FormatException('customer_order_detail_error_identity');
    }
    throw CustomerOrderRepositoryException(_remoteFailure(status));
  }
  const required = {
    'apiVersion',
    'status',
    'idempotent',
    'orderId',
    'orderCode',
    'orderStatus',
    'orderVersion',
    'shopSlug',
    'fulfillmentMode',
    'fulfillment',
    'currencyCode',
    'subtotalClp',
    'deliveryFeeClp',
    'totalClp',
    'items',
    'timeline',
    'cancellation',
    'placedAt',
    'updatedAt',
    'serverTime',
  };
  if (!payload.keys.toSet().containsAll(required) ||
      payload['currencyCode'] != 'CLP' ||
      _requiredUuid(payload, 'orderId') != expectedOrderId ||
      _requiredShopSlug(payload, 'shopSlug') != expectedShopSlug) {
    throw const FormatException('customer_order_detail_identity');
  }
  final orderStatus = _orderStatus(_requiredString(payload, 'orderStatus'));
  final version = _requiredInt(payload, 'orderVersion');
  final mode = _mode(_requiredString(payload, 'fulfillmentMode'));
  final subtotal = _amount(payload, 'subtotalClp');
  final fee = _amount(payload, 'deliveryFeeClp');
  final total = _amount(payload, 'totalClp');
  if (version < 1 ||
      total != subtotal + fee ||
      (mode != CustomerOrderFulfillmentMode.delivery && fee != 0)) {
    throw const FormatException('customer_order_detail_economics');
  }
  final items = _list(
    payload,
    'items',
    maximum: customerOrderMaximumLines,
  ).map(_parseLine).toList(growable: false);
  if (items.isEmpty ||
      items.fold<int>(0, (sum, line) => sum + line.lineTotalClp) != subtotal) {
    throw const FormatException('customer_order_detail_items');
  }
  _requireUnique(
    items.map((line) => line.publicationId),
    'customer_order_detail_publications',
  );
  final placedAt = _requiredDate(payload, 'placedAt');
  final updatedAt = _requiredDate(payload, 'updatedAt');
  if (updatedAt.isBefore(placedAt) ||
      placedAt.isAfter(serverTime.add(const Duration(minutes: 1)))) {
    throw const FormatException('customer_order_detail_timing');
  }
  final timeline = _list(
    payload,
    'timeline',
    maximum: 1000,
  ).map(_parseTimelineEvent).toList(growable: false);
  if (timeline.length != version || timeline.isEmpty) {
    throw const FormatException('customer_order_timeline_version');
  }
  DateTime? previousEventAt;
  for (var index = 0; index < timeline.length; index++) {
    final event = timeline[index];
    if (event.version != index + 1 ||
        event.createdAt.isBefore(placedAt) ||
        event.createdAt.isAfter(serverTime.add(const Duration(minutes: 1))) ||
        (previousEventAt != null &&
            event.createdAt.isBefore(previousEventAt))) {
      throw const FormatException('customer_order_timeline_order');
    }
    previousEventAt = event.createdAt;
  }
  if (timeline.last.status != orderStatus) {
    throw const FormatException('customer_order_timeline_status');
  }
  final cancellation = _parseCancellation(
    payload['cancellation'],
    orderStatus: orderStatus,
    placedAt: placedAt,
    serverTime: serverTime,
  );
  return CustomerOrderDetail(
    id: expectedOrderId,
    code: _orderCode(payload, 'orderCode'),
    status: orderStatus,
    version: version,
    shopSlug: _requiredShopSlug(payload, 'shopSlug'),
    fulfillment: _parseFulfillment(payload['fulfillment'], mode),
    subtotalClp: subtotal,
    deliveryFeeClp: fee,
    totalClp: total,
    items: items,
    timeline: timeline,
    cancellation: cancellation,
    placedAt: placedAt,
    updatedAt: updatedAt,
    serverTime: serverTime,
    idempotent: idempotent,
  );
}

CustomerOrderLine _parseLine(Object? raw) {
  final map = _payload(raw, const {
    'publicationId',
    'publicName',
    'quantity',
    'unitPriceClp',
    'compareAtPriceClp',
    'lineTotalClp',
    'promotionName',
    'promotionEndsAt',
  }, 'customer_order_line');
  const required = {
    'publicationId',
    'publicName',
    'quantity',
    'unitPriceClp',
    'lineTotalClp',
  };
  if (!map.keys.toSet().containsAll(required)) {
    throw const FormatException('customer_order_line_required');
  }
  final quantity = _requiredInt(map, 'quantity');
  final unitPrice = _amount(map, 'unitPriceClp');
  final lineTotal = _amount(map, 'lineTotalClp');
  final compareAt = _optionalAmount(map, 'compareAtPriceClp');
  if (quantity < 1 ||
      quantity > 99 ||
      lineTotal != unitPrice * quantity ||
      (compareAt != null && compareAt < unitPrice)) {
    throw const FormatException('customer_order_line_total');
  }
  return CustomerOrderLine(
    publicationId: _requiredUuid(map, 'publicationId'),
    publicName: _safeRequiredText(map, 'publicName', 200),
    quantity: quantity,
    unitPriceClp: unitPrice,
    compareAtPriceClp: compareAt,
    lineTotalClp: lineTotal,
    promotionName: _safeOptionalText(map, 'promotionName', 160),
    promotionEndsAt: _optionalDate(map, 'promotionEndsAt'),
  );
}

CustomerOrderTimelineEvent _parseTimelineEvent(Object? raw) {
  final map = _strictMap(raw, const {
    'eventVersion',
    'status',
    'actorKind',
    'createdAt',
  }, 'customer_order_event');
  final version = _requiredInt(map, 'eventVersion');
  if (version < 1) throw const FormatException('customer_order_event_version');
  return CustomerOrderTimelineEvent(
    version: version,
    status: _orderStatus(_requiredString(map, 'status')),
    actorKind: _actor(_requiredString(map, 'actorKind')),
    createdAt: _requiredDate(map, 'createdAt'),
  );
}

CustomerOrderCancellation _parseCancellation(
  Object? raw, {
  required CustomerOrderStatus orderStatus,
  required DateTime placedAt,
  required DateTime serverTime,
}) {
  final map = _strictMap(raw, const {
    'enabled',
    'allowed',
    'deadline',
  }, 'customer_order_cancellation');
  final enabled = map['enabled'];
  final allowed = map['allowed'];
  final deadline = _requiredDate(map, 'deadline');
  if (enabled is! bool ||
      allowed is! bool ||
      deadline.isBefore(placedAt) ||
      (allowed &&
          (!enabled ||
              orderStatus != CustomerOrderStatus.confirmed ||
              !deadline.isAfter(serverTime)))) {
    throw const FormatException('customer_order_cancellation_invariant');
  }
  return CustomerOrderCancellation(
    enabled: enabled,
    allowed: allowed,
    deadline: deadline,
  );
}

CustomerOrderFulfillment _parseFulfillment(
  Object? raw,
  CustomerOrderFulfillmentMode expectedMode,
) {
  final map = _payload(raw, const {
    'mode',
    'address',
    'pickupPoint',
    'deliveryZone',
    'slot',
  }, 'customer_order_fulfillment');
  if (_mode(_requiredString(map, 'mode')) != expectedMode ||
      !map.containsKey('slot')) {
    throw const FormatException('customer_order_fulfillment_mode');
  }
  final slot = _strictMap(map['slot'], const {
    'id',
    'label',
    'startsAt',
    'endsAt',
  }, 'customer_order_slot');
  _requiredUuid(slot, 'id');
  final slotStartsAt = _requiredDate(slot, 'startsAt');
  final slotEndsAt = _requiredDate(slot, 'endsAt');
  if (!slotEndsAt.isAfter(slotStartsAt)) {
    throw const FormatException('customer_order_slot_timing');
  }
  String destinationTitle;
  List<String> destinationLines;
  if (expectedMode == CustomerOrderFulfillmentMode.delivery) {
    if (!map.containsKey('address') ||
        !map.containsKey('deliveryZone') ||
        map.containsKey('pickupPoint')) {
      throw const FormatException('customer_order_delivery_shape');
    }
    final address = _payload(map['address'], const {
      'addressId',
      'recipientName',
      'addressLine1',
      'addressLine2',
      'commune',
      'region',
      'postalCode',
      'countryCode',
      'deliveryInstructions',
    }, 'customer_order_address');
    const requiredAddress = {
      'addressId',
      'recipientName',
      'addressLine1',
      'commune',
      'region',
      'countryCode',
    };
    if (!address.keys.toSet().containsAll(requiredAddress)) {
      throw const FormatException('customer_order_address_required');
    }
    _requiredUuid(address, 'addressId');
    destinationTitle = _safeRequiredText(address, 'recipientName', 160);
    destinationLines = [
      _safeRequiredText(address, 'addressLine1', 200),
      ?_safeOptionalText(address, 'addressLine2', 200),
      '${_safeRequiredText(address, 'commune', 100)}, '
          '${_safeRequiredText(address, 'region', 100)}',
    ];
    final zone = _payload(map['deliveryZone'], const {
      'id',
      'name',
      'region',
      'feeClp',
    }, 'customer_order_zone');
    _requiredUuid(zone, 'id');
    _safeRequiredText(zone, 'name', 120);
    _safeRequiredText(zone, 'region', 100);
    _amount(zone, 'feeClp');
  } else {
    if (!map.containsKey('pickupPoint') ||
        map.containsKey('address') ||
        map.containsKey('deliveryZone')) {
      throw const FormatException('customer_order_pickup_shape');
    }
    final point = _payload(map['pickupPoint'], const {
      'id',
      'name',
      'addressLine1',
      'addressLine2',
      'commune',
      'region',
      'instructions',
    }, 'customer_order_pickup');
    const requiredPoint = {'id', 'name', 'addressLine1', 'commune', 'region'};
    if (!point.keys.toSet().containsAll(requiredPoint)) {
      throw const FormatException('customer_order_pickup_required');
    }
    _requiredUuid(point, 'id');
    destinationTitle = _safeRequiredText(point, 'name', 120);
    destinationLines = [
      _safeRequiredText(point, 'addressLine1', 200),
      ?_safeOptionalText(point, 'addressLine2', 200),
      '${_safeRequiredText(point, 'commune', 100)}, '
          '${_safeRequiredText(point, 'region', 100)}',
    ];
  }
  return CustomerOrderFulfillment(
    mode: expectedMode,
    destinationTitle: destinationTitle,
    destinationLines: destinationLines,
    slotLabel: _safeRequiredText(slot, 'label', 160),
    slotStartsAt: slotStartsAt,
    slotEndsAt: slotEndsAt,
  );
}

CustomerOrderFailureKind _remoteFailure(String status) => switch (status) {
  'invalid' => CustomerOrderFailureKind.invalid,
  'unavailable' => CustomerOrderFailureKind.unavailable,
  'not_found' => CustomerOrderFailureKind.notFound,
  'not_cancellable' => CustomerOrderFailureKind.notCancellable,
  'version_conflict' => CustomerOrderFailureKind.versionConflict,
  'idempotency_conflict' => CustomerOrderFailureKind.idempotencyConflict,
  _ => CustomerOrderFailureKind.unexpected,
};

CustomerOrderFailureKind _postgrestFailure(String? code) => switch (code) {
  '28000' || '42501' || 'PGRST301' => CustomerOrderFailureKind.unauthorized,
  '57014' => CustomerOrderFailureKind.timeout,
  _ => CustomerOrderFailureKind.unexpected,
};

CustomerOrderStatus _orderStatus(String value) => switch (value) {
  'confirmed' => CustomerOrderStatus.confirmed,
  'accepted' => CustomerOrderStatus.accepted,
  'rejected' => CustomerOrderStatus.rejected,
  'preparing' => CustomerOrderStatus.preparing,
  'ready' => CustomerOrderStatus.ready,
  'out_for_delivery' => CustomerOrderStatus.outForDelivery,
  'completed' => CustomerOrderStatus.completed,
  'cancelled' => CustomerOrderStatus.cancelled,
  _ => throw const FormatException('customer_order_status'),
};

CustomerOrderFulfillmentMode _mode(String value) => switch (value) {
  'pickup' => CustomerOrderFulfillmentMode.pickup,
  'reservation' => CustomerOrderFulfillmentMode.reservation,
  'delivery' => CustomerOrderFulfillmentMode.delivery,
  _ => throw const FormatException('customer_order_mode'),
};

CustomerOrderActorKind _actor(String value) => switch (value) {
  'system' => CustomerOrderActorKind.system,
  'customer' => CustomerOrderActorKind.customer,
  'admin' => CustomerOrderActorKind.admin,
  'pos' => CustomerOrderActorKind.pos,
  _ => throw const FormatException('customer_order_actor'),
};

Map<String, Object?> _payload(Object? raw, Set<String> allowed, String label) {
  if (raw is! Map) throw FormatException('${label}_map');
  final map = raw.map((key, value) => MapEntry(key.toString(), value));
  if (map.keys.any((key) => !allowed.contains(key))) {
    throw FormatException('${label}_keys');
  }
  return map;
}

Map<String, Object?> _strictMap(Object? raw, Set<String> keys, String label) {
  final map = _payload(raw, keys, label);
  if (map.length != keys.length) throw FormatException('${label}_required');
  return map;
}

List<Object?> _list(
  Map<String, Object?> map,
  String key, {
  required int maximum,
}) {
  final value = map[key];
  if (value is! List || value.length > maximum) {
    throw FormatException('customer_order_$key');
  }
  return value.cast<Object?>();
}

String _requiredString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('customer_order_$key');
  }
  return value;
}

String _safeRequiredText(
  Map<String, Object?> map,
  String key,
  int maximumRunes,
) {
  final value = _requiredString(map, key);
  final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (value != normalized ||
      normalized.runes.length > maximumRunes ||
      !_isSafeText(normalized)) {
    throw FormatException('customer_order_$key');
  }
  return normalized;
}

String? _safeOptionalText(
  Map<String, Object?> map,
  String key,
  int maximumRunes,
) {
  if (!map.containsKey(key) || map[key] == null) return null;
  return _safeRequiredText(map, key, maximumRunes);
}

bool _isSafeText(String value) {
  if (value.contains('<') || value.contains('>')) return false;
  for (final rune in value.runes) {
    if (rune < 0x20 ||
        (rune >= 0x7f && rune <= 0x9f) ||
        rune == 0x061c ||
        (rune >= 0x200e && rune <= 0x200f) ||
        (rune >= 0x202a && rune <= 0x202e) ||
        (rune >= 0x2066 && rune <= 0x2069)) {
      return false;
    }
  }
  return true;
}

int _requiredInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) throw FormatException('customer_order_$key');
  return value;
}

int _amount(Map<String, Object?> map, String key) {
  final value = _requiredInt(map, key);
  if (value < 0 || value > customerOrderMaximumAmountClp) {
    throw FormatException('customer_order_$key');
  }
  return value;
}

int? _optionalAmount(Map<String, Object?> map, String key) {
  if (!map.containsKey(key) || map[key] == null) return null;
  return _amount(map, key);
}

DateTime _requiredDate(Map<String, Object?> map, String key) {
  final value = _requiredString(map, key);
  final parsed = DateTime.tryParse(value)?.toUtc();
  if (parsed == null) throw FormatException('customer_order_$key');
  _requirePayloadDate(parsed);
  return parsed;
}

DateTime? _optionalDate(Map<String, Object?> map, String key) {
  if (!map.containsKey(key) || map[key] == null) return null;
  return _requiredDate(map, key);
}

String _requiredUuid(Map<String, Object?> map, String key) {
  final value = _requiredString(map, key);
  _requirePayloadUuid(value);
  return value;
}

String? _optionalUuid(Map<String, Object?> map, String key) {
  if (!map.containsKey(key) || map[key] == null) return null;
  return _requiredUuid(map, key);
}

String _requiredShopSlug(Map<String, Object?> map, String key) {
  final value = _requiredString(map, key);
  _requirePayloadShopSlug(value);
  return value;
}

String _orderCode(Map<String, Object?> map, String key) {
  final value = _requiredString(map, key);
  if (!RegExp(r'^MC-[0-9A-F]{20}$').hasMatch(value)) {
    throw const FormatException('customer_order_code');
  }
  return value;
}

void _requireInputUuid(String value) {
  if (!RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  ).hasMatch(value)) {
    throw const CustomerOrderRepositoryException(
      CustomerOrderFailureKind.invalid,
    );
  }
}

void _requireInputShopSlug(String value) {
  if (!RegExp(r'^[a-z0-9][a-z0-9-]{2,62}$').hasMatch(value)) {
    throw const CustomerOrderRepositoryException(
      CustomerOrderFailureKind.invalid,
    );
  }
}

void _requireInputDate(DateTime value) {
  if (value.year < 2020 || value.year > 2200) {
    throw const CustomerOrderRepositoryException(
      CustomerOrderFailureKind.invalid,
    );
  }
}

void _requirePayloadUuid(String value) {
  if (!RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  ).hasMatch(value)) {
    throw const FormatException('customer_order_uuid');
  }
}

void _requirePayloadShopSlug(String value) {
  if (!RegExp(r'^[a-z0-9][a-z0-9-]{2,62}$').hasMatch(value)) {
    throw const FormatException('customer_order_shop_slug');
  }
}

void _requirePayloadDate(DateTime value) {
  if (value.year < 2020 || value.year > 2200) {
    throw const FormatException('customer_order_date');
  }
}

void _requireUnique(Iterable<String> values, String label) {
  final list = values.toList(growable: false);
  if (list.toSet().length != list.length) throw FormatException(label);
}
