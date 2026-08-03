import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/checkout_failure.dart';
import '../domain/checkout_models.dart';
import '../domain/checkout_repository.dart';

abstract interface class CheckoutPort {
  Future<Object?> invoke(String function, Map<String, Object?> parameters);
}

final class PlatformCheckoutPort implements CheckoutPort {
  PlatformCheckoutPort(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> invoke(String function, Map<String, Object?> parameters) {
    return _client.rpc(function, params: parameters);
  }
}

final class SupabaseCheckoutRepository implements CheckoutRepository {
  const SupabaseCheckoutRepository({
    required this.port,
    this.requestTimeout = const Duration(seconds: 12),
  });

  final CheckoutPort port;
  final Duration requestTimeout;

  @override
  Future<StorefrontFulfillmentOptions> loadOptions({required String shopSlug}) {
    return _guard(() async {
      _requireShopSlug(shopSlug);
      return _parseOptions(
        await port.invoke('storefront_fulfillment_options_v1', {
          'p_shop_slug': shopSlug,
        }),
        expectedShopSlug: shopSlug,
      );
    });
  }

  @override
  Future<CheckoutRemoteResponse> createQuote(
    CheckoutQuoteCreateRequest request,
  ) {
    return _guard(() async {
      _requireShopSlug(request.shopSlug);
      _requireVersion(request.cartVersion, allowZero: true);
      _validateSelection(request.selection);
      _requireUuid(request.idempotencyKey);
      return _parseCheckoutResponse(
        await port.invoke('customer_checkout_quote_create_v1', {
          'p_shop_slug': request.shopSlug,
          'p_cart_version': request.cartVersion,
          'p_fulfillment_mode': request.selection.mode!.name,
          'p_address_id': request.selection.addressId,
          'p_pickup_point_id': request.selection.pickupPointId,
          'p_slot_id': request.selection.slotId,
          'p_idempotency_key': request.idempotencyKey,
        }),
      );
    });
  }

  @override
  Future<CheckoutRemoteResponse> confirmQuote({
    required String quoteId,
    required int expectedQuoteVersion,
    required String idempotencyKey,
  }) {
    return _guard(() async {
      _requireUuid(quoteId);
      _requireVersion(expectedQuoteVersion);
      _requireUuid(idempotencyKey);
      return _parseCheckoutResponse(
        await port.invoke('customer_checkout_quote_confirm_v1', {
          'p_quote_id': quoteId,
          'p_expected_quote_version': expectedQuoteVersion,
          'p_idempotency_key': idempotencyKey,
        }),
      );
    });
  }

  @override
  Future<CheckoutRemoteResponse> readQuote({required String quoteId}) {
    return _guard(() async {
      _requireUuid(quoteId);
      return _parseCheckoutResponse(
        await port.invoke('customer_checkout_quote_read_v1', {
          'p_quote_id': quoteId,
        }),
      );
    });
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation().timeout(requestTimeout);
    } on CheckoutRepositoryException {
      rethrow;
    } on TimeoutException {
      throw const CheckoutRepositoryException(CheckoutFailureKind.timeout);
    } on SocketException {
      throw const CheckoutRepositoryException(CheckoutFailureKind.offline);
    } on AuthException {
      throw const CheckoutRepositoryException(CheckoutFailureKind.unauthorized);
    } on PostgrestException catch (error) {
      throw CheckoutRepositoryException(_postgrestFailure(error.code));
    } on FormatException {
      throw const CheckoutRepositoryException(CheckoutFailureKind.unexpected);
    } on Object {
      throw const CheckoutRepositoryException(CheckoutFailureKind.unexpected);
    }
  }
}

const _optionsRootKeys = <String>{
  'apiVersion',
  'status',
  'shopSlug',
  'currencyCode',
  'modes',
  'pickupPoints',
  'deliveryZones',
  'slots',
  'serverTime',
};

