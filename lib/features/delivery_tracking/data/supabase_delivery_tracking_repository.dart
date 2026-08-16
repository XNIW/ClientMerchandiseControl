import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/delivery_tracking_failure.dart';
import '../domain/delivery_tracking_models.dart';
import '../domain/delivery_tracking_repository.dart';

abstract interface class DeliveryTrackingPort {
  Future<Object?> invoke(String function, Map<String, Object?> parameters);

  Stream<Object?> watchOrder(String orderId);
}

final class PlatformDeliveryTrackingPort implements DeliveryTrackingPort {
  PlatformDeliveryTrackingPort(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> invoke(String function, Map<String, Object?> parameters) {
    return _client.rpc(function, params: parameters);
  }

  @override
  Stream<Object?> watchOrder(String orderId) {
    late final StreamController<Object?> controller;
    RealtimeChannel? channel;
    controller = StreamController<Object?>(
      onListen: () {
        channel =
            _client
                .channel('storefront-delivery-tracking:$orderId')
                .onPostgresChanges(
                  event: PostgresChangeEvent.all,
                  schema: 'public',
                  table: 'storefront_delivery_tracking_feed',
                  filter: PostgresChangeFilter(
                    type: PostgresChangeFilterType.eq,
                    column: 'order_id',
                    value: orderId,
                  ),
                  callback: (payload) {
                    if (payload.newRecord.isNotEmpty && !controller.isClosed) {
                      controller.add(payload.newRecord);
                    }
                  },
                )
              ..subscribe((status, error) {
                if ((status == RealtimeSubscribeStatus.channelError ||
                        status == RealtimeSubscribeStatus.timedOut) &&
                    !controller.isClosed) {
                  controller.addError(
                    const DeliveryTrackingRealtimeException(),
                  );
                }
              });
      },
      onCancel: () async {
        final active = channel;
        channel = null;
        if (active != null) await _client.removeChannel(active);
        if (!controller.isClosed) await controller.close();
      },
    );
    return controller.stream;
  }
}

final class DeliveryTrackingRealtimeException implements Exception {
  const DeliveryTrackingRealtimeException();
}

final class SupabaseDeliveryTrackingRepository
    implements DeliveryTrackingRepository {
  const SupabaseDeliveryTrackingRepository({
    required this.port,
    this.requestTimeout = const Duration(seconds: 8),
  });

  final DeliveryTrackingPort port;
  final Duration requestTimeout;

  @override
  Future<DeliveryTrackingSnapshot> load({
    required String shopSlug,
    required String orderId,
  }) {
    return _guard(() async {
      _requireShopSlug(shopSlug);
      _requireUuid(orderId);
      final raw = await port.invoke('storefront_order_tracking_v1', {
        'p_shop_slug': shopSlug,
        'p_order_id': orderId,
      });
      final root = _strictMap(raw, const {
        'ok',
        'code',
        'snapshot',
      }, 'delivery_tracking_root');
      if (root['ok'] != true || root['code'] != 'success') {
        if (root.keys.any((key) => !{'ok', 'code'}.contains(key))) {
          throw const FormatException('delivery_tracking_failure_shape');
        }
        throw DeliveryTrackingRepositoryException(_remoteFailure(root['code']));
      }
      final snapshot = parseDeliveryTrackingSnapshot(root['snapshot']);
      if (snapshot.orderId != orderId) {
        throw const FormatException('delivery_tracking_order_identity');
      }
      return snapshot;
    });
  }

  @override
  Stream<DeliveryTrackingSnapshot> watch({required String orderId}) {
    _requireUuid(orderId);
    return port.watchOrder(orderId).map((raw) {
      final record = _strictMap(raw, _realtimeKeys, 'delivery_tracking_feed');
      final snapshot = parseDeliveryTrackingSnapshot({
        'apiVersion': 'delivery-tracking-snapshot.v1',
        'orderId': record['order_id'],
        'orderStatus': record['order_status'],
        'orderStatusVersion': record['order_status_version'],
        'fulfillmentMode': record['fulfillment_mode'],
        'trackingMode': switch (record['tracking_mode']) {
          'status_only' => 'statusOnly',
          'external_carrier' => 'externalCarrier',
          'live_courier' => 'liveCourier',
          _ => record['tracking_mode'],
        },
        'trackingSessionId': record['tracking_session_id'],
        'trackingState': record['tracking_state'],
        'courierPublicLabel': record['courier_public_label'],
        'vehicleKind': record['vehicle_kind'],
        'latitude': record['latitude'],
        'longitude': record['longitude'],
        'horizontalAccuracyMeters': record['horizontal_accuracy_meters'],
        'bearingDegrees': record['bearing_degrees'],
        'speedMetersPerSecond': record['speed_meters_per_second'],
        'observedAt': record['observed_at'],
        'receivedAt': record['received_at'],
        'freshness': record['freshness'],
        'etaStartsAt': record['eta_starts_at'],
        'etaEndsAt': record['eta_ends_at'],
        'destinationLatitude': record['destination_latitude'],
        'destinationLongitude': record['destination_longitude'],
        'storeLatitude': record['store_latitude'],
        'storeLongitude': record['store_longitude'],
        'externalCarrier': record['external_carrier'],
        'externalTrackingCodeMasked': record['external_tracking_code_masked'],
        'externalTrackingUrl': record['external_tracking_url'],
        'contactCapability': record['contact_capability'],
        'serverTime': record['server_time'],
        'version': record['version'],
      });
      if (snapshot.orderId != orderId) {
        throw const FormatException('delivery_tracking_realtime_identity');
      }
      return snapshot;
    });
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation().timeout(requestTimeout);
    } on DeliveryTrackingRepositoryException {
      rethrow;
    } on TimeoutException {
      throw const DeliveryTrackingRepositoryException(
        DeliveryTrackingFailureKind.timeout,
      );
    } on SocketException {
      throw const DeliveryTrackingRepositoryException(
        DeliveryTrackingFailureKind.offline,
      );
    } on AuthException {
      throw const DeliveryTrackingRepositoryException(
        DeliveryTrackingFailureKind.unauthorized,
      );
    } on PostgrestException catch (error) {
      throw DeliveryTrackingRepositoryException(switch (error.code) {
        '28000' ||
        '42501' ||
        'PGRST301' => DeliveryTrackingFailureKind.unauthorized,
        '57014' => DeliveryTrackingFailureKind.timeout,
        _ => DeliveryTrackingFailureKind.unexpected,
      });
    } on FormatException {
      throw const DeliveryTrackingRepositoryException(
        DeliveryTrackingFailureKind.unexpected,
      );
    } on Object {
      throw const DeliveryTrackingRepositoryException(
        DeliveryTrackingFailureKind.unexpected,
      );
    }
  }
}

