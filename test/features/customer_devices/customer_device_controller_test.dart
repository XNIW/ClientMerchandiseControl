import 'dart:async';

import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/customer_devices/application/customer_device_controller.dart';
import 'package:client_merchandise_control/features/customer_devices/application/customer_device_providers.dart';
import 'package:client_merchandise_control/features/customer_devices/domain/customer_device_failure.dart';
import 'package:client_merchandise_control/features/customer_devices/domain/customer_device_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'customer_device_test_support.dart';

void main() {
  late MemoryCustomerDeviceStore store;
  late FakeCustomerDeviceRepository repository;
  late FakePushTokenProvider pushProvider;
  late ProviderContainer container;
  var generatedKey = testDeviceKey;

  test('factory produce UUID v4 casuali senza identificatori hardware', () {
    final randomContainer = ProviderContainer();
    addTearDown(randomContainer.dispose);
    final factory = randomContainer.read(customerDeviceUuidFactoryProvider);

    final values = List<String>.generate(64, (_) => factory());

    expect(values.toSet(), hasLength(values.length));
    expect(values.every(isCustomerDeviceUuid), isTrue);
    expect(values.any((value) => value.contains(testDeviceOwner)), isFalse);
  });

  setUp(() {
    store = MemoryCustomerDeviceStore();
    repository = FakeCustomerDeviceRepository();
    pushProvider = FakePushTokenProvider();
    container = _container(
      identity: _identity(testDeviceOwner),
      store: store,
      repository: repository,
      pushProvider: pushProvider,
      keyFactory: () => generatedKey,
    );
  });

  tearDown(() async {
    container.dispose();
    await pushProvider.dispose();
  });

  test(
    'installazione nuova resta not_requested senza registrazione implicita',
    () async {
      container.read(customerDeviceControllerProvider);
      await _waitForStatus(container, CustomerDeviceStatus.ready);

      final state = container.read(customerDeviceControllerProvider);
      expect(state.consentStatus, CustomerDeviceConsentStatus.notRequested);
      expect(state.serverConfirmed, isTrue);
      expect(repository.statusCalls, 1);
      expect(repository.registerCalls, 0);
    },
  );

  test(
    'consenso e permesso distinti registrano token una sola volta',
    () async {
      container.read(customerDeviceControllerProvider);
      await _waitForStatus(container, CustomerDeviceStatus.ready);
      final controller = container.read(
        customerDeviceControllerProvider.notifier,
      );

      await controller.enable('it');

      final request = repository.registrations.single;
      expect(pushProvider.requestCalls, 1);
      expect(request.consentStatus, CustomerDeviceConsentStatus.granted);
      expect(
        request.permissionStatus,
        CustomerDevicePermissionStatus.authorized,
      );
      expect(request.pushToken, testPushToken);
      expect(request.locale, 'it');
      expect(store.record.pendingOperation, isNull);
      expect(
        container.read(customerDeviceControllerProvider).notificationsActive,
        isTrue,
      );
    },
  );

  test('permesso OS negato registra denied senza token', () async {
    pushProvider.permission = CustomerDevicePermissionStatus.denied;
    container.read(customerDeviceControllerProvider);
    await _waitForStatus(container, CustomerDeviceStatus.ready);

    await container
        .read(customerDeviceControllerProvider.notifier)
        .enable('es-CL');

    final request = repository.registrations.single;
    expect(request.consentStatus, CustomerDeviceConsentStatus.denied);
    expect(request.permissionStatus, CustomerDevicePermissionStatus.denied);
    expect(request.pushToken, isNull);
    expect(
      container.read(customerDeviceControllerProvider).notice,
      CustomerDeviceNoticeKind.denied,
    );
  });

  test('provider non configurato non simula token o consenso', () async {
    pushProvider
      ..availability = CustomerPushProviderAvailability.notConfigured
      ..permission = CustomerDevicePermissionStatus.notDetermined
      ..token = null;
    container.read(customerDeviceControllerProvider);
    await _waitForStatus(container, CustomerDeviceStatus.ready);

    await container
        .read(customerDeviceControllerProvider.notifier)
        .enable('es-CL');

    final state = container.read(customerDeviceControllerProvider);
    expect(repository.registerCalls, 0);
    expect(state.consentStatus, CustomerDeviceConsentStatus.notRequested);
    expect(state.notice, CustomerDeviceNoticeKind.providerUnavailable);
  });

  test('doppio tap condivide operazione e non duplica register', () async {
    container.read(customerDeviceControllerProvider);
    await _waitForStatus(container, CustomerDeviceStatus.ready);
    repository.registerBarrier = Completer<void>();
    final controller = container.read(
      customerDeviceControllerProvider.notifier,
    );

    final first = controller.enable('es-CL');
    final second = controller.enable('es-CL');
    await Future<void>.delayed(Duration.zero);

    expect(identical(first, second), isTrue);
    expect(repository.registerCalls, 1);
    repository.registerBarrier!.complete();
    await first;
    expect(repository.registerCalls, 1);
  });

  test(
    'offline conserva retry idempotente senza falso serverConfirmed',
    () async {
      repository.registerError = const CustomerDeviceRepositoryException(
        CustomerDeviceFailureKind.offline,
      );
      container.read(customerDeviceControllerProvider);
      await _waitForStatus(container, CustomerDeviceStatus.ready);
      final controller = container.read(
        customerDeviceControllerProvider.notifier,
      );

      await controller.enable('en');

      final failed = container.read(customerDeviceControllerProvider);
      expect(failed.status, CustomerDeviceStatus.offline);
      expect(failed.serverConfirmed, isFalse);
      expect(store.record.pendingOperation?.idempotencyKey, testDeviceKey);
      expect(repository.registerCalls, 1);

      repository.registerError = null;
      generatedKey = testSecondDeviceKey;
      await controller.retry('en');

      expect(repository.registerCalls, 2);
      expect(
        repository.registrations.map((request) => request.idempotencyKey),
        [testDeviceKey, testDeviceKey],
      );
      expect(store.record.pendingOperation, isNull);
      expect(
        container.read(customerDeviceControllerProvider).serverConfirmed,
        isTrue,
      );
    },
  );

  test('rotazione token aggiorna server solo dopo consenso granted', () async {
    store.record = testLocalDeviceRecord(
      ownerSubjectId: testDeviceOwner,
      consent: CustomerDeviceConsentStatus.granted,
    );
    repository.statusResult = testDeviceSnapshot();
    container.read(customerDeviceControllerProvider);
    await _waitForStatus(container, CustomerDeviceStatus.ready);
    generatedKey = testSecondDeviceKey;

    pushProvider.emitToken('rotated-token-0123456789-abcdefghijkl');
    await _waitForRegisterCount(repository, 1);

    expect(
      repository.registrations.single.pushToken,
      'rotated-token-0123456789-abcdefghijkl',
    );
    expect(repository.registrations.single.idempotencyKey, testSecondDeviceKey);
  });

  test('revoca elimina token locale e conferma assenza server', () async {
    store.record = testLocalDeviceRecord(
      ownerSubjectId: testDeviceOwner,
      consent: CustomerDeviceConsentStatus.granted,
    );
    repository.statusResult = testDeviceSnapshot();
    container.read(customerDeviceControllerProvider);
    await _waitForStatus(container, CustomerDeviceStatus.ready);

    await container.read(customerDeviceControllerProvider.notifier).revoke();

    final state = container.read(customerDeviceControllerProvider);
    expect(pushProvider.revokeCalls, 1);
    expect(repository.revokeCalls, 1);
    expect(state.consentStatus, CustomerDeviceConsentStatus.revoked);
    expect(state.serverConfirmed, isTrue);
    expect(store.record.pendingOperation, isNull);
  });

  test(
    'cambio account non eredita consenso o retry dell owner precedente',
    () async {
      container.dispose();
      final identity = StateProvider<AuthenticatedCustomer?>(
        (ref) => _identity(testDeviceOwner),
      );
      store.record = testLocalDeviceRecord(
        ownerSubjectId: testDeviceOwner,
        consent: CustomerDeviceConsentStatus.granted,
        pending: const CustomerDevicePendingOperation(
          kind: CustomerDevicePendingOperationKind.register,
          ownerSubjectId: testDeviceOwner,
          idempotencyKey: testDeviceKey,
        ),
      );
      container = ProviderContainer(
        overrides: [
          customerDeviceIdentityProvider.overrideWith(
            (ref) => ref.watch(identity),
          ),
          customerDeviceLocalStoreProvider.overrideWithValue(store),
          customerDeviceRepositoryProvider.overrideWithValue(repository),
          customerPushTokenProvider.overrideWithValue(pushProvider),
          customerDeviceUuidFactoryProvider.overrideWithValue(
            () => testSecondDeviceKey,
          ),
        ],
      );
      container.read(customerDeviceControllerProvider);
      await _waitForStatus(container, CustomerDeviceStatus.ready);

      container.read(identity.notifier).state = _identity(
        testSecondDeviceOwner,
      );
      await _waitForStatus(container, CustomerDeviceStatus.ready);

      final state = container.read(customerDeviceControllerProvider);
      expect(state.consentStatus, CustomerDeviceConsentStatus.notRequested);
      expect(state.serverConfirmed, isTrue);
      expect(repository.registerCalls, 0);
      expect(store.record.decisionOwnerSubjectId, testSecondDeviceOwner);
      expect(store.record.pendingOperation, isNull);
    },
  );

  test(
    'errore provider non esce dal controller e resta non confermato',
    () async {
      pushProvider.requestError = StateError('private-provider-detail');
      container.read(customerDeviceControllerProvider);
      await _waitForStatus(container, CustomerDeviceStatus.ready);

      await expectLater(
        container.read(customerDeviceControllerProvider.notifier).enable('en'),
        completes,
      );

      final state = container.read(customerDeviceControllerProvider);
      expect(state.status, CustomerDeviceStatus.failure);
      expect(state.failure?.kind, CustomerDeviceFailureKind.unavailable);
      expect(state.serverConfirmed, isFalse);
    },
  );

  test(
    'revoca A pending viene completata prima della registrazione B',
    () async {
      container.dispose();
      final events = <String>[];
      store = MemoryCustomerDeviceStore(
        CustomerDeviceLocalRecord(
          installationId: testInstallationId,
          decisionOwnerSubjectId: testSecondDeviceOwner,
          consentStatus: CustomerDeviceConsentStatus.notRequested,
          pendingOperations: const [
            CustomerDevicePendingOperation(
              kind: CustomerDevicePendingOperationKind.revoke,
              ownerSubjectId: testDeviceOwner,
              idempotencyKey: testDeviceKey,
            ),
          ],
        ),
      );
      repository = FakeCustomerDeviceRepository(events: events);
      container = _container(
        identity: _identity(testSecondDeviceOwner),
        store: store,
        repository: repository,
        pushProvider: pushProvider,
        keyFactory: () => testSecondDeviceKey,
      );
      container.read(customerDeviceControllerProvider);
      await _waitForStatus(container, CustomerDeviceStatus.ready);

      await container
          .read(customerDeviceControllerProvider.notifier)
          .enable('it');

      expect(events, ['server-revoke', 'server-register']);
      expect(store.record.pendingOperations, isEmpty);
      expect(repository.revokeKeys, [testDeviceKey]);
    },
  );

  test('register A tardivo non ripristina consenso o stato sotto B', () async {
    container.dispose();
    final identity = StateProvider<AuthenticatedCustomer?>(
      (ref) => _identity(testDeviceOwner),
    );
    repository.registerBarrier = Completer<void>();
    container = ProviderContainer(
      overrides: [
        customerDeviceIdentityProvider.overrideWith(
          (ref) => ref.watch(identity),
        ),
        customerDeviceLocalStoreProvider.overrideWithValue(store),
        customerDeviceRepositoryProvider.overrideWithValue(repository),
        customerPushTokenProvider.overrideWithValue(pushProvider),
        customerDeviceUuidFactoryProvider.overrideWithValue(
          () => testDeviceKey,
        ),
      ],
    );
    container.read(customerDeviceControllerProvider);
    await _waitForStatus(container, CustomerDeviceStatus.ready);

    final operation = container
        .read(customerDeviceControllerProvider.notifier)
        .enable('es-CL');
    await _waitForRegisterCount(repository, 1);
    container.read(identity.notifier).state = _identity(testSecondDeviceOwner);
    repository.registerBarrier!.complete();
    await operation;
    await _waitForConsent(container, CustomerDeviceConsentStatus.notRequested);

    final state = container.read(customerDeviceControllerProvider);
    expect(state.notificationsActive, isFalse);
    expect(store.record.decisionOwnerSubjectId, testSecondDeviceOwner);
  });
}