StorefrontFulfillmentOptions _parseOptions(
  Object? raw, {
  required String expectedShopSlug,
}) {
  final payload = _payload(raw, _optionsRootKeys, 'checkout_options');
  if (payload['apiVersion'] != 'storefront-fulfillment.v1') {
    throw const FormatException('checkout_options_version');
  }
  final status = switch (_requiredString(payload, 'status')) {
    'ok' => FulfillmentOptionsStatus.ok,
    'unavailable' => FulfillmentOptionsStatus.unavailable,
    'invalid' => FulfillmentOptionsStatus.invalid,
    _ => throw const FormatException('checkout_options_status'),
  };
  final serverTime = _requiredDate(payload, 'serverTime');
  if (status != FulfillmentOptionsStatus.ok) {
    if (payload.keys.any(
      (key) => key != 'apiVersion' && key != 'status' && key != 'serverTime',
    )) {
      throw const FormatException('checkout_options_minimal');
    }
    return StorefrontFulfillmentOptions.unavailable(
      status: status,
      serverTime: serverTime,
    );
  }
  const required = {
    'apiVersion',
    'status',
    'shopSlug',
    'currencyCode',
    'modes',
    'pickupPoints',
    'deliveryZones',
    'slots',
    'serverTime',
  };
  if (!payload.keys.toSet().containsAll(required) ||
      _requiredString(payload, 'shopSlug') != expectedShopSlug ||
      payload['currencyCode'] != 'CLP') {
    throw const FormatException('checkout_options_identity');
  }
  final modes = _list(
    payload,
    'modes',
    maximum: 3,
  ).map(_parseMode).toList(growable: false);
  if (modes.length != 3 ||
      modes.map((option) => option.mode).toSet().length != 3) {
    throw const FormatException('checkout_options_modes');
  }
  final points = _list(
    payload,
    'pickupPoints',
    maximum: 100,
  ).map(_parsePickupPoint).toList(growable: false);
  final zones = _list(
    payload,
    'deliveryZones',
    maximum: 100,
  ).map(_parseDeliveryZone).toList(growable: false);
  final slots = _list(
    payload,
    'slots',
    maximum: 500,
  ).map(_parseSlot).toList(growable: false);
  _requireUnique(points.map((point) => point.id), 'checkout_options_points');
  _requireUnique(zones.map((zone) => zone.id), 'checkout_options_zones');
  _requireUnique(slots.map((slot) => slot.id), 'checkout_options_slots');
  final pointIds = points.map((point) => point.id).toSet();
  final zoneIds = zones.map((zone) => zone.id).toSet();
  for (final slot in slots) {
    if (slot.mode == CheckoutFulfillmentMode.delivery) {
      if (slot.pickupPointId != null ||
          !zoneIds.contains(slot.deliveryZoneId)) {
        throw const FormatException('checkout_options_slot_zone');
      }
    } else if (slot.deliveryZoneId != null ||
        !pointIds.contains(slot.pickupPointId)) {
      throw const FormatException('checkout_options_slot_point');
    }
  }
  return StorefrontFulfillmentOptions(
    status: status,
    shopSlug: expectedShopSlug,
    currencyCode: 'CLP',
    modes: modes,
    pickupPoints: points,
    deliveryZones: zones,
    slots: slots,
    serverTime: serverTime,
  );
}

CheckoutModeOption _parseMode(Object? raw) {
  final map = _strictMap(raw, const {'mode', 'enabled'}, 'checkout_mode');
  final enabled = map['enabled'];
  if (enabled is! bool) throw const FormatException('checkout_mode_enabled');
  return CheckoutModeOption(
    mode: _mode(_requiredString(map, 'mode')),
    enabled: enabled,
  );
}

