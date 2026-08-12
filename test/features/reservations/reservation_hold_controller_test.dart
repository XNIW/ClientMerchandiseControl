import 'dart:async';

import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/reservations/application/reservation_hold_controller.dart';
import 'package:client_merchandise_control/features/reservations/application/reservation_hold_providers.dart';
import 'package:client_merchandise_control/features/reservations/domain/reservation_hold_failure.dart';
import 'package:client_merchandise_control/features/reservations/domain/reservation_hold_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reservation_hold_test_support.dart';

final _identityProvider = StateProvider<AuthenticatedCustomer?>((ref) => null);

void main() {
  test('timeout create conserva intent e retry usa la stessa chiave', () async {
    final repository = FakeReservationHoldRepository();
    final store = MemoryReservationHoldStore();
    repository.createOutcomes.addAll([
      const ReservationHoldRepositoryException(
        ReservationHoldFailureKind.timeout,
      ),
      reservationResponse(hold: reservationSnapshot()),
    ]);
    repository.readOutcomes.add(
      reservationResponse(hold: reservationSnapshot(remainingSeconds: 599)),
    );
    final container = _container(repository: repository, store: store);
    addTearDown(container.dispose);
    final subscription = _keepAlive(container);
    addTearDown(subscription.close);
    await _waitFor(container, ReservationHoldViewStatus.idle);
    final controller = container.read(
      reservationHoldControllerProvider(reservationTestPublication).notifier,
    );

    await controller.reserve(quantity: 2);
    expect(
      container
          .read(reservationHoldControllerProvider(reservationTestPublication))
          .failureKind,
      ReservationHoldFailureKind.timeout,
    );
    final pending = await store.readEntry(
      ownerSubjectId: reservationTestOwner,
      shopSlug: reservationTestShop,
      publicationId: reservationTestPublication,
    );
    expect(pending?.pendingOperation?.idempotencyKey, reservationTestKey);

    await controller.retry();

    expect(repository.createCalls, hasLength(2));
    expect(repository.createCalls.map((call) => call.idempotencyKey).toSet(), {
      reservationTestKey,
    });
    expect(
      container
          .read(reservationHoldControllerProvider(reservationTestPublication))
          .status,
      ReservationHoldViewStatus.active,
    );
  });

  test('doppio tap condivide una sola operazione create', () async {
    final repository = FakeReservationHoldRepository();
    final store = MemoryReservationHoldStore();
    repository.createOutcomes.add(
      reservationResponse(hold: reservationSnapshot()),
    );
    repository.readOutcomes.add(
      reservationResponse(hold: reservationSnapshot()),
    );
    final container = _container(repository: repository, store: store);
    addTearDown(container.dispose);
    final subscription = _keepAlive(container);
    addTearDown(subscription.close);
    await _waitFor(container, ReservationHoldViewStatus.idle);
    final controller = container.read(
      reservationHoldControllerProvider(reservationTestPublication).notifier,
    );

    final first = controller.reserve(quantity: 2);
    final second = controller.reserve(quantity: 2);
    expect(identical(first, second), isTrue);
    await Future.wait([first, second]);

    expect(repository.createCalls, hasLength(1));
    expect(repository.readCalls, [reservationTestHold]);
  });

  test(
    'restart riconcilia hold con read server prima di mostrarla attiva',
    () async {
      final repository = FakeReservationHoldRepository();
      final store = MemoryReservationHoldStore();
      await store.saveEntry(
        reservationEntry(hold: reservationSnapshot(remainingSeconds: 580)),
      );
      repository.readOutcomes.add(
        reservationResponse(hold: reservationSnapshot(remainingSeconds: 420)),
      );

      var container = _container(repository: repository, store: store);
      var subscription = _keepAlive(container);
      await _waitFor(container, ReservationHoldViewStatus.active);
      expect(
        container
            .read(reservationHoldControllerProvider(reservationTestPublication))
            .remainingSeconds,
        420,
      );
      subscription.close();
      container.dispose();

      repository.readOutcomes.add(
        reservationResponse(hold: reservationSnapshot(remainingSeconds: 360)),
      );
      container = _container(repository: repository, store: store);
      addTearDown(container.dispose);
      subscription = _keepAlive(container);
      addTearDown(subscription.close);
      await _waitFor(container, ReservationHoldViewStatus.active);

      expect(repository.readCalls, [reservationTestHold, reservationTestHold]);
      expect(
        container
            .read(reservationHoldControllerProvider(reservationTestPublication))
            .remainingSeconds,
        360,
      );
    },
  );

  test(
    'release ambiguo conserva chiave e retry risolve stato terminale',
    () async {
      final repository = FakeReservationHoldRepository();
      final store = MemoryReservationHoldStore();
      await store.saveEntry(reservationEntry(hold: reservationSnapshot()));
      repository.readOutcomes.add(
        reservationResponse(hold: reservationSnapshot()),
      );
      repository.releaseOutcomes.addAll([
        const ReservationHoldRepositoryException(
          ReservationHoldFailureKind.offline,
        ),
        reservationResponse(
          status: ReservationHoldRemoteStatus.terminal,
          hold: reservationSnapshot(
            status: ReservationHoldServerStatus.released,
          ),
        ),
      ]);
      final container = _container(
        repository: repository,
        store: store,
        keyFactory: () => reservationSecondKey,
      );
      addTearDown(container.dispose);
      final subscription = _keepAlive(container);
      addTearDown(subscription.close);
      await _waitFor(container, ReservationHoldViewStatus.active);
      final controller = container.read(
        reservationHoldControllerProvider(reservationTestPublication).notifier,
      );

      await controller.release();
      await controller.retry();

      expect(repository.releaseCalls, hasLength(2));
      expect(
        repository.releaseCalls.map((call) => call.idempotencyKey).toSet(),
        {reservationSecondKey},
      );
      expect(
        container
            .read(reservationHoldControllerProvider(reservationTestPublication))
            .status,
        ReservationHoldViewStatus.released,
      );
    },
  );

  test(
    'cambio account non eredita hold o pending dell owner precedente',
    () async {
      final repository = FakeReservationHoldRepository();
      final store = MemoryReservationHoldStore();
      await store.saveEntry(reservationEntry(hold: reservationSnapshot()));
      repository.readOutcomes.add(
        reservationResponse(hold: reservationSnapshot()),
      );
      final container = _container(repository: repository, store: store);
      addTearDown(container.dispose);
      final subscription = _keepAlive(container);
      addTearDown(subscription.close);
      await _waitFor(container, ReservationHoldViewStatus.active);

      container.read(_identityProvider.notifier).state = reservationIdentity(
        reservationSecondOwner,
      );
      await _waitFor(container, ReservationHoldViewStatus.idle);

      final state = container.read(
        reservationHoldControllerProvider(reservationTestPublication),
      );
      expect(state.hold, isNull);
      expect(state.isAuthenticated, isTrue);
    },
  );

  test(
    'countdown server-derived passa a expiring e riconcilia expiry',
    () async {
      final repository = FakeReservationHoldRepository();
      final store = MemoryReservationHoldStore();
      await store.saveEntry(
        reservationEntry(hold: reservationSnapshot(remainingSeconds: 1)),
      );
      repository.readOutcomes.addAll([
        reservationResponse(hold: reservationSnapshot(remainingSeconds: 1)),
        reservationResponse(
          status: ReservationHoldRemoteStatus.terminal,
          hold: reservationSnapshot(
            status: ReservationHoldServerStatus.expired,
          ),
        ),
      ]);
      final container = _container(repository: repository, store: store);
      addTearDown(container.dispose);
      final subscription = _keepAlive(container);
      addTearDown(subscription.close);
      await _waitFor(container, ReservationHoldViewStatus.expiring);

      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await _waitFor(container, ReservationHoldViewStatus.expired);

      expect(repository.readCalls, hasLength(2));
    },
  );

  test('create iniziata da A non viene salvata o mostrata sotto B', () async {
    final response = Completer<ReservationHoldRemoteResponse>();
    final repository = FakeReservationHoldRepository()
      ..createOutcomes.add(response.future);
    final store = MemoryReservationHoldStore();
    final container = _container(repository: repository, store: store);
    addTearDown(container.dispose);
    final subscription = _keepAlive(container);
    addTearDown(subscription.close);
    await _waitFor(container, ReservationHoldViewStatus.idle);

    final operation = container
        .read(
          reservationHoldControllerProvider(
            reservationTestPublication,
          ).notifier,
        )
        .reserve(quantity: 2);
    while (repository.createCalls.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    container.read(_identityProvider.notifier).state = reservationIdentity(
      reservationSecondOwner,
    );
    await _waitFor(container, ReservationHoldViewStatus.idle);

    response.complete(reservationResponse(hold: reservationSnapshot()));
    await operation;

    final state = container.read(
      reservationHoldControllerProvider(reservationTestPublication),
    );
    expect(state.hold, isNull);
    expect(
      await store.readEntry(
        ownerSubjectId: reservationSecondOwner,
        shopSlug: reservationTestShop,
        publicationId: reservationTestPublication,
      ),
      isNull,
    );
  });
}

ProviderContainer _container({
  required FakeReservationHoldRepository repository,
  required MemoryReservationHoldStore store,
  String Function()? keyFactory,
}) {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(reservationTestConfig()),
      customerAccountIdentityProvider.overrideWith(
        (ref) => ref.watch(_identityProvider),
      ),
      reservationHoldRepositoryProvider.overrideWithValue(repository),
      reservationHoldLocalStoreProvider.overrideWithValue(store),
      reservationHoldClockProvider.overrideWithValue(
        () => reservationTestServerTime,
      ),
      customerIdempotencyKeyFactoryProvider.overrideWithValue(
        keyFactory ?? () => reservationTestKey,
      ),
    ],
  );
  container.read(_identityProvider.notifier).state = reservationIdentity();
  return container;
}

ProviderSubscription<ReservationHoldState> _keepAlive(
  ProviderContainer container,
) => container.listen(
  reservationHoldControllerProvider(reservationTestPublication),
  (_, _) {},
  fireImmediately: true,
);

Future<ReservationHoldState> _waitFor(
  ProviderContainer container,
  ReservationHoldViewStatus status,
) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    final state = container.read(
      reservationHoldControllerProvider(reservationTestPublication),
    );
    if (state.status == status) return state;
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  throw TestFailure(
    'Reservation state non raggiunto: '
    '${container.read(reservationHoldControllerProvider(reservationTestPublication)).status}',
  );
}
