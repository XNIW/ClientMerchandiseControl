const reservationHoldMaximumQuantity = 99;
const reservationHoldMaximumEntriesPerContext = 25;

enum ReservationHoldRemoteStatus {
  ok,
  activeHoldExists,
  terminal,
  unavailable,
  holdLimitReached,
  idempotencyConflict,
  invalid,
  notFound,
}

enum ReservationHoldServerStatus { active, released, expired, consumed }

enum ReservationHoldPendingOperationKind { create, release }

final class ReservationHoldSnapshot {
  const ReservationHoldSnapshot({
    required this.holdId,
    required this.shopSlug,
    required this.publicationId,
    required this.quantity,
    required this.status,
    required this.expiresAt,
    required this.serverTime,
    required this.remainingSeconds,
    required this.idempotent,
    this.terminalAt,
  });

  final String holdId;
  final String shopSlug;
  final String publicationId;
  final int quantity;
  final ReservationHoldServerStatus status;
  final DateTime expiresAt;
  final DateTime? terminalAt;
  final DateTime serverTime;
  final int remainingSeconds;
  final bool idempotent;

  bool get isActive => status == ReservationHoldServerStatus.active;
  bool get isTerminal => !isActive;
}

final class ReservationHoldRemoteResponse {
  const ReservationHoldRemoteResponse({
    required this.status,
    required this.idempotent,
    required this.serverTime,
    this.hold,
  });

  final ReservationHoldRemoteStatus status;
  final bool idempotent;
  final DateTime serverTime;
  final ReservationHoldSnapshot? hold;
}

final class ReservationHoldPendingOperation {
  const ReservationHoldPendingOperation({
    required this.kind,
    required this.idempotencyKey,
  });

  final ReservationHoldPendingOperationKind kind;
  final String idempotencyKey;
}

final class ReservationHoldLocalEntry {
  const ReservationHoldLocalEntry({
    required this.ownerSubjectId,
    required this.shopSlug,
    required this.publicationId,
    required this.quantity,
    required this.updatedAt,
    this.hold,
    this.pendingOperation,
  });

  final String ownerSubjectId;
  final String shopSlug;
  final String publicationId;
  final int quantity;
  final ReservationHoldSnapshot? hold;
  final ReservationHoldPendingOperation? pendingOperation;
  final DateTime updatedAt;

  ReservationHoldLocalEntry copyWith({
    int? quantity,
    ReservationHoldSnapshot? hold,
    ReservationHoldPendingOperation? pendingOperation,
    DateTime? updatedAt,
    bool clearHold = false,
    bool clearPendingOperation = false,
  }) {
    return ReservationHoldLocalEntry(
      ownerSubjectId: ownerSubjectId,
      shopSlug: shopSlug,
      publicationId: publicationId,
      quantity: quantity ?? this.quantity,
      hold: clearHold ? null : hold ?? this.hold,
      pendingOperation: clearPendingOperation
          ? null
          : pendingOperation ?? this.pendingOperation,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

bool isReservationHoldUuid(String value) => RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
).hasMatch(value);

bool isReservationHoldShopSlug(String value) =>
    RegExp(r'^[a-z0-9][a-z0-9-]{1,62}$').hasMatch(value);
