import 'package:client_merchandise_control/features/customer_devices/application/customer_device_sign_out_coordinator.dart';
import 'package:client_merchandise_control/features/customer_devices/domain/customer_device_failure.dart';
import 'package:client_merchandise_control/features/customer_devices/domain/customer_device_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'customer_device_test_support.dart';

void main() {
  test(
    'logout revoca token locale prima del server e ripulisce pending',
    () async {
      final events = <String>[];
      final store = MemoryCustomerDeviceStore(
        testLocalDeviceRecord(
          ownerSubjectId: testDeviceOwner,
          consent: CustomerDeviceConsentStatus.granted,
        ),
      );
      final repository = FakeCustomerDeviceRepository(events: events);
      final provider = FakePushTokenProvider(events: events);
      final coordinator = CustomerDeviceSignOutCoordinator(
        repository: repository,
        localStore: store,
        pushTokenProvider: provider,
        uuidFactory: () => testDeviceKey,
      );
      addTearDown(provider.dispose);

      await coordinator.prepareForSignOut(testDeviceOwner);

      expect(events, ['local-revoke', 'server-revoke']);
      expect(repository.revokeKeys, [testDeviceKey]);
      expect(store.record.consentStatus, CustomerDeviceConsentStatus.revoked);
      expect(store.record.pendingOperation, isNull);
    },
  );

  test(
    'logout offline non blocca e conserva revoca idempotente minimale',
    () async {
      final store = MemoryCustomerDeviceStore(
        testLocalDeviceRecord(
          ownerSubjectId: testDeviceOwner,
          consent: CustomerDeviceConsentStatus.granted,
        ),
      );
      final repository = FakeCustomerDeviceRepository()
        ..revokeError = const CustomerDeviceRepositoryException(
          CustomerDeviceFailureKind.offline,
        );
      final provider = FakePushTokenProvider();
      final coordinator = CustomerDeviceSignOutCoordinator(
        repository: repository,
        localStore: store,
        pushTokenProvider: provider,
        uuidFactory: () => testDeviceKey,
      );
      addTearDown(provider.dispose);

      await expectLater(
        coordinator.prepareForSignOut(testDeviceOwner),
        completes,
      );

      final pending = store.record.pendingOperation;
      expect(pending?.kind, CustomerDevicePendingOperationKind.revoke);
      expect(pending?.ownerSubjectId, testDeviceOwner);
      expect(pending?.idempotencyKey, testDeviceKey);
      expect(store.record.consentStatus, CustomerDeviceConsentStatus.revoked);
    },
  );

  test('doppio logout condivide una sola revoca', () async {
    final store = MemoryCustomerDeviceStore();
    final repository = FakeCustomerDeviceRepository();
    final provider = FakePushTokenProvider();
    final coordinator = CustomerDeviceSignOutCoordinator(
      repository: repository,
      localStore: store,
      pushTokenProvider: provider,
      uuidFactory: () => testDeviceKey,
    );
    addTearDown(provider.dispose);

    final first = coordinator.prepareForSignOut(testDeviceOwner);
    final second = coordinator.prepareForSignOut(testDeviceOwner);
    await Future.wait([first, second]);

    expect(identical(first, second), isTrue);
    expect(repository.revokeCalls, 1);
    expect(provider.revokeCalls, 1);
  });

  test('revoche offline di owner diversi restano entrambe pending', () async {
    final store = MemoryCustomerDeviceStore(
      testLocalDeviceRecord(
        ownerSubjectId: testDeviceOwner,
        consent: CustomerDeviceConsentStatus.granted,
      ),
    );
    final repository = FakeCustomerDeviceRepository()
      ..revokeError = const CustomerDeviceRepositoryException(
        CustomerDeviceFailureKind.offline,
      );
    final provider = FakePushTokenProvider();
    var key = testDeviceKey;
    final coordinator = CustomerDeviceSignOutCoordinator(
      repository: repository,
      localStore: store,
      pushTokenProvider: provider,
      uuidFactory: () => key,
    );
    addTearDown(provider.dispose);

    await coordinator.prepareForSignOut(testDeviceOwner);
    store.record = store.record.copyWith(
      decisionOwnerSubjectId: testSecondDeviceOwner,
      consentStatus: CustomerDeviceConsentStatus.granted,
    );
    key = testSecondDeviceKey;
    await coordinator.prepareForSignOut(testSecondDeviceOwner);

    expect(store.record.pendingOperations, hasLength(2));
    expect(
      store.record.pendingOperations.map(
        (operation) => operation.ownerSubjectId,
      ),
      [testDeviceOwner, testSecondDeviceOwner],
    );
  });
}