const _snapshotKeys = <String>{
  'apiVersion',
  'orderId',
  'orderStatus',
  'orderStatusVersion',
  'fulfillmentMode',
  'trackingMode',
  'trackingSessionId',
  'trackingState',
  'courierPublicLabel',
  'vehicleKind',
  'latitude',
  'longitude',
  'horizontalAccuracyMeters',
  'bearingDegrees',
  'speedMetersPerSecond',
  'observedAt',
  'receivedAt',
  'freshness',
  'etaStartsAt',
  'etaEndsAt',
  'destinationLatitude',
  'destinationLongitude',
  'storeLatitude',
  'storeLongitude',
  'externalCarrier',
  'externalTrackingCodeMasked',
  'externalTrackingUrl',
  'contactCapability',
  'serverTime',
  'version',
};

const _realtimeKeys = <String>{
  'order_id',
  'order_status',
  'order_status_version',
  'fulfillment_mode',
  'tracking_mode',
  'tracking_session_id',
  'tracking_state',
  'courier_public_label',
  'vehicle_kind',
  'latitude',
  'longitude',
  'horizontal_accuracy_meters',
  'bearing_degrees',
  'speed_meters_per_second',
  'observed_at',
  'received_at',
  'freshness',
  'eta_starts_at',
  'eta_ends_at',
  'destination_latitude',
  'destination_longitude',
  'store_latitude',
  'store_longitude',
  'external_carrier',
  'external_tracking_code_masked',
  'external_tracking_url',
  'contact_capability',
  'server_time',
  'version',
};

