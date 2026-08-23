enum CustomerDeliveryMode { delivery, pickup }

enum DeliveryServiceabilityStatus {
  serviceable,
  unsupported,
  invalid,
  temporarilyUnavailable,
}

final class CustomerDeliveryContext {
  const CustomerDeliveryContext({
    required this.ownerUserId,
    required this.shopSlug,
    required this.mode,
    required this.addressId,
    required this.pickupPointId,
    required this.pickupPointName,
    required this.serviceabilityStatus,
    required this.deliveryZoneId,
    required this.deliveryZoneName,
    required this.estimatedFeeClp,
    required this.earliestSlotStartsAt,
    required this.earliestSlotEndsAt,
    required this.version,
    required this.selectedAt,
    required this.serverTime,
  });

  final String? ownerUserId;
  final String shopSlug;
  final CustomerDeliveryMode mode;
  final String? addressId;
  final String? pickupPointId;
  final String? pickupPointName;
  final DeliveryServiceabilityStatus serviceabilityStatus;
  final String? deliveryZoneId;
  final String? deliveryZoneName;
  final int? estimatedFeeClp;
  final DateTime? earliestSlotStartsAt;
  final DateTime? earliestSlotEndsAt;
  final int version;
  final DateTime selectedAt;
  final DateTime serverTime;

  bool get isCheckoutReady =>
      serviceabilityStatus == DeliveryServiceabilityStatus.serviceable &&
      earliestSlotStartsAt != null &&
      earliestSlotEndsAt != null;
}

final class DeliveryCoordinate {
  const DeliveryCoordinate({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
}

final class AddressSearchSuggestion {
  const AddressSearchSuggestion({
    required this.displayText,
    required this.providerPlaceId,
  });

  final String displayText;
  final String providerPlaceId;
}

final class ReverseGeocodedAddress {
  const ReverseGeocodedAddress({
    required this.addressLine1,
    required this.commune,
    required this.region,
    required this.postalCode,
    required this.countryCode,
    required this.coordinate,
  });

  final String addressLine1;
  final String commune;
  final String region;
  final String? postalCode;
  final String countryCode;
  final DeliveryCoordinate coordinate;
}
