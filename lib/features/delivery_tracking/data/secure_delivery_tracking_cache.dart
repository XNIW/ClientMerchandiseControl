import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/delivery_tracking_models.dart';
import '../domain/delivery_tracking_repository.dart';
import 'supabase_delivery_tracking_repository.dart';

abstract interface class DeliveryTrackingSecurePreferences {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

final class PlatformDeliveryTrackingSecurePreferences
    implements DeliveryTrackingSecurePreferences {
  PlatformDeliveryTrackingSecurePreferences([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

final class SecureDeliveryTrackingCache implements DeliveryTrackingCacheStore {
  SecureDeliveryTrackingCache({
    DeliveryTrackingSecurePreferences? preferences,
    DateTime Function()? clock,
  }) : _preferences =
           preferences ?? PlatformDeliveryTrackingSecurePreferences(),
       _clock = clock ?? (() => DateTime.now().toUtc());

  static const storageKey = 'cmc.delivery-tracking-cache.v1';
  static const maximumEncodedBytes = 32768;
  static const maximumRetention = Duration(minutes: 15);

  final DeliveryTrackingSecurePreferences _preferences;
  final DateTime Function() _clock;
  Future<void> _tail = Future<void>.value();

  @override
  Future<DeliveryTrackingSnapshot?> read({
    required String ownerSubjectId,
    required String shopSlug,
    required String orderId,
  }) {
    return _serialized(() async {
      final encoded = await _preferences.read(storageKey);
      if (encoded == null) return null;
      try {
        if (utf8.encode(encoded).length > maximumEncodedBytes) {
          throw const FormatException('delivery_tracking_cache_size');
        }
        final root = jsonDecode(encoded);
        if (root is! Map) throw const FormatException('delivery_cache_root');
        final map = root.map((key, value) => MapEntry(key.toString(), value));
        if (map.keys.toSet().difference(const {
              'version',
              'ownerSubjectId',
              'shopSlug',
              'orderId',
              'cachedAt',
              'snapshot',
            }).isNotEmpty ||
            map['version'] != 1 ||
            map['ownerSubjectId'] != ownerSubjectId ||
            map['shopSlug'] != shopSlug ||
            map['orderId'] != orderId) {
          throw const FormatException('delivery_cache_identity');
        }
        final cachedAt = DateTime.tryParse(map['cachedAt']?.toString() ?? '');
        if (cachedAt == null ||
            _clock().difference(cachedAt.toUtc()) > maximumRetention ||
            cachedAt.toUtc().isAfter(
              _clock().add(const Duration(seconds: 30)),
            )) {
          throw const FormatException('delivery_cache_expired');
        }
        final snapshot = parseDeliveryTrackingSnapshot(map['snapshot']);
        if (snapshot.orderId != orderId) {
          throw const FormatException('delivery_cache_order');
        }
        return snapshot;
      } on Object {
        await _preferences.delete(storageKey);
        return null;
      }
    });
  }

  @override
  Future<void> save({
    required String ownerSubjectId,
    required String shopSlug,
    required DeliveryTrackingSnapshot snapshot,
  }) {
    return _serialized(() async {
      final encoded = jsonEncode({
        'version': 1,
        'ownerSubjectId': ownerSubjectId,
        'shopSlug': shopSlug,
        'orderId': snapshot.orderId,
        'cachedAt': _clock().toIso8601String(),
        'snapshot': _snapshotMap(snapshot),
      });
      if (utf8.encode(encoded).length > maximumEncodedBytes) {
        throw const FormatException('delivery_tracking_cache_size');
      }
      await _preferences.write(storageKey, encoded);
    });
  }

  @override
  Future<void> clear({required String ownerSubjectId}) {
    return _serialized(() => _preferences.delete(storageKey));
  }

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final next = _tail.then((_) => operation());
    _tail = next.then<void>((_) {}, onError: (_, _) {});
    return next;
  }
}

Map<String, Object?> _snapshotMap(DeliveryTrackingSnapshot snapshot) => {
  'apiVersion': 'delivery-tracking-snapshot.v1',
  'orderId': snapshot.orderId,
  'orderStatus': snapshot.orderStatus,
  'orderStatusVersion': snapshot.orderStatusVersion,
  'fulfillmentMode': snapshot.fulfillmentMode,
  'trackingMode': snapshot.trackingMode.name,
  'trackingSessionId': snapshot.trackingSessionId,
  'trackingState': switch (snapshot.trackingState) {
    DeliveryTrackingState.awaitingAssignment => 'awaiting_assignment',
    _ => snapshot.trackingState.name,
  },
  'courierPublicLabel': snapshot.courierPublicLabel,
  'vehicleKind': snapshot.vehicleKind?.name,
  'latitude': snapshot.courierCoordinate?.latitude,
  'longitude': snapshot.courierCoordinate?.longitude,
  'horizontalAccuracyMeters': snapshot.horizontalAccuracyMeters,
  'bearingDegrees': snapshot.bearingDegrees,
  'speedMetersPerSecond': snapshot.speedMetersPerSecond,
  'observedAt': snapshot.observedAt?.toIso8601String(),
  'receivedAt': snapshot.receivedAt?.toIso8601String(),
  'freshness': snapshot.freshness.name,
  'etaStartsAt': snapshot.etaStartsAt?.toIso8601String(),
  'etaEndsAt': snapshot.etaEndsAt?.toIso8601String(),
  'destinationLatitude': snapshot.destinationCoordinate?.latitude,
  'destinationLongitude': snapshot.destinationCoordinate?.longitude,
  'storeLatitude': snapshot.storeCoordinate?.latitude,
  'storeLongitude': snapshot.storeCoordinate?.longitude,
  'externalCarrier': snapshot.externalCarrier,
  'externalTrackingCodeMasked': snapshot.externalTrackingCodeMasked,
  'externalTrackingUrl': snapshot.externalTrackingUrl?.toString(),
  'contactCapability': switch (snapshot.contactCapability) {
    DeliveryContactCapability.none => 'none',
    DeliveryContactCapability.storePhone => 'store_phone',
    DeliveryContactCapability.storeSupportUrl => 'store_support_url',
  },
  'serverTime': snapshot.serverTime.toIso8601String(),
  'version': snapshot.version,
};
