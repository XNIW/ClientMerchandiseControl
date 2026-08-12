import 'package:client_merchandise_control/features/reservations/application/reservation_hold_coordinator.dart';
import 'package:client_merchandise_control/features/reservations/domain/reservation_hold_failure.dart';
import 'package:client_merchandise_control/features/reservations/domain/reservation_hold_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reservation_hold_test_support.dart';

void main() {
  test(
    'create ambiguo viene risolto con la stessa chiave prima del release',
    () async {
      final store = MemoryReservationHoldStore();
      final repository = FakeReservationHoldRepository();
      repository.createOutcomes.add(
        reservationResponse(hold: reservationSnapshot()),
      );
      repository.releaseOutcomes.add(
        reservationResponse(
          status: ReservationHoldRemoteStatus.terminal,
          hold: reservationSnapshot(
            status: ReservationHoldServerStatus.released,
          ),
        ),
      );
      await store.saveEntry(
        reservationEntry(
          pending: const ReservationHoldPendingOperation(
            kind: ReservationHoldPendingOperationKind.create,
            idempotencyKey: reservationTestKey,
          ),
        ),
      );
      final coordinator = ReservationHoldCoordinator(
        repository,
        store,
        () => reservationSecondKey,
        () => reservationTestServerTime,
      );

      await coordinator.prepareForCartMutation(
        ownerSubjectId: reservationTestOwner,
        shopSlug: reservationTestShop,
        publicationId: reservationTestPublication,
      );

      expect(repository.createCalls.single.idempotencyKey, reservationTestKey);
      expect(
        repository.releaseCalls.single.idempotencyKey,
        reservationSecondKey,
      );
      final saved = await store.readEntry(
        ownerSubjectId: reservationTestOwner,
        shopSlug: reservationTestShop,
        publicationId: reservationTestPublication,
      );
      expect(saved?.hold?.status, ReservationHoldServerStatus.released);
      expect(saved?.pendingOperation, isNull);
    },
  );

  test(
    'offline conserva il release pending e non blocca cart mutation',
    () async {
      final store = MemoryReservationHoldStore();
      final repository = FakeReservationHoldRepository();
      repository.releaseOutcomes.add(
        const ReservationHoldRepositoryException(
          ReservationHoldFailureKind.offline,
        ),
      );
      await store.saveEntry(reservationEntry(hold: reservationSnapshot()));
      final coordinator = ReservationHoldCoordinator(
        repository,
        store,
        () => reservationSecondKey,
        () => reservationTestServerTime,
      );

      await expectLater(
        coordinator.prepareForCartMutation(
          ownerSubjectId: reservationTestOwner,
          shopSlug: reservationTestShop,
          publicationId: reservationTestPublication,
        ),
        completes,
      );

      final pending = await store.readEntry(
        ownerSubjectId: reservationTestOwner,
        shopSlug: reservationTestShop,
        publicationId: reservationTestPublication,
      );
      expect(
        pending?.pendingOperation?.kind,
        ReservationHoldPendingOperationKind.release,
      );
      expect(pending?.pendingOperation?.idempotencyKey, reservationSecondKey);
    },
  );

  test(
    'logout rilascia tutte le hold attive dello stesso owner/shop',
    () async {
      final store = MemoryReservationHoldStore();
      final repository = FakeReservationHoldRepository();
      for (final fixture in [
        (reservationTestPublication, reservationTestHold),
        (reservationSecondPublication, '70000000-0000-4000-8000-000000000002'),
      ]) {
        await store.saveEntry(
          reservationEntry(
            publicationId: fixture.$1,
            hold: reservationSnapshot(
              publicationId: fixture.$1,
              holdId: fixture.$2,
            ),
          ),
        );
        repository.releaseOutcomes.add(
          reservationResponse(
            status: ReservationHoldRemoteStatus.terminal,
            hold: reservationSnapshot(
              publicationId: fixture.$1,
              holdId: fixture.$2,
              status: ReservationHoldServerStatus.released,
            ),
          ),
        );
      }
      final coordinator = ReservationHoldCoordinator(
        repository,
        store,
        () => reservationSecondKey,
        () => reservationTestServerTime,
      );

      await coordinator.prepareForSignOut(
        ownerSubjectId: reservationTestOwner,
        shopSlug: reservationTestShop,
      );

      expect(repository.releaseCalls, hasLength(2));
      expect(
        (await store.readContext(
          ownerSubjectId: reservationTestOwner,
          shopSlug: reservationTestShop,
        )).every((entry) => entry.hold?.isTerminal == true),
        isTrue,
      );
    },
  );

  test('hold terminale non genera una seconda release', () async {
    final store = MemoryReservationHoldStore();
    final repository = FakeReservationHoldRepository();
    await store.saveEntry(
      reservationEntry(
        hold: reservationSnapshot(status: ReservationHoldServerStatus.expired),
      ),
    );
    final coordinator = ReservationHoldCoordinator(
      repository,
      store,
      () => reservationSecondKey,
      () => reservationTestServerTime,
    );

    await coordinator.prepareForSignOut(
      ownerSubjectId: reservationTestOwner,
      shopSlug: reservationTestShop,
    );

    expect(repository.releaseCalls, isEmpty);
  });
}
