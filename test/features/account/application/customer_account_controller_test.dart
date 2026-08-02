import 'dart:async';

import 'package:client_merchandise_control/features/account/application/customer_account_controller.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_failure.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../customer_account_test_support.dart';

void main() {
  late FakeCustomerAccountRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeCustomerAccountRepository();
    container = ProviderContainer(
      overrides: [
        customerAccountIdentityProvider.overrideWithValue(_identity()),
        customerAccountRepositoryProvider.overrideWithValue(repository),
        customerIdempotencyKeyFactoryProvider.overrideWithValue(
          () => '21000000-0000-4000-8000-000000000777',
        ),
      ],
    );
    addTearDown(() => container.dispose());
  });

  test('carica owner snapshot e salva profilo con refresh server', () async {
    container.read(customerAccountControllerProvider);
    await _waitForStatus(container, CustomerAccountStatus.ready);

    final controller = container.read(
      customerAccountControllerProvider.notifier,
    );
    await controller.saveProfile(
      CustomerProfileDraft(displayName: 'Cliente Dos', locale: 'it'),
    );

    final state = container.read(customerAccountControllerProvider);
    expect(state.status, CustomerAccountStatus.ready);
    expect(state.snapshot?.profile?.displayName, 'Cliente Dos');
    expect(state.snapshot?.profile?.locale, 'it');
    expect(state.notice, CustomerAccountNoticeKind.profileSaved);
    expect(repository.saveProfileCalls, 1);
    expect(repository.loadCalls, 2);
  });

  test(
    'errore mutation preserva snapshot e non mostra successo autorevole',
    () async {
      container.read(customerAccountControllerProvider);
      await _waitForStatus(container, CustomerAccountStatus.ready);
      final before = container.read(customerAccountControllerProvider).snapshot;
      repository.mutationError = offlineCustomerFailure();

      await container
          .read(customerAccountControllerProvider.notifier)
          .deleteAddress(testAddressId);

      final state = container.read(customerAccountControllerProvider);
      expect(state.snapshot, same(before));
      expect(state.notice, CustomerAccountNoticeKind.actionFailed);
      expect(state.failure?.kind, CustomerAccountFailureKind.offline);
      expect(state.isMutating, isFalse);
    },
  );

  test(
    'retry deletion ambiguo conserva idempotency key e doppio tap è serializzato',
    () async {
      container.read(customerAccountControllerProvider);
      await _waitForStatus(container, CustomerAccountStatus.ready);
      final barrier = Completer<void>();
      repository.deletionBarrier = barrier;
      final controller = container.read(
        customerAccountControllerProvider.notifier,
      );

      final first = controller.requestAccountDeletion();
      final second = controller.requestAccountDeletion();
      await Future<void>.delayed(Duration.zero);
      expect(repository.requestDeletionCalls, 1);
      expect(repository.deletionKeys, ['21000000-0000-4000-8000-000000000777']);

      barrier.complete();
      await Future.wait([first, second]);
      final state = container.read(customerAccountControllerProvider);
      expect(state.notice, CustomerAccountNoticeKind.deletionRequested);
      expect(state.snapshot?.deletionRequest?.status, 'requested');
    },
  );

  test(
    'initial offline espone retry e poi recupera senza loop automatico',
    () async {
      repository.loadError = offlineCustomerFailure();
      container.read(customerAccountControllerProvider);
      await _waitForStatus(container, CustomerAccountStatus.offline);
      expect(repository.loadCalls, 1);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repository.loadCalls, 1);

      repository.loadError = null;
      await container.read(customerAccountControllerProvider.notifier).retry();
      expect(
        container.read(customerAccountControllerProvider).status,
        CustomerAccountStatus.ready,
      );
      expect(repository.loadCalls, 2);
    },
  );

  test(
    'retry durante un caricamento attivo riusa la stessa operazione',
    () async {
      final barrier = Completer<void>();
      repository.loadBarrier = barrier;
      container.read(customerAccountControllerProvider);
      await Future<void>.delayed(Duration.zero);
      expect(repository.loadCalls, 1);

      final controller = container.read(
        customerAccountControllerProvider.notifier,
      );
      final retry = controller.retry();
      final refresh = controller.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(repository.loadCalls, 1);

      barrier.complete();
      await Future.wait([retry, refresh]);
      expect(
        container.read(customerAccountControllerProvider).status,
        CustomerAccountStatus.ready,
      );
      expect(repository.loadCalls, 1);
    },
  );

  test(
    'cambio identità durante load invalida owner precedente e carica il nuovo',
    () async {
      container.dispose();
      final identity = StateProvider<AuthenticatedCustomer?>(
        (ref) => _identity(),
      );
      final barrier = Completer<void>();
      repository.loadBarrier = barrier;
      container = ProviderContainer(
        overrides: [
          customerAccountIdentityProvider.overrideWith(
            (ref) => ref.watch(identity),
          ),
          customerAccountRepositoryProvider.overrideWithValue(repository),
        ],
      );
      container.read(customerAccountControllerProvider);
      await Future<void>.delayed(Duration.zero);
      expect(repository.loadCalls, 1);

      container.read(identity.notifier).state = _identity(secondSubject);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(customerAccountControllerProvider).status,
        CustomerAccountStatus.loading,
      );

      barrier.complete();
      await _waitForStatus(container, CustomerAccountStatus.ready);
      expect(repository.loadCalls, 2);
      expect(repository.subjectId, secondSubject);
    },
  );

  test('identity assente non legge repository e resta signedOut', () async {
    container.dispose();
    container = ProviderContainer(
      overrides: [
        customerAccountIdentityProvider.overrideWithValue(null),
        customerAccountRepositoryProvider.overrideWithValue(repository),
      ],
    );

    expect(
      container.read(customerAccountControllerProvider).status,
      CustomerAccountStatus.signedOut,
    );
    await Future<void>.delayed(Duration.zero);
    expect(repository.loadCalls, 0);
  });
}

AuthenticatedCustomer _identity([String subjectId = testCustomerSubject]) {
  return AuthenticatedCustomer.fromUntrustedIdentity(
    subjectId: subjectId,
    email: 'customer@example.invalid',
    metadata: const {'name': 'Cliente Uno'},
  );
}

const secondSubject = '00000000-0000-4000-8000-000000021002';

Future<void> _waitForStatus(
  ProviderContainer container,
  CustomerAccountStatus expected,
) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    if (container.read(customerAccountControllerProvider).status == expected) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail(
    'Expected $expected, found '
    '${container.read(customerAccountControllerProvider).status}',
  );
}