DeliveryTrackingSnapshot parseDeliveryTrackingSnapshot(Object? raw) {
  final map = _strictMap(raw, _snapshotKeys, 'delivery_tracking_snapshot');
  if (map['apiVersion'] != 'delivery-tracking-snapshot.v1') {
    throw const FormatException('delivery_tracking_version');
  }
  final orderId = _requiredUuid(map, 'orderId');
  final orderStatus = _requiredEnum(map, 'orderStatus', const {
    'confirmed',
    'accepted',
    'rejected',
    'preparing',
    'ready',
    'out_for_delivery',
    'completed',
    'cancelled',
  });
  final orderStatusVersion = _requiredPositiveInt(map, 'orderStatusVersion');
  final fulfillmentMode = _requiredEnum(map, 'fulfillmentMode', const {
    'pickup',
    'reservation',
    'delivery',
  });
  final trackingMode = switch (_requiredString(map, 'trackingMode')) {
    'statusOnly' => DeliveryTrackingMode.statusOnly,
    'externalCarrier' => DeliveryTrackingMode.externalCarrier,
    'liveCourier' => DeliveryTrackingMode.liveCourier,
    _ => throw const FormatException('delivery_tracking_mode'),
  };
  final trackingState = switch (_requiredString(map, 'trackingState')) {
    'unavailable' => DeliveryTrackingState.unavailable,
    'awaiting_assignment' => DeliveryTrackingState.awaitingAssignment,
    'assigned' => DeliveryTrackingState.assigned,
    'active' => DeliveryTrackingState.active,
    'paused' => DeliveryTrackingState.paused,
    'completed' => DeliveryTrackingState.completed,
    'cancelled' => DeliveryTrackingState.cancelled,
    _ => throw const FormatException('delivery_tracking_state'),
  };
  final freshness = switch (_requiredString(map, 'freshness')) {
    'unavailable' => DeliveryTrackingFreshness.unavailable,
    'fresh' => DeliveryTrackingFreshness.fresh,
    'stale' => DeliveryTrackingFreshness.stale,
    'ended' => DeliveryTrackingFreshness.ended,
    _ => throw const FormatException('delivery_tracking_freshness'),
  };
  final contactCapability = switch (_requiredString(map, 'contactCapability')) {
    'none' => DeliveryContactCapability.none,
    'store_phone' => DeliveryContactCapability.storePhone,
    'store_support_url' => DeliveryContactCapability.storeSupportUrl,
    _ => throw const FormatException('delivery_tracking_contact'),
  };
  final serverTime = _requiredDate(map, 'serverTime');
  final version = _requiredPositiveInt(map, 'version');
  final trackingSessionId = _optionalUuid(map, 'trackingSessionId');
  final courierPublicLabel = _optionalBoundedString(
    map,
    'courierPublicLabel',
    maximum: 80,
  );
  final vehicleKind = switch (_optionalString(map, 'vehicleKind')) {
    null => null,
    'walking' => DeliveryVehicleKind.walking,
    'bicycle' => DeliveryVehicleKind.bicycle,
    'motorcycle' => DeliveryVehicleKind.motorcycle,
    'car' => DeliveryVehicleKind.car,
    'van' => DeliveryVehicleKind.van,
    'other' => DeliveryVehicleKind.other,
    _ => throw const FormatException('delivery_tracking_vehicle'),
  };
  final latitude = _optionalFinite(map, 'latitude');
  final longitude = _optionalFinite(map, 'longitude');
  final destinationLatitude = _optionalFinite(map, 'destinationLatitude');
  final destinationLongitude = _optionalFinite(map, 'destinationLongitude');
  final storeLatitude = _optionalFinite(map, 'storeLatitude');
  final storeLongitude = _optionalFinite(map, 'storeLongitude');
  final courierCoordinate = _coordinate(latitude, longitude, 'courier');
  final destinationCoordinate = _coordinate(
    destinationLatitude,
    destinationLongitude,
    'destination',
  );
  final storeCoordinate = _coordinate(storeLatitude, storeLongitude, 'store');
  final accuracy = _optionalFinite(map, 'horizontalAccuracyMeters');
  final bearing = _optionalFinite(map, 'bearingDegrees');
  final speed = _optionalFinite(map, 'speedMetersPerSecond');
  final observedAt = _optionalDate(map, 'observedAt');
  final receivedAt = _optionalDate(map, 'receivedAt');
  final etaStartsAt = _optionalDate(map, 'etaStartsAt');
  final etaEndsAt = _optionalDate(map, 'etaEndsAt');
  final externalCarrier = _optionalBoundedString(
    map,
    'externalCarrier',
    maximum: 80,
  );
  final externalTrackingCodeMasked = _optionalBoundedString(
    map,
    'externalTrackingCodeMasked',
    maximum: 40,
  );
  final externalTrackingUrl = _optionalPublicHttpsUri(
    map,
    'externalTrackingUrl',
  );

  if ((accuracy != null && (accuracy < 0 || accuracy > 5000)) ||
      (bearing != null && (bearing < 0 || bearing >= 360)) ||
      (speed != null && (speed < 0 || speed > 100)) ||
      ((courierCoordinate == null) != (observedAt == null)) ||
      ((courierCoordinate == null) != (receivedAt == null)) ||
      (observedAt != null && observedAt.isAfter(serverTime)) ||
      (receivedAt != null && receivedAt.isAfter(serverTime)) ||
      ((etaStartsAt == null) != (etaEndsAt == null)) ||
      (etaStartsAt != null && !etaStartsAt.isBefore(etaEndsAt!))) {
    throw const FormatException('delivery_tracking_numeric_shape');
  }
  final terminal =
      const {'completed', 'cancelled', 'rejected'}.contains(orderStatus) ||
      freshness == DeliveryTrackingFreshness.ended;
  if (terminal &&
      (courierCoordinate != null ||
          destinationCoordinate != null ||
          storeCoordinate != null ||
          courierPublicLabel != null ||
          externalTrackingUrl != null)) {
    throw const FormatException('delivery_tracking_terminal_redaction');
  }
  if (trackingMode != DeliveryTrackingMode.liveCourier &&
      (courierCoordinate != null ||
          destinationCoordinate != null ||
          storeCoordinate != null ||
          courierPublicLabel != null ||
          vehicleKind != null)) {
    throw const FormatException('delivery_tracking_live_shape');
  }
  if (!terminal &&
      trackingMode == DeliveryTrackingMode.externalCarrier &&
      (externalCarrier == null || externalTrackingUrl == null)) {
    throw const FormatException('delivery_tracking_external_shape');
  }
  if (trackingMode != DeliveryTrackingMode.externalCarrier &&
      (externalCarrier != null ||
          externalTrackingCodeMasked != null ||
          externalTrackingUrl != null)) {
    throw const FormatException('delivery_tracking_external_unexpected');
  }
  if (freshness == DeliveryTrackingFreshness.fresh &&
      (trackingMode != DeliveryTrackingMode.liveCourier ||
          trackingState != DeliveryTrackingState.active ||
          courierCoordinate == null)) {
    throw const FormatException('delivery_tracking_fresh_shape');
  }

  return DeliveryTrackingSnapshot(
    orderId: orderId,
    orderStatus: orderStatus,
    orderStatusVersion: orderStatusVersion,
    fulfillmentMode: fulfillmentMode,
    trackingMode: trackingMode,
    trackingState: trackingState,
    freshness: freshness,
    contactCapability: contactCapability,
    serverTime: serverTime,
    version: version,
    trackingSessionId: trackingSessionId,
    courierPublicLabel: courierPublicLabel,
    vehicleKind: vehicleKind,
    courierCoordinate: courierCoordinate,
    horizontalAccuracyMeters: accuracy,
    bearingDegrees: bearing,
    speedMetersPerSecond: speed,
    observedAt: observedAt,
    receivedAt: receivedAt,
    etaStartsAt: etaStartsAt,
    etaEndsAt: etaEndsAt,
    destinationCoordinate: destinationCoordinate,
    storeCoordinate: storeCoordinate,
    externalCarrier: externalCarrier,
    externalTrackingCodeMasked: externalTrackingCodeMasked,
    externalTrackingUrl: externalTrackingUrl,
  );
}

