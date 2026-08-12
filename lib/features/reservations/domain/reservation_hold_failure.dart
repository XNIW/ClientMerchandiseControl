enum ReservationHoldFailureKind {
  offline,
  timeout,
  unauthorized,
  invalidInput,
  conflict,
  unavailable,
  limitReached,
  notFound,
  unexpected,
}

final class ReservationHoldRepositoryException implements Exception {
  const ReservationHoldRepositoryException(this.kind);

  final ReservationHoldFailureKind kind;
}