ProviderContainer _container({
  required AuthenticatedCustomer identity,
  required MemoryCustomerDeviceStore store,
  required FakeCustomerDeviceRepository repository,
  required FakePushTokenProvider pushProvider,
  required String Function() keyFactory,
}) {
  return ProviderContainer(
    overrides: [
      customerDeviceIdentityProvider.overrideWithValue(identity),
      customerDeviceLocalStoreProvider.overrideWithValue(store),
      customerDeviceRepositoryProvider.overrideWithValue(repository),
      customerPushTokenProvider.overrideWithValue(pushProvider),
      customerDeviceUuidFactoryProvider.overrideWithValue(keyFactory),
    ],
  );
}

AuthenticatedCustomer _identity(String subjectId) {
  return AuthenticatedCustomer.fromUntrustedIdentity(
    subjectId: subjectId,
    email: 'customer@example.invalid',
    metadata: const {'name': 'Cliente'},
  );
}

Future<void> _waitForStatus(
  ProviderContainer container,
  CustomerDeviceStatus expected,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (container.read(customerDeviceControllerProvider).status == expected) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail(
    'Expected $expected, found '
    '${container.read(customerDeviceControllerProvider).status}',
  );
}

Future<void> _waitForConsent(
  ProviderContainer container,
  CustomerDeviceConsentStatus expected,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    final state = container.read(customerDeviceControllerProvider);
    if (state.status == CustomerDeviceStatus.ready &&
        state.consentStatus == expected) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Expected consent $expected.');
}

Future<void> _waitForRegisterCount(
  FakeCustomerDeviceRepository repository,
  int expected,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (repository.registerCalls == expected) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail(
    'Expected $expected register call(s), found ${repository.registerCalls}.',
  );
}
