import 'package:client_merchandise_control/features/delivery_context/data/address_provider_adapters.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_address_ports.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_context_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'permission denied richiede il sistema una volta e non legge coordinate',
    () async {
      final gateway = _Gateway(
        checked: ForegroundLocationPermission.denied,
        requested: ForegroundLocationPermission.denied,
      );

      expect(
        await PlatformCurrentLocationPort(gateway: gateway).readOnce(),
        isNull,
      );
      expect(gateway.permissionRequests, 1);
      expect(gateway.locationReads, 0);
    },
  );

  test(
    'permission granted esegue una sola lettura con precisione bounded',
    () async {
      final gateway = _Gateway(
        checked: ForegroundLocationPermission.whileInUse,
        requested: ForegroundLocationPermission.whileInUse,
      );

      final coordinate = await PlatformCurrentLocationPort(
        gateway: gateway,
      ).readOnce();
      expect(coordinate?.latitude, -33.4489);
      expect(coordinate?.longitude, -70.66927);
      expect(coordinate?.accuracyMeters, 12.3);
      expect(gateway.permissionRequests, 0);
      expect(gateway.locationReads, 1);
    },
  );

  test(
    'provider address non configurato fallisce chiuso senza risultati finti',
    () async {
      const port = NotConfiguredAddressSearchPort();
      expect(port.configured, isFalse);
      expect(
        () => port.search('Providencia'),
        throwsA(isA<AddressProviderNotConfiguredException>()),
      );
    },
  );
}

final class _Gateway implements ForegroundLocationGateway {
  _Gateway({required this.checked, required this.requested});

  final ForegroundLocationPermission checked;
  final ForegroundLocationPermission requested;
  int permissionRequests = 0;
  int locationReads = 0;

  @override
  Future<ForegroundLocationPermission> checkPermission() async => checked;

  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<DeliveryCoordinate> readOnce() async {
    locationReads++;
    return const DeliveryCoordinate(
      latitude: -33.44890123,
      longitude: -70.66927123,
      accuracyMeters: 12.34,
    );
  }

  @override
  Future<ForegroundLocationPermission> requestPermission() async {
    permissionRequests++;
    return requested;
  }
}