CheckoutPickupPoint _parsePickupPoint(Object? raw) {
  final map = _strictMap(raw, const {
    'id',
    'name',
    'addressLine1',
    'addressLine2',
    'commune',
    'region',
    'instructions',
  }, 'checkout_point');
  final id = _requiredString(map, 'id');
  _requirePayloadUuid(id);
  return CheckoutPickupPoint(
    id: id,
    name: _safeRequiredText(map, 'name', 120),
    addressLine1: _safeRequiredText(map, 'addressLine1', 200),
    addressLine2: _safeOptionalText(map, 'addressLine2', 200),
    commune: _safeRequiredText(map, 'commune', 100),
    region: _safeRequiredText(map, 'region', 100),
    instructions: _safeOptionalText(map, 'instructions', 500),
  );
}

CheckoutDeliveryZone _parseDeliveryZone(Object? raw) {
  final map = _strictMap(raw, const {
    'id',
    'name',
    'region',
    'communes',
    'feeClp',
  }, 'checkout_zone');
  final id = _requiredString(map, 'id');
  _requirePayloadUuid(id);
  final communes = _list(map, 'communes', maximum: 100)
      .map((value) => _safeTextValue(value, 100, 'checkout_zone_commune'))
      .toList(growable: false);
  if (communes.isEmpty) throw const FormatException('checkout_zone_communes');
  _requireUnique(communes.map((value) => value.toLowerCase()), 'checkout_zone');
  return CheckoutDeliveryZone(
    id: id,
    name: _safeRequiredText(map, 'name', 120),
    region: _safeRequiredText(map, 'region', 100),
    communes: communes,
    feeClp: _amount(map, 'feeClp'),
  );
}

CheckoutFulfillmentSlot _parseSlot(Object? raw) {
  final map = _strictMap(raw, const {
    'id',
    'mode',
    'pickupPointId',
    'deliveryZoneId',
    'label',
    'startsAt',
    'endsAt',
    'status',
  }, 'checkout_slot');
  final id = _requiredString(map, 'id');
  _requirePayloadUuid(id);
  final pointId = _optionalUuid(map, 'pickupPointId');
  final zoneId = _optionalUuid(map, 'deliveryZoneId');
  final startsAt = _requiredDate(map, 'startsAt');
  final endsAt = _requiredDate(map, 'endsAt');
  if (!endsAt.isAfter(startsAt) || map['status'] != 'available') {
    throw const FormatException('checkout_slot_timing');
  }
  return CheckoutFulfillmentSlot(
    id: id,
    mode: _mode(_requiredString(map, 'mode')),
    pickupPointId: pointId,
    deliveryZoneId: zoneId,
    label: _safeRequiredText(map, 'label', 160),
    startsAt: startsAt,
    endsAt: endsAt,
  );
}

const _checkoutRootKeys = <String>{
  'apiVersion',
  'status',
  'idempotent',
  'quoteId',
  'shopSlug',
  'cartVersion',
  'quoteVersion',
  'quoteStatus',
  'fulfillmentMode',
  'addressId',
  'pickupPointId',
  'deliveryZoneId',
  'slotId',
  'currencyCode',
  'subtotalClp',
  'deliveryFeeClp',
  'totalClp',
  'items',
  'changes',
  'requiresCustomerReview',
  'quotedAt',
  'expiresAt',
  'confirmedAt',
  'serverTime',
  'remainingSeconds',
};

