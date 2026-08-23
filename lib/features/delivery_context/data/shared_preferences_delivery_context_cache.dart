import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/delivery_context_cache.dart';
import '../domain/delivery_context_models.dart';

final class SharedPreferencesDeliveryContextCache
    implements DeliveryContextCacheStore {
  static const _prefix = 'customer_delivery_context_v1';

  @override
  Future<CustomerDeliveryContext?> read({
    required String ownerSubjectId,
    required String shopSlug,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(ownerSubjectId, shopSlug));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = decoded.map((key, value) => MapEntry(key.toString(), value));
      if (map['ownerSubjectId'] != ownerSubjectId ||
          map['shopSlug'] != shopSlug) {
        return null;
      }
      final mode = switch (map['mode']) {
        'delivery' => CustomerDeliveryMode.delivery,
        'pickup' => CustomerDeliveryMode.pickup,
        _ => null,
      };
      final status = switch (map['serviceabilityStatus']) {
        'serviceable' => DeliveryServiceabilityStatus.serviceable,
        'unsupported' => DeliveryServiceabilityStatus.unsupported,
        'invalid' => DeliveryServiceabilityStatus.invalid,
        'temporarilyUnavailable' =>
          DeliveryServiceabilityStatus.temporarilyUnavailable,
        _ => null,
      };
      if (mode == null || status == null) return null;
      return CustomerDeliveryContext(
        ownerUserId: ownerSubjectId,
        shopSlug: shopSlug,
        mode: mode,
        addressId: map['addressId'] as String?,
        pickupPointId: map['pickupPointId'] as String?,
        pickupPointName: map['pickupPointName'] as String?,
        serviceabilityStatus: status,
        deliveryZoneId: map['deliveryZoneId'] as String?,
        deliveryZoneName: map['deliveryZoneName'] as String?,
        estimatedFeeClp: map['estimatedFeeClp'] as int?,
        earliestSlotStartsAt: _date(map['earliestSlotStartsAt']),
        earliestSlotEndsAt: _date(map['earliestSlotEndsAt']),
        version: map['version'] as int,
        selectedAt: _date(map['selectedAt'])!,
        serverTime: _date(map['serverTime'])!,
      );
    } on Object {
      await prefs.remove(_key(ownerSubjectId, shopSlug));
      return null;
    }
  }

  @override
  Future<void> write({
    required String ownerSubjectId,
    required CustomerDeliveryContext context,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(ownerSubjectId, context.shopSlug),
      jsonEncode({
        'ownerSubjectId': ownerSubjectId,
        'shopSlug': context.shopSlug,
        'mode': context.mode.name,
        'addressId': context.addressId,
        'pickupPointId': context.pickupPointId,
        'pickupPointName': context.pickupPointName,
        'serviceabilityStatus': context.serviceabilityStatus.name,
        'deliveryZoneId': context.deliveryZoneId,
        'deliveryZoneName': context.deliveryZoneName,
        'estimatedFeeClp': context.estimatedFeeClp,
        'earliestSlotStartsAt': context.earliestSlotStartsAt?.toIso8601String(),
        'earliestSlotEndsAt': context.earliestSlotEndsAt?.toIso8601String(),
        'version': context.version,
        'selectedAt': context.selectedAt.toIso8601String(),
        'serverTime': context.serverTime.toIso8601String(),
      }),
    );
  }

  @override
  Future<void> remove({
    required String ownerSubjectId,
    required String shopSlug,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(ownerSubjectId, shopSlug));
  }

  static String _key(String ownerSubjectId, String shopSlug) =>
      '$_prefix:$ownerSubjectId:$shopSlug';

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
}
