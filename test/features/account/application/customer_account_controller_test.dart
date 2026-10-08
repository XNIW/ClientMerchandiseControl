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
    var generatedKeys = 776;
    container = ProviderContainer(
      overrides: [
        customerAccountIdentityProvider.overrideWithValue(_identity()),
        customerAccountRepositoryProvider.overrideWithValue(repository),
        customerAccountShopSlugProvider.overrideWithValue(null),
        customerIdempotencyKeyFactoryProvider.overrideWithValue(
          () =>
              '21000000-0000-4000-8000-${(++generatedKeys).toString().padLeft(12, '0')}',
        ),
      ],
    );
    addTearDown(() => container.dispose());
  });

  test(
    'create commit con risposta persa e retry produce un solo indirizzo',
    () async {
      container.read(customerAccountControllerProvider);
      await _waitForStatus(container, CustomerAccountStatus.ready);
      final controller = container.read(
        customerAccountControllerProvider.notifier,
      );
      final draft = testCustomerAddress().toDraft();
      repository.addressResponseError = offlineCustomerFailure();
      expect(await controller.createAddress(draft), isNull);
      repository.addressResponseError = null;
      final recovered = await controller.createAddress(draft);
      expect(recovered, isNotNull);
      expect(repository.createAddressCalls, 1);
    },
  );

  test('create concorrenti condividono anche il risultato canonico', () async {
    container.read(customerAccountControllerProvider);
    await _waitForStatus(container, CustomerAccountStatus.ready);
    final controller = container.read(
      customerAccountControllerProvider.notifier,
    );
    final barrier = Completer<void>();
    repository.addressMutationBarrier = barrier;
    final first = controller.createAddress(testCustomerAddress().toDraft());
    final second = controller.createAddress(testCustomerAddress().toDraft());
    barrier.complete();
    final results = await Future.wait([first, second]);
    expect(results[0], isNotNull);
    expect(results[1]?.id, results[0]?.id);
    expect(repository.createAddressCalls, 1);
  });

  test(
    'restart recupera journal e stesso canonico dopo risposta persa',
    () async {
      container.read(customerAccountControllerProvider);
      await _waitForStatus(container, CustomerAccountStatus.ready);
      repository.addressResponseError = const FormatException('response_lost');
      await container
          .read(customerAccountControllerProvider.notifier)
          .createAddress(testCustomerAddress().toDraft());
      container.dispose();
      container = ProviderContainer(
        overrides: [
          customerAccountIdentityProvider.overrideWithValue(_identity()),
          customerAccountRepositoryProvider.overrideWithValue(repository),
          customerAccountShopSlugProvider.overrideWithValue(null),
        ],
      );
      container.read(customerAccountControllerProvider);
      await _waitForStatus(container, CustomerAccountStatus.ready);
      final restored = container.read(customerAccountControllerProvider);
      expect(restored.pendingAddressDraft?.addressLine1, 'Avenida Uno 123');
      expect(restored.failure?.isUncertain, isTrue);
      final recovered = await container
          .read(customerAccountControllerProvider.notifier)
          .createAddress(restored.pendingAddressDraft!);
      expect(recovered?.id, repository.addresses.last.id);
      expect(repository.createAddressCalls, 1);
      expect(repository.reconcileCalls, 1);
      expect(repository.addressCreationJournal.intents, isEmpty);
    },
  );

  test('modifica dopo esito ambiguo non invia nuova creazione', () async {
    container.read(customerAccountControllerProvider);
    await _waitForStatus(container, CustomerAccountStatus.ready);
    repository.addressResponseError = offlineCustomerFailure();
    final controller = container.read(
      customerAccountControllerProvider.notifier,
    );
    await controller.createAddress(testCustomerAddress().toDraft());
    final changed = testCustomerAddress(label: 'Lavoro').toDraft();
    expect(await controller.createAddress(changed), isNull);
    expect(repository.createAddressAttempts, 1);
    final state = container.read(customerAccountControllerProvider);
    expect(state.failure?.isUncertain, isTrue);
    expect(state.pendingAddressDraft?.label, 'Casa');
  });

  test('not_found ritenta solo intent e payload originali', () async {
    container.read(customerAccountControllerProvider);
    await _waitForStatus(container, CustomerAccountStatus.ready);
    repository.mutationError = offlineCustomerFailure();
    final controller = container.read(
      customerAccountControllerProvider.notifier,
    );
    await controller.createAddress(testCustomerAddress().toDraft());
    repository.mutationError = null;
    expect(
      await controller.createAddress(testCustomerAddress().toDraft()),
      isNotNull,
    );
    expect(repository.receivedIntentIds.toSet(), hasLength(1));
    expect(repository.createAddressAttempts, 2);
    expect(repository.createAddressCalls, 1);
    expect(repository.reconcileCalls, 1);
  });

  test('journal non durevole impedisce qualunque RPC create', () async {
    container.read(customerAccountControllerProvider);
    await _waitForStatus(container, CustomerAccountStatus.ready);
    repository.addressCreationJournal.writeError = StateError('storage');
    final result = await container
        .read(customerAccountControllerProvider.notifier)
        .createAddress(testCustomerAddress().toDraft());
    expect(result, isNull);
    expect(repository.createAddressAttempts, 0);
  });

  test(
    'ACK con cancellazione journal fallita si riconcilia senza duplicare',
    () async {
      container.read(customerAccountControllerProvider);
      await _waitForStatus(container, CustomerAccountStatus.ready);
      repository.addressCreationJournal.clearError = StateError('storage');
      final controller = container.read(
        customerAccountControllerProvider.notifier,
      );
      final first = await controller.createAddress(
        testCustomerAddress().toDraft(),
      );
      expect(first, isNotNull);
      expect(repository.addressCreationJournal.intents, isNotEmpty);
      repository.addressCreationJournal.clearError = null;
      final second = await controller.createAddress(
        testCustomerAddress().toDraft(),
      );
      expect(second?.id, first?.id);
      expect(repository.createAddressCalls, 1);
    },
  );

  for (final kind in [
    CustomerAccountFailureKind.unauthorized,
    CustomerAccountFailureKind.conflict,
  ]) {
    test(
      'reconcile $kind non cancella intent precedentemente ambiguo',
      () async {
        container.read(customerAccountControllerProvider);
        await _waitForStatus(container, CustomerAccountStatus.ready);
        repository.addressResponseError = offlineCustomerFailure();
        final controller = container.read(
          customerAccountControllerProvider.notifier,
        );
        await controller.createAddress(testCustomerAddress().toDraft());
        repository.reconcileError = CustomerAccountRepositoryException(kind);
        await controller.createAddress(testCustomerAddress().toDraft());
        expect(repository.addressCreationJournal.intents, isNotEmpty);
        expect(
          container
              .read(customerAccountControllerProvider)
              .failure
              ?.isUncertain,
          isTrue,
        );
        expect(repository.createAddressCalls, 1);
      },
    );
  }

  for (final changeShop in [false, true]) {
    test(
      'risposta create tardiva dopo cambio ${changeShop ? 'shop' : 'account'} non conferma il nuovo scope',
      () async {
        container.dispose();
        final identity = StateProvider<AuthenticatedCustomer?>(
          (ref) => _identity(),
        );
        final shop = StateProvider<String?>((ref) => 'shop-a');
        container = ProviderContainer(
          overrides: [
            customerAccountIdentityProvider.overrideWith(
              (ref) => ref.watch(identity),
            ),
            customerAccountShopSlugProvider.overrideWith(
              (ref) => ref.watch(shop),
            ),
            customerAccountRepositoryProvider.overrideWithValue(repository),
          ],
        );
        container.read(customerAccountControllerProvider);
        await _waitForStatus(container, CustomerAccountStatus.ready);
        final barrier = Completer<void>();
        repository.addressMutationBarrier = barrier;
        final pending = container
            .read(customerAccountControllerProvider.notifier)
            .createAddress(testCustomerAddress().toDraft());
        await Future<void>.delayed(Duration.zero);
        expect(repository.createAddressAttempts, 1);
        if (changeShop) {
          container.read(shop.notifier).state = 'shop-b';
        } else {
          container.read(identity.notifier).state = _identity(secondSubject);
        }
        container.read(customerAccountControllerProvider);
        barrier.complete();
        expect(await pending, isNull);
        await _waitForStatus(container, CustomerAccountStatus.ready);
        final state = container.read(customerAccountControllerProvider);
        expect(state.notice, isNot(CustomerAccountNoticeKind.addressSaved));
        expect(state.pendingAddressDraft == null, !changeShop);
        expect(repository.addressCreationJournal.intents.keys, [
          testCustomerSubject,
        ]);
      },
    );
  }

  test(
    'due intenti confermati con campi uguali restano creazioni legittime',
    () async {
      container.read(customerAccountControllerProvider);
      await _waitForStatus(container, CustomerAccountStatus.ready);
      final controller = container.read(
        customerAccountControllerProvider.notifier,
      );
      final draft = testCustomerAddress().toDraft();
      final first = await controller.createAddress(draft);
      final second = await controller.createAddress(draft);
      expect(first?.id, isNot(second?.id));
      expect(repository.createAddressCalls, 2);
      expect(repository.receivedIntentIds.toSet(), hasLength(2));
    },
  );

  test(
    'kill durante richiesta e restart concorrente riusano intento persistito',
    () async {
      container.read(customerAccountControllerProvider);
      await _waitForStatus(container, CustomerAccountStatus.ready);
      final barrier = Completer<void>();
      repository.addressMutationBarrier = barrier;
      final draft = testCustomerAddress().toDraft();
      final oldRequest = container
          .read(customerAccountControllerProvider.notifier)
          .createAddress(draft);
      await Future<void>.delayed(Duration.zero);
      expect(repository.createAddressAttempts, 1);
      container.dispose();
      container = ProviderContainer(
        overrides: [
          customerAccountIdentityProvider.overrideWithValue(_identity()),
          customerAccountRepositoryProvider.overrideWithValue(repository),
          customerAccountShopSlugProvider.overrideWithValue(null),
        ],
      );
      container.read(customerAccountControllerProvider);
      await _waitForStatus(container, CustomerAccountStatus.ready);
      final newRequest = container
          .read(customerAccountControllerProvider.notifier)
          .createAddress(draft);
      await Future<void>.delayed(Duration.zero);
      expect(repository.createAddressAttempts, 2);
      expect(repository.receivedIntentIds.toSet(), hasLength(1));
      barrier.complete();
      expect(await oldRequest, isNull);
      expect(await newRequest, isNotNull);
      expect(repository.createAddressCalls, 1);
    },
  );

  test(
    'rifiuto server esplicito libera bozza per correzione senza conferma',
    () async {
      container.read(customerAccountControllerProvider);
      await _waitForStatus(container, CustomerAccountStatus.ready);
      repository.mutationError = const CustomerAccountRepositoryException(
        CustomerAccountFailureKind.invalidInput,
        creationRejected: true,
      );
      final result = await container
          .read(customerAccountControllerProvider.notifier)
          .createAddress(testCustomerAddress().toDraft());
      expect(result, isNull);
      final state = container.read(customerAccountControllerProvider);
      expect(state.failure?.isUncertain, isFalse);
      expect(state.pendingAddressDraft, isNull);
      expect(repository.addressCreationJournal.intents, isEmpty);
      expect(repository.createAddressCalls, 0);
    },
  );

  test(
    'intent letto dopo flush fallito non consente RPC senza nuova persistenza',
    () async {
      container.read(customerAccountControllerProvider);
      await _waitForStatus(container, CustomerAccountStatus.ready);
      repository.addressResponseError = offlineCustomerFailure();
      final controller = container.read(
        customerAccountControllerProvider.notifier,
      );
      final draft = testCustomerAddress().toDraft();
      await controller.createAddress(draft);
      repository.addressCreationJournal.writeError = StateError('flush_failed');
      await controller.createAddress(draft);
      expect(repository.reconcileCalls, 0);
      expect(repository.createAddressAttempts, 1);
      repository.addressCreationJournal.writeError = null;
      expect(await controller.createAddress(draft), isNotNull);
      expect(repository.reconcileCalls, 1);
      expect(repository.createAddressCalls, 1);
    },
  );

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
          customerAccountShopSlugProvider.overrideWithValue(null),
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

  test('mutation A-B-A non rilegge né pubblica nella nuova sessione', () async {
    container.dispose();
    final identity = StateProvider<AuthenticatedCustomer?>(
      (ref) => _identity(),
    );
    container = ProviderContainer(
      overrides: [
        customerAccountIdentityProvider.overrideWith(
          (ref) => ref.watch(identity),
        ),
        customerAccountRepositoryProvider.overrideWithValue(repository),
        customerAccountShopSlugProvider.overrideWithValue(null),
        customerIdempotencyKeyFactoryProvider.overrideWithValue(
          () => '21000000-0000-4000-8000-000000000777',
        ),
      ],
    );
    final notices = <CustomerAccountNoticeKind?>[];
    container.listen(
      customerAccountControllerProvider,
      (_, next) => notices.add(next.notice),
    );
    await _waitForStatus(container, CustomerAccountStatus.ready);
    final barrier = Completer<void>();
    repository.deletionBarrier = barrier;
    final pending = container
        .read(customerAccountControllerProvider.notifier)
        .requestAccountDeletion();
    container.read(identity.notifier).state = _identity(secondSubject);
    container.read(customerAccountControllerProvider);
    container.read(identity.notifier).state = _identity();
    container.read(customerAccountControllerProvider);
    notices.clear();
    barrier.complete();
    await pending;
    await _waitForStatus(container, CustomerAccountStatus.ready);
    expect(
      notices,
      isNot(contains(CustomerAccountNoticeKind.deletionRequested)),
    );
    expect(repository.loadCalls, 2);
  });

  test('identity assente non legge repository e resta signedOut', () async {
    container.dispose();
    container = ProviderContainer(
      overrides: [
        customerAccountIdentityProvider.overrideWithValue(null),
        customerAccountRepositoryProvider.overrideWithValue(repository),
        customerAccountShopSlugProvider.overrideWithValue(null),
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