CheckoutRemoteResponse _parseCheckoutResponse(Object? raw) {
  final payload = _payload(raw, _checkoutRootKeys, 'checkout_response');
  if (payload['apiVersion'] != 'customer-checkout.v1') {
    throw const FormatException('checkout_response_version');
  }
  final status = _remoteStatus(_requiredString(payload, 'status'));
  final idempotent = payload['idempotent'];
  if (idempotent is! bool) {
    throw const FormatException('checkout_response_idempotent');
  }
  final serverTime = _requiredDate(payload, 'serverTime');
  final responseChanges = payload.containsKey('changes')
      ? _parseChanges(_list(payload, 'changes', maximum: checkoutMaximumItems))
      : const <CheckoutQuoteChange>[];
  if (!payload.containsKey('quoteVersion')) {
    const minimalKeys = {
      'apiVersion',
      'status',
      'idempotent',
      'serverTime',
      'quoteId',
      'changes',
    };
    if (payload.keys.any((key) => !minimalKeys.contains(key))) {
      throw const FormatException('checkout_response_minimal');
    }
    if (payload['quoteId'] case final String quoteId) {
      _requirePayloadUuid(quoteId);
    } else if (payload['quoteId'] != null) {
      throw const FormatException('checkout_response_quote_id');
    }
    return CheckoutRemoteResponse(
      status: status,
      idempotent: idempotent,
      serverTime: serverTime,
      changes: responseChanges,
    );
  }
  final quote = _parseQuote(payload, idempotent: idempotent);
  if (quote.serverTime != serverTime) {
    throw const FormatException('checkout_response_server_time');
  }
  return CheckoutRemoteResponse(
    status: status,
    idempotent: idempotent,
    serverTime: serverTime,
    quote: quote,
    changes: quote.changes,
  );
}

CheckoutQuote _parseQuote(
  Map<String, Object?> payload, {
  required bool idempotent,
}) {
  const required = {
    'quoteId',
    'shopSlug',
    'cartVersion',
    'quoteVersion',
    'quoteStatus',
    'fulfillmentMode',
    'slotId',
    'currencyCode',
    'subtotalClp',
    'deliveryFeeClp',
    'totalClp',
    'items',
    'changes',
    'requiresCustomerReview',
    'quotedAt',
    'expiresAt',
    'serverTime',
    'remainingSeconds',
  };
  if (!payload.keys.toSet().containsAll(required) ||
      payload['currencyCode'] != 'CLP') {
    throw const FormatException('checkout_quote_required');
  }
  final id = _requiredString(payload, 'quoteId');
  final shopSlug = _requiredString(payload, 'shopSlug');
  final slotId = _requiredString(payload, 'slotId');
  _requirePayloadUuid(id);
  _requirePayloadUuid(slotId);
  _requirePayloadShopSlug(shopSlug);
  final cartVersion = _requiredInt(payload, 'cartVersion');
  final quoteVersion = _requiredInt(payload, 'quoteVersion');
  if (cartVersion < 0 || quoteVersion < 1) {
    throw const FormatException('checkout_quote_version');
  }
  final quoteStatus = _quoteStatus(_requiredString(payload, 'quoteStatus'));
  final mode = _mode(_requiredString(payload, 'fulfillmentMode'));
  final addressId = _optionalUuid(payload, 'addressId');
  final pointId = _optionalUuid(payload, 'pickupPointId');
  final zoneId = _optionalUuid(payload, 'deliveryZoneId');
  if (mode == CheckoutFulfillmentMode.delivery) {
    if (addressId == null || zoneId == null || pointId != null) {
      throw const FormatException('checkout_quote_delivery');
    }
  } else if (pointId == null || addressId != null || zoneId != null) {
    throw const FormatException('checkout_quote_pickup');
  }
  final subtotal = _amount(payload, 'subtotalClp');
  final fee = _amount(payload, 'deliveryFeeClp');
  final total = _amount(payload, 'totalClp');
  if (total != subtotal + fee ||
      (mode != CheckoutFulfillmentMode.delivery && fee != 0)) {
    throw const FormatException('checkout_quote_total');
  }
  final items = _list(
    payload,
    'items',
    maximum: checkoutMaximumItems,
  ).map(_parseQuoteItem).toList(growable: false);
  if (items.isEmpty ||
      items.fold<int>(0, (sum, item) => sum + item.lineTotalClp) != subtotal) {
    throw const FormatException('checkout_quote_items_total');
  }
  _requireUnique(
    items.map((item) => item.publicationId),
    'checkout_quote_items',
  );
  final changes = _parseChanges(
    _list(payload, 'changes', maximum: checkoutMaximumItems),
  );
  final requiresReview = payload['requiresCustomerReview'];
  if (requiresReview is! bool ||
      requiresReview != (quoteStatus == CheckoutQuoteStatus.requiresReview)) {
    throw const FormatException('checkout_quote_review');
  }
  final quotedAt = _requiredDate(payload, 'quotedAt');
  final expiresAt = _requiredDate(payload, 'expiresAt');
  final serverTime = _requiredDate(payload, 'serverTime');
  final confirmedAt = _optionalDate(payload, 'confirmedAt');
  final remaining = _requiredInt(payload, 'remainingSeconds');
  if (!expiresAt.isAfter(quotedAt) || remaining < 0 || remaining > 600) {
    throw const FormatException('checkout_quote_timing');
  }
  if (quoteStatus == CheckoutQuoteStatus.confirmed && confirmedAt == null) {
    throw const FormatException('checkout_quote_confirmation');
  }
  return CheckoutQuote(
    id: id,
    shopSlug: shopSlug,
    cartVersion: cartVersion,
    quoteVersion: quoteVersion,
    status: quoteStatus,
    fulfillmentMode: mode,
    addressId: addressId,
    pickupPointId: pointId,
    deliveryZoneId: zoneId,
    slotId: slotId,
    subtotalClp: subtotal,
    deliveryFeeClp: fee,
    totalClp: total,
    items: items,
    changes: changes,
    requiresCustomerReview: requiresReview,
    quotedAt: quotedAt,
    expiresAt: expiresAt,
    confirmedAt: confirmedAt,
    serverTime: serverTime,
    remainingSeconds: remaining,
    idempotent: idempotent,
  );
}

