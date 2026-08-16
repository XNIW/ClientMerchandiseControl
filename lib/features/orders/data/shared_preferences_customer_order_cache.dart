import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/formatting/shop_date_time_formatter.dart';
import '../domain/customer_order_models.dart';
import '../domain/customer_order_repository.dart';

abstract interface class CustomerOrderCachePreferences {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);
}

final class PlatformCustomerOrderCachePreferences
    implements CustomerOrderCachePreferences {
  PlatformCustomerOrderCachePreferences([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<void> remove(String key) => _preferences.remove(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);
}

final class SharedPreferencesCustomerOrderCache
    implements CustomerOrderCacheStore {
  SharedPreferencesCustomerOrderCache({
    CustomerOrderCachePreferences? preferences,
  }) : _preferences = preferences ?? PlatformCustomerOrderCachePreferences();

  static const storageKey = 'cmc.customer-order-cache.v1';
  static const maximumEncodedBytes = 262144;

  final CustomerOrderCachePreferences _preferences;
  Future<void> _tail = Future<void>.value();

  @override
  Future<CustomerOrderCacheSnapshot?> read({
    required String ownerSubjectId,
    required String shopSlug,
  }) {
    return _serialized(() async {
      _validateContext(ownerSubjectId, shopSlug);
      final encoded = await _preferences.getString(storageKey);
      if (encoded == null) return null;
      try {
        if (utf8.encode(encoded).length > maximumEncodedBytes) {
          throw const FormatException('customer_order_cache_size');
        }
        final snapshot = _decode(encoded);
        if (snapshot.ownerSubjectId != ownerSubjectId ||
            snapshot.shopSlug != shopSlug) {
          await _preferences.remove(storageKey);
          return null;
        }
        return snapshot;
      } on Object {
        await _preferences.remove(storageKey);
        return null;
      }
    });
  }

  @override
  Future<void> save(CustomerOrderCacheSnapshot snapshot) {
    return _serialized(() async {
      _validateSnapshot(snapshot);
      var encoded = _encode(snapshot);
      if (utf8.encode(encoded).length > maximumEncodedBytes) {
        encoded = _encode(
          snapshot.copyWith(details: const <String, CustomerOrderDetail>{}),
        );
      }
      if (utf8.encode(encoded).length > maximumEncodedBytes) {
        throw const FormatException('customer_order_cache_size');
      }
      await _preferences.setString(storageKey, encoded);
    });
  }

  @override
  Future<void> clear({
    required String ownerSubjectId,
    required String shopSlug,
  }) {
    return _serialized(() async {
      _validateContext(ownerSubjectId, shopSlug);
      final encoded = await _preferences.getString(storageKey);
      if (encoded == null) return;
      try {
        final snapshot = _decode(encoded);
        if (snapshot.ownerSubjectId != ownerSubjectId ||
            snapshot.shopSlug != shopSlug) {
          return;
        }
      } on Object {
        // Un record corrotto non deve sopravvivere al cleanup esplicito.
      }
      await _preferences.remove(storageKey);
    });
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final operation = _tail.then((_) => action());
    _tail = operation.then<void>((_) {}, onError: (_, _) {});
    return operation;
  }
}

String _encode(CustomerOrderCacheSnapshot snapshot) {
  _validateSnapshot(snapshot);
  return jsonEncode({
    'version': 2,
    'ownerSubjectId': snapshot.ownerSubjectId,
    'shopSlug': snapshot.shopSlug,
    'orders': snapshot.orders.map(_encodeCard).toList(growable: false),
    'details': snapshot.details.values
        .map(_encodeDetail)
        .toList(growable: false),
    'nextCursor': snapshot.nextCursor == null
        ? null
        : {
            'beforePlacedAt': _date(snapshot.nextCursor!.beforePlacedAt),
            'beforeOrderId': snapshot.nextCursor!.beforeOrderId,
          },
    'pendingCancellation': snapshot.pendingCancellation == null
        ? null
        : {
            'orderId': snapshot.pendingCancellation!.orderId,
            'expectedStatusVersion':
                snapshot.pendingCancellation!.expectedStatusVersion,
            'idempotencyKey': snapshot.pendingCancellation!.idempotencyKey,
            'createdAt': _date(snapshot.pendingCancellation!.createdAt),
          },
    'cachedAt': _date(snapshot.cachedAt),
  });
}

Map<String, Object?> _encodeCard(CustomerOrderCard card) => {
  'id': card.id,
  'code': card.code,
  'status': card.status.name,
  'version': card.version,
  'fulfillmentMode': card.fulfillmentMode.name,
  'totalClp': card.totalClp,
  'itemCount': card.itemCount,
  'primaryItemName': card.primaryItemName,
  'cancellationAllowed': card.cancellationAllowed,
  'placedAt': _date(card.placedAt),
  'updatedAt': _date(card.updatedAt),
  'timeZone': card.timeZone,
};

Map<String, Object?> _encodeDetail(CustomerOrderDetail detail) => {
  'id': detail.id,
  'code': detail.code,
  'status': detail.status.name,
  'version': detail.version,
  'shopSlug': detail.shopSlug,
  'fulfillment': {
    'mode': detail.fulfillment.mode.name,
    'destinationTitle': detail.fulfillment.destinationTitle,
    'destinationLines': detail.fulfillment.destinationLines,
    'slotLabel': detail.fulfillment.slotLabel,
    'slotStartsAt': _date(detail.fulfillment.slotStartsAt),
    'slotEndsAt': _date(detail.fulfillment.slotEndsAt),
  },
  'subtotalClp': detail.subtotalClp,
  'deliveryFeeClp': detail.deliveryFeeClp,
  'totalClp': detail.totalClp,
  'items': detail.items
      .map(
        (line) => {
          'publicationId': line.publicationId,
          'publicName': line.publicName,
          'quantity': line.quantity,
          'unitPriceClp': line.unitPriceClp,
          'compareAtPriceClp': line.compareAtPriceClp,
          'lineTotalClp': line.lineTotalClp,
          'promotionName': line.promotionName,
          'promotionEndsAt': line.promotionEndsAt == null
              ? null
              : _date(line.promotionEndsAt!),
        },
      )
      .toList(growable: false),
  'timeline': detail.timeline
      .map(
        (event) => {
          'version': event.version,
          'status': event.status.name,
          'actorKind': event.actorKind.name,
          'createdAt': _date(event.createdAt),
        },
      )
      .toList(growable: false),
  'cancellation': {
    'enabled': detail.cancellation.enabled,
    'allowed': detail.cancellation.allowed,
    'deadline': _date(detail.cancellation.deadline),
  },
  'placedAt': _date(detail.placedAt),
  'updatedAt': _date(detail.updatedAt),
  'serverTime': _date(detail.serverTime),
  'idempotent': detail.idempotent,
  'timeZone': detail.timeZone,
};

CustomerOrderCacheSnapshot _decode(String encoded) {
  final root = _strictMap(jsonDecode(encoded), const {
    'version',
    'ownerSubjectId',
    'shopSlug',
    'orders',
    'details',
    'nextCursor',
    'pendingCancellation',
    'cachedAt',
  }, 'root');
  if (root['version'] != 2) {
    throw const FormatException('customer_order_cache_version');
  }
  final ownerSubjectId = _string(root, 'ownerSubjectId', maximumRunes: 256);
  final shopSlug = _string(root, 'shopSlug', maximumRunes: 63);
  _validateContext(ownerSubjectId, shopSlug);
  final ordersRaw = _list(
    root,
    'orders',
    maximum: customerOrderMaximumCachedCards,
  );
  final orders = ordersRaw.map(_decodeCard).toList(growable: false);
  final detailsRaw = _list(
    root,
    'details',
    maximum: customerOrderMaximumCachedDetails,
  );
  final details = <String, CustomerOrderDetail>{};
  for (final raw in detailsRaw) {
    final detail = _decodeDetail(raw);
    if (details.containsKey(detail.id)) {
      throw const FormatException('customer_order_cache_detail_duplicate');
    }
    details[detail.id] = detail;
  }
  final cursorRaw = root['nextCursor'];
  CustomerOrderCursor? nextCursor;
  if (cursorRaw != null) {
    final map = _strictMap(cursorRaw, const {
      'beforePlacedAt',
      'beforeOrderId',
    }, 'cursor');
    nextCursor = CustomerOrderCursor(
      beforePlacedAt: _readDate(map, 'beforePlacedAt'),
      beforeOrderId: _uuid(map, 'beforeOrderId'),
    );
  }
  final pendingRaw = root['pendingCancellation'];
  CustomerOrderPendingCancellation? pending;
  if (pendingRaw != null) {
    final map = _strictMap(pendingRaw, const {
      'orderId',
      'expectedStatusVersion',
      'idempotencyKey',
      'createdAt',
    }, 'pending');
    pending = CustomerOrderPendingCancellation(
      orderId: _uuid(map, 'orderId'),
      expectedStatusVersion: _positiveInt(map, 'expectedStatusVersion'),
      idempotencyKey: _uuid(map, 'idempotencyKey'),
      createdAt: _readDate(map, 'createdAt'),
    );
  }
  final snapshot = CustomerOrderCacheSnapshot(
    ownerSubjectId: ownerSubjectId,
    shopSlug: shopSlug,
    orders: orders,
    details: details,
    nextCursor: nextCursor,
    pendingCancellation: pending,
    cachedAt: _readDate(root, 'cachedAt'),
  );
  _validateSnapshot(snapshot);
  return snapshot;
}

CustomerOrderCard _decodeCard(Object? raw) {
  final map = _strictMap(raw, const {
    'id',
    'code',
    'status',
    'version',
    'fulfillmentMode',
    'totalClp',
    'itemCount',
    'primaryItemName',
    'cancellationAllowed',
    'placedAt',
    'updatedAt',
    'timeZone',
  }, 'card');
  final cancellationAllowed = map['cancellationAllowed'];
  if (cancellationAllowed is! bool) {
    throw const FormatException('customer_order_cache_cancellation');
  }
  return CustomerOrderCard(
    id: _uuid(map, 'id'),
    code: _code(map, 'code'),
    status: _status(_string(map, 'status', maximumRunes: 32)),
    version: _positiveInt(map, 'version'),
    fulfillmentMode: _mode(_string(map, 'fulfillmentMode', maximumRunes: 32)),
    totalClp: _amount(map, 'totalClp'),
    itemCount: _boundedInt(
      map,
      'itemCount',
      minimum: 1,
      maximum: customerOrderMaximumLines,
    ),
    primaryItemName: _string(map, 'primaryItemName', maximumRunes: 200),
    cancellationAllowed: cancellationAllowed,
    placedAt: _readDate(map, 'placedAt'),
    updatedAt: _readDate(map, 'updatedAt'),
    timeZone: _timeZone(map, 'timeZone'),
  );
}

CustomerOrderDetail _decodeDetail(Object? raw) {
  final map = _strictMap(raw, const {
    'id',
    'code',
    'status',
    'version',
    'shopSlug',
    'fulfillment',
    'subtotalClp',
    'deliveryFeeClp',
    'totalClp',
    'items',
    'timeline',
    'cancellation',
    'placedAt',
    'updatedAt',
    'serverTime',
    'idempotent',
    'timeZone',
  }, 'detail');
  final fulfillmentMap = _strictMap(map['fulfillment'], const {
    'mode',
    'destinationTitle',
    'destinationLines',
    'slotLabel',
    'slotStartsAt',
    'slotEndsAt',
  }, 'fulfillment');
  final destinationLines = _list(fulfillmentMap, 'destinationLines', maximum: 4)
      .map(
        (value) =>
            _safeValueString(value, 'destinationLine', maximumRunes: 200),
      )
      .toList(growable: false);
  if (destinationLines.isEmpty) {
    throw const FormatException('customer_order_cache_destination');
  }
  final items = _list(
    map,
    'items',
    maximum: customerOrderMaximumLines,
  ).map(_decodeLine).toList(growable: false);
  final timeline = _list(
    map,
    'timeline',
    maximum: 1000,
  ).map(_decodeEvent).toList(growable: false);
  final cancellationMap = _strictMap(map['cancellation'], const {
    'enabled',
    'allowed',
    'deadline',
  }, 'cancellation');
  final enabled = cancellationMap['enabled'];
  final allowed = cancellationMap['allowed'];
  final idempotent = map['idempotent'];
  if (enabled is! bool || allowed is! bool || idempotent is! bool) {
    throw const FormatException('customer_order_cache_boolean');
  }
  return CustomerOrderDetail(
    id: _uuid(map, 'id'),
    code: _code(map, 'code'),
    status: _status(_string(map, 'status', maximumRunes: 32)),
    version: _positiveInt(map, 'version'),
    shopSlug: _string(map, 'shopSlug', maximumRunes: 63),
    fulfillment: CustomerOrderFulfillment(
      mode: _mode(_string(fulfillmentMap, 'mode', maximumRunes: 32)),
      destinationTitle: _string(
        fulfillmentMap,
        'destinationTitle',
        maximumRunes: 160,
      ),
      destinationLines: destinationLines,
      slotLabel: _string(fulfillmentMap, 'slotLabel', maximumRunes: 160),
      slotStartsAt: _readDate(fulfillmentMap, 'slotStartsAt'),
      slotEndsAt: _readDate(fulfillmentMap, 'slotEndsAt'),
    ),
    subtotalClp: _amount(map, 'subtotalClp'),
    deliveryFeeClp: _amount(map, 'deliveryFeeClp'),
    totalClp: _amount(map, 'totalClp'),
    items: items,
    timeline: timeline,
    cancellation: CustomerOrderCancellation(
      enabled: enabled,
      allowed: allowed,
      deadline: _readDate(cancellationMap, 'deadline'),
    ),
    placedAt: _readDate(map, 'placedAt'),
    updatedAt: _readDate(map, 'updatedAt'),
    serverTime: _readDate(map, 'serverTime'),
    idempotent: idempotent,
    timeZone: _timeZone(map, 'timeZone'),
  );
}

String _timeZone(Map<String, Object?> map, String key) {
  final value = _string(map, key, maximumRunes: 64);
  if (!ShopDateTimeFormatter.supports(value)) {
    throw const FormatException('customer_order_cache_time_zone');
  }
  return value;
}

CustomerOrderLine _decodeLine(Object? raw) {
  final map = _strictMap(raw, const {
    'publicationId',
    'publicName',
    'quantity',
    'unitPriceClp',
    'compareAtPriceClp',
    'lineTotalClp',
    'promotionName',
    'promotionEndsAt',
  }, 'line');
  return CustomerOrderLine(
    publicationId: _uuid(map, 'publicationId'),
    publicName: _string(map, 'publicName', maximumRunes: 200),
    quantity: _boundedInt(map, 'quantity', minimum: 1, maximum: 99),
    unitPriceClp: _amount(map, 'unitPriceClp'),
    compareAtPriceClp: _optionalAmount(map, 'compareAtPriceClp'),
    lineTotalClp: _amount(map, 'lineTotalClp'),
    promotionName: _optionalString(map, 'promotionName', maximumRunes: 160),
    promotionEndsAt: _optionalDate(map, 'promotionEndsAt'),
  );
}

CustomerOrderTimelineEvent _decodeEvent(Object? raw) {
  final map = _strictMap(raw, const {
    'version',
    'status',
    'actorKind',
    'createdAt',
  }, 'event');
  return CustomerOrderTimelineEvent(
    version: _positiveInt(map, 'version'),
    status: _status(_string(map, 'status', maximumRunes: 32)),
    actorKind: _actor(_string(map, 'actorKind', maximumRunes: 16)),
    createdAt: _readDate(map, 'createdAt'),
  );
}

void _validateSnapshot(CustomerOrderCacheSnapshot snapshot) {
  _validateContext(snapshot.ownerSubjectId, snapshot.shopSlug);
  if (snapshot.orders.length > customerOrderMaximumCachedCards ||
      snapshot.details.length > customerOrderMaximumCachedDetails ||
      snapshot.orders.map((order) => order.id).toSet().length !=
          snapshot.orders.length) {
    throw const FormatException('customer_order_cache_bounds');
  }
  for (final card in snapshot.orders) {
    _validateCard(card);
  }
  for (final entry in snapshot.details.entries) {
    if (entry.key != entry.value.id ||
        entry.value.shopSlug != snapshot.shopSlug) {
      throw const FormatException('customer_order_cache_detail_identity');
    }
    _validateDetail(entry.value);
  }
  final pending = snapshot.pendingCancellation;
  if (pending != null) {
    _validateUuid(pending.orderId);
    _validateUuid(pending.idempotencyKey);
    if (pending.expectedStatusVersion < 1) {
      throw const FormatException('customer_order_cache_pending_version');
    }
  }
  final cursor = snapshot.nextCursor;
  if (cursor != null) {
    _validateUuid(cursor.beforeOrderId);
    _validateDate(cursor.beforePlacedAt);
    if (snapshot.orders.isEmpty ||
        snapshot.orders.last.id != cursor.beforeOrderId ||
        snapshot.orders.last.placedAt != cursor.beforePlacedAt) {
      throw const FormatException('customer_order_cache_cursor');
    }
  }
  _validateDate(snapshot.cachedAt);
}

void _validateCard(CustomerOrderCard card) {
  _validateUuid(card.id);
  _validateCode(card.code);
  _validateAmount(card.totalClp);
  _validateText(card.primaryItemName, maximumRunes: 200);
  _validateDate(card.placedAt);
  _validateDate(card.updatedAt);
  if (!ShopDateTimeFormatter.supports(card.timeZone) ||
      card.version < 1 ||
      card.itemCount < 1 ||
      card.itemCount > customerOrderMaximumLines ||
      card.updatedAt.isBefore(card.placedAt)) {
    throw const FormatException('customer_order_cache_card');
  }
}

void _validateDetail(CustomerOrderDetail detail) {
  _validateUuid(detail.id);
  _validateCode(detail.code);
  _validateContext('owner-placeholder', detail.shopSlug);
  if (!ShopDateTimeFormatter.supports(detail.timeZone) ||
      detail.version < 1 ||
      detail.items.isEmpty ||
      detail.items.length > customerOrderMaximumLines ||
      detail.timeline.length != detail.version ||
      detail.timeline.isEmpty ||
      detail.timeline.last.status != detail.status ||
      detail.totalClp != detail.subtotalClp + detail.deliveryFeeClp ||
      (detail.fulfillment.mode != CustomerOrderFulfillmentMode.delivery &&
          detail.deliveryFeeClp != 0) ||
      detail.items.fold<int>(0, (sum, line) => sum + line.lineTotalClp) !=
          detail.subtotalClp ||
      detail.updatedAt.isBefore(detail.placedAt) ||
      detail.placedAt.isAfter(
        detail.serverTime.add(const Duration(minutes: 1)),
      ) ||
      detail.fulfillment.destinationLines.isEmpty ||
      !detail.fulfillment.slotEndsAt.isAfter(detail.fulfillment.slotStartsAt)) {
    throw const FormatException('customer_order_cache_detail');
  }
  _validateAmount(detail.subtotalClp);
  _validateAmount(detail.deliveryFeeClp);
  _validateAmount(detail.totalClp);
  _validateText(detail.fulfillment.destinationTitle, maximumRunes: 160);
  _validateText(detail.fulfillment.slotLabel, maximumRunes: 160);
  _validateDate(detail.fulfillment.slotStartsAt);
  _validateDate(detail.fulfillment.slotEndsAt);
  _validateDate(detail.placedAt);
  _validateDate(detail.updatedAt);
  _validateDate(detail.serverTime);
  for (final line in detail.fulfillment.destinationLines) {
    _validateText(line, maximumRunes: 200);
  }
  final publicationIds = <String>{};
  for (final line in detail.items) {
    _validateUuid(line.publicationId);
    _validateText(line.publicName, maximumRunes: 200);
    _validateAmount(line.unitPriceClp);
    _validateAmount(line.lineTotalClp);
    final compareAt = line.compareAtPriceClp;
    if (compareAt != null) {
      _validateAmount(compareAt);
    }
    if (line.quantity < 1 ||
        line.quantity > 99 ||
        line.lineTotalClp != line.unitPriceClp * line.quantity ||
        (compareAt != null && compareAt < line.unitPriceClp) ||
        !publicationIds.add(line.publicationId)) {
      throw const FormatException('customer_order_cache_line');
    }
    final promotionName = line.promotionName;
    if (promotionName != null) {
      _validateText(promotionName, maximumRunes: 160);
    }
    final promotionEndsAt = line.promotionEndsAt;
    if (promotionEndsAt != null) {
      _validateDate(promotionEndsAt);
    }
  }
  DateTime? previousEventAt;
  for (var index = 0; index < detail.timeline.length; index++) {
    final event = detail.timeline[index];
    _validateDate(event.createdAt);
    if (event.version != index + 1 ||
        event.createdAt.isBefore(detail.placedAt) ||
        event.createdAt.isAfter(
          detail.serverTime.add(const Duration(minutes: 1)),
        ) ||
        (previousEventAt != null &&
            event.createdAt.isBefore(previousEventAt))) {
      throw const FormatException('customer_order_cache_timeline');
    }
    previousEventAt = event.createdAt;
  }
  _validateDate(detail.cancellation.deadline);
  if (detail.cancellation.deadline.isBefore(detail.placedAt) ||
      (detail.cancellation.allowed &&
          (!detail.cancellation.enabled ||
              detail.status != CustomerOrderStatus.confirmed ||
              !detail.cancellation.deadline.isAfter(detail.serverTime)))) {
    throw const FormatException('customer_order_cache_cancellation');
  }
}

void _validateContext(String ownerSubjectId, String shopSlug) {
  _validateText(ownerSubjectId, maximumRunes: 256);
  if (!RegExp(r'^[a-z0-9][a-z0-9-]{2,62}$').hasMatch(shopSlug)) {
    throw const FormatException('customer_order_cache_shop');
  }
}

Map<String, Object?> _strictMap(Object? raw, Set<String> keys, String label) {
  if (raw is! Map) throw FormatException('customer_order_cache_${label}_map');
  final map = raw.map((key, value) => MapEntry(key.toString(), value));
  if (map.length != keys.length || map.keys.any((key) => !keys.contains(key))) {
    throw FormatException('customer_order_cache_${label}_keys');
  }
  return map;
}

List<Object?> _list(
  Map<String, Object?> map,
  String key, {
  required int maximum,
}) {
  final value = map[key];
  if (value is! List || value.length > maximum) {
    throw FormatException('customer_order_cache_$key');
  }
  return value.cast<Object?>();
}

String _string(
  Map<String, Object?> map,
  String key, {
  required int maximumRunes,
}) {
  return _safeValueString(map[key], key, maximumRunes: maximumRunes);
}

String _safeValueString(
  Object? value,
  String key, {
  required int maximumRunes,
}) {
  if (value is! String) throw FormatException('customer_order_cache_$key');
  _validateText(value, maximumRunes: maximumRunes);
  return value;
}

String? _optionalString(
  Map<String, Object?> map,
  String key, {
  required int maximumRunes,
}) {
  if (map[key] == null) return null;
  return _string(map, key, maximumRunes: maximumRunes);
}

String _uuid(Map<String, Object?> map, String key) {
  final value = _string(map, key, maximumRunes: 36);
  _validateUuid(value);
  return value;
}

String _code(Map<String, Object?> map, String key) {
  final value = _string(map, key, maximumRunes: 23);
  _validateCode(value);
  return value;
}

int _positiveInt(Map<String, Object?> map, String key) =>
    _boundedInt(map, key, minimum: 1, maximum: 2147483647);

int _boundedInt(
  Map<String, Object?> map,
  String key, {
  required int minimum,
  required int maximum,
}) {
  final value = map[key];
  if (value is! int || value < minimum || value > maximum) {
    throw FormatException('customer_order_cache_$key');
  }
  return value;
}

int _amount(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) throw FormatException('customer_order_cache_$key');
  _validateAmount(value);
  return value;
}

int? _optionalAmount(Map<String, Object?> map, String key) {
  if (map[key] == null) return null;
  return _amount(map, key);
}

DateTime _readDate(Map<String, Object?> map, String key) {
  final parsed = DateTime.tryParse(
    _string(map, key, maximumRunes: 40),
  )?.toUtc();
  if (parsed == null) throw FormatException('customer_order_cache_$key');
  _validateDate(parsed);
  return parsed;
}

DateTime? _optionalDate(Map<String, Object?> map, String key) {
  if (map[key] == null) return null;
  return _readDate(map, key);
}

CustomerOrderStatus _status(String value) => switch (value) {
  'confirmed' => CustomerOrderStatus.confirmed,
  'accepted' => CustomerOrderStatus.accepted,
  'rejected' => CustomerOrderStatus.rejected,
  'preparing' => CustomerOrderStatus.preparing,
  'ready' => CustomerOrderStatus.ready,
  'outForDelivery' => CustomerOrderStatus.outForDelivery,
  'completed' => CustomerOrderStatus.completed,
  'cancelled' => CustomerOrderStatus.cancelled,
  _ => throw const FormatException('customer_order_cache_status'),
};

CustomerOrderFulfillmentMode _mode(String value) => switch (value) {
  'pickup' => CustomerOrderFulfillmentMode.pickup,
  'reservation' => CustomerOrderFulfillmentMode.reservation,
  'delivery' => CustomerOrderFulfillmentMode.delivery,
  _ => throw const FormatException('customer_order_cache_mode'),
};

CustomerOrderActorKind _actor(String value) => switch (value) {
  'system' => CustomerOrderActorKind.system,
  'customer' => CustomerOrderActorKind.customer,
  'admin' => CustomerOrderActorKind.admin,
  'pos' => CustomerOrderActorKind.pos,
  _ => throw const FormatException('customer_order_cache_actor'),
};

void _validateUuid(String value) {
  if (!RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  ).hasMatch(value)) {
    throw const FormatException('customer_order_cache_uuid');
  }
}

void _validateCode(String value) {
  if (!RegExp(r'^MC-[0-9A-F]{20}$').hasMatch(value)) {
    throw const FormatException('customer_order_cache_code');
  }
}

void _validateAmount(int value) {
  if (value < 0 || value > customerOrderMaximumAmountClp) {
    throw const FormatException('customer_order_cache_amount');
  }
}

void _validateDate(DateTime value) {
  if (value.year < 2020 || value.year > 2200) {
    throw const FormatException('customer_order_cache_date');
  }
}

void _validateText(String value, {required int maximumRunes}) {
  if (value.isEmpty ||
      value.trim() != value ||
      value.runes.length > maximumRunes ||
      value.contains('<') ||
      value.contains('>')) {
    throw const FormatException('customer_order_cache_text');
  }
  for (final rune in value.runes) {
    if (rune < 0x20 ||
        (rune >= 0x7f && rune <= 0x9f) ||
        rune == 0x061c ||
        (rune >= 0x200e && rune <= 0x200f) ||
        (rune >= 0x202a && rune <= 0x202e) ||
        (rune >= 0x2066 && rune <= 0x2069)) {
      throw const FormatException('customer_order_cache_text');
    }
  }
}

String _date(DateTime value) => value.toUtc().toIso8601String();