Map<String, Object?> _strictMap(
  Object? raw,
  Set<String> allowed,
  String label,
) {
  if (raw is! Map) throw FormatException('${label}_map');
  final map = raw.map((key, value) => MapEntry(key.toString(), value));
  if (map.keys.any((key) => !allowed.contains(key))) {
    throw FormatException('${label}_keys');
  }
  return map;
}

String _requiredString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) throw FormatException('${key}_string');
  return value;
}

String _requiredEnum(
  Map<String, Object?> map,
  String key,
  Set<String> allowed,
) {
  final value = _requiredString(map, key);
  if (!allowed.contains(value)) throw FormatException('${key}_enum');
  return value;
}

String _requiredUuid(Map<String, Object?> map, String key) {
  final value = _requiredString(map, key);
  _requireUuid(value);
  return value;
}

String? _optionalUuid(Map<String, Object?> map, String key) {
  final value = _optionalString(map, key);
  if (value != null) _requireUuid(value);
  return value;
}

String? _optionalString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! String || value.isEmpty) throw FormatException('${key}_string');
  return value;
}

String? _optionalBoundedString(
  Map<String, Object?> map,
  String key, {
  required int maximum,
}) {
  final value = _optionalString(map, key);
  if (value != null &&
      (value.length > maximum ||
          value.trim() != value ||
          value.contains('\n'))) {
    throw FormatException('${key}_bounded');
  }
  return value;
}

