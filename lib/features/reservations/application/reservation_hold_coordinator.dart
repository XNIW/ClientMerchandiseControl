import '../domain/reservation_hold_failure.dart';
import '../domain/reservation_hold_models.dart';
import '../domain/reservation_hold_repository.dart';

typedef ReservationHoldIdempotencyKeyFactory = String Function();
typedef ReservationHoldClock = DateTime Function();

final class ReservationHoldCoordinator {
  const ReservationHoldCoordinator(
    this._repository,
    this._localStore,
    this._idempotencyKeyFactory,
    this._clock,
  );

  final ReservationHoldRepository _repository;
  final ReservationHoldLocalStore _localStore;
  final ReservationHoldIdempotencyKeyFactory _idempotencyKeyFactory;
  final ReservationHoldClock _clock;

  Future<void> prepareForCartMutation({
    required String ownerSubjectId,
    required String shopSlug,
    String? publicationId,
  }) async {
    final entries = publicationId == null
        ? await _localStore.readContext(
            ownerSubjectId: ownerSubjectId,
            shopSlug: shopSlug,
          )
        : [
            ?await _localStore.readEntry(
              ownerSubjectId: ownerSubjectId,
              shopSlug: shopSlug,
              publicationId: publicationId,
            ),
          ];
    for (final entry in entries) {
      await _releaseBestEffort(entry);
    }
  }

  Future<void> prepareForSignOut({
    required String ownerSubjectId,
    required String shopSlug,
  }) {
    return prepareForCartMutation(
      ownerSubjectId: ownerSubjectId,
      shopSlug: shopSlug,
    );
  }

  Future<void> _releaseBestEffort(ReservationHoldLocalEntry entry) async {
    var current = entry;
    try {
      final pending = current.pendingOperation;
      if (pending?.kind == ReservationHoldPendingOperationKind.create) {
        final response = await _repository.create(
          shopSlug: current.shopSlug,
          publicationId: current.publicationId,
          quantity: current.quantity,
          idempotencyKey: pending!.idempotencyKey,
        );
        final hold = response.hold;
        if (hold == null) {
          if (_isTerminalBusinessStatus(response.status)) {
            await _remove(current);
          }
          return;
        }
        current = current.copyWith(
          hold: hold,
          clearPendingOperation: true,
          updatedAt: _clock(),
        );
        await _localStore.saveEntry(current);
      }

      final hold = current.hold;
      if (hold == null) {
        await _remove(current);
        return;
      }
      if (hold.isTerminal) {
        await _localStore.saveEntry(
          current.copyWith(clearPendingOperation: true, updatedAt: _clock()),
        );
        return;
      }

      final releasePending =
          current.pendingOperation?.kind ==
              ReservationHoldPendingOperationKind.release
          ? current.pendingOperation!
          : ReservationHoldPendingOperation(
              kind: ReservationHoldPendingOperationKind.release,
              idempotencyKey: _idempotencyKeyFactory(),
            );
      current = current.copyWith(
        pendingOperation: releasePending,
        updatedAt: _clock(),
      );
      await _localStore.saveEntry(current);
      final response = await _repository.release(
        holdId: hold.holdId,
        idempotencyKey: releasePending.idempotencyKey,
      );
      if (response.hold case final resolved?) {
        await _localStore.saveEntry(
          current.copyWith(
            hold: resolved,
            clearPendingOperation: true,
            updatedAt: _clock(),
          ),
        );
      } else if (response.status == ReservationHoldRemoteStatus.notFound) {
        await _remove(current);
      }
    } on ReservationHoldRepositoryException {
      // Il pending persistito viene riconciliato al prossimo accesso autenticato.
    } on Object {
      // Un errore locale non deve impedire cart mutation o logout richiesti.
    }
  }

  bool _isTerminalBusinessStatus(ReservationHoldRemoteStatus status) =>
      switch (status) {
        ReservationHoldRemoteStatus.unavailable ||
        ReservationHoldRemoteStatus.holdLimitReached ||
        ReservationHoldRemoteStatus.invalid ||
        ReservationHoldRemoteStatus.notFound => true,
        _ => false,
      };

  Future<void> _remove(ReservationHoldLocalEntry entry) {
    return _localStore.removeEntry(
      ownerSubjectId: entry.ownerSubjectId,
      shopSlug: entry.shopSlug,
      publicationId: entry.publicationId,
    );
  }
}
