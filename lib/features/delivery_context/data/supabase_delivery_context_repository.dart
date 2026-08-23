import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/delivery_context_models.dart';
import '../domain/delivery_context_repository.dart';

abstract interface class DeliveryContextPort {
  Future<Object?> invoke(String function, Map<String, Object?> parameters);
}

final class PlatformDeliveryContextPort implements DeliveryContextPort {
  PlatformDeliveryContextPort(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> invoke(String function, Map<String, Object?> parameters) =>
      _client.rpc(function, params: parameters);
}

final class SupabaseDeliveryContextRepository
    implements DeliveryContextRepository {
  SupabaseDeliveryContextRepository({
    required this.port,
    this.requestTimeout = const Duration(seconds: 12),
  });

  final DeliveryContextPort port;
  final Duration requestTimeout;

  @override
  Future<CustomerDeliveryContext?> read({required String shopSlug}) {
    return _guard(() async {
      _requireShopSlug(shopSlug);
      final payload = _map(
        await port.invoke('customer_delivery_context_read_v1', {
          'p_shop_slug': shopSlug,
        }),
      );
      _requireVersion(payload);
      if (payload['status'] == 'not_found') return null;
      if (payload['status'] != 'ok') {
        throw const DeliveryContextRepositoryException(
          DeliveryContextFailureKind.unavailable,
        );
      }
      return _parse(payload, expectedShopSlug: shopSlug, fallbackMode: null);
    });
  }

  @override
  Future<CustomerDeliveryContext> preview({
    required String shopSlug,
    required CustomerDeliveryMode mode,
    String? addressId,
    String? pickupPointId,
    String? commune,
  }) {
    return _guard(() async {
      _validateShape(
        shopSlug: shopSlug,
        mode: mode,
        addressId: addressId,
        pickupPointId: pickupPointId,
        commune: commune,
        allowCommune: true,
      );
      final payload = _map(
        await port.invoke('storefront_delivery_context_preview_v1', {
          'p_shop_slug': shopSlug,
          'p_mode': mode.name,
          'p_address_id': addressId,
          'p_pickup_point_id': pickupPointId,
          'p_commune': commune,
        }),
      );
      if (payload['apiVersion'] != 'storefront-delivery-context.v1') {
        throw const FormatException('delivery_context_preview_version');
      }
      return _parse(payload, expectedShopSlug: shopSlug, fallbackMode: mode);
    });
  }

  @override
  Future<CustomerDeliveryContext> select({
    required String shopSlug,
    required CustomerDeliveryMode mode,
    required int expectedVersion,
    String? addressId,
    String? pickupPointId,
  }) {
    return _guard(() async {
      _validateShape(
        shopSlug: shopSlug,
        mode: mode,
        addressId: addressId,
        pickupPointId: pickupPointId,
      );
      if (expectedVersion < 0) {
        throw const DeliveryContextRepositoryException(
          DeliveryContextFailureKind.invalid,
        );
      }
      final payload = _map(
        await port.invoke('customer_delivery_context_select_v1', {
          'p_shop_slug': shopSlug,
          'p_mode': mode.name,
          'p_address_id': addressId,
          'p_pickup_point_id': pickupPointId,
          'p_expected_version': expectedVersion,
        }),
      );
      _requireVersion(payload);
      if (payload['status'] == 'version_conflict') {
        throw const DeliveryContextRepositoryException(
          DeliveryContextFailureKind.conflict,
        );
      }
      return _parse(payload, expectedShopSlug: shopSlug, fallbackMode: mode);
    });
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation().timeout(requestTimeout);
    } on DeliveryContextRepositoryException {
      rethrow;
    } on TimeoutException {
      throw const DeliveryContextRepositoryException(
        DeliveryContextFailureKind.timeout,
      );
    } on SocketException {
      throw const DeliveryContextRepositoryException(
        DeliveryContextFailureKind.offline,
      );
    } on AuthException {
      throw const DeliveryContextRepositoryException(
        DeliveryContextFailureKind.unauthorized,
      );
    } on PostgrestException catch (error) {
      throw DeliveryContextRepositoryException(switch (error.code) {
        '28000' ||
        '42501' ||
        'PGRST301' => DeliveryContextFailureKind.unauthorized,
        '22023' || '23514' => DeliveryContextFailureKind.invalid,
        '40001' => DeliveryContextFailureKind.conflict,
        _ => DeliveryContextFailureKind.unavailable,
      });
    } on FormatException {
      throw const DeliveryContextRepositoryException(
        DeliveryContextFailureKind.unexpected,
      );
    } on Object {
      throw const DeliveryContextRepositoryException(
        DeliveryContextFailureKind.unexpected,
      );
    }
  }
}

