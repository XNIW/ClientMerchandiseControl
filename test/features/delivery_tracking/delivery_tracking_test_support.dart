import 'dart:async';

import 'package:client_merchandise_control/features/delivery_tracking/data/secure_delivery_tracking_cache.dart';
import 'package:client_merchandise_control/features/delivery_tracking/data/supabase_delivery_tracking_repository.dart';
import 'package:client_merchandise_control/features/delivery_tracking/domain/delivery_tracking_models.dart';
import 'package:client_merchandise_control/features/delivery_tracking/domain/delivery_tracking_repository.dart';

const trackingTestOwner = '10000000-0000-4000-8000-000000044001';
const trackingTestShop = 'storefront-test';
const trackingTestOrder = '44000000-0000-4000-8000-000000044001';
const trackingTestSession = '74000000-0000-4000-8000-000000044001';
final trackingTestNow = DateTime.utc(2026, 8, 16, 12);

Map<String, Object?> trackingLivePayload({
  String orderId = trackingTestOrder,
  int version = 4,
  int orderStatusVersion = 5,
  String freshness = 'fresh',
  String orderStatus = 'out_for_delivery',
  String trackingState = 'active',
}) => {
  'apiVersion': 'delivery-tracking-snapshot.v1',
  'orderId': orderId,
  'orderStatus': orderStatus,
  'orderStatusVersion': orderStatusVersion,
  'fulfillmentMode': 'delivery',
  'trackingMode': 'liveCourier',
  'trackingSessionId': trackingTestSession,
  'trackingState': trackingState,
  'courierPublicLabel': 'Repartidor MC',
  'vehicleKind': 'bicycle',
  'latitude': -33.446,
  'longitude': -70.655,
  'horizontalAccuracyMeters': 12,
  'bearingDegrees': 90,
  'speedMetersPerSecond': 4,
  'observedAt': trackingTestNow
      .subtract(const Duration(seconds: 2))
      .toIso8601String(),
  'receivedAt': trackingTestNow
      .subtract(const Duration(seconds: 1))
      .toIso8601String(),
  'freshness': freshness,
  'etaStartsAt': trackingTestNow
      .add(const Duration(minutes: 30))
      .toIso8601String(),
  'etaEndsAt': trackingTestNow
      .add(const Duration(minutes: 50))
      .toIso8601String(),
  'destinationLatitude': -33.447,
  'destinationLongitude': -70.65,
  'storeLatitude': -33.445,
  'storeLongitude': -70.66,
  'contactCapability': 'none',
  'serverTime': trackingTestNow.toIso8601String(),
  'version': version,
};

DeliveryTrackingSnapshot trackingLiveSnapshot({
  String orderId = trackingTestOrder,
  int version = 4,
  int orderStatusVersion = 5,
  String freshness = 'fresh',
}) => parseDeliveryTrackingSnapshot(
  trackingLivePayload(
    orderId: orderId,
    version: version,
    orderStatusVersion: orderStatusVersion,
    freshness: freshness,
  ),
);

Map<String, Object?> trackingRealtimeRecord({int version = 5}) {
  final payload = trackingLivePayload(version: version);
  return {
    'order_id': payload['orderId'],
    'order_status': payload['orderStatus'],
    'order_status_version': payload['orderStatusVersion'],
    'fulfillment_mode': payload['fulfillmentMode'],
    'tracking_mode': 'live_courier',
    'tracking_session_id': payload['trackingSessionId'],
    'tracking_state': payload['trackingState'],
    'courier_public_label': payload['courierPublicLabel'],
    'vehicle_kind': payload['vehicleKind'],
    'latitude': payload['latitude'],
    'longitude': payload['longitude'],
    'horizontal_accuracy_meters': payload['horizontalAccuracyMeters'],
    'bearing_degrees': payload['bearingDegrees'],
    'speed_meters_per_second': payload['speedMetersPerSecond'],
    'observed_at': payload['observedAt'],
    'received_at': payload['receivedAt'],
    'freshness': payload['freshness'],
    'eta_starts_at': payload['etaStartsAt'],
    'eta_ends_at': payload['etaEndsAt'],
    'destination_latitude': payload['destinationLatitude'],
    'destination_longitude': payload['destinationLongitude'],
    'store_latitude': payload['storeLatitude'],
    'store_longitude': payload['storeLongitude'],
    'external_carrier': null,
    'external_tracking_code_masked': null,
    'external_tracking_url': null,
    'contact_capability': payload['contactCapability'],
    'server_time': payload['serverTime'],
    'version': payload['version'],
  };
}

final class FakeDeliveryTrackingPort implements DeliveryTrackingPort {
  Object? response;
  String? function;
  Map<String, Object?>? parameters;
  final stream = StreamController<Object?>.broadcast();

  @override
  Future<Object?> invoke(
    String function,
    Map<String, Object?> parameters,
  ) async {
    this.function = function;
    this.parameters = parameters;
    return response;
  }

  @override
  Stream<Object?> watchOrder(String orderId) => stream.stream;
}

final class FakeDeliveryTrackingRepository
    implements DeliveryTrackingRepository {
  DeliveryTrackingSnapshot snapshot = trackingLiveSnapshot();
  Object? loadError;
  var loadCalls = 0;
  var watchCalls = 0;
  final stream = StreamController<DeliveryTrackingSnapshot>.broadcast();

  @override
  Future<DeliveryTrackingSnapshot> load({
    required String shopSlug,
    required String orderId,
  }) async {
    loadCalls++;
    if (loadError case final error?) throw error;
    return snapshot;
  }

  @override
  Stream<DeliveryTrackingSnapshot> watch({required String orderId}) {
    watchCalls++;
    return stream.stream;
  }
}

final class MemoryDeliveryTrackingCache implements DeliveryTrackingCacheStore {
  DeliveryTrackingSnapshot? snapshot;
  var clearCalls = 0;
  var saveCalls = 0;

  @override
  Future<void> clear({required String ownerSubjectId}) async {
    clearCalls++;
    snapshot = null;
  }

  @override
  Future<DeliveryTrackingSnapshot?> read({
    required String ownerSubjectId,
    required String shopSlug,
    required String orderId,
  }) async => snapshot?.orderId == orderId ? snapshot : null;

  @override
  Future<void> save({
    required String ownerSubjectId,
    required String shopSlug,
    required DeliveryTrackingSnapshot snapshot,
  }) async {
    saveCalls++;
    this.snapshot = snapshot;
  }
}

final class MemoryDeliveryTrackingSecurePreferences
    implements DeliveryTrackingSecurePreferences {
  String? value;

  @override
  Future<void> delete(String key) async => value = null;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async => this.value = value;
}
