import 'package:client_merchandise_control/features/customer_devices/data/shared_preferences_customer_device_store.dart';
import 'package:client_merchandise_control/features/customer_devices/domain/customer_device_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'customer_device_test_support.dart';

void main() {
  test('genera UUID v4 app-scoped e lo mantiene tra istanze', () async {
    final preferences = _MemoryPreferences();
    var calls = 0;
    String factory() {
      calls++;
      return testInstallationId;
    }

    final first = SharedPreferencesCustomerDeviceStore(
      uuidFactory: factory,
      preferences: preferences,
    );
    final created = await first.loadOrCreate();
    final second = SharedPreferencesCustomerDeviceStore(
      uuidFactory: () => testSecondDeviceKey,
      preferences: preferences,
    );
    final restored = await second.loadOrCreate();

    expect(created.installationId, testInstallationId);
    expect(restored.installationId, testInstallationId);
    expect(calls, 1);
    expect(isCustomerDeviceUuid(restored.installationId), isTrue);
  });

  test('record corrotto rigenera senza ereditare consenso', () async {
    final preferences = _MemoryPreferences({
      SharedPreferencesCustomerDeviceStore.storageKey:
          '{"installationId":"hardware-id","consentStatus":"granted"}',
    });
    final store = SharedPreferencesCustomerDeviceStore(
      uuidFactory: () => testInstallationId,
      preferences: preferences,
    );

    final record = await store.loadOrCreate();

    expect(record.installationId, testInstallationId);
    expect(record.decisionOwnerSubjectId, isNull);
    expect(record.consentStatus, CustomerDeviceConsentStatus.notRequested);
  });

  test('persistenza contiene solo decisione e retry, mai push token', () async {
    final preferences = _MemoryPreferences();
    final store = SharedPreferencesCustomerDeviceStore(
      uuidFactory: () => testInstallationId,
      preferences: preferences,
    );
    final record = (await store.loadOrCreate()).copyWith(
      decisionOwnerSubjectId: testDeviceOwner,
      consentStatus: CustomerDeviceConsentStatus.granted,
      pendingOperation: const CustomerDevicePendingOperation(
        kind: CustomerDevicePendingOperationKind.register,
        ownerSubjectId: testDeviceOwner,
        idempotencyKey: testDeviceKey,
      ),
    );

    await store.save(record);
    final encoded = await preferences.getString(
      SharedPreferencesCustomerDeviceStore.storageKey,
    );

    expect(encoded, isNot(contains(testPushToken)));
    expect(encoded, isNot(contains('pushToken')));
    expect(encoded, contains(testDeviceKey));
    expect(
      (await store.loadOrCreate()).pendingOperation?.idempotencyKey,
      testDeviceKey,
    );
  });
}

final class _MemoryPreferences implements CustomerDevicePreferences {
  _MemoryPreferences([Map<String, String>? values])
    : _values = Map<String, String>.of(values ?? const {});

  final Map<String, String> _values;

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }
}
