enum DeliveryTrackingMode { statusOnly, externalCarrier, liveCourier }

enum DeliveryTrackingState {
  unavailable,
  awaitingAssignment,
  assigned,
  active,
  paused,
  completed,
  cancelled,
}

enum DeliveryTrackingFreshness { unavailable, fresh, stale, ended }

enum DeliveryVehicleKind { walking, bicycle, motorcycle, car, van, other }

enum DeliveryContactCapability { none, storePhone, storeSupportUrl }

final class DeliveryCoordinate {
  const DeliveryCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

final class DeliveryTrackingSnapshot {
  const DeliveryTrackingSnapshot({
    required this.orderId,
    required this.orderStatus,
    required this.orderStatusVersion,
    required this.fulfillmentMode,
    required this.trackingMode,
    required this.trackingState,
    required this.freshness,
    required this.contactCapability,
    required this.serverTime,
    required this.version,
    this.trackingSessionId,
    this.courierPublicLabel,
    this.vehicleKind,
    this.courierCoordinate,
    this.horizontalAccuracyMeters,
    this.bearingDegrees,
    this.speedMetersPerSecond,
    this.observedAt,
    this.receivedAt,
    this.etaStartsAt,
    this.etaEndsAt,
    this.destinationCoordinate,
    this.storeCoordinate,
    this.externalCarrier,
    this.externalTrackingCodeMasked,
    this.externalTrackingUrl,
  });

  final String orderId;
  final String orderStatus;
  final int orderStatusVersion;
  final String fulfillmentMode;
  final DeliveryTrackingMode trackingMode;
  final String? trackingSessionId;
  final DeliveryTrackingState trackingState;
  final String? courierPublicLabel;
  final DeliveryVehicleKind? vehicleKind;
  final DeliveryCoordinate? courierCoordinate;
  final double? horizontalAccuracyMeters;
  final double? bearingDegrees;
  final double? speedMetersPerSecond;
  final DateTime? observedAt;
  final DateTime? receivedAt;
  final DeliveryTrackingFreshness freshness;
  final DateTime? etaStartsAt;
  final DateTime? etaEndsAt;
  final DeliveryCoordinate? destinationCoordinate;
  final DeliveryCoordinate? storeCoordinate;
  final String? externalCarrier;
  final String? externalTrackingCodeMasked;
  final Uri? externalTrackingUrl;
  final DeliveryContactCapability contactCapability;
  final DateTime serverTime;
  final int version;

  bool get isTerminal =>
      orderStatus == 'completed' ||
      orderStatus == 'cancelled' ||
      orderStatus == 'rejected' ||
      freshness == DeliveryTrackingFreshness.ended;

  bool get hasFreshLiveLocation =>
      !isTerminal &&
      fulfillmentMode == 'delivery' &&
      orderStatus == 'out_for_delivery' &&
      trackingMode == DeliveryTrackingMode.liveCourier &&
      trackingSessionId?.trim().isNotEmpty == true &&
      trackingState == DeliveryTrackingState.active &&
      freshness == DeliveryTrackingFreshness.fresh &&
      courierCoordinate != null &&
      observedAt != null &&
      receivedAt != null;

  DeliveryTrackingSnapshot withoutPreciseLocation() {
    return copyWith(
      freshness: isTerminal
          ? DeliveryTrackingFreshness.ended
          : DeliveryTrackingFreshness.stale,
      clearPreciseLocation: true,
      clearSafeCoordinates: true,
    );
  }

  DeliveryTrackingSnapshot copyWith({
    DeliveryTrackingFreshness? freshness,
    bool clearPreciseLocation = false,
    bool clearSafeCoordinates = false,
  }) {
    return DeliveryTrackingSnapshot(
      orderId: orderId,
      orderStatus: orderStatus,
      orderStatusVersion: orderStatusVersion,
      fulfillmentMode: fulfillmentMode,
      trackingMode: trackingMode,
      trackingState: trackingState,
      freshness: freshness ?? this.freshness,
      contactCapability: contactCapability,
      serverTime: serverTime,
      version: version,
      trackingSessionId: trackingSessionId,
      courierPublicLabel: courierPublicLabel,
      vehicleKind: vehicleKind,
      courierCoordinate: clearPreciseLocation ? null : courierCoordinate,
      horizontalAccuracyMeters: clearPreciseLocation
          ? null
          : horizontalAccuracyMeters,
      bearingDegrees: clearPreciseLocation ? null : bearingDegrees,
      speedMetersPerSecond: clearPreciseLocation ? null : speedMetersPerSecond,
      etaStartsAt: etaStartsAt,
      etaEndsAt: etaEndsAt,
      destinationCoordinate: clearSafeCoordinates
          ? null
          : destinationCoordinate,
      storeCoordinate: clearSafeCoordinates ? null : storeCoordinate,
      externalCarrier: externalCarrier,
      externalTrackingCodeMasked: externalTrackingCodeMasked,
      externalTrackingUrl: externalTrackingUrl,
      observedAt: observedAt,
      receivedAt: receivedAt,
    );
  }
}

bool isNewerDeliveryTrackingSnapshot(
  DeliveryTrackingSnapshot current,
  DeliveryTrackingSnapshot candidate,
) {
  if (current.orderId != candidate.orderId) return false;
  if (candidate.orderStatusVersion != current.orderStatusVersion) {
    return candidate.orderStatusVersion > current.orderStatusVersion;
  }
  if (candidate.trackingSessionId != current.trackingSessionId) {
    return candidate.serverTime.isAfter(current.serverTime);
  }
  if (candidate.version != current.version) {
    return candidate.version > current.version;
  }
  final candidateReceived = candidate.receivedAt;
  final currentReceived = current.receivedAt;
  return candidateReceived != null &&
      (currentReceived == null || candidateReceived.isAfter(currentReceived));
}