CustomerDeliveryContext _parse(
  Map<String, Object?> payload, {
  required String expectedShopSlug,
  required CustomerDeliveryMode? fallbackMode,
}) {
  final status = _serviceability(payload['serviceabilityStatus']);
  final serverTime = _date(payload, 'serverTime');
  final shopSlug = payload['shopSlug'] == null
      ? expectedShopSlug
      : _string(payload, 'shopSlug');
  if (shopSlug != expectedShopSlug) throw const FormatException('shop_scope');
  final mode = payload['mode'] == null
      ? fallbackMode
      : _mode(_string(payload, 'mode'));
  if (mode == null || (fallbackMode != null && mode != fallbackMode)) {
    throw const FormatException('delivery_mode');
  }
  final addressId = _optionalString(payload, 'addressId');
  final pickupPointId = _optionalString(payload, 'pickupPointId');
  if (addressId != null) _requireUuid(addressId);
  if (pickupPointId != null) _requireUuid(pickupPointId);
  final contextVersion = payload['contextVersion'] ?? payload['version'] ?? 0;
  if (contextVersion is! int || contextVersion < 0) {
    throw const FormatException('context_version');
  }
  final fee = payload['estimatedFeeClp'];
  if (fee != null && (fee is! int || fee < 0 || fee > 999999999999)) {
    throw const FormatException('delivery_fee');
  }
  return CustomerDeliveryContext(
    ownerUserId: _optionalString(payload, 'ownerUserId'),
    shopSlug: shopSlug,
    mode: mode,
    addressId: addressId,
    pickupPointId: pickupPointId,
    pickupPointName: _safeOptional(payload, 'pickupPointName', 120),
    serviceabilityStatus: status,
    deliveryZoneId: _optionalUuid(payload, 'deliveryZoneId'),
    deliveryZoneName: _safeOptional(payload, 'deliveryZoneName', 120),
    estimatedFeeClp: fee as int?,
    earliestSlotStartsAt: _optionalDate(payload, 'earliestSlotStartsAt'),
    earliestSlotEndsAt: _optionalDate(payload, 'earliestSlotEndsAt'),
    version: contextVersion,
    selectedAt: _optionalDate(payload, 'selectedAt') ?? serverTime,
    serverTime: serverTime,
  );
}

DeliveryServiceabilityStatus _serviceability(Object? value) => switch (value) {
  'serviceable' => DeliveryServiceabilityStatus.serviceable,
  'unsupported' => DeliveryServiceabilityStatus.unsupported,
  'invalid' => DeliveryServiceabilityStatus.invalid,
  'temporarilyUnavailable' =>
    DeliveryServiceabilityStatus.temporarilyUnavailable,
  _ => throw const FormatException('serviceability_status'),
};

CustomerDeliveryMode _mode(String value) => switch (value) {
  'delivery' => CustomerDeliveryMode.delivery,
  'pickup' => CustomerDeliveryMode.pickup,
  _ => throw const FormatException('delivery_mode'),
};

void _validateShape({
  required String shopSlug,
  required CustomerDeliveryMode mode,
  String? addressId,
  String? pickupPointId,
  String? commune,
  bool allowCommune = false,
}) {
  _requireShopSlug(shopSlug);
  if (mode == CustomerDeliveryMode.delivery) {
    if (pickupPointId != null ||
        (addressId == null && (!allowCommune || commune == null))) {
      throw const DeliveryContextRepositoryException(
        DeliveryContextFailureKind.invalid,
      );
    }
    if (addressId != null) _requireUuid(addressId);
    if (commune != null &&
        (commune.trim().isEmpty || commune.runes.length > 100)) {
      throw const DeliveryContextRepositoryException(
        DeliveryContextFailureKind.invalid,
      );
    }
    return;
  }
  if (addressId != null || pickupPointId == null || commune != null) {
    throw const DeliveryContextRepositoryException(
      DeliveryContextFailureKind.invalid,
    );
  }
  _requireUuid(pickupPointId);
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) throw const FormatException('delivery_context_object');
  return value.map((key, item) => MapEntry(key.toString(), item));
}

void _requireVersion(Map<String, Object?> payload) {
  if (payload['apiVersion'] != 'customer-delivery-context.v1') {
    throw const FormatException('delivery_context_version');
  }
}

String _string(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw const FormatException('delivery_context_string');
  }
  return value;
}

String? _optionalString(Map<String, Object?> payload, String key) =>
    payload[key] == null ? null : _string(payload, key);

String? _safeOptional(Map<String, Object?> payload, String key, int maxRunes) {
  final value = _optionalString(payload, key);
  if (value != null &&
      (value.runes.length > maxRunes ||
          value.runes.any((rune) => rune < 0x20))) {
    throw const FormatException('delivery_context_safe_text');
  }
  return value;
}

DateTime _date(Map<String, Object?> payload, String key) {
  final value = _string(payload, key);
  return DateTime.parse(value).toUtc();
}

DateTime? _optionalDate(Map<String, Object?> payload, String key) =>
    payload[key] == null ? null : _date(payload, key);

String? _optionalUuid(Map<String, Object?> payload, String key) {
  final value = _optionalString(payload, key);
  if (value != null) _requireUuid(value);
  return value;
}

void _requireShopSlug(String value) {
  if (!RegExp(r'^[a-z0-9][a-z0-9-]{2,62}$').hasMatch(value)) {
    throw const DeliveryContextRepositoryException(
      DeliveryContextFailureKind.invalid,
    );
  }
}

void _requireUuid(String value) {
  if (!RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value)) {
    throw const DeliveryContextRepositoryException(
      DeliveryContextFailureKind.invalid,
    );
  }
}
