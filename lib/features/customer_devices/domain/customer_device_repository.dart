import 'customer_device_models.dart';

abstract interface class CustomerDeviceRepository {
  Future<CustomerDeviceSnapshot?> status(String installationId);

  Future<CustomerDeviceSnapshot> register(
    CustomerDeviceRegistrationRequest request,
  );

  Future<CustomerDeviceSnapshot?> revoke({
    required String installationId,
    required String idempotencyKey,
  });
}

abstract interface class CustomerDeviceLocalStore {
  Future<CustomerDeviceLocalRecord> loadOrCreate();

  Future<void> save(CustomerDeviceLocalRecord record);

  Future<CustomerDeviceLocalRecord> update(
    CustomerDeviceLocalRecord Function(CustomerDeviceLocalRecord current)
    transform,
  );
}

abstract interface class CustomerPushTokenProvider {
  CustomerDevicePlatform get platform;

  Stream<String> get tokenChanges;

  Future<CustomerPushCapability> currentCapability();

  Future<CustomerPushCapability> requestAuthorization();

  /// Revoca o elimina il token soltanto nel provider locale, senza loggarlo.
  Future<void> revokeLocalToken();
}
