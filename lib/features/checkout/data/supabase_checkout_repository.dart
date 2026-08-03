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
  Future<StorefrontPaymentOptions> loadPaymentOptions({
    required String shopSlug,
  }) {
    return _guard(() async {
      _requireShopSlug(shopSlug);
      return _parsePaymentOptions(
        await port.invoke('storefront_payment_options_v1', {
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

  @override
  Future<CheckoutOrderRemoteResponse> createOrder({
    required String quoteId,
    required int expectedQuoteVersion,
    required CheckoutPaymentMethod paymentMethod,
    required String idempotencyKey,
  }) {
    return _guard(() async {
      _requireUuid(quoteId);
      _requireVersion(expectedQuoteVersion);
      _requireUuid(idempotencyKey);
      return _parseOrderResponse(
        await port.invoke('customer_order_create_v2', {
          'p_quote_id': quoteId,
          'p_expected_quote_version': expectedQuoteVersion,
          'p_payment_method': _paymentMethodName(paymentMethod),
          'p_idempotency_key': idempotencyKey,
        }),
      );
    });
  }

  @override
  Future<CheckoutOrderRemoteResponse> readOrder({required String orderId}) {
    return _guard(() async {
      _requireUuid(orderId);
      return _parseOrderResponse(
        await port.invoke('customer_order_read_v2', {'p_order_id': orderId}),
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

const _paymentOptionsRootKeys = <String>{
  'apiVersion',
  'status',
  'shopSlug',
  'currencyCode',
  'methods',
  'onlineConfiguration',
  'serverTime',
};

StorefrontPaymentOptions _parsePaymentOptions(
  Object? raw, {
  required String expectedShopSlug,
}) {
  final payload = _payload(raw, _paymentOptionsRootKeys, 'payment_options');
  if (payload['apiVersion'] != 'storefront-payment-options.v1') {
    throw const FormatException('payment_options_version');
  }
  final status = switch (_requiredString(payload, 'status')) {
    'ok' => PaymentOptionsStatus.ok,
    'unavailable' => PaymentOptionsStatus.unavailable,
    'invalid' => PaymentOptionsStatus.invalid,
    _ => throw const FormatException('payment_options_status'),
  };
  final serverTime = _requiredDate(payload, 'serverTime');
  if (status != PaymentOptionsStatus.ok) {
    if (payload.keys.any(
      (key) => key != 'apiVersion' && key != 'status' && key != 'serverTime',
    )) {
      throw const FormatException('payment_options_minimal');
    }
    return StorefrontPaymentOptions.unavailable(
      status: status,
      serverTime: serverTime,
    );
  }
  if (!payload.keys.toSet().containsAll(_paymentOptionsRootKeys) ||
      _requiredString(payload, 'shopSlug') != expectedShopSlug ||
      payload['currencyCode'] != 'CLP' ||
      payload['onlineConfiguration'] != 'not_configured') {
    throw const FormatException('payment_options_identity');
  }
  final methods = _list(
    payload,
    'methods',
    maximum: 3,
  ).map(_parsePaymentOption).toList(growable: false);
  if (methods.length != 3 ||
      methods.map((option) => option.method).toSet().length != 3) {
    throw const FormatException('payment_options_methods');
  }
  for (final option in methods) {
    final actual = option.fulfillmentModes.toSet();
    final expected = switch (option.method) {
      CheckoutPaymentMethod.payAtPickup => const {
        CheckoutFulfillmentMode.pickup,
        CheckoutFulfillmentMode.reservation,
      },
      CheckoutPaymentMethod.cashOnDelivery => const {
        CheckoutFulfillmentMode.delivery,
      },
      CheckoutPaymentMethod.onlinePayment => const <CheckoutFulfillmentMode>{},
    };
    if (actual.length != option.fulfillmentModes.length ||
        actual.length != expected.length ||
        !actual.containsAll(expected) ||
        (option.method == CheckoutPaymentMethod.onlinePayment &&
            option.enabled)) {
      throw const FormatException('payment_options_compatibility');
    }
  }
  return StorefrontPaymentOptions(
    status: status,
    shopSlug: expectedShopSlug,
    currencyCode: 'CLP',
    methods: methods,
    onlineConfiguration: OnlinePaymentConfiguration.notConfigured,
    serverTime: serverTime,
  );
}

CheckoutPaymentOption _parsePaymentOption(Object? raw) {
  final map = _strictMap(raw, const {
    'method',
    'enabled',
    'fulfillmentModes',
  }, 'payment_option');
  final enabled = map['enabled'];
  if (enabled is! bool) throw const FormatException('payment_option_enabled');
  final modes = _list(map, 'fulfillmentModes', maximum: 3)
      .map((value) {
        if (value is! String) {
          throw const FormatException('payment_option_mode');
        }
        return _mode(value);
      })
      .toList(growable: false);
  return CheckoutPaymentOption(
    method: _paymentMethod(_requiredString(map, 'method')),
    enabled: enabled,
    fulfillmentModes: modes,
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

const _orderRootKeys = <String>{
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
  'payment',
  'placedAt',
  'serverTime',
};

CheckoutOrderRemoteResponse _parseOrderResponse(Object? raw) {
  final payload = _payload(raw, _orderRootKeys, 'checkout_order_response');
  if (payload['apiVersion'] != 'customer-order.v2') {
    throw const FormatException('checkout_order_response_version');
  }
  final status = _orderRemoteStatus(_requiredString(payload, 'status'));
  final idempotent = payload['idempotent'];
  if (idempotent is! bool) {
    throw const FormatException('checkout_order_response_idempotent');
  }
  final serverTime = _requiredDate(payload, 'serverTime');
  final orderId = _optionalUuid(payload, 'orderId');
  if (!payload.containsKey('orderVersion')) {
    const minimalKeys = {
      'apiVersion',
      'status',
      'idempotent',
      'orderId',
      'serverTime',
    };
    if (status == CheckoutOrderRemoteStatus.ok ||
        payload.keys.any((key) => !minimalKeys.contains(key))) {
      throw const FormatException('checkout_order_response_minimal');
    }
    return CheckoutOrderRemoteResponse(
      status: status,
      idempotent: idempotent,
      serverTime: serverTime,
      orderId: orderId,
    );
  }
  if (status != CheckoutOrderRemoteStatus.ok || orderId == null) {
    throw const FormatException('checkout_order_response_status');
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
    'payment',
    'placedAt',
    'serverTime',
  };
  if (!payload.keys.toSet().containsAll(required) ||
      payload['currencyCode'] != 'CLP') {
    throw const FormatException('checkout_order_required');
  }
  final code = _requiredString(payload, 'orderCode');
  if (!RegExp(r'^MC-[0-9A-F]{20}$').hasMatch(code)) {
    throw const FormatException('checkout_order_code');
  }
  final version = _requiredInt(payload, 'orderVersion');
  if (version < 1) throw const FormatException('checkout_order_version');
  final shopSlug = _requiredString(payload, 'shopSlug');
  _requirePayloadShopSlug(shopSlug);
  final mode = _mode(_requiredString(payload, 'fulfillmentMode'));
  _validateOrderFulfillment(payload['fulfillment'], mode);
  final subtotal = _amount(payload, 'subtotalClp');
  final fee = _amount(payload, 'deliveryFeeClp');
  final total = _amount(payload, 'totalClp');
  if (total != subtotal + fee ||
      (mode != CheckoutFulfillmentMode.delivery && fee != 0)) {
    throw const FormatException('checkout_order_total');
  }
  final items = _list(
    payload,
    'items',
    maximum: checkoutMaximumItems,
  ).map(_parseOrderItem).toList(growable: false);
  if (items.isEmpty ||
      items.fold<int>(0, (sum, item) => sum + item.lineTotalClp) != subtotal) {
    throw const FormatException('checkout_order_items_total');
  }
  _requireUnique(
    items.map((item) => item.publicationId),
    'checkout_order_items',
  );
  final payment = _parsePayment(payload['payment']);
  if (payment.amountClp != total || payment.currencyCode != 'CLP') {
    throw const FormatException('checkout_order_payment_total');
  }
  final placedAt = _requiredDate(payload, 'placedAt');
  if (placedAt.isAfter(serverTime.add(const Duration(minutes: 1)))) {
    throw const FormatException('checkout_order_timing');
  }
  final order = CheckoutOrder(
    id: orderId,
    code: code,
    status: _orderStatus(_requiredString(payload, 'orderStatus')),
    version: version,
    shopSlug: shopSlug,
    fulfillmentMode: mode,
    subtotalClp: subtotal,
    deliveryFeeClp: fee,
    totalClp: total,
    items: items,
    payment: payment,
    placedAt: placedAt,
    serverTime: serverTime,
    idempotent: idempotent,
  );
  return CheckoutOrderRemoteResponse(
    status: status,
    idempotent: idempotent,
    serverTime: serverTime,
    order: order,
    orderId: orderId,
  );
}

CheckoutPayment _parsePayment(Object? raw) {
  final map = _payload(raw, const {
    'method',
    'status',
    'amountClp',
    'currencyCode',
    'version',
    'failureCode',
    'createdAt',
    'updatedAt',
  }, 'checkout_payment');
  const required = {
    'method',
    'status',
    'amountClp',
    'currencyCode',
    'version',
    'createdAt',
    'updatedAt',
  };
  if (!map.keys.toSet().containsAll(required) || map['currencyCode'] != 'CLP') {
    throw const FormatException('checkout_payment_required');
  }
  final version = _requiredInt(map, 'version');
  if (version < 1) throw const FormatException('checkout_payment_version');
  final failureCode = _safeOptionalText(map, 'failureCode', 80);
  if (failureCode != null && !RegExp(r'^[a-z0-9_]+$').hasMatch(failureCode)) {
    throw const FormatException('checkout_payment_failure');
  }
  final createdAt = _requiredDate(map, 'createdAt');
  final updatedAt = _requiredDate(map, 'updatedAt');
  if (updatedAt.isBefore(createdAt)) {
    throw const FormatException('checkout_payment_timing');
  }
  return CheckoutPayment(
    method: _paymentMethod(_requiredString(map, 'method')),
    status: _paymentStatus(_requiredString(map, 'status')),
    amountClp: _amount(map, 'amountClp'),
    currencyCode: 'CLP',
    version: version,
    failureCode: failureCode,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

CheckoutQuoteItem _parseOrderItem(Object? raw) {
  final map = _payload(raw, const {
    'publicationId',
    'publicName',
    'quantity',
    'unitPriceClp',
    'compareAtPriceClp',
    'lineTotalClp',
    'promotionName',
    'promotionEndsAt',
  }, 'checkout_order_item');
  const required = {
    'publicationId',
    'publicName',
    'quantity',
    'unitPriceClp',
    'lineTotalClp',
  };
  if (!map.keys.toSet().containsAll(required)) {
    throw const FormatException('checkout_order_item_required');
  }
  final publicationId = _requiredString(map, 'publicationId');
  _requirePayloadUuid(publicationId);
  final quantity = _requiredInt(map, 'quantity');
  final unitPrice = _amount(map, 'unitPriceClp');
  final lineTotal = _amount(map, 'lineTotalClp');
  if (quantity < 1 || quantity > 99 || lineTotal != unitPrice * quantity) {
    throw const FormatException('checkout_order_item_total');
  }
  return CheckoutQuoteItem(
    publicationId: publicationId,
    publicName: _safeRequiredText(map, 'publicName', 200),
    quantity: quantity,
    unitPriceClp: unitPrice,
    compareAtPriceClp: _optionalAmount(map, 'compareAtPriceClp'),
    lineTotalClp: lineTotal,
    promotionName: _safeOptionalText(map, 'promotionName', 160),
    promotionEndsAt: _optionalDate(map, 'promotionEndsAt'),
  );
}

void _validateOrderFulfillment(
  Object? raw,
  CheckoutFulfillmentMode expectedMode,
) {
  final map = _payload(raw, const {
    'mode',
    'address',
    'pickupPoint',
    'deliveryZone',
    'slot',
  }, 'checkout_order_fulfillment');
  if (_mode(_requiredString(map, 'mode')) != expectedMode ||
      !map.containsKey('slot')) {
    throw const FormatException('checkout_order_fulfillment_mode');
  }
  final slot = _payload(map['slot'], const {
    'id',
    'label',
    'startsAt',
    'endsAt',
  }, 'checkout_order_slot');
  if (!slot.keys.toSet().containsAll(const {
    'id',
    'label',
    'startsAt',
    'endsAt',
  })) {
    throw const FormatException('checkout_order_slot_required');
  }
  _requirePayloadUuid(_requiredString(slot, 'id'));
  _safeRequiredText(slot, 'label', 120);
  final startsAt = _requiredDate(slot, 'startsAt');
  final endsAt = _requiredDate(slot, 'endsAt');
  if (!endsAt.isAfter(startsAt)) {
    throw const FormatException('checkout_order_slot_timing');
  }
  if (map['pickupPoint'] case final Object pointRaw) {
    final point = _payload(pointRaw, const {
      'id',
      'name',
      'addressLine1',
      'addressLine2',
      'commune',
      'region',
      'instructions',
    }, 'checkout_order_pickup');
    _requirePayloadUuid(_requiredString(point, 'id'));
    _safeRequiredText(point, 'name', 120);
    _safeRequiredText(point, 'addressLine1', 200);
    _safeRequiredText(point, 'commune', 100);
    _safeRequiredText(point, 'region', 100);
    _safeOptionalText(point, 'addressLine2', 200);
    _safeOptionalText(point, 'instructions', 500);
  }
  if (map['deliveryZone'] case final Object zoneRaw) {
    final zone = _payload(zoneRaw, const {
      'id',
      'name',
      'region',
      'feeClp',
    }, 'checkout_order_zone');
    _requirePayloadUuid(_requiredString(zone, 'id'));
    _safeRequiredText(zone, 'name', 120);
    _safeRequiredText(zone, 'region', 100);
    _amount(zone, 'feeClp');
  }
  if (map['address'] case final Object addressRaw) {
    final address = _payload(addressRaw, const {
      'addressId',
      'recipientName',
      'addressLine1',
      'addressLine2',
      'commune',
      'region',
      'postalCode',
      'countryCode',
      'deliveryInstructions',
    }, 'checkout_order_address');
    _requirePayloadUuid(_requiredString(address, 'addressId'));
    _safeRequiredText(address, 'recipientName', 160);
    _safeRequiredText(address, 'addressLine1', 200);
    _safeRequiredText(address, 'commune', 100);
    _safeRequiredText(address, 'region', 100);
    _safeRequiredText(address, 'countryCode', 2);
    _safeOptionalText(address, 'addressLine2', 200);
    _safeOptionalText(address, 'postalCode', 32);
    _safeOptionalText(address, 'deliveryInstructions', 500);
  }
  final hasPickup = map.containsKey('pickupPoint');
  final hasZone = map.containsKey('deliveryZone');
  final hasAddress = map.containsKey('address');
  if (expectedMode == CheckoutFulfillmentMode.delivery
      ? !hasZone || !hasAddress || hasPickup
      : !hasPickup || hasZone || hasAddress) {
    throw const FormatException('checkout_order_fulfillment_shape');
  }
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

CheckoutPaymentMethod _paymentMethod(String value) => switch (value) {
  'pay_at_pickup' => CheckoutPaymentMethod.payAtPickup,
  'cash_on_delivery' => CheckoutPaymentMethod.cashOnDelivery,
  'online_payment' => CheckoutPaymentMethod.onlinePayment,
  _ => throw const FormatException('checkout_payment_method'),
};

String _paymentMethodName(CheckoutPaymentMethod method) => switch (method) {
  CheckoutPaymentMethod.payAtPickup => 'pay_at_pickup',
  CheckoutPaymentMethod.cashOnDelivery => 'cash_on_delivery',
  CheckoutPaymentMethod.onlinePayment => 'online_payment',
};

CheckoutPaymentStatus _paymentStatus(String value) => switch (value) {
  'due_at_fulfillment' => CheckoutPaymentStatus.dueAtFulfillment,
  'pending_provider' => CheckoutPaymentStatus.pendingProvider,
  'processing' => CheckoutPaymentStatus.processing,
  'authorized' => CheckoutPaymentStatus.authorized,
  'collected' => CheckoutPaymentStatus.collected,
  'failed' => CheckoutPaymentStatus.failed,
  'cancelled' => CheckoutPaymentStatus.cancelled,
  'refund_pending' => CheckoutPaymentStatus.refundPending,
  'refund_failed' => CheckoutPaymentStatus.refundFailed,
  'refunded' => CheckoutPaymentStatus.refunded,
  _ => throw const FormatException('checkout_payment_status'),
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

CheckoutOrderRemoteStatus _orderRemoteStatus(String value) => switch (value) {
  'ok' => CheckoutOrderRemoteStatus.ok,
  'requires_review' => CheckoutOrderRemoteStatus.requiresReview,
  'expired' => CheckoutOrderRemoteStatus.expired,
  'invalidated' => CheckoutOrderRemoteStatus.invalidated,
  'quote_not_confirmed' => CheckoutOrderRemoteStatus.quoteNotConfirmed,
  'quote_version_conflict' => CheckoutOrderRemoteStatus.quoteVersionConflict,
  'cart_version_conflict' => CheckoutOrderRemoteStatus.cartVersionConflict,
  'cart_empty' => CheckoutOrderRemoteStatus.cartEmpty,
  'mode_unavailable' => CheckoutOrderRemoteStatus.modeUnavailable,
  'slot_unavailable' => CheckoutOrderRemoteStatus.slotUnavailable,
  'invalid_selection' => CheckoutOrderRemoteStatus.invalidSelection,
  'pickup_unavailable' => CheckoutOrderRemoteStatus.pickupUnavailable,
  'delivery_unavailable' => CheckoutOrderRemoteStatus.deliveryUnavailable,
  'invalid_address' => CheckoutOrderRemoteStatus.invalidAddress,
  'unsupported_zone' => CheckoutOrderRemoteStatus.unsupportedZone,
  'cart_unavailable' => CheckoutOrderRemoteStatus.cartUnavailable,
  'idempotency_conflict' => CheckoutOrderRemoteStatus.idempotencyConflict,
  'payment_method_unavailable' =>
    CheckoutOrderRemoteStatus.paymentMethodUnavailable,
  'payment_method_conflict' => CheckoutOrderRemoteStatus.paymentMethodConflict,
  'online_payment_unavailable' =>
    CheckoutOrderRemoteStatus.onlinePaymentUnavailable,
  'not_found' => CheckoutOrderRemoteStatus.notFound,
  'invariant_error' => CheckoutOrderRemoteStatus.invariantError,
  'invalid' => CheckoutOrderRemoteStatus.invalid,
  'unavailable' => CheckoutOrderRemoteStatus.unavailable,
  _ => throw const FormatException('checkout_order_status'),
};

CheckoutOrderStatus _orderStatus(String value) => switch (value) {
  'confirmed' => CheckoutOrderStatus.confirmed,
  'accepted' => CheckoutOrderStatus.accepted,
  'rejected' => CheckoutOrderStatus.rejected,
  'preparing' => CheckoutOrderStatus.preparing,
  'ready' => CheckoutOrderStatus.ready,
  'out_for_delivery' => CheckoutOrderStatus.outForDelivery,
  'completed' => CheckoutOrderStatus.completed,
  'cancelled' => CheckoutOrderStatus.cancelled,
  _ => throw const FormatException('checkout_order_state'),
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