CheckoutQuoteItem _parseQuoteItem(Object? raw) {
  final map = _strictMap(raw, const {
    'publicationId',
    'publicName',
    'quantity',
    'unitPriceClp',
    'compareAtPriceClp',
    'lineTotalClp',
    'promotionId',
    'promotionName',
    'promotionEndsAt',
    'holdId',
  }, 'checkout_quote_item');
  final publicationId = _requiredString(map, 'publicationId');
  _requirePayloadUuid(publicationId);
  _optionalUuid(map, 'promotionId');
  _optionalUuid(map, 'holdId');
  final quantity = _requiredInt(map, 'quantity');
  final unitPrice = _amount(map, 'unitPriceClp');
  final compareAt = _optionalAmount(map, 'compareAtPriceClp');
  final lineTotal = _amount(map, 'lineTotalClp');
  if (quantity < 1 || quantity > 99 || lineTotal != unitPrice * quantity) {
    throw const FormatException('checkout_quote_item_total');
  }
  return CheckoutQuoteItem(
    publicationId: publicationId,
    publicName: _safeRequiredText(map, 'publicName', 240),
    quantity: quantity,
    unitPriceClp: unitPrice,
    compareAtPriceClp: compareAt,
    lineTotalClp: lineTotal,
    promotionName: _safeOptionalText(map, 'promotionName', 160),
    promotionEndsAt: _optionalDate(map, 'promotionEndsAt'),
  );
}

List<CheckoutQuoteChange> _parseChanges(List<Object?> raw) {
  return raw
      .map((value) {
        final map = _strictMap(value, const {
          'publicationId',
          'type',
          'previousPriceClp',
          'currentPriceClp',
        }, 'checkout_change');
        final publicationId = _requiredString(map, 'publicationId');
        _requirePayloadUuid(publicationId);
        final type = switch (_requiredString(map, 'type')) {
          'price_changed' => CheckoutChangeType.priceChanged,
          'promotion_changed' => CheckoutChangeType.promotionChanged,
          'unavailable' => CheckoutChangeType.unavailable,
          'hold_required' => CheckoutChangeType.holdRequired,
          _ => throw const FormatException('checkout_change_type'),
        };
        return CheckoutQuoteChange(
          publicationId: publicationId,
          type: type,
          previousPriceClp: _optionalAmount(map, 'previousPriceClp'),
          currentPriceClp: _optionalAmount(map, 'currentPriceClp'),
        );
      })
      .toList(growable: false);
}

