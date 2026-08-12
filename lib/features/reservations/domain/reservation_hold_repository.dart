import 'reservation_hold_models.dart';

abstract interface class ReservationHoldRepository {
  Future<ReservationHoldRemoteResponse> create({
    required String shopSlug,
    required String publicationId,
    required int quantity,
    required String idempotencyKey,
  });

  Future<ReservationHoldRemoteResponse> read({required String holdId});

  Future<ReservationHoldRemoteResponse> release({
    required String holdId,
    required String idempotencyKey,
  });
}

abstract interface class ReservationHoldLocalStore {
  Future<List<ReservationHoldLocalEntry>> readContext({
    required String ownerSubjectId,
    required String shopSlug,
  });

  Future<ReservationHoldLocalEntry?> readEntry({
    required String ownerSubjectId,
    required String shopSlug,
    required String publicationId,
  });

  Future<void> saveEntry(ReservationHoldLocalEntry entry);

  Future<void> removeEntry({
    required String ownerSubjectId,
    required String shopSlug,
    required String publicationId,
  });
}
