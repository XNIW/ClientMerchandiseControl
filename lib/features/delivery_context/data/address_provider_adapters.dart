import 'package:geolocator/geolocator.dart';

import '../domain/delivery_address_ports.dart';
import '../domain/delivery_context_models.dart';

enum ForegroundLocationPermission { denied, deniedForever, whileInUse, always }

abstract interface class ForegroundLocationGateway {
  Future<bool> isServiceEnabled();

  Future<ForegroundLocationPermission> checkPermission();

  Future<ForegroundLocationPermission> requestPermission();

  Future<DeliveryCoordinate> readOnce();
}

final class GeolocatorForegroundLocationGateway
    implements ForegroundLocationGateway {
  const GeolocatorForegroundLocationGateway();

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<ForegroundLocationPermission> checkPermission() async =>
      _permission(await Geolocator.checkPermission());

  @override
  Future<ForegroundLocationPermission> requestPermission() async =>
      _permission(await Geolocator.requestPermission());

  @override
  Future<DeliveryCoordinate> readOnce() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return DeliveryCoordinate(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
    );
  }

  static ForegroundLocationPermission _permission(
    LocationPermission value,
  ) => switch (value) {
    LocationPermission.denied => ForegroundLocationPermission.denied,
    LocationPermission.deniedForever =>
      ForegroundLocationPermission.deniedForever,
    LocationPermission.whileInUse => ForegroundLocationPermission.whileInUse,
    LocationPermission.always => ForegroundLocationPermission.always,
    LocationPermission.unableToDetermine => ForegroundLocationPermission.denied,
  };
}

final class PlatformCurrentLocationPort implements CurrentLocationPort {
  const PlatformCurrentLocationPort({
    this.gateway = const GeolocatorForegroundLocationGateway(),
  });

  final ForegroundLocationGateway gateway;

  @override
  bool get configured => true;

  @override
  Future<DeliveryCoordinate?> readOnce() async {
    try {
      if (!await gateway.isServiceEnabled()) return null;
      var permission = await gateway.checkPermission();
      if (permission == ForegroundLocationPermission.denied) {
        permission = await gateway.requestPermission();
      }
      if (permission == ForegroundLocationPermission.denied ||
          permission == ForegroundLocationPermission.deniedForever) {
        return null;
      }
      final coordinate = await gateway.readOnce();
      if (!coordinate.latitude.isFinite ||
          !coordinate.longitude.isFinite ||
          coordinate.latitude < -90 ||
          coordinate.latitude > 90 ||
          coordinate.longitude < -180 ||
          coordinate.longitude > 180) {
        return null;
      }
      final accuracy = coordinate.accuracyMeters;
      return DeliveryCoordinate(
        latitude: _boundedPrecision(coordinate.latitude),
        longitude: _boundedPrecision(coordinate.longitude),
        accuracyMeters:
            accuracy == null ||
                !accuracy.isFinite ||
                accuracy < 0 ||
                accuracy > 100000
            ? null
            : (accuracy * 10).round() / 10,
      );
    } on Object {
      return null;
    }
  }

  static double _boundedPrecision(double value) =>
      (value * 100000).round() / 100000;
}

final class NotConfiguredDeliveryAddressMapPort
    implements DeliveryAddressMapPort {
  const NotConfiguredDeliveryAddressMapPort();

  @override
  bool get configured => false;

  @override
  Future<DeliveryCoordinate> previewAndAdjust(DeliveryCoordinate initial) =>
      throw const AddressProviderNotConfiguredException();
}

final class NotConfiguredAddressSearchPort implements AddressSearchPort {
  const NotConfiguredAddressSearchPort();

  @override
  bool get configured => false;

  @override
  Future<List<AddressSearchSuggestion>> search(String query) =>
      throw const AddressProviderNotConfiguredException();

  @override
  Future<ReverseGeocodedAddress?> resolve(AddressSearchSuggestion suggestion) =>
      throw const AddressProviderNotConfiguredException();
}

final class NotConfiguredReverseGeocodingPort implements ReverseGeocodingPort {
  const NotConfiguredReverseGeocodingPort();

  @override
  bool get configured => false;

  @override
  Future<ReverseGeocodedAddress?> reverse(DeliveryCoordinate coordinate) =>
      throw const AddressProviderNotConfiguredException();
}

final class NotConfiguredCurrentLocationPort implements CurrentLocationPort {
  const NotConfiguredCurrentLocationPort();

  @override
  bool get configured => false;

  @override
  Future<DeliveryCoordinate?> readOnce() =>
      throw const AddressProviderNotConfiguredException();
}

final class FakeDeliveryAddressMapPort implements DeliveryAddressMapPort {
  const FakeDeliveryAddressMapPort({this.adjusted});

  final DeliveryCoordinate? adjusted;

  @override
  bool get configured => true;

  @override
  Future<DeliveryCoordinate> previewAndAdjust(
    DeliveryCoordinate initial,
  ) async => adjusted ?? initial;
}

final class FakeAddressSearchPort implements AddressSearchPort {
  const FakeAddressSearchPort(this.results, {this.resolved});

  final List<AddressSearchSuggestion> results;
  final ReverseGeocodedAddress? resolved;

  @override
  bool get configured => true;

  @override
  Future<List<AddressSearchSuggestion>> search(String query) async =>
      query.trim().isEmpty ? const [] : List.unmodifiable(results);

  @override
  Future<ReverseGeocodedAddress?> resolve(
    AddressSearchSuggestion suggestion,
  ) async => resolved;
}

final class FakeReverseGeocodingPort implements ReverseGeocodingPort {
  const FakeReverseGeocodingPort(this.result);

  final ReverseGeocodedAddress? result;

  @override
  bool get configured => true;

  @override
  Future<ReverseGeocodedAddress?> reverse(
    DeliveryCoordinate coordinate,
  ) async => result;
}

final class FakeCurrentLocationPort implements CurrentLocationPort {
  const FakeCurrentLocationPort(this.result);

  final DeliveryCoordinate? result;

  @override
  bool get configured => true;

  @override
  Future<DeliveryCoordinate?> readOnce() async => result;
}