Map<String, Object?> _payload(Object? raw, Set<String> keys, String error) {
  if (raw is! Map) throw FormatException(error);
  final map = raw.map((key, value) => MapEntry(key.toString(), value));
  if (map.keys.any((key) => !keys.contains(key))) {
    throw FormatException('${error}_keys');
  }
  return map;
}

Map<String, Object?> _strictMap(Object? raw, Set<String> keys, String error) {
  final map = _payload(raw, keys, error);
  if (map.length != keys.length) throw FormatException('${error}_shape');
  return map;
}

List<Object?> _list(
  Map<String, Object?> map,
  String key, {
  required int maximum,
}) {
  final value = map[key];
  if (value is! List || value.length > maximum) {
    throw FormatException('checkout_$key');
  }
  return value.cast<Object?>();
}

String _requiredString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('checkout_$key');
  }
  return value;
}

String _safeRequiredText(Map<String, Object?> map, String key, int maximum) =>
    _safeTextValue(map[key], maximum, 'checkout_$key');

String? _safeOptionalText(Map<String, Object?> map, String key, int maximum) {
  final value = map[key];
  if (value == null) return null;
  return _safeTextValue(value, maximum, 'checkout_$key');
}

String _safeTextValue(Object? value, int maximum, String error) {
  if (value is! String ||
      value.isEmpty ||
      value.runes.length > maximum ||
      !_isSafeText(value)) {
    throw FormatException(error);
  }
  return value;
}

bool _isSafeText(String value) {
  for (final rune in value.runes) {
    final control = rune < 0x20 || (rune >= 0x7f && rune <= 0x9f);
    final bidi =
        rune == 0x061c ||
        (rune >= 0x200e && rune <= 0x200f) ||
        (rune >= 0x202a && rune <= 0x202e) ||
        (rune >= 0x2066 && rune <= 0x2069);
    if (control || bidi) return false;
  }
  return !value.contains('<') && !value.contains('>');
}

int _requiredInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) throw FormatException('checkout_$key');
  return value;
}

int _amount(Map<String, Object?> map, String key) {
  final value = _requiredInt(map, key);
  if (value < 0 || value > checkoutMaximumAmountClp) {
    throw FormatException('checkout_$key');
  }
  return value;
}

int? _optionalAmount(Map<String, Object?> map, String key) {
  if (map[key] == null) return null;
  return _amount(map, key);
}

DateTime _requiredDate(Map<String, Object?> map, String key) {
  final value = _requiredString(map, key);
  final date = DateTime.tryParse(value)?.toUtc();
  if (date == null) throw FormatException('checkout_$key');
  return date;
}

DateTime? _optionalDate(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('checkout_$key');
  final date = DateTime.tryParse(value)?.toUtc();
  if (date == null) throw FormatException('checkout_$key');
  return date;
}

String? _optionalUuid(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('checkout_$key');
  _requirePayloadUuid(value);
  return value;
}

CheckoutFulfillmentMode _mode(String value) => switch (value) {
  'pickup' => CheckoutFulfillmentMode.pickup,
  'reservation' => CheckoutFulfillmentMode.reservation,
  'delivery' => CheckoutFulfillmentMode.delivery,
  _ => throw const FormatException('checkout_mode'),
};

