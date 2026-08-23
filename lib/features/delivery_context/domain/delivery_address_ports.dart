import 'delivery_context_models.dart';

abstract interface class DeliveryAddressMapPort {
  bool get configured;

  Future<DeliveryCoordinate> previewAndAdjust(DeliveryCoordinate initial);
}

abstract interface class AddressSearchPort {
  bool get configured;

  Future<List<AddressSearchSuggestion>> search(String query);

  Future<ReverseGeocodedAddress?> resolve(AddressSearchSuggestion suggestion);
}

abstract interface class ReverseGeocodingPort {
  bool get configured;

  Future<ReverseGeocodedAddress?> reverse(DeliveryCoordinate coordinate);
}

abstract interface class CurrentLocationPort {
  bool get configured;

  /// One foreground read only. Implementations must not retain the result.
  Future<DeliveryCoordinate?> readOnce();
}

final class AddressProviderNotConfiguredException implements Exception {
  const AddressProviderNotConfiguredException();
}