int _requiredPositiveInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int || value < 1) throw FormatException('${key}_int');
  return value;
}

double? _optionalFinite(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! num || !value.toDouble().isFinite) {
    throw FormatException('${key}_number');
  }
  return value.toDouble();
}

DateTime _requiredDate(Map<String, Object?> map, String key) {
  final value = _optionalDate(map, key);
  if (value == null) throw FormatException('${key}_date');
  return value;
}

DateTime? _optionalDate(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('${key}_date');
  final parsed = DateTime.tryParse(value);
  if (parsed == null ||
      !value.endsWith('Z') && !value.contains(RegExp(r'[+-]\d\d:\d\d$'))) {
    throw FormatException('${key}_date');
  }
  return parsed.toUtc();
}

DeliveryCoordinate? _coordinate(
  double? latitude,
  double? longitude,
  String label,
) {
  if ((latitude == null) != (longitude == null)) {
    throw FormatException('${label}_coordinate_pair');
  }
  if (latitude == null) return null;
  if (latitude < -90 || latitude > 90 || longitude! < -180 || longitude > 180) {
    throw FormatException('${label}_coordinate_range');
  }
  return DeliveryCoordinate(latitude: latitude, longitude: longitude);
}

Uri? _optionalPublicHttpsUri(Map<String, Object?> map, String key) {
  final value = _optionalString(map, key);
  if (value == null) return null;
  final uri = Uri.tryParse(value);
  final host = uri?.host.toLowerCase() ?? '';
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.userInfo.isNotEmpty ||
      uri.fragment.isNotEmpty ||
      uri.hasPort ||
      !host.contains('.') ||
      host == 'localhost' ||
      host.endsWith('.local') ||
      host.contains(':') ||
      RegExp(
        r'^(0\.|10\.|127\.|169\.254\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)',
      ).hasMatch(host)) {
    throw FormatException('${key}_url');
  }
  return uri;
}

DeliveryTrackingFailureKind _remoteFailure(Object? code) => switch (code) {
  'invalid' || 'validation_failed' => DeliveryTrackingFailureKind.invalid,
  'not_found' => DeliveryTrackingFailureKind.notFound,
  'permission_denied' ||
  'session_expired' => DeliveryTrackingFailureKind.unauthorized,
  'unavailable' ||
  'feature_disabled' => DeliveryTrackingFailureKind.unavailable,
  _ => DeliveryTrackingFailureKind.unexpected,
};

void _requireUuid(String value) {
  if (!RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  ).hasMatch(value)) {
    throw const FormatException('delivery_tracking_uuid');
  }
}

void _requireShopSlug(String value) {
  if (!RegExp(r'^[a-z0-9][a-z0-9-]{2,62}$').hasMatch(value)) {
    throw const DeliveryTrackingRepositoryException(
      DeliveryTrackingFailureKind.invalid,
    );
  }
}