CheckoutRemoteStatus _remoteStatus(String value) => switch (value) {
  'ok' => CheckoutRemoteStatus.ok,
  'quoted' => CheckoutRemoteStatus.quoted,
  'requires_review' => CheckoutRemoteStatus.requiresReview,
  'confirmed' => CheckoutRemoteStatus.confirmed,
  'expired' => CheckoutRemoteStatus.expired,
  'invalid' => CheckoutRemoteStatus.invalid,
  'unavailable' => CheckoutRemoteStatus.unavailable,
  'cart_empty' => CheckoutRemoteStatus.cartEmpty,
  'cart_version_conflict' => CheckoutRemoteStatus.cartVersionConflict,
  'quote_version_conflict' => CheckoutRemoteStatus.quoteVersionConflict,
  'mode_unavailable' => CheckoutRemoteStatus.modeUnavailable,
  'slot_unavailable' => CheckoutRemoteStatus.slotUnavailable,
  'invalid_selection' => CheckoutRemoteStatus.invalidSelection,
  'pickup_unavailable' => CheckoutRemoteStatus.pickupUnavailable,
  'delivery_unavailable' => CheckoutRemoteStatus.deliveryUnavailable,
  'invalid_address' => CheckoutRemoteStatus.invalidAddress,
  'unsupported_zone' => CheckoutRemoteStatus.unsupportedZone,
  'cart_unavailable' => CheckoutRemoteStatus.cartUnavailable,
  'idempotency_conflict' => CheckoutRemoteStatus.idempotencyConflict,
  'not_found' => CheckoutRemoteStatus.notFound,
  _ => throw const FormatException('checkout_status'),
};

CheckoutQuoteStatus _quoteStatus(String value) => switch (value) {
  'quoted' => CheckoutQuoteStatus.quoted,
  'requires_review' => CheckoutQuoteStatus.requiresReview,
  'confirmed' => CheckoutQuoteStatus.confirmed,
  'expired' => CheckoutQuoteStatus.expired,
  'invalidated' => CheckoutQuoteStatus.invalidated,
  'consumed' => CheckoutQuoteStatus.consumed,
  _ => throw const FormatException('checkout_quote_status'),
};

void _validateSelection(CheckoutSelection selection) {
  if (selection.mode == null || selection.slotId == null) {
    throw const CheckoutRepositoryException(CheckoutFailureKind.invalidInput);
  }
  _requireUuid(selection.slotId!);
  if (selection.mode == CheckoutFulfillmentMode.delivery) {
    if (selection.addressId == null || selection.pickupPointId != null) {
      throw const CheckoutRepositoryException(CheckoutFailureKind.invalidInput);
    }
    _requireUuid(selection.addressId!);
  } else {
    if (selection.pickupPointId == null || selection.addressId != null) {
      throw const CheckoutRepositoryException(CheckoutFailureKind.invalidInput);
    }
    _requireUuid(selection.pickupPointId!);
  }
}

void _requireUnique(Iterable<String> values, String error) {
  final list = values.toList(growable: false);
  if (list.toSet().length != list.length) throw FormatException(error);
}

void _requireShopSlug(String value) {
  if (!RegExp(r'^[a-z0-9][a-z0-9-]{2,62}$').hasMatch(value)) {
    throw const CheckoutRepositoryException(CheckoutFailureKind.invalidInput);
  }
}

void _requirePayloadShopSlug(String value) {
  if (!RegExp(r'^[a-z0-9][a-z0-9-]{2,62}$').hasMatch(value)) {
    throw const FormatException('checkout_shop_slug');
  }
}

void _requireUuid(String value) {
  if (!_uuidPattern.hasMatch(value)) {
    throw const CheckoutRepositoryException(CheckoutFailureKind.invalidInput);
  }
}

void _requirePayloadUuid(String value) {
  if (!_uuidPattern.hasMatch(value)) {
    throw const FormatException('checkout_uuid');
  }
}

void _requireVersion(int value, {bool allowZero = false}) {
  if (value < (allowZero ? 0 : 1)) {
    throw const CheckoutRepositoryException(CheckoutFailureKind.invalidInput);
  }
}

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

CheckoutFailureKind _postgrestFailure(String? code) => switch (code) {
  '401' || '403' || '28000' || 'PGRST301' => CheckoutFailureKind.unauthorized,
  '57014' => CheckoutFailureKind.timeout,
  '23505' || '40001' || '40P01' => CheckoutFailureKind.conflict,
  _ => CheckoutFailureKind.unexpected,
};
